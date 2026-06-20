//
//  WorldEnvironmentModels.swift
//  Ester
//
//  Tipos compartilhados pela geracao procedural do oceano.
//

import Foundation
import SpriteKit

enum AquaticBiome: UInt64, CaseIterable {
    case openWater = 1
    case coralGarden = 2
    case kelpForest = 3
    case crystalField = 4
    case deepVents = 5
    case abyssPlain = 6
    case ancientRuins = 7
    case cavernMouth = 8
    case reefWall = 9

    static func biome(at point: CGPoint, zone: DepthZone) -> AquaticBiome {
        let coord = WorldChunkCoord.chunkCoord(for: point)
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .biome))
        let roll = rng.nextCGFloat(in: 0...1)

        switch zone {
        case .surface, .clear:
            return roll < 0.55 ? .openWater : .coralGarden
        case .shallow:
            if roll < 0.36 { return .coralGarden }
            if roll < 0.66 { return .kelpForest }
            if roll < 0.84 { return .reefWall }
            return .openWater
        case .mid:
            if roll < 0.36 { return .reefWall }
            if roll < 0.58 { return .cavernMouth }
            if roll < 0.76 { return .coralGarden }
            return .openWater
        case .blue:
            return roll < 0.72 ? .openWater : .cavernMouth
        case .deep:
            if roll < 0.36 { return .crystalField }
            if roll < 0.64 { return .deepVents }
            if roll < 0.82 { return .ancientRuins }
            return .openWater
        case .abyss:
            if roll < 0.58 { return .abyssPlain }
            if roll < 0.78 { return .deepVents }
            if roll < 0.92 { return .ancientRuins }
            return .openWater
        }
    }
}

struct WorldChunkCoord: Hashable {
    static let size: CGFloat = 2048

    let x: Int
    let y: Int

    static func chunkCoord(for position: CGPoint) -> WorldChunkCoord {
        WorldChunkCoord(x: Int(floor(position.x / size)),
                        y: Int(floor(position.y / size)))
    }

    var rect: CGRect {
        CGRect(x: CGFloat(x) * Self.size,
               y: CGFloat(y) * Self.size,
               width: Self.size,
               height: Self.size)
    }

    var center: CGPoint { CGPoint(x: rect.midX, y: rect.midY) }
}

enum WorldLayerSeed: UInt64 {
    case biome = 1
    case reef = 2
    case kelp = 3
    case rocks = 4
    case particles = 5
    case current = 6
    case macroform = 7
}

enum WorldSeed {
    static let value: UInt64 = 123_456_789

    static func seedForChunk(_ coord: WorldChunkCoord, layer: WorldLayerSeed) -> UInt64 {
        var value = Self.value
        value ^= UInt64(bitPattern: Int64(coord.x)) &* 0x9E3779B97F4A7C15
        value ^= UInt64(bitPattern: Int64(coord.y)) &* 0xBF58476D1CE4E5B9
        value ^= layer.rawValue &* 0x94D049BB133111EB
        return value
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xA24BAED4963EE407 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func nextCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let unit = CGFloat(Double(next()) / Double(UInt64.max))
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }

    mutating func chance(_ probability: CGFloat) -> Bool {
        nextCGFloat(in: 0...1) <= probability
    }
}

enum WorldStampKind: UInt64 {
    case rockBase = 1
    case kelpRibbon = 2
    case kelpBlade = 3
    case kelpBush = 4
    case coralFan = 5
    case coralBranch = 6
    case coralTube = 7
    case spongePatch = 8
    case crystalCluster = 9
    case ventStack = 10
    case ruinShard = 11
    case currentRibbon = 12
    case macroform = 13
    case reefSkirt = 14
}

struct WorldTextureKey: Hashable {
    let kindRaw: UInt64
    let zoneRaw: Int
    let biomeRaw: UInt64
    let variant: Int
}
