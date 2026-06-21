//
//  ChallengeSystem.swift
//  Ester
//
//  Sistema de Desafios: NPCs do mundo (hoje, peixes; no futuro, tubarões,
//  outras sereias...) oferecem desafios. A sereia vai até quem oferece,
//  o NPC fica em destaque no topo enquanto o minijogo acontece embaixo.
//  Para adicionar um novo tipo de desafio: criar um ChallengeKind novo,
//  um overlay próprio e rotear em GameScene.openChallenge.
//

import Foundation
import SpriteKit

// MARK: - Tipos de desafio

enum ChallengeKind: String, CaseIterable, Codable {
    /// Match-3 (antiga "Trama das Marés").
    case plot
    /// Subir o mais alto possível pegando bolhas antes do tempo acabar.
    case ascent
    /// Tocar grupos de 3+ peças iguais antes do tempo acabar.
    case snap

    var shortName: String {
        switch self {
        case .plot: return "Trama"
        case .ascent: return "Subida"
        case .snap: return "Estalo"
        }
    }

    var title: String { "Desafio: \(shortName)" }

    var blurb: String {
        switch self {
        case .plot: return "Combine correntes, faça sequências e junte conchas."
        case .ascent: return "Suba pelas bolhas antes que o fôlego acabe."
        case .snap: return "Toque grupos iguais, mantenha combo e solte ondas."
        }
    }

    var icon: String {
        switch self {
        case .plot: return "≈"
        case .ascent: return "○"
        case .snap: return "✦"
        }
    }

    var tint: UIColor {
        switch self {
        case .plot: return GameUI.accent
        case .ascent: return UIColor(red: 0.38, green: 0.58, blue: 0.90, alpha: 1)
        case .snap: return GameUI.coral
        }
    }
}

// MARK: - Quem oferece desafios

/// Qualquer entidade do mundo capaz de oferecer um desafio.
/// Hoje só peixes conformam; o protocolo deixa o caminho aberto para
/// tubarões, outras sereias e o que mais vier.
protocol ChallengeGiver: AnyObject {
    /// Desafio que esta entidade está oferecendo (nil = nenhum).
    var offeredChallenge: ChallengeKind? { get set }
    /// Recompensas maiores (desafios especiais de evento).
    var isSpecialChallenge: Bool { get set }
    /// Posição no mundo, para a sereia nadar até lá.
    var worldPosition: CGPoint { get }
    /// Cópia visual estática para ficar em destaque no topo do desafio.
    func makeGiverDisplayNode() -> SKNode
}

// MARK: - Resultado genérico

struct ChallengeResult {
    let kind: ChallengeKind
    let points: Int
    let reachedTarget: Bool
    let pearls: Int
    let special: Bool
    /// Só usado pelo match-3 durante a fase de ovo.
    let isHatching: Bool
}

// MARK: - Sistema

final class ChallengeSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    /// Chamado quando um peixe nasce: decide se ele oferece um desafio.
    func decorateSpawn(_ fish: FishNode) {
        guard ctx.stats.phase != .egg else { return }
        let maxNearbyGivers = GameBalance.maxNearbyChallengeGivers(for: ctx.stats.phase)
        let spawnChallengeChance = GameBalance.challengeSpawnChanceTenths(for: ctx.stats.phase)
        guard nearbyGivers(to: fish.position, maxDistance: 2600).count < maxNearbyGivers else { return }
        guard Int.random(in: 0..<10) < spawnChallengeChance else { return }
        fish.offeredChallenge = ChallengeKind.allCases.randomElement()
    }

    func nearbyGivers(to point: CGPoint, maxDistance: CGFloat) -> [FishNode] {
        ctx.fish.fishes.filter {
            $0.offeredChallenge != nil
                && $0.position.distance(to: point) <= maxDistance
        }
    }

    func nearestGiver(to point: CGPoint, maxDistance: CGFloat) -> FishNode? {
        nearbyGivers(to: point, maxDistance: maxDistance)
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
    }

    /// Garante que existe um peixe com desafio por perto (botão "Desafio").
    @discardableResult
    func ensureGiver(near point: CGPoint, kind preferredKind: ChallengeKind? = nil) -> FishNode? {
        if let preferredKind,
           let existing = nearbyGivers(to: point, maxDistance: 2200)
            .filter({ $0.offeredChallenge == preferredKind })
            .min(by: { $0.position.distance(to: point) < $1.position.distance(to: point) }) {
            return existing
        }
        if preferredKind == nil, let existing = nearestGiver(to: point, maxDistance: 2200) {
            return existing
        }
        let zone = DepthZone.zone(atY: point.y)
        guard let fish = ctx.fish.spawnFish(zone: zone, near: point) else { return nil }
        fish.offeredChallenge = preferredKind ?? ChallengeKind.allCases.randomElement()
        return fish
    }

    /// Peixe dourado especial criado por eventos (recompensas maiores).
    func spawnSpecialGiver(near point: CGPoint, zone: DepthZone) {
        guard let fish = ctx.fish.spawnFish(zone: zone, near: point, rare: true) else { return }
        fish.offeredChallenge = ChallengeKind.allCases.randomElement()
        fish.isSpecialChallenge = true
    }

    /// O desafio foi jogado: o peixe volta à vida normal.
    func consumeChallenge(of giver: ChallengeGiver) {
        giver.offeredChallenge = nil
        giver.isSpecialChallenge = false
    }
}

// MARK: - Escolha de desafio

final class ChallengeChoiceOverlay: SKNode {
    private let onSelect: (ChallengeKind) -> Void
    private let onClose: () -> Void
    private var choiceKinds: [String: ChallengeKind] = [:]

    init(size: CGSize,
         kinds: [ChallengeKind] = ChallengeKind.allCases,
         onSelect: @escaping (ChallengeKind) -> Void,
         onClose: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onClose = onClose
        super.init()
        isUserInteractionEnabled = true

        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2.2, height: size.height * 2.2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.54)
        backdrop.strokeColor = .clear
        backdrop.name = "challenge_choice_close"
        addChild(backdrop)

        let panelWidth = min(size.width - 32, size.width >= 700 ? 444 : 368)
        let rowHeight: CGFloat = 82
        let rowSpacing: CGFloat = 10
        let panelHeight = min(size.height - 52,
                              148 + CGFloat(kinds.count) * rowHeight + CGFloat(max(0, kinds.count - 1)) * rowSpacing)

        let panel = GameUI.card(size: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 22,
                                tint: GameUI.gold.withAlphaComponent(0.74),
                                baseColors: [UIColor.lerp(GameUI.palePaper, GameUI.gold, 0.05)])
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let title = makeLabel("Desafios", fontSize: 20, color: GameUI.ink, bold: true)
        title.position = CGPoint(x: -panelWidth / 2 + 24, y: panelHeight / 2 - 32)
        content.addChild(title)

        let subtitle = makeLabel("Qual chamado enviar para ela?",
                                 fontSize: 12,
                                 color: GameUI.mutedInk,
                                 maxWidth: panelWidth - 48)
        subtitle.position = CGPoint(x: -panelWidth / 2 + 24, y: panelHeight / 2 - 56)
        content.addChild(subtitle)

        let rowWidth = panelWidth - 32
        let firstRowY = panelHeight / 2 - 102
        for (index, kind) in kinds.enumerated() {
            let key = kind.rawValue
            let rowName = "challenge_choice_\(key)"
            choiceKinds[key] = kind

            let row = GameUI.card(size: CGSize(width: rowWidth, height: rowHeight),
                                  cornerRadius: 14,
                                  tint: kind.tint.withAlphaComponent(0.72),
                                  baseColors: GameUI.tintedColors(kind.tint))
            row.name = rowName
            row.position = CGPoint(x: 0, y: firstRowY - CGFloat(index) * (rowHeight + rowSpacing))
            content.addChild(row)

            let rowContent = SKNode()
            rowContent.zPosition = 6
            row.addChild(rowContent)

            let iconRing = SKShapeNode(circleOfRadius: 22)
            iconRing.fillColor = UIColor.lerp(GameUI.palePaper, kind.tint, 0.18)
            iconRing.strokeColor = kind.tint.withAlphaComponent(0.68)
            iconRing.lineWidth = 1.1
            iconRing.position = CGPoint(x: -rowWidth / 2 + 38, y: 8)
            rowContent.addChild(iconRing)

            let icon = SKLabelNode(text: kind.icon)
            icon.fontName = "AvenirNext-Heavy"
            icon.fontSize = 22
            icon.fontColor = UIColor.lerp(GameUI.ink, kind.tint, 0.26)
            icon.horizontalAlignmentMode = .center
            icon.verticalAlignmentMode = .center
            icon.position = iconRing.position
            icon.zPosition = 3
            rowContent.addChild(icon)

            let name = makeLabel(kind.title,
                                 fontSize: 15,
                                 color: GameUI.ink,
                                 bold: true,
                                 maxWidth: rowWidth - 152)
            name.position = CGPoint(x: -rowWidth / 2 + 74, y: 20)
            rowContent.addChild(name)

            let blurb = makeLabel(kind.blurb,
                                  fontSize: 10.8,
                                  color: GameUI.mutedInk,
                                  maxWidth: rowWidth - 152,
                                  lines: 2)
            blurb.position = CGPoint(x: -rowWidth / 2 + 74, y: -7)
            rowContent.addChild(blurb)

            let action = GameUI.pill(text: "Pedir",
                                     fontSize: 12,
                                     fill: [kind.tint.withAlphaComponent(0.92)],
                                     strokeColor: kind.tint.withAlphaComponent(0.55),
                                     minWidth: 72,
                                     height: 30)
            action.name = rowName
            action.position = CGPoint(x: rowWidth / 2 - 48, y: -20)
            action.zPosition = 7
            rowContent.addChild(action)
        }

        let close = GameUI.pill(text: "Voltar",
                                fontSize: 13,
                                bold: false,
                                fill: [GameUI.coral.withAlphaComponent(0.92)],
                                strokeColor: GameUI.coral.withAlphaComponent(0.55),
                                minWidth: 104,
                                height: 32)
        close.name = "challenge_choice_close"
        close.position = CGPoint(x: 0, y: -panelHeight / 2 + 30)
        close.zPosition = 12
        content.addChild(close)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        var node: SKNode? = atPoint(location)
        while let current = node {
            if let name = current.name {
                if name == "challenge_choice_close" {
                    onClose()
                    return
                }
                if name.hasPrefix("challenge_choice_") {
                    let key = String(name.dropFirst("challenge_choice_".count))
                    if let kind = choiceKinds[key] {
                        onSelect(kind)
                        return
                    }
                }
            }
            node = current.parent
        }
    }

    private func makeLabel(_ text: String,
                           fontSize: CGFloat,
                           color: UIColor,
                           bold: Bool = false,
                           maxWidth: CGFloat = 0,
                           lines: Int = 1) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        if maxWidth > 0 {
            label.preferredMaxLayoutWidth = maxWidth
            label.numberOfLines = lines
        }
        return label
    }
}

// MARK: - Cabeçalho compartilhado dos overlays

enum ChallengeChrome {
    /// Escala para um nó caber numa altura alvo.
    static func fitScale(for node: SKNode, targetHeight: CGFloat) -> CGFloat {
        let frame = node.calculateAccumulatedFrame()
        guard frame.height > 1 else { return 1 }
        return min(1.2, targetHeight / frame.height)
    }

    /// Cabeçalho com o NPC que deu o desafio em destaque + título.
    /// Devolve o nó pronto para posicionar no topo do painel.
    static func makeHeader(kind: ChallengeKind,
                           subtitle: String,
                           giverDisplay: SKNode?,
                           width: CGFloat) -> SKNode {
        let header = SKNode()

        // destaque do NPC (anel dourado pulsante)
        if let giver = giverDisplay {
            let spotlight = SKShapeNode(circleOfRadius: 35)
            spotlight.fillColor = GameUI.gold.withAlphaComponent(0.10)
            spotlight.strokeColor = GameUI.gold.withAlphaComponent(0.72)
            spotlight.lineWidth = 2
            spotlight.glowWidth = 1
            spotlight.position = .zero
            header.addChild(spotlight)
            spotlight.run(.repeatForever(.sequence([
                .scale(to: 1.08, duration: 0.9),
                .scale(to: 1.0, duration: 0.9)
            ])))

            giver.setScale(fitScale(for: giver, targetHeight: 42))
            giver.position = .zero
            header.addChild(giver)
        } else {
            header.addChild(makeSketchIcon(kind: kind))
        }

        let title = GameUI.pill(text: kind.title,
                                fontSize: 17,
                                fill: [GameUI.gold.withAlphaComponent(0.95)],
                                strokeColor: GameUI.gold.withAlphaComponent(0.55),
                                textColor: GameUI.ink,
                                hPadding: 22,
                                height: 38)
        title.position = CGPoint(x: 0, y: -62)
        header.addChild(title)

        let sub = SKLabelNode(text: subtitle)
        sub.fontName = "AvenirNext-Regular"
        sub.fontSize = 13
        sub.fontColor = GameUI.mutedInk
        sub.verticalAlignmentMode = .center
        sub.preferredMaxLayoutWidth = width - 24
        sub.numberOfLines = 1
        sub.position = CGPoint(x: 0, y: -94)
        header.addChild(sub)

        return header
    }

    private static func makeSketchIcon(kind: ChallengeKind) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: 25)
        ring.fillColor = GameUI.palePaper.withAlphaComponent(0.75)
        ring.strokeColor = GameUI.accent.withAlphaComponent(0.72)
        ring.lineWidth = 1.5
        node.addChild(ring)

        switch kind {
        case .plot:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -15, y: -2))
            path.addCurve(to: CGPoint(x: 0, y: 8),
                          controlPoint1: CGPoint(x: -11, y: 10),
                          controlPoint2: CGPoint(x: -2, y: 14))
            path.addCurve(to: CGPoint(x: 15, y: -4),
                          controlPoint1: CGPoint(x: 4, y: -6),
                          controlPoint2: CGPoint(x: 10, y: -8))
            path.addCurve(to: CGPoint(x: -4, y: -11),
                          controlPoint1: CGPoint(x: 10, y: 5),
                          controlPoint2: CGPoint(x: -3, y: 2))
            let wave = SKShapeNode(path: path.cgPath)
            wave.fillColor = .clear
            wave.strokeColor = GameUI.accent
            wave.lineWidth = 2
            wave.lineCap = .round
            wave.lineJoin = .round
            node.addChild(wave)
        case .ascent:
            let arrow = UIBezierPath()
            arrow.move(to: CGPoint(x: 0, y: -14))
            arrow.addLine(to: CGPoint(x: 0, y: 14))
            arrow.move(to: CGPoint(x: -8, y: 6))
            arrow.addLine(to: CGPoint(x: 0, y: 14))
            arrow.addLine(to: CGPoint(x: 8, y: 6))
            let arrowNode = SKShapeNode(path: arrow.cgPath)
            arrowNode.fillColor = .clear
            arrowNode.strokeColor = GameUI.accent
            arrowNode.lineWidth = 2
            arrowNode.lineCap = .round
            arrowNode.lineJoin = .round
            node.addChild(arrowNode)

            for point in [CGPoint(x: -11, y: -5), CGPoint(x: 11, y: 0), CGPoint(x: -8, y: 9)] {
                let dot = SKShapeNode(circleOfRadius: 2)
                dot.fillColor = GameUI.accent.withAlphaComponent(0.70)
                dot.strokeColor = .clear
                dot.position = point
                node.addChild(dot)
            }
        case .snap:
            let burst = UIBezierPath()
            for angle in stride(from: CGFloat(0), to: CGFloat.pi * 2, by: CGFloat.pi / 4) {
                burst.move(to: CGPoint(x: cos(angle) * 4, y: sin(angle) * 4))
                burst.addLine(to: CGPoint(x: cos(angle) * 16, y: sin(angle) * 16))
            }
            let burstNode = SKShapeNode(path: burst.cgPath)
            burstNode.fillColor = .clear
            burstNode.strokeColor = GameUI.coral
            burstNode.lineWidth = 2
            burstNode.lineCap = .round
            node.addChild(burstNode)

            let core = SKShapeNode(circleOfRadius: 6)
            core.fillColor = GameUI.gold.withAlphaComponent(0.82)
            core.strokeColor = UIColor.white.withAlphaComponent(0.50)
            core.lineWidth = 1
            node.addChild(core)
        }

        return node
    }

    static func animatePointConversion(label: SKLabelNode, points: Int, pearls: Int) {
        let duration: TimeInterval = 1.1
        let durationCGFloat = CGFloat(duration)
        label.removeAllActions()
        label.text = "Convertendo pontos..."

        let count = SKAction.customAction(withDuration: duration) { node, elapsed in
            guard let label = node as? SKLabelNode else { return }
            let t = max(0, min(1, elapsed / durationCGFloat))
            let eased = t * t * (3 - 2 * t)
            let shownPoints = Int((CGFloat(points) * eased).rounded())
            let shownPearls = Int((CGFloat(pearls) * eased).rounded())
            label.text = "\(shownPoints) pontos = \(GameUI.shellAmountText(shownPearls)) conchas"
        }
        let settle = SKAction.run {
            label.text = "\(points) pontos = \(GameUI.shellAmountText(pearls)) conchas"
        }
        let pulseStep = SKAction.sequence([
            .scale(to: 1.08, duration: 0.12),
            .scale(to: 1.0, duration: 0.18)
        ])
        let pulse = SKAction.repeat(pulseStep, count: 4)

        label.run(.group([.sequence([count, settle]), pulse]))
    }

    /// Altura total ocupada pelo cabeçalho (NPC + título + subtítulo).
    static let headerHeight: CGFloat = 130
}
