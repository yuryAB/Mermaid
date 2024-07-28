//
//  EntityManager.swift
//  Ester
//
//  Created by yury antony on 28/07/24.
//

import Foundation
import GameplayKit

class EntityManager {
    var entities = Set<GKEntity>()
    
    func addEntity(_ entity: GKEntity, to container: SKNode) {
        entities.insert(entity)
        
        if let baseSpriteComponent = entity.component(ofType: BaseSpriteComponent.self) {
            baseSpriteComponent.node.entity = entity
            container.addChild(baseSpriteComponent.node)
            print("Entity added to container")
        } else {
            print("Failed to add entity: SpriteComponent missing")
        }
    }
}
