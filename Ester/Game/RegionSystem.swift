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
        xRange
    }

    func contains(_ point: CGPoint) -> Bool {
        playableXRange.contains(point.x) && yRange.contains(point.y)
    }

    func isAccessible(for phase: MermaidPhase) -> Bool {
        phase >= minPhase
    }
}

extension Region {
    var ecosystemProfile: EcosystemBiomeProfile {
        EcosystemBiomeCatalog.profile(for: id)
    }
}

enum AquaticAnimalGroup: String {
    case fish
    case shark
    case ray
    case mammal
    case reptile
    case crustacean
    case mollusk
    case cephalopod
    case cnidarian
    case echinoderm
    case annelid
    case bird
    case arthropod
}

struct AquaticSpecies {
    let id: String
    let commonName: String
    let scientificName: String
    let group: AquaticAnimalGroup
    let preferredZones: [DepthZone]
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
        "recife_tropical|shallow": "Recife Tropical: corais rasos abrigam cardumes pequenos e curiosos.",
        "recife_tropical|mid": "Recife Tropical: a parede do recife desce em cores vivas.",
        "floresta_kelp|shallow": "Floresta de Kelp: lâminas altas balançam como uma mata submersa.",
        "floresta_kelp|mid": "Floresta de Kelp: sombras verdes guardam lontras, peixes e ouriços."
    ]
}

// MARK: - Descoberta de regiões

final class RegionDiscoverySystem {
    unowned let ctx: GameContext
    private var progressTimer: CGFloat = 0
    private var mapRevealTimer: CGFloat = 0
    private var leadTimer: CGFloat = 0

    private static let catalogOrder = [
        "recife_tropical",
        "floresta_kelp",
        "manguezal",
        "estuario",
        "mar_aberto_tropical",
        "mar_aberto_temperado",
        "rio_amazonico",
        "oceano_profundo",
        "zona_abissal",
        "regiao_polar"
    ]

    private static let legacyRegionIds: [String: String] = [
        "nascente": "recife_tropical",
        "jardim_calmo": "floresta_kelp",
        "recife": "manguezal",
        "delta": "estuario",
        "mar_azul_aberto": "mar_aberto_tropical",
        "cavernas": "mar_aberto_temperado",
        "campos_cristal": "rio_amazonico",
        "ruinas": "oceano_profundo",
        "abismo_vivo": "zona_abissal",
        "superficie_distante": "regiao_polar"
    ]

    static let all: [Region] = [
        Region(id: "zona_abissal",
               name: "Zona Abissal",
               xRange: -50000 ... -41000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .abyss,
               tint: UIColor(red: 0.08, green: 0.06, blue: 0.18, alpha: 1),
               tintStrength: 0.38,
               minPhase: .adult,
               blurb: "Planícies profundas, fontes hidrotermais e fauna adaptada à pressão extrema.",
               tideTitle: "Pressão Abissal",
               tideIcons: ["✧", "◇", "◌", "◆", "✦"]),
        Region(id: "mar_aberto_temperado",
               name: "Mar Aberto Temperado",
               xRange: -40000 ... -31000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .blue,
               tint: UIColor(red: 0.16, green: 0.34, blue: 0.50, alpha: 1),
               tintStrength: 0.28,
               minPhase: .teen,
               blurb: "Águas produtivas, correntes frias e grandes migradores pelágicos.",
               tideTitle: "Correntes Temperadas",
               tideIcons: ["⌁", "▧", "◇", "◌", "≋"]),
        Region(id: "estuario",
               name: "Estuário",
               xRange: -30000 ... -21000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.40, green: 0.50, blue: 0.36, alpha: 1),
               tintStrength: 0.3,
               minPhase: .child,
               blurb: "Mistura de rio e mar, berçário salobro para peixes, crustáceos e moluscos.",
               tideTitle: "Marés Salobras",
               tideIcons: ["⌁", "≋", "◡", "▧", "◌"]),
        Region(id: "oceano_profundo",
               name: "Oceano Profundo",
               xRange: -20000 ... -11000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .deep,
               tint: UIColor(red: 0.12, green: 0.18, blue: 0.36, alpha: 1),
               tintStrength: 0.34,
               minPhase: .young,
               blurb: "Zona mesopelágica e batial com bioluminescência, lulas e predadores de mergulho.",
               tideTitle: "Luzes Profundas",
               tideIcons: ["▧", "◇", "✦", "◌", "◆"]),
        Region(id: "recife_tropical",
               name: "Recife Tropical",
               xRange: -10000 ... 0,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.25, green: 0.74, blue: 0.78, alpha: 1),
               tintStrength: 0.18,
               minPhase: .baby,
               blurb: "Corais tropicais rasos, peixes coloridos, tartarugas e invertebrados recifais.",
               tideTitle: "Corais Tropicais",
               tideIcons: ["○", "✦", "◡", "◌", "✧"]),
        Region(id: "floresta_kelp",
               name: "Floresta de Kelp",
               xRange: 1000 ... 10000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.28, green: 0.58, blue: 0.44, alpha: 1),
               tintStrength: 0.24,
               minPhase: .baby,
               blurb: "Matas de algas gigantes em águas frias e ricas, com lontras, ouriços e peixes costeiros.",
               tideTitle: "Folhas de Kelp",
               tideIcons: ["◡", "✿", "◌", "○", "⌁"]),
        Region(id: "manguezal",
               name: "Manguezal",
               xRange: 11000 ... 20000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .shallow,
               tint: UIColor(red: 0.26, green: 0.54, blue: 0.34, alpha: 1),
               tintStrength: 0.3,
               minPhase: .child,
               blurb: "Raízes alagadas, água salobra e berçários para peixes, siris, crocodilos e peixes-boi.",
               tideTitle: "Raízes do Mangue",
               tideIcons: ["◡", "⌁", "◇", "✿", "✦"]),
        Region(id: "regiao_polar",
               name: "Região Polar",
               xRange: 21000 ... 30000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .surface,
               tint: UIColor(red: 0.62, green: 0.78, blue: 0.92, alpha: 1),
               tintStrength: 0.28,
               minPhase: .adult,
               blurb: "Águas geladas, gelo marinho, krill e grandes predadores adaptados ao frio.",
               tideTitle: "Gelo Vivo",
               tideIcons: ["○", "✦", "◇", "◌", "✧"]),
        Region(id: "mar_aberto_tropical",
               name: "Mar Aberto Tropical",
               xRange: 31000 ... 40000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .blue,
               tint: UIColor(red: 0.12, green: 0.44, blue: 0.84, alpha: 1),
               tintStrength: 0.3,
               minPhase: .teen,
               blurb: "Pelágico quente com atuns, golfinhos, tubarões oceânicos e grandes migradores.",
               tideTitle: "Azul Tropical",
               tideIcons: ["≋", "○", "✦", "⌁", "◇"]),
        Region(id: "rio_amazonico",
               name: "Rio Amazônico",
               xRange: 41000 ... 50000,
               yRange: World.floorY ... World.surfaceTopY,
               entryZone: .mid,
               tint: UIColor(red: 0.42, green: 0.52, blue: 0.28, alpha: 1),
               tintStrength: 0.34,
               minPhase: .young,
               blurb: "Água doce tropical, várzeas e grandes espécies amazônicas.",
               tideTitle: "Várzea Amazônica",
               tideIcons: ["◇", "✧", "◆", "◌", "✦"])
    ]

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    static func canonicalRegionId(_ id: String) -> String {
        legacyRegionIds[id] ?? id
    }

    static func region(withId id: String) -> Region? {
        let canonicalId = canonicalRegionId(id)
        return all.first { $0.id == canonicalId }
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
        restoreCollectedRegionMapLeadIfNeeded(in: region)

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
            let revealedArea = ctx.stats.expeditionAreaProgress(in: region)
            ctx.stats.regionProgress[region.id] = max(current, revealedArea)
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
        if let warmCurrentTint = ctx.pois?.warmCurrentTint(at: point) {
            return (warmCurrentTint.color,
                    max(region.tintStrength, warmCurrentTint.strength))
        }
        return (region.tint, region.tintStrength)
    }

    /// Paleta de peixes característica da região (nil = paleta da camada).
    static func fishPalette(for regionId: String) -> [UIColor]? {
        switch canonicalRegionId(regionId) {
        case "recife_tropical":
            return [UIColor(red: 0.95, green: 0.5, blue: 0.25, alpha: 1),
                    UIColor(red: 0.7, green: 0.4, blue: 0.85, alpha: 1),
                    UIColor(red: 0.3, green: 0.85, blue: 0.7, alpha: 1),
                    UIColor(red: 0.95, green: 0.75, blue: 0.3, alpha: 1)]
        case "floresta_kelp":
            return [UIColor(red: 0.22, green: 0.62, blue: 0.42, alpha: 1),
                    UIColor(red: 0.54, green: 0.68, blue: 0.38, alpha: 1),
                    UIColor(red: 0.36, green: 0.54, blue: 0.62, alpha: 1)]
        case "manguezal":
            return [UIColor(red: 0.40, green: 0.52, blue: 0.28, alpha: 1),
                    UIColor(red: 0.62, green: 0.52, blue: 0.34, alpha: 1),
                    UIColor(red: 0.32, green: 0.58, blue: 0.48, alpha: 1)]
        case "estuario":
            return [UIColor(red: 0.56, green: 0.58, blue: 0.42, alpha: 1),
                    UIColor(red: 0.64, green: 0.68, blue: 0.52, alpha: 1),
                    UIColor(red: 0.40, green: 0.58, blue: 0.64, alpha: 1)]
        case "mar_aberto_tropical":
            return [UIColor(red: 0.16, green: 0.52, blue: 0.92, alpha: 1),
                    UIColor(red: 0.42, green: 0.72, blue: 0.98, alpha: 1),
                    UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1)]
        case "mar_aberto_temperado":
            return [UIColor(red: 0.20, green: 0.42, blue: 0.62, alpha: 1),
                    UIColor(red: 0.52, green: 0.66, blue: 0.74, alpha: 1),
                    UIColor(red: 0.74, green: 0.82, blue: 0.86, alpha: 1)]
        case "rio_amazonico":
            return [UIColor(red: 0.44, green: 0.48, blue: 0.22, alpha: 1),
                    UIColor(red: 0.68, green: 0.48, blue: 0.24, alpha: 1),
                    UIColor(red: 0.24, green: 0.40, blue: 0.28, alpha: 1)]
        case "oceano_profundo":
            return [UIColor(red: 0.18, green: 0.34, blue: 0.58, alpha: 1),
                    UIColor(red: 0.26, green: 0.62, blue: 0.72, alpha: 1),
                    UIColor(red: 0.58, green: 0.46, blue: 0.82, alpha: 1)]
        case "zona_abissal":
            return [UIColor(red: 0.42, green: 0.18, blue: 0.70, alpha: 1),
                    UIColor(red: 0.16, green: 0.76, blue: 0.86, alpha: 1),
                    UIColor(red: 0.88, green: 0.32, blue: 0.68, alpha: 1)]
        case "regiao_polar":
            return [UIColor(red: 0.78, green: 0.92, blue: 1.0, alpha: 1),
                    UIColor(red: 0.58, green: 0.74, blue: 0.92, alpha: 1),
                    UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1)]
        default:
            return nil
        }
    }

    /// Comidas extras típicas da região.
    static func extraFood(for regionId: String) -> [FoodKind] {
        switch canonicalRegionId(regionId) {
        case "recife_tropical":
            return [
                FoodKind(name: "plâncton recifal", weight: 4, nutrition: 12, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.72, green: 0.9, blue: 1.0, alpha: 1)),
                FoodKind(name: "alga calcária solta", weight: 3, nutrition: 15, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.90, green: 0.55, blue: 0.64, alpha: 1))
            ]
        case "floresta_kelp":
            return [
                FoodKind(name: "lâmina de kelp", weight: 4, nutrition: 16, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.34, green: 0.70, blue: 0.36, alpha: 1)),
                FoodKind(name: "ouriço quebrado", weight: 2, nutrition: 14, pearls: 1, courage: 0, style: .pearl, color: UIColor(red: 0.54, green: 0.42, blue: 0.72, alpha: 1))
            ]
        case "manguezal":
            return [
                FoodKind(name: "folha de mangue", weight: 4, nutrition: 13, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.36, green: 0.62, blue: 0.34, alpha: 1)),
                FoodKind(name: "propágulo caído", weight: 3, nutrition: 16, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.58, green: 0.46, blue: 0.24, alpha: 1))
            ]
        case "estuario":
            return [
                FoodKind(name: "detrito salobro", weight: 4, nutrition: 15, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.50, green: 0.56, blue: 0.34, alpha: 1)),
                FoodKind(name: "concha de ostra", weight: 2, nutrition: 0, pearls: 2, courage: 0, style: .pearl, color: UIColor(red: 0.78, green: 0.74, blue: 0.64, alpha: 1))
            ]
        case "mar_aberto_tropical":
            return [
                FoodKind(name: "plâncton de corrente quente", weight: 3, nutrition: 14, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.34, green: 0.68, blue: 1.0, alpha: 1)),
                FoodKind(name: "sargaço flutuante", weight: 3, nutrition: 17, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.42, green: 0.64, blue: 0.28, alpha: 1))
            ]
        case "mar_aberto_temperado":
            return [
                FoodKind(name: "plâncton frio", weight: 3, nutrition: 13, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.58, green: 0.78, blue: 0.92, alpha: 1)),
                FoodKind(name: "alga de deriva", weight: 3, nutrition: 16, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.26, green: 0.52, blue: 0.46, alpha: 1))
            ]
        case "rio_amazonico":
            return [
                FoodKind(name: "fruto de várzea", weight: 4, nutrition: 20, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.74, green: 0.42, blue: 0.24, alpha: 1)),
                FoodKind(name: "folha amazônica", weight: 3, nutrition: 14, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.36, green: 0.58, blue: 0.28, alpha: 1))
            ]
        case "oceano_profundo":
            return [
                FoodKind(name: "neve marinha", weight: 4, nutrition: 12, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.72, green: 0.84, blue: 1.0, alpha: 1)),
                FoodKind(name: "partícula bioluminescente", weight: 2, nutrition: 18, pearls: 1, courage: 0, style: .glow, color: UIColor(red: 0.42, green: 0.86, blue: 0.96, alpha: 1))
            ]
        case "zona_abissal":
            return [
                FoodKind(name: "detrito abissal", weight: 3, nutrition: 15, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.48, green: 0.92, blue: 1.0, alpha: 1)),
                FoodKind(name: "mineral de fonte hidrotermal", weight: 1, nutrition: 20, pearls: 2, courage: 0, style: .crystal, color: UIColor(red: 0.76, green: 0.32, blue: 0.92, alpha: 1))
            ]
        case "regiao_polar":
            return [
                FoodKind(name: "krill disperso", weight: 4, nutrition: 16, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.92, green: 0.58, blue: 0.62, alpha: 1)),
                FoodKind(name: "alga de gelo", weight: 3, nutrition: 13, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.82, green: 0.94, blue: 1.0, alpha: 1))
            ]
        default:
            return []
        }
    }

    static func species(for regionId: String) -> [AquaticSpecies] {
        let resolvedRegion = canonicalRegionId(regionId)
        let catalogSpecies = AquaticSpeciesCatalog.species(for: resolvedRegion)
        let profileSpecies = EcosystemBiomeCatalog.profile(for: resolvedRegion)
            .faunaAssociations
            .compactMap { id in
                catalogSpecies.first(where: { $0.id == id })
            }
        return profileSpecies.isEmpty ? catalogSpecies : profileSpecies
    }

    static func species(for regionId: String, zone: DepthZone) -> [AquaticSpecies] {
        let regional = species(for: regionId)
        let matching = regional.filter { $0.preferredZones.contains(zone) }
        return matching.isEmpty ? regional : matching
    }

    static func randomSpecies(for regionId: String, zone: DepthZone) -> AquaticSpecies? {
        species(for: regionId, zone: zone).randomElement()
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

        let point = discoveryRoutePoint(for: destination, from: current)
        ctx.stats.pendingRegionDiscoveryId = destination.id
        ctx.stats.revealExpeditionMap(in: current, near: point)
        ctx.stats.addMemory("Encontrou pista para \(destination.name)")
        GameAudio.shared.play(.regionDiscover)
        ctx.say("Um fragmento de corrente aponta para \(destination.name). Abra o mapa para seguir a pista.")
        return true
    }

    private func restoreCollectedRegionMapLeadIfNeeded(in current: Region) {
        guard ctx.stats.pendingRegionDiscoveryId == nil,
              ctx.stats.discoveryRouteRegionId == nil,
              ctx.stats.readyRegionDiscoveryId == nil else { return }

        for poi in WorldPOICatalog.pois(in: current, stats: ctx.stats) {
            guard ctx.stats.isPOIRewardCollected(poi.key),
                  poi.reward.kind == .regionMap,
                  let regionId = poi.reward.regionId,
                  let destination = RegionDiscoverySystem.region(withId: regionId),
                  destination.isAccessible(for: ctx.stats.phase),
                  !ctx.stats.isRegionKnown(destination),
                  !ctx.stats.hasDiscoveryLead(for: destination) else { continue }

            let point = discoveryRoutePoint(for: destination, from: current)
            ctx.stats.pendingRegionDiscoveryId = destination.id
            ctx.stats.discoveryPointByRegion[destination.id] = point
            ctx.stats.revealExpeditionMap(in: current, near: point)
            ctx.stats.addMemory("Mapa recuperado: passagem para \(destination.name)")
            ctx.showRegionMapCue(for: destination, unlocked: true)
            return
        }
    }

    @discardableResult
    func startDiscoveryRoute(to region: Region) -> Bool {
        guard let current = currentRegion,
              ctx.stats.pendingRegionDiscoveryId == region.id
                || ctx.stats.discoveryRouteRegionId == region.id else { return false }
        let point = discoveryRoutePoint(for: region, from: current)
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
        let gained = ctx.stats.awardPearls(4)
        ctx.stats.addMemory("Confirmou rota para \(region.name)")
        GameAudio.shared.play(.regionDiscover)
        ctx.say("Rota aberta: \(region.name). Conchas +\(GameUI.shellAmountText(gained))")
        return true
    }

    @discardableResult
    func unlockRegionMap(_ regionId: String, source: String) -> String {
        guard let region = RegionDiscoverySystem.region(withId: regionId) else {
            return "Mapa encontrado, mas a região ainda não existe."
        }
        guard let current = currentRegion else {
            return "Mapa encontrado, mas a região atual não foi localizada."
        }
        guard region.isAccessible(for: ctx.stats.phase) else {
            ctx.showRegionMapCue(for: region, unlocked: false)
            return "\(region.name) foi marcado, mas só ficará disponível quando ela for \(region.minPhase.mapAccessDisplayName)."
        }
        if ctx.stats.isRegionKnown(region) {
            return "Mapa já conhecido: \(region.name)."
        }
        if ctx.stats.hasDiscoveryLead(for: region) {
            let point = discoveryRoutePoint(for: region, from: current)
            ctx.stats.discoveryPointByRegion[region.id] = point
            ctx.stats.revealExpeditionMap(in: current, near: point)
            ctx.showRegionMapCue(for: region, unlocked: true)
            return "Mapa já marcou uma pista para \(region.name). Abra Expedição para seguir."
        }

        let point = discoveryRoutePoint(for: region, from: current)
        ctx.stats.pendingRegionDiscoveryId = region.id
        ctx.stats.discoveryRouteRegionId = nil
        ctx.stats.readyRegionDiscoveryId = nil
        ctx.stats.discoveryPointByRegion[region.id] = point
        ctx.stats.revealExpeditionMap(in: current, near: point)
        ctx.stats.addMemory("\(source): recebeu mapa para \(region.name)")
        GameAudio.shared.play(.regionDiscover)
        ctx.showRegionMapCue(for: region, unlocked: true)
        return "Mapa recebido: passagem para \(region.name) marcada em Expedição."
    }

    private func nextDiscoverableRegion() -> Region? {
        RegionDiscoverySystem.menuRegions
            .filter { region in
                region.isAccessible(for: ctx.stats.phase)
                    && !ctx.stats.isRegionKnown(region)
                    && !ctx.stats.hasDiscoveryLead(for: region)
                    && region.id != "floresta_kelp"
            }
            .first
    }

    private func updateDiscoveryRoute(in current: Region) {
        guard let id = ctx.stats.discoveryRouteRegionId,
              let destination = RegionDiscoverySystem.region(withId: id) else { return }
        let point = discoveryRoutePoint(for: destination, from: current)
        ctx.stats.revealExpeditionMap(in: current, near: point)
        guard ctx.mermaidPosition.distance(to: point) < 180 else { return }
        ctx.stats.discoveryRouteRegionId = nil
        ctx.stats.readyRegionDiscoveryId = id
        ctx.scene?.showRegionDiscoveryCue(for: destination)
        ctx.say("A água mudou de cor. \(destination.name) está logo além; confirme no mapa.")
    }

    private func discoveryRoutePoint(for destination: Region, from current: Region) -> CGPoint {
        let rawPoint = ctx.stats.discoveryPoint(for: destination, from: current)
        return CGPoint(x: rawPoint.x.clamped(to: current.playableXRange),
                       y: rawPoint.y.clamped(to: DepthSystem.allowedYRange(for: ctx.stats)))
    }
}

enum AquaticSpeciesCatalog {
    private static func s(_ id: String,
                          _ commonName: String,
                          _ scientificName: String,
                          _ group: AquaticAnimalGroup,
                          _ zones: [DepthZone]) -> AquaticSpecies {
        AquaticSpecies(id: id,
                       commonName: commonName,
                       scientificName: scientificName,
                       group: group,
                       preferredZones: zones)
    }

    static func species(for regionId: String) -> [AquaticSpecies] {
        speciesByRegion[regionId] ?? []
    }

    private static let speciesByRegion: [String: [AquaticSpecies]] = [
        "recife_tropical": [
            s("peixe_palhaco_comum", "Peixe-palhaço-comum", "Amphiprion ocellaris", .fish, [.clear, .shallow]),
            s("peixe_cirurgiao_azul", "Peixe-cirurgião-azul", "Paracanthurus hepatus", .fish, [.shallow]),
            s("peixe_papagaio_arco_iris", "Peixe-papagaio-arco-íris", "Scarus guacamaia", .fish, [.shallow, .mid]),
            s("peixe_borboleta_lavrado", "Peixe-borboleta-lavrado", "Chaetodon capistratus", .fish, [.clear, .shallow]),
            s("peixe_anjo_rainha", "Peixe-anjo-rainha", "Holacanthus ciliaris", .fish, [.shallow]),
            s("mero_de_nassau", "Mero-de-Nassau", "Epinephelus striatus", .fish, [.mid]),
            s("barracuda_grande", "Barracuda-grande", "Sphyraena barracuda", .fish, [.mid, .blue]),
            s("tubarao_recife_caribenho", "Tubarão-de-recife-caribenho", "Carcharhinus perezi", .shark, [.mid, .blue]),
            s("arraia_chita", "Arraia-chita", "Aetobatus narinari", .ray, [.shallow, .mid]),
            s("tartaruga_verde", "Tartaruga-verde", "Chelonia mydas", .reptile, [.surface, .clear, .shallow]),
            s("tartaruga_de_pente", "Tartaruga-de-pente", "Eretmochelys imbricata", .reptile, [.clear, .shallow]),
            s("lagosta_espinhosa_caribenha", "Lagosta-espinhosa-caribenha", "Panulirus argus", .crustacean, [.shallow, .mid]),
            s("polvo_do_recife_caribenho", "Polvo-do-recife-caribenho", "Octopus briareus", .cephalopod, [.shallow, .mid]),
            s("lula_recifal_caribenha", "Lula-recifal-caribenha", "Sepioteuthis sepioidea", .cephalopod, [.clear, .shallow]),
            s("estrela_do_mar_azul", "Estrela-do-mar-azul", "Linckia laevigata", .echinoderm, [.shallow])
        ],
        "floresta_kelp": [
            s("lontra_marinha", "Lontra-marinha", "Enhydra lutris", .mammal, [.surface, .clear, .shallow]),
            s("foca_comum", "Foca-comum", "Phoca vitulina", .mammal, [.surface, .clear]),
            s("leao_marinho_california", "Leão-marinho-da-Califórnia", "Zalophus californianus", .mammal, [.surface, .clear, .shallow]),
            s("garibaldi", "Garibaldi", "Hypsypops rubicundus", .fish, [.shallow]),
            s("badejo_de_kelp", "Badejo-de-kelp", "Paralabrax clathratus", .fish, [.shallow, .mid]),
            s("peixe_cabecao_california", "Peixe-cabeção-da-Califórnia", "Semicossyphus pulcher", .fish, [.shallow, .mid]),
            s("robalo_gigante", "Robalo-gigante", "Stereolepis gigas", .fish, [.mid, .blue]),
            s("rockfish_azul", "Rockfish-azul", "Sebastes mystinus", .fish, [.mid, .deep]),
            s("cabezon", "Cabezon", "Scorpaenichthys marmoratus", .fish, [.shallow, .mid]),
            s("tubarao_leopardo", "Tubarão-leopardo", "Triakis semifasciata", .shark, [.shallow]),
            s("arraia_morcego", "Arraia-morcego", "Myliobatis californica", .ray, [.shallow, .mid]),
            s("polvo_gigante_pacifico", "Polvo-gigante-do-Pacífico", "Enteroctopus dofleini", .cephalopod, [.mid, .deep]),
            s("caranguejo_de_kelp", "Caranguejo-de-kelp", "Pugettia producta", .crustacean, [.shallow]),
            s("ourico_roxo_do_mar", "Ouriço-roxo-do-mar", "Strongylocentrotus purpuratus", .echinoderm, [.shallow]),
            s("abalone_vermelho", "Abalone-vermelho", "Haliotis rufescens", .mollusk, [.shallow])
        ],
        "manguezal": [
            s("peixe_arqueiro", "Peixe-arqueiro", "Toxotes jaculatrix", .fish, [.clear, .shallow]),
            s("saltador_do_lodo", "Saltador-do-lodo", "Periophthalmus barbarus", .fish, [.surface, .shallow]),
            s("robalo_flecha", "Robalo-flecha", "Centropomus undecimalis", .fish, [.shallow, .mid]),
            s("tarpon", "Tarpon", "Megalops atlanticus", .fish, [.surface, .shallow]),
            s("tainha", "Tainha", "Mugil cephalus", .fish, [.shallow]),
            s("peixe_serra_dentes_pequenos", "Peixe-serra-de-dentes-pequenos", "Pristis pectinata", .ray, [.shallow, .mid]),
            s("tubarao_limao", "Tubarão-limão", "Negaprion brevirostris", .shark, [.shallow, .mid]),
            s("crocodilo_americano", "Crocodilo-americano", "Crocodylus acutus", .reptile, [.surface, .shallow]),
            s("peixe_boi_marinho", "Peixe-boi-marinho", "Trichechus manatus", .mammal, [.surface, .shallow]),
            s("caranguejo_uca", "Caranguejo-uçá", "Ucides cordatus", .crustacean, [.surface, .shallow]),
            s("caranguejo_violinista", "Caranguejo-violinista", "Minuca rapax", .crustacean, [.surface, .shallow]),
            s("camarao_branco", "Camarão-branco", "Litopenaeus schmitti", .crustacean, [.shallow]),
            s("ostra_do_mangue", "Ostra-do-mangue", "Crassostrea rhizophorae", .mollusk, [.shallow]),
            s("siri_azul", "Siri-azul", "Callinectes sapidus", .crustacean, [.shallow, .mid]),
            s("cavalo_marinho_focinho_longo", "Cavalo-marinho-de-focinho-longo", "Hippocampus reidi", .fish, [.shallow])
        ],
        "estuario": [
            s("salmao_atlantico", "Salmão-atlântico", "Salmo salar", .fish, [.clear, .mid]),
            s("truta_arco_iris", "Truta-arco-íris", "Oncorhynchus mykiss", .fish, [.clear, .shallow]),
            s("esturjao_atlantico", "Esturjão-atlântico", "Acipenser oxyrinchus", .fish, [.mid, .deep]),
            s("robalo_listrado", "Robalo-listrado", "Morone saxatilis", .fish, [.shallow, .mid]),
            s("anchova_do_atlantico", "Anchova-do-Atlântico", "Anchoa hepsetus", .fish, [.clear, .shallow]),
            s("tainha_estuarina", "Tainha", "Mugil cephalus", .fish, [.shallow]),
            s("linguado_de_inverno", "Linguado-de-inverno", "Pseudopleuronectes americanus", .fish, [.shallow, .mid]),
            s("siri_azul_estuario", "Siri-azul", "Callinectes sapidus", .crustacean, [.shallow, .mid]),
            s("caranguejo_ferradura", "Caranguejo-ferradura", "Limulus polyphemus", .arthropod, [.shallow]),
            s("ostra_americana", "Ostra-americana", "Crassostrea virginica", .mollusk, [.shallow]),
            s("mexilhao_azul", "Mexilhão-azul", "Mytilus edulis", .mollusk, [.shallow]),
            s("camarao_marrom", "Camarão-marrom", "Farfantepenaeus aztecus", .crustacean, [.shallow]),
            s("foca_comum_estuario", "Foca-comum", "Phoca vitulina", .mammal, [.surface, .clear]),
            s("lontra_de_rio_norte_americana", "Lontra-de-rio-norte-americana", "Lontra canadensis", .mammal, [.surface, .shallow]),
            s("golfinho_nariz_de_garrafa_estuario", "Golfinho-nariz-de-garrafa", "Tursiops truncatus", .mammal, [.surface, .clear])
        ],
        "mar_aberto_tropical": [
            s("atum_albacora", "Atum-albacora", "Thunnus albacares", .fish, [.blue]),
            s("atum_bonito", "Atum-bonito", "Katsuwonus pelamis", .fish, [.surface, .blue]),
            s("dourado", "Dourado", "Coryphaena hippurus", .fish, [.surface, .blue]),
            s("agulhao_vela", "Agulhão-vela", "Istiophorus platypterus", .fish, [.surface, .blue]),
            s("marlim_azul", "Marlim-azul", "Makaira nigricans", .fish, [.blue]),
            s("peixe_voador", "Peixe-voador", "Cypselurus melanurus", .fish, [.surface, .clear]),
            s("peixe_lua", "Peixe-lua", "Mola mola", .fish, [.surface, .blue]),
            s("tubarao_baleia", "Tubarão-baleia", "Rhincodon typus", .shark, [.surface, .blue]),
            s("tubarao_galha_branca_oceanico", "Tubarão-galha-branca-oceânico", "Carcharhinus longimanus", .shark, [.blue]),
            s("tubarao_seda", "Tubarão-seda", "Carcharhinus falciformis", .shark, [.blue]),
            s("raia_manta_oceanica", "Raia-manta-oceânica", "Mobula birostris", .ray, [.surface, .blue]),
            s("golfinho_pintado_pantropical", "Golfinho-pintado-pantropical", "Stenella attenuata", .mammal, [.surface, .blue]),
            s("golfinho_nariz_de_garrafa_tropical", "Golfinho-nariz-de-garrafa", "Tursiops truncatus", .mammal, [.surface, .blue]),
            s("tartaruga_de_couro", "Tartaruga-de-couro", "Dermochelys coriacea", .reptile, [.surface, .blue]),
            s("caravela_portuguesa", "Caravela-portuguesa", "Physalia physalis", .cnidarian, [.surface])
        ],
        "mar_aberto_temperado": [
            s("atum_rabilho", "Atum-rabilho", "Thunnus thynnus", .fish, [.blue, .deep]),
            s("albacora_branca", "Albacora-branca", "Thunnus alalunga", .fish, [.blue]),
            s("cavala_do_atlantico", "Cavala-do-atlântico", "Scomber scombrus", .fish, [.clear, .blue]),
            s("sardinha_europeia", "Sardinha-europeia", "Sardina pilchardus", .fish, [.clear, .blue]),
            s("arenque_atlantico", "Arenque-atlântico", "Clupea harengus", .fish, [.clear, .blue]),
            s("bacalhau_atlantico", "Bacalhau-atlântico", "Gadus morhua", .fish, [.mid, .deep]),
            s("espadarte", "Espadarte", "Xiphias gladius", .fish, [.blue, .deep]),
            s("tubarao_azul", "Tubarão-azul", "Prionace glauca", .shark, [.blue]),
            s("tubarao_frade", "Tubarão-frade", "Cetorhinus maximus", .shark, [.surface, .blue]),
            s("orca_temperada", "Orca", "Orcinus orca", .mammal, [.surface, .blue]),
            s("baleia_jubarte_temperada", "Baleia-jubarte", "Megaptera novaeangliae", .mammal, [.surface, .blue]),
            s("golfinho_comum", "Golfinho-comum", "Delphinus delphis", .mammal, [.surface, .blue]),
            s("foca_cinzenta", "Foca-cinzenta", "Halichoerus grypus", .mammal, [.surface, .clear]),
            s("lula_comum", "Lula-comum", "Loligo vulgaris", .cephalopod, [.mid, .blue]),
            s("agua_viva_lua", "Água-viva-lua", "Aurelia aurita", .cnidarian, [.surface, .clear])
        ],
        "rio_amazonico": [
            s("boto_cor_de_rosa", "Boto-cor-de-rosa", "Inia geoffrensis", .mammal, [.surface, .mid]),
            s("tucuxi", "Tucuxi", "Sotalia fluviatilis", .mammal, [.surface, .mid]),
            s("peixe_boi_da_amazonia", "Peixe-boi-da-Amazônia", "Trichechus inunguis", .mammal, [.shallow, .mid]),
            s("pirarucu", "Pirarucu", "Arapaima gigas", .fish, [.surface, .shallow]),
            s("tambaqui", "Tambaqui", "Colossoma macropomum", .fish, [.shallow, .mid]),
            s("pacu", "Pacu", "Mylossoma duriventre", .fish, [.shallow]),
            s("piranha_vermelha", "Piranha-vermelha", "Pygocentrus nattereri", .fish, [.shallow, .mid]),
            s("candiru", "Candiru", "Vandellia cirrhosa", .fish, [.mid]),
            s("bagre_dourado", "Bagre-dourado", "Brachyplatystoma rousseauxii", .fish, [.mid, .deep]),
            s("jau", "Jaú", "Zungaro zungaro", .fish, [.mid, .deep]),
            s("arraia_de_rio", "Arraia-de-rio", "Potamotrygon motoro", .ray, [.shallow]),
            s("enguia_eletrica", "Enguia-elétrica", "Electrophorus electricus", .fish, [.shallow, .mid]),
            s("jacare_acu", "Jacaré-açu", "Melanosuchus niger", .reptile, [.surface, .shallow]),
            s("tartaruga_da_amazonia", "Tartaruga-da-Amazônia", "Podocnemis expansa", .reptile, [.surface, .shallow]),
            s("anaconda_verde", "Anaconda-verde", "Eunectes murinus", .reptile, [.surface, .shallow])
        ],
        "oceano_profundo": [
            s("cachalote", "Cachalote", "Physeter macrocephalus", .mammal, [.blue, .deep]),
            s("lula_gigante", "Lula-gigante", "Architeuthis dux", .cephalopod, [.deep]),
            s("peixe_lanterna", "Peixe-lanterna", "Myctophum punctatum", .fish, [.mid, .deep]),
            s("peixe_dragao_negro", "Peixe-dragão-negro", "Idiacanthus atlanticus", .fish, [.deep]),
            s("peixe_vibora", "Peixe-víbora", "Chauliodus sloani", .fish, [.deep]),
            s("peixe_machado_marinho", "Peixe-machado-marinho", "Sternoptyx diaphana", .fish, [.deep]),
            s("peixe_ogro", "Peixe-ogro", "Anoplogaster cornuta", .fish, [.deep]),
            s("enguia_gulper", "Enguia-gulper", "Eurypharynx pelecanoides", .fish, [.deep]),
            s("tubarao_duende", "Tubarão-duende", "Mitsukurina owstoni", .shark, [.deep]),
            s("tubarao_de_seis_guelras", "Tubarão-de-seis-guelras", "Hexanchus griseus", .shark, [.deep]),
            s("quimera_de_nariz_longo", "Quimera-de-nariz-longo", "Harriotta raleighana", .fish, [.deep]),
            s("polvo_dumbo", "Polvo-dumbo", "Grimpoteuthis bathynectes", .cephalopod, [.deep, .abyss]),
            s("camarao_de_vidro", "Camarão-de-vidro", "Pasiphaea pacifica", .crustacean, [.deep]),
            s("agua_viva_capacete", "Água-viva-capacete", "Periphylla periphylla", .cnidarian, [.deep]),
            s("sifonoforo_gigante", "Sifonóforo-gigante", "Praya dubia", .cnidarian, [.deep])
        ],
        "zona_abissal": [
            s("pepino_do_mar_abissal", "Pepino-do-mar-abissal", "Scotoplanes globosa", .echinoderm, [.abyss]),
            s("peixe_caracol_marianas", "Peixe-caracol-das-Marianas", "Pseudoliparis swirei", .fish, [.abyss]),
            s("peixe_tripe", "Peixe-tripé", "Bathypterois grallator", .fish, [.abyss]),
            s("granadeiro_abissal", "Granadeiro-abissal", "Coryphaenoides armatus", .fish, [.deep, .abyss]),
            s("cusk_eel_abissal", "Cusk-eel abissal", "Abyssobrotula galatheae", .fish, [.abyss]),
            s("cirroteuthis_abissal", "Polvo-cirroteuthis", "Cirroteuthis muelleri", .cephalopod, [.deep, .abyss]),
            s("lula_vampiro", "Lula-vampiro", "Vampyroteuthis infernalis", .cephalopod, [.deep, .abyss]),
            s("anfipode_gigante", "Anfípode-gigante", "Alicella gigantea", .crustacean, [.abyss]),
            s("isopode_gigante", "Isópode-gigante", "Bathynomus giganteus", .crustacean, [.deep, .abyss]),
            s("camarao_de_ventos", "Camarão-de-ventos", "Rimicaris exoculata", .crustacean, [.deep, .abyss]),
            s("caranguejo_yeti", "Caranguejo-yeti", "Kiwa hirsuta", .crustacean, [.deep, .abyss]),
            s("mexilhao_fonte_hidrotermal", "Mexilhão-de-fonte-hidrotermal", "Bathymodiolus thermophilus", .mollusk, [.deep, .abyss]),
            s("verme_tubicola_gigante", "Verme-tubícola-gigante", "Riftia pachyptila", .annelid, [.deep, .abyss]),
            s("agua_viva_atolla", "Água-viva-Atolla", "Atolla wyvillei", .cnidarian, [.deep, .abyss]),
            s("estrela_cesto", "Estrela-cesto", "Gorgonocephalus eucnemis", .echinoderm, [.deep, .abyss])
        ],
        "regiao_polar": [
            s("pinguim_imperador", "Pinguim-imperador", "Aptenodytes forsteri", .bird, [.surface, .clear]),
            s("pinguim_adelia", "Pinguim-de-Adélia", "Pygoscelis adeliae", .bird, [.surface, .clear]),
            s("foca_de_weddell", "Foca-de-Weddell", "Leptonychotes weddellii", .mammal, [.surface, .blue]),
            s("foca_leopardo", "Foca-leopardo", "Hydrurga leptonyx", .mammal, [.surface, .blue]),
            s("foca_caranguejeira", "Foca-caranguejeira", "Lobodon carcinophaga", .mammal, [.surface, .blue]),
            s("leao_marinho_antartico", "Leão-marinho-antártico", "Arctocephalus gazella", .mammal, [.surface, .blue]),
            s("baleia_azul_polar", "Baleia-azul", "Balaenoptera musculus", .mammal, [.surface, .blue]),
            s("baleia_minke_antartica", "Baleia-minke-antártica", "Balaenoptera bonaerensis", .mammal, [.surface, .blue]),
            s("orca_polar", "Orca", "Orcinus orca", .mammal, [.surface, .blue]),
            s("krill_antartico", "Krill-antártico", "Euphausia superba", .crustacean, [.clear, .mid]),
            s("peixe_gelo_antartico", "Peixe-gelo-antártico", "Chionodraco hamatus", .fish, [.mid, .deep]),
            s("nototenia_antartica", "Nototênia-antártica", "Dissostichus mawsoni", .fish, [.deep]),
            s("lula_colossal", "Lula-colossal", "Mesonychoteuthis hamiltoni", .cephalopod, [.deep]),
            s("estrela_do_mar_antartica", "Estrela-do-mar-antártica", "Odontaster validus", .echinoderm, [.shallow, .mid]),
            s("agua_viva_juba_de_leao", "Água-viva-juba-de-leão", "Cyanea capillata", .cnidarian, [.surface, .clear])
        ]
    ]
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
        let clamped = CGPoint(x: saved.x.clamped(to: destination.playableXRange),
                              y: saved.y.clamped(to: yRange))
        return clamped
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

enum WorldPOIVisualConcept: String, Codable, CaseIterable {
    case environment
    case object
    case npc

    var displayName: String {
        switch self {
        case .environment: return "Ambiente"
        case .object: return "Objeto"
        case .npc: return "NPC"
        }
    }
}

enum WorldPOIActionKind: String, Codable, CaseIterable {
    case temporaryEffect
    case challenge

    var displayName: String {
        switch self {
        case .temporaryEffect: return "Efeito temporário"
        case .challenge: return "Desafio"
        }
    }
}

struct POIChallenge: Codable {
    let kind: ChallengeKind
    let goal: Int?
    let goalMultiplier: CGFloat
    let special: Bool
    let introText: String

    init(kind: ChallengeKind,
         goal: Int? = nil,
         goalMultiplier: CGFloat = 1,
         special: Bool = true,
         introText: String = "") {
        self.kind = kind
        self.goal = goal
        self.goalMultiplier = max(0.1, goalMultiplier)
        self.special = special
        self.introText = introText
    }

    private enum CodingKeys: String, CodingKey {
        case kind, goal, goalMultiplier, special, introText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(ChallengeKind.self, forKey: .kind)
        goal = try c.decodeIfPresent(Int.self, forKey: .goal)
        goalMultiplier = max(0.1, try c.decodeIfPresent(CGFloat.self, forKey: .goalMultiplier) ?? 1)
        special = try c.decodeIfPresent(Bool.self, forKey: .special) ?? true
        introText = try c.decodeIfPresent(String.self, forKey: .introText) ?? ""
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
    let visualConcept: WorldPOIVisualConcept
    let actionKind: WorldPOIActionKind
    let name: String
    let position: CGPoint
    let reward: Reward
    let visual: POIVisual
    let challenge: POIChallenge?
}

enum WorldPOICatalog {
    static func pois(in region: Region, stats: MermaidStats) -> [WorldPOI] {
        DepthZone.accessOrder.flatMap { pois(in: region, zone: $0, stats: stats) }
    }

    static func pois(in region: Region, zone: DepthZone, stats: MermaidStats) -> [WorldPOI] {
        let definitions = configuredDefinitions.filter { $0.mapId == region.id && $0.zone == zone.storageKey }
        if !definitions.isEmpty {
            return definitions.enumerated().map { index, definition in
                let rawPosition = configuredPosition(for: definition,
                                                     index: index,
                                                     totalCount: definitions.count,
                                                     region: region,
                                                     zone: zone,
                                                     stats: stats)
                let position = boundedPosition(rawPosition, region: region, zone: zone)
                return WorldPOI(key: definition.poiId,
                                regionId: region.id,
                                zone: zone,
                                kind: definition.kind,
                                visualConcept: definition.visualConcept
                                    ?? visualConcept(for: definition.kind, key: definition.poiId),
                                actionKind: definition.actionKind ?? actionKind(for: definition.kind),
                                name: definition.name,
                                position: position,
                                reward: definition.reward,
                                visual: definition.visual ?? .default(for: definition.kind),
                                challenge: definition.challenge
                                    ?? challenge(for: definition.actionKind ?? actionKind(for: definition.kind),
                                                 kind: definition.kind))
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
            let rawPosition = CGPoint(x: rng.next(in: xRange),
                                      y: rng.next(in: yRange))
            let position = boundedPosition(rawPosition, region: region, zone: zone)
            let reward = reward(for: kind, region: region, zone: zone)
            return WorldPOI(key: key,
                            regionId: region.id,
                            zone: zone,
                            kind: kind,
                            visualConcept: visualConcept(for: kind, key: key),
                            actionKind: actionKind(for: kind),
                            name: name(for: kind, region: region, zone: zone),
                            position: position,
                            reward: reward,
                            visual: .default(for: kind),
                            challenge: challenge(for: actionKind(for: kind), kind: kind))
        }
    }

    private struct POIDefinition: Decodable {
        let poiId: String
        let mapId: String
        let zone: String
        let kind: WorldPOIKind
        let visualConcept: WorldPOIVisualConcept?
        let actionKind: WorldPOIActionKind?
        let name: String
        let reward: Reward
        let visual: POIVisual?
        let challenge: POIChallenge?
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

    private static func boundedPosition(_ position: CGPoint,
                                        region: Region,
                                        zone: DepthZone) -> CGPoint {
        let yPadding: CGFloat = zone == .surface ? 24 : 220
        let innerYMin = zone.yRange.lowerBound + yPadding
        let innerYMax = zone.yRange.upperBound - yPadding
        let yRange = innerYMin <= innerYMax ? innerYMin...innerYMax : zone.yRange
        return CGPoint(x: position.x.clamped(to: region.playableXRange),
                       y: position.y.clamped(to: yRange))
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
            return .pearls(120, title: "Baú de conchas")
        case .npc:
            return .temporaryEffect(.eagerCompanion, duration: GameBalance.gameplayEffectDuration)
        case .minigame:
            return .supportResource(.currentAmpoule, quantity: 3)
        case .pet:
            return Reward(kind: .temporaryEffect,
                          title: "peixinho companheiro",
                          pearlAmount: 0,
                          itemId: nil,
                          buffKind: .temporaryPet,
                          duration: GameBalance.visualEffectDuration,
                          storyText: nil)
        case .story:
            return .temporaryEffect(.eagerCompanion, duration: GameBalance.gameplayEffectDuration)
        }
    }

    private static func visualConcept(for kind: WorldPOIKind, key: String) -> WorldPOIVisualConcept {
        if key == "floresta_kelp_shallow_warm_current" { return .environment }
        switch kind {
        case .npc, .pet:
            return .npc
        case .shipwreck, .minigame, .story:
            return .object
        }
    }

    private static func actionKind(for kind: WorldPOIKind) -> WorldPOIActionKind {
        switch kind {
        case .shipwreck, .minigame:
            return .challenge
        case .npc, .pet, .story:
            return .temporaryEffect
        }
    }

    private static func challenge(for actionKind: WorldPOIActionKind,
                                  kind: WorldPOIKind) -> POIChallenge? {
        guard actionKind == .challenge else { return nil }
        switch kind {
        case .shipwreck:
            return POIChallenge(kind: .memory, goalMultiplier: 4)
        case .minigame:
            return POIChallenge(kind: .plot, goalMultiplier: 4)
        case .npc:
            return POIChallenge(kind: .snap, goalMultiplier: 5)
        case .story:
            return POIChallenge(kind: .memory, goalMultiplier: 4)
        case .pet:
            return POIChallenge(kind: .snap, goalMultiplier: 4)
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
    private enum RepeatablePOIReward {
        static let warmCurrentKey = "floresta_kelp_shallow_warm_current"
    }
    private enum WarmCurrentEnvironment {
        static let horizontalRadius: CGFloat = 980
        static let verticalRadius: CGFloat = 420
        static let coreRadius: CGFloat = 0.26
        static let maxHorizontalDrift: CGFloat = 118
        static let maxVerticalDrift: CGFloat = 34
        static let audioCooldown: CGFloat = 9
        static let tint = UIColor(red: 0.96, green: 0.48, blue: 0.32, alpha: 1)
        static let tintStrength: CGFloat = 0.34
    }
    private enum InteractionBalance {
        static let arrivalRadius: CGFloat = 150
        static let automaticRadius: CGFloat = 185
        static let automaticCooldown: TimeInterval = 35
    }

    unowned let ctx: GameContext
    private weak var worldNode: SKNode?
    private var scanTimer: CGFloat = 0
    private var exploreFocusLevel = 0
    private var focusUntil: Date?
    private var pendingInteraction: WorldPOI?
    private var visibleNodes: [String: WorldPOINode] = [:]
    private var visiblePOIs: [String: WorldPOI] = [:]
    private var isInsideWarmCurrent = false
    private var warmCurrentAudioCooldown: CGFloat = 0
    private var automaticInteractionCooldownByKey: [String: Date] = [:]

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        updateWarmCurrentEnvironment(dt: dt)

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
        activateNearbyPOIIfNeeded()
    }

    func explorationTargetAfterCommand() -> CGPoint? {
        exploreFocusLevel = min(5, exploreFocusLevel + 1)
        focusUntil = Date().addingTimeInterval(45)
        guard exploreFocusLevel >= 2 else { return nil }
        return nearestUndiscoveredPOI()?.position
    }

    func guidanceTargetForFish(near point: CGPoint, zone: DepthZone) -> WorldPOI? {
        guard let region = ctx.regions.currentRegion else { return nil }
        return WorldPOICatalog.pois(in: region, zone: zone, stats: ctx.stats)
            .filter { isReachable($0) }
            .min { lhs, rhs in
                let lhsRank = guidanceRank(for: lhs)
                let rhsRank = guidanceRank(for: rhs)
                if lhsRank != rhsRank { return lhsRank < rhsRank }
                return lhs.position.distance(to: point) < rhs.position.distance(to: point)
            }
    }

    func nearestVisiblePOI(to point: CGPoint, maxDistance: CGFloat) -> WorldPOI? {
        syncWorldNodes()
        return visiblePOIs.values
            .filter { $0.position.distance(to: point) <= maxDistance }
            .min { lhs, rhs in
                lhs.position.distance(to: point) < rhs.position.distance(to: point)
            }
    }

    func warmCurrentTint(at point: CGPoint) -> (color: UIColor, strength: CGFloat)? {
        guard let warmCurrent = reachableWarmCurrentPOI(),
              let intensity = warmCurrentIntensity(at: point, for: warmCurrent) else {
            return nil
        }
        let strength = WarmCurrentEnvironment.tintStrength
            * (0.35 + intensity * 0.65)
        return (WarmCurrentEnvironment.tint, strength)
    }

    func warmCurrentEnvironmentLevel(at point: CGPoint) -> CGFloat {
        guard let warmCurrent = reachableWarmCurrentPOI(),
              let intensity = warmCurrentIntensity(at: point, for: warmCurrent) else {
            return 0
        }
        return intensity
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
        if ctx.mermaidPosition.distance(to: poi.position) < InteractionBalance.arrivalRadius {
            pendingInteraction = poi
            syncWorldNodes()
            completePendingInteractionIfReached()
            return true
        }
        guard ctx.autonomy.canReachPointWithCurrentEnergy(poi.position, margin: 24) else {
            ctx.say("\(poi.name) está marcado, mas longe demais para a energia atual. Aproxime-se ou deixe ela descansar antes de interagir.")
            return false
        }
        guard ctx.autonomy.requestDestinationFromTouch(
            poi.position,
            acceptedMessage: "Ela aceitou voltar a \(poi.name) e vai nadar até lá.",
            refusalMessages: [
                "Ela viu \(poi.name), mas preferiu ficar por aqui.",
                "Ela olhou para \(poi.name), mas não quis voltar agora.",
                "Ela reconheceu o caminho para \(poi.name), mas seguiu a própria vontade."
            ]
        ) else { return false }
        pendingInteraction = poi
        syncWorldNodes()
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
        if isWarmCurrentPOI(poi) {
            return isReachable(poi)
        }
        guard ctx.stats.isPOIDiscovered(poi.key) else { return false }
        return isReachable(poi)
    }

    private func isReachable(_ poi: WorldPOI) -> Bool {
        ctx.stats.canAccess(poi.zone)
    }

    private func guidanceRank(for poi: WorldPOI) -> Int {
        if !ctx.stats.isPOIDiscovered(poi.key) { return 0 }
        if !ctx.stats.isPOIVisited(poi.key) { return 1 }
        if !ctx.stats.isPOIRewardCollected(poi.key) { return 2 }
        return 3
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

    private func updateWarmCurrentEnvironment(dt: CGFloat) {
        warmCurrentAudioCooldown = max(0, warmCurrentAudioCooldown - dt)
        guard let warmCurrent = reachableWarmCurrentPOI(),
              let intensity = warmCurrentIntensity(at: ctx.mermaidPosition, for: warmCurrent) else {
            ctx.autonomy.environmentDrift = .zero
            isInsideWarmCurrent = false
            return
        }

        let dx = ctx.mermaidPosition.x - warmCurrent.position.x
        let pushSign: CGFloat = dx < 0 ? -1 : 1
        let edgeFactor = abs(dx / WarmCurrentEnvironment.horizontalRadius).clamped(to: 0...1)
        let coreFactor = (WarmCurrentEnvironment.coreRadius - edgeFactor)
            .clamped(to: 0...WarmCurrentEnvironment.coreRadius)
            / WarmCurrentEnvironment.coreRadius
        let horizontal = pushSign * WarmCurrentEnvironment.maxHorizontalDrift
            * (0.30 + intensity * 0.70)
            * (1 - coreFactor * 0.55)
        let wave = sin((ctx.mermaidPosition.x - warmCurrent.position.x) / 240)
        let vertical = wave * WarmCurrentEnvironment.maxVerticalDrift * intensity
        ctx.autonomy.environmentDrift = CGVector(dx: horizontal, dy: vertical)

        if !isInsideWarmCurrent {
            isInsideWarmCurrent = true
            ctx.stats.boostMood(1.5)
        }
        if warmCurrentAudioCooldown <= 0 {
            warmCurrentAudioCooldown = WarmCurrentEnvironment.audioCooldown
            GameAudio.shared.play(.currentRush, volumeMultiplier: 0.32, cooldownOverride: 1.0)
        }
    }

    private func completePendingInteractionIfReached() {
        guard let poi = pendingInteraction,
              ctx.regions.currentRegion?.id == poi.regionId,
              ctx.mermaidPosition.distance(to: poi.position) < InteractionBalance.arrivalRadius else { return }
        pendingInteraction = nil
        interact(with: poi)
    }

    private func activateNearbyPOIIfNeeded() {
        guard let region = ctx.regions.currentRegion else { return }
        pruneAutomaticInteractionCooldowns()
        let pois = WorldPOICatalog.pois(in: region, stats: ctx.stats)
            .filter { canAutomaticallyActivate($0) }
        guard let poi = pois.min(by: {
            automaticActivationDistance(for: $0) < automaticActivationDistance(for: $1)
        }) else { return }

        automaticInteractionCooldownByKey[poi.key] = Date()
            .addingTimeInterval(InteractionBalance.automaticCooldown)
        pendingInteraction = nil
        interact(with: poi)
    }

    private func canAutomaticallyActivate(_ poi: WorldPOI) -> Bool {
        guard ctx.regions.currentRegion?.id == poi.regionId,
              ctx.stats.isPOIDiscovered(poi.key),
              isReachable(poi),
              automaticActivationDistance(for: poi) <= automaticActivationRadius(for: poi),
              automaticInteractionCooldownByKey[poi.key, default: .distantPast] <= Date() else {
            return false
        }
        if ctx.stats.isPOIRewardCollected(poi.key) {
            return canGrantRepeatableReward(for: poi)
        }
        if poi.actionKind == .challenge,
           ctx.scene?.canPresentPOIChallengeOffer() != true {
            return false
        }
        if isRepeatableRewardPOI(poi),
           !canGrantRepeatableReward(for: poi) {
            return false
        }
        return true
    }

    private func automaticActivationRadius(for poi: WorldPOI) -> CGFloat {
        isWarmCurrentPOI(poi) ? 1 : InteractionBalance.automaticRadius
    }

    private func automaticActivationDistance(for poi: WorldPOI) -> CGFloat {
        if isWarmCurrentPOI(poi),
           warmCurrentIntensity(at: ctx.mermaidPosition, for: poi) != nil {
            return 0
        }
        return ctx.mermaidPosition.distance(to: poi.position)
    }

    private func pruneAutomaticInteractionCooldowns() {
        let now = Date()
        automaticInteractionCooldownByKey = automaticInteractionCooldownByKey.filter { $0.value > now }
    }

    private func interact(with poi: WorldPOI) {
        ctx.stats.visitPOI(poi.key)
        ctx.stats.revealExpeditionMap(in: ctx.activeRegion, near: poi.position)

        if ctx.stats.isPOIRewardCollected(poi.key) {
            if grantRepeatableRewardIfReady(for: poi) {
                return
            }
            syncWorldNodes()
            ctx.say("Ela voltou a \(poi.name) e reconheceu o lugar.")
            return
        }

        if isRepeatableRewardPOI(poi),
           !canGrantRepeatableReward(for: poi) {
            syncWorldNodes()
            ctx.say("Ela sentiu a água morna da corrente e reconheceu o lugar.")
            return
        }

        if poi.actionKind == .challenge {
            guard let scene = ctx.scene,
                  scene.openPOIChallenge(for: poi, onCompletion: { [weak self] result in
                      self?.finishPOIChallenge(poi, result: result)
                  }) else {
                return
            }
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
        markRepeatableRewardActivatedIfNeeded(for: poi)
        ctx.stats.addMemory("Interagiu com \(poi.name)")
        syncWorldNodes()
        ctx.stats.save()
        ctx.say("\(prefix) \(rewardText)")
    }

    private func grantRepeatableRewardIfReady(for poi: WorldPOI) -> Bool {
        guard canGrantRepeatableReward(for: poi) else { return false }
        let rewardText = ctx.rewards.grant(poi.reward, source: poi.name)
        markRepeatableRewardActivatedIfNeeded(for: poi)
        ctx.stats.addMemory("Revisitou \(poi.name)")
        syncWorldNodes()
        ctx.stats.save()
        ctx.say("Ela voltou a \(poi.name). \(rewardText)")
        return true
    }

    private func canGrantRepeatableReward(for poi: WorldPOI) -> Bool {
        guard isRepeatableRewardPOI(poi),
              poi.reward.kind == .temporaryEffect,
              let buffKind = poi.reward.buffKind else {
            return false
        }
        return !ctx.stats.hasActiveBuff(buffKind)
            && ctx.stats.canActivateRepeatablePOIReward(poi.key)
    }

    private func markRepeatableRewardActivatedIfNeeded(for poi: WorldPOI) {
        guard isRepeatableRewardPOI(poi) else { return }
        ctx.stats.markRepeatablePOIRewardActivated(poi.key,
                                                   activeDuration: poi.reward.duration)
    }

    private func isRepeatableRewardPOI(_ poi: WorldPOI) -> Bool {
        poi.key == RepeatablePOIReward.warmCurrentKey
    }

    private func reachableWarmCurrentPOI() -> WorldPOI? {
        guard let region = ctx.regions.currentRegion else { return nil }
        return WorldPOICatalog.pois(in: region, stats: ctx.stats)
            .first { isWarmCurrentPOI($0) && isReachable($0) }
    }

    private func warmCurrentIntensity(at point: CGPoint, for poi: WorldPOI) -> CGFloat? {
        let normalizedX = (point.x - poi.position.x) / WarmCurrentEnvironment.horizontalRadius
        let normalizedY = (point.y - poi.position.y) / WarmCurrentEnvironment.verticalRadius
        let distance = normalizedX * normalizedX + normalizedY * normalizedY
        guard distance <= 1 else { return nil }
        return (1 - distance).clamped(to: 0...1)
    }

    private func isWarmCurrentPOI(_ poi: WorldPOI) -> Bool {
        poi.key == RepeatablePOIReward.warmCurrentKey
            && poi.visualConcept == .environment
            && poi.actionKind == .temporaryEffect
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
    private let mapPadding: CGFloat = 10

    init(size: CGSize,
         stats: MermaidStats,
         region: Region,
         currentPosition: CGPoint?) {
        self.mapSize = size
        super.init()

        drawFrame(region: region)
        drawDepthBands(stats: stats)
        drawRevealedCells(stats: stats, region: region)
        drawLockedVeil(stats: stats)
        drawPOIs(stats: stats, region: region)
        drawDiscoveryLead(stats: stats, region: region)
        drawCurrentPosition(currentPosition, in: region)
        drawTitle(region.name)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var slotHeight: CGFloat {
        plotHeight / CGFloat(zoneOrder.count)
    }

    private var plotWidth: CGFloat {
        max(1, mapSize.width - mapPadding * 2)
    }

    private var plotHeight: CGFloat {
        max(1, mapSize.height - mapPadding * 2)
    }

    private var plotLeftX: CGFloat {
        -mapSize.width / 2 + mapPadding
    }

    private var plotBottomY: CGFloat {
        -mapSize.height / 2 + mapPadding
    }

    private func drawFrame(region: Region) {
        let shadow = SKShapeNode(rectOf: mapSize, cornerRadius: 18)
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.fillColor = UIColor(white: 0, alpha: 0.24)
        shadow.strokeColor = .clear
        shadow.zPosition = -4
        addChild(shadow)

        let frame = SKShapeNode(rectOf: mapSize, cornerRadius: 18)
        frame.fillColor = UIColor(red: 0.01, green: 0.055, blue: 0.09, alpha: 0.94)
        frame.strokeColor = UIColor.lerp(region.tint, GameUI.gold, 0.22).withAlphaComponent(0.74)
        frame.lineWidth = 1.2
        frame.glowWidth = 1.4
        frame.zPosition = -3
        addChild(frame)

        let inner = SKShapeNode(rectOf: CGSize(width: mapSize.width - 8,
                                               height: mapSize.height - 8),
                                cornerRadius: 15)
        inner.fillColor = .clear
        inner.strokeColor = UIColor.white.withAlphaComponent(0.09)
        inner.lineWidth = 0.8
        inner.zPosition = 25
        addChild(inner)
    }

    private func drawDepthBands(stats: MermaidStats) {
        for (index, zone) in zoneOrder.enumerated() {
            let rect = SKShapeNode(rectOf: CGSize(width: plotWidth, height: slotHeight + 0.5),
                                   cornerRadius: 1.5)
            rect.position = CGPoint(x: 0, y: plotBottomY + slotHeight * (CGFloat(index) + 0.5))
            let unlocked = stats.canAccess(zone)
            rect.fillColor = unlocked
                ? mapColor(for: zone).withAlphaComponent(0.30)
                : UIColor(red: 0.03, green: 0.055, blue: 0.075, alpha: 0.72)
            rect.strokeColor = .clear
            addChild(rect)

            if index > 0 {
                let line = SKShapeNode(rectOf: CGSize(width: plotWidth, height: 0.7))
                line.position = CGPoint(x: 0, y: plotBottomY + slotHeight * CGFloat(index))
                line.fillColor = UIColor.white.withAlphaComponent(unlocked ? 0.06 : 0.035)
                line.strokeColor = .clear
                line.zPosition = 2
                addChild(line)
            }
        }
    }

    private func drawRevealedCells(stats: MermaidStats, region: Region) {
        let reveal = stats.expeditionReveal(for: region.id)
        let cellWidth = plotWidth / CGFloat(MermaidStats.expeditionMapColumns)
        let cellHeight = max(2.5, plotHeight / CGFloat(MermaidStats.expeditionMapRows) * 0.82)

        for (key, amount) in reveal {
            guard amount > 0.02,
                  let cell = MermaidStats.expeditionCellCoordinates(from: key) else { continue }
            let x = plotLeftX + (CGFloat(cell.column) + 0.5) * cellWidth
            let y = visualY(forWorldY: worldY(forRow: cell.row))
            let node = SKShapeNode(rectOf: CGSize(width: cellWidth + 0.5, height: cellHeight), cornerRadius: 1.2)
            node.position = CGPoint(x: x, y: y)
            node.fillColor = UIColor(red: 0.78, green: 0.98, blue: 0.94, alpha: 0.20 + amount * 0.62)
            node.strokeColor = .clear
            node.zPosition = 6
            addChild(node)
        }

        for poi in WorldPOICatalog.pois(in: region, stats: stats) {
            guard stats.canAccess(poi.zone) else { continue }
            let discovered = stats.isPOIDiscovered(poi.key)
            let interacted = stats.isPOIVisited(poi.key) || stats.isPOIRewardCollected(poi.key)
            guard discovered || interacted else { continue }

            let column = MermaidStats.expeditionColumn(forX: poi.position.x, in: region)
            let row = MermaidStats.expeditionRow(forY: poi.position.y)
            let cellKey = MermaidStats.expeditionCellKey(column: column, row: row)
            guard (reveal[cellKey] ?? 0) <= 0.02 else { continue }

            let x = plotLeftX + (CGFloat(column) + 0.5) * cellWidth
            let y = visualY(forWorldY: worldY(forRow: row))
            let node = SKShapeNode(rectOf: CGSize(width: cellWidth + 0.5, height: cellHeight), cornerRadius: 1.2)
            node.position = CGPoint(x: x, y: y)
            node.fillColor = poi.visual.color.withAlphaComponent(interacted ? 0.38 : 0.25)
            node.strokeColor = .clear
            node.zPosition = 6
            addChild(node)
        }
    }

    private func drawLockedVeil(stats: MermaidStats) {
        for (index, zone) in zoneOrder.enumerated() where !stats.canAccess(zone) {
            let veil = SKShapeNode(rectOf: CGSize(width: plotWidth, height: slotHeight + 0.5),
                                   cornerRadius: 1.5)
            veil.position = CGPoint(x: 0, y: plotBottomY + slotHeight * (CGFloat(index) + 0.5))
            veil.fillColor = UIColor(white: 0.01, alpha: 0.40)
            veil.strokeColor = UIColor.white.withAlphaComponent(0.03)
            veil.lineWidth = 0.4
            veil.zPosition = 8
            addChild(veil)
        }
    }

    private func drawCurrentPosition(_ position: CGPoint?, in region: Region) {
        guard let position, region.contains(position) else { return }
        let point = mapPoint(for: position, in: region)

        let pulse = SKShapeNode(circleOfRadius: 14)
        pulse.position = point
        pulse.fillColor = GameUI.gold.withAlphaComponent(0.12)
        pulse.strokeColor = GameUI.gold.withAlphaComponent(0.34)
        pulse.lineWidth = 1
        pulse.zPosition = 18
        addChild(pulse)

        let pinPath = UIBezierPath()
        pinPath.move(to: CGPoint(x: 0, y: -14))
        pinPath.addCurve(to: CGPoint(x: -8.2, y: -1.5),
                         controlPoint1: CGPoint(x: -5.6, y: -8.8),
                         controlPoint2: CGPoint(x: -8.2, y: -5.4))
        pinPath.addCurve(to: CGPoint(x: 0, y: 9.2),
                         controlPoint1: CGPoint(x: -8.2, y: 5.2),
                         controlPoint2: CGPoint(x: -4.3, y: 9.2))
        pinPath.addCurve(to: CGPoint(x: 8.2, y: -1.5),
                         controlPoint1: CGPoint(x: 4.3, y: 9.2),
                         controlPoint2: CGPoint(x: 8.2, y: 5.2))
        pinPath.addCurve(to: CGPoint(x: 0, y: -14),
                         controlPoint1: CGPoint(x: 8.2, y: -5.4),
                         controlPoint2: CGPoint(x: 5.6, y: -8.8))
        pinPath.close()
        let pin = SKShapeNode(path: pinPath.cgPath)
        pin.position = point
        pin.fillColor = UIColor(red: 0.03, green: 0.09, blue: 0.12, alpha: 0.96)
        pin.strokeColor = UIColor.white.withAlphaComponent(0.82)
        pin.lineWidth = 1.0
        pin.glowWidth = 1.2
        pin.zPosition = 19
        addChild(pin)

        let head = SKShapeNode(circleOfRadius: 2.4)
        head.position = CGPoint(x: point.x, y: point.y + 3.8)
        head.fillColor = GameUI.gold
        head.strokeColor = .clear
        head.zPosition = 20
        addChild(head)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: 0, y: 1.6))
        tailPath.addCurve(to: CGPoint(x: -2.4, y: -4.8),
                          controlPoint1: CGPoint(x: -1.7, y: -0.6),
                          controlPoint2: CGPoint(x: -2.2, y: -2.8))
        tailPath.addLine(to: CGPoint(x: -6.0, y: -7.6))
        tailPath.addCurve(to: CGPoint(x: 0, y: -6.0),
                          controlPoint1: CGPoint(x: -3.6, y: -8.2),
                          controlPoint2: CGPoint(x: -1.6, y: -7.4))
        tailPath.addCurve(to: CGPoint(x: 6.0, y: -7.6),
                          controlPoint1: CGPoint(x: 1.6, y: -7.4),
                          controlPoint2: CGPoint(x: 3.6, y: -8.2))
        tailPath.addLine(to: CGPoint(x: 2.4, y: -4.8))
        tailPath.addCurve(to: CGPoint(x: 0, y: 1.6),
                          controlPoint1: CGPoint(x: 2.2, y: -2.8),
                          controlPoint2: CGPoint(x: 1.7, y: -0.6))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.position = point
        tail.fillColor = GameUI.gold
        tail.strokeColor = .clear
        tail.zPosition = 20
        addChild(tail)
    }

    private func drawPOIs(stats: MermaidStats, region: Region) {
        let reveal = stats.expeditionReveal(for: region.id)
        for poi in WorldPOICatalog.pois(in: region, stats: stats) {
            guard stats.canAccess(poi.zone) else { continue }
            let column = MermaidStats.expeditionColumn(forX: poi.position.x, in: region)
            let row = MermaidStats.expeditionRow(forY: poi.position.y)
            let cellKey = MermaidStats.expeditionCellKey(column: column, row: row)
            let discovered = stats.isPOIDiscovered(poi.key)
            let interacted = stats.isPOIVisited(poi.key) || stats.isPOIRewardCollected(poi.key)
            let known = discovered || interacted
            guard (reveal[cellKey] ?? 0) > 0.14 || known else { continue }

            let node = SKNode()
            node.position = poiPoint(for: poi, in: region)
            node.name = known ? "poi_\(poi.key)" : nil
            node.zPosition = interacted ? 17 : (discovered ? 16 : 12)
            addChild(node)

            if known {
                let hit = SKShapeNode(circleOfRadius: 16)
                hit.fillColor = UIColor.white.withAlphaComponent(0.001)
                hit.strokeColor = .clear
                hit.name = node.name
                node.addChild(hit)
            }

            let marker = SKShapeNode(circleOfRadius: interacted ? 7.8 : (discovered ? 7.2 : 6.4))
            marker.fillColor = interacted
                ? poi.visual.color.withAlphaComponent(0.90)
                : discovered
                    ? poi.visual.color.withAlphaComponent(0.18)
                    : UIColor.white.withAlphaComponent(0.10)
            marker.strokeColor = interacted
                ? UIColor.white.withAlphaComponent(0.76)
                : discovered
                    ? poi.visual.color.withAlphaComponent(0.50)
                    : UIColor.white.withAlphaComponent(0.24)
            marker.lineWidth = 0.8
            marker.glowWidth = interacted ? 3 : 0
            marker.name = node.name
            node.addChild(marker)

            let artwork = WorldPOIArtworkFactory.makeArtwork(for: poi, size: .mapSmall)
            artwork.alpha = interacted ? 1 : (discovered ? 0.50 : 0.26)
            artwork.zPosition = 2
            WorldPOIArtworkFactory.applyInteractionName(node.name, to: artwork)
            node.addChild(artwork)
        }
    }

    private func drawDiscoveryLead(stats: MermaidStats, region: Region) {
        let leadId = stats.readyRegionDiscoveryId
            ?? stats.discoveryRouteRegionId
            ?? stats.pendingRegionDiscoveryId
        guard let leadId,
              let destination = RegionDiscoverySystem.region(withId: leadId),
              let point = stats.discoveryPointByRegion[leadId],
              region.contains(point) else { return }

        let mapPoint = mapPoint(for: point, in: region)
        let node = SKNode()
        node.position = mapPoint
        node.zPosition = 18
        addChild(node)

        let halo = SKShapeNode(circleOfRadius: 17)
        halo.fillColor = GameUI.gold.withAlphaComponent(0.13)
        halo.strokeColor = GameUI.gold.withAlphaComponent(0.52)
        halo.lineWidth = 1
        halo.glowWidth = 3
        node.addChild(halo)

        let marker = SKShapeNode(circleOfRadius: 8)
        marker.fillColor = UIColor.lerp(GameUI.palePaper, destination.tint, 0.24)
        marker.strokeColor = GameUI.gold.withAlphaComponent(0.90)
        marker.lineWidth = 1.2
        marker.zPosition = 2
        node.addChild(marker)

        let icon = GameUI.symbolIconNode(named: "map.fill",
                                         fallback: "M",
                                         color: UIColor.lerp(GameUI.ink, destination.tint, 0.24),
                                         size: 11)
        icon.zPosition = 3
        node.addChild(icon)

        let labelWidth = min(mapSize.width - 36, max(92, CGFloat(destination.name.count) * 5.3 + 36))
        let label = SKShapeNode(rectOf: CGSize(width: labelWidth, height: 20), cornerRadius: 7)
        label.position = CGPoint(x: 0, y: 24)
        label.fillColor = UIColor(red: 0.01, green: 0.04, blue: 0.07, alpha: 0.86)
        label.strokeColor = GameUI.gold.withAlphaComponent(0.34)
        label.lineWidth = 0.7
        label.zPosition = 4
        node.addChild(label)

        let text = SKLabelNode(text: stats.readyRegionDiscoveryId == leadId ? "rota pronta" : "passagem")
        text.fontName = "AvenirNext-DemiBold"
        text.fontSize = 8.6
        text.fontColor = GameUI.palePaper
        text.horizontalAlignmentMode = .center
        text.verticalAlignmentMode = .center
        text.position = label.position
        text.zPosition = 5
        node.addChild(text)
    }

    private func drawTitle(_ text: String) {
        let badgeWidth = min(mapSize.width - 28, max(126, CGFloat(text.count) * 6.2 + 28))
        let badge = SKShapeNode(rectOf: CGSize(width: badgeWidth, height: 24), cornerRadius: 9)
        badge.fillColor = UIColor(red: 0.01, green: 0.04, blue: 0.07, alpha: 0.82)
        badge.strokeColor = UIColor.white.withAlphaComponent(0.12)
        badge.lineWidth = 0.8
        badge.position = CGPoint(x: -mapSize.width / 2 + 12 + badgeWidth / 2,
                                 y: mapSize.height / 2 - 20)
        badge.zPosition = 20
        addChild(badge)

        let dot = SKShapeNode(circleOfRadius: 3.2)
        dot.position = CGPoint(x: badge.position.x - badgeWidth / 2 + 11,
                               y: badge.position.y)
        dot.fillColor = GameUI.gold.withAlphaComponent(0.90)
        dot.strokeColor = .clear
        dot.zPosition = 21
        addChild(dot)

        let title = SKLabelNode(text: text)
        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 10.5
        title.fontColor = GameUI.palePaper
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: dot.position.x + 9, y: badge.position.y)
        title.zPosition = 21
        addChild(title)
    }

    private func visualY(forWorldY y: CGFloat) -> CGFloat {
        let zone = DepthZone.zone(atY: y)
        guard let index = zoneOrder.firstIndex(of: zone) else { return 0 }
        let span = max(1, zone.yRange.upperBound - zone.yRange.lowerBound)
        let t = ((y - zone.yRange.lowerBound) / span).clamped(to: 0...1)
        return plotBottomY + CGFloat(index) * slotHeight + t * slotHeight
    }

    private func worldY(forRow row: Int) -> CGFloat {
        let t = CGFloat(row).clamped(to: 0...CGFloat(MermaidStats.expeditionMapRows - 1))
            / CGFloat(MermaidStats.expeditionMapRows - 1)
        return World.floorY + (World.surfaceTopY - World.floorY) * t
    }

    private func poiPoint(for poi: WorldPOI, in region: Region) -> CGPoint {
        mapPoint(for: poi.position, in: region)
    }

    private func mapPoint(for point: CGPoint, in region: Region) -> CGPoint {
        let column = MermaidStats.expeditionColumn(forX: point.x, in: region)
        let x = plotLeftX
            + (CGFloat(column) + 0.5) * (plotWidth / CGFloat(MermaidStats.expeditionMapColumns))
        let y = visualY(forWorldY: point.y)
        let inset: CGFloat = 12
        return CGPoint(x: x.clamped(to: (-mapSize.width / 2 + inset)...(mapSize.width / 2 - inset)),
                       y: y.clamped(to: (-mapSize.height / 2 + inset)...(mapSize.height / 2 - inset)))
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
    private var listRowStep: CGFloat = 1
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

        func fitLabel(_ label: SKLabelNode,
                      maxWidth: CGFloat,
                      minFontSize: CGFloat) {
            while label.calculateAccumulatedFrame().width > maxWidth && label.fontSize > minFontSize {
                label.fontSize -= 0.5
            }
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

        func poiIndicatorStrip(region: Region?,
                               stats: MermaidStats,
                               width: CGFloat,
                               height: CGFloat) -> SKNode {
            let node = SKNode()
            let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
            bg.fillColor = GameUI.palePaper.withAlphaComponent(0.74)
            bg.strokeColor = GameUI.line.withAlphaComponent(0.16)
            bg.lineWidth = 0.7
            node.addChild(bg)

            guard let region = region else { return node }
            let pois = WorldPOICatalog.pois(in: region, stats: stats)
                .filter { stats.canAccess($0.zone) }
            guard !pois.isEmpty else { return node }

            let iconDiameter = min(30, max(24, height - 10))
            let usableWidth = max(iconDiameter, width - 36)
            let step = pois.count > 1
                ? min(42, usableWidth / CGFloat(pois.count - 1))
                : 0
            let startX = pois.count > 1 ? -step * CGFloat(pois.count - 1) / 2 : 0

            for (index, poi) in pois.enumerated() {
                let discovered = stats.isPOIDiscovered(poi.key)
                let interacted = stats.isPOIVisited(poi.key) || stats.isPOIRewardCollected(poi.key)
                let known = discovered || interacted
                let indicator = SKNode()
                indicator.position = CGPoint(x: startX + CGFloat(index) * step, y: 0)
                indicator.zPosition = CGFloat(index + 1)
                if known {
                    indicator.name = "poi_\(poi.key)"
                }

                let ring = SKShapeNode(circleOfRadius: iconDiameter / 2)
                ring.fillColor = interacted
                    ? poi.visual.color.withAlphaComponent(0.24)
                    : discovered
                        ? poi.visual.color.withAlphaComponent(0.09)
                        : GameUI.mutedInk.withAlphaComponent(0.08)
                ring.strokeColor = interacted
                    ? poi.visual.color.withAlphaComponent(0.84)
                    : discovered
                        ? poi.visual.color.withAlphaComponent(0.34)
                        : GameUI.mutedInk.withAlphaComponent(0.22)
                ring.lineWidth = interacted ? 1.1 : 0.8
                ring.glowWidth = interacted ? 2 : 0
                ring.name = indicator.name
                indicator.addChild(ring)

                let artwork = WorldPOIArtworkFactory.makeArtwork(for: poi, size: .listSmall)
                artwork.alpha = interacted ? 1 : (discovered ? 0.44 : 0.24)
                artwork.zPosition = 2
                WorldPOIArtworkFactory.applyInteractionName(indicator.name, to: artwork)
                indicator.addChild(artwork)

                node.addChild(indicator)
            }

            return node
        }

        let regions = RegionDiscoverySystem.menuRegions
        let rowCardHeight: CGFloat = size.height < 720 ? 76 : 84
        let rowSpacing: CGFloat = 8
        let rowStep = rowCardHeight + rowSpacing
        listRowStep = rowStep
        let mapPreviewHeight: CGFloat = {
            if size.height < 720 { return 100 }
            if size.height < 760 { return 116 }
            return min(148, size.height * 0.18)
        }()
        let titleHeight: CGFloat = 24
        let currentCardHeight: CGFloat = 56
        let poiStripHeight: CGFloat = size.height < 520 ? 26 : 28
        let footerHeight: CGFloat = size.height < 720 ? 104 : 116
        let headerHeight: CGFloat = 18 + titleHeight + 8 + currentCardHeight + 10 + mapPreviewHeight + 8 + poiStripHeight + 24
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
        let titleY = panelHeight / 2 - 18 - titleHeight / 2
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

        let currentCardY = titleY - titleHeight / 2 - 8 - currentCardHeight / 2
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
        currentEyebrow.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY + 17)
        panelContent.addChild(currentEyebrow)

        let currentName = menuLabel(currentMapName,
                                    fontSize: 17,
                                    color: GameUI.palePaper,
                                    bold: true,
                                    maxWidth: listWidth - 126)
        currentName.lineBreakMode = .byTruncatingTail
        currentName.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY + 0)
        fitLabel(currentName, maxWidth: listWidth - 126, minFontSize: 13.0)
        panelContent.addChild(currentName)

        let openCount = regions.filter { stats.isRegionKnown($0) && $0.isAccessible(for: stats.phase) }.count
        let currentMeta = menuLabel("\(stats.phase.displayName) · \(openCount)/\(regions.count) mapas abertos",
                                    fontSize: 10,
                                    color: GameUI.palePaper.withAlphaComponent(0.76),
                                    bold: false,
                                    maxWidth: listWidth - 126)
        currentMeta.lineBreakMode = .byTruncatingTail
        currentMeta.position = CGPoint(x: -listWidth / 2 + 16, y: currentCardY - 18)
        fitLabel(currentMeta, maxWidth: listWidth - 126, minFontSize: 8.5)
        panelContent.addChild(currentMeta)

        let currentBadge = stateBadge(text: "ATUAL", color: GameUI.gold, width: 66)
        currentBadge.position = CGPoint(x: listWidth / 2 - 45, y: currentCardY + 6)
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
            route.lineBreakMode = .byTruncatingTail
            route.position = CGPoint(x: listWidth / 2 - 16, y: currentCardY - 18)
            fitLabel(route, maxWidth: 108, minFontSize: 8.0)
            panelContent.addChild(route)
        }

        let previewRegion: Region? = {
            guard let previewId = currentRegionId ?? destinationId else { return nil }
            return RegionDiscoverySystem.region(withId: previewId)
        }()

        if let previewRegion = previewRegion {
            let map = ExpeditionMapNode(size: CGSize(width: listWidth, height: mapPreviewHeight),
                                        stats: stats,
                                        region: previewRegion,
                                        currentPosition: currentPosition)
            map.position = CGPoint(x: 0, y: currentCardY - currentCardHeight / 2 - 10 - mapPreviewHeight / 2)
            map.zPosition = 4
            panelContent.addChild(map)

            for poi in WorldPOICatalog.pois(in: previewRegion, stats: stats) {
                let known = stats.isPOIDiscovered(poi.key)
                    || stats.isPOIVisited(poi.key)
                    || stats.isPOIRewardCollected(poi.key)
                if known {
                    rowPOIs[poi.key] = poi
                }
            }
        }

        let poiStripY = currentCardY - currentCardHeight / 2 - 10 - mapPreviewHeight - poiStripHeight / 2 - 8
        let poiStrip = poiIndicatorStrip(region: previewRegion,
                                         stats: stats,
                                         width: listWidth,
                                         height: poiStripHeight)
        poiStrip.position = CGPoint(x: 0, y: poiStripY)
        panelContent.addChild(poiStrip)

        let routeHeading = menuLabel("Rotas",
                                     fontSize: 11,
                                     color: GameUI.mutedInk,
                                     bold: true)
        routeHeading.position = CGPoint(x: -listWidth / 2 + 4, y: poiStripY - poiStripHeight / 2 - 12)
        panelContent.addChild(routeHeading)

        let listTopY = panelHeight / 2 - headerHeight
        let footerTopY = -panelHeight / 2 + footerHeight
        let listBottomY = footerTopY
        let rawListViewportHeight = max(rowCardHeight, listTopY - listBottomY)
        let visibleRowCount = max(1, min(regions.count, Int(floor((rawListViewportHeight + rowSpacing) / rowStep))))
        listViewportHeight = CGFloat(visibleRowCount) * rowStep - rowSpacing
        listCenterY = listTopY - listViewportHeight / 2
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
                actionText = "mapa atual"
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
            let textWidth = max(132, listWidth - 204)

            let stripe = SKShapeNode(rectOf: CGSize(width: 5, height: rowCardHeight - 18), cornerRadius: 2.5)
            stripe.position = CGPoint(x: -listWidth / 2 + 8, y: 0)
            stripe.fillColor = rowTint.withAlphaComponent(isLocked ? 0.34 : 0.86)
            stripe.strokeColor = .clear
            rowContent.addChild(stripe)

            let emblem = SKShapeNode(circleOfRadius: 17)
            emblem.position = CGPoint(x: -listWidth / 2 + 32, y: 4)
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
            name.fontSize = isCurrent ? 15.0 : 14.2
            name.fontColor = isLocked ? GameUI.mutedInk : GameUI.ink
            name.horizontalAlignmentMode = .left
            name.verticalAlignmentMode = .center
            name.preferredMaxLayoutWidth = textWidth
            name.numberOfLines = 1
            name.lineBreakMode = .byTruncatingTail
            name.position = CGPoint(x: leftX, y: 22)
            fitLabel(name, maxWidth: textWidth, minFontSize: 11.5)
            rowContent.addChild(name)

            let discoveryProgress = stats.mapDiscoveryProgress(in: region)
            let progress = Int((discoveryProgress * 100).rounded(.down))
            let status = menuLabel("\(actionText) · \(progress)%",
                                   fontSize: 10.5,
                                   color: isLocked ? GameUI.mutedInk.withAlphaComponent(0.78) : (hasLead || isDestination || isCurrent ? GameUI.gold : GameUI.accent),
                                   bold: true,
                                   maxWidth: textWidth)
            status.lineBreakMode = .byTruncatingTail
            status.position = CGPoint(x: leftX, y: -2)
            fitLabel(status, maxWidth: textWidth, minFontSize: 8.6)
            rowContent.addChild(status)

            let barWidth = max(72, min(150, listWidth - 190))
            let bar = progressBar(width: barWidth,
                                  progress: discoveryProgress,
                                  color: rowTint)
            bar.position = CGPoint(x: leftX + barWidth / 2, y: -24)
            rowContent.addChild(bar)

            let badge = stateBadge(text: badgeText,
                                   color: badgeColor,
                                   width: badgeText.count > 7 ? 86 : 70)
            badge.position = CGPoint(x: listWidth / 2 - (badgeText.count > 7 ? 52 : 44), y: 20)
            rowContent.addChild(badge)

            let phase = menuLabel(region.minPhase.displayName,
                                  fontSize: 8.5,
                                  color: isLocked ? GameUI.mutedInk.withAlphaComponent(0.64) : GameUI.mutedInk,
                                  bold: true)
            phase.horizontalAlignmentMode = .right
            phase.position = CGPoint(x: listWidth / 2 - 18, y: -18)
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

        let footerScrimSize = CGSize(width: panelWidth - 10, height: footerHeight)
        let footerScrim = SKShapeNode(rectOf: footerScrimSize, cornerRadius: 0)
        footerScrim.fillTexture = GameUI.paperTexture(size: footerScrimSize,
                                                      base: UIColor.lerp(GameUI.paper, GameUI.palePaper, 0.08))
        footerScrim.fillColor = .white
        footerScrim.strokeColor = .clear
        footerScrim.position = CGPoint(x: 0, y: footerTopY - footerHeight / 2)
        footerScrim.zPosition = 16
        panelContent.addChild(footerScrim)

        let footerDivider = SKShapeNode(rectOf: CGSize(width: listWidth - 24, height: 1.2), cornerRadius: 0.6)
        footerDivider.fillColor = GameUI.line.withAlphaComponent(0.16)
        footerDivider.strokeColor = .clear
        footerDivider.position = CGPoint(x: 0, y: footerTopY - 4)
        footerDivider.zPosition = 18
        panelContent.addChild(footerDivider)

        let close = GameUI.pill(text: "Fechar registro",
                                fontSize: 14,
                                bold: false,
                                fill: [GameUI.coral.withAlphaComponent(0.95)],
                                strokeColor: GameUI.coral.withAlphaComponent(0.55),
                                textColor: GameUI.ink,
                                hPadding: 20,
                                height: 32)
        close.name = "region_close"
        close.position = CGPoint(x: 0, y: -panelHeight / 2 + 38)
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

        if didScrollDuringTouch {
            snapListScrollToRow()
            return
        }

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

    private func snapListScrollToRow() {
        guard listRowStep > 1 else { return }
        let snapped = (listScrollOffset / listRowStep).rounded() * listRowStep
        updateListScroll(snapped)
    }
}
