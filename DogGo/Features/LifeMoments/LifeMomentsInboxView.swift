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
                        if events.isEmpty {
                            ContentUnavailableView(
                                "还没有新片段",
                                systemImage: "moon.zzz",
                                description: Text("等你下次回来，\(dogName)也许会有新故事。")
                            )
                        }
                        ForEach(events) { event in
                            NavigationLink {
                                LifeMomentView(event: event, dogName: dogName)
                            } label: {
                                VStack(alignment: .leading, spacing: 0) {
                                    EventVisualThumbnail(event: event, dogName: dogName)
                                        .frame(height: 176)
                                        .overlay(alignment: .topTrailing) {
                                            if !event.isViewed {
                                                Text("新片段")
                                                    .font(DogGoTheme.Typography.caption)
                                                    .foregroundStyle(DogGoTheme.Colors.canvas)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(DogGoTheme.Colors.ochre)
                                                    .clipShape(Capsule())
                                                    .padding(12)
                                            }
                                        }

                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Label(event.emotionTitle, systemImage: event.emotionSymbolName)
                                                .font(DogGoTheme.Typography.caption)
                                                .foregroundStyle(DogGoTheme.Colors.olive)
                                            Text(event.factSnapshot?.text ?? "\(dogName)度过了一小段自己的时间。")
                                                .font(DogGoTheme.Typography.body)
                                                .foregroundStyle(DogGoTheme.Colors.ink)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)

                                            Text(event.occurredAt.formatted(date: .abbreviated, time: .shortened))
                                                .font(DogGoTheme.Typography.caption)
                                                .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                                        }

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                                    }
                                    .padding(16)
                                }
                                .background(DogGoTheme.Colors.ink.opacity(0.055))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
