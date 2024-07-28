//
//  MermaidEyes.swift
//  Ester
//
//  Created by yury antony on 27/07/24.
//

import Foundation
import SpriteKit

class MermaidEyes {
    let base:SKSpriteNode
    let right:SKSpriteNode
    let left:SKSpriteNode
    
    init() {
        base = SKSpriteNode()
        right = SKSpriteNode(texture: SKTexture(imageNamed: "eye"))
        left = SKSpriteNode(texture: SKTexture(imageNamed: "eye"))
        left.xScale = -1.0
        
        base.addChild(right)
        base.addChild(left)
        setPositions()
    }
    
    func setPositions() {
        let xpos:CGFloat = 40
        right.position.x = xpos
        left.position.x = -xpos
    }
}
