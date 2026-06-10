//
//  TideWeavingSystem.swift
//  Ester
//
//  Trama das Marés: o único tipo de puzzle do jogo (combinar 3+ peças).
//  A fantasia é a sereia alinhando pérolas, conchas, cristais e correntes.
//  Sessões: básica (sempre disponível), de região, de evento e de choco.
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
            return TideTheme(icons: ["🫧", "✨", "💛", "🐚", "💙"],
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
            return TideTheme(icons: base.icons + ["👑"],
                             subtitle: "✨ " + base.subtitle + " ✨")
        }
    }

    private static func zoneTheme(for zone: DepthZone) -> TideTheme {
        switch zone {
        case .clear:
            return TideTheme(icons: ["🫧", "☀️", "⭐️", "🌿", "🐚"], subtitle: "Luzes da Camada Clara")
        case .shallow:
            return TideTheme(icons: ["🐚", "🫧", "⭐️", "🌿", "🦀"], subtitle: "Conchas da Camada Rasa")
        case .mid:
            return TideTheme(icons: ["💧", "🐟", "🌀", "⭐️", "🫧"], subtitle: "Correntes da Camada Média")
        case .blue:
            return TideTheme(icons: ["💧", "🌀", "🐟", "💎", "🫧"], subtitle: "Marés da Camada Azul")
        case .deep:
            return TideTheme(icons: ["💎", "✨", "🦑", "🔮", "🌟"], subtitle: "Cristais da Camada Profunda")
        case .abyss:
            return TideTheme(icons: ["💎", "🔮", "🦑", "✨", "🌑"], subtitle: "Segredos da Camada Abissal")
        case .surface:
            return TideTheme(icons: ["⚓️", "🫧", "☀️", "🛟", "🐬"], subtitle: "Reflexos da Superfície")
        }
    }
}

struct TideResult {
    let score: Int
    let reachedTarget: Bool
    let pearls: Int
    let xp: CGFloat
    let session: TideSessionType
}

// MARK: - Fio da Trama no mundo

final class PuzzlePointNode: SKNode {
    let zone: DepthZone
    let special: Bool

    init(zone: DepthZone, special: Bool) {
        self.zone = zone
        self.special = special
        super.init()
        name = "puzzlePoint"
        zPosition = 6

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 46))
        path.addLine(to: CGPoint(x: 26, y: 10))
        path.addLine(to: CGPoint(x: 14, y: -38))
        path.addLine(to: CGPoint(x: -14, y: -38))
        path.addLine(to: CGPoint(x: -26, y: 10))
        path.close()
        let crystal = SKShapeNode(path: path.cgPath)
        crystal.fillColor = special
            ? UIColor(red: 1, green: 0.8, blue: 0.35, alpha: 0.9)
            : UIColor(red: 0.55, green: 0.8, blue: 1, alpha: 0.9)
        crystal.strokeColor = .white
        crystal.glowWidth = special ? 18 : 12
        addChild(crystal)

        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.9),
            .scale(to: 1.0, duration: 0.9)
        ]))
        pulse.eaeInEaseOut()
        crystal.run(pulse)
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 14, duration: 1.3),
            .moveBy(x: 0, y: -14, duration: 1.3)
        ])))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Sistema (fios no mundo)

final class TideWeavingSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var puzzlePoint: PuzzlePointNode?
    private var specialExpiry: CGFloat = -1

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        if specialExpiry > 0 {
            specialExpiry -= dt
            if specialExpiry <= 0, let point = puzzlePoint, point.special {
                clearPoint()
                ctx.say("O brilho especial da Trama se desfez nas águas...")
            }
        }
    }

    /// Garante um fio da Trama perto da sereia e devolve a posição dele.
    @discardableResult
    func ensurePuzzlePoint(near point: CGPoint, zone: DepthZone) -> CGPoint {
        if let existing = puzzlePoint,
           existing.position.distance(to: point) < 2200 {
            return existing.position
        }
        clearPoint()
        guard let world = worldNode else { return point }

        let node = PuzzlePointNode(zone: zone, special: false)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 300...550)
        node.position = CGPoint(
            x: (point.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (point.y + sin(angle) * distance).clamped(to: ctx.depth.allowedYRange())
        )
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.7))
        world.addChild(node)
        puzzlePoint = node
        return node.position
    }

    /// Fio especial criado por eventos (recompensas maiores, expira).
    func spawnSpecialPoint(near point: CGPoint, zone: DepthZone) {
        clearPoint()
        guard let world = worldNode else { return }
        let node = PuzzlePointNode(zone: zone, special: true)
        node.position = CGPoint(
            x: (point.x + .random(in: -450...450)).clamped(to: World.minX...World.maxX),
            y: (point.y + .random(in: -300...300)).clamped(to: ctx.depth.allowedYRange())
        )
        node.alpha = 0
        node.run(.fadeIn(withDuration: 0.7))
        world.addChild(node)
        puzzlePoint = node
        specialExpiry = 90
    }

    func clearPoint() {
        puzzlePoint?.run(.sequence([.fadeOut(withDuration: 0.4), .removeFromParent()]))
        puzzlePoint = nil
        specialExpiry = -1
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
    private let target: Int
    private let session: TideSessionType
    private let rewardMultiplier: CGFloat
    private let onFinish: (TideResult) -> Void

    private var board: [[Int]] = []
    private var pieces: [[SKNode?]] = []
    private var score = 0
    private var movesLeft = 16
    private var busy = false
    private var finished = false
    private var selected: GridPos?
    private var dragStart: (pos: GridPos, location: CGPoint)?

    private let cellSize: CGFloat
    private let gridOrigin: CGPoint
    private var scoreLabel: SKLabelNode!
    private var movesLabel: SKLabelNode!
    private let selectionRing = SKShapeNode(circleOfRadius: 10)
    private let boardNode = SKNode()

    init(size: CGSize,
         zone: DepthZone,
         region: Region?,
         session: TideSessionType,
         rewardMultiplier: CGFloat,
         onFinish: @escaping (TideResult) -> Void) {
        self.theme = TideTheme.theme(for: zone, region: region, session: session)
        self.kindCount = theme.icons.count
        self.session = session
        self.rewardMultiplier = rewardMultiplier
        var goal = 400 + zone.rawValue * 100
        if session == .event { goal += 200 }
        if session == .hatching { goal = 350 }
        self.target = goal
        self.onFinish = onFinish

        let boardWidth = min(size.width - 36, 380)
        self.cellSize = boardWidth / CGFloat(gridSize)
        self.gridOrigin = CGPoint(x: -boardWidth / 2, y: -boardWidth / 2 - 30)

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, boardWidth: boardWidth)
        fillInitialBoard()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, boardWidth: CGFloat) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.6)
        backdrop.strokeColor = .clear
        addChild(backdrop)

        let panel = SKShapeNode(rectOf: CGSize(width: boardWidth + 28, height: boardWidth + 190),
                                cornerRadius: 22)
        panel.fillColor = UIColor(red: 0.06, green: 0.12, blue: 0.22, alpha: 0.95)
        panel.strokeColor = UIColor(white: 1, alpha: 0.25)
        panel.lineWidth = 2
        panel.position = CGPoint(x: 0, y: -30)
        addChild(panel)

        let title = SKLabelNode(text: "Trama das Marés")
        title.fontName = "Helvetica-Bold"
        title.fontSize = 19
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: boardWidth / 2 + 96)
        addChild(title)

        let subtitle = SKLabelNode(text: theme.subtitle)
        subtitle.fontName = "Helvetica"
        subtitle.fontSize = 13
        subtitle.fontColor = UIColor(red: 0.65, green: 0.85, blue: 1, alpha: 1)
        subtitle.position = CGPoint(x: 0, y: boardWidth / 2 + 74)
        addChild(subtitle)

        scoreLabel = SKLabelNode(text: "0 / \(target)")
        scoreLabel.fontName = "Helvetica-Bold"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = UIColor(red: 0.6, green: 0.9, blue: 1, alpha: 1)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: gridOrigin.x, y: boardWidth / 2 + 44)
        addChild(scoreLabel)

        movesLabel = SKLabelNode(text: "Jogadas: \(movesLeft)")
        movesLabel.fontName = "Helvetica"
        movesLabel.fontSize = 16
        movesLabel.fontColor = .white
        movesLabel.horizontalAlignmentMode = .right
        movesLabel.position = CGPoint(x: gridOrigin.x + boardWidth, y: boardWidth / 2 + 44)
        addChild(movesLabel)

        let quit = SKLabelNode(text: "✕ Sair")
        quit.fontName = "Helvetica"
        quit.fontSize = 15
        quit.fontColor = UIColor(white: 1, alpha: 0.7)
        quit.name = "tide_quit"
        quit.position = CGPoint(x: 0, y: gridOrigin.y - 56)
        addChild(quit)

        boardNode.position = .zero
        addChild(boardNode)

        selectionRing.strokeColor = .white
        selectionRing.lineWidth = 3
        selectionRing.glowWidth = 4
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
        icon.fontSize = cellSize * 0.55
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
            if self.findMatches().isEmpty {
                self.swapData(a, b)
                self.animateSwap(a, b) { [weak self] in
                    self?.busy = false
                }
            } else {
                self.movesLeft -= 1
                self.movesLabel.text = "Jogadas: \(self.movesLeft)"
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
        let matches = findMatches()
        if matches.isEmpty {
            busy = false
            if !hasPossibleMove() { reshuffle() }
            if movesLeft <= 0 { finish() }
            return
        }

        score += matches.count * 10 * multiplier
        scoreLabel.text = "\(score) / \(target)"

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

    private var pendingResult: TideResult?

    private func finish() {
        guard !finished else { return }
        finished = true
        busy = true
        selectionRing.isHidden = true

        let reached = score >= target
        var pearls = Int(CGFloat(score) / 12 * rewardMultiplier)
        if reached { pearls += 12 }
        if session == .event { pearls = Int(CGFloat(pearls) * 1.5) }
        let xp = CGFloat(score) / 5 * (session == .event ? 1.5 : 1)

        let panel = SKShapeNode(rectOf: CGSize(width: 290, height: 220), cornerRadius: 20)
        panel.fillColor = UIColor(red: 0.08, green: 0.16, blue: 0.28, alpha: 0.98)
        panel.strokeColor = reached
            ? UIColor(red: 0.6, green: 0.95, blue: 0.7, alpha: 1)
            : UIColor(white: 1, alpha: 0.4)
        panel.lineWidth = 2
        panel.zPosition = 10
        addChild(panel)

        let titleText: String
        if session == .hatching {
            titleText = reached ? "Energia reunida! 🥚✨" : "O ovo sentiu o carinho 💛"
        } else {
            titleText = reached ? "Trama concluída! 🎉" : "Boa tentativa!"
        }
        let titleLabel = SKLabelNode(text: titleText)
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 19
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: 0, y: 60)
        panel.addChild(titleLabel)

        let scoreLine = SKLabelNode(text: "Pontuação: \(score)")
        scoreLine.fontName = "Helvetica"
        scoreLine.fontSize = 16
        scoreLine.fontColor = .white
        scoreLine.position = CGPoint(x: 0, y: 24)
        panel.addChild(scoreLine)

        let rewardLine = SKLabelNode(text: "💠 +\(pearls)   ⭐️ +\(Int(xp)) XP")
        rewardLine.fontName = "Helvetica-Bold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = UIColor(red: 0.7, green: 0.9, blue: 1, alpha: 1)
        rewardLine.position = CGPoint(x: 0, y: -10)
        panel.addChild(rewardLine)

        let continueButton = SKShapeNode(rectOf: CGSize(width: 170, height: 44), cornerRadius: 12)
        continueButton.fillColor = UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1)
        continueButton.strokeColor = .clear
        continueButton.name = "tide_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        panel.addChild(continueButton)

        let continueLabel = SKLabelNode(text: "Continuar")
        continueLabel.fontName = "Helvetica-Bold"
        continueLabel.fontSize = 16
        continueLabel.fontColor = .white
        continueLabel.verticalAlignmentMode = .center
        continueLabel.name = "tide_continue"
        continueButton.addChild(continueLabel)

        pendingResult = TideResult(score: score, reachedTarget: reached,
                                   pearls: pearls, xp: xp, session: session)
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
