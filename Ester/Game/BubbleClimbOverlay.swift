//
//  BubbleClimbOverlay.swift
//  Ester
//
//  Desafio: Subida - bolhas frágeis funcionam como plataformas temporárias.
//  A sereia salta automaticamente ao tocar uma bolha; o jogador controla
//  apenas o eixo horizontal, como no Sky Jump do Pou.
//

import CoreMotion
import Foundation
import SpriteKit

// MARK: - Plataforma de bolha

private final class ClimbBubble: SKShapeNode {
    var radius: CGFloat = 26
    var popped = false
    var crumbleDuration: CGFloat = 1.15
    var permanent = false
    var scored = false
    var starter = false

    private var crumbling = false
    private var crumbleTimer: CGFloat = 0
    private var horizontalMotionCenterX: CGFloat?
    private var horizontalMotionAmplitude: CGFloat = 0
    private var horizontalMotionSpeed: CGFloat = 0
    private var horizontalMotionPhase: CGFloat = 0

    convenience init(radius: CGFloat, crumbleDuration: CGFloat, starter: Bool = false, permanent: Bool = false) {
        self.init(circleOfRadius: radius)
        self.radius = radius
        self.crumbleDuration = crumbleDuration
        self.starter = starter
        self.permanent = starter || permanent
        fillColor = self.permanent
            ? UIColor(red: 0.78, green: 0.93, blue: 1.0, alpha: 0.30)
            : UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 0.24)
        strokeColor = self.permanent
            ? GameUI.gold.withAlphaComponent(0.72)
            : UIColor(white: 1, alpha: 0.78)
        lineWidth = self.permanent ? 2.0 : 1.6
        glowWidth = self.permanent ? 4 : 3

        let shine = SKShapeNode(circleOfRadius: radius * 0.22)
        shine.fillColor = UIColor(white: 1, alpha: 0.55)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -radius * 0.35, y: radius * 0.4)
        addChild(shine)

        let innerGlow = SKShapeNode(circleOfRadius: radius * 0.72)
        innerGlow.fillColor = UIColor.white.withAlphaComponent(0.08)
        innerGlow.strokeColor = UIColor.white.withAlphaComponent(0.12)
        innerGlow.lineWidth = 1
        innerGlow.position = CGPoint(x: radius * 0.08, y: -radius * 0.05)
        innerGlow.zPosition = 1
        addChild(innerGlow)
    }

    func configureHorizontalMotion(amplitude: CGFloat, speed: CGFloat, phase: CGFloat) {
        horizontalMotionCenterX = position.x
        horizontalMotionAmplitude = amplitude
        horizontalMotionSpeed = speed
        horizontalMotionPhase = phase
        strokeColor = permanent
            ? GameUI.gold.withAlphaComponent(0.9)
            : UIColor(red: 0.72, green: 0.94, blue: 1.0, alpha: 0.92)
        glowWidth = permanent ? 5 : 4
    }

    func updateHorizontalMotion(dt: CGFloat) {
        guard let centerX = horizontalMotionCenterX else { return }
        horizontalMotionPhase += horizontalMotionSpeed * dt
        position.x = centerX + sin(horizontalMotionPhase) * horizontalMotionAmplitude
    }

    func beginCrumbling() {
        guard !permanent, !crumbling, !popped else { return }
        crumbling = true
        crumbleTimer = crumbleDuration
    }

    func reactToLanding() {
        let ripple = SKShapeNode(circleOfRadius: radius * 0.9)
        ripple.fillColor = .clear
        ripple.strokeColor = UIColor.white.withAlphaComponent(0.70)
        ripple.lineWidth = 1.4
        ripple.zPosition = 5
        addChild(ripple)
        ripple.run(.sequence([
            .group([
                .scale(to: 1.35, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))

        run(.sequence([
            .scaleX(to: 1.12, y: 0.88, duration: 0.08),
            .scaleX(to: 0.96, y: 1.06, duration: 0.08),
            .scale(to: 1.0, duration: 0.08)
        ]))
    }

    func updateFragility(dt: CGFloat) {
        guard crumbling, !popped else { return }
        crumbleTimer -= dt

        let ratio = max(0, crumbleTimer / max(0.01, crumbleDuration))
        if crumbleTimer <= 0.45 {
            alpha = 0.35 + 0.65 * abs(sin(crumbleTimer * 32))
        } else {
            alpha = 0.82 + 0.18 * ratio
        }
        setScale(0.94 + 0.06 * ratio)

        if crumbleTimer <= 0 {
            pop()
        }
    }

    func pop() {
        guard !permanent, !popped else { return }
        popped = true
        GameAudio.shared.play(.climbPop)
        spawnMiniBubbles()
        run(.sequence([
            .group([.scale(to: 1.5, duration: 0.16), .fadeOut(withDuration: 0.16)]),
            .removeFromParent()
        ]))
    }

    private func spawnMiniBubbles() {
        guard let parent else { return }
        for index in 0..<7 {
            let size = CGFloat.random(in: 3...7)
            let mini = SKShapeNode(circleOfRadius: size)
            mini.fillColor = UIColor(red: 0.72, green: 0.90, blue: 1.0, alpha: 0.24)
            mini.strokeColor = UIColor.white.withAlphaComponent(0.70)
            mini.lineWidth = 0.9
            mini.position = position
            mini.zPosition = zPosition + 1
            parent.addChild(mini)

            let angle = (CGFloat(index) / 7) * .pi * 2 + CGFloat.random(in: -0.35...0.35)
            let distance = CGFloat.random(in: radius * 0.45...radius * 1.15)
            let drift = CGPoint(x: cos(angle) * distance,
                                y: sin(angle) * distance + CGFloat.random(in: 10...26))
            mini.run(.sequence([
                .group([
                    .moveBy(x: drift.x, y: drift.y, duration: 0.38),
                    .scale(to: 0.35, duration: 0.38),
                    .fadeOut(withDuration: 0.38)
                ]),
                .removeFromParent()
            ]))
        }
    }
}

// MARK: - Overlay

final class BubbleClimbOverlay: SKNode {
    private let special: Bool
    private let phase: MermaidPhase
    private let shellRewardMultiplier: CGFloat
    private let challengeGoalBubbles: Int
    private let onFinish: (ChallengeResult) -> Void

    private let areaWidth: CGFloat
    private let areaHeight: CGFloat
    private let areaCenter = CGPoint(x: 0, y: -38)
    private var areaHalf: CGFloat { areaWidth / 2 }
    private var areaHalfY: CGFloat { areaHeight / 2 }
    private let skyReferencePoints: CGFloat = 10_000

    private var timerRunning = false
    private var bubblesClimbed = 0
    private var pointScore = 0
    private var challengeCompleted = false

    private let contentNode = SKNode()
    private var bubbles: [ClimbBubble] = []
    private var currentPlatform: ClimbBubble?
    private var lastPlatformPosition = CGPoint.zero

    private var mermaid: Mermaid!
    private var mermaidNode: SKNode { mermaid.base }
    private var velocity = CGVector(dx: 0, dy: 0)

    private let motionManager = CMMotionManager()
    private var touchControl: CGFloat = 0
    private var motionControl: CGFloat = 0

    private var finished = false
    private var pendingResult: ChallengeResult?

    private var timerLabel: SKLabelNode!
    private var objectiveLabel: SKLabelNode!
    private var streakLabel: SKLabelNode!

    private let mermaidSupportOffset: CGFloat = 20
    private let gravity: CGFloat = 660
    private let jumpVelocity: CGFloat = 430
    private let maxHorizontalSpeed: CGFloat = 250
    private let maxFallSpeed: CGFloat = -500

    private var platformCrumbleDuration: CGFloat {
        special ? 1.1 : 1.35
    }

    private enum ClimbVisual {
        static let darkTop = UIColor(red: 0.05, green: 0.22, blue: 0.31, alpha: 1)
        static let darkMid = UIColor(red: 0.04, green: 0.16, blue: 0.27, alpha: 1)
        static let darkBottom = UIColor(red: 0.03, green: 0.09, blue: 0.19, alpha: 1)
        static let abyss = UIColor(red: 0.01, green: 0.02, blue: 0.08, alpha: 1)
        static let deep = UIColor(red: 0.03, green: 0.09, blue: 0.20, alpha: 1)
        static let blue = UIColor(red: 0.04, green: 0.26, blue: 0.43, alpha: 1)
        static let shallow = UIColor(red: 0.12, green: 0.54, blue: 0.66, alpha: 1)
        static let sky = UIColor(red: 0.62, green: 0.82, blue: 0.94, alpha: 1)
    }

    init(size: CGSize,
         phase: MermaidPhase,
         palette: MermaidPalette,
         special: Bool,
         shellRewardMultiplier: CGFloat,
         giverDisplay: SKNode?,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.special = special
        self.phase = phase
        self.shellRewardMultiplier = shellRewardMultiplier
        self.challengeGoalBubbles = special ? 24 : 16
        self.onFinish = onFinish
        let availableWidth = max(260, size.width - 36)
        let availableHeight = max(260, size.height - 432)
        let width = min(availableWidth, availableHeight, 380)
        self.areaWidth = width
        self.areaHeight = width + 52
        super.init()
        isUserInteractionEnabled = true
        GameAudio.shared.preloadClimbSounds()
        startMotionControl()
        buildChrome(size: size, giverDisplay: giverDisplay)
        buildPlayArea(phase: phase, palette: palette)
        GameAudio.shared.play(.climbStart)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, giverDisplay: SKNode?) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.14)
        backdrop.strokeColor = .clear
        backdrop.zPosition = -100
        addChild(backdrop)

        let panelSize = CGSize(width: areaWidth + 34, height: areaWidth + 320)
        let panel = makeClimbFrame(size: panelSize)
        panel.position = CGPoint(x: 0, y: 42)
        addChild(panel)

        let subtitle = special
            ? "Bolhas frágeis em corrente forte"
            : "Suba bolhas e faça pontos"
        let header = makeClimbHeader(subtitle: subtitle,
                                     giverDisplay: giverDisplay,
                                     width: areaWidth)
        header.position = CGPoint(x: 0, y: areaHalf + 150)
        header.zPosition = 20
        addChild(header)

        let chipWidth = (areaWidth - 14) / 2
        let shellsChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "star.fill",
                                                                      fallback: "★",
                                                                      color: GameUI.gold,
                                                                      size: 22),
                                      title: "Pontos",
                                      value: progressText(),
                                      width: chipWidth,
                                      accent: GameUI.gold)
        shellsChip.node.position = CGPoint(x: -areaHalf + chipWidth / 2, y: areaHalf + 42)
        shellsChip.node.zPosition = 20
        addChild(shellsChip.node)
        timerLabel = shellsChip.valueLabel

        let objectiveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                         fallback: "⌾",
                                                                         color: GameUI.coral,
                                                                         size: 22),
                                         title: "Objetivo",
                                         value: objectiveText(),
                                         width: chipWidth,
                                         accent: GameUI.coral)
        objectiveChip.node.position = CGPoint(x: -areaHalf + chipWidth * 1.5 + 14,
                                              y: areaHalf + 42)
        objectiveChip.node.zPosition = 20
        addChild(objectiveChip.node)
        objectiveLabel = objectiveChip.valueLabel

        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-Heavy"
        streakLabel.fontSize = 18
        streakLabel.fontColor = GameUI.coral
        streakLabel.alpha = 0
        streakLabel.position = CGPoint(x: 0, y: areaHalf + 76)
        streakLabel.zPosition = 25
        addChild(streakLabel)

        let quit = makeReefButton(text: "Sair", width: 118, height: 38, nodeName: "climb_quit")
        quit.position = CGPoint(x: 0, y: areaCenter.y - areaHalfY - 32)
        quit.zPosition = 20
        addChild(quit)
    }

    private func makeClimbFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: GameUI.accent.withAlphaComponent(0.50),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -5
        addMiniGameCardWash(to: node,
                            size: size,
                            tint: GameUI.accent)

        let currentPath = UIBezierPath()
        currentPath.move(to: CGPoint(x: -size.width / 2 + 28, y: size.height / 2 - 54))
        currentPath.addCurve(to: CGPoint(x: size.width / 2 - 28, y: size.height / 2 - 62),
                             controlPoint1: CGPoint(x: -size.width * 0.18, y: size.height / 2 - 28),
                             controlPoint2: CGPoint(x: size.width * 0.26, y: size.height / 2 - 86))
        let current = SKShapeNode(path: currentPath.cgPath)
        current.fillColor = .clear
        current.strokeColor = GameUI.palePaper.withAlphaComponent(0.12)
        current.lineWidth = 3
        current.lineCap = .round
        current.zPosition = 3
        node.addChild(current)

        for side: CGFloat in [-1, 1] {
            let coral = makeFrameCoralSprig(height: 78,
                                            color: side < 0 ? GameUI.coral : GameUI.algae)
            coral.position = CGPoint(x: side * (size.width / 2 - 26), y: -size.height / 2 + 48)
            coral.zPosition = 3
            coral.xScale = side
            node.addChild(coral)
        }

        return node
    }

    private func addMiniGameCardWash(to card: SKNode, size: CGSize, tint: UIColor) {
        let wash = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                               cornerRadius: 22)
        wash.fillTexture = GameUI.gradientTexture(size: size,
                                                  colors: [
                                                      ClimbVisual.darkTop,
                                                      UIColor.lerp(ClimbVisual.darkMid, tint, 0.12),
                                                      ClimbVisual.darkBottom
                                                  ])
        wash.fillColor = .white
        wash.strokeColor = GameUI.accent.withAlphaComponent(0.24)
        wash.lineWidth = 1
        wash.zPosition = 0.5
        card.addChild(wash)

        let glow = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: size.height - 20),
                               cornerRadius: 18)
        glow.fillColor = GameUI.gold.withAlphaComponent(0.04)
        glow.strokeColor = UIColor.white.withAlphaComponent(0.05)
        glow.lineWidth = 1
        glow.zPosition = 0.7
        card.addChild(glow)
    }

    private func makeClimbHeader(subtitle: String,
                                 giverDisplay: SKNode?,
                                 width: CGFloat) -> SKNode {
        let header = SKNode()

        let titlePanel = SKShapeNode(rectOf: CGSize(width: width - 92, height: 82), cornerRadius: 24)
        titlePanel.fillTexture = GameUI.paperTexture(size: CGSize(width: width - 92, height: 82),
                                                     base: GameUI.palePaper)
        titlePanel.fillColor = .white
        titlePanel.strokeColor = GameUI.line.withAlphaComponent(0.30)
        titlePanel.lineWidth = 1.3
        titlePanel.position = CGPoint(x: 34, y: -14)
        header.addChild(titlePanel)

        let courierGlow = SKShapeNode(circleOfRadius: 48)
        courierGlow.fillColor = GameUI.gold.withAlphaComponent(0.12)
        courierGlow.strokeColor = GameUI.gold.withAlphaComponent(0.68)
        courierGlow.lineWidth = 1.8
        courierGlow.glowWidth = 2
        courierGlow.position = CGPoint(x: -width / 2 + 54, y: -8)
        header.addChild(courierGlow)
        courierGlow.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.72),
            .scale(to: 1.0, duration: 0.72)
        ])))

        if let giver = giverDisplay {
            giver.setScale(ChallengeChrome.fitScale(for: giver, targetHeight: 50))
            giver.position = courierGlow.position
            giver.zPosition = 4
            header.addChild(giver)
            giver.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 5, duration: 0.55),
                .moveBy(x: 0, y: -5, duration: 0.55)
            ])))
        } else {
            let fish = makeCourierFish(color: GameUI.gold)
            fish.position = courierGlow.position
            fish.zPosition = 4
            header.addChild(fish)
        }

        let courier = SKLabelNode(text: "peixinho-correio")
        courier.fontName = "AvenirNext-DemiBold"
        courier.fontSize = 10.5
        courier.fontColor = GameUI.mutedInk
        courier.verticalAlignmentMode = .center
        courier.position = CGPoint(x: courierGlow.position.x, y: -66)
        header.addChild(courier)

        let title = SKLabelNode(text: "Desafio: Subida")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 24
        title.fontColor = GameUI.ink
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 112, y: 2)
        title.zPosition = 3
        header.addChild(title)

        let subtitleLabel = SKLabelNode(text: subtitle)
        subtitleLabel.fontName = "AvenirNext-DemiBold"
        subtitleLabel.fontSize = 13
        subtitleLabel.fontColor = GameUI.accent
        subtitleLabel.horizontalAlignmentMode = .left
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.preferredMaxLayoutWidth = max(120, width - 136)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.position = CGPoint(x: title.position.x, y: -28)
        subtitleLabel.zPosition = 3
        header.addChild(subtitleLabel)

        let accentColors = [GameUI.gold, GameUI.accent, GameUI.coral, GameUI.algae, GameUI.palePaper]
        for i in 0..<5 {
            let spark = SKLabelNode(text: i.isMultiple(of: 2) ? "✦" : "◌")
            spark.fontName = "AvenirNext-DemiBold"
            spark.fontSize = CGFloat(12 + i)
            spark.fontColor = accentColors[i % accentColors.count].withAlphaComponent(0.45)
            spark.position = CGPoint(x: -width / 2 + 92 + CGFloat(i) * 38,
                                     y: 34 + CGFloat(i % 2) * 10)
            header.addChild(spark)
            spark.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.28, duration: 0.7 + Double(i) * 0.08),
                .fadeAlpha(to: 0.82, duration: 0.7 + Double(i) * 0.08)
            ])))
        }

        return header
    }

    private func makeCourierFish(color: UIColor) -> SKNode {
        let node = SKNode()

        let body = SKShapeNode(ellipseOf: CGSize(width: 58, height: 30))
        body.fillColor = color
        body.strokeColor = UIColor.white.withAlphaComponent(0.45)
        body.lineWidth = 1.2
        body.glowWidth = 4
        node.addChild(body)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -25, y: 0))
        tailPath.addLine(to: CGPoint(x: -48, y: 17))
        tailPath.addLine(to: CGPoint(x: -44, y: -16))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = UIColor.lerp(color, GameUI.coral, 0.35)
        tail.strokeColor = .clear
        node.addChild(tail)

        let fin = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
        fin.fillColor = UIColor.white.withAlphaComponent(0.26)
        fin.strokeColor = .clear
        fin.position = CGPoint(x: 0, y: -9)
        fin.zRotation = -0.35
        node.addChild(fin)

        let eye = SKShapeNode(circleOfRadius: 4)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 18, y: 6)
        node.addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 2)
        pupil.fillColor = GameUI.ink
        pupil.strokeColor = .clear
        pupil.position = eye.position
        node.addChild(pupil)

        node.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 5, duration: 0.55),
            .moveBy(x: 0, y: -5, duration: 0.55)
        ])))

        return node
    }

    private func makeInfoChip(iconNode: SKNode,
                              title: String,
                              value: String,
                              width: CGFloat,
                              accent: UIColor) -> (node: SKNode, valueLabel: SKLabelNode) {
        let node = SKNode()
        let size = CGSize(width: width, height: 50)

        let bg = SKShapeNode(rectOf: size, cornerRadius: 17)
        bg.fillTexture = GameUI.paperTexture(size: size, base: GameUI.paper)
        bg.fillColor = .white
        bg.strokeColor = accent.withAlphaComponent(0.55)
        bg.lineWidth = 1.4
        node.addChild(bg)

        iconNode.position = CGPoint(x: -width / 2 + 24, y: 0)
        node.addChild(iconNode)

        let titleLabel = SKLabelNode(text: title.uppercased())
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 8.5
        titleLabel.fontColor = GameUI.mutedInk
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -width / 2 + 46, y: 12)
        node.addChild(titleLabel)

        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Heavy"
        valueLabel.fontSize = 13.5
        valueLabel.fontColor = GameUI.ink
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.verticalAlignmentMode = .center
        valueLabel.preferredMaxLayoutWidth = width - 54
        valueLabel.numberOfLines = 1
        valueLabel.position = CGPoint(x: titleLabel.position.x, y: -8)
        node.addChild(valueLabel)

        return (node, valueLabel)
    }

    private func makeReefButton(text: String, width: CGFloat, height: CGFloat, nodeName: String) -> SKNode {
        let node = GameUI.pill(text: text,
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: width,
                               height: height)
        node.name = nodeName
        return node
    }

    private func makeMiniShell(color: UIColor, size: CGFloat) -> SKNode {
        let node = SKNode()
        let shell = SKShapeNode(ellipseOf: CGSize(width: size, height: size * 0.82))
        shell.fillColor = color
        shell.strokeColor = UIColor.white.withAlphaComponent(0.50)
        shell.lineWidth = 1
        shell.glowWidth = 3
        node.addChild(shell)

        for offset in [-0.18, 0, 0.18] {
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: size * CGFloat(offset), y: -size * 0.30))
            rib.addCurve(to: CGPoint(x: size * CGFloat(offset) * 0.18, y: size * 0.30),
                         controlPoint1: CGPoint(x: size * CGFloat(offset) * 1.45, y: -size * 0.06),
                         controlPoint2: CGPoint(x: size * CGFloat(offset) * 0.65, y: size * 0.22))
            let ribNode = SKShapeNode(path: rib.cgPath)
            ribNode.strokeColor = UIColor.white.withAlphaComponent(0.30)
            ribNode.lineWidth = 1
            ribNode.fillColor = .clear
            node.addChild(ribNode)
        }

        return node
    }

    private func makeFrameCoralSprig(height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        for i in 0..<4 {
            let path = UIBezierPath()
            let x = CGFloat(i) * 6 - 9
            path.move(to: CGPoint(x: 0, y: -height / 2))
            path.addCurve(to: CGPoint(x: x, y: height / 2 - CGFloat(i) * 9),
                          controlPoint1: CGPoint(x: CGFloat(i - 1) * 9, y: -height * 0.16),
                          controlPoint2: CGPoint(x: x * 1.5, y: height * 0.18))
            let branch = SKShapeNode(path: path.cgPath)
            branch.strokeColor = color.withAlphaComponent(0.72)
            branch.lineWidth = CGFloat(5 - min(i, 2))
            branch.lineCap = .round
            branch.fillColor = .clear
            node.addChild(branch)
        }
        return node
    }

    private func buildPlayArea(phase: MermaidPhase, palette: MermaidPalette) {
        let playSize = CGSize(width: areaWidth, height: areaHeight)
        let frame = SKShapeNode(rectOf: playSize,
                                cornerRadius: 14)
        frame.fillColor = UIColor(red: 0.03, green: 0.09, blue: 0.18, alpha: 1)
        frame.strokeColor = GameUI.palePaper.withAlphaComponent(0.18)
        frame.lineWidth = 1.5
        frame.position = areaCenter
        frame.zPosition = -1
        addChild(frame)

        let crop = SKCropNode()
        crop.position = areaCenter
        crop.zPosition = 1
        let mask = SKSpriteNode(color: .white,
                                size: CGSize(width: areaWidth - 6, height: areaHeight - 6))
        crop.maskNode = mask
        addChild(crop)
        crop.addChild(contentNode)
        addDrawnSeaBackground()

        mermaid = Mermaid()
        if phase != .egg {
            mermaid.setForm(for: phase)
        }
        mermaid.applyPalette(palette)
        mermaid.setAnimationMode(.idle)
        let scale = ChallengeChrome.fitScale(for: mermaid.base, targetHeight: 62)
        mermaid.base.setScale(scale)
        mermaid.base.zPosition = 10

        let starter = makePlatform(radius: 38,
                                   position: CGPoint(x: 0, y: -areaHalfY + 72),
                                   crumbleDuration: 2.0,
                                   starter: true)
        lastPlatformPosition = starter.position

        mermaid.base.position = CGPoint(x: starter.position.x,
                                        y: starter.position.y + starter.radius + mermaidSupportOffset)
        contentNode.addChild(mermaid.base)
        land(on: starter, animated: false)
        ensurePlatformsAhead()

        let hint = SKLabelNode(text: "Incline o aparelho ou segure um lado.")
        hint.fontName = "AvenirNext-Regular"
        hint.fontSize = 13
        hint.fontColor = UIColor(white: 1, alpha: 0.86)
        hint.position = CGPoint(x: areaCenter.x, y: areaCenter.y + areaHalfY - 36)
        hint.zPosition = 20
        addChild(hint)
        hint.run(.sequence([.wait(forDuration: 3.8), .fadeOut(withDuration: 0.8), .removeFromParent()]))
    }

    private func addDrawnSeaBackground() {
        let background = SKNode()
        background.zPosition = -50
        contentNode.addChild(background)

        let segmentHeight: CGFloat = 560
        let bottom = -areaHalfY - 80
        let top = skyReferencePoints + areaHalfY
        var y = bottom
        while y < top {
            let nextY = min(y + segmentHeight, top)
            let segmentCenterY = (y + nextY) / 2
            let segmentSize = CGSize(width: areaWidth - 6, height: nextY - y + 2)
            let lower = seaColor(at: max(1, y))
            let upper = seaColor(at: max(1, nextY))
            let band = SKSpriteNode(texture: GameUI.gradientTexture(size: segmentSize,
                                                                    colors: [upper, lower]))
            band.size = segmentSize
            band.position = CGPoint(x: 0, y: segmentCenterY)
            band.zPosition = -5
            background.addChild(band)
            y = nextY
        }

        addAbyssDetails(to: background)
        addMidSeaDetails(to: background)
        addSurfaceDetails(to: background)
    }

    private func seaColor(at points: CGFloat) -> UIColor {
        let t = (points / skyReferencePoints).clamped(to: 0...1)
        if t < 0.22 {
            return UIColor.lerp(ClimbVisual.abyss, ClimbVisual.deep, t / 0.22)
        } else if t < 0.56 {
            return UIColor.lerp(ClimbVisual.deep, ClimbVisual.blue, (t - 0.22) / 0.34)
        } else if t < 0.86 {
            return UIColor.lerp(ClimbVisual.blue, ClimbVisual.shallow, (t - 0.56) / 0.30)
        }
        return UIColor.lerp(ClimbVisual.shallow, ClimbVisual.sky, (t - 0.86) / 0.14)
    }

    private func addAbyssDetails(to background: SKNode) {
        let floor = UIBezierPath()
        floor.move(to: CGPoint(x: -areaHalf, y: -areaHalfY - 74))
        floor.addLine(to: CGPoint(x: -areaHalf * 0.60, y: -areaHalfY - 18))
        floor.addLine(to: CGPoint(x: -areaHalf * 0.22, y: -areaHalfY - 52))
        floor.addLine(to: CGPoint(x: areaHalf * 0.18, y: -areaHalfY - 24))
        floor.addLine(to: CGPoint(x: areaHalf * 0.62, y: -areaHalfY - 62))
        floor.addLine(to: CGPoint(x: areaHalf, y: -areaHalfY - 30))
        floor.addLine(to: CGPoint(x: areaHalf, y: -areaHalfY - 100))
        floor.addLine(to: CGPoint(x: -areaHalf, y: -areaHalfY - 100))
        floor.close()
        let floorNode = SKShapeNode(path: floor.cgPath)
        floorNode.fillColor = UIColor.black.withAlphaComponent(0.28)
        floorNode.strokeColor = GameUI.accent.withAlphaComponent(0.10)
        floorNode.lineWidth = 1
        floorNode.zPosition = -1
        background.addChild(floorNode)

        for x in stride(from: -areaHalf + 28, through: areaHalf - 28, by: 56) {
            let coral = makeStaticCoral(height: CGFloat.random(in: 42...84),
                                        color: CGFloat.random(in: 0...1) > 0.45 ? GameUI.coral : GameUI.algae)
            coral.position = CGPoint(x: x + CGFloat.random(in: -12...12),
                                     y: -areaHalfY - CGFloat.random(in: 8...30))
            coral.zPosition = 0
            background.addChild(coral)
        }
    }

    private func addMidSeaDetails(to background: SKNode) {
        for i in 0..<12 {
            let y = CGFloat(i) * 620 + 520
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -areaHalf + CGFloat.random(in: 16...42), y: y))
            path.addCurve(to: CGPoint(x: areaHalf - CGFloat.random(in: 16...42),
                                      y: y + CGFloat.random(in: -28...28)),
                          controlPoint1: CGPoint(x: -areaHalf * 0.36, y: y + CGFloat.random(in: 32...64)),
                          controlPoint2: CGPoint(x: areaHalf * 0.30, y: y + CGFloat.random(in: -64...32)))
            let current = SKShapeNode(path: path.cgPath)
            current.strokeColor = GameUI.palePaper.withAlphaComponent(0.06)
            current.lineWidth = CGFloat.random(in: 1.5...3.0)
            current.lineCap = .round
            current.fillColor = .clear
            current.zPosition = -1
            background.addChild(current)
        }

        for i in 0..<10 {
            let fish = SKLabelNode(text: i.isMultiple(of: 2) ? "⌁" : "≈")
            fish.fontName = "AvenirNext-DemiBold"
            fish.fontSize = CGFloat.random(in: 15...24)
            fish.fontColor = GameUI.palePaper.withAlphaComponent(0.10)
            fish.position = CGPoint(x: CGFloat.random(in: (-areaHalf + 30)...(areaHalf - 30)),
                                    y: CGFloat.random(in: 700...6_500))
            fish.zRotation = CGFloat.random(in: -0.18...0.18)
            background.addChild(fish)
        }
    }

    private func addSurfaceDetails(to background: SKNode) {
        let horizonY = skyReferencePoints - 260
        let surface = SKShapeNode(rectOf: CGSize(width: areaWidth - 16, height: 8), cornerRadius: 4)
        surface.fillColor = UIColor.white.withAlphaComponent(0.36)
        surface.strokeColor = .clear
        surface.position = CGPoint(x: 0, y: horizonY)
        background.addChild(surface)

        for i in 0..<5 {
            let ray = UIBezierPath()
            let x = -areaHalf + 40 + CGFloat(i) * (areaWidth - 80) / 4
            ray.move(to: CGPoint(x: x, y: skyReferencePoints + areaHalfY))
            ray.addLine(to: CGPoint(x: x + CGFloat.random(in: -34...34), y: skyReferencePoints - 780))
            let node = SKShapeNode(path: ray.cgPath)
            node.strokeColor = UIColor.white.withAlphaComponent(0.10)
            node.lineWidth = CGFloat.random(in: 8...16)
            node.lineCap = .round
            background.addChild(node)
        }
    }

    private func makeStaticCoral(height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        for i in 0..<3 {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addCurve(to: CGPoint(x: CGFloat(i - 1) * 10, y: height - CGFloat(i) * 13),
                          controlPoint1: CGPoint(x: CGFloat(i - 1) * 11, y: height * 0.28),
                          controlPoint2: CGPoint(x: CGFloat(i - 1) * 14, y: height * 0.62))
            let branch = SKShapeNode(path: path.cgPath)
            branch.strokeColor = color.withAlphaComponent(0.34)
            branch.lineWidth = CGFloat(4 - i)
            branch.lineCap = .round
            branch.fillColor = .clear
            node.addChild(branch)
        }
        return node
    }

    private func makePlatform(radius: CGFloat,
                              position: CGPoint,
                              crumbleDuration: CGFloat,
                              starter: Bool = false,
                              permanent: Bool = false) -> ClimbBubble {
        let bubble = ClimbBubble(radius: radius,
                                 crumbleDuration: crumbleDuration,
                                 starter: starter,
                                 permanent: permanent)
        bubble.position = position
        bubble.zPosition = 4
        contentNode.addChild(bubble)
        bubbles.append(bubble)
        return bubble
    }

    // MARK: - Loop

    func update(dt: CGFloat) {
        guard !finished else { return }

        updateMotionControl()
        updateTimerLabels()

        ensurePlatformsAhead()
        updatePlatforms(dt: dt)
        updateMermaid(dt: dt)
        scrollCamera()
        cullPlatforms()
    }

    private func updateTimerLabels() {
        timerLabel.text = progressText()
        objectiveLabel.text = objectiveText()
    }

    private func progressText() -> String {
        "\(pointScore)"
    }

    private func objectiveText() -> String {
        if challengeCompleted {
            return "Meta completa"
        }
        return "Bolhas \(bubblesClimbed)/\(challengeGoalBubbles)"
    }

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: pointScore,
                                                          reachedTarget: reached ?? challengeCompleted,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        return GameBalance.scaledPearlReward(baseAmount: basePearls,
                                             multiplier: shellRewardMultiplier)
    }

    private func contentY(forViewY viewY: CGFloat) -> CGFloat {
        viewY - contentNode.position.y
    }

    private func viewY(forContentY y: CGFloat) -> CGFloat {
        y + contentNode.position.y
    }

    private func ensurePlatformsAhead() {
        let targetTop = contentY(forViewY: areaHalfY + 260)
        while lastPlatformPosition.y < targetTop {
            spawnPlatformAbove()
        }
    }

    private func spawnPlatformAbove() {
        let progress = min(1.25, CGFloat(bubblesClimbed) / CGFloat(max(1, challengeGoalBubbles)))
        let minRadius: CGFloat = special ? 23 : 25
        let maxRadius: CGFloat = special ? 31 : 34
        let radius = CGFloat.random(in: minRadius...maxRadius)
        let yGap = CGFloat.random(in: 68...94) + progress * (special ? 14 : 9)
        let maxShift = min(areaWidth * 0.30, 94 + progress * 18)
        var x = lastPlatformPosition.x + CGFloat.random(in: -maxShift...maxShift)
        if abs(x - lastPlatformPosition.x) < 34 {
            x += Bool.random() ? 42 : -42
        }

        let minX = -areaHalf + radius + 14
        let maxX = areaHalf - radius - 14
        x = x.clamped(to: minX...maxX)

        let becomesPermanent = CGFloat.random(in: 0...1) < (special ? 0.10 : 0.14)
        let movesHorizontally = !becomesPermanent && CGFloat.random(in: 0...1) < (special ? 0.30 : 0.24)

        var motionAmplitude: CGFloat = 0
        if movesHorizontally {
            let maxAmplitude = min(54 + progress * 18, min(x - minX, maxX - x))
            if maxAmplitude >= 24 {
                motionAmplitude = CGFloat.random(in: 24...maxAmplitude)
            }
        }

        let bubble = makePlatform(radius: radius,
                                  position: CGPoint(x: x, y: lastPlatformPosition.y + yGap),
                                  crumbleDuration: platformCrumbleDuration,
                                  permanent: becomesPermanent)
        if motionAmplitude > 0 {
            bubble.configureHorizontalMotion(amplitude: motionAmplitude,
                                             speed: CGFloat.random(in: 1.05...1.55),
                                             phase: CGFloat.random(in: 0...(2 * CGFloat.pi)))
        }
        lastPlatformPosition = bubble.position
    }

    private func updatePlatforms(dt: CGFloat) {
        for bubble in bubbles where !bubble.popped {
            let wasPopped = bubble.popped
            bubble.updateHorizontalMotion(dt: dt)
            bubble.updateFragility(dt: dt)
            if bubble.popped && !wasPopped && bubble === currentPlatform {
                detachFromPlatform()
            }
        }
    }

    private func updateMermaid(dt: CGFloat) {
        if let platform = currentPlatform, !platform.popped {
            velocity = CGVector(dx: 0, dy: 0)
            mermaidNode.position = CGPoint(x: platform.position.x,
                                           y: platform.position.y + platform.radius + mermaidSupportOffset)
            return
        }

        let previousPosition = mermaidNode.position
        applyHorizontalControl()
        velocity.dy = max(maxFallSpeed, velocity.dy - gravity * dt)

        mermaidNode.position.x += velocity.dx * dt
        mermaidNode.position.y += velocity.dy * dt

        wrapMermaidHorizontally()
        checkLanding(from: previousPosition)

        if viewY(forContentY: mermaidNode.position.y) < -areaHalfY - 48 {
            finish()
        }
    }

    private func applyHorizontalControl() {
        let input = activeHorizontalInput()
        velocity.dx = input * maxHorizontalSpeed
    }

    private func activeHorizontalInput() -> CGFloat {
        abs(touchControl) > 0.05 ? touchControl : motionControl
    }

    private func wrapMermaidHorizontally() {
        let margin: CGFloat = 24
        if mermaidNode.position.x < -areaHalf - margin {
            mermaidNode.position.x = areaHalf + margin
        } else if mermaidNode.position.x > areaHalf + margin {
            mermaidNode.position.x = -areaHalf - margin
        }
    }

    private func checkLanding(from previousPosition: CGPoint) {
        guard velocity.dy <= 0 else { return }

        let previousFootY = previousPosition.y - mermaidSupportOffset
        let footY = mermaidNode.position.y - mermaidSupportOffset

        let candidates = bubbles
            .filter { !$0.popped }
            .sorted { abs($0.position.y - footY) < abs($1.position.y - footY) }

        for bubble in candidates {
            let platformTop = bubble.position.y + bubble.radius
            let crossedTop = previousFootY >= platformTop && footY <= platformTop + 8
            let withinWidth = abs(mermaidNode.position.x - bubble.position.x) <= bubble.radius + 18
            guard crossedTop && withinWidth else { continue }
            land(on: bubble)
            return
        }
    }

    private func land(on bubble: ClimbBubble, animated: Bool = true) {
        guard !bubble.popped else { return }
        let shouldBounce = timerRunning || !bubble.permanent
        let retainedHorizontalVelocity = bubble.permanent && !timerRunning ? 0 : velocity.dx
        let landingX = shouldBounce ? mermaidNode.position.x : bubble.position.x
        currentPlatform = bubble
        velocity = CGVector(dx: retainedHorizontalVelocity, dy: 0)
        mermaid.setAnimationMode(.idle)
        mermaidNode.position = CGPoint(x: landingX,
                                       y: bubble.position.y + bubble.radius + mermaidSupportOffset)
        if animated {
            bubble.reactToLanding()
        }
        let completedNow = scoreLanding(on: bubble, willBounce: shouldBounce)
        bubble.beginCrumbling()
        if shouldBounce {
            bounce(from: bubble, playSound: !completedNow)
        }
    }

    private func scoreLanding(on bubble: ClimbBubble, willBounce: Bool) -> Bool {
        guard !bubble.starter, !bubble.scored else { return false }
        let completedNow = !challengeCompleted && bubblesClimbed + 1 >= challengeGoalBubbles
        bubble.scored = true
        bubblesClimbed += 1
        pointScore += 1
        if !challengeCompleted && bubblesClimbed >= challengeGoalBubbles {
            challengeCompleted = true
        }
        updateTimerLabels()
        pulseScoreLabels(includeObjective: !challengeCompleted || completedNow)
        showLandingBurst(at: bubble.position, permanent: bubble.permanent)
        if completedNow {
            GameAudio.shared.play(.climbGoal)
            showGoalBurst()
        } else if !willBounce {
            GameAudio.shared.play(.climbLand)
        }
        return completedNow
    }

    private func detachFromPlatform() {
        guard currentPlatform != nil else { return }
        currentPlatform = nil
        velocity.dy = min(velocity.dy, 24)
        mermaid.setAnimationMode(.swing)
    }

    private func bounce(from platform: ClimbBubble, playSound: Bool = true) {
        if platform.permanent {
            timerRunning = true
        }
        currentPlatform = nil
        velocity.dy = jumpVelocity
        mermaid.setAnimationMode(.swing)
        if playSound {
            GameAudio.shared.play(.climbBounce)
        }
        showBounceTrail(from: platform.position)
        mermaidNode.run(.sequence([
            .scale(to: mermaidNode.xScale * 1.08, duration: 0.08),
            .scale(to: mermaidNode.xScale, duration: 0.14)
        ]))
    }

    private func pulseScoreLabels(includeObjective: Bool) {
        let labels: [SKLabelNode] = includeObjective ? [timerLabel, objectiveLabel] : [timerLabel]
        for label in labels {
            label.removeAction(forKey: "score_pulse")
            label.run(.sequence([
                .scale(to: 1.12, duration: 0.10),
                .scale(to: 1.0, duration: 0.18)
            ]), withKey: "score_pulse")
        }
    }

    private func showLandingBurst(at point: CGPoint, permanent: Bool) {
        let label = SKLabelNode(text: permanent ? "+1 ponto seguro" : "+1 ponto")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = permanent ? 20 : 18
        label.fontColor = permanent ? GameUI.gold : GameUI.palePaper
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: point.x, y: point.y + 34)
        label.zPosition = 40
        contentNode.addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -10...10), y: 58, duration: 0.62),
                .fadeOut(withDuration: 0.62),
                .scale(to: 1.18, duration: 0.18)
            ]),
            .removeFromParent()
        ]))

        guard !challengeCompleted else {
            streakLabel.removeAllActions()
            streakLabel.alpha = 0
            return
        }

        streakLabel.removeAllActions()
        streakLabel.text = "SUBIDA x\(max(1, bubblesClimbed))"
        streakLabel.alpha = 1
        streakLabel.setScale(0.86)
        streakLabel.run(.sequence([
            .group([.scale(to: 1.10, duration: 0.16), .moveBy(x: 0, y: 6, duration: 0.16)]),
            .wait(forDuration: 0.26),
            .group([.fadeOut(withDuration: 0.24), .moveBy(x: 0, y: -6, duration: 0.24)])
        ]))
    }

    private func showBounceTrail(from point: CGPoint) {
        for i in 0..<6 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5.5))
            dot.fillColor = (i.isMultiple(of: 2) ? GameUI.palePaper : GameUI.accent).withAlphaComponent(0.34)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: point.x + CGFloat.random(in: -18...18),
                                   y: point.y + CGFloat.random(in: 4...18))
            dot.zPosition = 20
            contentNode.addChild(dot)
            dot.run(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: (-32)...(-14)), duration: 0.34),
                    .scale(to: 0.25, duration: 0.34),
                    .fadeOut(withDuration: 0.34)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showGoalBurst() {
        streakLabel.removeAllActions()
        streakLabel.alpha = 0

        let label = SKLabelNode(text: "META!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 30
        label.fontColor = GameUI.algae
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: areaHalf + 78)
        label.zPosition = 60
        label.setScale(0.64)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1.18, duration: 0.22),
                .fadeAlpha(to: 1, duration: 0.22)
            ]),
            .wait(forDuration: 0.36),
            .group([
                .moveBy(x: 0, y: 38, duration: 0.34),
                .fadeOut(withDuration: 0.34),
                .scale(to: 0.90, duration: 0.34)
            ]),
            .removeFromParent()
        ]))
    }

    private func scrollCamera() {
        let upperComfortY = areaHalfY * 0.30
        let mermaidViewY = viewY(forContentY: mermaidNode.position.y)
        if mermaidViewY > upperComfortY {
            contentNode.position.y -= (mermaidViewY - upperComfortY)
        }
    }

    private func cullPlatforms() {
        for bubble in bubbles where bubble !== currentPlatform {
            if bubble.popped && bubble.parent == nil {
                continue
            }
            if viewY(forContentY: bubble.position.y) < -areaHalfY - 100 {
                bubble.popped = true
                bubble.removeFromParent()
            }
        }
        bubbles.removeAll { $0.parent == nil }
    }

    // MARK: - Controle horizontal

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if finished {
            handleFinishedTap(at: location)
            return
        }

        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "climb_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish()
                return
            }
            node = current.parent
        }

        guard isInsidePlayArea(location) else { return }
        updateTouchControl(at: location)
        if let platform = currentPlatform, !timerRunning {
            bounce(from: platform)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if isInsidePlayArea(location) {
            updateTouchControl(at: location)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchControl = 0
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchControl = 0
    }

    private func isInsidePlayArea(_ location: CGPoint) -> Bool {
        abs(location.x - areaCenter.x) <= areaHalf &&
            abs(location.y - areaCenter.y) <= areaHalfY
    }

    private func updateTouchControl(at location: CGPoint) {
        let relativeX = (location.x - areaCenter.x) / max(1, areaHalf)
        let clamped = relativeX.clamped(to: -1...1)
        touchControl = clamped * abs(clamped)
    }

    private func startMotionControl() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates()
    }

    private func updateMotionControl() {
        guard let motion = motionManager.deviceMotion else {
            motionControl = 0
            return
        }
        let tilt = (CGFloat(motion.gravity.x) * 1.45).clamped(to: -1...1)
        motionControl = tilt * abs(tilt)
    }

    // MARK: - Fim

    private func finish() {
        guard !finished else { return }
        finished = true
        touchControl = 0
        updateTimerLabels()
        GameAudio.shared.play(challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: pointScore,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 100
        addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 8
        panel.addChild(panelContent)

        let titleLabel = SKLabelNode(text: reached ? "Desafio concluído!" : "Boa tentativa!")
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 19
        titleLabel.fontColor = GameUI.ink
        titleLabel.position = CGPoint(x: 0, y: 60)
        panelContent.addChild(titleLabel)

        let scoreText = "Pontos feitos: \(pointScore)"
        let scoreLine = SKLabelNode(text: scoreText)
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.position = CGPoint(x: 0, y: 24)
        panelContent.addChild(scoreLine)

        let rewardLine = SKLabelNode(text: "Convertendo pontos...")
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.position = CGPoint(x: 0, y: -10)
        panelContent.addChild(rewardLine)
        ChallengeChrome.animatePointConversion(label: rewardLine, points: pointScore, pearls: pearls)

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "climb_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        panelContent.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .ascent,
                                        points: pointScore,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        special: special,
                                        isHatching: false)
    }

    private func makeResultPanel(reached: Bool) -> SKNode {
        let resultTint = reached
            ? GameUI.algae.withAlphaComponent(0.82)
            : GameUI.coral.withAlphaComponent(0.82)
        let panel = GameUI.card(size: CGSize(width: 290, height: 220),
                                cornerRadius: 24,
                                tint: resultTint,
                                baseColors: [UIColor.lerp(GameUI.palePaper, resultTint, 0.28)])
        let wash = SKShapeNode(rectOf: CGSize(width: 278, height: 208), cornerRadius: 20)
        wash.fillColor = resultTint.withAlphaComponent(0.08)
        wash.strokeColor = .clear
        wash.zPosition = 0.5
        panel.addChild(wash)
        return panel
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "climb_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
