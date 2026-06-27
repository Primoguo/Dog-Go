#if DEBUG
import SwiftData
import SwiftUI

struct DebugPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var states: [DogState]
    @Query private var events: [LifeEventRecord]
    @Query private var memories: [MemoryRecord]

    let dog: DogProfile

    @State private var isAdvancing = false
    @State private var resultMessage: String?
    @State private var errorMessage: String?

    init(dog: DogProfile) {
        self.dog = dog
        let dogID = dog.id
        _states = Query(filter: #Predicate<DogState> { $0.dogID == dogID })
        _events = Query(
            filter: #Predicate<LifeEventRecord> { $0.dogID == dogID },
            sort: \LifeEventRecord.occurredAt,
            order: .reverse
        )
        _memories = Query(filter: #Predicate<MemoryRecord> { $0.dogID == dogID })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DogGoTheme.Colors.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        statusSection
                        timeSection

                        if let resultMessage {
                            Label(resultMessage, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(DogGoTheme.Colors.olive)
                                .accessibilityIdentifier("debug-result")
                        }
                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red.opacity(0.78))
                                .accessibilityIdentifier("debug-error")
                        }
                    }
                    .font(DogGoTheme.Typography.caption)
                    .padding(DogGoTheme.Spacing.page)
                }
            }
            .navigationTitle("生活调试台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前状态")
                .font(DogGoTheme.Typography.headline)
                .foregroundStyle(DogGoTheme.Colors.ink)

            if let state = states.first {
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                    statusRow("行为", state.currentBehaviorRawValue)
                    statusRow("心情", state.moodRawValue)
                    statusRow("精力", state.energyRawValue)
                    statusRow("事件", "\(events.count)")
                    statusRow("记忆", "\(memories.count)")
                    statusRow("模拟至", state.lastSimulatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .foregroundStyle(DogGoTheme.Colors.secondaryInk)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DogGoTheme.Colors.ink.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityElement(children: .combine)
            } else {
                Label("没有找到狗狗状态", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red.opacity(0.78))
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推进时间")
                .font(DogGoTheme.Typography.headline)
                .foregroundStyle(DogGoTheme.Colors.ink)
            Text("使用可注入时钟触发真实离线模拟，不修改系统时间。")
                .foregroundStyle(DogGoTheme.Colors.secondaryInk)

            ForEach(DebugTimeJump.allCases) { jump in
                Button {
                    advance(by: jump)
                } label: {
                    HStack {
                        Label(jump.title, systemImage: jump.symbolName)
                        Spacer()
                        Text(jump.detail)
                            .opacity(0.65)
                    }
                    .foregroundStyle(DogGoTheme.Colors.ink)
                    .padding(17)
                    .background(DogGoTheme.Colors.ink.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isAdvancing || states.first == nil)
                .accessibilityHint("生成这个时间跨度内的离线生活片段")
            }
        }
    }

    private func statusRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(DogGoTheme.Colors.olive)
            Text(value).textSelection(.enabled)
        }
    }

    private func advance(by jump: DebugTimeJump) {
        guard let state = states.first else { return }
        isAdvancing = true
        resultMessage = nil
        errorMessage = nil

        do {
            let targetDate = state.lastSimulatedAt.addingTimeInterval(jump.interval)
            let result = try OfflineLifeSimulationService().simulate(
                for: dog,
                state: state,
                in: modelContext,
                clock: FixedClock(now: targetDate)
            )
            resultMessage = result.count == 0 ? "没有符合条件的新片段" : "生成了 \(result.count) 个新片段"
        } catch {
            errorMessage = "推进失败，请检查事件配置或存储状态。"
        }
        isAdvancing = false
    }
}

private enum DebugTimeJump: CaseIterable, Identifiable {
    case twentyMinutes
    case eightHours
    case oneDay

    var id: Self { self }

    var interval: TimeInterval {
        switch self {
        case .twentyMinutes: 20 * 60
        case .eightHours: 8 * 60 * 60
        case .oneDay: 24 * 60 * 60
        }
    }

    var title: String {
        switch self {
        case .twentyMinutes: "短暂离开"
        case .eightHours: "半天之后"
        case .oneDay: "一天之后"
        }
    }

    var detail: String {
        switch self {
        case .twentyMinutes: "+20 分钟"
        case .eightHours: "+8 小时"
        case .oneDay: "+24 小时"
        }
    }

    var symbolName: String {
        switch self {
        case .twentyMinutes: "clock"
        case .eightHours: "sun.horizon"
        case .oneDay: "moon.stars"
        }
    }
}
#endif
