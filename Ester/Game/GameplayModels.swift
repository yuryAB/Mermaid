//
//  GameplayModels.swift
//  Ester
//
//  Modelos centrais do mundo: zonas de profundidade, fases, comandos e intenções.
//

import Foundation
import SpriteKit

// MARK: - Limites do mundo

enum World {
    static let minX: CGFloat = -900
    static let maxX: CGFloat = 900
    static let surfaceTopY: CGFloat = 600
    static let waterlineY: CGFloat = 0
    static let floorY: CGFloat = -12000
}

// MARK: - Zonas de profundidade

enum DepthZone: Int, Codable, CaseIterable {
    case surface = 0
    case shallow
    case reef
    case mid
    case deep
    case abyss

    var displayName: String {
        switch self {
        case .surface: return "Superfície"
        case .shallow: return "Águas Rasas"
        case .reef: return "Recife"
        case .mid: return "Zona Média"
        case .deep: return "Fundo Escuro"
        case .abyss: return "Abismo"
        }
    }

    var storageKey: String {
        switch self {
        case .surface: return "surface"
        case .shallow: return "shallow"
        case .reef: return "reef"
        case .mid: return "mid"
        case .deep: return "deep"
        case .abyss: return "abyss"
        }
    }

    var yRange: ClosedRange<CGFloat> {
        switch self {
        case .surface: return World.waterlineY...World.surfaceTopY
        case .shallow: return -2400 ... World.waterlineY
        case .reef: return -4800 ... -2400
        case .mid: return -7200 ... -4800
        case .deep: return -9600 ... -7200
        case .abyss: return World.floorY ... -9600
        }
    }

    var midY: CGFloat { (yRange.lowerBound + yRange.upperBound) / 2 }

    static func zone(atY y: CGFloat) -> DepthZone {
        if y > World.waterlineY { return .surface }
        for zone in DepthZone.allCases where zone != .surface {
            if zone.yRange.contains(y) { return zone }
        }
        return y < World.floorY ? .abyss : .shallow
    }

    var deeper: DepthZone? {
        switch self {
        case .surface: return .shallow
        case .shallow: return .reef
        case .reef: return .mid
        case .mid: return .deep
        case .deep: return .abyss
        case .abyss: return nil
        }
    }

    var shallower: DepthZone? {
        switch self {
        case .surface: return nil
        case .shallow: return .surface
        case .reef: return .shallow
        case .mid: return .reef
        case .deep: return .mid
        case .abyss: return .deep
        }
    }

    var courageRequired: CGFloat {
        switch self {
        case .shallow: return 0
        case .reef: return 15
        case .mid: return 30
        case .deep: return 50
        case .abyss: return 70
        case .surface: return 80
        }
    }

    /// A adaptação desta zona precisa amadurecer antes de liberar a próxima.
    var adaptationGate: (zone: DepthZone, value: CGFloat)? {
        switch self {
        case .shallow: return nil
        case .reef: return (.shallow, 20)
        case .mid: return (.reef, 30)
        case .deep: return (.mid, 40)
        case .abyss: return (.deep, 55)
        case .surface: return (.shallow, 60)
        }
    }

    var minPhase: MermaidPhase {
        switch self {
        case .shallow: return .baby
        case .reef: return .child
        case .mid: return .child
        case .deep: return .teen
        case .abyss: return .young
        case .surface: return .young
        }
    }

    /// A superfície só abre depois do abismo; as demais dependem da zona acima.
    var prerequisiteZone: DepthZone? {
        switch self {
        case .shallow: return nil
        case .surface: return .abyss
        default: return shallower
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
        case .egg: return 0.18
        case .baby: return 0.2
        case .child: return 0.3
        case .teen: return 0.42
        case .young: return 0.55
        case .adult: return 0.7
        }
    }

    var next: MermaidPhase? { MermaidPhase(rawValue: rawValue + 1) }

    static func < (lhs: MermaidPhase, rhs: MermaidPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Comandos do jogador

enum PlayerCommand: String, CaseIterable {
    case explore
    case seekFood
    case rest
    case interact
    case goUp
    case goDown
    case challenge
    case goHome

    var label: String {
        switch self {
        case .explore: return "Explorar"
        case .seekFood: return "Comida"
        case .rest: return "Descansar"
        case .interact: return "Interagir"
        case .goUp: return "Subir"
        case .goDown: return "Descer"
        case .challenge: return "Desafio"
        case .goHome: return "Abrigo"
        }
    }

    /// Emoji usado apenas como fallback se o SF Symbol não existir no iOS instalado.
    var icon: String {
        switch self {
        case .explore: return "🧭"
        case .seekFood: return "🍎"
        case .rest: return "😴"
        case .interact: return "🐠"
        case .goUp: return "⬆️"
        case .goDown: return "⬇️"
        case .challenge: return "💎"
        case .goHome: return "🏠"
        }
    }

    var symbolName: String {
        switch self {
        case .explore: return "safari.fill"
        case .seekFood: return "leaf.fill"
        case .rest: return "moon.zzz.fill"
        case .interact: return "heart.fill"
        case .goUp: return "arrow.up.circle.fill"
        case .goDown: return "arrow.down.circle.fill"
        case .challenge: return "puzzlepiece.fill"
        case .goHome: return "house.fill"
        }
    }

    var tint: UIColor {
        switch self {
        case .explore: return UIColor(red: 0.4, green: 0.8, blue: 0.95, alpha: 1)
        case .seekFood: return UIColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 1)
        case .rest: return UIColor(red: 0.72, green: 0.68, blue: 0.95, alpha: 1)
        case .interact: return UIColor(red: 0.95, green: 0.55, blue: 0.68, alpha: 1)
        case .goUp: return UIColor(red: 0.6, green: 0.88, blue: 0.95, alpha: 1)
        case .goDown: return UIColor(red: 0.42, green: 0.6, blue: 0.95, alpha: 1)
        case .challenge: return UIColor(red: 0.98, green: 0.8, blue: 0.4, alpha: 1)
        case .goHome: return UIColor(red: 0.95, green: 0.7, blue: 0.45, alpha: 1)
        }
    }
}

// MARK: - Intenções da sereia

enum MermaidIntent: String {
    case idle
    case wandering
    case seekingFood
    case eating
    case seekingPuzzle
    case solvingPuzzle
    case goingDeeper
    case goingUp
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
        case .seekingPuzzle: return "procurando um desafio"
        case .solvingPuzzle: return "resolvendo um desafio"
        case .goingDeeper: return "descendo"
        case .goingUp: return "subindo"
        case .resting: return "descansando"
        case .returningHome: return "voltando ao abrigo"
        case .interactingWithFish: return "brincando com peixes"
        case .avoidingDanger: return "fugindo"
        case .observing: return "observando"
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
    var shelter: ShelterSystem!
    var match3: Match3System!
    var events: EventSystem!
    var growth: GrowthSystem!
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
