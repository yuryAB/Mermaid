//
//  MermaidEyes.swift
//  Ester
//
//  Created by yury antony on 27/07/24.
//

import Foundation
import SpriteKit

class MermaidEyes {
    let base: SKNode
    let rightNode: SKNode
    let leftNode: SKNode
    let right: SKSpriteNode
    let left: SKSpriteNode
    
    init() {
        base = SKNode()
        rightNode = SKNode()
        leftNode = SKNode()
        right = SKSpriteNode(texture: SKTexture(imageNamed: "eye_open"))
        left = SKSpriteNode(texture: SKTexture(imageNamed: "eye_open"))
        left.xScale = -1.0
        
        rightNode.addChild(right)
        leftNode.addChild(left)
        base.addChild(rightNode)
        base.addChild(leftNode)
        setPositions()
    }
    
    func setPositions() {
        let xpos:CGFloat = 40
        rightNode.position.x = xpos
        leftNode.position.x = -xpos
    }
}
