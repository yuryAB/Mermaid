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

final class DepthSystem {
    unowned let ctx: GameContext

    private(set) var currentZone: DepthZone = .mid
    private var paletteTimer: CGFloat = 0
    private var unlockTimer: CGFloat = 2

    private let waterAnchors: [(y: CGFloat, color: UIColor)]

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

    /// Paleta do corpo: clara só junto à superfície, padrão na imensa
    /// faixa do meio, escura apenas nas camadas realmente profundas.
    func mermaidPalette(atY y: CGFloat) -> MermaidPalette {
        if y >= -1500 { return .upper }
        if y >= -5000 {
            return .lerp(.upper, .main, (-y - 1500) / 3500)
        }
        if y >= -24000 { return .main }
        if y >= -34000 {
            return .lerp(.main, .abyss, (-y - 24000) / 10000)
        }
        return .abyss
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        let y = ctx.mermaidPosition.y
        let zone = DepthZone.zone(atY: y)
        if zone != currentZone {
            currentZone = zone
            ctx.stats.gainXP(2)
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
            ctx.stats.gainXP(10)
            ctx.stats.courage = min(100, ctx.stats.courage + 0.5)
            ctx.say("Ela nadou mais fundo do que nunca! 🐚+\(gained)")
        }

        paletteTimer -= dt
        if paletteTimer <= 0 {
            paletteTimer = 0.25
            ctx.mermaidEntity.mermaid.applyPalette(mermaidPalette(atY: y))
        }

        unlockTimer -= dt
        if unlockTimer <= 0 {
            unlockTimer = 3
            checkUnlocks()
        }
    }

    // MARK: - Desbloqueio de camadas

    func isUnlocked(_ zone: DepthZone) -> Bool {
        ctx.stats.isUnlocked(zone)
    }

    private func checkUnlocks() {
        for zone in DepthZone.allCases where !ctx.stats.isUnlocked(zone) {
            guard meetsRequirements(zone) else { continue }
            ctx.stats.unlock(zone)
            let gained = ctx.stats.awardPearls(8)
            ctx.stats.gainXP(30)
            ctx.stats.addMemory("Alcançou a \(zone.displayName)")
            ctx.say("🌊 Nova camada alcançável: \(zone.displayName)! 🐚+\(gained)")
        }
    }

    private func meetsRequirements(_ zone: DepthZone) -> Bool {
        let stats = ctx.stats!
        if let prerequisite = zone.prerequisiteZone, !stats.isUnlocked(prerequisite) { return false }
        if stats.courage < zone.courageRequired { return false }
        if stats.phase < zone.minPhase { return false }
        if let gate = zone.adaptationGate, stats.adaptation(for: gate.zone) < gate.value { return false }
        return true
    }

    /// Mensagem para quando o jogador manda subir além do permitido.
    func ascentHint() -> String {
        "Ela ainda não está pronta para chegar tão perto da superfície. 🌅"
    }

    /// Mensagem para quando o jogador manda descer além do permitido.
    func descentHint(for zone: DepthZone) -> String {
        let stats = ctx.stats!
        if stats.phase < zone.minPhase {
            return "Ela ainda é muito nova para ir tão fundo..."
        }
        if stats.courage < zone.courageRequired {
            return "Ela ainda não tem coragem para ir tão fundo. 😟"
        }
        if let gate = zone.adaptationGate, stats.adaptation(for: gate.zone) < gate.value {
            return "Ela precisa se adaptar melhor à \(gate.zone.displayName) antes de descer mais."
        }
        return "Ela ainda não consegue descer até a \(zone.displayName)."
    }

    /// Faixa vertical onde a sereia pode nadar, baseada nas camadas liberadas.
    /// As fronteiras têm folga para ela nunca encostar em área bloqueada.
    func allowedYRange() -> ClosedRange<CGFloat> {
        var top: CGFloat = DepthZone.shallow.yRange.upperBound - 80
        if ctx.stats.isUnlocked(.surface) {
            top = 280
        } else if ctx.stats.isUnlocked(.clear) {
            top = -150
        }

        var deepest = DepthZone.mid.yRange.lowerBound
        for zone in DepthZone.allCases where zone != .surface && ctx.stats.isUnlocked(zone) {
            deepest = min(deepest, zone.yRange.lowerBound)
        }
        return (deepest + 80)...top
    }

    /// Dreno extra de energia em camadas pouco adaptadas.
    func energyPenalty(atY y: CGFloat) -> CGFloat {
        let zone = DepthZone.zone(atY: y)
        guard zone != .shallow && zone != .mid else { return 0 }
        let adaptation = ctx.stats.adaptation(for: zone)
        return (1 - adaptation / 100) * 0.15
    }
}
