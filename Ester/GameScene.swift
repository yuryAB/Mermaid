import SpriteKit

class GameScene: SKScene {
    var cameraNode: SKCameraNode?
    var mermaid: Mermaid?
    var currentZone: DepthZone?
    
    enum DepthZone: String {
        case surface
        case shallow
        case mid
        case deep
        case abyssal
    }
    
    override func didMove(to view: SKView) {
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -1.0)
        //self.mermaid = Mermaid()
        
//        if let head = mermaid?.headNode {
//            self.addChild(head)
//        }
        
        let mermbody = FrameAnimationManager.shared.createAnimatedSprite(for: .MermBody)
        let mermFin = FrameAnimationManager.shared.createAnimatedSprite(for: .MermFin)
        mermFin.zPosition = 1
        let mermScale = FrameAnimationManager.shared.createAnimatedSprite(for: .MermScale)
        mermScale.zPosition = 2
        
        mermbody.addChild(mermFin)
        mermbody.addChild(mermScale)
        
        mermbody.position = CGPoint(x: 0, y: 0)
        mermbody.color = ColorManager.shared.upper["skinColor"]!
        mermbody.colorBlendFactor = 1.0
        
        mermFin.color = ColorManager.shared.upper["vibrant2"]!
        mermFin.colorBlendFactor = 1.0
        
        mermScale.color = ColorManager.shared.upper["vibrant1"]!
        mermScale.colorBlendFactor = 1.0
        
        addChild(mermbody)
        
        //self.mermaid?.startWaveAnimation()
        //self.mermaid?.applyMainForm()
        setUpCamera()
        self.currentZone = .mid
        self.backgroundColor = ColorManager.shared.waters["mid"]!
        
        //startMermaidRandomMovement()
    }
    
    func setUpCamera() {
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.addChild(cameraNode)
        self.cameraNode = cameraNode
        
//        if let headNode = mermaid?.headNode {
//        //    cameraNode.position = headNode.position
//        }
        
        self.cameraNode?.setScale(7.0)
    }
    
    override func update(_ currentTime: TimeInterval) {
//        guard let headNode = mermaid?.headNode, let cameraNode = cameraNode else { return }
        //cameraNode.position = headNode.position
        updateBackgroundColor()
    }
    
    func updateBackgroundColor() {
        guard let headNode = mermaid?.headNode else { return }
        
        let depth = headNode.position.y
        let newZone: DepthZone
        
        switch depth {
        case let y where y >= 30000:
            newZone = .surface
        case let y where y < 30000 && y >= 10000:
            newZone = .shallow
        case let y where y < 10000 && y >= -10000:
            newZone = .mid
        case let y where y < -10000 && y >= -30000:
            newZone = .deep
        case let y where y < -30000:
            newZone = .abyssal
        default:
            newZone = .surface
        }
        
        if newZone != currentZone {
            self.currentZone = newZone
            if let newColor = ColorManager.shared.waters[newZone.rawValue] {
                self.backgroundColor = newColor
                print(newZone.rawValue)
                
                switch newZone {
                case .surface:
                    mermaid?.applySurfaceForm()
                case .abyssal:
                    mermaid?.applyAbyssForm()
                default:
                    mermaid?.applyMainForm()
                }
            }
        }
    }
    
    func startMermaidRandomMovement() {
        guard let mermaid = mermaid else { return }
        
        let moveDuration: TimeInterval = 3.0
        let waitDuration: TimeInterval = 1.0
        
        // Define três movimentos aleatórios
        let randomMovements: [CGPoint] = (0..<3).map { _ in
            let randomX = CGFloat(arc4random_uniform(1000)) - 500
            let randomY = CGFloat(arc4random_uniform(1000)) - 500
            return CGPoint(x: randomX, y: randomY)
        }
        
        let moveActions = randomMovements.map { randomPoint -> SKAction in
            let moveAction = SKAction.move(to: randomPoint, duration: moveDuration)
            let waitAction = SKAction.wait(forDuration: waitDuration)
            return SKAction.sequence([moveAction, waitAction])
        }
        
        let randomMovementSequence = SKAction.sequence(moveActions)
        let repeatRandomMovement = SKAction.repeatForever(randomMovementSequence)
        
        mermaid.headNode.run(repeatRandomMovement)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        mermaid?.updateAttributesForTouchBegan()
        zoomOutCamera()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Desabilitado para movimentos automáticos
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        mermaid?.resetHeadMovement()
        mermaid?.updateAttributesForTouchEnded()
        resetCameraZoom()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        mermaid?.resetHeadMovement()
        mermaid?.updateAttributesForTouchEnded()
        resetCameraZoom()
    }
    
    func zoomOutCamera() {
        let zoomOutAction = SKAction.scale(to: 10.0, duration: 2.0)
        cameraNode?.run(zoomOutAction)
    }
    
    func resetCameraZoom() {
        let resetZoomAction = SKAction.scale(to: 7.0, duration: 2.0)
        cameraNode?.run(resetZoomAction)
    }
}

