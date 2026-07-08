//
//  Mermaid.swift
//  Ester
//
//  Created by yury antony on 23/07/24.
//

import Foundation
import SpriteKit

/// Forma visual por fase de vida.
enum MermaidFormKind: String, CaseIterable, Codable {
    case baby
    case child
    case young
    case adult

    var displayName: String {
        switch self {
        case .baby:
            return "Baby"
        case .child:
            return "Child"
        case .young:
            return "Young"
        case .adult:
            return "Adult"
        }
    }
}

enum MermaidFigurePart: String, CaseIterable, Codable {
    case head
    case hairBack
    case hairFront
    case eyeLeft
    case eyeRight
    case eyebrowLeft
    case eyebrowRight
    case mouth
    case waistBack
    case waistFront
    case tail
    case tailFin
    case handLeft
    case handRight
    case chest

    var displayName: String {
        rawValue
    }
}

protocol MermaidFigure {
    var root: SKNode { get }

    func applyAnimationMode(_ mode: MovementType)
    func applyDirection(_ direction: MovementDirection)
    func applyPalette(_ palette: MermaidPalette)
    func applyFacePose(_ pose: MermaidFacePose, animated: Bool)

    func setPartX(_ x: CGFloat, for part: MermaidFigurePart)
    func setPartY(_ y: CGFloat, for part: MermaidFigurePart)
    func setPartScale(_ scale: CGFloat, for part: MermaidFigurePart)
    func setPartPosition(_ position: CGPoint, for part: MermaidFigurePart)
}

extension MermaidFigure {
    func setPartPosition(_ position: CGPoint, for part: MermaidFigurePart) {
        setPartX(position.x, for: part)
        setPartY(position.y, for: part)
    }
}

class Mermaid {
    var base: SKSpriteNode
    var currentDirection: Direction = .none

    private(set) var formKind: MermaidFormKind = .young
    private(set) var figure: MermaidFigure = YoungMermaidFigure()
    private(set) var formRevision = 0

    enum Direction {
        case up
        case down
        case right
        case left
        case none
    }

    init() {
        base = SKSpriteNode()
        base.addChild(figure.root)
        figure.applyAnimationMode(.idle)
        figure.applyFacePose(.pose(for: .neutral), animated: false)
    }

    private static func formKind(for phase: MermaidPhase) -> MermaidFormKind {
        switch phase {
        case .egg:
            return .young
        case .baby:
            return .baby
        case .child:
            return .child
        case .teen, .young:
            return .young
        case .adult:
            return .adult
        }
    }

    /// Troca o rig visual conforme a fase de vida.
    func setForm(for phase: MermaidPhase) {
        setForm(Self.formKind(for: phase))
    }

    /// Troca o rig visual pela forma selecionada.
    func setForm(_ kind: MermaidFormKind) {
        guard kind != formKind else { return }
        replaceForm(kind)
    }

    func reloadForm() {
        replaceForm(formKind)
    }

    private func replaceForm(_ kind: MermaidFormKind) {

        formKind = kind
        base.removeAllActions()
        base.removeAllChildren()

        switch kind {
        case .baby:
            figure = BabyMermaidFigure()
        case .child:
            figure = ChildMermaidFigure()
        case .young:
            figure = YoungMermaidFigure()
        case .adult:
            figure = AdultMermaidFigure()
        }

        formRevision += 1
        base.addChild(figure.root)
        currentDirection = .none
        figure.applyAnimationMode(.idle)
        figure.applyFacePose(.pose(for: .neutral), animated: false)
    }

    func setFigurePartX(_ x: CGFloat, for part: MermaidFigurePart) {
        figure.setPartX(x, for: part)
    }

    func setFigurePartY(_ y: CGFloat, for part: MermaidFigurePart) {
        figure.setPartY(y, for: part)
    }

    func setFigurePartScale(_ scale: CGFloat, for part: MermaidFigurePart) {
        figure.setPartScale(scale, for: part)
    }

    func setFigurePartPosition(_ position: CGPoint, for part: MermaidFigurePart) {
        figure.setPartPosition(position, for: part)
    }

    func applyFacePose(_ pose: MermaidFacePose, animated: Bool) {
        figure.applyFacePose(pose, animated: animated)
    }

    func applyExpression(_ expression: MermaidExpressionName, animated: Bool) {
        figure.applyFacePose(MermaidExpressionLibrary.pose(named: expression), animated: animated)
    }
}

extension Mermaid {
    func applyIdleMoveMode() {
        base.removeAllActions()
        currentDirection = .none
        figure.applyAnimationMode(.idle)
    }
}
