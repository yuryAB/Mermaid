//
//  Model.swift
//  Ester
//
//  Created by yury antony on 12/07/24.
//

import GameplayKit
import SpriteKit

// Define a entidade base
class BaseEntity: GKEntity {
    
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

// Componente de Sprite
class SpriteComponent: GKComponent {
    let node: SKSpriteNode
    
    init(texture: SKTexture) {
        self.node = SKSpriteNode(texture: texture)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Componente de Física
class PhysicsComponent: GKComponent {
    let physicsBody: SKPhysicsBody
    
    override init() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        super.init()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPhysics() {
        physicsBody.affectedByGravity = true
        physicsBody.categoryBitMask = 0x1 << 0
        physicsBody.collisionBitMask = 0x1 << 1
        physicsBody.contactTestBitMask = 0x1 << 1
    }
}

// Exemplo de Estado
class IdleState: GKState {
    weak var entity: BaseEntity?
    
    init(entity: BaseEntity) {
        self.entity = entity
    }
    
    override func didEnter(from previousState: GKState?) {
        // Configurações ao entrar no estado
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        // Lógica de atualização do estado
    }
    
    override func willExit(to nextState: GKState) {
        // Configurações ao sair do estado
    }
}
