//
//  TideMemorySystem.swift
//  Ester
//
//  Desafio: Lembranças da Maré. Jogo da memória solo: virar duas cartas,
//  encontrar pares e iniciar outra lembrança sempre que o tabuleiro fecha.
//

import Foundation
import SpriteKit

// MARK: - Regras puras

private struct TideMemoryTimeRecovery {
    let timeLeft: CGFloat
    let addedTime: CGFloat
}

private enum TideMemoryRules {
    static let rows = 4
    static let columns = 4
    static let startTime: CGFloat = 52
    static let maxTime: CGFloat = 68
    static let mismatchPenalty: CGFloat = 1.6
    static let comboWindow: CGFloat = 3.8
    static let flipFadeOutDuration: TimeInterval = 0.045
    static let flipFadeInDuration: TimeInterval = 0.045

    static var pairCount: Int {
        rows * columns / 2
    }

    static func goal(for zone: DepthZone, special: Bool, wave: Int) -> Int {
        GameBalance.challengeGoalFallback(for: .memory, zone: zone, special: special)
            + max(0, wave - 1) * GameBalance.memoryChallengeWaveGoalStep
    }

    static func matchPoints(streak: Int, revealGap: CGFloat, remainingPairs: Int) -> Int {
        let base = 14
        let streakBonus = min(32, max(0, streak - 1) * 5)
        let quickBonus: Int
        if revealGap <= 1.7 {
            quickBonus = 10
        } else if revealGap <= 2.8 {
            quickBonus = 6
        } else if revealGap <= 4.0 {
            quickBonus = 3
        } else {
            quickBonus = 0
        }
        let closeoutBonus = remainingPairs <= 2 ? 6 : 0
        return base + streakBonus + quickBonus + closeoutBonus
    }

    static func timeBonus(streak: Int, revealGap: CGFloat, timeLeft: CGFloat) -> CGFloat {
        let base: CGFloat = 0.65
        let quickBonus: CGFloat
        if revealGap <= 1.4 {
            quickBonus = 1.15
        } else if revealGap <= 2.5 {
            quickBonus = 0.80
        } else if revealGap <= 4.0 {
            quickBonus = 0.45
        } else {
            quickBonus = 0.20
        }

        let streakBonus = streak >= 2 ? min(1.40, CGFloat(streak - 1) * 0.28) : 0
        let pressureBonus: CGFloat
        if timeLeft <= 14 {
            pressureBonus = 0.85
        } else if timeLeft <= 24 {
            pressureBonus = 0.45
        } else {
            pressureBonus = 0
        }

        return min(3.10, base + quickBonus + streakBonus + pressureBonus)
    }

    static func finalBonus(timeLeft: CGFloat, mistakes: Int, allMatched: Bool) -> Int {
        guard allMatched else { return 0 }
        let timeScore = Int((timeLeft * 1.8).rounded())
        let memoryScore = max(0, 28 - mistakes * 3)
        return timeScore + memoryScore
    }

    static func waveBonus(wave: Int, timeLeft: CGFloat, mistakesThisWave: Int) -> Int {
        let timeScore = Int((timeLeft * 0.9).rounded())
        let cleanScore = max(0, 18 - mistakesThisWave * 3)
        return 24 + wave * 6 + timeScore + cleanScore
    }

    static func waveTimeBonus(wave: Int, mistakesThisWave: Int) -> CGFloat {
        let cleanBonus: CGFloat
        if mistakesThisWave == 0 {
            cleanBonus = 6.0
        } else if mistakesThisWave <= 2 {
            cleanBonus = 3.0
        } else {
            cleanBonus = 0
        }

        let waveRamp = min(2.0, CGFloat(wave) * 0.18)
        let mistakeTax = min(4.0, CGFloat(mistakesThisWave) * 0.60)
        return max(6.0, min(14.0, 8.0 + waveRamp + cleanBonus - mistakeTax))
    }

    static func waveTimeFloor(mistakesThisWave: Int) -> CGFloat {
        switch mistakesThisWave {
        case 0:
            return 46
        case 1...2:
            return 40
        case 3...5:
            return 34
        default:
            return 28
        }
    }

    static func recoverTimeAfterWave(currentTime: CGFloat,
                                     wave: Int,
                                     mistakesThisWave: Int) -> TideMemoryTimeRecovery {
        let additiveTime = currentTime + waveTimeBonus(wave: wave,
                                                       mistakesThisWave: mistakesThisWave)
        let floorTime = waveTimeFloor(mistakesThisWave: mistakesThisWave)
        let recoveredTime = min(maxTime, max(additiveTime, floorTime))
        return TideMemoryTimeRecovery(timeLeft: recoveredTime,
                                      addedTime: recoveredTime - currentTime)
    }
}

private struct TideMemoryTheme {
    let icons: [String]
    let subtitle: String
    let colors: [UIColor]

    static func theme(for zone: DepthZone) -> TideMemoryTheme {
        let colors = [
            GameUI.gold,
            GameUI.coral,
            UIColor(red: 0.31, green: 0.72, blue: 0.86, alpha: 1),
            GameUI.algae,
            UIColor(red: 0.58, green: 0.48, blue: 0.82, alpha: 1),
            UIColor(red: 0.88, green: 0.60, blue: 0.34, alpha: 1),
            UIColor(red: 0.38, green: 0.78, blue: 0.66, alpha: 1),
            UIColor(red: 0.82, green: 0.40, blue: 0.62, alpha: 1)
        ]

        switch zone {
        case .surface:
            return TideMemoryTheme(icons: ["🐬", "🫧", "⭐️", "🐠", "🐚", "🌙", "🪸", "💎"],
                                   subtitle: "Lembranças refletidas na superfície",
                                   colors: colors)
        case .clear:
            return TideMemoryTheme(icons: ["🐚", "🫧", "🐠", "⭐️", "🦀", "🌙", "🪸", "💎"],
                                   subtitle: "Lembranças da Camada Clara",
                                   colors: colors)
        case .shallow:
            return TideMemoryTheme(icons: ["🐚", "🐠", "🦀", "🐡", "⭐️", "🪸", "💎", "🌙"],
                                   subtitle: "Ecos vivos da Camada Rasa",
                                   colors: colors)
        case .mid:
            return TideMemoryTheme(icons: ["🫧", "🐠", "🐙", "🐡", "🐚", "🦑", "💎", "🪸"],
                                   subtitle: "Memórias cruzando a maré média",
                                   colors: colors)
        case .blue:
            return TideMemoryTheme(icons: ["🫧", "🐬", "🐠", "🦑", "🐚", "💎", "🌙", "🪸"],
                                   subtitle: "Clarões guardados na Camada Azul",
                                   colors: colors)
        case .deep:
            return TideMemoryTheme(icons: ["🦑", "🐙", "🐡", "⭐️", "🐚", "💎", "🌙", "🫧"],
                                   subtitle: "Lembranças sob pressão profunda",
                                   colors: colors)
        case .abyss:
            return TideMemoryTheme(icons: ["🐙", "🦑", "🐡", "🫧", "🐚", "💎", "🌙", "⭐️"],
                                   subtitle: "Memórias brilhando no abismo",
                                   colors: colors)
        }
    }
}

// MARK: - Modelo puro de tabuleiro

private struct TideMemoryPosition: Hashable {
    let row: Int
    let column: Int
}

private enum TideMemoryCardState {
    case faceDown
    case faceUp
    case matched
}

private struct TideMemoryCard {
    let id = UUID()
    let kind: Int
    var state: TideMemoryCardState = .faceDown
}

private struct TideMemoryResolution {
    let first: TideMemoryPosition
    let second: TideMemoryPosition
    let matched: Bool
    let kind: Int
}

private final class TideMemoryBoard {
    let rows: Int
    let columns: Int
    let kindCount: Int

    private(set) var cards: [[TideMemoryCard]]

    init(rows: Int, columns: Int, kindCount: Int) {
        self.rows = rows
        self.columns = columns
        self.kindCount = kindCount
        self.cards = []
        reset()
    }

    var matchedPairs: Int {
        cards.flatMap { $0 }.filter { $0.state == .matched }.count / 2
    }

    var remainingPairs: Int {
        rows * columns / 2 - matchedPairs
    }

    var allMatched: Bool {
        remainingPairs == 0
    }

    func card(at position: TideMemoryPosition) -> TideMemoryCard {
        cards[position.row][position.column]
    }

    func reveal(at position: TideMemoryPosition) -> TideMemoryCard? {
        guard isValid(position) else { return nil }
        guard cards[position.row][position.column].state == .faceDown else { return nil }
        cards[position.row][position.column].state = .faceUp
        return cards[position.row][position.column]
    }

    func resolve(first: TideMemoryPosition, second: TideMemoryPosition) -> TideMemoryResolution {
        let firstCard = card(at: first)
        let secondCard = card(at: second)
        let matched = firstCard.kind == secondCard.kind
        if matched {
            cards[first.row][first.column].state = .matched
            cards[second.row][second.column].state = .matched
        } else {
            cards[first.row][first.column].state = .faceDown
            cards[second.row][second.column].state = .faceDown
        }
        return TideMemoryResolution(first: first,
                                    second: second,
                                    matched: matched,
                                    kind: firstCard.kind)
    }

    func startNextWave() {
        reset()
    }

    private func reset() {
        let totalCards = rows * columns
        let pairs = totalCards / 2
        let kinds = (0..<pairs).map { $0 % kindCount }
        let deck = (kinds + kinds).shuffled().map { TideMemoryCard(kind: $0) }
        cards = (0..<rows).map { row in
            (0..<columns).map { column in
                deck[row * columns + column]
            }
        }
    }

    private func isValid(_ position: TideMemoryPosition) -> Bool {
        position.row >= 0 && position.row < rows
            && position.column >= 0 && position.column < columns
    }
}

// MARK: - Overlay SpriteKit

final class TideMemoryOverlay: SKNode {
    private let theme: TideMemoryTheme
    private let board: TideMemoryBoard
    private let phase: MermaidPhase
    private let zone: DepthZone
    private let special: Bool
    private let shellRewardMultiplier: CGFloat
    private let victoryReward: ChallengeVictoryReward
    private let initialGoal: Int
    private let bestScore: Int
    private let record: ChallengeRecordSnapshot
    private let onFinish: (ChallengeResult) -> Void

    private let boardWidth: CGFloat
    private let boardHeight: CGFloat
    private let cellSize: CGFloat
    private let gridOrigin: CGPoint

    private var cardNodes: [[SKNode?]]
    private var revealed: [TideMemoryPosition] = []
    private var score = 0
    private var mistakes = 0
    private var mistakesThisWave = 0
    private var streak = 0
    private var wave = 1
    private var timeLeft = TideMemoryRules.startTime
    private var timeSinceLastMatch = TideMemoryRules.comboWindow + 1
    private var firstRevealAge: CGFloat = 0
    private var challengeCompleted = false
    private var busy = false
    private var finished = false
    private var pendingResult: ChallengeResult?

    private let boardNode = SKNode()
    private var scoreLabel: SKLabelNode!
    private var objectiveLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var streakLabel: SKLabelNode!
    private var bestLabel: SKLabelNode!
    private var timerBarFill: SKShapeNode!
    private var timerBarWidth: CGFloat = 0
    private var timerBarLeft: CGFloat = 0

    private enum Visual {
        static let darkTop = UIColor(red: 0.04, green: 0.18, blue: 0.26, alpha: 1)
        static let darkMid = UIColor(red: 0.03, green: 0.12, blue: 0.22, alpha: 1)
        static let darkBottom = UIColor(red: 0.02, green: 0.05, blue: 0.13, alpha: 1)
        static let memoryBlue = UIColor(red: 0.38, green: 0.86, blue: 0.92, alpha: 1)
        static let rose = UIColor(red: 0.96, green: 0.48, blue: 0.48, alpha: 1)
        static let violet = UIColor(red: 0.56, green: 0.48, blue: 0.86, alpha: 1)
    }

    init(size: CGSize,
         zone: DepthZone,
         phase: MermaidPhase,
         special: Bool,
         shellRewardMultiplier: CGFloat,
         victoryReward: ChallengeVictoryReward,
         initialGoal: Int,
         giverDisplay: SKNode?,
         record: ChallengeRecordSnapshot,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.theme = TideMemoryTheme.theme(for: zone)
        self.zone = zone
        self.phase = phase
        self.special = special
        self.shellRewardMultiplier = shellRewardMultiplier
        self.victoryReward = victoryReward
        self.initialGoal = initialGoal
        self.bestScore = record.bestScore
        self.record = record
        self.onFinish = onFinish
        self.board = TideMemoryBoard(rows: TideMemoryRules.rows,
                                     columns: TideMemoryRules.columns,
                                     kindCount: theme.icons.count)

        let availableWidth = max(270, size.width - 36)
        let availableHeight = max(280, size.height - 432)
        let resolvedBoardWidth = min(availableWidth, availableHeight, 386)
        self.boardWidth = resolvedBoardWidth
        self.cellSize = resolvedBoardWidth / CGFloat(TideMemoryRules.columns)
        self.boardHeight = cellSize * CGFloat(TideMemoryRules.rows)
        self.gridOrigin = CGPoint(x: -resolvedBoardWidth / 2, y: -boardHeight / 2 - 30)
        self.cardNodes = Array(repeating: Array<SKNode?>(repeating: nil, count: TideMemoryRules.columns),
                               count: TideMemoryRules.rows)

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, giverDisplay: giverDisplay)
        rebuildCards(animated: true)
        updateStatusUI()
        GameAudio.shared.play(.tideSelect, volumeMultiplier: 0.78)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat) {
        guard !finished else { return }
        timeLeft = max(0, timeLeft - dt)
        timeSinceLastMatch += dt
        if revealed.count == 1 {
            firstRevealAge += dt
        }
        if streak > 0 && timeSinceLastMatch > TideMemoryRules.comboWindow {
            streak = 0
            updateStatusUI()
        }
        updateTimerUI()
        if timeLeft <= 0 {
            finish()
        }
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, giverDisplay: SKNode?) {
        addChild(makeBackdrop(size: size))

        let frame = makeFrame(size: CGSize(width: boardWidth + 34, height: boardHeight + 330))
        frame.position = CGPoint(x: 0, y: 42)
        addChild(frame)

        let header = ChallengeChrome.makeHeader(kind: .memory,
                                                subtitle: theme.subtitle,
                                                giverDisplay: giverDisplay,
                                                width: boardWidth)
        header.position = CGPoint(x: 0, y: boardHeight / 2 + 154)
        addChild(header)

        let chipWidth = (boardWidth - 14) / 2
        let scoreChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "brain.head.profile",
                                                                     fallback: "?",
                                                                     color: GameUI.gold,
                                                                     size: 22),
                                     title: "Pontos",
                                     value: "\(score)",
                                     width: chipWidth,
                                     accent: GameUI.gold)
        scoreChip.node.position = CGPoint(x: gridOrigin.x + chipWidth / 2,
                                           y: boardHeight / 2 + 48)
        addChild(scoreChip.node)
        scoreLabel = scoreChip.valueLabel

        let objectiveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                         fallback: "o",
                                                                         color: GameUI.coral,
                                                                         size: 22),
                                         title: "Onda",
                                         value: objectiveText(),
                                         width: chipWidth,
                                         accent: GameUI.coral)
        objectiveChip.node.position = CGPoint(x: gridOrigin.x + chipWidth * 1.5 + 14,
                                              y: boardHeight / 2 + 48)
        addChild(objectiveChip.node)
        objectiveLabel = objectiveChip.valueLabel

        timerBarWidth = boardWidth - 34
        timerBarLeft = -timerBarWidth / 2
        addChild(makeTimerBar(width: timerBarWidth, y: boardHeight / 2 - 10))

        streakLabel = SKLabelNode(text: "Memória pronta")
        streakLabel.fontName = "AvenirNext-DemiBold"
        streakLabel.fontSize = 13
        streakLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.88)
        streakLabel.verticalAlignmentMode = .center
        streakLabel.horizontalAlignmentMode = .center
        streakLabel.position = CGPoint(x: 0, y: boardHeight / 2 + 80)
        streakLabel.zPosition = 35
        addChild(streakLabel)

        bestLabel = SKLabelNode(text: bestScore > 0 ? "Recorde \(bestScore)" : "Novo desafio")
        bestLabel.fontName = "AvenirNext-Regular"
        bestLabel.fontSize = 11.5
        bestLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.70)
        bestLabel.verticalAlignmentMode = .center
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.position = CGPoint(x: 0, y: boardHeight / 2 + 104)
        bestLabel.zPosition = 35
        addChild(bestLabel)

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: 118,
                               height: 38)
        quit.name = "memory_quit"
        quit.position = CGPoint(x: 0, y: gridOrigin.y - 56)
        quit.zPosition = 20
        addChild(quit)

        boardNode.addChild(makeBoardSurface())
        addChild(boardNode)
    }

    private func makeBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let texture = GameUI.gradientTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                             colors: [
                                                UIColor.black.withAlphaComponent(0.24),
                                                UIColor.lerp(GameUI.accent, GameUI.ink, 0.34).withAlphaComponent(0.34),
                                                UIColor.lerp(Visual.violet, GameUI.gold, 0.18).withAlphaComponent(0.18),
                                                UIColor.black.withAlphaComponent(0.32)
                                             ])
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.size = CGSize(width: size.width * 2, height: size.height * 2)
        backdrop.zPosition = -20
        node.addChild(backdrop)

        for i in 0..<10 {
            let path = UIBezierPath()
            let y = size.height * 0.42 - CGFloat(i) * 54
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(i.isMultiple(of: 2) ? 22 : -16)),
                          controlPoint1: CGPoint(x: -size.width * 0.32, y: y - 42),
                          controlPoint2: CGPoint(x: size.width * 0.35, y: y + 44))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = UIColor.white.withAlphaComponent(0.052)
            wave.lineWidth = 3
            wave.glowWidth = 7
            wave.zPosition = -10
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: i.isMultiple(of: 2) ? 26 : -20, y: 0, duration: 2.4),
                .moveBy(x: i.isMultiple(of: 2) ? -26 : 20, y: 0, duration: 2.4)
            ])))
        }

        for index in 0..<28 {
            let glyph = SKLabelNode(text: index.isMultiple(of: 3) ? "?" : "•")
            glyph.fontName = "AvenirNext-Heavy"
            glyph.fontSize = CGFloat.random(in: 8...18)
            glyph.fontColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.05...0.13))
            glyph.verticalAlignmentMode = .center
            glyph.horizontalAlignmentMode = .center
            glyph.position = CGPoint(x: CGFloat.random(in: -size.width * 0.55...size.width * 0.55),
                                     y: CGFloat.random(in: -size.height * 0.52...size.height * 0.52))
            glyph.zPosition = -8
            node.addChild(glyph)
            glyph.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.05),
                .group([
                    .moveBy(x: CGFloat.random(in: -20...20),
                            y: size.height * CGFloat.random(in: 0.24...0.44),
                            duration: Double.random(in: 4.0...6.8)),
                    .fadeOut(withDuration: Double.random(in: 4.0...6.8)),
                    .rotate(byAngle: CGFloat.random(in: -0.8...0.8), duration: Double.random(in: 4.0...6.8))
                ]),
                .moveBy(x: 0, y: -size.height * 0.50, duration: 0),
                .fadeAlpha(to: 1.0, duration: 0.18)
            ])))
        }

        return node
    }

    private func makeFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: Visual.memoryBlue.withAlphaComponent(0.56),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -6

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
        pulse.fillColor = Visual.memoryBlue.withAlphaComponent(0.045)
        pulse.strokeColor = GameUI.gold.withAlphaComponent(0.12)
        pulse.lineWidth = 1
        pulse.zPosition = 2
        node.addChild(pulse)
        pulse.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.54, duration: 0.72),
            .fadeAlpha(to: 1.0, duration: 0.72)
        ])))

        return node
    }

    private func makeBoardSurface() -> SKNode {
        let node = SKNode()
        let center = CGPoint(x: 0, y: gridOrigin.y + boardHeight / 2)
        node.zPosition = -20

        let backSize = CGSize(width: boardWidth + 18, height: boardHeight + 18)
        let back = SKShapeNode(rectOf: backSize, cornerRadius: 26)
        back.position = center
        back.fillTexture = GameUI.gradientTexture(size: backSize,
                                                  colors: [
                                                    UIColor.lerp(Visual.darkTop, Visual.memoryBlue, 0.18),
                                                    Visual.darkMid,
                                                    Visual.darkBottom
                                                  ])
        back.fillColor = .white
        back.strokeColor = GameUI.palePaper.withAlphaComponent(0.20)
        back.lineWidth = 1.5
        node.addChild(back)

        for row in 0..<TideMemoryRules.rows {
            for column in 0..<TideMemoryRules.columns {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize - 7, height: cellSize - 7),
                                       cornerRadius: 13)
                cell.fillColor = ((row + column).isMultiple(of: 2) ? GameUI.palePaper : Visual.memoryBlue)
                    .withAlphaComponent((row + column).isMultiple(of: 2) ? 0.10 : 0.06)
                cell.strokeColor = GameUI.palePaper.withAlphaComponent(0.07)
                cell.lineWidth = 0.8
                cell.position = position(of: TideMemoryPosition(row: row, column: column))
                cell.zPosition = 1
                node.addChild(cell)
            }
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
        let bg = SKShapeNode(rectOf: size, cornerRadius: 17)
        bg.fillTexture = GameUI.paperTexture(size: size, base: GameUI.paper)
        bg.fillColor = .white
        bg.strokeColor = accent.withAlphaComponent(0.55)
        bg.lineWidth = 1.4
        node.addChild(bg)

        iconNode.position = CGPoint(x: -width / 2 + 24, y: 0)
        node.addChild(iconNode)

        let titleLabel = SKLabelNode(text: title.uppercased())
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 8.5
        titleLabel.fontColor = GameUI.mutedInk
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .center
        titleLabel.position = CGPoint(x: -width / 2 + 46, y: 12)
        node.addChild(titleLabel)

        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Heavy"
        valueLabel.fontSize = 13.5
        valueLabel.fontColor = GameUI.ink
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.verticalAlignmentMode = .center
        ChallengeChrome.fitSingleLineLabel(valueLabel,
                                           maxWidth: width - 64,
                                           maxFontSize: 13.5,
                                           minFontSize: 10.5)
        valueLabel.position = CGPoint(x: titleLabel.position.x, y: -8)
        node.addChild(valueLabel)

        return (node, valueLabel)
    }

    private func makeTimerBar(width: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 12

        let back = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        back.fillColor = GameUI.line.withAlphaComponent(0.12)
        back.strokeColor = GameUI.line.withAlphaComponent(0.20)
        back.lineWidth = 1
        node.addChild(back)

        timerBarFill = SKShapeNode(rectOf: CGSize(width: width, height: 11), cornerRadius: 5.5)
        timerBarFill.fillColor = Visual.memoryBlue.withAlphaComponent(0.76)
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

    // MARK: - Cartas

    private func position(of position: TideMemoryPosition) -> CGPoint {
        CGPoint(x: gridOrigin.x + (CGFloat(position.column) + 0.5) * cellSize,
                y: gridOrigin.y + (CGFloat(position.row) + 0.5) * cellSize)
    }

    private func rebuildCards(animated: Bool) {
        for row in 0..<TideMemoryRules.rows {
            for column in 0..<TideMemoryRules.columns {
                cardNodes[row][column]?.removeFromParent()
                let position = TideMemoryPosition(row: row, column: column)
                let node = makeCardNode(at: position)
                if animated {
                    node.setScale(0.35)
                    node.alpha = 0
                    node.run(.sequence([
                        .wait(forDuration: Double(row * TideMemoryRules.columns + column) * 0.006),
                        .group([
                            .scale(to: 1.0, duration: 0.09),
                            .fadeIn(withDuration: 0.09)
                        ])
                    ]))
                }
                boardNode.addChild(node)
                cardNodes[row][column] = node
            }
        }
    }

    private func makeCardNode(at position: TideMemoryPosition) -> SKNode {
        let node = SKNode()
        node.name = name(for: position)
        node.position = self.position(of: position)
        node.zPosition = 10
        decorateCard(node, card: board.card(at: position), position: position)
        return node
    }

    private func decorateCard(_ node: SKNode,
                              card: TideMemoryCard,
                              position: TideMemoryPosition,
                              startsIdle: Bool = true) {
        node.removeAllChildren()
        let cardSize = CGSize(width: cellSize - 10, height: cellSize - 10)
        let cornerRadius = min(16, cellSize * 0.22)

        let shadow = SKShapeNode(rectOf: cardSize, cornerRadius: cornerRadius)
        shadow.fillColor = UIColor.black.withAlphaComponent(card.state == .matched ? 0.10 : 0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -3
        node.addChild(shadow)

        switch card.state {
        case .faceDown:
            let back = SKShapeNode(rectOf: cardSize, cornerRadius: cornerRadius)
            back.fillTexture = GameUI.gradientTexture(size: cardSize,
                                                      colors: [
                                                        UIColor.lerp(Visual.darkTop, Visual.memoryBlue, 0.34),
                                                        Visual.darkMid,
                                                        UIColor.lerp(Visual.darkBottom, GameUI.gold, 0.14)
                                                      ])
            back.fillColor = .white
            back.strokeColor = GameUI.palePaper.withAlphaComponent(0.24)
            back.lineWidth = 1.2
            back.glowWidth = 1
            node.addChild(back)

            let ring = SKShapeNode(circleOfRadius: cellSize * 0.20)
            ring.fillColor = GameUI.palePaper.withAlphaComponent(0.07)
            ring.strokeColor = Visual.memoryBlue.withAlphaComponent(0.45)
            ring.lineWidth = 1.2
            ring.glowWidth = 3
            ring.zPosition = 2
            node.addChild(ring)

            let mark = SKLabelNode(text: "?")
            mark.fontName = "AvenirNext-Heavy"
            mark.fontSize = cellSize * 0.36
            mark.fontColor = GameUI.gold.withAlphaComponent(0.95)
            mark.verticalAlignmentMode = .center
            mark.horizontalAlignmentMode = .center
            mark.zPosition = 3
            node.addChild(mark)

            let shimmer = SKShapeNode(rectOf: CGSize(width: cardSize.width * 0.68, height: 3), cornerRadius: 1.5)
            shimmer.fillColor = UIColor.white.withAlphaComponent(0.14)
            shimmer.strokeColor = .clear
            shimmer.position = CGPoint(x: 0, y: cardSize.height * 0.26)
            shimmer.zPosition = 3
            node.addChild(shimmer)

            if startsIdle {
                startCardIdle(on: node)
            }

        case .faceUp, .matched:
            node.removeAction(forKey: "memory_idle")
            let color = theme.colors[card.kind % theme.colors.count]
            let isMatched = card.state == .matched
            let front = SKShapeNode(rectOf: cardSize, cornerRadius: cornerRadius)
            front.fillTexture = GameUI.gradientTexture(size: cardSize,
                                                       colors: [
                                                        UIColor.lerp(color, .white, 0.38),
                                                        color,
                                                        UIColor.lerp(color, Visual.darkBottom, 0.28)
                                                       ])
            front.fillColor = .white
            front.strokeColor = isMatched
                ? GameUI.gold.withAlphaComponent(0.80)
                : UIColor.white.withAlphaComponent(0.62)
            front.lineWidth = isMatched ? 2.0 : 1.4
            front.glowWidth = isMatched ? 4 : 2
            node.addChild(front)

            let glow = SKShapeNode(circleOfRadius: cellSize * 0.42)
            glow.fillColor = color.withAlphaComponent(isMatched ? 0.20 : 0.14)
            glow.strokeColor = .clear
            glow.glowWidth = isMatched ? 10 : 6
            glow.zPosition = -1
            node.addChild(glow)

            let icon = SKLabelNode(text: theme.icons[card.kind % theme.icons.count])
            icon.fontName = "AppleColorEmoji"
            icon.fontSize = cellSize * 0.46
            icon.verticalAlignmentMode = .center
            icon.horizontalAlignmentMode = .center
            icon.position = CGPoint(x: 0, y: -cellSize * 0.02)
            icon.zPosition = 5
            node.addChild(icon)

            let shine = SKShapeNode(circleOfRadius: cellSize * 0.075)
            shine.fillColor = UIColor.white.withAlphaComponent(0.42)
            shine.strokeColor = .clear
            shine.position = CGPoint(x: -cellSize * 0.19, y: cellSize * 0.21)
            shine.zPosition = 6
            node.addChild(shine)

            if isMatched {
                let seal = SKLabelNode(text: "✓")
                seal.fontName = "AvenirNext-Heavy"
                seal.fontSize = cellSize * 0.18
                seal.fontColor = GameUI.ink.withAlphaComponent(0.72)
                seal.verticalAlignmentMode = .center
                seal.horizontalAlignmentMode = .center
                seal.position = CGPoint(x: cellSize * 0.24, y: cellSize * 0.23)
                seal.zPosition = 7
                node.addChild(seal)
            }
        }

        node.name = name(for: position)
        for child in node.children {
            child.name = node.name
        }
    }

    private func startCardIdle(on node: SKNode) {
        node.removeAction(forKey: "memory_idle")
        node.run(.repeatForever(.sequence([
            .scale(to: CGFloat.random(in: 1.006...1.016), duration: Double.random(in: 0.34...0.48)),
            .scale(to: 1.0, duration: Double.random(in: 0.30...0.42))
        ])), withKey: "memory_idle")
    }

    private func flipCard(at position: TideMemoryPosition,
                          animated: Bool) {
        guard let node = cardNodes[position.row][position.column] else { return }
        let update = { [weak self, weak node] (startsIdle: Bool) in
            guard let self, let node else { return }
            self.decorateCard(node,
                              card: self.board.card(at: position),
                              position: position,
                              startsIdle: startsIdle)
        }
        guard animated else {
            update(true)
            return
        }
        node.removeAllActions()
        node.zRotation = 0
        node.setScale(1.0)
        node.alpha = 1.0

        let fadeOut = SKAction.fadeAlpha(to: 0.18, duration: TideMemoryRules.flipFadeOutDuration)
        fadeOut.timingMode = .easeOut
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: TideMemoryRules.flipFadeInDuration)
        fadeIn.timingMode = .easeIn

        node.run(.sequence([
            fadeOut,
            .run { [weak self, weak node] in
                update(false)
                node?.setScale(1.0)
                if let node {
                    node.alpha = 0.18
                }
                guard let self, let node else { return }
                if self.board.card(at: position).state != .faceDown {
                    node.removeAction(forKey: "memory_idle")
                }
            },
            fadeIn,
            .run { [weak self, weak node] in
                guard let self, let node else { return }
                node.setScale(1.0)
                if self.board.card(at: position).state == .faceDown {
                    self.startCardIdle(on: node)
                }
            }
        ]))
    }

    private func name(for position: TideMemoryPosition) -> String {
        "memory_card_\(position.row)_\(position.column)"
    }

    private func position(fromName name: String) -> TideMemoryPosition? {
        guard name.hasPrefix("memory_card_") else { return nil }
        let parts = name.dropFirst("memory_card_".count).split(separator: "_")
        guard parts.count == 2,
              let row = Int(parts[0]),
              let column = Int(parts[1]),
              row >= 0,
              row < TideMemoryRules.rows,
              column >= 0,
              column < TideMemoryRules.columns else { return nil }
        return TideMemoryPosition(row: row, column: column)
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
            if current.name == "memory_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish()
                return
            }
            if let name = current.name, let position = position(fromName: name) {
                handleTap(at: position)
                return
            }
            node = current.parent
        }
    }

    private func handleTap(at position: TideMemoryPosition) {
        guard !busy, !finished else { return }
        guard board.reveal(at: position) != nil else {
            GameAudio.shared.play(.tideInvalid)
            return
        }

        GameAudio.shared.play(.tideSelect, cooldownOverride: 0.04)
        flipCard(at: position, animated: true)
        revealed.append(position)

        if revealed.count == 1 {
            firstRevealAge = 0
            showFloatingLabel(text: "Lembra...",
                              at: self.position(of: position) + CGPoint(x: 0, y: cellSize * 0.40),
                              color: Visual.memoryBlue,
                              size: 17,
                              drift: CGPoint(x: CGFloat.random(in: -10...10), y: 42))
            return
        }

        guard revealed.count == 2 else { return }
        busy = true
        let first = revealed[0]
        let second = revealed[1]
        let revealGap = firstRevealAge
        revealed.removeAll()

        run(.sequence([
            .wait(forDuration: 0.22),
            .run { [weak self] in
                self?.resolvePair(first: first, second: second, revealGap: revealGap)
            }
        ]))
    }

    private func resolvePair(first: TideMemoryPosition,
                             second: TideMemoryPosition,
                             revealGap: CGFloat) {
        guard !finished else { return }
        let resolution = board.resolve(first: first, second: second)
        if resolution.matched {
            handleMatch(resolution: resolution, revealGap: revealGap)
        } else {
            handleMismatch(resolution: resolution)
        }
    }

    private func handleMatch(resolution: TideMemoryResolution, revealGap: CGFloat) {
        if timeSinceLastMatch <= TideMemoryRules.comboWindow {
            streak += 1
        } else {
            streak = 1
        }
        timeSinceLastMatch = 0

        let gained = TideMemoryRules.matchPoints(streak: streak,
                                                 revealGap: revealGap,
                                                 remainingPairs: board.remainingPairs)
        let addedTime = TideMemoryRules.timeBonus(streak: streak,
                                                  revealGap: revealGap,
                                                  timeLeft: timeLeft)
        score += gained
        timeLeft = min(TideMemoryRules.maxTime, timeLeft + addedTime)

        flipCard(at: resolution.first, animated: true)
        flipCard(at: resolution.second, animated: true)
        animateMatchedPair(resolution: resolution, gained: gained, addedTime: addedTime)
        updateChallengeProgress()

        GameAudio.shared.play(streak >= 4 ? .tideCascade : .tideMatch,
                              volumeMultiplier: streak >= 4 ? 1.12 : 1.0,
                              cooldownOverride: 0.05)

        if board.allMatched {
            run(.sequence([
                .wait(forDuration: 0.34),
                .run { [weak self] in self?.startNextMemoryWave() }
            ]))
        } else {
            run(.sequence([
                .wait(forDuration: 0.12),
                .run { [weak self] in self?.busy = false }
            ]))
        }
    }

    private func handleMismatch(resolution: TideMemoryResolution) {
        mistakes += 1
        mistakesThisWave += 1
        streak = 0
        timeLeft = max(0, timeLeft - TideMemoryRules.mismatchPenalty)

        showFloatingLabel(text: "-\(Int(TideMemoryRules.mismatchPenalty))s",
                          at: midPoint(resolution.first, resolution.second),
                          color: GameUI.coral,
                          size: 24,
                          drift: CGPoint(x: CGFloat.random(in: -12...12), y: 70))
        GameAudio.shared.play(.tideInvalid)
        updateStatusUI()

        run(.sequence([
            .wait(forDuration: 0.20),
            .run { [weak self] in
                guard let self else { return }
                self.flipCard(at: resolution.first, animated: true)
                self.flipCard(at: resolution.second, animated: true)
                self.shakeCard(at: resolution.first)
                self.shakeCard(at: resolution.second)
                self.boardNode.run(.sequence([
                    .moveBy(x: -6, y: 0, duration: 0.04),
                    .moveBy(x: 12, y: 0, duration: 0.08),
                    .moveBy(x: -6, y: 0, duration: 0.04)
                ]))
            },
            .wait(forDuration: 0.13),
            .run { [weak self] in
                guard let self else { return }
                self.busy = false
                if self.timeLeft <= 0 {
                    self.finish()
                }
            }
        ]))
    }

    private func animateMatchedPair(resolution: TideMemoryResolution, gained: Int, addedTime: CGFloat) {
        let firstPoint = position(of: resolution.first)
        let secondPoint = position(of: resolution.second)
        let center = midPoint(resolution.first, resolution.second)
        let color = theme.colors[resolution.kind % theme.colors.count]

        for position in [resolution.first, resolution.second] {
            cardNodes[position.row][position.column]?.run(.sequence([
                .group([
                    .scale(to: 1.10, duration: 0.055),
                    .rotate(byAngle: CGFloat.random(in: -0.08...0.08), duration: 0.055)
                ]),
                .group([
                    .scale(to: 1.0, duration: 0.07),
                    .rotate(toAngle: 0, duration: 0.07)
                ])
            ]))
        }

        drawMemoryThread(from: firstPoint, to: secondPoint, color: color)
        spawnSparkles(at: firstPoint, color: color, count: 9)
        spawnSparkles(at: secondPoint, color: color, count: 9)
        showFloatingLabel(text: "+\(gained)",
                          at: center,
                          color: streak >= 4 ? Visual.rose : GameUI.gold,
                          size: streak >= 4 ? 30 : 24,
                          drift: CGPoint(x: CGFloat.random(in: -16...16), y: 78))

        if addedTime >= 0.4 {
            showFloatingLabel(text: "+\(String(format: "%.1f", addedTime))s",
                              at: center + CGPoint(x: 0, y: 26),
                              color: Visual.memoryBlue,
                              size: 18,
                              drift: CGPoint(x: CGFloat.random(in: -18...18), y: 66))
        }

        if streak >= 2 {
            showFloatingLabel(text: "MEMÓRIA x\(streak)",
                              at: CGPoint(x: 0, y: boardHeight / 2 + 102),
                              color: streak >= 4 ? Visual.rose : Visual.memoryBlue,
                              size: min(32, 17 + CGFloat(streak)),
                              drift: CGPoint(x: CGFloat.random(in: -8...8), y: 56))
        }

        if streak == 4 {
            showFloatingLabel(text: "MARÉ VIVA!",
                              at: CGPoint(x: 0, y: 8),
                              color: Visual.rose,
                              size: 36,
                              drift: CGPoint(x: 0, y: 96))
            makeMemoryFlash(color: Visual.rose)
        }
    }

    private func drawMemoryThread(from start: CGPoint, to end: CGPoint, color: UIColor) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addCurve(to: end,
                      controlPoint1: CGPoint(x: start.x, y: start.y + cellSize * 0.42),
                      controlPoint2: CGPoint(x: end.x, y: end.y + cellSize * 0.42))
        let thread = SKShapeNode(path: path.cgPath)
        thread.fillColor = .clear
        thread.strokeColor = UIColor.lerp(color, .white, 0.34).withAlphaComponent(0.80)
        thread.lineWidth = 3
        thread.lineCap = .round
        thread.glowWidth = 8
        thread.zPosition = 90
        addChild(thread)
        thread.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.22),
                .scale(to: 1.04, duration: 0.22)
            ]),
            .removeFromParent()
        ]))
    }

    private func shakeCard(at position: TideMemoryPosition) {
        cardNodes[position.row][position.column]?.run(.sequence([
            .moveBy(x: -7, y: 0, duration: 0.04),
            .moveBy(x: 14, y: 0, duration: 0.08),
            .moveBy(x: -7, y: 0, duration: 0.04)
        ]))
    }

    private func midPoint(_ first: TideMemoryPosition, _ second: TideMemoryPosition) -> CGPoint {
        let a = position(of: first)
        let b = position(of: second)
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
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
        label.position = point
        label.zPosition = 130
        label.setScale(0.68)
        addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: drift.x, y: drift.y, duration: 0.46),
                .fadeOut(withDuration: 0.46),
                .scale(to: 1.14, duration: 0.09)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnSparkles(at point: CGPoint, color: UIColor, count: Int) {
        for index in 0..<count {
            let sparkle = SKLabelNode(text: index.isMultiple(of: 2) ? "✦" : "•")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = CGFloat.random(in: 10...19)
            sparkle.fontColor = UIColor.lerp(color, .white, CGFloat.random(in: 0.16...0.52))
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = point
            sparkle.zPosition = 92
            addChild(sparkle)

            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat.random(in: -0.30...0.30)
            let distance = CGFloat.random(in: 24...56)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance + CGFloat.random(in: 18...46),
                            duration: 0.22),
                    .rotate(byAngle: CGFloat.random(in: -1.6...1.6), duration: 0.22),
                    .fadeOut(withDuration: 0.22),
                    .scale(to: CGFloat.random(in: 0.25...0.55), duration: 0.22)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func makeMemoryFlash(color: UIColor) {
        let flash = SKShapeNode(rectOf: CGSize(width: boardWidth + 28, height: boardHeight + 28),
                                cornerRadius: 26)
        flash.position = CGPoint(x: 0, y: gridOrigin.y + boardHeight / 2)
        flash.fillColor = color.withAlphaComponent(0.18)
        flash.strokeColor = GameUI.gold.withAlphaComponent(0.72)
        flash.lineWidth = 2
        flash.glowWidth = 10
        flash.zPosition = 80
        addChild(flash)
        flash.run(.sequence([
            .group([
                .scale(to: 1.05, duration: 0.14),
                .fadeOut(withDuration: 0.14)
            ]),
            .removeFromParent()
        ]))
    }

    private func startNextMemoryWave() {
        guard !finished else { return }
        busy = true
        let completedWave = wave
        let bonus = TideMemoryRules.waveBonus(wave: completedWave,
                                              timeLeft: timeLeft,
                                              mistakesThisWave: mistakesThisWave)
        let recovery = TideMemoryRules.recoverTimeAfterWave(currentTime: timeLeft,
                                                            wave: completedWave,
                                                            mistakesThisWave: mistakesThisWave)
        let addedTime = recovery.addedTime
        score += bonus
        timeLeft = recovery.timeLeft
        challengeCompleted = challengeCompleted || score >= currentGoal
        updateStatusUI()

        GameAudio.shared.play(.tideCascade, volumeMultiplier: 1.18, cooldownOverride: 0.04)
        showFloatingLabel(text: "NOVA MEMÓRIA +\(bonus)",
                          at: CGPoint(x: 0, y: gridOrigin.y + boardHeight + 44),
                          color: GameUI.gold,
                          size: 28,
                          drift: CGPoint(x: 0, y: 78))
        showFloatingLabel(text: "+\(String(format: "%.1f", addedTime))s",
                          at: CGPoint(x: 0, y: gridOrigin.y + boardHeight + 10),
                          color: Visual.memoryBlue,
                          size: 20,
                          drift: CGPoint(x: CGFloat.random(in: -12...12), y: 62))
        makeMemoryFlash(color: Visual.memoryBlue)

        for row in 0..<TideMemoryRules.rows {
            for column in 0..<TideMemoryRules.columns {
                cardNodes[row][column]?.removeAllActions()
                cardNodes[row][column]?.run(.sequence([
                    .wait(forDuration: Double(row * TideMemoryRules.columns + column) * 0.006),
                    .group([
                        .scale(to: 0.18, duration: 0.08),
                        .fadeOut(withDuration: 0.08),
                        .rotate(byAngle: CGFloat.random(in: -0.5...0.5), duration: 0.08)
                    ]),
                    .removeFromParent()
                ]))
            }
        }

        wave += 1
        mistakesThisWave = 0
        revealed.removeAll()
        firstRevealAge = 0
        board.startNextWave()
        cardNodes = Array(repeating: Array<SKNode?>(repeating: nil, count: TideMemoryRules.columns),
                          count: TideMemoryRules.rows)

        run(.sequence([
            .wait(forDuration: 0.20),
            .run { [weak self] in
                guard let self else { return }
                self.rebuildCards(animated: true)
                self.updateStatusUI()
            },
            .wait(forDuration: 0.18),
            .run { [weak self] in self?.busy = false }
        ]))
    }

    // MARK: - Estado

    private var currentGoal: Int {
        initialGoal + max(0, wave - 1) * GameBalance.memoryChallengeWaveGoalStep
    }

    private func updateChallengeProgress() {
        let completedNow = !challengeCompleted && (score >= currentGoal || board.allMatched)
        if completedNow {
            challengeCompleted = true
        }
        updateStatusUI()
        if completedNow {
            GameAudio.shared.play(.tideGoal)
            showGoalCompleteBurst()
        }
    }

    private func updateStatusUI() {
        guard scoreLabel != nil else { return }
        scoreLabel.text = "\(score)"
        objectiveLabel.text = objectiveText()
        ChallengeChrome.fitSingleLineLabel(scoreLabel,
                                           maxWidth: scoreLabel.preferredMaxLayoutWidth,
                                           maxFontSize: 13.5,
                                           minFontSize: 10.5)
        ChallengeChrome.fitSingleLineLabel(objectiveLabel,
                                           maxWidth: objectiveLabel.preferredMaxLayoutWidth,
                                           maxFontSize: 13.5,
                                           minFontSize: 10.5)
        let remaining = board.remainingPairs
        if streak > 0 {
            streakLabel.text = "Memória x\(streak) • \(remaining) pares"
        } else {
            streakLabel.text = "\(remaining) pares escondidos"
        }
        streakLabel.fontColor = streak >= 4 ? Visual.rose : GameUI.palePaper.withAlphaComponent(0.88)
        updateTimerUI()
    }

    private func updateTimerUI() {
        guard timerLabel != nil, timerBarFill != nil else { return }
        timerLabel.text = timerText()
        let progress = (timeLeft / TideMemoryRules.startTime).clamped(to: 0...1)
        let visibleProgress = max(0.012, progress)
        timerBarFill.xScale = visibleProgress
        timerBarFill.position = CGPoint(x: timerBarLeft + timerBarWidth * visibleProgress / 2, y: 0)
        timerBarFill.fillColor = progress < 0.24
            ? GameUI.coral.withAlphaComponent(0.84)
            : (streak >= 4 ? Visual.rose.withAlphaComponent(0.86) : Visual.memoryBlue.withAlphaComponent(0.76))
    }

    private func objectiveText() -> String {
        let goalText = challengeCompleted ? "meta viva" : "\(score)/\(currentGoal)"
        return "Onda \(wave) • \(goalText)"
    }

    private func timerText() -> String {
        "\(max(0, Int(ceil(timeLeft))))s"
    }

    private func showGoalCompleteBurst() {
        let label = SKLabelNode(text: "LEMBROU!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 32
        label.fontColor = GameUI.algae
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: gridOrigin.y + boardHeight + 58)
        label.zPosition = 135
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1.12, duration: 0.12),
                .fadeAlpha(to: 1, duration: 0.12)
            ]),
            .wait(forDuration: 0.28),
            .group([
                .moveBy(x: 0, y: 42, duration: 0.22),
                .fadeOut(withDuration: 0.22),
                .scale(to: 0.90, duration: 0.22)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Fim

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .memory,
                                                          reachedTarget: reached ?? challengeCompleted,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false,
                                                          victoryReward: victoryReward)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: score,
                                                      multiplier: shellRewardMultiplier)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        busy = true

        let bonus = TideMemoryRules.finalBonus(timeLeft: timeLeft,
                                               mistakes: mistakes,
                                               allMatched: board.allMatched)
        if bonus > 0 {
            score += bonus
            showFloatingLabel(text: "BÔNUS +\(bonus)",
                              at: CGPoint(x: 0, y: gridOrigin.y + boardHeight + 18),
                              color: GameUI.gold,
                              size: 26,
                              drift: CGPoint(x: 0, y: 78))
        }
        challengeCompleted = challengeCompleted || board.allMatched || score >= currentGoal
        updateStatusUI()

        GameAudio.shared.play(challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .memory,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false,
                                                          victoryReward: victoryReward)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 140
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let titleLabel = SKLabelNode(text: reached ? "Memórias despertas!" : "A maré fechou.")
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

        let scoreLine = SKLabelNode(text: "Pontos feitos: \(score)")
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

        let detailsLine = SKLabelNode(text: "Onda \(wave) • \(board.matchedPairs)/\(TideMemoryRules.pairCount) pares • \(mistakes) erros")
        detailsLine.fontName = "AvenirNext-Regular"
        detailsLine.fontSize = 13.5
        detailsLine.fontColor = GameUI.mutedInk
        detailsLine.verticalAlignmentMode = .center
        detailsLine.position = CGPoint(x: 0, y: 24)
        ChallengeChrome.fitSingleLineLabel(detailsLine,
                                           maxWidth: 282,
                                           maxFontSize: 13.5,
                                           minFontSize: 10.5)
        content.addChild(detailsLine)

        let rewardLine = SKLabelNode(text: "Convertendo pontos...")
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.verticalAlignmentMode = .center
        rewardLine.position = CGPoint(x: 0, y: -34)
        content.addChild(rewardLine)
        ChallengeChrome.animatePointConversion(label: rewardLine,
                                               points: score,
                                               pearls: pearls,
                                               reachedTarget: reached,
                                               victoryReward: victoryReward,
                                               newRecord: record.isNewRecord(score: score))

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "memory_continue"
        continueButton.position = CGPoint(x: 0, y: -104)
        content.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .memory,
                                        points: score,
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
        let panel = GameUI.card(size: CGSize(width: 314, height: 286),
                                cornerRadius: 24,
                                tint: resultTint,
                                baseColors: [UIColor.lerp(GameUI.palePaper, resultTint, 0.28)])
        let wash = SKShapeNode(rectOf: CGSize(width: 302, height: 274), cornerRadius: 20)
        wash.fillColor = resultTint.withAlphaComponent(0.08)
        wash.strokeColor = .clear
        wash.zPosition = 0.5
        panel.addChild(wash)
        return panel
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "memory_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
