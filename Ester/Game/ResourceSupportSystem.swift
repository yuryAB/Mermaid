//
//  ResourceSupportSystem.swift
//  Ester
//
//  Catalogs and runtime rules for observer-sent support resources.
//

import Foundation
import SpriteKit
import UIKit

enum SupportResourceKind: String, CaseIterable, Codable, Equatable {
    case foodBag
    case calmShell
    case currentAmpoule
    case coralToy
    case growthPotion
    case powerfulGrowthPotion

    private static let challengeRewardExcludedRawValues: Set<String> = ["growthPotion", "powerfulGrowthPotion"]

    var itemId: String { "support_\(rawValue)" }

    static var challengeRewardCandidates: [SupportResourceKind] {
        allCases.filter(\.canDropFromChallengeCompletion)
    }

    var canDropFromChallengeCompletion: Bool {
        !Self.challengeRewardExcludedRawValues.contains(rawValue)
    }

    var title: String {
        switch self {
        case .foodBag: return "Saco de comida"
        case .calmShell: return "Concha calma"
        case .currentAmpoule: return "Ampola corrente"
        case .coralToy: return "Brinquedo coral"
        case .growthPotion: return "Porção acelerar"
        case .powerfulGrowthPotion: return "Poção de crescimento poderosa"
        }
    }

    var shortTitle: String {
        switch self {
        case .foodBag: return "Comida"
        case .calmShell: return "Calma"
        case .currentAmpoule: return "Corrente"
        case .coralToy: return "Brinquedo"
        case .growthPotion: return "Acelerar"
        case .powerfulGrowthPotion: return "Poção +1d"
        }
    }

    var blurb: String {
        switch self {
        case .foodBag:
            return "Reduz 22 de fome, melhora humor e aumenta a confiança."
        case .calmShell:
            return "Diminui o medo por até 18 segundos e melhora o humor."
        case .currentAmpoule:
            return "Restaura 12 de energia e ativa nado acelerado por 5 minutos."
        case .coralToy:
            return "Aumenta humor em 16 e melhora a aceitação de pedidos por 5 minutos."
        case .growthPotion:
            return "Adiantam 1 hora da espera de crescimento."
        case .powerfulGrowthPotion:
            return "Adiantam 1 dia da espera de crescimento."
        }
    }

    var deliveredMessage: String {
        switch self {
        case .foodBag:
            return "Recurso enviado: ela recebeu comida e se alimentou."
        case .calmShell:
            return "Recurso enviado: ela se acalmou com a concha."
        case .currentAmpoule:
            return "Recurso enviado: uma corrente suave envolve a sereia."
        case .coralToy:
            return "Recurso enviado: ela ficou curiosa com o brinquedo de coral."
        case .growthPotion:
            return "Recurso enviado: ela recebeu a porção de acelerar."
        case .powerfulGrowthPotion:
            return "Recurso enviado: ela recebeu a poção de crescimento poderosa."
        }
    }

    var missingMessage: String {
        "\(title) não está no estoque do Refúgio."
    }

    var tint: UIColor {
        switch self {
        case .foodBag:
            return UIColor(red: 0.36, green: 0.58, blue: 0.32, alpha: 1)
        case .calmShell:
            return UIColor(red: 0.42, green: 0.74, blue: 0.78, alpha: 1)
        case .currentAmpoule:
            return UIColor(red: 0.22, green: 0.54, blue: 0.86, alpha: 1)
        case .coralToy:
            return UIColor(red: 0.82, green: 0.38, blue: 0.42, alpha: 1)
        case .growthPotion:
            return GameUI.coral
        case .powerfulGrowthPotion:
            return UIColor(red: 0.72, green: 0.36, blue: 0.92, alpha: 1)
        }
    }

    var glyph: String {
        switch self {
        case .foodBag: return "F"
        case .calmShell: return "C"
        case .currentAmpoule: return "N"
        case .coralToy: return "B"
        case .growthPotion: return "H"
        case .powerfulGrowthPotion: return "D"
        }
    }

    var symbolName: String {
        switch self {
        case .foodBag: return "shippingbox.fill"
        case .calmShell: return "seal.fill"
        case .currentAmpoule: return "drop.fill"
        case .coralToy: return "sparkles"
        case .growthPotion: return "hourglass"
        case .powerfulGrowthPotion: return "hourglass.badge.plus"
        }
    }
}

enum RefugeShopPurchase {
    case resource(SupportResourceKind, quantity: Int)
}

struct RefugeShopItem {
    let id: String
    let title: String
    let blurb: String
    let cost: Int
    let tint: UIColor
    let symbolName: String
    let fallbackGlyph: String
    let purchase: RefugeShopPurchase
    var availableWeekdays: Set<Int>? = nil

    func isAvailable(on date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let availableWeekdays else { return true }
        return availableWeekdays.contains(calendar.component(.weekday, from: date))
    }
}

enum RefugeShopCatalog {
    private static let mondayWeekday = 2

    static let items: [RefugeShopItem] = [
        RefugeShopItem(id: "food_bag",
                       title: "Saco de comida",
                       blurb: "Cura 22 de fome, melhora humor e aumenta a confiança.",
                       cost: 80,
                       tint: SupportResourceKind.foodBag.tint,
                       symbolName: SupportResourceKind.foodBag.symbolName,
                       fallbackGlyph: SupportResourceKind.foodBag.glyph,
                       purchase: .resource(.foodBag, quantity: 1)),
        RefugeShopItem(id: "calm_shell",
                       title: "Concha calma",
                       blurb: "Diminui o medo por até 18 segundos e melhora o humor.",
                       cost: 180,
                       tint: SupportResourceKind.calmShell.tint,
                       symbolName: SupportResourceKind.calmShell.symbolName,
                       fallbackGlyph: SupportResourceKind.calmShell.glyph,
                       purchase: .resource(.calmShell, quantity: 1)),
        RefugeShopItem(id: "current_ampoule",
                       title: "Ampola corrente",
                       blurb: "Restaura 12 de energia e ativa nado acelerado por 5 minutos.",
                       cost: 260,
                       tint: SupportResourceKind.currentAmpoule.tint,
                       symbolName: SupportResourceKind.currentAmpoule.symbolName,
                       fallbackGlyph: SupportResourceKind.currentAmpoule.glyph,
                       purchase: .resource(.currentAmpoule, quantity: 1)),
        RefugeShopItem(id: "coral_toy",
                       title: "Brinquedo coral",
                       blurb: "Aumenta humor em 16 e melhora a aceitação de pedidos por 5 minutos.",
                       cost: 220,
                       tint: SupportResourceKind.coralToy.tint,
                       symbolName: SupportResourceKind.coralToy.symbolName,
                       fallbackGlyph: SupportResourceKind.coralToy.glyph,
                       purchase: .resource(.coralToy, quantity: 1)),
        RefugeShopItem(id: "growth_potion",
                       title: "Porção acelerar",
                       blurb: "Adiantam 1 hora da espera de crescimento.",
                       cost: GameBalance.growthAccelerateShellCost,
                       tint: SupportResourceKind.growthPotion.tint,
                       symbolName: SupportResourceKind.growthPotion.symbolName,
                       fallbackGlyph: SupportResourceKind.growthPotion.glyph,
                       purchase: .resource(.growthPotion, quantity: 1)),
        RefugeShopItem(id: "powerful_growth_potion",
                       title: "Poção de crescimento poderosa",
                       blurb: "Adiantam 1 dia da espera de crescimento. Só fica disponível às segundas-feiras.",
                       cost: 20_000,
                       tint: SupportResourceKind.powerfulGrowthPotion.tint,
                       symbolName: SupportResourceKind.powerfulGrowthPotion.symbolName,
                       fallbackGlyph: SupportResourceKind.powerfulGrowthPotion.glyph,
                       purchase: .resource(.powerfulGrowthPotion, quantity: 1),
                       availableWeekdays: [mondayWeekday])
    ]

    static func availableItems(on date: Date = Date()) -> [RefugeShopItem] {
        items.filter { $0.isAvailable(on: date) }
    }

    static func item(withId id: String) -> RefugeShopItem? {
        items.first { $0.id == id }
    }
}

final class ResourceSupportSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func count(for kind: SupportResourceKind) -> Int {
        ctx.stats.inventoryCount(for: kind.itemId)
    }

    @discardableResult
    func reserveForDelivery(_ kind: SupportResourceKind) -> Bool {
        guard count(for: kind) > 0 else { return false }
        if kind == .growthPotion,
           !ctx.growth.canReceiveGrowthAccelerationResource() {
            return false
        }
        if kind == .powerfulGrowthPotion,
           !ctx.growth.canReceivePowerfulGrowthAccelerationResource() {
            return false
        }
        return ctx.stats.spendInventoryItem(id: kind.itemId, amount: 1)
    }

    func applyDeliveredResource(_ kind: SupportResourceKind) {
        let stats = ctx.stats!
        switch kind {
        case .foodBag:
            stats.hunger = max(0, stats.hunger - GameBalance.supportFoodBagHungerRelief)
            stats.mealsEaten += 1
            stats.boostMood(6)
            stats.trust = min(100, stats.trust + 0.8)
            GameAudio.shared.play(.mermaidEat)
        case .calmShell:
            stats.scaredTimer = max(0, stats.scaredTimer - 18)
            stats.disposition = min(100, stats.disposition + 14)
            stats.boostMood(10)
            stats.trust = min(100, stats.trust + 1.1)
            GameAudio.shared.play(.uiConfirm)
        case .currentAmpoule:
            stats.energy = min(100, stats.energy + 12)
            stats.addTimedBuff(.swiftCurrent,
                               title: "Corrente engarrafada",
                               duration: GameBalance.gameplayEffectDuration)
            stats.trust = min(100, stats.trust + 0.6)
            GameAudio.shared.play(.uiConfirm)
        case .coralToy:
            stats.boostMood(16)
            stats.trust = min(100, stats.trust + 1.4)
            stats.addTimedBuff(.eagerCompanion,
                               title: "Brinquedo de coral",
                               duration: GameBalance.gameplayEffectDuration)
            GameAudio.shared.play(.uiConfirm)
        case .growthPotion:
            if ctx.growth.applyGrowthAccelerationResource() {
                return
            } else {
                stats.addInventoryItem(id: kind.itemId,
                                       amount: 1,
                                       memoryText: "Porção acelerar devolvida ao estoque",
                                       autosave: true)
            }
            return
        case .powerfulGrowthPotion:
            if ctx.growth.applyPowerfulGrowthAccelerationResource() {
                return
            } else {
                stats.addInventoryItem(id: kind.itemId,
                                       amount: 1,
                                       memoryText: "Poção de crescimento poderosa devolvida ao estoque",
                                       autosave: true)
            }
            return
        }
        stats.addMemory("Recurso enviado: \(kind.title)")
        stats.save(immediately: true)
        ctx.say(kind.deliveredMessage)
    }

    func grantCommonChallengeCompletionReward(_ kind: SupportResourceKind) {
        ctx.stats.addInventoryItem(id: kind.itemId,
                                   amount: 1,
                                   memoryText: "Venceu desafio e recebeu \(kind.title)",
                                   autosave: false)
    }

    @discardableResult
    func purchase(_ item: RefugeShopItem) -> Bool {
        guard item.isAvailable() else {
            ctx.say("\(item.title) só fica disponível às segundas-feiras.")
            return false
        }

        switch item.purchase {
        case .resource(let kind, let quantity):
            guard ctx.stats.spendPearls(item.cost, autosave: false) else {
                ctx.say("\(item.title) custa \(GameUI.shellAmountText(item.cost)) conchas. Faltam \(GameUI.shellAmountText(item.cost - ctx.stats.pearls)) conchas.")
                return false
            }
            ctx.stats.addInventoryItem(id: kind.itemId,
                                       amount: quantity,
                                       memoryText: "Guardou \(kind.title)",
                                       autosave: false)
            ctx.stats.addMemory("Comprou \(item.title) na Loja")
            ctx.stats.save(immediately: true)
            ctx.say("\(item.title) guardado no painel Recursos.")
            GameAudio.shared.play(.uiUpgradeBuy)
            return true
        }
    }
}

final class ResourceChoiceOverlay: SKNode {
    private let counts: [SupportResourceKind: Int]
    private let onSelect: (SupportResourceKind) -> Void
    private let onUnavailable: (SupportResourceKind) -> Void
    private let onClose: () -> Void
    private var choices: [String: SupportResourceKind] = [:]

    init(size: CGSize,
         counts: [SupportResourceKind: Int],
         onSelect: @escaping (SupportResourceKind) -> Void,
         onUnavailable: @escaping (SupportResourceKind) -> Void,
         onClose: @escaping () -> Void) {
        self.counts = counts
        self.onSelect = onSelect
        self.onUnavailable = onUnavailable
        self.onClose = onClose
        super.init()
        isUserInteractionEnabled = true
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size: CGSize) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2.2, height: size.height * 2.2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.50)
        backdrop.strokeColor = .clear
        backdrop.name = "resource_choice_close"
        addChild(backdrop)

        let resources = SupportResourceKind.allCases
        let panelWidth = min(size.width - 32, size.width >= 700 ? 444 : 370)
        let rowSpacing: CGFloat = 10
        let maxPanelHeight = size.height - 52
        let reservedHeight: CGFloat = 166
        let spacingTotal = CGFloat(max(0, resources.count - 1)) * rowSpacing
        let rowHeight = min(84, max(64, (maxPanelHeight - reservedHeight - spacingTotal) / CGFloat(resources.count)))
        let panelHeight = min(maxPanelHeight,
                              reservedHeight + CGFloat(resources.count) * rowHeight + spacingTotal)

        let panel = GameUI.card(size: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 22,
                                tint: GameUI.accent.withAlphaComponent(0.72),
                                baseColors: [UIColor.lerp(GameUI.palePaper, GameUI.accent, 0.04)])
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let title = makeLabel("Recursos", fontSize: 20, color: GameUI.ink, bold: true)
        title.position = CGPoint(x: -panelWidth / 2 + 24, y: panelHeight / 2 - 32)
        content.addChild(title)

        let subtitle = makeLabel("Enviar ajuda sem comandar a sereia.",
                                 fontSize: 12,
                                 color: GameUI.mutedInk,
                                 maxWidth: panelWidth - 48)
        subtitle.position = CGPoint(x: -panelWidth / 2 + 24, y: panelHeight / 2 - 56)
        content.addChild(subtitle)

        let rowWidth = panelWidth - 32
        let firstRowY = panelHeight / 2 - 102
        for (index, kind) in resources.enumerated() {
            let key = kind.rawValue
            let rowName = "resource_choice_\(key)"
            let stock = counts[kind] ?? 0
            choices[key] = kind

            let active = stock > 0
            let tint = active ? kind.tint : GameUI.mutedInk
            let row = GameUI.card(size: CGSize(width: rowWidth, height: rowHeight),
                                  cornerRadius: 14,
                                  tint: tint.withAlphaComponent(active ? 0.72 : 0.36),
                                  baseColors: active ? GameUI.tintedColors(tint) : [GameUI.palePaper])
            row.name = rowName
            row.alpha = active ? 1 : 0.74
            row.position = CGPoint(x: 0, y: firstRowY - CGFloat(index) * (rowHeight + rowSpacing))
            content.addChild(row)

            let rowContent = SKNode()
            rowContent.zPosition = 6
            row.addChild(rowContent)

            let iconRing = SKShapeNode(circleOfRadius: 22)
            iconRing.fillColor = UIColor.lerp(GameUI.palePaper, tint, active ? 0.18 : 0.08)
            iconRing.strokeColor = tint.withAlphaComponent(active ? 0.68 : 0.38)
            iconRing.lineWidth = 1.1
            iconRing.position = CGPoint(x: -rowWidth / 2 + 38, y: 8)
            rowContent.addChild(iconRing)

            let icon = GameUI.symbolIconNode(named: kind.symbolName,
                                             fallback: kind.glyph,
                                             color: tint,
                                             size: 22)
            icon.position = iconRing.position
            icon.zPosition = 3
            rowContent.addChild(icon)

            let longTitle = kind.title.count > 24
            let compactRow = rowHeight < 76
            let titleWidth = rowWidth - 122
            let bodyWidth = rowWidth - 154
            let titleFontSize: CGFloat = longTitle
                ? (compactRow ? 11.3 : 12.2)
                : (compactRow ? 13.6 : 14.5)
            let titleY: CGFloat = longTitle
                ? (compactRow ? 18 : 23)
                : (compactRow ? 18 : 20)
            let blurbFontSize: CGFloat = longTitle
                ? (compactRow ? 9.2 : 9.8)
                : (compactRow ? 9.8 : 10.5)
            let blurbY: CGFloat = longTitle
                ? (compactRow ? -14 : -18)
                : (compactRow ? -9 : -8)

            let name = makeLabel(kind.title,
                                 fontSize: titleFontSize,
                                 color: GameUI.ink,
                                 bold: true,
                                 maxWidth: titleWidth,
                                 lines: longTitle ? 2 : 1)
            name.position = CGPoint(x: -rowWidth / 2 + 74, y: titleY)
            rowContent.addChild(name)

            let blurb = makeLabel(kind.blurb,
                                  fontSize: blurbFontSize,
                                  color: GameUI.mutedInk,
                                  maxWidth: bodyWidth,
                                  lines: 2)
            blurb.position = CGPoint(x: -rowWidth / 2 + 74, y: blurbY)
            rowContent.addChild(blurb)

            let count = SKLabelNode(text: "x\(stock)")
            count.fontName = "AvenirNext-DemiBold"
            count.fontSize = 12
            count.fontColor = active ? kind.tint : GameUI.mutedInk.withAlphaComponent(0.62)
            count.horizontalAlignmentMode = .right
            count.verticalAlignmentMode = .center
            count.position = CGPoint(x: rowWidth / 2 - 18, y: 22)
            rowContent.addChild(count)

            let action = GameUI.pill(text: active ? "Enviar" : "Sem estoque",
                                     fontSize: active ? 12 : 10.5,
                                     fill: [tint.withAlphaComponent(active ? 0.92 : 0.42)],
                                     strokeColor: tint.withAlphaComponent(active ? 0.55 : 0.22),
                                     minWidth: active ? 76 : 96,
                                     height: 30)
            action.name = rowName
            action.position = CGPoint(x: rowWidth / 2 - (active ? 50 : 60), y: -20)
            action.zPosition = 7
            rowContent.addChild(action)
        }

        let close = GameUI.pill(text: "Voltar",
                                fontSize: 13,
                                bold: false,
                                fill: [GameUI.coral.withAlphaComponent(0.92)],
                                strokeColor: GameUI.coral.withAlphaComponent(0.55),
                                minWidth: 104,
                                height: 32)
        close.name = "resource_choice_close"
        close.position = CGPoint(x: 0, y: -panelHeight / 2 + 30)
        close.zPosition = 12
        content.addChild(close)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            if let name = current.name {
                if name == "resource_choice_close" {
                    onClose()
                    return
                }
                if name.hasPrefix("resource_choice_") {
                    let key = String(name.dropFirst("resource_choice_".count))
                    if let kind = choices[key] {
                        if (counts[kind] ?? 0) > 0 {
                            onSelect(kind)
                        } else {
                            onUnavailable(kind)
                        }
                        return
                    }
                }
            }
            node = current.parent
        }
    }

    private func makeLabel(_ text: String,
                           fontSize: CGFloat,
                           color: UIColor,
                           bold: Bool = false,
                           maxWidth: CGFloat = 0,
                           lines: Int = 1) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        if maxWidth > 0 {
            label.preferredMaxLayoutWidth = maxWidth
            label.numberOfLines = lines
            label.lineBreakMode = .byWordWrapping
        }
        return label
    }
}

enum SupportResourceVisualFactory {
    static func makeNode(for kind: SupportResourceKind) -> SKNode {
        let node = SKNode()
        node.zPosition = 18

        let glow = SKShapeNode(circleOfRadius: 34)
        glow.fillColor = kind.tint.withAlphaComponent(0.16)
        glow.strokeColor = .clear
        glow.glowWidth = 10
        glow.zPosition = -1
        node.addChild(glow)

        switch kind {
        case .foodBag:
            buildFoodBag(in: node, tint: kind.tint)
        case .calmShell:
            buildCalmShell(in: node, tint: kind.tint)
        case .currentAmpoule:
            buildCurrentAmpoule(in: node, tint: kind.tint)
        case .coralToy:
            buildCoralToy(in: node, tint: kind.tint)
        case .growthPotion, .powerfulGrowthPotion:
            buildGrowthPotion(in: node, tint: kind.tint)
        }

        return node
    }

    static func makeArrivalEffect(for kind: SupportResourceKind) -> SKNode {
        let node = SKNode()
        node.zPosition = 17
        switch kind {
        case .foodBag:
            for i in 0..<8 {
                let crumb = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
                crumb.fillColor = UIColor(red: 0.76, green: 0.64, blue: 0.35, alpha: 0.92)
                crumb.strokeColor = .clear
                crumb.position = CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -5...10))
                node.addChild(crumb)
                let angle = CGFloat(i) / 8 * .pi * 2
                crumb.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * 42, y: sin(angle) * 30, duration: 0.34),
                        .fadeOut(withDuration: 0.34),
                        .scale(to: 0.2, duration: 0.34)
                    ]),
                    .removeFromParent()
                ]))
            }
        case .calmShell:
            let ring = SKShapeNode(circleOfRadius: 18)
            ring.fillColor = .clear
            ring.strokeColor = kind.tint.withAlphaComponent(0.82)
            ring.lineWidth = 2
            ring.glowWidth = 5
            node.addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 2.4, duration: 0.55), .fadeOut(withDuration: 0.55)]),
                .removeFromParent()
            ]))
        case .currentAmpoule:
            for i in 0..<3 {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: -36, y: CGFloat(i * 12 - 12)))
                path.addCurve(to: CGPoint(x: 38, y: CGFloat(12 - i * 10)),
                              controlPoint1: CGPoint(x: -10, y: 36),
                              controlPoint2: CGPoint(x: 14, y: -34))
                let streak = SKShapeNode(path: path.cgPath)
                streak.strokeColor = kind.tint.withAlphaComponent(0.78)
                streak.lineWidth = 2
                streak.lineCap = .round
                streak.glowWidth = 4
                node.addChild(streak)
                streak.run(.sequence([
                    .group([.rotate(byAngle: .pi, duration: 0.5), .fadeOut(withDuration: 0.5)]),
                    .removeFromParent()
                ]))
            }
        case .coralToy:
            for i in 0..<6 {
                let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...4.5))
                spark.fillColor = i.isMultiple(of: 2) ? kind.tint : GameUI.gold
                spark.strokeColor = .clear
                spark.glowWidth = 4
                node.addChild(spark)
                let angle = CGFloat(i) / 6 * .pi * 2
                spark.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * 44, y: sin(angle) * 40, duration: 0.48),
                        .fadeOut(withDuration: 0.48),
                        .scale(to: 0.1, duration: 0.48)
                    ]),
                    .removeFromParent()
                ]))
            }
        case .growthPotion, .powerfulGrowthPotion:
            let ring = SKShapeNode(circleOfRadius: 16)
            ring.fillColor = .clear
            ring.strokeColor = kind.tint.withAlphaComponent(0.86)
            ring.lineWidth = 2
            ring.glowWidth = 6
            node.addChild(ring)
            ring.run(.sequence([
                .group([
                    .scale(to: 2.6, duration: 0.62),
                    .rotate(byAngle: -.pi, duration: 0.62),
                    .fadeOut(withDuration: 0.62)
                ]),
                .removeFromParent()
            ]))

            for i in 0..<8 {
                let grain = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.8...3.2))
                grain.fillColor = i.isMultiple(of: 2) ? GameUI.gold : kind.tint
                grain.strokeColor = .clear
                grain.glowWidth = 4
                node.addChild(grain)
                let angle = CGFloat(i) / 8 * .pi * 2
                grain.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * 38, y: sin(angle) * 38, duration: 0.5),
                        .fadeOut(withDuration: 0.5),
                        .scale(to: 0.15, duration: 0.5)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
        node.run(.sequence([.wait(forDuration: 0.7), .removeFromParent()]))
        return node
    }

    private static func buildFoodBag(in node: SKNode, tint: UIColor) {
        let bag = SKShapeNode(rectOf: CGSize(width: 42, height: 46), cornerRadius: 8)
        bag.fillColor = UIColor(red: 0.75, green: 0.66, blue: 0.44, alpha: 1)
        bag.strokeColor = tint.withAlphaComponent(0.72)
        bag.lineWidth = 2
        node.addChild(bag)

        let fold = SKShapeNode(rectOf: CGSize(width: 32, height: 8), cornerRadius: 4)
        fold.fillColor = UIColor(red: 0.62, green: 0.50, blue: 0.30, alpha: 1)
        fold.strokeColor = .clear
        fold.position = CGPoint(x: 0, y: 16)
        node.addChild(fold)

        let leaf = UIBezierPath()
        leaf.move(to: CGPoint(x: -5, y: -4))
        leaf.addQuadCurve(to: CGPoint(x: 7, y: 9), controlPoint: CGPoint(x: 12, y: 0))
        leaf.addQuadCurve(to: CGPoint(x: -5, y: -4), controlPoint: CGPoint(x: -10, y: 7))
        let mark = SKShapeNode(path: leaf.cgPath)
        mark.fillColor = tint.withAlphaComponent(0.84)
        mark.strokeColor = .clear
        node.addChild(mark)
    }

    private static func buildCalmShell(in node: SKNode, tint: UIColor) {
        let shell = SKShapeNode(ellipseOf: CGSize(width: 46, height: 36))
        shell.fillColor = UIColor.lerp(.white, tint, 0.28)
        shell.strokeColor = tint.withAlphaComponent(0.78)
        shell.lineWidth = 2
        shell.glowWidth = 3
        node.addChild(shell)

        for x in stride(from: -14, through: 14, by: 7) {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: 26), cornerRadius: 1)
            line.fillColor = tint.withAlphaComponent(0.42)
            line.strokeColor = .clear
            line.position = CGPoint(x: CGFloat(x), y: 0)
            line.zRotation = CGFloat(x) * 0.01
            node.addChild(line)
        }
    }

    private static func buildCurrentAmpoule(in node: SKNode, tint: UIColor) {
        let vial = SKShapeNode(ellipseOf: CGSize(width: 28, height: 54))
        vial.fillColor = UIColor.white.withAlphaComponent(0.38)
        vial.strokeColor = tint.withAlphaComponent(0.86)
        vial.lineWidth = 2
        vial.glowWidth = 4
        node.addChild(vial)

        let liquid = SKShapeNode(ellipseOf: CGSize(width: 20, height: 34))
        liquid.fillColor = tint.withAlphaComponent(0.72)
        liquid.strokeColor = .clear
        liquid.position = CGPoint(x: 0, y: -5)
        node.addChild(liquid)

        let cap = SKShapeNode(rectOf: CGSize(width: 16, height: 8), cornerRadius: 3)
        cap.fillColor = GameUI.gold.withAlphaComponent(0.9)
        cap.strokeColor = .clear
        cap.position = CGPoint(x: 0, y: 28)
        node.addChild(cap)
    }

    private static func buildCoralToy(in node: SKNode, tint: UIColor) {
        let core = SKShapeNode(circleOfRadius: 13)
        core.fillColor = tint
        core.strokeColor = UIColor.white.withAlphaComponent(0.42)
        core.lineWidth = 1.2
        node.addChild(core)

        for angle in stride(from: CGFloat(0), to: .pi * 2, by: .pi / 3) {
            let branch = SKShapeNode(rectOf: CGSize(width: 7, height: 30), cornerRadius: 3.5)
            branch.fillColor = tint.withAlphaComponent(0.84)
            branch.strokeColor = .clear
            branch.position = CGPoint(x: cos(angle) * 15, y: sin(angle) * 15)
            branch.zRotation = angle
            node.addChild(branch)
        }

        let bead = SKShapeNode(circleOfRadius: 5)
        bead.fillColor = GameUI.gold.withAlphaComponent(0.9)
        bead.strokeColor = .clear
        bead.position = CGPoint(x: 0, y: 24)
        node.addChild(bead)
    }

    private static func buildGrowthPotion(in node: SKNode, tint: UIColor) {
        let vial = SKShapeNode(ellipseOf: CGSize(width: 30, height: 52))
        vial.fillColor = UIColor.white.withAlphaComponent(0.40)
        vial.strokeColor = tint.withAlphaComponent(0.88)
        vial.lineWidth = 2
        vial.glowWidth = 5
        node.addChild(vial)

        let sandTop = SKShapeNode(ellipseOf: CGSize(width: 18, height: 14))
        sandTop.fillColor = GameUI.gold.withAlphaComponent(0.82)
        sandTop.strokeColor = .clear
        sandTop.position = CGPoint(x: 0, y: 9)
        node.addChild(sandTop)

        let sandBottom = SKShapeNode(ellipseOf: CGSize(width: 20, height: 16))
        sandBottom.fillColor = tint.withAlphaComponent(0.72)
        sandBottom.strokeColor = .clear
        sandBottom.position = CGPoint(x: 0, y: -13)
        node.addChild(sandBottom)

        let neck = SKShapeNode(rectOf: CGSize(width: 4, height: 24), cornerRadius: 2)
        neck.fillColor = GameUI.gold.withAlphaComponent(0.72)
        neck.strokeColor = .clear
        node.addChild(neck)

        let cap = SKShapeNode(rectOf: CGSize(width: 18, height: 7), cornerRadius: 3)
        cap.fillColor = tint.withAlphaComponent(0.92)
        cap.strokeColor = .clear
        cap.position = CGPoint(x: 0, y: 29)
        node.addChild(cap)
    }
}

final class RefugeStoreOverlay: SKNode {
    private let size: CGSize
    private let insets: UIEdgeInsets
    private let stats: MermaidStats
    private let closeTitle: String
    private let onClose: (() -> Void)?
    private let onPurchase: ((RefugeShopItem) -> Void)?

    init(size: CGSize,
         insets: UIEdgeInsets,
         stats: MermaidStats,
         closeTitle: String = "Voltar ao refúgio",
         handlesTouches: Bool = false,
         onClose: (() -> Void)? = nil,
         onPurchase: ((RefugeShopItem) -> Void)? = nil) {
        self.size = size
        self.insets = insets
        self.stats = stats
        self.closeTitle = closeTitle
        self.onClose = onClose
        self.onPurchase = onPurchase
        super.init()
        isUserInteractionEnabled = handlesTouches
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = GameUI.palePaper
        backdrop.strokeColor = GameUI.accent.withAlphaComponent(0.2)
        backdrop.zPosition = 0
        addChild(backdrop)

        let top = size.height / 2 - insets.top
        let rowWidth = min(size.width - 28, 420)
        let title = makeLabel(text: "Loja", fontSize: 21, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: 0, y: top - 38)
        title.zPosition = 2
        addChild(title)

        let seller = SKSpriteNode(imageNamed: "SellerSardines")
        seller.size = CGSize(width: 58, height: 92)
        seller.position = CGPoint(x: -rowWidth / 2 + 52, y: top - 94)
        seller.zPosition = 2
        addChild(seller)

        let greeting = makeLabel(text: "Tenho recursos fresquinhos para ajudar a sereia.",
                                 fontSize: 12,
                                 color: GameUI.mutedInk)
        greeting.horizontalAlignmentMode = .left
        greeting.preferredMaxLayoutWidth = rowWidth - 118
        greeting.numberOfLines = 2
        greeting.lineBreakMode = .byWordWrapping
        greeting.position = CGPoint(x: -rowWidth / 2 + 96, y: top - 72)
        greeting.zPosition = 2
        addChild(greeting)

        let pearlLine = makeLabel(text: "Conchas \(GameUI.shellAmountText(stats.pearls))", fontSize: 13, bold: true, color: GameUI.gold)
        pearlLine.horizontalAlignmentMode = .left
        pearlLine.position = CGPoint(x: -rowWidth / 2 + 96, y: top - 114)
        pearlLine.zPosition = 2
        addChild(pearlLine)

        let items = RefugeShopCatalog.availableItems()
        let availableHeight = max(330, size.height - insets.top - insets.bottom - 280)
        let rowHeight = min(82, max(64, availableHeight / CGFloat(items.count)))
        let firstY = top - 172

        for (index, item) in items.enumerated() {
            addRow(item: item,
                   width: rowWidth,
                   height: rowHeight - 8,
                   centerY: firstY - CGFloat(index) * rowHeight)
        }

        let closeButton = SKNode()
        closeButton.name = "store_close"
        closeButton.position = CGPoint(x: 0, y: -size.height / 2 + insets.bottom + 48)
        closeButton.zPosition = 4
        let closeCard = GameUI.card(size: CGSize(width: min(220, size.width - 80), height: 44),
                                    cornerRadius: 9,
                                    tint: GameUI.accent)
        closeCard.name = "store_close"
        closeButton.addChild(closeCard)
        let closeLabel = makeLabel(text: closeTitle, fontSize: 13, bold: true, color: GameUI.ink)
        closeLabel.name = "store_close"
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 5
        closeButton.addChild(closeLabel)
        addChild(closeButton)
    }

    private func addRow(item: RefugeShopItem,
                        width: CGFloat,
                        height: CGFloat,
                        centerY: CGFloat) {
        let actionName = "store_item_\(item.id)"
        let row = SKNode()
        row.name = actionName
        row.position = CGPoint(x: 0, y: centerY)
        row.zPosition = 2
        addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = UIColor.white.withAlphaComponent(0.36)
        bg.strokeColor = item.tint.withAlphaComponent(0.25)
        bg.lineWidth = 1
        bg.name = actionName
        row.addChild(bg)

        let iconRing = SKShapeNode(circleOfRadius: 20)
        iconRing.fillColor = item.tint.withAlphaComponent(0.14)
        iconRing.strokeColor = item.tint.withAlphaComponent(0.58)
        iconRing.lineWidth = 1
        iconRing.position = CGPoint(x: -width / 2 + 34, y: 6)
        iconRing.name = actionName
        row.addChild(iconRing)

        let icon = GameUI.symbolIconNode(named: item.symbolName,
                                         fallback: item.fallbackGlyph,
                                         color: item.tint,
                                         size: 21)
        icon.position = iconRing.position
        icon.zPosition = 4
        row.addChild(icon)

        let title = makeLabel(text: item.title, fontSize: 13, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 66, y: height / 2 - 21)
        title.preferredMaxLayoutWidth = width - 172
        title.numberOfLines = 1
        title.name = actionName
        row.addChild(title)

        let description = makeLabel(text: item.blurb, fontSize: 10.3, color: GameUI.mutedInk)
        description.horizontalAlignmentMode = .left
        description.preferredMaxLayoutWidth = width - 180
        description.numberOfLines = 2
        description.lineBreakMode = .byWordWrapping
        description.position = CGPoint(x: -width / 2 + 66, y: -8)
        description.name = actionName
        row.addChild(description)

        let button = SKNode()
        button.name = actionName
        button.position = CGPoint(x: width / 2 - 56, y: -2)
        button.zPosition = 4
        row.addChild(button)

        let buttonBg = GameUI.card(size: CGSize(width: 92, height: 46),
                                   cornerRadius: 8,
                                   tint: item.tint)
        buttonBg.name = actionName
        button.addChild(buttonBg)

        let label = makeLabel(text: "\(GameUI.shellAmountText(item.cost))\nconchas",
                              fontSize: 10.5,
                              bold: true,
                              color: GameUI.ink)
        label.name = actionName
        label.numberOfLines = 2
        label.verticalAlignmentMode = .center
        label.zPosition = 5
        button.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            switch current.name {
            case "store_close":
                onClose?()
                return
            case let name? where name.hasPrefix("store_item_"):
                let itemId = String(name.dropFirst("store_item_".count))
                guard let item = RefugeShopCatalog.item(withId: itemId) else { return }
                onPurchase?(item)
                return
            default:
                break
            }
            node = current.parent
        }
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
