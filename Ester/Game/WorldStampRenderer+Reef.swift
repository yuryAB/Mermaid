//
//  WorldStampRenderer+Reef.swift
//  Ester
//
//  Stamps procedurais de vegetacao, coral, esponjas e cristais.
//

import UIKit

extension WorldStampRenderer {
    static func drawKelp(context: CGContext,
                         size: CGSize,
                         kind: WorldStampKind,
                         zone: DepthZone,
                         rng: inout SeededGenerator) {
        let baseColor = WorldVisualPalette.kelpColor(for: zone)
        let dark = UIColor.lerp(baseColor, .black, 0.42)
        let light = UIColor.lerp(baseColor, .white, 0.22)
        let stemCount: Int
        switch kind {
        case .kelpRibbon: stemCount = rng.nextInt(in: 1...2)
        case .kelpBlade: stemCount = rng.nextInt(in: 2...3)
        default: stemCount = rng.nextInt(in: 4...7)
        }

        for index in 0..<stemCount {
            let spread = size.width * (kind == .kelpBush ? 0.56 : 0.28)
            let baseX = size.width * 0.5 + rng.nextCGFloat(in: -spread...spread) * CGFloat(index + 1) / CGFloat(stemCount + 1)
            let base = CGPoint(x: baseX, y: size.height * 0.94)
            let lean = rng.nextCGFloat(in: -30...30)
            let tip = CGPoint(x: (baseX + lean).clamped(to: size.width * 0.16...size.width * 0.84),
                              y: size.height * rng.nextCGFloat(in: 0.08...0.20))
            let mid = CGPoint(x: (base.x + tip.x) * 0.5 + rng.nextCGFloat(in: -22...22),
                              y: size.height * rng.nextCGFloat(in: 0.42...0.58))
            let path = UIBezierPath()
            path.move(to: base)
            path.addCurve(to: tip,
                          controlPoint1: CGPoint(x: base.x - lean * 0.55, y: size.height * 0.70),
                          controlPoint2: CGPoint(x: mid.x + lean * 0.35, y: size.height * 0.30))
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            let width = kind == .kelpRibbon
                ? rng.nextCGFloat(in: 9...16)
                : rng.nextCGFloat(in: 4.5...8.5)
            stroke(path, color: dark.withAlphaComponent(0.52), width: width + 3.2)
            stroke(path, color: baseColor.withAlphaComponent(0.82), width: width)
            stroke(path, color: light.withAlphaComponent(0.30), width: max(1, width * 0.22))

            let leafCount = kind == .kelpRibbon ? rng.nextInt(in: 3...5) : rng.nextInt(in: 2...4)
            for leafIndex in 1...leafCount {
                let t = CGFloat(leafIndex) / CGFloat(leafCount + 1)
                let x = cubic(base.x,
                              base.x - lean * 0.55,
                              mid.x + lean * 0.35,
                              tip.x,
                              t)
                let y = cubic(base.y,
                              size.height * 0.70,
                              size.height * 0.30,
                              tip.y,
                              t)
                let side: CGFloat = leafIndex.isMultiple(of: 2) ? 1 : -1
                drawEllipse(context: context,
                            center: CGPoint(x: x + side * rng.nextCGFloat(in: 5...12),
                                            y: y),
                            size: CGSize(width: rng.nextCGFloat(in: 11...19),
                                         height: rng.nextCGFloat(in: 30...58)),
                            angle: side * rng.nextCGFloat(in: 0.65...1.12),
                            fill: UIColor.lerp(baseColor, .white, rng.nextCGFloat(in: 0.06...0.18)).withAlphaComponent(0.54),
                            stroke: UIColor.lerp(baseColor, .black, 0.35).withAlphaComponent(0.12),
                            lineWidth: 1)
            }
        }
    }

    static func drawCoralFan(context: CGContext,
                             size: CGSize,
                             zone: DepthZone,
                             biome: AquaticBiome,
                             rng: inout SeededGenerator) {
        let color = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .coralFan)
        let dark = UIColor.lerp(color, .black, 0.34)
        let base = CGPoint(x: size.width * 0.5, y: size.height * 0.88)
        let branchCount = rng.nextInt(in: 7...11)
        for i in 0..<branchCount {
            let t = CGFloat(i) / CGFloat(max(1, branchCount - 1))
            let angle = -CGFloat.pi * rng.nextCGFloat(in: 0.18...0.82) - (CGFloat.pi * 0.18) * (0.5 - t)
            let length = rng.nextCGFloat(in: size.height * 0.40...size.height * 0.78)
            let end = CGPoint(x: base.x + cos(angle) * length * rng.nextCGFloat(in: 0.58...0.86),
                              y: base.y + sin(angle) * length)
            let path = UIBezierPath()
            path.move(to: base)
            path.addCurve(to: end,
                          controlPoint1: CGPoint(x: base.x + (end.x - base.x) * 0.18,
                                                  y: base.y - length * 0.18),
                          controlPoint2: CGPoint(x: base.x + (end.x - base.x) * 0.72,
                                                  y: base.y - length * 0.62))
            path.lineCapStyle = .round
            stroke(path, color: dark.withAlphaComponent(0.46), width: rng.nextCGFloat(in: 4.5...7.0))
            stroke(path, color: color.withAlphaComponent(0.82), width: rng.nextCGFloat(in: 2.0...4.0))

            drawEllipse(context: context,
                        center: end,
                        size: CGSize(width: rng.nextCGFloat(in: 8...14),
                                     height: rng.nextCGFloat(in: 8...14)),
                        angle: 0,
                        fill: UIColor.lerp(color, .white, 0.24).withAlphaComponent(0.72),
                        stroke: .clear,
                        lineWidth: 0)

            if rng.chance(0.45) {
                let sideEnd = CGPoint(x: end.x + rng.nextCGFloat(in: -18...18),
                                      y: end.y + rng.nextCGFloat(in: 8...24))
                let side = UIBezierPath()
                side.move(to: CGPoint(x: (base.x + end.x) * 0.5, y: (base.y + end.y) * 0.5))
                side.addLine(to: sideEnd)
                stroke(side, color: color.withAlphaComponent(0.46), width: 1.6)
            }
        }
    }

    static func drawCoralBranch(context: CGContext,
                                size: CGSize,
                                zone: DepthZone,
                                biome: AquaticBiome,
                                rng: inout SeededGenerator) {
        let color = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .coralBranch)
        let start = CGPoint(x: size.width * rng.nextCGFloat(in: 0.42...0.58),
                            y: size.height * 0.90)
        drawBranch(start: start,
                   angle: -CGFloat.pi / 2 + rng.nextCGFloat(in: -0.12...0.12),
                   length: size.height * rng.nextCGFloat(in: 0.44...0.58),
                   width: rng.nextCGFloat(in: 7...10),
                   depth: 3,
                   color: color,
                   context: context,
                   rng: &rng)
    }

    static func drawCoralTube(context: CGContext,
                              size: CGSize,
                              zone: DepthZone,
                              biome: AquaticBiome,
                              rng: inout SeededGenerator) {
        let color = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .coralTube)
        let dark = UIColor.lerp(color, .black, 0.35)
        let count = rng.nextInt(in: 4...8)
        for _ in 0..<count {
            let tubeWidth = rng.nextCGFloat(in: 14...26)
            let tubeHeight = rng.nextCGFloat(in: 46...96)
            let center = CGPoint(x: rng.nextCGFloat(in: size.width * 0.22...size.width * 0.78),
                                 y: size.height * 0.86 - tubeHeight * 0.45 + rng.nextCGFloat(in: -8...12))
            let angle = rng.nextCGFloat(in: -0.22...0.22)
            context.saveGState()
            context.translateBy(x: center.x, y: center.y)
            context.rotate(by: angle)
            let rect = CGRect(x: -tubeWidth / 2, y: -tubeHeight / 2, width: tubeWidth, height: tubeHeight)
            let tube = UIBezierPath(roundedRect: rect, cornerRadius: tubeWidth / 2)
            fill(tube,
                 in: rect.insetBy(dx: -2, dy: -2),
                 top: UIColor.lerp(color, .white, 0.24).withAlphaComponent(0.88),
                 bottom: dark.withAlphaComponent(0.88),
                 context: context)
            stroke(tube, color: dark.withAlphaComponent(0.34), width: 2)
            drawEllipse(context: context,
                        center: CGPoint(x: 0, y: -tubeHeight / 2 + tubeWidth * 0.22),
                        size: CGSize(width: tubeWidth * 0.82, height: tubeWidth * 0.42),
                        angle: 0,
                        fill: UIColor.lerp(color, .black, 0.58).withAlphaComponent(0.62),
                        stroke: UIColor.lerp(color, .white, 0.36).withAlphaComponent(0.38),
                        lineWidth: 1)
            context.restoreGState()
        }
    }

    static func drawSpongePatch(context: CGContext,
                                size: CGSize,
                                zone: DepthZone,
                                biome: AquaticBiome,
                                rng: inout SeededGenerator) {
        let color = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .spongePatch)
        let dark = UIColor.lerp(color, .black, 0.32)
        let count = rng.nextInt(in: 7...13)
        for _ in 0..<count {
            let radius = rng.nextCGFloat(in: 10...23)
            let center = CGPoint(x: rng.nextCGFloat(in: size.width * 0.22...size.width * 0.78),
                                 y: rng.nextCGFloat(in: size.height * 0.46...size.height * 0.88))
            drawEllipse(context: context,
                        center: center,
                        size: CGSize(width: radius * rng.nextCGFloat(in: 1.1...1.8),
                                     height: radius * rng.nextCGFloat(in: 0.9...1.55)),
                        angle: rng.nextCGFloat(in: -0.5...0.5),
                        fill: UIColor.lerp(color, .white, rng.nextCGFloat(in: 0.0...0.15)).withAlphaComponent(0.70),
                        stroke: dark.withAlphaComponent(0.20),
                        lineWidth: 1)
            for _ in 0..<rng.nextInt(in: 1...3) {
                drawEllipse(context: context,
                            center: CGPoint(x: center.x + rng.nextCGFloat(in: -radius * 0.35...radius * 0.35),
                                            y: center.y + rng.nextCGFloat(in: -radius * 0.28...radius * 0.28)),
                            size: CGSize(width: rng.nextCGFloat(in: 2.8...5.5),
                                         height: rng.nextCGFloat(in: 2.8...5.5)),
                            angle: 0,
                            fill: dark.withAlphaComponent(0.38),
                            stroke: .clear,
                            lineWidth: 0)
            }
        }
    }

    static func drawCrystalCluster(context: CGContext,
                                   size: CGSize,
                                   zone: DepthZone,
                                   biome: AquaticBiome,
                                   rng: inout SeededGenerator) {
        let color = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .crystalCluster)
        for _ in 0..<rng.nextInt(in: 4...8) {
            let height = rng.nextCGFloat(in: size.height * 0.34...size.height * 0.80)
            let width = height * rng.nextCGFloat(in: 0.18...0.34)
            let baseX = rng.nextCGFloat(in: size.width * 0.25...size.width * 0.75)
            let baseY = size.height * 0.90
            let tip = CGPoint(x: baseX + rng.nextCGFloat(in: -12...12),
                              y: baseY - height)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: baseX - width / 2, y: baseY))
            path.addLine(to: tip)
            path.addLine(to: CGPoint(x: baseX + width / 2, y: baseY))
            path.close()
            fill(path,
                 in: CGRect(x: baseX - width, y: tip.y, width: width * 2, height: height),
                 top: UIColor.lerp(color, .white, 0.36).withAlphaComponent(0.74),
                 bottom: UIColor.lerp(color, .black, 0.28).withAlphaComponent(0.52),
                 context: context)
            stroke(path, color: UIColor.lerp(color, .white, 0.22).withAlphaComponent(0.62), width: 1.5)
        }
        drawSoftGlow(context: context,
                     center: CGPoint(x: size.width * 0.5, y: size.height * 0.58),
                     radius: size.width * 0.42,
                     color: color.withAlphaComponent(0.20))
    }

    private static func drawBranch(start: CGPoint,
                                   angle: CGFloat,
                                   length: CGFloat,
                                   width: CGFloat,
                                   depth: Int,
                                   color: UIColor,
                                   context: CGContext,
                                   rng: inout SeededGenerator) {
        guard depth > 0, length > 10, width > 1 else { return }
        let end = CGPoint(x: start.x + cos(angle) * length,
                          y: start.y + sin(angle) * length)
        let path = UIBezierPath()
        path.move(to: start)
        path.addCurve(to: end,
                      controlPoint1: CGPoint(x: start.x + cos(angle - 0.22) * length * 0.38,
                                             y: start.y + sin(angle - 0.22) * length * 0.38),
                      controlPoint2: CGPoint(x: start.x + cos(angle + 0.18) * length * 0.74,
                                             y: start.y + sin(angle + 0.18) * length * 0.74))
        path.lineCapStyle = .round
        stroke(path, color: UIColor.lerp(color, .black, 0.40).withAlphaComponent(0.48), width: width + 2.6)
        stroke(path, color: color.withAlphaComponent(0.78), width: width)
        drawEllipse(context: context,
                    center: end,
                    size: CGSize(width: max(4, width * 1.4), height: max(4, width * 1.4)),
                    angle: 0,
                    fill: UIColor.lerp(color, .white, 0.24).withAlphaComponent(0.65),
                    stroke: .clear,
                    lineWidth: 0)

        let branchCount = rng.nextInt(in: 2...3)
        for sideIndex in 0..<branchCount {
            let side: CGFloat = sideIndex.isMultiple(of: 2) ? -1 : 1
            let branchStart = CGPoint(x: start.x + (end.x - start.x) * rng.nextCGFloat(in: 0.45...0.78),
                                      y: start.y + (end.y - start.y) * rng.nextCGFloat(in: 0.45...0.78))
            drawBranch(start: branchStart,
                       angle: angle + side * rng.nextCGFloat(in: 0.45...0.78),
                       length: length * rng.nextCGFloat(in: 0.42...0.64),
                       width: width * rng.nextCGFloat(in: 0.52...0.68),
                       depth: depth - 1,
                       color: color,
                       context: context,
                       rng: &rng)
        }
    }
}
