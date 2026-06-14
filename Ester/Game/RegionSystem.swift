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
        CGPoint(x: (playableXRange.lowerBound + playableXRange.upperBound) / 2,
                y: entryZone.midY.clamped(to: yRange))
    }

    var playableXRange: ClosedRange<CGFloat> {
        World.minX...World.maxX
    }

    func contains(_ point: CGPoint) -> Bool {
        playableXRange.contains(point.x) && yRange.contains(point.y)
    }

    func isAccessible(for phase: MermaidPhase) -> Bool {
        phase >= minPhase
    }
}

enum EntryTextCatalog {
    static func text(for region: Region, zone: DepthZone) -> String {
        if let specific = specificText["\(region.id)|\(zone.storageKey)"] {
            return specific
        }

        switch zone {
        case .surface:
            return "\(region.name): a luz da superfície abre reflexos novos sobre a água."
        case .clear:
            return "\(region.name): águas claras deixam cada movimento parecer uma descoberta."
        case .shallow:
            return "\(region.name): a camada rasa pulsa com vida pequena e curiosa."
        case .mid:
            return "\(region.name): o azul médio guarda caminhos calmos e ecos distantes."
        case .blue:
            return "\(region.name): a água azul pesa um pouco mais, chamando calma tranquila."
        case .deep:
            return "\(region.name): a profundidade abafa o mundo e acende sinais frios."
        case .abyss:
            return "\(region.name): no abismo, tudo parece respirar devagar."
        }
    }

    private static let specificText: [String: String] = [
        "nascente|shallow": "Águas de Nascimento: conchas pequenas tremem como lembranças novas.",
        "nascente|mid": "Águas de Nascimento: no azul médio, ela sente o berço ficando maior.",
        "jardim_calmo|shallow": "Jardim Calmo: folhas macias balançam sem pressa ao redor dela.",
        "jardim_calmo|mid": "Jardim Calmo: raízes antigas escondem uma calma que parece responder."
    ]
}

// MARK: - Descoberta de regiões

final class RegionDiscoverySystem {
    unowned let ctx: GameContext
    private var progressTimer: CGFloat = 0
    private var mapRevealTimer: CGFloat = 0
    private var leadTimer: CGFloat = 0

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
        ctx.activeRegion
    }

    func update(dt: CGFloat) {
        guard let region = currentRegion else { return }

        ctx.stats.ensureBaselineRegionAccess()

        // Migração defensiva: se a cena atual veio de um save antigo, mantém o mapa conhecido.
        if !ctx.stats.discoveredRegionIds.contains(region.id) {
            ctx.stats.discoveredRegionIds.insert(region.id)
            ctx.stats.addMemory("Descobriu \(region.name)")
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
            ctx.stats.rememberMapPosition(ctx.mermaidPosition, in: region)
            let current = ctx.stats.regionProgress[region.id] ?? 0
            if current < 1 {
                ctx.stats.regionProgress[region.id] = min(1, current + 5.0 / 1200.0 * ctx.stats.explorationProgressMultiplier)
            }
        }

        leadTimer += dt
        if leadTimer >= 34 {
            leadTimer = 0
            maybeRevealRegionLead(source: "exploração", chance: 0.18)
        }
        updateDiscoveryRoute(in: region)
    }

    /// Tinta da região misturada na cor da água.
    func waterTint(at point: CGPoint) -> (color: UIColor, strength: CGFloat)? {
        guard let region = ctx.activeRegion else { return nil }
        return (region.tint, region.tintStrength)
    }

    /// Paleta de peixes característica da região (nil = paleta da camada).
    static func fishPalette(for regionId: String) -> [UIColor]? {
        switch regionId {
        case "nascente":
            return [UIColor(red: 0.60, green: 0.82, blue: 0.98, alpha: 1),
                    UIColor(red: 0.92, green: 0.72, blue: 0.88, alpha: 1),
                    UIColor(red: 0.78, green: 0.92, blue: 0.96, alpha: 1)]
        case "jardim_calmo":
            return [UIColor(red: 0.38, green: 0.82, blue: 0.68, alpha: 1),
                    UIColor(red: 0.72, green: 0.88, blue: 0.58, alpha: 1),
                    UIColor(red: 0.58, green: 0.78, blue: 0.78, alpha: 1)]
        case "recife":
            return [UIColor(red: 0.95, green: 0.5, blue: 0.25, alpha: 1),
                    UIColor(red: 0.7, green: 0.4, blue: 0.85, alpha: 1),
                    UIColor(red: 0.3, green: 0.85, blue: 0.7, alpha: 1),
                    UIColor(red: 0.95, green: 0.75, blue: 0.3, alpha: 1)]
        case "delta":
            return [UIColor(red: 0.55, green: 0.5, blue: 0.35, alpha: 1),
                    UIColor(red: 0.65, green: 0.6, blue: 0.45, alpha: 1),
                    UIColor(red: 0.5, green: 0.55, blue: 0.4, alpha: 1)]
        case "mar_azul_aberto":
            return [UIColor(red: 0.22, green: 0.48, blue: 0.92, alpha: 1),
                    UIColor(red: 0.42, green: 0.68, blue: 0.98, alpha: 1),
                    UIColor(red: 0.82, green: 0.90, blue: 1.0, alpha: 1)]
        case "cavernas":
            return [UIColor(red: 0.18, green: 0.38, blue: 0.48, alpha: 1),
                    UIColor(red: 0.34, green: 0.58, blue: 0.68, alpha: 1),
                    UIColor(red: 0.52, green: 0.80, blue: 0.86, alpha: 1)]
        case "campos_cristal":
            return [UIColor(red: 0.74, green: 0.92, blue: 1.0, alpha: 1),
                    UIColor(red: 0.54, green: 0.72, blue: 0.98, alpha: 1),
                    UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 1)]
        case "ruinas":
            return [UIColor(red: 0.46, green: 0.40, blue: 0.62, alpha: 1),
                    UIColor(red: 0.62, green: 0.58, blue: 0.74, alpha: 1),
                    UIColor(red: 0.78, green: 0.72, blue: 0.62, alpha: 1)]
        case "abismo_vivo":
            return [UIColor(red: 0.42, green: 0.18, blue: 0.70, alpha: 1),
                    UIColor(red: 0.16, green: 0.76, blue: 0.86, alpha: 1),
                    UIColor(red: 0.88, green: 0.32, blue: 0.68, alpha: 1)]
        case "superficie_distante":
            return [UIColor(red: 0.84, green: 0.94, blue: 1.0, alpha: 1),
                    UIColor(red: 1.0, green: 0.86, blue: 0.52, alpha: 1),
                    UIColor(red: 0.58, green: 0.76, blue: 0.96, alpha: 1)]
        default:
            return nil
        }
    }

    /// Comidas extras típicas da região.
    static func extraFood(for regionId: String) -> [FoodKind] {
        switch regionId {
        case "nascente":
            return [
                FoodKind(name: "plâncton de berço", weight: 4, nutrition: 12, xp: 3, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.72, green: 0.9, blue: 1.0, alpha: 1)),
                FoodKind(name: "conchinha morna", weight: 2, nutrition: 0, xp: 4, pearls: 1, courage: 0, style: .pearl, color: UIColor(red: 0.95, green: 0.82, blue: 0.92, alpha: 1))
            ]
        case "jardim_calmo":
            return [
                FoodKind(name: "folha doce", weight: 4, nutrition: 14, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.46, green: 0.76, blue: 0.48, alpha: 1)),
                FoodKind(name: "frutinha d'água", weight: 3, nutrition: 18, xp: 4, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.82, green: 0.58, blue: 0.72, alpha: 1))
            ]
        case "recife":
            return [
                FoodKind(name: "baga de coral", weight: 3, nutrition: 20, xp: 5, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.95, green: 0.35, blue: 0.55, alpha: 1)),
                FoodKind(name: "alga do recife", weight: 3, nutrition: 15, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.95, green: 0.55, blue: 0.65, alpha: 1))
            ]
        case "delta":
            return [
                FoodKind(name: "semente de rio", weight: 4, nutrition: 16, xp: 4, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.75, green: 0.65, blue: 0.35, alpha: 1)),
                FoodKind(name: "folha do delta", weight: 3, nutrition: 13, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.5, green: 0.6, blue: 0.3, alpha: 1))
            ]
        case "mar_azul_aberto":
            return [
                FoodKind(name: "sal azul", weight: 2, nutrition: 9, xp: 5, pearls: 1, courage: 0, style: .crystal, color: UIColor(red: 0.34, green: 0.62, blue: 1.0, alpha: 1)),
                FoodKind(name: "alga de corrente", weight: 3, nutrition: 17, xp: 4, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.22, green: 0.58, blue: 0.72, alpha: 1))
            ]
        case "cavernas":
            return [
                FoodKind(name: "musgo de pedra", weight: 4, nutrition: 15, xp: 4, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.26, green: 0.52, blue: 0.46, alpha: 1)),
                FoodKind(name: "gota luminosa", weight: 2, nutrition: 10, xp: 6, pearls: 1, courage: 0, style: .glow, color: UIColor(red: 0.58, green: 0.86, blue: 0.92, alpha: 1))
            ]
        case "campos_cristal":
            return [
                FoodKind(name: "fruto de cristal", weight: 2, nutrition: 18, xp: 7, pearls: 1, courage: 0, style: .crystal, color: UIColor(red: 0.74, green: 0.9, blue: 1.0, alpha: 1)),
                FoodKind(name: "plâncton prismático", weight: 3, nutrition: 12, xp: 5, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.86, green: 0.78, blue: 1.0, alpha: 1))
            ]
        case "ruinas":
            return [
                FoodKind(name: "semente antiga", weight: 3, nutrition: 16, xp: 6, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.62, green: 0.54, blue: 0.36, alpha: 1)),
                FoodKind(name: "concha gravada", weight: 2, nutrition: 0, xp: 6, pearls: 2, courage: 0, style: .pearl, color: UIColor(red: 0.76, green: 0.70, blue: 0.58, alpha: 1))
            ]
        case "abismo_vivo":
            return [
                FoodKind(name: "luz abissal", weight: 2, nutrition: 20, xp: 8, pearls: 1, courage: 0, style: .glow, color: UIColor(red: 0.48, green: 0.92, blue: 1.0, alpha: 1)),
                FoodKind(name: "cristal vivo", weight: 1, nutrition: 22, xp: 9, pearls: 2, courage: 0, style: .crystal, color: UIColor(red: 0.76, green: 0.32, blue: 0.92, alpha: 1))
            ]
        case "superficie_distante":
            return [
                FoodKind(name: "gota de sol", weight: 2, nutrition: 18, xp: 7, pearls: 1, courage: 0, style: .glow, color: UIColor(red: 1.0, green: 0.86, blue: 0.46, alpha: 1)),
                FoodKind(name: "fruta flutuante", weight: 3, nutrition: 20, xp: 5, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.92, green: 0.62, blue: 0.48, alpha: 1))
            ]
        default:
            return []
        }
    }

    func canSelect(_ region: Region) -> Bool {
        guard ctx.stats.phase >= region.minPhase else { return false }
        return ctx.stats.isRegionKnown(region) || ctx.stats.hasDiscoveryLead(for: region)
    }

    @discardableResult
    func maybeRevealRegionLead(source: String, chance: CGFloat) -> Bool {
        guard CGFloat.random(in: 0...1) <= chance else { return false }
        return revealNextRegionLead(source: source)
    }

    @discardableResult
    func revealNextRegionLead(source: String) -> Bool {
        guard ctx.stats.pendingRegionDiscoveryId == nil,
              ctx.stats.discoveryRouteRegionId == nil,
              ctx.stats.readyRegionDiscoveryId == nil,
              let current = currentRegion,
              let destination = nextDiscoverableRegion() else { return false }

        let point = ctx.stats.discoveryPoint(for: destination, from: current)
        ctx.stats.pendingRegionDiscoveryId = destination.id
        ctx.stats.revealExpeditionMap(in: current, near: point)
        ctx.stats.addMemory("Encontrou pista para \(destination.name)")
        GameAudio.shared.play(.regionDiscover)
        ctx.say("Um fragmento de corrente aponta para \(destination.name). Abra o mapa para seguir a pista.")
        return true
    }

    @discardableResult
    func startDiscoveryRoute(to region: Region) -> Bool {
        guard let current = currentRegion,
              ctx.stats.pendingRegionDiscoveryId == region.id
                || ctx.stats.discoveryRouteRegionId == region.id else { return false }
        let point = ctx.stats.discoveryPoint(for: region, from: current)
        guard ctx.autonomy.requestPointFromTouch(point) else { return false }
        ctx.stats.pendingRegionDiscoveryId = nil
        ctx.stats.discoveryRouteRegionId = region.id
        ctx.stats.revealExpeditionMap(in: current, near: point)
        ctx.say("Ela aceitou seguir a pista até a borda de \(region.name).")
        return true
    }

    @discardableResult
    func completeDiscovery(for region: Region) -> Bool {
        guard ctx.stats.readyRegionDiscoveryId == region.id else { return false }
        ctx.stats.readyRegionDiscoveryId = nil
        ctx.stats.pendingRegionDiscoveryId = nil
        ctx.stats.discoveryRouteRegionId = nil
        ctx.stats.discoveredRegionIds.insert(region.id)
        ctx.stats.discoveryPointByRegion[region.id] = nil
        ctx.stats.gainXP(40)
        let gained = ctx.stats.awardPearls(4)
        ctx.stats.addMemory("Confirmou rota para \(region.name)")
        GameAudio.shared.play(.regionDiscover)
        ctx.say("Rota aberta: \(region.name). Conchas +\(gained)")
        return true
    }

    private func nextDiscoverableRegion() -> Region? {
        RegionDiscoverySystem.menuRegions
            .filter { region in
                region.isAccessible(for: ctx.stats.phase)
                    && !ctx.stats.isRegionKnown(region)
                    && !ctx.stats.hasDiscoveryLead(for: region)
            }
            .randomElement()
    }

    private func updateDiscoveryRoute(in current: Region) {
        guard let id = ctx.stats.discoveryRouteRegionId,
              let destination = RegionDiscoverySystem.region(withId: id) else { return }
        let point = ctx.stats.discoveryPoint(for: destination, from: current)
        ctx.stats.revealExpeditionMap(in: current, near: point)
        guard ctx.mermaidPosition.distance(to: point) < 180 else { return }
        ctx.stats.discoveryRouteRegionId = nil
        ctx.stats.readyRegionDiscoveryId = id
        ctx.scene?.showRegionDiscoveryCue(for: destination)
        ctx.say("A água mudou de cor. \(destination.name) está logo além; confirme no mapa.")
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
        let saved = ctx.stats.savedMapPosition(for: destination) ?? destination.center
        return CGPoint(x: saved.x.clamped(to: destination.playableXRange),
                       y: saved.y.clamped(to: yRange))
    }

    func setDestination(_ region: Region) {
        if ctx.activeRegion?.id == region.id {
            ctx.say("Ela já está em \(region.name).")
            return
        }
        if ctx.stats.phase < region.minPhase {
            ctx.say("Disponível quando ela for \(region.minPhase.mapAccessDisplayName).")
            return
        }
        if !ctx.stats.isRegionKnown(region) {
            if ctx.stats.readyRegionDiscoveryId == region.id {
                guard ctx.regions.completeDiscovery(for: region) else { return }
            } else if ctx.stats.hasDiscoveryLead(for: region) {
                _ = ctx.regions.startDiscoveryRoute(to: region)
                return
            } else {
                ctx.say("Ela ainda precisa encontrar uma pista para \(region.name).")
                return
            }
        }
        if let current = ctx.regions.currentRegion {
            ctx.stats.rememberMapPosition(ctx.mermaidPosition, in: current)
        }
        ctx.stats.destinationRegionId = region.id
        GameAudio.shared.play(.travelStart)
        ctx.say("Ela seguiu rumo a \(region.name).")
        ctx.scene?.transitionToMap(region)
    }

    func clearDestination() {
        ctx.stats.destinationRegionId = nil
    }

    func update(dt: CGFloat) {
        guard let destination else { return }
        guard ctx.activeRegion?.id != destination.id else {
            clearDestination()
            return
        }
        ctx.scene?.transitionToMap(destination)
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

struct POIVisual: Codable {
    let glyph: String
    let tint: String
    let scale: CGFloat

    init(glyph: String, tint: String, scale: CGFloat = 1) {
        self.glyph = glyph
        self.tint = tint
        self.scale = scale
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        glyph = try c.decode(String.self, forKey: .glyph)
        tint = try c.decodeIfPresent(String.self, forKey: .tint) ?? "gold"
        scale = try c.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
    }

    static func `default`(for kind: WorldPOIKind) -> POIVisual {
        switch kind {
        case .shipwreck: return POIVisual(glyph: "▧", tint: "sand")
        case .npc: return POIVisual(glyph: "?", tint: "coral")
        case .minigame: return POIVisual(glyph: "◇", tint: "gold")
        case .pet: return POIVisual(glyph: "•", tint: "aqua")
        case .story: return POIVisual(glyph: "✦", tint: "violet")
        }
    }

    var color: UIColor {
        switch tint.lowercased() {
        case "aqua": return UIColor(red: 0.40, green: 0.86, blue: 0.88, alpha: 1)
        case "teal": return GameUI.accent
        case "coral": return GameUI.coral
        case "gold": return GameUI.gold
        case "algae": return GameUI.algae
        case "violet": return UIColor(red: 0.68, green: 0.50, blue: 0.92, alpha: 1)
        case "sand": return UIColor(red: 0.72, green: 0.62, blue: 0.42, alpha: 1)
        default: return GameUI.gold
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
    let visual: POIVisual
}

enum WorldPOICatalog {
    static func pois(in region: Region, stats: MermaidStats) -> [WorldPOI] {
        DepthZone.accessOrder.flatMap { pois(in: region, zone: $0, stats: stats) }
    }

    static func pois(in region: Region, zone: DepthZone, stats: MermaidStats) -> [WorldPOI] {
        let definitions = configuredDefinitions.filter { $0.mapId == region.id && $0.zone == zone.storageKey }
        if !definitions.isEmpty {
            return definitions.enumerated().map { index, definition in
                let position = configuredPosition(for: definition,
                                                  index: index,
                                                  totalCount: definitions.count,
                                                  region: region,
                                                  zone: zone,
                                                  stats: stats)
                return WorldPOI(key: definition.poiId,
                                regionId: region.id,
                                zone: zone,
                                kind: definition.kind,
                                name: definition.name,
                                position: position,
                                reward: definition.reward,
                                visual: definition.visual ?? .default(for: definition.kind))
            }
        }

        let seedBase = "\(region.id)|\(zone.storageKey)|\(Int(stats.birthDate.timeIntervalSince1970))"
        var rng = StableRNG(seed: stableHash(seedBase))
        return (0..<2).map { index in
            let kindIndex = (Int(rng.nextInt() % UInt64(WorldPOIKind.allCases.count)) + index)
                % WorldPOIKind.allCases.count
            let kind = WorldPOIKind.allCases[kindIndex]
            let key = "\(region.id)|\(zone.storageKey)|\(index)"
            let xPadding: CGFloat = 520
            let innerXMin = region.playableXRange.lowerBound + xPadding
            let innerXMax = region.playableXRange.upperBound - xPadding
            let xRange = innerXMin <= innerXMax ? innerXMin...innerXMax : region.playableXRange
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
                            reward: reward(for: kind, region: region, zone: zone),
                            visual: .default(for: kind))
        }
    }

    private struct POIDefinition: Decodable {
        let poiId: String
        let mapId: String
        let zone: String
        let kind: WorldPOIKind
        let name: String
        let reward: Reward
        let visual: POIVisual?
    }

    private static let configuredDefinitions: [POIDefinition] = {
        let url = Bundle.main.url(forResource: "WorldPOIs", withExtension: "json")
            ?? Bundle.main.url(forResource: "WorldPOIs", withExtension: "json", subdirectory: "GameData")
        guard let url,
              let data = try? Data(contentsOf: url),
              let definitions = try? JSONDecoder().decode([POIDefinition].self, from: data) else {
            return []
        }
        return definitions
    }()

    private static func configuredPosition(for definition: POIDefinition,
                                           index: Int,
                                           totalCount: Int,
                                           region: Region,
                                           zone: DepthZone,
                                           stats: MermaidStats) -> CGPoint {
        let seedBase = "\(definition.poiId)|\(region.id)|\(zone.storageKey)|\(Int(stats.birthDate.timeIntervalSince1970))"
        var rng = StableRNG(seed: stableHash(seedBase))
        let xPadding: CGFloat = 520
        let innerXMin = region.playableXRange.lowerBound + xPadding
        let innerXMax = region.playableXRange.upperBound - xPadding
        let xRange = innerXMin <= innerXMax ? innerXMin...innerXMax : region.playableXRange
        let yPadding: CGFloat = zone == .surface ? 24 : 220
        let innerYMin = zone.yRange.lowerBound + yPadding
        let innerYMax = zone.yRange.upperBound - yPadding
        let yRange = innerYMin <= innerYMax ? innerYMin...innerYMax : zone.yRange
        let lane = CGFloat(index + 1) / CGFloat(max(2, totalCount + 1))
        let jitterRange: ClosedRange<CGFloat> = -220...220
        let x = (xRange.lowerBound + (xRange.upperBound - xRange.lowerBound) * lane
                 + rng.next(in: jitterRange)).clamped(to: xRange)
        return CGPoint(x: x, y: rng.next(in: yRange))
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
    private weak var worldNode: SKNode?
    private var scanTimer: CGFloat = 0
    private var exploreFocusLevel = 0
    private var focusUntil: Date?
    private var pendingInteraction: WorldPOI?
    private var visibleNodes: [String: WorldPOINode] = [:]
    private var visiblePOIs: [String: WorldPOI] = [:]

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        if let focusUntil, focusUntil <= Date() {
            exploreFocusLevel = 0
            self.focusUntil = nil
        }

        scanTimer += dt
        guard scanTimer >= 1 else { return }
        scanTimer = 0
        syncWorldNodes()
        discoverNearbyPOIs()
        completePendingInteractionIfReached()
    }

    func explorationTargetAfterCommand() -> CGPoint? {
        exploreFocusLevel = min(5, exploreFocusLevel + 1)
        focusUntil = Date().addingTimeInterval(45)
        guard exploreFocusLevel >= 2 else { return nil }
        return nearestUndiscoveredPOI()?.position
    }

    func nearestVisiblePOI(to point: CGPoint, maxDistance: CGFloat) -> WorldPOI? {
        syncWorldNodes()
        return visiblePOIs.values
            .filter { $0.position.distance(to: point) <= maxDistance }
            .min { lhs, rhs in
                lhs.position.distance(to: point) < rhs.position.distance(to: point)
            }
    }

    @discardableResult
    func requestReturn(to poi: WorldPOI) -> Bool {
        guard ctx.stats.isPOIDiscovered(poi.key) else {
            ctx.say("Ela só vê uma silhueta no mapa. Precisa chegar mais perto primeiro.")
            return false
        }
        guard ctx.regions.currentRegion?.id == poi.regionId else {
            ctx.say("\(poi.name) fica em outro mapa. Viaje para lá antes de voltar ao ponto.")
            return false
        }
        guard isReachable(poi) else {
            ctx.say("\(poi.name) está em uma profundidade que ela ainda não alcança.")
            return false
        }
        guard ctx.autonomy.canReachPointWithCurrentEnergy(poi.position, margin: 24) else {
            ctx.say("\(poi.name) está marcado, mas longe demais para a energia atual. Aproxime-se ou deixe ela descansar antes de interagir.")
            return false
        }
        guard ctx.autonomy.requestPointFromTouch(poi.position) else { return false }
        pendingInteraction = poi
        syncWorldNodes()
        ctx.say("Ela aceitou voltar a \(poi.name). O ponto já está visível no mundo.")
        completePendingInteractionIfReached()
        return true
    }

    private func syncWorldNodes() {
        guard let worldNode,
              let region = ctx.regions.currentRegion else {
            removeAllWorldNodes()
            return
        }

        let pois = WorldPOICatalog.pois(in: region, stats: ctx.stats)
            .filter { shouldShowInWorld($0) }
        let validKeys = Set(pois.map { $0.key })

        let staleKeys = visibleNodes.keys.filter { !validKeys.contains($0) }
        for key in staleKeys {
            visibleNodes[key]?.removeFromParent()
            visibleNodes[key] = nil
            visiblePOIs[key] = nil
        }

        for poi in pois {
            let discovered = ctx.stats.isPOIDiscovered(poi.key)
            let collected = ctx.stats.isPOIRewardCollected(poi.key)
            let focused = pendingInteraction?.key == poi.key

            if let node = visibleNodes[poi.key] {
                node.position = poi.position
                node.update(discovered: discovered, rewardCollected: collected, focused: focused)
            } else {
                let node = WorldPOINode(poi: poi,
                                        discovered: discovered,
                                        rewardCollected: collected,
                                        focused: focused)
                node.position = poi.position
                worldNode.addChild(node)
                visibleNodes[poi.key] = node
            }
            visiblePOIs[poi.key] = poi
        }
    }

    private func removeAllWorldNodes() {
        for node in visibleNodes.values {
            node.removeFromParent()
        }
        visibleNodes.removeAll()
        visiblePOIs.removeAll()
    }

    private func shouldShowInWorld(_ poi: WorldPOI) -> Bool {
        guard ctx.stats.isPOIDiscovered(poi.key) else { return false }
        return isReachable(poi)
    }

    private func isReachable(_ poi: WorldPOI) -> Bool {
        ctx.stats.phase >= poi.zone.minPhase && ctx.stats.isUnlocked(poi.zone)
    }

    private func discoverNearbyPOIs() {
        guard let region = ctx.regions.currentRegion else { return }
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        let baseRadius: CGFloat = ctx.autonomy.intent == .wandering ? 320 : 240
        let radius = baseRadius + CGFloat(exploreFocusLevel) * 85

        for poi in WorldPOICatalog.pois(in: region, zone: zone, stats: ctx.stats) {
            guard !ctx.stats.isPOIDiscovered(poi.key) else { continue }
            guard isReachable(poi) else { continue }
            guard poi.position.distance(to: ctx.mermaidPosition) <= radius else { continue }
            ctx.stats.discoverPOI(poi.key)
            ctx.stats.revealExpeditionMap(in: region, near: poi.position)
            ctx.stats.addMemory("Descobriu \(poi.name)")
            syncWorldNodes()
            ctx.say("Ponto descoberto: \(poi.name). Ele ficou marcado no mapa de expedição.")
            return
        }
    }

    private func completePendingInteractionIfReached() {
        guard let poi = pendingInteraction,
              ctx.regions.currentRegion?.id == poi.regionId,
              ctx.mermaidPosition.distance(to: poi.position) < 150 else { return }
        pendingInteraction = nil
        interact(with: poi)
    }

    private func interact(with poi: WorldPOI) {
        ctx.stats.visitPOI(poi.key)
        ctx.stats.revealExpeditionMap(in: ctx.activeRegion, near: poi.position)

        if ctx.stats.isPOIRewardCollected(poi.key) {
            syncWorldNodes()
            ctx.say("Ela voltou a \(poi.name) e reconheceu o lugar. A recompensa dali já foi coletada.")
            return
        }

        if poi.kind == .minigame {
            guard let scene = ctx.scene,
                  scene.openPOIChallenge(for: poi, onCompletion: { [weak self] result in
                      self?.finishPOIChallenge(poi, result: result)
                  }) else {
                ctx.say("O desafio local de \(poi.name) não abriu agora. Tente de novo em instantes.")
                return
            }
            ctx.say("Ela começou o desafio local de \(poi.name).")
            return
        }

        grantReward(for: poi, prefix: "Ela explorou \(poi.name).")
    }

    private func finishPOIChallenge(_ poi: WorldPOI, result: ChallengeResult) {
        guard ctx.regions.currentRegion?.id == poi.regionId else { return }
        guard result.reachedTarget else {
            syncWorldNodes()
            ctx.say("Ela tentou o desafio de \(poi.name). A recompensa dali ainda espera uma vitória.")
            return
        }
        grantReward(for: poi, prefix: "Desafio concluído em \(poi.name).")
    }

    private func grantReward(for poi: WorldPOI, prefix: String) {
        ctx.stats.collectPOIReward(poi.key)
        let rewardText = ctx.rewards.grant(poi.reward, source: poi.name)
        ctx.stats.addMemory("Interagiu com \(poi.name)")
        _ = ctx.regions.maybeRevealRegionLead(source: "POI", chance: 0.35)
        syncWorldNodes()
        ctx.stats.save()
        ctx.say("\(prefix) \(rewardText)")
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
        frame.fillColor = UIColor(red: 0.01, green: 0.06, blue: 0.10, alpha: 0.88)
        frame.strokeColor = region.tint.withAlphaComponent(0.82)
        frame.lineWidth = 1.6
        frame.glowWidth = 2
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

        let labelBg = SKShapeNode(rectOf: CGSize(width: 38, height: 15), cornerRadius: 7.5)
        labelBg.position = CGPoint(x: x + 28, y: y + 13)
        labelBg.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.10, alpha: 0.88)
        labelBg.strokeColor = GameUI.gold.withAlphaComponent(0.72)
        labelBg.lineWidth = 0.8
        addChild(labelBg)

        let label = SKLabelNode(text: "você")
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 7.5
        label.fontColor = GameUI.palePaper
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = labelBg.position
        addChild(label)
    }

    private func drawPOIs(stats: MermaidStats, region: Region) {
        let reveal = stats.expeditionReveal(for: region.id)
        for poi in WorldPOICatalog.pois(in: region, stats: stats) {
            guard stats.phase >= poi.zone.minPhase && stats.isUnlocked(poi.zone) else { continue }
            let column = MermaidStats.expeditionColumn(forX: poi.position.x, in: region)
            let row = MermaidStats.expeditionRow(forY: poi.position.y)
            let cellKey = MermaidStats.expeditionCellKey(column: column, row: row)
            guard (reveal[cellKey] ?? 0) > 0.14 else { continue }

            let discovered = stats.isPOIDiscovered(poi.key)
            let node = SKNode()
            node.position = poiPoint(for: poi, in: region)
            node.name = discovered ? "poi_\(poi.key)" : nil
            addChild(node)

            let marker = SKShapeNode(circleOfRadius: discovered ? 7.2 : 6.0)
            marker.fillColor = discovered
                ? poi.visual.color.withAlphaComponent(0.92)
                : UIColor.white.withAlphaComponent(0.22)
            marker.strokeColor = discovered
                ? UIColor.white.withAlphaComponent(0.72)
                : UIColor.white.withAlphaComponent(0.28)
            marker.lineWidth = 0.8
            marker.glowWidth = discovered ? 3 : 0
            marker.name = node.name
            node.addChild(marker)

            if discovered {
                let glyph = SKLabelNode(text: poi.visual.glyph)
                glyph.fontName = "AvenirNext-DemiBold"
                glyph.fontSize = 8
                glyph.fontColor = UIColor.white.withAlphaComponent(0.92)
                glyph.horizontalAlignmentMode = .center
                glyph.verticalAlignmentMode = .center
                glyph.name = node.name
                glyph.zPosition = 2
                node.addChild(glyph)

                let label = SKLabelNode(text: poi.name)
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
        let badgeWidth = min(mapSize.width - 24, max(168, CGFloat(text.count) * 6.8 + 72))
        let badge = SKShapeNode(rectOf: CGSize(width: badgeWidth, height: 34), cornerRadius: 11)
        badge.fillColor = UIColor(red: 0.01, green: 0.04, blue: 0.07, alpha: 0.92)
        badge.strokeColor = GameUI.gold.withAlphaComponent(0.58)
        badge.lineWidth = 1
        badge.position = CGPoint(x: -mapSize.width / 2 + 12 + badgeWidth / 2,
                                 y: mapSize.height / 2 - 23)
        badge.zPosition = 20
        addChild(badge)

        let eyebrow = SKLabelNode(text: "MAPA ATUAL")
        eyebrow.fontName = "AvenirNext-Heavy"
        eyebrow.fontSize = 6.5
        eyebrow.fontColor = GameUI.gold.withAlphaComponent(0.95)
        eyebrow.horizontalAlignmentMode = .left
        eyebrow.verticalAlignmentMode = .center
        eyebrow.position = CGPoint(x: badge.position.x - badgeWidth / 2 + 10,
                                   y: badge.position.y + 7)
        eyebrow.zPosition = 21
        addChild(eyebrow)

        let title = SKLabelNode(text: text)
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 11.5
        title.fontColor = GameUI.palePaper
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: eyebrow.position.x, y: badge.position.y - 7)
        title.zPosition = 21
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
    private var closeButtonRect: CGRect = .zero

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

        func menuLabel(_ text: String,
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
            }
            return label
        }

        func stateBadge(text: String, color: UIColor, width: CGFloat = 82) -> SKNode {
            let node = SKNode()
            let bg = SKShapeNode(rectOf: CGSize(width: width, height: 24), cornerRadius: 8)
            bg.fillColor = UIColor.lerp(GameUI.palePaper, color, 0.18)
            bg.strokeColor = color.withAlphaComponent(0.58)
            bg.lineWidth = 0.9
            node.addChild(bg)

            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Heavy"
            label.fontSize = 8.5
            label.fontColor = UIColor.lerp(GameUI.ink, color, 0.28)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 2
            node.addChild(label)
            return node
        }

        func progressBar(width: CGFloat, progress: CGFloat, color: UIColor) -> SKNode {
            let node = SKNode()
            let track = SKShapeNode(rectOf: CGSize(width: width, height: 5), cornerRadius: 2.5)
            track.fillColor = GameUI.line.withAlphaComponent(0.14)
            track.strokeColor = .clear
            node.addChild(track)

            let fillWidth = max(6, width * progress.clamped(to: 0...1))
            let fill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 5), cornerRadius: 2.5)
            fill.fillColor = color.withAlphaComponent(0.78)
            fill.strokeColor = .clear
            fill.position.x = -width / 2 + fillWidth / 2
            fill.zPosition = 2
            node.addChild(fill)
            return node
        }

        func legendItem(text: String,
                        color: UIColor,
                        x: CGFloat,
                        y: CGFloat,
                        hollow: Bool = false) -> SKNode {
            let node = SKNode()
            node.position = CGPoint(x: x, y: y)
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = hollow ? color.withAlphaComponent(0.22) : color.withAlphaComponent(0.88)
            dot.strokeColor = color.withAlphaComponent(0.82)
            dot.lineWidth = 0.8
            node.addChild(dot)

            let label = menuLabel(text, fontSize: 8.5, color: GameUI.mutedInk, bold: true)
            label.position = CGPoint(x: 8, y: 0)
            node.addChild(label)
            return node
        }

        let regions = RegionDiscoverySystem.menuRegions
        let rowCardHeight: CGFloat = 92
        let rowSpacing: CGFloat = 9
        let rowStep = rowCardHeight + rowSpacing
        let mapPreviewHeight: CGFloat = size.height < 520 ? 124 : min(190, size.height * 0.28)
        let titleHeight: CGFloat = 24
        let currentCardHeight: CGFloat = 64
        let legendHeight: CGFloat = 24
        let headerHeight: CGFloat = 20 + titleHeight + 10 + currentCardHeight + 12 + mapPreviewHeight + legendHeight + 10
        let footerHeight: CGFloat = 64
        let panelWidth = min(size.width - 24, size.width >= 700 ? 500 : 392)
        let desiredPanelHeight = CGFloat(regions.count) * rowStep + headerHeight + footerHeight
        let maxPanelHeight = max(300, size.height - 42)
        let minPanelHeight = min(maxPanelHeight, 360)
        let panelHeight = min(maxPanelHeight, max(minPanelHeight, desiredPanelHeight))

        let content = SKNode()
        content.position = .zero
        addChild(content)

        let panel = GameUI.card(size: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 22,
                                tint: GameUI.accent.withAlphaComponent(0.62),
                                baseColors: [UIColor.lerp(GameUI.palePaper, GameUI.accent, 0.06)])
        content.addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 5
        panel.addChild(panelContent)

        let listWidth = panelWidth - 28
        let titleY = panelHeight / 2 - 20 - titleHeight / 2
        let currentMapName = currentRegionId
            .flatMap { RegionDiscoverySystem.region(withId: $0)?.name }
            ?? "Mapa desconhecido"
        let title = menuLabel("Expedição",
                              fontSize: 18,
                              color: GameUI.ink,
                              bold: true)
        title.position = CGPoint(x: -listWidth / 2 + 4, y: titleY)
        panelContent.addChild(title)

        let titleBadge = stateBadge(text: "REGISTRO", color: GameUI.accent, width: 84)
        titleBadge.position = CGPoint(x: listWidth / 2 - 42, y: titleY)
        panelContent.addChild(titleBadge)

        let currentCardY = titleY - titleHeight / 2 - 10 - currentCardHeight / 2
        let currentCard = SKShapeNode(rectOf: CGSize(width: listWidth, height: currentCardHeight),
                                      cornerRadius: 18)
        currentCard.position = CGPoint(x: 0, y: currentCardY)
        currentCard.fillColor = UIColor(red: 0.02, green: 0.10, blue: 0.14, alpha: 0.94)
        currentCard.strokeColor = GameUI.gold.withAlphaComponent(0.50)
        currentCard.lineWidth = 1.1
        panelContent.addChild(currentCard)

        let currentEyebrow = menuLabel("MAPA ATUAL",
                                       fontSize: 8,
                                       color: GameUI.gold,
                                       bold: true)
        currentEyebrow.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY + 19)
        panelContent.addChild(currentEyebrow)

        let currentName = menuLabel(currentMapName,
                                    fontSize: 17,
                                    color: GameUI.palePaper,
                                    bold: true,
                                    maxWidth: listWidth - 126)
        currentName.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY + 1)
        panelContent.addChild(currentName)

        let openCount = regions.filter { stats.isRegionKnown($0) && $0.isAccessible(for: stats.phase) }.count
        let currentMeta = menuLabel("\(stats.phase.displayName) · \(openCount)/\(regions.count) mapas abertos",
                                    fontSize: 10,
                                    color: GameUI.palePaper.withAlphaComponent(0.76),
                                    bold: false)
        currentMeta.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY - 20)
        panelContent.addChild(currentMeta)

        let currentBadge = stateBadge(text: "ATUAL", color: GameUI.gold, width: 66)
        currentBadge.position = CGPoint(x: listWidth / 2 - 45, y: currentCardY + 8)
        panelContent.addChild(currentBadge)

        if let destinationId,
           let destination = RegionDiscoverySystem.region(withId: destinationId),
           destination.id != currentRegionId {
            let route = menuLabel("Rumo a \(destination.name)",
                                  fontSize: 9.5,
                                  color: GameUI.gold,
                                  bold: true,
                                  maxWidth: 108)
            route.horizontalAlignmentMode = .right
            route.position = CGPoint(x: listWidth / 2 - 16, y: currentCardY - 20)
            panelContent.addChild(route)
        }

        if let previewId = currentRegionId ?? destinationId,
           let previewRegion = RegionDiscoverySystem.region(withId: previewId) {
            let map = ExpeditionMapNode(size: CGSize(width: listWidth, height: mapPreviewHeight),
                                        stats: stats,
                                        region: previewRegion,
                                        currentPosition: currentPosition)
            map.position = CGPoint(x: 0, y: currentCardY - currentCardHeight / 2 - 12 - mapPreviewHeight / 2)
            map.zPosition = 4
            panelContent.addChild(map)

            for poi in WorldPOICatalog.pois(in: previewRegion, stats: stats) where stats.isPOIDiscovered(poi.key) {
                rowPOIs[poi.key] = poi
            }
        }

        let legendY = currentCardY - currentCardHeight / 2 - 12 - mapPreviewHeight - legendHeight / 2 - 4
        let legend = SKShapeNode(rectOf: CGSize(width: listWidth, height: legendHeight), cornerRadius: 12)
        legend.fillColor = GameUI.palePaper.withAlphaComponent(0.74)
        legend.strokeColor = GameUI.line.withAlphaComponent(0.16)
        legend.lineWidth = 0.7
        legend.position = CGPoint(x: 0, y: legendY)
        panelContent.addChild(legend)

        panelContent.addChild(legendItem(text: "você",
                                         color: GameUI.gold,
                                         x: -listWidth / 2 + 22,
                                         y: legendY))
        panelContent.addChild(legendItem(text: "POI",
                                         color: GameUI.accent,
                                         x: -listWidth / 2 + 90,
                                         y: legendY))
        panelContent.addChild(legendItem(text: "silhueta",
                                         color: GameUI.mutedInk,
                                         x: -listWidth / 2 + 150,
                                         y: legendY,
                                         hollow: true))

        let routeHeading = menuLabel("Rotas",
                                     fontSize: 11,
                                     color: GameUI.mutedInk,
                                     bold: true)
        routeHeading.position = CGPoint(x: -listWidth / 2 + 4, y: legendY - legendHeight / 2 - 12)
        panelContent.addChild(routeHeading)

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
            let phaseLocked = !region.isAccessible(for: stats.phase)
            let isKnown = stats.isRegionKnown(region)
            let hasLead = stats.hasDiscoveryLead(for: region)
            let isLocked = phaseLocked || (!isKnown && !hasLead)
            let isCurrent = region.id == currentRegionId
            let isDestination = region.id == destinationId
            let isReadyDiscovery = stats.readyRegionDiscoveryId == region.id
            let isFollowingLead = stats.discoveryRouteRegionId == region.id
            let isPendingLead = stats.pendingRegionDiscoveryId == region.id

            let rowTint: UIColor
            let badgeText: String
            let badgeColor: UIColor
            let actionText: String
            if phaseLocked {
                rowTint = UIColor(white: 0.40, alpha: 1)
                badgeText = "BLOQUEADO"
                badgeColor = GameUI.mutedInk
                actionText = "fase \(region.minPhase.mapAccessDisplayName)"
            } else if isCurrent {
                rowTint = GameUI.gold
                badgeText = "ATUAL"
                badgeColor = GameUI.gold
                actionText = "você está aqui"
            } else if isDestination {
                rowTint = UIColor(red: 0.44, green: 0.78, blue: 1, alpha: 1)
                badgeText = "EM ROTA"
                badgeColor = GameUI.accent
                actionText = "viagem em andamento"
            } else if isReadyDiscovery {
                rowTint = GameUI.gold
                badgeText = "PRONTO"
                badgeColor = GameUI.gold
                actionText = "toque para abrir"
            } else if isFollowingLead {
                rowTint = GameUI.gold
                badgeText = "SEGUINDO"
                badgeColor = GameUI.gold
                actionText = "siga até a borda"
            } else if isPendingLead {
                rowTint = GameUI.gold
                badgeText = "PISTA"
                badgeColor = GameUI.gold
                actionText = "toque para seguir"
            } else if isLocked {
                rowTint = UIColor(white: 0.38, alpha: 1)
                badgeText = "SEM PISTA"
                badgeColor = GameUI.mutedInk
                actionText = "falta pista"
            } else {
                rowTint = region.tint
                badgeText = "ABERTO"
                badgeColor = region.tint
                actionText = "toque para viajar"
            }

            let row = GameUI.card(size: CGSize(width: listWidth, height: rowCardHeight),
                                  cornerRadius: 14,
                                  tint: rowTint.withAlphaComponent(isCurrent ? 0.9 : 0.6),
                                  baseColors: isLocked
                                    ? [UIColor.lerp(GameUI.fadedPaper, UIColor(white: 0.35, alpha: 1), 0.12)]
                                    : GameUI.tintedColors(isCurrent ? GameUI.gold : region.tint))
            row.position = CGPoint(x: 0, y: y)
            row.name = "region_\(region.id)"
            listNode.addChild(row)
            if !isLocked {
                rowRegions[region.id] = region
            }

            let rowContent = SKNode()
            rowContent.zPosition = 5
            row.addChild(rowContent)
            let leftX = -listWidth / 2 + 58

            let stripe = SKShapeNode(rectOf: CGSize(width: 5, height: rowCardHeight - 18), cornerRadius: 2.5)
            stripe.position = CGPoint(x: -listWidth / 2 + 8, y: 0)
            stripe.fillColor = rowTint.withAlphaComponent(isLocked ? 0.34 : 0.86)
            stripe.strokeColor = .clear
            rowContent.addChild(stripe)

            let emblem = SKShapeNode(circleOfRadius: 18)
            emblem.position = CGPoint(x: -listWidth / 2 + 32, y: 12)
            emblem.fillColor = isLocked
                ? GameUI.fadedPaper.withAlphaComponent(0.62)
                : UIColor.lerp(GameUI.palePaper, rowTint, 0.20)
            emblem.strokeColor = rowTint.withAlphaComponent(isLocked ? 0.28 : 0.68)
            emblem.lineWidth = 1
            rowContent.addChild(emblem)

            let icon = SKLabelNode(text: isLocked ? "?" : (region.tideIcons.first ?? "○"))
            icon.fontName = "AvenirNext-DemiBold"
            icon.fontSize = 16
            icon.fontColor = isLocked ? GameUI.mutedInk.withAlphaComponent(0.58) : UIColor.lerp(GameUI.ink, rowTint, 0.28)
            icon.horizontalAlignmentMode = .center
            icon.verticalAlignmentMode = .center
            icon.position = emblem.position
            rowContent.addChild(icon)

            let name = SKLabelNode(text: region.name)
            name.fontName = "AvenirNext-DemiBold"
            name.fontSize = isCurrent ? 15.5 : 14.5
            name.fontColor = isLocked ? GameUI.mutedInk : GameUI.ink
            name.horizontalAlignmentMode = .left
            name.verticalAlignmentMode = .center
            name.preferredMaxLayoutWidth = max(130, listWidth - 166)
            name.numberOfLines = 1
            name.position = CGPoint(x: leftX, y: 24)
            rowContent.addChild(name)

            let blurb = SKLabelNode(text: region.blurb)
            blurb.fontName = "AvenirNext-Regular"
            blurb.fontSize = 10
            blurb.fontColor = isLocked ? GameUI.mutedInk.withAlphaComponent(0.72) : GameUI.mutedInk
            blurb.horizontalAlignmentMode = .left
            blurb.verticalAlignmentMode = .center
            blurb.preferredMaxLayoutWidth = max(130, listWidth - 166)
            blurb.numberOfLines = 2
            blurb.position = CGPoint(x: leftX, y: 3)
            rowContent.addChild(blurb)

            let progress = Int((stats.regionProgress[region.id] ?? 0) * 100)
            let status = menuLabel("\(actionText) · \(progress)%",
                                   fontSize: 10.5,
                                   color: isLocked ? GameUI.mutedInk.withAlphaComponent(0.78) : (hasLead || isDestination || isCurrent ? GameUI.gold : GameUI.accent),
                                   bold: true,
                                   maxWidth: max(130, listWidth - 166))
            status.position = CGPoint(x: leftX, y: -22)
            rowContent.addChild(status)

            let barWidth = max(72, min(150, listWidth - 190))
            let bar = progressBar(width: barWidth,
                                  progress: CGFloat(progress) / 100,
                                  color: rowTint)
            bar.position = CGPoint(x: leftX + barWidth / 2, y: -36)
            rowContent.addChild(bar)

            let badge = stateBadge(text: badgeText,
                                   color: badgeColor,
                                   width: badgeText.count > 7 ? 86 : 70)
            badge.position = CGPoint(x: listWidth / 2 - (badgeText.count > 7 ? 52 : 44), y: 22)
            rowContent.addChild(badge)

            let phase = menuLabel(region.minPhase.displayName,
                                  fontSize: 8.5,
                                  color: isLocked ? GameUI.mutedInk.withAlphaComponent(0.64) : GameUI.mutedInk,
                                  bold: true)
            phase.horizontalAlignmentMode = .right
            phase.position = CGPoint(x: listWidth / 2 - 18, y: -16)
            rowContent.addChild(phase)
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
        close.zPosition = 20
        closeButtonRect = CGRect(x: content.position.x + close.position.x - 110,
                                 y: close.position.y - 24,
                                 width: 220,
                                 height: 48)
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if closeButtonRect.contains(location) {
            GameAudio.shared.play(.uiClosePanel)
            onClose()
            return
        }

        guard !didScrollDuringTouch else { return }

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
