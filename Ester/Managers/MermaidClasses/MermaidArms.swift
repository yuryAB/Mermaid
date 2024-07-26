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
    
    var rPosition = CGPoint(x: 80, y: 0)
    var lPosition = CGPoint(x: -80, y: 0)
    
    private enum Orientation {
        case horizontal
        case vertical
    }
    
    private enum Rotation {
        case up
        case down
    }
    
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
    }
}

//MARK: - MermaidMoveModeProtocol
extension MermaidArms: MermaidMoveModeProtocol {
    func setSwingMoveMode() {
        
    }
    
    func setFastMoveMode() {
        
    }
    
    func setIdleMoveMode() {
        removeAllAnimations()
        moveArms(to: .vertical)
        
        let armIdleAction = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: 5, duration: 3),
            .rotate(toDegrees: -5, duration: 3)]))
        
        right.zPosition = 0
        
        self.right.run(armIdleAction)
        self.left.run(armIdleAction)
    }
    
    func setDownMoveMode() {
        removeAllAnimations()
        moveArms(to: .vertical)
        rotateArms(to: .down)
        right.zPosition = 0
        left.zPosition = 0
        
        let moveRightArm = SKAction.move(to: CGPoint(x: rPosition.x, y: rPosition.y+200),
                                         duration: 1.0)
        let moveLeftArm = SKAction.move(to: CGPoint(x: lPosition.x, y: lPosition.y+200),
                                        duration: 1.0)
        
        right.run(moveRightArm)
        left.run(moveLeftArm)
    }
    
    func setUpMoveMode() {
        removeAllAnimations()
        moveArms(to: .vertical)
        rotateArms()
        
        let duration: Double = 0.5
        let firstDegree: CGFloat = 7
        let lastDegree: CGFloat = -7
        
        let sequenceR = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: firstDegree, duration: duration),
            .rotate(toDegrees: lastDegree, duration: duration+1)]))
        
        let sequenceL = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: -firstDegree, duration: duration),
            .rotate(toDegrees: -lastDegree, duration: duration+1)]))
        
        sequenceR.timingMode = .easeInEaseOut
        sequenceL.timingMode = .easeInEaseOut
        
        right.zPosition = 3
        
        right.run(sequenceR)
        left.run(sequenceL)
    }
    
    func setRightMoveMode() {
        removeAllAnimations()
        moveArms(to: .horizontal)
        rotateArms()
        right.zPosition = 0
        
    }
    
    func setLeftMoveMode() {
        removeAllAnimations()
        moveArms(to: .horizontal)
        rotateArms()
        right.zPosition = 0
        
    }
    
    private func moveArms(to position: Orientation) {
        var increment:CGFloat = 40
        
        if position == .vertical {
            increment = 0
        }
        
        let moveRightArm = SKAction.move(to: CGPoint(x: rPosition.x - increment, y: rPosition.y), 
                                         duration: 1.0)
        let moveLeftArm = SKAction.move(to: CGPoint(x: lPosition.x + increment, y: lPosition.y), 
                                        duration: 1.0)
        
        right.run(moveRightArm)
        left.run(moveLeftArm)
    }
    
    private func rotateArms(to rotation: Rotation = .up) {
        var degree:CGFloat = 0
        var zpos:CGFloat = 3
        
        if rotation == .down {
            degree = 180
            zpos = 0
        }
        
        let rotationRAction = SKAction.rotate(toDegrees: degree, duration: 1)
        let rotationLAction = SKAction.rotate(toDegrees: degree, duration: 1)
        
        right.zPosition = zpos
        left.zPosition = zpos
        
        right.run(rotationRAction)
        left.run(rotationLAction)
    }
    
    private func removeAllAnimations() {
        self.right.removeAllActions()
        self.left.removeAllActions()
    }
}
