//
//  AutonomySystem.swift
//  Ester
//
//  Cérebro da sereia: escolhe intenções por pesos a partir dos atributos,
//  executa a locomoção orgânica e processa comandos do jogador (que
//  influenciam, mas não controlam).
//

import Foundation
import SpriteKit

final class AutonomySystem {
    unowned let ctx: GameContext

    private(set) var intent: MermaidIntent = .idle
    private var target: CGPoint?
    private var velocity = CGVector(dx: 0, dy: 0)
    private var decisionCooldown: CGFloat = 1.5
    private var intentTime: CGFloat = 0
    private var commandBias: (intent: MermaidIntent, until: Date)?
    private var commandCooldownUntil: [PlayerCommand: Date] = [:]
    private let refusalCooldownSeconds: TimeInterval = 10
    private var lastAnimation: MovementType = .idle
    private var lastFacing: Mermaid.Direction = .none
    private var eatCooldown: CGFloat = 0
    private var interactCooldown: CGFloat = 0
    private var wobblePhase: CGFloat = .random(in: 0...10)

    /// Pausa total (fase de ovo, puzzle aberto).
    var paused = false
    /// Empuxo de eventos como correnteza.
    var drift = CGVector(dx: 0, dy: 0)

    private var mermaid: Mermaid { ctx.mermaidEntity.mermaid }
    private var stats: MermaidStats { ctx.stats }
    private var position: CGPoint { mermaid.base.position }
    private var currentZone: DepthZone { DepthZone.zone(atY: position.y) }
    var commandCooldownsRemaining: [PlayerCommand: TimeInterval] {
        let now = Date()
        return commandCooldownUntil.reduce(into: [:]) { result, item in
            let remaining = item.value.timeIntervalSince(now)
            if remaining > 0 { result[item.key] = remaining }
        }
    }

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    // MARK: - Loop principal

    func update(dt: CGFloat) {
        guard !paused else { return }
        intentTime += dt
        decisionCooldown -= dt
        eatCooldown -= dt
        interactCooldown -= dt
        wobblePhase += dt

        tickStats(dt: dt)
        autoEat()
        if decisionCooldown <= 0 { decide() }
        progressIntent(dt: dt)
        steer(dt: dt)
        updateAnimation()
        updateEmotion(dt: dt)
    }

    private func tickStats(dt: CGFloat) {
        var energyRate: CGFloat
        switch intent {
        case .idle, .observing: energyRate = -0.01
        case .wandering: energyRate = -0.06
        case .seekingFood, .seekingChallenge: energyRate = -0.09
        case .eating: energyRate = 0
        case .goingDeeper, .goingUp: energyRate = -0.12
        case .traveling: energyRate = -0.05
        case .returningHome, .goingToObjective: energyRate = -0.08
        case .interactingWithFish, .enteringRefuge: energyRate = -0.05
        case .avoidingDanger: energyRate = -0.25
        case .inChallenge: energyRate = -0.02
        case .resting:
            energyRate = 1.0
        }
        if intent != .resting {
            energyRate -= ctx.depth.energyPenalty(atY: position.y)
        }
        stats.tick(dt: dt, energyDelta: energyRate)
    }

    // MARK: - Decisão por pesos

    private func decide() {
        // a caminho do portal do Refúgio: não muda de ideia no meio
        if intent == .enteringRefuge, portalPoint != nil {
            decisionCooldown = 1
            return
        }
        decisionCooldown = .random(in: 4...8)
        var scores: [MermaidIntent: CGFloat] = [:]

        scores[.idle] = 8 + .random(in: 0...6)
        scores[.wandering] = 16 + stats.curiosity * 0.25 + .random(in: 0...10)
        scores[.observing] = 4 + stats.curiosity * 0.1

        if stats.hunger > 30 {
            var foodScore = stats.hunger * 1.1
            if ctx.food.nearestFood(to: position, maxDistance: 900) != nil { foodScore += 20 }
            scores[.seekingFood] = foodScore
        }
        if stats.energy < 35 {
            scores[.resting] = (60 - stats.energy) * 1.6
        }
        if stats.energy < 18 {
            scores[.resting, default: 0] += (40 - stats.energy) * 2.2
        }
        if stats.scaredTimer > 0 {
            scores[.resting, default: 0] += 50
            scores[.observing, default: 0] += 25
        }
        if interactCooldown <= 0,
           ctx.fish.nearestFish(to: position, maxDistance: 700) != nil {
            scores[.interactingWithFish] = 10 + stats.disposition * 0.15 + stats.curiosity * 0.1
        }
        if let deeperZone = currentZone.deeper,
           ctx.depth.isUnlocked(deeperZone),
           stats.energy > 40, stats.hunger < 70 {
            scores[.goingDeeper] = stats.curiosity * 0.2 + stats.courage * 0.15
        }
        if currentZone != .shallow && currentZone != .surface {
            scores[.goingUp] = 6 + (stats.energy < 50 ? 10 : 0)
        }
        // peixes com desafio por perto despertam interesse próprio
        if ctx.challenges.nearestGiver(to: position, maxDistance: 1400) != nil,
           stats.energy > 25 {
            scores[.seekingChallenge] = 18 + stats.curiosity * 0.2
        }
        // viagem em andamento: prioridade alta, mas fome/cansaço interrompem
        if ctx.travel.destination != nil && stats.energy > 12 && stats.hunger < 88 {
            scores[.traveling] = 70
        }

        // Comando do jogador pesa muito, mas não é absoluto
        if let bias = commandBias {
            if Date() < bias.until {
                scores[bias.intent, default: 0] += 120
            } else {
                commandBias = nil
            }
        }

        // Fome alta tira vontade de coisas difíceis
        if stats.hunger > 70 {
            scores[.goingDeeper] = (scores[.goingDeeper] ?? 0) - 30
            scores[.seekingChallenge] = (scores[.seekingChallenge] ?? 0) - 20
        }

        if let best = scores.max(by: { $0.value < $1.value })?.key {
            setIntent(best)
        }
    }

    private func setIntent(_ newIntent: MermaidIntent) {
        intent = newIntent
        intentTime = 0
        switch newIntent {
        case .idle, .observing, .resting, .eating, .inChallenge, .avoidingDanger, .returningHome:
            if newIntent != .avoidingDanger { target = nil }
        case .wandering:
            target = randomWanderPoint()
        case .seekingFood:
            if let food = ctx.food.nearestFood(to: position, maxDistance: 1800) {
                target = food.position
            } else {
                ctx.food.requestSpawn(near: position)
                target = randomWanderPoint()
            }
        case .seekingChallenge:
            target = ctx.challenges.ensureGiver(near: position)?.position
        case .goingToObjective:
            target = ctx.events.currentObjective?.position()
        case .enteringRefuge:
            target = portalPoint
        case .goingDeeper:
            // camada bloqueada: tenta mesmo assim e esbarra no limite permitido
            let y: CGFloat
            if let zone = currentZone.deeper, ctx.depth.isUnlocked(zone) {
                y = zone.midY + .random(in: -800...800)
            } else {
                y = position.y - 1600
            }
            target = CGPoint(x: position.x + .random(in: -800...800), y: y)
        case .goingUp:
            let y: CGFloat
            if let zone = currentZone.shallower, ctx.depth.isUnlocked(zone) {
                y = zone == .surface
                    ? CGFloat.random(in: 40...200)
                    : zone.midY + .random(in: -800...800)
            } else {
                y = position.y + 1600
            }
            target = CGPoint(x: position.x + .random(in: -800...800), y: y)
        case .traveling:
            target = ctx.travel.targetPoint
        case .interactingWithFish:
            target = ctx.fish.nearestFish(to: position, maxDistance: 1200)?.position
        }
    }

    private func randomWanderPoint() -> CGPoint {
        let range = ctx.depth.allowedYRange()
        let x = (position.x + .random(in: -1100...1100)).clamped(to: World.minX...World.maxX)
        let y = (position.y + .random(in: -700...700)).clamped(to: range)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Progresso da intenção atual

    private func progressIntent(dt: CGFloat) {
        switch intent {
        case .seekingFood:
            if let food = ctx.food.nearestFood(to: position, maxDistance: 1800) {
                target = food.position
                if position.distance(to: food.position) < 130 { eat(food) }
            } else if intentTime > 6 {
                ctx.food.requestSpawn(near: position)
                intentTime = 0
            }
        case .eating:
            if intentTime > 1.6 {
                showEmotion(.satisfied, duration: 1.6)
                setIntent(.idle)
                decisionCooldown = min(decisionCooldown, 1.5)
            }
        case .seekingChallenge:
            if let giver = ctx.challenges.nearestGiver(to: position, maxDistance: 2600) {
                target = giver.position
                if position.distance(to: giver.position) < 150 {
                    enterChallenge()
                    ctx.scene?.openChallenge(giver: giver)
                }
            } else if intentTime > 4 {
                target = ctx.challenges.ensureGiver(near: position)?.position
                intentTime = 0
            }
        case .goingToObjective:
            if let objective = ctx.events.currentObjective,
               let point = objective.position() {
                target = point
                if position.distance(to: point) < 140 {
                    ctx.events.completeObjective()
                    setIntent(.observing)
                    decisionCooldown = 3
                }
            } else {
                // objetivo sumiu no caminho
                setIntent(.idle)
                decisionCooldown = min(decisionCooldown, 1.5)
            }
        case .enteringRefuge:
            if let portal = portalPoint {
                target = portal
                if position.distance(to: portal) < 90 {
                    portalPoint = nil
                    target = nil
                    velocity = CGVector(dx: 0, dy: 0)
                    ctx.scene?.mermaidReachedRefugePortal()
                }
            } else {
                setIntent(.idle)
            }
        case .interactingWithFish:
            if let fish = ctx.fish.nearestFish(to: position, maxDistance: 1200) {
                target = fish.position
                if position.distance(to: fish.position) < 140 && interactCooldown <= 0 {
                    interactCooldown = 8
                    ctx.fish.interact(fish)
                    stats.boostMood(6)
                    stats.gainXP(3)
                    if Int.random(in: 0..<12) == 0 {
                        let gained = stats.awardPearls(1)
                        ctx.say("O peixinho deixou conchas! 🐚+\(gained)")
                    }
                    setIntent(.observing)
                    decisionCooldown = 4
                }
            } else {
                setIntent(.wandering)
            }
        case .traveling:
            if let point = ctx.travel.targetPoint {
                target = point
            } else {
                setIntent(.idle)
                decisionCooldown = min(decisionCooldown, 1)
            }
        case .returningHome:
            // sem abrigo físico no mundo: ela se acomoda onde está
            setIntent(.resting)
        case .resting:
            if stats.energy > 90 && stats.scaredTimer <= 0 {
                decisionCooldown = min(decisionCooldown, 1)
            }
        case .wandering, .goingDeeper, .goingUp:
            if let t = target, position.distance(to: t) < 90 {
                setIntent(.idle)
                decisionCooldown = min(decisionCooldown, .random(in: 1...2.5))
            }
        case .avoidingDanger:
            if intentTime > 3.5 {
                setIntent(stats.scaredTimer > 0 ? .resting : .idle)
            }
        case .observing:
            if intentTime > 5 {
                decisionCooldown = min(decisionCooldown, 0.5)
            }
        default:
            break
        }
    }

    // MARK: - Comida

    private func autoEat() {
        guard intent != .inChallenge, intent != .enteringRefuge,
              stats.hunger > 25, eatCooldown <= 0 else { return }
        if let food = ctx.food.nearestFood(to: position, maxDistance: 120) {
            eat(food)
        }
    }

    private func eat(_ food: FoodNode) {
        guard eatCooldown <= 0 else { return }
        eatCooldown = 1.2
        ctx.food.consume(food)
        intent = .eating
        target = nil
        intentTime = 0
        showEmotion(.eating, duration: 1.2)
    }

    // MARK: - Medo / eventos

    func scare(from point: CGPoint) {
        guard !paused, intent != .inChallenge, intent != .enteringRefuge else { return }
        stats.scare(duration: 7)
        let dx = position.x - point.x
        let dy = position.y - point.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let range = ctx.depth.allowedYRange()
        target = CGPoint(x: (position.x + dx / length * 500).clamped(to: World.minX...World.maxX),
                         y: (position.y + dy / length * 500).clamped(to: range))
        intent = .avoidingDanger
        intentTime = 0
        decisionCooldown = 5
    }

    // MARK: - Desafios

    func enterChallenge() {
        intent = .inChallenge
        target = nil
        velocity = CGVector(dx: 0, dy: 0)
        if lastAnimation != .idle {
            lastAnimation = .idle
            lastFacing = .none
            mermaid.setAnimationMode(.idle)
        }
    }

    func finishChallenge() {
        intent = .idle
        decisionCooldown = 2.5
        showEmotion(.satisfied, duration: 1.8)
    }

    // MARK: - Portal do Refúgio

    private var portalPoint: CGPoint?

    /// A sereia nada até o portal; ao chegar, avisa a cena.
    func goToRefugePortal(at point: CGPoint) {
        portalPoint = point
        commandBias = nil
        setIntent(.enteringRefuge)
        decisionCooldown = 2
        showEmotion(.surprised, duration: 1.2)
    }

    func cancelRefugeEntry() {
        guard portalPoint != nil || intent == .enteringRefuge else { return }
        portalPoint = nil
        setIntent(.idle)
        decisionCooldown = 1.5
    }

    // MARK: - Comandos do jogador

    func give(_ command: PlayerCommand) {
        clearExpiredCommandCooldowns()
        if let until = commandCooldownUntil[command], until > Date() {
            return
        }

        guard stats.phase != .egg else {
            // Durante o ovo só o Desafio: Trama funciona — e abre na hora.
            if command == .challenge {
                ctx.scene?.openHatchingChallenge()
            } else {
                refuse(command, saying: "A pequena sereia ainda está dormindo no ovo... jogue o Desafio: Trama para reunir energia de nascimento 🌀")
            }
            return
        }
        guard intent != .inChallenge else { return }
        guard intent != .enteringRefuge else { return }

        let desired: MermaidIntent
        switch command {
        case .explore:
            desired = .wandering
        case .seekFood:
            // teimosia de criança: quanto mais nova, mais recusa comer
            if CGFloat.random(in: 0...1) < eatRefusalChance() {
                stats.trust = max(0, stats.trust - 0.2)
                let excuses = [
                    "Não quero comer agora! 😤",
                    "Ela fechou a boquinha e virou o rosto...",
                    "Ela fez bico: \"depois...\"",
                    "Hmpf! Ela fingiu não estar com fome."
                ]
                refuse(command, saying: excuses.randomElement()!)
                return
            }
            desired = .seekingFood
        case .rest:
            desired = .resting
        case .travel:
            // o menu de regiões é interface, não depende da disposição dela
            ctx.scene?.openRegionMenu()
            return
        case .refuge:
            // portal mágico: ela sempre vai, mas agora dá para VER o caminho
            ctx.scene?.beginRefugeEntry()
            return
        case .challenge:
            if stats.hunger >= 92 {
                refuse(command, saying: "Faminta demais para um desafio... me ajuda a comer algo?")
                return
            }
            if stats.energy < 8 {
                refuse(command, saying: "Preciso descansar antes de um desafio... 😴")
                return
            }
            guard ctx.challenges.ensureGiver(near: position) != nil else {
                refuse(command, saying: "Nenhum peixe com desafio por perto agora...")
                return
            }
            desired = .seekingChallenge
        case .objective:
            guard let objective = ctx.events.currentObjective,
                  objective.position() != nil else {
                refuse(command, saying: "Nada acontecendo por perto agora... 👀")
                return
            }
            desired = .goingToObjective
        case .goDown:
            guard let next = currentZone.deeper else {
                refuse(command, saying: "Já estamos no fundo do abismo.")
                return
            }
            guard stats.energy > 15 else {
                refuseTired(command)
                return
            }
            if stats.hunger > 80 {
                stats.trust = max(0, stats.trust - 0.6)
                refuse(command, saying: "Com essa fome eu não desço... 🍽")
                return
            }
            // camada fechada: explica o motivo, mas desce até onde dá
            if !ctx.depth.isUnlocked(next) {
                ctx.say(ctx.depth.descentHint(for: next))
            }
            desired = .goingDeeper
        case .goUp:
            if currentZone == .surface {
                refuse(command, saying: "Já estou na superfície!")
                return
            }
            guard stats.energy > 10 else {
                refuseTired(command)
                return
            }
            if let next = currentZone.shallower, !ctx.depth.isUnlocked(next) {
                ctx.say(ctx.depth.ascentHint())
            }
            desired = .goingUp
        }

        // Disposição: cresce com vínculo e bem-estar, cai com fome e medo.
        var chance = 0.34
            + stats.trust * 0.0024
            + stats.disposition * 0.001
            - stats.hunger * 0.0014
            + stats.dispositionAcceptanceBonus
        if stats.scaredTimer > 0 { chance -= 0.2 }
        chance = chance.clamped(to: 0.18...0.90)

        if CGFloat.random(in: 0...1) <= chance {
            stats.trust = min(100, stats.trust + 0.4)
            commandBias = (desired, Date().addingTimeInterval(30))
            setIntent(desired)
            decisionCooldown = .random(in: 6...10)
            if desired == .seekingChallenge {
                ctx.say("Ela foi atrás de um peixe com desafio... 🏆")
            } else if desired == .goingToObjective {
                ctx.say("Ela foi investigar... 👀")
            }
        } else {
            stats.trust = max(0, stats.trust - 0.2)
            let excuses = [
                "Hmm... agora não.",
                "Ela fingiu que não ouviu...",
                "Ela balançou a cabeça, sem vontade."
            ]
            refuse(command, saying: excuses.randomElement()!)
        }
    }

    private func refuse(_ command: PlayerCommand, saying message: String) {
        commandCooldownUntil[command] = Date().addingTimeInterval(refusalCooldownSeconds)
        showEmotion(.stubborn, duration: 1.8)
        ctx.say(message)
    }

    private func clearExpiredCommandCooldowns() {
        let now = Date()
        commandCooldownUntil = commandCooldownUntil.filter { $0.value > now }
    }

    /// Quanto mais nova, mais teimosa para comer quando mandam.
    private func eatRefusalChance() -> CGFloat {
        let reduction = CGFloat(stats.dispositionUpgradeLevel) * 0.0028
        switch stats.phase {
        case .egg: return 0
        case .baby: return (0.45 - reduction).clamped(to: 0.17...0.45)
        case .child: return (0.34 - reduction).clamped(to: 0.12...0.34)
        case .teen: return (0.23 - reduction).clamped(to: 0.08...0.23)
        case .young: return (0.14 - reduction).clamped(to: 0.05...0.14)
        case .adult: return (0.08 - reduction).clamped(to: 0.03...0.08)
        }
    }

    private func refuseTired(_ command: PlayerCommand) {
        stats.trust = max(0, stats.trust - 1)
        let excuses = [
            "Estou sem energia... preciso descansar. 😮‍💨",
            "Cansada demais para isso agora...",
            "Ela olhou para você, exausta."
        ]
        refuse(command, saying: excuses.randomElement()!)
    }

    // MARK: - Locomoção orgânica

    private func speed(for intent: MermaidIntent) -> CGFloat {
        let baseSpeed: CGFloat
        switch intent {
        case .idle, .observing, .resting, .eating, .inChallenge: baseSpeed = 0
        case .wandering: baseSpeed = 130
        case .seekingFood, .seekingChallenge: baseSpeed = 200
        case .goingToObjective: baseSpeed = 210
        case .enteringRefuge: baseSpeed = 180
        case .goingDeeper, .goingUp: baseSpeed = 170
        case .traveling: baseSpeed = 260
        case .returningHome: baseSpeed = 220
        case .interactingWithFish: baseSpeed = 150
        case .avoidingDanger: baseSpeed = 380
        }
        return baseSpeed * stats.speedMultiplier
    }

    private func steer(dt: CGFloat) {
        let maxSpeed = speed(for: intent)
        if let t = target, maxSpeed > 0 {
            let dx = t.x - position.x
            let dy = t.y - position.y
            let dist = max(1, sqrt(dx * dx + dy * dy))
            let desired = CGVector(dx: dx / dist * maxSpeed, dy: dy / dist * maxSpeed)
            let blend = min(1, dt * 1.8)
            velocity.dx += (desired.dx - velocity.dx) * blend
            velocity.dy += (desired.dy - velocity.dy) * blend
        } else {
            let damp = max(0, 1 - dt * 2.2)
            velocity.dx *= damp
            velocity.dy *= damp
        }

        var p = position
        p.x += (velocity.dx + drift.dx) * dt
        p.y += (velocity.dy + drift.dy) * dt
        // ondulação sutil para o nado parecer vivo
        p.x += cos(wobblePhase * 0.9) * 10 * dt
        p.y += sin(wobblePhase * 1.6) * 8 * dt

        let yRange = ctx.depth.allowedYRange()
        p.x = p.x.clamped(to: World.minX...World.maxX)
        p.y = p.y.clamped(to: yRange)
        mermaid.base.position = p
    }

    private func updateAnimation() {
        let effectiveVelocity = CGVector(dx: velocity.dx + drift.dx, dy: velocity.dy + drift.dy)
        let currentSpeed = effectiveVelocity.length
        let mode: MovementType = currentSpeed < 30 ? .idle : (currentSpeed < 290 ? .swing : .fast)
        if mode != lastAnimation {
            lastAnimation = mode
            mermaid.setAnimationMode(mode)
            if mode == .idle { lastFacing = .none }
        }
        guard mode != .idle else { return }

        let facing: Mermaid.Direction
        if abs(effectiveVelocity.dx) > abs(effectiveVelocity.dy) {
            facing = effectiveVelocity.dx > 0 ? .right : .left
        } else {
            facing = effectiveVelocity.dy > 0 ? .up : .down
        }
        if facing != lastFacing {
            lastFacing = facing
            mermaid.setVisualDirection(facing)
        }
    }

    private func updateEmotion(dt: CGFloat) {
        ctx.mermaidEntity
            .component(ofType: MermaidEmotionComponent.self)?
            .update(dt: dt, intent: intent, stats: stats)
    }

    private func showEmotion(_ emotion: MermaidEmotion, duration: CGFloat) {
        ctx.mermaidEntity
            .component(ofType: MermaidEmotionComponent.self)?
            .show(emotion, duration: duration)
    }
}
