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
    
     func eaeInEaseOut() {
        self.timingMode = .easeInEaseOut
    }
}
