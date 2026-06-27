import Foundation

struct EventSelectionContext {
    let timeWindow: TimeWindow
    let traitWeights: [String: Double]
    let memoryTags: Set<String>
    let recentEventIDs: [String]
    let completedFirstExperienceIDs: Set<String>
    let preferredFollowUpEventIDs: Set<String>

    init(
        timeWindow: TimeWindow,
        traitWeights: [String: Double] = [:],
        memoryTags: Set<String> = [],
        recentEventIDs: [String] = [],
        completedFirstExperienceIDs: Set<String> = [],
        preferredFollowUpEventIDs: Set<String> = []
    ) {
        self.timeWindow = timeWindow
        self.traitWeights = traitWeights
        self.memoryTags = memoryTags
        self.recentEventIDs = recentEventIDs
        self.completedFirstExperienceIDs = completedFirstExperienceIDs
        self.preferredFollowUpEventIDs = preferredFollowUpEventIDs
    }
}

struct EventScore: Equatable {
    let base: Int
    let timeMatch: Int
    let traitMatch: Int
    let memoryAssociation: Int
    let followUp: Int
    let recentRepeatPenalty: Int

    var total: Int {
        max(0, base + timeMatch + traitMatch + memoryAssociation + followUp - recentRepeatPenalty)
    }
}

struct ScoredEvent {
    let definition: EventDefinition
    let score: EventScore
}

struct LifeEventSelector {
    func eligibleEvents(
        from events: [EventDefinition],
        context: EventSelectionContext
    ) -> [ScoredEvent] {
        events.compactMap { event in
            guard event.timeWindows.contains(context.timeWindow) else { return nil }
            guard Set(event.requiredMemoryTags).isSubset(of: context.memoryTags) else { return nil }
            guard Set(event.excludedRecentEventIDs).isDisjoint(with: context.recentEventIDs) else { return nil }
            guard event.category != .firstExperience || !context.completedFirstExperienceIDs.contains(event.id) else {
                return nil
            }

            let score = score(event, context: context)
            return score.total > 0 ? ScoredEvent(definition: event, score: score) : nil
        }
    }

    func score(_ event: EventDefinition, context: EventSelectionContext) -> EventScore {
        let traitBonus = event.preferredTraits.reduce(into: 0) { total, trait in
            total += Int(((context.traitWeights[trait] ?? 0) * 10).rounded())
        }
        let memoryBonus = event.requiredMemoryTags.count * 4
        let followUpBonus = context.preferredFollowUpEventIDs.contains(event.id) ? 18 : 0
        let repeatPenalty = context.recentEventIDs.contains(event.id) ? 8 : 0

        return EventScore(
            base: event.baseWeight,
            timeMatch: 4,
            traitMatch: traitBonus,
            memoryAssociation: memoryBonus,
            followUp: followUpBonus,
            recentRepeatPenalty: repeatPenalty
        )
    }

    func select<Source: RandomSource>(
        from events: [EventDefinition],
        context: EventSelectionContext,
        randomSource: inout Source
    ) -> ScoredEvent? {
        let candidates = eligibleEvents(from: events, context: context)
        let totalWeight = candidates.reduce(0) { $0 + $1.score.total }
        guard totalWeight > 0 else { return nil }

        var threshold = Int(randomSource.nextUInt64() % UInt64(totalWeight))
        for candidate in candidates {
            if threshold < candidate.score.total {
                return candidate
            }
            threshold -= candidate.score.total
        }

        return candidates.last
    }
}
