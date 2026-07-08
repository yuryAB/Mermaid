//
//  EntityFactory.swift
//  Ester
//

import GameplayKit
import SpriteKit
import CoreGraphics

final class EntityFactory {

    static func makeMermaidEntity(stats: MermaidStats) -> GKEntity {
        let entity = GKEntity()
        let mermaid = Mermaid()
        mermaid.base.position = World.startPosition

        let nodeComponent = NodeComponent(node: mermaid.base)
        let transform = TransformComponent(position: World.startPosition)
        let health = HealthComponent(hunger: stats.hunger,
                                     energy: stats.energy,
                                     mood: stats.mood,
                                     trust: stats.trust)
        let intent = IntentComponent()
        let expression = ExpressionComponent()

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(health)
        entity.addComponent(intent)
        entity.addComponent(expression)

        return entity
    }

    static func makeFoodEntity(kind: FoodKind, position: CGPoint) -> GKEntity {
        let entity = GKEntity()
        let foodNode = FoodNode(kind: kind)
        foodNode.position = position

        let nodeComponent = NodeComponent(node: foodNode)
        let transform = TransformComponent(position: position)
        let food = FoodComponent(kind: kind)
        let lifetime = LifetimeComponent(timeToLive: 120)
        let visual = VisualEffectComponent()
        visual.addEffect(.bob(amplitude: 8, frequency: 2.5))
        visual.addEffect(.fadeIn(duration: 0.8))

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(food)
        entity.addComponent(lifetime)
        entity.addComponent(visual)

        foodNode.entity = entity
        return entity
    }

    static func makeFishEntity(zone: DepthZone,
                               position: CGPoint,
                               species: AquaticSpecies? = nil,
                               isRare: Bool = false) -> GKEntity {
        let entity = GKEntity()
        let fishNode = FishNode(zone: zone, rare: isRare, palette: nil, species: species)
        fishNode.position = position

        let nodeComponent = NodeComponent(node: fishNode)
        let transform = TransformComponent(position: position)
        let velocity = VelocityComponent(dx: .random(in: -0.4...0.4), dy: .random(in: -0.3...0.3))
        let behavior = FishBehaviorComponent(species: FishSpecies(
            name: species?.commonName ?? "peixe",
            minSize: 30,
            maxSize: 40,
            speed: 80,
            turnRate: 0.5,
            colors: [.white],
            finCount: 2,
            glowIntensity: (zone == .deep || zone == .abyss || isRare) ? 0.6 : 0
        ), isRare: isRare)
        let zoneComp = ZoneComponent(zone: zone)
        let lifetime = LifetimeComponent(timeToLive: 60)
        let visual = VisualEffectComponent()
        visual.addEffect(.fadeIn(duration: 0.8))

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(velocity)
        entity.addComponent(behavior)
        entity.addComponent(zoneComp)
        entity.addComponent(lifetime)
        entity.addComponent(visual)

        fishNode.entity = entity
        return entity
    }

    static func makePOIEntity(poi: WorldPOI, position: CGPoint) -> GKEntity {
        let entity = GKEntity()
        let poiNode = WorldPOINode(poi: poi, discovered: true, rewardCollected: false, focused: false)
        poiNode.position = position

        let nodeComponent = NodeComponent(node: poiNode)
        let transform = TransformComponent(position: position)
        let poiComp = POIComponent(poi: poi)

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(poiComp)

        poiNode.entity = entity
        return entity
    }

    static func makeChallengeGiverEntity(kind: ChallengeKind,
                                         goalRange: ChallengeGoalRange,
                                         position: CGPoint,
                                         visualNode: SKNode) -> GKEntity {
        let entity = GKEntity()
        visualNode.position = position

        let nodeComponent = NodeComponent(node: visualNode)
        let transform = TransformComponent(position: position)
        let giver = ChallengeGiverComponent(kind: kind, goalRange: goalRange)

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(giver)

        visualNode.entity = entity
        return entity
    }

    static func makeObjectiveEntity(label: String,
                                    position: CGPoint,
                                    timeToLive: CGFloat,
                                    onReach: (() -> Void)?) -> GKEntity {
        let entity = GKEntity()

        let objectiveIcon = SKShapeNode(circleOfRadius: 20)
        objectiveIcon.fillColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.6)
        objectiveIcon.strokeColor = .clear
        objectiveIcon.position = position

        let nodeComponent = NodeComponent(node: objectiveIcon)
        let transform = TransformComponent(position: position)
        let objective = ObjectiveComponent(label: label,
                                           positionProvider: { [weak objectiveIcon] in objectiveIcon?.position },
                                           onReach: onReach,
                                           timeRemaining: timeToLive)
        let visual = VisualEffectComponent()
        visual.addEffect(.pulse(scale: 1.3, duration: 0.8))

        entity.addComponent(nodeComponent)
        entity.addComponent(transform)
        entity.addComponent(objective)
        entity.addComponent(visual)

        objectiveIcon.entity = entity
        return entity
    }
}
