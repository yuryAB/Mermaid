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
    private var hatchRing: SKShapeNode?
    private var lastRingProgress: CGFloat = -1
    private var lastTapTime: TimeInterval = 0
    private var tapCount = 0
    private var crackCount = 0
    private var announcedAlmostBorn = false
    private let crackThresholds: [CGFloat] = [0.35, 0.6, 0.82]

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
        case .teen: return Requirement(ageDays: 4, xp: 1000, zone: .blue)
        case .young: return Requirement(ageDays: 14, xp: 4000, zone: .deep)
        case .adult: return Requirement(ageDays: 60, xp: 16000, zone: .abyss)
        }
    }

    /// Progresso 0–1 até a próxima fase (menor critério domina).
    func progressToNext() -> CGFloat {
        if ctx.stats.phase == .egg { return ctx.stats.hatchProgress }
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
        egg.position = World.startPosition + CGPoint(x: 0, y: 60)
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
        shell.run(pulse)

        // anel de progresso do choco ao redor do ovo
        let ring = SKShapeNode()
        ring.strokeColor = UIColor(red: 1, green: 0.92, blue: 0.7, alpha: 0.95)
        ring.lineWidth = 6
        ring.lineCap = .round
        ring.glowWidth = 4
        ring.fillColor = .clear
        egg.addChild(ring)
        hatchRing = ring

        world.addChild(egg)
        eggNode = egg
        updateRing()

        // posiciona a sereia onde o ovo está, para nascer ali
        ctx.mermaidEntity.mermaid.base.position = egg.position
    }

    // MARK: - Interação com o ovo

    /// Toques aquecem o ovo: cada carinho adianta o choco.
    func tapEgg() {
        guard ctx.stats.phase == .egg, let egg = eggNode else { return }
        let now = Date().timeIntervalSince1970
        guard now - lastTapTime > 0.3 else { return }
        lastTapTime = now
        tapCount += 1

        addHatchProgress(0.02)

        if egg.action(forKey: "wiggle") == nil {
            let wiggle = SKAction.sequence([
                .rotate(toAngle: 0.12, duration: 0.08),
                .rotate(toAngle: -0.12, duration: 0.12),
                .rotate(toAngle: 0, duration: 0.08)
            ])
            egg.run(wiggle, withKey: "wiggle")
        }

        if let world = worldNode {
            let spark = SKShapeNode(circleOfRadius: 5)
            spark.fillColor = UIColor(red: 1, green: 0.9, blue: 0.6, alpha: 0.9)
            spark.strokeColor = .clear
            spark.glowWidth = 6
            spark.position = egg.position + CGPoint(x: .random(in: -50...50), y: 60)
            spark.zPosition = 12
            world.addChild(spark)
            spark.run(.sequence([
                .group([.moveBy(x: 0, y: 70, duration: 0.8), .fadeOut(withDuration: 0.8)]),
                .removeFromParent()
            ]))
        }

        if tapCount % 8 == 0 {
            let phrases = [
                "O ovo se mexeu! 🥚",
                "Algo respondeu lá de dentro... ✨",
                "Está ficando quentinho! Continue 💛",
                "Quase lá... ela sente seu carinho."
            ]
            ctx.say(phrases.randomElement()!)
        }
    }

    /// Progresso de choco vindo de tempo, toques ou da Trama das Marés.
    func addHatchProgress(_ amount: CGFloat) {
        guard ctx.stats.phase == .egg else { return }
        ctx.stats.hatchProgress = min(1, ctx.stats.hatchProgress + amount)
        updateRing()
        updateCracks()
        if ctx.stats.hatchProgress >= 0.82 && !announcedAlmostBorn {
            announcedAlmostBorn = true
            ctx.say("Ela está quase nascendo... 🥚✨")
        }
        if ctx.stats.hatchProgress >= 1 { hatch() }
    }

    /// Rachaduras vão aparecendo conforme o choco avança.
    private func updateCracks() {
        guard let egg = eggNode else { return }
        let progress = ctx.stats.hatchProgress
        while crackCount < crackThresholds.count && progress >= crackThresholds[crackCount] {
            crackCount += 1
            let path = UIBezierPath()
            let startX = CGFloat.random(in: -30...30)
            let startY = CGFloat.random(in: -30...40)
            path.move(to: CGPoint(x: startX, y: startY))
            var point = CGPoint(x: startX, y: startY)
            for _ in 0..<3 {
                point.x += .random(in: -16...16)
                point.y -= .random(in: 8...18)
                path.addLine(to: point)
            }
            let crack = SKShapeNode(path: path.cgPath)
            crack.strokeColor = UIColor(white: 1, alpha: 0.75)
            crack.lineWidth = 2
            crack.zPosition = 2
            crack.alpha = 0
            egg.addChild(crack)
            crack.run(.fadeIn(withDuration: 0.4))
        }
    }

    private func updateRing() {
        guard let ring = hatchRing else { return }
        let progress = ctx.stats.hatchProgress
        guard abs(progress - lastRingProgress) > 0.004 else { return }
        lastRingProgress = progress
        let start = CGFloat.pi / 2
        let path = UIBezierPath(arcCenter: .zero, radius: 102,
                                startAngle: start,
                                endAngle: start + progress * 2 * .pi,
                                clockwise: true)
        ring.path = path.cgPath
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        if ctx.stats.phase == .egg {
            // não choca no meio de um puzzle aberto
            guard ctx.scene?.isPuzzleOpen != true else { return }
            // o tempo sozinho choca em ~4 min; interações aceleram muito
            addHatchProgress(dt / 240)
            return
        }
        checkTimer -= dt
        guard checkTimer <= 0 else { return }
        checkTimer = 5
        if canEvolve() { evolve() }
    }

    private func hatch() {
        guard let egg = eggNode else { return }
        ctx.stats.phase = .baby
        let mermaid = ctx.mermaidEntity.mermaid
        mermaid.setForm(for: .baby)
        eggNode = nil
        hatchRing = nil
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
        let mermaid = ctx.mermaidEntity.mermaid
        mermaid.setForm(for: next)
        ctx.stats.pearls += 20
        ctx.stats.courage = min(100, ctx.stats.courage + 5)
        ctx.stats.addMemory("Evoluiu para \(next.displayName)")
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
