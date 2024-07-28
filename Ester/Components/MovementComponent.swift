//
//  MovementComponent.swift
//  Ester
//
//  Created by yury antony on 28/07/24.
//

import Foundation
import GameplayKit

class MovementComponent<T: MovementTypeProtocol & MovementDirectionProtocol>: GKComponent {
    let baseClass: T
    
    init(baseClass: T) {
        self.baseClass = baseClass
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setIdleMoveMode() {
        baseClass.applyIdleMoveMode()
    }
    
    func setSwingMoveMode() {
        baseClass.applySwingMoveMode()
    }
    
    func setFastMoveMode() {
        baseClass.applyFastMoveMode()
    }
    
    func setUpMoveMode() {
        baseClass.setUpMoveMode()
    }
    
    func setDownMoveMode() {
        baseClass.setDownMoveMode()
    }
    
    func setRightMoveMode() {
        baseClass.setRightMoveMode()
    }
    
    func setLeftMoveMode() {
        baseClass.setLeftMoveMode()
    }
}
