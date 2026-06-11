//
//  TideWeavingSystem.swift
//  Ester
//
//  Desafio: Trama — o minijogo de combinar 3+ peças (antiga "Trama das
//  Marés"). Hoje é um dos desafios oferecidos pelos peixes; o peixe que
//  ofereceu fica em destaque no topo enquanto o tabuleiro roda embaixo.
//  Sessões: básica, de região, de evento (especial) e de choco.
//

import Foundation
import SpriteKit

// MARK: - Tipos de sessão

enum TideSessionType {
    case basic
    case region
    case event
    case hatching
}

// MARK: - Tema

struct TideTheme {
    let icons: [String]
    let subtitle: String

    static func theme(for zone: DepthZone,
                      region: Region?,
                      session: TideSessionType) -> TideTheme {
        switch session {
        case .hatching:
            return TideTheme(icons: ["○", "✦", "♡", "◡", "◇"],
                             subtitle: "Energia de Nascimento")
        case .region:
            if let region {
                return TideTheme(icons: region.tideIcons, subtitle: region.tideTitle)
            }
            return zoneTheme(for: zone)
        case .basic:
            return zoneTheme(for: zone)
        case .event:
            let base = region.map { TideTheme(icons: $0.tideIcons, subtitle: $0.tideTitle) }
                ?? zoneTheme(for: zone)
            return TideTheme(icons: base.icons + ["◎"],
                             subtitle: base.subtitle + " especial")
        }
    }

    private static func zoneTheme(for zone: DepthZone) -> TideTheme {
        switch zone {
        case .clear:
            return TideTheme(icons: ["○", "☼", "✦", "⌁", "◡"], subtitle: "Luzes da Camada Clara")
        case .shallow:
            return TideTheme(icons: ["◡", "○", "✦", "⌁", "※"], subtitle: "Conchas da Camada Rasa")
        case .mid:
            return TideTheme(icons: ["◌", "><>", "≈", "✦", "○"], subtitle: "Correntes da Camada Média")
        case .blue:
            return TideTheme(icons: ["◌", "≈", "><>", "◇", "○"], subtitle: "Marés da Camada Azul")
        case .deep:
            return TideTheme(icons: ["◇", "✦", "⌘", "◎", "✧"], subtitle: "Cristais da Camada Profunda")
        case .abyss:
            return TideTheme(icons: ["◇", "◎", "⌘", "✦", "●"], subtitle: "Segredos da Camada Abissal")
        case .surface:
            return TideTheme(icons: ["⌖", "○", "☼", "□", "⌁"], subtitle: "Reflexos da Superfície")
        }
    }
}

// MARK: - Tabuleiro (camada modal)

private struct GridPos: Hashable {
    let r: Int
    let c: Int
}

final class TideWeavingOverlay: SKNode {
    private let gridSize = 7
    private let theme: TideTheme
    private let kindCount: Int
    private let challengeGoal: Int
    private let challengeBonus: Int
    private let session: TideSessionType
    private let phase: MermaidPhase
    private let shellRewardMultiplier: CGFloat
    private let onFinish: (ChallengeResult) -> Void

    private var board: [[Int]] = []
    private var pieces: [[SKNode?]] = []
    private var score = 0
    private let actionTimeLimit: CGFloat = 40
    private var actionTimeLeft: CGFloat = 40
    private var challengeCompleted = false
    private var busy = false
    private var finished = false
    private var selected: GridPos?
    private var dragStart: (pos: GridPos, location: CGPoint)?

    private let cellSize: CGFloat
    private let gridOrigin: CGPoint
    private var scoreLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private let selectionRing = SKShapeNode(circleOfRadius: 10)
    private let boardNode = SKNode()

    init(size: CGSize,
         zone: DepthZone,
         region: Region?,
         session: TideSessionType,
         phase: MermaidPhase,
         shellRewardMultiplier: CGFloat,
         giverDisplay: SKNode?,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.theme = TideTheme.theme(for: zone, region: region, session: session)
        self.kindCount = theme.icons.count
        self.session = session
        self.phase = phase
        self.shellRewardMultiplier = shellRewardMultiplier
        var goal = 18 + zone.rawValue * 4
        var bonus = GameBalance.challengeBaseReward(score: 0,
                                                    reachedTarget: true,
                                                    phase: phase,
                                                    special: session == .event,
                                                    isHatching: session == .hatching)
        if session == .event {
            goal += 10
        }
        if session == .hatching {
            goal = 35
            bonus = 0
        }
        self.challengeGoal = goal
        self.challengeBonus = bonus
        self.onFinish = onFinish

        let boardWidth = min(size.width - 36, 380)
        self.cellSize = boardWidth / CGFloat(gridSize)
        self.gridOrigin = CGPoint(x: -boardWidth / 2, y: -boardWidth / 2 - 30)

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, boardWidth: boardWidth, giverDisplay: giverDisplay)
        fillInitialBoard()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat) {
        guard !finished else { return }
        actionTimeLeft = max(0, actionTimeLeft - dt)
        timerLabel.text = actionTimerText()
        if actionTimeLeft <= 0 {
            finish()
        }
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, boardWidth: CGFloat, giverDisplay: SKNode?) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.6)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        let panel = GameUI.card(size: CGSize(width: boardWidth + 28, height: boardWidth + 335),
                                cornerRadius: 26,
                                tint: GameUI.accent.withAlphaComponent(0.5))
        panel.position = CGPoint(x: 0, y: 57)
        addChild(panel)

        // NPC que deu o desafio em destaque no topo + título
        let header = ChallengeChrome.makeHeader(kind: .plot,
                                                subtitle: theme.subtitle,
                                                giverDisplay: giverDisplay,
                                                width: boardWidth)
        header.position = CGPoint(x: 0, y: boardWidth / 2 + 160)
        addChild(header)

        scoreLabel = SKLabelNode(text: scoreText())
        scoreLabel.fontName = "AvenirNext-DemiBold"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = GameUI.ink
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: gridOrigin.x, y: boardWidth / 2 + 44)
        addChild(scoreLabel)

        timerLabel = SKLabelNode(text: actionTimerText())
        timerLabel.fontName = "AvenirNext-Regular"
        timerLabel.fontSize = 16
        timerLabel.fontColor = GameUI.mutedInk
        timerLabel.horizontalAlignmentMode = .right
        timerLabel.position = CGPoint(x: gridOrigin.x + boardWidth, y: boardWidth / 2 + 44)
        addChild(timerLabel)

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               height: 34)
        quit.name = "tide_quit"
        quit.position = CGPoint(x: 0, y: gridOrigin.y - 56)
        quit.zPosition = 20
        addChild(quit)

        boardNode.position = .zero
        addChild(boardNode)

        selectionRing.strokeColor = GameUI.gold
        selectionRing.lineWidth = 3
        selectionRing.glowWidth = 1
        selectionRing.isHidden = true
        selectionRing.zPosition = 5
        selectionRing.setScale(cellSize / 24)
        boardNode.addChild(selectionRing)
    }

    // MARK: - Tabuleiro

    private func position(of pos: GridPos) -> CGPoint {
        CGPoint(x: gridOrigin.x + (CGFloat(pos.c) + 0.5) * cellSize,
                y: gridOrigin.y + (CGFloat(pos.r) + 0.5) * cellSize)
    }

    private func gridPos(at location: CGPoint) -> GridPos? {
        let c = Int(floor((location.x - gridOrigin.x) / cellSize))
        let r = Int(floor((location.y - gridOrigin.y) / cellSize))
        guard r >= 0, r < gridSize, c >= 0, c < gridSize else { return nil }
        return GridPos(r: r, c: c)
    }

    private func makePiece(kind: Int, at pos: GridPos) -> SKNode {
        let piece = SKNode()
        let bg = SKShapeNode(circleOfRadius: cellSize * 0.42)
        bg.fillColor = UIColor(white: 1, alpha: 0.12)
        bg.strokeColor = UIColor(white: 1, alpha: 0.2)
        piece.addChild(bg)
        let icon = SKLabelNode(text: theme.icons[kind])
        icon.fontName = "AvenirNext-DemiBold"
        icon.fontSize = cellSize * (theme.icons[kind].count > 1 ? 0.28 : 0.50)
        icon.fontColor = [GameUI.accent, GameUI.gold, GameUI.coral, GameUI.algae, GameUI.mutedInk][kind % 5]
        icon.verticalAlignmentMode = .center
        piece.addChild(icon)
        piece.position = position(of: pos)
        return piece
    }

    private func fillInitialBoard() {
        board = Array(repeating: Array(repeating: -1, count: gridSize), count: gridSize)
        pieces = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                var kind: Int
                repeat {
                    kind = Int.random(in: 0..<kindCount)
                } while createsInitialMatch(kind: kind, r: r, c: c)
                board[r][c] = kind
                let piece = makePiece(kind: kind, at: GridPos(r: r, c: c))
                boardNode.addChild(piece)
                pieces[r][c] = piece
            }
        }
        if !hasPossibleMove() { reshuffle() }
    }

    private func createsInitialMatch(kind: Int, r: Int, c: Int) -> Bool {
        if c >= 2 && board[r][c - 1] == kind && board[r][c - 2] == kind { return true }
        if r >= 2 && board[r - 1][c] == kind && board[r - 2][c] == kind { return true }
        return false
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
            if current.name == "tide_quit" {
                finish()
                return
            }
            node = current.parent
        }

        guard !busy else { return }
        let boardLocation = touch.location(in: boardNode)
        guard let pos = gridPos(at: boardLocation) else { return }
        dragStart = (pos, boardLocation)

        if let sel = selected {
            if isAdjacent(sel, pos) {
                selected = nil
                selectionRing.isHidden = true
                trySwap(sel, pos)
                dragStart = nil
            } else {
                selected = pos
                selectionRing.position = position(of: pos)
                selectionRing.isHidden = false
            }
        } else {
            selected = pos
            selectionRing.position = position(of: pos)
            selectionRing.isHidden = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !busy, !finished,
              let touch = touches.first,
              let drag = dragStart else { return }
        let location = touch.location(in: boardNode)
        let dx = location.x - drag.location.x
        let dy = location.y - drag.location.y
        guard max(abs(dx), abs(dy)) > cellSize * 0.35 else { return }

        var neighbor = drag.pos
        if abs(dx) > abs(dy) {
            neighbor = GridPos(r: drag.pos.r, c: drag.pos.c + (dx > 0 ? 1 : -1))
        } else {
            neighbor = GridPos(r: drag.pos.r + (dy > 0 ? 1 : -1), c: drag.pos.c)
        }
        guard neighbor.r >= 0, neighbor.r < gridSize,
              neighbor.c >= 0, neighbor.c < gridSize else { return }

        dragStart = nil
        selected = nil
        selectionRing.isHidden = true
        trySwap(drag.pos, neighbor)
    }

    private func isAdjacent(_ a: GridPos, _ b: GridPos) -> Bool {
        abs(a.r - b.r) + abs(a.c - b.c) == 1
    }

    // MARK: - Troca e combinações

    private func swapData(_ a: GridPos, _ b: GridPos) {
        let kind = board[a.r][a.c]
        board[a.r][a.c] = board[b.r][b.c]
        board[b.r][b.c] = kind
        let piece = pieces[a.r][a.c]
        pieces[a.r][a.c] = pieces[b.r][b.c]
        pieces[b.r][b.c] = piece
    }

    private func animateSwap(_ a: GridPos, _ b: GridPos, completion: @escaping () -> Void) {
        let moveA = SKAction.move(to: position(of: a), duration: 0.18)
        let moveB = SKAction.move(to: position(of: b), duration: 0.18)
        moveA.eaeInEaseOut()
        moveB.eaeInEaseOut()
        pieces[a.r][a.c]?.run(moveA)
        pieces[b.r][b.c]?.run(moveB)
        run(.sequence([.wait(forDuration: 0.2), .run(completion)]))
    }

    private func trySwap(_ a: GridPos, _ b: GridPos) {
        guard !busy else { return }
        busy = true
        swapData(a, b)
        animateSwap(a, b) { [weak self] in
            guard let self else { return }
            guard !self.finished else { return }
            if self.findMatches().isEmpty {
                self.swapData(a, b)
                self.animateSwap(a, b) { [weak self] in
                    guard let self, !self.finished else { return }
                    self.busy = false
                }
            } else {
                self.resolveCascade(multiplier: 1)
            }
        }
    }

    private func findMatches() -> Set<GridPos> {
        var matches = Set<GridPos>()
        for r in 0..<gridSize {
            var run = 1
            for c in 1...gridSize {
                if c < gridSize && board[r][c] == board[r][c - 1] && board[r][c] != -1 {
                    run += 1
                } else {
                    if run >= 3 {
                        for k in (c - run)..<c { matches.insert(GridPos(r: r, c: k)) }
                    }
                    run = 1
                }
            }
        }
        for c in 0..<gridSize {
            var run = 1
            for r in 1...gridSize {
                if r < gridSize && board[r][c] == board[r - 1][c] && board[r][c] != -1 {
                    run += 1
                } else {
                    if run >= 3 {
                        for k in (r - run)..<r { matches.insert(GridPos(r: k, c: c)) }
                    }
                    run = 1
                }
            }
        }
        return matches
    }

    private func resolveCascade(multiplier: Int) {
        guard !finished else { return }
        let matches = findMatches()
        if matches.isEmpty {
            busy = false
            if !hasPossibleMove() { reshuffle() }
            return
        }

        score += matches.count
        actionTimeLeft = actionTimeLimit
        updateChallengeProgress()

        for pos in matches {
            board[pos.r][pos.c] = -1
            if let piece = pieces[pos.r][pos.c] {
                pieces[pos.r][pos.c] = nil
                piece.run(.sequence([
                    .group([.scale(to: 0.1, duration: 0.22), .fadeOut(withDuration: 0.22)]),
                    .removeFromParent()
                ]))
            }
        }

        run(.sequence([
            .wait(forDuration: 0.26),
            .run { [weak self] in self?.applyGravity(multiplier: multiplier) }
        ]))
    }

    private func applyGravity(multiplier: Int) {
        guard !finished else { return }
        for c in 0..<gridSize {
            var write = 0
            for r in 0..<gridSize where board[r][c] != -1 {
                if write != r {
                    board[write][c] = board[r][c]
                    board[r][c] = -1
                    pieces[write][c] = pieces[r][c]
                    pieces[r][c] = nil
                    let fall = SKAction.move(to: position(of: GridPos(r: write, c: c)), duration: 0.22)
                    fall.eaeInEaseOut()
                    pieces[write][c]?.run(fall)
                }
                write += 1
            }
            for r in write..<gridSize {
                let kind = Int.random(in: 0..<kindCount)
                board[r][c] = kind
                let spawnPos = GridPos(r: r, c: c)
                let piece = makePiece(kind: kind, at: spawnPos)
                piece.position = position(of: GridPos(r: r + 3, c: c))
                boardNode.addChild(piece)
                pieces[r][c] = piece
                let fall = SKAction.move(to: position(of: spawnPos), duration: 0.28)
                fall.eaeInEaseOut()
                piece.run(fall)
            }
        }
        run(.sequence([
            .wait(forDuration: 0.34),
            .run { [weak self] in self?.resolveCascade(multiplier: multiplier + 1) }
        ]))
    }

    // MARK: - Sem jogadas possíveis

    private func hasPossibleMove() -> Bool {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if c + 1 < gridSize {
                    swapValues(GridPos(r: r, c: c), GridPos(r: r, c: c + 1))
                    let found = !findMatches().isEmpty
                    swapValues(GridPos(r: r, c: c), GridPos(r: r, c: c + 1))
                    if found { return true }
                }
                if r + 1 < gridSize {
                    swapValues(GridPos(r: r, c: c), GridPos(r: r + 1, c: c))
                    let found = !findMatches().isEmpty
                    swapValues(GridPos(r: r, c: c), GridPos(r: r + 1, c: c))
                    if found { return true }
                }
            }
        }
        return false
    }

    private func swapValues(_ a: GridPos, _ b: GridPos) {
        let kind = board[a.r][a.c]
        board[a.r][a.c] = board[b.r][b.c]
        board[b.r][b.c] = kind
    }

    private func reshuffle() {
        var attempts = 0
        repeat {
            for r in 0..<gridSize {
                for c in 0..<gridSize {
                    var kind: Int
                    repeat {
                        kind = Int.random(in: 0..<kindCount)
                    } while createsInitialMatch(kind: kind, r: r, c: c)
                    board[r][c] = kind
                }
            }
            attempts += 1
        } while !hasPossibleMove() && attempts < 20

        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if let piece = pieces[r][c] {
                    piece.removeFromParent()
                }
                let newPiece = makePiece(kind: board[r][c], at: GridPos(r: r, c: c))
                boardNode.addChild(newPiece)
                pieces[r][c] = newPiece
            }
        }
    }

    // MARK: - Fim de sessão

    private var pendingResult: ChallengeResult?

    private func scoreText() -> String {
        if challengeCompleted {
            return "Pontos \(score) · Bônus pronto"
        }
        if challengeBonus > 0 {
            return "Meta \(score)/\(challengeGoal) · +\(challengeBonus)"
        }
        return "Energia \(score)/\(challengeGoal)"
    }

    private func actionTimerText() -> String {
        "Ação \(max(0, Int(ceil(actionTimeLeft))))s"
    }

    private func updateChallengeProgress() {
        if !challengeCompleted && score >= challengeGoal {
            challengeCompleted = true
        }
        scoreLabel.text = scoreText()
        timerLabel.text = actionTimerText()
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        busy = true
        selectionRing.isHidden = true

        let reached = challengeCompleted
        let basePearls = GameBalance.challengeBaseReward(score: score,
                                                         reachedTarget: reached,
                                                         phase: phase,
                                                         special: session == .event,
                                                         isHatching: session == .hatching)
        let pearls = GameBalance.scaledPearlReward(baseAmount: basePearls,
                                                   multiplier: shellRewardMultiplier)
        let xp = CGFloat(score) / 5 * (session == .event ? 1.5 : 1)

        let resultTint = reached
            ? UIColor(red: 0.5, green: 0.9, blue: 0.65, alpha: 1)
            : GameUI.accent
        let panel = GameUI.card(size: CGSize(width: 290, height: 220),
                                cornerRadius: 24,
                                tint: resultTint)
        panel.zPosition = 10
        addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 5
        panel.addChild(panelContent)

        let titleText: String
        if session == .hatching {
            titleText = reached ? "Energia reunida!" : "O ovo sentiu o carinho"
        } else {
            titleText = reached ? "Desafio concluído!" : "Boa tentativa!"
        }
        let titleLabel = SKLabelNode(text: titleText)
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 19
        titleLabel.fontColor = GameUI.ink
        titleLabel.position = CGPoint(x: 0, y: 60)
        panelContent.addChild(titleLabel)

        let scoreLine = SKLabelNode(text: "Peças removidas: \(score)")
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.position = CGPoint(x: 0, y: 24)
        panelContent.addChild(scoreLine)

        let rewardText = session == .hatching
            ? "Energia de nascimento +\(score)"
            : "Conchas +\(pearls)   XP +\(Int(xp))"
        let rewardLine = SKLabelNode(text: rewardText)
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.position = CGPoint(x: 0, y: -10)
        panelContent.addChild(rewardLine)

        let continueButton = GameUI.card(size: CGSize(width: 170, height: 44),
                                         cornerRadius: 16,
                                         tint: GameUI.accent,
                                         baseColors: [UIColor(red: 0.22, green: 0.5, blue: 0.82, alpha: 1),
                                                      UIColor(red: 0.12, green: 0.3, blue: 0.6, alpha: 1)])
        continueButton.name = "tide_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        panelContent.addChild(continueButton)

        let continueLabel = SKLabelNode(text: "Continuar")
        continueLabel.fontName = "AvenirNext-DemiBold"
        continueLabel.fontSize = 16
        continueLabel.fontColor = GameUI.ink
        continueLabel.verticalAlignmentMode = .center
        continueLabel.zPosition = 5
        continueLabel.name = "tide_continue"
        continueButton.addChild(continueLabel)

        pendingResult = ChallengeResult(kind: .plot,
                                        score: score,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        xp: xp,
                                        special: session == .event,
                                        isHatching: session == .hatching)
    }

    private func handleFinishedTap(at location: CGPoint) {
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "tide_continue", let result = pendingResult {
                pendingResult = nil
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
