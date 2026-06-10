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

    var upgradeCost: Int? {
        ctx.stats.shelterLevel < 5 ? ctx.stats.shelterLevel * 40 : nil
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
        ctx.say("Nham! Ela comeu do estoque do Refúgio 🐚")
        return true
    }

    func tryUpgrade() {
        guard let cost = upgradeCost else {
            ctx.say("O Refúgio já está no nível máximo! 🐚✨")
            return
        }
        guard ctx.stats.pearls >= cost else {
            ctx.say("Melhorar o Refúgio custa 💠\(cost). Faltam \(cost - ctx.stats.pearls).")
            return
        }
        ctx.stats.pearls -= cost
        ctx.stats.shelterLevel += 1
        ctx.stats.gainXP(20)
        ctx.say("Refúgio melhorado para o nível \(ctx.stats.shelterLevel)! 🐚✨ (+capacidade)")
    }
}

// MARK: - Cena do Refúgio (camada modal)

final class RefugeOverlay: SKNode {
    unowned let ctx: GameContext
    private let onClose: () -> Void
    private let onTide: () -> Void

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var upgradeLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var displayMermaid: Mermaid?

    init(size: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         onTide: @escaping () -> Void,
         onClose: @escaping () -> Void) {
        self.ctx = ctx
        self.onTide = onTide
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

        // fundo da dimensão mágica
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(red: 0.04, green: 0.1, blue: 0.18, alpha: 0.97)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        // halo de concha atrás da sereia
        let halo = SKShapeNode(circleOfRadius: 150)
        halo.fillColor = UIColor(red: 0.95, green: 0.8, blue: 0.85, alpha: 0.15)
        halo.strokeColor = UIColor(red: 1, green: 0.9, blue: 0.9, alpha: 0.4)
        halo.glowWidth = 26
        halo.position = CGPoint(x: 0, y: 130)
        addChild(halo)
        halo.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.6, duration: 2.2),
            .fadeAlpha(to: 1.0, duration: 2.2)
        ])))

        // bolhas suaves subindo
        for i in 0..<6 {
            let bubble = SKShapeNode(circleOfRadius: .random(in: 4...10))
            bubble.fillColor = UIColor(white: 1, alpha: 0.12)
            bubble.strokeColor = UIColor(white: 1, alpha: 0.3)
            bubble.position = CGPoint(x: .random(in: -size.width / 2...size.width / 2),
                                      y: .random(in: -size.height / 2...0))
            addChild(bubble)
            let rise = SKAction.repeatForever(.sequence([
                .moveBy(x: .random(in: -20...20), y: size.height, duration: Double.random(in: 9...14)),
                .run { bubble.position.y = -size.height / 2 }
            ]))
            bubble.run(.sequence([.wait(forDuration: Double(i)), rise]))
        }

        let title = SKLabelNode(text: "Refúgio das Marés")
        title.fontName = "Helvetica-Bold"
        title.fontSize = 21
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: topEdge - 52)
        addChild(title)

        let subtitle = SKLabelNode(text: "o cantinho mágico dela, em qualquer lugar do oceano")
        subtitle.fontName = "Helvetica"
        subtitle.fontSize = 12
        subtitle.fontColor = UIColor(white: 1, alpha: 0.6)
        subtitle.position = CGPoint(x: 0, y: topEdge - 72)
        addChild(subtitle)

        // sereia em destaque, com a paleta atual dela
        let mermaid = Mermaid()
        mermaid.base.setScale(0.34)
        mermaid.base.position = CGPoint(x: 0, y: 200)
        mermaid.applyPalette(ctx.depth.mermaidPalette(atY: ctx.mermaidPosition.y))
        mermaid.setAnimationMode(.idle)
        addChild(mermaid.base)
        displayMermaid = mermaid

        // cartão de estado
        let card = SKShapeNode(rectOf: CGSize(width: size.width - 48, height: 120), cornerRadius: 16)
        card.fillColor = UIColor(white: 1, alpha: 0.07)
        card.strokeColor = UIColor(white: 1, alpha: 0.22)
        card.position = CGPoint(x: 0, y: -95)
        addChild(card)

        statusLabel = makeLabel(fontSize: 14, bold: true)
        statusLabel.position = CGPoint(x: 0, y: 36)
        card.addChild(statusLabel)

        foodLabel = makeLabel(fontSize: 13)
        foodLabel.position = CGPoint(x: 0, y: 10)
        card.addChild(foodLabel)

        pearlsLabel = makeLabel(fontSize: 13)
        pearlsLabel.position = CGPoint(x: 0, y: -14)
        card.addChild(pearlsLabel)

        // memórias recentes
        let memoriesTitle = makeLabel(fontSize: 12, bold: true)
        memoriesTitle.text = "Memórias recentes"
        memoriesTitle.fontColor = UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 1)
        memoriesTitle.position = CGPoint(x: 0, y: -42)
        card.addChild(memoriesTitle)

        let memories = ctx.stats.memories.suffix(2)
        let memoryText = memories.isEmpty
            ? "Nenhuma memória ainda — explore o oceano ✨"
            : memories.joined(separator: "  ·  ")
        let memoriesLabel = makeLabel(fontSize: 11)
        memoriesLabel.text = memoryText
        memoriesLabel.fontColor = UIColor(white: 1, alpha: 0.65)
        memoriesLabel.preferredMaxLayoutWidth = size.width - 80
        memoriesLabel.numberOfLines = 2
        memoriesLabel.position = CGPoint(x: 0, y: -64)
        card.addChild(memoriesLabel)

        // botões de ação
        let buttonWidth = (size.width - 64) / 2
        let actions: [(name: String, text: String, color: UIColor, column: Int, row: Int)] = [
            ("refuge_feed", "Alimentar", UIColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 1), 0, 0),
            ("refuge_upgrade", "Melhorar", UIColor(red: 0.98, green: 0.8, blue: 0.4, alpha: 1), 1, 0),
            ("refuge_tide", "Trama das Marés", UIColor(red: 0.55, green: 0.8, blue: 1, alpha: 1), 0, 1),
            ("refuge_close", "Voltar ao oceano", UIColor(red: 0.45, green: 0.9, blue: 0.75, alpha: 1), 1, 1)
        ]
        for action in actions {
            let x = -size.width / 2 + 24 + buttonWidth / 2 + CGFloat(action.column) * (buttonWidth + 16)
            let y = bottomEdge + 128 - CGFloat(action.row) * 60
            let button = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: 48), cornerRadius: 14)
            button.fillColor = UIColor(white: 1, alpha: 0.08)
            button.strokeColor = action.color.withAlphaComponent(0.7)
            button.lineWidth = 1.5
            button.name = action.name
            button.position = CGPoint(x: x, y: y)
            addChild(button)

            let label = makeLabel(fontSize: 14, bold: true)
            label.text = action.text
            label.verticalAlignmentMode = .center
            label.name = action.name
            button.addChild(label)

            if action.name == "refuge_upgrade" {
                upgradeLabel = label
            }
        }

        refreshLabels()
    }

    private func makeLabel(fontSize: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontName = bold ? "Helvetica-Bold" : "Helvetica"
        label.fontSize = fontSize
        label.fontColor = .white
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
        statusLabel.text = "\(stats.phase.displayName) · \(stats.ageText) · descansando em paz 💤"
        foodLabel.text = "Comida guardada: \(stats.storedFood)/\(ctx.shelter.capacity) · Energia \(Int(stats.energy))% · Fome \(Int(stats.hunger))%"
        pearlsLabel.text = "💠 \(stats.pearls) pérolas · Refúgio nível \(stats.shelterLevel)"
        if let cost = ctx.shelter.upgradeCost {
            upgradeLabel.text = "Melhorar 💠\(cost)"
        } else {
            upgradeLabel.text = "Nível máximo ✨"
        }
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            switch current.name {
            case "refuge_feed":
                ctx.shelter.feedFromStorage()
                refreshLabels()
                return
            case "refuge_upgrade":
                ctx.shelter.tryUpgrade()
                refreshLabels()
                return
            case "refuge_tide":
                onTide()
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
