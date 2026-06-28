import XCTest
@testable import DogGo

final class HomeLifePresentationTests: XCTestCase {
    func testTimePhaseBoundaries() {
        XCTAssertEqual(HomeTimePhase(hour: 4), .night)
        XCTAssertEqual(HomeTimePhase(hour: 5), .morning)
        XCTAssertEqual(HomeTimePhase(hour: 10), .morning)
        XCTAssertEqual(HomeTimePhase(hour: 11), .afternoon)
        XCTAssertEqual(HomeTimePhase(hour: 16), .afternoon)
        XCTAssertEqual(HomeTimePhase(hour: 17), .evening)
        XCTAssertEqual(HomeTimePhase(hour: 20), .evening)
        XCTAssertEqual(HomeTimePhase(hour: 21), .night)
    }

    func testEventTraceMappingUsesAvailableSceneAssets() {
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "nose_mark_on_window")?.assetName, "TraceNoseMarkWindow")
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "paper_bag_crumpled")?.assetName, "TracePaperBag")
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "toy_returned_to_rug")?.assetName, "TraceToyMoved")
        XCTAssertNil(HomeSceneTrace.resolve(visualTraceID: "blanket_new_fold"))
    }

    func testEveryBehaviorHasAStablePoseAndAutonomousAlternatives() {
        for behavior in DogBehavior.allCases {
            let poses = HomeIdlePlanner.poses(for: behavior)
            XCTAssertEqual(poses.first, behavior.visualPose)
            XCTAssertGreaterThan(poses.count, 1)
        }
    }

    func testObservingAndPlayingCanPassThroughStandingTurn() {
        XCTAssertTrue(HomeIdlePlanner.poses(for: .observing).contains(.standTurn))
        XCTAssertTrue(HomeIdlePlanner.poses(for: .playing).contains(.standTurn))
    }

    func testAutonomousPoseChangeHasAThirtySecondUpperBound() {
        XCTAssertEqual(HomeIdlePlanner.poseChangeMomentRange.lowerBound, 2)
        XCTAssertEqual(HomeIdlePlanner.poseChangeMomentRange.upperBound, 3)
        XCTAssertLessThanOrEqual(HomeIdlePlanner.poseChangeMomentRange.upperBound * 9, 30)
    }
}
