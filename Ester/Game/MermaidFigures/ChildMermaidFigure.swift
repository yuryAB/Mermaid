//
//  ChildMermaidFigure.swift
//  Ester
//

import Foundation
import SpriteKit

final class ChildMermaidFigure: MermaidFigure {
    let root = SKNode()

    private let flip = SKNode()
    private let upperBody = SKNode()
    private let waistGroup = SKNode()
    private let tail = SKNode()

    private let hairBack = SKSpriteNode(imageNamed: "child-hairBack")
    private let hairFront = SKSpriteNode(imageNamed: "child-hairFront")
    private let head = SKSpriteNode(imageNamed: "MermHead")
    private let eyeLeft = SKSpriteNode(imageNamed: "eye")
    private let eyeRight = SKSpriteNode(imageNamed: "eye")
    private let eyebrowLeft = SKSpriteNode(imageNamed: "eyeBrow")
    private let eyebrowRight = SKSpriteNode(imageNamed: "eyeBrow")
    private let mouth = SKSpriteNode(imageNamed: "mouth")
    private let chest = SKSpriteNode(imageNamed: "chest")
    private let waistBack = SKSpriteNode(imageNamed: "child-waistBack")
    private let waistFront = SKSpriteNode(imageNamed: "child-waistFront")
    private let tailFin = SKSpriteNode(imageNamed: "child-fin")
    private let handLeft = SKSpriteNode(imageNamed: "baby-hand1-1")
    private let handRight = SKSpriteNode(imageNamed: "baby-hand1")
    private let rig: ChildMermaidRig

    init(rig: ChildMermaidRig = MermaidRigStore.shared.document.child) {
        self.rig = rig
        assembleNodes()
        applyAnimationMode(.idle)
    }

    private func assembleNodes() {
        root.addChild(flip)
        flip.addChild(upperBody)
        flip.addChild(waistGroup)

        hairBack.zPosition = rig.hairBack.z
        hairBack.position = rig.hairBack.point
        hairBack.setScale(rig.hairBack.scale)
        upperBody.addChild(hairBack)

        head.zPosition = rig.head.z
        head.position = rig.head.point
        head.setScale(rig.head.scale)
        upperBody.addChild(head)

        eyeLeft.zPosition = rig.eyeLeft.z
        eyeLeft.position = rig.eyeLeft.point
        applyScale(rig.eyeLeft.scale, to: eyeLeft, part: .eyeLeft)
        upperBody.addChild(eyeLeft)

        eyeRight.zPosition = rig.eyeRight.z
        eyeRight.position = rig.eyeRight.point
        eyeRight.setScale(rig.eyeRight.scale)
        upperBody.addChild(eyeRight)

        eyebrowLeft.zPosition = rig.eyebrowLeft.z
        eyebrowLeft.position = rig.eyebrowLeft.point
        eyebrowLeft.xScale = -rig.eyebrowLeft.scale
        eyebrowLeft.yScale = rig.eyebrowLeft.scale
        eyebrowLeft.zRotation = 6 * .pi / 180
        upperBody.addChild(eyebrowLeft)

        eyebrowRight.zPosition = rig.eyebrowRight.z
        eyebrowRight.position = rig.eyebrowRight.point
        eyebrowRight.setScale(rig.eyebrowRight.scale)
        eyebrowRight.zRotation = -6 * .pi / 180
        upperBody.addChild(eyebrowRight)

        mouth.zPosition = rig.mouth.z
        mouth.position = rig.mouth.point
        mouth.setScale(rig.mouth.scale)
        upperBody.addChild(mouth)

        hairFront.zPosition = rig.hairFront.z
        hairFront.position = rig.hairFront.point
        hairFront.setScale(rig.hairFront.scale)
        upperBody.addChild(hairFront)

        waistGroup.position = rig.waistGroup.point
        waistGroup.zPosition = rig.waistGroup.z

        chest.zPosition = rig.chest.z
        chest.position = rig.chest.point
        let chestDiameter = max(rig.chestSize.width, rig.chestSize.height)
        chest.size = CGSize(width: chestDiameter, height: chestDiameter)
        chest.setScale(rig.chest.scale)
        waistGroup.addChild(chest)

        tail.position = .zero
        tail.zPosition = 0
        tail.setScale(1)
        waistGroup.addChild(tail)

        waistBack.zPosition = rig.waistBack.z
        waistBack.position = rig.waistBack.point
        waistBack.setScale(rig.waistBack.scale)
        waistGroup.addChild(waistBack)

        waistFront.zPosition = rig.waistFront.z
        waistFront.position = rig.waistFront.point
        waistFront.setScale(rig.waistFront.scale)
        waistGroup.addChild(waistFront)

        tailFin.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        tailFin.position = rig.tailFin.point
        tailFin.zPosition = rig.tailFin.z
        tailFin.setScale(rig.tailFin.scale)
        tail.addChild(tailFin)

        handLeft.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        handLeft.zPosition = rig.handLeft.z
        handLeft.position = rig.handLeft.point
        handLeft.setScale(rig.handLeft.scale)
        upperBody.addChild(handLeft)

        handRight.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        handRight.zPosition = rig.handRight.z
        handRight.position = rig.handRight.point
        handRight.setScale(rig.handRight.scale)
        upperBody.addChild(handRight)
    }

    func applyAnimationMode(_ mode: MovementType) {
        switch mode {
        case .idle:
            applyModeMotion(bobAmplitude: 12, bobDuration: 1.4,
                            tailDegrees: 5, tailDuration: 2.0,
                            finDegrees: 5.5, finDuration: 2.0,
                            handDegrees: 8, handDuration: 2.6)
        case .swing:
            applyModeMotion(bobAmplitude: 8, bobDuration: 0.8,
                            tailDegrees: 5, tailDuration: 0.5,
                            finDegrees: 8, finDuration: 0.5,
                            handDegrees: 12, handDuration: 0.7)
        case .fast:
            applyModeMotion(bobAmplitude: 5, bobDuration: 0.4,
                            tailDegrees: 5, tailDuration: 0.22,
                            finDegrees: 6, finDuration: 0.22,
                            handDegrees: 16, handDuration: 0.4)
        }
    }

    func applyDirection(_ direction: MovementDirection) {
        switch direction {
        case .up:
            tilt(toDegrees: 10)
        case .down:
            tilt(toDegrees: -12)
        case .right:
            tilt(toDegrees: -6, flipX: 1)
        case .left:
            tilt(toDegrees: 6, flipX: -1)
        }
    }

    func applyPalette(_ palette: MermaidPalette) {
        for node in [hairBack, hairFront] {
            node.color = palette.hair
            node.colorBlendFactor = 0.55
        }

        head.color = palette.skin
        head.colorBlendFactor = 1.0

        for node in [waistBack, waistFront, chest] {
            node.color = palette.vibrant1
            node.colorBlendFactor = 0.5
        }

        tailFin.color = palette.vibrant2
        tailFin.colorBlendFactor = 1.0

        for node in [eyebrowLeft, eyebrowRight] {
            node.color = palette.hair
            node.colorBlendFactor = 1.0
        }

        mouth.color = palette.skin
        mouth.colorBlendFactor = 0.45

        for node in [handLeft, handRight] {
            node.color = palette.skin
            node.colorBlendFactor = 0.6
        }
    }

    func setPartX(_ x: CGFloat, for part: MermaidFigurePart) {
        node(for: part)?.position.x = x
    }

    func setPartY(_ y: CGFloat, for part: MermaidFigurePart) {
        node(for: part)?.position.y = y
    }

    func setPartScale(_ scale: CGFloat, for part: MermaidFigurePart) {
        applyScale(scale, to: node(for: part), part: part)
    }

    private func node(for part: MermaidFigurePart) -> SKNode? {
        switch part {
        case .head:
            return head
        case .hairBack:
            return hairBack
        case .hairFront:
            return hairFront
        case .eyeLeft:
            return eyeLeft
        case .eyeRight:
            return eyeRight
        case .eyebrowLeft:
            return eyebrowLeft
        case .eyebrowRight:
            return eyebrowRight
        case .mouth:
            return mouth
        case .waistBack:
            return waistBack
        case .waistFront:
            return waistFront
        case .tail:
            return nil
        case .tailFin:
            return tailFin
        case .handLeft:
            return handLeft
        case .handRight:
            return handRight
        case .chest:
            return chest
        }
    }

    private func applyScale(_ scale: CGFloat, to node: SKNode?, part: MermaidFigurePart) {
        guard let node else { return }
        if part == .eyeLeft || part == .eyebrowLeft {
            node.xScale = -scale
            node.yScale = scale
        } else {
            node.setScale(scale)
        }
    }

    private func applyModeMotion(
        bobAmplitude: CGFloat,
        bobDuration: Double,
        tailDegrees: CGFloat,
        tailDuration: Double,
        finDegrees: CGFloat,
        finDuration: Double,
        handDegrees: CGFloat,
        handDuration: Double
    ) {
        removeAllAnimations()
        runHairPulse()
        runBob(amplitude: bobAmplitude, duration: bobDuration)
        tail.run(swing(degrees: tailDegrees, duration: tailDuration))
        tailFin.run(swing(degrees: finDegrees, duration: finDuration))
        handLeft.run(swing(degrees: handDegrees, duration: handDuration))
        handRight.run(swing(degrees: -handDegrees, duration: handDuration))
    }

    private func removeAllAnimations() {
        root.removeAllActions()
        hairBack.removeAllActions()
        tail.removeAllActions()
        tailFin.removeAllActions()
        handLeft.removeAllActions()
        handRight.removeAllActions()
    }

    private func runHairPulse() {
        let baseScale = rig.hairBack.scale
        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: baseScale * 1.05, duration: 0.9),
            .scale(to: baseScale, duration: 0.9)
        ]))
        pulse.eaeInEaseOut()
        hairBack.run(pulse)
    }

    private func runBob(amplitude: CGFloat, duration: Double) {
        let bob = SKAction.repeatForever(.sequence([
            .moveBy(x: 0, y: amplitude, duration: duration),
            .moveBy(x: 0, y: -amplitude, duration: duration)
        ]))
        bob.eaeInEaseOut()
        root.run(bob)
    }

    private func swing(degrees: CGFloat, duration: Double) -> SKAction {
        let action = SKAction.repeatForever(.sequence([
            .rotate(toDegrees: degrees, duration: duration),
            .rotate(toDegrees: -degrees, duration: duration)
        ]))
        action.eaeInEaseOut()
        return action
    }

    private func tilt(toDegrees degrees: CGFloat, flipX: CGFloat? = nil) {
        let rotate = SKAction.rotate(toDegrees: degrees, duration: 0.5)
        rotate.eaeInEaseOut()
        flip.run(rotate)

        if let flipX {
            let scale = SKAction.scaleX(to: flipX, duration: 0.3)
            scale.eaeInEaseOut()
            flip.run(scale)
        }
    }
}
