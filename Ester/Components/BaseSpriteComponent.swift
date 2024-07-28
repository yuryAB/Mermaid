//
//  BaseSpriteComponent.swift
//  Ester
//
//  Created by yury antony on 28/07/24.
//

import Foundation
import GameplayKit

class BaseSpriteComponent: GKComponent {
    let node: SKSpriteNode
    
    init(node: SKSpriteNode) {
        self.node = node
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
