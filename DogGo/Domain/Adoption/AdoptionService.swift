import Foundation
import SwiftData

@MainActor
struct AdoptionService {
    @discardableResult
    func adopt(
        name input: String,
        in modelContext: ModelContext,
        clock: some DogGoClock = SystemClock()
    ) throws -> DogProfile {
        let name = try DogNameValidator.validated(input)
        let dog = DogProfile(name: name, adoptedAt: clock.now)
        let state = DogState(dogID: dog.id, lastSimulatedAt: clock.now)
        let relationship = Relationship(dogID: dog.id, updatedAt: clock.now)

        modelContext.insert(dog)
        modelContext.insert(state)
        modelContext.insert(relationship)

        do {
            try modelContext.save()
            return dog
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
