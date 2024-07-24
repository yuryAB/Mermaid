//
//  Mermaid.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class Mermaid {
    var mermaid: SKSpriteNode
    var head = MermaidHead()
    var body = MermaidBody()
    var arms = MermaidArms()
    
    init() {
        mermaid = SKSpriteNode()
        
        body.mermBody.position.y = -670
        body.mermBody.zPosition = 1
        head.hairBackNode.addChild(body.mermBody)
        
        body.mermBody.addChild(arms.left)
        body.mermBody.addChild(arms.right)
        
        self.mermaid.addChild(head.headNode)
        
    }
}
