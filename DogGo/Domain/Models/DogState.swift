import Foundation
import SwiftData

enum DogMood: String, Codable, CaseIterable {
    case low
    case calm
    case happy
    case excited
}

enum DogEnergy: String, Codable, CaseIterable {
    case resting
    case normal
    case active
}

enum SocialTendency: String, Codable, CaseIterable {
    case solitary
    case neutral
    case nearUser
}

enum CuriosityLevel: String, Codable, CaseIterable {
    case cautious
    case neutral
    case exploring
}

enum DogBehavior: String, Codable, CaseIterable {
    case sleeping
    case observing
    case playing
}

@Model
final class DogState {
    var id: UUID
    var moodRawValue: String
    var energyRawValue: String
    var socialTendencyRawValue: String
    var curiosityRawValue: String
    var currentBehaviorRawValue: String
    var lastSimulatedAt: Date

    init(
        id: UUID = UUID(),
        mood: DogMood = .calm,
        energy: DogEnergy = .normal,
        socialTendency: SocialTendency = .neutral,
        curiosity: CuriosityLevel = .exploring,
        currentBehavior: DogBehavior = .observing,
        lastSimulatedAt: Date = .now
    ) {
        self.id = id
        self.moodRawValue = mood.rawValue
        self.energyRawValue = energy.rawValue
        self.socialTendencyRawValue = socialTendency.rawValue
        self.curiosityRawValue = curiosity.rawValue
        self.currentBehaviorRawValue = currentBehavior.rawValue
        self.lastSimulatedAt = lastSimulatedAt
    }

    var mood: DogMood { DogMood(rawValue: moodRawValue) ?? .calm }
    var energy: DogEnergy { DogEnergy(rawValue: energyRawValue) ?? .normal }
    var socialTendency: SocialTendency { SocialTendency(rawValue: socialTendencyRawValue) ?? .neutral }
    var curiosity: CuriosityLevel { CuriosityLevel(rawValue: curiosityRawValue) ?? .neutral }
    var currentBehavior: DogBehavior { DogBehavior(rawValue: currentBehaviorRawValue) ?? .observing }
}
