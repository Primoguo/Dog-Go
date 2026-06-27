import SwiftUI

struct LifeMomentsInboxView: View {
    @Environment(\.dismiss) private var dismiss

    let events: [LifeEventRecord]
    let dogName: String

    var body: some View {
        NavigationStack {
            ZStack {
                DogGoTheme.Colors.canvas.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(events) { event in
                            NavigationLink {
                                LifeMomentView(event: event, dogName: dogName)
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: event.emotionSymbolName)
                                        .foregroundStyle(DogGoTheme.Colors.ochre)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(event.factSnapshot?.text ?? "\(dogName)度过了一小段自己的时间。")
                                            .font(DogGoTheme.Typography.body)
                                            .foregroundStyle(DogGoTheme.Colors.ink)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Text(event.occurredAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(DogGoTheme.Typography.caption)
                                            .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                                    }

                                    Spacer(minLength: 4)

                                    if !event.isViewed {
                                        Circle()
                                            .fill(DogGoTheme.Colors.ochre)
                                            .frame(width: 7, height: 7)
                                            .accessibilityLabel("未读")
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                                }
                                .padding(18)
                                .background(DogGoTheme.Colors.ink.opacity(0.055))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DogGoTheme.Spacing.page)
                }
            }
            .navigationTitle("你不在时")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
