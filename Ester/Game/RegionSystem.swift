//
//  RegionSystem.swift
//  Ester
//
//  Regiões descobríveis do oceano: cada uma tem coordenadas reais,
//  paleta, fauna, comida e tema de Trama das Marés próprios.
//  Inclui o sistema de viagem (destinos não são teleporte) e o menu
//  de regiões.
//

import Foundation
import SpriteKit

// MARK: - Região

struct Region {
    let id: String
    let name: String
    let xRange: ClosedRange<CGFloat>
    let yRange: ClosedRange<CGFloat>
    let tint: UIColor
    let tintStrength: CGFloat
    let minPhase: MermaidPhase
    let blurb: String
    let tideTitle: String
    let tideIcons: [String]

    var center: CGPoint {
        CGPoint(x: (xRange.lowerBound + xRange.upperBound) / 2,
                y: (yRange.lowerBound + yRange.upperBound) / 2)
    }

    func contains(_ point: CGPoint) -> Bool {
        xRange.contains(point.x) && yRange.contains(point.y)
    }
}

// MARK: - Descoberta de regiões

final class RegionDiscoverySystem {
    unowned let ctx: GameContext
    private var progressTimer: CGFloat = 0

    static let all: [Region] = [
        Region(id: "nascente",
               name: "Águas de Nascimento",
               xRange: -8000 ... 8000,
               yRange: -10000 ... -4000,
               tint: UIColor(red: 0.45, green: 0.65, blue: 0.9, alpha: 1),
               tintStrength: 0.12,
               minPhase: .baby,
               blurb: "Águas calmas e seguras onde tudo começou.",
               tideTitle: "Pérolas do Berço",
               tideIcons: ["🫧", "⭐️", "🐚", "💧", "✨"]),
        Region(id: "recife",
               name: "Recife Esmeralda",
               xRange: 14000 ... 28000,
               yRange: -9000 ... -3000,
               tint: UIColor(red: 0.2, green: 0.75, blue: 0.55, alpha: 1),
               tintStrength: 0.28,
               minPhase: .child,
               blurb: "Um jardim de corais vibrante e cheio de vida.",
               tideTitle: "Corais do Recife",
               tideIcons: ["🐚", "🪸", "💎", "🌺", "⭐️"]),
        Region(id: "delta",
               name: "Grande Delta",
               xRange: -30000 ... -16000,
               yRange: -5500 ... -2200,
               tint: UIColor(red: 0.45, green: 0.5, blue: 0.3, alpha: 1),
               tintStrength: 0.3,
               minPhase: .child,
               blurb: "Onde o rio encontra o mar, entre correntes e sementes.",
               tideTitle: "Sementes do Delta",
               tideIcons: ["🌱", "🍃", "🐚", "🪨", "💧"])
    ]

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    static func region(withId id: String) -> Region? {
        all.first { $0.id == id }
    }

    var currentRegion: Region? {
        let p = ctx.mermaidPosition
        return RegionDiscoverySystem.all.first { $0.contains(p) }
    }

    func update(dt: CGFloat) {
        guard let region = currentRegion else { return }

        // descoberta permanente
        if !ctx.stats.discoveredRegionIds.contains(region.id) {
            ctx.stats.discoveredRegionIds.insert(region.id)
            ctx.stats.pearls += 15
            ctx.stats.gainXP(40)
            ctx.stats.courage = min(100, ctx.stats.courage + 2)
            ctx.stats.addMemory("Descobriu \(region.name)")
            ctx.say("🗺 Nova região descoberta: \(region.name)! 💠+15")
        }

        // progresso de exploração lento (0–100% em ~20 min na região)
        progressTimer += dt
        if progressTimer >= 5 {
            progressTimer = 0
            let current = ctx.stats.regionProgress[region.id] ?? 0
            if current < 1 {
                ctx.stats.regionProgress[region.id] = min(1, current + 5.0 / 1200.0)
            }
        }
    }

    /// Tinta da região misturada na cor da água.
    func waterTint(at point: CGPoint) -> (color: UIColor, strength: CGFloat)? {
        guard let region = RegionDiscoverySystem.all.first(where: { $0.contains(point) }) else { return nil }
        return (region.tint, region.tintStrength)
    }

    /// Paleta de peixes característica da região (nil = paleta da camada).
    static func fishPalette(for regionId: String) -> [UIColor]? {
        switch regionId {
        case "recife":
            return [UIColor(red: 0.95, green: 0.5, blue: 0.25, alpha: 1),
                    UIColor(red: 0.7, green: 0.4, blue: 0.85, alpha: 1),
                    UIColor(red: 0.3, green: 0.85, blue: 0.7, alpha: 1),
                    UIColor(red: 0.95, green: 0.75, blue: 0.3, alpha: 1)]
        case "delta":
            return [UIColor(red: 0.55, green: 0.5, blue: 0.35, alpha: 1),
                    UIColor(red: 0.65, green: 0.6, blue: 0.45, alpha: 1),
                    UIColor(red: 0.5, green: 0.55, blue: 0.4, alpha: 1)]
        default:
            return nil
        }
    }

    /// Comidas extras típicas da região.
    static func extraFood(for regionId: String) -> [FoodKind] {
        switch regionId {
        case "recife":
            return [
                FoodKind(name: "baga de coral", weight: 3, nutrition: 20, xp: 5, pearls: 0, courage: 0.3, style: .fruit, color: UIColor(red: 0.95, green: 0.35, blue: 0.55, alpha: 1)),
                FoodKind(name: "alga do recife", weight: 3, nutrition: 15, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 1))
            ]
        case "delta":
            return [
                FoodKind(name: "semente de rio", weight: 4, nutrition: 16, xp: 4, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.75, green: 0.65, blue: 0.35, alpha: 1)),
                FoodKind(name: "folha do delta", weight: 3, nutrition: 13, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.5, green: 0.6, blue: 0.3, alpha: 1))
            ]
        default:
            return []
        }
    }
}

// MARK: - Viagem

final class TravelSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    var destination: Region? {
        guard let id = ctx.stats.destinationRegionId else { return nil }
        return RegionDiscoverySystem.region(withId: id)
    }

    var targetPoint: CGPoint? {
        guard let destination else { return nil }
        let yRange = ctx.depth.allowedYRange()
        return CGPoint(x: destination.center.x,
                       y: destination.center.y.clamped(to: yRange))
    }

    func setDestination(_ region: Region) {
        if region.contains(ctx.mermaidPosition) {
            ctx.say("Ela já está em \(region.name).")
            return
        }
        if ctx.stats.phase < region.minPhase {
            ctx.say("Ela ainda é muito nova para viajar até \(region.name).")
            return
        }
        if ctx.stats.energy < 15 {
            ctx.say("Cansada demais para uma viagem longa... ela precisa descansar.")
            return
        }
        ctx.stats.destinationRegionId = region.id
        ctx.say("Ela partiu rumo a \(region.name) 🌊 A viagem leva tempo...")
    }

    func clearDestination() {
        ctx.stats.destinationRegionId = nil
    }

    func update(dt: CGFloat) {
        guard let destination else { return }
        if destination.contains(ctx.mermaidPosition) {
            clearDestination()
            ctx.stats.gainXP(20)
            ctx.stats.pearls += 5
            ctx.stats.boostMood(8)
            ctx.stats.addMemory("Viajou até \(destination.name)")
            ctx.say("Ela chegou: \(destination.name)! 💠+5")
        }
    }
}

// MARK: - Menu de regiões

final class RegionMenuOverlay: SKNode {
    private let onSelect: (Region) -> Void
    private let onClose: () -> Void
    private var rowRegions: [String: Region] = [:]

    init(size: CGSize,
         stats: MermaidStats,
         currentRegionId: String?,
         destinationId: String?,
         onSelect: @escaping (Region) -> Void,
         onClose: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onClose = onClose
        super.init()
        isUserInteractionEnabled = true

        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.6)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        let discovered = RegionDiscoverySystem.all.filter { stats.discoveredRegionIds.contains($0.id) }
        let unknownCount = RegionDiscoverySystem.all.count - discovered.count
        let rowHeight: CGFloat = 86
        let panelWidth = min(size.width - 32, 360)
        let panelHeight = CGFloat(discovered.count) * rowHeight + 130

        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 22)
        panel.fillColor = UIColor(red: 0.06, green: 0.12, blue: 0.22, alpha: 0.97)
        panel.strokeColor = UIColor(white: 1, alpha: 0.25)
        panel.lineWidth = 2
        addChild(panel)

        let title = SKLabelNode(text: "Viajar")
        title.fontName = "Helvetica-Bold"
        title.fontSize = 19
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelHeight / 2 - 40)
        panel.addChild(title)

        for (index, region) in discovered.enumerated() {
            let y = panelHeight / 2 - 84 - CGFloat(index) * rowHeight
            let row = SKShapeNode(rectOf: CGSize(width: panelWidth - 28, height: rowHeight - 12),
                                  cornerRadius: 14)
            let isCurrent = region.id == currentRegionId
            let isDestination = region.id == destinationId
            row.fillColor = isCurrent
                ? UIColor(white: 1, alpha: 0.08)
                : UIColor(red: 0.15, green: 0.3, blue: 0.5, alpha: 0.45)
            row.strokeColor = isDestination
                ? UIColor(red: 0.5, green: 0.85, blue: 1, alpha: 0.9)
                : region.tint.withAlphaComponent(0.7)
            row.lineWidth = 1.5
            row.position = CGPoint(x: 0, y: y)
            row.name = "region_\(region.id)"
            panel.addChild(row)
            rowRegions[region.id] = region

            let name = SKLabelNode(text: region.name)
            name.fontName = "Helvetica-Bold"
            name.fontSize = 15
            name.fontColor = .white
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: -panelWidth / 2 + 28, y: 12)
            name.name = row.name
            row.addChild(name)

            let blurb = SKLabelNode(text: region.blurb)
            blurb.fontName = "Helvetica"
            blurb.fontSize = 11
            blurb.fontColor = UIColor(white: 1, alpha: 0.7)
            blurb.horizontalAlignmentMode = .left
            blurb.position = CGPoint(x: -panelWidth / 2 + 28, y: -8)
            blurb.name = row.name
            row.addChild(blurb)

            let progress = Int((stats.regionProgress[region.id] ?? 0) * 100)
            let statusText: String
            if isCurrent { statusText = "• atual" }
            else if isDestination { statusText = "→ a caminho" }
            else { statusText = "explorada \(progress)%" }
            let status = SKLabelNode(text: statusText)
            status.fontName = "Helvetica"
            status.fontSize = 11
            status.fontColor = UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)
            status.horizontalAlignmentMode = .left
            status.position = CGPoint(x: -panelWidth / 2 + 28, y: -26)
            status.name = row.name
            row.addChild(status)
        }

        if unknownCount > 0 {
            let hint = SKLabelNode(text: "Há águas desconhecidas além... continue explorando.")
            hint.fontName = "Helvetica"
            hint.fontSize = 11
            hint.fontColor = UIColor(white: 1, alpha: 0.55)
            hint.position = CGPoint(x: 0, y: -panelHeight / 2 + 64)
            panel.addChild(hint)
        }

        let close = SKLabelNode(text: "✕ Fechar")
        close.fontName = "Helvetica"
        close.fontSize = 15
        close.fontColor = UIColor(white: 1, alpha: 0.75)
        close.name = "region_close"
        close.position = CGPoint(x: 0, y: -panelHeight / 2 + 28)
        panel.addChild(close)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            if let name = current.name {
                if name == "region_close" {
                    onClose()
                    return
                }
                if name.hasPrefix("region_"),
                   let region = rowRegions[String(name.dropFirst(7))] {
                    onSelect(region)
                    return
                }
            }
            node = current.parent
        }
    }
}
