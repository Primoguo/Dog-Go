import XCTest
@testable import DogGo

final class HomeLifePresentationTests: XCTestCase {
    func testTimePhaseBoundaries() {
        XCTAssertEqual(HomeTimePhase(hour: 4), .night)
        XCTAssertEqual(HomeTimePhase(hour: 5), .dawn)
        XCTAssertEqual(HomeTimePhase(hour: 7), .dawn)
        XCTAssertEqual(HomeTimePhase(hour: 8), .morning)
        XCTAssertEqual(HomeTimePhase(hour: 11), .morning)
        XCTAssertEqual(HomeTimePhase(hour: 12), .afternoon)
        XCTAssertEqual(HomeTimePhase(hour: 16), .afternoon)
        XCTAssertEqual(HomeTimePhase(hour: 17), .evening)
        XCTAssertEqual(HomeTimePhase(hour: 20), .evening)
        XCTAssertEqual(HomeTimePhase(hour: 21), .night)
        XCTAssertEqual(HomeTimePhase.allCases, [.dawn, .morning, .afternoon, .evening, .night])
    }

    func testEventTraceMappingUsesAvailableSceneAssets() {
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "nose_mark_on_window")?.assetName, "TraceNoseMarkWindow")
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "paper_bag_crumpled")?.assetName, "TracePaperBag")
        XCTAssertEqual(HomeSceneTrace.resolve(visualTraceID: "toy_returned_to_rug")?.assetName, "TraceToyMoved")
        XCTAssertNil(HomeSceneTrace.resolve(visualTraceID: "blanket_new_fold"))
    }

    func testTraceResolverKeepsRecentUniqueVisibleTraces() {
        let traces = HomeSceneTrace.resolveMany([
            "paper_bag_crumpled",
            "nose_mark_on_window",
            "paper_bag_crumpled",
            "toy_returned_to_rug"
        ])

        XCTAssertEqual(traces.map(\.assetName), ["TracePaperBag", "TraceNoseMarkWindow", "TraceToyMoved"])
    }

    func testEventTracesResolveToTheirSceneObjectStates() {
        let traces = HomeSceneTrace.resolveMany([
            "paper_bag_crumpled",
            "nose_mark_on_window",
            "toy_returned_to_rug"
        ])
        let states = HomeSceneObjectState.resolve(from: traces)

        XCTAssertEqual(states.first { $0.objectID == .paperBag }?.visualState, .paperBagCrumpled)
        XCTAssertEqual(states.first { $0.objectID == .curtain }?.visualState, .windowMarked)
        XCTAssertEqual(states.first { $0.objectID == .toyArea }?.visualState, .toyMoved)
        XCTAssertEqual(states.first { $0.objectID == .dogBed }?.visualState, .unchanged)

        for trace in traces {
            let object = HomeSceneObjectSpec.livingRoomSpec(for: trace.objectID)
            XCTAssertEqual(trace.x, object.normalizedX)
            XCTAssertEqual(trace.y, object.normalizedY)
        }
    }

    func testDaylightProfilesProgressFromSunPatchToNightTint() {
        XCTAssertGreaterThan(HomeTimePhase.afternoon.ambient.sunPatchOpacity, HomeTimePhase.evening.ambient.sunPatchOpacity)
        XCTAssertEqual(HomeTimePhase.night.ambient.sunPatchOpacity, 0)
        XCTAssertGreaterThan(HomeTimePhase.night.ambient.tintOpacity, HomeTimePhase.morning.ambient.tintOpacity)
        XCTAssertLessThan(HomeTimePhase.night.ambient.dogSaturation, HomeTimePhase.afternoon.ambient.dogSaturation)
    }

    func testLivingRoomObjectsHaveUniqueInBoundsInteractionRegions() {
        let objects = HomeSceneObjectSpec.livingRoom

        XCTAssertEqual(Set(objects.map(\.id)).count, HomeSceneObjectID.allCases.count)
        for object in objects {
            XCTAssertTrue(0 ... 1 ~= object.normalizedX)
            XCTAssertTrue(0 ... 1 ~= object.normalizedY)
            XCTAssertGreaterThan(object.interactionRadius, 0)
            XCTAssertLessThanOrEqual(object.interactionRadius, 0.20)
        }
    }

    func testAutonomyPhasesFocusTheExpectedSceneObject() {
        XCTAssertEqual(HomeAutonomyPhase.resting.focusedObjectID, .dogBed)
        XCTAssertEqual(HomeAutonomyPhase.noticingCurtain.focusedObjectID, .curtain)
        XCTAssertEqual(HomeAutonomyPhase.rising.focusedObjectID, .curtain)
        XCTAssertEqual(HomeAutonomyPhase.movingToWindow.focusedObjectID, .curtain)
        XCTAssertEqual(HomeAutonomyPhase.observingWindow.focusedObjectID, .curtain)
    }

    @MainActor
    func testObjectStateChangesTriggerACharacterReaction() {
        let model = HomeLifePresentationModel()
        let initialToken = model.cueToken

        model.present(sceneObjectStates: [
            HomeSceneObjectState(objectID: .toyArea, visualState: .toyMoved)
        ])
        XCTAssertEqual(model.cue, .wagTail)
        XCTAssertEqual(model.cueToken, initialToken + 1)

        model.present(sceneObjectStates: [
            HomeSceneObjectState(objectID: .paperBag, visualState: .paperBagCrumpled)
        ])
        XCTAssertEqual(model.cue, .turnEar)
        XCTAssertEqual(model.cueToken, initialToken + 2)
    }

    func testEveryBehaviorHasAStablePoseAndAutonomousAlternatives() {
        for behavior in DogBehavior.allCases {
            let poses = HomeIdlePlanner.poses(for: behavior)
            XCTAssertEqual(poses.first, behavior.visualPose)
            if behavior == .sleeping {
                XCTAssertEqual(poses, [.lieRest])
            } else {
                XCTAssertGreaterThan(poses.count, 1)
            }
        }
    }

    func testSleepingNeverSwitchesToAnAwakePose() {
        XCTAssertEqual(HomeIdlePlanner.poses(for: .sleeping), [.lieRest])
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

    func testCurtainInvestigationFormsACompleteCausalSequence() {
        var snapshot = HomeAutonomySnapshot.resting

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .curtainMoved)
        XCTAssertEqual(snapshot.phase, .noticingCurtain)
        XCTAssertEqual(snapshot.anchor, .rugCenter)
        XCTAssertEqual(snapshot.pose, .lieAlert)
        XCTAssertEqual(snapshot.cue, .turnEar)

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .stimulusConfirmed)
        XCTAssertEqual(snapshot.phase, .rising)
        XCTAssertEqual(snapshot.pose, .standTurn)
        XCTAssertEqual(snapshot.cue, .lookBack)

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .stoodUp)
        XCTAssertEqual(snapshot.phase, .movingToWindow)
        XCTAssertEqual(snapshot.anchor, .window)
        XCTAssertEqual(snapshot.pose, .walkA)

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .advancedStep)
        XCTAssertEqual(snapshot.pose, .walkB)

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .advancedStep)
        XCTAssertEqual(snapshot.pose, .walkA)

        snapshot = HomeAutonomyReducer.reduce(snapshot, signal: .reachedWindow)
        XCTAssertEqual(snapshot.phase, .observingWindow)
        XCTAssertEqual(snapshot.anchor, .window)
        XCTAssertEqual(snapshot.pose, .sitWindow)
        XCTAssertEqual(snapshot.cue, .blink)
    }

    func testAutonomyReducerIgnoresOutOfOrderSignals() {
        let snapshot = HomeAutonomyReducer.reduce(.resting, signal: .reachedWindow)
        XCTAssertEqual(snapshot, .resting)
    }

    func testSceneAnchorsCreateVisibleMovementAndDepth() {
        XCTAssertNotEqual(HomeSceneAnchor.rugCenter.horizontalOffset, HomeSceneAnchor.window.horizontalOffset)
        XCTAssertNotEqual(HomeSceneAnchor.rugCenter.scale, HomeSceneAnchor.window.scale)
        XCTAssertGreaterThan(HomeSceneAnchor.transit.scale, HomeSceneAnchor.rugCenter.scale)
        XCTAssertGreaterThan(HomeSceneAnchor.transit.scale, HomeSceneAnchor.window.scale)
    }

    func testPoseScaleKeepsWideRestingArtworkFromAppearingOversized() {
        XCTAssertLessThan(DogVisualPose.lieRest.homeDisplayScale, DogVisualPose.sitWindow.homeDisplayScale)
        XCTAssertLessThan(DogVisualPose.lieAlert.homeDisplayScale, DogVisualPose.sitWindow.homeDisplayScale)
        XCTAssertLessThan(DogVisualPose.standTurn.homeDisplayScale, DogVisualPose.sitWindow.homeDisplayScale)
    }

    @MainActor
    func testOnlineResponsesMapToReactionPoseAndCue() {
        let cases: [(DogResponseMotion, DogVisualPose, DogAnimationCue)] = [
            (.turnEar, .sitWindow, .turnEar),
            (.lookBack, .standTurn, .lookBack),
            (.wagTail, .sitWindow, .wagTail),
            (.settle, .lieRest, .blink)
        ]

        for (motion, expectedPose, expectedCue) in cases {
            let model = HomeLifePresentationModel()
            model.present(response: OnlineCompanionResponse(motion: motion, text: "test"))
            XCTAssertEqual(model.pose, expectedPose)
            XCTAssertEqual(model.cue, expectedCue)
            XCTAssertEqual(model.cueToken, 1)
        }
    }
}
