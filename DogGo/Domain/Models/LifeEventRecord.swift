import Foundation
import SwiftData

@Model
final class LifeEventRecord {
    var id: UUID
    var definitionID: String
    var occurredAt: Date
    var sceneID: String
    var factPayload: Data
    var emotion: String
    var visualTraceID: String?
    var isViewed: Bool
    var selectedResponseID: String?
    var idempotencyKey: String

    init(
        id: UUID = UUID(),
        definitionID: String,
        occurredAt: Date,
        sceneID: String,
        factPayload: Data,
        emotion: String,
        visualTraceID: String? = nil,
        isViewed: Bool = false,
        selectedResponseID: String? = nil,
        idempotencyKey: String
    ) {
        self.id = id
        self.definitionID = definitionID
        self.occurredAt = occurredAt
        self.sceneID = sceneID
        self.factPayload = factPayload
        self.emotion = emotion
        self.visualTraceID = visualTraceID
        self.isViewed = isViewed
        self.selectedResponseID = selectedResponseID
        self.idempotencyKey = idempotencyKey
    }
}
