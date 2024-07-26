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
}

extension MermaidHead: MermaidMoveModeProtocol {
    func setSwingMoveMode() {
        
    }
    
    func setFastMoveMode() {
        
    }
    
    func setIdleMoveMode() {
        if self.headpositon != .idle {
            let idleAction = SKAction.group([
                .rotate(toDegrees: 0, duration: 0.5),
                .move(to: CGPoint.zero, duration: 0.5)])
            
            idleAction.timingMode = .easeInEaseOut
            
            self.hairBackNode.run(idleAction)
            self.hairFrontNode.run(idleAction)
            self.headpositon = .idle
        }
    }
    
    func setUpMoveMode() {
        if self.headpositon != .up {
            let upActionForHairBack = SKAction.group([
                .rotate(toDegrees: 0, duration: 1),
                .move(to: CGPoint(x: 0, y: -25), duration: 0.5)])
            
            upActionForHairBack.timingMode = .easeInEaseOut
            
            self.hairBackNode.run(upActionForHairBack)
            
            let upActionForHairFront = SKAction.move(to: CGPoint(x: 0, y: 15), duration: 0.5)
            
            upActionForHairFront.timingMode = .easeInEaseOut
            
            self.hairFrontNode.run(upActionForHairFront)
            
            self.headpositon = .up
        }
    }
    
    func setDownMoveMode() {
        if self.headpositon != .down {
            let degree: CGFloat = (self.headpositon == .right) ? -CGFloat.pi : CGFloat.pi
            
            let downActionForHairBack = SKAction.group([
                .rotate(toAngle: degree, duration: 1, shortestUnitArc: true),
                .move(to: CGPoint(x: 0, y: 150), duration: 1)])
            
            downActionForHairBack.timingMode = .easeInEaseOut
            
            self.hairBackNode.run(downActionForHairBack)
            
            let downActionForHairfront = SKAction.move(to: CGPoint.zero, duration: 1)
            
            downActionForHairfront.timingMode = .easeInEaseOut
            
            self.hairFrontNode.run(downActionForHairfront)
            
            self.headpositon = .down
        }
    }

    func setRightMoveMode() {
        if self.headpositon != .right {
            let rightActionForHairBack = SKAction.group([
                .rotate(toAngle: -CGFloat.pi / 2, duration: 1, shortestUnitArc: true),
                .move(to: CGPoint(x: -55, y: 55), duration: 1)])
            
            rightActionForHairBack.timingMode = .easeInEaseOut
            
            self.hairBackNode.run(rightActionForHairBack)
            
            let rightActionForHairFront = SKAction.move(to: CGPoint.zero, duration: 1)
            
            rightActionForHairFront.timingMode = .easeInEaseOut
            
            self.hairFrontNode.run(rightActionForHairFront)
            
            self.headpositon = .right
        }
    }

    func setLeftMoveMode() {
        if self.headpositon != .left {
            let leftActionForHairBack = SKAction.group([
                .rotate(toAngle: CGFloat.pi / 2, duration: 1, shortestUnitArc: true),
                .move(to: CGPoint(x: 55, y: 55), duration: 1)])
            
            leftActionForHairBack.timingMode = .easeInEaseOut
            
            self.hairBackNode.run(leftActionForHairBack)
            
            let leftActionForHairFront = SKAction.move(to: CGPoint.zero, duration: 1)
            leftActionForHairFront.timingMode = .easeInEaseOut
            
            self.hairFrontNode.run(leftActionForHairFront)
            
            self.headpositon = .left
        }
    }
}
