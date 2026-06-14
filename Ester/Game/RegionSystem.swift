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
    let entryZone: DepthZone
    let tint: UIColor
    let tintStrength: CGFloat
    let minPhase: MermaidPhase
    let blurb: String
    let tideTitle: String
    let tideIcons: [String]

    var center: CGPoint {
        CGPoint(x: (xRange.lowerBound + xRange.upperBound) / 2,
                y: entryZone.midY.clamped(to: yRange))
    }

    func contains(_ point: CGPoint) -> Bool {
        xRange.contains(point.x) && yRange.contains(point.y)
    }

    func isAccessible(for phase: MermaidPhase) -> Bool {
        phase >= minPhase
    }
}

// MARK: - Descoberta de regiões

final class RegionDiscoverySystem {
    unowned let ctx: GameContext
    private var progressTimer: CGFloat = 0

    private static let catalogOrder = [
        "nascente",
        "jardim_calmo",
        "recife",
        "delta",
        "mar_azul_aberto",
        "cavernas",
        "campos_cristal",
        "ruinas",
        "abismo_vivo",
        "superficie_distante"
    ]

    static let all: [Region] = [
        Region(id: "abismo_vivo",
               name: "Abismo Vivo",
               xRange: -50000 ... -41000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .abyss,
               tint: UIColor(red: 0.18, green: 0.10, blue: 0.34, alpha: 1),
               tintStrength: 0.36,
               minPhase: .adult,
               blurb: "Vida luminosa pulsa sob pressão extrema.",
               tideTitle: "Batimentos do Abismo",
               tideIcons: ["✧", "◇", "◌", "◆", "✦"]),
        Region(id: "cavernas",
               name: "Boca das Cavernas",
               xRange: -40000 ... -31000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .blue,
               tint: UIColor(red: 0.12, green: 0.28, blue: 0.40, alpha: 1),
               tintStrength: 0.34,
               minPhase: .teen,
               blurb: "Fendas azuis e ecos de entradas escondidas.",
               tideTitle: "Ecos da Boca",
               tideIcons: ["⌁", "▧", "◇", "◌", "≋"]),
        Region(id: "delta",
               name: "Grande Delta",
               xRange: -30000 ... -21000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.45, green: 0.5, blue: 0.3, alpha: 1),
               tintStrength: 0.3,
               minPhase: .child,
               blurb: "Onde o rio encontra o mar, entre correntes e sementes.",
               tideTitle: "Sementes do Delta",
               tideIcons: ["⌁", "≋", "◡", "▧", "◌"]),
        Region(id: "ruinas",
               name: "Ruínas Antigas",
               xRange: -20000 ... -11000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .deep,
               tint: UIColor(red: 0.30, green: 0.26, blue: 0.48, alpha: 1),
               tintStrength: 0.32,
               minPhase: .young,
               blurb: "Pedras antigas guardam rotas e histórias.",
               tideTitle: "Memória das Ruínas",
               tideIcons: ["▧", "◇", "✦", "◌", "◆"]),
        Region(id: "nascente",
               name: "Águas de Nascimento",
               xRange: -10000 ... 0,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .mid,
               tint: UIColor(red: 0.45, green: 0.65, blue: 0.9, alpha: 1),
               tintStrength: 0.12,
               minPhase: .baby,
               blurb: "Águas calmas e seguras onde tudo começou.",
               tideTitle: "Pérolas do Berço",
               tideIcons: ["○", "✦", "◡", "◌", "✧"]),
        Region(id: "jardim_calmo",
               name: "Jardim Calmo",
               xRange: 1000 ... 10000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.36, green: 0.68, blue: 0.66, alpha: 1),
               tintStrength: 0.18,
               minPhase: .baby,
               blurb: "Jardins lentos para primeiras explorações.",
               tideTitle: "Folhas do Jardim",
               tideIcons: ["◡", "✿", "◌", "○", "⌁"]),
        Region(id: "recife",
               name: "Recife Esmeralda",
               xRange: 11000 ... 20000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.2, green: 0.75, blue: 0.55, alpha: 1),
               tintStrength: 0.28,
               minPhase: .child,
               blurb: "Um jardim de corais vibrante e cheio de vida.",
               tideTitle: "Corais do Recife",
               tideIcons: ["◡", "⌁", "◇", "✿", "✦"]),
        Region(id: "superficie_distante",
               name: "Superfície Distante",
               xRange: 21000 ... 30000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .surface,
               tint: UIColor(red: 0.78, green: 0.88, blue: 0.96, alpha: 1),
               tintStrength: 0.24,
               minPhase: .adult,
               blurb: "Luz aberta onde céu e água se encontram.",
               tideTitle: "Céu na Água",
               tideIcons: ["○", "✦", "◇", "◌", "✧"]),
        Region(id: "mar_azul_aberto",
               name: "Mar Azul Aberto",
               xRange: 31000 ... 40000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .blue,
               tint: UIColor(red: 0.18, green: 0.42, blue: 0.78, alpha: 1),
               tintStrength: 0.30,
               minPhase: .teen,
               blurb: "Água ampla, rotas longas e cardumes velozes.",
               tideTitle: "Rumos do Azul",
               tideIcons: ["≋", "○", "✦", "⌁", "◇"]),
        Region(id: "campos_cristal",
               name: "Campos de Cristal",
               xRange: 41000 ... 50000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .deep,
               tint: UIColor(red: 0.54, green: 0.76, blue: 0.94, alpha: 1),
               tintStrength: 0.30,
               minPhase: .young,
               blurb: "Cristais frios refletem caminhos profundos.",
               tideTitle: "Luzes de Cristal",
               tideIcons: ["◇", "✧", "◆", "◌", "✦"])
    ]

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    static func region(withId id: String) -> Region? {
        all.first { $0.id == id }
    }

    static var menuRegions: [Region] {
        catalogOrder.compactMap { region(withId: $0) }
    }

    static func accessibleRegions(for phase: MermaidPhase) -> [Region] {
        menuRegions.filter { $0.isAccessible(for: phase) }
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
            let gained = ctx.stats.awardPearls(8)
            ctx.stats.gainXP(40)
            ctx.stats.addMemory("Descobriu \(region.name)")
            GameAudio.shared.play(.regionDiscover)
            ctx.say("Nova região catalogada: \(region.name). Conchas +\(gained)")
        }

        // progresso de exploração lento (0–100% em ~20 min na região)
        progressTimer += dt
        if progressTimer >= 5 {
            progressTimer = 0
            let current = ctx.stats.regionProgress[region.id] ?? 0
            if current < 1 {
                ctx.stats.regionProgress[region.id] = min(1, current + 5.0 / 1200.0 * ctx.stats.explorationProgressMultiplier)
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
            ctx.say("Disponível quando ela for \(region.minPhase.mapAccessDisplayName).")
            return
        }
        if ctx.stats.energy < 15 {
            ctx.say("Cansada demais para uma viagem longa... ela precisa descansar.")
            return
        }
        ctx.stats.destinationRegionId = region.id
        GameAudio.shared.play(.travelStart)
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
            let gained = ctx.stats.awardPearls(4)
            ctx.stats.boostMood(8)
            ctx.stats.addMemory("Viajou até \(destination.name)")
            GameAudio.shared.play(.travelArrive)
            ctx.say("Chegada registrada: \(destination.name). Conchas +\(gained)")
        }
    }
}

// MARK: - Menu de regiões

final class RegionMenuOverlay: SKNode {
    private let onSelect: (Region) -> Void
    private let onClose: () -> Void
    private var rowRegions: [String: Region] = [:]
    private var listNode = SKNode()
    private var listViewportRect: CGRect = .zero
    private var listViewportHeight: CGFloat = 0
    private var listContentHeight: CGFloat = 0
    private var listCenterY: CGFloat = 0
    private var listScrollOffset: CGFloat = 0
    private var scrollThumb: SKShapeNode?
    private var scrollThumbHeight: CGFloat = 0
    private var touchStartLocation: CGPoint = .zero
    private var lastTouchLocation: CGPoint = .zero
    private var didScrollDuringTouch = false

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

        let regions = RegionDiscoverySystem.menuRegions
        let rowCardHeight: CGFloat = 78
        let rowSpacing: CGFloat = 10
        let rowStep = rowCardHeight + rowSpacing
        let headerHeight: CGFloat = 84
        let footerHeight: CGFloat = 72
        // painel mais estreito, encostado no lado direito da tela
        let panelWidth = min(size.width - 28, 336)
        let desiredPanelHeight = CGFloat(regions.count) * rowStep + headerHeight + footerHeight
        let maxPanelHeight = max(280, size.height - 72)
        let minPanelHeight = min(maxPanelHeight, 320)
        let panelHeight = min(maxPanelHeight, max(minPanelHeight, desiredPanelHeight))

        // container deslocado para a direita (o backdrop continua centralizado)
        let content = SKNode()
        let rightMargin: CGFloat = 14
        content.position = CGPoint(x: size.width / 2 - panelWidth / 2 - rightMargin, y: 0)
        addChild(content)

        let panel = GameUI.card(size: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 26,
                                tint: GameUI.accent.withAlphaComponent(0.5))
        content.addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 5
        panel.addChild(panelContent)

        let title = GameUI.pill(text: "Mapa de expedição",
                                fontSize: 16,
                                fill: [GameUI.accent.withAlphaComponent(0.95)],
                                strokeColor: GameUI.accent.withAlphaComponent(0.55),
                                textColor: GameUI.ink,
                                hPadding: 26,
                                height: 38)
        title.position = CGPoint(x: 0, y: panelHeight / 2 - 38)
        panelContent.addChild(title)

        let listWidth = panelWidth - 28
        let listTopY = panelHeight / 2 - headerHeight
        let listBottomY = -panelHeight / 2 + footerHeight
        listCenterY = (listTopY + listBottomY) / 2
        listViewportHeight = max(96, listTopY - listBottomY)
        listContentHeight = max(0, CGFloat(regions.count) * rowStep - rowSpacing)
        listViewportRect = CGRect(x: content.position.x - listWidth / 2,
                                  y: listCenterY - listViewportHeight / 2,
                                  width: listWidth,
                                  height: listViewportHeight)

        let listCrop = SKCropNode()
        listCrop.position = CGPoint(x: 0, y: listCenterY)
        listCrop.zPosition = 4
        let listMask = SKShapeNode(rectOf: CGSize(width: listWidth, height: listViewportHeight),
                                   cornerRadius: 18)
        listMask.fillColor = .white
        listMask.strokeColor = .clear
        listCrop.maskNode = listMask
        listCrop.addChild(listNode)
        panelContent.addChild(listCrop)

        for (index, region) in regions.enumerated() {
            let y = listViewportHeight / 2 - rowCardHeight / 2 - CGFloat(index) * rowStep
            let isLocked = !region.isAccessible(for: stats.phase)
            let isCurrent = region.id == currentRegionId
            let isDestination = region.id == destinationId

            let rowTint = isDestination
                ? UIColor(red: 0.5, green: 0.85, blue: 1, alpha: 1)
                : (isLocked ? UIColor(white: 0.45, alpha: 1) : region.tint)
            let row = GameUI.card(size: CGSize(width: listWidth, height: rowCardHeight),
                                  cornerRadius: 16,
                                  tint: rowTint.withAlphaComponent(isCurrent ? 0.9 : 0.6),
                                  baseColors: isLocked ? GameUI.tintedColors(UIColor(white: 0.34, alpha: 1)) : GameUI.tintedColors(region.tint))
            row.position = CGPoint(x: 0, y: y)
            row.name = "region_\(region.id)"
            listNode.addChild(row)
            if !isLocked {
                rowRegions[region.id] = region
            }

            let rowContent = SKNode()
            rowContent.zPosition = 5
            row.addChild(rowContent)
            let leftX = -listWidth / 2 + 18

            let name = SKLabelNode(text: region.name)
            name.fontName = "AvenirNext-DemiBold"
            name.fontSize = 15
            name.fontColor = isLocked ? GameUI.mutedInk : GameUI.ink
            name.horizontalAlignmentMode = .left
            name.position = CGPoint(x: leftX, y: 13)
            rowContent.addChild(name)

            let blurb = SKLabelNode(text: region.blurb)
            blurb.fontName = "AvenirNext-Regular"
            blurb.fontSize = 10.5
            blurb.fontColor = isLocked ? GameUI.mutedInk.withAlphaComponent(0.72) : GameUI.mutedInk
            blurb.horizontalAlignmentMode = .left
            blurb.verticalAlignmentMode = .center
            blurb.preferredMaxLayoutWidth = listWidth - 36
            blurb.numberOfLines = 2
            blurb.position = CGPoint(x: leftX, y: -8)
            rowContent.addChild(blurb)

            let progress = Int((stats.regionProgress[region.id] ?? 0) * 100)
            let statusText: String
            if isLocked { statusText = "Disponível quando ela for \(region.minPhase.mapAccessDisplayName)" }
            else if isCurrent { statusText = "local atual" }
            else if isDestination { statusText = "em rota" }
            else if stats.discoveredRegionIds.contains(region.id) { statusText = "explorada \(progress)%" }
            else { statusText = "ainda não visitado" }
            let status = SKLabelNode(text: statusText)
            status.fontName = "AvenirNext-DemiBold"
            status.fontSize = 11
            status.fontColor = isLocked ? GameUI.mutedInk : (isDestination ? GameUI.gold : GameUI.accent)
            status.horizontalAlignmentMode = .left
            status.position = CGPoint(x: leftX, y: -28)
            rowContent.addChild(status)
        }

        if listContentHeight > listViewportHeight + 1 {
            let track = SKShapeNode(rectOf: CGSize(width: 3, height: listViewportHeight - 10),
                                    cornerRadius: 1.5)
            track.fillColor = GameUI.line.withAlphaComponent(0.18)
            track.strokeColor = .clear
            track.position = CGPoint(x: listWidth / 2 + 7, y: listCenterY)
            track.zPosition = 6
            panelContent.addChild(track)

            scrollThumbHeight = max(30, (listViewportHeight / max(1, listContentHeight)) * (listViewportHeight - 10))
            let thumb = SKShapeNode(rectOf: CGSize(width: 4, height: scrollThumbHeight),
                                    cornerRadius: 2)
            thumb.fillColor = GameUI.accent.withAlphaComponent(0.55)
            thumb.strokeColor = .clear
            thumb.zPosition = 7
            thumb.position.x = track.position.x
            panelContent.addChild(thumb)
            scrollThumb = thumb
        }
        updateListScroll(0)

        let close = GameUI.pill(text: "Fechar registro",
                                fontSize: 14,
                                bold: false,
                                fill: [GameUI.coral.withAlphaComponent(0.95)],
                                strokeColor: GameUI.coral.withAlphaComponent(0.55),
                                textColor: GameUI.ink,
                                hPadding: 20,
                                height: 32)
        close.name = "region_close"
        close.position = CGPoint(x: 0, y: -panelHeight / 2 + 30)
        panelContent.addChild(close)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchStartLocation = touch.location(in: self)
        lastTouchLocation = touchStartLocation
        didScrollDuringTouch = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let dy = location.y - lastTouchLocation.y
        let totalDrag = hypot(location.x - touchStartLocation.x,
                              location.y - touchStartLocation.y)

        if listViewportRect.contains(touchStartLocation), listContentHeight > listViewportHeight {
            updateListScroll(listScrollOffset + dy)
            if totalDrag > 6 {
                didScrollDuringTouch = true
            }
        }

        lastTouchLocation = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !didScrollDuringTouch else { return }
        let location = touch.location(in: self)
        var node: SKNode? = atPoint(location)
        while let current = node {
            if let name = current.name {
                if name == "region_close" {
                    GameAudio.shared.play(.uiClosePanel)
                    onClose()
                    return
                }
                if name.hasPrefix("region_"),
                   listViewportRect.contains(location),
                   let region = rowRegions[String(name.dropFirst(7))] {
                    GameAudio.shared.play(.uiConfirm)
                    onSelect(region)
                    return
                }
            }
            node = current.parent
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        didScrollDuringTouch = false
    }

    private func updateListScroll(_ offset: CGFloat) {
        let maxOffset = max(0, listContentHeight - listViewportHeight)
        listScrollOffset = offset.clamped(to: 0...maxOffset)
        listNode.position.y = listScrollOffset

        guard let scrollThumb, maxOffset > 0 else { return }
        let progress = listScrollOffset / maxOffset
        let topY = listCenterY + listViewportHeight / 2 - scrollThumbHeight / 2 - 5
        let bottomY = listCenterY - listViewportHeight / 2 + scrollThumbHeight / 2 + 5
        scrollThumb.position.y = topY + (bottomY - topY) * progress
    }
}
