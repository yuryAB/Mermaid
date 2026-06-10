//
//  ChildMermaidRig.swift
//  Ester
//

import Foundation
import SpriteKit

struct ChildMermaidRig: Codable {
    var hairBack = MermaidRigPosition(x: 0, y: 10, z: -2)
    var hairFront = MermaidRigPosition(x: 0, y: 110, z: 3)
    var head = MermaidRigPosition(x: 0, y: -20, z: 0, scale: 1.2)
    var eyeLeft = MermaidRigPosition(x: -52, y: 0, z: 2)
    var eyeRight = MermaidRigPosition(x: 52, y: 0, z: 2)
    var eyebrowLeft = MermaidRigPosition(x: -52, y: 28, z: 4)
    var eyebrowRight = MermaidRigPosition(x: 52, y: 28, z: 4)
    var mouth = MermaidRigPosition(x: 0, y: -32, z: 3)
    var waistGroup = MermaidRigPosition(x: 0, y: -200, z: 1)
    var chest = MermaidRigPosition(x: 0, y: -42, z: 0)
    var waistBack = MermaidRigPosition(x: 0, y: -138, z: -1)
    var waistFront = MermaidRigPosition(x: 0, y: -200, z: 1)
    var tail = MermaidRigPosition(x: 0, y: 0, z: -1)
    var tailFin = MermaidRigPosition(x: 0, y: -220, z: 0)
    var handLeft = MermaidRigPosition(x: -105, y: -58, z: 2)
    var handRight = MermaidRigPosition(x: 105, y: -58, z: 2)
    var chestSize = CGSize(width: 180, height: 180)

    func position(for part: MermaidFigurePart) -> MermaidRigPosition? {
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

    mutating func add(_ delta: CGFloat, axis: MermaidRigAxis, part: MermaidFigurePart) {
        switch part {
        case .head:
            head.add(delta, axis: axis)
        case .hairBack:
            hairBack.add(delta, axis: axis)
        case .hairFront:
            hairFront.add(delta, axis: axis)
        case .eyeLeft:
            eyeLeft.add(delta, axis: axis)
        case .eyeRight:
            eyeRight.add(delta, axis: axis)
        case .eyebrowLeft:
            eyebrowLeft.add(delta, axis: axis)
        case .eyebrowRight:
            eyebrowRight.add(delta, axis: axis)
        case .mouth:
            mouth.add(delta, axis: axis)
        case .waistBack:
            waistBack.add(delta, axis: axis)
        case .waistFront:
            waistFront.add(delta, axis: axis)
        case .tail:
            break
        case .tailFin:
            tailFin.add(delta, axis: axis)
        case .handLeft:
            handLeft.add(delta, axis: axis)
        case .handRight:
            handRight.add(delta, axis: axis)
        case .chest:
            chest.add(delta, axis: axis)
        }
    }
}
