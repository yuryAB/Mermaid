//
//  EntityManager.swift
//  Ester
//
//  Gerencia o ciclo de vida de entidades e component systems ECS.
//

import Foundation
import GameplayKit
import SpriteKit

final class EntityManager {
    private var entities = Set<GKEntity>()
    private var componentSystems: [ObjectIdentifier: GKComponentSystem<GKComponent>] = [:]

    private weak var worldNode: SKNode?

    init(worldNode: SKNode) {
        self.worldNode = worldNode
    }

    func registerComponentSystem<T: GKComponent>(_ system: GKComponentSystem<T>) {
        let key = ObjectIdentifier(T.self)
        componentSystems[key] = system as? GKComponentSystem<GKComponent>
    }

    func componentSystem<T: GKComponent>(for type: T.Type) -> GKComponentSystem<T>? {
        let key = ObjectIdentifier(T.self)
        return componentSystems[key] as? GKComponentSystem<T>
    }

    func addEntity(_ entity: GKEntity, to container: SKNode? = nil) {
        entities.insert(entity)

        if let nodeComponent = entity.component(ofType: NodeComponent.self) {
            nodeComponent.node.entity = entity
            let parent = container ?? worldNode
            parent?.addChild(nodeComponent.node)
        }

        for (_, system) in componentSystems {
            system.addComponent(foundIn: entity)
        }
    }

    func removeEntity(_ entity: GKEntity) {
        entities.remove(entity)

        if let nodeComponent = entity.component(ofType: NodeComponent.self) {
            nodeComponent.node.removeFromParent()
        }

        for (_, system) in componentSystems {
            system.removeComponent(foundIn: entity)
        }
    }

    func entitiesWith<T: GKComponent>(_ componentType: T.Type) -> [GKEntity] {
        entities.filter { $0.component(ofType: componentType) != nil }
    }

    func entitiesWith<A: GKComponent, B: GKComponent>(_ a: A.Type, _ b: B.Type) -> [GKEntity] {
        entities.filter { $0.component(ofType: a) != nil && $0.component(ofType: b) != nil }
    }

    func entitiesWith<A: GKComponent, B: GKComponent, C: GKComponent>(_ a: A.Type, _ b: B.Type, _ c: C.Type) -> [GKEntity] {
        entities.filter { $0.component(ofType: a) != nil && $0.component(ofType: b) != nil && $0.component(ofType: c) != nil }
    }

    func update(deltaTime: TimeInterval) {
        for (_, system) in componentSystems {
            system.update(deltaTime: deltaTime)
        }
    }

    var allEntities: Set<GKEntity> { entities }
    var entityCount: Int { entities.count }
}
