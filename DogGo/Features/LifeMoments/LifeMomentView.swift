import SwiftData
import SwiftUI

struct LifeMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var event: LifeEventRecord

    let dogName: String

    @State private var reactionText: String?
    @State private var errorMessage: String?

    private var definition: EventDefinition? {
        try? EventCatalog.load().event(id: event.definitionID)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DogGoTheme.Colors.canvas.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Label(event.occurredAt.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(DogGoTheme.Colors.olive)

                        Text("刚刚发生的事")
                            .font(DogGoTheme.Typography.title)
                            .foregroundStyle(DogGoTheme.Colors.ink)
                            .padding(.top, 12)

                        Text(event.factSnapshot?.text ?? "\(dogName)度过了一小段自己的时间。")
                            .font(DogGoTheme.Typography.body)
                            .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                            .lineSpacing(8)
                            .padding(.top, 20)

                        if let reactionText {
                            Text(reactionText)
                                .font(DogGoTheme.Typography.body)
                                .foregroundStyle(DogGoTheme.Colors.ink)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DogGoTheme.Colors.ochre.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .padding(.top, 24)
                        } else if let responses = definition?.responses, !responses.isEmpty {
                            Text("你想怎么回应？")
                                .font(DogGoTheme.Typography.headline)
                                .foregroundStyle(DogGoTheme.Colors.ink)
                                .padding(.top, 34)

                            ForEach(responses) { response in
                                Button(response.label) { respond(with: response) }
                                    .font(DogGoTheme.Typography.button)
                                    .foregroundStyle(DogGoTheme.Colors.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18)
                                    .background(DogGoTheme.Colors.ink.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .padding(.top, 10)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(DogGoTheme.Typography.caption)
                                .foregroundStyle(.red.opacity(0.75))
                                .padding(.top, 12)
                        }
                    }
                    .padding(DogGoTheme.Spacing.page)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .task { markViewed() }
    }

    private func markViewed() {
        guard !event.isViewed else { return }
        event.isViewed = true
        try? modelContext.save()
    }

    private func respond(with response: ResponseDefinition) {
        guard event.selectedResponseID == nil, let definition else { return }
        event.selectedResponseID = response.id
        let tags = Array(Set(definition.memoryOutputTags + response.memoryTags)).sorted()
        modelContext.insert(
            MemoryRecord(
                dogID: event.dogID,
                sourceEventID: event.id,
                responseID: response.id,
                tags: tags
            )
        )

        do {
            try modelContext.save()
            reactionText = response.reactionText
        } catch {
            modelContext.rollback()
            errorMessage = "回应暂时没有保存，请再试一次。"
        }
    }
}
