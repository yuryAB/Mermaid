//
//  YoungMermaidFigure.swift
//  Ester
//

import Foundation
import SpriteKit

final class YoungMermaidFigure: MermaidFigure {
    let root = SKNode()

    private let head = MermaidHead()
    private let body = MermaidBody()
    private let arms = MermaidArms()
    private let face = MermaidFace()
    private let rig: YoungMermaidRig

    init(rig: YoungMermaidRig = MermaidRigStore.shared.document.young) {
        self.rig = rig
        assembleNodes()
        applyRig()
        applyAnimationMode(.idle)
    }

    private func assembleNodes() {
        body.body.zPosition = 1
        head.headNode.addChild(body.body)

        face.base.zPosition = 3
        head.headNode.addChild(face.base)

        body.body.addChild(arms.left)
        body.body.addChild(arms.right)

        root.addChild(head.headNode)
    }

    private func applyRig() {
        head.headNode.position = rig.head.point
        head.headNode.zPosition = rig.head.z
        head.headNode.setScale(rig.head.scale)
        head.hairBackNode.position = rig.hairBack.point
        head.hairBackNode.zPosition = rig.hairBack.z
        head.hairBackNode.setScale(rig.hairBack.scale)
        head.hairFrontNode.position = rig.hairFront.point
        head.hairFrontNode.zPosition = rig.hairFront.z
        head.hairFrontNode.setScale(rig.hairFront.scale)
        body.body.position = rig.body.point
        body.body.zPosition = rig.body.z
        body.body.setScale(rig.body.scale)
        face.base.position = rig.face.point
        face.base.zPosition = rig.face.z
        face.base.setScale(rig.face.scale)
        face.eyebrows.base.position = rig.eyebrowGroup.point
        face.eyebrows.base.zPosition = rig.eyebrowGroup.z
        face.eyebrows.base.setScale(rig.eyebrowGroup.scale)
        face.eyes.base.position = rig.eyeGroup.point
        face.eyes.base.zPosition = rig.eyeGroup.z
        face.eyes.base.setScale(rig.eyeGroup.scale)
        face.mouth.base.position = rig.mouth.point
        face.mouth.base.zPosition = rig.mouth.z
        face.mouth.base.setScale(rig.mouth.scale)
        face.eyebrows.left.position = rig.eyebrowLeft.point
        face.eyebrows.left.zPosition = rig.eyebrowLeft.z
        face.eyebrows.left.setScale(rig.eyebrowLeft.scale)
        face.eyebrows.right.position = rig.eyebrowRight.point
        face.eyebrows.right.zPosition = rig.eyebrowRight.z
        face.eyebrows.right.setScale(rig.eyebrowRight.scale)
        face.eyes.left.position = rig.eyeLeft.point
        face.eyes.left.zPosition = rig.eyeLeft.z
        face.eyes.left.setScale(rig.eyeLeft.scale)
        face.eyes.right.position = rig.eyeRight.point
        face.eyes.right.zPosition = rig.eyeRight.z
        face.eyes.right.setScale(rig.eyeRight.scale)
        body.waist.position = rig.waistBack.point
        body.waist.zPosition = rig.waistBack.z
        body.waist.setScale(rig.waistBack.scale)
        body.waistScale.position = rig.waistFront.point
        body.waistScale.zPosition = rig.waistFront.z
        body.waistScale.setScale(rig.waistFront.scale)
        body.articulation.position = rig.tail.point
        body.articulation.zPosition = rig.tail.z
        body.articulation.setScale(rig.tail.scale)
        body.fin.position = rig.tailFin.point
        body.fin.zPosition = rig.tailFin.z
        body.fin.setScale(rig.tailFin.scale)
        arms.left.position = rig.handLeft.point
        arms.left.zPosition = rig.handLeft.z
        arms.left.setScale(rig.handLeft.scale)
        arms.right.position = rig.handRight.point
        arms.right.zPosition = rig.handRight.z
        arms.right.setScale(rig.handRight.scale)
    }

    func applyAnimationMode(_ mode: MovementType) {
        switch mode {
        case .idle:
            body.applyIdleMoveMode()
            head.applyIdleMoveMode()
            arms.applyIdleMoveMode()
            face.applyIdleMoveMode()
        case .swing:
            body.applySwingMoveMode()
        case .fast:
            body.applyFastMoveMode()
        }
    }

    func applyDirection(_ direction: MovementDirection) {
        switch direction {
        case .up:
            head.setUpMoveMode()
            body.setUpMoveMode()
            arms.setUpMoveMode()
            face.setUpMoveMode()
        case .down:
            head.setDownMoveMode()
            body.setDownMoveMode()
            arms.setDownMoveMode()
            face.setDownMoveMode()
        case .right:
            head.setRightMoveMode()
            body.setRightMoveMode()
            arms.setRightMoveMode()
            face.setRightMoveMode()
        case .left:
            head.setLeftMoveMode()
            body.setLeftMoveMode()
            arms.setLeftMoveMode()
            face.setLeftMoveMode()
        }
    }

    func applyPalette(_ palette: MermaidPalette) {
        head.headNode.color = palette.skin
        head.hairFrontNode.color = palette.hair
        head.hairBackNode.color = palette.hair
        head.headNode.colorBlendFactor = 1.0
        head.hairFrontNode.colorBlendFactor = 0.55
        head.hairBackNode.colorBlendFactor = 0.55

        body.body.color = palette.skin
        body.waist.color = palette.skin
        body.articulation.color = palette.vibrant1
        body.waistScale.color = palette.vibrant1
        body.finScale.color = palette.vibrant1
        body.fin.color = palette.vibrant2
        body.body.colorBlendFactor = 1.0
        body.waist.colorBlendFactor = 1.0
        body.articulation.colorBlendFactor = 0.5
        body.waistScale.colorBlendFactor = 0.5
        body.finScale.colorBlendFactor = 0.5
        body.fin.colorBlendFactor = 1.0

        arms.left.color = palette.skin
        arms.right.color = palette.skin
        arms.left.colorBlendFactor = 0.6
        arms.right.colorBlendFactor = 0.6

        face.eyebrows.left.color = palette.hair
        face.eyebrows.right.color = palette.hair
        face.eyebrows.left.colorBlendFactor = 1.0
        face.eyebrows.right.colorBlendFactor = 1.0
        face.eyes.left.color = palette.hair
        face.eyes.right.color = palette.hair
        face.eyes.left.colorBlendFactor = 0.25
        face.eyes.right.colorBlendFactor = 0.25
        face.mouth.base.color = palette.skin
        face.mouth.base.colorBlendFactor = 0.25
    }

    func setPartX(_ x: CGFloat, for part: MermaidFigurePart) {
        node(for: part)?.position.x = x
    }

    func setPartY(_ y: CGFloat, for part: MermaidFigurePart) {
        node(for: part)?.position.y = y
    }

    func setPartScale(_ scale: CGFloat, for part: MermaidFigurePart) {
        node(for: part)?.setScale(scale)
    }

    private func node(for part: MermaidFigurePart) -> SKNode? {
        switch part {
        case .head:
            return head.headNode
        case .hairBack:
            return head.hairBackNode
        case .hairFront:
            return head.hairFrontNode
        case .eyeLeft:
            return face.eyes.left
        case .eyeRight:
            return face.eyes.right
        case .eyebrowLeft:
            return face.eyebrows.left
        case .eyebrowRight:
            return face.eyebrows.right
        case .mouth:
            return face.mouth.base
        case .waistBack:
            return body.waist
        case .waistFront:
            return body.waistScale
        case .tail:
            return body.articulation
        case .tailFin:
            return body.fin
        case .handLeft:
            return arms.left
        case .handRight:
            return arms.right
        case .chest:
            return nil
        }
    }
}
