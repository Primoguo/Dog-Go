import Foundation
import Observation

enum HomeTimePhase: String, CaseIterable, Sendable {
    case morning
    case afternoon
    case evening
    case night

    init(date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }

    init(hour: Int) {
        switch hour {
        case 5 ... 10: self = .morning
        case 11 ... 16: self = .afternoon
        case 17 ... 20: self = .evening
        default: self = .night
        }
    }

    var caption: String {
        switch self {
        case .morning: "晨光刚刚爬上窗沿。"
        case .afternoon: "阳光落在耳朵上，窗帘轻轻动了一下。"
        case .evening: "城市慢慢暗下来，房间还留着一点暖色。"
        case .night: "窗外安静了，房间只剩柔和的光。"
        }
    }
}

struct HomeSceneTrace: Equatable, Sendable {
    let assetName: String
    let x: Double
    let y: Double
    let width: Double

    static func resolve(visualTraceID: String?) -> HomeSceneTrace? {
        guard let visualTraceID else { return nil }
        if visualTraceID.contains("nose_mark") {
            return HomeSceneTrace(assetName: "TraceNoseMarkWindow", x: 0.60, y: 0.36, width: 0.10)
        }
        if visualTraceID.contains("paper_bag") {
            return HomeSceneTrace(assetName: "TracePaperBag", x: 0.72, y: 0.68, width: 0.20)
        }
        if visualTraceID.contains("toy") {
            return HomeSceneTrace(assetName: "TraceToyMoved", x: 0.34, y: 0.69, width: 0.18)
        }
        return nil
    }
}

enum HomeIdlePlanner {
    static let poseChangeMomentRange = 2 ... 3

    static func poses(for behavior: DogBehavior) -> [DogVisualPose] {
        switch behavior {
        case .sleeping: [.lieRest, .sitWindow]
        case .observing: [.sitWindow, .standTurn, .lieRest]
        case .playing: [.playBow, .standTurn, .sitWindow]
        }
    }

    static let cues: [DogAnimationCue] = [.blink, .turnEar, .lookBack, .wagTail]
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

@MainActor
@Observable
final class HomeLifePresentationModel {
    private(set) var pose = DogVisualPose.sitWindow
    private(set) var cue: DogAnimationCue?
    private(set) var cueToken = 0

    private var behavior = DogBehavior.observing
    private var idleTask: Task<Void, Never>?
    private var idleMomentsBeforePoseChange = 2

    func start(behavior: DogBehavior, reduceMotion: Bool) {
        stop()
        self.behavior = behavior
        pose = behavior.visualPose
        idleMomentsBeforePoseChange = Int.random(in: HomeIdlePlanner.poseChangeMomentRange)
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
        idleTask = nil
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
}
