import Observation
import SwiftUI

enum DogVisualPose: String, CaseIterable, Sendable {
    case sitWindow
    case lieRest
    case lieAlert
    case standTurn
    case walkA
    case walkB
    case playBow

    var assets: DogPoseAssets {
        switch self {
        case .sitWindow: DogPoseAssets(full: "ChestnutSitWindow")
        case .lieRest: DogPoseAssets(full: "ChestnutRestUnifiedV2")
        case .lieAlert: DogPoseAssets(full: "ChestnutRestAlertV2")
        case .standTurn: DogPoseAssets(full: "ChestnutStandTurn")
        case .walkA: DogPoseAssets(full: "ChestnutWalkA")
        case .walkB: DogPoseAssets(full: "ChestnutWalkB")
        // The approved play-bow asset has not been produced yet. Reuse the
        // new Chestnut standing pose so the app never falls back to the old,
        // photorealistic character during a playing state.
        case .playBow: DogPoseAssets(full: "ChestnutStandTurn")
        }
    }
}

struct DogPoseAssets: Equatable, Sendable {
    let full: String
    let shadow: String?
    let earNear: String?
    let earFar: String?
    let eyesClosed: String?
    let tail: String?
    let head: String?

    var usesLayeredAnimation: Bool { head != nil }

    init(full: String) {
        self.full = full
        shadow = nil
        earNear = nil
        earFar = nil
        eyesClosed = nil
        tail = nil
        head = nil
    }

    init(prefix: String) {
        full = prefix
        shadow = "\(prefix)Shadow"
        earNear = "\(prefix)EarNear"
        earFar = "\(prefix)EarFar"
        eyesClosed = "\(prefix)EyesClosed"
        tail = "\(prefix)Tail"
        head = "\(prefix)Head"
    }
}

enum DogAnimationCue: CaseIterable, Hashable, Sendable {
    case blink
    case turnEar
    case wagTail
    case lookBack

    var channel: DogAnimationChannel {
        switch self {
        case .blink: .eyes
        case .turnEar: .ears
        case .wagTail: .tail
        case .lookBack: .head
        }
    }
}

enum DogAnimationChannel: Hashable, Sendable {
    case eyes
    case ears
    case tail
    case head
}

enum DogAnimationPriority: Int, Comparable, Sendable {
    case idle
    case environment
    case interaction
    case event

    static func < (lhs: DogAnimationPriority, rhs: DogAnimationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@MainActor
@Observable
final class DogAnimationPlayerModel {
    private(set) var isBlinking = false
    private(set) var earRotation = 0.0
    private(set) var tailRotation = 0.0
    private(set) var headOffset = 0.0

    private struct ActiveCue {
        let id: UUID
        let priority: DogAnimationPriority
        let task: Task<Void, Never>
    }

    private var activeCues: [DogAnimationChannel: ActiveCue] = [:]
    private var idleTask: Task<Void, Never>?

    func startIdle(reduceMotion: Bool) {
        idleTask?.cancel()
        guard !reduceMotion else { return }
        idleTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 3.5 ... 8)))
                guard !Task.isCancelled else { return }
                self?.trigger(.blink, priority: .idle, reduceMotion: false)
                try? await Task.sleep(for: .seconds(Double.random(in: 2.5 ... 6)))
                guard !Task.isCancelled else { return }
                if Bool.random() {
                    self?.trigger(.turnEar, priority: .idle, reduceMotion: false)
                }
            }
        }
    }

    func stop() {
        activeCues.values.forEach { $0.task.cancel() }
        idleTask?.cancel()
        activeCues.removeAll()
        idleTask = nil
        reset()
    }

    func trigger(
        _ cue: DogAnimationCue,
        priority: DogAnimationPriority = .interaction,
        reduceMotion: Bool
    ) {
        let channel = cue.channel
        if let active = activeCues[channel], active.priority > priority {
            return
        }

        activeCues[channel]?.task.cancel()
        let cueID = UUID()
        let task = Task { [weak self] in
            await self?.run(cue, reduceMotion: reduceMotion)
            self?.finish(channel: channel, cueID: cueID)
        }
        activeCues[channel] = ActiveCue(id: cueID, priority: priority, task: task)
    }

    private func run(_ cue: DogAnimationCue, reduceMotion: Bool) async {
        let shortDelay = reduceMotion ? Duration.milliseconds(160) : .milliseconds(120)
        switch cue {
        case .blink:
            isBlinking = true
            try? await Task.sleep(for: shortDelay)
            isBlinking = false
        case .turnEar:
            earRotation = reduceMotion ? 3 : 7
            try? await Task.sleep(for: reduceMotion ? .milliseconds(180) : .milliseconds(280))
            earRotation = 0
        case .wagTail:
            guard !reduceMotion else {
                tailRotation = 4
                try? await Task.sleep(for: .milliseconds(180))
                tailRotation = 0
                return
            }
            for _ in 0 ..< 3 {
                tailRotation = 10
                try? await Task.sleep(for: .milliseconds(150))
                tailRotation = -8
                try? await Task.sleep(for: .milliseconds(150))
            }
            tailRotation = 0
        case .lookBack:
            headOffset = reduceMotion ? 2 : 8
            try? await Task.sleep(for: reduceMotion ? .milliseconds(180) : .milliseconds(620))
            headOffset = 0
        }
    }

    private func reset() {
        isBlinking = false
        earRotation = 0
        tailRotation = 0
        headOffset = 0
    }

    private func finish(channel: DogAnimationChannel, cueID: UUID) {
        guard activeCues[channel]?.id == cueID else { return }
        activeCues[channel] = nil
    }
}

struct DogAnimationPlayerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = DogAnimationPlayerModel()
    @State private var breathing = false

    let pose: DogVisualPose
    var cue: DogAnimationCue?
    var cueToken = 0
    var accessibilityLabel: String

    private var assets: DogPoseAssets { pose.assets }

    var body: some View {
        ZStack {
            if let shadow = assets.shadow {
                Image(shadow).resizable().scaledToFit()
            }

            Image(assets.full)
                .resizable()
                .scaledToFit()
                .contentTransition(.identity)

            if assets.usesLayeredAnimation {
                if let head = assets.head {
                    Image(head)
                        .resizable()
                        .scaledToFit()
                        .offset(x: model.headOffset)
                }
                if let earFar = assets.earFar {
                    Image(earFar)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(-model.earRotation), anchor: pose.earFarAnchor)
                }
                if let earNear = assets.earNear {
                    Image(earNear)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(model.earRotation), anchor: pose.earNearAnchor)
                }
                if let tail = assets.tail {
                    Image(tail)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(model.tailRotation), anchor: pose.tailAnchor)
                }
                if let eyesClosed = assets.eyesClosed {
                    Image(eyesClosed)
                        .resizable()
                        .scaledToFit()
                        .opacity(model.isBlinking ? 1 : 0)
                }
            }
        }
        .scaleEffect(
            reduceMotion ? 1 : (breathing ? 1.012 : 0.997),
            anchor: .bottom
        )
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 3.2).repeatForever(autoreverses: true),
            value: breathing
        )
        .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.24), value: model.earRotation)
        .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.15), value: model.tailRotation)
        .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.52), value: model.headOffset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .task(id: reduceMotion) {
            breathing = !reduceMotion
            model.startIdle(reduceMotion: reduceMotion)
        }
        .onChange(of: cueToken) { _, _ in
            guard let cue else { return }
            model.trigger(cue, reduceMotion: reduceMotion)
        }
        .onDisappear { model.stop() }
    }
}

private extension DogVisualPose {
    var earFarAnchor: UnitPoint {
        switch self {
        case .sitWindow: UnitPoint(x: 0.35, y: 0.20)
        case .lieRest, .lieAlert: UnitPoint(x: 0.22, y: 0.56)
        case .standTurn, .walkA, .walkB: UnitPoint(x: 0.16, y: 0.23)
        case .playBow: UnitPoint(x: 0.24, y: 0.61)
        }
    }

    var earNearAnchor: UnitPoint {
        switch self {
        case .sitWindow: UnitPoint(x: 0.41, y: 0.22)
        case .lieRest, .lieAlert: UnitPoint(x: 0.33, y: 0.58)
        case .standTurn, .walkA, .walkB: UnitPoint(x: 0.30, y: 0.24)
        case .playBow: UnitPoint(x: 0.35, y: 0.63)
        }
    }

    var tailAnchor: UnitPoint {
        switch self {
        case .sitWindow: UnitPoint(x: 0.68, y: 0.78)
        case .lieRest, .lieAlert: UnitPoint(x: 0.80, y: 0.80)
        case .standTurn, .walkA, .walkB: UnitPoint(x: 0.72, y: 0.28)
        case .playBow: UnitPoint(x: 0.72, y: 0.30)
        }
    }
}

#if DEBUG
private struct DogAnimationDebugPreview: View {
    @State private var pose = DogVisualPose.sitWindow
    @State private var cue: DogAnimationCue?
    @State private var cueToken = 0

    var body: some View {
        VStack(spacing: 18) {
            DogAnimationPlayerView(
                pose: pose,
                cue: cue,
                cueToken: cueToken,
                accessibilityLabel: "栗子动画预览"
            )
            .frame(height: 360)

            Picker("姿态", selection: $pose) {
                ForEach(DogVisualPose.allCases, id: \.self) { pose in
                    Text(pose.rawValue).tag(pose)
                }
            }

            HStack {
                cueButton("眨眼", .blink)
                cueButton("转耳", .turnEar)
                cueButton("摇尾", .wagTail)
                cueButton("回头", .lookBack)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(DogGoTheme.Colors.canvas)
    }

    private func cueButton(_ title: String, _ cue: DogAnimationCue) -> some View {
        Button(title) {
            self.cue = cue
            cueToken += 1
        }
    }
}

#Preview("Dog animation controls") {
    DogAnimationDebugPreview()
}
#endif
