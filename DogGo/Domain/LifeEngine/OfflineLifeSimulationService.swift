import Foundation
import SwiftData

struct OfflineSimulationResult: Equatable {
    let generatedEventIDs: [String]

    var count: Int { generatedEventIDs.count }
}

@MainActor
struct OfflineLifeSimulationService {
    private let selector = LifeEventSelector()
    private let minimumAbsence: TimeInterval = 10 * 60

    func simulate(
        for dog: DogProfile,
        state: DogState,
        in modelContext: ModelContext,
        clock: some DogGoClock = SystemClock(),
        calendar: Calendar = .current
    ) throws -> OfflineSimulationResult {
        let now = clock.now
        let absence = now.timeIntervalSince(state.lastSimulatedAt)
        guard absence >= minimumAbsence else {
            return OfflineSimulationResult(generatedEventIDs: [])
        }

        let eventCount = numberOfEvents(for: absence)
        let catalog = try EventCatalog.load()
        let dogID = dog.id
        let eventDescriptor = FetchDescriptor<LifeEventRecord>(
            predicate: #Predicate { $0.dogID == dogID },
            sortBy: [SortDescriptor(\LifeEventRecord.occurredAt)]
        )
        let memoryDescriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.dogID == dogID }
        )
        var existingEvents = try modelContext.fetch(eventDescriptor)
        let memories = try modelContext.fetch(memoryDescriptor)
        var generatedIDs: [String] = []
        let resolver = TimeWindowResolver(calendar: calendar)

        do {
            for slot in 0..<eventCount {
                let occurredAt = occurrenceDate(
                    slot: slot,
                    count: eventCount,
                    from: state.lastSimulatedAt,
                    to: now
                )
                let idempotencyKey = makeIdempotencyKey(dogID: dog.id, occurredAt: occurredAt, slot: slot)
                guard !existingEvents.contains(where: { $0.idempotencyKey == idempotencyKey }) else { continue }

                let context = selectionContext(
                    dog: dog,
                    at: occurredAt,
                    events: existingEvents,
                    memories: memories,
                    catalog: catalog,
                    resolver: resolver
                )
                let seed = StableEventSeed.make(
                    dogID: dog.id,
                    windowStart: resolver.windowStart(containing: occurredAt),
                    slot: slot
                )
                var random = SplitMix64RandomSource(seed: seed)

                let definition: EventDefinition?
                if !existingEvents.contains(where: { $0.definitionID == "first_short_leave" }) {
                    definition = catalog.event(id: "first_short_leave")
                } else {
                    definition = selector.select(
                        from: catalog.events,
                        context: context,
                        randomSource: &random
                    )?.definition
                }

                guard let definition,
                      definition.timeWindows.contains(context.timeWindow),
                      Set(definition.requiredMemoryTags).isSubset(of: context.memoryTags),
                      let text = chooseText(from: definition, randomSource: &random) else {
                    continue
                }

                let eventID = UUID()
                let referencedMemoryTags = MemoryReferenceLinker().link(
                    eventID: eventID,
                    requiredTags: definition.requiredMemoryTags,
                    memories: memories
                )
                let snapshot = LifeEventFactSnapshot(
                    definitionID: definition.id,
                    textVariantID: text.id,
                    text: text.text,
                    sceneID: definition.sceneID,
                    emotion: definition.emotion,
                    visualTraceID: definition.visualTraceID,
                    referencedMemoryTags: referencedMemoryTags.isEmpty ? nil : referencedMemoryTags
                )
                let record = LifeEventRecord(
                    id: eventID,
                    dogID: dog.id,
                    definitionID: definition.id,
                    occurredAt: occurredAt,
                    sceneID: definition.sceneID,
                    factPayload: try JSONEncoder().encode(snapshot),
                    emotion: definition.emotion,
                    visualTraceID: definition.visualTraceID,
                    idempotencyKey: idempotencyKey
                )

                modelContext.insert(record)
                existingEvents.append(record)
                generatedIDs.append(definition.id)
                state.currentBehaviorRawValue = behavior(for: definition).rawValue
            }

            state.lastSimulatedAt = now
            try modelContext.save()
            return OfflineSimulationResult(generatedEventIDs: generatedIDs)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func numberOfEvents(for absence: TimeInterval) -> Int {
        switch absence {
        case ..<(6 * 60 * 60): 1
        case ..<(18 * 60 * 60): 2
        default: 3
        }
    }

    private func occurrenceDate(slot: Int, count: Int, from start: Date, to end: Date) -> Date {
        let interval = end.timeIntervalSince(start) / Double(count)
        return start.addingTimeInterval(interval * Double(slot + 1))
    }

    private func makeIdempotencyKey(dogID: UUID, occurredAt: Date, slot: Int) -> String {
        let tenMinuteBucket = Int64(occurredAt.timeIntervalSince1970 / 600)
        return "\(dogID.uuidString)|offline|\(tenMinuteBucket)|\(slot)"
    }

    private func selectionContext(
        dog: DogProfile,
        at date: Date,
        events: [LifeEventRecord],
        memories: [MemoryRecord],
        catalog: EventCatalog,
        resolver: TimeWindowResolver
    ) -> EventSelectionContext {
        let recent = events.suffix(10).map(\.definitionID)
        let completedFirstExperiences = Set(events.compactMap { record -> String? in
            catalog.event(id: record.definitionID)?.category == .firstExperience ? record.definitionID : nil
        })
        let eventMemoryTags = events.reduce(into: Set<String>()) { tags, record in
            tags.formUnion(catalog.event(id: record.definitionID)?.memoryOutputTags ?? [])
        }
        let storedMemoryTags = memories.reduce(into: Set<String>()) { tags, memory in
            tags.formUnion(memory.tags)
        }
        let latestDefinition = events.last.flatMap { catalog.event(id: $0.definitionID) }

        return EventSelectionContext(
            timeWindow: resolver.timeWindow(at: date),
            traitWeights: dog.traitWeights,
            memoryTags: eventMemoryTags.union(storedMemoryTags),
            recentEventIDs: recent,
            completedFirstExperienceIDs: completedFirstExperiences,
            preferredFollowUpEventIDs: Set(latestDefinition?.followUpEventIDs ?? [])
        )
    }

    private func chooseText(
        from definition: EventDefinition,
        randomSource: inout SplitMix64RandomSource
    ) -> TextVariant? {
        guard !definition.textVariants.isEmpty else { return nil }
        let index = Int(randomSource.nextUInt64() % UInt64(definition.textVariants.count))
        return definition.textVariants[index]
    }

    private func behavior(for definition: EventDefinition) -> DogBehavior {
        if definition.id.contains("sleep") || definition.id.contains("sun_patch") {
            return .sleeping
        }
        if definition.id.contains("toy") || definition.id.contains("paper_bag") {
            return .playing
        }
        return .observing
    }
}
