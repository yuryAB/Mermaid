//
//  Mermaid.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class Mermaid {
    var base: SKSpriteNode
    var head = MermaidHead()
    var body = MermaidBody()
    var arms = MermaidArms()
    var face = MermaidFace()
    
    init() {
        base = SKSpriteNode()
        
        body.body.position.y = -220
        body.body.zPosition = 1
        head.base.addChild(body.body)
        
        face.base.zPosition = 3
        head.headNode.addChild(face.base)
        
        body.body.addChild(arms.left)
        body.body.addChild(arms.right)
        
        self.base.addChild(head.headNode)
        
    }
}

extension Mermaid: MovementTypeProtocol {
    func setIdleMoveMode() {
        arms.setIdleMoveMode()
        head.setIdleMoveMode()
        body.setIdleMoveMode()
        face.setIdleMoveMode()
    }
    
    func setSwingMoveMode() {
        body.setSwingMoveMode()
    }
    
    func setFastMoveMode() {
        body.setFastMoveMode()
    }
}

extension Mermaid: MovementDirectionProtocol {
    func setUpMoveMode() {
        arms.setUpMoveMode()
        head.setUpMoveMode()
        body.setUpMoveMode()
        face.setUpMoveMode()
    }
    
    func setDownMoveMode() {
        arms.setDownMoveMode()
        head.setDownMoveMode()
        body.setDownMoveMode()
        face.setDownMoveMode()
    }
    
    func setRightMoveMode() {
        arms.setRightMoveMode()
        head.setRightMoveMode()
        body.setRightMoveMode()
        face.setRightMoveMode()
    }
    
    func setLeftMoveMode() {
        arms.setLeftMoveMode()
        head.setLeftMoveMode()
        body.setLeftMoveMode()
        face.setLeftMoveMode()
    }
}
