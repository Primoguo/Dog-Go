import Foundation
import XCTest
@testable import DogGo

final class EventCatalogTests: XCTestCase {
    func testBundledCatalogContainsExpectedM0Content() throws {
        let catalog = try EventCatalog.load()

        XCTAssertEqual(catalog.events.count, 15)
        XCTAssertEqual(catalog.events.filter { $0.category == .firstExperience }.count, 3)
        XCTAssertEqual(catalog.events.filter { $0.category == .ordinary }.count, 9)
        XCTAssertEqual(catalog.events.filter { $0.category == .followUp }.count, 3)
        XCTAssertNotNil(catalog.event(id: "window_bird_02"))
    }

    func testDuplicateEventIDIsRejected() throws {
        let definition = try XCTUnwrap(try EventCatalog.load().events.first)

        XCTAssertThrowsError(try EventCatalog(events: [definition, definition])) { error in
            XCTAssertEqual(error as? EventCatalogError, .duplicateEventID(definition.id))
        }
    }

    func testUnsupportedSchemaIsRejected() {
        let data = Data("{\"schemaVersion\":99,\"events\":[]}".utf8)

        XCTAssertThrowsError(try EventCatalog.decode(data)) { error in
            XCTAssertEqual(error as? EventCatalogError, .unsupportedSchema(99))
        }
    }
}
