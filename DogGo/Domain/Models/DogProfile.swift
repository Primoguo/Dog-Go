import Foundation
import SwiftData

@Model
final class DogProfile {
    var id: UUID
    var name: String
    var breed: String
    var adoptedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        breed: String = "shibaInu",
        adoptedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.breed = breed
        self.adoptedAt = adoptedAt
    }
}
