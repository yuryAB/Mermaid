//
//  FishSystem.swift
//  Ester
//
//  Peixes ambientais procedurais: vivem em rotas próprias, formam
//  cardumes, fogem da sereia e brilham nas zonas escuras.
//  Desenhados apenas com SKShapeNode.
//

import Foundation
import SpriteKit
import GameplayKit

// MARK: - Sistema

final class FishSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var fishes: [FishNode] = []
    private var spawnTimer: CGFloat = 1

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    private func desiredCount(for zone: DepthZone) -> Int {
        switch zone {
        case .surface: return 5
        case .clear: return 8
        case .shallow: return 9
        case .mid: return 8
        case .blue: return 7
        case .deep: return 5
        case .abyss: return 4
        }
    }

    func update(dt: CGFloat) {
        let mermaidPos = ctx.mermaidPosition
        for fish in fishes {
            fish.update(dt: dt, mermaidPosition: mermaidPos)
        }
        fishes.removeAll { fish in
            if fish.position.distance(to: mermaidPos) > 3600 {
                fish.removeFromParent()
                if let em = ctx.entityManager, let entity = fish.entity {
                    em.removeEntity(entity)
                }
                return true
            }
            return false
        }

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = .random(in: 1.4...3.4)
            let zone = DepthZone.zone(atY: mermaidPos.y)
            let nearby = fishes.filter { $0.zone == zone }.count
            if nearby < desiredCount(for: zone) {
                if Int.random(in: 0..<10) < 4 {
                    spawnSchool(zone: zone, near: mermaidPos)
                } else {
                    spawnFish(zone: zone, near: mermaidPos)
                }
            }
        }
    }

    @discardableResult
    func spawnFish(zone: DepthZone, near point: CGPoint, rare: Bool = false) -> FishNode? {
        guard let world = worldNode else { return nil }
        let region = ctx.regions.currentRegion
        let regionPalette = region.flatMap { RegionDiscoverySystem.fishPalette(for: $0.id) }
        let species = region.flatMap { RegionDiscoverySystem.randomSpecies(for: $0.id, zone: zone) }
        let fish = FishNode(zone: zone, rare: rare, palette: regionPalette, species: species)
        let range = zone.yRange
        let yRange = (range.lowerBound + 80)...(range.upperBound - 80)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 780...1500)
        let spawnPosition = CGPoint(
            x: (point.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (point.y + sin(angle) * distance).clamped(to: yRange)
        )
        fish.position = spawnPosition
        fish.alpha = 0
        fish.run(.fadeIn(withDuration: 0.8))
        world.addChild(fish)
        fishes.append(fish)
        if let em = ctx.entityManager, let entity = fish.entity {
            em.addEntity(entity)
        }
        ctx.challenges?.decorateSpawn(fish)
        return fish
    }

    private func spawnSchool(zone: DepthZone, near point: CGPoint) {
        guard let leader = spawnFish(zone: zone, near: point) else { return }
        let count = Int.random(in: 3...6)
        for _ in 0..<count {
            guard let member = spawnFish(zone: zone, near: point) else { continue }
            let range = (zone.yRange.lowerBound + 80)...(zone.yRange.upperBound - 80)
            let candidate = leader.position + CGPoint(x: .random(in: -120...120),
                                                      y: .random(in: -80...80))
            let xRange = ctx.activeRegion?.playableXRange ?? (World.minX...World.maxX)
            member.position = CGPoint(x: candidate.x.clamped(to: xRange),
                                      y: candidate.y.clamped(to: range))
            member.heading = leader.heading
            member.baseSpeed = leader.baseSpeed * CGFloat.random(in: 0.9...1.1)
            member.skittish = leader.skittish
        }
    }

    func nearestFish(to point: CGPoint, maxDistance: CGFloat, includeBusy: Bool = false) -> FishNode? {
        fishes
            .filter {
                (includeBusy || $0.isAvailableForCompanionAction)
                    && $0.position.distance(to: point) <= maxDistance
            }
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
    }

    /// Reação do peixe quando a sereia interage: um giro alegre + bolhinhas.
    func interact(_ fish: FishNode) {
        let circle = SKAction.sequence([
            .rotate(byAngle: .pi * 2, duration: 0.8),
            .rotate(toAngle: 0, duration: 0.1)
        ])
        circle.eaeInEaseOut()
        fish.run(circle)

        let sparkle = SKShapeNode(circleOfRadius: 4)
        sparkle.fillColor = .white
        sparkle.strokeColor = .clear
        sparkle.glowWidth = 6
        sparkle.position = fish.position + CGPoint(x: 0, y: 40)
        fish.parent?.addChild(sparkle)
        sparkle.run(.sequence([
            .group([.moveBy(x: 0, y: 60, duration: 0.9), .fadeOut(withDuration: 0.9)]),
            .removeFromParent()
        ]))
        fish.heading = fish.heading + .pi
    }
}
