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
    static let minX: CGFloat = -50000
    static let maxX: CGFloat = 50000
    static let surfaceTopY: CGFloat = 600
    static let waterlineY: CGFloat = 0
    static let floorY: CGFloat = -42000
    /// Nascimento em águas seguras, longe da superfície e do abismo.
    static let startPosition = CGPoint(x: 0, y: -7000)
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

    var courageRequired: CGFloat {
        switch self {
        case .shallow, .mid: return 0
        case .clear: return 12
        case .blue: return 30
        case .deep: return 50
        case .abyss: return 70
        case .surface: return 85
        }
    }

    /// A adaptação desta camada precisa amadurecer antes de liberar a próxima.
    var adaptationGate: (zone: DepthZone, value: CGFloat)? {
        switch self {
        case .shallow, .mid: return nil
        case .clear: return (.shallow, 15)
        case .blue: return (.mid, 30)
        case .deep: return (.blue, 40)
        case .abyss: return (.deep, 55)
        case .surface: return (.clear, 50)
        }
    }

    var minPhase: MermaidPhase {
        switch self {
        case .shallow, .mid: return .baby
        case .clear, .blue: return .child
        case .deep: return .teen
        case .abyss, .surface: return .young
        }
    }

    /// A superfície só abre depois do abismo; as demais dependem da camada vizinha.
    var prerequisiteZone: DepthZone? {
        switch self {
        case .shallow, .mid: return nil
        case .surface: return .abyss
        case .clear: return .shallow
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

    static func < (lhs: MermaidPhase, rhs: MermaidPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Comandos do jogador

enum PlayerCommand: String, CaseIterable {
    case explore
    case seekFood
    case tideWeave
    case goUp
    case goDown
    case travel
    case refuge
    case rest

    var label: String {
        switch self {
        case .explore: return "Explorar"
        case .seekFood: return "Comida"
        case .tideWeave: return "Trama"
        case .goUp: return "Subir"
        case .goDown: return "Descer"
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
        case .tideWeave: return "🌀"
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
        case .tideWeave: return "circle.grid.3x3.fill"
        case .goUp: return "arrow.up.circle.fill"
        case .goDown: return "arrow.down.circle.fill"
        case .travel: return "map.fill"
        case .refuge: return "house.fill"
        case .rest: return "moon.zzz.fill"
        }
    }

    var tint: UIColor {
        switch self {
        case .explore: return UIColor(red: 0.4, green: 0.8, blue: 0.95, alpha: 1)
        case .seekFood: return UIColor(red: 0.5, green: 0.85, blue: 0.5, alpha: 1)
        case .tideWeave: return UIColor(red: 0.98, green: 0.8, blue: 0.4, alpha: 1)
        case .goUp: return UIColor(red: 0.6, green: 0.88, blue: 0.95, alpha: 1)
        case .goDown: return UIColor(red: 0.42, green: 0.6, blue: 0.95, alpha: 1)
        case .travel: return UIColor(red: 0.45, green: 0.9, blue: 0.75, alpha: 1)
        case .refuge: return UIColor(red: 0.95, green: 0.7, blue: 0.45, alpha: 1)
        case .rest: return UIColor(red: 0.72, green: 0.68, blue: 0.95, alpha: 1)
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
        case .seekingPuzzle: return "procurando a Trama"
        case .solvingPuzzle: return "tecendo a Trama das Marés"
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
    var tideWeaving: TideWeavingSystem!
    var events: EventSystem!
    var growth: GrowthSystem!
    var regions: RegionDiscoverySystem!
    var travel: TravelSystem!
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
