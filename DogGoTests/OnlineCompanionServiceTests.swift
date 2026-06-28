import XCTest
@testable import DogGo

final class OnlineCompanionServiceTests: XCTestCase {
    private let service = OnlineCompanionService()

    func testCallingNearbyDogProducesVisibleLookBack() {
        let response = service.respond(
            to: .callName,
            dogName: "栗子",
            mood: .calm,
            energy: .normal,
            socialTendency: .nearUser,
            roll: 0.9
        )
        XCTAssertEqual(response.motion, .lookBack)
        XCTAssertTrue(response.text.contains("栗子"))
    }

    func testCallingIndependentDogCanProduceSubtleEarResponse() {
        let response = service.respond(
            to: .callName,
            dogName: "栗子",
            mood: .calm,
            energy: .normal,
            socialTendency: .solitary,
            roll: 0.9
        )
        XCTAssertEqual(response.motion, .turnEar)
    }

    func testGentlePetRespectsLowMoodWithoutPunishment() {
        let response = service.respond(
            to: .gentlePet,
            dogName: "栗子",
            mood: .low,
            energy: .resting,
            socialTendency: .solitary,
            roll: 0.2
        )
        XCTAssertEqual(response.motion, .settle)
        XCTAssertFalse(response.text.contains("生气"))
        XCTAssertFalse(response.text.contains("失望"))
    }

    func testQuietCompanySettlesWithoutRewardLanguage() {
        let response = service.respond(
            to: .quietCompany,
            dogName: "栗子",
            mood: .calm,
            energy: .normal,
            socialTendency: .neutral,
            roll: 0.5
        )
        XCTAssertEqual(response.motion, .settle)
        XCTAssertFalse(response.text.contains("奖励"))
    }
}

