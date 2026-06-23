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

enum BondRecoveryHUDState {
    case hidden
    case available
    case waiting(TimeInterval)
    case ready(Int)
}

final class AutonomySystem {
    unowned let ctx: GameContext

    private(set) var intent: MermaidIntent = .idle
    private var target: CGPoint?
    private var velocity = CGVector(dx: 0, dy: 0)
    private var decisionCooldown: CGFloat = 1.5
    private var intentTime: CGFloat = 0
    private var commandBias: (intent: MermaidIntent, until: Date)?
    private var commandCooldownUntil: [PlayerCommand: Date] = [:]
    private var touchRequestCooldownUntil: Date?
    private var touchPointTarget: CGPoint?
    private var touchDirection: CGVector?
    private var touchDirectionUntil: Date?
    private weak var touchFoodTarget: FoodNode?
    private weak var touchFishTarget: FishNode?
    private weak var touchChallengeTarget: FishNode?
    private weak var guidingFishTarget: FishNode?
    private var guidingPOI: WorldPOI?
    private var fishGuidanceUntil: Date?
    private weak var playFishTarget: FishNode?
    private var fishPlayMeetPoint: CGPoint?
    private var fishPlayAnchor: CGPoint?
    private var fishPlayUntil: Date?
    private var fishPlayPhase: CGFloat = 0
    private var passiveBondQuietTimer: CGFloat = 0
    private var bondRecoveryState: BondRecoveryState = .idle
    private var lastAnimation: MovementType = .idle
    private var lastFacing: Mermaid.Direction = .none
    private var eatCooldown: CGFloat = 0
    private var interactCooldown: CGFloat = 0
    private var boundaryFeedbackCooldown: CGFloat = 0
    private var activeBoundaryContact: DepthBoundaryEdge?
    private var activeHorizontalBoundaryContact: HorizontalBoundarySide?
    private var wobblePhase: CGFloat = .random(in: 0...10)

    private enum TrustBalance {
        static let acceptedCommand: CGFloat = 0.4
        static let inconvenientCareAsk: CGFloat = 1.2
        static let generalRefusal: CGFloat = 1.6
        static let unmetNeedRefusal: CGFloat = 2.6
        static let forcedRiskWhileHungry: CGFloat = 3.0
        static let exhaustedRefusal: CGFloat = 4.0
    }

    private enum BondRecoveryBalance {
        static let lowTrustThreshold: CGFloat = 10
        static let spaceDuration: TimeInterval = 10
        static let spaceTrustGain: CGFloat = 6
        static let acceptedRequestTrustGain: CGFloat = 4
        static let guaranteedRequestCount = 5
    }

    private enum PassiveBondBalance {
        static let quietDelay: CGFloat = 40
        static let gainPerSecond: CGFloat = 0.007
        static let strainedCareMultiplier: CGFloat = 0.35
    }

    private enum FishPlayBalance {
        static let decisionRange: CGFloat = 1_600
        static let chaseRange: CGFloat = 1_800
        static let cooldown: CGFloat = 5
        static let guidanceDuration: TimeInterval = 60
        static let playDuration: TimeInterval = 30
        static let gatherDuration: TimeInterval = 12
        static let meetDistance: CGFloat = 120
        static let guideChanceOnTouch: CGFloat = 0.58
        static let guidanceFollowDistance: CGFloat = 190
        static let gatherSideOffset: CGFloat = 130
        static let mermaidPlayRadiusX: CGFloat = 170
        static let mermaidPlayRadiusY: CGFloat = 72
        static let mermaidPlaySpeed: CGFloat = 0.68
    }

    private enum FishCompanionAction {
        case guide(WorldPOI)
        case play

        var intent: MermaidIntent {
            switch self {
            case .guide(_): return .followingFish
            case .play: return .interactingWithFish
            }
        }
    }

    private enum HorizontalBoundarySide {
        case left
        case right
    }

    private enum HorizontalBoundaryBalance {
        static let contactPadding: CGFloat = 24
        static let releasePadding: CGFloat = 900
        static let retreatPaddingRange: ClosedRange<CGFloat> = 1_400...2_300
        static let wanderPadding: CGFloat = 700
        static let verticalJitterRange: ClosedRange<CGFloat> = -260...260
    }

    private enum TouchDirectionBalance {
        static let duration: TimeInterval = 9
        static let targetDistance: CGFloat = 2_200
        static let minimumGestureDistance: CGFloat = 48
    }

    private enum BondRecoveryState {
        case idle
        case waiting(until: Date)
        case ready(remainingRequests: Int)
    }

    /// Pausa total (fase de ovo, puzzle aberto).
    var paused = false
    /// Empuxo de eventos como correnteza.
    var drift = CGVector(dx: 0, dy: 0)
    /// Empuxo contínuo de zonas ambientais, como uma corrente quente local.
    var environmentDrift = CGVector(dx: 0, dy: 0)

    private var mermaid: Mermaid { ctx.mermaidEntity.mermaid }
    private var stats: MermaidStats { ctx.stats }
    private var position: CGPoint { mermaid.base.position }
    private var currentZone: DepthZone { DepthZone.zone(atY: position.y) }
    private var horizontalRange: ClosedRange<CGFloat> {
        ctx.activeRegion?.playableXRange ?? (World.minX...World.maxX)
    }
    var commandCooldownsRemaining: [PlayerCommand: TimeInterval] {
        let now = Date()
        return commandCooldownUntil.reduce(into: [:]) { result, item in
            let remaining = item.value.timeIntervalSince(now)
            if remaining > 0 { result[item.key] = remaining }
        }
    }
    var touchRequestCooldownRemaining: TimeInterval {
        guard let until = touchRequestCooldownUntil else { return 0 }
        return max(0, until.timeIntervalSince(Date()))
    }
    var activeDirectionsCommand: PlayerCommand? {
        guard stats.phase != .egg else { return nil }
        switch intent {
        case .goingUp:
            return .goUp
        case .goingDeeper:
            return .goDown
        case .resting:
            return .rest
        case .wandering:
            guard let direction = touchDirection,
                  let until = touchDirectionUntil,
                  Date() < until,
                  abs(direction.dx) >= abs(direction.dy),
                  abs(direction.dx) > 0.1 else { return nil }
            return direction.dx < 0 ? .goLeft : .goRight
        default:
            return nil
        }
    }
    var bondRecoveryHUDState: BondRecoveryHUDState {
        guard stats.phase != .egg else { return .hidden }
        switch bondRecoveryState {
        case .idle:
            return stats.trust < BondRecoveryBalance.lowTrustThreshold ? .available : .hidden
        case .waiting(let until):
            return .waiting(max(0, until.timeIntervalSince(Date())))
        case .ready(let remainingRequests):
            return .ready(remainingRequests)
        }
    }

    private var isBondRecoveryRequestReady: Bool {
        if case .ready(let remainingRequests) = bondRecoveryState {
            return remainingRequests > 0
        }
        return false
    }

    private var fishCompanionSessionIsActive: Bool {
        if intent == .followingFish,
           let until = fishGuidanceUntil,
           Date() < until,
           guidingFishTarget?.parent != nil {
            return true
        }
        if intent == .interactingWithFish,
           playFishTarget?.parent != nil {
            return true
        }
        return false
    }

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    // MARK: - Loop principal

    func update(dt: CGFloat) {
        updateBondRecovery()
        guard !paused else { return }
        intentTime += dt
        decisionCooldown -= dt
        eatCooldown -= dt
        interactCooldown -= dt
        boundaryFeedbackCooldown -= dt
        wobblePhase += dt

        tickStats(dt: dt)
        updatePassiveBond(dt: dt)
        pursueCurrentObjectiveIfNeeded()
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
        case .returningHome, .goingToObjective, .followingFish: energyRate = -0.08
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

    private func updatePassiveBond(dt: CGFloat) {
        guard stats.phase != .egg, stats.trust < 100 else { return }
        guard commandBias == nil,
              touchPointTarget == nil,
              touchDirection == nil,
              touchFoodTarget == nil,
              touchFishTarget == nil,
              touchChallengeTarget == nil,
              intent != .inChallenge,
              intent != .enteringRefuge else {
            passiveBondQuietTimer = 0
            return
        }

        passiveBondQuietTimer += dt
        guard passiveBondQuietTimer >= PassiveBondBalance.quietDelay else { return }

        let needsCare = stats.hunger >= GameBalance.autoEatHungerThreshold(for: stats.phase)
            || stats.energy < 20
            || stats.scaredTimer > 0
        let multiplier = needsCare ? PassiveBondBalance.strainedCareMultiplier : 1
        stats.trust = min(100, stats.trust + dt * PassiveBondBalance.gainPerSecond * multiplier)
    }

    private func notePlayerPressure() {
        passiveBondQuietTimer = 0
    }

    // MARK: - Decisão por pesos

    @discardableResult
    func noticeObjectiveAvailable() -> Bool {
        pursueCurrentObjectiveIfNeeded()
    }

    @discardableResult
    private func pursueCurrentObjectiveIfNeeded() -> Bool {
        guard stats.phase != .egg,
              !paused,
              intent != .inChallenge,
              intent != .enteringRefuge,
              let objective = ctx.events.currentObjective,
              let point = objective.position() else {
            return false
        }

        if intent != .goingToObjective {
            commandBias = nil
            setIntent(.goingToObjective)
            decisionCooldown = 1
            showEmotion(.curious, duration: 1.2)
        } else {
            target = point
        }
        return true
    }

    private func decide() {
        // a caminho do portal do Refúgio: não muda de ideia no meio
        if intent == .enteringRefuge, portalPoint != nil {
            decisionCooldown = 1
            return
        }
        if pursueCurrentObjectiveIfNeeded() {
            decisionCooldown = 1
            return
        }
        if fishCompanionSessionIsActive {
            decisionCooldown = 1
            return
        }
        if intent == .wandering, let destination = touchPointTarget {
            if canReachPointWithCurrentEnergy(destination, margin: 0) {
                target = destination
                decisionCooldown = 1
            } else {
                stopDirectedDestinationForLowEnergy()
            }
            return
        }
        decisionCooldown = .random(in: 4...8)
        var scores: [MermaidIntent: CGFloat] = [:]

        scores[.idle] = 8 + .random(in: 0...6)
        scores[.wandering] = 16 + stats.curiosity * 0.25 + .random(in: 0...10)
        scores[.observing] = 4 + stats.curiosity * 0.1

        if stats.hunger > GameBalance.requestFoodHungerThreshold(for: stats.phase) {
            var foodScore = stats.hunger * 1.1
            if ctx.food.nearestFood(to: position, maxDistance: 900, includeShellCurrency: false) != nil { foodScore += 20 }
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
           stats.energy > 24,
           stats.hunger < 76,
           stats.scaredTimer <= 0,
           ctx.fish.nearestFish(to: position, maxDistance: FishPlayBalance.decisionRange) != nil {
            scores[.interactingWithFish] = 22
                + stats.disposition * 0.20
                + stats.curiosity * 0.16
                + CGFloat.random(in: 0...8)
        }
        if interactCooldown <= 0,
           stats.energy > 30,
           stats.hunger < 78,
           stats.scaredTimer <= 0,
           let fish = ctx.fish.nearestFish(to: position, maxDistance: FishPlayBalance.decisionRange),
           ctx.pois.guidanceTargetForFish(near: fish.position, zone: fish.zone) != nil {
            scores[.followingFish] = 12
                + stats.curiosity * 0.18
                + CGFloat.random(in: 0...8)
        }
        if let deeperZone = currentZone.deeper,
           ctx.depth.isUnlocked(deeperZone),
           stats.energy > 40, stats.hunger < 70 {
            scores[.goingDeeper] = stats.curiosity * 0.28 + stats.energy * 0.04
        }
        if currentZone != .shallow && currentZone != .surface {
            scores[.goingUp] = 6 + (stats.energy < 50 ? 10 : 0)
        }
        // peixes com desafio por perto despertam interesse próprio
        if ctx.challenges.nearestGiver(to: position, maxDistance: 1400) != nil,
           stats.energy > (stats.phase == .baby ? 35 : 25),
           stats.hunger < (stats.phase == .baby ? 65 : 85) {
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
        if intent == .followingFish && newIntent != .followingFish {
            endFishGuidance(removeBuff: true)
        }
        if intent == .interactingWithFish && newIntent != .interactingWithFish {
            cancelFishPlay(removeBuff: true)
        }
        intent = newIntent
        intentTime = 0
        clearTouchTargets(except: newIntent)
        switch newIntent {
        case .idle, .observing, .resting, .eating, .inChallenge, .avoidingDanger, .returningHome:
            if newIntent != .avoidingDanger { target = nil }
        case .wandering:
            target = directionalTouchTarget() ?? touchPointTarget ?? randomWanderPoint()
        case .seekingFood:
            if let food = validTouchFoodTarget() {
                target = food.position
            } else if let food = ctx.food.nearestFood(to: position, maxDistance: 1800, includeShellCurrency: false) {
                target = food.position
            } else {
                ctx.food.requestSpawn(near: position)
                target = randomWanderPoint()
            }
        case .seekingChallenge:
            target = validTouchChallengeTarget()?.position ?? ctx.challenges.ensureGiver(near: position)?.position
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
            target = boundedTarget(CGPoint(x: position.x + .random(in: -800...800), y: y),
                                   yRange: ctx.depth.allowedYRange())
        case .goingUp:
            let y: CGFloat
            if let zone = currentZone.shallower, ctx.depth.isUnlocked(zone) {
                y = zone == .surface
                    ? CGFloat.random(in: 40...200)
                    : zone.midY + .random(in: -800...800)
            } else {
                y = position.y + 1600
            }
            target = boundedTarget(CGPoint(x: position.x + .random(in: -800...800), y: y),
                                   yRange: ctx.depth.allowedYRange())
        case .traveling:
            target = ctx.travel.targetPoint
        case .followingFish:
            if guidingFishTarget == nil {
                guard beginAutonomousFishGuidance() else {
                    intent = .wandering
                    touchFishTarget = nil
                    target = randomWanderPoint()
                    return
                }
            }
            target = guidingFishTarget?.position
        case .interactingWithFish:
            if playFishTarget == nil {
                let fish = validTouchFishTarget()
                    ?? ctx.fish.nearestFish(to: position, maxDistance: FishPlayBalance.chaseRange)
                if let fish = fish {
                    beginFishPlayGathering(with: fish)
                }
            }
            target = fishPlayMeetPoint ?? playFishTarget?.position
        }
    }

    private func boundedTarget(_ point: CGPoint,
                               yRange: ClosedRange<CGFloat>) -> CGPoint {
        let clampedPoint = CGPoint(x: point.x.clamped(to: horizontalRange),
                                   y: point.y.clamped(to: yRange))
        return clampedPoint
    }

    private func directionalTouchTarget() -> CGPoint? {
        guard let direction = touchDirection,
              let until = touchDirectionUntil else { return nil }
        guard Date() < until else {
            clearTouchDirection()
            return nil
        }

        let range = ctx.depth.allowedYRange()
        let candidate = CGPoint(x: position.x + direction.dx * TouchDirectionBalance.targetDistance,
                                y: position.y + direction.dy * TouchDirectionBalance.targetDistance)
        return boundedTarget(candidate, yRange: range)
    }

    private func clearTouchDirection() {
        touchDirection = nil
        touchDirectionUntil = nil
    }

    private func randomWanderPoint() -> CGPoint {
        let range = ctx.depth.allowedYRange()
        let xRange = safeHorizontalWanderRange()
        return CGPoint(x: (position.x + .random(in: -1100...1100)).clamped(to: xRange),
                       y: (position.y + .random(in: -700...700)).clamped(to: range))
    }

    private func safeHorizontalWanderRange() -> ClosedRange<CGFloat> {
        inset(horizontalRange, by: HorizontalBoundaryBalance.wanderPadding)
    }

    private func inset(_ range: ClosedRange<CGFloat>, by padding: CGFloat) -> ClosedRange<CGFloat> {
        let lower = range.lowerBound + padding
        let upper = range.upperBound - padding
        return lower <= upper ? lower...upper : range
    }

    // MARK: - Progresso da intenção atual

    private func progressIntent(dt: CGFloat) {
        switch intent {
        case .seekingFood:
            if let food = validTouchFoodTarget() {
                target = food.position
                if position.distance(to: food.position) < 130 {
                    touchFoodTarget = nil
                    eat(food)
                }
            } else if touchFoodTarget != nil {
                touchFoodTarget = nil
                setIntent(.idle)
                decisionCooldown = min(decisionCooldown, 1.5)
            } else if let food = ctx.food.nearestFood(to: position, maxDistance: 1800, includeShellCurrency: false) {
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
            if let giver = validTouchChallengeTarget() {
                target = giver.position
                if position.distance(to: giver.position) < 150 {
                    touchChallengeTarget = nil
                    enterChallenge()
                    ctx.scene?.openChallenge(giver: giver)
                }
            } else if touchChallengeTarget != nil {
                touchChallengeTarget = nil
                setIntent(.idle)
                decisionCooldown = 2
            } else if let giver = ctx.challenges.nearestGiver(to: position, maxDistance: 2600) {
                target = giver.position
                if position.distance(to: giver.position) < 150 {
                    enterChallenge()
                    ctx.scene?.openChallenge(giver: giver)
                }
            } else if intentTime > 4 {
                target = ctx.challenges.ensureGiver(near: position)?.position
                if target == nil {
                    setIntent(.idle)
                    decisionCooldown = 2
                }
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
        case .followingFish:
            progressFishGuidance()
        case .interactingWithFish:
            progressFishPlay(dt: dt)
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
            if intent == .wandering, let directionalTarget = directionalTouchTarget() {
                target = directionalTarget
                break
            }
            if intent == .wandering, let destination = touchPointTarget {
                target = destination
                guard canReachPointWithCurrentEnergy(destination, margin: 0) else {
                    stopDirectedDestinationForLowEnergy()
                    break
                }
            }
            if let t = target, position.distance(to: t) < 90 {
                if intent == .wandering {
                    touchPointTarget = nil
                    clearTouchDirection()
                    commandBias = nil
                }
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
              intent != .followingFish, intent != .interactingWithFish,
              touchPointTarget == nil,
              stats.hunger >= GameBalance.autoEatHungerThreshold(for: stats.phase),
              eatCooldown <= 0 else { return }
        if let food = ctx.food.nearestFood(to: position, maxDistance: 120, includeShellCurrency: false) {
            eat(food)
        }
    }

    private func eat(_ food: FoodNode) {
        guard eatCooldown <= 0 else { return }
        let isShellCurrency = food.kind.isShellCurrency
        eatCooldown = 1.2
        touchFoodTarget = nil
        ctx.food.consume(food)
        if isShellCurrency {
            intent = .observing
            target = nil
            intentTime = 0
            showEmotion(.happy, duration: 1.2)
            return
        }
        GameAudio.shared.play(.mermaidEat)
        intent = .eating
        target = nil
        intentTime = 0
        showEmotion(.eating, duration: 1.2)
    }

    // MARK: - Medo / eventos

    func scare(from point: CGPoint) {
        guard !paused, intent != .inChallenge, intent != .enteringRefuge else { return }
        GameAudio.shared.play(.mermaidScared)
        stats.scare(duration: 7)
        let dx = position.x - point.x
        let dy = position.y - point.y
        let length = max(1, sqrt(dx * dx + dy * dy))
        let range = ctx.depth.allowedYRange()
        target = boundedTarget(CGPoint(x: position.x + dx / length * 500,
                                       y: position.y + dy / length * 500),
                               yRange: range)
        intent = .avoidingDanger
        intentTime = 0
        decisionCooldown = 5
    }

    // MARK: - Desafios

    @discardableResult
    func requestChallenge(kind: ChallengeKind) -> Bool {
        guard kind.isAvailable else {
            refuse(.challenge, saying: "\(kind.title) está pausado por enquanto.")
            return false
        }
        clearExpiredCommandCooldowns()

        let guaranteedByBabyStart = stats.canUseBabyGuaranteedRequest
        let guaranteedByCheat = stats.cheatAlwaysAcceptCommandsEnabled
        if !guaranteedByBabyStart,
           !guaranteedByCheat,
           let until = commandCooldownUntil[.challenge],
           until > Date() {
            return false
        }

        notePlayerPressure()

        guard stats.phase != .egg else {
            ctx.scene?.openHatchingChallenge()
            return true
        }
        guard intent != .inChallenge, intent != .enteringRefuge else { return false }

        let guaranteedByBondRecovery = isBondRecoveryRequestReady
        let requestIsGuaranteed = guaranteedByBabyStart
            || guaranteedByBondRecovery
            || guaranteedByCheat
            || stats.hasActiveBuff(.eagerCompanion)

        let hungerLimit: CGFloat = stats.phase == .baby ? 65 : 92
        let energyLimit: CGFloat = stats.phase == .baby ? 35 : 8
        if !requestIsGuaranteed && stats.hunger > hungerLimit {
            penalizeTrust(TrustBalance.unmetNeedRefusal)
            refuse(.challenge, saying: "Faminta demais para o \(kind.title)... me ajuda a comer algo?")
            return false
        }
        if !requestIsGuaranteed && stats.energy < energyLimit {
            penalizeTrust(TrustBalance.exhaustedRefusal)
            refuse(.challenge, saying: "Preciso descansar antes do \(kind.title)... 😴")
            return false
        }

        guard let giver = ctx.challenges.ensureGiver(near: position, kind: kind) else {
            refuse(.challenge, saying: "Nenhum peixe conseguiu trazer o \(kind.title) agora...")
            return false
        }

        let desired = MermaidIntent.seekingChallenge
        let chance = commandAcceptanceChance(for: desired)
        if requestIsGuaranteed || CGFloat.random(in: 0...1) <= chance {
            rewardAcceptedRequest(baseGain: TrustBalance.acceptedCommand,
                                  guaranteedByBondRecovery: guaranteedByBondRecovery,
                                  guaranteedByBabyStart: guaranteedByBabyStart)
            touchChallengeTarget = giver
            commandBias = (desired, Date().addingTimeInterval(30))
            setIntent(desired)
            decisionCooldown = .random(in: 6...10)
            GameAudio.shared.play(.uiConfirm)
            if guaranteedByBondRecovery {
                ctx.say("Ela aceitou seu pedido. O vínculo entre vocês ficou mais forte.")
            } else {
                ctx.say("Ela aceitou tentar o \(kind.title)... 🏆")
            }
            return true
        }

        penalizeTrust(TrustBalance.generalRefusal)
        let excuses = [
            "Ela pensou no \(kind.title), mas recusou por enquanto.",
            "Ela olhou o \(kind.shortName) e balançou a cabeça: agora não.",
            "Ela chegou perto da ideia do \(kind.shortName)... mas mudou de vontade."
        ]
        refuse(.challenge, saying: excuses.randomElement()!)
        return false
    }

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

    func startGivingSpace() {
        guard stats.phase != .egg else { return }
        notePlayerPressure()
        switch bondRecoveryState {
        case .waiting:
            return
        case .ready(_):
            ctx.say("Ela já respirou um pouco. Pode pedir com calma agora.")
            return
        case .idle:
            guard stats.trust < BondRecoveryBalance.lowTrustThreshold else { return }
        }

        bondRecoveryState = .waiting(until: Date().addingTimeInterval(BondRecoveryBalance.spaceDuration))
        commandBias = nil
        touchRequestCooldownUntil = nil
        GameAudio.shared.play(.mermaidRest)
        if !paused, intent != .inChallenge, intent != .enteringRefuge {
            setIntent(.observing)
            decisionCooldown = CGFloat(BondRecoveryBalance.spaceDuration)
            showEmotion(.sad, duration: 2)
        }
        ctx.say("Você deu espaço. Ela ficou quieta, mas a tensão começou a baixar.")
    }

    private func updateBondRecovery() {
        guard case .waiting(let until) = bondRecoveryState else { return }
        guard Date() >= until else { return }
        stats.trust = min(100, stats.trust + BondRecoveryBalance.spaceTrustGain)
        commandCooldownUntil.removeAll()
        touchRequestCooldownUntil = nil
        bondRecoveryState = .ready(remainingRequests: BondRecoveryBalance.guaranteedRequestCount)
        if !paused {
            showEmotion(.satisfied, duration: 1.8)
        }
        GameAudio.shared.play(.uiConfirm)
        ctx.say("Ela respirou um pouco. Pode pedir com calma agora.")
    }

    private func rewardAcceptedRequest(baseGain: CGFloat,
                                       guaranteedByBondRecovery: Bool,
                                       guaranteedByBabyStart: Bool = false) {
        var gain = baseGain
        if guaranteedByBondRecovery {
            gain += BondRecoveryBalance.acceptedRequestTrustGain
            if case .ready(let remainingRequests) = bondRecoveryState {
                let nextRemaining = max(0, remainingRequests - 1)
                bondRecoveryState = nextRemaining > 0
                    ? .ready(remainingRequests: nextRemaining)
                    : .idle
            }
        }
        if guaranteedByBabyStart {
            stats.consumeBabyGuaranteedRequestIfNeeded()
        }
        stats.trust = min(100, stats.trust + gain)
    }

    func give(_ command: PlayerCommand) {
        clearExpiredCommandCooldowns()
        let shouldDeferPressure = command == .challenge && stats.phase != .egg
        if !shouldDeferPressure {
            notePlayerPressure()
        }
        let guaranteedByBabyStart = stats.canUseBabyGuaranteedRequest
        let guaranteedByCheat = stats.cheatAlwaysAcceptCommandsEnabled
        if !guaranteedByBabyStart,
           !guaranteedByCheat,
           let until = commandCooldownUntil[command],
           until > Date() {
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

        let guaranteedByBondRecovery = isBondRecoveryRequestReady
        let requestIsGuaranteed = guaranteedByBabyStart
            || guaranteedByBondRecovery
            || guaranteedByCheat
            || stats.hasActiveBuff(.eagerCompanion)
        var guidedExplorePoint: CGPoint?
        var guidedDirection: CGVector?
        let desired: MermaidIntent
        switch command {
        case .explore:
            guidedExplorePoint = ctx.pois.explorationTargetAfterCommand()
            desired = .wandering
        case .resources:
            ctx.scene?.openResourceChoiceMenu()
            return
        case .rest:
            desired = .resting
        case .travel:
            // o menu de regiões é interface, não depende da disposição dela
            ctx.scene?.openRegionMenu()
            return
        case .registro:
            ctx.scene?.openRegistro()
            return
        case .refuge:
            // portal mágico: ela sempre vai, mas agora dá para VER o caminho
            if guaranteedByBondRecovery {
                rewardAcceptedRequest(baseGain: TrustBalance.acceptedCommand,
                                      guaranteedByBondRecovery: true)
            }
            ctx.scene?.beginRefugeEntry()
            return
        case .challenge:
            ctx.scene?.openChallengeChoiceMenu()
            return
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
            guard requestIsGuaranteed || stats.energy > 15 else {
                refuseTired(command)
                return
            }
            if !requestIsGuaranteed && stats.hunger > 80 {
                penalizeTrust(TrustBalance.forcedRiskWhileHungry)
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
            guard requestIsGuaranteed || stats.energy > 10 else {
                refuseTired(command)
                return
            }
            if let next = currentZone.shallower, !ctx.depth.isUnlocked(next) {
                ctx.say(ctx.depth.ascentHint(for: next))
            }
            desired = .goingUp
        case .goLeft:
            guard requestIsGuaranteed || stats.energy > 10 else {
                refuseTired(command)
                return
            }
            guidedDirection = CGVector(dx: -1, dy: 0)
            desired = .wandering
        case .goRight:
            guard requestIsGuaranteed || stats.energy > 10 else {
                refuseTired(command)
                return
            }
            guidedDirection = CGVector(dx: 1, dy: 0)
            desired = .wandering
        }

        let chance = commandAcceptanceChance(for: desired)

        if requestIsGuaranteed || CGFloat.random(in: 0...1) <= chance {
            rewardAcceptedRequest(baseGain: TrustBalance.acceptedCommand,
                                  guaranteedByBondRecovery: guaranteedByBondRecovery,
                                  guaranteedByBabyStart: guaranteedByBabyStart)
            if desired == .wandering {
                if let guidedDirection {
                    touchPointTarget = nil
                    touchDirection = guidedDirection
                    touchDirectionUntil = Date().addingTimeInterval(TouchDirectionBalance.duration)
                } else if let guidedExplorePoint {
                    let limitedPoint = pointLimitedByEnergy(guidedExplorePoint)
                    touchPointTarget = limitedPoint
                    if limitedPoint.distance(to: guidedExplorePoint) > 24 {
                        ctx.say("Ela sentiu uma pista longe, mas vai se aproximar por partes para não cansar.")
                    }
                } else {
                    touchPointTarget = nil
                }
            }
            let hasDirectedDestination = desired == .wandering
                && touchPointTarget != nil
                && guidedDirection == nil
            commandBias = hasDirectedDestination ? nil : (desired, Date().addingTimeInterval(30))
            setIntent(desired)
            decisionCooldown = .random(in: 6...10)
            GameAudio.shared.play(.uiConfirm)
            if guaranteedByBondRecovery {
                ctx.say("Ela aceitou seu pedido. O vínculo entre vocês ficou mais forte.")
            } else if desired == .seekingChallenge {
                ctx.say("Ela foi atrás de um peixe com desafio... 🏆")
            } else if desired == .goingToObjective {
                ctx.say("Ela foi investigar... 👀")
            }
        } else {
            penalizeTrust(TrustBalance.generalRefusal)
            let excuses = [
                "Hmm... agora não.",
                "Ela fingiu que não ouviu...",
                "Ela balançou a cabeça, sem vontade."
            ]
            refuse(command, saying: excuses.randomElement()!)
        }
    }

    private func refuse(_ command: PlayerCommand, saying message: String) {
        let cooldown: TimeInterval = command == .challenge
            ? GameBalance.challengeCommandCooldown(for: stats.phase)
            : 10
        commandCooldownUntil[command] = Date().addingTimeInterval(cooldown)
        GameAudio.shared.play(.uiReject)
        showEmotion(.stubborn, duration: 1.8)
        ctx.say(message)
    }

    @discardableResult
    func requestPointFromTouch(_ point: CGPoint) -> Bool {
        notePlayerPressure()
        let range = ctx.depth.allowedYRange()
        let clampedPoint = CGPoint(x: point.x.clamped(to: horizontalRange),
                                   y: point.y.clamped(to: range))
        let dx = clampedPoint.x - position.x
        let dy = clampedPoint.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance >= TouchDirectionBalance.minimumGestureDistance else {
            ctx.say("Ela precisa de uma direção mais clara.")
            return false
        }

        guard acceptTouchRequest(for: .wandering,
                                 acceptedMessage: "Ela entendeu a direção e começou a nadar...",
                                 refusalMessages: [
                                    "Ela olhou para onde você apontou, mas preferiu ficar por aqui.",
                                    "Ela fez que não com a cabeça. Agora não.",
                                    "Ela viu seu gesto, mas seguiu a própria vontade."
                                 ]) else { return false }
        touchPointTarget = nil
        touchDirection = CGVector(dx: dx / distance, dy: dy / distance)
        touchDirectionUntil = Date().addingTimeInterval(TouchDirectionBalance.duration)
        commandBias = nil
        setIntent(.wandering)
        decisionCooldown = CGFloat(TouchDirectionBalance.duration)
        return true
    }

    @discardableResult
    func requestDestinationFromTouch(_ point: CGPoint,
                                     acceptedMessage: String,
                                     refusalMessages: [String]) -> Bool {
        notePlayerPressure()
        let range = ctx.depth.allowedYRange()
        let clampedPoint = CGPoint(x: point.x.clamped(to: horizontalRange),
                                   y: point.y.clamped(to: range))
        let distance = position.distance(to: clampedPoint)
        guard distance >= TouchDirectionBalance.minimumGestureDistance else {
            return true
        }

        guard acceptTouchRequest(for: .wandering,
                                 acceptedMessage: acceptedMessage,
                                 refusalMessages: refusalMessages) else { return false }
        touchPointTarget = clampedPoint
        clearTouchDirection()
        commandBias = nil
        setIntent(.wandering)
        decisionCooldown = 1
        return true
    }

    func canReachPointWithCurrentEnergy(_ point: CGPoint, margin: CGFloat = 120) -> Bool {
        let range = ctx.depth.allowedYRange()
        let clampedPoint = CGPoint(x: point.x.clamped(to: horizontalRange),
                                   y: point.y.clamped(to: range))
        return position.distance(to: clampedPoint) <= directedTravelLimit() + margin
    }

    @discardableResult
    func requestObjectiveFromTouch() -> Bool {
        notePlayerPressure()
        guard ctx.events.currentObjective?.position() != nil else {
            ctx.say("Nada acontecendo ali agora... 👀")
            return false
        }
        guard intent != .inChallenge, intent != .enteringRefuge, !paused else { return false }
        commandBias = nil
        setIntent(.goingToObjective)
        decisionCooldown = 1
        return true
    }

    @discardableResult
    func requestFoodFromTouch(_ food: FoodNode) -> Bool {
        notePlayerPressure()
        guard food.parent != nil else { return false }
        guard !food.kind.isShellCurrency else { return false }
        guard stats.canUseBabyGuaranteedRequest
                || isBondRecoveryRequestReady
                || stats.hunger >= 28
                || food.kind.pearls > 0
                || food.kind.nutrition >= 18 else {
            return rejectTouchRequest("Ela viu \(food.kind.name), mas não está com fome agora.")
        }
        let acceptedMessage = "Ela aceitou provar \(food.kind.name)..."
        let refusalMessages = [
            "Ela viu \(food.kind.name), mas não quis comer agora.",
            "Ela virou o rostinho para longe da comida.",
            "Ela fingiu que não viu \(food.kind.name)."
        ]
        guard acceptTouchRequest(for: .seekingFood,
                                 acceptedMessage: acceptedMessage,
                                 refusalMessages: refusalMessages) else { return false }
        touchFoodTarget = food
        commandBias = nil
        setIntent(.seekingFood)
        decisionCooldown = .random(in: 7...12)
        return true
    }

    @discardableResult
    func requestFishFromTouch(_ fish: FishNode) -> Bool {
        notePlayerPressure()
        guard fish.parent != nil else { return false }
        guard fish.isAvailableForCompanionAction else { return false }
        let action = companionAction(for: fish)
        let acceptedMessage: String
        switch action {
        case .guide(_):
            acceptedMessage = "Ela aceitou seguir o peixinho..."
        case .play:
            acceptedMessage = "Ela aceitou brincar com o peixinho..."
        }
        guard acceptTouchRequest(for: action.intent,
                                 acceptedMessage: acceptedMessage,
                                 refusalMessages: [
                                    "Ela viu o peixinho, mas não quis chegar perto agora.",
                                    "Ela deixou o peixinho passar sem seguir.",
                                    "Ela balançou a cabeça: hoje não."
                                 ]) else { return false }
        touchFishTarget = fish
        commandBias = nil
        switch action {
        case .guide(let poi):
            beginFishGuidance(with: fish, poi: poi, playerInitiated: true)
            setIntent(.followingFish)
            decisionCooldown = CGFloat(FishPlayBalance.guidanceDuration)
        case .play:
            beginFishPlayGathering(with: fish)
            setIntent(.interactingWithFish)
            decisionCooldown = CGFloat(FishPlayBalance.playDuration + FishPlayBalance.gatherDuration)
        }
        return true
    }

    @discardableResult
    func requestChallengeFromTouch(_ giver: FishNode) -> Bool {
        notePlayerPressure()
        guard giver.parent != nil, giver.offeredChallenge != nil else { return false }
        let hungerLimit: CGFloat = stats.phase == .baby ? 65 : 92
        let energyLimit: CGFloat = stats.phase == .baby ? 35 : 8
        guard stats.canUseBabyGuaranteedRequest || isBondRecoveryRequestReady || stats.hunger <= hungerLimit else {
            return rejectTouchRequest("Faminta demais para um desafio... me ajuda a comer algo?")
        }
        guard stats.canUseBabyGuaranteedRequest || isBondRecoveryRequestReady || stats.energy >= energyLimit else {
            return rejectTouchRequest("Preciso descansar antes de um desafio... 😴", emotion: .tired)
        }
        guard acceptTouchRequest(for: .seekingChallenge,
                                 acceptedMessage: "Ela aceitou seguir até o peixe do desafio...",
                                 refusalMessages: [
                                    "O peixe chamou, mas ela não quis seguir agora.",
                                    "Ela viu o desafio e recusou por enquanto.",
                                    "Ela chegou perto da ideia... mas mudou de vontade."
                                 ]) else { return false }
        touchChallengeTarget = giver
        commandBias = nil
        setIntent(.seekingChallenge)
        decisionCooldown = .random(in: 7...12)
        return true
    }

    private func companionAction(for fish: FishNode) -> FishCompanionAction {
        if let poi = guidanceCandidate(for: fish),
           CGFloat.random(in: 0...1) <= FishPlayBalance.guideChanceOnTouch {
            return .guide(poi)
        }
        return .play
    }

    private func guidanceCandidate(for fish: FishNode) -> WorldPOI? {
        guard fish.isAvailableForCompanionAction else { return nil }
        return ctx.pois.guidanceTargetForFish(near: fish.position, zone: fish.zone)
    }

    @discardableResult
    private func beginAutonomousFishGuidance() -> Bool {
        guard let fish = ctx.fish.nearestFish(to: position, maxDistance: FishPlayBalance.chaseRange),
              let poi = guidanceCandidate(for: fish) else {
            return false
        }
        beginFishGuidance(with: fish, poi: poi, playerInitiated: false)
        return true
    }

    private func beginFishGuidance(with fish: FishNode,
                                   poi: WorldPOI,
                                   playerInitiated: Bool) {
        cancelFishPlay(removeBuff: true)
        guidingFishTarget?.resumeNaturalSwimming()
        guidingFishTarget = fish
        guidingPOI = poi
        fishGuidanceUntil = Date().addingTimeInterval(FishPlayBalance.guidanceDuration)
        touchFishTarget = fish
        target = fishGuidanceFollowPoint(for: fish, poi: poi)
        fish.startGuiding(toward: poi.position, duration: FishPlayBalance.guidanceDuration)
        stats.addTimedBuff(.fishGuide,
                           title: "Seguindo peixe",
                           duration: FishPlayBalance.guidanceDuration)
        showEmotion(.curious, duration: 1.4)
        if !playerInitiated {
            ctx.say("Um peixinho parece saber um caminho... ela começou a seguir.")
        }
    }

    private func progressFishGuidance() {
        guard let fish = guidingFishTarget,
              fish.parent != nil,
              let poi = guidingPOI,
              let until = fishGuidanceUntil else {
            setIntent(.wandering)
            return
        }

        target = fishGuidanceFollowPoint(for: fish, poi: poi)
        if position.distance(to: poi.position) < 420 {
            ctx.stats.revealExpeditionMap(in: ctx.activeRegion, near: poi.position)
        }
        guard Date() < until else {
            let reached = position.distance(to: poi.position) < 560
            endFishGuidance(removeBuff: true)
            if reached {
                ctx.stats.revealExpeditionMap(in: ctx.activeRegion, near: poi.position)
                ctx.say("O peixinho levou \(stats.mermaidName) para perto de \(poi.name).")
            } else {
                ctx.say("O peixinho guiou \(stats.mermaidName) um pouco mais perto de algo curioso.")
            }
            setIntent(.observing)
            decisionCooldown = 3
            return
        }
    }

    private func fishGuidanceFollowPoint(for fish: FishNode, poi: WorldPOI) -> CGPoint {
        let direction = fishGuidanceDirection(for: fish, poi: poi)
        let point = CGPoint(x: fish.position.x - direction.dx * FishPlayBalance.guidanceFollowDistance,
                            y: fish.position.y - direction.dy * FishPlayBalance.guidanceFollowDistance)
        let range = ctx.depth.allowedYRange()
        return CGPoint(x: point.x.clamped(to: horizontalRange),
                       y: point.y.clamped(to: range))
    }

    private func fishGuidanceDirection(for fish: FishNode, poi: WorldPOI) -> CGVector {
        let dx = poi.position.x - position.x
        let dy = poi.position.y - position.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 1 else {
            return CGVector(dx: cos(fish.heading), dy: sin(fish.heading))
        }
        return CGVector(dx: dx / distance, dy: dy / distance)
    }

    private func endFishGuidance(removeBuff: Bool) {
        guidingFishTarget?.resumeNaturalSwimming()
        guidingFishTarget = nil
        guidingPOI = nil
        fishGuidanceUntil = nil
        if removeBuff {
            stats.removeTimedBuff(.fishGuide)
        }
    }

    private func beginFishPlayGathering(with fish: FishNode) {
        endFishGuidance(removeBuff: true)
        playFishTarget?.resumeNaturalSwimming()
        playFishTarget = fish
        touchFishTarget = fish
        let meetPoint = fishPlayGatherPoint(for: fish)
        fishPlayMeetPoint = meetPoint
        fishPlayAnchor = nil
        fishPlayUntil = nil
        fishPlayPhase = 0
        target = meetPoint
        fish.gatherForPlay(at: fishPlayFishGatherPoint(for: fish, mermaidPoint: meetPoint),
                           duration: FishPlayBalance.gatherDuration)
        stats.addTimedBuff(.fishPlay,
                           title: "Indo brincar",
                           duration: FishPlayBalance.gatherDuration)
        showEmotion(.happy, duration: 1.2)
    }

    private func progressFishPlay(dt: CGFloat) {
        guard let fish = playFishTarget, fish.parent != nil else {
            cancelFishPlay(removeBuff: true)
            setIntent(.wandering)
            return
        }

        if let until = fishPlayUntil, let anchor = fishPlayAnchor {
            guard Date() < until else {
                finishFishPlay(with: fish)
                return
            }
            fishPlayPhase += dt * FishPlayBalance.mermaidPlaySpeed
            target = mermaidPlayPoint(around: anchor, phase: fishPlayPhase)
            return
        }

        let meetPoint = fishPlayMeetPoint ?? fish.position
        target = meetPoint
        if position.distance(to: meetPoint) <= FishPlayBalance.meetDistance
            || intentTime >= CGFloat(FishPlayBalance.gatherDuration) {
            beginActiveFishPlay(with: fish)
        }
    }

    private func beginActiveFishPlay(with fish: FishNode) {
        let anchor = fishPlayAnchorPoint(for: fish)
        fishPlayAnchor = anchor
        fishPlayMeetPoint = nil
        fishPlayUntil = Date().addingTimeInterval(FishPlayBalance.playDuration)
        fishPlayPhase = 0
        target = mermaidPlayPoint(around: anchor, phase: fishPlayPhase)
        fish.startPlaying(around: anchor, duration: FishPlayBalance.playDuration)
        stats.addTimedBuff(.fishPlay,
                           title: "Brincando com peixe",
                           duration: FishPlayBalance.playDuration)
        ctx.say("\(stats.mermaidName) e o peixinho chegaram pertinho e começaram a brincar.")
    }

    private func fishPlayGatherPoint(for fish: FishNode) -> CGPoint {
        let midpoint = CGPoint(x: (position.x + fish.position.x) / 2,
                               y: (position.y + fish.position.y) / 2)
        let dx = fish.position.x - position.x
        let dy = fish.position.y - position.y
        let distance = max(CGFloat(1), sqrt(dx * dx + dy * dy))
        let side: CGFloat = fish.position.x >= position.x ? 1 : -1
        let perpendicular = CGVector(dx: -dy / distance * side,
                                     dy: dx / distance * side)
        let point = CGPoint(x: midpoint.x + perpendicular.dx * FishPlayBalance.gatherSideOffset,
                            y: midpoint.y + perpendicular.dy * FishPlayBalance.gatherSideOffset)
        return boundedTarget(point, yRange: ctx.depth.allowedYRange())
    }

    private func fishPlayAnchorPoint(for fish: FishNode) -> CGPoint {
        let basePoint = fishPlayMeetPoint ?? CGPoint(x: (position.x + fish.position.x) / 2,
                                                     y: (position.y + fish.position.y) / 2)
        return boundedTarget(basePoint, yRange: ctx.depth.allowedYRange())
    }

    private func fishPlayFishGatherPoint(for fish: FishNode, mermaidPoint: CGPoint) -> CGPoint {
        let dx = fish.position.x - position.x
        let dy = fish.position.y - position.y
        let distance = max(CGFloat(1), sqrt(dx * dx + dy * dy))
        let point = CGPoint(x: mermaidPoint.x + dx / distance * CGFloat(145),
                            y: mermaidPoint.y + dy / distance * CGFloat(82))
        return boundedTarget(point, yRange: ctx.depth.allowedYRange())
    }

    private func mermaidPlayPoint(around anchor: CGPoint, phase: CGFloat) -> CGPoint {
        let point = CGPoint(x: anchor.x + cos(phase + .pi) * FishPlayBalance.mermaidPlayRadiusX,
                            y: anchor.y + sin(phase * 1.35 + .pi) * FishPlayBalance.mermaidPlayRadiusY)
        return boundedTarget(point, yRange: ctx.depth.allowedYRange())
    }

    private func finishFishPlay(with fish: FishNode) {
        playFishTarget = nil
        fishPlayMeetPoint = nil
        fishPlayAnchor = nil
        fishPlayUntil = nil
        touchFishTarget = nil
        fish.resumeNaturalSwimming()
        interact(with: fish)
    }

    private func cancelFishPlay(removeBuff: Bool) {
        playFishTarget?.resumeNaturalSwimming()
        playFishTarget = nil
        fishPlayMeetPoint = nil
        fishPlayAnchor = nil
        fishPlayUntil = nil
        if removeBuff {
            stats.removeTimedBuff(.fishPlay)
        }
    }

    func showTouchCooldownFeedback() {
        let remaining = Int(ceil(touchRequestCooldownRemaining))
        guard remaining > 0 else { return }
        ctx.say("Ela ainda está decidida. Tente outro gesto em \(remaining)s.")
    }

    private func acceptTouchRequest(for desired: MermaidIntent,
                                    acceptedMessage: String,
                                    refusalMessages: [String]) -> Bool {
        guard stats.phase != .egg, intent != .inChallenge, intent != .enteringRefuge, !paused else { return false }

        let guaranteedByBabyStart = stats.canUseBabyGuaranteedRequest
        let guaranteedByCheat = stats.cheatAlwaysAcceptCommandsEnabled
        if !guaranteedByBabyStart && !guaranteedByCheat && touchRequestCooldownRemaining > 0 {
            showTouchCooldownFeedback()
            return false
        }

        let guaranteedByBondRecovery = isBondRecoveryRequestReady
        let requestIsGuaranteed = guaranteedByBabyStart
            || guaranteedByBondRecovery
            || guaranteedByCheat
            || stats.hasActiveBuff(.eagerCompanion)
        let chance = touchAcceptanceChance(for: desired)
        if requestIsGuaranteed || CGFloat.random(in: 0...1) <= chance {
            rewardAcceptedRequest(baseGain: 0.15,
                                  guaranteedByBondRecovery: guaranteedByBondRecovery,
                                  guaranteedByBabyStart: guaranteedByBabyStart)
            GameAudio.shared.play(.uiConfirm)
            ctx.say(guaranteedByBondRecovery
                    ? "Ela aceitou seu pedido. O vínculo entre vocês ficou mais forte."
                    : acceptedMessage)
            return true
        }

        stats.trust = max(0, stats.trust - 0.3)
        let refusal = refusalMessages.randomElement() ?? "Ela recusou seu pedido."
        return rejectTouchRequest(refusal)
    }

    private func rejectTouchRequest(_ message: String,
                                    emotion: MermaidEmotion = .stubborn) -> Bool {
        touchRequestCooldownUntil = Date().addingTimeInterval(10)
        GameAudio.shared.play(.uiReject)
        showEmotion(emotion, duration: 1.8)
        ctx.say("\(message) Tente outro gesto em 10s.")
        return false
    }

    private func commandAcceptanceChance(for desired: MermaidIntent) -> CGFloat {
        // Disposição: cresce com vínculo e bem-estar, cai com fome e medo.
        var chance = (stats.phase == .baby ? 0.25 : 0.34)
            + stats.trust * 0.0024
            + stats.disposition * 0.001
            - stats.hunger * 0.0014
            + stats.dispositionAcceptanceBonus
        if stats.phase == .baby && desired == .seekingChallenge { chance -= 0.08 }
        if stats.scaredTimer > 0 { chance -= 0.2 }
        return chance.clamped(to: stats.phase == .baby ? 0.12...0.78 : 0.18...0.90)
    }

    private func touchAcceptanceChance(for desired: MermaidIntent) -> CGFloat {
        commandAcceptanceChance(for: desired)
    }

    private func pointLimitedByEnergy(_ point: CGPoint) -> CGPoint {
        let distance = position.distance(to: point)
        let limit = directedTravelLimit()
        guard distance > limit else { return point }
        let dx = point.x - position.x
        let dy = point.y - position.y
        let safeDistance = max(1, distance)
        return CGPoint(x: position.x + dx / safeDistance * limit,
                       y: position.y + dy / safeDistance * limit)
    }

    private func stopDirectedDestinationForLowEnergy() {
        touchPointTarget = nil
        clearTouchDirection()
        commandBias = nil
        target = nil
        velocity = CGVector(dx: 0, dy: 0)
        setIntent(.resting)
        decisionCooldown = 3
        showEmotion(.tired, duration: 1.8)
        ctx.say("Ela ficou sem energia para continuar até o ponto e parou para descansar.")
    }

    private func directedTravelLimit() -> CGFloat {
        let phaseMultiplier: CGFloat
        switch stats.phase {
        case .egg: phaseMultiplier = 0
        case .baby: phaseMultiplier = 0.75
        case .child: phaseMultiplier = 0.92
        case .teen: phaseMultiplier = 1.08
        case .young: phaseMultiplier = 1.22
        case .adult: phaseMultiplier = 1.36
        }
        let base = 2_200 + stats.energy.clamped(to: 0...100) * 160
        return base * phaseMultiplier * stats.speedMultiplier
    }

    private func validTouchFoodTarget() -> FoodNode? {
        guard let food = touchFoodTarget, food.parent != nil else { return nil }
        return food
    }

    private func validTouchFishTarget() -> FishNode? {
        guard let fish = touchFishTarget, fish.parent != nil else { return nil }
        return fish
    }

    private func validTouchChallengeTarget() -> FishNode? {
        guard let fish = touchChallengeTarget,
              fish.parent != nil,
              fish.offeredChallenge != nil else { return nil }
        return fish
    }

    private func clearTouchTargets(except intent: MermaidIntent) {
        if intent != .wandering {
            touchPointTarget = nil
            clearTouchDirection()
        }
        if intent != .seekingFood {
            touchFoodTarget = nil
        }
        if intent != .interactingWithFish && intent != .followingFish {
            touchFishTarget = nil
        }
        if intent != .seekingChallenge {
            touchChallengeTarget = nil
        }
    }

    private func interact(with fish: FishNode) {
        interactCooldown = FishPlayBalance.cooldown
        ctx.fish.interact(fish)
        GameAudio.shared.play(.mermaidFishPlay)
        stats.boostMood(6)
        if Int.random(in: 0..<12) == 0 {
            let gained = stats.awardPearls(1)
            ctx.say("O peixinho deixou conchas! 🐚+\(GameUI.shellAmountText(gained))")
        }
        setIntent(.observing)
        decisionCooldown = 4
    }

    private func clearExpiredCommandCooldowns() {
        let now = Date()
        commandCooldownUntil = commandCooldownUntil.filter { $0.value > now }
    }

    private func penalizeTrust(_ amount: CGFloat) {
        stats.trust = max(0, stats.trust - amount)
    }

    /// Quanto mais nova, mais teimosa para comer quando mandam.
    private func eatRefusalChance() -> CGFloat {
        let reduction = CGFloat(stats.dispositionUpgradeLevel) * 0.0028
        switch stats.phase {
        case .egg: return 0
        case .baby: return (0.55 - reduction).clamped(to: 0.22...0.55)
        case .child: return (0.34 - reduction).clamped(to: 0.12...0.34)
        case .teen: return (0.23 - reduction).clamped(to: 0.08...0.23)
        case .young: return (0.14 - reduction).clamped(to: 0.05...0.14)
        case .adult: return (0.08 - reduction).clamped(to: 0.03...0.08)
        }
    }

    private func refuseTired(_ command: PlayerCommand) {
        penalizeTrust(TrustBalance.exhaustedRefusal)
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
        case .followingFish: baseSpeed = 205
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
        let combinedDrift = CGVector(dx: drift.dx + environmentDrift.dx,
                                     dy: drift.dy + environmentDrift.dy)
        p.x += (velocity.dx + combinedDrift.dx) * dt
        p.y += (velocity.dy + combinedDrift.dy) * dt
        // ondulação sutil para o nado parecer vivo
        p.x += cos(wobblePhase * 0.9) * 10 * dt
        p.y += sin(wobblePhase * 1.6) * 8 * dt

        let xRange = horizontalRange
        let yRange = ctx.depth.allowedYRange()
        let horizontalContact = horizontalBoundaryContact(forX: p.x, in: xRange)
        let attemptedAboveLimit = p.y > yRange.upperBound + 1
        let attemptedBelowLimit = p.y < yRange.lowerBound - 1
        let verticalMotion = velocity.dy + combinedDrift.dy
        let movingUp = verticalMotion > 20 || intent == .goingUp
        let movingDown = verticalMotion < -20 || intent == .goingDeeper
        let boundaryContact: DepthBoundaryEdge?
        if attemptedAboveLimit && movingUp {
            boundaryContact = .upper
        } else if attemptedBelowLimit && movingDown {
            boundaryContact = .lower
        } else {
            boundaryContact = nil
        }

        p.x = p.x.clamped(to: xRange)
        p.y = p.y.clamped(to: yRange)
        if let horizontalContact {
            if activeHorizontalBoundaryContact != horizontalContact,
               canStartHorizontalBoundaryReturn {
                activeHorizontalBoundaryContact = horizontalContact
                startHorizontalBoundaryReturn(from: horizontalContact, yRange: yRange)
            }
        } else if p.x > xRange.lowerBound + HorizontalBoundaryBalance.releasePadding,
                  p.x < xRange.upperBound - HorizontalBoundaryBalance.releasePadding {
            activeHorizontalBoundaryContact = nil
        }
        if let boundaryContact {
            if activeBoundaryContact != boundaryContact {
                activeBoundaryContact = boundaryContact
                showBoundaryFeedback(for: boundaryContact)
            }
        } else if p.y < yRange.upperBound - 120 && p.y > yRange.lowerBound + 120 {
            activeBoundaryContact = nil
        }
        mermaid.base.position = p
    }

    private func horizontalBoundaryContact(forX x: CGFloat, in range: ClosedRange<CGFloat>) -> HorizontalBoundarySide? {
        if x <= range.lowerBound + HorizontalBoundaryBalance.contactPadding {
            return .left
        }
        if x >= range.upperBound - HorizontalBoundaryBalance.contactPadding {
            return .right
        }
        return nil
    }

    private var canStartHorizontalBoundaryReturn: Bool {
        intent != .inChallenge && intent != .enteringRefuge
    }

    private func startHorizontalBoundaryReturn(from side: HorizontalBoundarySide, yRange: ClosedRange<CGFloat>) {
        guard canStartHorizontalBoundaryReturn else { return }

        let range = horizontalRange
        let width = max(0, range.upperBound - range.lowerBound)
        let padding = min(CGFloat.random(in: HorizontalBoundaryBalance.retreatPaddingRange), width / 2)
        let x = side == .left ? range.lowerBound + padding : range.upperBound - padding
        let y = (position.y + CGFloat.random(in: HorizontalBoundaryBalance.verticalJitterRange)).clamped(to: yRange)

        commandBias = nil
        touchPointTarget = nil
        clearTouchDirection()
        setIntent(.wandering)
        target = CGPoint(x: x, y: y)
        decisionCooldown = max(decisionCooldown, 3)
    }

    private func showBoundaryFeedback(for edge: DepthBoundaryEdge) {
        ctx.depth.flashBoundaryPalette(for: edge)
        guard boundaryFeedbackCooldown <= 0 else { return }
        boundaryFeedbackCooldown = 8
        GameAudio.shared.play(.uiReject)
        showEmotion(.stubborn, duration: 1.4)
        ctx.say(ctx.depth.boundaryHint(for: edge))
    }

    private func updateAnimation() {
        let effectiveVelocity = CGVector(dx: velocity.dx + drift.dx + environmentDrift.dx,
                                         dy: velocity.dy + drift.dy + environmentDrift.dy)
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
