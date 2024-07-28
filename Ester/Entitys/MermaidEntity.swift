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
    var directionSM: GKStateMachine
    var movementSM: GKStateMachine
    
    override init() {
        self.mermaid = Mermaid()
        self.directionSM = GKStateMachine(states: [])
        self.movementSM = GKStateMachine(states: [])
        super.init()
        setupComponents()
        setupStateMachines()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupStateMachines() {
        let idleState = MermaidIdleState(entity: self)
        let swingState = MermaidSwingState(entity: self)
        let fastState = MermaidFastState(entity: self)
        let upState = MermaidUpState(entity: self)
        let downState = MermaidDownState(entity: self)
        let rightState = MermaidRightState(entity: self)
        let leftState = MermaidLeftState(entity: self)
        
        directionSM = GKStateMachine(states: [
            upState,
            downState,
            rightState,
            leftState
        ])
        
        movementSM = GKStateMachine(states: [
            idleState,
            swingState,
            fastState,
        ])
        
        movementSM.enter(MermaidIdleState.self)
    }
    
    private func setupComponents() {
        let spriteComponent = BaseSpriteComponent(node: mermaid.base)
        self.addComponent(spriteComponent)
        
        let movementComponent = MovementComponent(baseClass: mermaid)
        self.addComponent(movementComponent)
    }
}
