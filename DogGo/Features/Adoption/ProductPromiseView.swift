import SwiftUI

struct ProductPromiseView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DogGoTheme.Colors.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(DogGoTheme.Colors.ochre)
                    .accessibilityHidden(true)

                Text("它有自己的生活")
                    .font(DogGoTheme.Typography.title)
                    .foregroundStyle(DogGoTheme.Colors.ink)
                    .padding(.top, DogGoTheme.Spacing.medium)

                Text("你不在的时候，栗子也会观察窗外、整理小毯子，认真度过属于它的时间。")
                    .font(DogGoTheme.Typography.body)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                    .lineSpacing(7)
                    .padding(.top, DogGoTheme.Spacing.small)

                Text("它不会因为你的离开而责怪你。")
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.olive)
                    .padding(.top, DogGoTheme.Spacing.large)

                Button(action: onContinue) {
                    Text("认识栗子")
                        .font(DogGoTheme.Typography.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(DogGoTheme.Colors.olive)
                        .foregroundStyle(DogGoTheme.Colors.canvas)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 36)
                .accessibilityHint("进入领养流程")
            }
            .padding(.horizontal, DogGoTheme.Spacing.page)
            .padding(.bottom, 44)
        }
    }
}

#Preview {
    ProductPromiseView(onContinue: {})
}
