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
        let startingRegion = RegionDiscoverySystem.region(withId: stats.currentRegionId)
            ?? RegionDiscoverySystem.region(withId: "recife_tropical")
        let startPoint = CGPoint(x: stats.posX, y: stats.posY)

        // distância offline limitada: nunca cruza o mundo de uma vez
        let distance = min(cappedSeconds * 8 * stats.speedMultiplier, 14000)

        if let routeId = stats.discoveryRouteRegionId,
           let current = startingRegion,
           let destination = RegionDiscoverySystem.region(withId: routeId) {
            let target = boundedPoint(stats.discoveryPoint(for: destination, from: current),
                                      in: current,
                                      stats: stats)
            move(stats: stats, toward: target, maxDistance: distance)
            if CGPoint(x: stats.posX, y: stats.posY).distance(to: target) < 180 {
                stats.discoveryRouteRegionId = nil
                stats.readyRegionDiscoveryId = destination.id
                lines.append("ela achou a borda de \(destination.name) e espera sua confirmação")
            } else {
                lines.append("ela seguiu uma pista no mapa")
            }
        } else if let destinationId = stats.destinationRegionId,
           let destination = RegionDiscoverySystem.region(withId: destinationId) {
            _ = CGPoint(x: stats.posX, y: stats.posY)
            let rawTarget = stats.savedMapPosition(for: destination) ?? destination.center
            let target = boundedPoint(rawTarget, in: destination, stats: stats)
            move(stats: stats, toward: target, maxDistance: distance)

            if CGPoint(x: stats.posX, y: stats.posY).distance(to: target) < 700 {
                stats.destinationRegionId = nil
                stats.posX = target.x
                stats.posY = target.y
                stats.rememberMapPosition(target, in: destination)
                stats.discoveredRegionIds.insert(destination.id)
                stats.currentRegionId = destination.id
                stats.awardPearls(4)
                stats.addMemory("Chegou a \(destination.name) durante a sua ausência")
                lines.append("ela chegou a \(destination.name)! 🗺")
            } else {
                lines.append("ela avançou na rota para \(destination.name)")
            }
        } else {
            // deriva tranquila pela vizinhança
            let xRange = startingRegion?.playableXRange ?? (World.minX...World.maxX)
            stats.posX = (stats.posX + .random(in: -1 ... 1) * distance * 0.3)
                .clamped(to: xRange)
            lines.append("ela explorou as águas por perto")
        }

        // manter a posição dentro das camadas liberadas
        stats.posY = stats.posY.clamped(to: DepthSystem.allowedYRange(for: stats))
        if let region = RegionDiscoverySystem.region(withId: stats.currentRegionId) ?? startingRegion {
            let endPoint = boundedPoint(CGPoint(x: stats.posX, y: stats.posY),
                                        in: region,
                                        stats: stats)
            stats.posX = endPoint.x
            stats.posY = endPoint.y
            let revealedPOIs = applyOfflinePathReveal(stats: stats,
                                                      from: startPoint,
                                                      to: endPoint,
                                                      in: region)
            stats.rememberMapPosition(endPoint, in: region)
            if revealedPOIs > 0 {
                lines.append("marcou \(revealedPOIs) ponto\(revealedPOIs == 1 ? "" : "s") no mapa")
            }
        }

        // Fora do app ela descansa, mas a fome ainda vira tensão de cuidado.
        let hungerGain: CGFloat = stats.phase == .baby
            ? min(35, hours * 6)
            : min(25, hours * 2.5)
        stats.hunger = (stats.hunger + hungerGain * stats.feedingDrainMultiplier).clamped(to: 0...100)
        stats.energy = (stats.energy + min(35, hours * 8)).clamped(to: 0...100)
        lines.append("descansou, mas voltou precisando de cuidado")

        let pearlGain = stats.phase == .baby ? (hours >= 6 ? 1 : 0) : Int(min(4, hours / 2))
        if pearlGain > 0 {
            let gained = stats.awardPearls(pearlGain)
            lines.append("juntou 🐚\(GameUI.shellAmountText(gained))")
        }
        if hours >= 3 && Int.random(in: 0..<3) == 0 {
            stats.addMemory("Viu um cardume raro enquanto você estava fora")
            lines.append("viu algo bonito e guardou a memória ✨")
        }

        stats.lastSaved = Date()
        guard !lines.isEmpty else { return nil }
        return "Enquanto você esteve fora: " + lines.joined(separator: ", ") + "."
    }

    private static func move(stats: MermaidStats, toward target: CGPoint, maxDistance: CGFloat) {
        let current = CGPoint(x: stats.posX, y: stats.posY)
        let dx = target.x - current.x
        let dy = target.y - current.y
        let total = max(1, sqrt(dx * dx + dy * dy))
        let step = min(maxDistance, total)
        stats.posX += dx / total * step
        stats.posY += dy / total * step
    }

    private static func boundedPoint(_ point: CGPoint,
                                     in region: Region,
                                     stats: MermaidStats) -> CGPoint {
        let yRange = DepthSystem.allowedYRange(for: stats)
        return CGPoint(x: point.x.clamped(to: region.playableXRange),
                       y: point.y.clamped(to: yRange))
    }

    private static func applyOfflinePathReveal(stats: MermaidStats,
                                               from start: CGPoint,
                                               to end: CGPoint,
                                               in region: Region) -> Int {
        let samples = 10
        var revealedPOIs = 0
        for index in 0...samples {
            let t = CGFloat(index) / CGFloat(samples)
            let wave = sin(t * .pi * 2) * min(420, start.distance(to: end) * 0.08)
            let point = CGPoint(x: (start.x + (end.x - start.x) * t + wave).clamped(to: region.playableXRange),
                                y: (start.y + (end.y - start.y) * t).clamped(to: World.floorY...World.surfaceTopY))
            stats.revealExpeditionMap(in: region, near: point)
            let radius: CGFloat = 280
            for poi in WorldPOICatalog.pois(in: region, stats: stats)
                where !stats.isPOIDiscovered(poi.key)
                    && poi.position.distance(to: point) <= radius {
                stats.discoverPOI(poi.key)
                stats.revealExpeditionMap(in: region, near: poi.position)
                revealedPOIs += 1
            }
        }
        return revealedPOIs
    }
}
