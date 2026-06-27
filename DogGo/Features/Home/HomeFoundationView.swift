import SwiftData
import SwiftUI

struct HomeFoundationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var states: [DogState]
    @Query(sort: \LifeEventRecord.occurredAt, order: .reverse) private var events: [LifeEventRecord]

    let dog: DogProfile

    @State private var showingMoments = false
    @State private var loadError: String?
    @State private var showingQuietCompany = false
    @State private var showingOurDays = false

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
            DogGoTheme.Colors.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { showingOurDays = true } label: {
                        Label("我们的日子", systemImage: "book.closed")
                            .font(DogGoTheme.Typography.caption)
                            .foregroundStyle(DogGoTheme.Colors.olive)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(DogGoTheme.Colors.ink.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 36)

                Text("\(dog.name)正在\(currentBehavior.title)")
                    .font(DogGoTheme.Typography.headline)
                    .foregroundStyle(DogGoTheme.Colors.ink)

                Image(systemName: currentBehavior.symbolName)
                    .font(.system(size: 92, weight: .ultraLight))
                    .foregroundStyle(DogGoTheme.Colors.ochre)
                    .frame(height: 230)
                    .accessibilityLabel("\(dog.name)正在\(currentBehavior.title)")

                Text("阳光落在它的耳朵上，窗帘轻轻动了一下。")
                    .font(DogGoTheme.Typography.caption)
                    .foregroundStyle(DogGoTheme.Colors.secondaryInk)

                Spacer()

                if let loadError {
                    Text(loadError)
                        .font(DogGoTheme.Typography.caption)
                        .foregroundStyle(.red.opacity(0.75))
                        .padding(.bottom, 12)
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
                    .background(DogGoTheme.Colors.ink.opacity(0.06))
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
        .task { await refreshLife() }
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
    }

    @MainActor
    private func refreshLife() async {
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

    var symbolName: String {
        switch self {
        case .sleeping: "dog.fill"
        case .observing: "dog.fill"
        case .playing: "tennisball.fill"
        }
    }
}
