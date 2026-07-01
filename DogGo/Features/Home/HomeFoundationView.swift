import SwiftData
import SwiftUI

struct HomeFoundationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var states: [DogState]
    @Query(sort: \LifeEventRecord.occurredAt, order: .reverse) private var events: [LifeEventRecord]

    let dog: DogProfile

    @State private var showingMoments = false
    @State private var loadError: String?
    @State private var showingQuietCompany = false
    @State private var showingOurDays = false
    @State private var presentation = HomeLifePresentationModel()
    @State private var interactionReaction: String?
    @State private var reactionTask: Task<Void, Never>?
#if DEBUG
    @State private var showingDebugPanel = false
#endif

    init(dog: DogProfile) {
        self.dog = dog
        let dogID = dog.id
        _states = Query(filter: #Predicate<DogState> { $0.dogID == dogID })
        _events = Query(filter: #Predicate<LifeEventRecord> { $0.dogID == dogID }, sort: \LifeEventRecord.occurredAt, order: .reverse)
    }

    private var unreadEvents: [LifeEventRecord] { events.filter { !$0.isViewed } }
    private var sceneTraces: [HomeSceneTrace] {
        HomeSceneTrace.resolveMany(events.compactMap(\.visualTraceID))
    }
    private var currentBehavior: DogBehavior {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-autonomyPreview") {
            return .observing
        }
#endif
        return states.first?.currentBehavior ?? .observing
    }

    var body: some View {
        ZStack {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                HomeSpriteSceneView(
                    input: DogSpriteSceneInput(
                        pose: presentation.pose,
                        cue: presentation.cue,
                        cueToken: presentation.cueToken,
                        anchor: presentation.anchor,
                        phase: presentation.autonomyPhase,
                        timePhase: HomeTimePhase(date: context.date),
                        reduceMotion: reduceMotion,
                        traces: sceneTraces
                    )
                )
            }

            VStack(spacing: 0) {
                HStack {
#if DEBUG
                    Button { showingDebugPanel = true } label: {
                        Image(systemName: "wrench.and.screwdriver")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                            .background(DogGoTheme.Colors.canvas.opacity(0.74))
                            .clipShape(Circle())
                    }
                    .foregroundStyle(DogGoTheme.Colors.olive)
                    .buttonStyle(.plain)
                    .accessibilityLabel("打开生活调试台")
#endif
                    Spacer()
                    Button { showingOurDays = true } label: {
                        Label("我们的日子", systemImage: "book.closed")
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(DogGoTheme.Colors.olive)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(DogGoTheme.Colors.canvas.opacity(0.74))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 36)

                Text(
                    currentBehavior == .observing
                        ? "\(dog.name)\(presentation.autonomyPhase.title)"
                        : "\(dog.name)正在\(currentBehavior.title)"
                )
                    .font(DogGoTheme.Typography.headline)
                    .foregroundStyle(DogGoTheme.Colors.ink)

                Color.clear
                .frame(height: 230)

                Text(
                    currentBehavior == .observing
                        ? presentation.autonomyPhase.observation
                        : HomeTimePhase(date: .now).caption
                )
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(DogGoTheme.Colors.canvas.opacity(0.72))
                    .clipShape(Capsule())
                    .padding(.top, 36)
                    .animation(.easeInOut(duration: 0.25), value: presentation.autonomyPhase)

                Spacer()

                if let interactionReaction {
                    Text(interactionReaction)
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(DogGoTheme.Colors.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(DogGoTheme.Colors.canvas.opacity(0.84))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.bottom, 10)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let loadError {
                    VStack(spacing: 8) {
                        Text(loadError)
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(.red.opacity(0.75))
                        Button("重新尝试") { Task { await refreshLife() } }
                            .font(DogGoTheme.Typography.button)
                            .foregroundStyle(DogGoTheme.Colors.olive)
                    }
                    .padding(.bottom, 12)
                    .accessibilityElement(children: .combine)
                }

                Button {
                    showingMoments = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("你不在时 · \(unreadEvents.count) 个片段")
                                .font(DogGoTheme.Typography.body)
                            Text(unreadEvents.isEmpty ? "今天的片段都看过了" : "看看它刚刚经历了什么")
                                .font(DogGoTheme.Typography.caption)
                                .opacity(0.72)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(DogGoTheme.Colors.ink)
                    .padding(18)
                    .background(DogGoTheme.Colors.canvas.opacity(0.78))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(events.isEmpty)

                HStack(spacing: 10) {
                    interactionButton("叫名字", systemImage: "waveform", interaction: .callName)
                    interactionButton("轻轻摸摸", systemImage: "hand.raised", interaction: .gentlePet)
                }
                .padding(.top, 12)

                Button("一起待会儿") {
                    respond(to: .quietCompany)
                    showingQuietCompany = true
                }
                    .font(DogGoTheme.Typography.button)
                    .foregroundStyle(DogGoTheme.Colors.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(DogGoTheme.Colors.olive)
                    .clipShape(Capsule())
                    .padding(.top, 10)
                    .accessibilityHint("进入安静陪伴")
            }
            .padding(.horizontal, DogGoTheme.Spacing.page)
            .padding(.bottom, 32)
        }
        .task {
            await refreshLife()
            presentation.start(behavior: currentBehavior, reduceMotion: reduceMotion)
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-quietCompanyPreview") {
                showingQuietCompany = true
            }
#endif
        }
        .onChange(of: currentBehavior) { _, behavior in
            presentation.update(behavior: behavior, reduceMotion: reduceMotion)
        }
        .onChange(of: reduceMotion) { _, value in
            presentation.start(behavior: currentBehavior, reduceMotion: value)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await refreshLife() }
        }
        .sheet(isPresented: $showingMoments) {
            LifeMomentsInboxView(events: events, dogName: dog.name)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingQuietCompany) {
            QuietCompanionView(dogName: dog.name)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingOurDays) {
            OurDaysView(dogID: dog.id, dogName: dog.name)
                .presentationDetents([.large])
        }
#if DEBUG
        .sheet(isPresented: $showingDebugPanel) {
            DebugPanelView(dog: dog)
                .presentationDetents([.large])
        }
#endif
        .onDisappear {
            presentation.stop()
            reactionTask?.cancel()
        }
    }

    @MainActor
    private func refreshLife() async {
        loadError = nil
        do {
            _ = try FirstExperienceService().ensureFirstMeeting(for: dog, in: modelContext)
            if let state = states.first {
                _ = try OfflineLifeSimulationService().simulate(
                    for: dog,
                    state: state,
                    in: modelContext
                )
            }
        } catch {
            loadError = "暂时没能准备好今天的片段。"
        }
    }

    private func interactionButton(
        _ title: String,
        systemImage: String,
        interaction: OnlineInteraction
    ) -> some View {
        Button {
            respond(to: interaction)
        } label: {
            Label(title, systemImage: systemImage)
                .font(DogGoTheme.Typography.button)
                .foregroundStyle(DogGoTheme.Colors.olive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(DogGoTheme.Colors.canvas.opacity(0.80))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func respond(to interaction: OnlineInteraction) {
        guard let state = states.first else { return }
        let response = OnlineCompanionService().respond(
            to: interaction,
            dogName: dog.name,
            mood: state.mood,
            energy: state.energy,
            socialTendency: state.socialTendency,
            roll: Double.random(in: 0 ..< 1)
        )
        presentation.present(response: response)
        reactionTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            interactionReaction = response.text
        }
        reactionTask = Task {
            try? await Task.sleep(for: .seconds(3.2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    interactionReaction = nil
                }
            }
        }
    }
}

private struct HomeSceneBackdrop: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let phase = HomeTimePhase(date: context.date)
            GeometryReader { proxy in
                ZStack {
                    Image("SceneHomeBase")
                        .resizable()
                        .scaledToFill()
                        .brightness(phase.ambient.brightness)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    phase.tint.opacity(phase.ambient.tintOpacity)
                    DogGoTheme.Colors.canvas.opacity(0.06)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private extension HomeTimePhase {
    var tint: Color {
        switch self {
        case .morning: Color(red: 0.97, green: 0.87, blue: 0.66)
        case .afternoon: Color(red: 0.91, green: 0.72, blue: 0.36)
        case .evening: Color(red: 0.79, green: 0.52, blue: 0.36)
        case .night: Color(red: 0.24, green: 0.32, blue: 0.38)
        }
    }

}

private struct QuietCompanionView: View {
    @Environment(\.dismiss) private var dismiss

    let dogName: String

    var body: some View {
        ZStack {
            DogGoTheme.Colors.canvas.ignoresSafeArea()
            VStack(spacing: 22) {
                DogAnimationPlayerView(
                    pose: .lieRest,
                    cue: .blink,
                    cueToken: 1,
                    accessibilityLabel: "\(dogName)安静地趴在你身边"
                )
                .frame(height: 170)

                Text("和\(dogName)一起待会儿")
                    .font(DogGoTheme.Typography.headline)
                    .foregroundStyle(DogGoTheme.Colors.ink)

                Text("什么都不用做。听一会儿房间里的声音就好。")
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                    .multilineTextAlignment(.center)

                Button("结束陪伴") { dismiss() }
                    .font(DogGoTheme.Typography.button)
                    .foregroundStyle(DogGoTheme.Colors.olive)
            }
            .padding(DogGoTheme.Spacing.page)
        }
    }
}

private extension DogBehavior {
    var title: String {
        switch self {
        case .sleeping: "睡觉"
        case .observing: "观察窗外"
        case .playing: "玩自己的玩具"
        }
    }

}
