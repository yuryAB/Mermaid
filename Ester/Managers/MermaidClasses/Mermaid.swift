//
//  Mermaid.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

class Mermaid {
    var base: SKSpriteNode
    var head = MermaidHead()
    var body = MermaidBody()
    var arms = MermaidArms()
    var face = MermaidFace()
    var distanceToTravel: CGFloat = 200
    var currentDirection: Direction = .none
    
    enum Direction {
        case up
        case down
        case right
        case left
        case none
    }
    
    init() {
        base = SKSpriteNode()
        
        body.body.position.y = -220
        body.body.zPosition = 1
        head.base.addChild(body.body)
        
        face.base.zPosition = 3
        head.headNode.addChild(face.base)
        
        body.body.addChild(arms.left)
        body.body.addChild(arms.right)
        
        self.base.addChild(head.headNode)
    }
}

extension Mermaid: MovementTypeProtocol {
    func applyIdleMoveMode() {
        base.removeAllActions()
        currentDirection = .none
        arms.applyIdleMoveMode()
        head.applyIdleMoveMode()
        body.applyIdleMoveMode()
        face.applyIdleMoveMode()
    }
    
    func applySwingMoveMode() {
        distanceToTravel = 200
        body.applySwingMoveMode()
        updateMovement()
    }
    
    func applyFastMoveMode() {
        distanceToTravel = 500
        body.applyFastMoveMode()
        updateMovement()
    }
    
    private func updateMovement() {
        base.removeAllActions()
        switch currentDirection {
        case .up:
            let move = SKAction.moveBy(x: 0, y: distanceToTravel, duration: 1.0)
            base.run(SKAction.repeatForever(move), withKey: "moving")
        case .down:
            let move = SKAction.moveBy(x: 0, y: -distanceToTravel, duration: 1.0)
            base.run(SKAction.repeatForever(move), withKey: "moving")
        case .right:
            let move = SKAction.moveBy(x: distanceToTravel, y: 0, duration: 1.0)
            base.run(SKAction.repeatForever(move), withKey: "moving")
        case .left:
            let move = SKAction.moveBy(x: -distanceToTravel, y: 0, duration: 1.0)
            base.run(SKAction.repeatForever(move), withKey: "moving")
        case .none:
            break
        }
    }
}

extension Mermaid: MovementDirectionProtocol {
    func setUpMoveMode() {
        currentDirection = .up
        let move = SKAction.moveBy(x: 0, y: distanceToTravel, duration: 1.0)
        base.run(SKAction.repeatForever(move), withKey: "moving")
        
        arms.setUpMoveMode()
        head.setUpMoveMode()
        body.setUpMoveMode()
        face.setUpMoveMode()
    }
    
    func setDownMoveMode() {
        currentDirection = .down
        let move = SKAction.moveBy(x: 0, y: -distanceToTravel, duration: 1.0)
        base.run(SKAction.repeatForever(move), withKey: "moving")
        
        arms.setDownMoveMode()
        head.setDownMoveMode()
        body.setDownMoveMode()
        face.setDownMoveMode()
    }
    
    func setRightMoveMode() {
        currentDirection = .right
        let move = SKAction.moveBy(x: distanceToTravel, y: 0, duration: 1.0)
        base.run(SKAction.repeatForever(move), withKey: "moving")
        
        arms.setRightMoveMode()
        head.setRightMoveMode()
        body.setRightMoveMode()
        face.setRightMoveMode()
    }
    
    func setLeftMoveMode() {
        currentDirection = .left
        let move = SKAction.moveBy(x: -distanceToTravel, y: 0, duration: 1.0)
        base.run(SKAction.repeatForever(move), withKey: "moving")
        
        arms.setLeftMoveMode()
        head.setLeftMoveMode()
        body.setLeftMoveMode()
        face.setLeftMoveMode()
    }
}

