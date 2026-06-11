//
//  ShelterSystem.swift
//  Ester
//
//  Refúgio das Marés: um espaço pessoal mágico acessível de qualquer
//  lugar do oceano (dimensão de bolso, não um ponto físico do mundo).
//  Lá a sereia descansa, come do estoque, evolui o refúgio e mostra
//  suas memórias. Ao sair, ela continua de onde estava.
//

import Foundation
import SpriteKit

// MARK: - Sistema (estoque e melhorias)

final class ShelterSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    var capacity: Int { ctx.stats.shelterLevel * 3 }

    private var maximumLevel: Int { MermaidPhase.adult.rawValue }

    var upgradeCost: Int? {
        guard ctx.stats.shelterLevel < maximumLevel else { return nil }
        return ctx.stats.shelterLevel * 40
    }

    var upgradeLabelText: String {
        if let cost = upgradeCost { return "Melhorar · \(cost) brilhos" }
        return "Nível máximo"
    }

    /// Guarda uma comida encontrada quando ela não está com fome.
    func storeFood() -> Bool {
        guard ctx.stats.storedFood < capacity else { return false }
        ctx.stats.storedFood += 1
        return true
    }

    /// Alimenta a sereia com o estoque do refúgio.
    @discardableResult
    func feedFromStorage() -> Bool {
        guard ctx.stats.storedFood > 0 else {
            ctx.say("O estoque do Refúgio está vazio... ela guarda comida quando está satisfeita.")
            return false
        }
        guard ctx.stats.hunger > 10 else {
            ctx.say("Ela não está com fome agora.")
            return false
        }
        ctx.stats.storedFood -= 1
        ctx.stats.hunger = max(0, ctx.stats.hunger - 28)
        ctx.stats.boostMood(5)
        ctx.say("Alimentação registrada com estoque do Refúgio.")
        return true
    }

    func tryUpgrade() {
        guard let cost = upgradeCost else {
            ctx.say("Refúgio já catalogado no nível máximo.")
            return
        }
        guard ctx.stats.pearls >= cost else {
            ctx.say("Melhorar o Refúgio custa \(cost) brilhos. Faltam \(cost - ctx.stats.pearls).")
            return
        }
        ctx.stats.pearls -= cost
        ctx.stats.shelterLevel += 1
        ctx.stats.gainXP(20)
        ctx.say("Refúgio melhorado para o nível \(ctx.stats.shelterLevel). Capacidade ampliada.")
    }
}

// MARK: - Portal do Refúgio (nó no mundo)

/// Pequeno portal mágico que se abre perto da sereia; ela nada até ele,
/// entra, e só então o Refúgio aparece.
final class RefugePortalNode: SKNode {
    private let outerRing = SKShapeNode(ellipseOf: CGSize(width: 110, height: 170))
    private let innerSwirl = SKShapeNode(ellipseOf: CGSize(width: 70, height: 120))
    private let core = SKShapeNode(ellipseOf: CGSize(width: 34, height: 64))

    override init() {
        super.init()
        zPosition = 9

        outerRing.fillColor = UIColor(red: 0.55, green: 0.4, blue: 0.85, alpha: 0.25)
        outerRing.strokeColor = UIColor(red: 0.8, green: 0.7, blue: 1, alpha: 0.9)
        outerRing.lineWidth = 3
        outerRing.glowWidth = 16
        addChild(outerRing)

        innerSwirl.fillColor = UIColor(red: 0.7, green: 0.55, blue: 0.95, alpha: 0.35)
        innerSwirl.strokeColor = UIColor(white: 1, alpha: 0.5)
        innerSwirl.lineWidth = 1.5
        innerSwirl.glowWidth = 8
        addChild(innerSwirl)

        core.fillColor = UIColor(white: 1, alpha: 0.85)
        core.strokeColor = .clear
        core.glowWidth = 10
        addChild(core)

        // começa fechado
        setScale(0.01)
        alpha = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Abre devagar, com um giro suave — nada de pressa.
    func open() {
        let grow = SKAction.scale(to: 1.0, duration: 1.1)
        grow.eaeInEaseOut()
        run(.group([.fadeIn(withDuration: 0.7), grow]))
        innerSwirl.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 5)))
        outerRing.run(.repeatForever(.sequence([
            .scale(to: 1.06, duration: 1.0),
            .scale(to: 1.0, duration: 1.0)
        ])))
        core.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.9),
            .fadeAlpha(to: 0.95, duration: 0.9)
        ])))
    }

    /// Fecha e some do mundo.
    func close(after delay: TimeInterval = 0) {
        run(.sequence([
            .wait(forDuration: delay),
            .group([.scale(to: 0.01, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent()
        ]))
    }
}

// MARK: - Cena do Refúgio (camada modal)

final class RefugeOverlay: SKNode {
    unowned let ctx: GameContext
    private let onClose: () -> Void

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var careLabel: SKLabelNode!
    private var upgradeLabel: SKLabelNode!
    private var growthLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var displayMermaid: Mermaid?

    init(size: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         onClose: @escaping () -> Void) {
        self.ctx = ctx
        self.onClose = onClose
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

        // botões: melhorar abrigo, gastar brilhos no crescimento e voltar
        let buttonWidth = (size.width - 80) / 3
        let actions: [(name: String, text: String, color: UIColor, column: Int)] = [
            ("refuge_upgrade", "Melhorar", GameUI.gold, 0),
            ("refuge_growth", "Crescer", GameUI.coral, 1),
            ("refuge_close", "Voltar", GameUI.accent, 2)
        ]
        for action in actions {
            let x = -size.width / 2 + 24 + buttonWidth / 2 + CGFloat(action.column) * (buttonWidth + 16)
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

            if action.name == "refuge_upgrade" {
                upgradeLabel = label
            } else if action.name == "refuge_growth" {
                growthLabel = label
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
        careLabel.text = "Energia \(Int(stats.energy))% · Fome \(Int(stats.hunger))% · Alimento \(stats.storedFood)/\(ctx.shelter.capacity)"
        pearlsLabel.text = "Brilhos \(stats.pearls) · Refúgio nível \(stats.shelterLevel)"
        upgradeLabel.text = ctx.shelter.upgradeLabelText
        growthLabel.text = ctx.growth.growthSparkleLabelText()
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            switch current.name {
            case "refuge_upgrade":
                ctx.shelter.tryUpgrade()
                refreshLabels()
                return
            case "refuge_growth":
                ctx.growth.spendSparklesForGrowth()
                refreshLabels()
                return
            case "refuge_close":
                onClose()
                return
            default:
                node = current.parent
            }
        }
    }
}
