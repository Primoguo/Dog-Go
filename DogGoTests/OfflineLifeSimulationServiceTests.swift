import Foundation
import SwiftData
import XCTest
@testable import DogGo

@MainActor
final class OfflineLifeSimulationServiceTests: XCTestCase {
    func testLessThanTenMinutesGeneratesNothing() throws {
        let setup = try makeSetup()

        let result = try OfflineLifeSimulationService().simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: setup.start.addingTimeInterval(9 * 60)),
            calendar: utcCalendar
        )

        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(setup.state.lastSimulatedAt, setup.start)
    }

    func testFirstReturnGeneratesGuaranteedShortLeaveEvent() throws {
        let setup = try makeSetup()

        let result = try OfflineLifeSimulationService().simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: setup.start.addingTimeInterval(20 * 60)),
            calendar: utcCalendar
        )

        XCTAssertEqual(result.generatedEventIDs, ["first_short_leave"])
        XCTAssertEqual(try setup.context.fetch(FetchDescriptor<LifeEventRecord>()).count, 2)
    }

    func testRepeatedSimulationAtSameTimeIsIdempotent() throws {
        let setup = try makeSetup()
        let now = setup.start.addingTimeInterval(20 * 60)
        let service = OfflineLifeSimulationService()

        _ = try service.simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: now),
            calendar: utcCalendar
        )
        let repeated = try service.simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: now),
            calendar: utcCalendar
        )

        XCTAssertEqual(repeated.count, 0)
        XCTAssertEqual(try setup.context.fetch(FetchDescriptor<LifeEventRecord>()).count, 2)
    }

    func testLongAbsenceNeverGeneratesMoreThanThreeEvents() throws {
        let setup = try makeSetup()

        let result = try OfflineLifeSimulationService().simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: setup.start.addingTimeInterval(48 * 60 * 60)),
            calendar: utcCalendar
        )

        XCTAssertLessThanOrEqual(result.count, 3)
        XCTAssertGreaterThan(result.count, 0)
    }

    func testClockRollbackDoesNotChangeStateOrHistory() throws {
        let setup = try makeSetup()

        let result = try OfflineLifeSimulationService().simulate(
            for: setup.dog,
            state: setup.state,
            in: setup.context,
            clock: FixedClock(now: setup.start.addingTimeInterval(-60)),
            calendar: utcCalendar
        )

        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(setup.state.lastSimulatedAt, setup.start)
        XCTAssertEqual(try setup.context.fetch(FetchDescriptor<LifeEventRecord>()).count, 1)
    }

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func makeSetup() throws -> (
        container: ModelContainer,
        context: ModelContext,
        dog: DogProfile,
        state: DogState,
        start: Date
    ) {
        let schema = Schema([DogProfile.self, DogState.self, LifeEventRecord.self, MemoryRecord.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
        let start = Date(timeIntervalSince1970: 1_717_200_000)
        let dog = DogProfile(name: "栗子", adoptedAt: start)
        let state = DogState(dogID: dog.id, lastSimulatedAt: start)
        context.insert(dog)
        context.insert(state)
        _ = try FirstExperienceService().ensureFirstMeeting(
            for: dog,
            in: context,
            clock: FixedClock(now: start)
        )
        return (container, context, dog, state, start)
    }
}
