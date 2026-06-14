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
    private var mapRevealTimer: CGFloat = 0

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
        mapRevealTimer += dt
        if mapRevealTimer >= 2 {
            mapRevealTimer = 0
            ctx.stats.revealExpeditionMap(in: region, near: ctx.mermaidPosition)
        }

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

// MARK: - Pontos de Interesse

enum WorldPOIKind: String, Codable, CaseIterable {
    case shipwreck
    case npc
    case minigame
    case pet
    case story

    var displayName: String {
        switch self {
        case .shipwreck: return "Naufrágio"
        case .npc: return "Encontro"
        case .minigame: return "Desafio local"
        case .pet: return "Companhia"
        case .story: return "Memória"
        }
    }
}

struct WorldPOI: Codable {
    let key: String
    let regionId: String
    let zone: DepthZone
    let kind: WorldPOIKind
    let name: String
    let position: CGPoint
    let reward: Reward
}

enum WorldPOICatalog {
    static func pois(in region: Region, stats: MermaidStats) -> [WorldPOI] {
        DepthZone.accessOrder.flatMap { pois(in: region, zone: $0, stats: stats) }
    }

    static func pois(in region: Region, zone: DepthZone, stats: MermaidStats) -> [WorldPOI] {
        let seedBase = "\(region.id)|\(zone.storageKey)|\(Int(stats.birthDate.timeIntervalSince1970))"
        var rng = StableRNG(seed: stableHash(seedBase))
        return (0..<2).map { index in
            let kindIndex = (Int(rng.nextInt() % UInt64(WorldPOIKind.allCases.count)) + index)
                % WorldPOIKind.allCases.count
            let kind = WorldPOIKind.allCases[kindIndex]
            let key = "\(region.id)|\(zone.storageKey)|\(index)"
            let xPadding: CGFloat = 520
            let innerXMin = region.xRange.lowerBound + xPadding
            let innerXMax = region.xRange.upperBound - xPadding
            let xRange = innerXMin <= innerXMax ? innerXMin...innerXMax : region.xRange
            let yPadding: CGFloat = zone == .surface ? 24 : 220
            let innerYMin = zone.yRange.lowerBound + yPadding
            let innerYMax = zone.yRange.upperBound - yPadding
            let yRange = innerYMin <= innerYMax ? innerYMin...innerYMax : zone.yRange
            let position = CGPoint(x: rng.next(in: xRange),
                                   y: rng.next(in: yRange))
            return WorldPOI(key: key,
                            regionId: region.id,
                            zone: zone,
                            kind: kind,
                            name: name(for: kind, region: region, zone: zone),
                            position: position,
                            reward: reward(for: kind, region: region, zone: zone))
        }
    }

    private static func name(for kind: WorldPOIKind, region: Region, zone: DepthZone) -> String {
        switch kind {
        case .shipwreck: return "Naufrágio em \(zone.displayName)"
        case .npc: return "Viajante de \(region.name)"
        case .minigame: return "Marca de desafio"
        case .pet: return "Amigo pequeno"
        case .story: return "Sussurro antigo"
        }
    }

    private static func reward(for kind: WorldPOIKind, region: Region, zone: DepthZone) -> Reward {
        switch kind {
        case .shipwreck:
            return .item(id: "fragmento_\(region.id)", title: "fragmento de naufrágio")
        case .npc:
            return .temporaryEffect(.eagerCompanion, duration: 3600)
        case .minigame:
            return .temporaryEffect(.swiftCurrent, duration: 1800)
        case .pet:
            return .temporaryPet(title: "peixinho companheiro", duration: 3600)
        case .story:
            return .story("Ela ouviu uma história perdida em \(region.name), \(zone.displayName).")
        }
    }

    private struct StableRNG {
        private var state: UInt64

        init(seed: UInt64) {
            self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        mutating func nextInt() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }

        mutating func nextUnit() -> CGFloat {
            CGFloat(nextInt() % 10_000) / 10_000
        }

        mutating func next(in range: ClosedRange<CGFloat>) -> CGFloat {
            range.lowerBound + (range.upperBound - range.lowerBound) * nextUnit()
        }
    }

    private static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

final class POISystem {
    unowned let ctx: GameContext
    private var scanTimer: CGFloat = 0
    private var exploreFocusLevel = 0
    private var focusUntil: Date?

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    func update(dt: CGFloat) {
        if let focusUntil, focusUntil <= Date() {
            exploreFocusLevel = 0
            self.focusUntil = nil
        }

        scanTimer += dt
        guard scanTimer >= 1 else { return }
        scanTimer = 0
        discoverNearbyPOIs()
    }

    func explorationTargetAfterCommand() -> CGPoint? {
        exploreFocusLevel = min(5, exploreFocusLevel + 1)
        focusUntil = Date().addingTimeInterval(45)
        guard exploreFocusLevel >= 2 else { return nil }
        return nearestUndiscoveredPOI()?.position
    }

    private func discoverNearbyPOIs() {
        guard let region = ctx.regions.currentRegion else { return }
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        let baseRadius: CGFloat = ctx.autonomy.intent == .wandering ? 320 : 240
        let radius = baseRadius + CGFloat(exploreFocusLevel) * 85

        for poi in WorldPOICatalog.pois(in: region, zone: zone, stats: ctx.stats) {
            guard !ctx.stats.isPOIDiscovered(poi.key) else { continue }
            guard poi.position.distance(to: ctx.mermaidPosition) <= radius else { continue }
            ctx.stats.discoverPOI(poi.key)
            ctx.stats.revealExpeditionMap(in: region, near: poi.position)
            ctx.stats.gainXP(18)
            ctx.stats.boostMood(7)
            let rewardText = ctx.rewards.grant(poi.reward, source: poi.name)
            ctx.stats.addMemory("Descobriu \(poi.name)")
            ctx.say("Descobriu \(poi.name)! \(rewardText)")
            return
        }
    }

    private func nearestUndiscoveredPOI() -> WorldPOI? {
        guard let region = ctx.regions.currentRegion else { return nil }
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        return WorldPOICatalog.pois(in: region, zone: zone, stats: ctx.stats)
            .filter { !ctx.stats.isPOIDiscovered($0.key) }
            .min { lhs, rhs in
                lhs.position.distance(to: ctx.mermaidPosition) < rhs.position.distance(to: ctx.mermaidPosition)
            }
    }
}

// MARK: - Mini-mapa de expedição

final class ExpeditionMapNode: SKNode {
    private let mapSize: CGSize
    private let zoneOrder: [DepthZone] = [.abyss, .deep, .blue, .mid, .shallow, .clear, .surface]

    init(size: CGSize,
         stats: MermaidStats,
         region: Region,
         currentPosition: CGPoint?) {
        self.mapSize = size
        super.init()

        let frame = SKShapeNode(rectOf: size, cornerRadius: 16)
        frame.fillColor = UIColor(red: 0.02, green: 0.09, blue: 0.13, alpha: 0.58)
        frame.strokeColor = region.tint.withAlphaComponent(0.52)
        frame.lineWidth = 1.4
        frame.glowWidth = 1
        addChild(frame)

        drawDepthBands(stats: stats)
        drawRevealedCells(stats: stats, region: region)
        drawLockedVeil(stats: stats)
        drawPOIs(stats: stats, region: region)
        drawCurrentPosition(currentPosition, in: region)
        drawTitle(region.name)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var slotHeight: CGFloat {
        mapSize.height / CGFloat(zoneOrder.count)
    }

    private func drawDepthBands(stats: MermaidStats) {
        for (index, zone) in zoneOrder.enumerated() {
            let rect = SKShapeNode(rectOf: CGSize(width: mapSize.width, height: slotHeight))
            rect.position = CGPoint(x: 0, y: -mapSize.height / 2 + slotHeight * (CGFloat(index) + 0.5))
            let unlocked = stats.isUnlocked(zone) && stats.phase >= zone.minPhase
            rect.fillColor = unlocked
                ? mapColor(for: zone).withAlphaComponent(0.34)
                : UIColor(white: 0.18, alpha: 0.66)
            rect.strokeColor = UIColor.white.withAlphaComponent(0.05)
            rect.lineWidth = 0.5
            addChild(rect)

            let label = SKLabelNode(text: zone.displayName.replacingOccurrences(of: "Camada ", with: ""))
            label.fontName = "AvenirNext-DemiBold"
            label.fontSize = 8.5
            label.fontColor = unlocked ? UIColor.white.withAlphaComponent(0.48) : UIColor.white.withAlphaComponent(0.28)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -mapSize.width / 2 + 10, y: rect.position.y)
            addChild(label)
        }
    }

    private func drawRevealedCells(stats: MermaidStats, region: Region) {
        let reveal = stats.expeditionReveal(for: region.id)
        let cellWidth = mapSize.width / CGFloat(MermaidStats.expeditionMapColumns)
        let cellHeight = max(2.5, mapSize.height / CGFloat(MermaidStats.expeditionMapRows) * 0.82)

        for (key, amount) in reveal {
            guard amount > 0.04,
                  let cell = MermaidStats.expeditionCellCoordinates(from: key) else { continue }
            let x = -mapSize.width / 2 + (CGFloat(cell.column) + 0.5) * cellWidth
            let y = visualY(forWorldY: worldY(forRow: cell.row))
            let node = SKShapeNode(rectOf: CGSize(width: cellWidth + 0.5, height: cellHeight), cornerRadius: 1.2)
            node.position = CGPoint(x: x, y: y)
            node.fillColor = UIColor(red: 0.76, green: 0.95, blue: 0.92, alpha: 0.16 + amount * 0.50)
            node.strokeColor = .clear
            addChild(node)
        }
    }

    private func drawLockedVeil(stats: MermaidStats) {
        for (index, zone) in zoneOrder.enumerated() where !stats.isUnlocked(zone) || stats.phase < zone.minPhase {
            let veil = SKShapeNode(rectOf: CGSize(width: mapSize.width, height: slotHeight))
            veil.position = CGPoint(x: 0, y: -mapSize.height / 2 + slotHeight * (CGFloat(index) + 0.5))
            veil.fillColor = UIColor(white: 0.05, alpha: 0.36)
            veil.strokeColor = UIColor.white.withAlphaComponent(0.04)
            veil.lineWidth = 0.5
            addChild(veil)

            let lock = SKLabelNode(text: "bloq.")
            lock.fontName = "AvenirNext-DemiBold"
            lock.fontSize = 8
            lock.fontColor = UIColor.white.withAlphaComponent(0.34)
            lock.horizontalAlignmentMode = .right
            lock.verticalAlignmentMode = .center
            lock.position = CGPoint(x: mapSize.width / 2 - 10, y: veil.position.y)
            addChild(lock)
        }
    }

    private func drawCurrentPosition(_ position: CGPoint?, in region: Region) {
        guard let position, region.contains(position) else { return }
        let column = MermaidStats.expeditionColumn(forX: position.x, in: region)
        let x = -mapSize.width / 2
            + (CGFloat(column) + 0.5) * (mapSize.width / CGFloat(MermaidStats.expeditionMapColumns))
        let y = visualY(forWorldY: position.y)

        let pulse = SKShapeNode(circleOfRadius: 8)
        pulse.position = CGPoint(x: x, y: y)
        pulse.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 0.18)
        pulse.strokeColor = UIColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 0.58)
        pulse.lineWidth = 1
        addChild(pulse)

        let dot = SKShapeNode(circleOfRadius: 3.4)
        dot.position = pulse.position
        dot.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.45, alpha: 0.95)
        dot.strokeColor = UIColor.white.withAlphaComponent(0.72)
        dot.lineWidth = 0.8
        addChild(dot)
    }

    private func drawPOIs(stats: MermaidStats, region: Region) {
        let reveal = stats.expeditionReveal(for: region.id)
        for poi in WorldPOICatalog.pois(in: region, stats: stats) {
            let column = MermaidStats.expeditionColumn(forX: poi.position.x, in: region)
            let row = MermaidStats.expeditionRow(forY: poi.position.y)
            let cellKey = MermaidStats.expeditionCellKey(column: column, row: row)
            guard (reveal[cellKey] ?? 0) > 0.14 else { continue }

            let discovered = stats.isPOIDiscovered(poi.key)
            let node = SKNode()
            node.position = poiPoint(for: poi, in: region)
            node.name = discovered ? "poi_\(poi.key)" : nil
            addChild(node)

            let diamond = UIBezierPath()
            diamond.move(to: CGPoint(x: 0, y: 6))
            diamond.addLine(to: CGPoint(x: 6, y: 0))
            diamond.addLine(to: CGPoint(x: 0, y: -6))
            diamond.addLine(to: CGPoint(x: -6, y: 0))
            diamond.close()

            let marker = SKShapeNode(path: diamond.cgPath)
            marker.fillColor = discovered
                ? UIColor(red: 1.0, green: 0.82, blue: 0.34, alpha: 0.94)
                : UIColor.white.withAlphaComponent(0.22)
            marker.strokeColor = discovered
                ? UIColor.white.withAlphaComponent(0.72)
                : UIColor.white.withAlphaComponent(0.28)
            marker.lineWidth = 0.8
            marker.glowWidth = discovered ? 3 : 0
            marker.name = node.name
            node.addChild(marker)

            if discovered {
                let label = SKLabelNode(text: poi.kind.displayName)
                label.fontName = "AvenirNext-DemiBold"
                label.fontSize = 7.5
                label.fontColor = UIColor.white.withAlphaComponent(0.82)
                label.horizontalAlignmentMode = .left
                label.verticalAlignmentMode = .center
                label.position = CGPoint(x: 9, y: 0)
                label.name = node.name
                node.addChild(label)
            }
        }
    }

    private func drawTitle(_ text: String) {
        let title = SKLabelNode(text: text)
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 11
        title.fontColor = GameUI.ink
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -mapSize.width / 2 + 12, y: mapSize.height / 2 - 13)
        addChild(title)
    }

    private func visualY(forWorldY y: CGFloat) -> CGFloat {
        let zone = DepthZone.zone(atY: y)
        guard let index = zoneOrder.firstIndex(of: zone) else { return 0 }
        let span = max(1, zone.yRange.upperBound - zone.yRange.lowerBound)
        let t = ((y - zone.yRange.lowerBound) / span).clamped(to: 0...1)
        return -mapSize.height / 2 + CGFloat(index) * slotHeight + t * slotHeight
    }

    private func worldY(forRow row: Int) -> CGFloat {
        let t = CGFloat(row).clamped(to: 0...CGFloat(MermaidStats.expeditionMapRows - 1))
            / CGFloat(MermaidStats.expeditionMapRows - 1)
        return World.floorY + (World.surfaceTopY - World.floorY) * t
    }

    private func poiPoint(for poi: WorldPOI, in region: Region) -> CGPoint {
        let column = MermaidStats.expeditionColumn(forX: poi.position.x, in: region)
        let x = -mapSize.width / 2
            + (CGFloat(column) + 0.5) * (mapSize.width / CGFloat(MermaidStats.expeditionMapColumns))
        return CGPoint(x: x, y: visualY(forWorldY: poi.position.y))
    }

    private func mapColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface: return UIColor(red: 0.76, green: 0.88, blue: 0.96, alpha: 1)
        case .clear: return UIColor(red: 0.52, green: 0.88, blue: 0.88, alpha: 1)
        case .shallow: return UIColor(red: 0.28, green: 0.78, blue: 0.66, alpha: 1)
        case .mid: return UIColor(red: 0.18, green: 0.58, blue: 0.72, alpha: 1)
        case .blue: return UIColor(red: 0.16, green: 0.38, blue: 0.74, alpha: 1)
        case .deep: return UIColor(red: 0.10, green: 0.22, blue: 0.42, alpha: 1)
        case .abyss: return UIColor(red: 0.08, green: 0.06, blue: 0.18, alpha: 1)
        }
    }
}

// MARK: - Menu de regiões

final class RegionMenuOverlay: SKNode {
    private let onSelect: (Region) -> Void
    private let onPOISelect: (WorldPOI) -> Void
    private let onClose: () -> Void
    private var rowRegions: [String: Region] = [:]
    private var rowPOIs: [String: WorldPOI] = [:]
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
         currentPosition: CGPoint?,
         onSelect: @escaping (Region) -> Void,
         onPOISelect: @escaping (WorldPOI) -> Void,
         onClose: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onPOISelect = onPOISelect
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
        let mapPreviewHeight: CGFloat = size.height < 520 ? 0 : 148
        let headerHeight: CGFloat = 84 + mapPreviewHeight + (mapPreviewHeight > 0 ? 12 : 0)
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
        if mapPreviewHeight > 0,
           let previewId = currentRegionId ?? destinationId,
           let previewRegion = RegionDiscoverySystem.region(withId: previewId) {
            let map = ExpeditionMapNode(size: CGSize(width: listWidth, height: mapPreviewHeight),
                                        stats: stats,
                                        region: previewRegion,
                                        currentPosition: currentPosition)
            map.position = CGPoint(x: 0, y: panelHeight / 2 - 84 - mapPreviewHeight / 2)
            map.zPosition = 4
            panelContent.addChild(map)

            for poi in WorldPOICatalog.pois(in: previewRegion, stats: stats) where stats.isPOIDiscovered(poi.key) {
                rowPOIs[poi.key] = poi
            }
        }

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
                if name.hasPrefix("poi_"),
                   let poi = rowPOIs[String(name.dropFirst(4))] {
                    GameAudio.shared.play(.uiConfirm)
                    onPOISelect(poi)
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
