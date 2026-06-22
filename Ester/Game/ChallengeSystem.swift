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

enum ChallengeKind: String, CaseIterable, Codable, Hashable {
    /// Match-3 (antiga "Trama das Marés").
    case plot
    /// Subir o mais alto possível pegando bolhas antes do tempo acabar.
    case ascent
    /// Tocar grupos de 3+ peças iguais antes do tempo acabar.
    case snap
    /// Comer alimentos bons, crescer e desviar de perigos numa arena.
    case banquet
    /// Virar cartas, lembrar posições e encontrar todos os pares.
    case memory
    /// Escutar uma sequencia musical e reproduzir o canto crescente.
    case echoMelody
    /// Pedras e corais quebram em partes menores numa arena infinita de high score.
    case reefAsteroids

    // Pausados: mantidos no projeto, mas fora de sorteios, menus e abertura direta.
    static let disabledCases: Set<ChallengeKind> = [.ascent, .reefAsteroids]

    static var availableCases: [ChallengeKind] {
        allCases.filter(\.isAvailable)
    }

    var isAvailable: Bool {
        !Self.disabledCases.contains(self)
    }

    var shortName: String {
        switch self {
        case .plot: return "Trama"
        case .ascent: return "Subida"
        case .snap: return "Estalo"
        case .banquet: return "Banquete"
        case .memory: return "Lembrança"
        case .echoMelody: return "Eco"
        case .reefAsteroids: return "Ruptura"
        }
    }

    var title: String {
        switch self {
        case .banquet: return "Desafio: Banquete das Marés"
        case .memory: return "Desafio: Lembranças da Maré"
        case .echoMelody: return "Desafio: Canto dos Ecos"
        case .reefAsteroids: return "Desafio: Ruptura do Recife"
        default: return "Desafio: \(shortName)"
        }
    }

    var blurb: String {
        switch self {
        case .plot: return "Combine correntes, faça sequências e junte conchas."
        case .ascent: return "Suba pelas bolhas antes que o fôlego acabe."
        case .snap: return "Toque grupos iguais, mantenha combo e solte ondas."
        case .banquet: return "Coma as delícias, cresça e fuja dos perigos."
        case .memory: return "Vire pares, guarde posições e complete a lembrança."
        case .echoMelody: return "Escute a maré, repita as notas e segure o eco."
        case .reefAsteroids: return "Quebre pedras e corais, faça combo e sobreviva à maré."
        }
    }

    var icon: String {
        switch self {
        case .plot: return "≈"
        case .ascent: return "○"
        case .snap: return "✦"
        case .banquet: return "●"
        case .memory: return "?"
        case .echoMelody: return "♪"
        case .reefAsteroids: return "◆"
        }
    }

    var tint: UIColor {
        switch self {
        case .plot: return GameUI.accent
        case .ascent: return UIColor(red: 0.38, green: 0.58, blue: 0.90, alpha: 1)
        case .snap: return GameUI.coral
        case .banquet: return GameUI.gold
        case .memory: return UIColor(red: 0.38, green: 0.86, blue: 0.92, alpha: 1)
        case .echoMelody: return UIColor(red: 0.45, green: 0.82, blue: 0.92, alpha: 1)
        case .reefAsteroids: return UIColor(red: 0.26, green: 0.75, blue: 0.92, alpha: 1)
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
    /// Meta definida pela entidade que oferece o desafio.
    var offeredChallengeGoal: Int? { get set }
    /// Recompensas maiores (desafios especiais de evento).
    var isSpecialChallenge: Bool { get set }
    /// Posição no mundo, para a sereia nadar até lá.
    var worldPosition: CGPoint { get }
    /// Cópia visual estática para ficar em destaque no topo do desafio.
    func makeGiverDisplayNode() -> SKNode
}

// MARK: - Resultado genérico

struct ChallengeRecordSnapshot {
    let kind: ChallengeKind
    let bestScore: Int

    var displayText: String {
        bestScore > 0 ? "Recorde \(bestScore)" : "Sem recorde"
    }

    func isNewRecord(score: Int, isHatching: Bool = false) -> Bool {
        !isHatching && score > bestScore
    }

    static func empty(for kind: ChallengeKind) -> ChallengeRecordSnapshot {
        ChallengeRecordSnapshot(kind: kind, bestScore: 0)
    }
}

struct ChallengeResult {
    let kind: ChallengeKind
    let points: Int
    let reachedTarget: Bool
    let pearls: Int
    let special: Bool
    let victoryReward: ChallengeVictoryReward
    let previousBestScore: Int
    /// Só usado pelo match-3 durante a fase de ovo.
    let isHatching: Bool

    var madeHighScore: Bool {
        !isHatching && points > previousBestScore
    }

    var bestScoreAfterRun: Int {
        max(previousBestScore, points)
    }
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
        guard let kind = ChallengeKind.availableCases.randomElement() else { return }
        assignChallenge(kind, to: fish, special: false)
    }

    func nearbyGivers(to point: CGPoint, maxDistance: CGFloat) -> [FishNode] {
        ctx.fish.fishes.filter {
            $0.offeredChallenge?.isAvailable == true
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
        if preferredKind?.isAvailable == false { return nil }
        if let preferredKind,
           let existing = nearbyGivers(to: point, maxDistance: 2200)
            .filter({ $0.offeredChallenge == preferredKind })
            .min(by: { $0.position.distance(to: point) < $1.position.distance(to: point) }) {
            ensureGoal(for: existing, kind: preferredKind)
            return existing
        }
        if preferredKind == nil, let existing = nearestGiver(to: point, maxDistance: 2200) {
            if let kind = existing.offeredChallenge {
                ensureGoal(for: existing, kind: kind)
            }
            return existing
        }
        let resolvedKind: ChallengeKind
        if let preferredKind {
            resolvedKind = preferredKind
        } else if let randomKind = ChallengeKind.availableCases.randomElement() {
            resolvedKind = randomKind
        } else {
            return nil
        }
        let zone = DepthZone.zone(atY: point.y)
        guard let fish = ctx.fish.spawnFish(zone: zone, near: point) else { return nil }
        assignChallenge(resolvedKind, to: fish, special: false)
        return fish
    }

    /// Peixe dourado especial criado por eventos (recompensas maiores).
    func spawnSpecialGiver(near point: CGPoint, zone: DepthZone) {
        guard let kind = ChallengeKind.availableCases.randomElement() else { return }
        guard let fish = ctx.fish.spawnFish(zone: zone, near: point, rare: true) else { return }
        assignChallenge(kind, to: fish, special: true)
    }

    /// O desafio foi jogado: o peixe volta à vida normal.
    func consumeChallenge(of giver: ChallengeGiver) {
        giver.offeredChallenge = nil
        giver.offeredChallengeGoal = nil
        giver.isSpecialChallenge = false
    }

    func makeGoal(kind: ChallengeKind, special: Bool, at point: CGPoint) -> Int {
        GameBalance.randomChallengeGoal(for: kind,
                                        zone: DepthZone.zone(atY: point.y),
                                        special: special)
    }

    private func assignChallenge(_ kind: ChallengeKind, to fish: FishNode, special: Bool) {
        fish.isSpecialChallenge = special
        fish.offeredChallengeGoal = GameBalance.randomChallengeGoal(for: kind,
                                                                    zone: fish.zone,
                                                                    special: special)
        fish.offeredChallenge = kind
    }

    private func ensureGoal(for fish: FishNode, kind: ChallengeKind) {
        guard fish.offeredChallengeGoal == nil else { return }
        fish.offeredChallengeGoal = GameBalance.randomChallengeGoal(for: kind,
                                                                    zone: fish.zone,
                                                                    special: fish.isSpecialChallenge)
    }
}

// MARK: - Escolha de desafio

final class ChallengeChoiceOverlay: SKNode {
    private let onSelect: (ChallengeKind) -> Void
    private let onClose: () -> Void
    private var choiceKinds: [String: ChallengeKind] = [:]

    init(size: CGSize,
         kinds: [ChallengeKind] = ChallengeKind.availableCases,
         records: [ChallengeKind: ChallengeRecordSnapshot] = [:],
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
        let recordSectionHeight: CGFloat = 96
        let rowSpacing: CGFloat = 10
        let maxPanelHeight = size.height - 52
        let spacingTotal = CGFloat(max(0, kinds.count - 1)) * rowSpacing
        let reservedHeight: CGFloat = 166 + recordSectionHeight
        let rowHeight = min(78, max(58, (maxPanelHeight - reservedHeight - spacingTotal) / CGFloat(max(1, kinds.count))))
        let panelHeight = min(size.height - 52,
                              reservedHeight + CGFloat(kinds.count) * rowHeight + spacingTotal)

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

        let subtitle = makeLabel("Vitória comum: +50% conchas ou 1 recurso.",
                                 fontSize: 12,
                                 color: GameUI.mutedInk,
                                 maxWidth: panelWidth - 48,
                                 lines: 2)
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

            let isLongTitle = kind == .banquet || kind == .memory || kind == .echoMelody || kind == .reefAsteroids
            let name = makeLabel(kind.title,
                                 fontSize: isLongTitle ? 13.2 : 15,
                                 color: GameUI.ink,
                                 bold: true,
                                 maxWidth: rowWidth - 152,
                                 lines: isLongTitle ? 2 : 1)
            name.position = CGPoint(x: -rowWidth / 2 + 74, y: 20)
            rowContent.addChild(name)

            let blurb = makeLabel(kind.blurb,
                                  fontSize: 10.8,
                                  color: GameUI.mutedInk,
                                  maxWidth: rowWidth - 152,
                                  lines: 2)
            blurb.position = CGPoint(x: -rowWidth / 2 + 74, y: -7)
            rowContent.addChild(blurb)

            let record = records[kind] ?? .empty(for: kind)
            let recordLabel = SKLabelNode(text: record.displayText)
            recordLabel.fontName = "AvenirNext-DemiBold"
            recordLabel.fontSize = 10.5
            recordLabel.fontColor = GameUI.gold.withAlphaComponent(record.bestScore > 0 ? 0.95 : 0.68)
            recordLabel.horizontalAlignmentMode = .right
            recordLabel.verticalAlignmentMode = .center
            recordLabel.position = CGPoint(x: rowWidth / 2 - 16, y: 20)
            rowContent.addChild(recordLabel)

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

        let recordsTopY = firstRowY
            - CGFloat(max(0, kinds.count - 1)) * (rowHeight + rowSpacing)
            - rowHeight / 2
            - 22
        let recordsTitle = makeLabel("Recordes",
                                     fontSize: 12.5,
                                     color: GameUI.ink,
                                     bold: true)
        recordsTitle.position = CGPoint(x: -rowWidth / 2 + 8, y: recordsTopY)
        content.addChild(recordsTitle)

        let recordKinds = kinds
        let columnWidth = rowWidth / 2
        for (index, kind) in recordKinds.enumerated() {
            let column = index / 3
            let row = index % 3
            let x = -rowWidth / 2 + 12 + CGFloat(column) * columnWidth
            let y = recordsTopY - 24 - CGFloat(row) * 20
            let record = records[kind] ?? .empty(for: kind)

            let name = makeLabel(kind.shortName,
                                 fontSize: 10.5,
                                 color: GameUI.mutedInk,
                                 bold: false,
                                 maxWidth: columnWidth - 70)
            name.position = CGPoint(x: x, y: y)
            content.addChild(name)

            let value = SKLabelNode(text: record.bestScore > 0 ? "\(record.bestScore)" : "-")
            value.fontName = "AvenirNext-DemiBold"
            value.fontSize = 10.5
            value.fontColor = record.bestScore > 0 ? GameUI.gold : GameUI.mutedInk.withAlphaComponent(0.62)
            value.horizontalAlignmentMode = .right
            value.verticalAlignmentMode = .center
            value.position = CGPoint(x: x + columnWidth - 22, y: y)
            content.addChild(value)
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

// MARK: - Convite de desafio de POI

final class POIChallengeOfferOverlay: SKNode {
    private let onAccept: () -> Void
    private let onDecline: () -> Void

    init(size: CGSize,
         poi: WorldPOI,
         challengeGoal: Int,
         onAccept: @escaping () -> Void,
         onDecline: @escaping () -> Void) {
        self.onAccept = onAccept
        self.onDecline = onDecline
        super.init()
        isUserInteractionEnabled = true

        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2.2, height: size.height * 2.2))
        backdrop.fillColor = UIColor(white: 0, alpha: 0.48)
        backdrop.strokeColor = .clear
        backdrop.name = "poi_challenge_decline"
        addChild(backdrop)

        let panelWidth = min(size.width - 32, size.width >= 700 ? 460 : 372)
        let panelHeight: CGFloat = 282
        let panel = GameUI.card(size: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 18,
                                tint: poi.visual.color.withAlphaComponent(0.72),
                                baseColors: GameUI.tintedColors(poi.visual.color))
        addChild(panel)

        let content = SKNode()
        content.zPosition = 8
        panel.addChild(content)

        let artwork = WorldPOIArtworkFactory.makeArtwork(for: poi, size: .listSmall)
        artwork.position = CGPoint(x: -panelWidth / 2 + 42, y: panelHeight / 2 - 45)
        artwork.setScale(1.45)
        content.addChild(artwork)

        let title = makeLabel(poi.name,
                              fontSize: 19,
                              color: GameUI.ink,
                              bold: true,
                              maxWidth: panelWidth - 116,
                              lines: 2)
        title.position = CGPoint(x: -panelWidth / 2 + 86, y: panelHeight / 2 - 34)
        content.addChild(title)

        let subtitle = makeLabel("\(poi.challenge?.kind.title ?? "Desafio") · meta \(challengeGoal)",
                                 fontSize: 12.5,
                                 color: GameUI.mutedInk,
                                 maxWidth: panelWidth - 116,
                                 lines: 1)
        subtitle.position = CGPoint(x: -panelWidth / 2 + 86, y: panelHeight / 2 - 62)
        content.addChild(subtitle)

        let intro = poi.challenge?.introText.isEmpty == false
            ? poi.challenge?.introText
            : Self.defaultIntro(for: poi)
        let body = makeLabel("\"\(intro ?? "")\"",
                             fontSize: 14,
                             color: GameUI.ink,
                             maxWidth: panelWidth - 52,
                             lines: 4)
        body.position = CGPoint(x: -panelWidth / 2 + 26, y: 26)
        content.addChild(body)

        let reward = makeLabel("Vitória: \(rewardText(for: poi.reward))",
                               fontSize: 12.5,
                               color: GameUI.mutedInk,
                               maxWidth: panelWidth - 52,
                               lines: 2)
        reward.position = CGPoint(x: -panelWidth / 2 + 26, y: -54)
        content.addChild(reward)

        let decline = GameUI.pill(text: "Agora não",
                                  fontSize: 13,
                                  fill: [GameUI.mutedInk.withAlphaComponent(0.20)],
                                  strokeColor: GameUI.mutedInk.withAlphaComponent(0.30),
                                  minWidth: 112,
                                  height: 38)
        decline.name = "poi_challenge_decline"
        decline.position = CGPoint(x: -68, y: -panelHeight / 2 + 42)
        decline.zPosition = 10
        content.addChild(decline)

        let accept = GameUI.pill(text: "Aceitar",
                                 fontSize: 13,
                                 fill: [poi.visual.color.withAlphaComponent(0.95)],
                                 strokeColor: UIColor.white.withAlphaComponent(0.32),
                                 minWidth: 112,
                                 height: 38)
        accept.name = "poi_challenge_accept"
        accept.position = CGPoint(x: 68, y: -panelHeight / 2 + 42)
        accept.zPosition = 10
        content.addChild(accept)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        var node: SKNode? = atPoint(location)
        while let current = node {
            if current.name == "poi_challenge_accept" {
                onAccept()
                return
            }
            if current.name == "poi_challenge_decline" {
                onDecline()
                return
            }
            node = current.parent
        }
    }

    private static func defaultIntro(for poi: WorldPOI) -> String {
        switch poi.visualConcept {
        case .npc:
            return "Eu posso te testar, pequena corrente. Quer tentar agora?"
        case .object:
            return "Há uma lembrança presa aqui. Só a maré certa consegue abrir."
        case .environment:
            return "A água mudou de tom. Respire antes de seguir."
        }
    }

    private func rewardText(for reward: Reward) -> String {
        switch reward.kind {
        case .supportResource:
            return "\(reward.supportResourceKind?.title ?? reward.title) x\(reward.quantity)"
        case .regionMap:
            return reward.title
        case .pearls:
            return "\(GameUI.shellAmountText(reward.pearlAmount)) conchas"
        default:
            return reward.title
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

    static func fitLabel(_ label: SKLabelNode,
                         maxWidth: CGFloat,
                         maxFontSize: CGFloat,
                         minFontSize: CGFloat = 10,
                         lines: Int = 1) {
        label.numberOfLines = lines
        label.preferredMaxLayoutWidth = maxWidth
        label.fontSize = maxFontSize
        for _ in 0..<12 {
            let frame = label.calculateAccumulatedFrame()
            guard frame.width > maxWidth, label.fontSize > minFontSize else { break }
            label.fontSize = max(minFontSize, label.fontSize - 0.5)
        }
    }

    static func fitSingleLineLabel(_ label: SKLabelNode,
                                   maxWidth: CGFloat,
                                   maxFontSize: CGFloat,
                                   minFontSize: CGFloat = 10) {
        fitLabel(label,
                 maxWidth: maxWidth,
                 maxFontSize: maxFontSize,
                 minFontSize: minFontSize,
                 lines: 1)
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
        case .banquet:
            let bowl = SKShapeNode(ellipseOf: CGSize(width: 31, height: 22))
            bowl.fillColor = GameUI.gold.withAlphaComponent(0.78)
            bowl.strokeColor = GameUI.coral.withAlphaComponent(0.76)
            bowl.lineWidth = 1.6
            bowl.position = CGPoint(x: 0, y: -2)
            node.addChild(bowl)

            for point in [CGPoint(x: -8, y: 4), CGPoint(x: 0, y: 8), CGPoint(x: 9, y: 3)] {
                let bite = SKShapeNode(circleOfRadius: 3.2)
                bite.fillColor = GameUI.algae.withAlphaComponent(0.86)
                bite.strokeColor = UIColor.white.withAlphaComponent(0.38)
                bite.lineWidth = 0.8
                bite.position = point
                bite.zPosition = 2
                node.addChild(bite)
            }

            let sparkle = SKLabelNode(text: "✦")
            sparkle.fontName = "AvenirNext-Heavy"
            sparkle.fontSize = 12
            sparkle.fontColor = GameUI.palePaper
            sparkle.verticalAlignmentMode = .center
            sparkle.horizontalAlignmentMode = .center
            sparkle.position = CGPoint(x: 12, y: 12)
            sparkle.zPosition = 3
            node.addChild(sparkle)
        case .memory:
            let cardSize = CGSize(width: 23, height: 30)
            for index in 0..<2 {
                let card = SKShapeNode(rectOf: cardSize, cornerRadius: 5)
                card.fillColor = index == 0
                    ? GameUI.palePaper.withAlphaComponent(0.82)
                    : UIColor.lerp(GameUI.accent, GameUI.gold, 0.24).withAlphaComponent(0.76)
                card.strokeColor = UIColor.white.withAlphaComponent(0.62)
                card.lineWidth = 1.2
                card.position = CGPoint(x: CGFloat(index) * 10 - 5, y: CGFloat(index) * 4 - 2)
                card.zRotation = CGFloat(index == 0 ? -0.18 : 0.16)
                node.addChild(card)
            }

            let mark = SKLabelNode(text: "?")
            mark.fontName = "AvenirNext-Heavy"
            mark.fontSize = 18
            mark.fontColor = GameUI.gold
            mark.verticalAlignmentMode = .center
            mark.horizontalAlignmentMode = .center
            mark.position = CGPoint(x: 5, y: 1)
            mark.zPosition = 4
            node.addChild(mark)

            let threadPath = UIBezierPath()
            threadPath.move(to: CGPoint(x: -16, y: -12))
            threadPath.addCurve(to: CGPoint(x: 17, y: 13),
                                controlPoint1: CGPoint(x: -7, y: 2),
                                controlPoint2: CGPoint(x: 7, y: -1))
            let thread = SKShapeNode(path: threadPath.cgPath)
            thread.fillColor = .clear
            thread.strokeColor = UIColor.lerp(GameUI.accent, .white, 0.28).withAlphaComponent(0.62)
            thread.lineWidth = 1.8
            thread.lineCap = .round
            thread.glowWidth = 3
            thread.zPosition = 5
            node.addChild(thread)
        case .echoMelody:
            let noteStem = UIBezierPath()
            noteStem.move(to: CGPoint(x: 2, y: -10))
            noteStem.addLine(to: CGPoint(x: 2, y: 14))
            noteStem.addCurve(to: CGPoint(x: 13, y: 10),
                              controlPoint1: CGPoint(x: 6, y: 16),
                              controlPoint2: CGPoint(x: 11, y: 15))
            let noteLine = SKShapeNode(path: noteStem.cgPath)
            noteLine.fillColor = .clear
            noteLine.strokeColor = UIColor.lerp(GameUI.gold, .white, 0.16)
            noteLine.lineWidth = 2.3
            noteLine.lineCap = .round
            noteLine.lineJoin = .round
            noteLine.glowWidth = 3
            node.addChild(noteLine)

            let head = SKShapeNode(ellipseOf: CGSize(width: 18, height: 13))
            head.fillColor = UIColor(red: 0.45, green: 0.82, blue: 0.92, alpha: 0.86)
            head.strokeColor = UIColor.white.withAlphaComponent(0.62)
            head.lineWidth = 1.1
            head.zRotation = -0.32
            head.position = CGPoint(x: -4, y: -11)
            node.addChild(head)

            for radius in [CGFloat(10), CGFloat(17)] {
                let echo = SKShapeNode(circleOfRadius: radius)
                echo.fillColor = .clear
                echo.strokeColor = UIColor.lerp(GameUI.accent, .white, 0.34).withAlphaComponent(0.38)
                echo.lineWidth = 1.1
                echo.glowWidth = 2
                echo.position = CGPoint(x: -1, y: 0)
                node.addChild(echo)
            }
        case .reefAsteroids:
            let rockPath = UIBezierPath()
            let points = [
                CGPoint(x: -14, y: -5),
                CGPoint(x: -8, y: 13),
                CGPoint(x: 6, y: 15),
                CGPoint(x: 15, y: 2),
                CGPoint(x: 9, y: -13),
                CGPoint(x: -7, y: -15)
            ]
            for (index, point) in points.enumerated() {
                if index == 0 {
                    rockPath.move(to: point)
                } else {
                    rockPath.addLine(to: point)
                }
            }
            rockPath.close()
            let rock = SKShapeNode(path: rockPath.cgPath)
            rock.fillColor = GameUI.line.withAlphaComponent(0.58)
            rock.strokeColor = UIColor.white.withAlphaComponent(0.58)
            rock.lineWidth = 1.3
            node.addChild(rock)

            let crack = UIBezierPath()
            crack.move(to: CGPoint(x: -5, y: 9))
            crack.addLine(to: CGPoint(x: 0, y: 1))
            crack.addLine(to: CGPoint(x: -3, y: -8))
            let crackNode = SKShapeNode(path: crack.cgPath)
            crackNode.fillColor = .clear
            crackNode.strokeColor = GameUI.palePaper.withAlphaComponent(0.70)
            crackNode.lineWidth = 1.2
            crackNode.lineCap = .round
            node.addChild(crackNode)

            for angle in [CGFloat(-0.25), CGFloat(0.55), CGFloat(1.30)] {
                let branch = UIBezierPath()
                branch.move(to: CGPoint(x: 2, y: -2))
                branch.addLine(to: CGPoint(x: cos(angle) * 17, y: sin(angle) * 17))
                let branchNode = SKShapeNode(path: branch.cgPath)
                branchNode.fillColor = .clear
                branchNode.strokeColor = UIColor.lerp(GameUI.coral, GameUI.gold, 0.34)
                branchNode.lineWidth = 2
                branchNode.lineCap = .round
                branchNode.zPosition = 2
                node.addChild(branchNode)
            }
        }

        return node
    }

    static func animatePointConversion(label: SKLabelNode,
                                       points: Int,
                                       pearls: Int,
                                       reachedTarget: Bool = false,
                                       victoryReward: ChallengeVictoryReward = .none,
                                       newRecord: Bool = false) {
        let duration: TimeInterval = 1.1
        let durationCGFloat = CGFloat(duration)
        label.removeAllActions()
        let rewardText = reachedTarget ? victoryReward.displayText : nil
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        func conversionText(points shownPoints: Int, pearls shownPearls: Int) -> String {
            let prefix = newRecord ? "Recorde! " : ""
            let conversion = "\(prefix)\(shownPoints) pts = \(GameUI.shellAmountText(shownPearls)) conchas"
            guard let rewardText else { return conversion }
            return "\(conversion)\n\(rewardText)"
        }

        let lineCount = rewardText == nil ? 1 : 2
        let maxFontSize: CGFloat
        if rewardText != nil {
            maxFontSize = min(label.fontSize, 14.5)
        } else if newRecord {
            maxFontSize = min(label.fontSize, 15.5)
        } else {
            maxFontSize = label.fontSize
        }
        label.text = conversionText(points: points, pearls: pearls)
        fitLabel(label,
                 maxWidth: 250,
                 maxFontSize: maxFontSize,
                 minFontSize: 11.5,
                 lines: lineCount)
        let settledFontSize = label.fontSize
        label.text = newRecord ? "Novo recorde!" : "Convertendo pontos..."

        let count = SKAction.customAction(withDuration: duration) { node, elapsed in
            guard let label = node as? SKLabelNode else { return }
            let t = max(0, min(1, elapsed / durationCGFloat))
            let eased = t * t * (3 - 2 * t)
            let shownPoints = Int((CGFloat(points) * eased).rounded())
            let shownPearls = Int((CGFloat(pearls) * eased).rounded())
            label.fontSize = settledFontSize
            label.text = conversionText(points: shownPoints, pearls: shownPearls)
        }
        let settle = SKAction.run {
            label.fontSize = settledFontSize
            label.text = conversionText(points: points, pearls: pearls)
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
