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
        if let cost = upgradeCost { return "Melhorar · \(cost) conchas" }
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
            ctx.say("Melhorar o Refúgio custa \(cost) conchas. Faltam \(cost - ctx.stats.pearls).")
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
    private let overlaySize: CGSize

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var careLabel: SKLabelNode!
    private var upgradeLabel: SKLabelNode!
    private var growthLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var displayMermaid: Mermaid?
    private var enhancementsOverlay: RefugeEnhancementsOverlay?

    init(size: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         onClose: @escaping () -> Void) {
        self.ctx = ctx
        self.onClose = onClose
        self.overlaySize = size
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

        // botões: cuidados, reduzir tempo de crescimento e voltar
        let buttonWidth = (size.width - 80) / 3
        let actions: [(name: String, text: String, color: UIColor, column: Int)] = [
            ("refuge_enhancements", "Cuidados", GameUI.gold, 0),
            ("refuge_growth", "Reduzir tempo", GameUI.coral, 1),
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

            if action.name == "refuge_enhancements" {
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
        careLabel.text = "Energia \(Int(stats.energy))% · Alimentação \(Int(100 - stats.hunger))% · Alimento \(stats.storedFood)/\(ctx.shelter.capacity)"
        pearlsLabel.text = "Conchas \(stats.pearls) · Refúgio nível \(stats.shelterLevel)"
        upgradeLabel.text = "Cuidados"
        growthLabel.text = ctx.growth.growthShellLabelText()
    }

    private func openEnhancements() {
        enhancementsOverlay?.removeFromParent()
        let overlay = RefugeEnhancementsOverlay(size: overlaySize, stats: ctx.stats)
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
                openEnhancements()
                refreshLabels()
                return
            case "enhancements_close":
                enhancementsOverlay?.removeFromParent()
                enhancementsOverlay = nil
                refreshLabels()
                return
            case let name? where name.hasPrefix("upgrade_"):
                guard let raw = name.split(separator: "_").last,
                      let kind = MermaidStats.UpgradeKind(rawValue: String(raw)) else { return }
                if let cost = ctx.stats.upgradeCost(for: kind) {
                    guard ctx.stats.pearls >= cost else {
                        ctx.say("\(kind.title) custa \(cost) conchas. Faltam \(cost - ctx.stats.pearls).")
                        return
                    }
                    if ctx.stats.buyUpgrade(kind) {
                        ctx.say("\(kind.title) melhorado para o nível \(ctx.stats.upgradeLevel(for: kind)).")
                        enhancementsOverlay?.removeFromParent()
                        enhancementsOverlay = nil
                        openEnhancements()
                        refreshLabels()
                    }
                } else {
                    ctx.say("\(kind.title) já chegou ao nível máximo.")
                }
                return
            case "refuge_growth":
                ctx.growth.spendShellsForGrowth()
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

final class RefugeEnhancementsOverlay: SKNode {
    private let stats: MermaidStats

    init(size: CGSize, stats: MermaidStats) {
        self.stats = stats
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

        let top = size.height / 2
        let title = makeLabel(text: "Cuidados da Eistrelinha", fontSize: 21, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: 0, y: top - 52)
        title.zPosition = 2
        addChild(title)

        let subtitle = makeLabel(text: "aprimoramentos comprados com conchas", fontSize: 12, color: GameUI.mutedInk)
        subtitle.position = CGPoint(x: 0, y: top - 74)
        subtitle.zPosition = 2
        addChild(subtitle)

        let pearlLine = makeLabel(text: "Conchas \(stats.pearls)", fontSize: 13, bold: true, color: GameUI.gold)
        pearlLine.position = CGPoint(x: 0, y: top - 98)
        pearlLine.zPosition = 2
        addChild(pearlLine)

        let rowWidth = min(size.width - 28, 420)
        let availableHeight = max(390, size.height - 180)
        let rowHeight = min(90, max(74, availableHeight / CGFloat(MermaidStats.UpgradeKind.allCases.count)))
        let firstY = top - 142

        for (index, kind) in MermaidStats.UpgradeKind.allCases.enumerated() {
            addRow(kind: kind,
                   width: rowWidth,
                   height: rowHeight - 8,
                   centerY: firstY - CGFloat(index) * rowHeight)
        }

        let closeButton = SKNode()
        closeButton.name = "enhancements_close"
        closeButton.position = CGPoint(x: 0, y: -size.height / 2 + 48)
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
            buttonText = "\(cost)\nconchas"
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
