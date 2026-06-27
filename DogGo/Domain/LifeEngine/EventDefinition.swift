import Foundation

enum EventCategory: String, Codable {
    case firstExperience
    case ordinary
    case followUp
}

enum TimeWindow: String, Codable, CaseIterable {
    case morning
    case daytime
    case evening
    case night
}

struct EventCatalogDocument: Codable {
    let schemaVersion: Int
    let events: [EventDefinition]
}

struct EventDefinition: Codable, Identifiable {
    let id: String
    let category: EventCategory
    let timeWindows: [TimeWindow]
    let baseWeight: Int
    let preferredTraits: [String]
    let excludedRecentEventIDs: [String]
    let requiredMemoryTags: [String]
    let stateEffects: StateEffects
    let memoryOutputTags: [String]
    let followUpEventIDs: [String]
    let sceneID: String
    let visualTraceID: String?
    let emotion: String
    let textVariants: [TextVariant]
    let responses: [ResponseDefinition]
}

struct StateEffects: Codable, Equatable {
    let mood: Int?
    let energy: Int?
    let social: Int?
    let curiosity: Int?
}

struct TextVariant: Codable, Identifiable {
    let id: String
    let text: String
}

struct ResponseDefinition: Codable, Identifiable {
    let id: String
    let label: String
    let reactionText: String
    let memoryTags: [String]
}
