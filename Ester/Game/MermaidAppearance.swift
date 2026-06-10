//
//  MermaidAppearance.swift
//  Ester
//
//  Aplicação dinâmica de paleta (adaptação à profundidade) e variantes
//  visuais de direção/animação que não movem o nó base.
//

import Foundation
import SpriteKit

extension Mermaid {
    /// Tinge todas as partes do corpo com a paleta interpolada pela profundidade.
    func applyPalette(_ palette: MermaidPalette) {
        figure.applyPalette(palette)
    }

    /// Atualiza apenas os visuais de direção (cabelo, braços, rosto),
    /// sem disparar as SKActions de deslocamento do nó base.
    func setVisualDirection(_ direction: Direction) {
        currentDirection = direction
        switch direction {
        case .up:
            figure.applyDirection(.up)
        case .down:
            figure.applyDirection(.down)
        case .right:
            figure.applyDirection(.right)
        case .left:
            figure.applyDirection(.left)
        case .none:
            break
        }
    }

    /// Ritmo de nado (ondulação do corpo) sem mover o nó base.
    func setAnimationMode(_ mode: MovementType) {
        switch mode {
        case .idle:
            currentDirection = .none
            figure.applyAnimationMode(.idle)
        case .swing:
            figure.applyAnimationMode(.swing)
        case .fast:
            figure.applyAnimationMode(.fast)
        }
    }
}
