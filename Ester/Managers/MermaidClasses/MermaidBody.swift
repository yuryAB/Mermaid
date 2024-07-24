//
//  MermaidBody.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class MermaidBody {
    var mermBody: SKSpriteNode
    private var mermFin: SKSpriteNode
    private var mermScale: SKSpriteNode
    
    init() {
        mermBody = FrameAnimationManager.shared.createAnimatedSprite(for: .MermBody)
        mermFin = FrameAnimationManager.shared.createAnimatedSprite(for: .MermFin)
        mermFin.zPosition = 1
        mermScale = FrameAnimationManager.shared.createAnimatedSprite(for: .MermScale)
        mermScale.zPosition = 2
        
        mermBody.addChild(mermFin)
        mermBody.addChild(mermScale)
        
        mermBody.position = CGPoint(x: 0, y: 0)
        mermBody.color = ColorManager.shared.upper["skinColor"]!
        mermBody.colorBlendFactor = 1.0
        
        mermFin.color = ColorManager.shared.upper["vibrant2"]!
        mermFin.colorBlendFactor = 1.0
        
        mermScale.color = ColorManager.shared.upper["vibrant1"]!
        mermScale.colorBlendFactor = 1.0
        
    }
    
}
