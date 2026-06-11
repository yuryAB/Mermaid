//
//  OfflineProgressSystem.swift
//  Ester
//
//  A sereia continua existindo quando o app fecha: avança na rota,
//  come, descansa e ganha pequenos recursos — com limites para o
//  progresso offline nunca ser absurdo.
//

import Foundation
import CoreGraphics

enum OfflineProgressSystem {
    /// Aplica o progresso offline e devolve um resumo pt-BR (nil se a ausência foi curta).
    static func apply(stats: MermaidStats) -> String? {
        let elapsed = CGFloat(Date().timeIntervalSince(stats.lastSaved))
        guard elapsed > 300, stats.phase != .egg else { return nil }

        let cappedSeconds = min(elapsed, 12 * 3600)
        let hours = cappedSeconds / 3600
        var lines: [String] = []

        // distância offline limitada: nunca cruza o mundo de uma vez
        let distance = min(cappedSeconds * 8, 14000)

        if let destinationId = stats.destinationRegionId,
           let destination = RegionDiscoverySystem.region(withId: destinationId) {
            let current = CGPoint(x: stats.posX, y: stats.posY)
            let dx = destination.center.x - current.x
            let dy = destination.center.y - current.y
            let total = max(1, sqrt(dx * dx + dy * dy))
            let step = min(distance, total)
            stats.posX += dx / total * step
            stats.posY += dy / total * step

            if destination.contains(CGPoint(x: stats.posX, y: stats.posY)) {
                stats.destinationRegionId = nil
                stats.discoveredRegionIds.insert(destination.id)
                stats.pearls += 5
                stats.addMemory("Chegou a \(destination.name) durante a sua ausência")
                lines.append("ela chegou a \(destination.name)! 🗺")
            } else {
                lines.append("ela avançou na rota para \(destination.name)")
            }
        } else {
            // deriva tranquila pela vizinhança
            stats.posX = (stats.posX + .random(in: -1 ... 1) * distance * 0.3)
                .clamped(to: World.minX...World.maxX)
            lines.append("ela explorou as águas por perto")
        }

        // manter a posição dentro das camadas liberadas
        stats.posY = stats.posY.clamped(to: allowedYRange(for: stats))

        // alimentação e descanso moderados
        if hours >= 1 {
            let meals = Int(min(4, hours / 2)) + 1
            stats.mealsEaten += meals
            stats.hunger = max(0, stats.hunger - CGFloat(meals) * 8)
            lines.append("encontrou comida pelo caminho")
        }
        stats.gainXP(min(50, hours * 6))
        let pearlGain = Int(min(6, hours))
        if pearlGain > 0 {
            stats.pearls += pearlGain
            lines.append("juntou 🐚\(pearlGain)")
        }
        if hours >= 3 && Int.random(in: 0..<3) == 0 {
            stats.addMemory("Viu um cardume raro enquanto você estava fora")
            lines.append("viu algo bonito e guardou a memória ✨")
        }

        guard !lines.isEmpty else { return nil }
        return "Enquanto você esteve fora: " + lines.joined(separator: ", ") + "."
    }

    /// Réplica estática da faixa permitida, sem depender dos sistemas da cena.
    private static func allowedYRange(for stats: MermaidStats) -> ClosedRange<CGFloat> {
        var top: CGFloat = DepthZone.shallow.yRange.upperBound - 80
        if stats.isUnlocked(.surface) {
            top = 280
        } else if stats.isUnlocked(.clear) {
            top = -150
        }
        var deepest = DepthZone.mid.yRange.lowerBound
        for zone in DepthZone.allCases where zone != .surface && stats.isUnlocked(zone) {
            deepest = min(deepest, zone.yRange.lowerBound)
        }
        return (deepest + 80)...top
    }
}
