//
//  AdultMermaidRig.swift
//  Ester
//

import Foundation
import SpriteKit

struct AdultMermaidRig: Codable {
    var head = MermaidRigPosition(x: 0, y: 0, z: 0)
    var hairBack = MermaidRigPosition(x: 0, y: 0, z: -1)
    var hairFront = MermaidRigPosition(x: 0, y: 0, z: 1)
    var body = MermaidRigPosition(x: 0, y: -220, z: 1)
    var face = MermaidRigPosition(x: 0, y: 0, z: 3)
    var eyebrowGroup = MermaidRigPosition(x: 0, y: 45, z: 0)
    var eyeGroup = MermaidRigPosition(x: 0, y: 15, z: 0)
    var mouth = MermaidRigPosition(x: 0, y: -15, z: 0)
    var eyebrowLeft = MermaidRigPosition(x: -40, y: 0, z: 0)
    var eyebrowRight = MermaidRigPosition(x: 40, y: 0, z: 0)
    var eyeLeft = MermaidRigPosition(x: -40, y: 0, z: 0)
    var eyeRight = MermaidRigPosition(x: 40, y: 0, z: 0)
    var waistBack = MermaidRigPosition(x: 0, y: -230, z: 0)
    var waistFront = MermaidRigPosition(x: 0, y: 0, z: 1)
    var tail = MermaidRigPosition(x: 0, y: -230, z: 0)
    var extraTailSegment = MermaidRigPosition(x: 0, y: -200, z: 0)
    var tailFin = MermaidRigPosition(x: 0, y: -140, z: 0)
    var handLeft = MermaidRigPosition(x: -75, y: 0, z: 3)
    var handRight = MermaidRigPosition(x: 75, y: 0, z: -1)

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
            return tail
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
            tail.add(delta, axis: axis)
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
