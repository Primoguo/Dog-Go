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

                        if event.definitionID == "first_short_leave" {
                            FirstShortLeaveReplay(dogName: dogName)
                                .padding(.top, 20)
                        }

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

                        if let memoryTags = event.factSnapshot?.referencedMemoryTags,
                           !memoryTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("它记得你们之间的事", systemImage: "bookmark.fill")
                                    .font(DogGoTheme.Typography.caption)
                                    .foregroundStyle(DogGoTheme.Colors.olive)
                                Text(memoryTags.map(\.memoryDisplayName).joined(separator: " · "))
                                    .font(DogGoTheme.Typography.body)
                                    .foregroundStyle(DogGoTheme.Colors.ink)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DogGoTheme.Colors.olive.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(.top, 24)
                        }

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
                                    .accessibilityHint("保存回应，并影响未来的生活片段")
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
        .accessibilityAction(named: "关闭片段") { dismiss() }
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

private struct FirstShortLeaveReplay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = LeaveReplayPhase.checkedDoor
    @State private var replayToken = 0

    let dogName: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottom) {
                Image("SceneHomeBase")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
                    .overlay(Color.black.opacity(0.08))

                DogAnimationPlayerView(
                    pose: phase.pose,
                    cue: phase.cue,
                    cueToken: phase.rawValue + replayToken * LeaveReplayPhase.allCases.count,
                    accessibilityLabel: phase.accessibilityLabel(dogName: dogName)
                )
                .frame(height: 205)
                .offset(x: phase.horizontalOffset, y: -36)

                Text(phase.caption(dogName: dogName))
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DogGoTheme.Colors.canvas.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(14)
                    .id(phase)
                    .transition(.opacity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack {
                HStack(spacing: 6) {
                    ForEach(LeaveReplayPhase.allCases, id: \.self) { item in
                        Capsule()
                            .fill(item == phase ? DogGoTheme.Colors.olive : DogGoTheme.Colors.ink.opacity(0.14))
                            .frame(width: item == phase ? 22 : 7, height: 7)
                    }
                }
                Spacer()
                Button("再看一次", systemImage: "arrow.counterclockwise") {
                    replayToken += 1
                    phase = .checkedDoor
                }
                .font(DogGoTheme.Typography.caption)
                .foregroundStyle(DogGoTheme.Colors.olive)
            }
        }
        .task(id: replayToken) {
            guard !reduceMotion else {
                phase = .returned
                return
            }
            for next in LeaveReplayPhase.allCases.dropFirst() {
                try? await Task.sleep(for: .seconds(1.8))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.35)) { phase = next }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("第一次短暂分别的画面回放")
    }
}

private enum LeaveReplayPhase: Int, CaseIterable, Sendable {
    case checkedDoor
    case returnedToWindow
    case livedQuietly
    case returned

    var pose: DogVisualPose {
        switch self {
        case .checkedDoor, .returned: .standTurn
        case .returnedToWindow: .sitWindow
        case .livedQuietly: .lieRest
        }
    }

    var cue: DogAnimationCue {
        switch self {
        case .checkedDoor: .turnEar
        case .returnedToWindow: .lookBack
        case .livedQuietly: .blink
        case .returned: .wagTail
        }
    }

    var horizontalOffset: CGFloat {
        switch self {
        case .checkedDoor: -44
        case .returnedToWindow: 32
        case .livedQuietly: 10
        case .returned: -12
        }
    }

    func caption(dogName: String) -> String {
        switch self {
        case .checkedDoor: "门外安静后，\(dogName)去确认了一会儿。"
        case .returnedToWindow: "随后，它自己回到了熟悉的窗边。"
        case .livedQuietly: "门垫歪了一点，日子仍安静地继续。"
        case .returned: "你回来时，它抬头、转耳，尾巴轻轻动了两下。"
        }
    }

    func accessibilityLabel(dogName: String) -> String { caption(dogName: dogName) }
}

extension String {
    var memoryDisplayName: String {
        switch self {
        case "first_meeting": "第一次见面"
        case "gentle_response": "温柔的回应"
        case "playful_response": "一起玩过的约定"
        case "quiet_response": "安静陪伴的时刻"
        default: replacingOccurrences(of: "_", with: " ")
        }
    }
}
