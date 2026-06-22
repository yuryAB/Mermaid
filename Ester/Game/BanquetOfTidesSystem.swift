//
//  BanquetOfTidesSystem.swift
//  Ester
//
//  Desafio: Banquete das Marés. Jogo de comer alimentos bons, crescer,
//  evitar comida estragada e escapar de perigos que cruzam a arena.
//

import Foundation
import SpriteKit

// MARK: - Regras puras

private enum BanquetRules {
    static let startTime: CGFloat = 44
    static let maxTime: CGFloat = 48
    static let startLives = 3
    static let gaugeLimit: CGFloat = 100
    static let maxStage = 5
    static let basePlayerRadius: CGFloat = 23
    static let playerStageRadius: CGFloat = 4.4
    static let invulnerabilityTime: CGFloat = 1.05
    static let bumpCooldown: CGFloat = 0.85

    static func goal(for zone: DepthZone, special: Bool) -> Int {
        132 + zone.rawValue * 18 + (special ? 54 : 0)
    }

    static func playerRadius(stage: Int) -> CGFloat {
        basePlayerRadius + CGFloat(max(0, stage - 1)) * playerStageRadius
    }

    static func playerSpeed(stage: Int) -> CGFloat {
        max(190, 285 - CGFloat(stage - 1) * 18)
    }

    static func difficulty(elapsed: CGFloat, stage: Int, score: Int) -> CGFloat {
        let timePressure = elapsed / startTime * 0.42
        let bodyPressure = CGFloat(stage - 1) * 0.11
        let scorePressure = CGFloat(score) / 360 * 0.24
        return (timePressure + bodyPressure + scorePressure).clamped(to: 0...1)
    }

    static func spawnInterval(difficulty: CGFloat) -> CGFloat {
        (0.76 - difficulty * 0.24).clamped(to: 0.44...0.76)
    }

    static func entityScale(stage: Int, difficulty: CGFloat) -> CGFloat {
        1 + CGFloat(stage - 1) * 0.07 + difficulty * 0.10
    }

    static func speed(for role: BanquetItemRole, difficulty: CGFloat) -> CGFloat {
        let base: CGFloat
        switch role {
        case .fresh: base = 94
        case .rotten: base = 110
        case .hazard: base = 128
        case .bumper: base = 86
        }
        return base + difficulty * 58 + CGFloat.random(in: -18...22)
    }

    static func freshPoints(for kind: BanquetItemKind, stage: Int) -> Int {
        let base: Int
        switch kind {
        case .seaGrapes: base = 8
        case .moonRice: base = 10
        case .sweetShell: base = 12
        default: base = 0
        }
        return base + max(0, stage - 1) * 2
    }

    static func freshGauge(for kind: BanquetItemKind, stage: Int) -> CGFloat {
        let base: CGFloat
        switch kind {
        case .seaGrapes: base = 23
        case .moonRice: base = 29
        case .sweetShell: base = 35
        default: base = 0
        }
        return base + CGFloat(max(0, stage - 1)) * 2
    }

    static func rottenPointPenalty(stage: Int) -> Int {
        6 + max(0, stage - 1) * 2
    }

    static func rottenGaugePenalty(stage: Int) -> CGFloat {
        28 + CGFloat(max(0, stage - 1)) * 4
    }

    static func growthBonus(stage: Int) -> Int {
        12 + stage * 4
    }

    static func timeBonus(for kind: BanquetItemKind) -> CGFloat {
        switch kind {
        case .sweetShell: return 0.7
        case .moonRice: return 0.45
        case .seaGrapes: return 0.25
        default: return 0
        }
    }
}

private enum BanquetItemRole {
    case fresh
    case rotten
    case hazard
    case bumper
}

private enum BanquetItemKind: CaseIterable {
    case seaGrapes
    case moonRice
    case sweetShell
    case sourKelp
    case crackedBone
    case puffer
    case whirlpool

    var role: BanquetItemRole {
        switch self {
        case .seaGrapes, .moonRice, .sweetShell: return .fresh
        case .sourKelp, .crackedBone: return .rotten
        case .puffer: return .hazard
        case .whirlpool: return .bumper
        }
    }

    var icon: String {
        switch self {
        case .seaGrapes: return "🍇"
        case .moonRice: return "🍚"
        case .sweetShell: return "🐚"
        case .sourKelp: return "☠️"
        case .crackedBone: return "🦴"
        case .puffer: return "🐡"
        case .whirlpool: return "🌀"
        }
    }
}

private enum BanquetFeedbackTone {
    case fresh
    case growth
    case rotten
    case danger
    case bump
    case goal
}

private enum BanquetFeedbackEffect {
    case pop
    case spray
    case shake
    case huge
}

private struct BanquetFeedback {
    let text: String
    let position: CGPoint
    let tone: BanquetFeedbackTone
    let effect: BanquetFeedbackEffect
}

private struct BanquetFrame {
    var feedback: [BanquetFeedback] = []
}

private struct BanquetPlayer {
    var position: CGPoint
    var velocity: CGPoint = .zero
    var target: CGPoint?
    var stage = 1
    var gauge: CGFloat = 0
    var lives = BanquetRules.startLives
    var invulnerableTime: CGFloat = 0
    var wobble: CGFloat = 0

    var radius: CGFloat {
        BanquetRules.playerRadius(stage: stage)
    }
}

private struct BanquetEntity: Identifiable {
    let id = UUID()
    let kind: BanquetItemKind
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat
    var rotation: CGFloat
    var spin: CGFloat
    var hitCooldown: CGFloat = 0

    var role: BanquetItemRole {
        kind.role
    }
}

// MARK: - Motor do jogo

private final class BanquetEngine {
    let playRect: CGRect
    let goal: Int
    let special: Bool

    private(set) var player: BanquetPlayer
    private(set) var entities: [BanquetEntity] = []
    private(set) var score = 0
    private(set) var timeLeft = BanquetRules.startTime
    private(set) var challengeCompleted = false
    private(set) var finished = false

    private var elapsed: CGFloat = 0
    private var spawnTimer: CGFloat = 0

    init(playRect: CGRect, goal: Int, special: Bool) {
        self.playRect = playRect
        self.goal = goal
        self.special = special
        self.player = BanquetPlayer(position: CGPoint(x: playRect.midX, y: playRect.midY))
        spawnTimer = 0.25
    }

    func setTarget(_ point: CGPoint?) {
        guard let point else {
            player.target = nil
            return
        }
        player.target = clamped(point, inset: player.radius)
    }

    func update(dt rawDt: CGFloat) -> BanquetFrame {
        guard !finished else { return BanquetFrame() }
        let dt = min(max(rawDt, 0), 0.08)
        var frame = BanquetFrame()

        elapsed += dt
        timeLeft = max(0, timeLeft - dt)
        updatePlayer(dt: dt)
        updateEntities(dt: dt)
        spawnIfNeeded(dt: dt)
        resolveCollisions(feedback: &frame.feedback)
        removeOffscreenEntities()
        updateCompletion(feedback: &frame.feedback)

        if timeLeft <= 0 || player.lives <= 0 {
            finished = true
        }

        return frame
    }

    private func updatePlayer(dt: CGFloat) {
        player.invulnerableTime = max(0, player.invulnerableTime - dt)
        player.wobble += dt

        if let target = player.target {
            let delta = target - player.position
            let distance = max(1, hypot(delta.x, delta.y))
            let speed = BanquetRules.playerSpeed(stage: player.stage)
            let desired = CGPoint(x: delta.x / distance * speed,
                                  y: delta.y / distance * speed)
            let blend = min(1, dt * 8.5)
            player.velocity = CGPoint(x: player.velocity.x + (desired.x - player.velocity.x) * blend,
                                      y: player.velocity.y + (desired.y - player.velocity.y) * blend)
            if distance < 16 {
                player.velocity = CGPoint(x: player.velocity.x * 0.72,
                                          y: player.velocity.y * 0.72)
            }
        } else {
            player.velocity = CGPoint(x: player.velocity.x * 0.90,
                                      y: player.velocity.y * 0.90)
        }

        let next = CGPoint(x: player.position.x + player.velocity.x * dt,
                           y: player.position.y + player.velocity.y * dt)
        player.position = clamped(next, inset: player.radius)

        if player.position.x <= playRect.minX + player.radius || player.position.x >= playRect.maxX - player.radius {
            player.velocity.x *= -0.25
        }
        if player.position.y <= playRect.minY + player.radius || player.position.y >= playRect.maxY - player.radius {
            player.velocity.y *= -0.25
        }
    }

    private func updateEntities(dt: CGFloat) {
        for index in entities.indices {
            entities[index].position = CGPoint(x: entities[index].position.x + entities[index].velocity.x * dt,
                                               y: entities[index].position.y + entities[index].velocity.y * dt)
            entities[index].rotation += entities[index].spin * dt
            entities[index].hitCooldown = max(0, entities[index].hitCooldown - dt)
        }
    }

    private func spawnIfNeeded(dt: CGFloat) {
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }

        let difficulty = currentDifficulty()
        spawnTimer = BanquetRules.spawnInterval(difficulty: difficulty)
        spawnEntity(difficulty: difficulty)

        if difficulty > 0.64, Int.random(in: 0..<10) < 3 {
            spawnTimer *= 0.55
        }
    }

    private func resolveCollisions(feedback: inout [BanquetFeedback]) {
        var removeIds = Set<UUID>()

        for index in entities.indices {
            guard !removeIds.contains(entities[index].id) else { continue }
            let entity = entities[index]
            let distance = entity.position.distance(to: player.position)
            guard distance <= entity.radius + player.radius else { continue }

            switch entity.role {
            case .fresh:
                eatFresh(entity, feedback: &feedback)
                removeIds.insert(entity.id)
            case .rotten:
                eatRotten(entity, feedback: &feedback)
                removeIds.insert(entity.id)
            case .hazard:
                if player.invulnerableTime <= 0 {
                    loseLife(at: entity.position, text: "BAIACU!", tone: .danger, feedback: &feedback)
                }
                removeIds.insert(entity.id)
            case .bumper:
                guard entities[index].hitCooldown <= 0 else { continue }
                bump(from: entity, feedback: &feedback)
                entities[index].hitCooldown = BanquetRules.bumpCooldown
            }
        }

        if !removeIds.isEmpty {
            entities.removeAll { removeIds.contains($0.id) }
        }
    }

    private func eatFresh(_ entity: BanquetEntity, feedback: inout [BanquetFeedback]) {
        let gained = BanquetRules.freshPoints(for: entity.kind, stage: player.stage)
        let gauge = BanquetRules.freshGauge(for: entity.kind, stage: player.stage)
        score += gained
        player.gauge += gauge
        timeLeft = min(BanquetRules.maxTime, timeLeft + BanquetRules.timeBonus(for: entity.kind))

        feedback.append(BanquetFeedback(text: "+\(gained)",
                                        position: entity.position,
                                        tone: .fresh,
                                        effect: .pop))

        while player.gauge >= BanquetRules.gaugeLimit {
            player.gauge -= BanquetRules.gaugeLimit
            if player.stage < BanquetRules.maxStage {
                player.stage += 1
                let bonus = BanquetRules.growthBonus(stage: player.stage)
                score += bonus
                feedback.append(BanquetFeedback(text: "CRESCEU! +\(bonus)",
                                                position: player.position,
                                                tone: .growth,
                                                effect: .huge))
            } else {
                let bonus = 8
                score += bonus
                feedback.append(BanquetFeedback(text: "FOME CHEIA! +\(bonus)",
                                                position: player.position,
                                                tone: .growth,
                                                effect: .spray))
            }
        }
    }

    private func eatRotten(_ entity: BanquetEntity, feedback: inout [BanquetFeedback]) {
        let penalty = BanquetRules.rottenPointPenalty(stage: player.stage)
        let gaugePenalty = BanquetRules.rottenGaugePenalty(stage: player.stage)
        let hadGaugeRoom = player.gauge >= gaugePenalty * 0.28
        score = max(0, score - penalty)
        player.gauge = max(0, player.gauge - gaugePenalty)

        feedback.append(BanquetFeedback(text: "-\(penalty)",
                                        position: entity.position,
                                        tone: .rotten,
                                        effect: .shake))

        if !hadGaugeRoom && player.invulnerableTime <= 0 {
            loseLife(at: entity.position, text: "AZEDOU!", tone: .rotten, feedback: &feedback)
        }
    }

    private func bump(from entity: BanquetEntity, feedback: inout [BanquetFeedback]) {
        var push = player.position - entity.position
        let length = max(1, hypot(push.x, push.y))
        push = CGPoint(x: push.x / length, y: push.y / length)
        let impulse = 250 + CGFloat(player.stage) * 32
        player.velocity = CGPoint(x: player.velocity.x + push.x * impulse,
                                  y: player.velocity.y + push.y * impulse)
        player.position = clamped(CGPoint(x: player.position.x + push.x * 24,
                                          y: player.position.y + push.y * 24),
                                  inset: player.radius)
        feedback.append(BanquetFeedback(text: "EMPURRÃO!",
                                        position: player.position,
                                        tone: .bump,
                                        effect: .shake))
    }

    private func loseLife(at point: CGPoint,
                          text: String,
                          tone: BanquetFeedbackTone,
                          feedback: inout [BanquetFeedback]) {
        player.lives = max(0, player.lives - 1)
        player.invulnerableTime = BanquetRules.invulnerabilityTime
        player.gauge = max(0, player.gauge * 0.45)
        player.target = nil
        player.position = CGPoint(x: playRect.midX, y: playRect.midY)
        player.velocity = .zero
        feedback.append(BanquetFeedback(text: text,
                                        position: point,
                                        tone: tone,
                                        effect: .huge))
    }

    private func updateCompletion(feedback: inout [BanquetFeedback]) {
        guard !challengeCompleted, score >= goal else { return }
        challengeCompleted = true
        feedback.append(BanquetFeedback(text: "META!",
                                        position: CGPoint(x: playRect.midX, y: playRect.maxY - 32),
                                        tone: .goal,
                                        effect: .huge))
    }

    private func spawnEntity(difficulty: CGFloat) {
        let kind = randomKind(difficulty: difficulty)
        let role = kind.role
        let scale = BanquetRules.entityScale(stage: player.stage, difficulty: difficulty)
        let radius: CGFloat
        switch role {
        case .fresh: radius = CGFloat.random(in: 16...21) * scale
        case .rotten: radius = CGFloat.random(in: 17...23) * scale
        case .hazard: radius = CGFloat.random(in: 20...26) * scale
        case .bumper: radius = CGFloat.random(in: 26...34) * scale
        }

        let route = makeSpawnRoute(radius: radius, speed: BanquetRules.speed(for: role, difficulty: difficulty))
        entities.append(BanquetEntity(kind: kind,
                                      position: route.position,
                                      velocity: route.velocity,
                                      radius: radius,
                                      rotation: CGFloat.random(in: 0...(.pi * 2)),
                                      spin: CGFloat.random(in: -2.1...2.1)))
    }

    private func randomKind(difficulty: CGFloat) -> BanquetItemKind {
        let stagePressure = CGFloat(player.stage - 1) * 0.035
        let freshChance = (0.74 - difficulty * 0.18 - stagePressure).clamped(to: 0.44...0.76)
        let rottenChance = (0.16 + difficulty * 0.08 + stagePressure * 0.4).clamped(to: 0.14...0.30)
        let hazardChance = (0.06 + difficulty * 0.06 + stagePressure * 0.3).clamped(to: 0.05...0.18)
        let roll = CGFloat.random(in: 0...1)

        if roll < freshChance {
            return [.seaGrapes, .moonRice, .sweetShell].randomElement()!
        }
        if roll < freshChance + rottenChance {
            return [.sourKelp, .crackedBone].randomElement()!
        }
        if roll < freshChance + rottenChance + hazardChance {
            return .puffer
        }
        return .whirlpool
    }

    private func makeSpawnRoute(radius: CGFloat, speed: CGFloat) -> (position: CGPoint, velocity: CGPoint) {
        let edge = Int.random(in: 0..<4)
        let overscan = radius + 36
        let target = CGPoint(x: CGFloat.random(in: playRect.minX...playRect.maxX),
                             y: CGFloat.random(in: playRect.minY...playRect.maxY))
        let start: CGPoint

        switch edge {
        case 0:
            start = CGPoint(x: playRect.minX - overscan,
                            y: CGFloat.random(in: playRect.minY...playRect.maxY))
        case 1:
            start = CGPoint(x: playRect.maxX + overscan,
                            y: CGFloat.random(in: playRect.minY...playRect.maxY))
        case 2:
            start = CGPoint(x: CGFloat.random(in: playRect.minX...playRect.maxX),
                            y: playRect.maxY + overscan)
        default:
            start = CGPoint(x: CGFloat.random(in: playRect.minX...playRect.maxX),
                            y: playRect.minY - overscan)
        }

        let delta = target - start
        let length = max(1, hypot(delta.x, delta.y))
        let velocity = CGPoint(x: delta.x / length * speed,
                               y: delta.y / length * speed)
        return (start, velocity)
    }

    private func removeOffscreenEntities() {
        let padded = playRect.insetBy(dx: -90, dy: -90)
        entities.removeAll { !padded.contains($0.position) }
    }

    private func currentDifficulty() -> CGFloat {
        BanquetRules.difficulty(elapsed: elapsed, stage: player.stage, score: score)
    }

    private func clamped(_ point: CGPoint, inset: CGFloat) -> CGPoint {
        CGPoint(x: point.x.clamped(to: (playRect.minX + inset)...(playRect.maxX - inset)),
                y: point.y.clamped(to: (playRect.minY + inset)...(playRect.maxY - inset)))
    }
}

// MARK: - Overlay SpriteKit

final class BanquetOfTidesOverlay: SKNode {
    private let phase: MermaidPhase
    private let special: Bool
    private let shellRewardMultiplier: CGFloat
    private let onFinish: (ChallengeResult) -> Void
    private let goal: Int

    private let arenaWidth: CGFloat
    private let arenaOrigin: CGPoint
    private let playRect: CGRect
    private let engine: BanquetEngine

    private var entityNodes: [UUID: SKNode] = [:]
    private var finished = false
    private var pendingResult: ChallengeResult?

    private let arenaNode = SKNode()
    private let entityLayer = SKNode()
    private var playerMermaid: Mermaid?
    private var playerMermaidMoving = false
    private var playerMermaidDirectionKey = 0
    private var playerNode: SKNode!
    private var scoreLabel: SKLabelNode!
    private var objectiveLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var gaugeLabel: SKLabelNode!
    private var gaugeFill: SKShapeNode!
    private var timerBarFill: SKShapeNode!
    private var timerBarWidth: CGFloat = 0
    private var timerBarLeft: CGFloat = 0
    private var gaugeWidth: CGFloat = 0
    private var gaugeLeft: CGFloat = 0

    private enum Visual {
        static let darkTop = UIColor(red: 0.04, green: 0.18, blue: 0.26, alpha: 1)
        static let darkMid = UIColor(red: 0.03, green: 0.12, blue: 0.22, alpha: 1)
        static let darkBottom = UIColor(red: 0.02, green: 0.07, blue: 0.15, alpha: 1)
        static let feast = UIColor(red: 0.96, green: 0.68, blue: 0.30, alpha: 1)
        static let danger = UIColor(red: 0.96, green: 0.32, blue: 0.30, alpha: 1)
        static let mint = UIColor(red: 0.45, green: 0.88, blue: 0.70, alpha: 1)
        static let current = UIColor(red: 0.39, green: 0.73, blue: 0.95, alpha: 1)
    }

    init(size: CGSize,
         zone: DepthZone,
         phase: MermaidPhase,
         special: Bool,
         shellRewardMultiplier: CGFloat,
         giverDisplay: SKNode?,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.phase = phase
        self.special = special
        self.shellRewardMultiplier = shellRewardMultiplier
        self.onFinish = onFinish
        self.goal = BanquetRules.goal(for: zone, special: special)

        let availableWidth = max(320, size.width - 8)
        let availableHeight = max(360, size.height - 318)
        let resolvedArenaWidth = min(availableWidth, availableHeight, 540)
        self.arenaWidth = resolvedArenaWidth
        self.arenaOrigin = CGPoint(x: -resolvedArenaWidth / 2, y: -resolvedArenaWidth / 2 - 12)
        self.playRect = CGRect(x: arenaOrigin.x + 4,
                               y: arenaOrigin.y + 4,
                               width: resolvedArenaWidth - 8,
                               height: resolvedArenaWidth - 8)
        self.engine = BanquetEngine(playRect: playRect, goal: goal, special: special)

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, zone: zone, giverDisplay: giverDisplay)
        buildPlayer()
        updateStatusUI()
        GameAudio.shared.play(.tideCascade, volumeMultiplier: 0.62)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat) {
        guard !finished else { return }
        let frame = engine.update(dt: dt)
        syncEntityNodes()
        syncPlayerNode()
        updateStatusUI()
        frame.feedback.forEach(showFeedback)

        if engine.finished {
            finish()
        }
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, zone: DepthZone, giverDisplay: SKNode?) {
        addChild(makeBackdrop(size: size))

        let frame = makeFrame(size: CGSize(width: arenaWidth + 8, height: arenaWidth + 292))
        frame.position = CGPoint(x: 0, y: 22)
        addChild(frame)

        let subtitle = special
            ? "Banquete das Marés especial em \(zone.displayName)"
            : "Banquete das Marés em \(zone.displayName)"
        let header = ChallengeChrome.makeHeader(kind: .banquet,
                                                subtitle: subtitle,
                                                giverDisplay: giverDisplay,
                                                width: arenaWidth)
        header.position = CGPoint(x: 0, y: arenaWidth / 2 + 142)
        addChild(header)

        let chipWidth = (arenaWidth - 18) / 3
        let scoreChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "fork.knife",
                                                                     fallback: "*",
                                                                     color: Visual.feast,
                                                                     size: 21),
                                     title: "Pontos",
                                     value: "\(engine.score)",
                                     width: chipWidth,
                                     accent: Visual.feast)
        scoreChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth / 2,
                                           y: arenaWidth / 2 + 42)
        addChild(scoreChip.node)
        scoreLabel = scoreChip.valueLabel

        let objectiveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                         fallback: "o",
                                                                         color: GameUI.coral,
                                                                         size: 21),
                                         title: "Meta",
                                         value: objectiveText(),
                                         width: chipWidth,
                                         accent: GameUI.coral)
        objectiveChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth * 1.5 + 9,
                                              y: arenaWidth / 2 + 42)
        addChild(objectiveChip.node)
        objectiveLabel = objectiveChip.valueLabel

        let livesChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "heart.fill",
                                                                     fallback: "v",
                                                                     color: Visual.danger,
                                                                     size: 21),
                                     title: "Vidas",
                                     value: livesText(),
                                     width: chipWidth,
                                     accent: Visual.danger)
        livesChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth * 2.5 + 18,
                                          y: arenaWidth / 2 + 42)
        addChild(livesChip.node)
        livesLabel = livesChip.valueLabel

        timerBarWidth = arenaWidth - 34
        timerBarLeft = -timerBarWidth / 2
        addChild(makeTimerBar(width: timerBarWidth, y: arenaWidth / 2 - 26))

        arenaNode.addChild(makeArenaSurface(width: arenaWidth))
        addChild(arenaNode)

        entityLayer.zPosition = 20
        arenaNode.addChild(entityLayer)

        gaugeWidth = arenaWidth - 52
        gaugeLeft = -gaugeWidth / 2
        addChild(makeGaugeBar(width: gaugeWidth, y: arenaOrigin.y - 14))

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: 118,
                               height: 38)
        quit.name = "banquet_quit"
        quit.position = CGPoint(x: 0, y: arenaOrigin.y - 48)
        quit.zPosition = 45
        addChild(quit)
    }

    private func makeBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let texture = GameUI.gradientTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                             colors: [
                                                UIColor.black.withAlphaComponent(0.18),
                                                UIColor.lerp(GameUI.accent, GameUI.ink, 0.32).withAlphaComponent(0.34),
                                                UIColor.lerp(Visual.feast, GameUI.accent, 0.42).withAlphaComponent(0.18),
                                                UIColor.black.withAlphaComponent(0.34)
                                             ])
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.size = CGSize(width: size.width * 2, height: size.height * 2)
        backdrop.zPosition = -25
        node.addChild(backdrop)

        for i in 0..<14 {
            let y = size.height * 0.44 - CGFloat(i) * 42
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(i.isMultiple(of: 2) ? 24 : -16)),
                          controlPoint1: CGPoint(x: -size.width * 0.26, y: y - 34),
                          controlPoint2: CGPoint(x: size.width * 0.32, y: y + 46))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = UIColor.white.withAlphaComponent(0.046)
            wave.lineWidth = i.isMultiple(of: 3) ? 4 : 2
            wave.glowWidth = 8
            wave.zPosition = -12
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: i.isMultiple(of: 2) ? 22 : -18, y: 0, duration: 2.0),
                .moveBy(x: i.isMultiple(of: 2) ? -22 : 18, y: 0, duration: 2.0)
            ])))
        }

        for index in 0..<36 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...6.5))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.045)
            bubble.strokeColor = GameUI.palePaper.withAlphaComponent(0.18)
            bubble.lineWidth = 0.8
            bubble.position = CGPoint(x: CGFloat.random(in: -size.width * 0.56...size.width * 0.56),
                                      y: CGFloat.random(in: -size.height * 0.52...size.height * 0.52))
            bubble.zPosition = -8
            node.addChild(bubble)
            bubble.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.04),
                .group([
                    .moveBy(x: CGFloat.random(in: -20...20),
                            y: size.height * CGFloat.random(in: 0.28...0.52),
                            duration: Double.random(in: 3.4...6.0)),
                    .fadeOut(withDuration: Double.random(in: 3.4...6.0))
                ]),
                .moveBy(x: 0, y: -size.height * 0.55, duration: 0),
                .fadeAlpha(to: 0.9, duration: 0.16)
            ])))
        }

        return node
    }

    private func makeFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: Visual.feast.withAlphaComponent(0.50),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -8

        let dark = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                               cornerRadius: 22)
        dark.fillTexture = GameUI.gradientTexture(size: size,
                                                  colors: [Visual.darkTop, Visual.darkMid, Visual.darkBottom])
        dark.fillColor = .white
        dark.strokeColor = GameUI.palePaper.withAlphaComponent(0.15)
        dark.lineWidth = 1.1
        dark.zPosition = 1
        node.addChild(dark)

        let pulse = SKShapeNode(rectOf: CGSize(width: size.width - 22, height: size.height - 22),
                                cornerRadius: 18)
        pulse.fillColor = Visual.feast.withAlphaComponent(0.045)
        pulse.strokeColor = GameUI.gold.withAlphaComponent(0.13)
        pulse.lineWidth = 1
        pulse.zPosition = 2
        node.addChild(pulse)
        pulse.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.48, duration: 0.58),
            .fadeAlpha(to: 1.0, duration: 0.58)
        ])))

        return node
    }

    private func makeArenaSurface(width: CGFloat) -> SKNode {
        let node = SKNode()
        let center = CGPoint(x: 0, y: arenaOrigin.y + width / 2)
        node.zPosition = -18

        let back = SKShapeNode(circleOfRadius: width / 2 + 8)
        back.position = center
        back.fillTexture = GameUI.gradientTexture(size: CGSize(width: width + 20, height: width + 20),
                                                  colors: [
                                                    UIColor.lerp(Visual.darkTop, Visual.current, 0.18),
                                                    Visual.darkMid,
                                                    Visual.darkBottom
                                                  ])
        back.fillColor = .white
        back.strokeColor = Visual.feast.withAlphaComponent(0.44)
        back.lineWidth = 2
        back.glowWidth = 4
        node.addChild(back)

        for index in 0..<4 {
            let ring = SKShapeNode(circleOfRadius: width / 2 - CGFloat(index) * width * 0.12)
            ring.position = center
            ring.fillColor = .clear
            ring.strokeColor = (index.isMultiple(of: 2) ? GameUI.palePaper : Visual.current)
                .withAlphaComponent(index == 0 ? 0.18 : 0.08)
            ring.lineWidth = index == 0 ? 2 : 1
            node.addChild(ring)
        }

        for index in 0..<18 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            dot.fillColor = (index.isMultiple(of: 2) ? Visual.feast : Visual.current).withAlphaComponent(0.16)
            dot.strokeColor = .clear
            let angle = CGFloat(index) / 18 * .pi * 2
            let radius = CGFloat.random(in: width * 0.12...width * 0.43)
            dot.position = CGPoint(x: center.x + cos(angle) * radius,
                                   y: center.y + sin(angle) * radius)
            node.addChild(dot)
        }

        return node
    }

    private func makeInfoChip(iconNode: SKNode,
                              title: String,
                              value: String,
                              width: CGFloat,
                              accent: UIColor) -> (node: SKNode, valueLabel: SKLabelNode) {
        let node = SKNode()
        let size = CGSize(width: width, height: 50)
        let bg = SKShapeNode(rectOf: size, cornerRadius: 16)
        bg.fillTexture = GameUI.paperTexture(size: size, base: GameUI.paper)
        bg.fillColor = .white
        bg.strokeColor = accent.withAlphaComponent(0.54)
        bg.lineWidth = 1.35
        node.addChild(bg)

        iconNode.position = CGPoint(x: -width / 2 + 22, y: 0)
        node.addChild(iconNode)

        let titleLabel = SKLabelNode(text: title.uppercased())
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 8.0
        titleLabel.fontColor = GameUI.mutedInk
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -width / 2 + 42, y: 12)
        node.addChild(titleLabel)

        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Heavy"
        valueLabel.fontSize = 12.6
        valueLabel.fontColor = GameUI.ink
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.verticalAlignmentMode = .center
        valueLabel.preferredMaxLayoutWidth = width - 48
        valueLabel.numberOfLines = 1
        valueLabel.position = CGPoint(x: titleLabel.position.x, y: -8)
        node.addChild(valueLabel)

        return (node, valueLabel)
    }

    private func makeTimerBar(width: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 35

        let back = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        back.fillColor = GameUI.line.withAlphaComponent(0.13)
        back.strokeColor = GameUI.line.withAlphaComponent(0.22)
        back.lineWidth = 1
        node.addChild(back)

        timerBarFill = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        timerBarFill.fillColor = Visual.current.withAlphaComponent(0.82)
        timerBarFill.strokeColor = .clear
        timerBarFill.glowWidth = 2
        timerBarFill.zPosition = 1
        node.addChild(timerBarFill)

        timerLabel = SKLabelNode(text: timerText())
        timerLabel.fontName = "AvenirNext-DemiBold"
        timerLabel.fontSize = 11
        timerLabel.fontColor = GameUI.palePaper
        timerLabel.verticalAlignmentMode = .center
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.zPosition = 2
        node.addChild(timerLabel)

        return node
    }

    private func makeGaugeBar(width: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 40

        let back = SKShapeNode(rectOf: CGSize(width: width, height: 26), cornerRadius: 13)
        back.fillColor = GameUI.ink.withAlphaComponent(0.22)
        back.strokeColor = Visual.feast.withAlphaComponent(0.42)
        back.lineWidth = 1.2
        node.addChild(back)

        gaugeFill = SKShapeNode(rectOf: CGSize(width: width, height: 26), cornerRadius: 13)
        gaugeFill.fillColor = Visual.feast.withAlphaComponent(0.84)
        gaugeFill.strokeColor = .clear
        gaugeFill.glowWidth = 3
        gaugeFill.zPosition = 1
        node.addChild(gaugeFill)

        gaugeLabel = SKLabelNode(text: "Fome 0%")
        gaugeLabel.fontName = "AvenirNext-DemiBold"
        gaugeLabel.fontSize = 12
        gaugeLabel.fontColor = GameUI.palePaper
        gaugeLabel.verticalAlignmentMode = .center
        gaugeLabel.horizontalAlignmentMode = .center
        gaugeLabel.zPosition = 2
        node.addChild(gaugeLabel)

        return node
    }

    private func buildPlayer() {
        playerNode = makePlayerNode()
        playerNode.position = engine.player.position
        playerNode.zPosition = 50
        arenaNode.addChild(playerNode)
    }

    private func makePlayerNode() -> SKNode {
        let node = SKNode()
        let radius = BanquetRules.basePlayerRadius

        let shadow = SKShapeNode(ellipseOf: CGSize(width: radius * 1.9, height: radius * 0.55))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.24)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -radius * 0.64)
        shadow.zPosition = -3
        node.addChild(shadow)

        let aura = SKShapeNode(circleOfRadius: radius * 1.18)
        aura.fillColor = Visual.feast.withAlphaComponent(0.12)
        aura.strokeColor = Visual.feast.withAlphaComponent(0.32)
        aura.lineWidth = 1.2
        aura.glowWidth = 5
        aura.zPosition = -2
        node.addChild(aura)
        aura.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.46),
            .scale(to: 0.96, duration: 0.46)
        ])))

        let mermaid = Mermaid()
        if phase != .egg {
            mermaid.setForm(for: phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.swing)
        playerMermaidMoving = true
        let scale = ChallengeChrome.fitScale(for: mermaid.base, targetHeight: radius * 2.25)
        mermaid.base.setScale(scale)
        mermaid.base.zPosition = 4
        mermaid.base.position = CGPoint(x: 0, y: -radius * 0.08)
        node.addChild(mermaid.base)
        playerMermaid = mermaid

        return node
    }

    // MARK: - Sincronia visual

    private func syncPlayerNode() {
        let player = engine.player
        playerNode.position = player.position
        let targetScale = player.radius / BanquetRules.basePlayerRadius
        let wobble = sin(player.wobble * 7.5) * 0.035
        playerNode.xScale = targetScale * (1 + wobble)
        playerNode.yScale = targetScale * (1 - wobble)
        playerNode.alpha = player.invulnerableTime > 0
            ? (sin(player.invulnerableTime * 24) > 0 ? 0.56 : 1.0)
            : 1.0
        updateMermaidDirection(for: player.velocity)
    }

    private func updateMermaidDirection(for velocity: CGPoint) {
        guard let mermaid = playerMermaid else { return }
        let movementThreshold: CGFloat = 24
        guard abs(velocity.x) > movementThreshold || abs(velocity.y) > movementThreshold else {
            if playerMermaidMoving {
                mermaid.setAnimationMode(.idle)
                playerMermaidMoving = false
                playerMermaidDirectionKey = 0
            }
            return
        }

        if !playerMermaidMoving {
            mermaid.setAnimationMode(.swing)
            playerMermaidMoving = true
        }

        let directionKey: Int
        let direction: Mermaid.Direction
        if abs(velocity.x) > abs(velocity.y) {
            directionKey = velocity.x >= 0 ? 1 : 2
            direction = velocity.x >= 0 ? .right : .left
        } else {
            directionKey = velocity.y >= 0 ? 3 : 4
            direction = velocity.y >= 0 ? .up : .down
        }

        if directionKey != playerMermaidDirectionKey {
            mermaid.setVisualDirection(direction)
            playerMermaidDirectionKey = directionKey
        }
    }

    private func syncEntityNodes() {
        let ids = Set(engine.entities.map(\.id))
        let staleIds = entityNodes.keys.filter { !ids.contains($0) }
        for id in staleIds {
            guard let node = entityNodes[id] else { continue }
            node.removeFromParent()
            entityNodes[id] = nil
        }

        for entity in engine.entities {
            let node: SKNode
            if let existing = entityNodes[entity.id] {
                node = existing
            } else {
                node = makeEntityNode(entity)
                entityLayer.addChild(node)
                entityNodes[entity.id] = node
            }
            node.position = entity.position
            node.zRotation = entity.rotation
        }
    }

    private func makeEntityNode(_ entity: BanquetEntity) -> SKNode {
        let node = SKNode()
        node.zPosition = entity.role == .bumper ? 18 : 22

        let color = color(for: entity.kind)
        let radius = entity.radius
        let glow = SKShapeNode(circleOfRadius: radius * 1.06)
        glow.fillColor = color.withAlphaComponent(entity.role == .hazard ? 0.24 : 0.16)
        glow.strokeColor = .clear
        glow.glowWidth = entity.role == .hazard ? 9 : 5
        glow.zPosition = -2
        node.addChild(glow)

        let body = entity.role == .bumper
            ? SKShapeNode(circleOfRadius: radius * 0.92)
            : SKShapeNode(circleOfRadius: radius * 0.78)
        body.fillTexture = GameUI.gradientTexture(size: CGSize(width: radius * 2, height: radius * 2),
                                                  colors: [
                                                    UIColor.lerp(color, .white, 0.34),
                                                    color,
                                                    UIColor.lerp(color, Visual.darkBottom, 0.35)
                                                  ])
        body.fillColor = .white
        body.strokeColor = UIColor.white.withAlphaComponent(entity.role == .rotten ? 0.34 : 0.56)
        body.lineWidth = 1.2
        body.glowWidth = entity.role == .bumper ? 5 : 2
        node.addChild(body)

        let icon = SKLabelNode(text: entity.kind.icon)
        icon.fontName = "AppleColorEmoji"
        icon.fontSize = radius * (entity.role == .bumper ? 0.90 : 0.98)
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: -radius * 0.03)
        icon.zPosition = 5
        node.addChild(icon)

        if entity.role == .hazard {
            let warning = SKShapeNode(circleOfRadius: radius * 1.16)
            warning.fillColor = .clear
            warning.strokeColor = Visual.danger.withAlphaComponent(0.54)
            warning.lineWidth = 1.6
            warning.glowWidth = 3
            warning.zPosition = -1
            node.addChild(warning)
            warning.run(.repeatForever(.sequence([
                .scale(to: 1.16, duration: 0.24),
                .scale(to: 0.96, duration: 0.24)
            ])))
        }

        node.run(.repeatForever(.sequence([
            .scale(to: CGFloat.random(in: 1.02...1.07), duration: Double.random(in: 0.54...0.86)),
            .scale(to: 1.0, duration: Double.random(in: 0.54...0.86))
        ])))

        return node
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if finished {
            handleFinishedTap(at: location)
            return
        }

        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "banquet_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish()
                return
            }
            node = current.parent
        }

        engine.setTarget(touch.location(in: arenaNode))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let touch = touches.first else { return }
        engine.setTarget(touch.location(in: arenaNode))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        engine.setTarget(nil)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        engine.setTarget(nil)
    }

    // MARK: - Feedback

    private func showFeedback(_ feedback: BanquetFeedback) {
        let color = color(for: feedback.tone)
        showFloatingLabel(text: feedback.text,
                          at: feedback.position,
                          color: color,
                          size: feedback.effect == .huge ? 30 : 23,
                          drift: feedback.effect == .huge
                            ? CGPoint(x: CGFloat.random(in: -20...20), y: 118)
                            : CGPoint(x: CGFloat.random(in: -18...18), y: 78))

        switch feedback.effect {
        case .pop:
            spawnSparkles(at: feedback.position, color: color, count: 8)
            GameAudio.shared.play(.tideMatch, cooldownOverride: 0.05)
        case .spray:
            spawnSparkles(at: feedback.position, color: color, count: 16)
            GameAudio.shared.play(.tideCascade, volumeMultiplier: 1.04, cooldownOverride: 0.08)
        case .shake:
            spawnSparkles(at: feedback.position, color: color, count: 10)
            arenaNode.run(.sequence([
                .moveBy(x: -7, y: 2, duration: 0.04),
                .moveBy(x: 14, y: -4, duration: 0.08),
                .moveBy(x: -7, y: 2, duration: 0.04)
            ]))
            GameAudio.shared.play(feedback.tone == .bump ? .climbBounce : .tideInvalid)
        case .huge:
            spawnSparkles(at: feedback.position, color: color, count: 22)
            makeScreenFlash(color: color)
            GameAudio.shared.play(feedback.tone == .goal ? .tideGoal : .tideCascade,
                                  volumeMultiplier: 1.08,
                                  cooldownOverride: 0.05)
        }
    }

    private func showFloatingLabel(text: String,
                                   at point: CGPoint,
                                   color: UIColor,
                                   size: CGFloat,
                                   drift: CGPoint) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = convert(point, from: arenaNode)
        label.zPosition = 140
        label.setScale(0.62)
        addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: drift.x, y: drift.y, duration: 0.78),
                .fadeOut(withDuration: 0.78),
                .scale(to: 1.18, duration: 0.20)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnSparkles(at point: CGPoint, color: UIColor, count: Int) {
        let converted = convert(point, from: arenaNode)
        for index in 0..<count {
            let sparkle = SKLabelNode(text: index.isMultiple(of: 2) ? "✦" : "•")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = CGFloat.random(in: 10...20)
            sparkle.fontColor = UIColor.lerp(color, .white, CGFloat.random(in: 0.16...0.50))
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = converted
            sparkle.zPosition = 124
            addChild(sparkle)

            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat.random(in: -0.32...0.32)
            let distance = CGFloat.random(in: 28...64)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance + CGFloat.random(in: 20...48),
                            duration: 0.44),
                    .rotate(byAngle: CGFloat.random(in: -1.8...1.8), duration: 0.44),
                    .fadeOut(withDuration: 0.44),
                    .scale(to: CGFloat.random(in: 0.25...0.55), duration: 0.44)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func makeScreenFlash(color: UIColor) {
        let flash = SKShapeNode(circleOfRadius: arenaWidth * 0.54)
        flash.position = CGPoint(x: 0, y: arenaOrigin.y + arenaWidth / 2)
        flash.fillColor = color.withAlphaComponent(0.14)
        flash.strokeColor = color.withAlphaComponent(0.54)
        flash.lineWidth = 2
        flash.glowWidth = 12
        flash.zPosition = 112
        addChild(flash)
        flash.run(.sequence([
            .group([
                .scale(to: 1.16, duration: 0.30),
                .fadeOut(withDuration: 0.30)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Estado

    private func updateStatusUI() {
        guard scoreLabel != nil else { return }
        scoreLabel.text = "\(engine.score)"
        objectiveLabel.text = objectiveText()
        livesLabel.text = livesText()
        updateTimerUI()
        updateGaugeUI()
    }

    private func updateTimerUI() {
        guard timerLabel != nil, timerBarFill != nil else { return }
        timerLabel.text = timerText()
        let progress = (engine.timeLeft / BanquetRules.startTime).clamped(to: 0...1)
        let visible = max(0.012, progress)
        timerBarFill.xScale = visible
        timerBarFill.position = CGPoint(x: timerBarLeft + timerBarWidth * visible / 2, y: 0)
        timerBarFill.fillColor = progress < 0.24
            ? Visual.danger.withAlphaComponent(0.84)
            : Visual.current.withAlphaComponent(0.82)
    }

    private func updateGaugeUI() {
        guard gaugeLabel != nil, gaugeFill != nil else { return }
        let player = engine.player
        let progress = (player.gauge / BanquetRules.gaugeLimit).clamped(to: 0...1)
        let visible = max(0.012, progress)
        gaugeFill.xScale = visible
        gaugeFill.position = CGPoint(x: gaugeLeft + gaugeWidth * visible / 2, y: 0)
        gaugeFill.fillColor = progress > 0.82
            ? Visual.mint.withAlphaComponent(0.86)
            : Visual.feast.withAlphaComponent(0.84)
        gaugeLabel.text = "Fome \(Int((progress * 100).rounded()))%  •  Tamanho \(player.stage)"
    }

    private func objectiveText() -> String {
        engine.challengeCompleted ? "Completa" : "\(engine.score)/\(goal)"
    }

    private func livesText() -> String {
        "\(engine.player.lives)/\(BanquetRules.startLives)"
    }

    private func timerText() -> String {
        "\(max(0, Int(ceil(engine.timeLeft))))s"
    }

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .banquet,
                                                          reachedTarget: reached ?? engine.challengeCompleted,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: engine.score,
                                                      multiplier: shellRewardMultiplier)
    }

    // MARK: - Fim

    private func finish() {
        guard !finished else { return }
        finished = true
        engine.setTarget(nil)
        GameAudio.shared.play(engine.challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = engine.challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .banquet,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 150
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let titleLabel = SKLabelNode(text: reached ? "Banquete completo!" : "Quase virou banquete!")
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = GameUI.ink
        titleLabel.position = CGPoint(x: 0, y: 60)
        content.addChild(titleLabel)

        let scoreLine = SKLabelNode(text: "Pontos feitos: \(engine.score)")
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.position = CGPoint(x: 0, y: 24)
        content.addChild(scoreLine)

        let rewardLine = SKLabelNode(text: "Convertendo pontos...")
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.position = CGPoint(x: 0, y: -10)
        content.addChild(rewardLine)
        ChallengeChrome.animatePointConversion(label: rewardLine, points: engine.score, pearls: pearls)

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "banquet_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        content.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .banquet,
                                        points: engine.score,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        special: special,
                                        isHatching: false)
    }

    private func makeResultPanel(reached: Bool) -> SKNode {
        let resultTint = reached
            ? GameUI.algae.withAlphaComponent(0.82)
            : GameUI.coral.withAlphaComponent(0.82)
        let panel = GameUI.card(size: CGSize(width: 290, height: 220),
                                cornerRadius: 24,
                                tint: resultTint,
                                baseColors: [UIColor.lerp(GameUI.palePaper, resultTint, 0.28)])
        let wash = SKShapeNode(rectOf: CGSize(width: 278, height: 208), cornerRadius: 20)
        wash.fillColor = resultTint.withAlphaComponent(0.08)
        wash.strokeColor = .clear
        wash.zPosition = 0.5
        panel.addChild(wash)
        return panel
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "banquet_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }

    // MARK: - Cores

    private func color(for kind: BanquetItemKind) -> UIColor {
        switch kind {
        case .seaGrapes: return GameUI.algae
        case .moonRice: return GameUI.palePaper
        case .sweetShell: return Visual.feast
        case .sourKelp: return GameUI.coral
        case .crackedBone: return UIColor(red: 0.73, green: 0.62, blue: 0.54, alpha: 1)
        case .puffer: return Visual.danger
        case .whirlpool: return Visual.current
        }
    }

    private func color(for tone: BanquetFeedbackTone) -> UIColor {
        switch tone {
        case .fresh: return Visual.mint
        case .growth: return Visual.feast
        case .rotten: return GameUI.coral
        case .danger: return Visual.danger
        case .bump: return Visual.current
        case .goal: return GameUI.gold
        }
    }
}
