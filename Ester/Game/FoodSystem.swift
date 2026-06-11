//
//  FoodSystem.swift
//  Ester
//
//  Comida procedural por bioma: surge no ambiente, tem raridade e
//  efeitos diferentes, e é desenhada só com SKShapeNode.
//

import Foundation
import SpriteKit

// MARK: - Tipos de comida

enum FoodStyle {
    case leaf       // alga
    case glow       // plâncton brilhante
    case fruit      // fruta caída
    case pearl      // concha
    case critter    // crustáceo abstrato
    case crystal    // fruto-cristal / objeto raro
}

struct FoodKind {
    let name: String
    let weight: CGFloat
    let nutrition: CGFloat
    let xp: CGFloat
    let pearls: Int
    let courage: CGFloat
    let style: FoodStyle
    let color: UIColor
}

// MARK: - Nó de comida

final class FoodNode: SKNode {
    let kind: FoodKind

    init(kind: FoodKind) {
        self.kind = kind
        super.init()
        buildShape()
        runBobbing()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildShape() {
        switch kind.style {
        case .leaf:
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addQuadCurve(to: CGPoint(x: 0, y: 70), controlPoint: CGPoint(x: 30, y: 35))
            path.addQuadCurve(to: .zero, controlPoint: CGPoint(x: -30, y: 35))
            let leaf = SKShapeNode(path: path.cgPath)
            leaf.fillColor = kind.color
            leaf.strokeColor = kind.color.withAlphaComponent(0.6)
            addChild(leaf)
        case .glow:
            let core = SKShapeNode(circleOfRadius: 14)
            core.fillColor = kind.color
            core.strokeColor = .clear
            core.glowWidth = 10
            addChild(core)
            let pulse = SKAction.repeatForever(.sequence([
                .scale(to: 1.3, duration: 0.8),
                .scale(to: 1.0, duration: 0.8)
            ]))
            pulse.eaeInEaseOut()
            core.run(pulse)
        case .fruit:
            let body = SKShapeNode(circleOfRadius: 24)
            body.fillColor = kind.color
            body.strokeColor = kind.color.withAlphaComponent(0.5)
            addChild(body)
            let stem = SKShapeNode(rect: CGRect(x: -3, y: 20, width: 6, height: 14), cornerRadius: 3)
            stem.fillColor = UIColor(red: 0.35, green: 0.5, blue: 0.2, alpha: 1)
            stem.strokeColor = .clear
            addChild(stem)
        case .pearl:
            let pearl = SKShapeNode(circleOfRadius: 16)
            pearl.fillColor = kind.color
            pearl.strokeColor = .white
            pearl.glowWidth = 6
            addChild(pearl)
            let shine = SKShapeNode(circleOfRadius: 5)
            shine.fillColor = .white
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -5, y: 6)
            shine.alpha = 0.8
            addChild(shine)
        case .critter:
            let body = SKShapeNode(ellipseOf: CGSize(width: 44, height: 26))
            body.fillColor = kind.color
            body.strokeColor = .clear
            addChild(body)
            for i in 0..<3 {
                let leg = SKShapeNode(rect: CGRect(x: -14 + CGFloat(i) * 12, y: -22, width: 3, height: 12))
                leg.fillColor = kind.color.withAlphaComponent(0.7)
                leg.strokeColor = .clear
                addChild(leg)
            }
        case .crystal:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -30))
            path.addLine(to: CGPoint(x: -18, y: 0))
            path.close()
            let crystal = SKShapeNode(path: path.cgPath)
            crystal.fillColor = kind.color
            crystal.strokeColor = .white
            crystal.glowWidth = 8
            addChild(crystal)
        }
    }

    private func runBobbing() {
        let bob = SKAction.repeatForever(.sequence([
            .moveBy(x: 0, y: 12, duration: 1.4),
            .moveBy(x: 0, y: -12, duration: 1.4)
        ]))
        bob.eaeInEaseOut()
        run(bob)
    }
}

// MARK: - Sistema

final class FoodSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var foods: [FoodNode] = []
    private var spawnTimer: CGFloat = 4
    private var pendingSpawn: CGFloat = -1

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = .random(in: 7...14)
            if foods.count < 7 {
                spawn(near: ctx.mermaidPosition)
            }
        }
        if pendingSpawn > 0 {
            pendingSpawn -= dt
            if pendingSpawn <= 0 {
                spawn(near: ctx.mermaidPosition, maxDistance: 500)
            }
        }
        // remove comida muito distante
        foods.removeAll { food in
            if food.position.distance(to: ctx.mermaidPosition) > 4000 {
                food.removeFromParent()
                return true
            }
            return false
        }
    }

    /// A sereia "fareja": garante que algo aparece perto em instantes.
    func requestSpawn(near point: CGPoint) {
        if pendingSpawn <= 0 {
            pendingSpawn = .random(in: 1.5...3)
        }
    }

    func nearestFood(to point: CGPoint, maxDistance: CGFloat) -> FoodNode? {
        foods
            .filter { $0.position.distance(to: point) <= maxDistance }
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
    }

    @discardableResult
    func spawn(near point: CGPoint, maxDistance: CGFloat = 1300) -> FoodNode? {
        guard let world = worldNode else { return nil }
        let zone = DepthZone.zone(atY: point.y)
        let kind = weightedKind(for: zone)

        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 350...maxDistance)
        let yRange = ctx.depth.allowedYRange()
        let position = CGPoint(
            x: (point.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (point.y + sin(angle) * distance).clamped(to: yRange)
        )
        return spawn(kind: kind, at: position, in: world)
    }

    @discardableResult
    func spawn(kind: FoodKind, at position: CGPoint, in world: SKNode) -> FoodNode {
        let node = FoodNode(kind: kind)
        node.position = position
        node.zPosition = 5
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.6))
        world.addChild(node)
        foods.append(node)
        return node
    }

    /// Spawn de comida rara perto da sereia (eventos).
    @discardableResult
    func spawnRare(near point: CGPoint) -> FoodNode? {
        guard let world = worldNode else { return nil }
        let zone = DepthZone.zone(atY: point.y)
        let rare = FoodSystem.kinds(for: zone).max { $0.xp < $1.xp } ?? FoodSystem.kinds(for: zone)[0]
        let position = CGPoint(
            x: (point.x + .random(in: -350...350)).clamped(to: World.minX...World.maxX),
            y: (point.y + .random(in: -250...250)).clamped(to: ctx.depth.allowedYRange())
        )
        return spawn(kind: rare, at: position, in: world)
    }

    /// Come a comida: aplica efeitos nos atributos.
    func consume(_ food: FoodNode) {
        guard foods.contains(where: { $0 === food }) else { return }
        removeNode(food)

        let stats = ctx.stats!
        stats.hunger = max(0, stats.hunger - food.kind.nutrition)
        stats.boostMood(4)
        stats.gainXP(food.kind.xp)
        stats.mealsEaten += 1
        if food.kind.courage > 0 {
            stats.courage = min(100, stats.courage + food.kind.courage)
        }
        if food.kind.pearls > 0 {
            let gained = stats.awardPearls(food.kind.pearls)
            ctx.say("Ela achou \(food.kind.name)! 🐚+\(gained)")
        } else if Int.random(in: 0..<4) == 0 {
            ctx.say("Nham... \(food.kind.name) 😋")
        }
    }

    /// Coleta sem comer (armazenar no abrigo).
    func collect(_ food: FoodNode) {
        removeNode(food)
    }

    private func removeNode(_ food: FoodNode) {
        foods.removeAll { $0 === food }
        food.run(.sequence([
            .group([.scale(to: 0.1, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .removeFromParent()
        ]))
    }

    // MARK: - Tabelas por bioma

    static func kinds(for zone: DepthZone) -> [FoodKind] {
        switch zone {
        case .clear:
            return [
                FoodKind(name: "alga doce", weight: 5, nutrition: 14, xp: 2, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1)),
                FoodKind(name: "plâncton brilhante", weight: 3, nutrition: 10, xp: 4, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.65, green: 0.95, blue: 0.85, alpha: 1)),
                FoodKind(name: "fruta caída na água", weight: 2, nutrition: 22, xp: 3, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.95, green: 0.45, blue: 0.4, alpha: 1))
            ]
        case .shallow:
            return [
                FoodKind(name: "alga macia", weight: 5, nutrition: 14, xp: 2, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.3, green: 0.75, blue: 0.45, alpha: 1)),
                FoodKind(name: "plâncton brilhante", weight: 3, nutrition: 10, xp: 4, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.65, green: 0.95, blue: 0.85, alpha: 1)),
                FoodKind(name: "semente aquática", weight: 2, nutrition: 12, xp: 2, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.85, green: 0.75, blue: 0.4, alpha: 1)),
                FoodKind(name: "uma concha pequena", weight: 1, nutrition: 6, xp: 8, pearls: 3, courage: 0.5, style: .pearl, color: UIColor(white: 0.95, alpha: 1))
            ]
        case .mid:
            return [
                FoodKind(name: "plâncton azul", weight: 4, nutrition: 12, xp: 4, pearls: 0, courage: 0, style: .glow, color: UIColor(red: 0.45, green: 0.65, blue: 0.95, alpha: 1)),
                FoodKind(name: "crustáceo das águas", weight: 3, nutrition: 20, xp: 5, pearls: 0, courage: 0.3, style: .critter, color: UIColor(red: 0.55, green: 0.55, blue: 0.75, alpha: 1)),
                FoodKind(name: "alga da meia-água", weight: 3, nutrition: 16, xp: 3, pearls: 0, courage: 0, style: .leaf, color: UIColor(red: 0.25, green: 0.55, blue: 0.5, alpha: 1)),
                FoodKind(name: "uma concha nutritiva", weight: 1, nutrition: 10, xp: 10, pearls: 4, courage: 0.6, style: .pearl, color: UIColor(white: 0.95, alpha: 1))
            ]
        case .blue:
            return [
                FoodKind(name: "organismo luminoso", weight: 4, nutrition: 15, xp: 5, pearls: 0, courage: 0.3, style: .glow, color: UIColor(red: 0.5, green: 0.85, blue: 0.95, alpha: 1)),
                FoodKind(name: "crustáceo azulado", weight: 3, nutrition: 20, xp: 5, pearls: 0, courage: 0.3, style: .critter, color: UIColor(red: 0.45, green: 0.5, blue: 0.8, alpha: 1)),
                FoodKind(name: "um cristal marinho", weight: 1, nutrition: 12, xp: 10, pearls: 3, courage: 0.8, style: .crystal, color: UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1))
            ]
        case .deep:
            return [
                FoodKind(name: "plâncton luminoso", weight: 4, nutrition: 16, xp: 6, pearls: 0, courage: 0.3, style: .glow, color: UIColor(red: 0.55, green: 0.95, blue: 0.9, alpha: 1)),
                FoodKind(name: "crustáceo das fendas", weight: 3, nutrition: 22, xp: 6, pearls: 0, courage: 0.4, style: .critter, color: UIColor(red: 0.4, green: 0.35, blue: 0.6, alpha: 1)),
                FoodKind(name: "uma concha mágica", weight: 1, nutrition: 8, xp: 14, pearls: 6, courage: 1, style: .pearl, color: UIColor(red: 0.8, green: 0.85, blue: 1, alpha: 1))
            ]
        case .abyss:
            return [
                FoodKind(name: "plâncton abissal", weight: 4, nutrition: 18, xp: 8, pearls: 0, courage: 0.5, style: .glow, color: UIColor(red: 0.75, green: 0.55, blue: 0.95, alpha: 1)),
                FoodKind(name: "fruto-cristal", weight: 2, nutrition: 26, xp: 12, pearls: 2, courage: 1, style: .crystal, color: UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)),
                FoodKind(name: "uma concha do abismo", weight: 1, nutrition: 8, xp: 18, pearls: 8, courage: 1.5, style: .pearl, color: UIColor(red: 0.9, green: 0.8, blue: 1, alpha: 1))
            ]
        case .surface:
            return [
                FoodKind(name: "fruta flutuante", weight: 4, nutrition: 24, xp: 6, pearls: 0, courage: 0, style: .fruit, color: UIColor(red: 0.95, green: 0.65, blue: 0.3, alpha: 1)),
                FoodKind(name: "migalhas de barco", weight: 3, nutrition: 12, xp: 5, pearls: 1, courage: 0.3, style: .critter, color: UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1)),
                FoodKind(name: "um objeto humano curioso", weight: 1, nutrition: 5, xp: 12, pearls: 4, courage: 0.8, style: .crystal, color: UIColor(red: 0.7, green: 0.75, blue: 0.8, alpha: 1))
            ]
        }
    }

    private func weightedKind(for zone: DepthZone) -> FoodKind {
        var kinds = FoodSystem.kinds(for: zone)
        if let region = ctx.regions.currentRegion {
            kinds += RegionDiscoverySystem.extraFood(for: region.id)
        }
        let total = kinds.reduce(CGFloat(0)) { $0 + $1.weight }
        var roll = CGFloat.random(in: 0..<total)
        for kind in kinds {
            roll -= kind.weight
            if roll <= 0 { return kind }
        }
        return kinds[0]
    }
}
