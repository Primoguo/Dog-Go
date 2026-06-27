import Foundation

struct LifeEventFactSnapshot: Codable, Equatable {
    let definitionID: String
    let textVariantID: String
    let text: String
    let sceneID: String
    let emotion: String
    let visualTraceID: String?
}

extension LifeEventRecord {
    var factSnapshot: LifeEventFactSnapshot? {
        try? JSONDecoder().decode(LifeEventFactSnapshot.self, from: factPayload)
    }
}
