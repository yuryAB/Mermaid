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
    case surprised
    case sad
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
        switch emotion {
        case .neutral:
            return MermaidFacePose(eyeAsset: .open, mouthAsset: .neutral)
        case .curious:
            return MermaidFacePose(eyeAsset: .open,
                                   mouthAsset: .smile,
                                   leftEyebrowOffset: CGPoint(x: 0, y: 8),
                                   rightEyebrowOffset: CGPoint(x: 0, y: 1),
                                   leftEyebrowRotationDelta: -5,
                                   rightEyebrowRotationDelta: -2)
        case .happy:
            return MermaidFacePose(eyeAsset: .open,
                                   mouthAsset: .smile,
                                   leftEyebrowOffset: CGPoint(x: 0, y: 5),
                                   rightEyebrowOffset: CGPoint(x: 0, y: 5),
                                   leftEyebrowRotationDelta: -4,
                                   rightEyebrowRotationDelta: 4,
                                   mouthOffset: CGPoint(x: 0, y: 2),
                                   mouthScale: 1.05)
        case .satisfied:
            return MermaidFacePose(eyeAsset: .closed,
                                   mouthAsset: .smile,
                                   leftEyebrowOffset: CGPoint(x: 0, y: 3),
                                   rightEyebrowOffset: CGPoint(x: 0, y: 3),
                                   leftEyebrowRotationDelta: -3,
                                   rightEyebrowRotationDelta: 3,
                                   mouthOffset: CGPoint(x: 0, y: 1))
        case .hungry:
            return MermaidFacePose(eyeAsset: .half,
                                   mouthAsset: .open,
                                   leftEyebrowOffset: CGPoint(x: 1, y: -2),
                                   rightEyebrowOffset: CGPoint(x: -1, y: -2),
                                   leftEyebrowRotationDelta: 7,
                                   rightEyebrowRotationDelta: -7,
                                   mouthOffset: CGPoint(x: 0, y: -1))
        case .eating:
            return MermaidFacePose(eyeAsset: .half,
                                   mouthAsset: .chew,
                                   leftEyebrowOffset: CGPoint(x: 0, y: 1),
                                   rightEyebrowOffset: CGPoint(x: 0, y: 1),
                                   mouthScale: 1.08)
        case .tired:
            return MermaidFacePose(eyeAsset: .half,
                                   mouthAsset: .sleepy,
                                   leftEyebrowOffset: CGPoint(x: 0, y: -5),
                                   rightEyebrowOffset: CGPoint(x: 0, y: -5),
                                   leftEyebrowRotationDelta: -2,
                                   rightEyebrowRotationDelta: 2,
                                   mouthOffset: CGPoint(x: 0, y: -2))
        case .scared:
            return MermaidFacePose(eyeAsset: .wide,
                                   mouthAsset: .o,
                                   leftEyebrowOffset: CGPoint(x: -2, y: 13),
                                   rightEyebrowOffset: CGPoint(x: 2, y: 13),
                                   leftEyebrowRotationDelta: -8,
                                   rightEyebrowRotationDelta: 8,
                                   mouthScale: 1.08)
        case .stubborn:
            return MermaidFacePose(eyeAsset: .half,
                                   mouthAsset: .pout,
                                   leftEyebrowOffset: CGPoint(x: 3, y: -4),
                                   rightEyebrowOffset: CGPoint(x: -3, y: -4),
                                   leftEyebrowRotationDelta: 12,
                                   rightEyebrowRotationDelta: -12,
                                   mouthOffset: CGPoint(x: 0, y: -1),
                                   mouthScale: 1.04)
        case .focused:
            return MermaidFacePose(eyeAsset: .open,
                                   mouthAsset: .neutral,
                                   leftEyebrowOffset: CGPoint(x: 3, y: -3),
                                   rightEyebrowOffset: CGPoint(x: -3, y: -3),
                                   leftEyebrowRotationDelta: 8,
                                   rightEyebrowRotationDelta: -8)
        case .surprised:
            return MermaidFacePose(eyeAsset: .wide,
                                   mouthAsset: .o,
                                   leftEyebrowOffset: CGPoint(x: 0, y: 10),
                                   rightEyebrowOffset: CGPoint(x: 0, y: 10),
                                   leftEyebrowRotationDelta: -4,
                                   rightEyebrowRotationDelta: 4)
        case .sad:
            return MermaidFacePose(eyeAsset: .half,
                                   mouthAsset: .frown,
                                   leftEyebrowOffset: CGPoint(x: 3, y: 2),
                                   rightEyebrowOffset: CGPoint(x: -3, y: 2),
                                   leftEyebrowRotationDelta: -10,
                                   rightEyebrowRotationDelta: 10,
                                   mouthOffset: CGPoint(x: 0, y: -2))
        }
    }
}

final class MermaidEmotionComponent: GKComponent {
    private let mermaid: Mermaid
    private var currentEmotion: MermaidEmotion?
    private var overrideEmotion: MermaidEmotion?
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
            blinkTime = 0
        }

        if overrideTime > 0 {
            overrideTime -= dt
            if overrideTime <= 0 { overrideEmotion = nil }
        }

        let emotion = overrideEmotion ?? emotion(for: intent, stats: stats)
        setEmotion(emotion, animated: true)
        updateBlink(dt: dt, emotion: emotion)
    }

    func show(_ emotion: MermaidEmotion, duration: CGFloat) {
        overrideEmotion = emotion
        overrideTime = max(0, duration)
        setEmotion(emotion, animated: true)
    }

    private func setEmotion(_ emotion: MermaidEmotion, animated: Bool) {
        guard emotion != currentEmotion else { return }
        currentEmotion = emotion
        activeBasePose = MermaidFacePose.pose(for: emotion)
        mermaid.applyFacePose(activeBasePose, animated: animated)
    }

    private func emotion(for intent: MermaidIntent, stats: MermaidStats) -> MermaidEmotion {
        if stats.scaredTimer > 0 || intent == .avoidingDanger { return .scared }
        if intent == .eating { return .eating }
        if intent == .resting || stats.energy < 18 { return .tired }
        if stats.hunger > 72 || intent == .seekingFood { return .hungry }

        switch intent {
        case .inChallenge, .seekingChallenge, .goingToObjective, .goingDeeper, .goingUp, .traveling, .enteringRefuge:
            return .focused
        case .wandering, .observing:
            return .curious
        case .interactingWithFish:
            return .happy
        default:
            break
        }

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
        let nextTexture = SKTexture(imageNamed: name)
        texture = nextTexture
        size = nextTexture.size()
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
