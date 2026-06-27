import SwiftData
import SwiftUI

struct LifeMomentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var event: LifeEventRecord

    let dogName: String

    @State private var reactionText: String?
    @State private var errorMessage: String?
    @State private var isSavingResponse = false

    private var definition: EventDefinition? {
        try? EventCatalog.load().event(id: event.definitionID)
    }

    private var savedReactionText: String? {
        guard let selectedResponseID = event.selectedResponseID else { return nil }
        return definition?.responses.first { $0.id == selectedResponseID }?.reactionText
    }

    private var displayedReactionText: String? {
        reactionText ?? savedReactionText
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

                        VStack(alignment: .leading, spacing: 10) {
                            Label(event.emotionTitle, systemImage: event.emotionSymbolName)
                            if let trace = event.visualTraceTitle {
                                Label(trace, systemImage: "sparkle.magnifyingglass")
                            }
                        }
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(DogGoTheme.Colors.olive)
                        .padding(.top, 22)
                        .fixedSize(horizontal: false, vertical: true)

                        if let displayedReactionText {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("你的回应留下了影响")
                                    .font(DogGoTheme.Typography.caption)
                                    .foregroundStyle(DogGoTheme.Colors.olive)
                                Text(displayedReactionText)
                                    .font(DogGoTheme.Typography.body)
                                    .foregroundStyle(DogGoTheme.Colors.ink)
                            }
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
                                    .disabled(isSavingResponse)
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
        reactionText = response.reactionText
        isSavingResponse = true
        errorMessage = nil

        Task { @MainActor in
            await Task.yield()
            do {
                _ = try LifeMomentResponseService().save(
                    response: response,
                    for: event,
                    definition: definition,
                    in: modelContext
                )
            } catch {
                reactionText = nil
                errorMessage = "回应暂时没有保存，请再试一次。"
            }
            isSavingResponse = false
        }
    }
}
