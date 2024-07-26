//
//  MermaidBody2.swift
//  Ester
//
//  Created by yury antony on 24/07/24.
//

import Foundation
import SpriteKit

class MermaidBody {
    let body: SKSpriteNode
    let waist: SKSpriteNode
    let articulation: SKSpriteNode
    let waistFront: SKSpriteNode
    let finBack: SKSpriteNode
    let finFront: SKSpriteNode
    
    init() {
        body = SKSpriteNode(imageNamed: "roundPiece")
        waist = SKSpriteNode(imageNamed: "roundPiece")
        articulation = SKSpriteNode(imageNamed: "roundPiece")
        waistFront = SKSpriteNode(imageNamed: "waist")
        finBack = SKSpriteNode(imageNamed: "finBack")
        finFront = SKSpriteNode(imageNamed: "finFront")
        
        setupNodes()
        setupPositions()
        setupZPositions()
        setupAnchorPoints()
        setupColors()
        addChildren()
    }
    
    private func setupNodes() {
        body.setScale(1.2)
        waist.setScale(0.9)
        articulation.setScale(0.9)
        finBack.setScale(1.1)
    }
    
    private func setupPositions() {
        let yPos: CGFloat = -230
        waist.position.y = yPos
        articulation.position.y = yPos
        finBack.position.y = -150
    }
    
    private func setupZPositions() {
        waistFront.zPosition = 1
        finFront.zPosition = 1
    }
    
    private func setupAnchorPoints() {
        finBack.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        finFront.anchorPoint = CGPoint(x: 0.5, y: 1.0)
    }
    
    private func setupColors() {
        body.color = ColorManager.shared.upper["skinColor"]!
        waist.color = ColorManager.shared.upper["skinColor"]!
        articulation.color = ColorManager.shared.upper["vibrant1"]!
        waistFront.color = ColorManager.shared.upper["vibrant1"]!
        finFront.color = ColorManager.shared.upper["vibrant1"]!
        finBack.color = ColorManager.shared.upper["vibrant2"]!
        
        body.colorBlendFactor = 1.0
        waist.colorBlendFactor = 1.0
        articulation.colorBlendFactor = 1.0
        waistFront.colorBlendFactor = 1.0
        finFront.colorBlendFactor = 1.0
        finBack.colorBlendFactor = 1.0
    }
    
    private func addChildren() {
        body.addChild(waist)
        waist.addChild(articulation)
        waist.addChild(waistFront)
        articulation.addChild(finBack)
        finBack.addChild(finFront)
    }
    
    private func swingAnimation(degrees: CGFloat, duration: Double ) -> SKAction {
        let rotateL = SKAction.rotate(toDegrees: degrees, duration: duration)
        let rotateR = SKAction.rotate(toDegrees: -degrees, duration: duration)
        let swing = SKAction.repeatForever(.sequence([rotateL,rotateR]))
        swing.timingMode = .easeInEaseOut
        
        return swing
    }
}

extension MermaidBody: MermaidMoveModeProtocol {
    func setSwingMoveMode() {
        removeAllAnimations()
        body.run(swingAnimation(degrees: 4, duration: 0.4))
        waist.run(swingAnimation(degrees: 4, duration: 0.4))
        articulation.run(swingAnimation(degrees: 4, duration: 0.4))
        finBack.run(swingAnimation(degrees: 7, duration: 0.4))
    }
    
    func setFastMoveMode() {
        removeAllAnimations()
        body.run(swingAnimation(degrees: 8, duration: 0.3))
        waist.run(swingAnimation(degrees: 8, duration: 0.3))
        articulation.run(swingAnimation(degrees: 8, duration: 0.3))
        finBack.run(swingAnimation(degrees: 20, duration: 0.2))
    }
    
    func setIdleMoveMode() {
        removeAllAnimations()
        body.run(swingAnimation(degrees: 5, duration: 2))
        waist.run(swingAnimation(degrees: 5, duration: 2))
        articulation.run(swingAnimation(degrees: 5, duration: 2))
        finBack.run(swingAnimation(degrees: 5, duration: 2))
        body.run(bodyZPosition())
    }
    
    func setRightMoveMode() {
        body.run(bodyZPosition())
    }
    
    func setLeftMoveMode() {
        body.run(bodyZPosition())
    }
    
    func setUpMoveMode() {
        body.run(bodyZPosition())
    }
    
    func setDownMoveMode() {
        body.run(bodyZPosition(isUp: false))
    }
    
    private func removeAllAnimations() {
        body.removeAllActions()
        waist.removeAllActions()
        articulation.removeAllActions()
        finBack.removeAllActions()
    }
    
    func bodyZPosition(isUp: Bool = true) -> SKAction {
        let position = isUp ?  CGFloat(1) : CGFloat(-1)
        let wait = SKAction.wait(forDuration: 0.5)
        let changeZPositionAction = SKAction.run {
            self.body.zPosition = position
        }
        return SKAction.sequence([wait,changeZPositionAction])
    }
}
