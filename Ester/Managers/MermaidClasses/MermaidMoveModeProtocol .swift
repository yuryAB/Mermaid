//
//  MermaidMoveModeProtocol .swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import SpriteKit

protocol MermaidMoveModeProtocol {
    func setIdleMoveMode()
    func setSwingMoveMode()
    func setFastMoveMode()
    func setUpMoveMode()
    func setDownMoveMode()
    func setRightMoveMode()
    func setLeftMoveMode()
}

enum MermaidMoveMode {
    case idle
    case swing
    case fast
    case up
    case down
    case right
    case left
}
