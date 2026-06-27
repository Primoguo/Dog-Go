import Foundation
import SwiftData

@Model
final class MemoryRecord {
    var id: UUID
    var dogID: UUID
    var createdAt: Date
    var sourceEventID: UUID
    var responseID: String?
    var tagsData: Data
    var referencedByEventIDsData: Data

    init(
        id: UUID = UUID(),
        dogID: UUID,
        createdAt: Date = .now,
        sourceEventID: UUID,
        responseID: String? = nil,
        tags: [String],
        referencedByEventIDs: [UUID] = []
    ) {
        self.id = id
        self.dogID = dogID
        self.createdAt = createdAt
        self.sourceEventID = sourceEventID
        self.responseID = responseID
        self.tagsData = (try? JSONEncoder().encode(tags)) ?? Data()
        self.referencedByEventIDsData = (try? JSONEncoder().encode(referencedByEventIDs)) ?? Data()
    }

    var tags: [String] {
        (try? JSONDecoder().decode([String].self, from: tagsData)) ?? []
    }

    var referencedByEventIDs: [UUID] {
        (try? JSONDecoder().decode([UUID].self, from: referencedByEventIDsData)) ?? []
    }
}
