import Foundation

enum OnlineInteraction: CaseIterable, Sendable {
    case callName
    case gentlePet
    case quietCompany
}

enum DogResponseMotion: Equatable, Sendable {
    case turnEar
    case lookBack
    case wagTail
    case settle
}

struct OnlineCompanionResponse: Equatable, Sendable {
    let motion: DogResponseMotion
    let text: String
}

struct OnlineCompanionService {
    func respond(
        to interaction: OnlineInteraction,
        dogName: String,
        mood: DogMood,
        energy: DogEnergy,
        socialTendency: SocialTendency,
        roll: Double
    ) -> OnlineCompanionResponse {
        switch interaction {
        case .callName:
            if socialTendency == .nearUser || roll < 0.45 {
                return OnlineCompanionResponse(
                    motion: .lookBack,
                    text: "\(dogName)回过头，确认是你在叫它。"
                )
            }
            return OnlineCompanionResponse(
                motion: .turnEar,
                text: "它的一只耳朵转向你，目光还留在窗外。"
            )

        case .gentlePet:
            if socialTendency == .solitary || mood == .low {
                return OnlineCompanionResponse(
                    motion: .settle,
                    text: "它轻轻挪了半步，又在离你不远的地方趴下。"
                )
            }
            if mood == .happy || mood == .excited || roll < 0.60 {
                return OnlineCompanionResponse(
                    motion: .wagTail,
                    text: "它没有抬头，尾巴却轻轻碰了两下地面。"
                )
            }
            return OnlineCompanionResponse(
                motion: .lookBack,
                text: "它眯了一下眼，安静地接受了这次触碰。"
            )

        case .quietCompany:
            let text = energy == .active
                ? "它绕着垫子走了一圈，最后在你附近停下。"
                : "它慢慢放松下来，房间里只剩下呼吸声。"
            return OnlineCompanionResponse(motion: .settle, text: text)
        }
    }
}
