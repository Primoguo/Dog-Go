import Foundation
import SwiftData

enum RelationshipStage: String, Codable, CaseIterable {
    case acquainted
    case familiar
    case trusting
}

@Model
final class Relationship {
    var id: UUID
    var dogID: UUID
    var stageRawValue: String
    var milestoneIDsData: Data
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dogID: UUID,
        stage: RelationshipStage = .acquainted,
        milestoneIDs: [String] = [],
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dogID = dogID
        self.stageRawValue = stage.rawValue
        self.milestoneIDsData = (try? JSONEncoder().encode(milestoneIDs)) ?? Data()
        self.updatedAt = updatedAt
    }

    var stage: RelationshipStage {
        RelationshipStage(rawValue: stageRawValue) ?? .acquainted
    }

    var milestoneIDs: [String] {
        (try? JSONDecoder().decode([String].self, from: milestoneIDsData)) ?? []
    }
}
