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
    var hairFrontNode: SKSpriteNode
    var hairBackNode: SKSpriteNode
    var base: SKSpriteNode
    
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
        
        base = SKSpriteNode(texture: SKTexture(imageNamed: "MermHairBack"))
        base.zPosition = -1
        base.color = .clear
        base.colorBlendFactor = 1.0
        base.addChild(hairBackNode)
        
        headNode.addChild(base)
    }
    
    private func hairBackAnimation() {
        let fill: SKAction = .scale(to: 1.07, duration: 0.8)
        let dry: SKAction = .scale(to: 1, duration: 0.8)
        
        let hairbackAnimation:SKAction = .repeatForever(.sequence([fill,dry]))
        hairbackAnimation.eaeInEaseOut()
        
        hairBackNode.run(hairbackAnimation)
    }
}

extension MermaidHead: MovementTypeProtocol {
    func applyIdleMoveMode() {
        hairBackAnimation()
        let idleAction = SKAction.group([
            .rotate(toDegrees: 0, duration: 0.5),
            .move(to: CGPoint.zero, duration: 0.5)])
        
        idleAction.eaeInEaseOut()
        
        self.base.run(idleAction)
        self.hairFrontNode.run(idleAction)
    }
    
    func applySwingMoveMode() { }
    
    func applyFastMoveMode() { }
}

extension MermaidHead: MovementDirectionProtocol {
    func setUpMoveMode() {
        let upActionForHairBack = SKAction.group([
            .rotate(toDegrees: 0, duration: 1),
            .move(to: CGPoint(x: 0, y: -25), duration: 0.5)])
        let upActionForHairFront = SKAction.move(to: CGPoint(x: 0, y: 15), duration: 0.5)
        
        upActionForHairBack.eaeInEaseOut()
        upActionForHairFront.eaeInEaseOut()
        
        self.base.run(upActionForHairBack)
        self.hairFrontNode.run(upActionForHairFront)
    }
    
    func setDownMoveMode() {
        let degree: CGFloat = CGFloat.pi
        
        let downActionForHairBack = SKAction.group([
            .rotate(toAngle: degree, duration: 1, shortestUnitArc: true),
            .move(to: CGPoint(x: 0, y: 150), duration: 1)])
        let downActionForHairfront = SKAction.move(to: CGPoint.zero, duration: 1)
        
        downActionForHairBack.eaeInEaseOut()
        downActionForHairfront.eaeInEaseOut()
        
        self.base.run(downActionForHairBack)
        self.hairFrontNode.run(downActionForHairfront)
    }
    
    func setRightMoveMode() {
        let rightActionForHairBack = SKAction.group([
            .rotate(toAngle: -CGFloat.pi / 2, duration: 1, shortestUnitArc: true),
            .move(to: CGPoint(x: -55, y: 55), duration: 1)])
        let rightActionForHairFront = SKAction.move(to: CGPoint.zero, duration: 1)
        
        rightActionForHairBack.eaeInEaseOut()
        rightActionForHairFront.eaeInEaseOut()
        
        self.base.run(rightActionForHairBack)
        self.hairFrontNode.run(rightActionForHairFront)
    }
    
    func setLeftMoveMode() {
        let leftActionForHairBack = SKAction.group([
            .rotate(toAngle: CGFloat.pi / 2, duration: 1, shortestUnitArc: true),
            .move(to: CGPoint(x: 55, y: 55), duration: 1)])
        let leftActionForHairFront = SKAction.move(to: CGPoint.zero, duration: 1)
        
        leftActionForHairBack.eaeInEaseOut()
        leftActionForHairFront.eaeInEaseOut()
        
        self.base.run(leftActionForHairBack)
        self.hairFrontNode.run(leftActionForHairFront)
    }
}
