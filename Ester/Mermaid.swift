import SpriteKit

class Mermaid {
    var headNode: SKSpriteNode
    var chest: SKSpriteNode?
    var waistBack: SKSpriteNode?
    var waistFront: SKSpriteNode?
    var tail: SKSpriteNode?
    var finBack: SKSpriteNode?
    var finFront: SKSpriteNode?
    var tailNodes: [SKSpriteNode] = []
    
    var leftArm: SKSpriteNode?
    var rightArm: SKSpriteNode?

    var hairFront: SKSpriteNode?
    var face: SKSpriteNode?
    var hairBack: SKSpriteNode?
    var expression: SKSpriteNode?

    var originalArmPositionX: CGFloat = 95

    var animationDuration: TimeInterval = 1.0 {
        didSet {
            updateWaveAnimation()
            updateArmsAnimation()
        }
    }
    var baseAmplitude: CGFloat = 20.0 {
        didSet {
            updateWaveAnimation()
        }
    }
    var amplitudeIncrement: CGFloat = 25.0 {
        didSet {
            updateWaveAnimation()
        }
    }
    var spaceBetweenNodes: CGFloat = 200.0 {
        didSet {
            repositionTailNodes()
        }
    }

    init() {
        headNode = SKSpriteNode()
        setupHead()
        setupMermaidParts()
        startHairAnimation()
        startExpressionAnimation()
        setupArms()
        startArmsAnimation()
    }
}

// MARK: - Setup Methods
extension Mermaid {
    private func setupHead() {
        hairBack = createNode(named: "hairBack", imageName: "hairBack", zPosition: -1)
        face = createNode(named: "face", imageName: "face", zPosition: 0)
        hairFront = createNode(named: "hairFront", imageName: "hairFront", zPosition: 1)
        expression = createNode(named: "expression", imageName: "expre1", positionY: 10, zPosition: 2)
        
        face?.addChild(hairFront!)
        face?.addChild(expression!)
        
        addChildNodesToHead([hairBack, face])
    }

    private func setupArms() {
        leftArm = createNode(named: "leftArm", imageName: "leftArm", positionX: -originalArmPositionX, zPosition: 2, anchorPoint: CGPoint(x: 0.5, y: 1.0))
        rightArm = createNode(named: "rightArm", imageName: "rightArm", positionX: originalArmPositionX, zPosition: -2, anchorPoint: CGPoint(x: 0.5, y: 1.0))
        
        addChildrenToChest([leftArm, rightArm])
    }

    private func setupMermaidParts() {
        chest = createNode(named: "chest", imageName: "chest", positionY: -(spaceBetweenNodes * 1.2))
        addToMermaid(chest)
        
        waistBack = createNode(named: "waistBack", imageName: "waistBack", positionY: -(spaceBetweenNodes * 2.3), zPosition: 0)
        waistFront = createNode(named: "waistFront", imageName: "waistFront", zPosition: 1)
        addChildNodesToParent(waistBack, children: [waistFront])
        addToMermaid(waistBack)

        tail = createNode(named: "tail", imageName: "tail", positionY: -(spaceBetweenNodes * 3.3))
        addToMermaid(tail)

        finBack = createNode(named: "finBack", imageName: "finBack", positionY: -(spaceBetweenNodes * 4.4), zPosition: 0, anchorPoint: CGPoint(x: 0.5, y: 1.0))
        finFront = createNode(named: "finFront", imageName: "finFront", zPosition: 1, anchorPoint: CGPoint(x: 0.5, y: 1.0))
        addChildNodesToParent(finBack, children: [finFront])
        addToMermaid(finBack)
    }
}

// MARK: - Helper Methods
extension Mermaid {
    private func createNode(named name: String, imageName: String, positionX: CGFloat = 0, positionY: CGFloat = 0, zPosition: CGFloat? = nil, anchorPoint: CGPoint? = nil) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: imageName)
        node.name = name
        node.position = CGPoint(x: positionX, y: positionY)
        if let zPos = zPosition {
            node.zPosition = zPos
        }
        if let anchor = anchorPoint {
            node.anchorPoint = anchor
        }
        return node
    }

    private func addToMermaid(_ node: SKSpriteNode?) {
        guard let node = node else { return }
        headNode.addChild(node)
        tailNodes.append(node)
    }

    private func addChildNodesToHead(_ nodes: [SKSpriteNode?]) {
        for node in nodes {
            if let node = node {
                headNode.addChild(node)
            }
        }
    }

    private func addChildNodesToParent(_ parent: SKSpriteNode?, children: [SKSpriteNode?]) {
        guard let parent = parent else { return }
        for child in children {
            if let child = child {
                parent.addChild(child)
            }
        }
    }

    private func addChildrenToChest(_ children: [SKSpriteNode?]) {
        guard let chest = chest else { return }
        for child in children {
            if let child = child {
                chest.addChild(child)
            }
        }
    }
}

// MARK: - Animation Methods
extension Mermaid {
    func startHairAnimation() {
        let zoomIn = SKAction.scale(to: 1.1, duration: 2)
        let zoomOut = SKAction.scale(to: 1.0, duration: 2)
        let moveUp = SKAction.moveBy(x: 0, y: 7, duration: 2)
        let moveDown = SKAction.moveBy(x: 0, y: -7, duration: 2)
        
        let zoomSequence = SKAction.sequence([zoomIn, zoomOut])
        let moveSequence = SKAction.sequence([moveUp, moveDown])
        
        let groupAction = SKAction.group([zoomSequence, moveSequence])
        let repeatGroup = SKAction.repeatForever(groupAction)
        
        repeatGroup.timingMode = .easeInEaseOut
        
        hairBack?.run(repeatGroup)
    }
    
    func startArmsAnimation() {
        let rotationDiv: CGFloat = 20

        let rotateRight = SKAction.rotate(toAngle: .pi / rotationDiv, duration: animationDuration)
        let rotateLeft = SKAction.rotate(toAngle: -.pi / rotationDiv, duration: animationDuration)
        let rotateWait = SKAction.wait(forDuration: animationDuration)

        let rotateSequence = SKAction.sequence([rotateRight, rotateWait, rotateLeft, rotateWait])
        let repeatRotate = SKAction.repeatForever(rotateSequence)
        
        leftArm?.run(repeatRotate)
        rightArm?.run(repeatRotate)
    }

    func startExpressionAnimation() {
        let expressions = ["expre1", "expre2", "expre3"]
        let changeExpression = SKAction.run { [weak self] in
            guard let self = self else { return }
            let randomExpression = expressions.randomElement() ?? "expre1"
            self.expression?.texture = SKTexture(imageNamed: randomExpression)
        }
        let wait = SKAction.wait(forDuration: 2.0, withRange: 1.0)
        let sequence = SKAction.sequence([changeExpression, wait])
        let repeatSequence = SKAction.repeatForever(sequence)
        
        expression?.run(repeatSequence)
    }

    func startWaveAnimation() {
        let timingMode = SKActionTimingMode.easeInEaseOut

        for (index, node) in tailNodes.enumerated() {
            let delay = TimeInterval(index) * 0.2
            let adjustedIncrement = CGFloat(index)
            let amplitude = baseAmplitude + adjustedIncrement * amplitudeIncrement

            let moveRight = SKAction.moveBy(x: amplitude, y: 0, duration: animationDuration)
            let moveCenter1 = SKAction.moveBy(x: -amplitude, y: 0, duration: animationDuration)
            let moveLeft = SKAction.moveBy(x: -amplitude, y: 0, duration: animationDuration)
            let moveCenter2 = SKAction.moveBy(x: amplitude, y: 0, duration: animationDuration)
            let waveSequence = SKAction.sequence([moveRight, moveCenter1, moveLeft, moveCenter2])
            let repeatWave = SKAction.repeatForever(waveSequence)

            let rotationDiv: CGFloat = 7

            let rotateRight = SKAction.rotate(toAngle: .pi / rotationDiv, duration: animationDuration)
            let rotateLeft = SKAction.rotate(toAngle: -.pi / rotationDiv, duration: animationDuration)
            let rotateWait = SKAction.wait(forDuration: animationDuration)

            let rotateSequence = SKAction.sequence([rotateRight, rotateWait, rotateLeft, rotateWait])
            let repeatRotate = SKAction.repeatForever(rotateSequence)
            let setRotation = SKAction.rotate(toAngle: 0, duration: 0.1, shortestUnitArc: true)
            let rotateAction = SKAction.group([setRotation, repeatRotate])

            let combinedAction: SKAction
            if node.name == "finBack" || node.name == "finFront" {
                combinedAction = SKAction.group([repeatWave, rotateAction])
            } else {
                combinedAction = repeatWave
            }

            combinedAction.timingMode = timingMode
            let delayedAction = SKAction.sequence([SKAction.wait(forDuration: delay), combinedAction])
            node.run(delayedAction)
        }
    }

    func updateWaveAnimation() {
        for node in tailNodes {
            node.removeAllActions()
        }
        startWaveAnimation()
    }
    
    func updateArmsAnimation() {
        leftArm?.removeAllActions()
        rightArm?.removeAllActions()
        startArmsAnimation()
    }
}

// MARK: - Position Update Methods
extension Mermaid {
    func repositionTailNodes() {
        var dec: Double = 0.2
        for (index, node) in tailNodes.enumerated() {
            node.position = CGPoint(x: 0, y: -spaceBetweenNodes * CGFloat(Double(index + 1) + dec))
            dec += 0.1
            node.zRotation = 0
        }
    }

    func updateHeadMovement(with touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: headNode.parent!)

        let direction = CGVector(dx: location.x - headNode.position.x, dy: location.y - headNode.position.y)
        let angle = atan2(direction.dy, direction.dx) - .pi / 2

        let rotateAction = SKAction.rotate(toAngle: angle, duration: 0.1, shortestUnitArc: true)
        let moveAction = SKAction.move(to: location, duration: 0.5)
        let groupAction = SKAction.group([rotateAction, moveAction])
        headNode.run(groupAction)
        
        face?.run(SKAction.rotate(toAngle: -angle, duration: 0.1, shortestUnitArc: true))
        
        let newFacePositionY: CGFloat
        let newHairBackZPosition: CGFloat
        let newFaceZPosition: CGFloat

        if abs(direction.dy) > abs(direction.dx) {
            if direction.dy > 0 {
                newFacePositionY = 0
                newFaceZPosition = 0
                newHairBackZPosition = -1
            } else {
                newFacePositionY = 80
                newFaceZPosition = 2
                newHairBackZPosition = 1
            }
        } else {
            newFacePositionY = 25
            newFaceZPosition = 0
            newHairBackZPosition = -1
        }
        
        let moveFaceAction = SKAction.moveTo(y: newFacePositionY, duration: 0.3)
        face?.run(moveFaceAction)
        face?.zPosition = newFaceZPosition
        hairBack?.zPosition = newHairBackZPosition

        updateArmPositions(for: angle)
    }

    func resetHeadMovement() {
        let currentAngle = headNode.zRotation
        let rotateSpeed: CGFloat = 0.3
        let rotateDistance = abs(currentAngle)
        let duration = TimeInterval(rotateDistance / rotateSpeed)

        let resetRotateAction = SKAction.rotate(toAngle: 0, duration: duration, shortestUnitArc: true)
        let moveFaceAction = SKAction.moveTo(y: 0, duration: duration)
        
        headNode.run(resetRotateAction)
        face?.run(resetRotateAction)
        face?.run(moveFaceAction)
        hairBack?.zPosition = -1
        updateArmPositions(for: 0)
    }

    func updateArmPositions(for angle: CGFloat) {
        let maxArmPositionX: CGFloat = 95
        let minArmPositionX: CGFloat = 0
        
        let interpolationFactor = abs(cos(angle))
        let armPositionX = minArmPositionX + (maxArmPositionX - minArmPositionX) * interpolationFactor
        
        leftArm?.position.x = -armPositionX
        rightArm?.position.x = armPositionX
    }
}

// MARK: - Touch Attributes Methods
extension Mermaid {
    func updateAttributesForTouchBegan() {
        animationDuration = 0.2
        baseAmplitude = 25.0
        amplitudeIncrement = 30.0
        spaceBetweenNodes = 200.0
    }

    func updateAttributesForTouchEnded() {
        animationDuration = 1.0
        baseAmplitude = 20
        amplitudeIncrement = 25.0
        spaceBetweenNodes = 200.0
    }
}

// MARK: - Palette Application Methods
extension Mermaid {
    func applyMainForm() {
        self.applyPalette(palette: ColorManager.shared.main)
    }
    
    func applySurfaceForm() {
        self.applyPalette(palette: ColorManager.shared.upper)
    }
    
    func applyAbyssForm() {
        self.applyPalette(palette: ColorManager.shared.abyss)
    }
    
    private func applyPalette(palette: [String: UIColor]) {
        let duration: TimeInterval = 2

        let applyColorAnimation = { (node: SKSpriteNode?, color: UIColor?) in
            guard let node = node, let color = color else { return }
            let colorAction = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration)
            node.run(colorAction)
        }

        applyColorAnimation(hairFront, palette["hairColor"])
        applyColorAnimation(hairBack, palette["hairColor"])
        applyColorAnimation(face, palette["skinColor"])
        applyColorAnimation(leftArm, palette["skinColor"])
        applyColorAnimation(rightArm, palette["skinColor"])
        applyColorAnimation(chest, palette["skinColor"])
        applyColorAnimation(tail, palette["vibrant1"])
        applyColorAnimation(waistBack, palette["skinColor"])
        applyColorAnimation(waistFront, palette["vibrant1"])
        applyColorAnimation(finBack, palette["vibrant2"])
        applyColorAnimation(finFront, palette["vibrant1"])
    }
}
