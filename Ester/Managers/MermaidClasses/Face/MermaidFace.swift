//
//  MermaidFace.swift
//  Ester
//
//  Created by yury antony on 27/07/24.
//

import Foundation
import SpriteKit

class MermaidFace {
    let base:SKSpriteNode
    let eyebrows:MermaidEyebrows
    let eyes: MermaidEyes
    let mouth: MermaidMouth
    
    init() {
        base = SKSpriteNode()
        eyebrows = MermaidEyebrows()
        eyes = MermaidEyes()
        mouth = MermaidMouth()
        
        eyebrows.base.position.y = 45
        eyes.base.position.y = 15
        mouth.base.position.y = -15
        base.addChild(eyebrows.base)
        base.addChild(eyes.base)
        base.addChild(mouth.base)
    }
}

extension MermaidFace: MermaidMoveModeProtocol {
    func setIdleMoveMode() {
        let moveto:SKAction = .move(to: CGPoint(x: 0, y: 0), duration: 0.5)
        moveto.eaeInEaseOut()
        base.run(moveto)
    }
    
    func setSwingMoveMode() { }
    
    func setFastMoveMode() { }
    
    func setUpMoveMode() { 
        let moveto:SKAction = .move(to: CGPoint(x: 0, y: 40), duration: 0.5)
        moveto.eaeInEaseOut()
        base.run(moveto)
    }
    
    func setDownMoveMode() { 
        let moveto:SKAction = .move(to: CGPoint(x: 0, y: -10), duration: 0.5)
        moveto.eaeInEaseOut()
        base.run(moveto)
    }
    
    func setRightMoveMode() { 
        let moveto:SKAction = .move(to: CGPoint(x: 20, y: 0), duration: 0.5)
        moveto.eaeInEaseOut()
        base.run(moveto)
    }
    
    func setLeftMoveMode() { 
        let moveto:SKAction = .move(to: CGPoint(x: -20, y: 0), duration: 0.5)
        moveto.eaeInEaseOut()
        base.run(moveto)
    }
    
    
}
