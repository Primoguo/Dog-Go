import Foundation

enum EventCatalogError: Error, Equatable {
    case resourceNotFound(String)
    case unsupportedSchema(Int)
    case duplicateEventID(String)
    case emptyTextVariants(String)
}

struct EventCatalog {
    static let supportedSchemaVersion = 1

    let events: [EventDefinition]

    init(events: [EventDefinition]) throws {
        var seenIDs = Set<String>()

        for event in events {
            guard seenIDs.insert(event.id).inserted else {
                throw EventCatalogError.duplicateEventID(event.id)
            }
            guard !event.textVariants.isEmpty else {
                throw EventCatalogError.emptyTextVariants(event.id)
            }
        }

        self.events = events
    }

    static func load(
        named resourceName: String = "m0-events",
        bundle: Bundle = .main
    ) throws -> EventCatalog {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw EventCatalogError.resourceNotFound(resourceName)
        }

        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> EventCatalog {
        let document = try JSONDecoder().decode(EventCatalogDocument.self, from: data)
        guard document.schemaVersion == supportedSchemaVersion else {
            throw EventCatalogError.unsupportedSchema(document.schemaVersion)
        }
        return try EventCatalog(events: document.events)
    }

    func event(id: String) -> EventDefinition? {
        events.first { $0.id == id }
    }
}
