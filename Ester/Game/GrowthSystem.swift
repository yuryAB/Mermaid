//
//  GrowthSystem.swift
//  Ester
//
//  Evolução por fases: ovo → bebê → criança → adolescente → jovem → adulta.
//  Progresso lento, pensado para acompanhamento real: 1 mês da bebê para
//  criança, 2 meses para a próxima fase, e assim por diante.
//

import Foundation
import SpriteKit

final class GrowthSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var eggNode: SKNode?
    private var checkTimer: CGFloat = 3
    private var hatchRing: SKShapeNode?
    private var hatchRingTrack: SKShapeNode?
    private weak var eggShellNode: SKShapeNode?
    private weak var eggCoreGlowNode: SKShapeNode?
    private weak var eggCrackLayer: SKNode?
    private var lastRingProgress: CGFloat = -1
    private var lastTapTime: TimeInterval = 0
    private var tapCount = 0
    private var crackCount = 0
    private var announcedAlmostBorn = false
    private let crackThresholds: [CGFloat] = [0.35, 0.6, 0.82]
    private let daysPerGrowthMonth: Double = 30
    private let shellGrowthSkipSeconds: TimeInterval = 3_600

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    // MARK: - Requisitos

    private struct Requirement {
        let waitDays: Double
        let zone: DepthZone?

        var waitSeconds: Double { waitDays * 86_400 }
    }

    private func requirement(toReach phase: MermaidPhase) -> Requirement? {
        let months = Double(max(1, phase.rawValue - MermaidPhase.baby.rawValue))
        let waitDays = months * daysPerGrowthMonth
        switch phase {
        case .egg: return nil
        case .baby: return Requirement(waitDays: 0, zone: nil)
        case .child: return Requirement(waitDays: waitDays, zone: nil)
        case .teen: return Requirement(waitDays: waitDays, zone: .blue)
        case .young: return Requirement(waitDays: waitDays, zone: .deep)
        case .adult: return Requirement(waitDays: waitDays, zone: .abyss)
        }
    }

    /// Progresso 0–1 até a próxima fase (menor critério domina).
    func progressToNext() -> CGFloat {
        if ctx.stats.phase == .egg { return ctx.stats.hatchProgress }
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else { return 1 }
        var fractions: [CGFloat] = []
        if req.waitSeconds > 0 {
            fractions.append(CGFloat(min(1, effectivePhaseSeconds() / req.waitSeconds)))
        }
        if let zone = req.zone { fractions.append(ctx.stats.isUnlocked(zone) ? 1 : 0.5 * ctx.stats.adaptation(for: zone.adaptationGate?.zone ?? .shallow) / 100) }
        return fractions.min() ?? 0
    }

    func evolutionNote() -> String {
        if ctx.stats.phase == .egg {
            return "Choco em curso · carinho aquece a concha"
        }
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else {
            return "Ciclo adulto completo · canto estabilizado"
        }

        let remaining = remainingWaitSeconds(for: req)
        if remaining > 0 {
            let waitText = GrowthSystem.formatDuration(remaining)
            return "Cresce em \(waitText)"
        }

        if let zone = req.zone, !ctx.stats.isUnlocked(zone) {
            return "Cresce quando \(zone.displayName.lowercased()) for catalogada"
        }
        if next == .adult && !ctx.stats.isUnlocked(.surface) {
            return "Cresce adulta quando superfície for registrada"
        }
        return "Crescimento pronto · próxima forma: \(next.displayName.lowercased())"
    }

    private func canEvolve() -> Bool {
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else { return false }
        if effectivePhaseSeconds() < req.waitSeconds { return false }
        if let zone = req.zone, !ctx.stats.isUnlocked(zone) { return false }
        if next == .adult && !ctx.stats.isUnlocked(.surface) { return false }
        return true
    }

    private func effectivePhaseSeconds() -> Double {
        ctx.stats.phaseAgeSeconds
    }

    private func remainingWaitSeconds(for req: Requirement) -> Double {
        max(0, req.waitSeconds - effectivePhaseSeconds())
    }

    @discardableResult
    func spendShellsForGrowth() -> Bool {
        guard let remaining = growthAccelerationRemainingWait(showMessages: true) else { return false }
        let shellGrowthCost = GameBalance.growthShellCost(for: ctx.stats.phase)
        guard ctx.stats.pearls >= shellGrowthCost else {
            ctx.say("Acelerar crescimento custa \(GameUI.shellAmountText(shellGrowthCost)) conchas. Faltam \(GameUI.shellAmountText(shellGrowthCost - ctx.stats.pearls)) conchas.")
            return false
        }
        guard ctx.stats.spendPearls(shellGrowthCost, autosave: false) else { return false }
        return applyGrowthAcceleration(remaining: remaining,
                                       memoryText: "Conchas aceleraram",
                                       messageText: "Crescimento acelerado")
    }

    func canReceiveGrowthAccelerationResource() -> Bool {
        growthAccelerationRemainingWait(showMessages: true) != nil
    }

    @discardableResult
    func applyGrowthAccelerationResource() -> Bool {
        guard let remaining = growthAccelerationRemainingWait(showMessages: true) else { return false }
        return applyGrowthAcceleration(remaining: remaining,
                                       memoryText: "Porção acelerou",
                                       messageText: "Porção acelerou o crescimento")
    }

    private func growthAccelerationRemainingWait(showMessages: Bool) -> Double? {
        if ctx.stats.phase == .egg {
            if showMessages {
                ctx.say("O ovo ainda precisa nascer antes de crescer.")
            }
            return nil
        }
        guard let next = ctx.stats.phase.next,
              let req = requirement(toReach: next) else {
            if showMessages {
                ctx.say("Ciclo adulto completo. As conchas ficam para o Refúgio.")
            }
            return nil
        }
        let remaining = remainingWaitSeconds(for: req)
        guard remaining > 0 else {
            if showMessages {
                ctx.say("A espera já abriu. Agora faltam os outros sinais do mar.")
            }
            return nil
        }
        return remaining
    }

    private func applyGrowthAcceleration(remaining: Double,
                                         memoryText: String,
                                         messageText: String) -> Bool {
        let skipped = min(shellGrowthSkipSeconds, remaining)
        ctx.stats.phaseStartedAt = ctx.stats.phaseStartedAt.addingTimeInterval(-skipped)
        ctx.stats.addMemory("\(memoryText) \(GrowthSystem.formatDuration(skipped)) do crescimento")
        ctx.say("\(messageText) em \(GrowthSystem.formatDuration(skipped)).")
        if canEvolve() { evolve() } else { ctx.stats.save(immediately: true) }
        return true
    }

    private static func formatDuration(_ seconds: Double) -> String {
        let totalHours = max(0, Int(ceil(seconds / 3600)))
        if totalHours >= 24 * 30 {
            let days = totalHours / 24
            let months = days / 30
            let remDays = days % 30
            let monthText = months == 1 ? "1 mês" : "\(months) meses"
            return remDays > 0 ? "\(monthText) \(remDays)d" : monthText
        }
        if totalHours >= 24 {
            let days = totalHours / 24
            let hours = totalHours % 24
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
        if totalHours >= 1 { return "\(totalHours)h" }
        let minutes = max(1, Int(ceil(seconds / 60)))
        return "\(minutes)min"
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

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 128, height: 28))
        shadow.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.12, alpha: 0.28)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -88)
        shadow.zPosition = -5
        egg.addChild(shadow)

        let aura = SKShapeNode(circleOfRadius: 118)
        aura.fillColor = UIColor(red: 0.39, green: 0.86, blue: 0.86, alpha: 0.11)
        aura.strokeColor = UIColor(red: 1, green: 0.88, blue: 0.55, alpha: 0.20)
        aura.lineWidth = 2
        aura.glowWidth = 22
        aura.zPosition = -4
        egg.addChild(aura)
        let auraBreath = SKAction.repeatForever(.sequence([
            .group([.scale(to: 1.08, duration: 1.8), .fadeAlpha(to: 0.72, duration: 1.8)]),
            .group([.scale(to: 0.98, duration: 1.8), .fadeAlpha(to: 1.0, duration: 1.8)])
        ]))
        auraBreath.eaeInEaseOut()
        aura.run(auraBreath)

        let orbit = SKNode()
        orbit.zPosition = -2
        egg.addChild(orbit)
        for i in 0..<9 {
            let angle = CGFloat(i) / 9 * .pi * 2
            let radius = CGFloat.random(in: 86...118)
            let mote = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.2...4.2))
            mote.fillColor = UIColor(red: 0.76, green: 0.96, blue: 0.95, alpha: 0.26)
            mote.strokeColor = UIColor.white.withAlphaComponent(0.20)
            mote.glowWidth = 4
            mote.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius * 0.82)
            orbit.addChild(mote)
            let bob = SKAction.repeatForever(.sequence([
                .moveBy(x: 0, y: CGFloat.random(in: 4...10), duration: Double.random(in: 1.2...1.8)),
                .moveBy(x: 0, y: CGFloat.random(in: -10...(-4)), duration: Double.random(in: 1.2...1.8))
            ]))
            bob.eaeInEaseOut()
            mote.run(bob)
        }
        orbit.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 16)))

        let shellSize = CGSize(width: 118, height: 160)
        let shell = SKShapeNode(ellipseOf: shellSize)
        shell.fillTexture = GameUI.gradientTexture(size: shellSize, colors: [
            UIColor(red: 0.96, green: 1.0, blue: 0.95, alpha: 1),
            UIColor(red: 0.61, green: 0.87, blue: 0.90, alpha: 1),
            UIColor(red: 0.33, green: 0.58, blue: 0.78, alpha: 1)
        ])
        shell.fillColor = .white
        shell.strokeColor = UIColor(red: 0.97, green: 1.0, blue: 0.94, alpha: 0.88)
        shell.lineWidth = 2.4
        shell.glowWidth = 12
        shell.zPosition = 0
        egg.addChild(shell)
        eggShellNode = shell

        for _ in 0..<18 {
            let spot = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 4...13),
                                                     height: CGFloat.random(in: 3...9)))
            spot.fillColor = [
                UIColor(red: 1.0, green: 0.91, blue: 0.55, alpha: 0.22),
                UIColor(red: 0.71, green: 0.95, blue: 0.91, alpha: 0.24),
                UIColor(red: 0.28, green: 0.47, blue: 0.72, alpha: 0.18)
            ].randomElement()!
            spot.strokeColor = .clear
            spot.glowWidth = CGFloat.random(in: 1...4)
            spot.position = randomPointInsideEgg(width: shellSize.width, height: shellSize.height)
            spot.zPosition = 1
            spot.zRotation = CGFloat.random(in: -0.6...0.6)
            shell.addChild(spot)
        }

        let innerSize = CGSize(width: 62, height: 94)
        let inner = SKShapeNode(ellipseOf: innerSize)
        inner.fillTexture = GameUI.gradientTexture(size: innerSize, colors: [
            UIColor(red: 0.27, green: 0.47, blue: 0.68, alpha: 0.54),
            UIColor(red: 0.46, green: 0.80, blue: 0.84, alpha: 0.42),
            UIColor(red: 1.0, green: 0.83, blue: 0.48, alpha: 0.32)
        ])
        inner.fillColor = .white
        inner.strokeColor = UIColor.white.withAlphaComponent(0.24)
        inner.lineWidth = 1.2
        inner.glowWidth = 5
        inner.zPosition = 2
        egg.addChild(inner)

        let coreGlow = SKShapeNode(circleOfRadius: 24)
        coreGlow.fillColor = UIColor(red: 1.0, green: 0.78, blue: 0.38, alpha: 0.30)
        coreGlow.strokeColor = UIColor.white.withAlphaComponent(0.28)
        coreGlow.glowWidth = 16
        coreGlow.zPosition = 3
        coreGlow.position = CGPoint(x: 0, y: -8)
        egg.addChild(coreGlow)
        eggCoreGlowNode = coreGlow

        let highlight = SKShapeNode(ellipseOf: CGSize(width: 34, height: 58))
        highlight.fillColor = UIColor.white.withAlphaComponent(0.34)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -24, y: 38)
        highlight.zRotation = -0.30
        highlight.zPosition = 4
        egg.addChild(highlight)

        let lowerShine = SKShapeNode(ellipseOf: CGSize(width: 72, height: 22))
        lowerShine.fillColor = UIColor(red: 0.92, green: 1.0, blue: 0.98, alpha: 0.13)
        lowerShine.strokeColor = .clear
        lowerShine.position = CGPoint(x: 4, y: -42)
        lowerShine.zPosition = 4
        egg.addChild(lowerShine)

        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.06, duration: 1.4),
            .scale(to: 1.0, duration: 1.4)
        ]))
        pulse.eaeInEaseOut()
        shell.run(pulse, withKey: "eggBreath")
        let corePulse = SKAction.repeatForever(.sequence([
            .group([.scale(to: 1.18, duration: 0.9), .fadeAlpha(to: 0.52, duration: 0.9)]),
            .group([.scale(to: 0.92, duration: 1.2), .fadeAlpha(to: 0.28, duration: 1.2)])
        ]))
        corePulse.eaeInEaseOut()
        coreGlow.run(corePulse)

        // anel de progresso do choco ao redor do ovo
        let track = SKShapeNode(circleOfRadius: 104)
        track.strokeColor = UIColor(red: 0.68, green: 0.95, blue: 0.92, alpha: 0.20)
        track.lineWidth = 7
        track.lineCap = .round
        track.glowWidth = 2
        track.fillColor = .clear
        track.zPosition = -1
        egg.addChild(track)
        hatchRingTrack = track

        let ring = SKShapeNode()
        ring.strokeColor = UIColor(red: 1, green: 0.86, blue: 0.46, alpha: 0.96)
        ring.lineWidth = 7
        ring.lineCap = .round
        ring.glowWidth = 8
        ring.fillColor = .clear
        ring.zPosition = 5
        egg.addChild(ring)
        hatchRing = ring

        let crackLayer = SKNode()
        crackLayer.zPosition = 6
        egg.addChild(crackLayer)
        eggCrackLayer = crackLayer

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
        GameAudio.shared.play(.eggTap)

        if egg.action(forKey: "wiggle") == nil {
            let wiggle = SKAction.sequence([
                .group([.rotate(toAngle: 0.14, duration: 0.08), .scale(to: 1.10, duration: 0.08)]),
                .rotate(toAngle: -0.13, duration: 0.10),
                .group([.rotate(toAngle: 0.06, duration: 0.07), .scale(to: 1.03, duration: 0.10)]),
                .group([.rotate(toAngle: 0, duration: 0.12), .scale(to: 1.0, duration: 0.12)])
            ])
            wiggle.eaeInEaseOut()
            egg.run(wiggle, withKey: "wiggle")
        }

        if let world = worldNode {
            spawnTapWarmth(in: world, at: egg.position)
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
            if let egg = eggNode {
                spawnAlmostReadySwirl(at: egg.position)
            }
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
            GameAudio.shared.play(.eggCrack)
            let path = UIBezierPath()
            let startX = CGFloat.random(in: -28...28)
            let startY = CGFloat.random(in: -10...50)
            path.move(to: CGPoint(x: startX, y: startY))
            var point = CGPoint(x: startX, y: startY)
            for _ in 0..<4 {
                point.x += .random(in: -18...18)
                point.y -= .random(in: 9...17)
                path.addLine(to: point)
            }
            let glowCrack = SKShapeNode(path: path.cgPath)
            glowCrack.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.38, alpha: 0.72)
            glowCrack.lineWidth = 4.2
            glowCrack.lineCap = .round
            glowCrack.lineJoin = .round
            glowCrack.glowWidth = 8
            glowCrack.alpha = 0

            let crack = SKShapeNode(path: path.cgPath)
            crack.strokeColor = UIColor(white: 1, alpha: 0.86)
            crack.lineWidth = 1.8
            crack.lineCap = .round
            crack.lineJoin = .round
            crack.alpha = 0
            glowCrack.addChild(crack)
            (eggCrackLayer ?? egg).addChild(glowCrack)
            glowCrack.run(.sequence([
                .group([.fadeIn(withDuration: 0.18), .scale(to: 1.03, duration: 0.18)]),
                .scale(to: 1.0, duration: 0.16)
            ]))
            crack.run(.fadeIn(withDuration: 0.24))
            spawnCrackDust(around: egg.position)
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
        ring.alpha = 0.74 + progress * 0.26
        hatchRingTrack?.alpha = 0.36 + progress * 0.28
        eggCoreGlowNode?.alpha = 0.30 + progress * 0.32
        eggShellNode?.glowWidth = 10 + progress * 10
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        if ctx.stats.phase == .egg {
            // não choca no meio de um desafio aberto
            guard ctx.scene?.isChallengeOpen != true else { return }
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
        let now = Date()
        ctx.stats.phase = .baby
        ctx.stats.birthDate = now
        ctx.stats.phaseStartedAt = now
        ctx.stats.balanceVersion = GameBalance.currentVersion
        ctx.stats.pearls = GameBalance.babyStartingPearls
        ctx.stats.hunger = GameBalance.babyStartingHunger
        ctx.stats.energy = GameBalance.babyStartingEnergy
        ctx.stats.disposition = GameBalance.babyStartingDisposition
        let mermaid = ctx.mermaidEntity.mermaid
        mermaid.setForm(for: .baby)
        eggNode = nil
        hatchRing = nil
        hatchRingTrack = nil
        eggShellNode = nil
        eggCoreGlowNode = nil
        eggCrackLayer = nil
        mermaid.base.position = egg.position
        mermaid.base.setScale(0.05)
        mermaid.base.alpha = 0
        mermaid.base.isHidden = false

        spawnHatchBloom(at: egg.position)
        egg.run(.sequence([
            .group([
                .scale(to: 1.75, duration: 0.85),
                .fadeOut(withDuration: 0.85),
                .rotate(byAngle: 0.22, duration: 0.85)
            ]),
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
        ctx.stats.addMemory("Nasceu! 🌊")
        GameAudio.shared.play(.hatch)
        GameAudio.shared.play(.firstBirthMusic)
        ctx.say("Ela nasceu! 🧜‍♀️🌊")
        ctx.stats.save()
    }

    private func randomPointInsideEgg(width: CGFloat, height: CGFloat) -> CGPoint {
        let halfW = width / 2
        let halfH = height / 2
        for _ in 0..<12 {
            let x = CGFloat.random(in: -halfW * 0.74...halfW * 0.74)
            let y = CGFloat.random(in: -halfH * 0.76...halfH * 0.76)
            let normalized = (x * x) / (halfW * halfW) + (y * y) / (halfH * halfH)
            if normalized <= 0.62 { return CGPoint(x: x, y: y) }
        }
        return .zero
    }

    private func spawnTapWarmth(in world: SKNode, at position: CGPoint) {
        let wave = SKShapeNode(circleOfRadius: 46)
        wave.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.45, alpha: 0.58)
        wave.fillColor = .clear
        wave.lineWidth = 2.2
        wave.glowWidth = 10
        wave.position = position
        wave.zPosition = 11
        world.addChild(wave)
        wave.run(.sequence([
            .group([.scale(to: 2.0, duration: 0.55), .fadeOut(withDuration: 0.55)]),
            .removeFromParent()
        ]))

        for _ in 0..<7 {
            let radius = CGFloat.random(in: 2.5...6.2)
            let spark = SKShapeNode(circleOfRadius: radius)
            spark.fillColor = [
                UIColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 0.88),
                UIColor(red: 0.72, green: 0.98, blue: 0.92, alpha: 0.76),
                UIColor(white: 1, alpha: 0.72)
            ].randomElement()!
            spark.strokeColor = UIColor.white.withAlphaComponent(0.22)
            spark.glowWidth = radius * 1.8
            spark.position = position + CGPoint(x: .random(in: -46...46), y: .random(in: 26...74))
            spark.zPosition = 12
            world.addChild(spark)
            let rise = SKAction.sequence([
                .group([
                    .moveBy(x: .random(in: -24...24), y: .random(in: 52...94), duration: Double.random(in: 0.72...1.05)),
                    .scale(to: CGFloat.random(in: 0.35...0.65), duration: Double.random(in: 0.72...1.05)),
                    .fadeOut(withDuration: Double.random(in: 0.72...1.05))
                ]),
                .removeFromParent()
            ])
            rise.eaeInEaseOut()
            spark.run(rise)
        }
    }

    private func spawnCrackDust(around position: CGPoint) {
        guard let world = worldNode else { return }
        for _ in 0..<8 {
            let chip = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 3...7),
                                                     height: CGFloat.random(in: 2...5)))
            chip.fillColor = UIColor(red: 0.90, green: 0.99, blue: 0.96, alpha: 0.58)
            chip.strokeColor = UIColor.white.withAlphaComponent(0.24)
            chip.glowWidth = 2
            chip.position = position + CGPoint(x: .random(in: -38...38), y: .random(in: -24...54))
            chip.zPosition = 13
            world.addChild(chip)
            chip.run(.sequence([
                .group([
                    .moveBy(x: .random(in: -28...28), y: .random(in: 12...44), duration: 0.52),
                    .rotate(byAngle: CGFloat.random(in: -1.2...1.2), duration: 0.52),
                    .fadeOut(withDuration: 0.52)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnAlmostReadySwirl(at position: CGPoint) {
        guard let world = worldNode else { return }

        let ring = SKShapeNode(circleOfRadius: 72)
        ring.strokeColor = UIColor(red: 1.0, green: 0.86, blue: 0.46, alpha: 0.72)
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.lineCap = .round
        ring.glowWidth = 14
        ring.position = position
        ring.zPosition = 18
        world.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.15, duration: 1.05),
                .rotate(byAngle: .pi * 1.4, duration: 1.05),
                .fadeOut(withDuration: 1.05)
            ]),
            .removeFromParent()
        ]))

        for i in 0..<14 {
            let delay = Double(i) * 0.035
            let angle = CGFloat(i) / 14 * .pi * 2
            let mote = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.4...5.0))
            if i.isMultiple(of: 2) {
                mote.fillColor = UIColor(red: 1.0, green: 0.90, blue: 0.56, alpha: 0.82)
            } else {
                mote.fillColor = UIColor(red: 0.68, green: 0.98, blue: 0.94, alpha: 0.74)
            }
            mote.strokeColor = UIColor.white.withAlphaComponent(0.18)
            mote.glowWidth = 6
            mote.position = position + CGPoint(x: cos(angle) * 42, y: sin(angle) * 36)
            mote.zPosition = 19
            world.addChild(mote)
            mote.run(.sequence([
                .wait(forDuration: delay),
                .group([
                    .moveBy(x: cos(angle + 0.5) * 62,
                            y: sin(angle + 0.5) * 54,
                            duration: 0.82),
                    .scale(to: 0.25, duration: 0.82),
                    .fadeOut(withDuration: 0.82)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnHatchBloom(at position: CGPoint) {
        guard let world = worldNode else { return }

        let bloom = SKShapeNode(circleOfRadius: 34)
        bloom.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.52, alpha: 0.42)
        bloom.strokeColor = UIColor.white.withAlphaComponent(0.50)
        bloom.lineWidth = 2
        bloom.glowWidth = 28
        bloom.position = position
        bloom.zPosition = 19
        world.addChild(bloom)
        bloom.run(.sequence([
            .group([.scale(to: 5.2, duration: 1.1), .fadeOut(withDuration: 1.1)]),
            .removeFromParent()
        ]))

        for i in 0..<22 {
            let angle = CGFloat(i) / 22 * .pi * 2 + CGFloat.random(in: -0.12...0.12)
            let distance = CGFloat.random(in: 86...168)
            let shard = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 4...10),
                                                      height: CGFloat.random(in: 2...6)))
            shard.fillColor = [
                UIColor(red: 1.0, green: 0.93, blue: 0.62, alpha: 0.82),
                UIColor(red: 0.68, green: 0.98, blue: 0.94, alpha: 0.72),
                UIColor.white.withAlphaComponent(0.80)
            ].randomElement()!
            shard.strokeColor = .clear
            shard.glowWidth = 5
            shard.position = position
            shard.zRotation = angle
            shard.zPosition = 21
            world.addChild(shard)
            shard.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance,
                            duration: Double.random(in: 0.82...1.28)),
                    .rotate(byAngle: CGFloat.random(in: 1.4...3.6), duration: Double.random(in: 0.82...1.28)),
                    .fadeOut(withDuration: Double.random(in: 0.82...1.28))
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func evolve() {
        guard let next = ctx.stats.phase.next else { return }
        ctx.stats.phase = next
        ctx.stats.phaseStartedAt = Date()
        let mermaid = ctx.mermaidEntity.mermaid
        mermaid.setForm(for: next)
        let gained = ctx.stats.awardPearls(20)
        ctx.stats.addMemory("Evoluiu para \(next.displayName)")
        GameAudio.shared.play(.evolution)
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

        ctx.say("✨ Ela evoluiu: agora é \(next.displayName)! 🐚+\(GameUI.shellAmountText(gained))")
        ctx.stats.save(immediately: true)
    }
}
