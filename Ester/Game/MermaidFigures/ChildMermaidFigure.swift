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
    private let bodyCore = SKNode()
    private let waistGroup = SKNode()
    private let tail = SKNode()

    private let hairBack = SKSpriteNode(imageNamed: "child-hairBack")
    private let hairFront = SKSpriteNode(imageNamed: "child-hairFront")
    private let head = SKSpriteNode(imageNamed: "MermHead")
    private let eyeLeftNode = SKNode()
    private let eyeRightNode = SKNode()
    private let eyeLeft = SKSpriteNode(imageNamed: "eye_open")
    private let eyeRight = SKSpriteNode(imageNamed: "eye_open")
    private let eyebrowLeft = SKSpriteNode(imageNamed: "eyeBrow")
    private let eyebrowRight = SKSpriteNode(imageNamed: "eyeBrow")
    private let mouth = SKSpriteNode(imageNamed: "mouth_neutral")
    private let chest = SKSpriteNode(imageNamed: "chest")
    private let waistBack = SKSpriteNode(imageNamed: "child-waistBack")
    private let waistFront = SKSpriteNode(imageNamed: "child-waistFront")
    private let tailFin = SKSpriteNode(imageNamed: "child-fin")
    private let handLeft = SKSpriteNode(imageNamed: "baby-hand1-1")
    private let handRight = SKSpriteNode(imageNamed: "baby-hand1")
    private let rig: ChildMermaidRig
    private var visualDirection: MovementDirection?
    private var currentAnimationMode: MovementType = .idle
    private var faceDirectionOffset: CGPoint = .zero

    init(rig: ChildMermaidRig = MermaidRigStore.shared.document.child) {
        self.rig = rig
        assembleNodes()
        applyPalette(.main)
        applyAnimationMode(.idle)
    }

    private func assembleNodes() {
        root.addChild(flip)
        flip.addChild(upperBody)
        flip.addChild(bodyCore)
        bodyCore.addChild(waistGroup)

        hairBack.zPosition = rig.hairBack.z
        hairBack.position = rig.hairBack.point
        hairBack.setScale(rig.hairBack.scale)
        upperBody.addChild(hairBack)

        head.zPosition = rig.head.z
        head.position = rig.head.point
        head.setScale(rig.head.scale)
        upperBody.addChild(head)

        eyeLeftNode.zPosition = rig.eyeLeft.z
        eyeLeftNode.position = rig.eyeLeft.point
        eyeLeftNode.setScale(abs(rig.eyeLeft.scale))
        eyeLeft.xScale = -1
        eyeLeft.yScale = 1
        eyeLeftNode.addChild(eyeLeft)
        upperBody.addChild(eyeLeftNode)

        eyeRightNode.zPosition = rig.eyeRight.z
        eyeRightNode.position = rig.eyeRight.point
        eyeRightNode.setScale(abs(rig.eyeRight.scale))
        eyeRightNode.addChild(eyeRight)
        upperBody.addChild(eyeRightNode)

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

        hairFront.zPosition = hairFrontZ
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

        tail.position = rig.tail.point
        tail.zPosition = rig.tail.z
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
        handLeft.position = handLeftRestPosition
        handLeft.setScale(rig.handLeft.scale)
        chest.addChild(handLeft)

        handRight.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        handRight.zPosition = rig.handRight.z
        handRight.position = handRightRestPosition
        handRight.setScale(rig.handRight.scale)
        chest.addChild(handRight)
    }

    func applyAnimationMode(_ mode: MovementType) {
        currentAnimationMode = mode
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

        switch mode {
        case .idle:
            visualDirection = nil
            resetDirectionalPose(animated: true)
        case .swing, .fast:
            if let visualDirection {
                applyDirectionalPose(visualDirection, animated: true)
            }
        }
    }

    func applyDirection(_ direction: MovementDirection) {
        visualDirection = direction
        applyDirectionalPose(direction, animated: true)
    }

    func applyPalette(_ palette: MermaidPalette) {
        hairBack.applyTemplateTexture(named: "child-hairBack", color: palette.hair)
        hairFront.applyTemplateTexture(named: "child-hairFront", color: palette.hair)
        head.applyTemplateTexture(named: "MermHead", color: palette.skin)
        waistBack.applyTemplateTexture(named: "child-waistBack", color: palette.vibrant1)
        waistFront.applyTemplateTexture(named: "child-waistFront", color: palette.vibrant1)
        chest.applyTemplateTexture(named: "chest", color: palette.vibrant1)
        tailFin.applyTemplateTexture(named: "child-fin", color: palette.vibrant2)
        eyebrowLeft.applyTemplateTexture(named: "eyeBrow", color: palette.hair)
        eyebrowRight.applyTemplateTexture(named: "eyeBrow", color: palette.hair)
        handLeft.applyTemplateTexture(named: "baby-hand1-1", color: palette.skin)
        handRight.applyTemplateTexture(named: "baby-hand1", color: palette.skin)
    }

    func applyFacePose(_ pose: MermaidFacePose, animated: Bool) {
        let faceRig = MermaidRigStore.shared.document.child
        eyeLeft.setFaceTexture(pose.eyeAsset.rawValue)
        eyeRight.setFaceTexture(pose.eyeAsset.rawValue)
        mouth.setFaceTexture(pose.mouthAsset.rawValue)

        eyeLeft.xScale = -1
        eyeLeft.yScale = 1
        eyeRight.setScale(1)
        eyeLeftNode.applyFaceTransform(position: offset(faceRig.eyeLeft.point,
                                                       dx: faceDirectionOffset.x,
                                                       dy: faceDirectionOffset.y),
                                       scale: faceRig.eyeLeft.scale,
                                       mirrored: false,
                                       rotationDegrees: 0,
                                       animated: animated)
        eyeRightNode.applyFaceTransform(position: offset(faceRig.eyeRight.point,
                                                        dx: faceDirectionOffset.x,
                                                        dy: faceDirectionOffset.y),
                                        scale: faceRig.eyeRight.scale,
                                        mirrored: false,
                                        rotationDegrees: 0,
                                        animated: animated)
        eyebrowLeft.applyFaceTransform(position: offset(faceRig.eyebrowLeft.point + pose.leftEyebrowOffset,
                                                       dx: faceDirectionOffset.x,
                                                       dy: faceDirectionOffset.y),
                                       scale: faceRig.eyebrowLeft.scale,
                                       mirrored: true,
                                       rotationDegrees: 6 + pose.leftEyebrowRotationDelta,
                                       animated: animated)
        eyebrowRight.applyFaceTransform(position: offset(faceRig.eyebrowRight.point + pose.rightEyebrowOffset,
                                                        dx: faceDirectionOffset.x,
                                                        dy: faceDirectionOffset.y),
                                        scale: faceRig.eyebrowRight.scale,
                                        mirrored: false,
                                        rotationDegrees: -6 + pose.rightEyebrowRotationDelta,
                                        animated: animated)
        mouth.applyFaceTransform(position: offset(faceRig.mouth.point + pose.mouthOffset,
                                                 dx: faceDirectionOffset.x,
                                                 dy: faceDirectionOffset.y),
                                 scale: faceRig.mouth.scale * pose.mouthScale,
                                 mirrored: false,
                                 rotationDegrees: 0,
                                 animated: animated)
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
            return eyeLeftNode
        case .eyeRight:
            return eyeRightNode
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
        if part == .eyebrowLeft {
            let targetScale = abs(scale)
            node.xScale = -targetScale
            node.yScale = targetScale
        } else {
            node.setScale(abs(scale))
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

    private func applyDirectionalPose(_ direction: MovementDirection, animated: Bool) {
        let duration = animated ? 1.0 : 0
        let tempo = directionalTempo

        switch direction {
        case .up:
            move(flip, to: .zero, duration: duration)
            rotate(flip, toDegrees: 0, duration: duration)
            scaleX(flip, to: 1, duration: duration)
            runDirectionalTail(centerDegrees: -6, amplitude: 6, duration: tempo.tail)
            applyCorePose(upperDegrees: 0, waistDegrees: 0, tailX: 0, tailY: -5,
                          duration: duration)
            applyPartOffsets(faceX: 0, faceY: 30, hairBackX: 0, hairBackY: -26,
                             hairFrontX: 0, hairFrontY: 14, headX: 0, headY: 8,
                             waistX: 0, waistY: -10, duration: duration)
            keepHairBehindFace()
            runDirectionalHands(leftPosition: offset(handLeftRestPosition, dx: 6, dy: 3),
                                rightPosition: offset(handRightRestPosition, dx: -6, dy: 3),
                                leftZ: 3,
                                rightZ: 3,
                                leftRestDegrees: -6,
                                rightRestDegrees: 6,
                                swingDegrees: 8,
                                duration: tempo.hand)
        case .down:
            move(flip, to: .zero, duration: duration)
            rotate(flip, toDegrees: 0, duration: duration)
            scaleX(flip, to: 1, duration: duration)
            runDirectionalTail(centerDegrees: 9, amplitude: 6, duration: tempo.tail)
            applyCorePose(upperDegrees: 180, waistDegrees: 0, tailX: 0, tailY: 10,
                          duration: duration)
            applyPartOffsets(faceX: 0, faceY: -16, hairBackX: 0, hairBackY: 58,
                             hairFrontX: 0, hairFrontY: -8, headX: 0, headY: -7,
                             waistX: 0, waistY: 16, duration: duration)
            keepHairBehindFace()
            tail.zPosition = rig.tail.z - 1
            runDirectionalHands(leftPosition: offset(handLeftRestPosition, dx: 6, dy: 3),
                                rightPosition: offset(handRightRestPosition, dx: -6, dy: 3),
                                leftZ: -6,
                                rightZ: -6,
                                leftRestDegrees: -7,
                                rightRestDegrees: 7,
                                swingDegrees: 7,
                                duration: tempo.hand)
        case .right:
            applyLateralDirection(flipX: 1, duration: duration, tempo: tempo)
        case .left:
            applyLateralDirection(flipX: -1, duration: duration, tempo: tempo)
        }
    }

    private func applyLateralDirection(
        flipX: CGFloat,
        duration: Double,
        tempo: (tail: Double, hand: Double)
    ) {
        move(flip, to: .zero, duration: duration)
        rotate(flip, toDegrees: 0, duration: duration)
        scaleX(flip, to: flipX, duration: duration)
        runDirectionalTail(centerDegrees: 0, amplitude: 7, duration: tempo.tail)
        applyCorePose(upperDegrees: -90,
                      waistDegrees: 0,
                      tailX: 0,
                      tailY: 0,
                      duration: duration)
        applyPartOffsets(faceX: 18, faceY: 0, hairBackX: -30, hairBackY: 24,
                         hairFrontX: -5, hairFrontY: 0, headX: 0, headY: 0,
                         waistX: 10, waistY: 0, duration: duration)
        keepHairBehindFace()
        tail.zPosition = rig.tail.z + 1
        runDirectionalHands(leftPosition: offset(handLeftRestPosition, dx: 6, dy: 0),
                            rightPosition: offset(handRightRestPosition, dx: -6, dy: 0),
                            leftZ: 3,
                            rightZ: 3,
                            leftRestDegrees: -14,
                            rightRestDegrees: 14,
                            swingDegrees: 9,
                            duration: tempo.hand)
    }

    private func resetDirectionalPose(animated: Bool) {
        let duration = animated ? 1.0 : 0
        move(flip, to: .zero, duration: duration)
        rotate(flip, toDegrees: 0, duration: duration)
        scaleX(flip, to: 1, duration: duration)
        applyCorePose(upperDegrees: 0, waistDegrees: 0, tailX: 0, tailY: 0,
                      duration: duration)
        applyPartOffsets(faceX: 0, faceY: 0, hairBackX: 0, hairBackY: 0,
                         hairFrontX: 0, hairFrontY: 0, headX: 0, headY: 0,
                         waistX: 0, waistY: 0, duration: duration)
        hairBack.zPosition = rig.hairBack.z
        hairFront.zPosition = hairFrontZ
        tail.zPosition = rig.tail.z
        handLeft.zPosition = rig.handLeft.z
        handRight.zPosition = rig.handRight.z
        move(handLeft, to: handLeftRestPosition, duration: duration)
        move(handRight, to: handRightRestPosition, duration: duration)
    }

    private var directionalTempo: (tail: Double, hand: Double) {
        switch currentAnimationMode {
        case .idle:
            return (tail: 0.9, hand: 1.1)
        case .swing:
            return (tail: 0.48, hand: 0.62)
        case .fast:
            return (tail: 0.22, hand: 0.34)
        }
    }

    private func applyPartOffsets(
        faceX: CGFloat,
        faceY: CGFloat,
        hairBackX: CGFloat,
        hairBackY: CGFloat,
        hairFrontX: CGFloat,
        hairFrontY: CGFloat,
        headX: CGFloat,
        headY: CGFloat,
        waistX: CGFloat,
        waistY: CGFloat,
        duration: Double
    ) {
        faceDirectionOffset = CGPoint(x: faceX, y: faceY)
        move(head, to: offset(rig.head.point, dx: headX, dy: headY), duration: duration)
        move(hairBack, to: offset(rig.hairBack.point, dx: hairBackX, dy: hairBackY), duration: duration)
        move(hairFront, to: offset(rig.hairFront.point, dx: hairFrontX, dy: hairFrontY), duration: duration)
        move(eyeLeftNode, to: offset(rig.eyeLeft.point, dx: faceX, dy: faceY), duration: duration)
        move(eyeRightNode, to: offset(rig.eyeRight.point, dx: faceX, dy: faceY), duration: duration)
        move(eyebrowLeft, to: offset(rig.eyebrowLeft.point, dx: faceX, dy: faceY), duration: duration)
        move(eyebrowRight, to: offset(rig.eyebrowRight.point, dx: faceX, dy: faceY), duration: duration)
        move(mouth, to: offset(rig.mouth.point, dx: faceX, dy: faceY), duration: duration)
        move(waistGroup, to: offset(rig.waistGroup.point, dx: waistX, dy: waistY), duration: duration)
    }

    private func applyCorePose(
        upperDegrees: CGFloat,
        waistDegrees: CGFloat,
        tailX: CGFloat,
        tailY: CGFloat,
        duration: Double
    ) {
        rotate(bodyCore, toDegrees: upperDegrees, duration: duration)
        rotate(waistGroup, toDegrees: waistDegrees, duration: duration)
        move(tail, to: offset(rig.tail.point, dx: tailX, dy: tailY), duration: duration)
    }

    private func keepHairBehindFace() {
        hairFront.zPosition = hairFrontZ
        hairBack.zPosition = min(rig.hairBack.z, hairFrontZ - 0.5)
    }

    private var hairFrontZ: CGFloat {
        let lowestFaceZ = min(eyeLeftNode.zPosition,
                              eyeRightNode.zPosition,
                              eyebrowLeft.zPosition,
                              eyebrowRight.zPosition,
                              mouth.zPosition)
        return min(rig.hairFront.z, lowestFaceZ - 0.5)
    }

    private func runDirectionalTail(centerDegrees: CGFloat, amplitude: CGFloat, duration: Double) {
        tail.removeAllActions()
        tailFin.removeAllActions()
        tail.run(centeredSwing(centerDegrees: centerDegrees, amplitude: amplitude, duration: duration),
                 withKey: "directionTail")
        tailFin.run(centeredSwing(centerDegrees: centerDegrees * -0.6,
                                  amplitude: amplitude * 1.1,
                                  duration: duration),
                    withKey: "directionFin")
    }

    private func runDirectionalHands(
        leftPosition: CGPoint,
        rightPosition: CGPoint,
        leftZ: CGFloat,
        rightZ: CGFloat,
        leftRestDegrees: CGFloat,
        rightRestDegrees: CGFloat,
        swingDegrees: CGFloat,
        duration: Double
    ) {
        handLeft.removeAllActions()
        handRight.removeAllActions()
        handLeft.zPosition = leftZ
        handRight.zPosition = rightZ

        let leftSettle = SKAction.group([
            moveAction(to: leftPosition, duration: 0.18),
            rotateAction(toDegrees: leftRestDegrees, duration: 0.18)
        ])
        let rightSettle = SKAction.group([
            moveAction(to: rightPosition, duration: 0.18),
            rotateAction(toDegrees: rightRestDegrees, duration: 0.18)
        ])
        handLeft.run(.sequence([
            leftSettle,
            centeredSwing(centerDegrees: leftRestDegrees, amplitude: swingDegrees, duration: duration)
        ]), withKey: "directionHand")
        handRight.run(.sequence([
            rightSettle,
            centeredSwing(centerDegrees: rightRestDegrees, amplitude: swingDegrees, duration: duration)
        ]), withKey: "directionHand")
    }

    private func centeredSwing(centerDegrees: CGFloat, amplitude: CGFloat, duration: Double) -> SKAction {
        let action = SKAction.repeatForever(.sequence([
            rotateAction(toDegrees: centerDegrees + amplitude, duration: duration),
            rotateAction(toDegrees: centerDegrees - amplitude, duration: duration)
        ]))
        action.eaeInEaseOut()
        return action
    }

    private func move(_ node: SKNode, to position: CGPoint, duration: Double) {
        node.run(moveAction(to: position, duration: duration), withKey: "directionPosition")
    }

    private func rotate(_ node: SKNode, toDegrees degrees: CGFloat, duration: Double) {
        node.run(rotateAction(toDegrees: degrees, duration: duration), withKey: "directionRotation")
    }

    private func scaleX(_ node: SKNode, to value: CGFloat, duration: Double) {
        let scale = SKAction.scaleX(to: value, duration: duration)
        scale.eaeInEaseOut()
        node.run(scale, withKey: "directionScaleX")
    }

    private func moveAction(to position: CGPoint, duration: Double) -> SKAction {
        let action = SKAction.move(to: position, duration: duration)
        action.eaeInEaseOut()
        return action
    }

    private func rotateAction(toDegrees degrees: CGFloat, duration: Double) -> SKAction {
        let rotate = SKAction.rotate(toDegrees: degrees, duration: duration)
        rotate.eaeInEaseOut()
        return rotate
    }

    private func offset(_ point: CGPoint, dx: CGFloat = 0, dy: CGFloat = 0) -> CGPoint {
        CGPoint(x: point.x + dx, y: point.y + dy)
    }

    private var handLeftRestPosition: CGPoint {
        pointInChest(rig.handLeft.point)
    }

    private var handRightRestPosition: CGPoint {
        pointInChest(rig.handRight.point)
    }

    private func pointInChest(_ point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x - rig.waistGroup.point.x - rig.chest.point.x) / rig.chest.scale,
                y: (point.y - rig.waistGroup.point.y - rig.chest.point.y) / rig.chest.scale)
    }
}
