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

// MARK: - Nó de peixe

final class FishNode: SKNode, ChallengeGiver {
    let zone: DepthZone
    var heading: CGFloat
    var baseSpeed: CGFloat
    var skittish: Bool
    var isRare = false

    /// Desafio oferecido por este peixe (nil = peixe comum).
    var offeredChallenge: ChallengeKind? {
        didSet { updateChallengeHighlight() }
    }
    var isSpecialChallenge = false
    var worldPosition: CGPoint { position }

    private var verticalPhase = CGFloat.random(in: 0...6)
    private var fleeTimer: CGFloat = 0
    private let container = SKNode()
    private var challengeHighlight: SKNode?

    // guardados para gerar a cópia visual do desafio
    private var bodyLength: CGFloat = 40
    private var bodyHeight: CGFloat = 18
    private var bodyColor: UIColor = .white

    private let paletteOverride: [UIColor]?

    init(zone: DepthZone, rare: Bool = false, palette: [UIColor]? = nil) {
        self.zone = zone
        self.heading = Bool.random() ? 0 : .pi
        self.baseSpeed = .random(in: 40...110)
        self.skittish = Bool.random()
        self.isRare = rare
        self.paletteOverride = palette
        super.init()
        if rare {
            baseSpeed = .random(in: 120...170)
            skittish = false
        }
        buildShape()
        addChild(container)
        zPosition = CGFloat.random(in: 3...7)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildShape() {
        let length = isRare ? CGFloat.random(in: 80...110) : CGFloat.random(in: 28...64)
        let height = length * CGFloat.random(in: 0.35...0.5)
        let color = isRare
            ? UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            : (paletteOverride ?? FishNode.palette(for: zone)).randomElement()!

        bodyLength = length
        bodyHeight = height
        bodyColor = color

        let drawing = FishNode.fishDrawing(length: length, height: height, color: color,
                                           animateTail: true)
        container.addChild(drawing)

        // brilho nas zonas escuras
        if zone == .deep || zone == .abyss || isRare {
            if let body = drawing.childNode(withName: "fish_body") as? SKShapeNode {
                body.glowWidth = isRare ? 14 : 8
                let pulse = SKAction.repeatForever(.sequence([
                    .fadeAlpha(to: 0.7, duration: 1.1),
                    .fadeAlpha(to: 1.0, duration: 1.1)
                ]))
                pulse.eaeInEaseOut()
                body.run(pulse)
            }
        }
    }

    /// Desenho do peixe (corpo, cauda, olho) reaproveitável para a cópia
    /// que fica em destaque no topo de um desafio.
    static func fishDrawing(length: CGFloat,
                            height: CGFloat,
                            color: UIColor,
                            animateTail: Bool) -> SKNode {
        let node = SKNode()

        let body = SKShapeNode(ellipseOf: CGSize(width: length, height: height))
        body.fillColor = color
        body.strokeColor = color.withAlphaComponent(0.4)
        body.name = "fish_body"
        node.addChild(body)

        let tail = UIBezierPath()
        tail.move(to: CGPoint(x: -length * 0.45, y: 0))
        tail.addLine(to: CGPoint(x: -length * 0.75, y: height * 0.55))
        tail.addLine(to: CGPoint(x: -length * 0.75, y: -height * 0.55))
        tail.close()
        let tailNode = SKShapeNode(path: tail.cgPath)
        tailNode.fillColor = color.withAlphaComponent(0.85)
        tailNode.strokeColor = .clear
        node.addChild(tailNode)

        if animateTail {
            let tailSwing = SKAction.repeatForever(.sequence([
                .scaleX(to: 0.7, duration: 0.35),
                .scaleX(to: 1.0, duration: 0.35)
            ]))
            tailSwing.eaeInEaseOut()
            tailNode.run(tailSwing)
        }

        let eye = SKShapeNode(circleOfRadius: max(2.5, height * 0.1))
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: length * 0.3, y: height * 0.12)
        node.addChild(eye)
        let pupil = SKShapeNode(circleOfRadius: max(1.2, height * 0.05))
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = eye.position
        node.addChild(pupil)

        return node
    }

    /// Cópia visual estática deste peixe, para o cabeçalho do desafio.
    func makeGiverDisplayNode() -> SKNode {
        FishNode.fishDrawing(length: bodyLength, height: bodyHeight,
                             color: bodyColor, animateTail: true)
    }

    /// Anel dourado pulsante indicando que este peixe oferece um desafio.
    private func updateChallengeHighlight() {
        challengeHighlight?.removeFromParent()
        challengeHighlight = nil
        guard offeredChallenge != nil else { return }

        let radius = bodyLength * 0.85
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0.07)
        ring.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0.9)
        ring.lineWidth = 2.5
        ring.glowWidth = 10
        ring.zPosition = -1
        addChild(ring)
        ring.run(.repeatForever(.sequence([
            .group([.scale(to: 1.18, duration: 0.8), .fadeAlpha(to: 0.55, duration: 0.8)]),
            .group([.scale(to: 1.0, duration: 0.8), .fadeAlpha(to: 1.0, duration: 0.8)])
        ])))

        let badge = SKLabelNode(text: "❗️")
        badge.fontSize = 20
        badge.position = CGPoint(x: 0, y: radius + 14)
        ring.addChild(badge)
        challengeHighlight = ring
    }

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

    func update(dt: CGFloat, mermaidPosition: CGPoint) {
        // ruído suave de direção
        heading += CGFloat.random(in: -0.5...0.5) * dt * 2

        var speed = baseSpeed
        if offeredChallenge != nil {
            // peixes com desafio esperam a sereia: nadam devagar e não fogem
            speed = min(baseSpeed, 45)
        } else if fleeTimer > 0 {
            fleeTimer -= dt
            speed = baseSpeed * 2.6
        } else if skittish && position.distance(to: mermaidPosition) < 160 {
            heading = atan2(position.y - mermaidPosition.y, position.x - mermaidPosition.x)
            fleeTimer = 2
        }

        verticalPhase += dt * 2
        position.x += cos(heading) * speed * dt
        position.y += sin(heading) * speed * dt * 0.4 + sin(verticalPhase) * 10 * dt

        // mantém o peixe dentro da própria camada
        let range = zone.yRange
        if position.y > range.upperBound - 60 || position.y < range.lowerBound + 60 {
            heading = -heading
            position.y = position.y.clamped(to: (range.lowerBound + 60)...(range.upperBound - 60))
        }
        if position.x > World.maxX || position.x < World.minX {
            heading = .pi - heading
            position.x = position.x.clamped(to: World.minX...World.maxX)
        }

        container.xScale = cos(heading) >= 0 ? 1 : -1
    }
}

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
        case .surface: return 4
        case .clear: return 6
        case .shallow: return 6
        case .mid: return 6
        case .blue: return 5
        case .deep: return 4
        case .abyss: return 3
        }
    }

    func update(dt: CGFloat) {
        let mermaidPos = ctx.mermaidPosition
        for fish in fishes {
            fish.update(dt: dt, mermaidPosition: mermaidPos)
        }
        fishes.removeAll { fish in
            if fish.position.distance(to: mermaidPos) > 3200 {
                fish.removeFromParent()
                return true
            }
            return false
        }

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = .random(in: 2...5)
            let zone = DepthZone.zone(atY: mermaidPos.y)
            let nearby = fishes.filter { $0.zone == zone }.count
            if nearby < desiredCount(for: zone) {
                if Int.random(in: 0..<10) < 3 {
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
        let regionPalette = ctx.regions.currentRegion.flatMap {
            RegionDiscoverySystem.fishPalette(for: $0.id)
        }
        let fish = FishNode(zone: zone, rare: rare, palette: regionPalette)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 900...1600)
        let range = zone.yRange
        fish.position = CGPoint(
            x: (point.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (point.y + sin(angle) * distance).clamped(to: (range.lowerBound + 80)...(range.upperBound - 80))
        )
        fish.alpha = 0
        fish.run(.fadeIn(withDuration: 0.8))
        world.addChild(fish)
        fishes.append(fish)
        ctx.challenges?.decorateSpawn(fish)
        return fish
    }

    private func spawnSchool(zone: DepthZone, near point: CGPoint) {
        guard let leader = spawnFish(zone: zone, near: point) else { return }
        let count = Int.random(in: 2...4)
        for _ in 0..<count {
            guard let member = spawnFish(zone: zone, near: point) else { continue }
            member.position = leader.position + CGPoint(x: .random(in: -120...120),
                                                        y: .random(in: -80...80))
            member.heading = leader.heading
            member.baseSpeed = leader.baseSpeed * CGFloat.random(in: 0.9...1.1)
            member.skittish = leader.skittish
        }
    }

    func nearestFish(to point: CGPoint, maxDistance: CGFloat) -> FishNode? {
        fishes
            .filter { $0.position.distance(to: point) <= maxDistance }
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
