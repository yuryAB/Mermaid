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
    let waistScale: SKSpriteNode
    let fin: SKSpriteNode
    let finScale: SKSpriteNode
    
    init() {
        body = SKSpriteNode(imageNamed: "roundPiece")
        waist = SKSpriteNode(imageNamed: "roundPiece")
        articulation = SKSpriteNode(imageNamed: "roundPiece")
        waistScale = SKSpriteNode(imageNamed: "waist")
        fin = SKSpriteNode(imageNamed: "finBack")
        finScale = SKSpriteNode(imageNamed: "finFront")
        
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
        fin.setScale(1.1)
    }
    
    private func setupPositions() {
        let yPos: CGFloat = -230
        waist.position.y = yPos
        articulation.position.y = yPos
        fin.position.y = -150
    }
    
    private func setupZPositions() {
        waistScale.zPosition = 1
        finScale.zPosition = 1
    }
    
    private func setupAnchorPoints() {
        fin.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        finScale.anchorPoint = CGPoint(x: 0.5, y: 1.0)
    }
    
    private func setupColors() {
        body.color = ColorManager.shared.upper["skinColor"]!
        waist.color = ColorManager.shared.upper["skinColor"]!
        articulation.color = ColorManager.shared.upper["vibrant1"]!
        waistScale.color = ColorManager.shared.upper["vibrant1"]!
        finScale.color = ColorManager.shared.upper["vibrant1"]!
        fin.color = ColorManager.shared.upper["vibrant2"]!
        
        body.colorBlendFactor = 1.0
        waist.colorBlendFactor = 1.0
        articulation.colorBlendFactor = 1.0
        waistScale.colorBlendFactor = 1.0
        finScale.colorBlendFactor = 1.0
        fin.colorBlendFactor = 1.0
    }
    
    private func addChildren() {
        body.addChild(waist)
        waist.addChild(articulation)
        waist.addChild(waistScale)
        articulation.addChild(fin)
        fin.addChild(finScale)
    }
    
    private func swingAnimation(degrees: CGFloat, duration: Double ) -> SKAction {
        let rotateL = SKAction.rotate(toDegrees: degrees, duration: duration)
        let rotateR = SKAction.rotate(toDegrees: -degrees, duration: duration)
        let swing = SKAction.repeatForever(.sequence([rotateL,rotateR]))
        swing.timingMode = .easeInEaseOut
        
        return swing
    }
    
    func runSwingAnimation(bodyDegree:CGFloat, bodyDuration:Double,
                           waistDegree:CGFloat, waistDuration:Double,
                           articulationDegree:CGFloat, articulationDuration:Double,
                           finDegree:CGFloat, finDuration:Double) {
        
        let wait = SKAction.wait(forDuration: 0.1)
        body.run(swingAnimation(degrees: bodyDegree, duration: bodyDuration))
        waist.run(.sequence([wait, swingAnimation(degrees: waistDegree, duration: waistDuration)]))
        articulation.run(.sequence([wait,swingAnimation(degrees: articulationDegree, duration: articulationDuration)]))
        fin.run(.sequence([wait,swingAnimation(degrees: finDegree, duration: finDuration)]))
    }
    
    private func removeAllAnimations() {
        body.removeAllActions()
        waist.removeAllActions()
        articulation.removeAllActions()
        fin.removeAllActions()
    }
    
    func bodyZPosition(isDownMoveMode: Bool = false) -> SKAction {
        let position = isDownMoveMode ?  CGFloat(-1) : CGFloat(1)
        let wait = SKAction.wait(forDuration: 0.5)
        let changeZPositionAction = SKAction.run {
            self.body.zPosition = position
        }
        return SKAction.sequence([wait,changeZPositionAction])
    }
}

extension MermaidBody: MermaidMoveModeProtocol {
    func setSwingMoveMode() {
        removeAllAnimations()
        runSwingAnimation(bodyDegree: 5, bodyDuration: 0.5,
                          waistDegree: 6, waistDuration: 0.5,
                          articulationDegree: 7, articulationDuration: 0.5,
                          finDegree: 8, finDuration: 0.5)
    }
    
    func setFastMoveMode() {
        removeAllAnimations()
        runSwingAnimation(bodyDegree: 5, bodyDuration: 0.2,
                          waistDegree: 5, waistDuration: 0.2,
                          articulationDegree: 5, articulationDuration: 0.2,
                          finDegree: 6, finDuration: 0.1)
        
    }
    
    func setIdleMoveMode() {
        removeAllAnimations()
        body.run(bodyZPosition())
        runSwingAnimation(bodyDegree: 5, bodyDuration: 2,
                          waistDegree: 5.5, waistDuration: 2,
                          articulationDegree: 6, articulationDuration: 2,
                          finDegree: 6.5, finDuration: 2)
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
        body.run(bodyZPosition(isDownMoveMode: true))
    }
}
