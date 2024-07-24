//
//  MermaidHead.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class MermaidHead {
    var headNode: SKSpriteNode
    
    private var hairFrontNode: SKSpriteNode
    var hairBackNode: SKSpriteNode
    private var headpositon: MermaidMoveMode = .idle
    
    
    init() {
        headNode = SKSpriteNode(texture: SKTexture(imageNamed: "MermHead"))
        headNode.color = ColorManager.shared.upper["skinColor"]!
        headNode.colorBlendFactor = 1.0
        
        hairFrontNode = SKSpriteNode(texture: SKTexture(imageNamed: "MermHairFront"))
        hairFrontNode.zPosition = 1
        hairFrontNode.color = ColorManager.shared.upper["hairColor"]!
        hairFrontNode.colorBlendFactor = 1.0
        headNode.addChild(hairFrontNode)
        
        hairBackNode = SKSpriteNode(texture: SKTexture(imageNamed: "MermHairBack"))
        hairBackNode.zPosition = -1
        hairBackNode.color = ColorManager.shared.upper["hairColor"]!
        hairBackNode.colorBlendFactor = 1.0
        headNode.addChild(hairBackNode)
    }
    
    func setIdleMoveMode() {
        if self.headpositon != .idle {
            let rotateAction = SKAction.rotate(toDegrees: 0, duration: 1)
            let posAction = SKAction.move(to: CGPoint.zero, duration: 1)
            let idleAction = SKAction.group([rotateAction,posAction])
            self.hairBackNode.run(idleAction)
            self.hairFrontNode.run(idleAction)
            self.headpositon = .idle
        }
        
    }
    
    func setRightMoveMode() {
        if self.headpositon != .right {
            
            let rotateAction = SKAction.rotate(toDegrees: -90, duration: 1)
            let posAction = SKAction.move(to: CGPoint(x: -55, y: 55), duration: 1)
            
            let swingPosition = SKAction.group([rotateAction,posAction])
            self.hairBackNode.run(swingPosition)
            
            let frontPosAction = SKAction.move(to: CGPoint.zero, duration: 1)
            self.hairFrontNode.run(frontPosAction)
            
            self.headpositon = .right
        }
    }
    
    func setLeftMoveMode() {
        if self.headpositon != .left {
            
            let rotateAction = SKAction.rotate(toDegrees: 90, duration: 1)
            let posAction = SKAction.move(to: CGPoint(x: 55, y: 55), duration: 1)
            
            let swingPosition = SKAction.group([rotateAction,posAction])
            self.hairBackNode.run(swingPosition)
            
            let frontPosAction = SKAction.move(to: CGPoint.zero, duration: 1)
            self.hairFrontNode.run(frontPosAction)
            
            self.headpositon = .left
        }
    }
    
    func setDownMoveMode() {
        if self.headpositon != .down {
            var degree:CGFloat = 0
            
            if self.headpositon == .right {
                degree = -180
            } else {degree = 180 }
            
            let rotateAction = SKAction.rotate(toDegrees: degree, duration: 1)
            let posAction = SKAction.move(to: CGPoint(x: 0, y: 150), duration: 1)
            
            let downAction = SKAction.group([rotateAction,posAction])
            self.hairBackNode.run(downAction)
            
            let frontPosAction = SKAction.move(to: CGPoint.zero, duration: 1)
            self.hairFrontNode.run(frontPosAction)
            
            self.headpositon = .down
        }
    }
    
    func setUpMoveMode() {
        if self.headpositon != .up {
            let rotateAction = SKAction.rotate(toDegrees: 0, duration: 1)
            let posAction = SKAction.move(to: CGPoint(x: 0, y: -25), duration: 1)
            let upActionForBack = SKAction.group([rotateAction,posAction])
            self.hairBackNode.run(upActionForBack)
            
            let frontPosAction = SKAction.move(to: CGPoint(x: 0, y: 15), duration: 1)
            self.hairFrontNode.run(frontPosAction)
            
            self.headpositon = .up
        }
    }
    
    func setPositionForTest() {
        switch self.headpositon {
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


enum MermaidMoveMode {
    case idle
    case right
    case left
    case up
    case down
}
