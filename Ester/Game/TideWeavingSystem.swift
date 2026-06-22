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
            return TideTheme(icons: ["🐚", "🫧", "🐠", "🦀", "⭐️"],
                             subtitle: "Energia de Nascimento")
        case .region:
            if let region {
                return TideTheme(icons: regionIcons(for: region), subtitle: region.tideTitle)
            }
            return zoneTheme(for: zone)
        case .basic:
            return zoneTheme(for: zone)
        case .event:
            let base = region.map { TideTheme(icons: regionIcons(for: $0), subtitle: $0.tideTitle) }
                ?? zoneTheme(for: zone)
            return TideTheme(icons: base.icons + ["🐙"],
                             subtitle: base.subtitle + " especial")
        }
    }

    private static func regionIcons(for region: Region) -> [String] {
        switch region.id {
        case "recife":
            return ["🐠", "🦀", "🐚", "⭐️", "🐙"]
        case "delta":
            return ["🫧", "🐡", "🐚", "🦑", "🐠"]
        default:
            return ["🐚", "🫧", "🐠", "🦀", "⭐️"]
        }
    }

    private static func zoneTheme(for zone: DepthZone) -> TideTheme {
        switch zone {
        case .clear:
            return TideTheme(icons: ["🐚", "🫧", "🐠", "⭐️", "🦀"], subtitle: "Luzes da Camada Clara")
        case .shallow:
            return TideTheme(icons: ["🐚", "🐠", "🦀", "🐡", "⭐️"], subtitle: "Marés da Camada Rasa")
        case .mid:
            return TideTheme(icons: ["🫧", "🐠", "🐙", "🐡", "🐚"], subtitle: "Correntes da Camada Média")
        case .blue:
            return TideTheme(icons: ["🫧", "🐬", "🐠", "🦑", "🐚"], subtitle: "Marés da Camada Azul")
        case .deep:
            return TideTheme(icons: ["🦑", "🐙", "🐡", "⭐️", "🐚"], subtitle: "Cristais da Camada Profunda")
        case .abyss:
            return TideTheme(icons: ["🐙", "🦑", "🐡", "🫧", "🐚"], subtitle: "Segredos da Camada Abissal")
        case .surface:
            return TideTheme(icons: ["🐬", "🐠", "🫧", "⭐️", "🐚"], subtitle: "Reflexos da Superfície")
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
    private let actionTimeLimit: CGFloat = 10
    private var actionTimeLeft: CGFloat = 10
    private var challengeCompleted = false
    private var busy = false
    private var finished = false
    private var selected: GridPos?
    private var dragStart: (pos: GridPos, location: CGPoint)?

    private let cellSize: CGFloat
    private let gridOrigin: CGPoint
    private var scoreLabel: SKLabelNode!
    private var objectiveLabel: SKLabelNode!
    private var timerLabel: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var timerBarFill: SKShapeNode!
    private var timerBarWidth: CGFloat = 0
    private var timerBarLeft: CGFloat = 0
    private let selectionRing = SKShapeNode(circleOfRadius: 10)
    private let boardNode = SKNode()

    private enum TideVisual {
        static let ink = GameUI.ink
        static let deepSea = UIColor.lerp(GameUI.line, GameUI.ink, 0.42)
        static let gold = GameUI.gold
        static let rose = UIColor.lerp(GameUI.coral, GameUI.paper, 0.18)
        static let mint = GameUI.algae
        static let darkTop = UIColor(red: 0.05, green: 0.22, blue: 0.31, alpha: 1)
        static let darkMid = UIColor(red: 0.04, green: 0.16, blue: 0.27, alpha: 1)
        static let darkBottom = UIColor(red: 0.03, green: 0.09, blue: 0.19, alpha: 1)
        static let shellColors: [UIColor] = [
            GameUI.coral,
            GameUI.gold,
            UIColor.lerp(GameUI.accent, GameUI.palePaper, 0.22),
            GameUI.algae,
            GameUI.line,
            GameUI.mutedInk
        ]
    }

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
        var bonus = GameBalance.challengeShellReward(points: 0,
                                                     kind: .plot,
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

        let availableWidth = max(260, size.width - 36)
        let availableHeight = max(260, size.height - 432)
        let boardWidth = min(availableWidth, availableHeight, 380)
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
        updateTimerUI()
        if actionTimeLeft <= 0 {
            finish()
        }
    }

    // MARK: - Visual fixo

    private func buildChrome(size: CGSize, boardWidth: CGFloat, giverDisplay: SKNode?) {
        addChild(makeUnderwaterBackdrop(size: size))

        let frame = makeReefFrame(size: CGSize(width: boardWidth + 34, height: boardWidth + 320))
        frame.position = CGPoint(x: 0, y: 42)
        addChild(frame)

        let header = makeTideHeader(giverDisplay: giverDisplay, width: boardWidth)
        header.position = CGPoint(x: 0, y: boardWidth / 2 + 150)
        addChild(header)

        let chipWidth = (boardWidth - 14) / 2
        let shellsChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "star.fill",
                                                                      fallback: "★",
                                                                      color: TideVisual.gold,
                                                                      size: 22),
                                      title: "Pontos",
                                      value: scoreText(),
                                      width: chipWidth,
                                      accent: TideVisual.gold)
        shellsChip.node.position = CGPoint(x: gridOrigin.x + chipWidth / 2, y: boardWidth / 2 + 42)
        addChild(shellsChip.node)
        scoreLabel = shellsChip.valueLabel

        let objectiveAccent = challengeCompleted ? TideVisual.mint : TideVisual.rose
        let objectiveChip = makeInfoChip(iconNode: GameUI.symbolIconNode(named: "scope",
                                                                         fallback: "⌾",
                                                                         color: objectiveAccent,
                                                                         size: 22),
                                         title: "Objetivo",
                                         value: objectiveText(),
                                         width: chipWidth,
                                         accent: objectiveAccent)
        objectiveChip.node.position = CGPoint(x: gridOrigin.x + chipWidth * 1.5 + 14,
                                              y: boardWidth / 2 + 42)
        addChild(objectiveChip.node)
        objectiveLabel = objectiveChip.valueLabel

        timerBarWidth = boardWidth - 34
        timerBarLeft = -timerBarWidth / 2
        let timerBarY = boardWidth / 2 - 12
        addChild(makeTimerWave(width: timerBarWidth, y: timerBarY))

        comboLabel = SKLabelNode(text: "")
        comboLabel.fontName = "AvenirNext-Heavy"
        comboLabel.fontSize = 18
        comboLabel.fontColor = GameUI.coral
        comboLabel.verticalAlignmentMode = .center
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.alpha = 0
        comboLabel.zPosition = 30
        comboLabel.position = CGPoint(x: 0, y: boardWidth / 2 + 76)
        addChild(comboLabel)

        let quit = makeReefButton(text: "Sair", width: 118, height: 38, nodeName: "tide_quit")
        quit.position = CGPoint(x: 0, y: gridOrigin.y - 56)
        quit.zPosition = 20
        addChild(quit)

        boardNode.position = .zero
        addChild(boardNode)
        boardNode.addChild(makeBoardReef(width: boardWidth))

        selectionRing.strokeColor = GameUI.gold
        selectionRing.lineWidth = 3.5
        selectionRing.glowWidth = 9
        selectionRing.isHidden = true
        selectionRing.zPosition = 40
        selectionRing.setScale(cellSize / 20)
        selectionRing.run(.repeatForever(.sequence([
            .scale(to: cellSize / 18, duration: 0.38),
            .scale(to: cellSize / 20, duration: 0.38)
        ])))
        boardNode.addChild(selectionRing)
        updateTimerUI()
    }

    private func makeUnderwaterBackdrop(size: CGSize) -> SKNode {
        let node = SKNode()
        node.zPosition = -100

        let backdropSize = CGSize(width: size.width * 2, height: size.height * 2)
        let backdrop = SKSpriteNode(texture: GameUI.gradientTexture(size: backdropSize,
                                                                    colors: [
                                                                        UIColor(white: 0, alpha: 0.12),
                                                                        UIColor.lerp(GameUI.line, GameUI.ink, 0.30).withAlphaComponent(0.20),
                                                                        GameUI.accent.withAlphaComponent(0.18),
                                                                        GameUI.ink.withAlphaComponent(0.24)
                                                                    ]))
        backdrop.size = backdropSize
        backdrop.zPosition = -20
        node.addChild(backdrop)

        for i in 0..<8 {
            let y = size.height * 0.46 - CGFloat(i) * 42
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -size.width, y: y))
            path.addCurve(to: CGPoint(x: size.width, y: y + CGFloat(i % 3) * 10 - 10),
                          controlPoint1: CGPoint(x: -size.width * 0.45, y: y + 28),
                          controlPoint2: CGPoint(x: size.width * 0.40, y: y - 30))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = GameUI.palePaper.withAlphaComponent(0.05 + CGFloat(i % 3) * 0.018)
            wave.lineWidth = 3
            wave.glowWidth = 7
            wave.zPosition = -12
            node.addChild(wave)
            wave.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat(i.isMultiple(of: 2) ? 22 : -18), y: 0, duration: 2.4),
                .moveBy(x: CGFloat(i.isMultiple(of: 2) ? -22 : 18), y: 0, duration: 2.4)
            ])))
        }

        for i in 0..<26 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...5.5))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.05)
            bubble.strokeColor = GameUI.palePaper.withAlphaComponent(0.22)
            bubble.lineWidth = 0.8
            bubble.glowWidth = 2
            bubble.position = CGPoint(x: CGFloat.random(in: -size.width * 0.55...size.width * 0.55),
                                      y: CGFloat.random(in: -size.height * 0.50...size.height * 0.50))
            bubble.zPosition = -8
            node.addChild(bubble)
            let rise = SKAction.sequence([
                .group([
                    .moveBy(x: CGFloat.random(in: -18...18),
                            y: size.height * CGFloat.random(in: 0.38...0.58),
                            duration: Double.random(in: 4.0...7.0)),
                    .fadeAlpha(to: 0.0, duration: Double.random(in: 4.0...7.0))
                ]),
                .moveBy(x: 0, y: -size.height * 0.52, duration: 0),
                .fadeAlpha(to: 0.85, duration: 0.2)
            ])
            bubble.run(.repeatForever(.sequence([.wait(forDuration: Double(i) * 0.07), rise])))
        }

        return node
    }

    private func makeReefFrame(size: CGSize) -> SKNode {
        let node = GameUI.card(size: size,
                               cornerRadius: 26,
                               tint: GameUI.accent.withAlphaComponent(0.50),
                               baseColors: [GameUI.palePaper, GameUI.paper])
        node.zPosition = -5

        let darkSurface = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                                      cornerRadius: 22)
        darkSurface.fillTexture = GameUI.gradientTexture(size: size,
                                                         colors: [
                                                             TideVisual.darkTop,
                                                             TideVisual.darkMid,
                                                             TideVisual.darkBottom
                                                         ])
        darkSurface.fillColor = .white
        darkSurface.strokeColor = GameUI.accent.withAlphaComponent(0.24)
        darkSurface.lineWidth = 1
        darkSurface.zPosition = 0.5
        node.addChild(darkSurface)

        let darkHighlight = SKShapeNode(rectOf: CGSize(width: size.width - 20, height: size.height - 20),
                                        cornerRadius: 18)
        darkHighlight.fillColor = GameUI.gold.withAlphaComponent(0.045)
        darkHighlight.strokeColor = UIColor.white.withAlphaComponent(0.05)
        darkHighlight.lineWidth = 1
        darkHighlight.zPosition = 0.7
        node.addChild(darkHighlight)

        let currentPath = UIBezierPath()
        currentPath.move(to: CGPoint(x: -size.width / 2 + 28, y: size.height / 2 - 54))
        currentPath.addCurve(to: CGPoint(x: size.width / 2 - 28, y: size.height / 2 - 62),
                             controlPoint1: CGPoint(x: -size.width * 0.18, y: size.height / 2 - 28),
                             controlPoint2: CGPoint(x: size.width * 0.26, y: size.height / 2 - 86))
        let current = SKShapeNode(path: currentPath.cgPath)
        current.fillColor = .clear
        current.strokeColor = GameUI.palePaper.withAlphaComponent(0.12)
        current.lineWidth = 3
        current.lineCap = .round
        current.zPosition = 3
        node.addChild(current)

        for side: CGFloat in [-1, 1] {
            let coral = makeCoralSprig(height: 80,
                                       color: side < 0 ? GameUI.coral : GameUI.algae)
            coral.position = CGPoint(x: side * (size.width / 2 - 26), y: -size.height / 2 + 48)
            coral.zPosition = 3
            coral.xScale = side
            node.addChild(coral)
        }

        return node
    }

    private func makeTideHeader(giverDisplay: SKNode?, width: CGFloat) -> SKNode {
        let header = SKNode()

        let titlePanel = SKShapeNode(rectOf: CGSize(width: width - 92, height: 82), cornerRadius: 24)
        titlePanel.fillTexture = GameUI.paperTexture(size: CGSize(width: width - 92, height: 82),
                                                     base: GameUI.palePaper)
        titlePanel.fillColor = .white
        titlePanel.strokeColor = GameUI.line.withAlphaComponent(0.30)
        titlePanel.lineWidth = 1.3
        titlePanel.position = CGPoint(x: 34, y: -14)
        header.addChild(titlePanel)

        let shellGlow = SKShapeNode(circleOfRadius: 48)
        shellGlow.fillColor = GameUI.gold.withAlphaComponent(0.12)
        shellGlow.strokeColor = GameUI.gold.withAlphaComponent(0.68)
        shellGlow.lineWidth = 1.8
        shellGlow.glowWidth = 2
        shellGlow.position = CGPoint(x: -width / 2 + 54, y: -8)
        header.addChild(shellGlow)
        shellGlow.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.72),
            .scale(to: 1.0, duration: 0.72)
        ])))

        if let giver = giverDisplay {
            giver.setScale(ChallengeChrome.fitScale(for: giver, targetHeight: 50))
            giver.position = shellGlow.position
            giver.zPosition = 4
            header.addChild(giver)
            giver.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 5, duration: 0.55),
                .moveBy(x: 0, y: -5, duration: 0.55)
            ])))
        } else {
            let fish = makeCourierFish(color: TideVisual.gold)
            fish.position = shellGlow.position
            fish.zPosition = 4
            header.addChild(fish)
        }

        let courier = SKLabelNode(text: "peixinho-correio")
        courier.fontName = "AvenirNext-DemiBold"
        courier.fontSize = 10.5
        courier.fontColor = GameUI.mutedInk
        courier.verticalAlignmentMode = .center
        courier.position = CGPoint(x: shellGlow.position.x, y: -66)
        header.addChild(courier)

        let title = SKLabelNode(text: "Desafio: Trama")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 24
        title.fontColor = GameUI.ink
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: -width / 2 + 112, y: 2)
        title.zPosition = 3
        header.addChild(title)

        let subtitle = SKLabelNode(text: theme.subtitle)
        subtitle.fontName = "AvenirNext-DemiBold"
        subtitle.fontSize = 13
        subtitle.fontColor = GameUI.accent
        subtitle.horizontalAlignmentMode = .left
        subtitle.verticalAlignmentMode = .center
        subtitle.preferredMaxLayoutWidth = max(120, width - 136)
        subtitle.numberOfLines = 1
        subtitle.position = CGPoint(x: title.position.x, y: -28)
        subtitle.zPosition = 3
        header.addChild(subtitle)

        for i in 0..<5 {
            let spark = SKLabelNode(text: i.isMultiple(of: 2) ? "✦" : "◌")
            spark.fontName = "AvenirNext-DemiBold"
            spark.fontSize = CGFloat(12 + i)
            spark.fontColor = TideVisual.shellColors[i % TideVisual.shellColors.count].withAlphaComponent(0.45)
            spark.position = CGPoint(x: -width / 2 + 92 + CGFloat(i) * 38,
                                     y: 34 + CGFloat(i % 2) * 10)
            header.addChild(spark)
            spark.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.28, duration: 0.7 + Double(i) * 0.08),
                .fadeAlpha(to: 0.82, duration: 0.7 + Double(i) * 0.08)
            ])))
        }

        return header
    }

    private func makeCourierFish(color: UIColor) -> SKNode {
        let node = SKNode()

        let body = SKShapeNode(ellipseOf: CGSize(width: 58, height: 30))
        body.fillColor = color
        body.strokeColor = UIColor.white.withAlphaComponent(0.45)
        body.lineWidth = 1.2
        body.glowWidth = 4
        node.addChild(body)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -25, y: 0))
        tailPath.addLine(to: CGPoint(x: -48, y: 17))
        tailPath.addLine(to: CGPoint(x: -44, y: -16))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = UIColor.lerp(color, TideVisual.rose, 0.35)
        tail.strokeColor = .clear
        node.addChild(tail)

        let fin = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
        fin.fillColor = UIColor.white.withAlphaComponent(0.26)
        fin.strokeColor = .clear
        fin.position = CGPoint(x: 0, y: -9)
        fin.zRotation = -0.35
        node.addChild(fin)

        let eye = SKShapeNode(circleOfRadius: 4)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: 18, y: 6)
        node.addChild(eye)

        let pupil = SKShapeNode(circleOfRadius: 2)
        pupil.fillColor = TideVisual.ink
        pupil.strokeColor = .clear
        pupil.position = eye.position
        node.addChild(pupil)

        node.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 5, duration: 0.55),
            .moveBy(x: 0, y: -5, duration: 0.55)
        ])))

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

    private func makeTimerWave(width: CGFloat, y: CGFloat) -> SKNode {
        let node = SKNode()
        node.position = CGPoint(x: 0, y: y)
        node.zPosition = 12

        let back = SKShapeNode(rectOf: CGSize(width: width, height: 10), cornerRadius: 5)
        back.fillColor = GameUI.line.withAlphaComponent(0.12)
        back.strokeColor = GameUI.line.withAlphaComponent(0.20)
        back.lineWidth = 1
        node.addChild(back)

        timerBarFill = SKShapeNode(rectOf: CGSize(width: width, height: 10), cornerRadius: 5)
        timerBarFill.fillColor = GameUI.accent.withAlphaComponent(0.72)
        timerBarFill.strokeColor = .clear
        timerBarFill.glowWidth = 1
        timerBarFill.zPosition = 1
        node.addChild(timerBarFill)

        timerLabel = SKLabelNode(text: actionTimerText())
        timerLabel.fontName = "AvenirNext-DemiBold"
        timerLabel.fontSize = 11
        timerLabel.fontColor = GameUI.palePaper
        timerLabel.verticalAlignmentMode = .center
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.zPosition = 2
        node.addChild(timerLabel)

        return node
    }

    private func makeBoardReef(width: CGFloat) -> SKNode {
        let node = SKNode()
        let center = CGPoint(x: 0, y: gridOrigin.y + width / 2)
        node.zPosition = -30

        let backSize = CGSize(width: width + 18, height: width + 18)
        let back = SKShapeNode(rectOf: backSize, cornerRadius: 26)
        back.position = center
        back.fillTexture = GameUI.gradientTexture(size: backSize,
                                                  colors: [
                                                      UIColor.lerp(TideVisual.darkTop, GameUI.accent, 0.18),
                                                      TideVisual.darkMid,
                                                      TideVisual.darkBottom
                                                  ])
        back.fillColor = .white
        back.strokeColor = GameUI.palePaper.withAlphaComponent(0.18)
        back.lineWidth = 1.5
        node.addChild(back)

        for r in 0..<gridSize {
            for c in 0..<gridSize {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize - 6, height: cellSize - 6),
                                       cornerRadius: 14)
                cell.fillColor = ((r + c).isMultiple(of: 2) ? GameUI.palePaper : GameUI.accent)
                    .withAlphaComponent((r + c).isMultiple(of: 2) ? 0.13 : 0.08)
                cell.strokeColor = GameUI.palePaper.withAlphaComponent(0.08)
                cell.lineWidth = 0.8
                cell.position = position(of: GridPos(r: r, c: c))
                cell.zPosition = 1
                node.addChild(cell)
            }
        }

        for c in 0..<gridSize {
            let pearl = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.0...4.5))
            pearl.fillColor = GameUI.gold.withAlphaComponent(0.14)
            pearl.strokeColor = .clear
            pearl.position = CGPoint(x: gridOrigin.x + (CGFloat(c) + 0.4) * cellSize,
                                     y: gridOrigin.y - CGFloat.random(in: 3...11))
            pearl.zPosition = 3
            node.addChild(pearl)
        }

        return node
    }

    private func makeReefButton(text: String, width: CGFloat, height: CGFloat, nodeName: String) -> SKNode {
        let node = GameUI.pill(text: text,
                               fontSize: 15,
                               bold: false,
                               fill: [GameUI.coral.withAlphaComponent(0.95)],
                               strokeColor: GameUI.coral.withAlphaComponent(0.55),
                               textColor: GameUI.ink,
                               hPadding: 26,
                               minWidth: width,
                               height: height)
        node.name = nodeName
        return node
    }

    private func makeMiniShell(color: UIColor, size: CGFloat) -> SKNode {
        let node = SKNode()
        let shell = SKShapeNode(ellipseOf: CGSize(width: size, height: size * 0.82))
        shell.fillColor = color
        shell.strokeColor = UIColor.white.withAlphaComponent(0.50)
        shell.lineWidth = 1
        shell.glowWidth = 3
        node.addChild(shell)

        for offset in [-0.18, 0, 0.18] {
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: size * CGFloat(offset), y: -size * 0.30))
            rib.addCurve(to: CGPoint(x: size * CGFloat(offset) * 0.18, y: size * 0.30),
                         controlPoint1: CGPoint(x: size * CGFloat(offset) * 1.45, y: -size * 0.06),
                         controlPoint2: CGPoint(x: size * CGFloat(offset) * 0.65, y: size * 0.22))
            let ribNode = SKShapeNode(path: rib.cgPath)
            ribNode.strokeColor = UIColor.white.withAlphaComponent(0.30)
            ribNode.lineWidth = 1
            ribNode.fillColor = .clear
            node.addChild(ribNode)
        }
        return node
    }

    private func makeCoralSprig(height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        for i in 0..<4 {
            let path = UIBezierPath()
            let x = CGFloat(i) * 6 - 9
            path.move(to: CGPoint(x: 0, y: -height / 2))
            path.addCurve(to: CGPoint(x: x, y: height / 2 - CGFloat(i) * 9),
                          controlPoint1: CGPoint(x: CGFloat(i - 1) * 9, y: -height * 0.16),
                          controlPoint2: CGPoint(x: x * 1.5, y: height * 0.18))
            let branch = SKShapeNode(path: path.cgPath)
            branch.strokeColor = color.withAlphaComponent(0.72)
            branch.lineWidth = CGFloat(5 - min(i, 2))
            branch.lineCap = .round
            branch.fillColor = .clear
            node.addChild(branch)
        }
        return node
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
        piece.zPosition = 10

        let color = TideVisual.shellColors[kind % TideVisual.shellColors.count]
        let glow = SKShapeNode(circleOfRadius: cellSize * 0.43)
        glow.fillColor = color.withAlphaComponent(0.16)
        glow.strokeColor = .clear
        glow.glowWidth = 8
        piece.addChild(glow)

        let shadow = SKShapeNode(circleOfRadius: cellSize * 0.36)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -cellSize * 0.05)
        shadow.zPosition = -1
        piece.addChild(shadow)

        let shell = SKShapeNode(circleOfRadius: cellSize * 0.37)
        shell.fillTexture = GameUI.gradientTexture(size: CGSize(width: cellSize, height: cellSize),
                                                   colors: [
                                                       UIColor.lerp(color, .white, 0.35),
                                                       color,
                                                       UIColor.lerp(color, TideVisual.deepSea, 0.25)
                                                   ])
        shell.fillColor = .white
        shell.strokeColor = UIColor.white.withAlphaComponent(0.58)
        shell.lineWidth = 1.4
        shell.glowWidth = 2
        piece.addChild(shell)

        let shine = SKShapeNode(circleOfRadius: cellSize * 0.095)
        shine.fillColor = UIColor.white.withAlphaComponent(0.42)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -cellSize * 0.14, y: cellSize * 0.15)
        shine.zPosition = 3
        piece.addChild(shine)

        for offset in [-0.20, 0, 0.20] {
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: cellSize * CGFloat(offset), y: -cellSize * 0.25))
            rib.addCurve(to: CGPoint(x: cellSize * CGFloat(offset) * 0.22, y: cellSize * 0.25),
                         controlPoint1: CGPoint(x: cellSize * CGFloat(offset) * 1.25, y: -cellSize * 0.02),
                         controlPoint2: CGPoint(x: cellSize * CGFloat(offset) * 0.65, y: cellSize * 0.16))
            let ribNode = SKShapeNode(path: rib.cgPath)
            ribNode.strokeColor = UIColor.white.withAlphaComponent(0.26)
            ribNode.lineWidth = 1
            ribNode.lineCap = .round
            ribNode.fillColor = .clear
            ribNode.zPosition = 2
            piece.addChild(ribNode)
        }

        let icon = SKLabelNode(text: theme.icons[kind])
        icon.fontName = "AppleColorEmoji"
        icon.fontSize = cellSize * 0.44
        icon.fontColor = TideVisual.ink.withAlphaComponent(0.82)
        icon.verticalAlignmentMode = .center
        icon.position = CGPoint(x: 0, y: -cellSize * 0.015)
        icon.zPosition = 5
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
                GameAudio.shared.play(.uiClosePanel)
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
                GameAudio.shared.play(.tideSelect)
            }
        } else {
            selected = pos
            selectionRing.position = position(of: pos)
            selectionRing.isHidden = false
            GameAudio.shared.play(.tideSelect)
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
        GameAudio.shared.play(.tideSwap)
        swapData(a, b)
        animateSwap(a, b) { [weak self] in
            guard let self else { return }
            guard !self.finished else { return }
            if self.findMatches().isEmpty {
                GameAudio.shared.play(.tideInvalid)
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

        let gained = matches.count
        let burstPoint = center(of: matches)
        score += gained
        GameAudio.shared.play(multiplier > 1 ? .tideCascade : .tideMatch)
        actionTimeLeft = actionTimeLimit
        updateChallengeProgress()
        showScoreBurst(at: burstPoint, gained: gained, multiplier: multiplier)

        for pos in matches {
            let matchedKind = board[pos.r][pos.c]
            board[pos.r][pos.c] = -1
            spawnSparkles(at: position(of: pos),
                          color: TideVisual.shellColors[matchedKind % TideVisual.shellColors.count])
            if let piece = pieces[pos.r][pos.c] {
                pieces[pos.r][pos.c] = nil
                piece.run(.sequence([
                    .group([
                        .scale(to: 0.1, duration: 0.22),
                        .rotate(byAngle: CGFloat.pi * 0.8, duration: 0.22),
                        .fadeOut(withDuration: 0.22)
                    ]),
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

    private func center(of matches: Set<GridPos>) -> CGPoint {
        guard !matches.isEmpty else { return .zero }
        let sum = matches.reduce(CGPoint.zero) { partial, pos in
            partial + position(of: pos)
        }
        let count = CGFloat(matches.count)
        return CGPoint(x: sum.x / count, y: sum.y / count)
    }

    private func showScoreBurst(at point: CGPoint, gained: Int, multiplier: Int) {
        let label = SKLabelNode(text: session == .hatching ? "+\(gained) energia" : "+\(gained) pontos")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = multiplier > 1 ? 25 : 21
        label.fontColor = multiplier > 1 ? TideVisual.rose : TideVisual.gold
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = point
        label.zPosition = 90
        label.setScale(0.72)
        addChild(label)

        let float = SKAction.group([
            .moveBy(x: CGFloat.random(in: -14...14), y: 72, duration: 0.72),
            .fadeOut(withDuration: 0.72),
            .scale(to: 1.22, duration: 0.24)
        ])
        label.run(.sequence([float, .removeFromParent()]))

        if multiplier > 1 {
            comboLabel.removeAllActions()
            comboLabel.text = "COMBO x\(multiplier)"
            comboLabel.fontColor = TideVisual.shellColors[multiplier % TideVisual.shellColors.count]
            comboLabel.alpha = 1
            comboLabel.setScale(0.82)
            comboLabel.run(.sequence([
                .group([.scale(to: 1.14, duration: 0.18), .moveBy(x: 0, y: 8, duration: 0.18)]),
                .wait(forDuration: 0.34),
                .group([.fadeOut(withDuration: 0.24), .moveBy(x: 0, y: -8, duration: 0.24)])
            ]))
        }
    }

    private func spawnSparkles(at point: CGPoint, color: UIColor) {
        for i in 0..<7 {
            let sparkle = SKLabelNode(text: i.isMultiple(of: 2) ? "✦" : "◌")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = CGFloat.random(in: 10...18)
            sparkle.fontColor = UIColor.lerp(color, .white, CGFloat.random(in: 0.18...0.52))
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = point
            sparkle.zPosition = 75
            addChild(sparkle)

            let drift = CGPoint(x: CGFloat.random(in: -34...34),
                                y: CGFloat.random(in: 26...58))
            sparkle.run(.sequence([
                .group([
                    .moveBy(x: drift.x, y: drift.y, duration: 0.42),
                    .rotate(byAngle: CGFloat.random(in: -1.4...1.4), duration: 0.42),
                    .fadeOut(withDuration: 0.42),
                    .scale(to: CGFloat.random(in: 0.25...0.55), duration: 0.42)
                ]),
                .removeFromParent()
            ]))
        }
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
        if session == .hatching {
            return "Energia \(score)"
        }
        return "Pontos \(score)"
    }

    private func objectiveText() -> String {
        if challengeCompleted {
            guard session != .hatching else { return "Nascimento pronto" }
            return challengeBonus > 0 ? "Meta completa" : "Objetivo completo"
        }
        return "Meta \(score)/\(challengeGoal)"
    }

    private func actionTimerText() -> String {
        "Onda \(max(0, Int(ceil(actionTimeLeft))))s"
    }

    private func projectedPearls(reached: Bool? = nil) -> Int {
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .plot,
                                                          reachedTarget: reached ?? challengeCompleted,
                                                          phase: phase,
                                                          special: session == .event,
                                                          isHatching: session == .hatching)
        return GameBalance.scaledChallengePearlReward(baseAmount: basePearls,
                                                      points: score,
                                                      multiplier: shellRewardMultiplier)
    }

    private func updateChallengeProgress() {
        let completedNow = !challengeCompleted && score >= challengeGoal
        if !challengeCompleted && score >= challengeGoal {
            challengeCompleted = true
        }
        scoreLabel.text = scoreText()
        objectiveLabel.text = objectiveText()
        updateTimerUI()
        pulseStatusLabel(scoreLabel)
        pulseStatusLabel(objectiveLabel)
        if completedNow {
            GameAudio.shared.play(.tideGoal)
            showGoalCompleteBurst()
        }
    }

    private func updateTimerUI() {
        guard timerLabel != nil, timerBarFill != nil else { return }
        timerLabel.text = actionTimerText()
        let progress = (actionTimeLeft / actionTimeLimit).clamped(to: 0...1)
        let visibleProgress = max(0.015, progress)
        timerBarFill.xScale = visibleProgress
        timerBarFill.position = CGPoint(x: timerBarLeft + timerBarWidth * visibleProgress / 2, y: 0)
        timerBarFill.fillColor = progress < 0.28
            ? GameUI.coral.withAlphaComponent(0.82)
            : GameUI.accent.withAlphaComponent(0.72)
    }

    private func pulseStatusLabel(_ label: SKLabelNode) {
        label.removeAction(forKey: "status_pulse")
        label.run(.sequence([
            .scale(to: 1.12, duration: 0.10),
            .scale(to: 1.0, duration: 0.18)
        ]), withKey: "status_pulse")
    }

    private func showGoalCompleteBurst() {
        let label = SKLabelNode(text: session == .hatching ? "NASCIMENTO!" : "META!")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 30
        label.fontColor = TideVisual.mint
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: gridOrigin.y + cellSize * CGFloat(gridSize) + 54)
        label.zPosition = 95
        label.setScale(0.6)
        addChild(label)
        label.run(.sequence([
            .group([
                .scale(to: 1.18, duration: 0.22),
                .fadeAlpha(to: 1, duration: 0.22)
            ]),
            .wait(forDuration: 0.36),
            .group([
                .moveBy(x: 0, y: 38, duration: 0.34),
                .fadeOut(withDuration: 0.34),
                .scale(to: 0.90, duration: 0.34)
            ]),
            .removeFromParent()
        ]))
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        busy = true
        selectionRing.isHidden = true
        GameAudio.shared.play(challengeCompleted ? .challengeSuccess : .challengeFail)

        let reached = challengeCompleted
        let basePearls = GameBalance.challengeShellReward(points: score,
                                                          kind: .plot,
                                                          reachedTarget: reached,
                                                          phase: phase,
                                                          special: session == .event,
                                                          isHatching: session == .hatching)
        let pearls = projectedPearls(reached: reached)

        let panel = makeResultPanel(reached: reached)
        panel.zPosition = 100
        addChild(panel)

        let panelContent = SKNode()
        panelContent.zPosition = 8
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

        let scoreLine = SKLabelNode(text: session == .hatching
                                    ? "Energia reunida: \(score)"
                                    : "Pontos feitos: \(score)")
        scoreLine.fontName = "AvenirNext-Regular"
        scoreLine.fontSize = 16
        scoreLine.fontColor = GameUI.mutedInk
        scoreLine.position = CGPoint(x: 0, y: 24)
        panelContent.addChild(scoreLine)

        let rewardText = session == .hatching
            ? "Energia de nascimento +\(score)"
            : "Convertendo pontos..."
        let rewardLine = SKLabelNode(text: rewardText)
        rewardLine.fontName = "AvenirNext-DemiBold"
        rewardLine.fontSize = 17
        rewardLine.fontColor = GameUI.gold
        rewardLine.position = CGPoint(x: 0, y: -10)
        panelContent.addChild(rewardLine)
        if session != .hatching {
            ChallengeChrome.animatePointConversion(label: rewardLine, points: score, pearls: pearls)
        }

        let continueButton = GameUI.pill(text: "Continuar",
                                         fontSize: 16,
                                         fill: [GameUI.accent],
                                         strokeColor: GameUI.accent.withAlphaComponent(0.62),
                                         textColor: GameUI.ink,
                                         hPadding: 26,
                                         minWidth: 170,
                                         height: 44)
        continueButton.name = "tide_continue"
        continueButton.position = CGPoint(x: 0, y: -68)
        panelContent.addChild(continueButton)

        pendingResult = ChallengeResult(kind: .plot,
                                        points: score,
                                        reachedTarget: reached,
                                        pearls: basePearls,
                                        special: session == .event,
                                        isHatching: session == .hatching)
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
            if current.name == "tide_continue", let result = pendingResult {
                pendingResult = nil
                GameAudio.shared.play(.uiConfirm)
                onFinish(result)
                return
            }
            node = current.parent
        }
    }
}
