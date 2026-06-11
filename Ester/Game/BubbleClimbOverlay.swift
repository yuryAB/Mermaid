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

    private var crumbling = false
    private var crumbleTimer: CGFloat = 0

    convenience init(radius: CGFloat, crumbleDuration: CGFloat, starter: Bool = false) {
        self.init(circleOfRadius: radius)
        self.radius = radius
        self.crumbleDuration = crumbleDuration
        self.permanent = starter
        fillColor = starter
            ? UIColor(red: 0.78, green: 0.93, blue: 1.0, alpha: 0.30)
            : UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 0.24)
        strokeColor = starter
            ? GameUI.gold.withAlphaComponent(0.72)
            : UIColor(white: 1, alpha: 0.78)
        lineWidth = starter ? 2.0 : 1.6
        glowWidth = starter ? 4 : 3

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
    private let rewardMultiplier: CGFloat
    private let onFinish: (ChallengeResult) -> Void

    private let areaWidth: CGFloat
    private let areaCenter = CGPoint(x: 0, y: -30)
    private var areaHalf: CGFloat { areaWidth / 2 }

    private let targetDuration: CGFloat
    private var timeLeft: CGFloat
    private var elapsedTime: CGFloat = 0
    private var timerRunning = false

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

    private let mermaidSupportOffset: CGFloat = 20
    private let gravity: CGFloat = 660
    private let jumpVelocity: CGFloat = 430
    private let horizontalAcceleration: CGFloat = 790
    private let horizontalDamping: CGFloat = 1.75
    private let maxHorizontalSpeed: CGFloat = 250
    private let maxFallSpeed: CGFloat = -500

    private var survivedSeconds: Int {
        Int(min(targetDuration, max(0, elapsedTime)).rounded(.down))
    }

    private var platformCrumbleDuration: CGFloat {
        special ? 0.95 : 1.15
    }

    init(size: CGSize,
         phase: MermaidPhase,
         palette: MermaidPalette,
         special: Bool,
         rewardMultiplier: CGFloat,
         giverDisplay: SKNode?,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.special = special
        self.rewardMultiplier = rewardMultiplier
        self.onFinish = onFinish
        self.areaWidth = min(size.width - 36, 380)
        self.targetDuration = special ? 40 : 30
        self.timeLeft = special ? 40 : 30
        super.init()
        isUserInteractionEnabled = true
        startMotionControl()
        buildChrome(size: size, giverDisplay: giverDisplay)
        buildPlayArea(phase: phase, palette: palette)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, giverDisplay: SKNode?) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.6)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        let panel = GameUI.card(size: CGSize(width: areaWidth + 28, height: areaWidth + 335),
                                cornerRadius: 26,
                                tint: GameUI.accent.withAlphaComponent(0.5))
        panel.position = CGPoint(x: 0, y: 57)
        addChild(panel)

        let subtitle = special
            ? "Bolhas frágeis em corrente forte"
            : "Sobreviva nas bolhas frágeis"
        let header = ChallengeChrome.makeHeader(kind: .ascent,
                                                subtitle: subtitle,
                                                giverDisplay: giverDisplay,
                                                width: areaWidth)
        header.position = CGPoint(x: 0, y: areaHalf + 160)
        addChild(header)

        timerLabel = SKLabelNode(text: "Tempo \(Int(targetDuration))s")
        timerLabel.fontName = "AvenirNext-DemiBold"
        timerLabel.fontSize = 16
        timerLabel.fontColor = GameUI.ink
        timerLabel.horizontalAlignmentMode = .left
        timerLabel.position = CGPoint(x: -areaHalf, y: areaHalf + 44)
        addChild(timerLabel)

        objectiveLabel = SKLabelNode(text: "Sobreviva: \(Int(targetDuration))s")
        objectiveLabel.fontName = "AvenirNext-DemiBold"
        objectiveLabel.fontSize = 16
        objectiveLabel.fontColor = GameUI.mutedInk
        objectiveLabel.horizontalAlignmentMode = .right
        objectiveLabel.position = CGPoint(x: areaHalf, y: areaHalf + 44)
        addChild(objectiveLabel)

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               height: 34)
        quit.name = "climb_quit"
        quit.position = CGPoint(x: 0, y: areaCenter.y - areaHalf - 56)
        quit.zPosition = 20
        addChild(quit)
    }

    private func buildPlayArea(phase: MermaidPhase, palette: MermaidPalette) {
        let frame = SKShapeNode(rectOf: CGSize(width: areaWidth, height: areaWidth),
                                cornerRadius: 14)
        frame.fillColor = UIColor(red: 0.03, green: 0.09, blue: 0.18, alpha: 1)
        frame.strokeColor = UIColor(white: 1, alpha: 0.2)
        frame.lineWidth = 1.5
        frame.position = areaCenter
        addChild(frame)

        let crop = SKCropNode()
        crop.position = areaCenter
        let mask = SKSpriteNode(color: .white,
                                size: CGSize(width: areaWidth - 6, height: areaWidth - 6))
        crop.maskNode = mask
        addChild(crop)
        crop.addChild(contentNode)

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
                                   position: CGPoint(x: 0, y: -areaHalf + 72),
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
        hint.position = CGPoint(x: areaCenter.x, y: areaCenter.y + areaHalf - 36)
        hint.zPosition = 20
        addChild(hint)
        hint.run(.sequence([.wait(forDuration: 3.8), .fadeOut(withDuration: 0.8), .removeFromParent()]))
    }

    private func makePlatform(radius: CGFloat,
                              position: CGPoint,
                              crumbleDuration: CGFloat,
                              starter: Bool = false) -> ClimbBubble {
        let bubble = ClimbBubble(radius: radius, crumbleDuration: crumbleDuration, starter: starter)
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
        if timerRunning {
            elapsedTime = min(targetDuration, elapsedTime + dt)
            timeLeft = max(0, targetDuration - elapsedTime)
        }
        updateTimerLabels()
        if timeLeft <= 0 {
            finish(survivedFull: true)
            return
        }

        ensurePlatformsAhead()
        updatePlatforms(dt: dt)
        updateMermaid(dt: dt)
        scrollCamera()
        cullPlatforms()
    }

    private func updateTimerLabels() {
        timerLabel.text = "Tempo \(max(0, Int(ceil(timeLeft))))s"
        objectiveLabel.text = "Sobreviva: \(Int(targetDuration))s"
    }

    private func contentY(forViewY viewY: CGFloat) -> CGFloat {
        viewY - contentNode.position.y
    }

    private func viewY(forContentY y: CGFloat) -> CGFloat {
        y + contentNode.position.y
    }

    private func ensurePlatformsAhead() {
        let targetTop = contentY(forViewY: areaHalf + 260)
        while lastPlatformPosition.y < targetTop {
            spawnPlatformAbove()
        }
    }

    private func spawnPlatformAbove() {
        let progress = min(1, elapsedTime / targetDuration)
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

        let bubble = makePlatform(radius: radius,
                                  position: CGPoint(x: x, y: lastPlatformPosition.y + yGap),
                                  crumbleDuration: platformCrumbleDuration)
        lastPlatformPosition = bubble.position
    }

    private func updatePlatforms(dt: CGFloat) {
        for bubble in bubbles where !bubble.popped {
            let wasPopped = bubble.popped
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
        applyHorizontalControl(dt: dt)
        velocity.dy = max(maxFallSpeed, velocity.dy - gravity * dt)

        mermaidNode.position.x += velocity.dx * dt
        mermaidNode.position.y += velocity.dy * dt

        wrapMermaidHorizontally()
        checkLanding(from: previousPosition)

        if viewY(forContentY: mermaidNode.position.y) < -areaHalf - 48 {
            finish(survivedFull: false)
        }
    }

    private func applyHorizontalControl(dt: CGFloat) {
        let input = activeHorizontalInput()
        if abs(input) > 0.04 {
            velocity.dx += input * horizontalAcceleration * dt
        } else {
            velocity.dx *= max(0, 1 - horizontalDamping * dt)
        }
        velocity.dx = velocity.dx.clamped(to: -maxHorizontalSpeed...maxHorizontalSpeed)
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
        bubble.beginCrumbling()
        if shouldBounce {
            bounce(from: bubble)
        }
    }

    private func detachFromPlatform() {
        guard currentPlatform != nil else { return }
        currentPlatform = nil
        velocity.dy = min(velocity.dy, 24)
        mermaid.setAnimationMode(.swing)
    }

    private func bounce(from platform: ClimbBubble) {
        if platform.permanent {
            timerRunning = true
        }
        currentPlatform = nil
        velocity.dy = jumpVelocity
        mermaid.setAnimationMode(.swing)
    }

    private func scrollCamera() {
        let upperComfortY = areaHalf * 0.18
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
            if viewY(forContentY: bubble.position.y) < -areaHalf - 100 {
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
                finish(survivedFull: false)
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
            abs(location.y - areaCenter.y) <= areaHalf
    }

    private func updateTouchControl(at location: CGPoint) {
        let relativeX = (location.x - areaCenter.x) / max(1, areaHalf)
        let clamped = relativeX.clamped(to: -1...1)
        touchControl = clamped * abs(clamped) * 0.86
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
        motionControl = tilt * abs(tilt) * 0.92
    }

    // MARK: - Fim

    private func finish(survivedFull: Bool) {
        guard !finished else { return }
        finished = true
        touchControl = 0
        if survivedFull {
            elapsedTime = targetDuration
            timeLeft = 0
            updateTimerLabels()
        }

        let seconds = survivedFull ? Int(targetDuration) : survivedSeconds
        let survivalRatio = CGFloat(seconds) / targetDuration
        var pearls = Int(20 * survivalRatio * rewardMultiplier)
        if survivedFull { pearls += 12 }
        if special { pearls = Int(CGFloat(pearls) * 1.5) }
        let xp = CGFloat(seconds) * 1.2 * (special ? 1.5 : 1)

        let resultTint = survivedFull
            ? UIColor(red: 0.5, green: 0.9, blue: 0.65, alpha: 1)
            : GameUI.accent
        let panel = GameUI.card(size: CGSize(width: 290, height: 220),
                                cornerRadius: 24,
                                tint: resultTint)
        panel.zPosition = 30
        addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 5
        panel.addChild(panelContent)

        let titleLabel = SKLabelNode(text: survivedFull ? "Desafio concluído!" : "A corrente venceu")
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 19
        titleLabel.fontColor = GameUI.ink
        titleLabel.position = CGPoint(x: 0, y: 60)
        panelContent.addChild(titleLabel)

        let scoreText = survivedFull
            ? "Sobreviveu \(seconds)s"
            : "Durou \(seconds)s"
        let scoreLine = SKLabelNode(text: scoreText)
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.position = CGPoint(x: 0, y: 24)
        panelContent.addChild(scoreLine)

        let rewardLine = SKLabelNode(text: "Brilhos +\(pearls)   XP +\(Int(xp))")
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.position = CGPoint(x: 0, y: -10)
        panelContent.addChild(rewardLine)

        let continueButton = GameUI.card(size: CGSize(width: 170, height: 44),
                                         cornerRadius: 16,
                                         tint: GameUI.accent,
                                         baseColors: [UIColor(red: 0.22, green: 0.5, blue: 0.82, alpha: 1),
                                                      UIColor(red: 0.12, green: 0.3, blue: 0.6, alpha: 1)])
        continueButton.name = "climb_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        panelContent.addChild(continueButton)

        let continueLabel = SKLabelNode(text: "Continuar")
        continueLabel.fontName = "AvenirNext-DemiBold"
        continueLabel.fontSize = 16
        continueLabel.fontColor = GameUI.ink
        continueLabel.verticalAlignmentMode = .center
        continueLabel.zPosition = 5
        continueLabel.name = "climb_continue"
        continueButton.addChild(continueLabel)

        pendingResult = ChallengeResult(kind: .ascent,
                                        score: seconds,
                                        reachedTarget: survivedFull,
                                        pearls: pearls,
                                        xp: xp,
                                        special: special,
                                        isHatching: false)
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "climb_continue", let result = pendingResult {
                pendingResult = nil
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
