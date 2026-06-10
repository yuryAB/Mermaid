//
//  BabyMermaidRig.swift
//  Ester
//

import Foundation
import SpriteKit

struct BabyMermaidRig: Codable {
    var hairBack = MermaidRigPosition(x: 0, y: 40, z: -2)
    var hairFront = MermaidRigPosition(x: 0, y: 110, z: 3)
    var head = MermaidRigPosition(x: 0, y: -20, z: 0, scale: 1.5)
    var eyeLeft = MermaidRigPosition(x: -52, y: 0, z: 2)
    var eyeRight = MermaidRigPosition(x: 52, y: 0, z: 2)
    var eyebrowLeft = MermaidRigPosition(x: -52, y: 32, z: 4)
    var eyebrowRight = MermaidRigPosition(x: 52, y: 32, z: 4)
    var mouth = MermaidRigPosition(x: 0, y: -35, z: 3)
    var waistGroup = MermaidRigPosition(x: 0, y: -150, z: 1)
    var waistBack = MermaidRigPosition(x: 0, y: -108, z: -1)
    var waistFront = MermaidRigPosition(x: 0, y: -180, z: 1)
    var tail = MermaidRigPosition(x: 0, y: 0, z: 2)
    var tailFin = MermaidRigPosition(x: 0, y: -220, z: 0, scale: 0.85)
    var handLeft = MermaidRigPosition(x: -50, y: -58, z: 2)
    var handRight = MermaidRigPosition(x: 50, y: -58, z: 2)

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
            return nil
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
            break
        }
    }
}
