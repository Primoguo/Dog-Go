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
    private var currentBehavior: DogBehavior { states.first?.currentBehavior ?? .observing }

    var body: some View {
        ZStack {
            HomeSceneBackdrop(visualTraceID: events.first?.visualTraceID)

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

                Text("\(dog.name)正在\(currentBehavior.title)")
                    .font(DogGoTheme.Typography.headline)
                    .foregroundStyle(DogGoTheme.Colors.ink)

                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let phase = HomeTimePhase(date: context.date)
                    DogAnimationPlayerView(
                        pose: presentation.pose,
                        cue: presentation.cue,
                        cueToken: presentation.cueToken,
                        accessibilityLabel: "\(dog.name)正在\(currentBehavior.title)"
                    )
                    .brightness(phase.dogBrightness)
                    .saturation(phase.dogSaturation)
                }
                .frame(height: 230)

                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(HomeTimePhase(date: context.date).caption)
                }
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(DogGoTheme.Colors.canvas.opacity(0.72))
                    .clipShape(Capsule())

                Spacer()

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

                Button("一起待会儿") { showingQuietCompany = true }
                    .font(DogGoTheme.Typography.button)
                    .foregroundStyle(DogGoTheme.Colors.canvas)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(DogGoTheme.Colors.olive)
                    .clipShape(Capsule())
                    .padding(.top, 14)
                    .accessibilityHint("进入安静陪伴")
            }
            .padding(.horizontal, DogGoTheme.Spacing.page)
            .padding(.bottom, 32)
        }
        .task {
            await refreshLife()
            presentation.start(behavior: currentBehavior, reduceMotion: reduceMotion)
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
        .onDisappear { presentation.stop() }
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
}

private struct HomeSceneBackdrop: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var curtainDrifting = false

    let visualTraceID: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let phase = HomeTimePhase(date: context.date)
            GeometryReader { proxy in
                ZStack {
                    Image("SceneHomeBase")
                        .resizable()
                        .scaledToFill()
                        .brightness(phase.brightness)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    if phase.sunPatchOpacity > 0 {
                        Image("SceneHomeSunPatch")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .opacity(phase.sunPatchOpacity)
                            .clipped()
                    }

                    if let trace = HomeSceneTrace.resolve(visualTraceID: visualTraceID) {
                        Image(trace.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width * trace.width)
                            .position(x: proxy.size.width * trace.x, y: proxy.size.height * trace.y)
                    }

                    Image("SceneHomeCurtainFront")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: reduceMotion ? 0 : (curtainDrifting ? 3 : -2))
                        .opacity(0.34)
                        .clipped()

                    phase.tint.opacity(phase.tintOpacity)
                    DogGoTheme.Colors.canvas.opacity(0.12)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { curtainDrifting = !reduceMotion }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 4.8).repeatForever(autoreverses: true),
            value: curtainDrifting
        )
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

    var tintOpacity: Double {
        switch self {
        case .morning: 0.12
        case .afternoon: 0.10
        case .evening: 0.22
        case .night: 0.48
        }
    }

    var sunPatchOpacity: Double {
        switch self {
        case .morning: 0.48
        case .afternoon: 0.68
        case .evening: 0.24
        case .night: 0
        }
    }

    var brightness: Double {
        switch self {
        case .morning: 0.03
        case .afternoon: 0
        case .evening: -0.06
        case .night: -0.18
        }
    }

    var dogBrightness: Double {
        switch self {
        case .morning: 0.02
        case .afternoon: 0
        case .evening: -0.03
        case .night: -0.10
        }
    }

    var dogSaturation: Double {
        switch self {
        case .morning, .afternoon: 1
        case .evening: 0.94
        case .night: 0.82
        }
    }
}

private struct QuietCompanionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breathing = false

    let dogName: String

    var body: some View {
        ZStack {
            DogGoTheme.Colors.canvas.ignoresSafeArea()
            VStack(spacing: 22) {
                Image(systemName: "dog.fill")
                    .font(.system(size: 68, weight: .ultraLight))
                    .foregroundStyle(DogGoTheme.Colors.ochre)
                    .scaleEffect(reduceMotion ? 1 : (breathing ? 1.025 : 0.99), anchor: .bottom)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 2.8).repeatForever(autoreverses: true),
                        value: breathing
                    )
                    .accessibilityHidden(true)

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
        .onAppear { breathing = true }
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
