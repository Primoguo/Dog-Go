import Foundation
import SwiftData

@Model
final class DogProfile {
    var id: UUID
    var name: String
    var breed: String
    var adoptedAt: Date
    var traitWeightsData: Data

    init(
        id: UUID = UUID(),
        name: String,
        breed: String = "shibaInu",
        adoptedAt: Date = .now,
        traitWeights: [String: Double] = ["curious": 0.8, "tidy": 0.7]
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.adoptedAt = adoptedAt
        self.traitWeightsData = (try? JSONEncoder().encode(traitWeights)) ?? Data()
    }

    var traitWeights: [String: Double] {
        (try? JSONDecoder().decode([String: Double].self, from: traitWeightsData)) ?? [:]
    }
}
