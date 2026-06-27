import Foundation
import SwiftData
import XCTest
@testable import DogGo

@MainActor
final class FirstExperienceServiceTests: XCTestCase {
    func testFirstMeetingIsGeneratedOnlyOnce() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dog = DogProfile(name: "栗子")
        context.insert(dog)
        let clock = FixedClock(now: Date(timeIntervalSince1970: 1_700_000_000))

        let first = try FirstExperienceService().ensureFirstMeeting(for: dog, in: context, clock: clock)
        let second = try FirstExperienceService().ensureFirstMeeting(for: dog, in: context, clock: clock)

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(try context.fetch(FetchDescriptor<LifeEventRecord>()).count, 1)
        XCTAssertEqual(first.factSnapshot?.definitionID, "first_meeting")
        XCTAssertFalse(first.factSnapshot?.text.isEmpty ?? true)
    }

    func testSnapshotKeepsAuthoredFact() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let dog = DogProfile(name: "栗子")
        context.insert(dog)

        let event = try FirstExperienceService().ensureFirstMeeting(for: dog, in: context)

        XCTAssertEqual(event.factSnapshot?.textVariantID, "a")
        XCTAssertEqual(event.sceneID, event.factSnapshot?.sceneID)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([DogProfile.self, LifeEventRecord.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
