import Foundation
import SwiftData
import XCTest
@testable import DogGo

@MainActor
final class LifeMomentResponseServiceTests: XCTestCase {
    func testResponseWritesOneMemoryAndCanBeRestored() throws {
        let setup = try makeSetup()

        let reaction = try LifeMomentResponseService().save(
            response: setup.response,
            for: setup.event,
            definition: setup.definition,
            in: setup.context
        )

        XCTAssertEqual(reaction, setup.response.reactionText)
        XCTAssertEqual(setup.event.selectedResponseID, setup.response.id)
        let memories = try setup.context.fetch(FetchDescriptor<MemoryRecord>())
        XCTAssertEqual(memories.count, 1)
        XCTAssertTrue(memories[0].tags.contains("first_meeting"))
        XCTAssertTrue(memories[0].tags.contains(contentsOf: setup.response.memoryTags))
    }

    func testSecondResponseIsRejectedWithoutDuplicateMemory() throws {
        let setup = try makeSetup()
        let service = LifeMomentResponseService()
        _ = try service.save(
            response: setup.response,
            for: setup.event,
            definition: setup.definition,
            in: setup.context
        )

        XCTAssertThrowsError(
            try service.save(
                response: setup.response,
                for: setup.event,
                definition: setup.definition,
                in: setup.context
            )
        )
        XCTAssertEqual(try setup.context.fetch(FetchDescriptor<MemoryRecord>()).count, 1)
    }

    func testPersistenceWorkCompletesWithinFeedbackBudget() throws {
        let setup = try makeSetup()
        let start = ContinuousClock.now

        _ = try LifeMomentResponseService().save(
            response: setup.response,
            for: setup.event,
            definition: setup.definition,
            in: setup.context
        )

        let duration = start.duration(to: .now)
        XCTAssertLessThan(duration, .milliseconds(500))
    }

    private func makeSetup() throws -> (
        context: ModelContext,
        event: LifeEventRecord,
        definition: EventDefinition,
        response: ResponseDefinition
    ) {
        let schema = Schema([LifeEventRecord.self, MemoryRecord.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let context = container.mainContext
        let definition = try XCTUnwrap(try EventCatalog.load().event(id: "first_meeting"))
        let response = try XCTUnwrap(definition.responses.first)
        let dogID = UUID()
        let event = LifeEventRecord(
            dogID: dogID,
            definitionID: definition.id,
            occurredAt: .now,
            sceneID: definition.sceneID,
            factPayload: Data(),
            emotion: definition.emotion,
            idempotencyKey: "test"
        )
        context.insert(event)
        try context.save()
        return (context, event, definition, response)
    }
}

private extension Array where Element == String {
    func contains(contentsOf expected: [String]) -> Bool {
        Set(expected).isSubset(of: Set(self))
    }
}
