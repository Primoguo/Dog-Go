import Foundation
import XCTest
@testable import DogGo

final class MemoryReferenceLinkerTests: XCTestCase {
    func testLinksOnlyMatchingMemoriesAndReturnsReferencedTags() {
        let eventID = UUID()
        let matching = MemoryRecord(
            dogID: UUID(),
            sourceEventID: UUID(),
            tags: ["first_meeting", "gentle_response"]
        )
        let unrelated = MemoryRecord(
            dogID: UUID(),
            sourceEventID: UUID(),
            tags: ["toy_found"]
        )

        let tags = MemoryReferenceLinker().link(
            eventID: eventID,
            requiredTags: ["gentle_response"],
            memories: [matching, unrelated]
        )

        XCTAssertEqual(tags, ["gentle_response"])
        XCTAssertEqual(matching.referencedByEventIDs, [eventID])
        XCTAssertTrue(unrelated.referencedByEventIDs.isEmpty)
    }

    func testLinkingSameEventTwiceIsIdempotent() {
        let eventID = UUID()
        let memory = MemoryRecord(
            dogID: UUID(),
            sourceEventID: UUID(),
            tags: ["gentle_response"]
        )
        let linker = MemoryReferenceLinker()

        _ = linker.link(eventID: eventID, requiredTags: ["gentle_response"], memories: [memory])
        _ = linker.link(eventID: eventID, requiredTags: ["gentle_response"], memories: [memory])

        XCTAssertEqual(memory.referencedByEventIDs, [eventID])
    }
}
