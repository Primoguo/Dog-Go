import SwiftData
import SwiftUI

@main
struct DogGoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            DogProfile.self,
            DogState.self,
            LifeEventRecord.self,
            MemoryRecord.self,
            Relationship.self
        ])
    }
}
