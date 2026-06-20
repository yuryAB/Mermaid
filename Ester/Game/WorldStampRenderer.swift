//
//  WorldStampRenderer.swift
//  Ester
//
//  Entrada central para gerar texturas procedurais do oceano.
//

import SpriteKit
import UIKit

enum WorldStampRenderer {
    static func makeTexture(kind: WorldStampKind,
                            zone: DepthZone,
                            biome: AquaticBiome,
                            variant: Int) -> SKTexture {
        let size = textureSize(for: kind)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1

        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            context.clear(CGRect(origin: .zero, size: size))
            var rng = SeededGenerator(seed: seed(kind: kind, zone: zone, biome: biome, variant: variant))

            switch kind {
            case .rockBase:
                drawRockBase(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .kelpRibbon, .kelpBlade, .kelpBush:
                drawKelp(context: context, size: size, kind: kind, zone: zone, rng: &rng)
            case .coralFan:
                drawCoralFan(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .coralBranch:
                drawCoralBranch(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .coralTube:
                drawCoralTube(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .spongePatch:
                drawSpongePatch(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .crystalCluster:
                drawCrystalCluster(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .ventStack:
                drawVentStack(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .ruinShard:
                drawRuinShard(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .currentRibbon:
                drawCurrentRibbon(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .macroform:
                drawMacroform(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            case .reefSkirt:
                drawReefSkirt(context: context, size: size, zone: zone, biome: biome, rng: &rng)
            }
        }

        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func textureSize(for kind: WorldStampKind) -> CGSize {
        switch kind {
        case .rockBase: return CGSize(width: 256, height: 128)
        case .kelpRibbon, .kelpBlade, .kelpBush: return CGSize(width: 112, height: 280)
        case .coralFan, .coralBranch, .coralTube, .spongePatch: return CGSize(width: 160, height: 160)
        case .crystalCluster, .ventStack, .ruinShard: return CGSize(width: 160, height: 220)
        case .currentRibbon: return CGSize(width: 512, height: 72)
        case .macroform: return CGSize(width: 512, height: 256)
        case .reefSkirt: return CGSize(width: 256, height: 118)
        }
    }

    private static func seed(kind: WorldStampKind,
                             zone: DepthZone,
                             biome: AquaticBiome,
                             variant: Int) -> UInt64 {
        var value: UInt64 = 0xD1B54A32D192ED03
        value ^= kind.rawValue &* 0x9E3779B97F4A7C15
        value ^= UInt64(zone.rawValue + 1) &* 0xBF58476D1CE4E5B9
        value ^= biome.rawValue &* 0x94D049BB133111EB
        value ^= UInt64(bitPattern: Int64(variant + 31)) &* 0xA24BAED4963EE407
        return value
    }
}
