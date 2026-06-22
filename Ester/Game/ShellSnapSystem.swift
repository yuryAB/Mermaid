//
//  ShellSnapSystem.swift
//  Ester
//
//  Desafio: Estalo — inspirado no Match Tap do Pou: tocar grupos adjacentes
//  de 3+ peças iguais, limpar, deixar cair e manter combo rápido.
//

import Foundation
import SpriteKit

// MARK: - Regras e pontuação

private enum ShellSnapRules {
    static let rows = 7
    static let columns = 7
    static let minClusterSize = 3
    static let startTime: CGFloat = 31
    static let maxTime: CGFloat = 36
    static let invalidPenalty: CGFloat = 1
    static let comboWindow: CGFloat = 2.15
    static let frenzyThreshold = 10

    static func goal(for zone: DepthZone, special: Bool) -> Int {
        94 + zone.rawValue * 8 + (special ? 36 : 0)
    }

    static func points(removedCount: Int,
                       pearlCount: Int,
                       streak: Int,
                       frenzy: Bool) -> Int {
        let sizeBonus = max(0, removedCount - minClusterSize) * 2
        let streakBonus = streak >= 3 ? min(10, streak - 2) : 0
        let frenzyBonus = frenzy ? max(2, removedCount / 3) : 0
        return removedCount + sizeBonus + pearlCount * 3 + streakBonus + frenzyBonus
    }

    static func timeBonus(removedCount: Int,
                          streak: Int,
                          frenzy: Bool) -> CGFloat {
        let sizeBonus = min(1.1, CGFloat(max(0, removedCount - minClusterSize)) * 0.16)
        let frenzyBonus: CGFloat
        if streak == frenzyThreshold {
            frenzyBonus = 2.0
        } else {
            frenzyBonus = frenzy ? 0.35 : 0
        }
        return sizeBonus + frenzyBonus
    }
}

private struct ShellSnapTheme {
    let icons: [String]
    let subtitle: String
    let colors: [UIColor]

    static func theme(for zone: DepthZone) -> ShellSnapTheme {
        let colors = [
            GameUI.coral,
            GameUI.gold,
            UIColor(red: 0.30, green: 0.70, blue: 0.86, alpha: 1),
            GameUI.algae,
            UIColor(red: 0.58, green: 0.45, blue: 0.82, alpha: 1),
            UIColor(red: 0.86, green: 0.48, blue: 0.34, alpha: 1)
        ]
        switch zone {
        case .surface:
            return ShellSnapTheme(icons: ["🐬", "🫧", "⭐️", "🐠", "🐚"],
                                  subtitle: "Estalos da Superfície",
                                  colors: colors)
        case .clear:
            return ShellSnapTheme(icons: ["🐚", "🫧", "🐠", "⭐️", "🦀"],
                                  subtitle: "Estalos da Camada Clara",
                                  colors: colors)
        case .shallow:
            return ShellSnapTheme(icons: ["🐚", "🐠", "🦀", "🐡", "⭐️"],
                                  subtitle: "Cardume em Disparo",
                                  colors: colors)
        case .mid:
            return ShellSnapTheme(icons: ["🫧", "🐠", "🐙", "🐡", "🐚"],
                                  subtitle: "Corrente de Estalos",
                                  colors: colors)
        case .blue:
            return ShellSnapTheme(icons: ["🫧", "🐬", "🐠", "🦑", "🐚"],
                                  subtitle: "Clarões da Camada Azul",
                                  colors: colors)
        case .deep:
            return ShellSnapTheme(icons: ["🦑", "🐙", "🐡", "⭐️", "🐚"],
                                  subtitle: "Cristais em Cadeia",
                                  colors: colors)
        case .abyss:
            return ShellSnapTheme(icons: ["🐙", "🦑", "🐡", "🫧", "🐚"],
                                  subtitle: "Pulso Abissal",
                                  colors: colors)
        }
    }
}

// MARK: - Modelo puro de tabuleiro

private struct ShellSnapPosition: Hashable {
    let row: Int
    let column: Int
}

private struct ShellSnapTile {
    let kind: Int
    let carriesPearl: Bool
}

private struct ShellSnapFall {
    let from: ShellSnapPosition
    let to: ShellSnapPosition
}

private struct ShellSnapSpawn {
    let position: ShellSnapPosition
    let startRow: Int
    let tile: ShellSnapTile
}

private struct ShellSnapPop {
    let primaryCluster: Set<ShellSnapPosition>
    let removedTiles: [(position: ShellSnapPosition, tile: ShellSnapTile)]
    let falls: [ShellSnapFall]
    let spawns: [ShellSnapSpawn]
    let splashPositions: Set<ShellSnapPosition>

    var pearlCount: Int {
        removedTiles.filter { $0.tile.carriesPearl }.count
    }
}

private final class ShellSnapBoard {
    let rows: Int
    let columns: Int
    let kindCount: Int
    private let pearlChance: Double

    private(set) var tiles: [[ShellSnapTile]] = []

    init(rows: Int,
         columns: Int,
         kindCount: Int,
         pearlChance: Double = 0.10) {
        self.rows = rows
        self.columns = columns
        self.kindCount = kindCount
        self.pearlChance = pearlChance
        refill()
        reshuffleUntilPlayable(minSize: ShellSnapRules.minClusterSize)
    }

    func tile(at position: ShellSnapPosition) -> ShellSnapTile {
        tiles[position.row][position.column]
    }

    func pop(at position: ShellSnapPosition,
             minSize: Int,
             splashRadius: Int) -> ShellSnapPop? {
        let primary = cluster(at: position)
        guard primary.count >= minSize else { return nil }

        var removal = primary
        if splashRadius > 0 {
            removal.formUnion(expandedPositions(around: primary, radius: splashRadius))
        }
        return collapse(removing: removal, primary: primary)
    }

    func hasValidCluster(minSize: Int) -> Bool {
        var visited = Set<ShellSnapPosition>()
        for row in 0..<rows {
            for column in 0..<columns {
                let position = ShellSnapPosition(row: row, column: column)
                guard !visited.contains(position) else { continue }
                let found = cluster(at: position)
                visited.formUnion(found)
                if found.count >= minSize { return true }
            }
        }
        return false
    }

    @discardableResult
    func reshuffleUntilPlayable(minSize: Int) -> Bool {
        guard !hasValidCluster(minSize: minSize) else { return false }
        for _ in 0..<24 {
            refill()
            if hasValidCluster(minSize: minSize) {
                return true
            }
        }
        forceCluster()
        return true
    }

    private func refill() {
        tiles = (0..<rows).map { _ in
            (0..<columns).map { _ in makeRandomTile() }
        }
    }

    private func makeRandomTile() -> ShellSnapTile {
        ShellSnapTile(kind: Int.random(in: 0..<kindCount),
                      carriesPearl: Double.random(in: 0...1) < pearlChance)
    }

    private func cluster(at start: ShellSnapPosition) -> Set<ShellSnapPosition> {
        let targetKind = tile(at: start).kind
        var visited: Set<ShellSnapPosition> = [start]
        var stack: [ShellSnapPosition] = [start]

        while let current = stack.popLast() {
            for neighbor in neighbors(of: current) where !visited.contains(neighbor) {
                guard tile(at: neighbor).kind == targetKind else { continue }
                visited.insert(neighbor)
                stack.append(neighbor)
            }
        }
        return visited
    }

    private func neighbors(of position: ShellSnapPosition) -> [ShellSnapPosition] {
        [
            ShellSnapPosition(row: position.row + 1, column: position.column),
            ShellSnapPosition(row: position.row - 1, column: position.column),
            ShellSnapPosition(row: position.row, column: position.column + 1),
            ShellSnapPosition(row: position.row, column: position.column - 1)
        ].filter(isValid)
    }

    private func expandedPositions(around cluster: Set<ShellSnapPosition>, radius: Int) -> Set<ShellSnapPosition> {
        guard radius > 0 else { return [] }
        var expanded = Set<ShellSnapPosition>()
        for position in cluster {
            for row in (position.row - radius)...(position.row + radius) {
                for column in (position.column - radius)...(position.column + radius) {
                    let candidate = ShellSnapPosition(row: row, column: column)
                    guard isValid(candidate) else { continue }
                    expanded.insert(candidate)
                }
            }
        }
        return expanded
    }

    private func collapse(removing removal: Set<ShellSnapPosition>,
                          primary: Set<ShellSnapPosition>) -> ShellSnapPop {
        var working = tiles.map { row in row.map { Optional($0) } }
        let sortedRemoval = removal.sorted {
            if $0.row != $1.row { return $0.row < $1.row }
            return $0.column < $1.column
        }
        let removedTiles = sortedRemoval.map { position in
            (position: position, tile: tiles[position.row][position.column])
        }

        for position in removal {
            working[position.row][position.column] = nil
        }

        var falls: [ShellSnapFall] = []
        var spawns: [ShellSnapSpawn] = []

        for column in 0..<columns {
            var survivors: [(from: ShellSnapPosition, tile: ShellSnapTile)] = []
            for row in 0..<rows {
                if let tile = working[row][column] {
                    survivors.append((ShellSnapPosition(row: row, column: column), tile))
                }
                working[row][column] = nil
            }

            var writeRow = 0
            for survivor in survivors {
                let destination = ShellSnapPosition(row: writeRow, column: column)
                working[writeRow][column] = survivor.tile
                if survivor.from != destination {
                    falls.append(ShellSnapFall(from: survivor.from, to: destination))
                }
                writeRow += 1
            }

            var spawnIndex = 0
            while writeRow < rows {
                let tile = makeRandomTile()
                let position = ShellSnapPosition(row: writeRow, column: column)
                working[writeRow][column] = tile
                spawns.append(ShellSnapSpawn(position: position,
                                            startRow: rows + spawnIndex,
                                            tile: tile))
                writeRow += 1
                spawnIndex += 1
            }
        }

        tiles = working.map { row in row.map { $0! } }
        return ShellSnapPop(primaryCluster: primary,
                            removedTiles: removedTiles,
                            falls: falls,
                            spawns: spawns,
                            splashPositions: removal.subtracting(primary))
    }

    private func forceCluster() {
        let row = rows / 2
        let startColumn = max(0, columns / 2 - 1)
        let kind = Int.random(in: 0..<kindCount)
        for column in startColumn..<(startColumn + ShellSnapRules.minClusterSize) {
            guard column < columns else { continue }
            tiles[row][column] = ShellSnapTile(kind: kind, carriesPearl: false)
        }
    }

    private func isValid(_ position: ShellSnapPosition) -> Bool {
        position.row >= 0 && position.row < rows
            && position.column >= 0 && position.column < columns
    }
}

// MARK: - Overlay SpriteKit

final class ShellSnapOverlay: SKNode {
    private let theme: ShellSnapTheme
    private let board: ShellSnapBoard
    private let phase: MermaidPhase
    private let zone: DepthZone
    private let special: Bool
    private let shellRewardMultiplier: CGFloat
    private let challengeGoal: Int
    private let record: ChallengeRecordSnapshot
    private let onFinish: (ChallengeResult) -> Void

    private let cellSize: CGFloat
    private let gridOrigin: CGPoint
    private let boardWidth: CGFloat

    private var pieces: [[SKNode?]]
    private var score = 0
    private var timeLeft = ShellSnapRules.startTime
    private var streak = 0
    private var timeSinceLastPop = ShellSnapRules.comboWindow + 1
    private var frenzyActive = false
    private var challengeCompleted = false
    private var busy = false
    private var finished = false
    private var pendingResult: ChallengeResult?

    private let boardNode = SKNode()
    private var scoreLabel: SKLabelNode!
    private var objectiveLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var streakLabel: SKLabelNode!
    private var frenzyLabel: SKLabelNode!
    private var timerBarFill: SKShapeNode!
    private var timerBarWidth: CGFloat = 0
    private var timerBarLeft: CGFloat = 0

    private enum Visual {
        static let darkTop = UIColor(red: 0.04, green: 0.20, blue: 0.29, alpha: 1)
        static let darkMid = UIColor(red: 0.03, green: 0.13, blue: 0.25, alpha: 1)
        static let darkBottom = UIColor(red: 0.02, green: 0.06, blue: 0.16, alpha: 1)
        static let hot = UIColor(red: 0.94, green: 0.46, blue: 0.34, alpha: 1)
        static let electric = UIColor(red: 0.46, green: 0.91, blue: 0.95, alpha: 1)
    }

    init(size: CGSize,
         zone: DepthZone,
         phase: MermaidPhase,
         special: Bool,
         shellRewardMultiplier: CGFloat,
         giverDisplay: SKNode?,
         record: ChallengeRecordSnapshot,
         onFinish: @escaping (ChallengeResult) -> Void) {
        self.theme = ShellSnapTheme.theme(for: zone)
        self.zone = zone
        self.phase = phase
        self.special = special
        self.shellRewardMultiplier = shellRewardMultiplier
        self.challengeGoal = ShellSnapRules.goal(for: zone, special: special)
        self.record = record
        self.onFinish = onFinish
        self.board = ShellSnapBoard(rows: ShellSnapRules.rows,
                                    columns: ShellSnapRules.columns,
                                    kindCount: theme.icons.count)
        let availableWidth = max(270, size.width - 36)
        let availableHeight = max(280, size.height - 432)
        let resolvedBoardWidth = min(availableWidth, availableHeight, 386)
        self.boardWidth = resolvedBoardWidth
        self.cellSize = resolvedBoardWidth / CGFloat(ShellSnapRules.columns)
        self.gridOrigin = CGPoint(x: -resolvedBoardWidth / 2, y: -resolvedBoardWidth / 2 - 26)
        self.pieces = Array(repeating: Array<SKNode?>(repeating: nil, count: ShellSnapRules.columns),
                            count: ShellSnapRules.rows)

        super.init()
        isUserInteractionEnabled = true
        buildChrome(size: size, giverDisplay: giverDisplay)
        rebuildPieces(animated: false)
        updateStatusUI()
        GameAudio.shared.play(.tideCascade, volumeMultiplier: 0.70)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat) {
        guard !finished else { return }
        timeLeft = max(0, timeLeft - dt)
        timeSinceLastPop += dt
        if streak > 0 && timeSinceLastPop > ShellSnapRules.comboWindow {
            streak = 0
            setFrenzy(false)
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

        let frame = makeFrame(size: CGSize(width: boardWidth + 34, height: boardWidth + 330))
        frame.position = CGPoint(x: 0, y: 42)
        addChild(frame)

        let header = ChallengeChrome.makeHeader(kind: .snap,
                                                subtitle: theme.subtitle,
                                                giverDisplay: giverDisplay,
                                                width: boardWidth)
        header.position = CGPoint(x: 0, y: boardWidth / 2 + 154)
        addChild(header)

        let chipWidth = (boardWidth - 14) / 2
        let scoreChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "bolt.fill",
                                                                     fallback: "!",
                                                                     color: GameUI.gold,
                                                                     size: 22),
                                     title: "Pontos",
                                     value: "\(score)",
                                     width: chipWidth,
                                     accent: GameUI.gold)
        scoreChip.node.position = CGPoint(x: gridOrigin.x + chipWidth / 2,
                                           y: boardWidth / 2 + 48)
        addChild(scoreChip.node)
        scoreLabel = scoreChip.valueLabel

        let objectiveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                         fallback: "o",
                                                                         color: GameUI.coral,
                                                                         size: 22),
                                         title: "Meta",
                                         value: objectiveText(),
                                         width: chipWidth,
                                         accent: GameUI.coral)
        objectiveChip.node.position = CGPoint(x: gridOrigin.x + chipWidth * 1.5 + 14,
                                              y: boardWidth / 2 + 48)
        addChild(objectiveChip.node)
        objectiveLabel = objectiveChip.valueLabel

        timerBarWidth = boardWidth - 34
        timerBarLeft = -timerBarWidth / 2
        addChild(makeTimerBar(width: timerBarWidth, y: boardWidth / 2 - 10))

        streakLabel = SKLabelNode(text: "Combo pronto")
        streakLabel.fontName = "AvenirNext-DemiBold"
        streakLabel.fontSize = 13
        streakLabel.fontColor = GameUI.palePaper.withAlphaComponent(0.86)
        streakLabel.verticalAlignmentMode = .center
        streakLabel.horizontalAlignmentMode = .center
        streakLabel.position = CGPoint(x: 0, y: boardWidth / 2 + 78)
        streakLabel.zPosition = 35
        addChild(streakLabel)

        frenzyLabel = SKLabelNode(text: "")
        frenzyLabel.fontName = "AvenirNext-Heavy"
        frenzyLabel.fontSize = 28
        frenzyLabel.fontColor = Visual.hot
        frenzyLabel.verticalAlignmentMode = .center
        frenzyLabel.horizontalAlignmentMode = .center
        frenzyLabel.position = CGPoint(x: 0, y: boardWidth / 2 + 106)
        frenzyLabel.zPosition = 50
        frenzyLabel.alpha = 0
        addChild(frenzyLabel)

        let quit = GameUI.pill(text: "Sair",
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: 118,
                               height: 38)
        quit.name = "snap_quit"
        quit.position = CGPoint(x: 0, y: gridOrigin.y - 56)
        quit.zPosition = 20
        addChild(quit)

        boardNode.addChild(makeBoardSurface(width: boardWidth))
        addChild(boardNode)
    }

    private func makeBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let texture = GameUI.gradientTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                             colors: [
                                                UIColor.black.withAlphaComponent(0.22),
                                                UIColor.lerp(GameUI.accent, GameUI.ink, 0.34).withAlphaComponent(0.30),
                                                UIColor.lerp(GameUI.gold, GameUI.accent, 0.55).withAlphaComponent(0.17),
                                                UIColor.black.withAlphaComponent(0.32)
                                             ])
        let backdrop = SKSpriteNode(texture: texture)
        backdrop.size = CGSize(width: size.width * 2, height: size.height * 2)
        backdrop.zPosition = -20
        node.addChild(backdrop)

        for i in 0..<12 {
            let path = UIBezierPath()
            let y = size.height * 0.42 - CGFloat(i) * 48
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(i % 2 == 0 ? 18 : -12)),
                          controlPoint1: CGPoint(x: -size.width * 0.32, y: y - 36),
                          controlPoint2: CGPoint(x: size.width * 0.36, y: y + 42))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = UIColor.white.withAlphaComponent(0.045)
            wave.lineWidth = 3
            wave.glowWidth = 7
            wave.zPosition = -10
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: i.isMultiple(of: 2) ? 24 : -18, y: 0, duration: 2.2),
                .moveBy(x: i.isMultiple(of: 2) ? -24 : 18, y: 0, duration: 2.2)
            ])))
        }

        for index in 0..<34 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...6.0))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.045)
            bubble.strokeColor = GameUI.palePaper.withAlphaComponent(0.20)
            bubble.lineWidth = 0.8
            bubble.position = CGPoint(x: CGFloat.random(in: -size.width * 0.55...size.width * 0.55),
                                      y: CGFloat.random(in: -size.height * 0.52...size.height * 0.52))
            bubble.zPosition = -8
            node.addChild(bubble)
            bubble.run(.repeatForever(.sequence([
                .wait(forDuration: Double(index) * 0.06),
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18),
                            y: size.height * CGFloat.random(in: 0.30...0.54),
                            duration: Double.random(in: 3.8...6.4)),
                    .fadeOut(withDuration: Double.random(in: 3.8...6.4))
                ]),
                .moveBy(x: 0, y: -size.height * 0.54, duration: 0),
                .fadeAlpha(to: 0.9, duration: 0.16)
            ])))
        }

        return node
    }

    private func makeFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: GameUI.coral.withAlphaComponent(0.54),
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
        pulse.fillColor = GameUI.coral.withAlphaComponent(0.045)
        pulse.strokeColor = GameUI.gold.withAlphaComponent(0.10)
        pulse.lineWidth = 1
        pulse.zPosition = 2
        node.addChild(pulse)
        pulse.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.64),
            .fadeAlpha(to: 1.0, duration: 0.64)
        ])))

        return node
    }

    private func makeBoardSurface(width: CGFloat) -> SKNode {
        let node = SKNode()
        let center = CGPoint(x: 0, y: gridOrigin.y + width / 2)
        node.zPosition = -20

        let backSize = CGSize(width: width + 18, height: width + 18)
        let back = SKShapeNode(rectOf: backSize, cornerRadius: 26)
        back.position = center
        back.fillTexture = GameUI.gradientTexture(size: backSize,
                                                  colors: [
                                                    UIColor.lerp(Visual.darkTop, GameUI.coral, 0.18),
                                                    Visual.darkMid,
                                                    Visual.darkBottom
                                                  ])
        back.fillColor = .white
        back.strokeColor = GameUI.palePaper.withAlphaComponent(0.20)
        back.lineWidth = 1.5
        node.addChild(back)

        for row in 0..<ShellSnapRules.rows {
            for column in 0..<ShellSnapRules.columns {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize - 6, height: cellSize - 6),
                                       cornerRadius: 12)
                cell.fillColor = ((row + column).isMultiple(of: 2) ? GameUI.palePaper : Visual.electric)
                    .withAlphaComponent((row + column).isMultiple(of: 2) ? 0.12 : 0.07)
                cell.strokeColor = GameUI.palePaper.withAlphaComponent(0.07)
                cell.lineWidth = 0.8
                cell.position = position(of: ShellSnapPosition(row: row, column: column))
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
        valueLabel.preferredMaxLayoutWidth = width - 54
        valueLabel.numberOfLines = 1
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
        timerBarFill.fillColor = Visual.electric.withAlphaComponent(0.76)
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

    // MARK: - Tabuleiro visual

    private func position(of position: ShellSnapPosition) -> CGPoint {
        CGPoint(x: gridOrigin.x + (CGFloat(position.column) + 0.5) * cellSize,
                y: gridOrigin.y + (CGFloat(position.row) + 0.5) * cellSize)
    }

    private func spawnPosition(column: Int, startRow: Int) -> CGPoint {
        CGPoint(x: gridOrigin.x + (CGFloat(column) + 0.5) * cellSize,
                y: gridOrigin.y + (CGFloat(startRow) + 0.5) * cellSize)
    }

    private func gridPos(at location: CGPoint) -> ShellSnapPosition? {
        let column = Int(floor((location.x - gridOrigin.x) / cellSize))
        let row = Int(floor((location.y - gridOrigin.y) / cellSize))
        guard row >= 0, row < ShellSnapRules.rows,
              column >= 0, column < ShellSnapRules.columns else { return nil }
        return ShellSnapPosition(row: row, column: column)
    }

    private func makePiece(tile: ShellSnapTile, at position: ShellSnapPosition) -> SKNode {
        let piece = SKNode()
        piece.position = self.position(of: position)
        piece.zPosition = 10

        let color = theme.colors[tile.kind % theme.colors.count]
        let glow = SKShapeNode(circleOfRadius: cellSize * 0.42)
        glow.fillColor = color.withAlphaComponent(0.16)
        glow.strokeColor = .clear
        glow.glowWidth = 8
        piece.addChild(glow)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: cellSize * 0.66, height: cellSize * 0.22))
        shadow.fillColor = UIColor.black.withAlphaComponent(0.20)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -cellSize * 0.25)
        shadow.zPosition = -2
        piece.addChild(shadow)

        let body = SKShapeNode(circleOfRadius: cellSize * 0.35)
        body.fillTexture = GameUI.gradientTexture(size: CGSize(width: cellSize, height: cellSize),
                                                  colors: [
                                                    UIColor.lerp(color, .white, 0.36),
                                                    color,
                                                    UIColor.lerp(color, Visual.darkBottom, 0.28)
                                                  ])
        body.fillColor = .white
        body.strokeColor = UIColor.white.withAlphaComponent(0.58)
        body.lineWidth = 1.4
        body.glowWidth = 2
        piece.addChild(body)

        let shine = SKShapeNode(circleOfRadius: cellSize * 0.085)
        shine.fillColor = UIColor.white.withAlphaComponent(0.44)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -cellSize * 0.13, y: cellSize * 0.15)
        shine.zPosition = 4
        piece.addChild(shine)

        let icon = SKLabelNode(text: theme.icons[tile.kind])
        icon.fontName = "AppleColorEmoji"
        icon.fontSize = cellSize * 0.42
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: -cellSize * 0.02)
        icon.zPosition = 5
        piece.addChild(icon)

        if tile.carriesPearl {
            let pearl = SKShapeNode(circleOfRadius: cellSize * 0.12)
            pearl.fillColor = GameUI.gold
            pearl.strokeColor = UIColor.white.withAlphaComponent(0.72)
            pearl.lineWidth = 1
            pearl.glowWidth = 4
            pearl.position = CGPoint(x: cellSize * 0.20, y: cellSize * 0.20)
            pearl.zPosition = 7
            piece.addChild(pearl)

            let mark = SKLabelNode(text: "✦")
            mark.fontName = "AvenirNext-Heavy"
            mark.fontSize = cellSize * 0.13
            mark.fontColor = GameUI.ink.withAlphaComponent(0.72)
            mark.verticalAlignmentMode = .center
            mark.horizontalAlignmentMode = .center
            mark.position = pearl.position
            mark.zPosition = 8
            piece.addChild(mark)
        }

        piece.run(.repeatForever(.sequence([
            .scale(to: CGFloat.random(in: 1.02...1.06), duration: Double.random(in: 0.62...0.92)),
            .scale(to: 1.0, duration: Double.random(in: 0.62...0.92))
        ])))
        return piece
    }

    private func rebuildPieces(animated: Bool) {
        for row in 0..<ShellSnapRules.rows {
            for column in 0..<ShellSnapRules.columns {
                pieces[row][column]?.removeFromParent()
                let position = ShellSnapPosition(row: row, column: column)
                let piece = makePiece(tile: board.tile(at: position), at: position)
                if animated {
                    piece.setScale(0.25)
                    piece.alpha = 0
                    piece.run(.group([
                        .scale(to: 1.0, duration: 0.24),
                        .fadeIn(withDuration: 0.20)
                    ]))
                }
                boardNode.addChild(piece)
                pieces[row][column] = piece
            }
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
            if current.name == "snap_quit" {
                GameAudio.shared.play(.uiClosePanel)
                finish()
                return
            }
            node = current.parent
        }

        guard !busy else { return }
        let boardLocation = touch.location(in: boardNode)
        guard let position = gridPos(at: boardLocation) else { return }
        handleTap(at: position)
    }

    private func handleTap(at position: ShellSnapPosition) {
        if timeSinceLastPop > ShellSnapRules.comboWindow {
            streak = 0
            setFrenzy(false)
        }

        let nextStreak = streak + 1
        let nextFrenzy = nextStreak >= ShellSnapRules.frenzyThreshold
        let splashRadius = nextFrenzy ? 1 : 0
        guard let pop = board.pop(at: position,
                                  minSize: ShellSnapRules.minClusterSize,
                                  splashRadius: splashRadius) else {
            handleInvalidTap(at: position)
            return
        }

        busy = true
        streak = nextStreak
        timeSinceLastPop = 0
        setFrenzy(nextFrenzy)

        let gained = ShellSnapRules.points(removedCount: pop.removedTiles.count,
                                           pearlCount: pop.pearlCount,
                                           streak: streak,
                                           frenzy: frenzyActive)
        let addedTime = ShellSnapRules.timeBonus(removedCount: pop.removedTiles.count,
                                                 streak: streak,
                                                 frenzy: frenzyActive)
        score += gained
        timeLeft = min(ShellSnapRules.maxTime, timeLeft + addedTime)

        GameAudio.shared.play(frenzyActive ? .tideCascade : .tideMatch,
                              volumeMultiplier: frenzyActive ? 1.12 : 1.0,
                              cooldownOverride: 0.04)
        updateChallengeProgress()
        showMatchBursts(pop: pop, gained: gained, addedTime: addedTime)
        animate(pop: pop)
    }

    private func handleInvalidTap(at position: ShellSnapPosition) {
        streak = 0
        setFrenzy(false)
        timeLeft = max(0, timeLeft - ShellSnapRules.invalidPenalty)
        GameAudio.shared.play(.tideInvalid)
        updateStatusUI()
        showFloatingLabel(text: "-1s",
                          at: self.position(of: position),
                          color: GameUI.coral,
                          size: 24,
                          drift: CGPoint(x: CGFloat.random(in: -12...12), y: 70))
        pieces[position.row][position.column]?.run(.sequence([
            .moveBy(x: -8, y: 0, duration: 0.04),
            .moveBy(x: 16, y: 0, duration: 0.08),
            .moveBy(x: -8, y: 0, duration: 0.04)
        ]))
        boardNode.run(.sequence([
            .moveBy(x: -6, y: 0, duration: 0.04),
            .moveBy(x: 12, y: 0, duration: 0.08),
            .moveBy(x: -6, y: 0, duration: 0.04)
        ]))
        if timeLeft <= 0 {
            finish()
        }
    }

    // MARK: - Animação de jogada

    private func animate(pop: ShellSnapPop) {
        var nextPieces = pieces
        for item in pop.removedTiles {
            let position = item.position
            guard let piece = pieces[position.row][position.column] else { continue }
            nextPieces[position.row][position.column] = nil
            let color = theme.colors[item.tile.kind % theme.colors.count]
            spawnSparkles(at: piece.position, color: color, count: pop.splashPositions.contains(position) ? 5 : 8)
            piece.removeAllActions()
            piece.run(.sequence([
                .group([
                    .scale(to: pop.splashPositions.contains(position) ? 0.18 : 0.06, duration: 0.22),
                    .rotate(byAngle: CGFloat.pi * CGFloat.random(in: -1.0...1.0), duration: 0.22),
                    .fadeOut(withDuration: 0.22)
                ]),
                .removeFromParent()
            ]))
        }

        for fall in pop.falls {
            guard let piece = pieces[fall.from.row][fall.from.column] else { continue }
            nextPieces[fall.from.row][fall.from.column] = nil
            nextPieces[fall.to.row][fall.to.column] = piece
            let move = SKAction.move(to: position(of: fall.to), duration: 0.24)
            move.timingMode = .easeInEaseOut
            piece.run(move)
        }

        for spawn in pop.spawns {
            let piece = makePiece(tile: spawn.tile, at: spawn.position)
            piece.position = spawnPosition(column: spawn.position.column, startRow: spawn.startRow)
            piece.alpha = 0.0
            boardNode.addChild(piece)
            nextPieces[spawn.position.row][spawn.position.column] = piece

            let fall = SKAction.move(to: position(of: spawn.position), duration: 0.30)
            fall.timingMode = .easeInEaseOut
            piece.run(.group([
                fall,
                .fadeIn(withDuration: 0.14)
            ]))
        }
        pieces = nextPieces

        run(.sequence([
            .wait(forDuration: 0.34),
            .run { [weak self] in
                guard let self, !self.finished else { return }
                if self.board.reshuffleUntilPlayable(minSize: ShellSnapRules.minClusterSize) {
                    self.showFloatingLabel(text: "NOVA MARÉ!",
                                           at: CGPoint(x: 0, y: self.gridOrigin.y + self.boardWidth + 18),
                                           color: Visual.electric,
                                           size: 22,
                                           drift: CGPoint(x: 0, y: 54))
                    self.rebuildPieces(animated: true)
                }
                self.busy = false
            }
        ]))
    }

    private func showMatchBursts(pop: ShellSnapPop, gained: Int, addedTime: CGFloat) {
        let center = center(of: pop.primaryCluster)
        showFloatingLabel(text: "+\(gained)",
                          at: center,
                          color: frenzyActive ? Visual.hot : GameUI.gold,
                          size: frenzyActive ? 30 : 23,
                          drift: CGPoint(x: CGFloat.random(in: -16...16), y: 78))

        if pop.pearlCount > 0 {
            showFloatingLabel(text: "+\(pop.pearlCount) pérola",
                              at: center + CGPoint(x: 0, y: -24),
                              color: GameUI.gold,
                              size: 17,
                              drift: CGPoint(x: CGFloat.random(in: -20...20), y: 64))
        }

        if addedTime >= 0.2 {
            showFloatingLabel(text: "+\(String(format: "%.1f", addedTime))s",
                              at: center + CGPoint(x: 0, y: 26),
                              color: Visual.electric,
                              size: 18,
                              drift: CGPoint(x: CGFloat.random(in: -18...18), y: 66))
        }

        if streak >= 3 {
            showFloatingLabel(text: "COMBO x\(streak)",
                              at: CGPoint(x: 0, y: boardWidth / 2 + 100),
                              color: streak >= ShellSnapRules.frenzyThreshold ? Visual.hot : Visual.electric,
                              size: min(32, 17 + CGFloat(streak)),
                              drift: CGPoint(x: CGFloat.random(in: -10...10), y: 54))
        }

        if streak == ShellSnapRules.frenzyThreshold {
            showFloatingLabel(text: "FRENESI!",
                              at: CGPoint(x: 0, y: 8),
                              color: Visual.hot,
                              size: 38,
                              drift: CGPoint(x: 0, y: 96))
            makeFrenzyFlash()
        } else if frenzyActive && !pop.splashPositions.isEmpty {
            showFloatingLabel(text: "ONDA!",
                              at: center + CGPoint(x: 0, y: -42),
                              color: Visual.hot,
                              size: 24,
                              drift: CGPoint(x: CGFloat.random(in: -22...22), y: 84))
        }
    }

    private func center(of positions: Set<ShellSnapPosition>) -> CGPoint {
        guard !positions.isEmpty else { return .zero }
        let total = positions.reduce(CGPoint.zero) { partial, position in
            partial + self.position(of: position)
        }
        let count = CGFloat(positions.count)
        return CGPoint(x: total.x / count, y: total.y / count)
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
        label.zPosition = 120
        label.setScale(0.68)
        addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: drift.x, y: drift.y, duration: 0.72),
                .fadeOut(withDuration: 0.72),
                .scale(to: 1.20, duration: 0.20)
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
            sparkle.zPosition = 82
            addChild(sparkle)

            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2 + CGFloat.random(in: -0.30...0.30)
            let distance = CGFloat.random(in: 24...54)
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance + CGFloat.random(in: 18...44),
                            duration: 0.42),
                    .rotate(byAngle: CGFloat.random(in: -1.6...1.6), duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: CGFloat.random(in: 0.25...0.55), duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func makeFrenzyFlash() {
        let flash = SKShapeNode(rectOf: CGSize(width: boardWidth + 28, height: boardWidth + 28),
                                cornerRadius: 26)
        flash.position = CGPoint(x: 0, y: gridOrigin.y + boardWidth / 2)
        flash.fillColor = Visual.hot.withAlphaComponent(0.18)
        flash.strokeColor = GameUI.gold.withAlphaComponent(0.72)
        flash.lineWidth = 2
        flash.glowWidth = 10
        flash.zPosition = 70
        addChild(flash)
        flash.run(.sequence([
            .group([
                .scale(to: 1.08, duration: 0.30),
                .fadeOut(withDuration: 0.30)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Estado

    private func updateChallengeProgress() {
        let completedNow = !challengeCompleted && score >= challengeGoal
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
        streakLabel.text = streak > 0 ? "Combo x\(streak)" : "Combo pronto"
        streakLabel.fontColor = frenzyActive ? Visual.hot : GameUI.palePaper.withAlphaComponent(0.86)
        updateTimerUI()
    }

    private func updateTimerUI() {
        guard timerLabel != nil, timerBarFill != nil else { return }
        timerLabel.text = timerText()
        let progress = (timeLeft / ShellSnapRules.startTime).clamped(to: 0...1)
        let visibleProgress = max(0.012, progress)
        timerBarFill.xScale = visibleProgress
        timerBarFill.position = CGPoint(x: timerBarLeft + timerBarWidth * visibleProgress / 2, y: 0)
        timerBarFill.fillColor = progress < 0.24
            ? GameUI.coral.withAlphaComponent(0.84)
            : (frenzyActive ? Visual.hot.withAlphaComponent(0.86) : Visual.electric.withAlphaComponent(0.76))
    }

    private func objectiveText() -> String {
        challengeCompleted ? "Meta completa" : "\(score)/\(challengeGoal)"
    }

    private func timerText() -> String {
        "\(max(0, Int(ceil(timeLeft))))s"
    }

    private func setFrenzy(_ active: Bool) {
        guard frenzyActive != active else { return }
        frenzyActive = active
        if active {
            frenzyLabel.text = "FRENESI"
            frenzyLabel.removeAllActions()
            frenzyLabel.alpha = 1
            frenzyLabel.setScale(0.78)
            frenzyLabel.run(.repeatForever(.sequence([
                .group([.scale(to: 1.10, duration: 0.16), .moveBy(x: 0, y: 4, duration: 0.16)]),
                .group([.scale(to: 0.92, duration: 0.16), .moveBy(x: 0, y: -4, duration: 0.16)])
            ])))
            if boardNode.action(forKey: "snap_frenzy_shake") == nil {
                boardNode.run(.repeatForever(.sequence([
                    .moveBy(x: -4, y: 2, duration: 0.035),
                    .moveBy(x: 8, y: -4, duration: 0.070),
                    .moveBy(x: -4, y: 2, duration: 0.035),
                    .wait(forDuration: 0.12)
                ])), withKey: "snap_frenzy_shake")
            }
        } else {
            frenzyLabel.removeAllActions()
            frenzyLabel.run(.fadeOut(withDuration: 0.18))
            boardNode.removeAction(forKey: "snap_frenzy_shake")
            boardNode.position = .zero
        }
    }

    private func showGoalCompleteBurst() {
        let label = SKLabelNode(text: "META!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 32
        label.fontColor = GameUI.algae
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: gridOrigin.y + cellSize * CGFloat(ShellSnapRules.rows) + 58)
        label.zPosition = 125
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1.18, duration: 0.22),
                .fadeAlpha(to: 1, duration: 0.22)
            ]),
            .wait(forDuration: 0.36),
            .group([
                .moveBy(x: 0, y: 42, duration: 0.34),
                .fadeOut(withDuration: 0.34),
                .scale(to: 0.90, duration: 0.34)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Fim

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .snap,
                                                          reachedTarget: reached ?? challengeCompleted,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: score,
                                                      multiplier: shellRewardMultiplier)
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        busy = true
        setFrenzy(false)
        GameAudio.shared.play(challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .snap,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: special,
                                                          isHatching: false)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 130
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let titleLabel = SKLabelNode(text: reached ? "Estalo perfeito!" : "Boa tentativa!")
        titleLabel.fontName = "AvenirNext-DemiBold"
        titleLabel.fontSize = 19
        titleLabel.fontColor = GameUI.ink
        titleLabel.position = CGPoint(x: 0, y: 60)
        content.addChild(titleLabel)

        let scoreLine = SKLabelNode(text: "Pontos feitos: \(score)")
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
        ChallengeChrome.animatePointConversion(label: rewardLine,
                                               points: score,
                                               pearls: pearls,
                                               newRecord: record.isNewRecord(score: score))

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "snap_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        content.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .snap,
                                        points: score,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        special: special,
                                        previousBestScore: record.bestScore,
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
            if current.name == "snap_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
