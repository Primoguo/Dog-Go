import SwiftData
import SwiftUI

struct OurDaysView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var events: [LifeEventRecord]
    @Query private var memories: [MemoryRecord]

    let dogName: String

    init(dogID: UUID, dogName: String) {
        self.dogName = dogName
        _events = Query(
            filter: #Predicate<LifeEventRecord> { $0.dogID == dogID },
            sort: \LifeEventRecord.occurredAt
        )
        _memories = Query(
            filter: #Predicate<MemoryRecord> { $0.dogID == dogID },
            sort: \MemoryRecord.createdAt
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DogGoTheme.Colors.canvas.ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if events.isEmpty {
                            ContentUnavailableView(
                                "日子正在开始",
                                systemImage: "pawprint",
                                description: Text("和\(dogName)相处过的片段，会慢慢留在这里。")
                            )
                        } else {
                            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                                timelineRow(event: event, isLast: index == events.count - 1)
                            }
                        }
                    }
                    .padding(DogGoTheme.Spacing.page)
                }
            }
            .navigationTitle("我们的日子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func timelineRow(event: LifeEventRecord, isLast: Bool) -> some View {
        let memory = memories.first { $0.sourceEventID == event.id }
        return NavigationLink {
            LifeMomentView(event: event, dogName: dogName)
        } label: {
            HStack(alignment: .top, spacing: 15) {
                VStack(spacing: 0) {
                    Circle()
                        .fill(event.selectedResponseID == nil ? DogGoTheme.Colors.ochre : DogGoTheme.Colors.olive)
                        .frame(width: 12, height: 12)
                    if !isLast {
                        Rectangle()
                            .fill(DogGoTheme.Colors.olive.opacity(0.22))
                            .frame(width: 1, height: 102)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(event.occurredAt.formatted(date: .abbreviated, time: .omitted))
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(DogGoTheme.Colors.olive)
                    Text(event.factSnapshot?.text ?? "\(dogName)度过了一小段自己的时间。")
                        .font(DogGoTheme.Typography.body)
                        .foregroundStyle(DogGoTheme.Colors.ink)
                        .multilineTextAlignment(.leading)
                    if event.definitionID == "first_meeting" {
                        milestone("第一次见面")
                    } else if event.definitionID == "first_short_leave" {
                        milestone("第一次短暂分别")
                    }
                    if event.selectedResponseID != nil {
                        milestone("你回应了它")
                    }
                    if let memory, !memory.referencedByEventIDs.isEmpty {
                        Text("后来被想起 \(memory.referencedByEventIDs.count) 次")
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                    }
                }
                .padding(.bottom, isLast ? 0 : 22)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func milestone(_ title: String) -> some View {
        Label(title, systemImage: "sparkles")
            .font(DogGoTheme.Typography.caption)
            .foregroundStyle(DogGoTheme.Colors.ochre)
    }
}
