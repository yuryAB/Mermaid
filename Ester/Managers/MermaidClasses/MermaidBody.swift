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
    /// Segmento adicional da cauda, exclusivo da forma adulta.
    private(set) var extraSegment: SKSpriteNode?
    private struct MotionProfile {
        let bodyDegree: CGFloat
        let bodyDuration: Double
        let waistDegree: CGFloat
        let waistDuration: Double
        let articulationDegree: CGFloat
        let articulationDuration: Double
        let finDegree: CGFloat
        let finDuration: Double
    }
    private var currentProfile = MotionProfile(bodyDegree: 5, bodyDuration: 2,
                                               waistDegree: 5.5, waistDuration: 2,
                                               articulationDegree: 6, articulationDuration: 2,
                                               finDegree: 6.5, finDuration: 2)
    private struct DirectionalCore {
        let bodyCenter: CGFloat
        let waistCenter: CGFloat
        let articulationCenter: CGFloat
        let finCenter: CGFloat
        let bodyZ: CGFloat
    }
    private var currentDirectionalCore = DirectionalCore(bodyCenter: 0,
                                                         waistCenter: 0,
                                                         articulationCenter: 0,
                                                         finCenter: 0,
                                                         bodyZ: 1)
    
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
    
    private func swingAnimation(centerDegrees: CGFloat = 0,
                                degrees: CGFloat,
                                duration: Double ) -> SKAction {
        let rotateL = SKAction.rotate(toDegrees: centerDegrees + degrees, duration: duration)
        let rotateR = SKAction.rotate(toDegrees: centerDegrees - degrees, duration: duration)
        let swing = SKAction.repeatForever(.sequence([rotateL,rotateR]))
        swing.eaeInEaseOut()
        
        return swing
    }
    
    func runSwingAnimation(bodyDegree:CGFloat, bodyDuration:Double,
                           waistDegree:CGFloat, waistDuration:Double,
                           articulationDegree:CGFloat, articulationDuration:Double,
                           finDegree:CGFloat, finDuration:Double,
                           bodyCenter: CGFloat = 0,
                           waistCenter: CGFloat = 0,
                           articulationCenter: CGFloat = 0,
                           finCenter: CGFloat = 0) {
        
        let wait = SKAction.wait(forDuration: 0.1)
        body.run(swingAnimation(centerDegrees: bodyCenter, degrees: bodyDegree, duration: bodyDuration))
        waist.run(.sequence([wait, swingAnimation(centerDegrees: waistCenter,
                                                  degrees: waistDegree,
                                                  duration: waistDuration)]))
        articulation.run(.sequence([wait,swingAnimation(centerDegrees: articulationCenter,
                                                        degrees: articulationDegree,
                                                        duration: articulationDuration)]))
        extraSegment?.run(.sequence([wait, swingAnimation(centerDegrees: articulationCenter * 1.15,
                                                          degrees: finDegree * 0.85,
                                                          duration: finDuration)]))
        fin.run(.sequence([wait,swingAnimation(centerDegrees: finCenter,
                                               degrees: finDegree,
                                               duration: finDuration)]))
    }

    private func removeAllAnimations() {
        body.removeAllActions()
        waist.removeAllActions()
        articulation.removeAllActions()
        extraSegment?.removeAllActions()
        fin.removeAllActions()
    }
    
    /// Forma adulta: um segmento arredondado a mais e cauda maior.
    func setAdultExtension(_ enabled: Bool) {
        if enabled {
            guard extraSegment == nil else { return }
            let segment = SKSpriteNode(imageNamed: "roundPiece")
            segment.setScale(0.85)
            segment.position.y = -200
            segment.color = articulation.color
            segment.colorBlendFactor = 1.0
            articulation.addChild(segment)

            fin.removeFromParent()
            segment.addChild(fin)
            fin.position.y = -140
            fin.setScale(1.25)
            extraSegment = segment
        } else if let segment = extraSegment {
            fin.removeFromParent()
            articulation.addChild(fin)
            fin.position.y = -150
            fin.setScale(1.1)
            segment.removeFromParent()
            extraSegment = nil
        }
    }

    func bodyZPosition(isDownMoveMode: Bool = false) -> SKAction {
        let position = isDownMoveMode ?  CGFloat(-2) : CGFloat(1)
        let wait = SKAction.wait(forDuration: 0.5)
        let changeZPositionAction = SKAction.run {
            self.body.zPosition = position
        }
        
        let sequence = SKAction.sequence([wait,changeZPositionAction])
        
        sequence.eaeInEaseOut()
        
        return sequence
    }

    private func applyMotion(_ profile: MotionProfile,
                             directionalCore: DirectionalCore? = nil) {
        currentProfile = profile
        if let directionalCore {
            currentDirectionalCore = directionalCore
        }
        body.zPosition = currentDirectionalCore.bodyZ
        removeAllAnimations()
        runSwingAnimation(bodyDegree: profile.bodyDegree,
                          bodyDuration: profile.bodyDuration,
                          waistDegree: profile.waistDegree,
                          waistDuration: profile.waistDuration,
                          articulationDegree: profile.articulationDegree,
                          articulationDuration: profile.articulationDuration,
                          finDegree: profile.finDegree,
                          finDuration: profile.finDuration,
                          bodyCenter: currentDirectionalCore.bodyCenter,
                          waistCenter: currentDirectionalCore.waistCenter,
                          articulationCenter: currentDirectionalCore.articulationCenter,
                          finCenter: currentDirectionalCore.finCenter)
    }

    private func applyDirectionalCore(bodyCenter: CGFloat,
                                      waistCenter: CGFloat,
                                      articulationCenter: CGFloat,
                                      finCenter: CGFloat,
                                      bodyZ: CGFloat = 1) {
        let core = DirectionalCore(bodyCenter: bodyCenter,
                                   waistCenter: waistCenter,
                                   articulationCenter: articulationCenter,
                                   finCenter: finCenter,
                                   bodyZ: bodyZ)
        applyMotion(currentProfile, directionalCore: core)
    }
}

extension MermaidBody: MovementTypeProtocol {
    func applyIdleMoveMode() {
        applyMotion(MotionProfile(bodyDegree: 5, bodyDuration: 2,
                                  waistDegree: 5.5, waistDuration: 2,
                                  articulationDegree: 6, articulationDuration: 2,
                                  finDegree: 6.5, finDuration: 2),
                    directionalCore: DirectionalCore(bodyCenter: 0,
                                                     waistCenter: 0,
                                                     articulationCenter: 0,
                                                     finCenter: 0,
                                                     bodyZ: 1))
    }
    
    func applySwingMoveMode() {
        applyMotion(MotionProfile(bodyDegree: 5, bodyDuration: 0.5,
                                  waistDegree: 6, waistDuration: 0.5,
                                  articulationDegree: 7, articulationDuration: 0.5,
                                  finDegree: 8, finDuration: 0.5))
    }
    
    func applyFastMoveMode() {
        applyMotion(MotionProfile(bodyDegree: 5, bodyDuration: 0.2,
                                  waistDegree: 5, waistDuration: 0.2,
                                  articulationDegree: 5, articulationDuration: 0.2,
                                  finDegree: 6, finDuration: 0.1))
        
    }
}

extension MermaidBody: MovementDirectionProtocol {
    func setUpMoveMode() {
        applyDirectionalCore(bodyCenter: 0,
                             waistCenter: 0,
                             articulationCenter: 0,
                             finCenter: 0)
    }
    
    func setDownMoveMode() {
        applyDirectionalCore(bodyCenter: 0,
                             waistCenter: 0,
                             articulationCenter: 0,
                             finCenter: 0,
                             bodyZ: -2)
    }
    
    func setRightMoveMode() {
        applyDirectionalCore(bodyCenter: 0,
                             waistCenter: 0,
                             articulationCenter: 0,
                             finCenter: 0)
    }
    
    func setLeftMoveMode() {
        applyDirectionalCore(bodyCenter: 0,
                             waistCenter: 0,
                             articulationCenter: 0,
                             finCenter: 0)
    }
}
