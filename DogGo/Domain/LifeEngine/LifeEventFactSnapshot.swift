import Foundation

struct LifeEventFactSnapshot: Codable, Equatable {
    let definitionID: String
    let textVariantID: String
    let text: String
    let sceneID: String
    let emotion: String
    let visualTraceID: String?
    let referencedMemoryTags: [String]?

    init(
        definitionID: String,
        textVariantID: String,
        text: String,
        sceneID: String,
        emotion: String,
        visualTraceID: String?,
        referencedMemoryTags: [String]? = nil
    ) {
        self.definitionID = definitionID
        self.textVariantID = textVariantID
        self.text = text
        self.sceneID = sceneID
        self.emotion = emotion
        self.visualTraceID = visualTraceID
        self.referencedMemoryTags = referencedMemoryTags
    }
}

extension LifeEventRecord {
    var factSnapshot: LifeEventFactSnapshot? {
        try? JSONDecoder().decode(LifeEventFactSnapshot.self, from: factPayload)
    }
}
