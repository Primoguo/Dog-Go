import Foundation
import SwiftData

enum LifeMomentResponseError: Error {
    case alreadyResponded
}

@MainActor
struct LifeMomentResponseService {
    @discardableResult
    func save(
        response: ResponseDefinition,
        for event: LifeEventRecord,
        definition: EventDefinition,
        in modelContext: ModelContext
    ) throws -> String {
        guard event.selectedResponseID == nil else {
            throw LifeMomentResponseError.alreadyResponded
        }

        let sourceEventID = event.id
        let existingDescriptor = FetchDescriptor<MemoryRecord>(
            predicate: #Predicate { $0.sourceEventID == sourceEventID }
        )
        let hasExistingMemory = try !modelContext.fetch(existingDescriptor).isEmpty
        event.selectedResponseID = response.id

        if !hasExistingMemory {
            let tags = Array(Set(definition.memoryOutputTags + response.memoryTags)).sorted()
            modelContext.insert(
                MemoryRecord(
                    dogID: event.dogID,
                    sourceEventID: event.id,
                    responseID: response.id,
                    tags: tags
                )
            )
        }

        do {
            try modelContext.save()
            return response.reactionText
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
