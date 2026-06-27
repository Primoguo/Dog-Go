import SwiftData
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenProductPromise") private var hasSeenProductPromise = false
    @Query(sort: \DogProfile.adoptedAt) private var dogs: [DogProfile]

    var body: some View {
        Group {
            if !hasSeenProductPromise {
                ProductPromiseView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasSeenProductPromise = true
                    }
                }
            } else if let dog = dogs.first {
                HomeFoundationView(dog: dog)
            } else {
                AdoptionView()
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    RootView()
        .modelContainer(for: DogProfile.self, inMemory: true)
}
