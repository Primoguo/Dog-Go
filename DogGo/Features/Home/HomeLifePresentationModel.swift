import Foundation
import Observation

enum HomeTimePhase: String, CaseIterable, Sendable {
    case dawn
    case morning
    case afternoon
    case evening
    case night

    init(date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    init(hour: Int) {
        switch hour {
        case 5 ... 7: self = .dawn
        case 8 ... 11: self = .morning
        case 12 ... 16: self = .afternoon
        case 17 ... 20: self = .evening
        default: self = .night
        }
    }

    var caption: String {
        switch self {
        case .dawn: "天刚亮，房间里还是柔和的晨光。"
        case .morning: "上午的阳光慢慢爬过窗沿。"
        case .afternoon: "阳光落在耳朵上，窗帘轻轻动了一下。"
        case .evening: "城市慢慢暗下来，房间还留着一点暖色。"
        case .night: "窗外安静了，房间只剩柔和的光。"
        }
    }

    static func resolved(date: Date, calendar: Calendar = .current) -> HomeTimePhase {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let flagIndex = arguments.firstIndex(of: "-homeTimePhase"),
           arguments.indices.contains(flagIndex + 1),
           let override = HomeTimePhase(rawValue: arguments[flagIndex + 1]) {
            return override
        }
#endif
        return HomeTimePhase(date: date, calendar: calendar)
    }
}

enum HomeSceneObjectID: String, CaseIterable, Sendable {
    case curtain
    case dogBed
    case toyArea
    case paperBag
}

struct HomeSceneObjectSpec: Equatable, Sendable {
    let id: HomeSceneObjectID
    let normalizedX: Double
    let normalizedY: Double
    let interactionRadius: Double

    static let livingRoom: [HomeSceneObjectSpec] = [
        HomeSceneObjectSpec(id: .curtain, normalizedX: 0.63, normalizedY: 0.31, interactionRadius: 0.12),
        HomeSceneObjectSpec(id: .dogBed, normalizedX: 0.29, normalizedY: 0.48, interactionRadius: 0.15),
        HomeSceneObjectSpec(id: .toyArea, normalizedX: 0.64, normalizedY: 0.54, interactionRadius: 0.14),
        HomeSceneObjectSpec(id: .paperBag, normalizedX: 0.78, normalizedY: 0.47, interactionRadius: 0.11)
    ]

    static func livingRoomSpec(for id: HomeSceneObjectID) -> HomeSceneObjectSpec {
        livingRoom.first { $0.id == id }!
    }
}

struct HomeSceneTrace: Equatable, Sendable {
    let assetName: String
    let x: Double
    let y: Double
    let width: Double

    var objectID: HomeSceneObjectID {
        switch assetName {
        case "TraceNoseMarkWindow": .curtain
        case "TracePaperBag": .paperBag
        case "TraceToyMoved": .toyArea
        default: .dogBed
        }
    }

    static func resolve(visualTraceID: String?) -> HomeSceneTrace? {
        guard let visualTraceID else { return nil }
        if visualTraceID.contains("nose_mark") {
            let object = HomeSceneObjectSpec.livingRoomSpec(for: .curtain)
            return HomeSceneTrace(assetName: "TraceNoseMarkWindow", x: object.normalizedX, y: object.normalizedY, width: 0.10)
        }
        if visualTraceID.contains("paper_bag") {
            let object = HomeSceneObjectSpec.livingRoomSpec(for: .paperBag)
            return HomeSceneTrace(assetName: "TracePaperBag", x: object.normalizedX, y: object.normalizedY, width: 0.13)
        }
        if visualTraceID.contains("toy") {
            let object = HomeSceneObjectSpec.livingRoomSpec(for: .toyArea)
            return HomeSceneTrace(assetName: "TraceToyMoved", x: object.normalizedX, y: object.normalizedY, width: 0.13)
        }
        return nil
    }

    static func resolveMany(_ visualTraceIDs: [String], limit: Int = 3) -> [HomeSceneTrace] {
        var seenAssets = Set<String>()
        return visualTraceIDs
            .compactMap(resolve(visualTraceID:))
            .filter { seenAssets.insert($0.assetName).inserted }
            .prefix(limit)
            .map { $0 }
    }
}

enum HomeSceneObjectVisualState: Equatable, Sendable {
    case unchanged
    case windowMarked
    case toyMoved
    case paperBagCrumpled
}

struct HomeSceneObjectState: Equatable, Sendable {
    let objectID: HomeSceneObjectID
    let visualState: HomeSceneObjectVisualState

    static func resolve(from traces: [HomeSceneTrace]) -> [HomeSceneObjectState] {
        let byObject = Dictionary(uniqueKeysWithValues: traces.map { trace in
            let state: HomeSceneObjectVisualState = switch trace.objectID {
            case .curtain: .windowMarked
            case .toyArea: .toyMoved
            case .paperBag: .paperBagCrumpled
            case .dogBed: .unchanged
            }
            return (trace.objectID, state)
        })
        return HomeSceneObjectID.allCases.map { objectID in
            HomeSceneObjectState(
                objectID: objectID,
                visualState: byObject[objectID] ?? .unchanged
            )
        }
    }
}

struct HomeAmbientProfile: Equatable, Sendable {
    let tintOpacity: Double
    let sunPatchOpacity: Double
    let brightness: Double
    let dogBrightness: Double
    let dogSaturation: Double
}

extension HomeTimePhase {
    var ambient: HomeAmbientProfile {
        switch self {
        case .dawn:
            HomeAmbientProfile(tintOpacity: 0.16, sunPatchOpacity: 0.24, brightness: 0.01, dogBrightness: 0.01, dogSaturation: 0.96)
        case .morning:
            HomeAmbientProfile(tintOpacity: 0.12, sunPatchOpacity: 0.48, brightness: 0.03, dogBrightness: 0.02, dogSaturation: 1)
        case .afternoon:
            HomeAmbientProfile(tintOpacity: 0.10, sunPatchOpacity: 0.68, brightness: 0, dogBrightness: 0, dogSaturation: 1)
        case .evening:
            HomeAmbientProfile(tintOpacity: 0.22, sunPatchOpacity: 0.24, brightness: -0.06, dogBrightness: -0.03, dogSaturation: 0.94)
        case .night:
            HomeAmbientProfile(tintOpacity: 0.48, sunPatchOpacity: 0, brightness: -0.18, dogBrightness: -0.10, dogSaturation: 0.82)
        }
    }
}

enum HomeIdlePlanner {
    static let poseChangeMomentRange = 2 ... 3

    static func poses(for behavior: DogBehavior) -> [DogVisualPose] {
        switch behavior {
        case .sleeping: [.lieRest]
        case .observing: [.sitWindow, .standTurn, .lieRest]
        case .playing: [.playBow, .standTurn, .sitWindow]
        }
    }

    static let cues: [DogAnimationCue] = [.blink, .turnEar, .lookBack, .wagTail]
}

enum HomeSceneAnchor: String, CaseIterable, Sendable {
    case rugCenter
    case transit
    case window

    var horizontalOffset: Double {
        switch self {
        // Scene 01 truth: the dog bed rests left-of-center and the window
        // observation point sits on the room's central sight line.
        case .rugCenter: -72
        case .transit: -34
        case .window: 0
        }
    }

    var verticalOffset: Double {
        switch self {
        case .rugCenter: -34
        case .transit: 24
        case .window: -46
        }
    }

    var scale: Double {
        switch self {
        case .rugCenter: 0.68
        case .transit: 0.82
        case .window: 0.64
        }
    }
}

enum HomeAutonomyPhase: String, CaseIterable, Sendable {
    case resting
    case noticingCurtain
    case rising
    case movingToWindow
    case observingWindow

    var focusedObjectID: HomeSceneObjectID {
        switch self {
        case .resting: .dogBed
        case .noticingCurtain, .rising, .movingToWindow, .observingWindow: .curtain
        }
    }

    var observation: String {
        switch self {
        case .resting: "房间很安静，它在地毯上休息。"
        case .noticingCurtain: "窗帘动了一下，它先转了转耳朵。"
        case .rising: "它抬起头，似乎想去确认一下。"
        case .movingToWindow: "它自己朝窗边走了过去。"
        case .observingWindow: "它在窗边坐下，安静地看着外面。"
        }
    }

    var title: String {
        switch self {
        case .resting: "正在休息"
        case .noticingCurtain: "留意到窗帘动了"
        case .rising: "准备去看看"
        case .movingToWindow: "正在走向窗边"
        case .observingWindow: "正在观察窗外"
        }
    }
}

struct HomeAutonomySnapshot: Equatable, Sendable {
    var phase: HomeAutonomyPhase
    var anchor: HomeSceneAnchor
    var pose: DogVisualPose
    var cue: DogAnimationCue?

    static let resting = HomeAutonomySnapshot(
        phase: .resting,
        anchor: .rugCenter,
        pose: .lieRest,
        cue: nil
    )
}

enum HomeAutonomySignal: Sendable {
    case curtainMoved
    case stimulusConfirmed
    case stoodUp
    case advancedStep
    case reachedWindow
}

enum HomeAutonomyReducer {
    static func reduce(_ snapshot: HomeAutonomySnapshot, signal: HomeAutonomySignal) -> HomeAutonomySnapshot {
        switch (snapshot.phase, signal) {
        case (.resting, .curtainMoved):
            HomeAutonomySnapshot(phase: .noticingCurtain, anchor: .rugCenter, pose: .lieAlert, cue: .turnEar)
        case (.noticingCurtain, .stimulusConfirmed):
            HomeAutonomySnapshot(phase: .rising, anchor: .rugCenter, pose: .standTurn, cue: .lookBack)
        case (.rising, .stoodUp):
            HomeAutonomySnapshot(phase: .movingToWindow, anchor: .window, pose: .walkA, cue: nil)
        case (.movingToWindow, .advancedStep):
            HomeAutonomySnapshot(
                phase: .movingToWindow,
                anchor: .window,
                pose: snapshot.pose == .walkA ? .walkB : .walkA,
                cue: nil
            )
        case (.movingToWindow, .reachedWindow):
            HomeAutonomySnapshot(phase: .observingWindow, anchor: .window, pose: .sitWindow, cue: .blink)
        default:
            snapshot
        }
    }
}

extension DogBehavior {
    var visualPose: DogVisualPose {
        switch self {
        case .sleeping: .lieRest
        case .observing: .sitWindow
        case .playing: .playBow
        }
    }
}

extension DogVisualPose {
    var homeDisplayScale: Double {
        switch self {
        case .lieRest: 0.84
        case .lieAlert: 0.78
        case .standTurn: 0.86
        case .walkA, .walkB: 0.88
        case .sitWindow: 1
        case .playBow: 0.86
        }
    }
}

@MainActor
@Observable
final class HomeLifePresentationModel {
    private(set) var pose = DogVisualPose.sitWindow
    private(set) var cue: DogAnimationCue?
    private(set) var cueToken = 0
    private(set) var anchor = HomeSceneAnchor.rugCenter
    private(set) var autonomyPhase = HomeAutonomyPhase.resting

    private var behavior = DogBehavior.observing
    private var idleTask: Task<Void, Never>?
    private var autonomyTask: Task<Void, Never>?
    private var idleMomentsBeforePoseChange = 2

    func start(behavior: DogBehavior, reduceMotion: Bool) {
        stop()
        self.behavior = behavior
        pose = behavior.visualPose
        anchor = behavior == .observing ? .rugCenter : .window
        autonomyPhase = .resting
        idleMomentsBeforePoseChange = Int.random(in: HomeIdlePlanner.poseChangeMomentRange)

        if behavior == .observing {
            startCurtainInvestigation(reduceMotion: reduceMotion)
            return
        }

        guard !reduceMotion else { return }

        idleTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 5 ... 9)))
                guard !Task.isCancelled, let self else { return }
                self.advanceIdleMoment()
            }
        }
    }

    func update(behavior: DogBehavior, reduceMotion: Bool) {
        guard behavior != self.behavior else { return }
        start(behavior: behavior, reduceMotion: reduceMotion)
    }

    func stop() {
        idleTask?.cancel()
        autonomyTask?.cancel()
        idleTask = nil
        autonomyTask = nil
    }

    func present(response: OnlineCompanionResponse) {
        switch response.motion {
        case .turnEar:
            cue = .turnEar
        case .lookBack:
            pose = .standTurn
            cue = .lookBack
        case .wagTail:
            cue = .wagTail
        case .settle:
            pose = .lieRest
            cue = .blink
        }
        cueToken += 1
    }

    func present(sceneObjectStates: [HomeSceneObjectState]) {
        if sceneObjectStates.contains(where: { $0.visualState == .paperBagCrumpled }) {
            cue = .turnEar
            cueToken += 1
        } else if sceneObjectStates.contains(where: { $0.visualState == .toyMoved }) {
            cue = .wagTail
            cueToken += 1
        }
    }

    private func advanceIdleMoment() {
        idleMomentsBeforePoseChange -= 1
        if idleMomentsBeforePoseChange <= 0 {
            let options = HomeIdlePlanner.poses(for: behavior).filter { $0 != pose }
            if let nextPose = options.randomElement() {
                pose = nextPose
                cue = .lookBack
                cueToken += 1
            }
            idleMomentsBeforePoseChange = Int.random(in: HomeIdlePlanner.poseChangeMomentRange)
            return
        }

        cue = HomeIdlePlanner.cues.randomElement()
        cueToken += 1
    }

    private func startCurtainInvestigation(reduceMotion: Bool) {
        apply(.resting)
#if DEBUG
        if let debugSnapshot = debugAutonomySnapshot {
            apply(debugSnapshot)
            return
        }
#endif
        autonomyTask = Task { [weak self] in
            let previewingAutonomy: Bool
#if DEBUG
            previewingAutonomy = ProcessInfo.processInfo.arguments.contains("-autonomyPreview")
#else
            previewingAutonomy = false
#endif
            let recordingPreview = ProcessInfo.processInfo.arguments.contains("-autonomyRecordingPreview")
            let initialDelay = recordingPreview
                ? 12.0
                : (previewingAutonomy ? 3.0 : (reduceMotion ? 1.5 : Double.random(in: 7 ... 11)))
            try? await Task.sleep(for: .seconds(initialDelay))
            guard !Task.isCancelled, let self else { return }
            self.advanceAutonomy(with: .curtainMoved)

            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 700))
            guard !Task.isCancelled else { return }
            self.advanceAutonomy(with: .stimulusConfirmed)

            try? await Task.sleep(for: .milliseconds(reduceMotion ? 250 : 850))
            guard !Task.isCancelled else { return }
            self.advanceAutonomy(with: .stoodUp)

            if reduceMotion {
                try? await Task.sleep(for: .milliseconds(300))
            } else {
                for _ in 0 ..< 4 {
                    try? await Task.sleep(for: .milliseconds(360))
                    guard !Task.isCancelled else { return }
                    self.advanceAutonomy(with: .advancedStep)
                }
                try? await Task.sleep(for: .milliseconds(360))
            }
            guard !Task.isCancelled else { return }
            self.advanceAutonomy(with: .reachedWindow)
        }
    }

    private func advanceAutonomy(with signal: HomeAutonomySignal) {
        let snapshot = HomeAutonomyReducer.reduce(currentSnapshot, signal: signal)
        apply(snapshot)
    }

    private var currentSnapshot: HomeAutonomySnapshot {
        HomeAutonomySnapshot(phase: autonomyPhase, anchor: anchor, pose: pose, cue: cue)
    }

    private func apply(_ snapshot: HomeAutonomySnapshot) {
        autonomyPhase = snapshot.phase
        anchor = snapshot.anchor
        pose = snapshot.pose
        cue = snapshot.cue
        if snapshot.cue != nil {
            cueToken += 1
        }
    }

#if DEBUG
    private var debugAutonomySnapshot: HomeAutonomySnapshot? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(of: "-autonomyStage") else { return nil }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }

        switch arguments[valueIndex] {
        case "resting":
            return .resting
        case "noticing", "noticingCurtain":
            return HomeAutonomySnapshot(
                phase: .noticingCurtain,
                anchor: .rugCenter,
                pose: .lieAlert,
                cue: .turnEar
            )
        case "rising":
            return HomeAutonomySnapshot(
                phase: .rising,
                anchor: .rugCenter,
                pose: .standTurn,
                cue: nil
            )
        case "walking":
            return HomeAutonomySnapshot(
                phase: .movingToWindow,
                anchor: .transit,
                pose: .walkA,
                cue: nil
            )
        case "observing":
            return HomeAutonomySnapshot(
                phase: .observingWindow,
                anchor: .window,
                pose: .sitWindow,
                cue: .blink
            )
        default:
            return nil
        }
    }
#endif
}
