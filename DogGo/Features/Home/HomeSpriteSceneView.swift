import SpriteKit
import SwiftUI

enum DogSpriteAnimationState: String, CaseIterable, Sendable {
    case idle
    case rest
    case walk
    case observe
    case reaction
}

struct DogSpriteSceneInput: Equatable, Sendable {
    let pose: DogVisualPose
    let cue: DogAnimationCue?
    let cueToken: Int
    let anchor: HomeSceneAnchor
    let phase: HomeAutonomyPhase
    let timePhase: HomeTimePhase
    let reduceMotion: Bool
    let traces: [HomeSceneTrace]

    var baseAnimationState: DogSpriteAnimationState {
        return switch phase {
        case .resting, .noticingCurtain: .rest
        case .rising: .idle
        case .movingToWindow: .walk
        case .observingWindow: .observe
        }
    }
}

@MainActor
final class HomeSpriteScene: SKScene {
    private enum Layer {
        static let background: CGFloat = -100
        static let traces: CGFloat = -30
        static let shadow: CGFloat = 5
        static let dog: CGFloat = 10
        static let foreground: CGFloat = 30
        static let lighting: CGFloat = 50
    }

    private let backgroundNode = SKSpriteNode(imageNamed: "SceneHomeBase")
    private let traceLayer = SKNode()
    private let environmentLayer = SKNode()
    private let curtainBreezeNode = SKShapeNode()
    private let dogRoot = SKNode()
    private let contactShadowNode = SKShapeNode(ellipseOf: CGSize(width: 112, height: 25))
    private let bodyNode = SKSpriteNode()
    private let foregroundLayer = SKNode()
    private let dogBedFrontNode = SKSpriteNode(imageNamed: "SceneHomeDogBedFront")
    private let sunPatchNode = SKShapeNode()
    private let lightingNode = SKSpriteNode(color: .clear, size: .zero)
    private let restOpenTexture = SKTexture(imageNamed: "ChestnutRestUnifiedV2")
    private let restBlinkTexture = SKTexture(imageNamed: "ChestnutRestBlinkV2")
    private let restEarTexture = SKTexture(imageNamed: "ChestnutRestEarV2")

    private(set) var animationState = DogSpriteAnimationState.idle
    private var currentInput: DogSpriteSceneInput?
    private var reactionTask: Task<Void, Never>?

    override init(size: CGSize) {
        super.init(size: size)
        // Keep one stable 430 × 932 logical canvas. Sheet presentation can
        // temporarily resize the underlying SpriteView; `.resizeFill` would then
        // mutate the scene coordinate space while nodes retain their old sizes,
        // making Chestnut appear almost full-screen behind the sheet.
        scaleMode = .aspectFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .clear
        configureGraph()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutScene()
        if let currentInput { positionDog(at: currentInput.anchor, animated: false) }
    }

    func apply(_ input: DogSpriteSceneInput) {
        let previous = currentInput
        currentInput = input
        updateLighting(for: input.timePhase)
        if previous?.traces != input.traces {
            updateTraces(input.traces)
        }
        if previous?.phase != input.phase {
            updateEnvironment(for: input.phase, reduceMotion: input.reduceMotion)
        }

        if previous?.pose != input.pose {
            bodyNode.removeAction(forKey: "cueTexture")
            let nextTexture = SKTexture(imageNamed: input.pose.assets.full)
            let isRestTransition = Set([previous?.pose, input.pose].compactMap { $0 })
                == Set([.lieRest, .lieAlert])
            if isRestTransition, !input.reduceMotion {
                bodyNode.run(.sequence([
                    .fadeAlpha(to: 0.90, duration: 0.10),
                    .setTexture(nextTexture, resize: false),
                    .fadeAlpha(to: 1, duration: 0.14)
                ]), withKey: "poseTransition")
            } else {
                bodyNode.texture = nextTexture
                fitBodyTexture()
                if previous != nil, !input.reduceMotion,
                   !Set([previous?.pose, input.pose].compactMap { $0 }).isSubset(of: [.walkA, .walkB]) {
                    bodyNode.alpha = 0.84
                    bodyNode.run(.fadeIn(withDuration: 0.16), withKey: "poseFade")
                }
            }
        }
        updateVisualLayers(for: input.pose)

        let anchorChanged = previous?.anchor != input.anchor
        let displayScaleChanged = previous?.pose.homeDisplayScale != input.pose.homeDisplayScale
        if anchorChanged || displayScaleChanged {
            positionDog(
                at: input.anchor,
                animated: !input.reduceMotion,
                duration: anchorChanged && input.phase == .movingToWindow ? 1.8 : 0.28
            )
        } else if previous == nil {
            positionDog(at: input.anchor, animated: false)
        }

        if previous?.baseAnimationState != input.baseAnimationState {
            enter(input.baseAnimationState, reduceMotion: input.reduceMotion)
        }

        if previous?.cueToken != input.cueToken, let cue = input.cue {
            play(cue, reduceMotion: input.reduceMotion)
        }
    }

    private func configureGraph() {
        backgroundNode.zPosition = Layer.background
        traceLayer.zPosition = Layer.traces
        environmentLayer.zPosition = Layer.traces + 1
        contactShadowNode.zPosition = -1
        dogRoot.zPosition = Layer.dog
        foregroundLayer.zPosition = Layer.foreground
        sunPatchNode.zPosition = Layer.lighting - 1
        lightingNode.zPosition = Layer.lighting

        contactShadowNode.fillColor = SKColor(white: 0, alpha: 0.12)
        contactShadowNode.strokeColor = .clear
        contactShadowNode.blendMode = .alpha

        bodyNode.name = "body"

        dogRoot.addChild(contactShadowNode)
        dogRoot.addChild(bodyNode)

        addChild(backgroundNode)
        addChild(traceLayer)
        addChild(environmentLayer)
        addChild(dogRoot)
        addChild(foregroundLayer)
        addChild(sunPatchNode)
        addChild(lightingNode)
        foregroundLayer.addChild(dogBedFrontNode)
        environmentLayer.addChild(curtainBreezeNode)
        layoutScene()
    }

    private func layoutScene() {
        guard size.width > 0, size.height > 0 else { return }
        let textureSize = backgroundNode.texture?.size() ?? CGSize(width: 1, height: 1)
        let scale = max(size.width / textureSize.width, size.height / textureSize.height)
        backgroundNode.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        backgroundNode.position = .zero
        let foregroundTextureSize = dogBedFrontNode.texture?.size() ?? textureSize
        let foregroundScale = max(size.width / foregroundTextureSize.width, size.height / foregroundTextureSize.height)
        dogBedFrontNode.size = CGSize(
            width: foregroundTextureSize.width * foregroundScale,
            height: foregroundTextureSize.height * foregroundScale
        )
        dogBedFrontNode.position = .zero
        lightingNode.size = size
        lightingNode.position = .zero
        let sunPath = CGMutablePath()
        sunPath.move(to: CGPoint(x: -size.width * 0.06, y: size.height * 0.20))
        sunPath.addLine(to: CGPoint(x: size.width * 0.34, y: size.height * 0.20))
        sunPath.addLine(to: CGPoint(x: size.width * 0.08, y: -size.height * 0.20))
        sunPath.addLine(to: CGPoint(x: -size.width * 0.34, y: -size.height * 0.20))
        sunPath.closeSubpath()
        sunPatchNode.path = sunPath
        sunPatchNode.fillColor = SKColor(red: 1, green: 0.82, blue: 0.42, alpha: 1)
        sunPatchNode.strokeColor = .clear
        sunPatchNode.blendMode = .add
        let breezePath = CGMutablePath()
        breezePath.move(to: CGPoint(x: size.width * 0.08, y: size.height * 0.17))
        breezePath.addCurve(
            to: CGPoint(x: size.width * 0.18, y: size.height * 0.12),
            control1: CGPoint(x: size.width * 0.12, y: size.height * 0.18),
            control2: CGPoint(x: size.width * 0.14, y: size.height * 0.11)
        )
        curtainBreezeNode.path = breezePath
        curtainBreezeNode.strokeColor = SKColor(white: 1, alpha: 0.24)
        curtainBreezeNode.lineWidth = 1.4
        curtainBreezeNode.lineCap = .round
        curtainBreezeNode.fillColor = .clear
    }

    private func fitBodyTexture() {
        guard let texture = bodyNode.texture else { return }
        let textureSize = texture.size()
        let maxSize = CGSize(width: size.width * 0.89, height: min(230, size.height * 0.25))
        let scale = min(maxSize.width / textureSize.width, maxSize.height / textureSize.height)
        bodyNode.size = CGSize(width: textureSize.width * scale, height: textureSize.height * scale)
        bodyNode.position = CGPoint(x: 0, y: bodyNode.size.height * 0.03)
        contactShadowNode.position = CGPoint(x: 0, y: -bodyNode.size.height * 0.34)
    }

    private func updateTraces(_ traces: [HomeSceneTrace]) {
        traceLayer.removeAllChildren()
        for trace in traces {
            let node = makeTraceNode(for: trace)
            node.position = CGPoint(
                x: (trace.x - 0.5) * size.width,
                y: (0.5 - trace.y) * size.height
            )
            traceLayer.addChild(node)
        }
    }

    private func updateEnvironment(for phase: HomeAutonomyPhase, reduceMotion: Bool) {
        curtainBreezeNode.removeAllActions()
        let isCurtainReaction = phase == .noticingCurtain
        curtainBreezeNode.isHidden = !isCurtainReaction
        guard isCurtainReaction, !reduceMotion else { return }
        curtainBreezeNode.alpha = 0.15
        curtainBreezeNode.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.65, duration: 0.7),
            .fadeAlpha(to: 0.15, duration: 0.9)
        ])), withKey: "curtainBreeze")
    }

    private func makeTraceNode(for trace: HomeSceneTrace) -> SKNode {
        let root = SKNode()
        let width = size.width * trace.width

        switch trace.assetName {
        case "TraceNoseMarkWindow":
            let smudge = SKShapeNode(ellipseOf: CGSize(width: width * 0.42, height: width * 0.32))
            smudge.fillColor = SKColor(white: 1, alpha: 0.10)
            smudge.strokeColor = SKColor(white: 1, alpha: 0.08)
            smudge.lineWidth = 1
            root.addChild(smudge)
            for x in [-0.14, 0.14] {
                let dot = SKShapeNode(circleOfRadius: width * 0.055)
                dot.fillColor = SKColor(white: 1, alpha: 0.13)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: width * x, y: width * 0.18)
                root.addChild(dot)
            }

        case "TracePaperBag":
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -width * 0.18, y: width * 0.06))
            path.addLine(to: CGPoint(x: -width * 0.04, y: -width * 0.05))
            path.addLine(to: CGPoint(x: width * 0.08, y: width * 0.04))
            path.addLine(to: CGPoint(x: width * 0.19, y: -width * 0.07))
            let crease = SKShapeNode(path: path)
            crease.strokeColor = SKColor(red: 0.38, green: 0.24, blue: 0.12, alpha: 0.16)
            crease.lineWidth = 1.2
            crease.lineCap = .round
            root.addChild(crease)

        default:
            for index in 0 ..< 3 {
                let dot = SKShapeNode(circleOfRadius: width * 0.035)
                dot.fillColor = SKColor(red: 0.45, green: 0.32, blue: 0.18, alpha: 0.12)
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: CGFloat(index - 1) * width * 0.18,
                    y: CGFloat((index % 2) * 2 - 1) * width * 0.05
                )
                root.addChild(dot)
            }
        }
        return root
    }

    private func updateVisualLayers(for pose: DogVisualPose) {
        let isRestingInBed = pose == .lieRest || pose == .lieAlert
        contactShadowNode.isHidden = isRestingInBed
        dogBedFrontNode.isHidden = !isRestingInBed
        bodyNode.position.y = bodyNode.size.height * (isRestingInBed ? 0.15 : 0.03)
    }

    private func positionDog(at anchor: HomeSceneAnchor, animated: Bool, duration: TimeInterval = 1.8) {
        let normalized: CGPoint = switch anchor {
        case .rugCenter: CGPoint(x: 0.30, y: 0.54)
        case .transit: CGPoint(x: 0.39, y: 0.52)
        case .window: CGPoint(x: 0.56, y: 0.60)
        }
        let target = CGPoint(
            x: (normalized.x - 0.5) * size.width,
            y: (normalized.y - 0.5) * size.height
        )
        let targetScale = anchor.scale * (currentInput?.pose.homeDisplayScale ?? 1)

        dogRoot.removeAction(forKey: "move")
        if animated {
            let move = SKAction.move(to: target, duration: duration)
            move.timingMode = .easeInEaseOut
            let scale = SKAction.scale(to: targetScale, duration: duration)
            scale.timingMode = .easeInEaseOut
            dogRoot.run(.group([move, scale]), withKey: "move")
        } else {
            dogRoot.position = target
            dogRoot.setScale(targetScale)
        }
    }

    private func enter(_ state: DogSpriteAnimationState, reduceMotion: Bool) {
        animationState = state
        dogRoot.removeAction(forKey: "state")
        bodyNode.removeAction(forKey: "state")
        guard !reduceMotion else { return }

        switch state {
        case .rest, .idle, .observe:
            let down = SKAction.scaleY(to: 0.992, duration: state == .rest ? 1.6 : 2.1)
            let up = SKAction.scaleY(to: 1.008, duration: state == .rest ? 1.6 : 2.1)
            down.timingMode = .easeInEaseOut
            up.timingMode = .easeInEaseOut
            bodyNode.run(.repeatForever(.sequence([down, up])), withKey: "state")
        case .walk:
            let lift = SKAction.moveBy(x: 0, y: 4, duration: 0.18)
            let land = lift.reversed()
            bodyNode.run(.repeatForever(.sequence([lift, land])), withKey: "state")
        case .reaction:
            break
        }
    }

    private func play(_ cue: DogAnimationCue, reduceMotion: Bool) {
        guard !reduceMotion else { return }
        reactionTask?.cancel()
        animationState = .reaction
        let reactionDuration: Duration
        switch cue {
        case .blink:
            reactionDuration = .milliseconds(260)
            if currentInput?.pose == .lieRest {
                bodyNode.run(.sequence([
                    .setTexture(restBlinkTexture, resize: false),
                    .wait(forDuration: 0.12),
                    .setTexture(restOpenTexture, resize: false)
                ]), withKey: "cueTexture")
            } else {
                bodyNode.run(.sequence([.fadeAlpha(to: 0.92, duration: 0.08), .fadeAlpha(to: 1, duration: 0.08)]))
            }
        case .turnEar:
            reactionDuration = .milliseconds(420)
            if currentInput?.pose == .lieRest {
                bodyNode.run(.sequence([
                    .setTexture(restEarTexture, resize: false),
                    .wait(forDuration: 0.22),
                    .setTexture(restOpenTexture, resize: false)
                ]), withKey: "cueTexture")
            } else {
                bodyNode.run(.sequence([.rotate(byAngle: 0.025, duration: 0.16), .rotate(byAngle: -0.025, duration: 0.22)]))
            }
        case .wagTail:
            reactionDuration = .milliseconds(520)
            bodyNode.run(.sequence([.rotate(byAngle: 0.035, duration: 0.12), .rotate(byAngle: -0.07, duration: 0.18), .rotate(byAngle: 0.035, duration: 0.12)]))
        case .lookBack:
            reactionDuration = .milliseconds(560)
            bodyNode.run(.sequence([.moveBy(x: 5, y: 4, duration: 0.2), .moveBy(x: -5, y: -4, duration: 0.28)]))
        }
        reactionTask = Task { [weak self] in
            try? await Task.sleep(for: reactionDuration)
            guard !Task.isCancelled, let self, let input = self.currentInput else { return }
            self.enter(input.baseAnimationState, reduceMotion: input.reduceMotion)
        }
    }

    private func updateLighting(for phase: HomeTimePhase) {
        let color: SKColor
        switch phase {
        case .morning: color = SKColor(red: 1, green: 0.90, blue: 0.70, alpha: 0.08)
        case .afternoon: color = SKColor(red: 1, green: 0.75, blue: 0.40, alpha: 0.06)
        case .evening: color = SKColor(red: 0.76, green: 0.42, blue: 0.25, alpha: 0.16)
        case .night: color = SKColor(red: 0.16, green: 0.24, blue: 0.34, alpha: 0.34)
        }
        lightingNode.color = color
        lightingNode.colorBlendFactor = 1
        sunPatchNode.alpha = CGFloat(phase.ambient.sunPatchOpacity * 0.10)
    }
}

struct HomeSpriteSceneView: View {
    @State private var scene = HomeSpriteScene(size: CGSize(width: 430, height: 932))

    let input: DogSpriteSceneInput

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .ignoresSafeArea()
            .task(id: input) { scene.apply(input) }
            .accessibilityHidden(true)
    }
}
