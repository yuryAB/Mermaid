//
//  MermaidAppearance.swift
//  Ester
//
//  Aplicação dinâmica de paleta (adaptação à profundidade) e variantes
//  visuais de direção/animação que não movem o nó base — a posição agora
//  é controlada pelo AutonomySystem.
//

import Foundation
import SpriteKit

extension Mermaid {
    /// Tinge todas as partes do corpo com a paleta interpolada pela profundidade.
    func applyPalette(_ palette: MermaidPalette) {
        head.headNode.color = palette.skin
        head.hairFrontNode.color = palette.hair
        head.hairBackNode.color = palette.hair

        body.body.color = palette.skin
        body.waist.color = palette.skin
        body.articulation.color = palette.vibrant1
        body.waistScale.color = palette.vibrant1
        body.finScale.color = palette.vibrant1
        body.fin.color = palette.vibrant2

        arms.left.color = palette.skin
        arms.right.color = palette.skin
    }

    /// Atualiza apenas os visuais de direção (cabelo, braços, rosto),
    /// sem disparar as SKActions de deslocamento do nó base.
    func setVisualDirection(_ direction: Direction) {
        currentDirection = direction
        switch direction {
        case .up:
            arms.setUpMoveMode()
            head.setUpMoveMode()
            body.setUpMoveMode()
            face.setUpMoveMode()
        case .down:
            arms.setDownMoveMode()
            head.setDownMoveMode()
            body.setDownMoveMode()
            face.setDownMoveMode()
        case .right:
            arms.setRightMoveMode()
            head.setRightMoveMode()
            body.setRightMoveMode()
            face.setRightMoveMode()
        case .left:
            arms.setLeftMoveMode()
            head.setLeftMoveMode()
            body.setLeftMoveMode()
            face.setLeftMoveMode()
        case .none:
            break
        }
    }

    /// Ritmo de nado (ondulação do corpo) sem mover o nó base.
    func setAnimationMode(_ mode: MovementType) {
        switch mode {
        case .idle:
            currentDirection = .none
            arms.applyIdleMoveMode()
            head.applyIdleMoveMode()
            body.applyIdleMoveMode()
            face.applyIdleMoveMode()
        case .swing:
            body.applySwingMoveMode()
        case .fast:
            body.applyFastMoveMode()
        }
    }
}
