//
//  ShelterSystem.swift
//  Ester
//
//  Refúgio das Marés: um espaço pessoal mágico acessível de qualquer
//  lugar do oceano (dimensão de bolso, não um ponto físico do mundo).
//  Lá a sereia descansa e mostra suas memórias. Ao sair, ela continua
//  de onde estava.
//

import Foundation
import SpriteKit

// MARK: - Portal do Refúgio (nó no mundo)

/// Pequeno portal mágico que se abre perto da sereia; ela nada até ele,
/// entra, e só então o Refúgio aparece.
final class RefugePortalNode: SKNode {
    private static let sparkTexture = SKTexture(imageNamed: "spark")
    private static let bokehTexture = SKTexture(imageNamed: "bokeh")
    private static let bubbleTexture = SKTexture(imageNamed: "bubble")

    private let backAura = SKShapeNode(ellipseOf: CGSize(width: 150, height: 220))
    private let outerRing = SKShapeNode(ellipseOf: CGSize(width: 112, height: 174))
    private let middleRing = SKShapeNode(ellipseOf: CGSize(width: 84, height: 134))
    private let innerSwirl = SKShapeNode(ellipseOf: CGSize(width: 62, height: 106))
    private let tideWell = SKShapeNode(ellipseOf: CGSize(width: 42, height: 78))
    private let core = SKShapeNode(ellipseOf: CGSize(width: 18, height: 42))
    private let threadLayer = SKNode()
    private let orbitLayer = SKNode()
    private var particleEmitters: [(node: SKEmitterNode, birthRate: CGFloat)] = []

    override init() {
        super.init()
        zPosition = 9

        backAura.fillColor = UIColor(red: 0.16, green: 0.74, blue: 0.82, alpha: 0.05)
        backAura.strokeColor = UIColor(red: 0.75, green: 1.0, blue: 0.95, alpha: 0.09)
        backAura.lineWidth = 1.2
        backAura.glowWidth = 18
        backAura.blendMode = .add
        backAura.zPosition = -4
        addChild(backAura)

        outerRing.fillColor = UIColor(red: 0.22, green: 0.12, blue: 0.48, alpha: 0.18)
        outerRing.strokeColor = UIColor(red: 0.73, green: 0.95, blue: 1.0, alpha: 0.58)
        outerRing.lineWidth = 2.2
        outerRing.glowWidth = 10
        outerRing.blendMode = .add
        outerRing.zPosition = -1
        addChild(outerRing)

        middleRing.fillColor = UIColor(red: 0.18, green: 0.62, blue: 0.72, alpha: 0.08)
        middleRing.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 1.0, alpha: 0.32)
        middleRing.lineWidth = 1.0
        middleRing.glowWidth = 5
        middleRing.blendMode = .add
        middleRing.zPosition = 0
        addChild(middleRing)

        threadLayer.zPosition = 1
        addChild(threadLayer)
        buildTideThreads()

        innerSwirl.fillColor = UIColor(red: 0.48, green: 0.28, blue: 0.88, alpha: 0.12)
        innerSwirl.strokeColor = UIColor(red: 0.86, green: 1.0, blue: 0.96, alpha: 0.38)
        innerSwirl.lineWidth = 1.0
        innerSwirl.glowWidth = 5
        innerSwirl.blendMode = .add
        innerSwirl.zPosition = 2
        addChild(innerSwirl)

        tideWell.fillColor = UIColor(red: 0.02, green: 0.08, blue: 0.20, alpha: 0.52)
        tideWell.strokeColor = UIColor(red: 0.36, green: 0.94, blue: 0.98, alpha: 0.24)
        tideWell.lineWidth = 0.9
        tideWell.glowWidth = 5
        tideWell.zPosition = 3
        addChild(tideWell)

        core.fillColor = UIColor(red: 0.95, green: 1.0, blue: 0.88, alpha: 0.56)
        core.strokeColor = .clear
        core.glowWidth = 7
        core.blendMode = .add
        core.zPosition = 4
        addChild(core)

        orbitLayer.zPosition = 5
        addChild(orbitLayer)
        buildOrbitingSparks()
        buildParticleEmitters()

        // começa fechado
        setScale(0.01)
        alpha = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Abre devagar, com um giro suave — nada de pressa.
    func open() {
        setEmittersActive(true)

        let grow = SKAction.scale(to: 1.0, duration: 1.05)
        grow.eaeInEaseOut()
        run(.group([.fadeIn(withDuration: 0.7), grow]))
        backAura.run(.repeatForever(.sequence([
            .scale(to: 1.03, duration: 1.7),
            .scale(to: 0.99, duration: 1.7)
        ])))
        outerRing.run(.repeatForever(.sequence([
            .scale(to: 1.035, duration: 1.25),
            .scale(to: 1.0, duration: 1.0)
        ])))
        middleRing.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.36, duration: 1.0),
            .fadeAlpha(to: 0.78, duration: 1.3)
        ])))
        innerSwirl.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 6.0)))
        threadLayer.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 10.0)))
        orbitLayer.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 8.5)))
        tideWell.run(.repeatForever(.sequence([
            .scale(to: 0.96, duration: 1.1),
            .scale(to: 1.02, duration: 1.3)
        ])))
        core.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.26, duration: 0.8),
            .fadeAlpha(to: 0.64, duration: 1.0)
        ])))
    }

    /// Fecha e some do mundo.
    func close(after delay: TimeInterval = 0) {
        run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in self?.setEmittersActive(false) },
            .group([.scale(to: 0.01, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent()
        ]))
    }

    private func buildTideThreads() {
        for i in 0..<5 {
            let t = CGFloat(i) / 4
            let y = -48 + 96 * t
            let width = 34 + sin(t * .pi) * 38
            let bow = CGFloat(i.isMultiple(of: 2) ? 1 : -1) * CGFloat.random(in: 8...14)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width / 2, y: y - 10))
            path.addCurve(to: CGPoint(x: width / 2, y: y + 10),
                          controlPoint1: CGPoint(x: -width * 0.14, y: y + bow),
                          controlPoint2: CGPoint(x: width * 0.18, y: y - bow))

            let thread = SKShapeNode(path: path.cgPath)
            let mix = CGFloat(i) / 8
            thread.strokeColor = UIColor.lerp(UIColor(red: 0.48, green: 0.96, blue: 1.0, alpha: 0.42),
                                              UIColor(red: 1.0, green: 0.76, blue: 0.98, alpha: 0.38),
                                              mix)
            thread.lineWidth = CGFloat.random(in: 0.7...1.4)
            thread.glowWidth = CGFloat.random(in: 1.5...4)
            thread.lineCap = .round
            thread.blendMode = .add
            thread.alpha = CGFloat.random(in: 0.18...0.38)
            thread.zRotation = CGFloat.random(in: -0.18...0.18)
            threadLayer.addChild(thread)

            thread.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.08, duration: Double.random(in: 0.9...1.4)),
                .fadeAlpha(to: thread.alpha, duration: Double.random(in: 0.8...1.4))
            ])))
        }
    }

    private func buildOrbitingSparks() {
        for i in 0..<8 {
            let angle = CGFloat(i) / 8 * .pi * 2
            let spark = SKSpriteNode(texture: Self.sparkTexture)
            let pointSize = CGFloat.random(in: 4...8)
            spark.size = CGSize(width: pointSize, height: pointSize)
            spark.position = CGPoint(x: cos(angle) * CGFloat.random(in: 48...62),
                                     y: sin(angle) * CGFloat.random(in: 68...88))
            spark.zRotation = angle
            spark.alpha = CGFloat.random(in: 0.18...0.42)
            spark.color = i.isMultiple(of: 3)
                ? UIColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 1)
                : UIColor(red: 0.74, green: 1.0, blue: 0.96, alpha: 1)
            spark.colorBlendFactor = 0.55
            spark.blendMode = .add
            orbitLayer.addChild(spark)

            let pulse = SKAction.sequence([
                .scale(to: 0.75, duration: Double.random(in: 0.65...1.0)),
                .scale(to: 1.08, duration: Double.random(in: 0.65...1.0))
            ])
            spark.run(.repeatForever(.group([
                pulse,
                .rotate(byAngle: .pi * 2, duration: Double.random(in: 2.0...3.5))
            ])))
        }
    }

    private func buildParticleEmitters() {
        addParticleEmitter(texture: Self.bokehTexture,
                           birthRate: 3,
                           lifetime: 3.2,
                           speed: 8,
                           positionRange: CGVector(dx: 64, dy: 104),
                           scale: 0.2,
                           scaleRange: 0.12,
                           alpha: 0.12,
                           color: UIColor(red: 0.34, green: 0.95, blue: 1.0, alpha: 1),
                           zPosition: -2)
        addParticleEmitter(texture: Self.sparkTexture,
                           birthRate: 7,
                           lifetime: 1.6,
                           speed: 26,
                           positionRange: CGVector(dx: 84, dy: 128),
                           scale: 0.07,
                           scaleRange: 0.04,
                           alpha: 0.28,
                           color: UIColor(red: 1.0, green: 0.82, blue: 0.36, alpha: 1),
                           zPosition: 6)
        addParticleEmitter(texture: Self.sparkTexture,
                           birthRate: 5,
                           lifetime: 2.2,
                           speed: 18,
                           positionRange: CGVector(dx: 48, dy: 88),
                           scale: 0.1,
                           scaleRange: 0.06,
                           alpha: 0.22,
                           color: UIColor(red: 0.88, green: 0.72, blue: 1.0, alpha: 1),
                           zPosition: 2)
        addBubbleEmitter()
    }

    private func addBubbleEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = Self.bubbleTexture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 2.4
        emitter.particleLifetimeRange = 0.9
        emitter.particleSpeed = 34
        emitter.particleSpeedRange = 16
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 5
        emitter.particlePositionRange = CGVector(dx: 76, dy: 26)
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.04
        emitter.particleScaleSpeed = -0.018
        emitter.particleAlpha = 0.26
        emitter.particleAlphaRange = 0.12
        emitter.particleAlphaSpeed = -0.12
        emitter.particleColor = UIColor(red: 0.78, green: 1.0, blue: 0.96, alpha: 1)
        emitter.particleColorBlendFactor = 0.55
        emitter.particleBlendMode = .alpha
        emitter.zPosition = 4
        addChild(emitter)
        particleEmitters.append((node: emitter, birthRate: 14))
    }

    private func addParticleEmitter(texture: SKTexture,
                                    birthRate: CGFloat,
                                    lifetime: CGFloat,
                                    speed: CGFloat,
                                    positionRange: CGVector,
                                    scale: CGFloat,
                                    scaleRange: CGFloat,
                                    alpha: CGFloat,
                                    color: UIColor,
                                    zPosition: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = lifetime
        emitter.particleLifetimeRange = lifetime * 0.38
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.8
        emitter.emissionAngleRange = .pi * 2
        emitter.particlePositionRange = positionRange
        emitter.particleScale = scale
        emitter.particleScaleRange = scaleRange
        emitter.particleScaleSpeed = -scale / max(lifetime, 0.1)
        emitter.particleAlpha = alpha
        emitter.particleAlphaRange = alpha * 0.45
        emitter.particleAlphaSpeed = -alpha / max(lifetime, 0.1)
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = .pi
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.zPosition = zPosition
        addChild(emitter)
        particleEmitters.append((node: emitter, birthRate: birthRate))
    }

    private func setEmittersActive(_ active: Bool) {
        for emitter in particleEmitters {
            emitter.node.particleBirthRate = active ? emitter.birthRate : 0
        }
    }
}

// MARK: - Cena do Refúgio (camada modal)

final class RefugeOverlay: SKNode {
    unowned let ctx: GameContext
    private let onClose: () -> Void
    private let overlaySize: CGSize

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var careLabel: SKLabelNode!
    private var upgradeLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var displayMermaid: Mermaid?
    private var enhancementsOverlay: RefugeEnhancementsOverlay?
    private let safeAreaInsets: UIEdgeInsets

    init(size: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         onClose: @escaping () -> Void) {
        self.ctx = ctx
        self.onClose = onClose
        self.overlaySize = size
        self.safeAreaInsets = insets
        super.init()
        isUserInteractionEnabled = true
        build(size: size, insets: insets)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Construção

    private func build(size: CGSize, insets: UIEdgeInsets) {
        let topEdge = size.height / 2 - insets.top
        let bottomEdge = -size.height / 2 + insets.bottom

        // página do diário do refúgio
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillTexture = GameUI.paperTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                                   base: GameUI.palePaper)
        backdrop.fillColor = .white
        backdrop.strokeColor = .clear
        addChild(backdrop)

        // bolhas suaves subindo
        for i in 0..<6 {
            let bubble = SKShapeNode(circleOfRadius: .random(in: 4...10))
            bubble.fillColor = GameUI.accent.withAlphaComponent(0.08)
            bubble.strokeColor = GameUI.accent.withAlphaComponent(0.24)
            bubble.position = CGPoint(x: .random(in: -size.width / 2...size.width / 2),
                                      y: .random(in: -size.height / 2...0))
            addChild(bubble)
            let rise = SKAction.repeatForever(.sequence([
                .moveBy(x: .random(in: -20...20), y: size.height, duration: Double.random(in: 9...14)),
                .run { bubble.position.y = -size.height / 2 }
            ]))
            bubble.run(.sequence([.wait(forDuration: Double(i)), rise]))
        }

        let title = SKLabelNode(text: "Registro do Refúgio")
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 21
        title.fontColor = GameUI.ink
        title.position = CGPoint(x: 0, y: topEdge - 52)
        addChild(title)

        let subtitle = SKLabelNode(text: "abrigo portátil catalogado para descanso e cuidado")
        subtitle.fontName = "AvenirNext-Regular"
        subtitle.fontSize = 12
        subtitle.fontColor = GameUI.mutedInk
        subtitle.position = CGPoint(x: 0, y: topEdge - 72)
        addChild(subtitle)

        // ---- Layout vertical sem sobreposição ----
        // botões (uma linha) embaixo, cartão acima deles e a sereia no
        // espaço restante entre o subtítulo e o cartão.
        let buttonRowY = bottomEdge + 60
        let buttonHeight: CGFloat = 48
        let cardHeight: CGFloat = 176
        let cardCenterY = buttonRowY + buttonHeight / 2 + 18 + cardHeight / 2
        let cardTopY = cardCenterY + cardHeight / 2
        let stageTopY = topEdge - 100
        let stageBottomY = cardTopY + 24
        let stageCenterY = (stageTopY + stageBottomY) / 2
        let stageHeight = max(140, stageTopY - stageBottomY)

        // halo de concha atrás da sereia
        let haloRadius = min(size.width * 0.46, stageHeight * 0.56)
        let halo = SKShapeNode(circleOfRadius: haloRadius)
        halo.fillColor = GameUI.paper.withAlphaComponent(0.42)
        halo.strokeColor = GameUI.coral.withAlphaComponent(0.25)
        halo.glowWidth = 0
        halo.position = CGPoint(x: 0, y: stageCenterY)
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.6, duration: 2.2),
            .fadeAlpha(to: 1.0, duration: 2.2)
        ])))

        // sereia em destaque: a forma da FASE ATUAL (bebê mostra bebê!),
        // com paleta clara — o Refúgio é um lugar iluminado.
        let mermaid = Mermaid()
        if ctx.stats.phase != .egg {
            mermaid.setForm(for: ctx.stats.phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.idle)
        let targetMermaidHeight = min(stageHeight * 0.72,
                                      size.height * 0.36,
                                      size.width * 0.76)
        let scale = ChallengeChrome.fitScale(for: mermaid.base,
                                             targetHeight: targetMermaidHeight)
        mermaid.base.setScale(scale)
        mermaid.base.alpha = 1
        let mermaidFrame = mermaid.base.calculateAccumulatedFrame()
        mermaid.base.position = CGPoint(x: 0, y: stageCenterY - mermaidFrame.midY)
        mermaid.base.zPosition = 2
        addChild(mermaid.base)
        displayMermaid = mermaid

        // cartão de estado (conteúdo cabe dentro do cartão)
        let card = GameUI.card(size: CGSize(width: size.width - 48, height: cardHeight),
                               cornerRadius: 10,
                               tint: GameUI.accent.withAlphaComponent(0.72))
        card.position = CGPoint(x: 0, y: cardCenterY)
        card.zPosition = 3
        addChild(card)

        statusLabel = makeLabel(fontSize: 13, bold: true)
        statusLabel.position = CGPoint(x: 0, y: 64)
        statusLabel.preferredMaxLayoutWidth = size.width - 80
        statusLabel.numberOfLines = 1
        card.addChild(statusLabel)

        foodLabel = makeLabel(fontSize: 13)
        foodLabel.position = CGPoint(x: 0, y: 39)
        foodLabel.preferredMaxLayoutWidth = size.width - 80
        foodLabel.numberOfLines = 1
        card.addChild(foodLabel)

        careLabel = makeLabel(fontSize: 13)
        careLabel.position = CGPoint(x: 0, y: 17)
        careLabel.preferredMaxLayoutWidth = size.width - 80
        careLabel.numberOfLines = 1
        card.addChild(careLabel)

        pearlsLabel = makeLabel(fontSize: 13)
        pearlsLabel.position = CGPoint(x: 0, y: -8)
        pearlsLabel.preferredMaxLayoutWidth = size.width - 80
        pearlsLabel.numberOfLines = 1
        card.addChild(pearlsLabel)

        // memórias recentes
        let memoriesTitle = makeLabel(fontSize: 12, bold: true)
        memoriesTitle.text = "Memórias recentes"
        memoriesTitle.fontColor = GameUI.accent
        memoriesTitle.position = CGPoint(x: 0, y: -37)
        card.addChild(memoriesTitle)

        let memories = ctx.stats.memories.suffix(2)
        let memoryText = memories.isEmpty
            ? "Nenhuma memória registrada. Explore o oceano."
            : memories.joined(separator: "  ·  ")
        let memoriesLabel = makeLabel(fontSize: 11)
        memoriesLabel.text = memoryText
        memoriesLabel.fontColor = GameUI.mutedInk
        memoriesLabel.preferredMaxLayoutWidth = size.width - 80
        memoriesLabel.numberOfLines = 2
        memoriesLabel.lineBreakMode = .byWordWrapping
        memoriesLabel.position = CGPoint(x: 0, y: -64)
        card.addChild(memoriesLabel)

        // botões: aprimoramentos e voltar. Acelerar fica dentro de aprimoramentos.
        let buttonWidth = (size.width - 72) / 2
        let actions: [(name: String, text: String, color: UIColor, column: Int)] = [
            ("refuge_enhancements", "Aprimoramentos", GameUI.gold, 0),
            ("refuge_close", "Voltar", GameUI.accent, 1)
        ]
        for action in actions {
            let x = -size.width / 2 + 24 + buttonWidth / 2 + CGFloat(action.column) * (buttonWidth + 24)
            let button = SKNode()
            button.name = action.name
            button.position = CGPoint(x: x, y: buttonRowY)
            button.zPosition = 3
            let card = GameUI.card(size: CGSize(width: buttonWidth, height: 48),
                                   cornerRadius: 9,
                                   tint: action.color)
            button.addChild(card)
            addChild(button)

            let label = makeLabel(fontSize: 11.5, bold: true)
            label.text = action.text
            label.verticalAlignmentMode = .center
            label.preferredMaxLayoutWidth = buttonWidth - 10
            label.numberOfLines = 2
            label.name = action.name
            label.zPosition = 5
            button.addChild(label)

            if action.name == "refuge_enhancements" {
                upgradeLabel = label
            }
        }

        refreshLabels()
    }

    private func makeLabel(fontSize: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = GameUI.ink
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        refreshTimer -= dt
        if refreshTimer <= 0 {
            refreshTimer = 0.5
            refreshLabels()
        }
    }

    private func refreshLabels() {
        let stats = ctx.stats!
        statusLabel.text = "\(stats.phase.displayName) · \(stats.ageText) · repouso observado"
        foodLabel.text = ctx.growth.evolutionNote()
        careLabel.text = "Energia \(Int(stats.energy))% · Alimentação \(Int(100 - stats.hunger))%"
        pearlsLabel.text = "Conchas \(GameUI.shellAmountText(stats.pearls))"
        upgradeLabel.text = "Aprimoramentos"
    }

    private func openEnhancements() {
        enhancementsOverlay?.removeFromParent()
        let overlay = RefugeEnhancementsOverlay(size: overlaySize,
                                                insets: safeAreaInsets,
                                                stats: ctx.stats)
        overlay.zPosition = 20
        addChild(overlay)
        enhancementsOverlay = overlay
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            switch current.name {
            case "refuge_enhancements":
                GameAudio.shared.play(.uiOpenPanel)
                openEnhancements()
                refreshLabels()
                return
            case "enhancements_close":
                GameAudio.shared.play(.uiClosePanel)
                enhancementsOverlay?.removeFromParent()
                enhancementsOverlay = nil
                refreshLabels()
                return
            case let name? where name.hasPrefix("upgrade_"):
                guard let raw = name.split(separator: "_").last,
                      let kind = MermaidStats.UpgradeKind(rawValue: String(raw)) else { return }
                if let cost = ctx.stats.upgradeCost(for: kind) {
                    guard ctx.stats.pearls >= cost else {
                        GameAudio.shared.play(.uiUpgradeFail)
                        ctx.say("\(kind.title) custa \(GameUI.shellAmountText(cost)) conchas. Faltam \(GameUI.shellAmountText(cost - ctx.stats.pearls)) conchas.")
                        return
                    }
                    if ctx.stats.buyUpgrade(kind) {
                        GameAudio.shared.play(.uiUpgradeBuy)
                        ctx.say("\(kind.title) melhorado para o nível \(ctx.stats.upgradeLevel(for: kind)).")
                        enhancementsOverlay?.removeFromParent()
                        enhancementsOverlay = nil
                        openEnhancements()
                        refreshLabels()
                    }
                } else {
                    GameAudio.shared.play(.uiUpgradeFail)
                    ctx.say("\(kind.title) já chegou ao nível máximo.")
                }
                return
            case "growth_accelerate":
                if ctx.growth.spendShellsForGrowth() {
                    GameAudio.shared.play(.uiUpgradeBuy)
                    enhancementsOverlay?.removeFromParent()
                    enhancementsOverlay = nil
                    openEnhancements()
                } else {
                    GameAudio.shared.play(.uiUpgradeFail)
                }
                refreshLabels()
                return
            case "refuge_close":
                GameAudio.shared.play(.uiClosePanel)
                onClose()
                return
            default:
                node = current.parent
            }
        }
    }
}

final class RefugeEnhancementsOverlay: SKNode {
    private let stats: MermaidStats
    private let insets: UIEdgeInsets

    init(size: CGSize, insets: UIEdgeInsets, stats: MermaidStats) {
        self.stats = stats
        self.insets = insets
        super.init()
        isUserInteractionEnabled = false
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size: CGSize) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = GameUI.palePaper
        backdrop.strokeColor = GameUI.accent.withAlphaComponent(0.2)
        backdrop.zPosition = 0
        addChild(backdrop)

        let top = size.height / 2 - insets.top
        let title = makeLabel(text: "Aprimoramentos", fontSize: 21, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: 0, y: top - 42)
        title.zPosition = 2
        addChild(title)

        let subtitle = makeLabel(text: "aprimoramentos comprados com conchas", fontSize: 12, color: GameUI.mutedInk)
        subtitle.position = CGPoint(x: 0, y: top - 66)
        subtitle.zPosition = 2
        addChild(subtitle)

        let pearlLine = makeLabel(text: "Conchas \(GameUI.shellAmountText(stats.pearls))", fontSize: 13, bold: true, color: GameUI.gold)
        pearlLine.position = CGPoint(x: 0, y: top - 92)
        pearlLine.zPosition = 2
        addChild(pearlLine)

        let rowWidth = min(size.width - 28, 420)
        let rowCount = MermaidStats.UpgradeKind.allCases.count + 1
        let availableHeight = max(390, size.height - insets.top - insets.bottom - 228)
        let rowHeight = min(90, max(74, availableHeight / CGFloat(rowCount)))
        let firstY = top - 148

        for (index, kind) in MermaidStats.UpgradeKind.allCases.enumerated() {
            addRow(kind: kind,
                   width: rowWidth,
                   height: rowHeight - 8,
                   centerY: firstY - CGFloat(index) * rowHeight)
        }
        addGrowthRow(width: rowWidth,
                     height: rowHeight - 8,
                     centerY: firstY - CGFloat(MermaidStats.UpgradeKind.allCases.count) * rowHeight)

        let closeButton = SKNode()
        closeButton.name = "enhancements_close"
        closeButton.position = CGPoint(x: 0, y: -size.height / 2 + insets.bottom + 48)
        closeButton.zPosition = 4
        let closeCard = GameUI.card(size: CGSize(width: min(220, size.width - 80), height: 44),
                                    cornerRadius: 9,
                                    tint: GameUI.accent)
        closeCard.name = "enhancements_close"
        closeButton.addChild(closeCard)
        let closeLabel = makeLabel(text: "Voltar ao refúgio", fontSize: 13, bold: true, color: GameUI.ink)
        closeLabel.name = "enhancements_close"
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 5
        closeButton.addChild(closeLabel)
        addChild(closeButton)
    }

    private func addRow(kind: MermaidStats.UpgradeKind,
                        width: CGFloat,
                        height: CGFloat,
                        centerY: CGFloat) {
        let level = stats.upgradeLevel(for: kind)
        let row = SKNode()
        row.position = CGPoint(x: 0, y: centerY)
        row.zPosition = 2
        addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = UIColor.white.withAlphaComponent(0.36)
        bg.strokeColor = GameUI.accent.withAlphaComponent(0.22)
        bg.lineWidth = 1
        row.addChild(bg)

        let title = makeLabel(text: "\(kind.title)  \(level)/100", fontSize: 13, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 14, y: height / 2 - 22)
        row.addChild(title)

        let description = makeLabel(text: kind.description, fontSize: 10.5, color: GameUI.mutedInk)
        description.horizontalAlignmentMode = .left
        description.preferredMaxLayoutWidth = width - 126
        description.numberOfLines = 2
        description.lineBreakMode = .byWordWrapping
        description.position = CGPoint(x: -width / 2 + 14, y: -4)
        row.addChild(description)

        let actionName = "upgrade_\(kind.rawValue)"
        let button = SKNode()
        button.name = actionName
        button.position = CGPoint(x: width / 2 - 56, y: -4)
        button.zPosition = 4
        row.addChild(button)

        let buttonColor: UIColor = stats.upgradeCost(for: kind) == nil ? GameUI.mutedInk : GameUI.gold
        let buttonBg = GameUI.card(size: CGSize(width: 92, height: 48),
                                   cornerRadius: 8,
                                   tint: buttonColor)
        buttonBg.name = actionName
        button.addChild(buttonBg)

        let buttonText: String
        if let cost = stats.upgradeCost(for: kind) {
            buttonText = "comprar\n\(GameUI.shellAmountText(cost)) conchas"
        } else {
            buttonText = "nível\nmáximo"
        }
        let label = makeLabel(text: buttonText, fontSize: 10.5, bold: true, color: GameUI.ink)
        label.name = actionName
        label.numberOfLines = 2
        label.verticalAlignmentMode = .center
        label.zPosition = 5
        button.addChild(label)
    }

    private func addGrowthRow(width: CGFloat,
                              height: CGFloat,
                              centerY: CGFloat) {
        let row = SKNode()
        row.position = CGPoint(x: 0, y: centerY)
        row.zPosition = 2
        addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = UIColor.white.withAlphaComponent(0.36)
        bg.strokeColor = GameUI.coral.withAlphaComponent(0.28)
        bg.lineWidth = 1
        row.addChild(bg)

        let title = makeLabel(text: "Acelerar", fontSize: 13, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 14, y: height / 2 - 22)
        row.addChild(title)

        let description = makeLabel(text: "Adianta 1h da espera de crescimento.", fontSize: 10.5, color: GameUI.mutedInk)
        description.horizontalAlignmentMode = .left
        description.preferredMaxLayoutWidth = width - 126
        description.numberOfLines = 2
        description.lineBreakMode = .byWordWrapping
        description.position = CGPoint(x: -width / 2 + 14, y: -4)
        row.addChild(description)

        let actionName = "growth_accelerate"
        let button = SKNode()
        button.name = actionName
        button.position = CGPoint(x: width / 2 - 56, y: -4)
        button.zPosition = 4
        row.addChild(button)

        let buttonBg = GameUI.card(size: CGSize(width: 92, height: 48),
                                   cornerRadius: 8,
                                   tint: GameUI.coral)
        buttonBg.name = actionName
        button.addChild(buttonBg)

        let cost = GameBalance.growthShellCost(for: stats.phase)
        let label = makeLabel(text: "\(GameUI.shellAmountText(cost))\nconchas", fontSize: 10.5, bold: true, color: GameUI.ink)
        label.name = actionName
        label.numberOfLines = 2
        label.verticalAlignmentMode = .center
        label.zPosition = 5
        button.addChild(label)
    }

    private func makeLabel(text: String,
                           fontSize: CGFloat,
                           bold: Bool = false,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }
}
