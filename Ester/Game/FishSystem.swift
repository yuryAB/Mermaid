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

fileprivate enum FishSilhouette: CaseIterable {
    case oval
    case needle
    case diamond
    case moon
    case ray

    static func random(for zone: DepthZone, rare: Bool) -> FishSilhouette {
        if rare {
            return [.moon, .ray, .diamond].randomElement()!
        }
        switch zone {
        case .surface, .clear:
            return [.needle, .oval, .diamond].randomElement()!
        case .shallow:
            return [.oval, .diamond, .moon].randomElement()!
        case .mid, .blue:
            return allCases.randomElement()!
        case .deep, .abyss:
            return [.needle, .ray, .moon, .diamond].randomElement()!
        }
    }
}

fileprivate enum FishPattern: CaseIterable {
    case plain
    case stripes
    case spots
    case glowDots

    static func random(for zone: DepthZone, rare: Bool) -> FishPattern {
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
}

fileprivate enum FishMotionMode {
    case normal
    case guiding(target: CGPoint, until: Date)
    case gatheringForPlay(point: CGPoint, until: Date)
    case playing(center: CGPoint, until: Date)
}

// MARK: - Nó de peixe

final class FishNode: SKNode, ChallengeGiver {
    let zone: DepthZone
    var heading: CGFloat
    var baseSpeed: CGFloat
    var skittish: Bool
    var isRare = false

    /// Desafio oferecido por este peixe (nil = peixe comum).
    var offeredChallenge: ChallengeKind? {
        didSet {
            if offeredChallenge == nil {
                offeredChallengeGoal = nil
            }
            updateChallengeHighlight()
        }
    }
    var offeredChallengeGoal: Int?
    var isSpecialChallenge = false
    var worldPosition: CGPoint { position }
    var isCompanionBusy: Bool {
        switch motionMode {
        case .normal: return false
        case .guiding, .gatheringForPlay, .playing: return true
        }
    }
    var isAvailableForCompanionAction: Bool {
        offeredChallenge == nil && !isCompanionBusy
    }

    private var verticalPhase = CGFloat.random(in: 0...6)
    private var playPhase = CGFloat.random(in: 0...6)
    private var fleeTimer: CGFloat = 0
    private var motionMode: FishMotionMode = .normal
    private let container = SKNode()
    private var challengeHighlight: SKNode?

    // guardados para gerar a cópia visual do desafio
    private var bodyLength: CGFloat = 40
    private var bodyHeight: CGFloat = 18
    private var bodyColor: UIColor = .white

    private let paletteOverride: [UIColor]?
    private let silhouette: FishSilhouette
    private let pattern: FishPattern

    init(zone: DepthZone, rare: Bool = false, palette: [UIColor]? = nil) {
        self.zone = zone
        self.heading = Bool.random() ? 0 : .pi
        self.baseSpeed = .random(in: 40...110)
        self.skittish = Bool.random()
        self.isRare = rare
        self.paletteOverride = palette
        self.silhouette = FishSilhouette.random(for: zone, rare: rare)
        self.pattern = FishPattern.random(for: zone, rare: rare)
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
        let length = FishNode.bodyLength(for: silhouette, rare: isRare)
        let height = FishNode.bodyHeight(for: silhouette, length: length)
        let color = isRare
            ? UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            : (paletteOverride ?? FishNode.palette(for: zone)).randomElement()!

        bodyLength = length
        bodyHeight = height
        bodyColor = color

        let drawing = FishNode.fishDrawing(length: length, height: height, color: color,
                                           animateTail: true,
                                           silhouette: silhouette,
                                           pattern: pattern)
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
    fileprivate static func fishDrawing(length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor,
                                        animateTail: Bool,
                                        silhouette: FishSilhouette = .oval,
                                        pattern: FishPattern = .plain) -> SKNode {
        let node = SKNode()

        let body = bodyShape(length: length, height: height, silhouette: silhouette)
        body.fillColor = color
        body.strokeColor = color.withAlphaComponent(0.4)
        body.name = "fish_body"
        node.addChild(body)

        let tailNode = tailShape(length: length, height: height, color: color, silhouette: silhouette)
        node.addChild(tailNode)

        if animateTail {
            let tight = silhouette == .needle ? 0.82 : 0.7
            let tailSwing = SKAction.repeatForever(.sequence([
                .scaleX(to: tight, duration: 0.28),
                .scaleX(to: 1.0, duration: 0.28)
            ]))
            tailSwing.eaeInEaseOut()
            tailNode.run(tailSwing)
        }

        addFins(to: node, length: length, height: height, color: color, silhouette: silhouette)
        addPattern(pattern, to: node, length: length, height: height, color: color, silhouette: silhouette)
        addEye(to: node, length: length, height: height, silhouette: silhouette)

        return node
    }

    private static func bodyLength(for silhouette: FishSilhouette, rare: Bool) -> CGFloat {
        let base: ClosedRange<CGFloat> = rare ? 80...118 : 30...70
        switch silhouette {
        case .oval:
            return CGFloat.random(in: base)
        case .needle:
            return CGFloat.random(in: rare ? 95...140 : 58...96)
        case .diamond:
            return CGFloat.random(in: rare ? 86...118 : 42...76)
        case .moon:
            return CGFloat.random(in: rare ? 88...120 : 44...78)
        case .ray:
            return CGFloat.random(in: rare ? 105...145 : 72...112)
        }
    }

    private static func bodyHeight(for silhouette: FishSilhouette, length: CGFloat) -> CGFloat {
        switch silhouette {
        case .oval:
            return length * CGFloat.random(in: 0.34...0.5)
        case .needle:
            return length * CGFloat.random(in: 0.16...0.24)
        case .diamond:
            return length * CGFloat.random(in: 0.55...0.72)
        case .moon:
            return length * CGFloat.random(in: 0.58...0.78)
        case .ray:
            return length * CGFloat.random(in: 0.34...0.46)
        }
    }

    private static func bodyShape(length: CGFloat,
                                  height: CGFloat,
                                  silhouette: FishSilhouette) -> SKShapeNode {
        switch silhouette {
        case .oval, .needle, .moon:
            return SKShapeNode(ellipseOf: CGSize(width: length, height: height))
        case .diamond:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height * 0.54))
            path.addLine(to: CGPoint(x: length * 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -height * 0.54))
            path.close()
            return SKShapeNode(path: path.cgPath)
        case .ray:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.5, y: 0))
            path.addCurve(to: CGPoint(x: length * 0.5, y: 0),
                          controlPoint1: CGPoint(x: -length * 0.22, y: height * 0.84),
                          controlPoint2: CGPoint(x: length * 0.22, y: height * 0.84))
            path.addCurve(to: CGPoint(x: -length * 0.5, y: 0),
                          controlPoint1: CGPoint(x: length * 0.20, y: -height * 0.56),
                          controlPoint2: CGPoint(x: -length * 0.20, y: -height * 0.56))
            return SKShapeNode(path: path.cgPath)
        }
    }

    private static func tailShape(length: CGFloat,
                                  height: CGFloat,
                                  color: UIColor,
                                  silhouette: FishSilhouette) -> SKNode {
        let node = SKNode()
        switch silhouette {
        case .ray:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: -height * 0.03))
            path.addLine(to: CGPoint(x: -length * 0.92, y: -height * 0.2))
            let tail = SKShapeNode(path: path.cgPath)
            tail.strokeColor = color.withAlphaComponent(0.68)
            tail.lineWidth = max(2, height * 0.08)
            tail.fillColor = .clear
            node.addChild(tail)
        case .needle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: height * 0.75))
            path.addLine(to: CGPoint(x: -length * 0.65, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: -height * 0.75))
            path.close()
            let tail = SKShapeNode(path: path.cgPath)
            tail.fillColor = color.withAlphaComponent(0.82)
            tail.strokeColor = .clear
            node.addChild(tail)
        default:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: height * 0.55))
            path.addLine(to: CGPoint(x: -length * 0.75, y: -height * 0.55))
            path.close()
            let tail = SKShapeNode(path: path.cgPath)
            tail.fillColor = color.withAlphaComponent(0.85)
            tail.strokeColor = .clear
            node.addChild(tail)
        }
        return node
    }

    private static func addFins(to node: SKNode,
                                length: CGFloat,
                                height: CGFloat,
                                color: UIColor,
                                silhouette: FishSilhouette) {
        guard silhouette != .ray else { return }

        let finPath = UIBezierPath()
        finPath.move(to: CGPoint(x: -length * 0.08, y: height * 0.36))
        finPath.addLine(to: CGPoint(x: length * 0.1, y: height * 0.74))
        finPath.addLine(to: CGPoint(x: length * 0.22, y: height * 0.24))
        finPath.close()
        let topFin = SKShapeNode(path: finPath.cgPath)
        topFin.fillColor = color.withAlphaComponent(0.54)
        topFin.strokeColor = .clear
        topFin.zPosition = -0.5
        node.addChild(topFin)

        let lower = SKShapeNode(ellipseOf: CGSize(width: length * 0.28, height: height * 0.28))
        lower.fillColor = color.withAlphaComponent(0.44)
        lower.strokeColor = .clear
        lower.position = CGPoint(x: length * 0.04, y: -height * 0.34)
        lower.zRotation = -0.35
        lower.zPosition = -0.4
        node.addChild(lower)
    }

    private static func addPattern(_ pattern: FishPattern,
                                   to node: SKNode,
                                   length: CGFloat,
                                   height: CGFloat,
                                   color: UIColor,
                                   silhouette: FishSilhouette) {
        switch pattern {
        case .plain:
            return
        case .stripes:
            for i in 0..<3 {
                let x = -length * 0.16 + CGFloat(i) * length * 0.13
                let path = UIBezierPath()
                path.move(to: CGPoint(x: x, y: height * 0.34))
                path.addLine(to: CGPoint(x: x - length * 0.05, y: -height * 0.34))
                let stripe = SKShapeNode(path: path.cgPath)
                stripe.strokeColor = UIColor.lerp(color, .white, 0.45).withAlphaComponent(0.42)
                stripe.lineWidth = max(1.2, height * 0.08)
                stripe.fillColor = .clear
                node.addChild(stripe)
            }
        case .spots:
            for _ in 0..<Int.random(in: 3...6) {
                let spot = SKShapeNode(circleOfRadius: max(1.8, height * CGFloat.random(in: 0.055...0.095)))
                spot.fillColor = UIColor.lerp(color, .white, 0.5).withAlphaComponent(0.52)
                spot.strokeColor = .clear
                spot.position = CGPoint(x: CGFloat.random(in: -length * 0.2...length * 0.25),
                                        y: CGFloat.random(in: -height * 0.22...height * 0.22))
                node.addChild(spot)
            }
        case .glowDots:
            for _ in 0..<Int.random(in: 3...7) {
                let dot = SKShapeNode(circleOfRadius: max(2, height * CGFloat.random(in: 0.045...0.075)))
                dot.fillColor = UIColor.lerp(color, .white, 0.72).withAlphaComponent(0.72)
                dot.strokeColor = .clear
                dot.glowWidth = 5
                dot.position = CGPoint(x: CGFloat.random(in: -length * 0.24...length * 0.32),
                                       y: CGFloat.random(in: -height * 0.24...height * 0.24))
                node.addChild(dot)
            }
        }

        if silhouette == .moon {
            let ring = SKShapeNode(ellipseOf: CGSize(width: length * 0.62, height: height * 0.82))
            ring.fillColor = .clear
            ring.strokeColor = UIColor.lerp(color, .white, 0.35).withAlphaComponent(0.26)
            ring.lineWidth = max(1.4, height * 0.04)
            node.addChild(ring)
        }
    }

    private static func addEye(to node: SKNode,
                               length: CGFloat,
                               height: CGFloat,
                               silhouette: FishSilhouette) {
        let eyeRadius = max(2.5, height * 0.1)
        let eye = SKShapeNode(circleOfRadius: eyeRadius)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = silhouette == .ray
            ? CGPoint(x: length * 0.12, y: height * 0.16)
            : CGPoint(x: length * 0.3, y: height * 0.12)
        node.addChild(eye)
        let pupil = SKShapeNode(circleOfRadius: max(1.2, eyeRadius * 0.5))
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = eye.position
        node.addChild(pupil)
    }

    /// Cópia visual estática deste peixe, para o cabeçalho do desafio.
    func makeGiverDisplayNode() -> SKNode {
        FishNode.fishDrawing(length: bodyLength, height: bodyHeight,
                             color: bodyColor,
                             animateTail: true,
                             silhouette: silhouette,
                             pattern: pattern)
    }

    func startGuiding(toward target: CGPoint, duration: TimeInterval) {
        motionMode = .guiding(target: target, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func gatherForPlay(at point: CGPoint, duration: TimeInterval) {
        motionMode = .gatheringForPlay(point: point, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func startPlaying(around center: CGPoint, duration: TimeInterval) {
        motionMode = .playing(center: center, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func resumeNaturalSwimming() {
        motionMode = .normal
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
        defer {
            container.xScale = cos(heading) >= 0 ? 1 : -1
        }
        if updateCompanionMotion(dt: dt, mermaidPosition: mermaidPosition) {
            return
        }

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
    }

    private func updateCompanionMotion(dt: CGFloat, mermaidPosition: CGPoint) -> Bool {
        switch motionMode {
        case .normal:
            return false
        case .guiding(let target, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updateGuidingMotion(dt: dt, mermaidPosition: mermaidPosition, target: target)
            return true
        case .gatheringForPlay(let point, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updateGatheringMotion(dt: dt, mermaidPosition: mermaidPosition, point: point)
            return true
        case .playing(let center, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updatePlayingMotion(dt: dt, center: center)
            return true
        }
    }

    private func updateGuidingMotion(dt: CGFloat, mermaidPosition: CGPoint, target: CGPoint) {
        verticalPhase += dt * CGFloat(2)
        playPhase += dt * CGFloat(0.9)

        let remaining = mermaidPosition.distance(to: target)
        let desired: CGPoint
        if remaining < CGFloat(280) {
            let orbitX = cos(playPhase) * CGFloat(120)
            let orbitY = sin(playPhase * CGFloat(0.8)) * CGFloat(70)
            desired = CGPoint(x: target.x + orbitX,
                              y: target.y + orbitY)
        } else {
            let dx = target.x - mermaidPosition.x
            let dy = target.y - mermaidPosition.y
            let rawDistance = sqrt(dx * dx + dy * dy)
            let distance = max(CGFloat(1), rawDistance)
            let farFromMermaid = position.distance(to: mermaidPosition) > CGFloat(620)
            let lead: CGFloat = farFromMermaid ? CGFloat(220) : CGFloat(320)
            let unitX = dx / distance
            let unitY = dy / distance
            let desiredX = mermaidPosition.x + unitX * lead
            let desiredY = mermaidPosition.y + unitY * lead
            desired = CGPoint(x: desiredX, y: desiredY)
        }

        let guideSpeed = max(CGFloat(150), baseSpeed * CGFloat(1.35))
        swimToward(desired, speed: guideSpeed, dt: dt, bob: CGFloat(4))
    }

    private func updateGatheringMotion(dt: CGFloat, mermaidPosition: CGPoint, point: CGPoint) {
        verticalPhase += dt * CGFloat(1.2)
        let distance = position.distance(to: point)
        if distance > CGFloat(32) {
            swimToward(point, speed: CGFloat(58), dt: dt, bob: CGFloat(2))
        } else {
            heading = atan2(mermaidPosition.y - position.y, mermaidPosition.x - position.x)
            position.y += sin(verticalPhase) * CGFloat(2) * dt
            clampToWorldAndZone()
        }
    }

    private func updatePlayingMotion(dt: CGFloat, center: CGPoint) {
        verticalPhase += dt * CGFloat(2.4)
        playPhase += dt * CGFloat(1.7)
        let orbitX = cos(playPhase) * CGFloat(90)
        let orbitY = sin(playPhase * CGFloat(1.2)) * CGFloat(54)
        let desired = CGPoint(x: center.x + orbitX,
                              y: center.y + orbitY)
        swimToward(desired, speed: CGFloat(92), dt: dt, bob: CGFloat(3))
    }

    private func swimToward(_ point: CGPoint, speed: CGFloat, dt: CGFloat, bob: CGFloat) {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let rawDistance = sqrt(dx * dx + dy * dy)
        let distance = max(CGFloat(1), rawDistance)
        heading = atan2(dy, dx)
        let step = min(distance, speed * dt)
        position.x += dx / distance * step
        position.y += dy / distance * step + sin(verticalPhase) * bob * dt
        clampToWorldAndZone()
    }

    private func clampToWorldAndZone() {
        let range = zone.yRange
        position.x = position.x.clamped(to: World.minX...World.maxX)
        position.y = position.y.clamped(to: (range.lowerBound + 60)...(range.upperBound - 60))
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
        let regionPalette = ctx.regions.currentRegion.flatMap {
            RegionDiscoverySystem.fishPalette(for: $0.id)
        }
        let fish = FishNode(zone: zone, rare: rare, palette: regionPalette)
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
