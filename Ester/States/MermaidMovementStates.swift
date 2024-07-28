//
//  MermaidMovementStates.swift
//  Ester
//
//  Created by yury antony on 28/07/24.
//

import Foundation
import GameplayKit

//MARK: Idle state
class MermaidIdleState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setIdleMoveMode()
    }
}

//MARK: Swing state
class MermaidSwingState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setSwingMoveMode()
    }
}

//MARK: Fast state
class MermaidFastState: MermaidState {
    override func didEnter(from previousState: GKState?) {
        movementComponent?.setFastMoveMode()
    }
}
