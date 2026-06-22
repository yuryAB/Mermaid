//
//  EchoMelodySystem.swift
//  Ester
//
//  Desafio: Canto dos Ecos. Jogo de memória musical: a maré canta uma
//  sequência, a jogadora repete, e a sequência cresce a cada rodada.
//

import Foundation
import SpriteKit

// MARK: - Regras puras

private enum EchoMelodyNote: Int, CaseIterable {
    case pearl
    case coral
    case kelp
    case moon

    var title: String {
        switch self {
        case .pearl: return "MI"
        case .coral: return "SOL"
        case .kelp: return "LA"
        case .moon: return "DO"
        }
    }

    var frequency: Double {
        switch self {
        case .pearl: return 329.63
        case .coral: return 392.00
        case .kelp: return 440.00
        case .moon: return 523.25
        }
    }

    var color: UIColor {
        switch self {
        case .pearl:
            return UIColor(red: 0.46, green: 0.85, blue: 0.94, alpha: 1)
        case .coral:
            return GameUI.coral
        case .kelp:
            return GameUI.algae
        case .moon:
            return GameUI.gold
        }
    }

    var symbolName: String {
        switch self {
        case .pearl: return "circle.grid.cross.fill"
        case .coral: return "sparkle"
        case .kelp: return "leaf.fill"
        case .moon: return "moon.stars.fill"
        }
    }
}

private enum EchoMelodyPhase {
    case resting
    case singing
    case listening
    case finished
}

private struct EchoMelodyInputResult {
    let note: EchoMelodyNote
    let expected: EchoMelodyNote
    let correct: Bool
    let hitPoints: Int
    let roundBonus: Int
    let completedRound: Bool
    let reachedGoalNow: Bool
}

private enum EchoMelodyRules {
    static let inputTimeout: CGFloat = 5
    static let maxSequenceLength = 31

    static func playbackStepDuration(sequenceLength: Int) -> TimeInterval {
        switch sequenceLength {
        case 13...:
            return 0.34
        case 9...:
            return 0.40
        case 5...:
            return 0.48
        default:
            return 0.56
        }
    }

    static func hitPoints(sequenceLength: Int,
                          expectedIndex: Int,
                          timeLeft: CGFloat) -> Int {
        let memoryLoad = 4 + sequenceLength
        let cadenceBonus: Int
        if timeLeft >= 3.75 {
            cadenceBonus = 4
        } else if timeLeft >= 2.25 {
            cadenceBonus = 2
        } else {
            cadenceBonus = 0
        }
        let closingBonus = expectedIndex == sequenceLength - 1 ? sequenceLength * 2 : 0
        return memoryLoad + cadenceBonus + closingBonus
    }

    static func roundBonus(sequenceLength: Int) -> Int {
        let speedTier: Int
        switch sequenceLength {
        case 13...:
            speedTier = 22
        case 9...:
            speedTier = 15
        case 5...:
            speedTier = 8
        default:
            speedTier = 0
        }
        return 12 + sequenceLength * 6 + speedTier
    }
}

private final class EchoMelodyEngine {
    let goal: Int

    private(set) var phase: EchoMelodyPhase = .resting
    private(set) var sequence: [EchoMelodyNote] = []
    private(set) var expectedIndex = 0
    private(set) var score = 0
    private(set) var perfectRounds = 0
    private(set) var challengeCompleted = false
    private(set) var inputTimeLeft = EchoMelodyRules.inputTimeout

    init(goal: Int) {
        self.goal = max(1, goal)
    }

    var round: Int { sequence.count }
    var finished: Bool { phase == .finished }

    func startNextRound() -> [EchoMelodyNote] {
        guard phase != .finished else { return sequence }
        sequence.append(nextNote())
        expectedIndex = 0
        inputTimeLeft = EchoMelodyRules.inputTimeout
        phase = .singing
        return sequence
    }

    func beginListening() {
        guard phase == .singing else { return }
        expectedIndex = 0
        inputTimeLeft = EchoMelodyRules.inputTimeout
        phase = .listening
    }

    func register(_ note: EchoMelodyNote) -> EchoMelodyInputResult? {
        guard phase == .listening,
              sequence.indices.contains(expectedIndex) else { return nil }

        let expected = sequence[expectedIndex]
        guard note == expected else {
            phase = .finished
            return EchoMelodyInputResult(note: note,
                                         expected: expected,
                                         correct: false,
                                         hitPoints: 0,
                                         roundBonus: 0,
                                         completedRound: false,
                                         reachedGoalNow: false)
        }

        let hitPoints = EchoMelodyRules.hitPoints(sequenceLength: sequence.count,
                                                  expectedIndex: expectedIndex,
                                                  timeLeft: inputTimeLeft)
        score += hitPoints
        expectedIndex += 1
        inputTimeLeft = EchoMelodyRules.inputTimeout

        let completedRound = expectedIndex >= sequence.count
        let roundBonus: Int
        if completedRound {
            roundBonus = EchoMelodyRules.roundBonus(sequenceLength: sequence.count)
            score += roundBonus
            perfectRounds += 1
            phase = sequence.count >= EchoMelodyRules.maxSequenceLength ? .finished : .resting
        } else {
            roundBonus = 0
        }

        let reachedNow = !challengeCompleted && score >= goal
        if reachedNow {
            challengeCompleted = true
        }

        return EchoMelodyInputResult(note: note,
                                     expected: expected,
                                     correct: true,
                                     hitPoints: hitPoints,
                                     roundBonus: roundBonus,
                                     completedRound: completedRound,
                                     reachedGoalNow: reachedNow)
    }

    func update(dt: CGFloat) -> Bool {
        guard phase == .listening else { return false }
        inputTimeLeft = max(0, inputTimeLeft - dt)
        if inputTimeLeft <= 0 {
            phase = .finished
            return true
        }
        return false
    }

    func forceFinish() {
        phase = .finished
    }

    private func nextNote() -> EchoMelodyNote {
        let notes = EchoMelodyNote.allCases
        guard sequence.count >= 2,
              sequence[sequence.count - 1] == sequence[sequence.count - 2],
              let last = sequence.last else {
            return notes.randomElement() ?? .pearl
        }
        return notes.filter { $0 != last }.randomElement() ?? .pearl
    }
}

// MARK: - Overlay SpriteKit

final class EchoMelodyOverlay: SKNode {
    private let zone: DepthZone
    private let phase: MermaidPhase
    private let special: Bool
    private let shellRewardMultiplier: CGFloat
    private let victoryReward: ChallengeVictoryReward
    private let challengeGoal: Int
    private let record: ChallengeRecordSnapshot
    private let onFinish: (ChallengeResult) -> Void
    private let engine: EchoMelodyEngine

    private let panelWidth: CGFloat
    private let panelHeight: CGFloat
    private let padRadius: CGFloat
    private let playCenterY: CGFloat
    private let stageHeight: CGFloat
    private let timerBarWidth: CGFloat

    private var padNodes: [EchoMelodyNote: SKNode] = [:]
    private var acceptingInput = false
    private var finished = false
    private var pendingResult: ChallengeResult?

    private var scoreLabel: SKLabelNode!
    private var sequenceLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var statusLabel: SKLabelNode!
    private var bestLabel: SKLabelNode!
    private var timerBarFill: SKShapeNode!
    private weak var quitButton: SKNode?

    private enum Visual {
        static let darkTop = UIColor(red: 0.03, green: 0.17, blue: 0.25, alpha: 1)
        static let darkMid = UIColor(red: 0.02, green: 0.10, blue: 0.20, alpha: 1)
        static let darkBottom = UIColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1)
        static let echo = UIColor(red: 0.45, green: 0.82, blue: 0.92, alpha: 1)
        static let violet = UIColor(red: 0.55, green: 0.45, blue: 0.88, alpha: 1)
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
        self.zone = zone
        self.phase = phase
        self.special = special
        self.shellRewardMultiplier = shellRewardMultiplier
        self.victoryReward = victoryReward
        self.challengeGoal = max(1, challengeGoal)
        self.record = record
        self.onFinish = onFinish
        self.engine = EchoMelodyEngine(goal: max(1, challengeGoal))

        let resolvedPanelWidth = min(max(320, size.width - 28), 456)
        self.panelWidth = resolvedPanelWidth
        self.panelHeight = min(max(520, size.height - 54), 620)
        self.padRadius = min(46, max(38, resolvedPanelWidth * 0.108))
        self.playCenterY = -self.panelHeight * 0.205
        self.stageHeight = max(220, min(self.panelHeight - 360, resolvedPanelWidth * 0.62, 268))
        self.timerBarWidth = resolvedPanelWidth - 76

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, giverDisplay: giverDisplay)
        updateStatusUI()
        run(.sequence([
            .wait(forDuration: 0.42),
            .run { [weak self] in self?.startRound() }
        ]))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat) {
        guard !finished else { return }
        let timedOut = engine.update(dt: dt)
        updateTimerUI()
        if timedOut {
            GameAudio.shared.play(.tideInvalid, volumeMultiplier: 0.86)
            showFloatingLabel(text: "A maré escapou!",
                              at: CGPoint(x: 0, y: playCenterY + 40),
                              color: GameUI.coral,
                              size: 25,
                              drift: CGPoint(x: 0, y: panelHeight * 0.45))
            finish(reason: "timeout")
        }
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, giverDisplay: SKNode?) {
        addChild(makeBackdrop(size: size))

        let frame = makeFrame(size: CGSize(width: panelWidth, height: panelHeight))
        addChild(frame)

        let subtitle = special
            ? "Eco especial em \(zone.displayName)"
            : "Escute, memorize e devolva a melodia"
        let header = ChallengeChrome.makeHeader(kind: .echoMelody,
                                                subtitle: subtitle,
                                                giverDisplay: giverDisplay,
                                                width: panelWidth - 38)
        header.position = CGPoint(x: 0, y: panelHeight / 2 - 48)
        addChild(header)

        let chipGap: CGFloat = 8
        let chipWidth = (panelWidth - 48 - chipGap * 2) / 3
        let chipY = panelHeight / 2 - 178
        let scoreChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "music.note",
                                                                     fallback: "*",
                                                                     color: GameUI.gold,
                                                                     size: 18),
                                     title: "Pontos",
                                     value: "\(engine.score)",
                                     width: chipWidth,
                                     accent: GameUI.gold)
        scoreChip.node.position = CGPoint(x: -panelWidth / 2 + 24 + chipWidth / 2,
                                           y: chipY)
        addChild(scoreChip.node)
        scoreLabel = scoreChip.valueLabel

        let sequenceChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "waveform",
                                                                        fallback: "~",
                                                                        color: Visual.echo,
                                                                        size: 18),
                                        title: "Eco",
                                        value: sequenceText(),
                                        width: chipWidth,
                                        accent: Visual.echo)
        sequenceChip.node.position = CGPoint(x: 0, y: chipY)
        addChild(sequenceChip.node)
        sequenceLabel = sequenceChip.valueLabel

        let timerChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "timer",
                                                                     fallback: "s",
                                                                     color: GameUI.coral,
                                                                     size: 18),
                                     title: "Tempo",
                                     value: timerText(),
                                     width: chipWidth,
                                     accent: GameUI.coral)
        timerChip.node.position = CGPoint(x: panelWidth / 2 - 24 - chipWidth / 2,
                                           y: chipY)
        addChild(timerChip.node)
        timerLabel = timerChip.valueLabel

        bestLabel = SKLabelNode(text: record.bestScore > 0
                                ? "Recorde \(record.bestScore) · Meta \(challengeGoal)"
                                : "Meta \(challengeGoal)")
        bestLabel.fontName = "AvenirNext-Regular"
        bestLabel.fontSize = 11.5
        bestLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.70)
        bestLabel.verticalAlignmentMode = .center
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 226)
        bestLabel.zPosition = 24
        addChild(bestLabel)

        statusLabel = SKLabelNode(text: "A maré preparando a primeira nota")
        statusLabel.fontName = "AvenirNext-DemiBold"
        statusLabel.fontSize = 14.5
        statusLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.90)
        statusLabel.verticalAlignmentMode = .center
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.preferredMaxLayoutWidth = panelWidth - 46
        statusLabel.numberOfLines = 2
        statusLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 250)
        statusLabel.zPosition = 25
        addChild(statusLabel)

        addChild(makeTimerBar(y: panelHeight / 2 - 274))
        addChild(makeStageSurface())
        makePads()

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: 118,
                               height: 38)
        quit.name = "echo_quit"
        quit.position = CGPoint(x: 0, y: -panelHeight / 2 + 34)
        quit.zPosition = 50
        addChild(quit)
        quitButton = quit
    }

    private func makeBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let texture = GameUI.gradientTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                             colors: [
                                                UIColor.black.withAlphaComponent(0.24),
                                                UIColor.lerp(GameUI.accent, GameUI.ink, 0.34).withAlphaComponent(0.38),
                                                UIColor.lerp(Visual.violet, Visual.echo, 0.30).withAlphaComponent(0.20),
                                                UIColor.black.withAlphaComponent(0.34)
                                             ])
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.size = CGSize(width: size.width * 2, height: size.height * 2)
        backdrop.zPosition = -24
        node.addChild(backdrop)

        for index in 0..<18 {
            let y = size.height * 0.44 - CGFloat(index) * 42
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(index.isMultiple(of: 2) ? 20 : -18)),
                          controlPoint1: CGPoint(x: -size.width * 0.32, y: y - 36),
                          controlPoint2: CGPoint(x: size.width * 0.34, y: y + 42))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = UIColor.white.withAlphaComponent(0.046)
            wave.lineWidth = index.isMultiple(of: 4) ? 4 : 2
            wave.glowWidth = 8
            wave.zPosition = -15
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: index.isMultiple(of: 2) ? 24 : -18, y: 0, duration: 2.1),
                .moveBy(x: index.isMultiple(of: 2) ? -24 : 18, y: 0, duration: 2.1)
            ])))
        }

        for index in 0..<34 {
            let note = SKLabelNode(text: index.isMultiple(of: 3) ? "♪" : "·")
            note.fontName = "AvenirNext-Heavy"
            note.fontSize = CGFloat.random(in: 10...23)
            note.fontColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.06...0.15))
            note.verticalAlignmentMode = .center
            note.horizontalAlignmentMode = .center
            note.position = CGPoint(x: CGFloat.random(in: -size.width * 0.56...size.width * 0.56),
                                    y: CGFloat.random(in: -size.height * 0.54...size.height * 0.54))
            note.zPosition = -8
            node.addChild(note)
            note.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.035),
                .group([
                    .moveBy(x: CGFloat.random(in: -30...30),
                            y: size.height * CGFloat.random(in: 0.30...0.58),
                            duration: Double.random(in: 3.8...6.4)),
                    .fadeOut(withDuration: Double.random(in: 3.8...6.4)),
                    .rotate(byAngle: CGFloat.random(in: -0.9...0.9), duration: Double.random(in: 3.8...6.4))
                ]),
                .moveBy(x: 0, y: -size.height * 0.58, duration: 0),
                .fadeAlpha(to: 1.0, duration: 0.16)
            ])))
        }

        return node
    }

    private func makeFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: Visual.echo.withAlphaComponent(0.58),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -10

        let dark = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                               cornerRadius: 22)
        dark.fillTexture = GameUI.gradientTexture(size: size,
                                                  colors: [Visual.darkTop, Visual.darkMid, Visual.darkBottom])
        dark.fillColor = .white
        dark.strokeColor = GameUI.palePaper.withAlphaComponent(0.16)
        dark.lineWidth = 1.1
        dark.zPosition = 1
        node.addChild(dark)

        let pulse = SKShapeNode(rectOf: CGSize(width: size.width - 22, height: size.height - 22),
                                cornerRadius: 18)
        pulse.fillColor = Visual.echo.withAlphaComponent(0.046)
        pulse.strokeColor = GameUI.gold.withAlphaComponent(0.14)
        pulse.lineWidth = 1
        pulse.zPosition = 2
        node.addChild(pulse)
        pulse.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.48, duration: 0.62),
            .fadeAlpha(to: 1.0, duration: 0.62)
        ])))

        return node
    }

    private func makeStageSurface() -> SKNode {
        let node = SKNode()
        node.zPosition = -3

        let stageSize = CGSize(width: panelWidth - 44, height: stageHeight)
        let stage = SKShapeNode(rectOf: stageSize, cornerRadius: 30)
        stage.position = CGPoint(x: 0, y: playCenterY)
        stage.fillTexture = GameUI.gradientTexture(size: stageSize,
                                                   colors: [
                                                    UIColor.lerp(Visual.darkTop, Visual.echo, 0.18),
                                                    Visual.darkMid,
                                                    UIColor.lerp(Visual.darkBottom, Visual.violet, 0.18)
                                                   ])
        stage.fillColor = .white
        stage.strokeColor = Visual.echo.withAlphaComponent(0.32)
        stage.lineWidth = 1.6
        stage.glowWidth = 4
        node.addChild(stage)

        let centerRing = SKShapeNode(circleOfRadius: min(68, stageHeight * 0.23))
        centerRing.position = CGPoint(x: 0, y: playCenterY)
        centerRing.fillColor = Visual.echo.withAlphaComponent(0.07)
        centerRing.strokeColor = GameUI.gold.withAlphaComponent(0.24)
        centerRing.lineWidth = 1.2
        centerRing.glowWidth = 8
        centerRing.zPosition = 2
        node.addChild(centerRing)
        centerRing.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.88),
            .scale(to: 1.0, duration: 0.88)
        ])))

        let music = SKLabelNode(text: "♪")
        music.fontName = "AvenirNext-Heavy"
        music.fontSize = 44
        music.fontColor = GameUI.gold.withAlphaComponent(0.86)
        music.verticalAlignmentMode = .center
        music.horizontalAlignmentMode = .center
        music.position = CGPoint(x: 0, y: playCenterY)
        music.zPosition = 3
        node.addChild(music)
        music.run(.repeatForever(.sequence([
            .rotate(byAngle: 0.22, duration: 0.38),
            .rotate(byAngle: -0.22, duration: 0.38)
        ])))

        return node
    }

    private func makePads() {
        let horizontal = min(panelWidth * 0.28, 112)
        let vertical = min(stageHeight * 0.28, 74)
        let positions: [EchoMelodyNote: CGPoint] = [
            .pearl: CGPoint(x: 0, y: playCenterY + vertical),
            .coral: CGPoint(x: horizontal, y: playCenterY),
            .kelp: CGPoint(x: 0, y: playCenterY - vertical),
            .moon: CGPoint(x: -horizontal, y: playCenterY)
        ]

        for note in EchoMelodyNote.allCases {
            let pad = makePad(note: note)
            pad.position = positions[note] ?? .zero
            addChild(pad)
            padNodes[note] = pad
        }
    }

    private func makePad(note: EchoMelodyNote) -> SKNode {
        let node = SKNode()
        let name = padName(for: note)
        node.name = name
        node.zPosition = 18

        let shadow = SKShapeNode(circleOfRadius: padRadius)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.24)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -5)
        shadow.zPosition = -3
        node.addChild(shadow)

        let body = SKShapeNode(circleOfRadius: padRadius)
        body.fillTexture = GameUI.gradientTexture(size: CGSize(width: padRadius * 2, height: padRadius * 2),
                                                  colors: [
                                                    UIColor.lerp(note.color, .white, 0.36),
                                                    note.color,
                                                    UIColor.lerp(note.color, Visual.darkBottom, 0.34)
                                                  ])
        body.fillColor = .white
        body.strokeColor = UIColor.white.withAlphaComponent(0.56)
        body.lineWidth = 1.4
        body.glowWidth = 2
        body.name = name
        node.addChild(body)

        let icon = GameUI.symbolIconNode(named: note.symbolName,
                                         fallback: note.title,
                                         color: GameUI.palePaper,
                                         size: padRadius * 0.48)
        icon.position = CGPoint(x: 0, y: padRadius * 0.12)
        icon.zPosition = 4
        assignName(name, to: icon)
        node.addChild(icon)

        let noteLabel = SKLabelNode(text: note.title)
        noteLabel.fontName = "AvenirNext-Heavy"
        noteLabel.fontSize = padRadius * 0.26
        noteLabel.fontColor = GameUI.ink.withAlphaComponent(0.78)
        noteLabel.verticalAlignmentMode = .center
        noteLabel.horizontalAlignmentMode = .center
        noteLabel.position = CGPoint(x: 0, y: -padRadius * 0.38)
        noteLabel.zPosition = 5
        noteLabel.name = name
        node.addChild(noteLabel)

        node.run(.repeatForever(.sequence([
            .scale(to: 1.018, duration: Double.random(in: 0.58...0.76)),
            .scale(to: 1.0, duration: Double.random(in: 0.52...0.70))
        ])), withKey: "echo_idle")

        return node
    }

    private func makeInfoChip(iconNode: SKNode,
                              title: String,
                              value: String,
                              width: CGFloat,
                              accent: UIColor) -> (node: SKNode, valueLabel: SKLabelNode) {
        let node = SKNode()
        node.zPosition = 20
        let size = CGSize(width: width, height: 48)
        let bg = SKShapeNode(rectOf: size, cornerRadius: 16)
        bg.fillTexture = GameUI.paperTexture(size: size, base: GameUI.paper)
        bg.fillColor = .white
        bg.strokeColor = accent.withAlphaComponent(0.55)
        bg.lineWidth = 1.4
        node.addChild(bg)

        iconNode.position = CGPoint(x: -width / 2 + 20, y: -1)
        node.addChild(iconNode)

        let titleLabel = SKLabelNode(text: title.uppercased())
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 8.2
        titleLabel.fontColor = GameUI.mutedInk
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -width / 2 + 38, y: 12)
        node.addChild(titleLabel)

        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Heavy"
        valueLabel.fontSize = 13.5
        valueLabel.fontColor = GameUI.ink
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.verticalAlignmentMode = .center
        valueLabel.preferredMaxLayoutWidth = width - 48
        valueLabel.position = CGPoint(x: titleLabel.position.x, y: -8)
        node.addChild(valueLabel)

        ChallengeChrome.fitSingleLineLabel(valueLabel,
                                           maxWidth: width - 48,
                                           maxFontSize: 13,
                                           minFontSize: 10.2)
        return (node, valueLabel)
    }

    private func makeTimerBar(y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 22

        let back = SKShapeNode(rectOf: CGSize(width: timerBarWidth, height: 10), cornerRadius: 5)
        back.fillColor = GameUI.line.withAlphaComponent(0.12)
        back.strokeColor = GameUI.line.withAlphaComponent(0.20)
        back.lineWidth = 1
        node.addChild(back)

        timerBarFill = SKShapeNode(rectOf: CGSize(width: timerBarWidth, height: 10), cornerRadius: 5)
        timerBarFill.fillColor = Visual.echo.withAlphaComponent(0.82)
        timerBarFill.strokeColor = .clear
        timerBarFill.glowWidth = 2
        timerBarFill.zPosition = 1
        node.addChild(timerBarFill)
        return node
    }

    // MARK: - Rodadas

    private func startRound() {
        guard !finished else { return }
        acceptingInput = false
        let sequence = engine.startNextRound()
        updateStatusUI()
        statusLabel.text = "Escute a maré cantar..."
        showFloatingLabel(text: "ESCUTE",
                          at: CGPoint(x: 0, y: playCenterY + 18),
                          color: Visual.echo,
                          size: 29,
                          drift: CGPoint(x: 0, y: min(118, panelHeight * 0.20)))
        playSequence(sequence)
    }

    private func playSequence(_ sequence: [EchoMelodyNote]) {
        removeAction(forKey: "echo_sequence")
        let step = EchoMelodyRules.playbackStepDuration(sequenceLength: sequence.count)
        var actions: [SKAction] = [.wait(forDuration: 0.34)]

        for (index, note) in sequence.enumerated() {
            actions.append(.run { [weak self] in
                guard let self else { return }
                self.statusLabel.text = "Eco \(index + 1) de \(sequence.count)"
                self.flashPad(note: note, demo: true)
                GameAudio.shared.playMelodyTone(frequency: note.frequency,
                                                duration: max(0.18, step * 0.72),
                                                volume: 0.18)
            })
            actions.append(.wait(forDuration: step))
        }

        actions.append(.run { [weak self] in
            guard let self, !self.finished else { return }
            self.engine.beginListening()
            self.acceptingInput = true
            self.statusLabel.text = "Agora canta a mesma sequência!"
            self.updateStatusUI()
            self.showFloatingLabel(text: "SUA VEZ",
                                   at: CGPoint(x: 0, y: self.playCenterY + 18),
                                   color: GameUI.gold,
                                   size: 28,
                                   drift: CGPoint(x: CGFloat.random(in: -18...18),
                                                  y: min(112, self.panelHeight * 0.19)))
        })

        run(.sequence(actions), withKey: "echo_sequence")
    }

    private func handleInput(note: EchoMelodyNote) {
        guard acceptingInput, !finished else {
            GameAudio.shared.play(.uiReject, volumeMultiplier: 0.72)
            return
        }
        acceptingInput = false
        flashPad(note: note, demo: false)
        GameAudio.shared.playMelodyTone(frequency: note.frequency,
                                        duration: 0.26,
                                        volume: 0.20)

        guard let result = engine.register(note) else {
            acceptingInput = true
            return
        }

        if !result.correct {
            statusLabel.text = "Era \(result.expected.title). A onda quebrou."
            showFloatingLabel(text: "Eco partiu!",
                              at: padNodes[note]?.position ?? CGPoint(x: 0, y: playCenterY),
                              color: GameUI.coral,
                              size: 24,
                              drift: CGPoint(x: 0, y: panelHeight * 0.44))
            run(.sequence([
                .wait(forDuration: 0.42),
                .run { [weak self] in self?.finish(reason: "miss") }
            ]))
            return
        }

        showFloatingLabel(text: "+\(result.hitPoints)",
                          at: padNodes[note]?.position ?? CGPoint(x: 0, y: playCenterY),
                          color: note.color,
                          size: 18,
                          drift: CGPoint(x: CGFloat.random(in: -12...12), y: 48))

        if result.reachedGoalNow {
            showGoalCompleteBurst()
        }

        if result.completedRound {
            updateStatusUI()
            showFloatingLabel(text: "ECO PERFEITO +\(result.roundBonus)",
                              at: CGPoint(x: 0, y: playCenterY + 24),
                              color: GameUI.gold,
                              size: 24,
                              drift: CGPoint(x: 0, y: min(130, panelHeight * 0.22)))
            GameAudio.shared.play(.tideCascade, volumeMultiplier: 0.82, cooldownOverride: 0.05)

            if engine.finished {
                run(.sequence([
                    .wait(forDuration: 0.62),
                    .run { [weak self] in self?.finish(reason: "complete") }
                ]))
            } else {
                run(.sequence([
                    .wait(forDuration: 0.72),
                    .run { [weak self] in self?.startRound() }
                ]))
            }
        } else {
            acceptingInput = true
            updateStatusUI()
        }
    }

    private func flashPad(note: EchoMelodyNote, demo: Bool) {
        guard let pad = padNodes[note] else { return }
        pad.removeAction(forKey: "echo_flash")
        pad.run(.sequence([
            .scale(to: demo ? 1.18 : 1.12, duration: 0.08),
            .scale(to: 1.0, duration: 0.18)
        ]), withKey: "echo_flash")

        let ring = SKShapeNode(circleOfRadius: padRadius + (demo ? 12 : 8))
        ring.fillColor = note.color.withAlphaComponent(demo ? 0.20 : 0.14)
        ring.strokeColor = UIColor.white.withAlphaComponent(demo ? 0.72 : 0.56)
        ring.lineWidth = demo ? 2.2 : 1.5
        ring.glowWidth = demo ? 10 : 6
        ring.zPosition = -1
        pad.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: demo ? 1.32 : 1.20, duration: demo ? 0.34 : 0.24),
                .fadeOut(withDuration: demo ? 0.34 : 0.24)
            ]),
            .removeFromParent()
        ]))

        for index in 0..<5 {
            let sparkle = SKLabelNode(text: index.isMultiple(of: 2) ? "♪" : "✦")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = CGFloat.random(in: 9...16)
            sparkle.fontColor = UIColor.lerp(note.color, .white, CGFloat.random(in: 0.16...0.48))
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = CGPoint(x: CGFloat.random(in: -padRadius * 0.45...padRadius * 0.45),
                                       y: CGFloat.random(in: -padRadius * 0.45...padRadius * 0.45))
            sparkle.zPosition = 8
            pad.addChild(sparkle)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -24...24),
                            y: CGFloat.random(in: 26...52),
                            duration: Double.random(in: 0.34...0.56)),
                    .fadeOut(withDuration: Double.random(in: 0.34...0.56)),
                    .rotate(byAngle: CGFloat.random(in: -0.7...0.7), duration: 0.46)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - UI dinamica

    private func updateStatusUI() {
        guard scoreLabel != nil else { return }
        scoreLabel.text = "\(engine.score)"
        sequenceLabel.text = sequenceText()
        timerLabel.text = timerText()
        ChallengeChrome.fitSingleLineLabel(scoreLabel,
                                           maxWidth: max(36, scoreLabel.preferredMaxLayoutWidth),
                                           maxFontSize: 13,
                                           minFontSize: 10.2)
        ChallengeChrome.fitSingleLineLabel(sequenceLabel,
                                           maxWidth: max(36, sequenceLabel.preferredMaxLayoutWidth),
                                           maxFontSize: 13,
                                           minFontSize: 10.2)
        ChallengeChrome.fitSingleLineLabel(timerLabel,
                                           maxWidth: max(36, timerLabel.preferredMaxLayoutWidth),
                                           maxFontSize: 13,
                                           minFontSize: 10.2)
        updateTimerUI()
    }

    private func updateTimerUI() {
        guard timerLabel != nil, timerBarFill != nil else { return }
        timerLabel.text = timerText()
        let progress: CGFloat
        if engine.phase == .listening {
            progress = (engine.inputTimeLeft / EchoMelodyRules.inputTimeout).clamped(to: 0...1)
        } else {
            progress = 1
        }
        let visible = max(0.012, progress)
        timerBarFill.xScale = visible
        timerBarFill.position = CGPoint(x: -timerBarWidth / 2 + timerBarWidth * visible / 2, y: 0)
        timerBarFill.fillColor = progress < 0.24
            ? GameUI.coral.withAlphaComponent(0.86)
            : (engine.challengeCompleted ? GameUI.gold.withAlphaComponent(0.88) : Visual.echo.withAlphaComponent(0.82))
    }

    private func sequenceText() -> String {
        "\(max(1, engine.round)) notas"
    }

    private func timerText() -> String {
        switch engine.phase {
        case .listening:
            return "\(max(0, Int(ceil(engine.inputTimeLeft))))s"
        case .singing:
            return "ouve"
        case .resting:
            return "prepara"
        case .finished:
            return "fim"
        }
    }

    private func showGoalCompleteBurst() {
        GameAudio.shared.play(.tideGoal, volumeMultiplier: 0.86)
        let label = SKLabelNode(text: "A META CANTOU!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 28
        label.fontColor = GameUI.algae
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: playCenterY + 68)
        label.zPosition = 135
        label.setScale(0.58)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1.12, duration: 0.14),
                .fadeAlpha(to: 1.0, duration: 0.14)
            ]),
            .wait(forDuration: 0.34),
            .group([
                .moveBy(x: 0, y: panelHeight * 0.42, duration: 0.72),
                .fadeOut(withDuration: 0.72),
                .rotate(byAngle: 0.18, duration: 0.72)
            ]),
            .removeFromParent()
        ]))
    }

    private func showFloatingLabel(text: String,
                                   at position: CGPoint,
                                   color: UIColor,
                                   size: CGFloat,
                                   drift: CGPoint) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = size
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = position
        label.zPosition = 130
        label.alpha = 0
        addChild(label)
        label.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.08),
                .scale(to: 1.12, duration: 0.08)
            ]),
            .group([
                .moveBy(x: drift.x, y: drift.y, duration: 0.74),
                .fadeOut(withDuration: 0.74),
                .scale(to: 0.92, duration: 0.74),
                .rotate(byAngle: CGFloat.random(in: -0.18...0.18), duration: 0.74)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Resultado

    private func projectedPearls(reached: Bool) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .echoMelody,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false,
                                                          victoryReward: victoryReward)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: engine.score,
                                                      multiplier: shellRewardMultiplier)
    }

    private func finish(reason: String) {
        guard !finished else { return }
        finished = true
        acceptingInput = false
        removeAction(forKey: "echo_sequence")
        engine.forceFinish()
        quitButton?.isHidden = true
        updateStatusUI()

        let reached = engine.challengeCompleted || engine.score >= challengeGoal
        GameAudio.shared.play(reached ? .challengeSuccess : .challengeFail)

        let basePearls = GameBalance.challengeShellReward(points: engine.score,
                                                          kind: .echoMelody,
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

        let titleText: String
        if reached {
            titleText = "Canto completo!"
        } else if reason == "timeout" {
            titleText = "A nota fugiu."
        } else if reason == "miss" {
            titleText = "Eco quebrado."
        } else {
            titleText = "Canto guardado."
        }

        let titleLabel = SKLabelNode(text: titleText)
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 18.5
        titleLabel.fontColor = GameUI.ink
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 82)
        ChallengeChrome.fitSingleLineLabel(titleLabel,
                                           maxWidth: 286,
                                           maxFontSize: 18.5,
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

        let detail = SKLabelNode(text: "\(engine.perfectRounds) ecos perfeitos • maior sequência \(engine.round)")
        detail.fontName = "AvenirNext-Regular"
        detail.fontSize = 13.5
        detail.fontColor = GameUI.mutedInk
        detail.verticalAlignmentMode = .center
        detail.position = CGPoint(x: 0, y: 23)
        ChallengeChrome.fitSingleLineLabel(detail,
                                           maxWidth: 282,
                                           maxFontSize: 13.5,
                                           minFontSize: 10.5)
        content.addChild(detail)

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
                                               newRecord: record.isNewRecord(score: engine.score))

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "echo_continue"
        continueButton.position = CGPoint(x: 0, y: -104)
        content.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .echoMelody,
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
        let panel = GameUI.card(size: CGSize(width: 304, height: 250),
                                cornerRadius: 22,
                                tint: resultTint,
                                baseColors: [UIColor.lerp(GameUI.palePaper, resultTint, 0.28)])
        panel.position = CGPoint(x: 0, y: playCenterY + 58)
        return panel
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "echo_continue" {
                GameAudio.shared.play(.uiConfirm)
                if let pendingResult {
                    onFinish(pendingResult)
                }
                return
            }
            node = current.parent
        }
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
            if current.name == "echo_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish(reason: "quit")
                return
            }
            if let name = current.name,
               let note = note(fromPadName: name) {
                handleInput(note: note)
                return
            }
            node = current.parent
        }
    }

    private func padName(for note: EchoMelodyNote) -> String {
        "echo_pad_\(note.rawValue)"
    }

    private func note(fromPadName name: String) -> EchoMelodyNote? {
        guard name.hasPrefix("echo_pad_"),
              let raw = Int(name.dropFirst("echo_pad_".count)) else { return nil }
        return EchoMelodyNote(rawValue: raw)
    }

    private func assignName(_ name: String, to node: SKNode) {
        node.name = name
        node.children.forEach { assignName(name, to: $0) }
    }
}
