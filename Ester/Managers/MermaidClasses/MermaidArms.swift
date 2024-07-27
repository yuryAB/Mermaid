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
    
    private func moveArms(to position: Orientation) {
        let increment:CGFloat = (position == .vertical) ? 0 : 45
        
        let moveRightArm = SKAction.move(to: CGPoint(x: rPosition.x - increment, y: rPosition.y),
                                         duration: 1.0)
        let moveLeftArm = SKAction.move(to: CGPoint(x: lPosition.x + increment, y: lPosition.y),
                                        duration: 1.0)
        
        moveRightArm.eaeInEaseOut()
        moveLeftArm.eaeInEaseOut()
        
        right.run(moveRightArm)
        left.run(moveLeftArm)
    }
    
    private func leftArmRotationAction(to rotation: Rotation = .up) -> SKAction {
        let degree: CGFloat = (rotation == .down) ? 180 : 0
        let rotate:SKAction = .rotate(toDegrees: -degree, duration: 1)
        rotate.eaeInEaseOut()
        
        return rotate
    }
    
    private func rightArmRotationAction(to rotation: Rotation = .up) -> SKAction {
        let degree: CGFloat = (rotation == .down) ? 180 : 0
        let rotate:SKAction = .rotate(toDegrees: degree, duration: 1)
        rotate.eaeInEaseOut()
        
        return rotate
    }
    
    func armZposition(rightZ:CGFloat, leftZ:CGFloat) {
        right.zPosition = rightZ
        left.zPosition = leftZ
    }
    
    private func removeAllAnimations() {
        self.right.removeAllActions()
        self.left.removeAllActions()
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
        armZposition(rightZ: -1, leftZ: 3)
        
        let armIdleAction = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: 5, duration: 3),
            .rotate(toDegrees: -5, duration: 3)]))
        
        armIdleAction.eaeInEaseOut()
        
        self.right.run(armIdleAction)
        self.left.run(armIdleAction)
    }
    
    func setDownMoveMode() {
        removeAllAnimations()
        moveArms(to: .vertical)
        armZposition(rightZ: -3, leftZ: -3)
        
        let movedown:SKAction = .moveTo(y: rPosition.y+200, duration: 1.0)
        let moveup:SKAction = .moveTo(y: rPosition.y, duration: 0.5)
        
        let rArmDown:SKAction = .group([rightArmRotationAction(to: .down),movedown])
        
        let lArmDown:SKAction = .group([leftArmRotationAction(to: .down),movedown])
        
        let wait:SKAction = .wait(forDuration: 3)
        
        let rArmUp:SKAction = .group([rightArmRotationAction(),moveup])
        let lArmUp:SKAction = .group([leftArmRotationAction(),moveup])
        
        let swing:SKAction = .repeatForever(.sequence([
            .rotate(toDegrees: 6, duration: 1),
            .rotate(toDegrees: -6, duration: 1)]))
        
        let rArmDownUp:SKAction = .sequence([rArmDown, wait, rArmUp, swing])
        let lArmDownUp:SKAction = .sequence([lArmDown, wait, lArmUp, swing])
        
        right.run(rArmDownUp)
        left.run(lArmDownUp)
    }
    
    func setUpMoveMode() {
        removeAllAnimations()
        moveArms(to: .vertical)
        armZposition(rightZ: 3, leftZ: 3)
        
        let duration: Double = 0.5
        let firstDegree: CGFloat = 7
        let lastDegree: CGFloat = -7
        
        let sequenceR = SKAction.repeatForever(.sequence([
            rightArmRotationAction(),
            .rotate(toDegrees: firstDegree, duration: duration),
            .rotate(toDegrees: lastDegree, duration: duration+1)]))
        
        let sequenceL = SKAction.repeatForever(.sequence([
            leftArmRotationAction(),
            .rotate(toDegrees: -firstDegree, duration: duration),
            .rotate(toDegrees: -lastDegree, duration: duration+1)]))
        
        sequenceR.eaeInEaseOut()
        sequenceL.eaeInEaseOut()
        
        right.run(sequenceR)
        left.run(sequenceL)
    }
    
    func setRightMoveMode() {
        removeAllAnimations()
        moveArms(to: .horizontal)
        armZposition(rightZ: -1, leftZ: 3)
        
        let duration: Double = 1
        let firstDegree: CGFloat = 5
        let lastDegree: CGFloat = -12
        
        let rightMoveModeAction = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: -firstDegree, duration: duration),
            .rotate(toDegrees: -lastDegree, duration: duration+1)]))
        
        rightMoveModeAction.eaeInEaseOut()
        
        right.run(rightArmRotationAction())
        right.run(rightMoveModeAction)
        
        left.run(leftArmRotationAction())
        left.run(rightMoveModeAction)
    }
    
    func setLeftMoveMode() {
        removeAllAnimations()
        moveArms(to: .horizontal)
        armZposition(rightZ: -1, leftZ: 3)
        
        let duration: Double = 1
        let firstDegree: CGFloat = 5
        let lastDegree: CGFloat = -12
        
        let rightMoveModeAction = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: firstDegree, duration: duration),
            .rotate(toDegrees: lastDegree, duration: duration+1)]))
        
        rightMoveModeAction.eaeInEaseOut()
        
        right.run(rightArmRotationAction())
        right.run(rightMoveModeAction)
        
        left.run(leftArmRotationAction())
        left.run(rightMoveModeAction)
    }
}
