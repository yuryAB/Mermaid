//
//  MermaidMoveModeProtocol .swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import SpriteKit

protocol MermaidMoveModeProtocol {
    var armMoveMode: MermaidMoveMode { get set }
    var right: SKSpriteNode { get }
    var left: SKSpriteNode { get }
    var rPosition: CGPoint { get }
    var lPosition: CGPoint { get }
    
    func setIdleMoveMode()
    func setRightMoveMode()
    func setLeftMoveMode()
    func setDownMoveMode()
    func setUpMoveMode()
    func setPositionForTest()
}

extension MermaidMoveModeProtocol {
    func setPositionForTest() {
        switch self.armMoveMode {
        case .idle:
            self.setRightMoveMode()
        case .up:
            self.setLeftMoveMode()
        case .down:
            self.setIdleMoveMode()
        case .right:
            setUpMoveMode()
        case .left:
            setDownMoveMode()
        }
    }
}
