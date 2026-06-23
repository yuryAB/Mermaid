//
//  FishDrawingFactory.swift
//  Ester
//
//  Fabrica procedural de silhuetas e ilustrações das especies aquaticas.
//

import SpriteKit

enum FishDrawingFactory {
    /// Desenho do peixe (corpo, cauda, olho) reaproveitável para a cópia
    /// que fica em destaque no topo de um desafio.
    static func fishDrawing(length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor,
                                        animateTail: Bool,
                                        silhouette: FishSilhouette = .oval,
                                        pattern: FishPattern = .plain,
                                        patternSeed: String? = nil) -> SKNode {
        let node = SKNode()

        let body = bodyShape(length: length, height: height, silhouette: silhouette)
        body.fillColor = color
        body.strokeColor = color.withAlphaComponent(0.4)
        body.name = "fish_body"
        node.addChild(body)

        let tailNode = tailShape(length: length, height: height, color: color, silhouette: silhouette)
        node.addChild(tailNode)

        if animateTail {
            let tight = silhouette == .needle ? 0.82 : 0.7
            let tailSwing = SKAction.repeatForever(.sequence([
                .scaleX(to: tight, duration: 0.28),
                .scaleX(to: 1.0, duration: 0.28)
            ]))
            tailSwing.eaeInEaseOut()
            tailNode.run(tailSwing)
        }

        if silhouette != .turtle {
            addFins(to: node, length: length, height: height, color: color, silhouette: silhouette)
            addPattern(pattern,
                       to: node,
                       length: length,
                       height: height,
                       color: color,
                       silhouette: silhouette,
                       seed: patternSeed)
            addEye(to: node, length: length, height: height, silhouette: silhouette)
        }

        return node
    }

    static func bodyLength(for silhouette: FishSilhouette, rare: Bool, species: AquaticSpecies?) -> CGFloat {
        if species?.group == .mammal || species?.group == .shark || species?.group == .reptile {
            return CGFloat.random(in: rare ? 110...150 : 76...126)
        }
        if species?.group == .crustacean || species?.group == .mollusk || species?.group == .echinoderm {
            return CGFloat.random(in: rare ? 72...104 : 28...58)
        }
        let base: ClosedRange<CGFloat> = rare ? 80...118 : 30...70
        switch silhouette {
        case .oval:
            return CGFloat.random(in: base)
        case .needle:
            return CGFloat.random(in: rare ? 95...140 : 58...96)
        case .diamond:
            return CGFloat.random(in: rare ? 86...118 : 42...76)
        case .moon:
            return CGFloat.random(in: rare ? 88...120 : 44...78)
        case .ray:
            return CGFloat.random(in: rare ? 105...145 : 72...112)
        case .turtle:
            return CGFloat.random(in: rare ? 116...154 : 82...124)
        }
    }

    static func bodyHeight(for silhouette: FishSilhouette, length: CGFloat) -> CGFloat {
        switch silhouette {
        case .oval:
            return length * CGFloat.random(in: 0.34...0.5)
        case .needle:
            return length * CGFloat.random(in: 0.16...0.24)
        case .diamond:
            return length * CGFloat.random(in: 0.55...0.72)
        case .moon:
            return length * CGFloat.random(in: 0.58...0.78)
        case .ray:
            return length * CGFloat.random(in: 0.34...0.46)
        case .turtle:
            return length * CGFloat.random(in: 0.46...0.55)
        }
    }

    private static func bodyShape(length: CGFloat,
                                  height: CGFloat,
                                  silhouette: FishSilhouette) -> SKShapeNode {
        switch silhouette {
        case .oval, .needle, .moon:
            return SKShapeNode(ellipseOf: CGSize(width: length, height: height))
        case .turtle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: -height * 0.06))
            path.addCurve(to: CGPoint(x: -length * 0.28, y: height * 0.36),
                          controlPoint1: CGPoint(x: -length * 0.44, y: height * 0.14),
                          controlPoint2: CGPoint(x: -length * 0.38, y: height * 0.28))
            path.addCurve(to: CGPoint(x: length * 0.18, y: height * 0.43),
                          controlPoint1: CGPoint(x: -length * 0.10, y: height * 0.50),
                          controlPoint2: CGPoint(x: length * 0.08, y: height * 0.48))
            path.addCurve(to: CGPoint(x: length * 0.42, y: height * 0.05),
                          controlPoint1: CGPoint(x: length * 0.33, y: height * 0.36),
                          controlPoint2: CGPoint(x: length * 0.41, y: height * 0.18))
            path.addCurve(to: CGPoint(x: length * 0.26, y: -height * 0.28),
                          controlPoint1: CGPoint(x: length * 0.43, y: -height * 0.12),
                          controlPoint2: CGPoint(x: length * 0.36, y: -height * 0.24))
            path.addCurve(to: CGPoint(x: -length * 0.32, y: -height * 0.27),
                          controlPoint1: CGPoint(x: length * 0.02, y: -height * 0.34),
                          controlPoint2: CGPoint(x: -length * 0.18, y: -height * 0.32))
            path.addCurve(to: CGPoint(x: -length * 0.45, y: -height * 0.06),
                          controlPoint1: CGPoint(x: -length * 0.42, y: -height * 0.23),
                          controlPoint2: CGPoint(x: -length * 0.47, y: -height * 0.16))
            return SKShapeNode(path: path.cgPath)
        case .diamond:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height * 0.54))
            path.addLine(to: CGPoint(x: length * 0.5, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -height * 0.54))
            path.close()
            return SKShapeNode(path: path.cgPath)
        case .ray:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.5, y: 0))
            path.addCurve(to: CGPoint(x: length * 0.5, y: 0),
                          controlPoint1: CGPoint(x: -length * 0.22, y: height * 0.84),
                          controlPoint2: CGPoint(x: length * 0.22, y: height * 0.84))
            path.addCurve(to: CGPoint(x: -length * 0.5, y: 0),
                          controlPoint1: CGPoint(x: length * 0.20, y: -height * 0.56),
                          controlPoint2: CGPoint(x: -length * 0.20, y: -height * 0.56))
            return SKShapeNode(path: path.cgPath)
        }
    }

    private static func tailShape(length: CGFloat,
                                  height: CGFloat,
                                  color: UIColor,
                                  silhouette: FishSilhouette) -> SKNode {
        let node = SKNode()
        switch silhouette {
        case .turtle:
            return node
        case .ray:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: -height * 0.03))
            path.addLine(to: CGPoint(x: -length * 0.92, y: -height * 0.2))
            let tail = SKShapeNode(path: path.cgPath)
            tail.strokeColor = color.withAlphaComponent(0.68)
            tail.lineWidth = max(2, height * 0.08)
            tail.fillColor = .clear
            node.addChild(tail)
        case .needle:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: height * 0.75))
            path.addLine(to: CGPoint(x: -length * 0.65, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: -height * 0.75))
            path.close()
            let tail = SKShapeNode(path: path.cgPath)
            tail.fillColor = color.withAlphaComponent(0.82)
            tail.strokeColor = .clear
            node.addChild(tail)
        default:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -length * 0.45, y: 0))
            path.addLine(to: CGPoint(x: -length * 0.75, y: height * 0.55))
            path.addLine(to: CGPoint(x: -length * 0.75, y: -height * 0.55))
            path.close()
            let tail = SKShapeNode(path: path.cgPath)
            tail.fillColor = color.withAlphaComponent(0.85)
            tail.strokeColor = .clear
            node.addChild(tail)
        }
        return node
    }

    private static func addFins(to node: SKNode,
                                length: CGFloat,
                                height: CGFloat,
                                color: UIColor,
                                silhouette: FishSilhouette) {
        guard silhouette != .ray && silhouette != .turtle else { return }

        let finPath = UIBezierPath()
        finPath.move(to: CGPoint(x: -length * 0.08, y: height * 0.36))
        finPath.addLine(to: CGPoint(x: length * 0.1, y: height * 0.74))
        finPath.addLine(to: CGPoint(x: length * 0.22, y: height * 0.24))
        finPath.close()
        let topFin = SKShapeNode(path: finPath.cgPath)
        topFin.fillColor = color.withAlphaComponent(0.54)
        topFin.strokeColor = .clear
        topFin.zPosition = -0.5
        node.addChild(topFin)

        let lower = SKShapeNode(ellipseOf: CGSize(width: length * 0.28, height: height * 0.28))
        lower.fillColor = color.withAlphaComponent(0.44)
        lower.strokeColor = .clear
        lower.position = CGPoint(x: length * 0.04, y: -height * 0.34)
        lower.zRotation = -0.35
        lower.zPosition = -0.4
        node.addChild(lower)
    }

    private static func addPattern(_ pattern: FishPattern,
                                   to node: SKNode,
                                   length: CGFloat,
                                   height: CGFloat,
                                   color: UIColor,
                                   silhouette: FishSilhouette,
                                   seed: String?) {
        func seeded(_ salt: Int) -> CGFloat {
            guard let seed else { return CGFloat.random(in: 0...1) }
            return stableUnit(for: seed, salt: salt)
        }

        switch pattern {
        case .plain:
            return
        case .stripes:
            for i in 0..<3 {
                let x = -length * 0.16 + CGFloat(i) * length * 0.13
                let path = UIBezierPath()
                path.move(to: CGPoint(x: x, y: height * 0.34))
                path.addLine(to: CGPoint(x: x - length * 0.05, y: -height * 0.34))
                let stripe = SKShapeNode(path: path.cgPath)
                stripe.strokeColor = UIColor.lerp(color, .white, 0.45).withAlphaComponent(0.42)
                stripe.lineWidth = max(1.2, height * 0.08)
                stripe.fillColor = .clear
                node.addChild(stripe)
            }
        case .spots:
            let count = seed.map { 3 + stableBucket(for: "\($0)|spots", modulo: 4) } ?? Int.random(in: 3...6)
            for i in 0..<count {
                let radiusFactor = 0.055 + seeded(101 + i) * 0.040
                let spot = SKShapeNode(circleOfRadius: max(1.8, height * radiusFactor))
                spot.fillColor = UIColor.lerp(color, .white, 0.5).withAlphaComponent(0.52)
                spot.strokeColor = .clear
                spot.position = CGPoint(x: -length * 0.2 + seeded(201 + i) * length * 0.45,
                                        y: -height * 0.22 + seeded(301 + i) * height * 0.44)
                node.addChild(spot)
            }
        case .glowDots:
            let count = seed.map { 3 + stableBucket(for: "\($0)|glow", modulo: 5) } ?? Int.random(in: 3...7)
            for i in 0..<count {
                let radiusFactor = 0.045 + seeded(401 + i) * 0.030
                let dot = SKShapeNode(circleOfRadius: max(2, height * radiusFactor))
                dot.fillColor = UIColor.lerp(color, .white, 0.72).withAlphaComponent(0.72)
                dot.strokeColor = .clear
                dot.glowWidth = 5
                dot.position = CGPoint(x: -length * 0.24 + seeded(501 + i) * length * 0.56,
                                       y: -height * 0.24 + seeded(601 + i) * height * 0.48)
                node.addChild(dot)
            }
        }

        if silhouette == .moon {
            let ring = SKShapeNode(ellipseOf: CGSize(width: length * 0.62, height: height * 0.82))
            ring.fillColor = .clear
            ring.strokeColor = UIColor.lerp(color, .white, 0.35).withAlphaComponent(0.26)
            ring.lineWidth = max(1.4, height * 0.04)
            node.addChild(ring)
        }
    }

    private static func addEye(to node: SKNode,
                               length: CGFloat,
                               height: CGFloat,
                               silhouette: FishSilhouette) {
        let eyeRadius = max(2.5, height * 0.1)
        let eye = SKShapeNode(circleOfRadius: eyeRadius)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = silhouette == .ray
            ? CGPoint(x: length * 0.12, y: height * 0.16)
            : CGPoint(x: length * 0.3, y: height * 0.12)
        node.addChild(eye)
        let pupil = SKShapeNode(circleOfRadius: max(1.2, eyeRadius * 0.5))
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = eye.position
        node.addChild(pupil)
    }

    private static func visualProfile(for species: AquaticSpecies) -> SpeciesVisualProfile {
        SpeciesVisualCatalog.profile(for: species)
    }

    static func addSpeciesTraits(to node: SKNode,
                                         species: AquaticSpecies?,
                                         length: CGFloat,
                                         height: CGFloat,
                                         color: UIColor,
                                         silhouette: FishSilhouette,
                                         animateTraits: Bool) {
        guard let species else { return }
        let visual = SpeciesVisualCatalog.profile(for: species)

        switch species.group {
        case .fish:
            addFishSpecificTraits(to: node, traits: visual.traits, length: length, height: height, color: color)
        case .shark:
            addDorsalFin(to: node, length: length, height: height, color: color)
            addGillMarks(to: node, length: length, height: height)
            if let count = visual.bodySpotCount {
                addBodySpots(to: node, length: length, height: height, color: color, count: count)
            }
        case .ray:
            if let count = visual.bodySpotCount {
                addBodySpots(to: node, length: length, height: height, color: color, count: count)
            }
        case .mammal:
            addMammalTraits(to: node, traits: visual.traits, length: length, height: height, color: color)
        case .reptile:
            if let style = visual.turtleShellStyle {
                addTurtleTraits(to: node,
                                shellStyle: style,
                                length: length,
                                height: height,
                                color: color,
                                animate: animateTraits)
            } else {
                addDorsalScutes(to: node, length: length, height: height, color: color)
            }
        case .crustacean, .arthropod:
            addCrustaceanTraits(to: node, hasClaws: visual.has(.claws), length: length, height: height, color: color)
        case .mollusk:
            addShellTraits(to: node, length: length, height: height, color: color)
        case .cephalopod:
            addCephalopodTraits(to: node, hasSquidFins: visual.has(.squidFins), length: length, height: height, color: color)
        case .cnidarian:
            addCnidarianTraits(to: node, length: length, height: height, color: color)
        case .echinoderm:
            addEchinodermTraits(to: node, hasSpines: visual.has(.urchinSpines), length: length, height: height, color: color)
        case .annelid:
            addSegmentBands(to: node, length: length, height: height, color: color)
        case .bird:
            addPenguinTraits(to: node, length: length, height: height, color: color)
        }

        if silhouette == .ray {
            addRayTailAccent(to: node, length: length, height: height, color: color)
        }
    }

    private static func addFishSpecificTraits(to node: SKNode,
                                              traits: [SpeciesVisualTrait],
                                              length: CGFloat,
                                              height: CGFloat,
                                              color: UIColor) {
        if traits.contains(.parrotBeak) {
            let beak = SKShapeNode(circleOfRadius: max(3, height * 0.13))
            beak.fillColor = UIColor(red: 0.45, green: 0.86, blue: 0.72, alpha: 1)
            beak.strokeColor = .clear
            beak.position = CGPoint(x: length * 0.44, y: 0)
            beak.zPosition = 4
            node.addChild(beak)
        }
        if traits.contains(.bill) {
            let bill = traitPath(points: [
                CGPoint(x: length * 0.46, y: 0),
                CGPoint(x: length * 0.76, y: height * 0.04)
            ], color: UIColor.lerp(color, .white, 0.35), width: max(2, height * 0.08))
            bill.zPosition = 4
            node.addChild(bill)
            addDorsalFin(to: node, length: length, height: height * 1.2, color: color)
        }
        if traits.contains(.moonFins) {
            let top = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.46),
                                   fill: color.withAlphaComponent(0.58))
            top.position = CGPoint(x: 0, y: height * 0.54)
            node.addChild(top)
            let bottom = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.46),
                                      fill: color.withAlphaComponent(0.48))
            bottom.position = CGPoint(x: 0, y: -height * 0.54)
            node.addChild(bottom)
        }
        if traits.contains(.teeth) {
            addTeeth(to: node, length: length, height: height)
        }
    }

    private static func addMammalTraits(to node: SKNode,
                                        traits: [SpeciesVisualTrait],
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor) {
        if traits.contains(.cetaceanFluke) {
            addDorsalFin(to: node, length: length, height: height, color: color)
            let fluke = traitPath(points: [
                CGPoint(x: -length * 0.55, y: 0),
                CGPoint(x: -length * 0.78, y: height * 0.42),
                CGPoint(x: -length * 0.66, y: 0),
                CGPoint(x: -length * 0.78, y: -height * 0.42)
            ], color: color.withAlphaComponent(0.72), width: max(2, height * 0.12))
            fluke.zPosition = 3
            node.addChild(fluke)
            if traits.contains(.orcaPatch) {
                let patch = traitEllipse(size: CGSize(width: length * 0.20, height: height * 0.26),
                                         fill: UIColor.white.withAlphaComponent(0.82))
                patch.position = CGPoint(x: length * 0.18, y: height * 0.18)
                patch.zPosition = 4
                node.addChild(patch)
            }
        } else {
            let whiskerY = height * 0.08
            for offset in [-0.06, 0.02, 0.10] as [CGFloat] {
                node.addChild(traitPath(points: [
                    CGPoint(x: length * 0.32, y: whiskerY + height * offset),
                    CGPoint(x: length * 0.54, y: whiskerY + height * (offset + 0.08))
                ], color: UIColor.white.withAlphaComponent(0.56), width: 1.2))
            }
            let flipper = traitEllipse(size: CGSize(width: length * 0.22, height: height * 0.18),
                                       fill: color.withAlphaComponent(0.50))
            flipper.position = CGPoint(x: length * 0.02, y: -height * 0.36)
            flipper.zRotation = -0.25
            node.addChild(flipper)
        }
    }

    private static func addTurtleTraits(to node: SKNode,
                                        shellStyle: TurtleShellStyle,
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor,
                                        animate: Bool) {
        let isLeatherback = shellStyle == .leatherback
        let isHawksbill = shellStyle == .hawksbill
        let shellFill = isLeatherback
            ? UIColor.lerp(color, .black, 0.12).withAlphaComponent(0.88)
            : UIColor.lerp(color, GameUI.gold, isHawksbill ? 0.30 : 0.18).withAlphaComponent(0.88)
        let skin = UIColor.lerp(color, .white, isHawksbill ? 0.10 : 0.04)
        let outline = UIColor.lerp(color, .black, 0.36).withAlphaComponent(0.58)

        func flipperNode(base: CGPoint,
                         points: [CGPoint],
                         alpha: CGFloat,
                         zPosition: CGFloat,
                         restAngle: CGFloat,
                         swing: CGFloat,
                         delay: TimeInterval) -> SKNode {
            let holder = SKNode()
            holder.position = base
            holder.zRotation = restAngle
            holder.zPosition = zPosition

            let path = UIBezierPath()
            if let first = points.first {
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.close()
            }

            let flipper = SKShapeNode(path: path.cgPath)
            flipper.fillColor = skin.withAlphaComponent(alpha)
            flipper.strokeColor = outline.withAlphaComponent(alpha + 0.08)
            flipper.lineWidth = max(1, height * 0.022)
            holder.addChild(flipper)

            if animate {
                let up = SKAction.rotate(toAngle: restAngle + swing, duration: 0.52)
                let down = SKAction.rotate(toAngle: restAngle - swing * 0.42, duration: 0.64)
                up.eaeInEaseOut()
                down.eaeInEaseOut()
                let flap = SKAction.repeatForever(.sequence([up, down]))
                holder.run(delay > 0 ? .sequence([.wait(forDuration: delay), flap]) : flap)
            }

            return holder
        }

        let backFrontFlipper = flipperNode(base: CGPoint(x: length * 0.12, y: -height * 0.04),
                                           points: [
                                               CGPoint(x: 0, y: 0),
                                               CGPoint(x: length * 0.16, y: -height * 0.08),
                                               CGPoint(x: length * 0.04, y: -height * 0.48),
                                               CGPoint(x: -length * 0.10, y: -height * 0.18)
                                           ],
                                           alpha: 0.34,
                                           zPosition: 0.8,
                                           restAngle: 0.18,
                                           swing: -0.22,
                                           delay: 0.32)
        node.addChild(backFrontFlipper)

        let rearFlipper = flipperNode(base: CGPoint(x: -length * 0.26, y: -height * 0.15),
                                      points: [
                                          CGPoint(x: 0, y: 0),
                                          CGPoint(x: -length * 0.23, y: -height * 0.06),
                                          CGPoint(x: -length * 0.20, y: -height * 0.30),
                                          CGPoint(x: length * 0.04, y: -height * 0.15)
                                      ],
                                      alpha: 0.48,
                                      zPosition: 1.2,
                                      restAngle: -0.06,
                                      swing: 0.16,
                                      delay: 0.18)
        node.addChild(rearFlipper)

        let frontFlipper = flipperNode(base: CGPoint(x: length * 0.17, y: -height * 0.13),
                                       points: [
                                           CGPoint(x: 0, y: 0),
                                           CGPoint(x: length * 0.20, y: -height * 0.11),
                                           CGPoint(x: length * 0.07, y: -height * 0.68),
                                           CGPoint(x: -length * 0.13, y: -height * 0.24)
                                       ],
                                       alpha: 0.76,
                                       zPosition: 4.8,
                                       restAngle: -0.16,
                                       swing: -0.36,
                                       delay: 0)
        node.addChild(frontFlipper)

        let tail = UIBezierPath()
        tail.move(to: CGPoint(x: -length * 0.43, y: height * 0.02))
        tail.addLine(to: CGPoint(x: -length * 0.59, y: 0))
        tail.addLine(to: CGPoint(x: -length * 0.43, y: -height * 0.10))
        tail.close()
        let tailNode = SKShapeNode(path: tail.cgPath)
        tailNode.fillColor = skin.withAlphaComponent(0.42)
        tailNode.strokeColor = .clear
        tailNode.zPosition = 1
        node.addChild(tailNode)

        var headParts: [SKNode] = []

        let neck = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.20),
                                fill: skin.withAlphaComponent(0.70))
        neck.position = CGPoint(x: length * 0.41, y: height * 0.01)
        neck.zRotation = 0.08
        neck.zPosition = 2
        node.addChild(neck)
        headParts.append(neck)

        let head = traitEllipse(size: CGSize(width: length * 0.23, height: height * 0.31),
                                fill: skin.withAlphaComponent(0.88))
        head.position = CGPoint(x: length * 0.54, y: height * 0.03)
        head.strokeColor = outline.withAlphaComponent(0.72)
        head.lineWidth = max(1, height * 0.025)
        head.zPosition = 4
        node.addChild(head)
        headParts.append(head)

        if isHawksbill {
            let beak = traitPath(points: [
                CGPoint(x: length * 0.62, y: height * 0.08),
                CGPoint(x: length * 0.70, y: height * 0.02),
                CGPoint(x: length * 0.62, y: -height * 0.03)
            ], color: outline.withAlphaComponent(0.56), width: max(1, height * 0.02))
            beak.zPosition = 5
            node.addChild(beak)
            headParts.append(beak)
        }

        let eye = SKShapeNode(circleOfRadius: max(1.5, height * 0.045))
        eye.fillColor = UIColor.white.withAlphaComponent(0.92)
        eye.strokeColor = .clear
        eye.position = CGPoint(x: length * 0.59, y: height * 0.12)
        eye.zPosition = 5
        node.addChild(eye)
        headParts.append(eye)

        let pupil = SKShapeNode(circleOfRadius: max(0.85, height * 0.022))
        pupil.fillColor = .black
        pupil.strokeColor = .clear
        pupil.position = CGPoint(x: length * 0.60, y: height * 0.12)
        pupil.zPosition = 6
        node.addChild(pupil)
        headParts.append(pupil)

        let mouth = traitPath(points: [
            CGPoint(x: length * 0.59, y: -height * 0.03),
            CGPoint(x: length * 0.65, y: -height * 0.06)
        ], color: outline.withAlphaComponent(0.45), width: max(1, height * 0.018))
        mouth.zPosition = 5
        node.addChild(mouth)
        headParts.append(mouth)

        let shellPath = UIBezierPath()
        shellPath.move(to: CGPoint(x: -length * 0.40, y: -height * 0.03))
        shellPath.addCurve(to: CGPoint(x: -length * 0.24, y: height * 0.35),
                           controlPoint1: CGPoint(x: -length * 0.39, y: height * 0.14),
                           controlPoint2: CGPoint(x: -length * 0.34, y: height * 0.28))
        shellPath.addCurve(to: CGPoint(x: length * 0.16, y: height * 0.39),
                           controlPoint1: CGPoint(x: -length * 0.08, y: height * 0.47),
                           controlPoint2: CGPoint(x: length * 0.07, y: height * 0.45))
        shellPath.addCurve(to: CGPoint(x: length * 0.36, y: height * 0.04),
                           controlPoint1: CGPoint(x: length * 0.30, y: height * 0.31),
                           controlPoint2: CGPoint(x: length * 0.36, y: height * 0.16))
        shellPath.addCurve(to: CGPoint(x: length * 0.25, y: -height * 0.13),
                           controlPoint1: CGPoint(x: length * 0.35, y: -height * 0.04),
                           controlPoint2: CGPoint(x: length * 0.31, y: -height * 0.10))
        shellPath.addCurve(to: CGPoint(x: -length * 0.31, y: -height * 0.15),
                           controlPoint1: CGPoint(x: length * 0.04, y: -height * 0.20),
                           controlPoint2: CGPoint(x: -length * 0.18, y: -height * 0.20))
        shellPath.addCurve(to: CGPoint(x: -length * 0.40, y: -height * 0.03),
                           controlPoint1: CGPoint(x: -length * 0.37, y: -height * 0.13),
                           controlPoint2: CGPoint(x: -length * 0.40, y: -height * 0.08))
        let shell = SKShapeNode(path: shellPath.cgPath)
        shell.fillColor = shellFill
        shell.strokeColor = outline
        shell.lineWidth = max(1.2, height * 0.035)
        shell.zPosition = 3
        node.addChild(shell)

        let centerRidge = traitPath(points: [
            CGPoint(x: -length * 0.28, y: height * 0.20),
            CGPoint(x: -length * 0.03, y: height * 0.32),
            CGPoint(x: length * 0.24, y: height * 0.15)
        ], color: UIColor.white.withAlphaComponent(isLeatherback ? 0.30 : 0.24), width: max(1, height * 0.024))
        centerRidge.zPosition = 4
        node.addChild(centerRidge)

        for x in [-0.20, -0.03, 0.14] as [CGFloat] {
            let plate = UIBezierPath()
            plate.move(to: CGPoint(x: length * x, y: height * 0.31))
            plate.addCurve(to: CGPoint(x: length * (x + 0.04), y: -height * 0.10),
                           controlPoint1: CGPoint(x: length * (x + 0.08), y: height * 0.20),
                           controlPoint2: CGPoint(x: length * (x + 0.08), y: height * 0.03))
            let plateNode = traitPath(path: plate,
                                      color: UIColor.white.withAlphaComponent(0.22),
                                      width: max(1, height * 0.022))
            plateNode.zPosition = 4
            node.addChild(plateNode)
        }

        let bellyLine = traitPath(points: [
            CGPoint(x: -length * 0.30, y: -height * 0.15),
            CGPoint(x: -length * 0.04, y: -height * 0.19),
            CGPoint(x: length * 0.25, y: -height * 0.13)
        ], color: UIColor.lerp(shellFill, .white, 0.26).withAlphaComponent(0.28), width: max(1.2, height * 0.035))
        bellyLine.zPosition = 4
        node.addChild(bellyLine)

        if isHawksbill {
            for point in [
                CGPoint(x: -length * 0.15, y: height * 0.18),
                CGPoint(x: length * 0.03, y: height * 0.02),
                CGPoint(x: length * 0.20, y: height * 0.14)
            ] {
                let blot = SKShapeNode(circleOfRadius: max(1.8, height * 0.050))
                blot.fillColor = UIColor.lerp(shellFill, GameUI.gold, 0.45).withAlphaComponent(0.42)
                blot.strokeColor = .clear
                blot.position = point
                blot.zPosition = 4
                node.addChild(blot)
            }
        }

        if animate {
            for part in headParts {
                let up = SKAction.moveBy(x: 0, y: height * 0.025, duration: 0.78)
                let down = SKAction.moveBy(x: 0, y: -height * 0.025, duration: 0.78)
                up.eaeInEaseOut()
                down.eaeInEaseOut()
                part.run(.repeatForever(.sequence([up, down])))
            }
        }
    }

    private static func addCrustaceanTraits(to node: SKNode,
                                            hasClaws: Bool,
                                            length: CGFloat,
                                            height: CGFloat,
                                            color: UIColor) {
        let legColor = UIColor.lerp(color, .black, 0.18).withAlphaComponent(0.70)
        for i in 0..<4 {
            let x = -length * 0.18 + CGFloat(i) * length * 0.12
            node.addChild(traitPath(points: [
                CGPoint(x: x, y: height * 0.30),
                CGPoint(x: x - length * 0.08, y: height * 0.62)
            ], color: legColor, width: max(1.2, height * 0.045)))
            node.addChild(traitPath(points: [
                CGPoint(x: x, y: -height * 0.30),
                CGPoint(x: x - length * 0.08, y: -height * 0.62)
            ], color: legColor, width: max(1.2, height * 0.045)))
        }
        if hasClaws {
            for side in [-1, 1] as [CGFloat] {
                let claw = traitEllipse(size: CGSize(width: length * 0.15, height: height * 0.22),
                                        fill: color.withAlphaComponent(0.75))
                claw.position = CGPoint(x: length * 0.38, y: side * height * 0.34)
                claw.zRotation = side * 0.46
                claw.zPosition = 4
                node.addChild(claw)
            }
        }
        for side in [-1, 1] as [CGFloat] {
            node.addChild(traitPath(points: [
                CGPoint(x: length * 0.30, y: side * height * 0.12),
                CGPoint(x: length * 0.58, y: side * height * 0.38)
            ], color: UIColor.white.withAlphaComponent(0.42), width: 1.1))
        }
    }

    private static func addCephalopodTraits(to node: SKNode,
                                            hasSquidFins: Bool,
                                            length: CGFloat,
                                            height: CGFloat,
                                            color: UIColor) {
        let armColor = UIColor.lerp(color, .white, 0.12).withAlphaComponent(0.70)
        let armCount = hasSquidFins ? 5 : 7
        for i in 0..<armCount {
            let t = CGFloat(i) / CGFloat(max(1, armCount - 1))
            let y = -height * 0.34 + t * height * 0.68
            let curve = UIBezierPath()
            curve.move(to: CGPoint(x: -length * 0.34, y: y * 0.45))
            curve.addCurve(to: CGPoint(x: -length * 0.66, y: y),
                           controlPoint1: CGPoint(x: -length * 0.46, y: y * 0.70 + sin(t * .pi) * height * 0.12),
                           controlPoint2: CGPoint(x: -length * 0.56, y: y * 1.08))
            let arm = traitPath(path: curve, color: armColor, width: max(1.4, height * 0.05))
            arm.zPosition = 4
            node.addChild(arm)
        }
        addBodySpots(to: node, length: length, height: height, color: color, count: 8)
        if hasSquidFins {
            let fin = traitEllipse(size: CGSize(width: length * 0.20, height: height * 0.42),
                                   fill: color.withAlphaComponent(0.44))
            fin.position = CGPoint(x: -length * 0.16, y: height * 0.42)
            fin.zRotation = 0.5
            node.addChild(fin)
        }
    }

    private static func addCnidarianTraits(to node: SKNode,
                                           length: CGFloat,
                                           height: CGFloat,
                                           color: UIColor) {
        let bell = traitEllipse(size: CGSize(width: length * 0.72, height: height * 0.54),
                                fill: UIColor.lerp(color, .white, 0.35).withAlphaComponent(0.34))
        bell.position = CGPoint(x: length * 0.02, y: height * 0.10)
        bell.zPosition = 4
        node.addChild(bell)
        for i in 0..<7 {
            let x = -length * 0.26 + CGFloat(i) * length * 0.085
            let curve = UIBezierPath()
            curve.move(to: CGPoint(x: x, y: -height * 0.22))
            curve.addCurve(to: CGPoint(x: x + sin(CGFloat(i)) * length * 0.05, y: -height * 0.92),
                           controlPoint1: CGPoint(x: x + length * 0.03, y: -height * 0.42),
                           controlPoint2: CGPoint(x: x - length * 0.04, y: -height * 0.62))
            node.addChild(traitPath(path: curve,
                                    color: UIColor.lerp(color, .white, 0.24).withAlphaComponent(0.55),
                                    width: 1.0))
        }
    }

    private static func addEchinodermTraits(to node: SKNode,
                                            hasSpines: Bool,
                                            length: CGFloat,
                                            height: CGFloat,
                                            color: UIColor) {
        if hasSpines {
            for i in 0..<12 {
                let angle = CGFloat(i) * .pi * 2 / 12
                node.addChild(traitPath(points: [
                    CGPoint(x: cos(angle) * length * 0.16, y: sin(angle) * height * 0.20),
                    CGPoint(x: cos(angle) * length * 0.34, y: sin(angle) * height * 0.42)
                ], color: UIColor.lerp(color, .black, 0.18), width: 1.1))
            }
        } else {
            let star = UIBezierPath()
            for i in 0..<10 {
                let angle = CGFloat(i) * .pi / 5
                let radius = i.isMultiple(of: 2) ? min(length, height) * 0.42 : min(length, height) * 0.18
                let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                i == 0 ? star.move(to: point) : star.addLine(to: point)
            }
            star.close()
            let starNode = SKShapeNode(path: star.cgPath)
            starNode.fillColor = color.withAlphaComponent(0.68)
            starNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
            starNode.lineWidth = 1
            starNode.zPosition = 5
            node.addChild(starNode)
        }
    }

    private static func addShellTraits(to node: SKNode,
                                       length: CGFloat,
                                       height: CGFloat,
                                       color: UIColor) {
        let shell = traitEllipse(size: CGSize(width: length * 0.72, height: height * 0.70),
                                 fill: UIColor.lerp(color, GameUI.gold, 0.20).withAlphaComponent(0.70))
        shell.strokeColor = UIColor.lerp(color, .black, 0.24).withAlphaComponent(0.46)
        shell.lineWidth = 1
        shell.zPosition = 4
        node.addChild(shell)
        for i in 0..<4 {
            let y = -height * 0.24 + CGFloat(i) * height * 0.16
            node.addChild(traitPath(points: [
                CGPoint(x: -length * 0.26, y: y),
                CGPoint(x: length * 0.24, y: y + height * 0.08)
            ], color: UIColor.white.withAlphaComponent(0.26), width: 1.0))
        }
    }

    private static func addPenguinTraits(to node: SKNode,
                                         length: CGFloat,
                                         height: CGFloat,
                                         color: UIColor) {
        let belly = traitEllipse(size: CGSize(width: length * 0.46, height: height * 0.72),
                                 fill: UIColor.white.withAlphaComponent(0.86))
        belly.position = CGPoint(x: length * 0.05, y: -height * 0.02)
        belly.zPosition = 4
        node.addChild(belly)
        for side in [-1, 1] as [CGFloat] {
            let wing = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.46),
                                    fill: color.withAlphaComponent(0.66))
            wing.position = CGPoint(x: -length * 0.04, y: side * height * 0.42)
            wing.zRotation = side * 0.28
            wing.zPosition = 2
            node.addChild(wing)
        }
    }

    private static func addDorsalFin(to node: SKNode,
                                     length: CGFloat,
                                     height: CGFloat,
                                     color: UIColor) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -length * 0.08, y: height * 0.36))
        path.addLine(to: CGPoint(x: length * 0.08, y: height * 0.90))
        path.addLine(to: CGPoint(x: length * 0.20, y: height * 0.32))
        path.close()
        let fin = SKShapeNode(path: path.cgPath)
        fin.fillColor = color.withAlphaComponent(0.62)
        fin.strokeColor = .clear
        fin.zPosition = 5
        node.addChild(fin)
    }

    private static func addGillMarks(to node: SKNode, length: CGFloat, height: CGFloat) {
        for i in 0..<4 {
            let x = length * 0.18 + CGFloat(i) * length * 0.035
            node.addChild(traitPath(points: [
                CGPoint(x: x, y: height * 0.23),
                CGPoint(x: x - length * 0.03, y: -height * 0.22)
            ], color: UIColor.white.withAlphaComponent(0.34), width: 1.1))
        }
    }

    private static func addDorsalScutes(to node: SKNode,
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor) {
        for i in 0..<6 {
            let x = -length * 0.28 + CGFloat(i) * length * 0.11
            let spike = traitPath(points: [
                CGPoint(x: x, y: height * 0.34),
                CGPoint(x: x + length * 0.04, y: height * 0.58),
                CGPoint(x: x + length * 0.08, y: height * 0.34)
            ], color: UIColor.lerp(color, .black, 0.2), width: 1.4)
            spike.zPosition = 4
            node.addChild(spike)
        }
    }

    private static func addSegmentBands(to node: SKNode,
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor) {
        for i in 0..<5 {
            let x = -length * 0.24 + CGFloat(i) * length * 0.12
            node.addChild(traitPath(points: [
                CGPoint(x: x, y: height * 0.28),
                CGPoint(x: x, y: -height * 0.28)
            ], color: UIColor.lerp(color, .white, 0.28).withAlphaComponent(0.42), width: 1.0))
        }
    }

    private static func addTeeth(to node: SKNode, length: CGFloat, height: CGFloat) {
        for i in 0..<4 {
            let tooth = traitPath(points: [
                CGPoint(x: length * 0.31 + CGFloat(i) * length * 0.035, y: height * 0.10),
                CGPoint(x: length * 0.34 + CGFloat(i) * length * 0.035, y: -height * 0.20)
            ], color: UIColor.white.withAlphaComponent(0.82), width: 1.2)
            tooth.zPosition = 6
            node.addChild(tooth)
        }
    }

    private static func addRayTailAccent(to node: SKNode,
                                         length: CGFloat,
                                         height: CGFloat,
                                         color: UIColor) {
        let barb = traitPath(points: [
            CGPoint(x: -length * 0.76, y: -height * 0.14),
            CGPoint(x: -length * 0.88, y: -height * 0.30)
        ], color: UIColor.lerp(color, .black, 0.18).withAlphaComponent(0.72), width: 1.4)
        barb.zPosition = 4
        node.addChild(barb)
    }

    private static func addBodySpots(to node: SKNode,
                                     length: CGFloat,
                                     height: CGFloat,
                                     color: UIColor,
                                     count: Int) {
        for i in 0..<count {
            let spot = SKShapeNode(circleOfRadius: max(1.6, height * 0.055))
            spot.fillColor = UIColor.lerp(color, .white, 0.58).withAlphaComponent(0.50)
            spot.strokeColor = .clear
            let t = CGFloat(i) / CGFloat(max(1, count - 1))
            spot.position = CGPoint(x: -length * 0.22 + t * length * 0.48,
                                    y: sin(t * .pi * 2.7) * height * 0.20)
            spot.zPosition = 5
            node.addChild(spot)
        }
    }

    private static func traitEllipse(size: CGSize, fill: UIColor) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: size)
        node.fillColor = fill
        node.strokeColor = .clear
        return node
    }

    private static func traitPath(points: [CGPoint], color: UIColor, width: CGFloat) -> SKShapeNode {
        let path = UIBezierPath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return traitPath(path: path, color: color, width: width)
    }

    private static func traitPath(path: UIBezierPath, color: UIColor, width: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(path: path.cgPath)
        node.fillColor = .clear
        node.strokeColor = color
        node.lineWidth = width
        node.lineCap = .round
        node.lineJoin = .round
        return node
    }
    static func makeGiverDisplayNode(length: CGFloat,
                                     height: CGFloat,
                                     color: UIColor,
                                     silhouette: FishSilhouette,
                                     pattern: FishPattern,
                                     species: AquaticSpecies?) -> SKNode {
        let displayPattern = species.map(SpeciesVisualCatalog.profile).flatMap(\.pattern) ?? pattern
        let drawing = fishDrawing(length: length,
                                  height: height,
                                  color: color,
                                  animateTail: true,
                                  silhouette: silhouette,
                                  pattern: displayPattern,
                                  patternSeed: species?.id)
        addSpeciesTraits(to: drawing,
                         species: species,
                         length: length,
                         height: height,
                         color: color,
                         silhouette: silhouette,
                         animateTraits: true)
        return drawing
    }

    static func makeSpeciesDisplayNode(species: AquaticSpecies,
                                       discovered: Bool,
                                       scale: CGFloat = 1) -> SKNode {
        let zone = species.preferredZones.first ?? .shallow
        let silhouette = discovered ? displaySilhouette(for: species) : .oval
        let profile = visualProfile(for: species)
        let length = discovered
            ? displayBodyLength(for: silhouette, species: species) * profile.lengthMultiplier
            : 54
        let height = discovered
            ? displayBodyHeight(for: silhouette, length: length)
            : 24
        let color = discovered
            ? profile.color
            : UIColor(red: 0.20, green: 0.28, blue: 0.34, alpha: 1)
        let drawing = fishDrawing(length: length,
                                  height: height,
                                  color: color,
                                  animateTail: false,
                                  silhouette: silhouette,
                                  pattern: discovered ? (profile.pattern ?? displayPattern(for: zone, species: species)) : .plain,
                                  patternSeed: discovered ? species.id : nil)
        if discovered {
            addSpeciesTraits(to: drawing,
                             species: species,
                             length: length,
                             height: height,
                             color: color,
                             silhouette: silhouette,
                             animateTraits: false)
        } else {
            drawing.alpha = 0.72
            let fog = SKShapeNode(ellipseOf: CGSize(width: length * 0.92, height: height * 1.16))
            fog.fillColor = UIColor.white.withAlphaComponent(0.08)
            fog.strokeColor = UIColor.white.withAlphaComponent(0.18)
            fog.lineWidth = 1
            fog.zPosition = 8
            drawing.addChild(fog)
        }
        drawing.setScale(scale)
        return drawing
    }

    private static func displaySilhouette(for species: AquaticSpecies) -> FishSilhouette {
        if let silhouette = SpeciesVisualCatalog.profile(for: species).silhouette {
            return silhouette
        }

        switch species.group {
        case .ray:
            return .ray
        case .shark, .mammal, .reptile, .bird:
            return .needle
        case .cephalopod, .cnidarian, .echinoderm, .mollusk, .annelid:
            return .moon
        case .crustacean, .arthropod:
            return .diamond
        case .fish:
            let choices: [FishSilhouette] = [.oval, .needle, .diamond, .moon]
            return choices[stableBucket(for: species.id, modulo: choices.count)]
        }
    }

    private static func displayPattern(for zone: DepthZone, species: AquaticSpecies) -> FishPattern {
        if let pattern = SpeciesVisualCatalog.profile(for: species).pattern {
            return pattern
        }
        if zone == .deep || zone == .abyss {
            return .glowDots
        }
        let choices: [FishPattern] = [.plain, .stripes, .spots]
        return choices[stableBucket(for: species.id, modulo: choices.count)]
    }

    private static func displayBodyLength(for silhouette: FishSilhouette, species: AquaticSpecies) -> CGFloat {
        switch species.group {
        case .mammal, .shark, .reptile:
            if silhouette == .turtle { return 78 }
            return silhouette == .needle ? 82 : 70
        case .crustacean, .mollusk, .echinoderm, .arthropod:
            return 46
        case .bird:
            return 58
        case .cephalopod, .cnidarian, .annelid:
            return 58
        case .fish, .ray:
            switch silhouette {
            case .oval: return 54
            case .needle: return 74
            case .diamond: return 52
            case .moon: return 56
            case .ray: return 78
            case .turtle: return 78
            }
        }
    }

    private static func displayBodyHeight(for silhouette: FishSilhouette, length: CGFloat) -> CGFloat {
        switch silhouette {
        case .oval:
            return length * 0.42
        case .needle:
            return length * 0.20
        case .diamond:
            return length * 0.62
        case .moon:
            return length * 0.66
        case .ray:
            return length * 0.40
        case .turtle:
            return length * 0.50
        }
    }

    private static func stableBucket(for id: String, modulo: Int) -> Int {
        guard modulo > 0 else { return 0 }
        let value = id.unicodeScalars.reduce(0) { partial, scalar in
            (partial &* 31 &+ Int(scalar.value)) & 0x7fffffff
        }
        return value % modulo
    }

    private static func stableUnit(for id: String, salt: Int) -> CGFloat {
        let value = stableBucket(for: "\(id)|\(salt)", modulo: 10_000)
        return CGFloat(value) / 9_999
    }


}
