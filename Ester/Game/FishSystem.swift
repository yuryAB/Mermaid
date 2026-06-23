//
//  FishSystem.swift
//  Ester
//
//  Peixes ambientais procedurais: vivem em rotas próprias, formam
//  cardumes, fogem da sereia e brilham nas zonas escuras.
//  Desenhados apenas com SKShapeNode.
//

import Foundation
import SpriteKit

fileprivate enum FishSilhouette: CaseIterable {
    case oval
    case needle
    case diamond
    case moon
    case ray

    static func random(for zone: DepthZone, rare: Bool, species: AquaticSpecies?) -> FishSilhouette {
        if let preferred = preferred(for: species) {
            return preferred
        }
        if let group = species?.group {
            switch group {
            case .ray:
                return .ray
            case .shark, .mammal, .reptile, .bird:
                return .needle
            case .cephalopod, .cnidarian, .echinoderm, .mollusk, .annelid:
                return .moon
            case .crustacean, .arthropod:
                return .diamond
            case .fish:
                break
            }
        }
        if rare {
            return [.moon, .ray, .diamond].randomElement()!
        }
        switch zone {
        case .surface, .clear:
            return [.needle, .oval, .diamond].randomElement()!
        case .shallow:
            return [.oval, .diamond, .moon].randomElement()!
        case .mid, .blue:
            return allCases.randomElement()!
        case .deep, .abyss:
            return [.needle, .ray, .moon, .diamond].randomElement()!
        }
    }

    private static func preferred(for species: AquaticSpecies?) -> FishSilhouette? {
        guard let species else { return nil }
        let id = species.id.lowercased()
        if id.contains("arraia") || id.contains("raia") || id.contains("manta") {
            return .ray
        }
        if id.contains("tubarao") || id.contains("barracuda") || id.contains("agulhao") ||
            id.contains("marlim") || id.contains("espadarte") || id.contains("enguia") ||
            id.contains("candiru") || id.contains("lula") || id.contains("sifonoforo") ||
            id.contains("anaconda") || id.contains("crocodilo") || id.contains("jacare") {
            return .needle
        }
        if id.contains("tartaruga") || id.contains("peixe_lua") || id.contains("polvo") ||
            id.contains("agua_viva") || id.contains("caravela") {
            return .moon
        }
        if id.contains("caranguejo") || id.contains("siri") || id.contains("lagosta") ||
            id.contains("camarao") || id.contains("krill") || id.contains("isopode") ||
            id.contains("anfipode") || id.contains("ourico") || id.contains("estrela") ||
            id.contains("pepino") || id.contains("ostra") || id.contains("mexilhao") ||
            id.contains("abalone") || id.contains("verme") {
            return .diamond
        }
        if id.contains("borboleta") || id.contains("anjo") || id.contains("cirurgiao") {
            return .diamond
        }
        return nil
    }
}

fileprivate enum FishPattern: CaseIterable {
    case plain
    case stripes
    case spots
    case glowDots

    static func random(for zone: DepthZone, rare: Bool, species: AquaticSpecies?) -> FishPattern {
        if let preferred = preferred(for: zone, species: species) {
            return preferred
        }
        if let group = species?.group {
            switch group {
            case .mammal, .reptile, .bird:
                return .plain
            case .cephalopod, .cnidarian:
                return zone == .deep || zone == .abyss ? .glowDots : .spots
            default:
                break
            }
        }
        if rare { return .glowDots }
        switch zone {
        case .surface, .clear:
            return [.plain, .stripes, .spots].randomElement()!
        case .shallow, .mid:
            return allCases.randomElement()!
        case .blue, .deep, .abyss:
            return [.plain, .spots, .glowDots].randomElement()!
        }
    }

    private static func preferred(for zone: DepthZone, species: AquaticSpecies?) -> FishPattern? {
        guard let species else { return nil }
        let id = species.id.lowercased()
        if id.contains("palhaco") || id.contains("borboleta") || id.contains("anjo") ||
            id.contains("leopardo") || id.contains("listrado") || id.contains("zebra") {
            return .stripes
        }
        if id.contains("pintado") || id.contains("chita") || id.contains("manta") ||
            id.contains("papagaio") || id.contains("estrela") || id.contains("polvo") ||
            id.contains("tartaruga") {
            return .spots
        }
        if zone == .deep || zone == .abyss ||
            id.contains("lanterna") || id.contains("dragao") || id.contains("vibora") ||
            id.contains("machado") || id.contains("ogro") || id.contains("gulper") {
            return .glowDots
        }
        return nil
    }
}

fileprivate enum FishMotionMode {
    case normal
    case guiding(target: CGPoint, until: Date)
    case gatheringForPlay(point: CGPoint, until: Date)
    case playing(center: CGPoint, until: Date)
}

// MARK: - Nó de peixe

final class FishNode: SKNode, ChallengeGiver {
    let zone: DepthZone
    let species: AquaticSpecies?
    var heading: CGFloat
    var baseSpeed: CGFloat
    var skittish: Bool
    var isRare = false

    /// Desafio oferecido por este peixe (nil = peixe comum).
    var offeredChallenge: ChallengeKind? {
        didSet {
            if offeredChallenge == nil {
                offeredChallengeGoal = nil
            }
            updateChallengeHighlight()
        }
    }
    var offeredChallengeGoal: Int?
    var isSpecialChallenge = false
    var worldPosition: CGPoint { position }
    var isCompanionBusy: Bool {
        switch motionMode {
        case .normal: return false
        case .guiding, .gatheringForPlay, .playing: return true
        }
    }
    var isAvailableForCompanionAction: Bool {
        offeredChallenge == nil && !isCompanionBusy
    }

    private var verticalPhase = CGFloat.random(in: 0...6)
    private var playPhase = CGFloat.random(in: 0...6)
    private var fleeTimer: CGFloat = 0
    private var motionMode: FishMotionMode = .normal
    private let container = SKNode()
    private var challengeHighlight: SKNode?

    // guardados para gerar a cópia visual do desafio
    private var bodyLength: CGFloat = 40
    private var bodyHeight: CGFloat = 18
    private var bodyColor: UIColor = .white

    private let paletteOverride: [UIColor]?
    private let silhouette: FishSilhouette
    private let pattern: FishPattern

    private struct SpeciesVisualProfile {
        let color: UIColor
        let pattern: FishPattern?
        let lengthMultiplier: CGFloat
    }

    init(zone: DepthZone, rare: Bool = false, palette: [UIColor]? = nil, species: AquaticSpecies? = nil) {
        self.zone = zone
        self.species = species
        self.heading = Bool.random() ? 0 : .pi
        self.baseSpeed = .random(in: 40...110)
        self.skittish = Bool.random()
        self.isRare = rare
        self.paletteOverride = palette
        self.silhouette = FishSilhouette.random(for: zone, rare: rare, species: species)
        self.pattern = FishPattern.random(for: zone, rare: rare, species: species)
        super.init()
        name = species.map { "animal_\($0.id)" } ?? "animal_generic"
        if rare {
            baseSpeed = .random(in: 120...170)
            skittish = false
        } else if species?.group == .mammal || species?.group == .shark || species?.group == .reptile {
            baseSpeed = .random(in: 70...130)
            skittish = false
        }
        buildShape()
        addChild(container)
        zPosition = CGFloat.random(in: 3...7)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildShape() {
        let visual = species.map(FishNode.visualProfile)
        let length = FishNode.bodyLength(for: silhouette, rare: isRare, species: species)
            * (visual?.lengthMultiplier ?? 1)
        let height = FishNode.bodyHeight(for: silhouette, length: length)
        let color = isRare
            ? UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1)
            : (visual?.color ?? (paletteOverride ?? FishNode.palette(for: zone)).randomElement()!)
        let resolvedPattern = visual.flatMap(\.pattern) ?? pattern

        bodyLength = length
        bodyHeight = height
        bodyColor = color

        let drawing = FishNode.fishDrawing(length: length, height: height, color: color,
                                           animateTail: true,
                                           silhouette: silhouette,
                                           pattern: resolvedPattern)
        FishNode.addSpeciesTraits(to: drawing,
                                  species: species,
                                  length: length,
                                  height: height,
                                  color: color,
                                  silhouette: silhouette)
        container.addChild(drawing)

        // brilho nas zonas escuras
        if zone == .deep || zone == .abyss || isRare {
            if let body = drawing.childNode(withName: "fish_body") as? SKShapeNode {
                body.glowWidth = isRare ? 14 : 8
                let pulse = SKAction.repeatForever(.sequence([
                    .fadeAlpha(to: 0.7, duration: 1.1),
                    .fadeAlpha(to: 1.0, duration: 1.1)
                ]))
                pulse.eaeInEaseOut()
                body.run(pulse)
            }
        }
    }

    /// Desenho do peixe (corpo, cauda, olho) reaproveitável para a cópia
    /// que fica em destaque no topo de um desafio.
    fileprivate static func fishDrawing(length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor,
                                        animateTail: Bool,
                                        silhouette: FishSilhouette = .oval,
                                        pattern: FishPattern = .plain) -> SKNode {
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

        addFins(to: node, length: length, height: height, color: color, silhouette: silhouette)
        addPattern(pattern, to: node, length: length, height: height, color: color, silhouette: silhouette)
        addEye(to: node, length: length, height: height, silhouette: silhouette)

        return node
    }

    private static func bodyLength(for silhouette: FishSilhouette, rare: Bool, species: AquaticSpecies?) -> CGFloat {
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
        }
    }

    private static func bodyHeight(for silhouette: FishSilhouette, length: CGFloat) -> CGFloat {
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
        }
    }

    private static func bodyShape(length: CGFloat,
                                  height: CGFloat,
                                  silhouette: FishSilhouette) -> SKShapeNode {
        switch silhouette {
        case .oval, .needle, .moon:
            return SKShapeNode(ellipseOf: CGSize(width: length, height: height))
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
        guard silhouette != .ray else { return }

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
                                   silhouette: FishSilhouette) {
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
            for _ in 0..<Int.random(in: 3...6) {
                let spot = SKShapeNode(circleOfRadius: max(1.8, height * CGFloat.random(in: 0.055...0.095)))
                spot.fillColor = UIColor.lerp(color, .white, 0.5).withAlphaComponent(0.52)
                spot.strokeColor = .clear
                spot.position = CGPoint(x: CGFloat.random(in: -length * 0.2...length * 0.25),
                                        y: CGFloat.random(in: -height * 0.22...height * 0.22))
                node.addChild(spot)
            }
        case .glowDots:
            for _ in 0..<Int.random(in: 3...7) {
                let dot = SKShapeNode(circleOfRadius: max(2, height * CGFloat.random(in: 0.045...0.075)))
                dot.fillColor = UIColor.lerp(color, .white, 0.72).withAlphaComponent(0.72)
                dot.strokeColor = .clear
                dot.glowWidth = 5
                dot.position = CGPoint(x: CGFloat.random(in: -length * 0.24...length * 0.32),
                                       y: CGFloat.random(in: -height * 0.24...height * 0.24))
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
        let id = species.id.lowercased()
        let color: UIColor
        let pattern: FishPattern?
        let lengthMultiplier: CGFloat

        switch species.group {
        case .fish:
            if id.contains("palhaco") {
                color = UIColor(red: 0.94, green: 0.42, blue: 0.16, alpha: 1)
                pattern = .stripes
            } else if id.contains("cirurgiao") || id.contains("rockfish_azul") {
                color = UIColor(red: 0.12, green: 0.48, blue: 0.86, alpha: 1)
                pattern = .plain
            } else if id.contains("papagaio") || id.contains("dourado") || id.contains("tambaqui") {
                color = UIColor(red: 0.30, green: 0.72, blue: 0.42, alpha: 1)
                pattern = .spots
            } else if id.contains("borboleta") || id.contains("anjo") || id.contains("garibaldi") {
                color = UIColor(red: 0.95, green: 0.67, blue: 0.24, alpha: 1)
                pattern = .stripes
            } else if id.contains("piranha") || id.contains("salm") {
                color = UIColor(red: 0.78, green: 0.42, blue: 0.34, alpha: 1)
                pattern = .spots
            } else if id.contains("lanterna") || id.contains("dragao") || id.contains("vibora") ||
                        id.contains("machado") || id.contains("ogro") || id.contains("gulper") {
                color = UIColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1)
                pattern = .glowDots
            } else if id.contains("atum") || id.contains("bonito") || id.contains("cavala") ||
                        id.contains("sardinha") || id.contains("arenque") {
                color = UIColor(red: 0.42, green: 0.58, blue: 0.72, alpha: 1)
                pattern = .plain
            } else {
                color = UIColor(red: 0.50, green: 0.72, blue: 0.76, alpha: 1)
                pattern = nil
            }
            lengthMultiplier = id.contains("agulhao") || id.contains("marlim") || id.contains("espadarte") ? 1.24 : 1
        case .shark:
            color = id.contains("baleia")
                ? UIColor(red: 0.34, green: 0.48, blue: 0.58, alpha: 1)
                : UIColor(red: 0.36, green: 0.48, blue: 0.54, alpha: 1)
            pattern = id.contains("leopardo") || id.contains("baleia") ? .spots : .plain
            lengthMultiplier = id.contains("baleia") || id.contains("frade") ? 1.32 : 1.16
        case .ray:
            color = UIColor(red: 0.43, green: 0.58, blue: 0.62, alpha: 1)
            pattern = id.contains("chita") || id.contains("manta") ? .spots : .plain
            lengthMultiplier = id.contains("manta") ? 1.28 : 1.08
        case .mammal:
            if id.contains("boto") {
                color = UIColor(red: 0.86, green: 0.54, blue: 0.58, alpha: 1)
            } else if id.contains("orca") {
                color = UIColor(red: 0.10, green: 0.13, blue: 0.16, alpha: 1)
            } else if id.contains("lontra") {
                color = UIColor(red: 0.38, green: 0.25, blue: 0.18, alpha: 1)
            } else {
                color = UIColor(red: 0.48, green: 0.56, blue: 0.60, alpha: 1)
            }
            pattern = id.contains("pintado") ? .spots : .plain
            lengthMultiplier = id.contains("baleia") || id.contains("cachalote") ? 1.42 : 1.18
        case .reptile:
            color = id.contains("couro")
                ? UIColor(red: 0.20, green: 0.22, blue: 0.24, alpha: 1)
                : UIColor(red: 0.37, green: 0.55, blue: 0.34, alpha: 1)
            pattern = .spots
            lengthMultiplier = id.contains("anaconda") || id.contains("crocodilo") || id.contains("jacare") ? 1.38 : 1.05
        case .crustacean, .arthropod:
            color = id.contains("azul")
                ? UIColor(red: 0.18, green: 0.48, blue: 0.76, alpha: 1)
                : UIColor(red: 0.74, green: 0.34, blue: 0.26, alpha: 1)
            pattern = id.contains("vidro") ? .plain : .spots
            lengthMultiplier = id.contains("gigante") ? 1.22 : 0.92
        case .mollusk:
            color = UIColor(red: 0.66, green: 0.56, blue: 0.42, alpha: 1)
            pattern = .stripes
            lengthMultiplier = 0.9
        case .cephalopod:
            color = id.contains("vampiro")
                ? UIColor(red: 0.32, green: 0.10, blue: 0.18, alpha: 1)
                : UIColor(red: 0.24, green: 0.62, blue: 0.66, alpha: 1)
            pattern = .spots
            lengthMultiplier = id.contains("gigante") || id.contains("colossal") ? 1.36 : 1.06
        case .cnidarian:
            color = UIColor(red: 0.74, green: 0.56, blue: 0.86, alpha: 1)
            pattern = .glowDots
            lengthMultiplier = id.contains("gigante") ? 1.24 : 0.95
        case .echinoderm:
            color = id.contains("azul")
                ? UIColor(red: 0.14, green: 0.54, blue: 0.82, alpha: 1)
                : UIColor(red: 0.85, green: 0.55, blue: 0.20, alpha: 1)
            pattern = .spots
            lengthMultiplier = 0.82
        case .annelid:
            color = UIColor(red: 0.76, green: 0.25, blue: 0.22, alpha: 1)
            pattern = .stripes
            lengthMultiplier = 1.0
        case .bird:
            color = UIColor(red: 0.10, green: 0.16, blue: 0.22, alpha: 1)
            pattern = .plain
            lengthMultiplier = 1.0
        }

        return SpeciesVisualProfile(color: color,
                                    pattern: pattern,
                                    lengthMultiplier: lengthMultiplier)
    }

    private static func addSpeciesTraits(to node: SKNode,
                                         species: AquaticSpecies?,
                                         length: CGFloat,
                                         height: CGFloat,
                                         color: UIColor,
                                         silhouette: FishSilhouette) {
        guard let species else { return }
        let id = species.id.lowercased()

        switch species.group {
        case .fish:
            addFishSpecificTraits(to: node, id: id, length: length, height: height, color: color)
        case .shark:
            addDorsalFin(to: node, length: length, height: height, color: color)
            addGillMarks(to: node, length: length, height: height)
            if id.contains("baleia") || id.contains("leopardo") {
                addBodySpots(to: node, length: length, height: height, color: color, count: id.contains("baleia") ? 12 : 7)
            }
        case .ray:
            addBodySpots(to: node, length: length, height: height, color: color, count: id.contains("manta") ? 6 : 9)
        case .mammal:
            addMammalTraits(to: node, id: id, length: length, height: height, color: color)
        case .reptile:
            if id.contains("tartaruga") {
                addTurtleTraits(to: node, length: length, height: height, color: color)
            } else {
                addDorsalScutes(to: node, length: length, height: height, color: color)
            }
        case .crustacean, .arthropod:
            addCrustaceanTraits(to: node, id: id, length: length, height: height, color: color)
        case .mollusk:
            addShellTraits(to: node, length: length, height: height, color: color)
        case .cephalopod:
            addCephalopodTraits(to: node, id: id, length: length, height: height, color: color)
        case .cnidarian:
            addCnidarianTraits(to: node, length: length, height: height, color: color)
        case .echinoderm:
            addEchinodermTraits(to: node, id: id, length: length, height: height, color: color)
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
                                              id: String,
                                              length: CGFloat,
                                              height: CGFloat,
                                              color: UIColor) {
        if id.contains("papagaio") {
            let beak = SKShapeNode(circleOfRadius: max(3, height * 0.13))
            beak.fillColor = UIColor(red: 0.45, green: 0.86, blue: 0.72, alpha: 1)
            beak.strokeColor = .clear
            beak.position = CGPoint(x: length * 0.44, y: 0)
            beak.zPosition = 4
            node.addChild(beak)
        }
        if id.contains("agulhao") || id.contains("marlim") || id.contains("espadarte") {
            let bill = traitPath(points: [
                CGPoint(x: length * 0.46, y: 0),
                CGPoint(x: length * 0.76, y: height * 0.04)
            ], color: UIColor.lerp(color, .white, 0.35), width: max(2, height * 0.08))
            bill.zPosition = 4
            node.addChild(bill)
            addDorsalFin(to: node, length: length, height: height * 1.2, color: color)
        }
        if id.contains("peixe_lua") {
            let top = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.46),
                                   fill: color.withAlphaComponent(0.58))
            top.position = CGPoint(x: 0, y: height * 0.54)
            node.addChild(top)
            let bottom = traitEllipse(size: CGSize(width: length * 0.18, height: height * 0.46),
                                      fill: color.withAlphaComponent(0.48))
            bottom.position = CGPoint(x: 0, y: -height * 0.54)
            node.addChild(bottom)
        }
        if id.contains("vibora") || id.contains("ogro") || id.contains("dragao") {
            addTeeth(to: node, length: length, height: height)
        }
    }

    private static func addMammalTraits(to node: SKNode,
                                        id: String,
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor) {
        if id.contains("baleia") || id.contains("golfinho") || id.contains("orca") ||
            id.contains("boto") || id.contains("cachalote") || id.contains("tucuxi") {
            addDorsalFin(to: node, length: length, height: height, color: color)
            let fluke = traitPath(points: [
                CGPoint(x: -length * 0.55, y: 0),
                CGPoint(x: -length * 0.78, y: height * 0.42),
                CGPoint(x: -length * 0.66, y: 0),
                CGPoint(x: -length * 0.78, y: -height * 0.42)
            ], color: color.withAlphaComponent(0.72), width: max(2, height * 0.12))
            fluke.zPosition = 3
            node.addChild(fluke)
            if id.contains("orca") {
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
                                        length: CGFloat,
                                        height: CGFloat,
                                        color: UIColor) {
        let shell = traitEllipse(size: CGSize(width: length * 0.72, height: height * 0.78),
                                 fill: UIColor.lerp(color, GameUI.gold, 0.18).withAlphaComponent(0.62))
        shell.strokeColor = UIColor.lerp(color, .black, 0.28).withAlphaComponent(0.48)
        shell.lineWidth = 1
        shell.zPosition = 3
        node.addChild(shell)
        for x in [-0.18, 0, 0.18] as [CGFloat] {
            let line = traitPath(points: [
                CGPoint(x: length * x, y: height * 0.32),
                CGPoint(x: length * x * 0.4, y: -height * 0.32)
            ], color: UIColor.white.withAlphaComponent(0.26), width: 1.2)
            line.zPosition = 4
            node.addChild(line)
        }
        for spec in [
            CGPoint(x: -length * 0.12, y: height * 0.50),
            CGPoint(x: length * 0.12, y: height * 0.50),
            CGPoint(x: -length * 0.18, y: -height * 0.48),
            CGPoint(x: length * 0.18, y: -height * 0.48)
        ] {
            let flipper = traitEllipse(size: CGSize(width: length * 0.20, height: height * 0.13),
                                       fill: color.withAlphaComponent(0.48))
            flipper.position = spec
            flipper.zRotation = spec.y > 0 ? 0.28 : -0.28
            flipper.zPosition = 1
            node.addChild(flipper)
        }
    }

    private static func addCrustaceanTraits(to node: SKNode,
                                            id: String,
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
        if id.contains("caranguejo") || id.contains("siri") || id.contains("lagosta") {
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
                                            id: String,
                                            length: CGFloat,
                                            height: CGFloat,
                                            color: UIColor) {
        let armColor = UIColor.lerp(color, .white, 0.12).withAlphaComponent(0.70)
        let armCount = id.contains("lula") ? 5 : 7
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
        if id.contains("lula") {
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
                                            id: String,
                                            length: CGFloat,
                                            height: CGFloat,
                                            color: UIColor) {
        if id.contains("ourico") {
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

    /// Cópia visual estática deste peixe, para o cabeçalho do desafio.
    func makeGiverDisplayNode() -> SKNode {
        let displayPattern = species.map(FishNode.visualProfile).flatMap(\.pattern) ?? pattern
        let drawing = FishNode.fishDrawing(length: bodyLength, height: bodyHeight,
                                           color: bodyColor,
                                           animateTail: true,
                                           silhouette: silhouette,
                                           pattern: displayPattern)
        FishNode.addSpeciesTraits(to: drawing,
                                  species: species,
                                  length: bodyLength,
                                  height: bodyHeight,
                                  color: bodyColor,
                                  silhouette: silhouette)
        return drawing
    }

    static func makeSpeciesDisplayNode(species: AquaticSpecies,
                                       discovered: Bool,
                                       scale: CGFloat = 1) -> SKNode {
        let zone = species.preferredZones.first ?? .shallow
        let silhouette = FishSilhouette.random(for: zone, rare: false, species: species)
        let profile = visualProfile(for: species)
        let length = bodyLength(for: silhouette, rare: false, species: species) * profile.lengthMultiplier
        let height = bodyHeight(for: silhouette, length: length)
        let color = discovered
            ? profile.color
            : UIColor(red: 0.20, green: 0.28, blue: 0.34, alpha: 1)
        let drawing = fishDrawing(length: length,
                                  height: height,
                                  color: color,
                                  animateTail: false,
                                  silhouette: silhouette,
                                  pattern: discovered ? (profile.pattern ?? FishPattern.random(for: zone, rare: false, species: species)) : .plain)
        if discovered {
            addSpeciesTraits(to: drawing,
                             species: species,
                             length: length,
                             height: height,
                             color: color,
                             silhouette: silhouette)
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

    func startGuiding(toward target: CGPoint, duration: TimeInterval) {
        motionMode = .guiding(target: target, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func gatherForPlay(at point: CGPoint, duration: TimeInterval) {
        motionMode = .gatheringForPlay(point: point, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func startPlaying(around center: CGPoint, duration: TimeInterval) {
        motionMode = .playing(center: center, until: Date().addingTimeInterval(duration))
        fleeTimer = 0
    }

    func resumeNaturalSwimming() {
        motionMode = .normal
    }

    /// Anel dourado pulsante indicando que este peixe oferece um desafio.
    private func updateChallengeHighlight() {
        challengeHighlight?.removeFromParent()
        challengeHighlight = nil
        guard offeredChallenge != nil else { return }

        let radius = bodyLength * 0.85
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.fillColor = UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0.07)
        ring.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.45, alpha: 0.9)
        ring.lineWidth = 2.5
        ring.glowWidth = 10
        ring.zPosition = -1
        addChild(ring)
        ring.run(.repeatForever(.sequence([
            .group([.scale(to: 1.18, duration: 0.8), .fadeAlpha(to: 0.55, duration: 0.8)]),
            .group([.scale(to: 1.0, duration: 0.8), .fadeAlpha(to: 1.0, duration: 0.8)])
        ])))

        let badge = SKLabelNode(text: "❗️")
        badge.fontSize = 20
        badge.position = CGPoint(x: 0, y: radius + 14)
        ring.addChild(badge)
        challengeHighlight = ring
    }

    static func palette(for zone: DepthZone) -> [UIColor] {
        switch zone {
        case .surface:
            return [UIColor(red: 0.75, green: 0.8, blue: 0.85, alpha: 1),
                    UIColor(red: 0.6, green: 0.7, blue: 0.8, alpha: 1)]
        case .clear:
            return [UIColor(red: 0.95, green: 0.85, blue: 0.5, alpha: 1),
                    UIColor(red: 0.75, green: 0.9, blue: 0.95, alpha: 1),
                    UIColor(red: 0.6, green: 0.85, blue: 0.7, alpha: 1)]
        case .shallow:
            return [UIColor(red: 0.95, green: 0.8, blue: 0.4, alpha: 1),
                    UIColor(red: 0.7, green: 0.85, blue: 0.9, alpha: 1),
                    UIColor(red: 0.55, green: 0.8, blue: 0.6, alpha: 1)]
        case .mid:
            return [UIColor(red: 0.4, green: 0.55, blue: 0.8, alpha: 1),
                    UIColor(red: 0.6, green: 0.65, blue: 0.75, alpha: 1),
                    UIColor(red: 0.5, green: 0.75, blue: 0.85, alpha: 1)]
        case .blue:
            return [UIColor(red: 0.35, green: 0.5, blue: 0.85, alpha: 1),
                    UIColor(red: 0.45, green: 0.6, blue: 0.8, alpha: 1)]
        case .deep:
            return [UIColor(red: 0.35, green: 0.45, blue: 0.7, alpha: 1),
                    UIColor(red: 0.45, green: 0.7, blue: 0.75, alpha: 1)]
        case .abyss:
            return [UIColor(red: 0.5, green: 0.4, blue: 0.7, alpha: 1),
                    UIColor(red: 0.3, green: 0.55, blue: 0.65, alpha: 1)]
        }
    }

    func update(dt: CGFloat, mermaidPosition: CGPoint) {
        defer {
            container.xScale = cos(heading) >= 0 ? 1 : -1
        }
        if updateCompanionMotion(dt: dt, mermaidPosition: mermaidPosition) {
            return
        }

        // ruído suave de direção
        heading += CGFloat.random(in: -0.5...0.5) * dt * 2

        var speed = baseSpeed
        if offeredChallenge != nil {
            // peixes com desafio esperam a sereia: nadam devagar e não fogem
            speed = min(baseSpeed, 45)
        } else if fleeTimer > 0 {
            fleeTimer -= dt
            speed = baseSpeed * 2.6
        } else if skittish && position.distance(to: mermaidPosition) < 160 {
            heading = atan2(position.y - mermaidPosition.y, position.x - mermaidPosition.x)
            fleeTimer = 2
        }

        verticalPhase += dt * 2
        position.x += cos(heading) * speed * dt
        position.y += sin(heading) * speed * dt * 0.4 + sin(verticalPhase) * 10 * dt

        // mantém o peixe dentro da própria camada
        let range = zone.yRange
        if position.y > range.upperBound - 60 || position.y < range.lowerBound + 60 {
            heading = -heading
            position.y = position.y.clamped(to: (range.lowerBound + 60)...(range.upperBound - 60))
        }
        if position.x > World.maxX || position.x < World.minX {
            heading = .pi - heading
            position.x = position.x.clamped(to: World.minX...World.maxX)
        }
    }

    private func updateCompanionMotion(dt: CGFloat, mermaidPosition: CGPoint) -> Bool {
        switch motionMode {
        case .normal:
            return false
        case .guiding(let target, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updateGuidingMotion(dt: dt, mermaidPosition: mermaidPosition, target: target)
            return true
        case .gatheringForPlay(let point, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updateGatheringMotion(dt: dt, mermaidPosition: mermaidPosition, point: point)
            return true
        case .playing(let center, let until):
            guard Date() < until else {
                motionMode = .normal
                return false
            }
            updatePlayingMotion(dt: dt, center: center)
            return true
        }
    }

    private func updateGuidingMotion(dt: CGFloat, mermaidPosition: CGPoint, target: CGPoint) {
        verticalPhase += dt * CGFloat(2)
        playPhase += dt * CGFloat(0.9)

        let remaining = mermaidPosition.distance(to: target)
        let desired: CGPoint
        if remaining < CGFloat(280) {
            let orbitX = cos(playPhase) * CGFloat(120)
            let orbitY = sin(playPhase * CGFloat(0.8)) * CGFloat(70)
            desired = CGPoint(x: target.x + orbitX,
                              y: target.y + orbitY)
        } else {
            let dx = target.x - mermaidPosition.x
            let dy = target.y - mermaidPosition.y
            let rawDistance = sqrt(dx * dx + dy * dy)
            let distance = max(CGFloat(1), rawDistance)
            let farFromMermaid = position.distance(to: mermaidPosition) > CGFloat(620)
            let lead: CGFloat = farFromMermaid ? CGFloat(220) : CGFloat(320)
            let unitX = dx / distance
            let unitY = dy / distance
            let desiredX = mermaidPosition.x + unitX * lead
            let desiredY = mermaidPosition.y + unitY * lead
            desired = CGPoint(x: desiredX, y: desiredY)
        }

        let guideSpeed = max(CGFloat(150), baseSpeed * CGFloat(1.35))
        swimToward(desired, speed: guideSpeed, dt: dt, bob: CGFloat(4))
        keepGuidingLead(from: mermaidPosition, toward: target)
    }

    private func keepGuidingLead(from mermaidPosition: CGPoint, toward target: CGPoint) {
        let dx = target.x - mermaidPosition.x
        let dy = target.y - mermaidPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > CGFloat(1) else { return }

        let unitX = dx / distance
        let unitY = dy / distance
        let offsetX = position.x - mermaidPosition.x
        let offsetY = position.y - mermaidPosition.y
        let forwardLead = offsetX * unitX + offsetY * unitY
        let minimumLead = CGFloat(220)
        guard forwardLead < minimumLead else { return }

        let sideOffset = (offsetX * -unitY + offsetY * unitX).clamped(to: -CGFloat(90)...CGFloat(90))
        position.x = mermaidPosition.x + unitX * minimumLead - unitY * sideOffset
        position.y = mermaidPosition.y + unitY * minimumLead + unitX * sideOffset
        heading = atan2(unitY, unitX)
        clampToWorldAndZone()
    }

    private func updateGatheringMotion(dt: CGFloat, mermaidPosition: CGPoint, point: CGPoint) {
        verticalPhase += dt * CGFloat(1.2)
        let distance = position.distance(to: point)
        if distance > CGFloat(32) {
            swimToward(point, speed: CGFloat(58), dt: dt, bob: CGFloat(2))
        } else {
            heading = atan2(mermaidPosition.y - position.y, mermaidPosition.x - position.x)
            position.y += sin(verticalPhase) * CGFloat(2) * dt
            clampToWorldAndZone()
        }
    }

    private func updatePlayingMotion(dt: CGFloat, center: CGPoint) {
        verticalPhase += dt * CGFloat(2.4)
        playPhase += dt * CGFloat(1.7)
        let orbitX = cos(playPhase) * CGFloat(90)
        let orbitY = sin(playPhase * CGFloat(1.2)) * CGFloat(54)
        let desired = CGPoint(x: center.x + orbitX,
                              y: center.y + orbitY)
        swimToward(desired, speed: CGFloat(92), dt: dt, bob: CGFloat(3))
    }

    private func swimToward(_ point: CGPoint, speed: CGFloat, dt: CGFloat, bob: CGFloat) {
        let dx = point.x - position.x
        let dy = point.y - position.y
        let rawDistance = sqrt(dx * dx + dy * dy)
        let distance = max(CGFloat(1), rawDistance)
        heading = atan2(dy, dx)
        let step = min(distance, speed * dt)
        position.x += dx / distance * step
        position.y += dy / distance * step + sin(verticalPhase) * bob * dt
        clampToWorldAndZone()
    }

    private func clampToWorldAndZone() {
        let range = zone.yRange
        position.x = position.x.clamped(to: World.minX...World.maxX)
        position.y = position.y.clamped(to: (range.lowerBound + 60)...(range.upperBound - 60))
    }
}

// MARK: - Sistema

final class FishSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private(set) var fishes: [FishNode] = []
    private var spawnTimer: CGFloat = 1

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    private func desiredCount(for zone: DepthZone) -> Int {
        switch zone {
        case .surface: return 5
        case .clear: return 8
        case .shallow: return 9
        case .mid: return 8
        case .blue: return 7
        case .deep: return 5
        case .abyss: return 4
        }
    }

    func update(dt: CGFloat) {
        let mermaidPos = ctx.mermaidPosition
        for fish in fishes {
            fish.update(dt: dt, mermaidPosition: mermaidPos)
        }
        fishes.removeAll { fish in
            if fish.position.distance(to: mermaidPos) > 3600 {
                fish.removeFromParent()
                return true
            }
            return false
        }

        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = .random(in: 1.4...3.4)
            let zone = DepthZone.zone(atY: mermaidPos.y)
            let nearby = fishes.filter { $0.zone == zone }.count
            if nearby < desiredCount(for: zone) {
                if Int.random(in: 0..<10) < 4 {
                    spawnSchool(zone: zone, near: mermaidPos)
                } else {
                    spawnFish(zone: zone, near: mermaidPos)
                }
            }
        }
    }

    @discardableResult
    func spawnFish(zone: DepthZone, near point: CGPoint, rare: Bool = false) -> FishNode? {
        guard let world = worldNode else { return nil }
        let region = ctx.regions.currentRegion
        let regionPalette = region.flatMap { RegionDiscoverySystem.fishPalette(for: $0.id) }
        let species = region.flatMap { RegionDiscoverySystem.randomSpecies(for: $0.id, zone: zone) }
        let fish = FishNode(zone: zone, rare: rare, palette: regionPalette, species: species)
        let range = zone.yRange
        let yRange = (range.lowerBound + 80)...(range.upperBound - 80)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 780...1500)
        let spawnPosition = CGPoint(
            x: (point.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (point.y + sin(angle) * distance).clamped(to: yRange)
        )
        fish.position = spawnPosition
        fish.alpha = 0
        fish.run(.fadeIn(withDuration: 0.8))
        world.addChild(fish)
        fishes.append(fish)
        ctx.challenges?.decorateSpawn(fish)
        return fish
    }

    private func spawnSchool(zone: DepthZone, near point: CGPoint) {
        guard let leader = spawnFish(zone: zone, near: point) else { return }
        let count = Int.random(in: 3...6)
        for _ in 0..<count {
            guard let member = spawnFish(zone: zone, near: point) else { continue }
            let range = (zone.yRange.lowerBound + 80)...(zone.yRange.upperBound - 80)
            let candidate = leader.position + CGPoint(x: .random(in: -120...120),
                                                      y: .random(in: -80...80))
            let xRange = ctx.activeRegion?.playableXRange ?? (World.minX...World.maxX)
            member.position = CGPoint(x: candidate.x.clamped(to: xRange),
                                      y: candidate.y.clamped(to: range))
            member.heading = leader.heading
            member.baseSpeed = leader.baseSpeed * CGFloat.random(in: 0.9...1.1)
            member.skittish = leader.skittish
        }
    }

    func nearestFish(to point: CGPoint, maxDistance: CGFloat, includeBusy: Bool = false) -> FishNode? {
        fishes
            .filter {
                (includeBusy || $0.isAvailableForCompanionAction)
                    && $0.position.distance(to: point) <= maxDistance
            }
            .min { $0.position.distance(to: point) < $1.position.distance(to: point) }
    }

    /// Reação do peixe quando a sereia interage: um giro alegre + bolhinhas.
    func interact(_ fish: FishNode) {
        let circle = SKAction.sequence([
            .rotate(byAngle: .pi * 2, duration: 0.8),
            .rotate(toAngle: 0, duration: 0.1)
        ])
        circle.eaeInEaseOut()
        fish.run(circle)

        let sparkle = SKShapeNode(circleOfRadius: 4)
        sparkle.fillColor = .white
        sparkle.strokeColor = .clear
        sparkle.glowWidth = 6
        sparkle.position = fish.position + CGPoint(x: 0, y: 40)
        fish.parent?.addChild(sparkle)
        sparkle.run(.sequence([
            .group([.moveBy(x: 0, y: 60, duration: 0.9), .fadeOut(withDuration: 0.9)]),
            .removeFromParent()
        ]))
        fish.heading = fish.heading + .pi
    }
}
