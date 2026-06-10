//
//  DepthSystem.swift
//  Ester
//
//  Conecta a posição vertical da sereia à cor da água, à paleta do corpo,
//  à adaptação por camada e ao desbloqueio progressivo das zonas.
//

import Foundation
import SpriteKit

final class DepthSystem {
    unowned let ctx: GameContext

    private(set) var currentZone: DepthZone = .shallow
    private var paletteTimer: CGFloat = 0
    private var unlockTimer: CGFloat = 2

    private let waterAnchors: [(y: CGFloat, color: UIColor)]

    init(ctx: GameContext) {
        self.ctx = ctx
        let waters = ColorManager.shared.waters
        let reefColor = UIColor.lerp(waters["shallow"]!, waters["mid"]!, 0.5)
        let abyssFloor = UIColor.lerp(waters["abyssal"]!, .black, 0.45)
        waterAnchors = [
            (World.surfaceTopY, waters["surface"]!),
            (World.waterlineY, waters["shallow"]!),
            (-1500, reefColor),
            (-3000, waters["mid"]!),
            (-4500, waters["deep"]!),
            (-6000, waters["abyssal"]!),
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

    /// Paleta do corpo: clara perto da superfície, escura no abismo.
    func mermaidPalette(atY y: CGFloat) -> MermaidPalette {
        if y >= 0 { return .upper }
        if y >= -2600 {
            return .lerp(.upper, .main, -y / 2600)
        }
        let t = ((-y - 2600) / 3400).clamped(to: 0...1)
        return .lerp(.main, .abyss, t)
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
        let rate: CGFloat = (zone == .shallow || zone == .surface) ? 0.5 : 0.35
        let current = ctx.stats.adaptation(for: zone)
        ctx.stats.setAdaptation(current + dt * rate * (1 - current / 100), for: zone)

        // Recorde de profundidade vira recompensa
        let meters = max(0, -y / 10)
        if meters > ctx.stats.maxDepthMeters + 25 {
            ctx.stats.maxDepthMeters = meters
            ctx.stats.pearls += 2
            ctx.stats.gainXP(10)
            ctx.stats.courage = min(100, ctx.stats.courage + 0.5)
            ctx.say("Nova profundidade: \(Int(meters))m! 💠+2")
        }

        // Paleta do corpo (com folga para não recolorir todo frame)
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

    // MARK: - Desbloqueio de zonas

    func isUnlocked(_ zone: DepthZone) -> Bool {
        ctx.stats.isUnlocked(zone)
    }

    private func checkUnlocks() {
        for zone in DepthZone.allCases where !ctx.stats.isUnlocked(zone) {
            guard meetsRequirements(zone) else { continue }
            ctx.stats.unlock(zone)
            ctx.stats.pearls += 10
            ctx.stats.gainXP(30)
            ctx.stats.addMemory("Desbloqueou \(zone.displayName)")
            ctx.say("🌊 Nova área desbloqueada: \(zone.displayName)! 💠+10")
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

    func unlockHint(_ zone: DepthZone) -> String {
        let stats = ctx.stats!
        if let prerequisite = zone.prerequisiteZone, !stats.isUnlocked(prerequisite) {
            return "Primeiro preciso conhecer \(prerequisite.displayName)..."
        }
        if stats.phase < zone.minPhase {
            return "Ainda sou muito nova para \(zone.displayName)..."
        }
        if stats.courage < zone.courageRequired {
            return "Não tenho coragem para \(zone.displayName) ainda... 😟"
        }
        if let gate = zone.adaptationGate, stats.adaptation(for: gate.zone) < gate.value {
            return "Preciso me adaptar mais a \(gate.zone.displayName) primeiro."
        }
        return "Ainda não consigo ir para \(zone.displayName)."
    }

    /// Faixa vertical onde a sereia pode nadar, baseada nas zonas liberadas.
    func allowedYRange() -> ClosedRange<CGFloat> {
        var deepest: CGFloat = DepthZone.shallow.yRange.lowerBound
        for zone in DepthZone.allCases where zone != .surface && ctx.stats.isUnlocked(zone) {
            deepest = min(deepest, zone.yRange.lowerBound)
        }
        let top: CGFloat = ctx.stats.isUnlocked(.surface) ? 280 : -30
        return (deepest + 50)...top
    }

    /// Dreno extra de energia em zonas pouco adaptadas.
    func energyPenalty(atY y: CGFloat) -> CGFloat {
        let zone = DepthZone.zone(atY: y)
        guard zone != .shallow else { return 0 }
        let adaptation = ctx.stats.adaptation(for: zone)
        return (1 - adaptation / 100) * 0.15
    }
}
