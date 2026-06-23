//
//  FishVisualModels.swift
//  Ester
//
//  Dados visuais explicitos das especies aquaticas.
//

import SpriteKit

enum FishSilhouette {
    case oval
    case needle
    case diamond
    case moon
    case ray
    case turtle

    private static let randomPool: [FishSilhouette] = [.oval, .needle, .diamond, .moon, .ray]

    static func random(for zone: DepthZone, rare: Bool, species: AquaticSpecies?) -> FishSilhouette {
        if let preferred = species.flatMap({ SpeciesVisualCatalog.profile(for: $0).silhouette }) {
            return preferred
        }
        if let group = species?.group {
            switch group {
            case .ray:
                return .ray
            case .shark, .mammal, .reptile, .bird:
                return .needle
            case .cephalopod, .cnidarian, .echinoderm, .mollusk, .annelid:
                return .moon
            case .crustacean, .arthropod:
                return .diamond
            case .fish:
                break
            }
        }
        if rare {
            return [.moon, .ray, .diamond].randomElement()!
        }
        switch zone {
        case .surface, .clear:
            return [.needle, .oval, .diamond].randomElement()!
        case .shallow:
            return [.oval, .diamond, .moon].randomElement()!
        case .mid, .blue:
            return randomPool.randomElement()!
        case .deep, .abyss:
            return [.needle, .ray, .moon, .diamond].randomElement()!
        }
    }
}

enum FishPattern: CaseIterable {
    case plain
    case stripes
    case spots
    case glowDots

    static func random(for zone: DepthZone, rare: Bool, species: AquaticSpecies?) -> FishPattern {
        if let preferred = preferred(for: zone, species: species) {
            return preferred
        }
        if let group = species?.group {
            switch group {
            case .mammal, .reptile, .bird:
                return .plain
            case .cephalopod, .cnidarian:
                return zone == .deep || zone == .abyss ? .glowDots : .spots
            default:
                break
            }
        }
        if rare { return .glowDots }
        switch zone {
        case .surface, .clear:
            return [.plain, .stripes, .spots].randomElement()!
        case .shallow, .mid:
            return allCases.randomElement()!
        case .blue, .deep, .abyss:
            return [.plain, .spots, .glowDots].randomElement()!
        }
    }

    private static func preferred(for zone: DepthZone, species: AquaticSpecies?) -> FishPattern? {
        if let species,
           let pattern = SpeciesVisualCatalog.profile(for: species).pattern {
            return pattern
        }
        if zone == .deep || zone == .abyss {
            return .glowDots
        }
        return nil
    }
}

enum TurtleShellStyle {
    case green
    case hawksbill
    case leatherback
}

enum SpeciesVisualTrait: Equatable {
    case parrotBeak
    case bill
    case moonFins
    case teeth
    case cetaceanFluke
    case orcaPatch
    case turtleShell(TurtleShellStyle)
    case claws
    case squidFins
    case urchinSpines
    case bodySpots(Int)
}

struct SpeciesVisualProfile {
    let color: UIColor
    let pattern: FishPattern?
    let silhouette: FishSilhouette?
    let lengthMultiplier: CGFloat
    let traits: [SpeciesVisualTrait]

    var bodySpotCount: Int? {
        for trait in traits {
            if case .bodySpots(let count) = trait { return count }
        }
        return nil
    }

    var turtleShellStyle: TurtleShellStyle? {
        for trait in traits {
            if case .turtleShell(let style) = trait { return style }
        }
        return nil
    }

    func has(_ trait: SpeciesVisualTrait) -> Bool {
        traits.contains(trait)
    }
}

enum SpeciesVisualCatalog {
    static func profile(for species: AquaticSpecies) -> SpeciesVisualProfile {
        overrides[species.id] ?? fallback(for: species.group)
    }

    private static func fallback(for group: AquaticAnimalGroup) -> SpeciesVisualProfile {
        switch group {
        case .fish:
            return profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1))
        case .shark:
            return profile(color: UIColor(red: 0.36, green: 0.48, blue: 0.54, alpha: 1),
                           pattern: .plain,
                           silhouette: .needle,
                           length: 1.16)
        case .ray:
            return profile(color: UIColor(red: 0.43, green: 0.58, blue: 0.62, alpha: 1),
                           pattern: .plain,
                           silhouette: .ray,
                           length: 1.08,
                           traits: [.bodySpots(9)])
        case .mammal:
            return profile(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1),
                           pattern: .plain,
                           silhouette: .needle,
                           length: 1.18)
        case .reptile:
            return profile(color: UIColor(red: 0.37, green: 0.55, blue: 0.34, alpha: 1),
                           pattern: .spots,
                           silhouette: .needle,
                           length: 1.10)
        case .crustacean, .arthropod:
            return profile(color: UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1),
                           pattern: .spots,
                           silhouette: .diamond,
                           length: 0.92)
        case .mollusk:
            return profile(color: UIColor(red: 0.66, green: 0.56, blue: 0.42, alpha: 1),
                           pattern: .stripes,
                           silhouette: .diamond,
                           length: 0.90)
        case .cephalopod:
            return profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                           pattern: .spots,
                           silhouette: .moon,
                           length: 1.06)
        case .cnidarian:
            return profile(color: UIColor(red: 0.74, green: 0.56, blue: 0.86, alpha: 1),
                           pattern: .glowDots,
                           silhouette: .moon,
                           length: 0.95)
        case .echinoderm:
            return profile(color: UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1),
                           pattern: .spots,
                           silhouette: .diamond,
                           length: 0.82)
        case .annelid:
            return profile(color: UIColor(red: 0.76, green: 0.25, blue: 0.22, alpha: 1),
                           pattern: .stripes,
                           silhouette: .diamond)
        case .bird:
            return profile(color: UIColor(red: 0.10, green: 0.16, blue: 0.22, alpha: 1),
                           pattern: .plain,
                           silhouette: .needle)
        }
    }

    private static func profile(color: UIColor,
                                pattern: FishPattern? = nil,
                                silhouette: FishSilhouette? = nil,
                                length: CGFloat = 1,
                                traits: [SpeciesVisualTrait] = []) -> SpeciesVisualProfile {
        SpeciesVisualProfile(color: color,
                             pattern: pattern,
                             silhouette: silhouette,
                             lengthMultiplier: length,
                             traits: traits)
    }

    private static let overrides: [String: SpeciesVisualProfile] = [
        "peixe_palhaco_comum": profile(color: UIColor(red: 0.94, green: 0.42, blue: 0.16, alpha: 1),
                                       pattern: .stripes),
        "peixe_cirurgiao_azul": profile(color: UIColor(red: 0.12, green: 0.48, blue: 0.86, alpha: 1),
                                         pattern: .plain,
                                         silhouette: .diamond),
        "rockfish_azul": profile(color: UIColor(red: 0.12, green: 0.48, blue: 0.86, alpha: 1),
                                  pattern: .plain),
        "peixe_papagaio_arco_iris": profile(color: UIColor(red: 0.30, green: 0.72, blue: 0.42, alpha: 1),
                                             pattern: .spots,
                                             silhouette: .moon,
                                             traits: [.parrotBeak]),
        "dourado": profile(color: UIColor(red: 0.30, green: 0.72, blue: 0.42, alpha: 1),
                            pattern: .spots),
        "tambaqui": profile(color: UIColor(red: 0.30, green: 0.72, blue: 0.42, alpha: 1),
                             pattern: .spots),
        "peixe_borboleta_lavrado": profile(color: UIColor(red: 0.95, green: 0.67, blue: 0.24, alpha: 1),
                                            pattern: .stripes,
                                            silhouette: .diamond),
        "peixe_anjo_rainha": profile(color: UIColor(red: 0.95, green: 0.67, blue: 0.24, alpha: 1),
                                      pattern: .stripes,
                                      silhouette: .diamond),
        "garibaldi": profile(color: UIColor(red: 0.95, green: 0.67, blue: 0.24, alpha: 1),
                              pattern: .stripes),
        "piranha_vermelha": profile(color: UIColor(red: 0.78, green: 0.42, blue: 0.34, alpha: 1),
                                     pattern: .spots),
        "salmao_atlantico": profile(color: UIColor(red: 0.78, green: 0.42, blue: 0.34, alpha: 1),
                                     pattern: .spots),
        "barracuda_grande": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                                     silhouette: .needle),
        "agulhao_vela": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                                 silhouette: .needle,
                                 length: 1.24,
                                 traits: [.bill]),
        "marlim_azul": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                                silhouette: .needle,
                                length: 1.24,
                                traits: [.bill]),
        "espadarte": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                              silhouette: .needle,
                              length: 1.24,
                              traits: [.bill]),
        "peixe_lua": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                              silhouette: .moon,
                              traits: [.moonFins]),
        "atum_albacora": openWaterFish,
        "atum_bonito": openWaterFish,
        "atum_rabilho": openWaterFish,
        "albacora_branca": openWaterFish,
        "cavala_do_atlantico": openWaterFish,
        "sardinha_europeia": openWaterFish,
        "arenque_atlantico": openWaterFish,
        "peixe_lanterna": deepFish,
        "peixe_dragao_negro": deepFishWithTeeth,
        "peixe_vibora": deepFishWithTeeth,
        "peixe_machado_marinho": deepFish,
        "peixe_ogro": deepFishWithTeeth,
        "enguia_gulper": deepFish,
        "candiru": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                            silhouette: .needle),
        "enguia_eletrica": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                                    silhouette: .needle),
        "cusk_eel_abissal": profile(color: UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1),
                                     silhouette: .needle),

        "tubarao_baleia": whaleShark,
        "tubarao_frade": whaleShark,
        "tubarao_leopardo": profile(color: UIColor(red: 0.36, green: 0.48, blue: 0.54, alpha: 1),
                                     pattern: .spots,
                                     silhouette: .needle,
                                     length: 1.16,
                                     traits: [.bodySpots(7)]),
        "arraia_chita": spottedRay,
        "raia_manta_oceanica": profile(color: UIColor(red: 0.43, green: 0.58, blue: 0.62, alpha: 1),
                                        pattern: .spots,
                                        silhouette: .ray,
                                        length: 1.28,
                                        traits: [.bodySpots(6)]),

        "boto_cor_de_rosa": cetacean(color: UIColor(red: 0.86, green: 0.54, blue: 0.58, alpha: 1)),
        "tucuxi": cetacean(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1)),
        "golfinho_nariz_de_garrafa_estuario": cetacean(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1)),
        "golfinho_nariz_de_garrafa_tropical": cetacean(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1)),
        "golfinho_pintado_pantropical": cetacean(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1),
                                                  pattern: .spots),
        "golfinho_comum": cetacean(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1)),
        "orca_temperada": orca,
        "orca_polar": orca,
        "cachalote": whale,
        "baleia_jubarte_temperada": whale,
        "baleia_azul_polar": whale,
        "baleia_minke_antartica": whale,
        "lontra_marinha": profile(color: UIColor(red: 0.38, green: 0.25, blue: 0.18, alpha: 1),
                                   pattern: .plain,
                                   silhouette: .needle,
                                   length: 1.18),
        "lontra_de_rio_norte_americana": profile(color: UIColor(red: 0.38, green: 0.25, blue: 0.18, alpha: 1),
                                                  pattern: .plain,
                                                  silhouette: .needle,
                                                  length: 1.18),

        "tartaruga_verde": turtle(.green),
        "tartaruga_de_pente": turtle(.hawksbill),
        "tartaruga_de_couro": turtle(.leatherback),
        "tartaruga_da_amazonia": turtle(.green),
        "crocodilo_americano": longReptile,
        "jacare_acu": longReptile,
        "anaconda_verde": longReptile,

        "siri_azul": blueCrustaceanWithClaws,
        "siri_azul_estuario": blueCrustaceanWithClaws,
        "caranguejo_uca": crustaceanWithClaws,
        "caranguejo_violinista": crustaceanWithClaws,
        "caranguejo_de_kelp": crustaceanWithClaws,
        "caranguejo_ferradura": crustaceanWithClaws,
        "caranguejo_yeti": crustaceanWithClaws,
        "lagosta_espinhosa_caribenha": crustaceanWithClaws,
        "krill_antartico": profile(color: UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1),
                                    pattern: .spots,
                                    silhouette: .diamond,
                                    length: 0.92),
        "camarao_de_vidro": profile(color: UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1),
                                     pattern: .plain,
                                     silhouette: .diamond,
                                     length: 0.92),
        "anfipode_gigante": giantCrustacean,
        "isopode_gigante": giantCrustacean,

        "lula_recifal_caribenha": squid,
        "lula_comum": squid,
        "lula_gigante": giantSquid,
        "lula_colossal": giantSquid,
        "lula_vampiro": profile(color: UIColor(red: 0.32, green: 0.10, blue: 0.18, alpha: 1),
                                 pattern: .spots,
                                 silhouette: .moon,
                                 length: 1.36,
                                 traits: [.squidFins]),
        "polvo_do_recife_caribenho": profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                                              pattern: .spots,
                                              silhouette: .moon),
        "polvo_gigante_pacifico": profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                                           pattern: .spots,
                                           silhouette: .moon,
                                           length: 1.36),
        "polvo_dumbo": profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                                pattern: .spots,
                                silhouette: .moon),

        "sifonoforo_gigante": profile(color: UIColor(red: 0.74, green: 0.56, blue: 0.86, alpha: 1),
                                       pattern: .glowDots,
                                       silhouette: .needle,
                                       length: 1.24),
        "agua_viva_capacete": giantCnidarian,
        "agua_viva_atolla": giantCnidarian,
        "agua_viva_juba_de_leao": giantCnidarian,

        "estrela_do_mar_azul": profile(color: UIColor(red: 0.14, green: 0.54, blue: 0.82, alpha: 1),
                                        pattern: .spots,
                                        silhouette: .diamond,
                                        length: 0.82),
        "ourico_roxo_do_mar": profile(color: UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1),
                                       pattern: .spots,
                                       silhouette: .diamond,
                                       length: 0.82,
                                       traits: [.urchinSpines])
    ]

    private static let openWaterFish = profile(color: UIColor(red: 0.42, green: 0.58, blue: 0.72, alpha: 1),
                                               pattern: .plain,
                                               silhouette: .needle)
    private static let deepFish = profile(color: UIColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1),
                                          pattern: .glowDots,
                                          silhouette: .needle)
    private static let deepFishWithTeeth = profile(color: UIColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1),
                                                   pattern: .glowDots,
                                                   silhouette: .needle,
                                                   traits: [.teeth])
    private static let whaleShark = profile(color: UIColor(red: 0.34, green: 0.48, blue: 0.58, alpha: 1),
                                            pattern: .spots,
                                            silhouette: .needle,
                                            length: 1.32,
                                            traits: [.bodySpots(12)])
    private static let spottedRay = profile(color: UIColor(red: 0.43, green: 0.58, blue: 0.62, alpha: 1),
                                            pattern: .spots,
                                            silhouette: .ray,
                                            length: 1.08,
                                            traits: [.bodySpots(9)])
    private static let whale = profile(color: UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1),
                                       pattern: .plain,
                                       silhouette: .needle,
                                       length: 1.42,
                                       traits: [.cetaceanFluke])
    private static let orca = profile(color: UIColor(red: 0.10, green: 0.13, blue: 0.16, alpha: 1),
                                      pattern: .plain,
                                      silhouette: .needle,
                                      length: 1.42,
                                      traits: [.cetaceanFluke, .orcaPatch])
    private static let longReptile = profile(color: UIColor(red: 0.37, green: 0.55, blue: 0.34, alpha: 1),
                                             pattern: .spots,
                                             silhouette: .needle,
                                             length: 1.38)
    private static let crustaceanWithClaws = profile(color: UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1),
                                                     pattern: .spots,
                                                     silhouette: .diamond,
                                                     length: 0.92,
                                                     traits: [.claws])
    private static let blueCrustaceanWithClaws = profile(color: UIColor(red: 0.18, green: 0.48, blue: 0.76, alpha: 1),
                                                         pattern: .spots,
                                                         silhouette: .diamond,
                                                         length: 0.92,
                                                         traits: [.claws])
    private static let giantCrustacean = profile(color: UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1),
                                                 pattern: .spots,
                                                 silhouette: .diamond,
                                                 length: 1.22)
    private static let squid = profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                                       pattern: .spots,
                                       silhouette: .needle,
                                       length: 1.06,
                                       traits: [.squidFins])
    private static let giantSquid = profile(color: UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1),
                                            pattern: .spots,
                                            silhouette: .needle,
                                            length: 1.36,
                                            traits: [.squidFins])
    private static let giantCnidarian = profile(color: UIColor(red: 0.74, green: 0.56, blue: 0.86, alpha: 1),
                                                pattern: .glowDots,
                                                silhouette: .moon,
                                                length: 1.24)

    private static func cetacean(color: UIColor, pattern: FishPattern = .plain) -> SpeciesVisualProfile {
        profile(color: color,
                pattern: pattern,
                silhouette: .needle,
                length: 1.18,
                traits: [.cetaceanFluke])
    }

    private static func turtle(_ style: TurtleShellStyle) -> SpeciesVisualProfile {
        let color: UIColor
        let length: CGFloat
        switch style {
        case .green:
            color = UIColor(red: 0.37, green: 0.55, blue: 0.34, alpha: 1)
            length = 1.10
        case .hawksbill:
            color = UIColor(red: 0.37, green: 0.55, blue: 0.34, alpha: 1)
            length = 1.10
        case .leatherback:
            color = UIColor(red: 0.20, green: 0.22, blue: 0.24, alpha: 1)
            length = 1.20
        }
        return profile(color: color,
                       pattern: .plain,
                       silhouette: .turtle,
                       length: length,
                       traits: [.turtleShell(style)])
    }
}


enum FishVisualPalette {
    static func palette(for zone: DepthZone) -> [UIColor] {
        switch zone {
        case .surface:
            return [UIColor(red: 0.75, green: 0.8, blue: 0.85, alpha: 1),
                    UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1)]
        case .clear:
            return [UIColor(red: 0.95, green: 0.85, blue: 0.5, alpha: 1),
                    UIColor(red: 0.75, green: 0.9, blue: 0.95, alpha: 1),
                    UIColor(red: 0.6, green: 0.85, blue: 0.7, alpha: 1)]
        case .shallow:
            return [UIColor(red: 0.95, green: 0.8, blue: 0.4, alpha: 1),
                    UIColor(red: 0.7, green: 0.85, blue: 0.9, alpha: 1),
                    UIColor(red: 0.55, green: 0.8, blue: 0.6, alpha: 1)]
        case .mid:
            return [UIColor(red: 0.4, green: 0.55, blue: 0.8, alpha: 1),
                    UIColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 1),
                    UIColor(red: 0.5, green: 0.75, blue: 0.85, alpha: 1)]
        case .blue:
            return [UIColor(red: 0.35, green: 0.5, blue: 0.85, alpha: 1),
                    UIColor(red: 0.45, green: 0.6, blue: 0.8, alpha: 1)]
        case .deep:
            return [UIColor(red: 0.35, green: 0.45, blue: 0.7, alpha: 1),
                    UIColor(red: 0.45, green: 0.7, blue: 0.75, alpha: 1)]
        case .abyss:
            return [UIColor(red: 0.5, green: 0.4, blue: 0.7, alpha: 1),
                    UIColor(red: 0.3, green: 0.55, blue: 0.65, alpha: 1)]
        }
    }
}

