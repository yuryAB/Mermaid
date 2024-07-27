import SpriteKit

class GameScene: SKScene {
    var cameraNode: SKCameraNode?
    var currentZone: DepthZone?
    let mermaid = Mermaid()
    
    var button1: SKSpriteNode!
    var button2: SKSpriteNode!
    var button3: SKSpriteNode!
    var button4: SKSpriteNode!
    var button6: SKSpriteNode!
    var button7: SKSpriteNode!
    var button8: SKSpriteNode!
    var button9: SKSpriteNode!
    var button10: SKSpriteNode!
    
    var button5: SKSpriteNode!
    
    enum DepthZone: String {
        case surface
        case shallow
        case mid
        case deep
        case abyssal
    }
    
    override func didMove(to view: SKView) {
        button1 = createButton(name: "button1", text: "Up", position: CGPoint(x: 0, y: -270))
        button2 = createButton(name: "button2", text: "Down", position: CGPoint(x: 0, y: 220))
        button3 = createButton(name: "button3", text: "Right", position: CGPoint(x: -140, y: 0))
        button4 = createButton(name: "button4", text: "Left", position: CGPoint(x: 140, y: 0))
        button5 = createButton(name: "button5", text: "Idle", position: CGPoint(x: 130, y: 340))
        button6 = createButton(name: "button6", text: "Swing", position: CGPoint(x: 0, y: 340))
        button7 = createButton(name: "button7", text: "Fast", position: CGPoint(x: -130, y: 340))
        button8 = createButton(name: "button8", text: "zoom1", position: CGPoint(x: 140, y: -80), fontsize: 25)
        button9 = createButton(name: "button9", text: "zoom2", position: CGPoint(x: 140, y: -160), fontsize: 25)
        button10 = createButton(name: "button10", text: "zoom3", position: CGPoint(x: 140, y: -240), fontsize: 25)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -1.0)
        
        setupNewMermaid()
        setupCamera()
        
        cameraNode!.addChild(button1)
        cameraNode!.addChild(button2)
        cameraNode!.addChild(button3)
        cameraNode!.addChild(button4)
        cameraNode!.addChild(button5)
        cameraNode!.addChild(button6)
        cameraNode!.addChild(button7)
        cameraNode!.addChild(button8)
        cameraNode!.addChild(button9)
        cameraNode!.addChild(button10)
        
        mermaid.setIdleMoveMode()
        
        self.currentZone = .mid
        self.backgroundColor = ColorManager.shared.waters["mid"]!
    }
    
    func createButton(name: String, text: String, position: CGPoint, fontsize: CGFloat = 35) -> SKSpriteNode {
        let button = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 30))
        button.name = name
        button.position = position
        
        let label = SKLabelNode(text: text)
        label.fontName = "Helvetica"
        label.fontSize = fontsize
        label.fontColor = .black
        label.position = CGPoint(x: 0, y: -10)
        label.zPosition = 1
        label.name = name
        
        button.addChild(label)
        
        return button
    }
    
    func setupNewMermaid() {
        addChild(mermaid.mermaid)
    }
    
    func setupCamera() {
        let cameraNode = SKCameraNode()
        self.camera = cameraNode
        self.addChild(cameraNode)
        self.cameraNode = cameraNode
    }
    
    override func update(_ currentTime: TimeInterval) {
        updateBackgroundColor()
    }
    
    func updateBackgroundColor() {
        //        guard let headNode = mermaid?.headNode else { return }
        //
        //        let depth = headNode.position.y
        //        let newZone: DepthZone
        //
        //        switch depth {
        //        case let y where y >= 30000:
        //            newZone = .surface
        //        case let y where y < 30000 && y >= 10000:
        //            newZone = .shallow
        //        case let y where y < 10000 && y >= -10000:
        //            newZone = .mid
        //        case let y where y < -10000 && y >= -30000:
        //            newZone = .deep
        //        case let y where y < -30000:
        //            newZone = .abyssal
        //        default:
        //            newZone = .surface
        //        }
        //
        //        if newZone != currentZone {
        //            self.currentZone = newZone
        //            if let newColor = ColorManager.shared.waters[newZone.rawValue] {
        //                self.backgroundColor = newColor
        //                print(newZone.rawValue)
        //
        //                switch newZone {
        //                case .surface:
        //                    mermaid?.applySurfaceForm()
        //                case .abyssal:
        //                    mermaid?.applyAbyssForm()
        //                default:
        //                    mermaid?.applyMainForm()
        //                }
        //            }
        //        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtLocation = nodes(at: location)
        
        for node in nodesAtLocation {
            if let nodeName = node.name {
                switch nodeName {
                case "button1":
                    mermaid.setUpMoveMode()
                case "button2":
                    mermaid.setDownMoveMode()
                case "button3":
                    mermaid.setRightMoveMode()
                case "button4":
                    mermaid.setLeftMoveMode()
                case "button5":
                    mermaid.setIdleMoveMode()
                case "button6":
                    mermaid.setSwingMoveMode()
                case "button7":
                    mermaid.setFastMoveMode()
                case "button8":
                    let resetZoomAction = SKAction.scale(to: 1.2, duration: 1.0)
                    cameraNode?.run(resetZoomAction)
                case "button9":
                    let resetZoomAction = SKAction.scale(to: 5.0, duration: 1.0)
                    cameraNode?.run(resetZoomAction)
                case "button10":
                    let resetZoomAction = SKAction.scale(to: 9.0, duration: 1.0)
                    cameraNode?.run(resetZoomAction)
                default:
                    break
                }
            }
        }
    }
        
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Desabilitado para movimentos automáticos
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetCameraZoom()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetCameraZoom()
    }
    
    func zoomOutCamera() {
//        let zoomOutAction = SKAction.scale(to: 10.0, duration: 2.0)
//        cameraNode?.run(zoomOutAction)
    }
    
    func resetCameraZoom() {
//        let resetZoomAction = SKAction.scale(to: 7.0, duration: 2.0)
//        cameraNode?.run(resetZoomAction)
    }
}

