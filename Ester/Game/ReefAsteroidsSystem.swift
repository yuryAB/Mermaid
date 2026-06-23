//
//  ReefAsteroidsSystem.swift
//  Ester
//
//  Desafio: Ruptura do Recife. Arena infinita inspirada em Asteroids:
//  pedras e corais flutuam, quebram em partes menores e a maré acelera
//  a cada minuto para sustentar high score.
//

import Foundation
import SpriteKit

// MARK: - Regras puras

private enum ReefAsteroidsRules {
    static let startLives = 3
    static let comboWindow: CGFloat = 2.4
    static let playerRadius: CGFloat = 23
    static let playerSpeed: CGFloat = 246
    static let playerDrag: CGFloat = 7.0
    static let invulnerabilityTime: CGFloat = 1.55
    static let projectileRadius: CGFloat = 5.5
    static let projectileSpeed: CGFloat = 620
    static let projectileLife: CGFloat = 1.0
    static let fireInterval: CGFloat = 0.28
    static let fragmentGhostTime: CGFloat = 0.78

    static func milestoneScore(for zone: DepthZone, special: Bool) -> Int {
        GameBalance.challengeGoalFallback(for: .reefAsteroids, zone: zone, special: special)
    }

    static func spawnCount(for wave: Int, special: Bool) -> Int {
        min(8, 3 + max(0, wave - 1) / 2 + (special ? 1 : 0))
    }

    static func tideMultiplier(elapsed: CGFloat, wave: Int, special: Bool) -> CGFloat {
        let minutePressure = floor(elapsed / 60) * 0.10
        let wavePressure = CGFloat(max(0, wave - 1)) * 0.025
        return 1 + minutePressure + wavePressure + (special ? 0.12 : 0)
    }

    static func radius(for size: ReefRockSize) -> CGFloat {
        switch size {
        case .large: return 39
        case .medium: return 26
        case .small: return 15
        }
    }

    static func points(for size: ReefRockSize) -> Int {
        switch size {
        case .large: return 20
        case .medium: return 50
        case .small: return 100
        }
    }

    static func speed(for size: ReefRockSize, tideMultiplier: CGFloat) -> CGFloat {
        let base: CGFloat
        switch size {
        case .large: base = 48
        case .medium: base = 70
        case .small: base = 96
        }
        return base * tideMultiplier + CGFloat.random(in: -8...14)
    }

    static func comboBonus(streak: Int) -> Int {
        guard streak >= 3 else { return 0 }
        return min(80, (streak - 2) * 6)
    }

    static func waveBonus(wave: Int) -> Int {
        150 + wave * 40
    }

}

private enum ReefRockSize: CaseIterable {
    case large
    case medium
    case small

    var child: ReefRockSize? {
        switch self {
        case .large: return .medium
        case .medium: return .small
        case .small: return nil
        }
    }
}

private enum ReefRockMotif: CaseIterable {
    case basalt
    case roseCoral
    case goldenCoral
    case algaeStone
}

private enum ReefFeedbackEffect {
    case score
    case combo
    case crack
    case hit
    case wave
    case surge
}

private struct ReefFeedback {
    let text: String
    let position: CGPoint
    let color: UIColor
    let effect: ReefFeedbackEffect
}

private struct ReefFrame {
    var feedback: [ReefFeedback] = []
}

private struct ReefPlayer {
    var position: CGPoint
    var velocity: CGPoint = .zero
    var controlVector: CGPoint = .zero
    var aimVector = CGPoint(x: 0, y: 1)
    var lives = ReefAsteroidsRules.startLives
    var invulnerableTime: CGFloat = 0
    var fireCooldown: CGFloat = 0
    var wobble: CGFloat = 0
}

private struct ReefProjectile: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var lifeTime: CGFloat = ReefAsteroidsRules.projectileLife
}

private struct ReefRock: Identifiable {
    let id = UUID()
    let size: ReefRockSize
    let motif: ReefRockMotif
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat
    var rotation: CGFloat
    var spin: CGFloat
    var ghostTime: CGFloat = 0
}

// MARK: - Motor do jogo

private final class ReefAsteroidsEngine {
    let playRect: CGRect
    let goal: Int
    let special: Bool

    private(set) var player: ReefPlayer
    private(set) var rocks: [ReefRock] = []
    private(set) var projectiles: [ReefProjectile] = []
    private(set) var score = 0
    private(set) var wave = 1
    private(set) var elapsed: CGFloat = 0
    private(set) var challengeCompleted = false
    private(set) var finished = false
    private(set) var aimTargetId: UUID?

    private var comboTimeLeft: CGFloat = 0
    private var streak = 0
    private var minuteTier = 0

    init(playRect: CGRect, goal: Int, special: Bool) {
        self.playRect = playRect
        self.goal = goal
        self.special = special
        self.player = ReefPlayer(position: CGPoint(x: playRect.midX, y: playRect.midY))
        spawnWave()
    }

    var tideMultiplier: CGFloat {
        ReefAsteroidsRules.tideMultiplier(elapsed: elapsed, wave: wave, special: special)
    }

    var currentStreak: Int { streak }

    var currentAimTarget: ReefRock? {
        guard let aimTargetId else { return nil }
        return rocks.first { $0.id == aimTargetId }
    }

    func setControlVector(_ vector: CGPoint?) {
        guard let vector else {
            player.controlVector = .zero
            return
        }
        let length = hypot(vector.x, vector.y)
        guard length > 0.01 else {
            player.controlVector = .zero
            return
        }
        let intensity = min(1, length)
        let direction = CGPoint(x: vector.x / length, y: vector.y / length)
        player.controlVector = CGPoint(x: direction.x * intensity, y: direction.y * intensity)
        player.aimVector = direction
    }

    func update(dt rawDt: CGFloat) -> ReefFrame {
        guard !finished else { return ReefFrame() }
        let dt = min(max(rawDt, 0), 0.08)
        var frame = ReefFrame()

        elapsed += dt
        comboTimeLeft = max(0, comboTimeLeft - dt)
        updateMinutePressure(feedback: &frame.feedback)
        updatePlayer(dt: dt)
        updateRocks(dt: dt)
        updateAimTarget()
        fireIfNeeded(dt: dt)
        updateProjectiles(dt: dt)
        resolveProjectileHits(feedback: &frame.feedback)
        resolvePlayerCollision(feedback: &frame.feedback)
        updateAimTarget()
        updateCompletion(feedback: &frame.feedback)
        advanceWaveIfCleared(feedback: &frame.feedback)

        if player.lives <= 0 {
            finished = true
        }
        return frame
    }

    private func updateMinutePressure(feedback: inout [ReefFeedback]) {
        let nextTier = Int(floor(elapsed / 60))
        guard nextTier > minuteTier else { return }
        minuteTier = nextTier
        feedback.append(ReefFeedback(text: "MARÉ +\(minuteTier * 10)%",
                                     position: CGPoint(x: playRect.midX, y: playRect.maxY - 46),
                                     color: Visual.current,
                                     effect: .surge))
    }

    private func updatePlayer(dt: CGFloat) {
        player.invulnerableTime = max(0, player.invulnerableTime - dt)
        player.fireCooldown = max(0, player.fireCooldown - dt)
        player.wobble += dt

        let controlLength = hypot(player.controlVector.x, player.controlVector.y)
        if controlLength > 0.04 {
            let desired = CGPoint(x: player.controlVector.x * ReefAsteroidsRules.playerSpeed,
                                  y: player.controlVector.y * ReefAsteroidsRules.playerSpeed)
            let blend = min(1, dt * ReefAsteroidsRules.playerDrag)
            player.velocity = CGPoint(x: player.velocity.x + (desired.x - player.velocity.x) * blend,
                                      y: player.velocity.y + (desired.y - player.velocity.y) * blend)
        } else {
            player.velocity = CGPoint(x: player.velocity.x * 0.91,
                                      y: player.velocity.y * 0.91)
        }

        let next = CGPoint(x: player.position.x + player.velocity.x * dt,
                           y: player.position.y + player.velocity.y * dt)
        player.position = clampedPlayerPosition(next)
    }

    private func updateAimTarget() {
        aimTargetId = selectTarget()?.id
    }

    private func fireIfNeeded(dt: CGFloat) {
        guard player.fireCooldown <= 0, let target = currentAimTarget else { return }
        let delta = target.position - player.position
        let distance = max(1, hypot(delta.x, delta.y))
        let direction = CGPoint(x: delta.x / distance, y: delta.y / distance)
        player.aimVector = direction

        let muzzle = CGPoint(x: player.position.x + direction.x * (ReefAsteroidsRules.playerRadius + 8),
                             y: player.position.y + direction.y * (ReefAsteroidsRules.playerRadius + 8))
        projectiles.append(ReefProjectile(position: muzzle,
                                          velocity: CGPoint(x: direction.x * ReefAsteroidsRules.projectileSpeed,
                                                            y: direction.y * ReefAsteroidsRules.projectileSpeed)))
        player.fireCooldown = ReefAsteroidsRules.fireInterval
    }

    private func updateProjectiles(dt: CGFloat) {
        for index in projectiles.indices {
            projectiles[index].position = CGPoint(x: projectiles[index].position.x + projectiles[index].velocity.x * dt,
                                                  y: projectiles[index].position.y + projectiles[index].velocity.y * dt)
            projectiles[index].lifeTime -= dt
        }
        let padded = playRect.insetBy(dx: -20, dy: -20)
        projectiles.removeAll { $0.lifeTime <= 0 || !padded.contains($0.position) }
    }

    private func updateRocks(dt: CGFloat) {
        for index in rocks.indices {
            rocks[index].position = wrapped(CGPoint(x: rocks[index].position.x + rocks[index].velocity.x * dt,
                                                    y: rocks[index].position.y + rocks[index].velocity.y * dt),
                                            inset: rocks[index].radius)
            rocks[index].rotation += rocks[index].spin * dt
            rocks[index].ghostTime = max(0, rocks[index].ghostTime - dt)
        }
    }

    private func selectTarget() -> ReefRock? {
        guard !rocks.isEmpty else { return nil }
        return rocks.min { lhs, rhs in
            targetScore(for: lhs) < targetScore(for: rhs)
        }
    }

    private func targetScore(for rock: ReefRock) -> CGFloat {
        let delta = player.position - rock.position
        let distance = max(1, hypot(delta.x, delta.y))
        let directionToPlayer = CGPoint(x: delta.x / distance, y: delta.y / distance)
        let relativeVelocity = CGPoint(x: rock.velocity.x - player.velocity.x,
                                       y: rock.velocity.y - player.velocity.y)
        let closingSpeed = max(0, relativeVelocity.x * directionToPlayer.x + relativeVelocity.y * directionToPlayer.y)
        let sizePressure: CGFloat
        switch rock.size {
        case .large: sizePressure = 10
        case .medium: sizePressure = 20
        case .small: sizePressure = 34
        }
        let ghostPenalty: CGFloat = rock.ghostTime > 0 ? 120 : 0
        return distance - closingSpeed * 0.85 - sizePressure + ghostPenalty
    }

    private func resolveProjectileHits(feedback: inout [ReefFeedback]) {
        var removeProjectileIds = Set<UUID>()
        var removeRockIds = Set<UUID>()
        var additions: [ReefRock] = []

        for projectile in projectiles {
            guard !removeProjectileIds.contains(projectile.id) else { continue }
            guard let rock = rocks.first(where: { candidate in
                !removeRockIds.contains(candidate.id)
                    && projectile.position.distance(to: candidate.position) <= candidate.radius + ReefAsteroidsRules.projectileRadius
            }) else { continue }

            removeProjectileIds.insert(projectile.id)
            removeRockIds.insert(rock.id)
            additions.append(contentsOf: split(rock))
            scoreBreak(rock, feedback: &feedback)
        }

        if !removeProjectileIds.isEmpty {
            projectiles.removeAll { removeProjectileIds.contains($0.id) }
        }
        if !removeRockIds.isEmpty {
            rocks.removeAll { removeRockIds.contains($0.id) }
            rocks.append(contentsOf: additions)
        }
    }

    private func resolvePlayerCollision(feedback: inout [ReefFeedback]) {
        guard player.invulnerableTime <= 0 else { return }
        guard let rock = rocks.first(where: {
            $0.ghostTime <= 0
                && $0.position.distance(to: player.position) <= $0.radius + ReefAsteroidsRules.playerRadius * 0.72
        }) else { return }

        player.lives = max(0, player.lives - 1)
        player.invulnerableTime = ReefAsteroidsRules.invulnerabilityTime
        player.controlVector = .zero
        player.velocity = .zero
        player.position = CGPoint(x: playRect.midX, y: playRect.midY)
        streak = 0
        comboTimeLeft = 0

        rocks.removeAll { $0.id == rock.id }
        rocks.append(contentsOf: split(rock))

        feedback.append(ReefFeedback(text: player.lives > 0 ? "TRINCOU!" : "FIM DA MARÉ!",
                                     position: rock.position,
                                     color: Visual.danger,
                                     effect: .hit))
    }

    private func scoreBreak(_ rock: ReefRock, feedback: inout [ReefFeedback]) {
        if comboTimeLeft > 0 {
            streak += 1
        } else {
            streak = 1
        }
        comboTimeLeft = ReefAsteroidsRules.comboWindow

        let base = ReefAsteroidsRules.points(for: rock.size)
        let combo = ReefAsteroidsRules.comboBonus(streak: streak)
        let gained = base + combo
        score += gained

        feedback.append(ReefFeedback(text: "+\(gained)",
                                     position: rock.position,
                                     color: color(for: rock.motif),
                                     effect: rock.size == .small ? .score : .crack))
        if streak == 3 || (streak > 3 && streak.isMultiple(of: 4)) {
            feedback.append(ReefFeedback(text: "COMBO x\(streak)",
                                         position: CGPoint(x: playRect.midX, y: playRect.maxY - 86),
                                         color: streak >= 9 ? Visual.hot : Visual.gold,
                                         effect: .combo))
        }
    }

    private func updateCompletion(feedback: inout [ReefFeedback]) {
        guard !challengeCompleted, score >= goal else { return }
        challengeCompleted = true
        feedback.append(ReefFeedback(text: "META!",
                                     position: CGPoint(x: playRect.midX, y: playRect.maxY - 52),
                                     color: Visual.gold,
                                     effect: .surge))
    }

    private func advanceWaveIfCleared(feedback: inout [ReefFeedback]) {
        guard rocks.isEmpty, !finished else { return }
        let bonus = ReefAsteroidsRules.waveBonus(wave: wave)
        score += bonus
        feedback.append(ReefFeedback(text: "NOVA ONDA! +\(bonus)",
                                     position: CGPoint(x: playRect.midX, y: playRect.midY),
                                     color: Visual.current,
                                     effect: .wave))
        wave += 1
        spawnWave()
    }

    private func spawnWave() {
        let count = ReefAsteroidsRules.spawnCount(for: wave, special: special)
        for index in 0..<count {
            rocks.append(makeRock(size: .large, index: index, count: count))
        }
    }

    private func makeRock(size: ReefRockSize, index: Int, count: Int) -> ReefRock {
        let radius = ReefAsteroidsRules.radius(for: size)
        let angle = (CGFloat(index) / CGFloat(max(1, count))) * .pi * 2 + CGFloat.random(in: -0.45...0.45)
        let distance = min(playRect.width, playRect.height) * CGFloat.random(in: 0.32...0.46)
        let center = CGPoint(x: playRect.midX, y: playRect.midY)
        var position = CGPoint(x: center.x + cos(angle) * distance,
                               y: center.y + sin(angle) * distance)
        position.x = position.x.clamped(to: (playRect.minX + radius)...(playRect.maxX - radius))
        position.y = position.y.clamped(to: (playRect.minY + radius)...(playRect.maxY - radius))

        let driftAngle = angle + .pi / 2 + CGFloat.random(in: -0.80...0.80)
        let speed = ReefAsteroidsRules.speed(for: size, tideMultiplier: tideMultiplier)
        return ReefRock(size: size,
                        motif: ReefRockMotif.allCases.randomElement()!,
                        position: position,
                        velocity: CGPoint(x: cos(driftAngle) * speed, y: sin(driftAngle) * speed),
                        radius: radius,
                        rotation: CGFloat.random(in: 0...(.pi * 2)),
                        spin: CGFloat.random(in: -1.5...1.5))
    }

    private func split(_ rock: ReefRock) -> [ReefRock] {
        guard let child = rock.size.child else { return [] }
        let childRadius = ReefAsteroidsRules.radius(for: child)
        let baseAngle = atan2(rock.velocity.y, rock.velocity.x)
        let awayFromPlayer = rock.position - player.position
        let awayLength = hypot(awayFromPlayer.x, awayFromPlayer.y)
        let safeAngle = awayLength > 1 ? atan2(awayFromPlayer.y, awayFromPlayer.x) : baseAngle
        let childSpeed = ReefAsteroidsRules.speed(for: child, tideMultiplier: tideMultiplier)

        return [CGFloat(-0.72), CGFloat(0.72)].map { spread in
            let angle = (baseAngle * 0.35) + (safeAngle * 0.65) + spread + CGFloat.random(in: -0.18...0.18)
            return ReefRock(size: child,
                            motif: rock.motif,
                            position: wrapped(CGPoint(x: rock.position.x + cos(angle) * childRadius * 2.0,
                                                      y: rock.position.y + sin(angle) * childRadius * 2.0),
                                              inset: childRadius),
                            velocity: CGPoint(x: cos(angle) * childSpeed,
                                              y: sin(angle) * childSpeed),
                            radius: childRadius,
                            rotation: CGFloat.random(in: 0...(.pi * 2)),
                            spin: CGFloat.random(in: -2.4...2.4),
                            ghostTime: ReefAsteroidsRules.fragmentGhostTime)
        }
    }

    private func clampedPlayerPosition(_ point: CGPoint) -> CGPoint {
        let inset = ReefAsteroidsRules.playerRadius
        let x = point.x.clamped(to: (playRect.minX + inset)...(playRect.maxX - inset))
        let y = point.y.clamped(to: (playRect.minY + inset)...(playRect.maxY - inset))
        if x != point.x {
            player.velocity.x *= -0.18
        }
        if y != point.y {
            player.velocity.y *= -0.18
        }
        return CGPoint(x: x, y: y)
    }

    private func wrapped(_ point: CGPoint, inset: CGFloat) -> CGPoint {
        var wrapped = point
        if wrapped.x < playRect.minX - inset {
            wrapped.x = playRect.maxX + inset
        } else if wrapped.x > playRect.maxX + inset {
            wrapped.x = playRect.minX - inset
        }
        if wrapped.y < playRect.minY - inset {
            wrapped.y = playRect.maxY + inset
        } else if wrapped.y > playRect.maxY + inset {
            wrapped.y = playRect.minY - inset
        }
        return wrapped
    }

    private func color(for motif: ReefRockMotif) -> UIColor {
        switch motif {
        case .basalt: return Visual.stone
        case .roseCoral: return GameUI.coral
        case .goldenCoral: return Visual.gold
        case .algaeStone: return GameUI.algae
        }
    }
}

// MARK: - Visual compartilhado

private enum Visual {
    static let darkTop = UIColor(red: 0.03, green: 0.16, blue: 0.24, alpha: 1)
    static let darkMid = UIColor(red: 0.02, green: 0.10, blue: 0.20, alpha: 1)
    static let darkBottom = UIColor(red: 0.01, green: 0.04, blue: 0.12, alpha: 1)
    static let current = UIColor(red: 0.26, green: 0.75, blue: 0.92, alpha: 1)
    static let hot = UIColor(red: 0.98, green: 0.38, blue: 0.24, alpha: 1)
    static let danger = UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
    static let stone = UIColor(red: 0.46, green: 0.54, blue: 0.57, alpha: 1)
    static let gold = UIColor(red: 0.95, green: 0.72, blue: 0.24, alpha: 1)
    static let reefGlow = UIColor(red: 0.60, green: 0.93, blue: 0.84, alpha: 1)
}

// MARK: - Overlay SpriteKit

final class ReefAsteroidsOverlay: SKNode {
    private let phase: MermaidPhase
    private let special: Bool
    private let shellRewardMultiplier: CGFloat
    private let victoryReward: ChallengeVictoryReward
    private let bestScore: Int
    private let record: ChallengeRecordSnapshot
    private let onFinish: (ChallengeResult) -> Void
    private let goal: Int

    private let arenaWidth: CGFloat
    private let arenaOrigin: CGPoint
    private let playRect: CGRect
    private let engine: ReefAsteroidsEngine

    private var rockNodes: [UUID: SKNode] = [:]
    private var projectileNodes: [UUID: SKNode] = [:]
    private var finished = false
    private var pendingResult: ChallengeResult?

    private let arenaNode = SKNode()
    private let rockLayer = SKNode()
    private let projectileLayer = SKNode()
    private var playerMermaid: Mermaid?
    private var playerMermaidMoving = false
    private var playerMermaidDirectionKey = 0
    private var playerNode: SKNode!
    private var scoreLabel: SKLabelNode!
    private var waveLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var recordLabel: SKLabelNode!
    private var tideLabel: SKLabelNode!
    private var tideFill: SKShapeNode!
    private var tideBarWidth: CGFloat = 0
    private var tideBarLeft: CGFloat = 0
    private let controlStripHeight: CGFloat = 56
    private let controlDeadZone: CGFloat = 0.08
    private var controlStripNode: SKNode?
    private var controlKnobNode: SKNode?
    private var controlActive = false
    private var aimLineNode: SKShapeNode!
    private var targetReticleNode: SKNode!

    private var controlStripWidth: CGFloat {
        max(260, arenaWidth - 42)
    }

    private var controlStripCenter: CGPoint {
        CGPoint(x: 0, y: arenaOrigin.y - 42)
    }

    private var controlStripRect: CGRect {
        CGRect(x: -controlStripWidth / 2,
               y: controlStripCenter.y - controlStripHeight / 2,
               width: controlStripWidth,
               height: controlStripHeight)
    }

    init(size: CGSize,
         zone: DepthZone,
         phase: MermaidPhase,
         special: Bool,
         shellRewardMultiplier: CGFloat,
         victoryReward: ChallengeVictoryReward,
         challengeGoal: Int,
         giverDisplay: SKNode?,
         record: ChallengeRecordSnapshot,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.phase = phase
        self.special = special
        self.shellRewardMultiplier = shellRewardMultiplier
        self.victoryReward = victoryReward
        self.bestScore = record.bestScore
        self.record = record
        self.onFinish = onFinish
        self.goal = challengeGoal

        let availableWidth = max(320, size.width - 8)
        let availableHeight = max(360, size.height - 318)
        let resolvedArenaWidth = min(availableWidth, availableHeight, 540)
        self.arenaWidth = resolvedArenaWidth
        self.arenaOrigin = CGPoint(x: -resolvedArenaWidth / 2, y: -resolvedArenaWidth / 2 - 12)
        self.playRect = CGRect(x: arenaOrigin.x + 8,
                               y: arenaOrigin.y + 8,
                               width: resolvedArenaWidth - 16,
                               height: resolvedArenaWidth - 16)
        self.engine = ReefAsteroidsEngine(playRect: playRect, goal: challengeGoal, special: special)

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
        syncProjectileNodes()
        syncRockNodes()
        syncPlayerNode()
        syncTargetingNodes()
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
            ? "Ruptura especial em \(zone.displayName)"
            : "Campo infinito em \(zone.displayName)"
        let header = ChallengeChrome.makeHeader(kind: .reefAsteroids,
                                                subtitle: subtitle,
                                                giverDisplay: giverDisplay,
                                                width: arenaWidth)
        header.position = CGPoint(x: 0, y: arenaWidth / 2 + 142)
        addChild(header)

        let chipWidth = (arenaWidth - 18) / 3
        let scoreChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                     fallback: "*",
                                                                     color: Visual.gold,
                                                                     size: 21),
                                     title: "Pontos",
                                     value: "\(engine.score)",
                                     width: chipWidth,
                                     accent: Visual.gold)
        scoreChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth / 2,
                                           y: arenaWidth / 2 + 34)
        addChild(scoreChip.node)
        scoreLabel = scoreChip.valueLabel

        let waveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "waveform.path.ecg",
                                                                    fallback: "~",
                                                                    color: Visual.current,
                                                                    size: 21),
                                    title: "Onda",
                                    value: "\(engine.wave)",
                                    width: chipWidth,
                                    accent: Visual.current)
        waveChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth * 1.5 + 9,
                                          y: arenaWidth / 2 + 34)
        addChild(waveChip.node)
        waveLabel = waveChip.valueLabel

        let livesChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "heart.fill",
                                                                     fallback: "v",
                                                                     color: Visual.danger,
                                                                     size: 21),
                                     title: "Vidas",
                                     value: livesText(),
                                     width: chipWidth,
                                     accent: Visual.danger)
        livesChip.node.position = CGPoint(x: arenaOrigin.x + chipWidth * 2.5 + 18,
                                          y: arenaWidth / 2 + 34)
        addChild(livesChip.node)
        livesLabel = livesChip.valueLabel

        recordLabel = SKLabelNode(text: recordText())
        recordLabel.fontName = "AvenirNext-DemiBold"
        recordLabel.fontSize = 12
        recordLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.88)
        recordLabel.verticalAlignmentMode = .center
        recordLabel.horizontalAlignmentMode = .center
        recordLabel.position = CGPoint(x: 0, y: arenaWidth / 2 - 6)
        recordLabel.zPosition = 36
        addChild(recordLabel)

        tideBarWidth = arenaWidth - 34
        tideBarLeft = -tideBarWidth / 2
        addChild(makeTideBar(width: tideBarWidth, y: arenaWidth / 2 - 26))

        arenaNode.addChild(makeArenaSurface(width: arenaWidth))
        addChild(arenaNode)

        rockLayer.zPosition = 24
        projectileLayer.zPosition = 36
        arenaNode.addChild(rockLayer)
        arenaNode.addChild(projectileLayer)
        buildTargetingNodes()

        let controlStrip = makeControlStrip(width: controlStripWidth, height: controlStripHeight)
        controlStrip.position = controlStripCenter
        addChild(controlStrip)

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: 118,
                               height: 38)
        quit.name = "reef_asteroids_quit"
        quit.position = CGPoint(x: 0, y: arenaOrigin.y - 94)
        quit.zPosition = 48
        addChild(quit)
    }

    private func makeBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let texture = GameUI.gradientTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                             colors: [
                                                UIColor.black.withAlphaComponent(0.22),
                                                UIColor.lerp(Visual.darkTop, Visual.current, 0.10).withAlphaComponent(0.54),
                                                UIColor.lerp(GameUI.coral, Visual.current, 0.42).withAlphaComponent(0.18),
                                                UIColor.black.withAlphaComponent(0.42)
                                             ])
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.size = CGSize(width: size.width * 2, height: size.height * 2)
        backdrop.zPosition = -25
        node.addChild(backdrop)

        for index in 0..<18 {
            let y = size.height * 0.48 - CGFloat(index) * 36
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(index.isMultiple(of: 2) ? 18 : -14)),
                          controlPoint1: CGPoint(x: -size.width * 0.24, y: y - 28),
                          controlPoint2: CGPoint(x: size.width * 0.30, y: y + 36))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = UIColor.white.withAlphaComponent(0.045)
            wave.lineWidth = index.isMultiple(of: 3) ? 4 : 2
            wave.glowWidth = 8
            wave.zPosition = -12
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: index.isMultiple(of: 2) ? 26 : -20, y: 0, duration: 1.8),
                .moveBy(x: index.isMultiple(of: 2) ? -26 : 20, y: 0, duration: 1.8)
            ])))
        }

        for index in 0..<44 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...4.6))
            spark.fillColor = (index.isMultiple(of: 3) ? Visual.reefGlow : UIColor.white).withAlphaComponent(0.06)
            spark.strokeColor = .clear
            spark.position = CGPoint(x: CGFloat.random(in: -size.width * 0.56...size.width * 0.56),
                                     y: CGFloat.random(in: -size.height * 0.52...size.height * 0.52))
            spark.zPosition = -8
            node.addChild(spark)
            spark.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.03),
                .group([
                    .moveBy(x: CGFloat.random(in: -32...32),
                            y: size.height * CGFloat.random(in: 0.18...0.38),
                            duration: Double.random(in: 2.2...4.4)),
                    .fadeOut(withDuration: Double.random(in: 2.2...4.4))
                ]),
                .moveBy(x: 0, y: -size.height * 0.36, duration: 0),
                .fadeAlpha(to: 0.9, duration: 0.16)
            ])))
        }

        return node
    }

    private func makeFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 24,
                               tint: Visual.current.withAlphaComponent(0.48),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -8

        let dark = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                               cornerRadius: 20)
        dark.fillTexture = GameUI.gradientTexture(size: size,
                                                  colors: [Visual.darkTop, Visual.darkMid, Visual.darkBottom])
        dark.fillColor = .white
        dark.strokeColor = GameUI.palePaper.withAlphaComponent(0.14)
        dark.lineWidth = 1.1
        dark.zPosition = 1
        node.addChild(dark)

        let pulse = SKShapeNode(rectOf: CGSize(width: size.width - 22, height: size.height - 22),
                                cornerRadius: 16)
        pulse.fillColor = Visual.current.withAlphaComponent(0.045)
        pulse.strokeColor = Visual.reefGlow.withAlphaComponent(0.18)
        pulse.lineWidth = 1
        pulse.zPosition = 2
        node.addChild(pulse)
        pulse.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.48, duration: 0.48),
            .fadeAlpha(to: 1.0, duration: 0.48)
        ])))

        return node
    }

    private func makeArenaSurface(width: CGFloat) -> SKNode {
        let node = SKNode()
        let center = CGPoint(x: 0, y: arenaOrigin.y + width / 2)
        node.zPosition = -18

        let back = SKShapeNode(rectOf: CGSize(width: width, height: width), cornerRadius: 24)
        back.position = center
        back.fillTexture = GameUI.gradientTexture(size: CGSize(width: width + 20, height: width + 20),
                                                  colors: [
                                                    UIColor.lerp(Visual.darkTop, Visual.current, 0.15),
                                                    Visual.darkMid,
                                                    Visual.darkBottom
                                                  ])
        back.fillColor = .white
        back.strokeColor = Visual.current.withAlphaComponent(0.48)
        back.lineWidth = 2
        back.glowWidth = 4
        node.addChild(back)

        for index in 0..<7 {
            let offset = -width / 2 + CGFloat(index) * width / 6
            let alpha = index == 0 || index == 6 ? 0.16 : 0.05

            let vertical = SKShapeNode(rectOf: CGSize(width: 1, height: width))
            vertical.fillColor = UIColor.white.withAlphaComponent(alpha)
            vertical.strokeColor = .clear
            vertical.position = CGPoint(x: offset, y: center.y)
            node.addChild(vertical)

            let horizontal = SKShapeNode(rectOf: CGSize(width: width, height: 1))
            horizontal.fillColor = UIColor.white.withAlphaComponent(alpha)
            horizontal.strokeColor = .clear
            horizontal.position = CGPoint(x: 0, y: center.y + offset)
            node.addChild(horizontal)
        }

        for index in 0..<26 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.8))
            dot.fillColor = (index.isMultiple(of: 2) ? Visual.gold : Visual.current).withAlphaComponent(0.16)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat.random(in: -width * 0.43...width * 0.43),
                                   y: center.y + CGFloat.random(in: -width * 0.43...width * 0.43))
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
        ChallengeChrome.fitSingleLineLabel(valueLabel,
                                           maxWidth: width - 60,
                                           maxFontSize: 12.6,
                                           minFontSize: 9.8)
        valueLabel.position = CGPoint(x: titleLabel.position.x, y: -8)
        node.addChild(valueLabel)

        return (node, valueLabel)
    }

    private func makeTideBar(width: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 35

        let back = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        back.fillColor = GameUI.line.withAlphaComponent(0.13)
        back.strokeColor = GameUI.line.withAlphaComponent(0.22)
        back.lineWidth = 1
        node.addChild(back)

        tideFill = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        tideFill.fillColor = Visual.current.withAlphaComponent(0.82)
        tideFill.strokeColor = .clear
        tideFill.glowWidth = 2
        tideFill.zPosition = 1
        node.addChild(tideFill)

        tideLabel = SKLabelNode(text: tideText())
        tideLabel.fontName = "AvenirNext-DemiBold"
        tideLabel.fontSize = 11
        tideLabel.fontColor = GameUI.palePaper
        tideLabel.verticalAlignmentMode = .center
        tideLabel.horizontalAlignmentMode = .center
        tideLabel.zPosition = 2
        node.addChild(tideLabel)

        return node
    }

    private func makeControlStrip(width: CGFloat, height: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = "reef_asteroids_control"
        node.zPosition = 44

        let back = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        back.fillTexture = GameUI.gradientTexture(size: CGSize(width: width, height: height),
                                                  colors: [
                                                    Visual.darkMid.withAlphaComponent(0.96),
                                                    UIColor.lerp(Visual.darkBottom, Visual.current, 0.16),
                                                    Visual.darkBottom.withAlphaComponent(0.98)
                                                  ])
        back.fillColor = .white
        back.strokeColor = Visual.reefGlow.withAlphaComponent(0.46)
        back.lineWidth = 1.4
        back.glowWidth = 4
        node.addChild(back)

        for index in 0..<4 {
            let y = (CGFloat(index) - 1.5) * height * 0.14
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width * 0.42, y: y))
            path.addCurve(to: CGPoint(x: width * 0.42, y: y + CGFloat(index.isMultiple(of: 2) ? 5 : -5)),
                          controlPoint1: CGPoint(x: -width * 0.16, y: y + 10),
                          controlPoint2: CGPoint(x: width * 0.15, y: y - 10))
            let current = SKShapeNode(path: path.cgPath)
            current.fillColor = .clear
            current.strokeColor = Visual.reefGlow.withAlphaComponent(0.18)
            current.lineWidth = 1.2
            current.lineCap = .round
            current.zPosition = 1
            node.addChild(current)
            current.run(.repeatForever(.sequence([
                .moveBy(x: index.isMultiple(of: 2) ? 12 : -12, y: 0, duration: 0.72),
                .moveBy(x: index.isMultiple(of: 2) ? -12 : 12, y: 0, duration: 0.72)
            ])))
        }

        let centerDot = SKShapeNode(circleOfRadius: 4.5)
        centerDot.fillColor = UIColor.white.withAlphaComponent(0.34)
        centerDot.strokeColor = .clear
        centerDot.zPosition = 2
        node.addChild(centerDot)

        let knob = SKShapeNode(circleOfRadius: height * 0.27)
        knob.fillColor = Visual.reefGlow.withAlphaComponent(0.24)
        knob.strokeColor = UIColor.white.withAlphaComponent(0.70)
        knob.lineWidth = 1.4
        knob.glowWidth = 5
        knob.zPosition = 3
        node.addChild(knob)

        controlStripNode = node
        controlKnobNode = knob
        return node
    }

    private func buildTargetingNodes() {
        let aimLine = SKShapeNode()
        aimLine.fillColor = .clear
        aimLine.strokeColor = Visual.reefGlow.withAlphaComponent(0.52)
        aimLine.lineWidth = 1.4
        aimLine.lineCap = .round
        aimLine.glowWidth = 4
        aimLine.zPosition = 43
        aimLine.isHidden = true
        arenaNode.addChild(aimLine)
        aimLineNode = aimLine

        let reticle = SKNode()
        reticle.zPosition = 44
        reticle.isHidden = true

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.fillColor = .clear
        ring.strokeColor = Visual.reefGlow.withAlphaComponent(0.58)
        ring.lineWidth = 1.4
        ring.glowWidth = 5
        reticle.addChild(ring)

        for angle in stride(from: CGFloat(0), to: CGFloat.pi * 2, by: CGFloat.pi / 2) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: cos(angle) * 28, y: sin(angle) * 28))
            path.addLine(to: CGPoint(x: cos(angle) * 38, y: sin(angle) * 38))
            let tick = SKShapeNode(path: path.cgPath)
            tick.fillColor = .clear
            tick.strokeColor = UIColor.white.withAlphaComponent(0.52)
            tick.lineWidth = 1.2
            tick.lineCap = .round
            reticle.addChild(tick)
        }

        reticle.run(.repeatForever(.sequence([
            .scale(to: 1.10, duration: 0.34),
            .scale(to: 0.96, duration: 0.34)
        ])))
        arenaNode.addChild(reticle)
        targetReticleNode = reticle
    }

    private func buildPlayer() {
        playerNode = makePlayerNode()
        playerNode.position = engine.player.position
        playerNode.zPosition = 50
        arenaNode.addChild(playerNode)
    }

    private func makePlayerNode() -> SKNode {
        let node = SKNode()
        let radius = ReefAsteroidsRules.playerRadius

        let aura = SKShapeNode(circleOfRadius: radius * 1.28)
        aura.fillColor = Visual.current.withAlphaComponent(0.12)
        aura.strokeColor = Visual.reefGlow.withAlphaComponent(0.34)
        aura.lineWidth = 1.2
        aura.glowWidth = 6
        aura.zPosition = -2
        node.addChild(aura)
        aura.run(.repeatForever(.sequence([
            .scale(to: 1.12, duration: 0.34),
            .scale(to: 0.94, duration: 0.34)
        ])))

        let mermaid = Mermaid()
        if phase != .egg {
            mermaid.setForm(for: phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.swing)
        playerMermaidMoving = true
        let scale = ChallengeChrome.fitScale(for: mermaid.base, targetHeight: radius * 2.35)
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
        let wobble = sin(player.wobble * 10) * 0.035
        playerNode.xScale = 1 + wobble
        playerNode.yScale = 1 - wobble
        playerNode.alpha = player.invulnerableTime > 0
            ? (sin(player.invulnerableTime * 26) > 0 ? 0.48 : 1.0)
            : 1.0
        updateMermaidDirection(for: player.velocity)
    }

    private func updateMermaidDirection(for velocity: CGPoint) {
        guard let mermaid = playerMermaid else { return }
        let movementThreshold: CGFloat = 22
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

    private func syncRockNodes() {
        let ids = Set(engine.rocks.map(\.id))
        let staleIds = rockNodes.keys.filter { !ids.contains($0) }
        for id in staleIds {
            rockNodes[id]?.removeFromParent()
            rockNodes[id] = nil
        }

        for rock in engine.rocks {
            let node: SKNode
            if let existing = rockNodes[rock.id] {
                node = existing
            } else {
                node = makeRockNode(rock)
                rockLayer.addChild(node)
                rockNodes[rock.id] = node
            }
            node.position = rock.position
            node.zRotation = rock.rotation
            node.alpha = rock.ghostTime > 0 ? 0.52 : 1.0
        }
    }

    private func syncProjectileNodes() {
        let ids = Set(engine.projectiles.map(\.id))
        let staleIds = projectileNodes.keys.filter { !ids.contains($0) }
        for id in staleIds {
            projectileNodes[id]?.removeFromParent()
            projectileNodes[id] = nil
        }

        for projectile in engine.projectiles {
            let node: SKNode
            if let existing = projectileNodes[projectile.id] {
                node = existing
            } else {
                node = makeProjectileNode()
                projectileLayer.addChild(node)
                projectileNodes[projectile.id] = node
            }
            node.position = projectile.position
            node.alpha = min(1, projectile.lifeTime / 0.18)
        }
    }

    private func syncTargetingNodes() {
        guard aimLineNode != nil, targetReticleNode != nil else { return }
        guard !finished, let target = engine.currentAimTarget else {
            aimLineNode.isHidden = true
            targetReticleNode.isHidden = true
            return
        }

        targetReticleNode.isHidden = false
        targetReticleNode.position = target.position
        targetReticleNode.setScale((target.radius / 26).clamped(to: 0.62...1.35))
        targetReticleNode.alpha = target.ghostTime > 0 ? 0.44 : 0.84

        let start = engine.player.position
        let delta = target.position - start
        let distance = max(1, hypot(delta.x, delta.y))
        let direction = CGPoint(x: delta.x / distance, y: delta.y / distance)
        let lineStart = CGPoint(x: start.x + direction.x * 30,
                                y: start.y + direction.y * 30)
        let lineLength = min(120, max(42, distance - target.radius - 12))
        let lineEnd = CGPoint(x: lineStart.x + direction.x * lineLength,
                              y: lineStart.y + direction.y * lineLength)

        let path = UIBezierPath()
        path.move(to: lineStart)
        path.addLine(to: lineEnd)
        aimLineNode.path = path.cgPath
        aimLineNode.isHidden = false
    }

    private func makeRockNode(_ rock: ReefRock) -> SKNode {
        let node = SKNode()
        let radius = rock.radius
        let color = color(for: rock.motif)

        let glow = SKShapeNode(circleOfRadius: radius * 1.10)
        glow.fillColor = color.withAlphaComponent(0.14)
        glow.strokeColor = .clear
        glow.glowWidth = rock.size == .large ? 8 : 5
        glow.zPosition = -2
        node.addChild(glow)

        let body = SKShapeNode(path: rockPath(radius: radius))
        body.fillTexture = GameUI.gradientTexture(size: CGSize(width: radius * 2.2, height: radius * 2.2),
                                                  colors: [
                                                    UIColor.lerp(color, .white, 0.30),
                                                    color,
                                                    UIColor.lerp(color, Visual.darkBottom, 0.42)
                                                  ])
        body.fillColor = .white
        body.strokeColor = UIColor.white.withAlphaComponent(0.42)
        body.lineWidth = rock.size == .large ? 1.6 : 1.2
        body.glowWidth = rock.size == .small ? 2 : 3
        node.addChild(body)

        if rock.motif != .basalt {
            addCoralBranches(to: node, radius: radius, color: color)
        } else {
            addStoneCracks(to: node, radius: radius)
        }

        node.run(.repeatForever(.sequence([
            .scale(to: CGFloat.random(in: 1.025...1.07), duration: Double.random(in: 0.52...0.82)),
            .scale(to: 1.0, duration: Double.random(in: 0.52...0.82))
        ])))

        return node
    }

    private func rockPath(radius: CGFloat) -> CGPath {
        let path = UIBezierPath()
        let points = 9
        for index in 0..<points {
            let angle = CGFloat(index) / CGFloat(points) * .pi * 2
            let jitter = CGFloat.random(in: 0.72...1.10)
            let point = CGPoint(x: cos(angle) * radius * jitter,
                                y: sin(angle) * radius * jitter)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        return path.cgPath
    }

    private func addCoralBranches(to node: SKNode, radius: CGFloat, color: UIColor) {
        for index in 0..<5 {
            let angle = CGFloat(index) / 5 * .pi * 2 + CGFloat.random(in: -0.25...0.25)
            let root = CGPoint(x: cos(angle) * radius * 0.18,
                               y: sin(angle) * radius * 0.18)
            let tip = CGPoint(x: cos(angle) * radius * CGFloat.random(in: 0.55...0.86),
                              y: sin(angle) * radius * CGFloat.random(in: 0.55...0.86))
            let path = UIBezierPath()
            path.move(to: root)
            path.addLine(to: tip)
            path.move(to: CGPoint(x: tip.x * 0.68, y: tip.y * 0.68))
            path.addLine(to: CGPoint(x: tip.x * 0.68 + cos(angle + 0.72) * radius * 0.18,
                                     y: tip.y * 0.68 + sin(angle + 0.72) * radius * 0.18))
            path.move(to: CGPoint(x: tip.x * 0.58, y: tip.y * 0.58))
            path.addLine(to: CGPoint(x: tip.x * 0.58 + cos(angle - 0.72) * radius * 0.15,
                                     y: tip.y * 0.58 + sin(angle - 0.72) * radius * 0.15))

            let branch = SKShapeNode(path: path.cgPath)
            branch.fillColor = .clear
            branch.strokeColor = UIColor.lerp(color, .white, 0.26).withAlphaComponent(0.74)
            branch.lineWidth = max(1.0, radius * 0.055)
            branch.lineCap = .round
            branch.lineJoin = .round
            branch.zPosition = 4
            node.addChild(branch)
        }
    }

    private func addStoneCracks(to node: SKNode, radius: CGFloat) {
        for index in 0..<3 {
            let angle = CGFloat(index) / 3 * .pi * 2 + CGFloat.random(in: -0.45...0.45)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: cos(angle) * radius * 0.10, y: sin(angle) * radius * 0.10))
            path.addLine(to: CGPoint(x: cos(angle) * radius * 0.66, y: sin(angle) * radius * 0.66))
            let crack = SKShapeNode(path: path.cgPath)
            crack.fillColor = .clear
            crack.strokeColor = UIColor.white.withAlphaComponent(0.28)
            crack.lineWidth = 1
            crack.lineCap = .round
            crack.zPosition = 4
            node.addChild(crack)
        }
    }

    private func makeProjectileNode() -> SKNode {
        let node = SKNode()
        let core = SKShapeNode(circleOfRadius: ReefAsteroidsRules.projectileRadius)
        core.fillColor = Visual.reefGlow.withAlphaComponent(0.92)
        core.strokeColor = UIColor.white.withAlphaComponent(0.72)
        core.lineWidth = 1
        core.glowWidth = 5
        node.addChild(core)

        let halo = SKShapeNode(circleOfRadius: ReefAsteroidsRules.projectileRadius * 2.0)
        halo.fillColor = Visual.current.withAlphaComponent(0.08)
        halo.strokeColor = Visual.reefGlow.withAlphaComponent(0.20)
        halo.glowWidth = 7
        halo.zPosition = -1
        node.addChild(halo)
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
            if current.name == "reef_asteroids_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish()
                return
            }
            node = current.parent
        }

        startControl(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let touch = touches.first else { return }
        updateControl(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        endControl()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        endControl()
    }

    private func startControl(at point: CGPoint) {
        guard controlStripRect.insetBy(dx: -8, dy: -10).contains(point) else { return }
        controlActive = true
        controlStripNode?.removeAllActions()
        controlStripNode?.setScale(1.0)
        controlStripNode?.run(.sequence([
            .scale(to: 1.025, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))
        updateControl(to: point)
    }

    private func updateControl(to point: CGPoint) {
        guard controlActive else { return }
        let rect = controlStripRect
        let clampedPoint = CGPoint(x: point.x.clamped(to: rect.minX...rect.maxX),
                                   y: point.y.clamped(to: rect.minY...rect.maxY))
        let x = ((clampedPoint.x - rect.midX) / (rect.width * 0.44)).clamped(to: -1...1)
        let y = ((clampedPoint.y - rect.midY) / (rect.height * 0.42)).clamped(to: -1...1)
        let length = hypot(x, y)
        guard length > controlDeadZone else {
            controlKnobNode?.position = .zero
            engine.setControlVector(nil)
            return
        }

        let intensity = min(1, length)
        let direction = CGPoint(x: x / length, y: y / length)
        controlKnobNode?.position = CGPoint(x: direction.x * rect.width * 0.36 * intensity,
                                            y: direction.y * rect.height * 0.25 * intensity)
        engine.setControlVector(CGPoint(x: direction.x * intensity,
                                        y: direction.y * intensity))
    }

    private func endControl() {
        controlActive = false
        engine.setControlVector(nil)
        let move = SKAction.move(to: .zero, duration: 0.14)
        move.timingMode = .easeOut
        controlKnobNode?.run(move)
    }

    // MARK: - Feedback

    private func showFeedback(_ feedback: ReefFeedback) {
        let size: CGFloat
        let drift: CGPoint
        switch feedback.effect {
        case .score:
            size = 18
            drift = CGPoint(x: CGFloat.random(in: -14...14), y: 52)
            GameAudio.shared.play(.tideMatch, cooldownOverride: 0.04)
            spawnSparkles(at: feedback.position, color: feedback.color, count: 4)
        case .combo:
            size = min(30, 17 + CGFloat(engine.currentStreak))
            drift = CGPoint(x: CGFloat.random(in: -12...12), y: 58)
            GameAudio.shared.play(.tideCascade, volumeMultiplier: 0.82, cooldownOverride: 0.06)
        case .crack:
            size = 21
            drift = CGPoint(x: CGFloat.random(in: -16...16), y: 62)
            GameAudio.shared.play(.tideMatch, cooldownOverride: 0.04)
            spawnSparkles(at: feedback.position, color: feedback.color, count: 8)
            makeShockwave(at: feedback.position, color: feedback.color, radius: 34)
        case .hit:
            size = 30
            drift = CGPoint(x: CGFloat.random(in: -22...22), y: 104)
            GameAudio.shared.play(.challengeFail, cooldownOverride: 0.12)
            spawnSparkles(at: feedback.position, color: feedback.color, count: 24)
            shakeArena()
            makeScreenFlash(color: feedback.color)
        case .wave:
            size = 36
            drift = CGPoint(x: 0, y: 118)
            GameAudio.shared.play(.tideGoal, volumeMultiplier: 0.9, cooldownOverride: 0.10)
            spawnSparkles(at: feedback.position, color: feedback.color, count: 32)
            makeScreenFlash(color: feedback.color)
        case .surge:
            size = 34
            drift = CGPoint(x: 0, y: 116)
            GameAudio.shared.play(.tideCascade, volumeMultiplier: 1.06, cooldownOverride: 0.10)
            makeScreenFlash(color: feedback.color)
        }

        showFloatingLabel(text: feedback.text,
                          at: feedback.position,
                          color: feedback.color,
                          size: size,
                          drift: drift)
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
        label.zPosition = 145
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
            let sparkle = SKLabelNode(text: index.isMultiple(of: 2) ? "*" : ".")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = CGFloat.random(in: 10...20)
            sparkle.fontColor = UIColor.lerp(color, .white, CGFloat.random(in: 0.16...0.52))
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = converted
            sparkle.zPosition = 124
            addChild(sparkle)

            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat.random(in: -0.30...0.30)
            let distance = CGFloat.random(in: 26...62)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance + CGFloat.random(in: 22...52),
                            duration: 0.42),
                    .rotate(byAngle: CGFloat.random(in: -1.6...1.6), duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: CGFloat.random(in: 0.25...0.55), duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func makeShockwave(at point: CGPoint, color: UIColor, radius: CGFloat) {
        let converted = convert(point, from: arenaNode)
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = converted
        ring.fillColor = .clear
        ring.strokeColor = color.withAlphaComponent(0.58)
        ring.lineWidth = 2
        ring.glowWidth = 5
        ring.zPosition = 118
        addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 1.75, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))
    }

    private func makeScreenFlash(color: UIColor) {
        let flash = SKShapeNode(rectOf: CGSize(width: arenaWidth, height: arenaWidth), cornerRadius: 24)
        flash.position = CGPoint(x: 0, y: arenaOrigin.y + arenaWidth / 2)
        flash.fillColor = color.withAlphaComponent(0.14)
        flash.strokeColor = color.withAlphaComponent(0.50)
        flash.lineWidth = 2
        flash.glowWidth = 12
        flash.zPosition = 112
        addChild(flash)
        flash.run(.sequence([
            .group([
                .scale(to: 1.05, duration: 0.24),
                .fadeOut(withDuration: 0.24)
            ]),
            .removeFromParent()
        ]))
    }

    private func shakeArena() {
        arenaNode.run(.sequence([
            .moveBy(x: -8, y: 3, duration: 0.04),
            .moveBy(x: 16, y: -6, duration: 0.08),
            .moveBy(x: -8, y: 3, duration: 0.04)
        ]))
    }

    // MARK: - Estado

    private func updateStatusUI() {
        guard scoreLabel != nil else { return }
        scoreLabel.text = "\(engine.score)"
        waveLabel.text = "\(engine.wave)"
        livesLabel.text = livesText()
        ChallengeChrome.fitSingleLineLabel(scoreLabel,
                                           maxWidth: scoreLabel.preferredMaxLayoutWidth,
                                           maxFontSize: 12.6,
                                           minFontSize: 9.8)
        ChallengeChrome.fitSingleLineLabel(waveLabel,
                                           maxWidth: waveLabel.preferredMaxLayoutWidth,
                                           maxFontSize: 12.6,
                                           minFontSize: 9.8)
        ChallengeChrome.fitSingleLineLabel(livesLabel,
                                           maxWidth: livesLabel.preferredMaxLayoutWidth,
                                           maxFontSize: 12.6,
                                           minFontSize: 9.8)
        recordLabel.text = recordText()
        updateTideUI()
    }

    private func updateTideUI() {
        guard tideLabel != nil, tideFill != nil else { return }
        tideLabel.text = tideText()
        let progress = ((engine.tideMultiplier - 1) / 1.8).clamped(to: 0...1)
        let visible = max(0.04, progress)
        tideFill.xScale = visible
        tideFill.position = CGPoint(x: tideBarLeft + tideBarWidth * visible / 2, y: 0)
        tideFill.fillColor = engine.tideMultiplier >= 1.72
            ? Visual.hot.withAlphaComponent(0.86)
            : Visual.current.withAlphaComponent(0.82)
    }

    private func livesText() -> String {
        "\(engine.player.lives)/\(ReefAsteroidsRules.startLives)"
    }

    private func tideText() -> String {
        String(format: "Maré %.2fx", engine.tideMultiplier)
    }

    private func recordText() -> String {
        let liveBest = max(bestScore, engine.score)
        return engine.score >= goal
            ? "Meta \(goal)  |  Recorde \(liveBest)"
            : "Meta \(engine.score)/\(goal)  |  Recorde \(liveBest)"
    }

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .reefAsteroids,
                                                          reachedTarget: reached ?? engine.challengeCompleted,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false,
                                                          victoryReward: victoryReward)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: engine.score,
                                                      multiplier: shellRewardMultiplier)
    }

    // MARK: - Fim

    private func finish() {
        guard !finished else { return }
        finished = true
        engine.setControlVector(nil)
        controlStripNode?.removeAllActions()
        controlKnobNode?.removeAllActions()
        GameAudio.shared.play(engine.challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = engine.challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .reefAsteroids,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false,
                                                          victoryReward: victoryReward)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 150
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let isNewRecord = record.isNewRecord(score: engine.score)
        let titleLabel = SKLabelNode(text: isNewRecord ? "Novo recorde!" : (reached ? "Recife rompido!" : "Maré encerrada!"))
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 18
        titleLabel.fontColor = GameUI.ink
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 82)
        ChallengeChrome.fitSingleLineLabel(titleLabel,
                                           maxWidth: 288,
                                           maxFontSize: 18,
                                           minFontSize: 13.5)
        content.addChild(titleLabel)

        let scoreLine = SKLabelNode(text: "Pontos feitos: \(engine.score)")
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.verticalAlignmentMode = .center
        scoreLine.position = CGPoint(x: 0, y: 48)
        ChallengeChrome.fitSingleLineLabel(scoreLine,
                                           maxWidth: 280,
                                           maxFontSize: 16,
                                           minFontSize: 12.5)
        content.addChild(scoreLine)

        let waveLine = SKLabelNode(text: "Onda \(engine.wave)  |  Recorde \(max(bestScore, engine.score))")
        waveLine.fontName = "AvenirNext-Regular"
        waveLine.fontSize = 13
        waveLine.fontColor = GameUI.mutedInk
        waveLine.verticalAlignmentMode = .center
        waveLine.position = CGPoint(x: 0, y: 24)
        ChallengeChrome.fitSingleLineLabel(waveLine,
                                           maxWidth: 284,
                                           maxFontSize: 13,
                                           minFontSize: 10.5)
        content.addChild(waveLine)

        let rewardLine = SKLabelNode(text: "Convertendo pontos...")
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.verticalAlignmentMode = .center
        rewardLine.position = CGPoint(x: 0, y: -34)
        content.addChild(rewardLine)
        ChallengeChrome.animatePointConversion(label: rewardLine,
                                               points: engine.score,
                                               pearls: pearls,
                                               reachedTarget: reached,
                                               victoryReward: victoryReward,
                                               newRecord: isNewRecord)

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "reef_asteroids_continue"
        continueButton.position = CGPoint(x: 0, y: -104)
        content.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .reefAsteroids,
                                        points: engine.score,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        special: special,
                                        victoryReward: victoryReward,
                                        previousBestScore: record.bestScore,
                                        isHatching: false)
    }

    private func makeResultPanel(reached: Bool) -> SKNode {
        let resultTint = reached
            ? GameUI.algae.withAlphaComponent(0.82)
            : GameUI.coral.withAlphaComponent(0.82)
        let panel = GameUI.card(size: CGSize(width: 316, height: 286),
                                cornerRadius: 24,
                                tint: resultTint,
                                baseColors: [UIColor.lerp(GameUI.palePaper, resultTint, 0.28)])
        let wash = SKShapeNode(rectOf: CGSize(width: 304, height: 274), cornerRadius: 20)
        wash.fillColor = resultTint.withAlphaComponent(0.08)
        wash.strokeColor = .clear
        wash.zPosition = 0.5
        panel.addChild(wash)
        return panel
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "reef_asteroids_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }

    // MARK: - Cores

    private func color(for motif: ReefRockMotif) -> UIColor {
        switch motif {
        case .basalt: return Visual.stone
        case .roseCoral: return GameUI.coral
        case .goldenCoral: return Visual.gold
        case .algaeStone: return GameUI.algae
        }
    }
}
