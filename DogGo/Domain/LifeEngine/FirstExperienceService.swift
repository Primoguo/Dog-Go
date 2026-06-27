import Foundation
import SwiftData

enum FirstExperienceError: Error {
    case definitionMissing
    case textMissing
}

@MainActor
struct FirstExperienceService {
    @discardableResult
    func ensureFirstMeeting(
        for dog: DogProfile,
        in modelContext: ModelContext,
        clock: some DogGoClock = SystemClock()
    ) throws -> LifeEventRecord {
        let dogID = dog.id
        let eventID = "first_meeting"
        let descriptor = FetchDescriptor<LifeEventRecord>(
            predicate: #Predicate { $0.dogID == dogID && $0.definitionID == eventID }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        guard let definition = try EventCatalog.load().event(id: eventID) else {
            throw FirstExperienceError.definitionMissing
        }
        guard let text = definition.textVariants.first else {
            throw FirstExperienceError.textMissing
        }

        let snapshot = LifeEventFactSnapshot(
            definitionID: definition.id,
            textVariantID: text.id,
            text: text.text,
            sceneID: definition.sceneID,
            emotion: definition.emotion,
            visualTraceID: definition.visualTraceID
        )
        let record = LifeEventRecord(
            dogID: dog.id,
            definitionID: definition.id,
            occurredAt: clock.now,
            sceneID: definition.sceneID,
            factPayload: try JSONEncoder().encode(snapshot),
            emotion: definition.emotion,
            visualTraceID: definition.visualTraceID,
            idempotencyKey: "\(dog.id.uuidString)|first_meeting"
        )

        modelContext.insert(record)
        try modelContext.save()
        return record
    }
}
