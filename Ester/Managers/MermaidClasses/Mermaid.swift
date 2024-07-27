//
//  Mermaid.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class Mermaid {
    var mermaid: SKSpriteNode
    var head = MermaidHead()
    var body = MermaidBody()
    var arms = MermaidArms()
    var face = MermaidFace()
    
    init() {
        mermaid = SKSpriteNode()
        
        body.body.position.y = -220
        body.body.zPosition = 1
        head.headBase.addChild(body.body)
        
        face.base.zPosition = 3
        head.headNode.addChild(face.base)
        
        body.body.addChild(arms.left)
        body.body.addChild(arms.right)
        
        self.mermaid.addChild(head.headNode)
        
    }
}

extension Mermaid: MermaidMoveModeProtocol {
    func setSwingMoveMode() {
        body.setSwingMoveMode()
    }
    
    func setFastMoveMode() {
        body.setFastMoveMode()
    }
    
    func setIdleMoveMode() {
        arms.setIdleMoveMode()
        head.setIdleMoveMode()
        body.setIdleMoveMode()
    }
    
    func setUpMoveMode() {
        arms.setUpMoveMode()
        head.setUpMoveMode()
        body.setUpMoveMode()
    }
    
    func setDownMoveMode() {
        arms.setDownMoveMode()
        head.setDownMoveMode()
        body.setDownMoveMode()
    }
    
    func setRightMoveMode() {
        arms.setRightMoveMode()
        head.setRightMoveMode()
        body.setRightMoveMode()
    }
    
    func setLeftMoveMode() {
        arms.setLeftMoveMode()
        head.setLeftMoveMode()
        body.setLeftMoveMode()
    }
}
