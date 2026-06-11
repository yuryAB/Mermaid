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

    var shortName: String {
        switch self {
        case .plot: return "Trama"
        case .ascent: return "Subida"
        }
    }

    var title: String { "Desafio: \(shortName)" }

    var icon: String {
        switch self {
        case .plot: return "≈"
        case .ascent: return "○"
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
    let score: Int
    let reachedTarget: Bool
    let pearls: Int
    let xp: CGFloat
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

    /// Limite de ofertas simultâneas perto da sereia.
    private let maxNearbyGivers = 2
    /// Chance de um peixe recém-criado oferecer desafio.
    private let spawnChallengeChance = 4 // em 1/10

    /// Chamado quando um peixe nasce: decide se ele oferece um desafio.
    func decorateSpawn(_ fish: FishNode) {
        guard ctx.stats.phase != .egg else { return }
        guard nearbyGivers(to: fish.position, maxDistance: 2600).count < maxNearbyGivers else { return }
        guard Int.random(in: 0..<10) < spawnChallengeChance else { return }
        fish.offeredChallenge = ChallengeKind.allCases.randomElement()
    }

    func nearbyGivers(to point: CGPoint, maxDistance: CGFloat) -> [FishNode] {
        ctx.fish.fishes.filter {
            $0.offeredChallenge != nil && $0.position.distance(to: point) <= maxDistance
        }
    }

    func nearestGiver(to point: CGPoint, maxDistance: CGFloat) -> FishNode? {
        nearbyGivers(to: point, maxDistance: maxDistance)
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
    }

    /// Garante que existe um peixe com desafio por perto (botão "Desafio").
    @discardableResult
    func ensureGiver(near point: CGPoint) -> FishNode? {
        if let existing = nearestGiver(to: point, maxDistance: 2200) {
            return existing
        }
        let zone = DepthZone.zone(atY: point.y)
        guard let fish = ctx.fish.spawnFish(zone: zone, near: point) else { return nil }
        fish.offeredChallenge = ChallengeKind.allCases.randomElement()
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
        }
        return node
    }

    /// Altura total ocupada pelo cabeçalho (NPC + título + subtítulo).
    static let headerHeight: CGFloat = 130
}
