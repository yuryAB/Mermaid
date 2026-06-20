//
//  WorldChunkFactory.swift
//  Ester
//
//  Montagem visual de um chunk procedural do oceano.
//

import Foundation
import SpriteKit

enum WorldChunkFactory {
    private struct ReefCluster {
        let node: SKNode
        let terrainFootprint: CGSize
    }

    private struct PlacedReefCluster {
        let position: CGPoint
        let terrainFootprint: CGSize
        let scale: CGFloat
    }

    static func makeChunk(_ coord: WorldChunkCoord) -> SKNode {
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

    private static func addMacroforms(to node: SKNode,
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
            let texture = WorldTextureCache.shared.texture(kind: .macroform,
                                                           zone: zone,
                                                           biome: biome,
                                                           variant: rng.nextInt(in: 0...5))
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: rng.nextCGFloat(in: 520...1120),
                                 height: rng.nextCGFloat(in: 190...560))
            sprite.position = randomPoint(in: coord.rect, margin: 220, rng: &rng)
            sprite.zPosition = -34
            sprite.alpha = WorldVisualPalette.macroAlpha(for: zone)
            sprite.zRotation = rng.nextCGFloat(in: -0.18...0.18)
            sprite.blendMode = .alpha
            node.addChild(sprite)
        }
    }

    private static func addCurrents(to node: SKNode,
                             coord: WorldChunkCoord,
                             zone: DepthZone,
                             biome: AquaticBiome) {
        guard zone != .surface else { return }
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .current))
        let baseCount = biome == .openWater ? 3 : 2
        let count = zone == .deep || zone == .abyss ? max(1, baseCount - 1) : baseCount

        for _ in 0..<count {
            let texture = WorldTextureCache.shared.texture(kind: .currentRibbon,
                                                           zone: zone,
                                                           biome: biome,
                                                           variant: rng.nextInt(in: 0...4))
            let ribbon = SKSpriteNode(texture: texture)
            ribbon.size = CGSize(width: rng.nextCGFloat(in: 540...1120),
                                 height: rng.nextCGFloat(in: 46...76))
            ribbon.position = randomPoint(in: coord.rect, margin: 140, rng: &rng)
            ribbon.zPosition = -10
            ribbon.alpha = rng.nextCGFloat(in: 0.16...0.34)
            ribbon.zRotation = rng.nextCGFloat(in: -0.18...0.18)
            ribbon.blendMode = zone == .deep || zone == .abyss ? .add : .alpha
            node.addChild(ribbon)
        }
    }

    private static func addReefs(to node: SKNode,
                                 coord: WorldChunkCoord,
                                 zone: DepthZone,
                                 biome: AquaticBiome) {
        var rng = SeededGenerator(seed: WorldSeed.seedForChunk(coord, layer: .reef))
        let density = reefDensity(for: zone, biome: biome, rng: &rng)
        let count = Int((density * 7).rounded())
        guard count > 0 else { return }

        var placedClusters: [PlacedReefCluster] = []
        var placedCount = 0
        var attempts = 0
        let maxAttempts = max(12, count * 12)

        while placedCount < count && attempts < maxAttempts {
            attempts += 1
            let cluster = makeReefCluster(zone: zone, biome: biome, rng: &rng)
            let scale = rng.nextCGFloat(in: 0.72...1.45)
            guard let position = reefClusterPosition(for: cluster,
                                                     scale: scale,
                                                     in: coord.rect,
                                                     placedClusters: placedClusters,
                                                     rng: &rng) else {
                continue
            }

            cluster.node.position = position
            cluster.node.zPosition = reefClusterZPosition(for: position, in: coord.rect, rng: &rng)
            cluster.node.setScale(scale)
            node.addChild(cluster.node)
            placedClusters.append(PlacedReefCluster(position: position,
                                                    terrainFootprint: cluster.terrainFootprint,
                                                    scale: scale))
            placedCount += 1
        }
    }

    private static func reefClusterPosition(for cluster: ReefCluster,
                                            scale: CGFloat,
                                            in rect: CGRect,
                                            placedClusters: [PlacedReefCluster],
                                            rng: inout SeededGenerator) -> CGPoint? {
        let horizontalMargin = min(rect.width * 0.44,
                                   max(180, cluster.terrainFootprint.width * scale * 0.58))
        let verticalMargin = min(rect.height * 0.44,
                                 max(180, cluster.terrainFootprint.height * scale * 0.78))

        for _ in 0..<12 {
            let position = CGPoint(x: rng.nextCGFloat(in: (rect.minX + horizontalMargin)...(rect.maxX - horizontalMargin)),
                                   y: rng.nextCGFloat(in: (rect.minY + verticalMargin)...(rect.maxY - verticalMargin)))
            if !hasVerticalConflict(position: position,
                                    terrainFootprint: cluster.terrainFootprint,
                                    scale: scale,
                                    placedClusters: placedClusters) {
                return position
            }
        }

        return nil
    }

    private static func hasVerticalConflict(position: CGPoint,
                                            terrainFootprint: CGSize,
                                            scale: CGFloat,
                                            placedClusters: [PlacedReefCluster]) -> Bool {
        let candidateHeight = terrainFootprint.height * scale
        for placed in placedClusters {
            let placedHeight = placed.terrainFootprint.height * placed.scale
            let minimumVerticalGap = max(CGFloat(230), (candidateHeight + placedHeight) * 0.70)
            if abs(position.y - placed.position.y) < minimumVerticalGap {
                return true
            }
        }
        return false
    }

    private static func reefClusterZPosition(for position: CGPoint,
                                             in rect: CGRect,
                                             rng: inout SeededGenerator) -> CGFloat {
        let depthInChunk = ((rect.maxY - position.y) / rect.height).clamped(to: 0...1)
        return -6 + depthInChunk * 4 + rng.nextCGFloat(in: -0.18...0.18)
    }

    private static func addAmbientEmitters(to node: SKNode,
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

    private static func makeReefCluster(zone: DepthZone,
                                        biome: AquaticBiome,
                                        rng: inout SeededGenerator) -> ReefCluster {
        let cluster = SKNode()
        let baseSize = CGSize(width: rng.nextCGFloat(in: 170...380),
                              height: rng.nextCGFloat(in: 58...112))
        var terrainWidth = baseSize.width
        var terrainHeight = baseSize.height * 1.65
        let rock = makeRockSprite(zone: zone, biome: biome, size: baseSize, rng: &rng)
        rock.alpha = rng.nextCGFloat(in: 0.54...0.82)
        rock.zRotation = rng.nextCGFloat(in: -0.08...0.08)
        rock.zPosition = -2
        cluster.addChild(rock)

        let skirt = makeReefSkirtSprite(zone: zone, biome: biome, size: baseSize, rng: &rng)
        skirt.position = CGPoint(x: 0,
                                 y: -baseSize.height * rng.nextCGFloat(in: 0.02...0.12))
        skirt.zRotation = rock.zRotation + rng.nextCGFloat(in: -0.025...0.025)
        skirt.zPosition = -1.55
        cluster.addChild(skirt)

        if rng.chance(0.38) {
            let shelfSize = CGSize(width: baseSize.width * rng.nextCGFloat(in: 0.46...0.72),
                                   height: baseSize.height * rng.nextCGFloat(in: 0.56...0.78))
            let shelfSide: CGFloat = rng.chance(0.5) ? -1 : 1
            let shelf = makeRockSprite(zone: zone,
                                       biome: biome,
                                       size: shelfSize,
                                       rng: &rng)
            shelf.position = CGPoint(x: shelfSide * rng.nextCGFloat(in: baseSize.width * 0.34...baseSize.width * 0.52),
                                     y: -baseSize.height * rng.nextCGFloat(in: 0.02...0.12))
            shelf.zRotation = rng.nextCGFloat(in: -0.11...0.11)
            shelf.zPosition = -2.35
            shelf.alpha = rng.nextCGFloat(in: 0.34...0.54)
            cluster.addChild(shelf)
            terrainWidth = max(terrainWidth, abs(shelf.position.x) * 2 + shelfSize.width)
            terrainHeight = max(terrainHeight, baseSize.height + shelfSize.height * 0.82)

            if rng.chance(0.64) {
                let shelfSkirt = makeReefSkirtSprite(zone: zone, biome: biome, size: shelfSize, rng: &rng)
                shelfSkirt.position = CGPoint(x: shelf.position.x,
                                              y: shelf.position.y - shelfSize.height * rng.nextCGFloat(in: 0.05...0.16))
                shelfSkirt.zRotation = shelf.zRotation + rng.nextCGFloat(in: -0.025...0.025)
                shelfSkirt.zPosition = -2.05
                shelfSkirt.alpha *= 0.76
                cluster.addChild(shelfSkirt)
            }
        }

        let kelpCount = kelpCount(for: zone, biome: biome, rng: &rng)
        for _ in 0..<kelpCount {
            let kelp = makeKelpSprite(zone: zone, baseSize: baseSize, rng: &rng)
            let x = plantingX(for: kelp, baseSize: baseSize, rng: &rng)
            let surfaceY = plantingSurfaceY(localX: x, baseSize: baseSize, rng: &rng)
            kelp.position = CGPoint(x: x,
                                    y: surfaceY - rootSink(for: kelp, rng: &rng))
            kelp.zPosition = rng.nextCGFloat(in: -1...2)
            cluster.addChild(kelp)
        }

        let detailCount = detailCount(for: zone, biome: biome, rng: &rng)
        for _ in 0..<detailCount {
            let detail = makeDetailSprite(zone: zone, biome: biome, baseSize: baseSize, rng: &rng)
            let x = plantingX(for: detail, baseSize: baseSize, rng: &rng)
            let surfaceY = plantingSurfaceY(localX: x, baseSize: baseSize, rng: &rng)
            detail.position = CGPoint(x: x,
                                      y: surfaceY - rootSink(for: detail, rng: &rng))
            detail.zPosition = 2
            cluster.addChild(detail)
        }

        return ReefCluster(node: cluster,
                           terrainFootprint: CGSize(width: terrainWidth,
                                                    height: terrainHeight))
    }

    private static func makeRockSprite(zone: DepthZone,
                                       biome: AquaticBiome,
                                       size: CGSize,
                                       rng: inout SeededGenerator) -> SKSpriteNode {
        let texture = WorldTextureCache.shared.texture(kind: .rockBase,
                                                       zone: zone,
                                                       biome: biome,
                                                       variant: rng.nextInt(in: 0...7))
        let rock = SKSpriteNode(texture: texture)
        rock.size = size
        rock.anchorPoint = CGPoint(x: 0.5, y: 0.24)
        return rock
    }

    private static func makeReefSkirtSprite(zone: DepthZone,
                                            biome: AquaticBiome,
                                            size: CGSize,
                                            rng: inout SeededGenerator) -> SKSpriteNode {
        let texture = WorldTextureCache.shared.texture(kind: .reefSkirt,
                                                       zone: zone,
                                                       biome: biome,
                                                       variant: rng.nextInt(in: 0...11))
        let skirt = SKSpriteNode(texture: texture)
        skirt.size = CGSize(width: size.width * rng.nextCGFloat(in: 0.92...1.10),
                            height: max(44, size.height * rng.nextCGFloat(in: 0.62...0.96)))
        skirt.anchorPoint = CGPoint(x: 0.5, y: 0.82)
        skirt.alpha = rng.nextCGFloat(in: 0.48...0.78)
        skirt.blendMode = .alpha
        return skirt
    }

    private static func makeKelpSprite(zone: DepthZone,
                                       baseSize: CGSize,
                                       rng: inout SeededGenerator) -> SKSpriteNode {
        let height = WorldVisualPalette.kelpHeight(for: zone) * rng.nextCGFloat(in: 0.65...1.18)
        let kind: WorldStampKind
        let roll = rng.nextCGFloat(in: 0...1)
        if roll < 0.34 {
            kind = .kelpRibbon
        } else if roll < 0.68 {
            kind = .kelpBlade
        } else {
            kind = .kelpBush
        }
        let texture = WorldTextureCache.shared.texture(kind: kind,
                                                       zone: zone,
                                                       biome: .kelpForest,
                                                       variant: rng.nextInt(in: 0...9))
        let kelp = SKSpriteNode(texture: texture)
        kelp.size = CGSize(width: height * rng.nextCGFloat(in: 0.24...0.48),
                           height: height)
        kelp.anchorPoint = CGPoint(x: 0.5, y: rootAnchorY(for: kind))
        fitPlantSprite(kelp, kind: kind, baseSize: baseSize)
        kelp.alpha = rng.nextCGFloat(in: 0.58...0.86)
        kelp.zRotation = rng.nextCGFloat(in: -0.12...0.12)
        if rng.chance(0.55) {
            let start = kelp.zRotation
            let left = SKAction.rotate(toAngle: start - rng.nextCGFloat(in: 0.025...0.07),
                                       duration: TimeInterval(rng.nextCGFloat(in: 2.4...4.6)))
            let right = SKAction.rotate(toAngle: start + rng.nextCGFloat(in: 0.025...0.07),
                                        duration: TimeInterval(rng.nextCGFloat(in: 2.4...4.6)))
            left.eaeInEaseOut()
            right.eaeInEaseOut()
            kelp.run(.repeatForever(.sequence([left, right])))
        }
        return kelp
    }

    private static func makeDetailSprite(zone: DepthZone,
                                         biome: AquaticBiome,
                                         baseSize: CGSize,
                                         rng: inout SeededGenerator) -> SKSpriteNode {
        let kind = detailStampKind(for: zone, biome: biome, rng: &rng)
        let texture = WorldTextureCache.shared.texture(kind: kind,
                                                       zone: zone,
                                                       biome: biome,
                                                       variant: rng.nextInt(in: 0...11))
        let detail = SKSpriteNode(texture: texture)
        detail.size = detailSize(for: kind, zone: zone, biome: biome, rng: &rng)
        detail.anchorPoint = CGPoint(x: 0.5, y: rootAnchorY(for: kind))
        fitPlantSprite(detail, kind: kind, baseSize: baseSize)
        detail.alpha = rng.nextCGFloat(in: 0.58...0.90)
        detail.zRotation = rng.nextCGFloat(in: -0.22...0.22)
        if kind == .crystalCluster || kind == .ventStack || zone == .deep || zone == .abyss {
            detail.blendMode = .add
            detail.alpha *= kind == .ventStack ? 0.86 : 0.72
        }
        return detail
    }

    private static func fitPlantSprite(_ sprite: SKSpriteNode,
                                       kind: WorldStampKind,
                                       baseSize: CGSize) {
        let widthRatio: CGFloat
        let heightRatio: CGFloat
        switch kind {
        case .kelpRibbon, .kelpBlade, .kelpBush:
            widthRatio = 0.34
            heightRatio = 2.55
        case .coralFan, .coralBranch:
            widthRatio = 0.40
            heightRatio = 1.85
        case .coralTube, .spongePatch:
            widthRatio = 0.44
            heightRatio = 1.55
        case .crystalCluster, .ventStack, .ruinShard:
            widthRatio = 0.42
            heightRatio = 2.10
        default:
            widthRatio = 0.40
            heightRatio = 1.80
        }

        let maxWidth = max(36, baseSize.width * widthRatio)
        let maxHeight = max(54, baseSize.height * heightRatio)
        let widthScale = maxWidth / max(1, sprite.size.width)
        let heightScale = maxHeight / max(1, sprite.size.height)
        let scale = min(1, widthScale, heightScale)
        if scale < 1 {
            sprite.size = CGSize(width: sprite.size.width * scale,
                                 height: sprite.size.height * scale)
        }
    }

    private static func plantingX(for sprite: SKSpriteNode,
                                  baseSize: CGSize,
                                  rng: inout SeededGenerator) -> CGFloat {
        let plantableHalfWidth = baseSize.width * 0.40
        let horizontalClearance = max(18, sprite.size.width * 0.56 + sprite.size.height * 0.08)
        let maxAbsX = max(0, plantableHalfWidth - horizontalClearance)
        guard maxAbsX > 1 else {
            return rng.nextCGFloat(in: -baseSize.width * 0.035...baseSize.width * 0.035)
        }
        return rng.nextCGFloat(in: -maxAbsX...maxAbsX)
    }

    private static func plantingSurfaceY(localX: CGFloat,
                                         baseSize: CGSize,
                                         rng: inout SeededGenerator) -> CGFloat {
        let halfWidth = max(1, baseSize.width * 0.5)
        let edgeAmount = (abs(localX) / halfWidth).clamped(to: 0...1)
        let dome = 1 - pow(edgeAmount, 1.65)
        let ripple = sin((localX / max(1, baseSize.width)) * .pi * 3) * baseSize.height * 0.025
        let jitter = rng.nextCGFloat(in: -0.025...0.025) * baseSize.height
        let y = baseSize.height * (0.07 + 0.26 * dome) + ripple + jitter
        return y.clamped(to: baseSize.height * 0.03...baseSize.height * 0.34)
    }

    private static func rootSink(for sprite: SKSpriteNode,
                                 rng: inout SeededGenerator) -> CGFloat {
        min(14, sprite.size.height * rng.nextCGFloat(in: 0.030...0.060))
    }

    private static func rootAnchorY(for kind: WorldStampKind) -> CGFloat {
        switch kind {
        case .kelpRibbon, .kelpBlade, .kelpBush:
            return 0.06
        case .coralFan:
            return 0.12
        case .coralBranch:
            return 0.10
        case .coralTube:
            return 0.09
        case .spongePatch:
            return 0.10
        case .crystalCluster:
            return 0.10
        case .ventStack:
            return 0.08
        case .ruinShard:
            return 0.10
        default:
            return 0.08
        }
    }

    private static func detailStampKind(for zone: DepthZone,
                                 biome: AquaticBiome,
                                 rng: inout SeededGenerator) -> WorldStampKind {
        switch biome {
        case .deepVents:
            return rng.chance(0.72) ? .ventStack : .crystalCluster
        case .crystalField:
            return rng.chance(0.78) ? .crystalCluster : .spongePatch
        case .ancientRuins:
            return rng.chance(0.64) ? .ruinShard : .crystalCluster
        case .cavernMouth:
            if rng.chance(0.48) { return .ruinShard }
            return zone == .deep || zone == .abyss ? .crystalCluster : .spongePatch
        case .kelpForest:
            if rng.chance(0.46) { return .spongePatch }
            return rng.chance(0.42) ? .coralTube : .coralBranch
        case .coralGarden, .reefWall:
            let roll = rng.nextCGFloat(in: 0...1)
            if roll < 0.36 { return .coralFan }
            if roll < 0.66 { return .coralBranch }
            if roll < 0.84 { return .coralTube }
            return .spongePatch
        case .openWater, .abyssPlain:
            if zone == .deep || zone == .abyss { return rng.chance(0.45) ? .crystalCluster : .ruinShard }
            return rng.chance(0.54) ? .spongePatch : .coralTube
        }
    }

    private static func detailSize(for kind: WorldStampKind,
                            zone: DepthZone,
                            biome: AquaticBiome,
                            rng: inout SeededGenerator) -> CGSize {
        switch kind {
        case .coralFan:
            return CGSize(width: rng.nextCGFloat(in: 74...138),
                          height: rng.nextCGFloat(in: 82...150))
        case .coralBranch:
            return CGSize(width: rng.nextCGFloat(in: 58...112),
                          height: rng.nextCGFloat(in: 86...172))
        case .coralTube:
            return CGSize(width: rng.nextCGFloat(in: 62...122),
                          height: rng.nextCGFloat(in: 64...132))
        case .spongePatch:
            return CGSize(width: rng.nextCGFloat(in: 64...128),
                          height: rng.nextCGFloat(in: 48...96))
        case .crystalCluster:
            let boost: CGFloat = biome == .crystalField ? 1.25 : 1
            return CGSize(width: rng.nextCGFloat(in: 54...104) * boost,
                          height: rng.nextCGFloat(in: 92...180) * boost)
        case .ventStack:
            return CGSize(width: rng.nextCGFloat(in: 70...132),
                          height: rng.nextCGFloat(in: 112...210))
        case .ruinShard:
            return CGSize(width: rng.nextCGFloat(in: 70...150),
                          height: rng.nextCGFloat(in: 92...210))
        default:
            return CGSize(width: rng.nextCGFloat(in: 54...110),
                          height: rng.nextCGFloat(in: 60...130))
        }
    }

    private static func reefDensity(for zone: DepthZone,
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

    private static func kelpCount(for zone: DepthZone,
                           biome: AquaticBiome,
                           rng: inout SeededGenerator) -> Int {
        let maxCount = biome == .kelpForest ? 7 : 4
        if zone == .deep || zone == .abyss { return rng.nextInt(in: 0...2) }
        return rng.nextInt(in: 1...maxCount)
    }

    private static func detailCount(for zone: DepthZone,
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

    private static func randomPoint(in rect: CGRect,
                             margin: CGFloat,
                             rng: inout SeededGenerator) -> CGPoint {
        CGPoint(x: rng.nextCGFloat(in: (rect.minX + margin)...(rect.maxX - margin)),
                y: rng.nextCGFloat(in: (rect.minY + margin)...(rect.maxY - margin)))
    }
}
