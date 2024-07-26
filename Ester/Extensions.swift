//
//  Extensions.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

//MARK: - SKAction
extension SKAction {
    static func rotate(toDegrees degrees: CGFloat, duration: TimeInterval) -> SKAction {
        let radians = degrees * (.pi / 180)
        return SKAction.rotate(toAngle: radians, duration: duration)
    }
}

//MARK: - SKSpriteNode
extension SKSpriteNode {
    func updateAnimation(with textures: [SKTexture], timePerFrame: TimeInterval) {
        let animation = SKAction.animate(with: textures, timePerFrame: timePerFrame)
        self.removeAllActions()
        self.run(SKAction.repeatForever(animation))
    }
}

import SpriteKit

extension SKSpriteNode {
    func updateAnimationSmoothly(with animationType: AnimationType, newTimePerFrame: TimeInterval) {
        let animation = SKAction.animate(with: animationType.textures, timePerFrame: newTimePerFrame)
        self.removeAllActions()
        self.run(SKAction.repeatForever(animation), withKey: animationType.rawValue)
        
    }
}
