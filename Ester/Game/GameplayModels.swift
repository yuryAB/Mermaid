//
//  GameplayModels.swift
//  Ester
//
//  Modelos centrais do mundo: zonas de profundidade, fases, comandos e intenções.
//

import Foundation
import SpriteKit
import UIKit

// MARK: - Limites do mundo

enum World {
    static let minX: CGFloat = -50000
    static let maxX: CGFloat = 50000
    static let surfaceTopY: CGFloat = 600
    static let waterlineY: CGFloat = 0
    static let floorY: CGFloat = -42000
    /// Nascimento em águas seguras, longe da superfície e do abismo.
    static let startPosition = CGPoint(x: 0, y: -7000)
}

// MARK: - Balanceamento

enum GameBalance {
    static let currentVersion = 2

    static let babyStartingPearls = 5
    static let babyStartingHunger: CGFloat = 42
    static let babyStartingEnergy: CGFloat = 75
    static let babyStartingDisposition: CGFloat = 58
    static let babyStartingXP: CGFloat = 4

    static func hungerRate(for phase: MermaidPhase) -> CGFloat {
        switch phase {
        case .egg: return 0
        case .baby: return 0.11
        case .child: return 0.095
        case .teen: return 0.08
        case .young: return 0.07
        case .adult: return 0.06
        }
    }

    static func foodSpawnInterval(for phase: MermaidPhase) -> ClosedRange<CGFloat> {
        phase == .baby ? 16...24 : 8...15
    }

    static func maxFoodCount(for phase: MermaidPhase) -> Int {
        phase == .baby ? 3 : 7
    }

    static func requestFoodHungerThreshold(for phase: MermaidPhase) -> CGFloat {
        phase == .baby ? 45 : 30
    }

    static func autoEatHungerThreshold(for phase: MermaidPhase) -> CGFloat {
        phase == .baby ? 55 : 35
    }

    static func challengeSpawnChanceTenths(for phase: MermaidPhase) -> Int {
        4
    }

    static func maxNearbyChallengeGivers(for phase: MermaidPhase) -> Int {
        2
    }

    static func challengeCommandCooldown(for phase: MermaidPhase) -> TimeInterval {
        10
    }

    static func challengeBaseReward(score: Int,
                                    reachedTarget: Bool,
                                    phase: MermaidPhase,
                                    special: Bool,
                                    isHatching: Bool) -> Int {
        guard !isHatching else { return 0 }
        let completionBonus: Int
        switch phase {
        case .egg:
            completionBonus = 0
        case .baby:
            completionBonus = 6
        case .child:
            completionBonus = 12
        case .teen:
            completionBonus = 20
        case .young:
            completionBonus = 30
        case .adult:
            completionBonus = 45
        }
        let base = max(0, score) + (reachedTarget ? completionBonus : 0)
        return special ? base * 3 : base
    }

    static func scaledPearlReward(baseAmount: Int, multiplier: CGFloat) -> Int {
        guard baseAmount > 0 else { return 0 }
        return max(1, Int((CGFloat(baseAmount) * multiplier).rounded()))
    }

    static func growthShellCost(for phase: MermaidPhase) -> Int {
        switch phase {
        case .egg: return 0
        case .baby: return 300
        case .child: return 600
        case .teen: return 1_000
        case .young: return 1_600
        case .adult: return 0
        }
    }
}

// MARK: - Camadas de profundidade

enum DepthZone: Int, Codable, CaseIterable {
    case surface = 0
    case clear
    case shallow
    case mid
    case blue
    case deep
    case abyss

    static let accessOrder: [DepthZone] = [.clear, .shallow, .mid, .blue, .deep, .abyss, .surface]

    var displayName: String {
        switch self {
        case .surface: return "Superfície"
        case .clear: return "Camada Clara"
        case .shallow: return "Camada Rasa"
        case .mid: return "Camada Média"
        case .blue: return "Camada Azul"
        case .deep: return "Camada Profunda"
        case .abyss: return "Camada Abissal"
        }
    }

    var storageKey: String {
        switch self {
        case .surface: return "surface"
        case .clear: return "clear"
        case .shallow: return "shallow"
        case .mid: return "mid"
        case .blue: return "blue"
        case .deep: return "deep"
        case .abyss: return "abyss"
        }
    }

    var yRange: ClosedRange<CGFloat> {
        switch self {
        case .surface: return World.waterlineY...World.surfaceTopY
        case .clear: return -2000 ... World.waterlineY
        case .shallow: return -6000 ... -2000
        case .mid: return -12000 ... -6000
        case .blue: return -20000 ... -12000
        case .deep: return -30000 ... -20000
        case .abyss: return World.floorY ... -30000
        }
    }

    var midY: CGFloat { (yRange.lowerBound + yRange.upperBound) / 2 }

    static func zone(atY y: CGFloat) -> DepthZone {
        if y > World.waterlineY { return .surface }
        for zone in DepthZone.allCases where zone != .surface {
            if zone.yRange.contains(y) { return zone }
        }
        return y < World.floorY ? .abyss : .mid
    }

    var deeper: DepthZone? {
        switch self {
        case .surface: return .clear
        case .clear: return .shallow
        case .shallow: return .mid
        case .mid: return .blue
        case .blue: return .deep
        case .deep: return .abyss
        case .abyss: return nil
        }
    }

    var shallower: DepthZone? {
        switch self {
        case .surface: return nil
        case .clear: return .surface
        case .shallow: return .clear
        case .mid: return .shallow
        case .blue: return .mid
        case .deep: return .blue
        case .abyss: return .deep
        }
    }

    /// A adaptação desta camada precisa amadurecer antes de liberar a próxima.
    var adaptationGate: (zone: DepthZone, value: CGFloat)? {
        switch self {
        case .clear, .shallow, .mid: return nil
        case .blue: return (.mid, 30)
        case .deep: return (.blue, 40)
        case .abyss: return (.deep, 55)
        case .surface: return (.abyss, 65)
        }
    }

    var minPhase: MermaidPhase {
        switch self {
        case .clear, .shallow, .mid: return .baby
        case .blue: return .child
        case .deep: return .teen
        case .abyss: return .young
        case .surface: return .adult
        }
    }

    /// A superfície só abre depois do abismo; as demais dependem da camada vizinha.
    var prerequisiteZone: DepthZone? {
        switch self {
        case .clear, .shallow, .mid: return nil
        case .surface: return .abyss
        case .blue: return .mid
        case .deep: return .blue
        case .abyss: return .deep
        }
    }
}

// MARK: - Fases de crescimento

enum MermaidPhase: Int, Codable, CaseIterable, Comparable {
    case egg = 0
    case baby
    case child
    case teen
    case young
    case adult

    var displayName: String {
        switch self {
        case .egg: return "Ovo"
        case .baby: return "Bebê"
        case .child: return "Criança"
        case .teen: return "Adolescente"
        case .young: return "Jovem"
        case .adult: return "Adulta"
        }
    }

    var scale: CGFloat {
        switch self {
        case .egg: return 0.12
        case .baby: return 0.12
        case .child: return 0.18
        case .teen: return 0.28
        case .young: return 0.4
        case .adult: return 0.52
        }
    }

    var next: MermaidPhase? { MermaidPhase(rawValue: rawValue + 1) }

    var mapAccessDisplayName: String {
        switch self {
        case .egg: return "Ovo"
        case .baby: return "bebê"
        case .child: return "criança"
        case .teen: return "adolescente"
        case .young: return "jovem"
        case .adult: return "adulta"
        }
    }

    static func < (lhs: MermaidPhase, rhs: MermaidPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Comandos do jogador

enum PlayerCommand: String, CaseIterable {
    case explore
    case seekFood
    case challenge
    case objective
    case goUp
    case goDown
    case travel
    case refuge
    case rest

    var label: String {
        switch self {
        case .explore: return "Explorar"
        case .seekFood: return "Alimentar"
        case .challenge: return "Desafio"
        case .objective: return "Objetivo"
        case .goUp: return "Subir camada"
        case .goDown: return "Descer camada"
        case .travel: return "Viajar"
        case .refuge: return "Refúgio"
        case .rest: return "Descansar"
        }
    }

    /// Emoji usado apenas como fallback se o SF Symbol não existir no iOS instalado.
    var icon: String {
        switch self {
        case .explore: return "🧭"
        case .seekFood: return "🍎"
        case .challenge: return "🏆"
        case .objective: return "🎯"
        case .goUp: return "⬆️"
        case .goDown: return "⬇️"
        case .travel: return "🗺"
        case .refuge: return "🐚"
        case .rest: return "😴"
        }
    }

    var symbolName: String {
        switch self {
        case .explore: return "safari.fill"
        case .seekFood: return "leaf.fill"
        case .challenge: return "trophy.fill"
        case .objective: return "scope"
        case .goUp: return "arrow.up.circle.fill"
        case .goDown: return "arrow.down.circle.fill"
        case .travel: return "map.fill"
        case .refuge: return "house.fill"
        case .rest: return "moon.zzz.fill"
        }
    }

    var tint: UIColor {
        switch self {
        case .explore: return UIColor(red: 0.16, green: 0.50, blue: 0.52, alpha: 1)
        case .seekFood: return UIColor(red: 0.33, green: 0.54, blue: 0.30, alpha: 1)
        case .challenge: return UIColor(red: 0.83, green: 0.62, blue: 0.25, alpha: 1)
        case .objective: return UIColor(red: 0.78, green: 0.34, blue: 0.30, alpha: 1)
        case .goUp: return UIColor(red: 0.30, green: 0.64, blue: 0.72, alpha: 1)
        case .goDown: return UIColor(red: 0.04, green: 0.24, blue: 0.43, alpha: 1)
        case .travel: return UIColor(red: 0.22, green: 0.45, blue: 0.50, alpha: 1)
        case .refuge: return UIColor(red: 0.72, green: 0.46, blue: 0.30, alpha: 1)
        case .rest: return UIColor(red: 0.28, green: 0.40, blue: 0.49, alpha: 1)
        }
    }
}

// MARK: - Intenções da sereia

enum MermaidIntent: String {
    case idle
    case wandering
    case seekingFood
    case eating
    case seekingChallenge
    case inChallenge
    case goingToObjective
    case enteringRefuge
    case goingDeeper
    case goingUp
    case traveling
    case resting
    case returningHome
    case interactingWithFish
    case avoidingDanger
    case observing

    var displayName: String {
        switch self {
        case .idle: return "tranquila"
        case .wandering: return "explorando"
        case .seekingFood: return "procurando comida"
        case .eating: return "comendo"
        case .seekingChallenge: return "procurando um desafio"
        case .inChallenge: return "em um desafio"
        case .goingToObjective: return "investigando o objetivo"
        case .enteringRefuge: return "indo ao portal do Refúgio"
        case .goingDeeper: return "descendo"
        case .goingUp: return "subindo"
        case .traveling: return "viajando"
        case .resting: return "descansando"
        case .returningHome: return "voltando ao refúgio"
        case .interactingWithFish: return "brincando com peixes"
        case .avoidingDanger: return "fugindo"
        case .observing: return "observando"
        }
    }
}

// MARK: - Recompensas e buffs

enum RewardKind: String, Codable {
    case pearls
    case temporaryPet
    case temporaryEffect
    case item
    case story
}

enum TimedBuffKind: String, Codable {
    case fullBelly
    case eagerCompanion
    case swiftCurrent
    case temporaryPet

    var title: String {
        switch self {
        case .fullBelly: return "Sem fome"
        case .eagerCompanion: return "Aceitação serena"
        case .swiftCurrent: return "Nado veloz"
        case .temporaryPet: return "Companhia temporária"
        }
    }
}

struct TimedBuff: Codable {
    let kind: TimedBuffKind
    let title: String
    let expiresAt: Date
}

struct Reward: Codable {
    let kind: RewardKind
    let title: String
    let pearlAmount: Int
    let itemId: String?
    let buffKind: TimedBuffKind?
    let duration: TimeInterval
    let storyText: String?

    static func pearls(_ amount: Int, title: String = "Conchas") -> Reward {
        Reward(kind: .pearls,
               title: title,
               pearlAmount: amount,
               itemId: nil,
               buffKind: nil,
               duration: 0,
               storyText: nil)
    }

    static func item(id: String, title: String) -> Reward {
        Reward(kind: .item,
               title: title,
               pearlAmount: 0,
               itemId: id,
               buffKind: nil,
               duration: 0,
               storyText: nil)
    }

    static func temporaryEffect(_ kind: TimedBuffKind, duration: TimeInterval) -> Reward {
        Reward(kind: .temporaryEffect,
               title: kind.title,
               pearlAmount: 0,
               itemId: nil,
               buffKind: kind,
               duration: duration,
               storyText: nil)
    }

    static func temporaryPet(title: String, duration: TimeInterval) -> Reward {
        Reward(kind: .temporaryPet,
               title: title,
               pearlAmount: 0,
               itemId: nil,
               buffKind: nil,
               duration: duration,
               storyText: nil)
    }

    static func story(_ text: String) -> Reward {
        Reward(kind: .story,
               title: "Memória",
               pearlAmount: 0,
               itemId: nil,
               buffKind: nil,
               duration: 0,
               storyText: text)
    }
}

final class RewardSystem {
    unowned let ctx: GameContext

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    @discardableResult
    func grant(_ reward: Reward, source: String) -> String {
        let stats = ctx.stats!
        switch reward.kind {
        case .pearls:
            let gained = stats.awardPearls(reward.pearlAmount)
            GameAudio.shared.play(.pearlReward)
            return "🐚+\(gained)"
        case .temporaryPet:
            stats.addTimedBuff(.temporaryPet,
                               title: reward.title,
                               duration: reward.duration)
            stats.addMemory("\(source): \(reward.title) acompanhou a exploração")
            GameAudio.shared.play(.pearlReward)
            return "\(reward.title) por tempo limitado"
        case .temporaryEffect:
            if let buffKind = reward.buffKind {
                stats.addTimedBuff(buffKind, title: reward.title, duration: reward.duration)
            }
            GameAudio.shared.play(.pearlReward)
            return reward.title
        case .item:
            let itemId = reward.itemId ?? reward.title
            stats.collectItem(id: itemId)
            GameAudio.shared.play(.pearlReward)
            return reward.title
        case .story:
            let text = reward.storyText ?? reward.title
            stats.addMemory(text)
            return text
        }
    }
}

// MARK: - Paleta da sereia

struct MermaidPalette {
    let skin: UIColor
    let hair: UIColor
    let vibrant1: UIColor
    let vibrant2: UIColor

    init(skin: UIColor, hair: UIColor, vibrant1: UIColor, vibrant2: UIColor) {
        self.skin = skin
        self.hair = hair
        self.vibrant1 = vibrant1
        self.vibrant2 = vibrant2
    }

    init(dict: [String: UIColor]) {
        self.init(skin: dict["skinColor"]!,
                  hair: dict["hairColor"]!,
                  vibrant1: dict["vibrant1"]!,
                  vibrant2: dict["vibrant2"]!)
    }

    static let upper = MermaidPalette(dict: ColorManager.shared.upper)
    static let main = MermaidPalette(dict: ColorManager.shared.main)
    static let abyss = MermaidPalette(dict: ColorManager.shared.abyss)

    static func lerp(_ a: MermaidPalette, _ b: MermaidPalette, _ t: CGFloat) -> MermaidPalette {
        MermaidPalette(skin: .lerp(a.skin, b.skin, t),
                       hair: .lerp(a.hair, b.hair, t),
                       vibrant1: .lerp(a.vibrant1, b.vibrant1, t),
                       vibrant2: .lerp(a.vibrant2, b.vibrant2, t))
    }
}

// MARK: - Contexto compartilhado entre sistemas

final class GameContext {
    var stats: MermaidStats!
    weak var scene: GameScene?
    var mermaidEntity: MermaidEntity!
    var depth: DepthSystem!
    var autonomy: AutonomySystem!
    var food: FoodSystem!
    var fish: FishSystem!
    var challenges: ChallengeSystem!
    var events: EventSystem!
    var growth: GrowthSystem!
    var regions: RegionDiscoverySystem!
    var travel: TravelSystem!
    var rewards: RewardSystem!
    var pois: POISystem!
    var hud: HUDLayer!

    var mermaidPosition: CGPoint { mermaidEntity.mermaid.base.position }

    func say(_ text: String) {
        hud?.showMessage(text)
    }
}

// MARK: - Helpers

extension UIColor {
    static func lerp(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        let t = t.clamped(to: 0...1)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t,
                       alpha: a1 + (a2 - a1) * t)
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - x
        let dy = point.y - y
        return sqrt(dx * dx + dy * dy)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}

extension CGVector {
    var length: CGFloat { sqrt(dx * dx + dy * dy) }
}

// MARK: - Estilo visual compartilhado da interface

enum GameUI {
    static let paper = UIColor(red: 0.96, green: 0.93, blue: 0.84, alpha: 1)
    static let palePaper = UIColor(red: 0.92, green: 0.97, blue: 0.95, alpha: 1)
    static let fadedPaper = UIColor(red: 0.84, green: 0.85, blue: 0.80, alpha: 1)
    static let ink = UIColor(red: 0.04, green: 0.15, blue: 0.28, alpha: 1)
    static let mutedInk = UIColor(red: 0.28, green: 0.40, blue: 0.49, alpha: 1)
    static let line = UIColor(red: 0.20, green: 0.40, blue: 0.52, alpha: 1)
    static let accent = UIColor(red: 0.16, green: 0.50, blue: 0.52, alpha: 1)
    static let gold = UIColor(red: 0.83, green: 0.62, blue: 0.25, alpha: 1)
    static let coral = UIColor(red: 0.78, green: 0.34, blue: 0.30, alpha: 1)
    static let algae = UIColor(red: 0.33, green: 0.54, blue: 0.30, alpha: 1)

    // Compatibilidade para chamadas antigas que ainda passam "baseColors".
    static let cardTop = paper
    static let cardBottom = palePaper
    static let cardStroke = line.withAlphaComponent(0.45)

    private static var gradientCache: [String: SKTexture] = [:]
    private static var paperCache: [String: SKTexture] = [:]
    private static var iconCache: [String: SKTexture] = [:]

    /// Retorna uma lavagem suave, não um gradiente escuro.
    static func tintedColors(_ tint: UIColor) -> [UIColor] {
        [.lerp(paper, tint, 0.10), .lerp(palePaper, tint, 0.08)]
    }

    /// Textura de gradiente vertical (primeira cor no topo, última embaixo).
    static func gradientTexture(size: CGSize, colors: [UIColor]) -> SKTexture {
        let w = max(1, Int(size.width.rounded()))
        let h = max(1, Int(size.height.rounded()))
        let key = "\(w)x\(h)|" + colors.map { c -> String in
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            c.getRed(&r, green: &g, blue: &b, alpha: &a)
            return String(format: "%.2f,%.2f,%.2f,%.2f", r, g, b, a)
        }.joined(separator: ";")
        if let cached = gradientCache[key] { return cached }

        let pixelSize = CGSize(width: w, height: h)
        let renderer = UIGraphicsImageRenderer(size: pixelSize)
        let image = renderer.image { context in
            let cg = context.cgContext
            let space = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map { $0.cgColor } as CFArray
            let locations: [CGFloat] = (0..<colors.count).map {
                colors.count <= 1 ? 0 : CGFloat($0) / CGFloat(colors.count - 1)
            }
            guard let gradient = CGGradient(colorsSpace: space,
                                            colors: cgColors,
                                            locations: locations) else { return }
            cg.drawLinearGradient(gradient,
                                  start: CGPoint(x: 0, y: 0),
                                  end: CGPoint(x: 0, y: pixelSize.height),
                                  options: [])
        }
        let texture = SKTexture(image: image)
        gradientCache[key] = texture
        return texture
    }

    static func paperTexture(size: CGSize, base: UIColor = paper) -> SKTexture {
        let w = max(1, Int(size.width.rounded()))
        let h = max(1, Int(size.height.rounded()))
        let key = "\(w)x\(h)|\(base.hashValue)"
        if let cached = paperCache[key] { return cached }

        let image = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { context in
            let cg = context.cgContext
            base.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

            cg.setStrokeColor(accent.withAlphaComponent(0.07).cgColor)
            cg.setLineWidth(1)
            for y in stride(from: CGFloat(14), to: CGFloat(h), by: CGFloat(18)) {
                cg.move(to: CGPoint(x: 0, y: y))
                cg.addLine(to: CGPoint(x: CGFloat(w), y: y + 0.7))
                cg.strokePath()
            }

            for i in 0..<70 {
                let x = CGFloat((i * 47 + 11) % w)
                let y = CGFloat((i * 71 + 17) % h)
                let radius = CGFloat((i % 3) + 1) * 0.5
                let color = i.isMultiple(of: 2)
                    ? ink.withAlphaComponent(0.028)
                    : UIColor.white.withAlphaComponent(0.08)
                color.setFill()
                cg.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
            }
        }

        let texture = SKTexture(image: image)
        paperCache[key] = texture
        return texture
    }

    static func assetIconNode(named name: String,
                              color: UIColor,
                              size: CGFloat) -> SKSpriteNode {
        let sprite: SKSpriteNode
        if let texture = tintedIconTexture(named: name, color: color, pointSize: size) {
            sprite = SKSpriteNode(texture: texture)
        } else {
            sprite = SKSpriteNode(imageNamed: name)
        }
        sprite.size = CGSize(width: size, height: size)
        return sprite
    }

    static func symbolIconNode(named symbolName: String,
                               fallback: String,
                               color: UIColor,
                               size: CGFloat) -> SKNode {
        let node = SKNode()
        let configuration = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        if let image = UIImage(systemName: symbolName, withConfiguration: configuration),
           let texture = tintedIconTexture(image: image, key: "symbol:\(symbolName)", color: color, pointSize: size) {
            let sprite = SKSpriteNode(texture: texture)
            sprite.size = CGSize(width: size, height: size)
            node.addChild(sprite)
        } else {
            let label = SKLabelNode(text: fallback)
            label.fontName = "AvenirNext-Heavy"
            label.fontSize = size * 0.72
            label.fontColor = color
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            node.addChild(label)
        }
        return node
    }

    private static func tintedIconTexture(named name: String,
                                          color: UIColor,
                                          pointSize: CGFloat) -> SKTexture? {
        guard let source = UIImage(named: name) else { return nil }
        return tintedIconTexture(image: source, key: "asset:\(name)", color: color, pointSize: pointSize)
    }

    private static func tintedIconTexture(image source: UIImage,
                                          key sourceKey: String,
                                          color: UIColor,
                                          pointSize: CGFloat) -> SKTexture? {
        let w = max(1, Int(pointSize.rounded()))
        let h = max(1, Int(pointSize.rounded()))
        let key = "\(sourceKey)|\(w)x\(h)|\(color.cacheKey)"
        if let cached = iconCache[key] { return cached }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        let canvasSize = CGSize(width: pointSize, height: pointSize)
        let tintedImage = UIGraphicsImageRenderer(size: canvasSize, format: format).image { context in
            let rect = source.size.aspectFitRect(in: CGRect(origin: .zero, size: canvasSize))
            color.setFill()
            context.cgContext.fill(rect)
            source.draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
        let texture = SKTexture(image: tintedImage)
        iconCache[key] = texture
        return texture
    }

    static func card(size: CGSize,
                     cornerRadius: CGFloat,
                     tint: UIColor? = nil,
                     baseColors: [UIColor]? = nil) -> SKNode {
        let container = SKNode()
        let accentColor = tint ?? line
        let baseColor = baseColors?.first.map { UIColor.lerp(paper, $0, 0.10) } ?? paper

        let shadow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height),
                                 cornerRadius: cornerRadius)
        shadow.fillColor = UIColor(white: 0, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -4)
        shadow.zPosition = -2
        container.addChild(shadow)

        let base = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        base.fillTexture = paperTexture(size: size, base: baseColor)
        base.fillColor = .white
        base.strokeColor = accentColor.withAlphaComponent(tint == nil ? 0.45 : 0.58)
        base.lineWidth = tint == nil ? 1.1 : 1.3
        container.addChild(base)

        if tint != nil {
            let tab = SKShapeNode(rectOf: CGSize(width: max(12, size.width - 18), height: 4),
                                  cornerRadius: 2)
            tab.fillColor = accentColor.withAlphaComponent(0.62)
            tab.strokeColor = .clear
            tab.position = CGPoint(x: 0, y: size.height / 2 - 9)
            tab.zPosition = 2
            container.addChild(tab)
        }

        let inner = SKShapeNode(rectOf: CGSize(width: size.width - 8, height: size.height - 8),
                                cornerRadius: max(2, cornerRadius - 2))
        inner.fillColor = .clear
        inner.strokeColor = UIColor.white.withAlphaComponent(0.25)
        inner.lineWidth = 0.8
        inner.zPosition = 1
        container.addChild(inner)

        return container
    }

    static func pill(text: String,
                     fontSize: CGFloat,
                     bold: Bool = true,
                     fill: [UIColor]? = nil,
                     strokeColor: UIColor? = nil,
                     textColor: UIColor = ink,
                     hPadding: CGFloat = 18,
                     minWidth: CGFloat = 0,
                     height: CGFloat = 34) -> SKNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = textColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let textWidth = label.frame.width
        let width = max(minWidth, textWidth + hPadding * 2)

        let container = SKNode()
        let bgSize = CGSize(width: width, height: height)

        let shadow = SKShapeNode(rectOf: bgSize, cornerRadius: height / 2)
        shadow.fillColor = UIColor(white: 0, alpha: 0.14)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -3)
        shadow.zPosition = -1
        container.addChild(shadow)

        let accentColor = fill?.first ?? accent
        let bg = SKShapeNode(rectOf: bgSize, cornerRadius: height / 2)
        bg.fillTexture = paperTexture(size: bgSize, base: UIColor.lerp(paper, accentColor, 0.10))
        bg.fillColor = .white
        bg.strokeColor = strokeColor ?? accentColor.withAlphaComponent(0.62)
        bg.lineWidth = 1.2
        container.addChild(bg)

        let mark = SKShapeNode(rectOf: CGSize(width: 4, height: height - 10), cornerRadius: 2)
        mark.fillColor = accentColor.withAlphaComponent(0.70)
        mark.strokeColor = .clear
        mark.position = CGPoint(x: -width / 2 + 10, y: 0)
        mark.zPosition = 2
        container.addChild(mark)

        label.zPosition = 2
        container.addChild(label)
        return container
    }
}

private extension UIColor {
    var cacheKey: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "%.3f,%.3f,%.3f,%.3f", red, green, blue, alpha)
    }
}

private extension CGSize {
    func aspectFitRect(in bounds: CGRect) -> CGRect {
        guard width > 0, height > 0 else { return bounds }
        let scale = min(bounds.width / width, bounds.height / height)
        let fittedSize = CGSize(width: width * scale, height: height * scale)
        return CGRect(x: bounds.midX - fittedSize.width / 2,
                      y: bounds.midY - fittedSize.height / 2,
                      width: fittedSize.width,
                      height: fittedSize.height)
    }
}
