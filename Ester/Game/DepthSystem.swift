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
        if meters > ctx.stats.maxDepthMeters + 100 {
            ctx.stats.maxDepthMeters = meters
            ctx.stats.pearls += 2
            ctx.stats.gainXP(10)
            ctx.stats.courage = min(100, ctx.stats.courage + 0.5)
            ctx.say("Ela nadou mais fundo do que nunca! 💠+2")
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
            ctx.stats.pearls += 10
            ctx.stats.gainXP(30)
            ctx.stats.addMemory("Alcançou a \(zone.displayName)")
            ctx.say("🌊 Nova camada alcançável: \(zone.displayName)! 💠+10")
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
