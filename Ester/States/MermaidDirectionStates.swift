//
//  MermaidDirectionStates.swift
//  Ester
//
//  Created by yury antony on 28/07/24.
//

import Foundation
import GameplayKit

class MermaidState: GKState {
    unowned let entity: MermaidEntity

    init(entity: MermaidEntity) {
        self.entity = entity
    }

    var movementComponent: MovementComponent<Mermaid>? {
        return entity.component(ofType: MovementComponent.self)
    }
}

class MermaidUpState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        print("chegou MermaidUpState didEnter")
        movementComponent?.setUpMoveMode()
    }
}

class MermaidDownState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setDownMoveMode()
    }
}

class MermaidLeftState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setLeftMoveMode()
    }
}

class MermaidRightState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setRightMoveMode()
    }
}
