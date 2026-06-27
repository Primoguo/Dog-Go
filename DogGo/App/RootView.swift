import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenProductPromise") private var hasSeenProductPromise = false

    var body: some View {
        Group {
            if hasSeenProductPromise {
                HomeFoundationView()
            } else {
                ProductPromiseView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasSeenProductPromise = true
                    }
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    RootView()
}
