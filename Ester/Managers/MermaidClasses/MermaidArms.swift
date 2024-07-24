//
//  MermaidArms.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class MermaidArms {
    var right: SKSpriteNode
    var left: SKSpriteNode
    
    var rPosition = CGPoint(x: 85, y: 510)
    var lPosition = CGPoint(x: -85, y: 510)
    
    internal var armMoveMode: MermaidMoveMode = .right
    
    init() {
        right = SKSpriteNode(texture: SKTexture(imageNamed: "hand1"))
        right.color = ColorManager.shared.upper["skinColor"]!
        right.colorBlendFactor = 1.0
        right.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        right.position = rPosition
        
        left = SKSpriteNode(texture: SKTexture(imageNamed: "hand2"))
        left.color = ColorManager.shared.upper["skinColor"]!
        left.colorBlendFactor = 1.0
        left.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        left.zPosition = 3
        left.position = lPosition
        
        setIdleMoveMode()
    }
}

extension MermaidArms: MermaidMoveModeProtocol {
    func setIdleMoveMode() {
        if self.armMoveMode != .idle {
            let rotateRight = SKAction.rotate(toDegrees: 5, duration: 3)
            let rotateLeft = SKAction.rotate(toDegrees: -5, duration: 3)
            let sequence = SKAction.sequence([rotateRight, rotateLeft])
            let repeatAction = SKAction.repeatForever(sequence)
            
            right.run(repeatAction)
            left.run(repeatAction)
            
            self.armMoveMode = .idle
        }
    }
    
    func setRightMoveMode() {
        if self.armMoveMode != .right {
            let moveRightArm = SKAction.move(to: CGPoint(x: rPosition.x - 40, y: rPosition.y), duration: 1.0)
            let moveLeftArm = SKAction.move(to: CGPoint(x: lPosition.x + 40, y: lPosition.y), duration: 1.0)
            
            right.run(moveRightArm)
            left.run(moveLeftArm)
            
            self.armMoveMode = .right
        }
    }
    
    func setLeftMoveMode() {
        <#code#>
    }
    
    func setDownMoveMode() {
        <#code#>
    }
    
    func setUpMoveMode() {
        <#code#>
    }
    
}
