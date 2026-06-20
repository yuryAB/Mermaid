//
//  WorldStampRenderer+Water.swift
//  Ester
//
//  Stamps procedurais de movimento e fluxo da agua.
//

import UIKit

extension WorldStampRenderer {
    static func drawCurrentRibbon(context: CGContext,
                                  size: CGSize,
                                  zone: DepthZone,
                                  biome: AquaticBiome,
                                  rng: inout SeededGenerator) {
        let color = WorldVisualPalette.currentColor(for: zone)
        for i in 0..<rng.nextInt(in: 2...4) {
            let path = UIBezierPath()
            let y = size.height * rng.nextCGFloat(in: 0.35...0.65) + CGFloat(i - 1) * rng.nextCGFloat(in: 7...12)
            path.move(to: CGPoint(x: size.width * 0.04, y: y))
            for step in 1...10 {
                let t = CGFloat(step) / 10
                let x = size.width * (0.04 + 0.92 * t)
                let wave = sin(t * CGFloat.pi * rng.nextCGFloat(in: 1.4...2.8) + rng.nextCGFloat(in: -0.6...0.6)) * rng.nextCGFloat(in: 5...13)
                path.addLine(to: CGPoint(x: x, y: y + wave))
            }
            path.lineCapStyle = .round
            stroke(path, color: color.withAlphaComponent(rng.nextCGFloat(in: 0.10...0.22)), width: rng.nextCGFloat(in: 8...15))
            stroke(path, color: UIColor.lerp(color, .white, 0.35).withAlphaComponent(rng.nextCGFloat(in: 0.16...0.34)), width: rng.nextCGFloat(in: 1.5...3.0))
        }
    }
}
