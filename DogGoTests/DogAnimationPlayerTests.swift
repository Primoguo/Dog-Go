import XCTest
@testable import DogGo

final class DogAnimationPlayerTests: XCTestCase {
    func testEveryPoseMapsToACompleteAssetSet() {
        for pose in DogVisualPose.allCases {
            let assets = pose.assets
            XCTAssertFalse(assets.full.isEmpty)
            if assets.usesLayeredAnimation {
                XCTAssertEqual(assets.shadow, "\(assets.full)Shadow")
                XCTAssertEqual(assets.earNear, "\(assets.full)EarNear")
                XCTAssertEqual(assets.earFar, "\(assets.full)EarFar")
                XCTAssertEqual(assets.eyesClosed, "\(assets.full)EyesClosed")
                XCTAssertEqual(assets.tail, "\(assets.full)Tail")
                XCTAssertEqual(assets.head, "\(assets.full)Head")
            }
        }
    }

    func testFirstAutonomyPosesUseApprovedChestnutAssets() {
        XCTAssertEqual(DogVisualPose.lieRest.assets.full, "ChestnutRestUnifiedV2")
        XCTAssertEqual(DogVisualPose.lieAlert.assets.full, "ChestnutRestAlertV2")
        XCTAssertEqual(DogVisualPose.standTurn.assets.full, "ChestnutStandTurn")
        XCTAssertEqual(DogVisualPose.walkA.assets.full, "ChestnutWalkA")
        XCTAssertEqual(DogVisualPose.walkB.assets.full, "ChestnutWalkB")
        XCTAssertEqual(DogVisualPose.sitWindow.assets.full, "ChestnutSitWindow")
        XCTAssertEqual(DogVisualPose.playBow.assets.full, "ChestnutStandTurn")
        XCTAssertFalse(DogVisualPose.lieRest.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.lieAlert.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.standTurn.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.walkA.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.walkB.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.sitWindow.assets.usesLayeredAnimation)
        XCTAssertFalse(DogVisualPose.playBow.assets.usesLayeredAnimation)
    }

    func testCuesUseIndependentBodyChannels() {
        XCTAssertEqual(DogAnimationCue.blink.channel, .eyes)
        XCTAssertEqual(DogAnimationCue.turnEar.channel, .ears)
        XCTAssertEqual(DogAnimationCue.wagTail.channel, .tail)
        XCTAssertEqual(DogAnimationCue.lookBack.channel, .head)
        XCTAssertEqual(Set(DogAnimationCue.allCases.map(\.channel)).count, 4)
    }

    func testPriorityOrderMatchesAnimationSpecification() {
        XCTAssertLessThan(DogAnimationPriority.idle, .environment)
        XCTAssertLessThan(DogAnimationPriority.environment, .interaction)
        XCTAssertLessThan(DogAnimationPriority.interaction, .event)
    }

    @MainActor
    func testHomeSceneKeepsStableCanvasDuringSheetPresentation() {
        let scene = HomeSpriteScene(size: CGSize(width: 430, height: 932))

        XCTAssertEqual(scene.scaleMode, .aspectFill)
        XCTAssertEqual(scene.size, CGSize(width: 430, height: 932))
    }

    func testSpriteSceneMapsAutonomyPhasesToBaseAnimationStates() {
        func state(for phase: HomeAutonomyPhase) -> DogSpriteAnimationState {
            DogSpriteSceneInput(
                pose: .lieRest,
                cue: .blink,
                cueToken: 1,
                anchor: .rugCenter,
                phase: phase,
                timePhase: .morning,
                reduceMotion: false,
                traces: []
            ).baseAnimationState
        }

        XCTAssertEqual(state(for: .resting), .rest)
        XCTAssertEqual(state(for: .noticingCurtain), .rest)
        XCTAssertEqual(state(for: .rising), .idle)
        XCTAssertEqual(state(for: .movingToWindow), .walk)
        XCTAssertEqual(state(for: .observingWindow), .observe)
    }

    @MainActor
    func testReactionReturnsToRestStateAfterCueFinishes() async {
        let scene = HomeSpriteScene(size: CGSize(width: 430, height: 932))
        scene.apply(DogSpriteSceneInput(
            pose: .lieRest,
            cue: .blink,
            cueToken: 1,
            anchor: .rugCenter,
            phase: .resting,
            timePhase: .morning,
            reduceMotion: false,
            traces: []
        ))

        XCTAssertEqual(scene.animationState, .reaction)
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(scene.animationState, .rest)
    }

    @MainActor
    func testIndependentCuesCanRunAtTheSameTime() async {
        let model = DogAnimationPlayerModel()

        model.trigger(.turnEar, reduceMotion: true)
        model.trigger(.wagTail, reduceMotion: true)
        await Task.yield()

        XCTAssertNotEqual(model.earRotation, 0)
        XCTAssertNotEqual(model.tailRotation, 0)
        model.stop()
    }

    @MainActor
    func testLowerPriorityCueDoesNotInterruptEventCue() async {
        let model = DogAnimationPlayerModel()

        model.trigger(.turnEar, priority: .event, reduceMotion: false)
        await Task.yield()
        model.trigger(.turnEar, priority: .idle, reduceMotion: false)

        XCTAssertEqual(model.earRotation, 7)
        model.stop()
    }
}
