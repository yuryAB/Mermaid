//
//  EcosystemBiomeCatalog.swift
//  Ester
//
//  Configurações de ecossistemas por bioma para flora, fauna e regras
//  de distribuição futura (variações visuais, profundidade e densidade).
//

import Foundation

// MARK: - Tipos auxiliares

enum EcosystemBiomeID: String, CaseIterable {
    case recifeTropical = "recife_tropical"
    case florestaKelp = "floresta_kelp"
    case manguezal = "manguezal"
    case estuario = "estuario"
    case marAbertoTropical = "mar_aberto_tropical"
    case marAbertoTemperado = "mar_aberto_temperado"
    case rioAmazonico = "rio_amazonico"
    case oceanoProfundo = "oceano_profundo"
    case zonaAbissal = "zona_abissal"
    case regiaoPolar = "regiao_polar"

    var biomeSeed: UInt64 {
        switch self {
        case .recifeTropical: return 0xA11CE1
        case .florestaKelp: return 0xA11CE2
        case .manguezal: return 0xA11CE3
        case .estuario: return 0xA11CE4
        case .marAbertoTropical: return 0xA11CE5
        case .marAbertoTemperado: return 0xA11CE6
        case .rioAmazonico: return 0xA11CE7
        case .oceanoProfundo: return 0xA11CE8
        case .zonaAbissal: return 0xA11CE9
        case .regiaoPolar: return 0xA11CEA
        }
    }
}

enum EcosystemVegetationCategory: String {
    case kelp
    case seagrass
    case algae
    case coral
    case sponge
    case mangroveRoot
    case macrophyte
    case rockAlgae
    case phytoplankton
    case iceAlgae
    case chemosyntheticMat
}

enum EcosystemVegetationSlot {
    case plant
    case detail
}

struct EcosystemZoneConfig {
    let reefDensityBias: CGFloat
    let plantSlots: ClosedRange<Int>
    let detailSlots: ClosedRange<Int>

    static let defaultSlots = EcosystemZoneConfig(reefDensityBias: 0,
                                                  plantSlots: 0...0,
                                                  detailSlots: 0...0)
}

struct EcosystemVegetationRule {
    let id: String
    let commonName: String
    let scientificName: String
    let category: EcosystemVegetationCategory
    let slot: EcosystemVegetationSlot
    let allowedZones: Set<DepthZone>
    let minDepth: CGFloat?
    let maxDepth: CGFloat?
    let rarity: CGFloat
    let renderKind: WorldStampKind
    let placeholderAliases: [String]
}

struct EcosystemBiomeProfile {
    let id: EcosystemBiomeID
    let displayName: String
    let shortDescription: String
    let compatibleZones: Set<DepthZone>
    let faunaAssociations: [String]
    let zoneConfigs: [DepthZone: EcosystemZoneConfig]
    let planktonDensityMultiplier: CGFloat
    let subBiomeWeights: [DepthZone: [AquaticBiome: CGFloat]]
    let vegetation: [EcosystemVegetationRule]

    func isDepthCompatible(_ zone: DepthZone) -> Bool {
        compatibleZones.contains(zone)
    }

    func isZoneCompatible(_ zone: DepthZone, y: CGFloat) -> Bool {
        compatibleZones.contains(zone) && zone.yRange.contains(y)
    }

    func zoneConfig(for zone: DepthZone) -> EcosystemZoneConfig {
        zoneConfigs[zone] ?? EcosystemZoneConfig.defaultSlots
    }

    func plantSlotRange(for zone: DepthZone) -> ClosedRange<Int> {
        zoneConfig(for: zone).plantSlots
    }

    func detailSlotRange(for zone: DepthZone) -> ClosedRange<Int> {
        zoneConfig(for: zone).detailSlots
    }

    func reefDensityBias(for zone: DepthZone) -> CGFloat {
        zoneConfig(for: zone).reefDensityBias
    }

    func subBiome(at coord: CGPoint, zone: DepthZone) -> AquaticBiome {
        guard isDepthCompatible(zone) else {
            return .openWater
        }
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(WorldChunkCoord.chunkCoord(for: coord), layer: .biome)
            ^ id.biomeSeed ^ UInt64(zone.rawValue + 31))
        return weightedSubBiome(for: zone, using: &rng) ?? AquaticBiome.biome(at: coord, zone: zone)
    }

    func plantRule(for zone: DepthZone, y: CGFloat, rng: inout SeededGenerator) -> EcosystemVegetationRule? {
        return randomRule(slot: .plant, zone: zone, y: y, rng: &rng)
    }

    func detailRule(for zone: DepthZone, y: CGFloat, rng: inout SeededGenerator) -> EcosystemVegetationRule? {
        return randomRule(slot: .detail, zone: zone, y: y, rng: &rng)
    }

    private func randomRule(slot: EcosystemVegetationSlot, zone: DepthZone, y: CGFloat, rng: inout SeededGenerator) -> EcosystemVegetationRule? {
        let candidates = vegetation.filter {
            $0.slot == slot &&
            $0.allowedZones.contains(zone) &&
            isCompatible(rule: $0, zone: zone, y: y)
        }
        return candidates.randomWeighted(using: &rng)
    }

    private func isCompatible(rule: EcosystemVegetationRule, zone: DepthZone, y: CGFloat) -> Bool {
        guard compatibleZones.contains(zone), rule.allowedZones.contains(zone) else { return false }
        if let minDepth = rule.minDepth, y < minDepth { return false }
        if let maxDepth = rule.maxDepth, y > maxDepth { return false }
        return true
    }

    private func weightedSubBiome(for zone: DepthZone, using rng: inout SeededGenerator) -> AquaticBiome? {
        let options = subBiomeWeights[zone] ?? [:]
        if options.isEmpty {
            return .openWater
        }
        let total = options.values.reduce(CGFloat.zero, +)
        guard total > 0 else { return nil }

        let target = rng.nextCGFloat(in: 0...total)
        var accumulator: CGFloat = 0
        for (biome, weight) in options {
            accumulator += Swift.max(CGFloat.zero, weight)
            if target <= accumulator { return biome }
        }
        return options.first?.key
    }
}

enum EcosystemBiomeCatalog {
    static func profile(for regionOrBiomeId: String) -> EcosystemBiomeProfile {
        if let id = EcosystemBiomeID(rawValue: regionOrBiomeId),
           let profile = all[id] {
            return profile
        }
        if let profile = all[biomeAlias[regionOrBiomeId] ?? .recifeTropical] {
            return profile
        }
        return all[.recifeTropical]!
    }

    private static let biomeAlias: [String: EcosystemBiomeID] = [
        "nascente": .recifeTropical,
        "jardim_calmo": .florestaKelp,
        "recife": .manguezal,
        "delta": .estuario,
        "mar_azul_aberto": .marAbertoTropical,
        "cavernas": .marAbertoTemperado,
        "campos_cristal": .rioAmazonico,
        "ruinas": .oceanoProfundo,
        "abismo_vivo": .zonaAbissal,
        "superficie_distante": .regiaoPolar
    ]

    private static let all: [EcosystemBiomeID: EcosystemBiomeProfile] = [
        .recifeTropical: EcosystemBiomeProfile(
            id: .recifeTropical,
            displayName: "Recife Tropical",
            shortDescription: "Habitat recifal com corais estruturadores, luz filtrada e fauna associada.",
            compatibleZones: [.clear, .shallow, .mid, .blue],
            faunaAssociations: [
                "peixe_palhaco_comum",
                "tartaruga_verde",
                "tartaruga_de_pente",
                "tubarao_recife_caribenho"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: 0.09, plantSlots: 0...2, detailSlots: 1...3),
                .shallow: .init(reefDensityBias: 0.18, plantSlots: 1...3, detailSlots: 3...6),
                .mid: .init(reefDensityBias: 0.09, plantSlots: 0...2, detailSlots: 2...5),
                .blue: .init(reefDensityBias: -0.12, plantSlots: 0...1, detailSlots: 0...2)
            ],
            planktonDensityMultiplier: 1.12,
            subBiomeWeights: [
                .clear: [.coralGarden: 0.68, .reefWall: 0.22, .openWater: 0.1],
                .shallow: [.coralGarden: 0.74, .reefWall: 0.16, .openWater: 0.1],
                .mid: [.coralGarden: 0.54, .reefWall: 0.24, .openWater: 0.22],
                .blue: [.openWater: 0.82, .coralGarden: 0.12, .reefWall: 0.06]
            ],
            vegetation: [
                .init(id: "recife_algas_corais",
                      commonName: "Algas coralinas incrustantes",
                      scientificName: "Porolithon spp.",
                      category: .rockAlgae,
                      slot: .detail,
                      allowedZones: [.shallow, .mid, .blue],
                      minDepth: nil,
                      maxDepth: nil,
                      rarity: 0.86,
                      renderKind: .spongePatch,
                      placeholderAliases: ["coral-alga-rocha"]),
                .init(id: "recife_coral_fan",
                      commonName: "Coral-chapéu",
                      scientificName: "Pocillopora spp.",
                      category: .coral,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: nil,
                      maxDepth: nil,
                      rarity: 0.78,
                      renderKind: .coralFan,
                      placeholderAliases: ["coral-fan"]),
                .init(id: "recife_coral_branch",
                      commonName: "Coral galho",
                      scientificName: "Acropora cervicornis",
                      category: .coral,
                      slot: .detail,
                      allowedZones: [.clear, .shallow, .mid],
                      minDepth: nil,
                      maxDepth: nil,
                      rarity: 0.68,
                      renderKind: .coralBranch,
                      placeholderAliases: ["coral-branch"]),
                .init(id: "recife_esponja",
                      commonName: "Esponja recifal",
                      scientificName: "Xestospongia muta",
                      category: .sponge,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: nil,
                      maxDepth: nil,
                      rarity: 0.54,
                      renderKind: .spongePatch,
                      placeholderAliases: ["sponge-patch"]),
                .init(id: "recife_plasmodes",
                      commonName: "Fitoplâncton do recife",
                      scientificName: "dinoflagelados bentônicos",
                      category: .phytoplankton,
                      slot: .detail,
                      allowedZones: [.clear, .shallow, .mid],
                      minDepth: nil,
                      maxDepth: nil,
                      rarity: 0.36,
                      renderKind: .crystalCluster,
                      placeholderAliases: ["plankton-film"])
            ]
        ),
        .florestaKelp: EcosystemBiomeProfile(
            id: .florestaKelp,
            displayName: "Floresta de Kelp",
            shortDescription: "Faixas frias e profundas com laminárias, sombra de copiosa produção de fitoplâncton.",
            compatibleZones: [.clear, .shallow, .mid, .blue],
            faunaAssociations: [
                "lontra_marinha",
                "garibaldi",
                "badejo_de_kelp",
                "caranguejo_de_kelp"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: 0.02, plantSlots: 1...3, detailSlots: 1...4),
                .shallow: .init(reefDensityBias: 0.2, plantSlots: 2...6, detailSlots: 2...5),
                .mid: .init(reefDensityBias: 0.14, plantSlots: 1...4, detailSlots: 1...4),
                .blue: .init(reefDensityBias: -0.04, plantSlots: 0...2, detailSlots: 1...2)
            ],
            planktonDensityMultiplier: 1.22,
            subBiomeWeights: [
                .clear: [.kelpForest: 0.86, .openWater: 0.14],
                .shallow: [.kelpForest: 0.94, .openWater: 0.06],
                .mid: [.kelpForest: 0.88, .deepVents: 0.06, .openWater: 0.06],
                .blue: [.kelpForest: 0.62, .openWater: 0.38]
            ],
            vegetation: [
                .init(id: "kelp_fronteira",
                      commonName: "Kelp marrom",
                      scientificName: "Nereocystis luetkeana",
                      category: .kelp,
                      slot: .plant,
                      allowedZones: [.clear, .shallow, .mid],
                      minDepth: -2800,
                      maxDepth: 0,
                      rarity: 1.0,
                      renderKind: .kelpBlade,
                      placeholderAliases: ["kelp-blade"]),
                .init(id: "kelp_broto",
                      commonName: "Kelp-ramo jovem",
                      scientificName: "Macrocystis pyrifera",
                      category: .kelp,
                      slot: .plant,
                      allowedZones: [.shallow, .mid],
                      minDepth: -6000,
                      maxDepth: -150,
                      rarity: 0.84,
                      renderKind: .kelpBush,
                      placeholderAliases: ["kelp-bush"]),
                .init(id: "kelp_filamentos",
                      commonName: "Fita de kelp",
                      scientificName: "Saccharina latissima",
                      category: .kelp,
                      slot: .plant,
                      allowedZones: [.clear, .shallow],
                      minDepth: -2800,
                      maxDepth: -40,
                      rarity: 0.74,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["kelp-ribbon"]),
                .init(id: "kelp_sponge",
                      commonName: "Esponja de base de kelp",
                      scientificName: "Suberites domuncula",
                      category: .sponge,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: -7000,
                      maxDepth: -250,
                      rarity: 0.46,
                      renderKind: .spongePatch,
                      placeholderAliases: ["sponge-patch"]),
                .init(id: "kelp_alga_marrom",
                      commonName: "Alga filamentosa do fundo",
                      scientificName: "Desmarestia aculeata",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: -6000,
                      maxDepth: -500,
                      rarity: 0.4,
                      renderKind: .spongePatch,
                      placeholderAliases: ["alga-filamentosa"])
            ]
        ),
        .manguezal: EcosystemBiomeProfile(
            id: .manguezal,
            displayName: "Manguezal",
            shortDescription: "Transição salobra com raízes aéreas, lama orgânica e refúgio para juvenis.",
            compatibleZones: [.clear, .shallow],
            faunaAssociations: [
                "peixe_arqueiro",
                "peixe_serra_dentes_pequenos",
                "crocodilo_americano",
                "peixe_boi_marinho"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: -0.05, plantSlots: 1...3, detailSlots: 1...3),
                .shallow: .init(reefDensityBias: -0.01, plantSlots: 2...5, detailSlots: 1...4)
            ],
            planktonDensityMultiplier: 1.28,
            subBiomeWeights: [
                .clear: [.openWater: 0.78, .reefWall: 0.18, .kelpForest: 0.04],
                .shallow: [.reefWall: 0.44, .openWater: 0.52, .kelpForest: 0.04]
            ],
            vegetation: [
                .init(id: "mangue_raizes",
                      commonName: "Raízes aéreas de mangue",
                      scientificName: "Rhizophora mangle",
                      category: .mangroveRoot,
                      slot: .plant,
                      allowedZones: [.shallow],
                      minDepth: -90,
                      maxDepth: -10,
                      rarity: 1.0,
                      renderKind: .reefSkirt,
                      placeholderAliases: ["mangrove-root"]),
                .init(id: "mangue_macrofitas",
                      commonName: "Macrófitas salobras",
                      scientificName: "Najas marina",
                      category: .macrophyte,
                      slot: .plant,
                      allowedZones: [.clear, .shallow],
                      minDepth: -150,
                      maxDepth: -5,
                      rarity: 0.82,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["salt-marsh-macrophyte"]),
                .init(id: "mangue_organismos_tam", commonName: "Alga de lama de mangue", scientificName: "Ulva australis", category: .algae, slot: .detail, allowedZones: [.shallow], minDepth: -110, maxDepth: -20, rarity: 0.66, renderKind: .spongePatch, placeholderAliases: ["mud-algae"]),
                .init(id: "mangue_plankton", commonName: "Plâncton estuarino", scientificName: "Microalgas estuarinas", category: .phytoplankton, slot: .detail, allowedZones: [.clear, .shallow], minDepth: -120, maxDepth: 0, rarity: 0.56, renderKind: .crystalCluster, placeholderAliases: ["estuary-plankton"])
            ]
        ),
        .estuario: EcosystemBiomeProfile(
            id: .estuario,
            displayName: "Estuário",
            shortDescription: "Zona de mistura salobra, fluxo sazonal e vegetação bentônica adaptada à variação de salinidade.",
            compatibleZones: [.clear, .shallow, .mid],
            faunaAssociations: [
                "salmao_atlantico",
                "robalo_listrado",
                "caranguejo_azul_estuario",
                "camarao_marrom"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: -0.06, plantSlots: 1...2, detailSlots: 1...3),
                .shallow: .init(reefDensityBias: 0.0, plantSlots: 1...4, detailSlots: 1...4),
                .mid: .init(reefDensityBias: 0.04, plantSlots: 1...3, detailSlots: 1...3)
            ],
            planktonDensityMultiplier: 1.24,
            subBiomeWeights: [
                .clear: [.openWater: 0.7, .reefWall: 0.26, .kelpForest: 0.04],
                .shallow: [.openWater: 0.55, .reefWall: 0.41, .kelpForest: 0.04],
                .mid: [.openWater: 0.7, .reefWall: 0.24, .kelpForest: 0.06]
            ],
            vegetation: [
                .init(id: "estuario_seagrass",
                      commonName: "Gramas submersas do estuário",
                      scientificName: "Ruppia maritima",
                      category: .seagrass,
                      slot: .plant,
                      allowedZones: [.shallow, .mid],
                      minDepth: -160,
                      maxDepth: -8,
                      rarity: 1.0,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["seagrass"]),
                .init(id: "estuario_macrophyte",
                      commonName: "Herbáceas flutuantes",
                      scientificName: "Zostera marina",
                      category: .macrophyte,
                      slot: .plant,
                      allowedZones: [.clear, .shallow],
                      minDepth: -150,
                      maxDepth: -20,
                      rarity: 0.64,
                      renderKind: .kelpBlade,
                      placeholderAliases: ["macrophyte"]),
                .init(id: "estuario_seda",
                      commonName: "Alga filamentosa de fundo",
                      scientificName: "Gracilaria caudata",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: -160,
                      maxDepth: -10,
                      rarity: 0.7,
                      renderKind: .spongePatch,
                      placeholderAliases: ["estuary-algae"]),
                .init(id: "estuario_plankton", commonName: "Plâncton fitoflagelado", scientificName: "Dunaliella salina", category: .phytoplankton, slot: .detail, allowedZones: [.clear, .shallow, .mid], minDepth: -140, maxDepth: 0, rarity: 0.48, renderKind: .crystalCluster, placeholderAliases: ["estuary-plankton"])
            ]
        ),
        .marAbertoTropical: EcosystemBiomeProfile(
            id: .marAbertoTropical,
            displayName: "Mar Aberto Tropical",
            shortDescription: "Pelágico quente e rápido, com derivas biológicas e bancos de fitoplâncton flutuante.",
            compatibleZones: [.clear, .shallow, .mid, .blue],
            faunaAssociations: [
                "atum_albacora",
                "agulhao_vela",
                "tubarao_baleia",
                "tartaruga_de_couro"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: -0.38, plantSlots: 0...0, detailSlots: 0...1),
                .shallow: .init(reefDensityBias: -0.2, plantSlots: 0...1, detailSlots: 0...2),
                .mid: .init(reefDensityBias: -0.25, plantSlots: 0...1, detailSlots: 0...2),
                .blue: .init(reefDensityBias: -0.3, plantSlots: 0...0, detailSlots: 0...1)
            ],
            planktonDensityMultiplier: 1.36,
            subBiomeWeights: [
                .clear: [.openWater: 0.95, .reefWall: 0.03, .kelpForest: 0.02],
                .shallow: [.openWater: 0.96, .reefWall: 0.02, .kelpForest: 0.02],
                .mid: [.openWater: 0.96, .reefWall: 0.03, .kelpForest: 0.01],
                .blue: [.openWater: 0.98, .reefWall: 0.02]
            ],
            vegetation: [
                .init(id: "maraberto_sargasso",
                      commonName: "Sargaço flutuante",
                      scientificName: "Sargassum natans",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.clear, .shallow],
                      minDepth: -220,
                      maxDepth: 0,
                      rarity: 1.0,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["floating-sargassum"]),
                .init(id: "maraberto_plankton", commonName: "Fitoplâncton oceânico", scientificName: "Thalassiosira spp.", category: .phytoplankton, slot: .detail, allowedZones: [.clear, .shallow, .mid, .blue], minDepth: -30000, maxDepth: -120, rarity: 0.82, renderKind: .crystalCluster, placeholderAliases: ["open-ocean-plankton"]),
                .init(id: "maraberto_medusa", commonName: "Jellyfish planctônica", scientificName: "Aurelia sp.", category: .algae, slot: .detail, allowedZones: [.mid, .blue], minDepth: -40000, maxDepth: -200, rarity: 0.34, renderKind: .spongePatch, placeholderAliases: ["jelly-placeholder"])
            ]
        ),
        .marAbertoTemperado: EcosystemBiomeProfile(
            id: .marAbertoTemperado,
            displayName: "Mar Aberto Temperado",
            shortDescription: "Correntes frias com comunidades pelágicas de longo alcance e matéria orgânica em suspensão.",
            compatibleZones: [.clear, .shallow, .mid, .blue],
            faunaAssociations: [
                "atum_rabilho",
                "cavala_do_atlantico",
                "orca_temperada",
                "baleia_jubarte_temperada"
            ],
            zoneConfigs: [
                .clear: .init(reefDensityBias: -0.34, plantSlots: 0...1, detailSlots: 0...2),
                .shallow: .init(reefDensityBias: -0.18, plantSlots: 0...1, detailSlots: 0...2),
                .mid: .init(reefDensityBias: -0.16, plantSlots: 0...1, detailSlots: 0...3),
                .blue: .init(reefDensityBias: -0.14, plantSlots: 0...1, detailSlots: 0...3)
            ],
            planktonDensityMultiplier: 1.3,
            subBiomeWeights: [
                .clear: [.openWater: 0.93, .reefWall: 0.05, .kelpForest: 0.02],
                .shallow: [.openWater: 0.92, .reefWall: 0.06, .kelpForest: 0.02],
                .mid: [.openWater: 0.94, .reefWall: 0.04, .kelpForest: 0.02],
                .blue: [.openWater: 0.96, .reefWall: 0.04]
            ],
            vegetation: [
                .init(id: "temperado_fita_alga",
                      commonName: "Alga filamentosa fria",
                      scientificName: "Ulva lactuca",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.shallow, .mid],
                      minDepth: -1600,
                      maxDepth: -20,
                      rarity: 0.9,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["cold-filament-algae"]),
                .init(id: "temperado_plankton",
                      commonName: "Fitoplâncton frio",
                      scientificName: "Chaetoceros spp.",
                      category: .phytoplankton,
                      slot: .detail,
                      allowedZones: [.clear, .shallow, .mid, .blue],
                      minDepth: -30000,
                      maxDepth: -15,
                      rarity: 0.8,
                      renderKind: .crystalCluster,
                      placeholderAliases: ["temperate-plankton"]),
                .init(id: "temperado_salps",
                      commonName: "Salpa gelatinoso",
                      scientificName: "Salpa maxima",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.blue],
                      minDepth: -36000,
                      maxDepth: -80,
                      rarity: 0.46,
                      renderKind: .spongePatch,
                      placeholderAliases: ["salp-placeholder"])
            ]
        ),
        .rioAmazonico: EcosystemBiomeProfile(
            id: .rioAmazonico,
            displayName: "Rio Amazônico",
            shortDescription: "Corrente de água doce com várzea, folhiço, madeira e plantas de transição rio-mar.",
            compatibleZones: [.surface, .clear, .shallow, .mid],
            faunaAssociations: [
                "boto_cor_de_rosa",
                "tucuxi",
                "peixe_boi_da_amazonia",
                "piranha_vermelha"
            ],
            zoneConfigs: [
                .surface: .init(reefDensityBias: 0.02, plantSlots: 1...4, detailSlots: 1...3),
                .clear: .init(reefDensityBias: 0.06, plantSlots: 1...4, detailSlots: 1...4),
                .shallow: .init(reefDensityBias: 0.1, plantSlots: 1...5, detailSlots: 1...4),
                .mid: .init(reefDensityBias: 0.05, plantSlots: 1...3, detailSlots: 1...3)
            ],
            planktonDensityMultiplier: 1.4,
            subBiomeWeights: [
                .surface: [.openWater: 0.92, .reefWall: 0.06, .kelpForest: 0.02],
                .clear: [.openWater: 0.9, .reefWall: 0.07, .kelpForest: 0.03],
                .shallow: [.openWater: 0.84, .reefWall: 0.12, .kelpForest: 0.04],
                .mid: [.openWater: 0.82, .kelpForest: 0.1, .reefWall: 0.08]
            ],
            vegetation: [
                .init(id: "amazonia_vareja",
                      commonName: "Macrófita de várzea",
                      scientificName: "Eichhornia crassipes",
                      category: .macrophyte,
                      slot: .plant,
                      allowedZones: [.surface, .shallow, .mid],
                      minDepth: -120,
                      maxDepth: 0,
                      rarity: 1.0,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["amazon-macrophyte"]),
                .init(id: "amazonia_frondosa",
                      commonName: "Folha flutuante",
                      scientificName: "Victoria amazonica",
                      category: .macrophyte,
                      slot: .plant,
                      allowedZones: [.surface, .clear],
                      minDepth: -80,
                      maxDepth: 0,
                      rarity: 0.75,
                      renderKind: .kelpBush,
                      placeholderAliases: ["floating-leaf"]),
                .init(id: "amazonia_videira",
                      commonName: "Raiz flutuante",
                      scientificName: "Pistia stratiotes",
                      category: .macrophyte,
                      slot: .detail,
                      allowedZones: [.surface, .clear, .shallow],
                      minDepth: -90,
                      maxDepth: 0,
                      rarity: 0.62,
                      renderKind: .coralTube,
                      placeholderAliases: ["floating-root"]),
                .init(id: "amazonia_plankton", commonName: "Fitoplâncton de água doce", scientificName: "Monoraphidium contortum", category: .phytoplankton, slot: .detail, allowedZones: [.surface, .clear, .shallow, .mid], minDepth: -150, maxDepth: 0, rarity: 0.9, renderKind: .crystalCluster, placeholderAliases: ["freshwater-plankton"])
            ]
        ),
        .oceanoProfundo: EcosystemBiomeProfile(
            id: .oceanoProfundo,
            displayName: "Oceano Profundo",
            shortDescription: "Zona mesopelágica/bateliana com fauna luminosa e comunidades sessis associadas à coluna escura.",
            compatibleZones: [.mid, .deep, .abyss],
            faunaAssociations: [
                "cachalote",
                "peixe_vibora",
                "tubarao_duende",
                "sifonoforo_gigante"
            ],
            zoneConfigs: [
                .mid: .init(reefDensityBias: -0.1, plantSlots: 0...1, detailSlots: 1...3),
                .deep: .init(reefDensityBias: 0.06, plantSlots: 0...2, detailSlots: 1...4),
                .abyss: .init(reefDensityBias: 0.08, plantSlots: 0...2, detailSlots: 1...4)
            ],
            planktonDensityMultiplier: 1.18,
            subBiomeWeights: [
                .mid: [.deepVents: 0.12, .openWater: 0.54, .crystalField: 0.34],
                .deep: [.deepVents: 0.24, .crystalField: 0.58, .openWater: 0.18],
                .abyss: [.deepVents: 0.32, .crystalField: 0.46, .ancientRuins: 0.12, .abyssPlain: 0.1]
            ],
            vegetation: [
                .init(id: "profundo_sifonoforo",
                      commonName: "Sifonóforo pelágico",
                      scientificName: "Praya dubia",
                      category: .algae,
                      slot: .detail,
                      allowedZones: [.deep, .abyss],
                      minDepth: -42000,
                      maxDepth: -1500,
                      rarity: 0.98,
                      renderKind: .spongePatch,
                      placeholderAliases: ["siphonophore"]),
                .init(id: "profundo_esponja", commonName: "Esponja de água fria", scientificName: "Xestospongia sp.", category: .sponge, slot: .detail, allowedZones: [.deep, .abyss], minDepth: -42000, maxDepth: -2500, rarity: 0.7, renderKind: .spongePatch, placeholderAliases: ["deep-sponge"]),
                .init(id: "profundo_crystal", commonName: "Cristalina de coluna", scientificName: "Colônia radiolariana", category: .algae, slot: .detail, allowedZones: [.deep, .abyss], minDepth: -45000, maxDepth: -1200, rarity: 0.56, renderKind: .crystalCluster, placeholderAliases: ["deep-crystal-cluster"]),
                .init(id: "profundo_mat_rod", commonName: "Manta bacteriana", scientificName: "Biofilme bentônico", category: .chemosyntheticMat, slot: .plant, allowedZones: [.deep, .abyss], minDepth: -42000, maxDepth: -2000, rarity: 0.35, renderKind: .reefSkirt, placeholderAliases: ["bacterial-mat"])
            ]
        ),
        .zonaAbissal: EcosystemBiomeProfile(
            id: .zonaAbissal,
            displayName: "Zona Abissal",
            shortDescription: "Planície profunda com baixíssima luz e organismos fixos quimiossintéticos de alta especialização.",
            compatibleZones: [.deep, .abyss],
            faunaAssociations: [
                "pepino_do_mar_abissal",
                "peixe_caracol_marianas",
                "lula_vampiro",
                "isopode_gigante"
            ],
            zoneConfigs: [
                .deep: .init(reefDensityBias: -0.01, plantSlots: 0...1, detailSlots: 1...3),
                .abyss: .init(reefDensityBias: 0.0, plantSlots: 0...2, detailSlots: 1...4)
            ],
            planktonDensityMultiplier: 0.94,
            subBiomeWeights: [
                .deep: [.deepVents: 0.28, .abyssPlain: 0.52, .ancientRuins: 0.2],
                .abyss: [.abyssPlain: 0.72, .deepVents: 0.22, .ancientRuins: 0.06]
            ],
            vegetation: [
                .init(id: "abissal_esponja_tubular",
                      commonName: "Esponja tubária",
                      scientificName: "Hyalonema spp.",
                      category: .sponge,
                      slot: .detail,
                      allowedZones: [.abyss],
                      minDepth: -50000,
                      maxDepth: -28000,
                      rarity: 1.0,
                      renderKind: .spongePatch,
                      placeholderAliases: ["abyssal-sponge"]),
                .init(id: "abissal_anelidae", commonName: "Manta bacteriana", scientificName: "Beggiatoa sp.", category: .chemosyntheticMat, slot: .plant, allowedZones: [.deep, .abyss], minDepth: -42000, maxDepth: -3000, rarity: 0.7, renderKind: .reefSkirt, placeholderAliases: ["bacterial-film"]),
                .init(id: "abissal_cristal", commonName: "Cristais de fonte", scientificName: "Riftia associada", category: .chemosyntheticMat, slot: .detail, allowedZones: [.deep, .abyss], minDepth: -50000, maxDepth: -4500, rarity: 0.52, renderKind: .crystalCluster, placeholderAliases: ["chemo-crystal"]),
                .init(id: "abissal_coral", commonName: "Braquiópode fixo", scientificName: "Lophelia pertusa", category: .sponge, slot: .detail, allowedZones: [.abyss], minDepth: -50000, maxDepth: -12000, rarity: 0.36, renderKind: .coralTube, placeholderAliases: ["deep-coral"])
            ]
        ),
        .regiaoPolar: EcosystemBiomeProfile(
            id: .regiaoPolar,
            displayName: "Região Polar",
            shortDescription: "Oceanos frios de alta latitude com gelo sazonal e fitoplâncton de água fria sob gelo.",
            compatibleZones: [.surface, .clear, .shallow, .mid],
            faunaAssociations: [
                "pinguim_imperador",
                "foca_de_weddell",
                "orca_polar",
                "krill_antartico"
            ],
            zoneConfigs: [
                .surface: .init(reefDensityBias: -0.08, plantSlots: 0...1, detailSlots: 0...2),
                .clear: .init(reefDensityBias: -0.02, plantSlots: 0...2, detailSlots: 0...3),
                .shallow: .init(reefDensityBias: 0.04, plantSlots: 0...2, detailSlots: 1...4),
                .mid: .init(reefDensityBias: 0.02, plantSlots: 0...1, detailSlots: 0...2)
            ],
            planktonDensityMultiplier: 1.5,
            subBiomeWeights: [
                .surface: [.openWater: 0.98],
                .clear: [.openWater: 0.95, .reefWall: 0.05],
                .shallow: [.openWater: 0.86, .reefWall: 0.12, .kelpForest: 0.02],
                .mid: [.openWater: 0.94, .reefWall: 0.06]
            ],
            vegetation: [
                .init(id: "polar_algas_gelo",
                      commonName: "Alga de gelo",
                      scientificName: "Palmaria decipiens",
                      category: .iceAlgae,
                      slot: .plant,
                      allowedZones: [.shallow, .mid],
                      minDepth: -200,
                      maxDepth: -20,
                      rarity: 1.0,
                      renderKind: .kelpRibbon,
                      placeholderAliases: ["ice-algae"]),
                .init(id: "polar_seston", commonName: "Fitoplâncton de águas frias", scientificName: "Phaeocystis antarctica", category: .phytoplankton, slot: .detail, allowedZones: [.surface, .clear, .shallow], minDepth: -250, maxDepth: -30, rarity: 0.9, renderKind: .crystalCluster, placeholderAliases: ["polar-plankton"]),
                .init(id: "polar_crio", commonName: "Capa de algas sobre gelo", scientificName: "Entotheca", category: .iceAlgae, slot: .detail, allowedZones: [.clear, .shallow], minDepth: -30, maxDepth: 0, rarity: 0.6, renderKind: .spongePatch, placeholderAliases: ["ice-crust"])
            ]
        )
    ]
}

// MARK: - Helpers

private extension Array where Element == EcosystemVegetationRule {
    func randomWeighted(using rng: inout SeededGenerator) -> EcosystemVegetationRule? {
        let totalWeight = reduce(CGFloat.zero) { $0 + Swift.max(CGFloat.zero, $1.rarity) }
        guard totalWeight > 0 else { return isEmpty ? nil : first }
        let target = rng.nextCGFloat(in: 0...totalWeight)
        var current = CGFloat.zero
        for rule in self {
            let weight = Swift.max(CGFloat.zero, rule.rarity)
            current += weight
            if target <= current { return rule }
        }
        return first
    }
}
