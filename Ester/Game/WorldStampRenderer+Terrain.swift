//
//  WorldStampRenderer+Terrain.swift
//  Ester
//
//  Stamps procedurais de rochas, fontes termais, ruinas e macroformas.
//

import UIKit

extension WorldStampRenderer {
    static func drawRockBase(context: CGContext,
                             size: CGSize,
                             zone: DepthZone,
                             biome: AquaticBiome,
                             rng: inout SeededGenerator) {
        let rect = CGRect(origin: .zero, size: size)
        let base = WorldVisualPalette.rockColor(for: zone)
        let edge = WorldVisualPalette.edgeColor(for: zone)
        let top = UIColor.lerp(base, .white, zone == .abyss ? 0.08 : 0.18)
        let bottom = UIColor.lerp(base, .black, 0.26)
        let path = UIBezierPath()
        let left = size.width * 0.08
        let right = size.width * 0.92
        let floorY = size.height * rng.nextCGFloat(in: 0.78...0.88)
        path.move(to: CGPoint(x: left, y: floorY))
        let steps = 10
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let x = left + (right - left) * t
            let dome = sin(t * .pi) * rng.nextCGFloat(in: 36...58)
            let y = floorY - dome + rng.nextCGFloat(in: -8...10)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        for i in stride(from: steps, through: 0, by: -1) {
            let t = CGFloat(i) / CGFloat(steps)
            let x = left + (right - left) * t + rng.nextCGFloat(in: -8...8)
            let sag = sin(t * .pi) * rng.nextCGFloat(in: 12...34)
            let y = floorY + rng.nextCGFloat(in: 16...42) + sag
            path.addLine(to: CGPoint(x: x, y: min(size.height * 0.96, y)))
        }
        path.close()

        fill(path, in: rect, top: top.withAlphaComponent(0.82), bottom: bottom.withAlphaComponent(0.94), context: context)
        stroke(path, color: edge.withAlphaComponent(0.52), width: 3.0)

        let crackColor = UIColor.lerp(base, .black, 0.62).withAlphaComponent(0.28)
        for _ in 0..<rng.nextInt(in: 3...6) {
            let start = CGPoint(x: rng.nextCGFloat(in: size.width * 0.22...size.width * 0.78),
                                y: rng.nextCGFloat(in: size.height * 0.34...size.height * 0.56))
            let end = CGPoint(x: start.x + rng.nextCGFloat(in: -26...26),
                              y: start.y + rng.nextCGFloat(in: 20...44))
            let crack = UIBezierPath()
            crack.move(to: start)
            crack.addLine(to: end)
            stroke(crack, color: crackColor, width: rng.nextCGFloat(in: 1.0...2.2))
        }

        for _ in 0..<rng.nextInt(in: 4...8) {
            drawEllipse(context: context,
                        center: CGPoint(x: rng.nextCGFloat(in: size.width * 0.18...size.width * 0.82),
                                        y: rng.nextCGFloat(in: size.height * 0.50...size.height * 0.82)),
                        size: CGSize(width: rng.nextCGFloat(in: 7...18),
                                     height: rng.nextCGFloat(in: 3...9)),
                        angle: rng.nextCGFloat(in: -0.45...0.45),
                        fill: UIColor.lerp(base, .white, 0.18).withAlphaComponent(0.12),
                        stroke: .clear,
                        lineWidth: 0)
        }
    }

    static func drawVentStack(context: CGContext,
                              size: CGSize,
                              zone: DepthZone,
                              biome: AquaticBiome,
                              rng: inout SeededGenerator) {
        let ember = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .ventStack)
        let rock = UIColor.lerp(WorldVisualPalette.rockColor(for: zone), .black, 0.38)
        let count = rng.nextInt(in: 3...6)
        for _ in 0..<count {
            let width = rng.nextCGFloat(in: 16...34)
            let height = rng.nextCGFloat(in: 54...128)
            let x = rng.nextCGFloat(in: size.width * 0.25...size.width * 0.75)
            let bottom = size.height * 0.92
            let rect = CGRect(x: x - width / 2,
                              y: bottom - height,
                              width: width,
                              height: height)
            let chimney = UIBezierPath(roundedRect: rect, cornerRadius: width * 0.28)
            rock.withAlphaComponent(0.82).setFill()
            chimney.fill()
            stroke(chimney, color: UIColor.lerp(rock, .white, 0.14).withAlphaComponent(0.26), width: 1.5)
            drawSoftGlow(context: context,
                         center: CGPoint(x: x, y: rect.minY + 4),
                         radius: width * 0.9,
                         color: ember.withAlphaComponent(0.34))
            drawEllipse(context: context,
                        center: CGPoint(x: x, y: rect.minY + 2),
                        size: CGSize(width: width * 0.78, height: width * 0.28),
                        angle: 0,
                        fill: ember.withAlphaComponent(0.64),
                        stroke: .clear,
                        lineWidth: 0)
        }
        for _ in 0..<rng.nextInt(in: 3...6) {
            drawSoftGlow(context: context,
                         center: CGPoint(x: rng.nextCGFloat(in: size.width * 0.30...size.width * 0.70),
                                         y: rng.nextCGFloat(in: size.height * 0.12...size.height * 0.45)),
                         radius: rng.nextCGFloat(in: 12...28),
                         color: ember.withAlphaComponent(rng.nextCGFloat(in: 0.10...0.22)))
        }
    }

    static func drawRuinShard(context: CGContext,
                              size: CGSize,
                              zone: DepthZone,
                              biome: AquaticBiome,
                              rng: inout SeededGenerator) {
        let stone = WorldVisualPalette.detailColor(for: zone, biome: biome, kind: .ruinShard)
        let edge = UIColor.lerp(stone, .white, 0.16)
        let columnCount = rng.nextInt(in: 2...4)
        for i in 0..<columnCount {
            let width = rng.nextCGFloat(in: 24...42)
            let height = rng.nextCGFloat(in: size.height * 0.34...size.height * 0.78)
            let x = size.width * (0.30 + CGFloat(i) * 0.18) + rng.nextCGFloat(in: -10...10)
            let y = size.height * 0.90 - height / 2
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.rotate(by: rng.nextCGFloat(in: -0.14...0.14))
            let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 5)
            fill(path,
                 in: rect,
                 top: UIColor.lerp(stone, .white, 0.12).withAlphaComponent(0.72),
                 bottom: UIColor.lerp(stone, .black, 0.22).withAlphaComponent(0.82),
                 context: context)
            stroke(path, color: edge.withAlphaComponent(0.34), width: 1.5)
            for _ in 0..<rng.nextInt(in: 2...4) {
                let crack = UIBezierPath()
                crack.move(to: CGPoint(x: rng.nextCGFloat(in: -width * 0.34...width * 0.34),
                                       y: rng.nextCGFloat(in: -height * 0.34...height * 0.10)))
                crack.addLine(to: CGPoint(x: rng.nextCGFloat(in: -width * 0.32...width * 0.32),
                                          y: rng.nextCGFloat(in: 0...height * 0.42)))
                stroke(crack, color: UIColor.lerp(stone, .black, 0.55).withAlphaComponent(0.34), width: 1)
            }
            context.restoreGState()
        }
    }

    static func drawMacroform(context: CGContext,
                              size: CGSize,
                              zone: DepthZone,
                              biome: AquaticBiome,
                              rng: inout SeededGenerator) {
        let base = WorldVisualPalette.macroColor(for: zone, biome: biome)
        let color = UIColor.lerp(base, .black, 0.18).withAlphaComponent(0.54)
        switch biome {
        case .ancientRuins:
            drawAncientRuinSilhouette(context: context, size: size, color: color, rng: &rng)
        case .cavernMouth, .reefWall:
            drawReefWallSilhouette(context: context, size: size, color: color, rng: &rng)
        default:
            drawDistantForestSilhouette(context: context, size: size, color: color, rng: &rng)
        }
    }

    private static func drawAncientRuinSilhouette(context: CGContext,
                                                  size: CGSize,
                                                  color: UIColor,
                                                  rng: inout SeededGenerator) {
        for i in 0..<rng.nextInt(in: 4...7) {
            let width = rng.nextCGFloat(in: 16...34)
            let height = rng.nextCGFloat(in: size.height * 0.28...size.height * 0.68)
            let x = size.width * 0.18 + CGFloat(i) * size.width * 0.12 + rng.nextCGFloat(in: -10...10)
            let bottomY = size.height * rng.nextCGFloat(in: 0.76...0.88)
            let topY = bottomY - height
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: bottomY))
            path.addLine(to: CGPoint(x: x + rng.nextCGFloat(in: -5...5), y: topY + rng.nextCGFloat(in: -8...8)))
            path.addLine(to: CGPoint(x: x + width, y: topY + rng.nextCGFloat(in: -10...10)))
            path.addLine(to: CGPoint(x: x + width + rng.nextCGFloat(in: -5...5), y: bottomY + rng.nextCGFloat(in: -8...8)))
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            stroke(path, color: color.withAlphaComponent(0.26), width: rng.nextCGFloat(in: 6...13))
            stroke(path, color: UIColor.lerp(color, .white, 0.12).withAlphaComponent(0.18), width: rng.nextCGFloat(in: 1.5...3.0))
        }
        drawBrokenRootMass(context: context,
                           size: size,
                           color: color.withAlphaComponent(0.14),
                           yRange: size.height * 0.70...size.height * 0.90,
                           rng: &rng)
    }

    private static func drawReefWallSilhouette(context: CGContext,
                                               size: CGSize,
                                               color: UIColor,
                                               rng: inout SeededGenerator) {
        drawBrokenRootMass(context: context,
                           size: size,
                           color: color.withAlphaComponent(0.16),
                           yRange: size.height * 0.58...size.height * 0.86,
                           rng: &rng)
        for _ in 0..<rng.nextInt(in: 12...22) {
            let x = rng.nextCGFloat(in: size.width * 0.10...size.width * 0.90)
            let baseY = rng.nextCGFloat(in: size.height * 0.70...size.height * 0.92)
            let height = rng.nextCGFloat(in: size.height * 0.18...size.height * 0.50)
            let lean = rng.nextCGFloat(in: -26...26)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: baseY))
            path.addCurve(to: CGPoint(x: x + lean, y: baseY - height),
                          controlPoint1: CGPoint(x: x - lean * 0.18, y: baseY - height * 0.32),
                          controlPoint2: CGPoint(x: x + lean * 0.78, y: baseY - height * 0.74))
            path.lineCapStyle = .round
            stroke(path, color: color.withAlphaComponent(rng.nextCGFloat(in: 0.10...0.22)), width: rng.nextCGFloat(in: 5...14))
        }
    }

    private static func drawDistantForestSilhouette(context: CGContext,
                                                    size: CGSize,
                                                    color: UIColor,
                                                    rng: inout SeededGenerator) {
        drawBrokenRootMass(context: context,
                           size: size,
                           color: color.withAlphaComponent(0.12),
                           yRange: size.height * 0.62...size.height * 0.88,
                           rng: &rng)
        for _ in 0..<rng.nextInt(in: 9...18) {
            let x = rng.nextCGFloat(in: size.width * 0.12...size.width * 0.88)
            let baseY = rng.nextCGFloat(in: size.height * 0.68...size.height * 0.90)
            let height = rng.nextCGFloat(in: size.height * 0.16...size.height * 0.42)
            let lean = rng.nextCGFloat(in: -22...22)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: baseY))
            path.addCurve(to: CGPoint(x: x + lean, y: baseY - height),
                          controlPoint1: CGPoint(x: x - lean * 0.24, y: baseY - height * 0.28),
                          controlPoint2: CGPoint(x: x + lean * 0.70, y: baseY - height * 0.70))
            path.lineCapStyle = .round
            stroke(path, color: color.withAlphaComponent(rng.nextCGFloat(in: 0.10...0.20)), width: rng.nextCGFloat(in: 4...11))

            if rng.chance(0.42) {
                drawEllipse(context: context,
                            center: CGPoint(x: x + lean * rng.nextCGFloat(in: 0.44...0.86),
                                            y: baseY - height * rng.nextCGFloat(in: 0.42...0.82)),
                            size: CGSize(width: rng.nextCGFloat(in: 30...72),
                                         height: rng.nextCGFloat(in: 16...42)),
                            angle: rng.nextCGFloat(in: -0.45...0.45),
                            fill: color.withAlphaComponent(rng.nextCGFloat(in: 0.05...0.10)),
                            stroke: .clear,
                            lineWidth: 0)
            }
        }
    }

    private static func drawBrokenRootMass(context: CGContext,
                                           size: CGSize,
                                           color: UIColor,
                                           yRange: ClosedRange<CGFloat>,
                                           rng: inout SeededGenerator) {
        for _ in 0..<rng.nextInt(in: 5...9) {
            let width = rng.nextCGFloat(in: size.width * 0.10...size.width * 0.28)
            let center = CGPoint(x: rng.nextCGFloat(in: size.width * 0.12...size.width * 0.88),
                                 y: rng.nextCGFloat(in: yRange))
            drawEllipse(context: context,
                        center: center,
                        size: CGSize(width: width,
                                     height: rng.nextCGFloat(in: size.height * 0.035...size.height * 0.085)),
                        angle: rng.nextCGFloat(in: -0.22...0.22),
                        fill: color.withAlphaComponent(rng.nextCGFloat(in: 0.08...0.20)),
                        stroke: .clear,
                        lineWidth: 0)
        }

        for _ in 0..<rng.nextInt(in: 8...16) {
            let x = rng.nextCGFloat(in: size.width * 0.10...size.width * 0.90)
            let y = rng.nextCGFloat(in: yRange)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y))
            path.addCurve(to: CGPoint(x: x + rng.nextCGFloat(in: -22...22),
                                      y: y + rng.nextCGFloat(in: 18...58)),
                          controlPoint1: CGPoint(x: x + rng.nextCGFloat(in: -12...12), y: y + 10),
                          controlPoint2: CGPoint(x: x + rng.nextCGFloat(in: -18...18), y: y + 34))
            path.lineCapStyle = .round
            stroke(path, color: color.withAlphaComponent(rng.nextCGFloat(in: 0.10...0.24)), width: rng.nextCGFloat(in: 1.2...3.2))
        }
    }
}
