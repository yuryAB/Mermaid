//
//  MermaidEntity.swift
//  Ester
//
//  Created by yury antony on 12/07/24.
//

import Foundation
import GameplayKit
import SpriteKit

class MermaidEntity: GKEntity {
    let mermaid: Mermaid
    
    override init() {
        self.mermaid = Mermaid()
        super.init()
        setupComponents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupComponents() {
        let spriteComponent = NodeComponent(node: mermaid.base)
        self.addComponent(spriteComponent)

        let transform = TransformComponent(position: World.startPosition)
        self.addComponent(transform)

        let health = HealthComponent()
        self.addComponent(health)

        let intent = IntentComponent()
        self.addComponent(intent)

        let expression = ExpressionComponent()
        self.addComponent(expression)

        let emotionComponent = MermaidEmotionComponent(mermaid: mermaid)
        self.addComponent(emotionComponent)
    }
}
