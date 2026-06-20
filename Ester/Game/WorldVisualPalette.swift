//
//  WorldVisualPalette.swift
//  Ester
//
//  Paleta visual procedural por profundidade e bioma.
//

import UIKit

enum WorldVisualPalette {
    static func rockColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear: return UIColor(red: 0.18, green: 0.44, blue: 0.46, alpha: 1)
        case .shallow: return UIColor(red: 0.12, green: 0.36, blue: 0.34, alpha: 1)
        case .mid: return UIColor(red: 0.08, green: 0.24, blue: 0.32, alpha: 1)
        case .blue: return UIColor(red: 0.05, green: 0.17, blue: 0.31, alpha: 1)
        case .deep: return UIColor(red: 0.04, green: 0.10, blue: 0.22, alpha: 1)
        case .abyss: return UIColor(red: 0.03, green: 0.04, blue: 0.12, alpha: 1)
        }
    }

    static func edgeColor(for zone: DepthZone) -> UIColor {
        UIColor.lerp(rockColor(for: zone), .white, zone == .abyss ? 0.12 : 0.2).withAlphaComponent(0.62)
    }

    static func kelpColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear: return UIColor(red: 0.34, green: 0.84, blue: 0.52, alpha: 1)
        case .shallow: return UIColor(red: 0.20, green: 0.66, blue: 0.44, alpha: 1)
        case .mid: return UIColor(red: 0.18, green: 0.52, blue: 0.50, alpha: 1)
        case .blue: return UIColor(red: 0.13, green: 0.42, blue: 0.58, alpha: 1)
        case .deep: return UIColor(red: 0.15, green: 0.34, blue: 0.56, alpha: 1)
        case .abyss: return UIColor(red: 0.24, green: 0.26, blue: 0.58, alpha: 1)
        }
    }

    static func groundCoverColor(for zone: DepthZone, biome: AquaticBiome) -> UIColor {
        let base: UIColor
        switch zone {
        case .surface, .clear:
            base = UIColor(red: 0.36, green: 0.82, blue: 0.56, alpha: 1)
        case .shallow:
            base = UIColor(red: 0.23, green: 0.66, blue: 0.45, alpha: 1)
        case .mid:
            base = UIColor(red: 0.18, green: 0.50, blue: 0.48, alpha: 1)
        case .blue:
            base = UIColor(red: 0.15, green: 0.38, blue: 0.54, alpha: 1)
        case .deep:
            base = UIColor(red: 0.18, green: 0.30, blue: 0.52, alpha: 1)
        case .abyss:
            base = UIColor(red: 0.28, green: 0.24, blue: 0.52, alpha: 1)
        }

        switch biome {
        case .coralGarden, .reefWall:
            return UIColor.lerp(base, UIColor(red: 0.82, green: 0.76, blue: 0.28, alpha: 1), 0.18)
        case .kelpForest:
            return UIColor.lerp(base, UIColor(red: 0.18, green: 0.74, blue: 0.36, alpha: 1), 0.24)
        case .crystalField:
            return UIColor.lerp(base, UIColor(red: 0.44, green: 0.92, blue: 1.0, alpha: 1), 0.18)
        case .deepVents:
            return UIColor.lerp(base, UIColor(red: 0.92, green: 0.38, blue: 0.22, alpha: 1), 0.14)
        case .ancientRuins, .cavernMouth:
            return UIColor.lerp(base, rockColor(for: zone), 0.28)
        case .openWater, .abyssPlain:
            return UIColor.lerp(base, rockColor(for: zone), 0.16)
        }
    }

    static func detailColor(for zone: DepthZone, biome: AquaticBiome) -> UIColor {
        if biome == .deepVents {
            return UIColor(red: 0.95, green: 0.45, blue: 0.24, alpha: 1)
        }
        switch zone {
        case .surface, .clear: return UIColor(red: 0.98, green: 0.58, blue: 0.54, alpha: 1)
        case .shallow: return UIColor(red: 0.92, green: 0.68, blue: 0.42, alpha: 1)
        case .mid: return UIColor(red: 0.42, green: 0.78, blue: 0.86, alpha: 1)
        case .blue: return UIColor(red: 0.45, green: 0.62, blue: 0.98, alpha: 1)
        case .deep: return UIColor(red: 0.42, green: 0.86, blue: 0.92, alpha: 1)
        case .abyss: return UIColor(red: 0.72, green: 0.46, blue: 0.96, alpha: 1)
        }
    }

    static func detailColor(for zone: DepthZone, biome: AquaticBiome, kind: WorldStampKind) -> UIColor {
        switch kind {
        case .coralFan:
            return UIColor.lerp(detailColor(for: zone, biome: biome),
                                UIColor(red: 1.0, green: 0.36, blue: 0.54, alpha: 1),
                                zone == .clear || zone == .shallow ? 0.42 : 0.18)
        case .coralBranch:
            return UIColor.lerp(detailColor(for: zone, biome: biome),
                                UIColor(red: 0.92, green: 0.28, blue: 0.26, alpha: 1),
                                zone == .deep || zone == .abyss ? 0.12 : 0.36)
        case .coralTube:
            return UIColor.lerp(detailColor(for: zone, biome: biome),
                                UIColor(red: 0.95, green: 0.72, blue: 0.38, alpha: 1),
                                0.32)
        case .spongePatch:
            return UIColor.lerp(detailColor(for: zone, biome: biome),
                                UIColor(red: 0.78, green: 0.82, blue: 0.28, alpha: 1),
                                0.36)
        case .crystalCluster:
            return zone == .abyss
                ? UIColor(red: 0.72, green: 0.46, blue: 1.0, alpha: 1)
                : UIColor(red: 0.44, green: 0.92, blue: 1.0, alpha: 1)
        case .ventStack:
            return UIColor(red: 0.96, green: 0.42, blue: 0.22, alpha: 1)
        case .ruinShard:
            return UIColor.lerp(rockColor(for: zone), UIColor(red: 0.42, green: 0.52, blue: 0.54, alpha: 1), 0.35)
        default:
            return detailColor(for: zone, biome: biome)
        }
    }

    static func kelpHeight(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface, .clear: return 180
        case .shallow: return 260
        case .mid: return 220
        case .blue: return 170
        case .deep: return 120
        case .abyss: return 100
        }
    }

    static func currentColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear: return UIColor(red: 0.86, green: 1.0, blue: 0.96, alpha: 1)
        case .shallow: return UIColor(red: 0.48, green: 0.92, blue: 0.78, alpha: 1)
        case .mid: return UIColor(red: 0.34, green: 0.72, blue: 0.86, alpha: 1)
        case .blue: return UIColor(red: 0.32, green: 0.56, blue: 0.92, alpha: 1)
        case .deep: return UIColor(red: 0.26, green: 0.42, blue: 0.74, alpha: 1)
        case .abyss: return UIColor(red: 0.36, green: 0.32, blue: 0.72, alpha: 1)
        }
    }

    static func macroColor(for zone: DepthZone, biome: AquaticBiome) -> UIColor {
        switch biome {
        case .ancientRuins:
            return UIColor(red: 0.06, green: 0.09, blue: 0.12, alpha: 1)
        case .deepVents:
            return UIColor(red: 0.08, green: 0.05, blue: 0.08, alpha: 1)
        case .crystalField:
            return UIColor(red: 0.08, green: 0.14, blue: 0.25, alpha: 1)
        default:
            return rockColor(for: zone)
        }
    }

    static func macroAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface, .clear: return 0.08
        case .shallow, .mid: return 0.14
        case .blue: return 0.18
        case .deep: return 0.22
        case .abyss: return 0.28
        }
    }

    static func particleBirthRate(for zone: DepthZone, biome: AquaticBiome) -> CGFloat {
        let base: CGFloat
        switch zone {
        case .surface: base = 0
        case .clear: base = 1.2
        case .shallow: base = 1.8
        case .mid: base = 2.4
        case .blue: base = 2.8
        case .deep: base = 3.2
        case .abyss: base = 1.6
        }
        let multiplier: CGFloat = biome == .deepVents || biome == .crystalField ? 1.35 : 1
        return base * multiplier
    }

    static func particleAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface: return 0
        case .clear, .shallow: return 0.16
        case .mid, .blue: return 0.20
        case .deep: return 0.25
        case .abyss: return 0.18
        }
    }

    static func particleColor(for zone: DepthZone, biome: AquaticBiome) -> UIColor {
        if biome == .deepVents {
            return UIColor(red: 0.92, green: 0.54, blue: 0.34, alpha: 1)
        }
        switch zone {
        case .deep, .abyss:
            return UIColor(red: 0.45, green: 0.92, blue: 0.98, alpha: 1)
        default:
            return UIColor(red: 0.82, green: 1.0, blue: 0.92, alpha: 1)
        }
    }
}
