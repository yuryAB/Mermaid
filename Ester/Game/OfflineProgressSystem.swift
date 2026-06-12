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
        let distance = min(cappedSeconds * 8 * stats.speedMultiplier, 14000)

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
                stats.awardPearls(4)
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
        stats.posY = stats.posY.clamped(to: DepthSystem.allowedYRange(for: stats))

        // Fora do app ela descansa, mas a fome ainda vira tensão de cuidado.
        let hungerGain: CGFloat = stats.phase == .baby
            ? min(35, hours * 6)
            : min(25, hours * 2.5)
        stats.hunger = (stats.hunger + hungerGain * stats.feedingDrainMultiplier).clamped(to: 0...100)
        stats.energy = (stats.energy + min(35, hours * 8)).clamped(to: 0...100)
        lines.append("descansou, mas voltou precisando de cuidado")

        stats.gainXP(stats.phase == .baby ? min(8, hours * 1.5) : min(35, hours * 4))
        let pearlGain = stats.phase == .baby ? (hours >= 6 ? 1 : 0) : Int(min(4, hours / 2))
        if pearlGain > 0 {
            let gained = stats.awardPearls(pearlGain)
            lines.append("juntou 🐚\(gained)")
        }
        if hours >= 3 && Int.random(in: 0..<3) == 0 {
            stats.addMemory("Viu um cardume raro enquanto você estava fora")
            lines.append("viu algo bonito e guardou a memória ✨")
        }

        stats.lastSaved = Date()
        guard !lines.isEmpty else { return nil }
        return "Enquanto você esteve fora: " + lines.joined(separator: ", ") + "."
    }
}
