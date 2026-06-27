import Foundation
import SwiftData
import XCTest
@testable import DogGo

@MainActor
final class AdoptionServiceTests: XCTestCase {
    func testAdoptionCreatesProfileStateAndRelationship() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let dog = try AdoptionService().adopt(
            name: "  栗子  ",
            in: context,
            clock: FixedClock(now: now)
        )

        XCTAssertEqual(dog.name, "栗子")
        XCTAssertEqual(dog.adoptedAt, now)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DogProfile>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DogState>()).first?.dogID, dog.id)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Relationship>()).first?.dogID, dog.id)
    }

    func testInvalidNameDoesNotWritePartialData() throws {
        let container = try makeContainer()
        let context = container.mainContext

        XCTAssertThrowsError(try AdoptionService().adopt(name: "   ", in: context))
        XCTAssertTrue(try context.fetch(FetchDescriptor<DogProfile>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<DogState>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Relationship>()).isEmpty)
    }

    func testNameLongerThanTwelveCharactersIsRejected() {
        XCTAssertThrowsError(try DogNameValidator.validated("一二三四五六七八九十一二三")) { error in
            XCTAssertEqual(error as? DogNameValidationError, .tooLong)
        }
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DogProfile.self, DogState.self, Relationship.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
