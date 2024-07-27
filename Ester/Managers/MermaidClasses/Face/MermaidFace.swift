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

class MermaidEyebrows {
    let base:SKSpriteNode
    let right:SKSpriteNode
    let left:SKSpriteNode
    
    init() {
        base = SKSpriteNode()
        right = SKSpriteNode(texture: SKTexture(imageNamed: "eyeBrow"))
        left = SKSpriteNode(texture: SKTexture(imageNamed: "eyeBrow"))
        base.addChild(right)
        base.addChild(left)
        
        setHairColor()
        setPositions()
    }
    
    func setPositions() {
        let xpos:CGFloat = 40
        right.position.x = xpos
        left.position.x = -xpos
        
        let degree:CGFloat = 6
        right.run(.rotate(toDegrees: -degree, duration: 0.5))
        left.run(.rotate(toDegrees: degree, duration: 0.5))
    }
    
    func setHairColor() {
        let eyebrows = [right, left]
        
        let color = ColorManager.shared.upper["hairColor"]!
        
        for eyebrow in eyebrows {
            eyebrow.color = color
            eyebrow.colorBlendFactor = 1.0
        }
    }

}

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

class MermaidMouth {
    let base:SKSpriteNode
    
    init() {
        base = SKSpriteNode(texture: SKTexture(imageNamed: "mouth"))
    }
}
