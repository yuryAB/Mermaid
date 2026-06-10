//
//  GrowthSystem.swift
//  Ester
//
//  Evolução por fases: ovo → bebê → criança → adolescente → jovem → adulta.
//  Progresso lento, pensado para acompanhamento diário (a fase adulta
//  leva meses). Depende de idade real, XP, exploração e puzzles.
//

import Foundation
import SpriteKit

final class GrowthSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var eggNode: SKNode?
    private var checkTimer: CGFloat = 3

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    // MARK: - Requisitos (idade em dias reais)

    private struct Requirement {
        let ageDays: Double
        let xp: CGFloat
        let zone: DepthZone?
    }

    private func requirement(toReach phase: MermaidPhase) -> Requirement? {
        switch phase {
        case .egg: return nil
        case .baby: return Requirement(ageDays: 0.002, xp: 0, zone: nil)          // ~3 min
        case .child: return Requirement(ageDays: 1, xp: 150, zone: nil)
        case .teen: return Requirement(ageDays: 4, xp: 1000, zone: .reef)
        case .young: return Requirement(ageDays: 14, xp: 4000, zone: .deep)
        case .adult: return Requirement(ageDays: 60, xp: 16000, zone: .abyss)
        }
    }

    /// Progresso 0–1 até a próxima fase (menor critério domina).
    func progressToNext() -> CGFloat {
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else { return 1 }
        var fractions: [CGFloat] = []
        fractions.append(CGFloat(min(1, ctx.stats.ageDays / req.ageDays)))
        if req.xp > 0 { fractions.append(min(1, ctx.stats.xp / req.xp)) }
        if let zone = req.zone { fractions.append(ctx.stats.isUnlocked(zone) ? 1 : 0.5 * ctx.stats.adaptation(for: zone.adaptationGate?.zone ?? .shallow) / 100) }
        return fractions.min() ?? 0
    }

    private func canEvolve() -> Bool {
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else { return false }
        if ctx.stats.ageDays < req.ageDays { return false }
        if ctx.stats.xp < req.xp { return false }
        if let zone = req.zone, !ctx.stats.isUnlocked(zone) { return false }
        if next == .adult && !ctx.stats.isUnlocked(.surface) { return false }
        return true
    }

    // MARK: - Setup

    func setup() {
        let mermaid = ctx.mermaidEntity.mermaid
        if ctx.stats.phase == .egg {
            mermaid.base.isHidden = true
            ctx.autonomy.paused = true
            spawnEgg()
        } else {
            mermaid.base.setScale(ctx.stats.phase.scale)
        }
    }

    private func spawnEgg() {
        guard let world = worldNode else { return }
        let egg = SKNode()
        egg.position = ctx.shelter.position + CGPoint(x: 0, y: 40)
        egg.zPosition = 10

        let shell = SKShapeNode(ellipseOf: CGSize(width: 110, height: 150))
        shell.fillColor = UIColor(red: 0.75, green: 0.85, blue: 0.9, alpha: 0.9)
        shell.strokeColor = UIColor(white: 1, alpha: 0.8)
        shell.glowWidth = 10
        egg.addChild(shell)

        let inner = SKShapeNode(ellipseOf: CGSize(width: 70, height: 100))
        inner.fillColor = UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.7)
        inner.strokeColor = .clear
        egg.addChild(inner)

        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.06, duration: 1.4),
            .scale(to: 1.0, duration: 1.4)
        ]))
        pulse.eaeInEaseOut()
        egg.run(pulse)

        world.addChild(egg)
        eggNode = egg

        // posiciona a sereia onde o ovo está, para nascer ali
        ctx.mermaidEntity.mermaid.base.position = egg.position
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        checkTimer -= dt
        guard checkTimer <= 0 else { return }
        checkTimer = 5

        if ctx.stats.phase == .egg {
            if canEvolve() { hatch() }
            return
        }
        if canEvolve() { evolve() }
    }

    private func hatch() {
        guard let egg = eggNode else { return }
        ctx.stats.phase = .baby
        eggNode = nil

        let mermaid = ctx.mermaidEntity.mermaid
        mermaid.base.position = egg.position
        mermaid.base.setScale(0.05)
        mermaid.base.alpha = 0
        mermaid.base.isHidden = false

        egg.run(.sequence([
            .group([.scale(to: 1.5, duration: 0.8), .fadeOut(withDuration: 0.8)]),
            .removeFromParent()
        ]))
        mermaid.base.run(.sequence([
            .wait(forDuration: 0.5),
            .group([
                .fadeIn(withDuration: 1.2),
                .scale(to: MermaidPhase.baby.scale, duration: 1.5)
            ]),
            .run { [weak self] in
                self?.ctx.autonomy.paused = false
            }
        ]))
        ctx.stats.gainXP(10)
        ctx.stats.addMemory("Nasceu! 🌊")
        ctx.say("Ela nasceu! 🧜‍♀️🌊")
        ctx.stats.save()
    }

    private func evolve() {
        guard let next = ctx.stats.phase.next else { return }
        ctx.stats.phase = next
        ctx.stats.pearls += 20
        ctx.stats.courage = min(100, ctx.stats.courage + 5)
        ctx.stats.addMemory("Evoluiu para \(next.displayName)")

        let mermaid = ctx.mermaidEntity.mermaid
        let grow = SKAction.scale(to: next.scale, duration: 1.5)
        grow.eaeInEaseOut()
        mermaid.base.run(grow)

        // brilho de evolução
        if let world = worldNode {
            let burst = SKShapeNode(circleOfRadius: 60)
            burst.fillColor = UIColor(white: 1, alpha: 0.5)
            burst.strokeColor = .white
            burst.glowWidth = 24
            burst.position = mermaid.base.position
            burst.zPosition = 20
            world.addChild(burst)
            burst.run(.sequence([
                .group([.scale(to: 5, duration: 1.2), .fadeOut(withDuration: 1.2)]),
                .removeFromParent()
            ]))
        }

        ctx.say("✨ Ela evoluiu: agora é \(next.displayName)! 💠+20")
        ctx.stats.save()
    }
}
