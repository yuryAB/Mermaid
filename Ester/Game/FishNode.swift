//
//  FishNode.swift
//  Ester
//
//  Comportamento e estado visual de um animal aquatico individual.
//

import Foundation
import SpriteKit
import GameplayKit

fileprivate enum FishMotionMode {
    case normal
    case guiding(target: CGPoint, until: Date)
    case gatheringForPlay(point: CGPoint, until: Date)
    case playing(center: CGPoint, until: Date)
}

// MARK: - Nó de peixe

final class FishNode: SKNode, ChallengeGiver {
    let zone: DepthZone
    let species: AquaticSpecies?
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

    init(zone: DepthZone, rare: Bool = false, palette: [UIColor]? = nil, species: AquaticSpecies? = nil) {
        self.zone = zone
        self.species = species
        self.heading = Bool.random() ? 0 : .pi
        self.baseSpeed = .random(in: 40...110)
        self.skittish = Bool.random()
        self.isRare = rare
        self.paletteOverride = palette
        self.silhouette = FishSilhouette.random(for: zone, rare: rare, species: species)
        self.pattern = FishPattern.random(for: zone, rare: rare, species: species)
        super.init()
        name = species.map { "animal_\($0.id)" } ?? "animal_generic"
        if rare {
            baseSpeed = .random(in: 120...170)
            skittish = false
        } else if species?.group == .mammal || species?.group == .shark || species?.group == .reptile {
            baseSpeed = .random(in: 70...130)
            skittish = false
        }
        buildShape()
        addChild(container)
        zPosition = CGFloat.random(in: 3...7)
        registerEntity()
    }

    private func registerEntity() {
        let entity = GKEntity()
        let nodeComp = NodeComponent(node: self)
        let transform = TransformComponent(position: position)
        let behavior = FishBehaviorComponent(
            species: FishSpecies(
                name: species?.commonName ?? name ?? "peixe",
                minSize: 30, maxSize: bodyLength, speed: baseSpeed,
                turnRate: 0.5, colors: [bodyColor], finCount: 2,
                glowIntensity: (zone == .deep || zone == .abyss || isRare) ? 0.6 : 0
            ),
            isRare: isRare
        )
        let zoneComp = ZoneComponent(zone: zone)
        let lifetime = LifetimeComponent(timeToLive: 120)

        entity.addComponent(nodeComp)
        entity.addComponent(transform)
        entity.addComponent(behavior)
        entity.addComponent(zoneComp)
        entity.addComponent(lifetime)
        self.entity = entity
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildShape() {
        let visual = species.map(SpeciesVisualCatalog.profile)
        let length = FishDrawingFactory.bodyLength(for: silhouette, rare: isRare, species: species)
            * (visual?.lengthMultiplier ?? 1)
        let height = FishDrawingFactory.bodyHeight(for: silhouette, length: length)
        let color = isRare
            ? UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            : (visual?.color ?? (paletteOverride ?? FishVisualPalette.palette(for: zone)).randomElement()!)
        let resolvedPattern = visual.flatMap(\.pattern) ?? pattern

        bodyLength = length
        bodyHeight = height
        bodyColor = color

        let drawing = FishDrawingFactory.fishDrawing(length: length,
                                                     height: height,
                                                     color: color,
                                                     animateTail: true,
                                                     silhouette: silhouette,
                                                     pattern: resolvedPattern)
        FishDrawingFactory.addSpeciesTraits(to: drawing,
                                            species: species,
                                            length: length,
                                            height: height,
                                            color: color,
                                            silhouette: silhouette,
                                            animateTraits: true)
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

    /// Cópia visual estática deste peixe, para o cabeçalho do desafio.
    func makeGiverDisplayNode() -> SKNode {
        FishDrawingFactory.makeGiverDisplayNode(length: bodyLength,
                                                height: bodyHeight,
                                                color: bodyColor,
                                                silhouette: silhouette,
                                                pattern: pattern,
                                                species: species)
    }

    static func makeSpeciesDisplayNode(species: AquaticSpecies,
                                       discovered: Bool,
                                       scale: CGFloat = 1) -> SKNode {
        FishDrawingFactory.makeSpeciesDisplayNode(species: species,
                                                  discovered: discovered,
                                                  scale: scale)
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
            updatePlayingMotion(dt: dt, center: center, mermaidPosition: mermaidPosition)
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
        keepGuidingLead(from: mermaidPosition, toward: target)
    }

    private func keepGuidingLead(from mermaidPosition: CGPoint, toward target: CGPoint) {
        let dx = target.x - mermaidPosition.x
        let dy = target.y - mermaidPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > CGFloat(1) else { return }

        let unitX = dx / distance
        let unitY = dy / distance
        let offsetX = position.x - mermaidPosition.x
        let offsetY = position.y - mermaidPosition.y
        let forwardLead = offsetX * unitX + offsetY * unitY
        let minimumLead = CGFloat(220)
        guard forwardLead < minimumLead else { return }

        let sideOffset = (offsetX * -unitY + offsetY * unitX).clamped(to: -CGFloat(90)...CGFloat(90))
        position.x = mermaidPosition.x + unitX * minimumLead - unitY * sideOffset
        position.y = mermaidPosition.y + unitY * minimumLead + unitX * sideOffset
        heading = atan2(unitY, unitX)
        clampToWorldAndZone()
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

    private func updatePlayingMotion(dt: CGFloat, center: CGPoint, mermaidPosition: CGPoint) {
        verticalPhase += dt * CGFloat(2.4)
        playPhase += dt * CGFloat(1.45)
        let liveCenter = CGPoint(x: center.x * CGFloat(0.35) + mermaidPosition.x * CGFloat(0.65),
                                 y: center.y * CGFloat(0.35) + mermaidPosition.y * CGFloat(0.65))
        let orbitX = cos(playPhase) * CGFloat(145)
        let orbitY = sin(playPhase * CGFloat(1.18)) * CGFloat(82)
        var desired = CGPoint(x: liveCenter.x + orbitX,
                              y: liveCenter.y + orbitY)

        let distanceFromMermaid = desired.distance(to: mermaidPosition)
        if distanceFromMermaid < CGFloat(105) {
            let dx = desired.x - mermaidPosition.x
            let dy = desired.y - mermaidPosition.y
            let distance = max(CGFloat(1), sqrt(dx * dx + dy * dy))
            desired.x = mermaidPosition.x + dx / distance * CGFloat(105)
            desired.y = mermaidPosition.y + dy / distance * CGFloat(105)
        }

        swimToward(desired, speed: CGFloat(124), dt: dt, bob: CGFloat(3))
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
