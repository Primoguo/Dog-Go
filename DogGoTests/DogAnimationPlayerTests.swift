import XCTest
@testable import DogGo

final class DogAnimationPlayerTests: XCTestCase {
    func testEveryPoseMapsToACompleteAssetSet() {
        for pose in DogVisualPose.allCases {
            let assets = pose.assets
            XCTAssertFalse(assets.full.isEmpty)
            XCTAssertEqual(assets.shadow, "\(assets.full)Shadow")
            XCTAssertEqual(assets.earNear, "\(assets.full)EarNear")
            XCTAssertEqual(assets.earFar, "\(assets.full)EarFar")
            XCTAssertEqual(assets.eyesClosed, "\(assets.full)EyesClosed")
            XCTAssertEqual(assets.tail, "\(assets.full)Tail")
            XCTAssertEqual(assets.head, "\(assets.full)Head")
        }
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
