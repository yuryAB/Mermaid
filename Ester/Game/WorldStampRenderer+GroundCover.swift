//
//  WorldStampRenderer+GroundCover.swift
//  Ester
//
//  Saia vegetal que amarra ilhas/rochedos ao fundo do oceano.
//

import UIKit

extension WorldStampRenderer {
    static func drawReefSkirt(context: CGContext,
                              size: CGSize,
                              zone: DepthZone,
                              biome: AquaticBiome,
                              rng: inout SeededGenerator) {
        let cover = WorldVisualPalette.groundCoverColor(for: zone, biome: biome)
        let rock = WorldVisualPalette.rockColor(for: zone)
        let dark = UIColor.lerp(cover, .black, zone == .abyss ? 0.50 : 0.34)
        let light = UIColor.lerp(cover, .white, zone == .deep || zone == .abyss ? 0.12 : 0.24)
        let underside = UIColor.lerp(rock, .black, 0.42)

        drawSoftGlow(context: context,
                     center: CGPoint(x: size.width * 0.50, y: size.height * 0.70),
                     radius: size.width * 0.34,
                     color: underside.withAlphaComponent(0.18))

        let band = UIBezierPath()
        let left = size.width * 0.06
        let right = size.width * 0.94
        band.move(to: CGPoint(x: left, y: size.height * 0.18))
        for step in 0...9 {
            let t = CGFloat(step) / 9
            let x = left + (right - left) * t
            let y = size.height * rng.nextCGFloat(in: 0.10...0.23)
            band.addLine(to: CGPoint(x: x, y: y))
        }
        for step in stride(from: 9, through: 0, by: -1) {
            let t = CGFloat(step) / 9
            let x = left + (right - left) * t
            let sag = sin(t * CGFloat.pi) * rng.nextCGFloat(in: 8...20)
            let y = size.height * rng.nextCGFloat(in: 0.32...0.46) + sag
            band.addLine(to: CGPoint(x: x, y: y))
        }
        band.close()

        fill(band,
             in: CGRect(x: 0, y: size.height * 0.08, width: size.width, height: size.height * 0.44),
             top: light.withAlphaComponent(0.70),
             bottom: dark.withAlphaComponent(0.82),
             context: context)
        stroke(band, color: dark.withAlphaComponent(0.22), width: 1.5)

        let tuftCount = rng.nextInt(in: 18...32)
        for index in 0..<tuftCount {
            let t = CGFloat(index) / CGFloat(max(1, tuftCount - 1))
            let rootX = size.width * (0.08 + t * 0.84) + rng.nextCGFloat(in: -6...6)
            let rootY = size.height * rng.nextCGFloat(in: 0.26...0.46)
            let length = size.height * rng.nextCGFloat(in: 0.22...0.64)
            let lean = rng.nextCGFloat(in: -18...18)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: rootX, y: rootY))
            path.addCurve(to: CGPoint(x: rootX + lean, y: min(size.height * 0.96, rootY + length)),
                          controlPoint1: CGPoint(x: rootX - lean * 0.30, y: rootY + length * 0.30),
                          controlPoint2: CGPoint(x: rootX + lean * 0.76, y: rootY + length * 0.76))
            path.lineCapStyle = .round
            let width = rng.nextCGFloat(in: 1.2...3.4)
            stroke(path, color: dark.withAlphaComponent(rng.nextCGFloat(in: 0.36...0.58)), width: width + 1.4)
            stroke(path, color: cover.withAlphaComponent(rng.nextCGFloat(in: 0.46...0.74)), width: width)
        }

        for _ in 0..<rng.nextInt(in: 7...13) {
            let center = CGPoint(x: rng.nextCGFloat(in: size.width * 0.14...size.width * 0.86),
                                 y: rng.nextCGFloat(in: size.height * 0.18...size.height * 0.42))
            drawEllipse(context: context,
                        center: center,
                        size: CGSize(width: rng.nextCGFloat(in: 8...22),
                                     height: rng.nextCGFloat(in: 5...13)),
                        angle: rng.nextCGFloat(in: -0.36...0.36),
                        fill: UIColor.lerp(cover, .white, rng.nextCGFloat(in: 0.08...0.24)).withAlphaComponent(0.46),
                        stroke: dark.withAlphaComponent(0.10),
                        lineWidth: 1)
        }

        if biome == .crystalField || biome == .deepVents || zone == .abyss {
            let glow = biome == .deepVents
                ? UIColor(red: 0.94, green: 0.42, blue: 0.22, alpha: 1)
                : UIColor(red: 0.48, green: 0.92, blue: 1.0, alpha: 1)
            for _ in 0..<rng.nextInt(in: 2...5) {
                drawSoftGlow(context: context,
                             center: CGPoint(x: rng.nextCGFloat(in: size.width * 0.18...size.width * 0.82),
                                             y: rng.nextCGFloat(in: size.height * 0.38...size.height * 0.76)),
                             radius: rng.nextCGFloat(in: 8...18),
                             color: glow.withAlphaComponent(0.16))
            }
        }
    }
}
