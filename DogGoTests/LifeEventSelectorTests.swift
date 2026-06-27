import Foundation
import XCTest
@testable import DogGo

final class LifeEventSelectorTests: XCTestCase {
    private let selector = LifeEventSelector()

    func testSameSeedAndContextSelectSameEvent() throws {
        let events = try EventCatalog.load().events
        let context = EventSelectionContext(
            timeWindow: .daytime,
            traitWeights: ["curious": 0.8, "tidy": 0.7],
            memoryTags: ["first_meeting", "first_time_alone"],
            completedFirstExperienceIDs: ["first_meeting", "first_short_leave", "first_memory_reference"]
        )
        var firstRandom = SplitMix64RandomSource(seed: 42)
        var secondRandom = SplitMix64RandomSource(seed: 42)

        let first = selector.select(from: events, context: context, randomSource: &firstRandom)
        let second = selector.select(from: events, context: context, randomSource: &secondRandom)

        XCTAssertEqual(first?.definition.id, second?.definition.id)
    }

    func testEventRequiringMemoryIsFilteredWithoutTag() throws {
        let events = try EventCatalog.load().events
        let context = EventSelectionContext(timeWindow: .daytime)

        let eligibleIDs = Set(selector.eligibleEvents(from: events, context: context).map(\.definition.id))

        XCTAssertFalse(eligibleIDs.contains("window_bird_02"))
        XCTAssertFalse(eligibleIDs.contains("hidden_toy_02"))
    }

    func testExcludedRecentEventIsFiltered() throws {
        let events = try EventCatalog.load().events
        let context = EventSelectionContext(
            timeWindow: .daytime,
            recentEventIDs: ["window_bird_01"],
            completedFirstExperienceIDs: ["first_meeting"]
        )

        let eligibleIDs = Set(selector.eligibleEvents(from: events, context: context).map(\.definition.id))

        XCTAssertFalse(eligibleIDs.contains("window_bird_01"))
    }

    func testTraitAndFollowUpBonusesAreVisibleInScore() throws {
        let event = try XCTUnwrap(try EventCatalog.load().event(id: "window_bird_02"))
        let context = EventSelectionContext(
            timeWindow: .daytime,
            traitWeights: ["curious": 0.8],
            memoryTags: ["noticed_bird"],
            preferredFollowUpEventIDs: ["window_bird_02"]
        )

        let score = selector.score(event, context: context)

        XCTAssertEqual(score.traitMatch, 8)
        XCTAssertEqual(score.memoryAssociation, 4)
        XCTAssertEqual(score.followUp, 18)
        XCTAssertEqual(score.total, 52)
    }

    func testStableSeedChangesOnlyWhenInputChanges() {
        let dogID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        let first = StableEventSeed.make(dogID: dogID, windowStart: date, slot: 0)
        let repeated = StableEventSeed.make(dogID: dogID, windowStart: date, slot: 0)
        let nextSlot = StableEventSeed.make(dogID: dogID, windowStart: date, slot: 1)

        XCTAssertEqual(first, repeated)
        XCTAssertNotEqual(first, nextSlot)
    }

    func testTimeWindowBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let resolver = TimeWindowResolver(calendar: calendar)

        XCTAssertEqual(resolver.timeWindow(at: date(hour: 5, calendar: calendar)), .morning)
        XCTAssertEqual(resolver.timeWindow(at: date(hour: 9, calendar: calendar)), .daytime)
        XCTAssertEqual(resolver.timeWindow(at: date(hour: 17, calendar: calendar)), .evening)
        XCTAssertEqual(resolver.timeWindow(at: date(hour: 22, calendar: calendar)), .night)
    }

    private func date(hour: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: 27, hour: hour))!
    }
}
