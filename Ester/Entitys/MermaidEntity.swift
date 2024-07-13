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
    
    // Inicialização padrão da entidade
    override init() {
        super.init()
        setupComponents()
    }
    
    // Inicializador necessário para conformidade com NSCoding
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupComponents()
    }
    
    // Configura os componentes da entidade
    private func setupComponents() {
        // Adiciona um componente de sprite
        let spriteComponent = SpriteComponent(texture: SKTexture(imageNamed: "defaultTexture"))
        self.addComponent(spriteComponent)
        
        // Adiciona um componente de física
        let physicsComponent = PhysicsComponent()
        self.addComponent(physicsComponent)
    }
}
