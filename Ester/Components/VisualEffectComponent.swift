//
//  VisualEffectComponent.swift
//  Ester
//

import GameplayKit
import SpriteKit

enum VisualEffect {
    case bob(amplitude: CGFloat, frequency: CGFloat)
    case glow(intensity: CGFloat)
    case pulse(scale: CGFloat, duration: CGFloat)
    case fadeIn(duration: CGFloat)
    case fadeOut(duration: CGFloat)
}

final class VisualEffectComponent: GKComponent {
    private var effects: [VisualEffect] = []
    private var bobPhase: CGFloat = .random(in: 0...(.pi * 2))
    private var pulsePhase: CGFloat = .random(in: 0...(.pi * 2))

    func addEffect(_ effect: VisualEffect) {
        effects.append(effect)
    }

    func clearEffects() {
        effects.removeAll()
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let node = entity?.component(ofType: NodeComponent.self)?.node else { return }

        for effect in effects {
            switch effect {
            case .bob(let amplitude, let frequency):
                bobPhase += CGFloat(seconds) * frequency
                node.position = CGPoint(
                    x: node.position.x,
                    y: node.position.y + sin(bobPhase) * amplitude * CGFloat(seconds)
                )
            case .glow(let intensity):
                if let shape = node as? SKShapeNode {
                    shape.glowWidth = intensity
                }
            case .pulse(let scale, let duration):
                pulsePhase += CGFloat(seconds)
                let s = 1 + sin(pulsePhase / duration * .pi * 2) * (scale - 1) * 0.5
                node.setScale(s)
            case .fadeIn(let duration):
                node.alpha += CGFloat(seconds) / CGFloat(duration)
                if node.alpha >= 1 { effects.removeAll { if case .fadeIn = $0 { return true }; return false } }
            case .fadeOut(let duration):
                node.alpha -= CGFloat(seconds) / CGFloat(duration)
                if node.alpha <= 0 { effects.removeAll { if case .fadeOut = $0 { return true }; return false } }
            }
        }
    }
}
