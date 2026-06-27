import SwiftUI

struct HomeFoundationView: View {
    let dogName: String

    var body: some View {
        ZStack {
            DogGoTheme.Colors.canvas.ignoresSafeArea()

            VStack(spacing: DogGoTheme.Spacing.medium) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(DogGoTheme.Colors.ochre)
                    .accessibilityHidden(true)

                Text("\(dogName)正在观察窗外")
                    .font(DogGoTheme.Typography.headline)
                    .foregroundStyle(DogGoTheme.Colors.ink)

                Text("阳光落在它的耳朵上，窗帘轻轻动了一下。")
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
            }
            .padding(DogGoTheme.Spacing.page)
        }
    }
}

#Preview {
    HomeFoundationView(dogName: "栗子")
}
