//
//  WorldEnvironmentSystem.swift
//  Ester
//
//  Streaming visual do oceano: chunks seedados por coordenada para manter
//  o mundo grande sem deixar milhares de nos vivos longe da camera.
//

import Foundation
import SpriteKit
import UIKit

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

final class WorldChunkManager {
    private let rootNode = SKNode()
    private let activeRadius = 2
    private var chunks: [WorldChunkCoord: SKNode] = [:]
    private var updateAccumulator: CGFloat = 0
    private var lastCenter: WorldChunkCoord?

    init(parent: SKNode) {
        rootNode.zPosition = -12
        parent.addChild(rootNode)
    }

    func update(dt: CGFloat, cameraPosition: CGPoint) {
        updateAccumulator += dt
        let center = WorldChunkCoord.chunkCoord(for: cameraPosition)
        guard center != lastCenter || updateAccumulator >= 0.35 else { return }
        updateAccumulator = 0
        lastCenter = center

        var needed = Set<WorldChunkCoord>()
        for dx in -activeRadius...activeRadius {
            for dy in -activeRadius...activeRadius {
                let coord = WorldChunkCoord(x: center.x + dx, y: center.y + dy)
                guard coord.rect.maxX >= World.minX,
                      coord.rect.minX <= World.maxX,
                      coord.rect.maxY >= World.floorY,
                      coord.rect.minY <= World.surfaceTopY else { continue }
                needed.insert(coord)
            }
        }

        for coord in Array(chunks.keys) where !needed.contains(coord) {
            chunks.removeValue(forKey: coord)?.removeFromParent()
        }

        for coord in needed where chunks[coord] == nil {
            let node = makeChunk(coord)
            chunks[coord] = node
            rootNode.addChild(node)
        }
    }

    private func makeChunk(_ coord: WorldChunkCoord) -> SKNode {
        let node = SKNode()
        node.name = "world_chunk_\(coord.x)_\(coord.y)"
        node.zPosition = CGFloat((coord.x ^ coord.y) % 5) - 2

        let zone = DepthZone.zone(atY: coord.center.y)
        let biome = AquaticBiome.biome(at: coord.center, zone: zone)
        addMacroforms(to: node, coord: coord, zone: zone, biome: biome)
        addCurrents(to: node, coord: coord, zone: zone, biome: biome)
        addReefs(to: node, coord: coord, zone: zone, biome: biome)
        addAmbientEmitters(to: node, coord: coord, zone: zone, biome: biome)
        return node
    }

    private func addMacroforms(to node: SKNode,
                               coord: WorldChunkCoord,
                               zone: DepthZone,
                               biome: AquaticBiome) {
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .macroform))
        let count: Int
        switch biome {
        case .openWater:
            count = rng.chance(0.25) ? 1 : 0
        case .abyssPlain:
            count = rng.chance(0.42) ? 1 : 0
        case .ancientRuins, .cavernMouth, .reefWall:
            count = rng.nextInt(in: 1...2)
        default:
            count = rng.chance(0.34) ? 1 : 0
        }

        for _ in 0..<count {
            let sprite = SKSpriteNode(color: WorldVisualPalette.macroColor(for: zone, biome: biome),
                                      size: CGSize(width: rng.nextCGFloat(in: 420...980),
                                                   height: rng.nextCGFloat(in: 160...520)))
            sprite.position = randomPoint(in: coord.rect, margin: 220, rng: &rng)
            sprite.zPosition = -34
            sprite.alpha = WorldVisualPalette.macroAlpha(for: zone)
            sprite.zRotation = rng.nextCGFloat(in: -0.18...0.18)
            sprite.blendMode = .alpha
            node.addChild(sprite)
        }
    }

    private func addCurrents(to node: SKNode,
                             coord: WorldChunkCoord,
                             zone: DepthZone,
                             biome: AquaticBiome) {
        guard zone != .surface else { return }
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .current))
        let baseCount = biome == .openWater ? 3 : 2
        let count = zone == .deep || zone == .abyss ? max(1, baseCount - 1) : baseCount

        for _ in 0..<count {
            let ribbon = SKSpriteNode(color: WorldVisualPalette.currentColor(for: zone),
                                      size: CGSize(width: rng.nextCGFloat(in: 460...980),
                                                   height: rng.nextCGFloat(in: 5...11)))
            ribbon.position = randomPoint(in: coord.rect, margin: 140, rng: &rng)
            ribbon.zPosition = -10
            ribbon.alpha = rng.nextCGFloat(in: 0.10...0.22)
            ribbon.zRotation = rng.nextCGFloat(in: -0.18...0.18)
            node.addChild(ribbon)
        }
    }

    private func addReefs(to node: SKNode,
                          coord: WorldChunkCoord,
                          zone: DepthZone,
                          biome: AquaticBiome) {
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .reef))
        let density = reefDensity(for: zone, biome: biome, rng: &rng)
        let count = Int((density * 7).rounded())
        guard count > 0 else { return }

        for _ in 0..<count {
            let cluster = makeReefCluster(zone: zone, biome: biome, rng: &rng)
            cluster.position = randomPoint(in: coord.rect, margin: 180, rng: &rng)
            cluster.zPosition = rng.nextCGFloat(in: -6...2)
            cluster.setScale(rng.nextCGFloat(in: 0.72...1.45))
            node.addChild(cluster)
        }
    }

    private func addAmbientEmitters(to node: SKNode,
                                    coord: WorldChunkCoord,
                                    zone: DepthZone,
                                    biome: AquaticBiome) {
        guard zone != .surface else { return }
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .particles))
        let emitter = SKEmitterNode()
        emitter.particleTexture = WorldTextureCache.shared.softDot
        emitter.particleBirthRate = WorldVisualPalette.particleBirthRate(for: zone, biome: biome)
        emitter.particleLifetime = rng.nextCGFloat(in: 16...32)
        emitter.particleLifetimeRange = emitter.particleLifetime * 0.3
        emitter.particlePositionRange = CGVector(dx: WorldChunkCoord.size, dy: WorldChunkCoord.size)
        emitter.particleSpeed = rng.nextCGFloat(in: 4...18)
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = rng.nextCGFloat(in: 0.04...0.12)
        emitter.particleScaleRange = 0.05
        emitter.particleAlpha = WorldVisualPalette.particleAlpha(for: zone)
        emitter.particleAlphaRange = 0.12
        emitter.particleColor = WorldVisualPalette.particleColor(for: zone, biome: biome)
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = zone == .deep || zone == .abyss ? .add : .alpha
        emitter.position = coord.center
        emitter.zPosition = 4
        node.addChild(emitter)
        emitter.advanceSimulationTime(TimeInterval(emitter.particleLifetime * 0.45))
    }

    private func makeReefCluster(zone: DepthZone,
                                 biome: AquaticBiome,
                                 rng: inout SeededGenerator) -> SKNode {
        let cluster = SKNode()
        let baseSize = CGSize(width: rng.nextCGFloat(in: 130...340),
                              height: rng.nextCGFloat(in: 28...78))
        let rock = SKSpriteNode(color: WorldVisualPalette.rockColor(for: zone),
                                size: baseSize)
        rock.alpha = rng.nextCGFloat(in: 0.42...0.68)
        rock.zRotation = rng.nextCGFloat(in: -0.08...0.08)
        rock.zPosition = -2
        cluster.addChild(rock)

        let kelpCount = kelpCount(for: zone, biome: biome, rng: &rng)
        for _ in 0..<kelpCount {
            let kelp = makeKelpSprite(zone: zone, rng: &rng)
            kelp.position = CGPoint(x: rng.nextCGFloat(in: -baseSize.width * 0.45...baseSize.width * 0.45),
                                    y: baseSize.height * 0.25)
            kelp.zPosition = rng.nextCGFloat(in: -1...2)
            cluster.addChild(kelp)
        }

        let detailCount = detailCount(for: zone, biome: biome, rng: &rng)
        for _ in 0..<detailCount {
            let detail = makeDetailSprite(zone: zone, biome: biome, rng: &rng)
            detail.position = CGPoint(x: rng.nextCGFloat(in: -baseSize.width * 0.42...baseSize.width * 0.42),
                                      y: baseSize.height * 0.28)
            detail.zPosition = 2
            cluster.addChild(detail)
        }

        return cluster
    }

    private func makeKelpSprite(zone: DepthZone, rng: inout SeededGenerator) -> SKSpriteNode {
        let height = WorldVisualPalette.kelpHeight(for: zone) * rng.nextCGFloat(in: 0.65...1.18)
        let width = rng.nextCGFloat(in: 12...24)
        let kelp = SKSpriteNode(color: WorldVisualPalette.kelpColor(for: zone),
                                size: CGSize(width: width, height: height))
        kelp.anchorPoint = CGPoint(x: 0.5, y: 0)
        kelp.alpha = rng.nextCGFloat(in: 0.42...0.72)
        kelp.zRotation = rng.nextCGFloat(in: -0.12...0.12)
        return kelp
    }

    private func makeDetailSprite(zone: DepthZone,
                                  biome: AquaticBiome,
                                  rng: inout SeededGenerator) -> SKSpriteNode {
        let isCrystal = zone == .deep || zone == .abyss || biome == .crystalField
        let size = isCrystal
            ? CGSize(width: rng.nextCGFloat(in: 16...38), height: rng.nextCGFloat(in: 44...110))
            : CGSize(width: rng.nextCGFloat(in: 26...64), height: rng.nextCGFloat(in: 22...58))
        let detail = SKSpriteNode(color: WorldVisualPalette.detailColor(for: zone, biome: biome),
                                  size: size)
        detail.anchorPoint = CGPoint(x: 0.5, y: 0)
        detail.alpha = rng.nextCGFloat(in: 0.45...0.76)
        detail.zRotation = rng.nextCGFloat(in: -0.22...0.22)
        if zone == .deep || zone == .abyss || biome == .deepVents {
            detail.blendMode = .add
            detail.alpha *= 0.75
        }
        return detail
    }

    private func reefDensity(for zone: DepthZone,
                             biome: AquaticBiome,
                             rng: inout SeededGenerator) -> CGFloat {
        let zoneBase: CGFloat
        switch zone {
        case .surface:
            zoneBase = 0
        case .clear:
            zoneBase = 0.24
        case .shallow:
            zoneBase = 0.62
        case .mid:
            zoneBase = 0.52
        case .blue:
            zoneBase = 0.18
        case .deep:
            zoneBase = 0.34
        case .abyss:
            zoneBase = 0.16
        }

        let biomeBoost: CGFloat
        switch biome {
        case .coralGarden, .reefWall:
            biomeBoost = 0.32
        case .kelpForest, .crystalField, .deepVents:
            biomeBoost = 0.22
        case .ancientRuins, .cavernMouth:
            biomeBoost = 0.12
        case .openWater, .abyssPlain:
            biomeBoost = -0.16
        }

        return (zoneBase + biomeBoost + rng.nextCGFloat(in: -0.18...0.18)).clamped(to: 0...1)
    }

    private func kelpCount(for zone: DepthZone,
                           biome: AquaticBiome,
                           rng: inout SeededGenerator) -> Int {
        let maxCount = biome == .kelpForest ? 7 : 4
        if zone == .deep || zone == .abyss { return rng.nextInt(in: 0...2) }
        return rng.nextInt(in: 1...maxCount)
    }

    private func detailCount(for zone: DepthZone,
                             biome: AquaticBiome,
                             rng: inout SeededGenerator) -> Int {
        switch biome {
        case .openWater, .abyssPlain:
            return rng.nextInt(in: 0...2)
        case .coralGarden, .crystalField, .deepVents:
            return rng.nextInt(in: 3...6)
        default:
            return rng.nextInt(in: 2...5)
        }
    }

    private func randomPoint(in rect: CGRect,
                             margin: CGFloat,
                             rng: inout SeededGenerator) -> CGPoint {
        CGPoint(x: rng.nextCGFloat(in: (rect.minX + margin)...(rect.maxX - margin)),
                y: rng.nextCGFloat(in: (rect.minY + margin)...(rect.maxY - margin)))
    }
}

private enum WorldVisualPalette {
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

private final class WorldTextureCache {
    static let shared = WorldTextureCache()

    let softDot: SKTexture

    private init() {
        let size = CGSize(width: 32, height: 32)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let rect = CGRect(origin: .zero, size: size)
            let context = renderer.cgContext
            context.clear(rect)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(white: 1, alpha: 0.85).cgColor,
                UIColor(white: 1, alpha: 0.22).cgColor,
                UIColor(white: 1, alpha: 0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.48, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: locations) else { return }
            context.drawRadialGradient(gradient,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: size.width / 2,
                                       options: [.drawsAfterEndLocation])
        }
        softDot = SKTexture(image: image)
        softDot.filteringMode = .linear
    }
}
