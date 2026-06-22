//
//  DepthSystem.swift
//  Ester
//
//  Profundidade como coordenada real: cor da água, paleta do corpo,
//  adaptação por camada, custo de energia e desbloqueio progressivo.
//  As transições visuais são lentas — só ficam fortes entre camadas
//  realmente distantes.
//

import Foundation
import SpriteKit

struct DepthEnvironment {
    let waterColor: UIColor
    let fogColor: UIColor
    let fogAlpha: CGFloat
    let causticAlpha: CGFloat
    let lightRayAlpha: CGFloat
    let planktonDensity: CGFloat
    let marineSnowDensity: CGFloat
    let maxVisibleDistance: CGFloat
    let lifeDensity: CGFloat
    let glowIntensity: CGFloat
}

enum DepthBoundaryEdge: Equatable {
    case upper
    case lower
}

final class DepthSystem {
    unowned let ctx: GameContext

    private static let lockedSurfaceApproachTopY: CGFloat = DepthZone.shallow.yRange.upperBound - 800
    private static let clearLayerApproachTopY: CGFloat = -150
    private static let surfaceApproachTopY: CGFloat = 280
    private static let surfaceTrafficMinY: CGFloat = -2500
    private static let boundaryAlertDuration: CGFloat = 3
    private static let boundaryBlinkDuration: CGFloat = 1.35
    private static let paletteTransitionDuration: CGFloat = 0.75

    private(set) var currentZone: DepthZone = .mid
    private var paletteTimer: CGFloat = 0
    private var currentPaletteZone: MermaidPaletteZone?
    private var normalPaletteTransition: MermaidPaletteTransition?
    private var currentNormalPalette: MermaidPalette?
    private var normalPaletteNeedsUpdate = false
    private var boundaryPaletteEffect: BoundaryPaletteEffect?
    private var unlockTimer: CGFloat = 2

    private let waterAnchors: [(y: CGFloat, color: UIColor)]

    private enum MermaidPaletteZone: Equatable {
        case upper
        case main
        case abyss

        var palette: MermaidPalette {
            switch self {
            case .upper:
                return .upper
            case .main:
                return .main
            case .abyss:
                return .abyss
            }
        }
    }

    private struct MermaidPaletteTransition {
        let fromPalette: MermaidPalette
        let toPalette: MermaidPalette
        var elapsed: CGFloat = 0

        var isFinished: Bool {
            elapsed >= DepthSystem.paletteTransitionDuration
        }

        func palette() -> MermaidPalette {
            let t = DepthSystem.smoothStep(elapsed / DepthSystem.paletteTransitionDuration)
            return .lerp(fromPalette, toPalette, t)
        }
    }

    private struct BoundaryPaletteEffect {
        let basePalette: MermaidPalette
        let limitPalette: MermaidPalette
        var elapsed: CGFloat = 0

        var isFinished: Bool {
            elapsed >= DepthSystem.boundaryAlertDuration
        }

        func palette() -> MermaidPalette {
            if elapsed < DepthSystem.boundaryBlinkDuration {
                return blinkPalette()
            }
            return limitPalette
        }

        private func blinkPalette() -> MermaidPalette {
            let keyframes = [basePalette, limitPalette, basePalette, limitPalette, basePalette, limitPalette]
            let progress = (elapsed / DepthSystem.boundaryBlinkDuration).clamped(to: 0...1)
            let scaled = progress * CGFloat(keyframes.count - 1)
            let index = min(Int(scaled), keyframes.count - 2)
            let localT = DepthSystem.smoothStep(scaled - CGFloat(index))
            return .lerp(keyframes[index], keyframes[index + 1], localT)
        }
    }

    init(ctx: GameContext) {
        self.ctx = ctx
        let waters = ColorManager.shared.waters
        let abyssFloor = UIColor.lerp(waters["abyssal"]!, .black, 0.45)
        // Âncoras nos miolos das camadas: a cor muda devagar ao longo
        // de milhares de pontos, nunca de repente.
        waterAnchors = [
            (World.surfaceTopY, waters["surface"]!),
            (World.waterlineY, UIColor.lerp(waters["surface"]!, waters["shallow"]!, 0.55)),
            (-4000, waters["shallow"]!),
            (-9000, UIColor.lerp(waters["shallow"]!, waters["mid"]!, 0.55)),
            (-16000, waters["mid"]!),
            (-25000, waters["deep"]!),
            (-36000, waters["abyssal"]!),
            (World.floorY, abyssFloor)
        ]
    }

    // MARK: - Cores

    func waterColor(atY y: CGFloat) -> UIColor {
        let y = y.clamped(to: World.floorY...World.surfaceTopY)
        for i in 0..<(waterAnchors.count - 1) {
            let top = waterAnchors[i]
            let bottom = waterAnchors[i + 1]
            if y <= top.y && y >= bottom.y {
                let span = top.y - bottom.y
                let t = span > 0 ? (top.y - y) / span : 0
                return .lerp(top.color, bottom.color, t)
            }
        }
        return waterAnchors.last!.color
    }

    func environment(atY y: CGFloat) -> DepthEnvironment {
        let zone = DepthZone.zone(atY: y)
        let water = waterColor(atY: y)

        switch zone {
        case .surface:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .white, 0.28),
                                    fogAlpha: 0.06,
                                    causticAlpha: 0.95,
                                    lightRayAlpha: 0.85,
                                    planktonDensity: 0.35,
                                    marineSnowDensity: 0.05,
                                    maxVisibleDistance: 1.0,
                                    lifeDensity: 0.45,
                                    glowIntensity: 0.0)
        case .clear:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .white, 0.18),
                                    fogAlpha: 0.10,
                                    causticAlpha: 0.80,
                                    lightRayAlpha: 0.70,
                                    planktonDensity: 0.42,
                                    marineSnowDensity: 0.12,
                                    maxVisibleDistance: 0.92,
                                    lifeDensity: 0.58,
                                    glowIntensity: 0.04)
        case .shallow:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .white, 0.08),
                                    fogAlpha: 0.16,
                                    causticAlpha: 0.45,
                                    lightRayAlpha: 0.36,
                                    planktonDensity: 0.58,
                                    marineSnowDensity: 0.20,
                                    maxVisibleDistance: 0.78,
                                    lifeDensity: 0.72,
                                    glowIntensity: 0.08)
        case .mid:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .black, 0.08),
                                    fogAlpha: 0.24,
                                    causticAlpha: 0.22,
                                    lightRayAlpha: 0.18,
                                    planktonDensity: 0.68,
                                    marineSnowDensity: 0.36,
                                    maxVisibleDistance: 0.62,
                                    lifeDensity: 0.58,
                                    glowIntensity: 0.16)
        case .blue:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .black, 0.15),
                                    fogAlpha: 0.32,
                                    causticAlpha: 0.12,
                                    lightRayAlpha: 0.08,
                                    planktonDensity: 0.72,
                                    marineSnowDensity: 0.48,
                                    maxVisibleDistance: 0.48,
                                    lifeDensity: 0.38,
                                    glowIntensity: 0.24)
        case .deep:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .black, 0.24),
                                    fogAlpha: 0.42,
                                    causticAlpha: 0.05,
                                    lightRayAlpha: 0.03,
                                    planktonDensity: 0.58,
                                    marineSnowDensity: 0.62,
                                    maxVisibleDistance: 0.34,
                                    lifeDensity: 0.30,
                                    glowIntensity: 0.48)
        case .abyss:
            return DepthEnvironment(waterColor: water,
                                    fogColor: UIColor.lerp(water, .black, 0.36),
                                    fogAlpha: 0.52,
                                    causticAlpha: 0.02,
                                    lightRayAlpha: 0.0,
                                    planktonDensity: 0.30,
                                    marineSnowDensity: 0.44,
                                    maxVisibleDistance: 0.22,
                                    lifeDensity: 0.18,
                                    glowIntensity: 0.58)
        }
    }

    /// Paleta-alvo do corpo: algumas áreas mudam oficialmente a cor da sereia.
    /// A troca visual é temporal, não proporcional à altura.
    func mermaidPalette(atY y: CGFloat) -> MermaidPalette {
        paletteZone(for: DepthZone.zone(atY: y)).palette
    }

    private func updateNormalMermaidPalette(atY y: CGFloat, dt: CGFloat) -> MermaidPalette {
        normalPaletteNeedsUpdate = false
        let targetZone = paletteZone(for: DepthZone.zone(atY: y))

        if currentPaletteZone == nil {
            currentPaletteZone = targetZone
            currentNormalPalette = targetZone.palette
            normalPaletteNeedsUpdate = true
            return targetZone.palette
        }

        if targetZone != currentPaletteZone {
            let fromPalette = normalPaletteTransition?.palette()
                ?? currentNormalPalette
                ?? currentPaletteZone?.palette
                ?? targetZone.palette
            currentPaletteZone = targetZone
            normalPaletteTransition = MermaidPaletteTransition(fromPalette: fromPalette,
                                                               toPalette: targetZone.palette)
            normalPaletteNeedsUpdate = true
        }

        if var transition = normalPaletteTransition {
            transition.elapsed += dt
            normalPaletteNeedsUpdate = true
            if transition.isFinished {
                normalPaletteTransition = nil
                currentNormalPalette = targetZone.palette
                return targetZone.palette
            }
            normalPaletteTransition = transition
            let palette = transition.palette()
            currentNormalPalette = palette
            return palette
        }

        currentNormalPalette = targetZone.palette
        return targetZone.palette
    }

    private func paletteZone(for zone: DepthZone) -> MermaidPaletteZone {
        switch zone {
        case .surface, .clear:
            return .upper
        case .shallow, .mid, .blue, .deep:
            return .main
        case .abyss:
            return .abyss
        }
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        let y = ctx.mermaidPosition.y
        let zone = DepthZone.zone(atY: y)
        if zone != currentZone {
            currentZone = zone
        }

        // Adaptação cresce na camada onde ela está
        let rate: CGFloat = (zone == .shallow || zone == .mid || zone == .surface) ? 0.5 : 0.35
        let current = ctx.stats.adaptation(for: zone)
        ctx.stats.setAdaptation(current + dt * rate * (1 - current / 100), for: zone)

        // Recorde de profundidade vira recompensa
        let meters = max(0, -y / 10)
        if meters > ctx.stats.maxDepthMeters + 200 {
            ctx.stats.maxDepthMeters = meters
            let gained = ctx.stats.awardPearls(1)
            GameAudio.shared.play(.depthRecord)
            ctx.say("Ela nadou mais fundo do que nunca! 🐚+\(GameUI.shellAmountText(gained))")
        }

        let normalPalette = updateNormalMermaidPalette(atY: y, dt: dt)
        var forcePaletteUpdate = normalPaletteNeedsUpdate
        if var effect = boundaryPaletteEffect {
            effect.elapsed += dt
            if effect.isFinished {
                boundaryPaletteEffect = nil
            } else {
                boundaryPaletteEffect = effect
            }
            forcePaletteUpdate = true
        }

        paletteTimer -= dt
        if forcePaletteUpdate || paletteTimer <= 0 {
            paletteTimer = boundaryPaletteEffect == nil ? 0.25 : 0
            let displayPalette = boundaryPaletteEffect?.palette() ?? normalPalette
            ctx.mermaidEntity.mermaid.applyPalette(displayPalette)
        }

        unlockTimer -= dt
        if unlockTimer <= 0 {
            unlockTimer = 3
            checkUnlocks()
        }
    }

    // MARK: - Desbloqueio de camadas

    func isUnlocked(_ zone: DepthZone) -> Bool {
        Self.canAccess(zone, with: ctx.stats)
    }

    private func checkUnlocks() {
        for zone in DepthZone.allCases where !ctx.stats.isUnlocked(zone) {
            guard meetsRequirements(zone) else { continue }
            ctx.stats.unlock(zone)
            let gained = ctx.stats.awardPearls(8)
            ctx.stats.addMemory("Alcançou a \(zone.displayName)")
            GameAudio.shared.play(.zoneUnlock)
            ctx.say("🌊 Nova camada alcançável: \(zone.displayName)! 🐚+\(GameUI.shellAmountText(gained))")
        }
    }

    private func meetsRequirements(_ zone: DepthZone) -> Bool {
        let stats = ctx.stats!
        if let prerequisite = zone.prerequisiteZone, !stats.isUnlocked(prerequisite) { return false }
        if stats.phase < zone.minPhase { return false }
        if let gate = zone.adaptationGate, stats.adaptation(for: gate.zone) < gate.value { return false }
        return true
    }

    /// Mensagem para quando ela tenta subir além do permitido.
    func ascentHint(for zone: DepthZone? = nil) -> String {
        let stats = ctx.stats!
        let target = zone ?? firstLockedAscentZone()

        if let target {
            if stats.phase < target.minPhase {
                return "Ela ainda é muito nova para subir até a \(target.displayName)."
            }
            if let prerequisite = target.prerequisiteZone, !stats.isUnlocked(prerequisite) {
                return "Ela precisa conhecer a \(prerequisite.displayName) antes de subir até a \(target.displayName)."
            }
            if let gate = target.adaptationGate, stats.adaptation(for: gate.zone) < gate.value {
                return "Ela precisa se adaptar melhor à \(gate.zone.displayName) antes de subir mais."
            }
        }

        return "Ela ainda não está pronta para chegar tão perto da superfície. 🌅"
    }

    /// Mensagem para quando o jogador manda descer além do permitido.
    func descentHint(for zone: DepthZone) -> String {
        let stats = ctx.stats!
        if stats.phase < zone.minPhase {
            return "Ela ainda é muito nova para ir tão fundo..."
        }
        if let gate = zone.adaptationGate, stats.adaptation(for: gate.zone) < gate.value {
            return "Ela precisa se adaptar melhor à \(gate.zone.displayName) antes de descer mais."
        }
        return "Ela ainda não consegue descer até a \(zone.displayName)."
    }

    func boundaryHint(for edge: DepthBoundaryEdge) -> String {
        switch edge {
        case .upper:
            return ascentHint()
        case .lower:
            if let zone = firstLockedDescentZone() {
                return descentHint(for: zone)
            }
            return "Ela chegou ao limite mais fundo que o oceano deixou hoje."
        }
    }

    func flashBoundaryPalette(for edge: DepthBoundaryEdge) {
        let basePalette = currentNormalPalette
            ?? paletteZone(for: DepthZone.zone(atY: ctx.mermaidPosition.y)).palette
        boundaryPaletteEffect = BoundaryPaletteEffect(basePalette: basePalette,
                                                      limitPalette: paletteForBoundary(edge))
        paletteTimer = 0
    }

    /// Faixa vertical onde a sereia pode nadar, baseada nas camadas liberadas.
    /// As fronteiras têm folga para ela nunca encostar em área bloqueada.
    func allowedYRange() -> ClosedRange<CGFloat> {
        Self.allowedYRange(for: ctx.stats)
    }

    static func allowedYRange(for stats: MermaidStats) -> ClosedRange<CGFloat> {
        var top = lockedSurfaceApproachTopY
        if canAccess(.surface, with: stats) {
            top = surfaceApproachTopY
        } else if canAccess(.clear, with: stats) {
            top = clearLayerApproachTopY
        }

        var deepest = DepthZone.mid.yRange.lowerBound
        for zone in DepthZone.allCases where zone != .surface && canAccess(zone, with: stats) {
            deepest = min(deepest, zone.yRange.lowerBound)
        }
        return (deepest + 80)...top
    }

    func allowsSurfaceTrafficEvents(atY y: CGFloat) -> Bool {
        Self.canAccess(.clear, with: ctx.stats) && y > Self.surfaceTrafficMinY
    }

    private func firstLockedAscentZone() -> DepthZone? {
        if !Self.canAccess(.clear, with: ctx.stats) { return .clear }
        if !Self.canAccess(.surface, with: ctx.stats) { return .surface }
        return nil
    }

    private func firstLockedDescentZone() -> DepthZone? {
        let deepest = DepthZone.allCases
            .filter { $0 != .surface && Self.canAccess($0, with: ctx.stats) }
            .map(\.rawValue)
            .max() ?? DepthZone.mid.rawValue
        guard deepest < DepthZone.abyss.rawValue else { return nil }
        for rawValue in (deepest + 1)...DepthZone.abyss.rawValue {
            guard let zone = DepthZone(rawValue: rawValue) else { continue }
            if !Self.canAccess(zone, with: ctx.stats) { return zone }
        }
        return nil
    }

    private func paletteForBoundary(_ edge: DepthBoundaryEdge) -> MermaidPalette {
        switch edge {
        case .upper:
            return .upper
        case .lower:
            return .abyss
        }
    }

    private static func canAccess(_ zone: DepthZone, with stats: MermaidStats) -> Bool {
        stats.canAccess(zone)
    }

    private static func smoothStep(_ value: CGFloat) -> CGFloat {
        let t = value.clamped(to: 0...1)
        return t * t * (3 - 2 * t)
    }

    /// Dreno extra de energia em camadas pouco adaptadas.
    func energyPenalty(atY y: CGFloat) -> CGFloat {
        let zone = DepthZone.zone(atY: y)
        guard zone != .shallow && zone != .mid else { return 0 }
        let adaptation = ctx.stats.adaptation(for: zone)
        return (1 - adaptation / 100) * 0.15
    }
}
