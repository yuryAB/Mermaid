//
//  FrameAnimationManager.swift
//  Ester
//
//  Created by yury antony on 22/07/24.
//

import Foundation
import SpriteKit

class FrameAnimationManager {
    static let shared = FrameAnimationManager()
    
    enum AnimationType: String {
        case ester = "Ester"
        
        var textures: [SKTexture] {
            return FrameAnimationManager.loadTextures(for: self)
        }
        
        var frameTime: TimeInterval {
            switch self {
            case .ester:
                return 0.05
            }
        }
    }
    
    private static func loadTextures(for animationType: AnimationType) -> [SKTexture] {
        let folderName = animationType.rawValue
        let baseFileName = "\(folderName)_frame_"
        var textures: [SKTexture] = []
        var index = 0
        
        while true {
            let fileName = "\(baseFileName)\(String(format: "%03d", index))"
            if let _ = UIImage(named: fileName) {
                let texture = SKTexture(imageNamed: fileName)
                textures.append(texture)
                index += 1
            } else {
                break
            }
        }
        
        if textures.isEmpty {
            fatalError("Nenhuma textura encontrada na pasta: \(folderName)")
        }
        
        return textures
    }
    
    func createAnimatedSprite(for animationType: AnimationType) -> SKSpriteNode {
        let textures = animationType.textures
        let frameTime = animationType.frameTime
        
        let sprite = SKSpriteNode(texture: textures.first)
        
        let animation = SKAction.animate(with: textures, timePerFrame: frameTime)
        
        sprite.run(SKAction.repeatForever(animation))
        
        return sprite
    }
    
    private init() {}
}
