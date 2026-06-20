//
//  MermaidEmotionComponent.swift
//  Ester
//

import CoreGraphics
import GameplayKit
import SpriteKit

enum MermaidEyeAsset: String {
    case open = "eye_open"
    case closed = "eye_closed"
    case half = "eye_half"
    case wide = "eye_wide"
}

enum MermaidMouthAsset: String {
    case neutral = "mouth_neutral"
    case smile = "mouth_smile"
    case open = "mouth_open"
    case o = "mouth_o"
    case frown = "mouth_frown"
    case pout = "mouth_pout"
    case sleepy = "mouth_sleepy"
    case chew = "mouth_chew"
}

enum MermaidEmotion: Equatable {
    case neutral
    case curious
    case happy
    case satisfied
    case hungry
    case eating
    case tired
    case scared
    case stubborn
    case focused
    case adventurous
    case surprised
    case sad
}

enum MermaidExpressionName: String, CaseIterable {
    case neutral
    case curious
    case happy
    case satisfied
    case hungry
    case eating
    case tired
    case scared
    case snob
    case focused
    case adventurous
    case surprised
    case sad
}

struct MermaidEyebrowExpression {
    var x: CGFloat
    var y: CGFloat
    var rotation: CGFloat

    init(x: CGFloat = 0, y: CGFloat = 0, rotation: CGFloat = 0) {
        self.x = x
        self.y = y
        self.rotation = rotation
    }
}

struct MermaidExpressionPreset {
    var eye: MermaidEyeAsset
    var mouth: MermaidMouthAsset
    var leftBrow: MermaidEyebrowExpression
    var rightBrow: MermaidEyebrowExpression
    var mouthX: CGFloat
    var mouthY: CGFloat
    var mouthScale: CGFloat

    init(eye: MermaidEyeAsset,
         mouth: MermaidMouthAsset,
         leftBrow: MermaidEyebrowExpression = MermaidEyebrowExpression(),
         rightBrow: MermaidEyebrowExpression = MermaidEyebrowExpression(),
         mouthX: CGFloat = 0,
         mouthY: CGFloat = 0,
         mouthScale: CGFloat = 1) {
        self.eye = eye
        self.mouth = mouth
        self.leftBrow = leftBrow
        self.rightBrow = rightBrow
        self.mouthX = mouthX
        self.mouthY = mouthY
        self.mouthScale = mouthScale
    }

    var pose: MermaidFacePose {
        MermaidFacePose(eyeAsset: eye,
                        mouthAsset: mouth,
                        leftEyebrowOffset: CGPoint(x: leftBrow.x, y: leftBrow.y),
                        rightEyebrowOffset: CGPoint(x: rightBrow.x, y: rightBrow.y),
                        leftEyebrowRotationDelta: leftBrow.rotation,
                        rightEyebrowRotationDelta: rightBrow.rotation,
                        mouthOffset: CGPoint(x: mouthX, y: mouthY),
                        mouthScale: mouthScale)
    }
}

enum MermaidExpressionLibrary {
    // Edit expressions here. Positive eyebrow y raises it; positive rotation
    // tilts the left brow clockwise and the right brow clockwise in local space.
    static var presets: [MermaidExpressionName: MermaidExpressionPreset] = [
        .neutral: MermaidExpressionPreset(eye: .open,
                                          mouth: .neutral),

        .curious: MermaidExpressionPreset(eye: .open,
                                          mouth: .smile,
                                          leftBrow: MermaidEyebrowExpression(y: 8, rotation: -5),
                                          rightBrow: MermaidEyebrowExpression(y: 1, rotation: -2)),

        .happy: MermaidExpressionPreset(eye: .open,
                                        mouth: .smile,
                                        leftBrow: MermaidEyebrowExpression(y: 5, rotation: -4),
                                        rightBrow: MermaidEyebrowExpression(y: 5, rotation: 4),
                                        mouthY: 2,
                                        mouthScale: 1.05),

        .satisfied: MermaidExpressionPreset(eye: .closed,
                                            mouth: .smile,
                                            leftBrow: MermaidEyebrowExpression(y: 3, rotation: -3),
                                            rightBrow: MermaidEyebrowExpression(y: 3, rotation: 3),
                                            mouthY: 1),

        .hungry: MermaidExpressionPreset(eye: .half,
                                         mouth: .open,
                                         leftBrow: MermaidEyebrowExpression(x: 1, y: -2, rotation: 7),
                                         rightBrow: MermaidEyebrowExpression(x: -1, y: -2, rotation: -7),
                                         mouthY: -1),

        .eating: MermaidExpressionPreset(eye: .half,
                                         mouth: .chew,
                                         leftBrow: MermaidEyebrowExpression(y: 1),
                                         rightBrow: MermaidEyebrowExpression(y: 1),
                                         mouthScale: 1.08),

        .tired: MermaidExpressionPreset(eye: .half,
                                        mouth: .sleepy,
                                        leftBrow: MermaidEyebrowExpression(y: -5, rotation: -2),
                                        rightBrow: MermaidEyebrowExpression(y: -5, rotation: 2),
                                        mouthY: -2),

        .scared: MermaidExpressionPreset(eye: .wide,
                                         mouth: .o,
                                         leftBrow: MermaidEyebrowExpression(x: -2, y: 13, rotation: -8),
                                         rightBrow: MermaidEyebrowExpression(x: 2, y: 13, rotation: 8),
                                         mouthScale: 1.08),

        .snob: MermaidExpressionPreset(eye: .half,
                                       mouth: .pout,
                                       leftBrow: MermaidEyebrowExpression(x: -2, y: 5, rotation: -12),
                                       rightBrow: MermaidEyebrowExpression(x: 2, y: -1, rotation: -8),
                                       mouthX: 2,
                                       mouthY: 1,
                                       mouthScale: 0.96),

        .focused: MermaidExpressionPreset(eye: .open,
                                          mouth: .neutral,
                                          leftBrow: MermaidEyebrowExpression(x: 2, y: -2, rotation: 4),
                                          rightBrow: MermaidEyebrowExpression(x: -2, y: -2, rotation: -4)),

        .adventurous: MermaidExpressionPreset(eye: .open,
                                              mouth: .smile,
                                              leftBrow: MermaidEyebrowExpression(x: -1, y: 4, rotation: -7),
                                              rightBrow: MermaidEyebrowExpression(x: 1, y: 2, rotation: 5),
                                              mouthY: 1,
                                              mouthScale: 1.02),

        .surprised: MermaidExpressionPreset(eye: .wide,
                                            mouth: .o,
                                            leftBrow: MermaidEyebrowExpression(y: 10, rotation: -4),
                                            rightBrow: MermaidEyebrowExpression(y: 10, rotation: 4)),

        .sad: MermaidExpressionPreset(eye: .half,
                                      mouth: .frown,
                                      leftBrow: MermaidEyebrowExpression(x: 3, y: 2, rotation: -10),
                                      rightBrow: MermaidEyebrowExpression(x: -3, y: 2, rotation: 10),
                                      mouthY: -2)
    ]

    static func pose(named name: MermaidExpressionName) -> MermaidFacePose {
        presets[name]?.pose ?? presets[.neutral]!.pose
    }

    static func expressionName(for emotion: MermaidEmotion) -> MermaidExpressionName {
        switch emotion {
        case .neutral:
            return .neutral
        case .curious:
            return .curious
        case .happy:
            return .happy
        case .satisfied:
            return .satisfied
        case .hungry:
            return .hungry
        case .eating:
            return .eating
        case .tired:
            return .tired
        case .scared:
            return .scared
        case .stubborn:
            return .snob
        case .focused:
            return .focused
        case .adventurous:
            return .adventurous
        case .surprised:
            return .surprised
        case .sad:
            return .sad
        }
    }
}

struct MermaidFacePose {
    let eyeAsset: MermaidEyeAsset
    let mouthAsset: MermaidMouthAsset
    let leftEyebrowOffset: CGPoint
    let rightEyebrowOffset: CGPoint
    let leftEyebrowRotationDelta: CGFloat
    let rightEyebrowRotationDelta: CGFloat
    let mouthOffset: CGPoint
    let mouthScale: CGFloat

    init(
        eyeAsset: MermaidEyeAsset,
        mouthAsset: MermaidMouthAsset,
        leftEyebrowOffset: CGPoint = .zero,
        rightEyebrowOffset: CGPoint = .zero,
        leftEyebrowRotationDelta: CGFloat = 0,
        rightEyebrowRotationDelta: CGFloat = 0,
        mouthOffset: CGPoint = .zero,
        mouthScale: CGFloat = 1
    ) {
        self.eyeAsset = eyeAsset
        self.mouthAsset = mouthAsset
        self.leftEyebrowOffset = leftEyebrowOffset
        self.rightEyebrowOffset = rightEyebrowOffset
        self.leftEyebrowRotationDelta = leftEyebrowRotationDelta
        self.rightEyebrowRotationDelta = rightEyebrowRotationDelta
        self.mouthOffset = mouthOffset
        self.mouthScale = mouthScale
    }

    static func pose(for emotion: MermaidEmotion) -> MermaidFacePose {
        MermaidExpressionLibrary.pose(named: MermaidExpressionLibrary.expressionName(for: emotion))
    }
}

final class MermaidEmotionComponent: GKComponent {
    private let mermaid: Mermaid
    private var currentEmotion: MermaidEmotion?
    private var currentExpression: MermaidExpressionName?
    private var overrideEmotion: MermaidEmotion?
    private var overrideExpression: MermaidExpressionName?
    private var overrideTime: CGFloat = 0
    private var blinkTimer: CGFloat = .random(in: 2.8...5.2)
    private var blinkTime: CGFloat = 0
    private var activeBasePose = MermaidFacePose.pose(for: .neutral)
    private var lastFormKind: MermaidFormKind?
    private var lastFormRevision = -1

    init(mermaid: Mermaid) {
        self.mermaid = mermaid
        super.init()
        mermaid.applyFacePose(activeBasePose, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(dt: CGFloat, intent: MermaidIntent, stats: MermaidStats) {
        if lastFormKind != mermaid.formKind || lastFormRevision != mermaid.formRevision {
            lastFormKind = mermaid.formKind
            lastFormRevision = mermaid.formRevision
            currentEmotion = nil
            currentExpression = nil
            blinkTime = 0
        }

        if overrideTime > 0 {
            overrideTime -= dt
            if overrideTime <= 0 {
                overrideEmotion = nil
                overrideExpression = nil
            }
        }

        let emotion = overrideEmotion ?? emotion(for: intent, stats: stats)
        if let overrideExpression {
            setExpression(overrideExpression, animated: true)
        } else {
            setEmotion(emotion, animated: true)
        }
        updateBlink(dt: dt, emotion: emotion)
    }

    func show(_ emotion: MermaidEmotion, duration: CGFloat) {
        overrideEmotion = emotion
        overrideExpression = nil
        overrideTime = max(0, duration)
        setEmotion(emotion, animated: true)
    }

    func show(_ expression: MermaidExpressionName, duration: CGFloat) {
        overrideEmotion = nil
        overrideExpression = expression
        overrideTime = max(0, duration)
        setExpression(expression, animated: true)
    }

    private func setEmotion(_ emotion: MermaidEmotion, animated: Bool) {
        let expression = MermaidExpressionLibrary.expressionName(for: emotion)
        guard emotion != currentEmotion || expression != currentExpression else { return }
        currentEmotion = emotion
        setExpression(expression, animated: animated)
    }

    private func setExpression(_ expression: MermaidExpressionName, animated: Bool) {
        guard expression != currentExpression else { return }
        currentExpression = expression
        activeBasePose = MermaidExpressionLibrary.pose(named: expression)
        mermaid.applyFacePose(activeBasePose, animated: animated)
    }

    private func emotion(for intent: MermaidIntent, stats: MermaidStats) -> MermaidEmotion {
        if intent == .avoidingDanger { return .scared }
        if intent == .eating { return .eating }
        if intent == .resting || stats.energy < 18 { return .tired }
        if stats.hunger > 72 || intent == .seekingFood { return .hungry }

        switch intent {
        case .inChallenge, .seekingChallenge:
            return .adventurous
        case .goingToObjective, .goingDeeper, .goingUp, .traveling, .enteringRefuge:
            return .focused
        case .wandering, .observing, .followingFish:
            return .curious
        case .interactingWithFish:
            return .happy
        default:
            break
        }

        if stats.scaredTimer > 0 { return .scared }
        if stats.disposition < 28 { return .sad }
        if stats.hunger < 24 && stats.energy > 70 && stats.disposition > 70 { return .satisfied }
        if stats.disposition > 82 { return .happy }
        return .neutral
    }

    private func updateBlink(dt: CGFloat, emotion: MermaidEmotion) {
        guard canBlink(during: emotion) else {
            blinkTime = 0
            blinkTimer = max(blinkTimer, 0.8)
            return
        }

        if blinkTime > 0 {
            blinkTime -= dt
            if blinkTime <= 0 {
                mermaid.applyFacePose(activeBasePose, animated: true)
                blinkTimer = .random(in: 2.8...5.2)
            }
            return
        }

        blinkTimer -= dt
        if blinkTimer <= 0 {
            var blinkPose = activeBasePose
            blinkPose = MermaidFacePose(eyeAsset: .closed,
                                        mouthAsset: blinkPose.mouthAsset,
                                        leftEyebrowOffset: blinkPose.leftEyebrowOffset,
                                        rightEyebrowOffset: blinkPose.rightEyebrowOffset,
                                        leftEyebrowRotationDelta: blinkPose.leftEyebrowRotationDelta,
                                        rightEyebrowRotationDelta: blinkPose.rightEyebrowRotationDelta,
                                        mouthOffset: blinkPose.mouthOffset,
                                        mouthScale: blinkPose.mouthScale)
            mermaid.applyFacePose(blinkPose, animated: true)
            blinkTime = 0.12
        }
    }

    private func canBlink(during emotion: MermaidEmotion) -> Bool {
        switch emotion {
        case .scared, .surprised, .eating:
            return false
        default:
            return true
        }
    }
}

extension SKSpriteNode {
    func setFaceTexture(_ name: String) {
        let nextTexture = FaceTextureCache.texture(named: name)
        texture = nextTexture
        size = nextTexture.size()
    }
}

private enum FaceTextureCache {
    private static let cache: NSCache<NSString, SKTexture> = {
        let cache = NSCache<NSString, SKTexture>()
        cache.name = "FaceTextureCache.textures"
        cache.countLimit = 24
        cache.totalCostLimit = 6 * 1024 * 1024
        return cache
    }()

    static func texture(named name: String) -> SKTexture {
        let key = NSString(string: name)
        if let texture = cache.object(forKey: key) {
            return texture
        }

        let texture = SKTexture(imageNamed: name)
        cache.setObject(texture, forKey: key, cost: texture.approximateFaceMemoryCost)
        return texture
    }
}

private extension SKTexture {
    var approximateFaceMemoryCost: Int {
        let size = self.size()
        let pixels = max(1, Int(ceil(size.width)) * Int(ceil(size.height)))
        return pixels * 4
    }
}

extension SKNode {
    func applyFaceTransform(position: CGPoint,
                            scale: CGFloat,
                            mirrored: Bool,
                            rotationDegrees: CGFloat,
                            animated: Bool) {
        let targetScale = abs(scale)
        let targetXScale = mirrored ? -targetScale : targetScale
        let targetYScale = targetScale
        let targetRotation = rotationDegrees * .pi / 180

        removeAllActions()
        xScale = targetXScale
        yScale = targetYScale
        if animated {
            let move = SKAction.move(to: position, duration: 0.18)
            let rotate = SKAction.rotate(toAngle: targetRotation, duration: 0.18)
            let group = SKAction.group([move, rotate])
            group.eaeInEaseOut()
            run(group, withKey: "facePose")
        } else {
            self.position = position
            zRotation = targetRotation
        }
    }
}
