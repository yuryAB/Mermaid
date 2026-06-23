//
//  WorldPOINode.swift
//  Ester
//

import SpriteKit
import UIKit

final class WorldPOINode: SKNode {
    private enum VisualStyle: Equatable {
        case object
        case npc
        case environment
        case warmCurrentEnvironment

        var shouldBobInWorld: Bool {
            switch self {
            case .npc: return true
            case .object, .environment, .warmCurrentEnvironment: return false
            }
        }
    }

    let poiKey: String

    private let artwork: SKNode
    private let title: SKLabelNode
    private let collectedMark: SKLabelNode
    private let baseColor: UIColor
    private let normalScale: CGFloat
    private let visualStyle: VisualStyle

    init(poi: WorldPOI, discovered: Bool, rewardCollected: Bool, focused: Bool) {
        let style = Self.visualStyle(for: poi)
        poiKey = poi.key
        baseColor = poi.visual.color
        visualStyle = style
        normalScale = Self.normalScale(for: poi, style: style)
        artwork = WorldPOIArtworkFactory.makeArtwork(for: poi, size: .world)
        title = SKLabelNode(text: Self.shortTitle(poi.name))
        collectedMark = SKLabelNode(text: "✓")

        super.init()

        name = "world_poi_\(poi.key)"
        isUserInteractionEnabled = false
        zPosition = visualStyle == .warmCurrentEnvironment ? -6 : 8
        setScale(normalScale)

        artwork.zPosition = 2
        addChild(artwork)

        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = visualStyle == .warmCurrentEnvironment ? 13 : 11
        title.fontColor = UIColor.white.withAlphaComponent(0.86)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = visualStyle == .warmCurrentEnvironment ? CGPoint(x: 0, y: -78) : CGPoint(x: 0, y: -47)
        title.zPosition = visualStyle == .warmCurrentEnvironment ? 8 : 2
        addChild(title)

        collectedMark.fontName = "AvenirNext-Bold"
        collectedMark.fontSize = visualStyle == .warmCurrentEnvironment ? 18 : 16
        collectedMark.fontColor = GameUI.gold
        collectedMark.verticalAlignmentMode = .center
        collectedMark.horizontalAlignmentMode = .center
        collectedMark.position = visualStyle == .warmCurrentEnvironment ? CGPoint(x: 126, y: 49) : CGPoint(x: 26, y: 24)
        collectedMark.zPosition = visualStyle == .warmCurrentEnvironment ? 9 : 4
        addChild(collectedMark)

        if visualStyle.shouldBobInWorld {
            let bob = SKAction.repeatForever(.sequence([
                .moveBy(x: 0, y: 5, duration: 1.35),
                .moveBy(x: 0, y: -5, duration: 1.45)
            ]))
            bob.eaeInEaseOut()
            run(bob, withKey: "poi_bob")
        }

        update(discovered: discovered, rewardCollected: rewardCollected, focused: focused)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(discovered: Bool, rewardCollected: Bool, focused: Bool) {
        if visualStyle == .warmCurrentEnvironment {
            alpha = discovered ? 0.96 : 0.86
        } else {
            alpha = discovered ? (rewardCollected ? 0.72 : 1.0) : 0.38
        }
        title.isHidden = !discovered
        collectedMark.isHidden = visualStyle == .warmCurrentEnvironment || !rewardCollected

        if focused {
            if action(forKey: "poi_focus") == nil {
                let focusedScale = visualStyle == .warmCurrentEnvironment ? normalScale * 1.035 : normalScale * 1.11
                let pulse = SKAction.repeatForever(.sequence([
                    .scale(to: focusedScale, duration: 0.45),
                    .scale(to: normalScale, duration: 0.55)
                ]))
                pulse.eaeInEaseOut()
                run(pulse, withKey: "poi_focus")
            }
        } else {
            removeAction(forKey: "poi_focus")
            setScale(normalScale)
        }
    }

    private static func shortTitle(_ text: String) -> String {
        guard text.count > 26 else { return text }
        let end = text.index(text.startIndex, offsetBy: 23)
        return "\(text[..<end])..."
    }

    private static func visualStyle(for poi: WorldPOI) -> VisualStyle {
        if poi.key == "jardim_calmo_shallow_warm_current",
           poi.visualConcept == .environment {
            return .warmCurrentEnvironment
        }
        switch poi.visualConcept {
        case .object: return .object
        case .npc: return .npc
        case .environment: return .environment
        }
    }

    private static func normalScale(for poi: WorldPOI, style: VisualStyle) -> CGFloat {
        switch style {
        case .object:
            return (poi.visual.scale * 1.62).clamped(to: 1.20...2.10)
        case .npc:
            return (poi.visual.scale * 1.70).clamped(to: 1.25...2.18)
        case .environment:
            return (poi.visual.scale * 1.55).clamped(to: 1.20...2.05)
        case .warmCurrentEnvironment:
            return (poi.visual.scale * 1.0).clamped(to: 0.90...1.20)
        }
    }
}

enum WorldPOIArtworkSize {
    case world
    case challenge
    case mapSmall
    case listSmall

    var scale: CGFloat {
        switch self {
        case .world: return 1
        case .challenge: return 0.78
        case .mapSmall: return 0.14
        case .listSmall: return 0.20
        }
    }
}

enum WorldPOIArtworkFactory {
    private static var miniTextureCache: [String: SKTexture] = [:]
    private static let miniTextureSide: CGFloat = 96

    static func makeArtwork(for poi: WorldPOI, size: WorldPOIArtworkSize) -> SKNode {
        switch size {
        case .mapSmall, .listSmall:
            return makeMiniArtwork(for: poi, size: size)
        case .world, .challenge:
            break
        }

        let node: SKNode
        switch poi.key {
        case "nascente_shallow_abandoned_egg_nest":
            node = makeAbandonedEggNest(tint: poi.visual.color)
        case "nascente_shallow_baby_fish_school":
            node = makeBabyFishSchool(tint: poi.visual.color)
        case "nascente_shallow_music_shell":
            node = makeMusicShell(tint: poi.visual.color)
        case "nascente_mid_small_shipwreck":
            node = makeSmallShipwreck(tint: poi.visual.color)
        case "jardim_calmo_mid_old_turtle":
            node = makeOldTurtle(tint: poi.visual.color)
        case "jardim_calmo_shallow_warm_current":
            node = makeWarmCurrent(tint: poi.visual.color)
        case "jardim_calmo_shallow_touch_plant":
            node = makeTouchPlant(tint: poi.visual.color)
        case "jardim_calmo_shallow_color_fish":
            node = makeColorFish(tint: poi.visual.color)
        case "jardim_calmo_shallow_bubble_cloud":
            node = makeBubbleCloud(tint: poi.visual.color)
        case "jardim_calmo_mid_algae_ruin":
            node = makeAlgaeRuin(tint: poi.visual.color)
        case "jardim_calmo_mid_hidden_baby_octopus":
            node = makeHiddenBabyOctopus(tint: poi.visual.color)
        case "jardim_calmo_mid_sleeping_elder":
            node = makeSleepingElder(tint: poi.visual.color)
        default:
            node = makeFallback(kind: poi.kind, tint: poi.visual.color)
        }

        node.setScale(size.scale)
        node.name = "poi_art_\(poi.key)"
        return node
    }

    static func makeTemporaryCompanionArtwork(title: String) -> SKNode {
        let lower = title.lowercased()
        let node: SKNode
        if lower.contains("polvo") {
            node = makeCompanionOctopus(tint: UIColor(red: 0.68, green: 0.50, blue: 0.92, alpha: 1))
        } else if lower.contains("cardume") {
            node = makeFollowingFishSchool(tint: GameUI.accent)
        } else {
            node = makeColorFish(tint: GameUI.accent)
        }
        node.setScale(lower.contains("cardume") ? 0.82 : 0.66)
        node.name = "temporary_companion_art"
        return node
    }

    static func applyInteractionName(_ name: String?, to node: SKNode) {
        node.name = name
        for child in node.children {
            applyInteractionName(name, to: child)
        }
    }

    private static func makeMiniArtwork(for poi: WorldPOI, size: WorldPOIArtworkSize) -> SKNode {
        let texture = miniTexture(for: poi)
        let sprite = SKSpriteNode(texture: texture)
        let side: CGFloat
        switch size {
        case .mapSmall:
            side = 14
        case .listSmall:
            side = 20
        case .world, .challenge:
            side = 18
        }
        sprite.size = CGSize(width: side, height: side)
        sprite.name = "poi_mini_art_\(poi.key)"
        return sprite
    }

    private static func miniTexture(for poi: WorldPOI) -> SKTexture {
        let cacheKey = "mini-\(poi.key)"
        if let cached = miniTextureCache[cacheKey] { return cached }

        let image = renderMiniIcon(for: poi)
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        miniTextureCache[cacheKey] = texture
        return texture
    }

    private static func renderMiniIcon(for poi: WorldPOI) -> UIImage {
        let size = CGSize(width: miniTextureSide, height: miniTextureSide)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 2

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            context.cgContext.setLineCap(.round)
            context.cgContext.setLineJoin(.round)

            let tint = poi.visual.color
            if poi.key != "jardim_calmo_shallow_warm_current" {
                drawMiniBackdrop(tint: tint)
            }

            switch poi.key {
            case "nascente_shallow_abandoned_egg_nest":
                drawMiniIconEggNest(tint: tint)
            case "nascente_shallow_baby_fish_school":
                drawMiniIconFishSchool(tint: tint)
            case "nascente_shallow_music_shell":
                drawMiniIconShell(tint: tint)
            case "nascente_mid_small_shipwreck":
                drawMiniIconToyBoat(tint: tint)
            case "jardim_calmo_mid_old_turtle":
                drawMiniIconTurtle(tint: tint)
            case "jardim_calmo_shallow_warm_current":
                drawMiniIconCurrent(tint: tint)
            case "jardim_calmo_shallow_touch_plant":
                drawMiniIconPlant(tint: tint)
            case "jardim_calmo_shallow_color_fish":
                drawMiniIconColorFish(tint: tint)
            case "jardim_calmo_shallow_bubble_cloud":
                drawMiniIconBubbleCloud(tint: tint)
            case "jardim_calmo_mid_algae_ruin":
                drawMiniIconRuin(tint: tint)
            case "jardim_calmo_mid_hidden_baby_octopus":
                drawMiniIconOctopus(tint: tint)
            case "jardim_calmo_mid_sleeping_elder":
                drawMiniIconSleepingElder(tint: tint)
            default:
                drawMiniIconFallback(kind: poi.kind, tint: tint)
            }
        }
    }

    private static func drawMiniBackdrop(tint: UIColor) {
        drawMiniEllipse(center: CGPoint(x: 48, y: 50),
                        size: CGSize(width: 78, height: 72),
                        fill: tint.withAlphaComponent(0.10),
                        stroke: UIColor.white.withAlphaComponent(0.10),
                        lineWidth: 1)
    }

    private static func drawMiniIconEggNest(tint: UIColor) {
        drawMiniEllipse(center: CGPoint(x: 48, y: 61),
                        size: CGSize(width: 58, height: 20),
                        fill: UIColor(red: 0.48, green: 0.36, blue: 0.22, alpha: 0.88),
                        stroke: tint.withAlphaComponent(0.42),
                        lineWidth: 2)
        drawMiniEllipse(center: CGPoint(x: 37, y: 45),
                        size: CGSize(width: 16, height: 25),
                        fill: UIColor.lerp(tint, .white, 0.70),
                        stroke: UIColor.white.withAlphaComponent(0.58),
                        lineWidth: 1.3,
                        rotation: -0.18)
        drawMiniEllipse(center: CGPoint(x: 52, y: 41),
                        size: CGSize(width: 17, height: 27),
                        fill: UIColor(red: 0.92, green: 0.86, blue: 0.68, alpha: 1),
                        stroke: UIColor.white.withAlphaComponent(0.58),
                        lineWidth: 1.3,
                        rotation: 0.08)
        drawMiniEllipse(center: CGPoint(x: 63, y: 47),
                        size: CGSize(width: 14, height: 23),
                        fill: UIColor.lerp(GameUI.palePaper, tint, 0.18),
                        stroke: UIColor.white.withAlphaComponent(0.50),
                        lineWidth: 1.1,
                        rotation: 0.2)
    }

    private static func drawMiniIconFishSchool(tint: UIColor) {
        drawMiniFish(center: CGPoint(x: 33, y: 41),
                     length: 32,
                     height: 14,
                     color: tint,
                     striped: false,
                     rotation: -0.08)
        drawMiniFish(center: CGPoint(x: 52, y: 55),
                     length: 29,
                     height: 13,
                     color: GameUI.gold,
                     striped: false,
                     rotation: 0.12)
        drawMiniFish(center: CGPoint(x: 65, y: 40),
                     length: 30,
                     height: 13,
                     color: GameUI.coral,
                     striped: false,
                     rotation: -0.14)
    }

    private static func drawMiniIconShell(tint: UIColor) {
        let shellColor = UIColor.lerp(GameUI.gold, tint, 0.25)
        drawMiniShell(center: CGPoint(x: 48, y: 50),
                      width: 60,
                      height: 45,
                      color: shellColor)
        drawMiniEllipse(center: CGPoint(x: 48, y: 55),
                        size: CGSize(width: 11, height: 11),
                        fill: UIColor.white.withAlphaComponent(0.82),
                        stroke: tint.withAlphaComponent(0.42),
                        lineWidth: 1)
    }

    private static func drawMiniIconToyBoat(tint: UIColor) {
        let wood = UIColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 0.94)
        let hull = UIBezierPath()
        hull.move(to: CGPoint(x: 13, y: 55))
        hull.addLine(to: CGPoint(x: 29, y: 72))
        hull.addLine(to: CGPoint(x: 68, y: 70))
        hull.addLine(to: CGPoint(x: 82, y: 53))
        hull.addCurve(to: CGPoint(x: 13, y: 55),
                      controlPoint1: CGPoint(x: 60, y: 62),
                      controlPoint2: CGPoint(x: 33, y: 64))
        drawMiniPath(hull,
                     fill: UIColor.lerp(wood, tint, 0.18),
                     stroke: UIColor.black.withAlphaComponent(0.22),
                     lineWidth: 1.6)

        for index in 0..<3 {
            drawMiniLine(from: CGPoint(x: 30, y: 57 + CGFloat(index) * 5),
                         to: CGPoint(x: 66, y: 56 + CGFloat(index) * 4),
                         color: UIColor.lerp(wood, .white, CGFloat(index) * 0.06).withAlphaComponent(0.70),
                         width: 2.2)
        }

        drawMiniLine(from: CGPoint(x: 44, y: 64),
                     to: CGPoint(x: 40, y: 21),
                     color: wood.withAlphaComponent(0.88),
                     width: 3)

        let sail = UIBezierPath()
        sail.move(to: CGPoint(x: 42, y: 24))
        sail.addLine(to: CGPoint(x: 67, y: 43))
        sail.addLine(to: CGPoint(x: 43, y: 47))
        sail.close()
        drawMiniPath(sail,
                     fill: UIColor.lerp(tint, .white, 0.38).withAlphaComponent(0.48),
                     stroke: UIColor.white.withAlphaComponent(0.38),
                     lineWidth: 1.1)
    }

    private static func drawMiniIconTurtle(tint: UIColor) {
        let skin = UIColor(red: 0.50, green: 0.68, blue: 0.45, alpha: 0.92)
        drawMiniEllipse(center: CGPoint(x: 29, y: 61),
                        size: CGSize(width: 25, height: 12),
                        fill: skin.withAlphaComponent(0.72),
                        stroke: .clear,
                        rotation: 0.38)
        drawMiniEllipse(center: CGPoint(x: 60, y: 62),
                        size: CGSize(width: 25, height: 12),
                        fill: skin.withAlphaComponent(0.72),
                        stroke: .clear,
                        rotation: -0.38)
        drawMiniEllipse(center: CGPoint(x: 48, y: 49),
                        size: CGSize(width: 58, height: 39),
                        fill: UIColor.lerp(GameUI.algae, tint, 0.24),
                        stroke: UIColor.white.withAlphaComponent(0.34),
                        lineWidth: 1.6)
        drawMiniEllipse(center: CGPoint(x: 75, y: 47),
                        size: CGSize(width: 21, height: 18),
                        fill: skin,
                        stroke: UIColor.white.withAlphaComponent(0.20),
                        lineWidth: 1)
        drawMiniEllipse(center: CGPoint(x: 76, y: 45),
                        size: CGSize(width: 4, height: 4),
                        fill: UIColor.black.withAlphaComponent(0.72),
                        stroke: .clear)
    }

    private static func drawMiniIconCurrent(tint: UIColor) {
        let warm = UIColor.lerp(GameUI.coral, tint, 0.18)
        let lane = UIBezierPath()
        lane.move(to: CGPoint(x: 7, y: 63))
        lane.addCurve(to: CGPoint(x: 90, y: 55),
                      controlPoint1: CGPoint(x: 29, y: 48),
                      controlPoint2: CGPoint(x: 62, y: 68))
        lane.addCurve(to: CGPoint(x: 87, y: 34),
                      controlPoint1: CGPoint(x: 93, y: 48),
                      controlPoint2: CGPoint(x: 93, y: 41))
        lane.addCurve(to: CGPoint(x: 8, y: 42),
                      controlPoint1: CGPoint(x: 61, y: 48),
                      controlPoint2: CGPoint(x: 31, y: 30))
        lane.addCurve(to: CGPoint(x: 7, y: 63),
                      controlPoint1: CGPoint(x: 5, y: 49),
                      controlPoint2: CGPoint(x: 4, y: 56))
        drawMiniPath(lane,
                     fill: warm.withAlphaComponent(0.16),
                     stroke: GameUI.gold.withAlphaComponent(0.28),
                     lineWidth: 1.4)

        let colors = [GameUI.coral, UIColor.lerp(GameUI.gold, tint, 0.15), tint]
        for index in 0..<4 {
            let y = 38 + CGFloat(index) * 6.5
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 10, y: y + 7))
            path.addCurve(to: CGPoint(x: 88, y: y - 4),
                          controlPoint1: CGPoint(x: 30, y: y - 13),
                          controlPoint2: CGPoint(x: 64, y: y + 14))
            drawMiniPath(path,
                         fill: .clear,
                         stroke: colors[index % colors.count].withAlphaComponent(0.82),
                         lineWidth: 3.2)
        }

        for point in [CGPoint(x: 25, y: 48), CGPoint(x: 49, y: 38), CGPoint(x: 69, y: 55)] {
            drawMiniEllipse(center: point,
                            size: CGSize(width: 5, height: 5),
                            fill: UIColor.lerp(GameUI.gold, .white, 0.18).withAlphaComponent(0.70),
                            stroke: .clear)
        }
    }

    private static func drawMiniIconPlant(tint: UIColor) {
        let stem = UIColor.lerp(GameUI.algae, tint, 0.18)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 48, y: 77))
        path.addCurve(to: CGPoint(x: 51, y: 30),
                      controlPoint1: CGPoint(x: 38, y: 60),
                      controlPoint2: CGPoint(x: 61, y: 48))
        drawMiniPath(path, fill: .clear, stroke: stem, lineWidth: 4)

        drawMiniLeaf(center: CGPoint(x: 34, y: 59),
                     size: CGSize(width: 13, height: 28),
                     color: GameUI.algae.withAlphaComponent(0.86),
                     rotation: -0.8)
        drawMiniLeaf(center: CGPoint(x: 61, y: 52),
                     size: CGSize(width: 12, height: 24),
                     color: UIColor.lerp(GameUI.algae, tint, 0.10).withAlphaComponent(0.82),
                     rotation: 0.72)

        for index in 0..<6 {
            let angle = CGFloat(index) * .pi / 3
            drawMiniEllipse(center: CGPoint(x: 50 + cos(angle) * 10, y: 25 + sin(angle) * 10),
                            size: CGSize(width: 14, height: 22),
                            fill: UIColor.lerp(tint, .white, 0.22).withAlphaComponent(0.86),
                            stroke: UIColor.white.withAlphaComponent(0.24),
                            lineWidth: 0.8,
                            rotation: angle)
        }
        drawMiniEllipse(center: CGPoint(x: 50, y: 25),
                        size: CGSize(width: 10, height: 10),
                        fill: GameUI.gold,
                        stroke: UIColor.white.withAlphaComponent(0.35),
                        lineWidth: 0.8)
    }

    private static func drawMiniIconColorFish(tint: UIColor) {
        drawMiniFish(center: CGPoint(x: 50, y: 49),
                     length: 65,
                     height: 30,
                     color: UIColor.lerp(GameUI.coral, tint, 0.20),
                     striped: true,
                     rotation: -0.03)
    }

    private static func drawMiniIconBubbleCloud(tint: UIColor) {
        let bubbles: [(CGPoint, CGFloat)] = [
            (CGPoint(x: 30, y: 58), 8),
            (CGPoint(x: 46, y: 47), 12),
            (CGPoint(x: 64, y: 57), 7),
            (CGPoint(x: 68, y: 38), 9),
            (CGPoint(x: 37, y: 31), 6),
            (CGPoint(x: 53, y: 25), 5)
        ]
        for bubble in bubbles {
            drawMiniEllipse(center: bubble.0,
                            size: CGSize(width: bubble.1 * 2, height: bubble.1 * 2),
                            fill: tint.withAlphaComponent(0.08),
                            stroke: UIColor.lerp(tint, .white, 0.58).withAlphaComponent(0.62),
                            lineWidth: 1.6)
            drawMiniEllipse(center: CGPoint(x: bubble.0.x - bubble.1 * 0.3,
                                            y: bubble.0.y - bubble.1 * 0.3),
                            size: CGSize(width: max(2, bubble.1 * 0.35), height: max(2, bubble.1 * 0.35)),
                            fill: UIColor.white.withAlphaComponent(0.55),
                            stroke: .clear)
        }
    }

    private static func drawMiniIconRuin(tint: UIColor) {
        let stone = UIColor(red: 0.34, green: 0.34, blue: 0.42, alpha: 0.94)
        drawMiniRoundedRect(center: CGPoint(x: 30, y: 56),
                            size: CGSize(width: 14, height: 48),
                            radius: 3,
                            fill: stone,
                            stroke: UIColor.white.withAlphaComponent(0.18),
                            lineWidth: 1)
        drawMiniRoundedRect(center: CGPoint(x: 66, y: 58),
                            size: CGSize(width: 14, height: 44),
                            radius: 3,
                            fill: UIColor.lerp(stone, .black, 0.08),
                            stroke: UIColor.white.withAlphaComponent(0.16),
                            lineWidth: 1)
        drawMiniRoundedRect(center: CGPoint(x: 48, y: 30),
                            size: CGSize(width: 56, height: 13),
                            radius: 3,
                            fill: UIColor.lerp(stone, .white, 0.10),
                            stroke: tint.withAlphaComponent(0.32),
                            lineWidth: 1.2)
        drawMiniLine(from: CGPoint(x: 23, y: 31),
                     to: CGPoint(x: 20, y: 54),
                     color: GameUI.algae.withAlphaComponent(0.76),
                     width: 2)
        drawMiniLine(from: CGPoint(x: 75, y: 31),
                     to: CGPoint(x: 70, y: 60),
                     color: GameUI.algae.withAlphaComponent(0.66),
                     width: 2)
    }

    private static func drawMiniIconOctopus(tint: UIColor) {
        let bodyColor = UIColor.lerp(tint, GameUI.coral, 0.28)
        for index in 0..<5 {
            let x = 31 + CGFloat(index) * 8.5
            drawMiniLine(from: CGPoint(x: x, y: 58),
                         to: CGPoint(x: x + CGFloat(index - 2) * 2.5, y: 77),
                         color: bodyColor.withAlphaComponent(0.78),
                         width: 5)
        }
        drawMiniEllipse(center: CGPoint(x: 48, y: 43),
                        size: CGSize(width: 43, height: 37),
                        fill: bodyColor,
                        stroke: UIColor.white.withAlphaComponent(0.30),
                        lineWidth: 1.2)
        for x in [40, 56] {
            drawMiniEllipse(center: CGPoint(x: CGFloat(x), y: 40),
                            size: CGSize(width: 7, height: 7),
                            fill: UIColor.white.withAlphaComponent(0.90),
                            stroke: .clear)
            drawMiniEllipse(center: CGPoint(x: CGFloat(x) + 1, y: 40.5),
                            size: CGSize(width: 3, height: 3),
                            fill: UIColor.black.withAlphaComponent(0.80),
                            stroke: .clear)
        }
    }

    private static func drawMiniIconSleepingElder(tint: UIColor) {
        drawMiniEllipse(center: CGPoint(x: 39, y: 40),
                        size: CGSize(width: 20, height: 28),
                        fill: UIColor.lerp(GameUI.gold, tint, 0.44).withAlphaComponent(0.86),
                        stroke: .clear,
                        rotation: 0.55)
        drawMiniEllipse(center: CGPoint(x: 49, y: 55),
                        size: CGSize(width: 40, height: 22),
                        fill: UIColor.lerp(tint, GameUI.algae, 0.24).withAlphaComponent(0.84),
                        stroke: UIColor.white.withAlphaComponent(0.22),
                        lineWidth: 1,
                        rotation: -0.2)
        drawMiniEllipse(center: CGPoint(x: 36, y: 40),
                        size: CGSize(width: 18, height: 18),
                        fill: UIColor(red: 0.83, green: 0.66, blue: 0.58, alpha: 1),
                        stroke: UIColor.white.withAlphaComponent(0.20),
                        lineWidth: 0.8)
        drawMiniEllipse(center: CGPoint(x: 24, y: 23),
                        size: CGSize(width: 13, height: 13),
                        fill: GameUI.gold.withAlphaComponent(0.66),
                        stroke: UIColor.white.withAlphaComponent(0.25),
                        lineWidth: 0.8)
    }

    private static func drawMiniIconFallback(kind: WorldPOIKind, tint: UIColor) {
        switch kind {
        case .shipwreck:
            drawMiniIconToyBoat(tint: tint)
        case .npc:
            drawMiniIconTurtle(tint: tint)
        case .minigame:
            drawMiniIconShell(tint: tint)
        case .pet:
            drawMiniIconFishSchool(tint: tint)
        case .story:
            drawMiniIconRuin(tint: tint)
        }
    }

    private static func drawMiniFish(center: CGPoint,
                                     length: CGFloat,
                                     height: CGFloat,
                                     color: UIColor,
                                     striped: Bool,
                                     rotation: CGFloat,
                                     mirrored: Bool = false) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: rotation)
        if mirrored {
            context.scaleBy(x: -1, y: 1)
        }

        let tail = UIBezierPath()
        tail.move(to: CGPoint(x: -length * 0.42, y: 0))
        tail.addLine(to: CGPoint(x: -length * 0.70, y: -height * 0.48))
        tail.addLine(to: CGPoint(x: -length * 0.66, y: height * 0.48))
        tail.close()
        drawMiniPath(tail,
                     fill: color.withAlphaComponent(0.76),
                     stroke: .clear)

        drawMiniEllipse(center: .zero,
                        size: CGSize(width: length, height: height),
                        fill: color,
                        stroke: UIColor.white.withAlphaComponent(0.32),
                        lineWidth: 1)

        if striped {
            for index in 0..<3 {
                let x = -length * 0.16 + CGFloat(index) * length * 0.14
                drawMiniLine(from: CGPoint(x: x, y: -height * 0.34),
                             to: CGPoint(x: x - length * 0.04, y: height * 0.34),
                             color: UIColor.lerp(GameUI.gold, .white, 0.18).withAlphaComponent(0.62),
                             width: max(1.4, height * 0.11))
            }
        }

        drawMiniEllipse(center: CGPoint(x: length * 0.30, y: -height * 0.12),
                        size: CGSize(width: max(3.2, height * 0.22), height: max(3.2, height * 0.22)),
                        fill: UIColor.white,
                        stroke: .clear)
        drawMiniEllipse(center: CGPoint(x: length * 0.30 + 0.6, y: -height * 0.12),
                        size: CGSize(width: max(1.4, height * 0.08), height: max(1.4, height * 0.08)),
                        fill: UIColor.black.withAlphaComponent(0.82),
                        stroke: .clear)
        context.restoreGState()
    }

    private static func drawMiniShell(center: CGPoint, width: CGFloat, height: CGFloat, color: UIColor) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)

        let shell = UIBezierPath()
        shell.move(to: CGPoint(x: 0, y: height * 0.48))
        shell.addCurve(to: CGPoint(x: -width * 0.47, y: -height * 0.05),
                       controlPoint1: CGPoint(x: -width * 0.20, y: height * 0.45),
                       controlPoint2: CGPoint(x: -width * 0.50, y: height * 0.20))
        shell.addCurve(to: CGPoint(x: 0, y: -height * 0.45),
                       controlPoint1: CGPoint(x: -width * 0.32, y: -height * 0.32),
                       controlPoint2: CGPoint(x: -width * 0.10, y: -height * 0.45))
        shell.addCurve(to: CGPoint(x: width * 0.47, y: -height * 0.05),
                       controlPoint1: CGPoint(x: width * 0.10, y: -height * 0.45),
                       controlPoint2: CGPoint(x: width * 0.32, y: -height * 0.32))
        shell.addCurve(to: CGPoint(x: 0, y: height * 0.48),
                       controlPoint1: CGPoint(x: width * 0.50, y: height * 0.20),
                       controlPoint2: CGPoint(x: width * 0.20, y: height * 0.45))
        drawMiniPath(shell,
                     fill: color.withAlphaComponent(0.90),
                     stroke: UIColor.white.withAlphaComponent(0.42),
                     lineWidth: 1.4)

        for index in -2...2 {
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: 0, y: height * 0.38))
            rib.addCurve(to: CGPoint(x: CGFloat(index) * width * 0.16, y: -height * 0.28),
                         controlPoint1: CGPoint(x: CGFloat(index) * width * 0.05, y: height * 0.12),
                         controlPoint2: CGPoint(x: CGFloat(index) * width * 0.18, y: -height * 0.10))
            drawMiniPath(rib,
                         fill: .clear,
                         stroke: UIColor.lerp(color, .white, 0.46).withAlphaComponent(0.45),
                         lineWidth: 1.2)
        }
        context.restoreGState()
    }

    private static func drawMiniLeaf(center: CGPoint,
                                     size: CGSize,
                                     color: UIColor,
                                     rotation: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: rotation)

        let width = size.width
        let height = size.height
        let leaf = UIBezierPath()
        leaf.move(to: CGPoint(x: 0, y: -height * 0.5))
        leaf.addCurve(to: CGPoint(x: 0, y: height * 0.5),
                      controlPoint1: CGPoint(x: -width, y: -height * 0.20),
                      controlPoint2: CGPoint(x: -width * 0.70, y: height * 0.28))
        leaf.addCurve(to: CGPoint(x: 0, y: -height * 0.5),
                      controlPoint1: CGPoint(x: width * 0.70, y: height * 0.28),
                      controlPoint2: CGPoint(x: width, y: -height * 0.20))
        drawMiniPath(leaf,
                     fill: color,
                     stroke: UIColor.white.withAlphaComponent(0.15),
                     lineWidth: 0.8)
        context.restoreGState()
    }

    private static func drawMiniEllipse(center: CGPoint,
                                        size: CGSize,
                                        fill: UIColor,
                                        stroke: UIColor,
                                        lineWidth: CGFloat = 0,
                                        rotation: CGFloat = 0) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: rotation)
        let rect = CGRect(x: -size.width / 2,
                          y: -size.height / 2,
                          width: size.width,
                          height: size.height)
        let path = UIBezierPath(ovalIn: rect)
        fill.setFill()
        path.fill()
        if lineWidth > 0 {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        context.restoreGState()
    }

    private static func drawMiniRoundedRect(center: CGPoint,
                                            size: CGSize,
                                            radius: CGFloat,
                                            fill: UIColor,
                                            stroke: UIColor,
                                            lineWidth: CGFloat = 0) {
        let rect = CGRect(x: center.x - size.width / 2,
                          y: center.y - size.height / 2,
                          width: size.width,
                          height: size.height)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        drawMiniPath(path, fill: fill, stroke: stroke, lineWidth: lineWidth)
    }

    private static func drawMiniLine(from start: CGPoint,
                                     to end: CGPoint,
                                     color: UIColor,
                                     width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        drawMiniPath(path, fill: .clear, stroke: color, lineWidth: width)
    }

    private static func drawMiniPath(_ path: UIBezierPath,
                                     fill: UIColor,
                                     stroke: UIColor,
                                     lineWidth: CGFloat = 0) {
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        fill.setFill()
        path.fill()
        if lineWidth > 0 {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
    }

    private static func makeMiniEggNest(tint: UIColor) -> SKNode {
        let node = SKNode()
        let bowl = ellipse(width: 54, height: 18,
                           fill: UIColor(red: 0.48, green: 0.36, blue: 0.22, alpha: 0.86),
                           stroke: tint.withAlphaComponent(0.44),
                           lineWidth: 1.4)
        bowl.position.y = -11
        node.addChild(bowl)
        for position in [CGPoint(x: -10, y: 2), CGPoint(x: 8, y: 4)] {
            let egg = ellipse(width: 15, height: 22,
                              fill: UIColor.lerp(tint, .white, 0.70),
                              stroke: UIColor.white.withAlphaComponent(0.48),
                              lineWidth: 1)
            egg.position = position
            node.addChild(egg)
        }
        return node
    }

    private static func makeMiniFishSchool(tint: UIColor) -> SKNode {
        let node = SKNode()
        let specs: [(CGPoint, UIColor, CGFloat)] = [
            (CGPoint(x: -18, y: 8), tint, 0.02),
            (CGPoint(x: 4, y: -6), GameUI.gold, -0.10),
            (CGPoint(x: 19, y: 7), GameUI.coral, 0.12)
        ]
        for spec in specs {
            let fish = makeMiniFish(length: 30, height: 13, color: spec.1, striped: false)
            fish.position = spec.0
            fish.zRotation = spec.2
            node.addChild(fish)
        }
        return node
    }

    private static func makeMiniShell(tint: UIColor) -> SKNode {
        let node = makeShell(width: 58, height: 42, color: UIColor.lerp(GameUI.gold, tint, 0.25))
        let pearl = circle(radius: 5,
                           fill: UIColor.white.withAlphaComponent(0.80),
                           stroke: tint.withAlphaComponent(0.42),
                           lineWidth: 0.8)
        pearl.position = CGPoint(x: 0, y: -5)
        pearl.zPosition = 4
        node.addChild(pearl)
        return node
    }

    private static func makeMiniToyBoat(tint: UIColor) -> SKNode {
        let node = SKNode()
        let wood = UIColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 0.92)
        let hullPath = UIBezierPath()
        hullPath.move(to: CGPoint(x: -35, y: -8))
        hullPath.addLine(to: CGPoint(x: -20, y: -23))
        hullPath.addLine(to: CGPoint(x: 22, y: -21))
        hullPath.addLine(to: CGPoint(x: 35, y: -6))
        hullPath.close()
        node.addChild(shape(hullPath,
                            fill: UIColor.lerp(wood, tint, 0.20),
                            stroke: UIColor.black.withAlphaComponent(0.20),
                            lineWidth: 1.2))
        node.addChild(line(from: CGPoint(x: -4, y: -19),
                           to: CGPoint(x: -9, y: 28),
                           color: wood,
                           width: 3))
        let sailPath = UIBezierPath()
        sailPath.move(to: CGPoint(x: -7, y: 24))
        sailPath.addLine(to: CGPoint(x: 18, y: 6))
        sailPath.addLine(to: CGPoint(x: -7, y: 2))
        sailPath.close()
        let sail = shape(sailPath,
                         fill: UIColor.lerp(tint, .white, 0.38).withAlphaComponent(0.44),
                         stroke: UIColor.white.withAlphaComponent(0.32),
                         lineWidth: 0.9)
        sail.zPosition = 2
        node.addChild(sail)
        return node
    }

    private static func makeMiniTurtle(tint: UIColor) -> SKNode {
        let node = SKNode()
        let skin = UIColor(red: 0.50, green: 0.68, blue: 0.45, alpha: 0.90)
        let shell = ellipse(width: 58, height: 38,
                            fill: UIColor.lerp(GameUI.algae, tint, 0.24),
                            stroke: UIColor.white.withAlphaComponent(0.32),
                            lineWidth: 1.1)
        shell.zPosition = 2
        node.addChild(shell)
        let head = ellipse(width: 21, height: 18, fill: skin, stroke: .clear)
        head.position = CGPoint(x: 34, y: 3)
        node.addChild(head)
        node.addChild(ellipse(width: 22, height: 10, fill: skin.withAlphaComponent(0.78), stroke: .clear))
        return node
    }

    private static func makeMiniCurrent(tint: UIColor) -> SKNode {
        let node = SKNode()
        for i in 0..<3 {
            let path = UIBezierPath()
            let y = CGFloat(i - 1) * 11
            path.move(to: CGPoint(x: -39, y: -12 + y))
            path.addCurve(to: CGPoint(x: 39, y: 12 + y),
                          controlPoint1: CGPoint(x: -20, y: 18 + y),
                          controlPoint2: CGPoint(x: 19, y: -18 + y))
            node.addChild(shape(path,
                                fill: .clear,
                                stroke: [GameUI.coral, GameUI.gold, tint][i].withAlphaComponent(0.78),
                                lineWidth: 3,
                                glow: 2,
                                lineCap: .round))
        }
        return node
    }

    private static func makeMiniPlant(tint: UIColor) -> SKNode {
        let node = SKNode()
        node.addChild(line(from: CGPoint(x: 0, y: -30),
                           to: CGPoint(x: 3, y: 20),
                           color: UIColor.lerp(GameUI.algae, tint, 0.18),
                           width: 4))
        let leafA = makeLeaf(width: 12, height: 26, color: GameUI.algae.withAlphaComponent(0.82))
        leafA.position = CGPoint(x: -13, y: -8)
        leafA.zRotation = -0.75
        node.addChild(leafA)
        let flower = circle(radius: 13,
                            fill: tint.withAlphaComponent(0.78),
                            stroke: UIColor.white.withAlphaComponent(0.30),
                            lineWidth: 1,
                            glow: 2)
        flower.position = CGPoint(x: 1, y: 24)
        node.addChild(flower)
        return node
    }

    private static func makeMiniColorFish(tint: UIColor) -> SKNode {
        makeMiniFish(length: 62,
                     height: 28,
                     color: UIColor.lerp(GameUI.coral, tint, 0.20),
                     striped: true)
    }

    private static func makeMiniBubbleCloud(tint: UIColor) -> SKNode {
        let node = SKNode()
        for spec in [(CGPoint(x: -18, y: -10), CGFloat(8)),
                     (CGPoint(x: -2, y: 0), CGFloat(12)),
                     (CGPoint(x: 18, y: -6), CGFloat(7)),
                     (CGPoint(x: 20, y: 15), CGFloat(9)),
                     (CGPoint(x: -12, y: 22), CGFloat(6))] {
            let bubble = circle(radius: spec.1,
                                fill: tint.withAlphaComponent(0.08),
                                stroke: UIColor.lerp(tint, .white, 0.58).withAlphaComponent(0.56),
                                lineWidth: 1.4,
                                glow: 2)
            bubble.position = spec.0
            node.addChild(bubble)
        }
        return node
    }

    private static func makeMiniRuin(tint: UIColor) -> SKNode {
        let node = SKNode()
        let stone = UIColor(red: 0.34, green: 0.34, blue: 0.42, alpha: 0.92)
        let left = roundedRect(width: 13, height: 47, radius: 2, fill: stone, stroke: UIColor.white.withAlphaComponent(0.18), lineWidth: 0.8)
        left.position = CGPoint(x: -18, y: -4)
        node.addChild(left)
        let right = roundedRect(width: 13, height: 43, radius: 2, fill: stone, stroke: UIColor.white.withAlphaComponent(0.18), lineWidth: 0.8)
        right.position = CGPoint(x: 18, y: -6)
        node.addChild(right)
        let cap = roundedRect(width: 54, height: 12, radius: 2, fill: UIColor.lerp(stone, .white, 0.08), stroke: tint.withAlphaComponent(0.30), lineWidth: 1)
        cap.position.y = 20
        node.addChild(cap)
        return node
    }

    private static func makeMiniOctopus(tint: UIColor) -> SKNode {
        let node = SKNode()
        let body = ellipse(width: 42, height: 36,
                           fill: UIColor.lerp(tint, GameUI.coral, 0.28),
                           stroke: UIColor.white.withAlphaComponent(0.28),
                           lineWidth: 1)
        body.position.y = 4
        body.zPosition = 2
        node.addChild(body)
        for x in [-18, -9, 0, 9, 18] {
            node.addChild(line(from: CGPoint(x: CGFloat(x), y: -9),
                               to: CGPoint(x: CGFloat(x) + CGFloat(x / 3), y: -29),
                               color: body.fillColor.withAlphaComponent(0.74),
                               width: 4))
        }
        return node
    }

    private static func makeMiniSleepingElder(tint: UIColor) -> SKNode {
        let node = SKNode()
        let body = ellipse(width: 44, height: 22,
                           fill: UIColor.lerp(tint, GameUI.algae, 0.24).withAlphaComponent(0.82),
                           stroke: UIColor.white.withAlphaComponent(0.22),
                           lineWidth: 0.8)
        body.position = CGPoint(x: 8, y: -5)
        body.zRotation = -0.2
        node.addChild(body)
        let head = circle(radius: 10,
                          fill: UIColor(red: 0.83, green: 0.66, blue: 0.58, alpha: 1),
                          stroke: UIColor.white.withAlphaComponent(0.20),
                          lineWidth: 0.7)
        head.position = CGPoint(x: -16, y: 10)
        node.addChild(head)
        let moon = circle(radius: 7, fill: GameUI.gold.withAlphaComponent(0.64), stroke: .clear, glow: 2)
        moon.position = CGPoint(x: -29, y: 25)
        node.addChild(moon)
        return node
    }

    private static func makeMiniFallback(kind: WorldPOIKind, tint: UIColor) -> SKNode {
        switch kind {
        case .shipwreck: return makeMiniToyBoat(tint: tint)
        case .npc: return makeMiniTurtle(tint: tint)
        case .minigame: return makeMiniShell(tint: tint)
        case .pet: return makeMiniFishSchool(tint: tint)
        case .story: return makeMiniRuin(tint: tint)
        }
    }

    private static func makeMiniFish(length: CGFloat,
                                     height: CGFloat,
                                     color: UIColor,
                                     striped: Bool) -> SKNode {
        let node = SKNode()
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -length * 0.44, y: 0))
        tailPath.addLine(to: CGPoint(x: -length * 0.72, y: height * 0.48))
        tailPath.addLine(to: CGPoint(x: -length * 0.68, y: -height * 0.48))
        tailPath.close()
        node.addChild(shape(tailPath, fill: color.withAlphaComponent(0.75), stroke: .clear))
        node.addChild(ellipse(width: length, height: height,
                              fill: color,
                              stroke: UIColor.white.withAlphaComponent(0.30),
                              lineWidth: 0.8))
        if striped {
            for i in 0..<3 {
                let x = -length * 0.16 + CGFloat(i) * length * 0.14
                node.addChild(line(from: CGPoint(x: x, y: height * 0.34),
                                   to: CGPoint(x: x - length * 0.04, y: -height * 0.34),
                                   color: UIColor.lerp(GameUI.gold, .white, 0.18).withAlphaComponent(0.58),
                                   width: max(1, height * 0.10)))
            }
        }
        let eye = circle(radius: max(1.7, height * 0.10), fill: UIColor.white, stroke: .clear)
        eye.position = CGPoint(x: length * 0.30, y: height * 0.12)
        node.addChild(eye)
        return node
    }

    private static func makeAbandonedEggNest(tint: UIColor) -> SKNode {
        let node = SKNode()
        let sand = UIColor(red: 0.68, green: 0.54, blue: 0.35, alpha: 1)
        let darkSand = UIColor.lerp(sand, .black, 0.36)

        let sandPatch = makeSeafloorPatch(width: 86,
                                           height: 34,
                                           color: sand.withAlphaComponent(0.46),
                                           stroke: darkSand.withAlphaComponent(0.24))
        sandPatch.position = CGPoint(x: -2, y: -23)
        sandPatch.zPosition = -3
        node.addChild(sandPatch)

        for i in 0..<5 {
            let grass = makeLeaf(width: 5,
                                 height: 18 + CGFloat(i % 3) * 5,
                                 color: UIColor.lerp(GameUI.algae, tint, 0.15).withAlphaComponent(0.58))
            grass.position = CGPoint(x: -38 + CGFloat(i) * 19, y: -20 + CGFloat(i % 2) * 3)
            grass.zRotation = -0.42 + CGFloat(i) * 0.18
            grass.zPosition = -1
            node.addChild(grass)
        }

        let bowl = ellipse(width: 55, height: 21,
                           fill: darkSand.withAlphaComponent(0.72),
                           stroke: sand.withAlphaComponent(0.58),
                           lineWidth: 1.1)
        bowl.position = CGPoint(x: 0, y: -15)
        node.addChild(bowl)

        for i in 0..<8 {
            let x = -27 + CGFloat(i) * 7.8
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x - 12, y: -17 + CGFloat(i % 2) * 3))
            path.addCurve(to: CGPoint(x: x + 12, y: -13 - CGFloat((i + 1) % 2) * 3),
                          controlPoint1: CGPoint(x: x - 3, y: -6),
                          controlPoint2: CGPoint(x: x + 8, y: -24))
            let twig = shape(path,
                             fill: .clear,
                             stroke: UIColor.lerp(sand, .white, CGFloat(i % 3) * 0.08).withAlphaComponent(0.82),
                             lineWidth: 2.1,
                             lineCap: .round)
            twig.zPosition = 1
            node.addChild(twig)
        }

        let eggColors = [
            UIColor.lerp(tint, .white, 0.72),
            UIColor(red: 0.92, green: 0.86, blue: 0.68, alpha: 1),
            UIColor.lerp(GameUI.palePaper, tint, 0.18)
        ]
        let eggPositions = [
            CGPoint(x: -13, y: -1),
            CGPoint(x: 2, y: 4),
            CGPoint(x: 15, y: -3)
        ]
        for (index, position) in eggPositions.enumerated() {
            let egg = ellipse(width: index == 1 ? 15 : 13,
                              height: index == 1 ? 23 : 20,
                              fill: eggColors[index],
                              stroke: UIColor.white.withAlphaComponent(0.54),
                              lineWidth: 0.9,
                              glow: index == 1 ? 4 : 2)
            egg.position = position
            egg.zRotation = [-0.18, 0.05, 0.2][index]
            egg.zPosition = 3
            node.addChild(egg)

            let shine = ellipse(width: 3.8, height: 8,
                                fill: UIColor.white.withAlphaComponent(0.42),
                                stroke: .clear)
            shine.position = CGPoint(x: position.x - 3, y: position.y + 4)
            shine.zRotation = egg.zRotation + 0.15
            shine.zPosition = 4
            node.addChild(shine)
        }

        node.run(makeBreathAction(amount: 1.035, duration: 1.8))
        return node
    }

    private static func makeBabyFishSchool(tint: UIColor) -> SKNode {
        let node = SKNode()
        let colors = [
            UIColor.lerp(tint, .white, 0.10),
            GameUI.coral,
            GameUI.gold,
            UIColor(red: 0.48, green: 0.86, blue: 0.66, alpha: 1),
            UIColor(red: 0.58, green: 0.74, blue: 0.98, alpha: 1),
            UIColor(red: 0.82, green: 0.92, blue: 0.72, alpha: 1)
        ]
        let positions = [
            CGPoint(x: -39, y: 12),
            CGPoint(x: -12, y: 28),
            CGPoint(x: 24, y: 6),
            CGPoint(x: 5, y: -25),
            CGPoint(x: -48, y: -14),
            CGPoint(x: 44, y: -17)
        ]
        for i in 0..<positions.count {
            let fish = makeFish(length: 26 - CGFloat(i % 2) * 4,
                                height: 12,
                                color: colors[i],
                                stripeColor: UIColor.white.withAlphaComponent(0.32),
                                striped: i.isMultiple(of: 2))
            fish.position = positions[i]
            fish.zRotation = [-0.08, 0.12, -0.16, 0.18, -0.22, 0.06][i]
            fish.zPosition = CGFloat(i + 1)
            fish.xScale = [4, 5].contains(i) ? -1 : 1
            node.addChild(fish)
            fish.run(.repeatForever(.sequence([
                eased(.moveBy(x: 0, y: 2.8 + CGFloat(i), duration: 0.75 + TimeInterval(i) * 0.06)),
                eased(.moveBy(x: 0, y: -2.8 - CGFloat(i), duration: 0.85 + TimeInterval(i) * 0.06))
            ])))
        }

        node.run(.repeatForever(.sequence([
            eased(.rotate(byAngle: 0.055, duration: 2.2)),
            eased(.rotate(byAngle: -0.055, duration: 2.2))
        ])))
        return node
    }

    private static func makeFollowingFishSchool(tint: UIColor) -> SKNode {
        let node = SKNode()
        let colors = [
            UIColor.lerp(tint, .white, 0.10),
            GameUI.coral,
            GameUI.gold,
            UIColor(red: 0.48, green: 0.86, blue: 0.66, alpha: 1),
            UIColor(red: 0.58, green: 0.74, blue: 0.98, alpha: 1),
            UIColor(red: 0.82, green: 0.92, blue: 0.72, alpha: 1),
            UIColor(red: 0.76, green: 1.0, blue: 0.94, alpha: 1),
            UIColor(red: 0.95, green: 0.78, blue: 0.62, alpha: 1)
        ]
        let positions = [
            CGPoint(x: -185, y: 64),
            CGPoint(x: -132, y: -52),
            CGPoint(x: -62, y: 112),
            CGPoint(x: 78, y: -86),
            CGPoint(x: 142, y: 48),
            CGPoint(x: 198, y: -22),
            CGPoint(x: -18, y: -118),
            CGPoint(x: 36, y: 125)
        ]

        for i in 0..<positions.count {
            let fish = makeFish(length: 28 - CGFloat(i % 3) * 3,
                                height: 12,
                                color: colors[i],
                                stripeColor: UIColor.white.withAlphaComponent(0.30),
                                striped: i.isMultiple(of: 2))
            fish.position = positions[i]
            fish.zRotation = [-0.12, 0.16, 0.04, -0.18, 0.10, -0.06, 0.14, -0.10][i]
            fish.xScale = [1, 6].contains(i) ? -1 : 1
            fish.zPosition = CGFloat(i + 1)
            node.addChild(fish)
            fish.run(.repeatForever(.sequence([
                eased(.moveBy(x: 0, y: 3.5 + CGFloat(i % 2) * 2, duration: 0.82 + TimeInterval(i) * 0.05)),
                eased(.moveBy(x: 0, y: -3.5 - CGFloat(i % 2) * 2, duration: 0.92 + TimeInterval(i) * 0.05))
            ])))
        }

        node.run(.repeatForever(.sequence([
            eased(.rotate(byAngle: 0.035, duration: 2.4)),
            eased(.rotate(byAngle: -0.035, duration: 2.4))
        ])))
        return node
    }

    private static func makeMusicShell(tint: UIColor) -> SKNode {
        let node = SKNode()
        let shellColor = UIColor.lerp(GameUI.gold, tint, 0.28)
        let island = makeVegetatedIsland(width: 118,
                                         height: 42,
                                         tint: tint,
                                         sandTint: shellColor,
                                         plantCount: 7)
        island.position = CGPoint(x: -5, y: -32)
        island.zPosition = -5
        node.addChild(island)

        let shell = makeShell(width: 58, height: 42, color: shellColor)
        shell.position = CGPoint(x: -2, y: -7)
        node.addChild(shell)

        for i in 0..<3 {
            let path = UIBezierPath()
            let y = -5 + CGFloat(i) * 10
            path.move(to: CGPoint(x: 21, y: y))
            path.addCurve(to: CGPoint(x: 43, y: y + 4),
                          controlPoint1: CGPoint(x: 29, y: y + 12),
                          controlPoint2: CGPoint(x: 36, y: y - 6))
            let wave = shape(path,
                             fill: .clear,
                             stroke: UIColor.lerp(shellColor, .white, 0.30).withAlphaComponent(0.70 - CGFloat(i) * 0.12),
                             lineWidth: 1.8,
                             glow: 2.5,
                             lineCap: .round)
            wave.zPosition = 4
            node.addChild(wave)
        }

        let pearl = circle(radius: 5.4,
                           fill: UIColor.white.withAlphaComponent(0.78),
                           stroke: shellColor.withAlphaComponent(0.60),
                           lineWidth: 0.8,
                           glow: 5)
        pearl.position = CGPoint(x: 2, y: -4)
        pearl.zPosition = 5
        node.addChild(pearl)

        shell.run(makeBreathAction(amount: 1.04, duration: 1.4))
        return node
    }

    private static func makeSmallShipwreck(tint: UIColor) -> SKNode {
        let node = SKNode()
        let wood = UIColor(red: 0.45, green: 0.31, blue: 0.18, alpha: 1)
        let wetWood = UIColor.lerp(wood, tint, 0.22)
        let island = makeVegetatedIsland(width: 132,
                                         height: 44,
                                         tint: tint,
                                         sandTint: wetWood,
                                         plantCount: 8)
        island.position = CGPoint(x: -4, y: -34)
        island.zPosition = -6
        node.addChild(island)

        let hullPath = UIBezierPath()
        hullPath.move(to: CGPoint(x: -34, y: -12))
        hullPath.addLine(to: CGPoint(x: -19, y: -28))
        hullPath.addLine(to: CGPoint(x: 20, y: -25))
        hullPath.addLine(to: CGPoint(x: 36, y: -7))
        hullPath.addCurve(to: CGPoint(x: -34, y: -12),
                          controlPoint1: CGPoint(x: 16, y: -18),
                          controlPoint2: CGPoint(x: -12, y: -20))
        let hull = shape(hullPath,
                         fill: wetWood.withAlphaComponent(0.84),
                         stroke: UIColor.lerp(wood, .black, 0.20).withAlphaComponent(0.82),
                         lineWidth: 1.2)
        hull.zPosition = 1
        node.addChild(hull)

        for i in 0..<4 {
            let plank = roundedRect(width: 42 - CGFloat(i) * 4,
                                    height: 5,
                                    radius: 2.5,
                                    fill: UIColor.lerp(wood, .white, CGFloat(i) * 0.055).withAlphaComponent(0.76),
                                    stroke: UIColor.black.withAlphaComponent(0.12),
                                    lineWidth: 0.6)
            plank.position = CGPoint(x: -5 + CGFloat(i) * 2, y: -12 - CGFloat(i) * 4)
            plank.zRotation = -0.09 + CGFloat(i) * 0.035
            plank.zPosition = 2
            node.addChild(plank)
        }

        let mast = line(from: CGPoint(x: -5, y: -20),
                        to: CGPoint(x: -10, y: 29),
                        color: wetWood.withAlphaComponent(0.82),
                        width: 3.2)
        mast.zPosition = 0
        node.addChild(mast)

        let sailPath = UIBezierPath()
        sailPath.move(to: CGPoint(x: -8, y: 25))
        sailPath.addLine(to: CGPoint(x: 18, y: 8))
        sailPath.addLine(to: CGPoint(x: -8, y: 3))
        sailPath.close()
        let sail = shape(sailPath,
                         fill: UIColor.lerp(tint, .white, 0.36).withAlphaComponent(0.28),
                         stroke: UIColor.white.withAlphaComponent(0.26),
                         lineWidth: 0.9)
        sail.zPosition = -1
        node.addChild(sail)

        for position in [CGPoint(x: 20, y: -12), CGPoint(x: -25, y: -6), CGPoint(x: 8, y: -29)] {
            let sparkle = makeSparkle(color: GameUI.gold, radius: 5)
            sparkle.position = position
            sparkle.zPosition = 5
            node.addChild(sparkle)
        }

        let mapThread = line(from: CGPoint(x: 31, y: -24),
                             to: CGPoint(x: 49, y: -16),
                             color: GameUI.gold.withAlphaComponent(0.56),
                             width: 1.2,
                             glow: 3)
        mapThread.zPosition = 6
        node.addChild(mapThread)

        node.zRotation = -0.08
        return node
    }

    private static func makeOldTurtle(tint: UIColor) -> SKNode {
        let node = SKNode()
        let shellColor = UIColor.lerp(GameUI.algae, tint, 0.22)
        let skinColor = UIColor(red: 0.50, green: 0.68, blue: 0.45, alpha: 1)

        let shadow = makeSeafloorPatch(width: 78,
                                       height: 24,
                                       color: UIColor.black.withAlphaComponent(0.16),
                                       stroke: GameUI.algae.withAlphaComponent(0.18))
        shadow.position = CGPoint(x: 1, y: -21)
        shadow.zPosition = -3
        node.addChild(shadow)

        let backLeft = ellipse(width: 23, height: 12,
                               fill: skinColor.withAlphaComponent(0.78),
                               stroke: .clear)
        backLeft.position = CGPoint(x: -17, y: -11)
        backLeft.zRotation = -0.48
        node.addChild(backLeft)

        let backRight = ellipse(width: 23, height: 12,
                                fill: skinColor.withAlphaComponent(0.78),
                                stroke: .clear)
        backRight.position = CGPoint(x: 17, y: -11)
        backRight.zRotation = 0.48
        node.addChild(backRight)

        let shell = ellipse(width: 57, height: 38,
                            fill: shellColor.withAlphaComponent(0.94),
                            stroke: UIColor.white.withAlphaComponent(0.34),
                            lineWidth: 1.2,
                            glow: 2)
        shell.zPosition = 2
        node.addChild(shell)

        let belly = ellipse(width: 34, height: 24,
                            fill: UIColor.lerp(shellColor, .black, 0.18).withAlphaComponent(0.56),
                            stroke: UIColor.white.withAlphaComponent(0.14),
                            lineWidth: 0.7)
        belly.zPosition = 3
        node.addChild(belly)

        for angle in [CGFloat(-0.55), 0, 0.55] {
            let rib = line(from: CGPoint(x: sin(angle) * 4, y: -15),
                           to: CGPoint(x: sin(angle) * 19, y: 14),
                           color: UIColor.lerp(shellColor, .white, 0.35).withAlphaComponent(0.28),
                           width: 1.1)
            rib.zPosition = 4
            node.addChild(rib)
        }

        let head = ellipse(width: 22, height: 19,
                           fill: skinColor,
                           stroke: UIColor.white.withAlphaComponent(0.24),
                           lineWidth: 0.8)
        head.position = CGPoint(x: 33, y: 4)
        head.zPosition = 1
        node.addChild(head)

        let eye = circle(radius: 2.1, fill: UIColor.black.withAlphaComponent(0.72), stroke: .clear)
        eye.position = CGPoint(x: 38, y: 7)
        eye.zPosition = 4
        node.addChild(eye)

        let frontFlipper = ellipse(width: 24, height: 11,
                                   fill: skinColor.withAlphaComponent(0.88),
                                   stroke: .clear)
        frontFlipper.position = CGPoint(x: 19, y: 15)
        frontFlipper.zRotation = 0.38
        frontFlipper.zPosition = 1
        node.addChild(frontFlipper)

        node.run(.repeatForever(.sequence([
            eased(.rotate(byAngle: 0.035, duration: 1.7)),
            eased(.rotate(byAngle: -0.035, duration: 1.7))
        ])))
        return node
    }

    private static func makeWarmCurrent(tint: UIColor) -> SKNode {
        return SKNode()
    }

    private static func makeTouchPlant(tint: UIColor) -> SKNode {
        let node = SKNode()
        let stemColor = UIColor.lerp(GameUI.algae, tint, 0.16)

        let rootPatch = makeSeafloorPatch(width: 64,
                                          height: 24,
                                          color: GameUI.algae.withAlphaComponent(0.22),
                                          stroke: stemColor.withAlphaComponent(0.22))
        rootPatch.position = CGPoint(x: 0, y: -32)
        rootPatch.zPosition = -3
        node.addChild(rootPatch)

        let stemPath = UIBezierPath()
        stemPath.move(to: CGPoint(x: 0, y: -29))
        stemPath.addCurve(to: CGPoint(x: 3, y: 22),
                          controlPoint1: CGPoint(x: -11, y: -8),
                          controlPoint2: CGPoint(x: 13, y: 5))
        let stem = shape(stemPath,
                         fill: .clear,
                         stroke: stemColor.withAlphaComponent(0.92),
                         lineWidth: 4,
                         glow: 2,
                         lineCap: .round)
        node.addChild(stem)

        let leafSpecs: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: -17, y: -11), -0.78, 25),
            (CGPoint(x: 16, y: -1), 0.72, 22),
            (CGPoint(x: -13, y: 10), -0.62, 20),
            (CGPoint(x: 11, y: 17), 0.55, 17)
        ]
        for spec in leafSpecs {
            let leaf = makeLeaf(width: spec.2 * 0.52,
                                height: spec.2,
                                color: UIColor.lerp(stemColor, .white, 0.10).withAlphaComponent(0.82))
            leaf.position = spec.0
            leaf.zRotation = spec.1
            node.addChild(leaf)
        }

        for i in 0..<6 {
            let petal = ellipse(width: 13, height: 22,
                                fill: UIColor.lerp(tint, .white, 0.22).withAlphaComponent(0.86),
                                stroke: UIColor.white.withAlphaComponent(0.26),
                                lineWidth: 0.6,
                                glow: 2)
            petal.position = CGPoint(x: cos(CGFloat(i) * .pi / 3) * 9,
                                     y: 25 + sin(CGFloat(i) * .pi / 3) * 9)
            petal.zRotation = CGFloat(i) * .pi / 3
            petal.zPosition = 3
            node.addChild(petal)
        }

        let center = circle(radius: 5,
                            fill: GameUI.gold.withAlphaComponent(0.90),
                            stroke: UIColor.white.withAlphaComponent(0.35),
                            lineWidth: 0.7,
                            glow: 4)
        center.position = CGPoint(x: 0, y: 25)
        center.zPosition = 4
        node.addChild(center)

        node.run(makeBreathAction(amount: 1.045, duration: 1.2))
        return node
    }

    private static func makeColorFish(tint: UIColor) -> SKNode {
        let node = SKNode()
        for i in 0..<4 {
            let trail = ellipse(width: 12 + CGFloat(i) * 6,
                                height: 4 + CGFloat(i),
                                fill: UIColor.lerp(GameUI.coral, tint, CGFloat(i) * 0.12).withAlphaComponent(0.18),
                                stroke: .clear,
                                glow: 2)
            trail.position = CGPoint(x: -44 - CGFloat(i) * 13, y: -8 + CGFloat(i % 2) * 10)
            trail.zRotation = -0.18 + CGFloat(i) * 0.08
            trail.zPosition = -2
            node.addChild(trail)
        }
        let body = makeFish(length: 62,
                            height: 30,
                            color: UIColor.lerp(GameUI.coral, tint, 0.18),
                            stripeColor: UIColor.lerp(GameUI.gold, .white, 0.16).withAlphaComponent(0.64),
                            striped: true)
        body.zPosition = 2
        node.addChild(body)

        let fin = ellipse(width: 17, height: 9,
                          fill: GameUI.gold.withAlphaComponent(0.75),
                          stroke: .clear)
        fin.position = CGPoint(x: 2, y: 17)
        fin.zRotation = 0.24
        fin.zPosition = 3
        node.addChild(fin)

        for position in [CGPoint(x: -8, y: -18), CGPoint(x: 14, y: -16)] {
            let scale = circle(radius: 3.4,
                               fill: UIColor.lerp(tint, .white, 0.52).withAlphaComponent(0.72),
                               stroke: UIColor.white.withAlphaComponent(0.30),
                               lineWidth: 0.4,
                               glow: 3)
            scale.position = position
            scale.zPosition = 4
            node.addChild(scale)
        }

        node.run(.repeatForever(.sequence([
            eased(.moveBy(x: 0, y: 4, duration: 0.9)),
            eased(.moveBy(x: 0, y: -4, duration: 1.0))
        ])))
        return node
    }

    private static func makeBubbleCloud(tint: UIColor) -> SKNode {
        let node = SKNode()
        let vent = makeSeafloorPatch(width: 58,
                                     height: 18,
                                     color: UIColor.black.withAlphaComponent(0.20),
                                     stroke: tint.withAlphaComponent(0.24))
        vent.position = CGPoint(x: 0, y: -35)
        vent.zPosition = -3
        node.addChild(vent)

        let bubbles: [(CGPoint, CGFloat, CGFloat)] = [
            (CGPoint(x: -22, y: -24), 8, 0.48),
            (CGPoint(x: -7, y: -12), 12, 0.56),
            (CGPoint(x: 13, y: -22), 7, 0.44),
            (CGPoint(x: 23, y: -2), 10, 0.52),
            (CGPoint(x: -17, y: 17), 6, 0.40),
            (CGPoint(x: 4, y: 37), 8, 0.48),
            (CGPoint(x: 24, y: 58), 5, 0.36),
            (CGPoint(x: -8, y: 78), 9, 0.44),
            (CGPoint(x: 14, y: 99), 6, 0.38)
        ]
        for (index, bubble) in bubbles.enumerated() {
            let ring = circle(radius: bubble.1,
                              fill: tint.withAlphaComponent(0.08),
                              stroke: UIColor.lerp(tint, .white, 0.58).withAlphaComponent(bubble.2),
                              lineWidth: 1.4,
                              glow: 3)
            ring.position = bubble.0
            ring.zPosition = CGFloat(index)
            node.addChild(ring)

            let shine = circle(radius: max(1.4, bubble.1 * 0.18),
                               fill: UIColor.white.withAlphaComponent(0.55),
                               stroke: .clear)
            shine.position = CGPoint(x: bubble.0.x - bubble.1 * 0.28,
                                     y: bubble.0.y + bubble.1 * 0.28)
            shine.zPosition = ring.zPosition + 0.2
            node.addChild(shine)

            ring.run(.repeatForever(.sequence([
                eased(.moveBy(x: 0, y: 3 + CGFloat(index % 3), duration: 1.1 + TimeInterval(index) * 0.08)),
                eased(.moveBy(x: 0, y: -3 - CGFloat(index % 3), duration: 1.1 + TimeInterval(index) * 0.08))
            ])))
        }
        return node
    }

    private static func makeAlgaeRuin(tint: UIColor) -> SKNode {
        let node = SKNode()
        let stone = UIColor(red: 0.34, green: 0.34, blue: 0.42, alpha: 1)
        let moss = UIColor.lerp(GameUI.algae, tint, 0.15)

        let rubble = makeSeafloorPatch(width: 92,
                                       height: 28,
                                       color: UIColor.black.withAlphaComponent(0.18),
                                       stroke: moss.withAlphaComponent(0.22))
        rubble.position = CGPoint(x: 2, y: -28)
        rubble.zPosition = -3
        node.addChild(rubble)

        let leftColumn = roundedRect(width: 13,
                                     height: 48,
                                     radius: 2,
                                     fill: stone.withAlphaComponent(0.88),
                                     stroke: UIColor.white.withAlphaComponent(0.16),
                                     lineWidth: 0.8)
        leftColumn.position = CGPoint(x: -18, y: -4)
        node.addChild(leftColumn)

        let rightColumn = roundedRect(width: 13,
                                      height: 44,
                                      radius: 2,
                                      fill: UIColor.lerp(stone, .black, 0.08).withAlphaComponent(0.88),
                                      stroke: UIColor.white.withAlphaComponent(0.14),
                                      lineWidth: 0.8)
        rightColumn.position = CGPoint(x: 19, y: -6)
        rightColumn.zRotation = -0.05
        node.addChild(rightColumn)

        let cap = roundedRect(width: 54,
                              height: 13,
                              radius: 2,
                              fill: UIColor.lerp(stone, .white, 0.08).withAlphaComponent(0.90),
                              stroke: UIColor.white.withAlphaComponent(0.16),
                              lineWidth: 0.8)
        cap.position = CGPoint(x: 1, y: 19)
        cap.zRotation = 0.04
        node.addChild(cap)

        let archPath = UIBezierPath()
        archPath.move(to: CGPoint(x: -17, y: -25))
        archPath.addLine(to: CGPoint(x: -17, y: -3))
        archPath.addCurve(to: CGPoint(x: 17, y: -3),
                          controlPoint1: CGPoint(x: -12, y: 13),
                          controlPoint2: CGPoint(x: 12, y: 13))
        archPath.addLine(to: CGPoint(x: 17, y: -25))
        let archShadow = shape(archPath,
                               fill: UIColor.black.withAlphaComponent(0.32),
                               stroke: tint.withAlphaComponent(0.26),
                               lineWidth: 0.8)
        archShadow.zPosition = 2
        node.addChild(archShadow)

        for i in 0..<4 {
            let x = -25 + CGFloat(i) * 14
            let vine = makeVine(from: CGPoint(x: x, y: 23),
                                length: 24 + CGFloat(i % 2) * 10,
                                lean: CGFloat(i - 1) * 3,
                                color: moss.withAlphaComponent(0.78))
            vine.zPosition = 4
            node.addChild(vine)
        }

        let symbol = makeSparkle(color: UIColor.lerp(tint, .white, 0.20), radius: 5)
        symbol.position = CGPoint(x: 0, y: -5)
        symbol.zPosition = 5
        node.addChild(symbol)
        return node
    }

    private static func makeHiddenBabyOctopus(tint: UIColor) -> SKNode {
        let node = SKNode()
        let rockPatch = makeSeafloorPatch(width: 84,
                                          height: 28,
                                          color: UIColor(red: 0.18, green: 0.16, blue: 0.22, alpha: 0.42),
                                          stroke: tint.withAlphaComponent(0.22))
        rockPatch.position = CGPoint(x: 0, y: -31)
        rockPatch.zPosition = -4
        node.addChild(rockPatch)

        let cave = ellipse(width: 67, height: 35,
                           fill: UIColor.black.withAlphaComponent(0.32),
                           stroke: UIColor.lerp(tint, .black, 0.20).withAlphaComponent(0.46),
                           lineWidth: 1,
                           glow: 2)
        cave.position = CGPoint(x: 0, y: -19)
        node.addChild(cave)

        let bodyColor = UIColor.lerp(tint, GameUI.coral, 0.28)
        let head = ellipse(width: 39, height: 34,
                           fill: bodyColor.withAlphaComponent(0.94),
                           stroke: UIColor.white.withAlphaComponent(0.28),
                           lineWidth: 0.9,
                           glow: 4)
        head.position = CGPoint(x: 0, y: 3)
        head.zPosition = 3
        node.addChild(head)

        for i in 0..<6 {
            let startX = -20 + CGFloat(i) * 8
            let path = UIBezierPath()
            path.move(to: CGPoint(x: startX, y: -10))
            path.addCurve(to: CGPoint(x: startX + CGFloat(i - 2) * 2, y: -31),
                          controlPoint1: CGPoint(x: startX - 7, y: -17),
                          controlPoint2: CGPoint(x: startX + 8, y: -24))
            let tentacle = shape(path,
                                 fill: .clear,
                                 stroke: bodyColor.withAlphaComponent(0.74),
                                 lineWidth: 4,
                                 lineCap: .round)
            tentacle.zPosition = 2
            node.addChild(tentacle)
        }

        for x in [-7, 7] {
            let eye = circle(radius: 3.4, fill: UIColor.white.withAlphaComponent(0.88), stroke: .clear)
            eye.position = CGPoint(x: CGFloat(x), y: 8)
            eye.zPosition = 5
            node.addChild(eye)
            let pupil = circle(radius: 1.6, fill: UIColor.black.withAlphaComponent(0.78), stroke: .clear)
            pupil.position = CGPoint(x: CGFloat(x) + 0.8, y: 7.2)
            pupil.zPosition = 6
            node.addChild(pupil)
        }

        let cover = roundedRect(width: 58,
                                height: 15,
                                radius: 7,
                                fill: UIColor(red: 0.20, green: 0.18, blue: 0.24, alpha: 0.78),
                                stroke: UIColor.white.withAlphaComponent(0.08),
                                lineWidth: 0.6)
        cover.position = CGPoint(x: 0, y: -27)
        cover.zPosition = 4
        node.addChild(cover)

        head.run(makeBreathAction(amount: 1.035, duration: 1.5))
        return node
    }

    private static func makeCompanionOctopus(tint: UIColor) -> SKNode {
        let node = SKNode()
        let bodyColor = UIColor.lerp(tint, GameUI.coral, 0.20)
        let head = ellipse(width: 41, height: 36,
                           fill: bodyColor.withAlphaComponent(0.95),
                           stroke: UIColor.white.withAlphaComponent(0.30),
                           lineWidth: 0.9,
                           glow: 4)
        head.position = CGPoint(x: 0, y: 5)
        head.zPosition = 3
        node.addChild(head)

        for i in 0..<6 {
            let startX = -20 + CGFloat(i) * 8
            let path = UIBezierPath()
            path.move(to: CGPoint(x: startX, y: -9))
            path.addCurve(to: CGPoint(x: startX + CGFloat(i - 2) * 3, y: -29),
                          controlPoint1: CGPoint(x: startX - 8, y: -17),
                          controlPoint2: CGPoint(x: startX + 9, y: -22))
            let tentacle = shape(path,
                                 fill: .clear,
                                 stroke: bodyColor.withAlphaComponent(0.78),
                                 lineWidth: 4,
                                 glow: 1,
                                 lineCap: .round)
            tentacle.zPosition = 2
            node.addChild(tentacle)
            tentacle.run(.repeatForever(.sequence([
                eased(.rotate(byAngle: CGFloat(i.isMultiple(of: 2) ? 1 : -1) * 0.055, duration: 0.75)),
                eased(.rotate(byAngle: CGFloat(i.isMultiple(of: 2) ? -1 : 1) * 0.055, duration: 0.85))
            ])))
        }

        for x in [-7, 7] {
            let eye = circle(radius: 3.5, fill: UIColor.white.withAlphaComponent(0.9), stroke: .clear)
            eye.position = CGPoint(x: CGFloat(x), y: 11)
            eye.zPosition = 5
            node.addChild(eye)
            let pupil = circle(radius: 1.6, fill: UIColor.black.withAlphaComponent(0.8), stroke: .clear)
            pupil.position = CGPoint(x: CGFloat(x) + 0.7, y: 10.2)
            pupil.zPosition = 6
            node.addChild(pupil)
        }

        head.run(makeBreathAction(amount: 1.04, duration: 1.2))
        return node
    }

    private static func makeSleepingElder(tint: UIColor) -> SKNode {
        let node = SKNode()

        let restingWeed = makeSeafloorPatch(width: 82,
                                            height: 24,
                                            color: GameUI.algae.withAlphaComponent(0.20),
                                            stroke: tint.withAlphaComponent(0.20))
        restingWeed.position = CGPoint(x: 6, y: -27)
        restingWeed.zPosition = -3
        node.addChild(restingWeed)

        let hair = ellipse(width: 22, height: 33,
                           fill: UIColor.lerp(GameUI.gold, tint, 0.44).withAlphaComponent(0.88),
                           stroke: .clear)
        hair.position = CGPoint(x: -14, y: 10)
        hair.zRotation = 0.58
        hair.zPosition = 1
        node.addChild(hair)

        let head = circle(radius: 10,
                          fill: UIColor(red: 0.83, green: 0.66, blue: 0.58, alpha: 1),
                          stroke: UIColor.white.withAlphaComponent(0.20),
                          lineWidth: 0.7)
        head.position = CGPoint(x: -6, y: 10)
        head.zPosition = 3
        node.addChild(head)

        let eyePath = UIBezierPath(arcCenter: CGPoint(x: -2, y: 12),
                                   radius: 3.2,
                                   startAngle: 0.1,
                                   endAngle: .pi - 0.1,
                                   clockwise: false)
        let eye = shape(eyePath,
                        fill: .clear,
                        stroke: UIColor.black.withAlphaComponent(0.34),
                        lineWidth: 0.9,
                        lineCap: .round)
        eye.zPosition = 4
        node.addChild(eye)

        let body = ellipse(width: 22, height: 17,
                           fill: UIColor.lerp(tint, .white, 0.14).withAlphaComponent(0.80),
                           stroke: UIColor.white.withAlphaComponent(0.18),
                           lineWidth: 0.6)
        body.position = CGPoint(x: 8, y: -3)
        body.zRotation = -0.22
        body.zPosition = 2
        node.addChild(body)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: 17, y: -7))
        tailPath.addCurve(to: CGPoint(x: 39, y: -19),
                          controlPoint1: CGPoint(x: 25, y: -2),
                          controlPoint2: CGPoint(x: 34, y: -6))
        tailPath.addCurve(to: CGPoint(x: 18, y: -24),
                          controlPoint1: CGPoint(x: 34, y: -26),
                          controlPoint2: CGPoint(x: 24, y: -29))
        let tail = shape(tailPath,
                         fill: UIColor.lerp(tint, GameUI.algae, 0.30).withAlphaComponent(0.82),
                         stroke: UIColor.white.withAlphaComponent(0.18),
                         lineWidth: 0.7)
        tail.zPosition = 2
        node.addChild(tail)

        let finTop = makeLeaf(width: 11,
                              height: 22,
                              color: UIColor.lerp(tint, .white, 0.22).withAlphaComponent(0.66))
        finTop.position = CGPoint(x: 38, y: -15)
        finTop.zRotation = -1.2
        finTop.zPosition = 3
        node.addChild(finTop)

        let moonOuter = circle(radius: 8,
                               fill: GameUI.gold.withAlphaComponent(0.62),
                               stroke: UIColor.white.withAlphaComponent(0.25),
                               lineWidth: 0.5,
                               glow: 5)
        moonOuter.position = CGPoint(x: -28, y: 26)
        moonOuter.zPosition = 4
        node.addChild(moonOuter)

        let moonCut = circle(radius: 8,
                             fill: UIColor.black.withAlphaComponent(0.42),
                             stroke: .clear)
        moonCut.position = CGPoint(x: -24, y: 28)
        moonCut.zPosition = 5
        node.addChild(moonCut)

        node.run(makeBreathAction(amount: 1.025, duration: 2.2))
        return node
    }

    private static func makeFallback(kind: WorldPOIKind, tint: UIColor) -> SKNode {
        switch kind {
        case .shipwreck:
            return makeSmallShipwreck(tint: tint)
        case .npc:
            return makeOldTurtle(tint: tint)
        case .minigame:
            return makeMusicShell(tint: tint)
        case .pet:
            return makeBabyFishSchool(tint: tint)
        case .story:
            return makeAlgaeRuin(tint: tint)
        }
    }

    private static func makeSeafloorPatch(width: CGFloat,
                                          height: CGFloat,
                                          color: UIColor,
                                          stroke: UIColor) -> SKShapeNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -width * 0.48, y: -height * 0.08))
        path.addCurve(to: CGPoint(x: -width * 0.18, y: height * 0.42),
                      controlPoint1: CGPoint(x: -width * 0.44, y: height * 0.26),
                      controlPoint2: CGPoint(x: -width * 0.30, y: height * 0.44))
        path.addCurve(to: CGPoint(x: width * 0.34, y: height * 0.30),
                      controlPoint1: CGPoint(x: width * 0.02, y: height * 0.54),
                      controlPoint2: CGPoint(x: width * 0.24, y: height * 0.42))
        path.addCurve(to: CGPoint(x: width * 0.49, y: -height * 0.10),
                      controlPoint1: CGPoint(x: width * 0.52, y: height * 0.14),
                      controlPoint2: CGPoint(x: width * 0.55, y: -height * 0.02))
        path.addCurve(to: CGPoint(x: width * 0.12, y: -height * 0.45),
                      controlPoint1: CGPoint(x: width * 0.40, y: -height * 0.34),
                      controlPoint2: CGPoint(x: width * 0.26, y: -height * 0.50))
        path.addCurve(to: CGPoint(x: -width * 0.48, y: -height * 0.08),
                      controlPoint1: CGPoint(x: -width * 0.14, y: -height * 0.56),
                      controlPoint2: CGPoint(x: -width * 0.42, y: -height * 0.36))
        path.close()
        return shape(path,
                     fill: color,
                     stroke: stroke,
                     lineWidth: 0.9)
    }

    private static func makeVegetatedIsland(width: CGFloat,
                                            height: CGFloat,
                                            tint: UIColor,
                                            sandTint: UIColor,
                                            plantCount: Int) -> SKNode {
        let node = SKNode()
        let sand = UIColor(red: 0.62, green: 0.51, blue: 0.34, alpha: 1)
        let base = makeSeafloorPatch(width: width,
                                     height: height,
                                     color: UIColor.lerp(sand, sandTint, 0.20).withAlphaComponent(0.52),
                                     stroke: UIColor.lerp(sandTint, .black, 0.18).withAlphaComponent(0.28))
        base.zPosition = -4
        node.addChild(base)

        let lowerShade = makeSeafloorPatch(width: width * 0.82,
                                           height: height * 0.34,
                                           color: UIColor.lerp(sand, .black, 0.32).withAlphaComponent(0.20),
                                           stroke: .clear)
        lowerShade.position = CGPoint(x: 4, y: -height * 0.18)
        lowerShade.zPosition = -5
        node.addChild(lowerShade)

        let plantColor = UIColor.lerp(GameUI.algae, tint, 0.18)
        for index in 0..<plantCount {
            let denom = CGFloat(max(1, plantCount - 1))
            let progress = CGFloat(index) / denom
            let sideBias = progress < 0.5 ? -1.0 : 1.0
            let x = -width * 0.42 + progress * width * 0.84
            let heightJitter = CGFloat(index % 3) * 4
            let leaf = makeLeaf(width: 5.2,
                                height: 18 + heightJitter,
                                color: plantColor.withAlphaComponent(0.62))
            leaf.position = CGPoint(x: x, y: height * 0.06 + CGFloat(index % 2) * 2)
            leaf.zRotation = CGFloat(sideBias) * 0.36 + CGFloat(index % 4) * 0.08
            leaf.zPosition = -1
            node.addChild(leaf)
        }

        for index in 0..<5 {
            let x = -width * 0.32 + CGFloat(index) * width * 0.16
            let pebble = ellipse(width: 6 + CGFloat(index % 2) * 2,
                                 height: 3.6,
                                 fill: UIColor.lerp(sandTint, .white, 0.18).withAlphaComponent(0.38),
                                 stroke: UIColor.white.withAlphaComponent(0.10),
                                 lineWidth: 0.4)
            pebble.position = CGPoint(x: x, y: -height * 0.16 + CGFloat(index % 2) * 2)
            pebble.zPosition = -2
            node.addChild(pebble)
        }

        return node
    }

    private static func makeFish(length: CGFloat,
                                 height: CGFloat,
                                 color: UIColor,
                                 stripeColor: UIColor,
                                 striped: Bool) -> SKNode {
        let node = SKNode()
        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -length * 0.44, y: 0))
        tailPath.addLine(to: CGPoint(x: -length * 0.72, y: height * 0.48))
        tailPath.addLine(to: CGPoint(x: -length * 0.68, y: 0))
        tailPath.addLine(to: CGPoint(x: -length * 0.72, y: -height * 0.48))
        tailPath.close()
        let tail = shape(tailPath,
                         fill: color.withAlphaComponent(0.74),
                         stroke: .clear)
        tail.zPosition = 0
        node.addChild(tail)

        let body = ellipse(width: length, height: height,
                           fill: color,
                           stroke: UIColor.white.withAlphaComponent(0.30),
                           lineWidth: 0.8,
                           glow: 1.5)
        body.zPosition = 1
        node.addChild(body)

        if striped {
            for i in 0..<3 {
                let x = -length * 0.16 + CGFloat(i) * length * 0.14
                let stripe = line(from: CGPoint(x: x, y: height * 0.34),
                                  to: CGPoint(x: x - length * 0.04, y: -height * 0.34),
                                  color: stripeColor,
                                  width: max(1, height * 0.10))
                stripe.zPosition = 2
                node.addChild(stripe)
            }
        }

        let eye = circle(radius: max(1.7, height * 0.10), fill: UIColor.white, stroke: .clear)
        eye.position = CGPoint(x: length * 0.30, y: height * 0.12)
        eye.zPosition = 3
        node.addChild(eye)

        let pupil = circle(radius: max(0.8, height * 0.045), fill: UIColor.black.withAlphaComponent(0.80), stroke: .clear)
        pupil.position = eye.position
        pupil.zPosition = 4
        node.addChild(pupil)

        tail.run(.repeatForever(.sequence([
            eased(.scaleX(to: 0.72, duration: 0.28)),
            eased(.scaleX(to: 1.0, duration: 0.28))
        ])))
        return node
    }

    private static func makeShell(width: CGFloat, height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        let shellPath = UIBezierPath()
        shellPath.move(to: CGPoint(x: 0, y: -height * 0.48))
        shellPath.addCurve(to: CGPoint(x: -width * 0.47, y: height * 0.05),
                           controlPoint1: CGPoint(x: -width * 0.20, y: -height * 0.45),
                           controlPoint2: CGPoint(x: -width * 0.50, y: -height * 0.20))
        shellPath.addCurve(to: CGPoint(x: 0, y: height * 0.45),
                           controlPoint1: CGPoint(x: -width * 0.32, y: height * 0.32),
                           controlPoint2: CGPoint(x: -width * 0.10, y: height * 0.45))
        shellPath.addCurve(to: CGPoint(x: width * 0.47, y: height * 0.05),
                           controlPoint1: CGPoint(x: width * 0.10, y: height * 0.45),
                           controlPoint2: CGPoint(x: width * 0.32, y: height * 0.32))
        shellPath.addCurve(to: CGPoint(x: 0, y: -height * 0.48),
                           controlPoint1: CGPoint(x: width * 0.50, y: -height * 0.20),
                           controlPoint2: CGPoint(x: width * 0.20, y: -height * 0.45))
        let shell = shape(shellPath,
                          fill: color.withAlphaComponent(0.90),
                          stroke: UIColor.white.withAlphaComponent(0.40),
                          lineWidth: 1.1,
                          glow: 3)
        node.addChild(shell)

        for i in -2...2 {
            let ribPath = UIBezierPath()
            ribPath.move(to: CGPoint(x: 0, y: -height * 0.40))
            ribPath.addCurve(to: CGPoint(x: CGFloat(i) * width * 0.16, y: height * 0.28),
                             controlPoint1: CGPoint(x: CGFloat(i) * width * 0.05, y: -height * 0.12),
                             controlPoint2: CGPoint(x: CGFloat(i) * width * 0.18, y: height * 0.10))
            let rib = shape(ribPath,
                            fill: .clear,
                            stroke: UIColor.lerp(color, .white, 0.45).withAlphaComponent(0.38),
                            lineWidth: 1,
                            lineCap: .round)
            rib.zPosition = 2
            node.addChild(rib)
        }
        return node
    }

    private static func makeLeaf(width: CGFloat, height: CGFloat, color: UIColor) -> SKShapeNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -height * 0.5))
        path.addCurve(to: CGPoint(x: 0, y: height * 0.5),
                      controlPoint1: CGPoint(x: -width, y: -height * 0.20),
                      controlPoint2: CGPoint(x: -width * 0.70, y: height * 0.28))
        path.addCurve(to: CGPoint(x: 0, y: -height * 0.5),
                      controlPoint1: CGPoint(x: width * 0.70, y: height * 0.28),
                      controlPoint2: CGPoint(x: width, y: -height * 0.20))
        return shape(path,
                     fill: color,
                     stroke: UIColor.white.withAlphaComponent(0.13),
                     lineWidth: 0.6)
    }

    private static func makeVine(from start: CGPoint,
                                 length: CGFloat,
                                 lean: CGFloat,
                                 color: UIColor) -> SKNode {
        let node = SKNode()
        let path = UIBezierPath()
        path.move(to: start)
        path.addCurve(to: CGPoint(x: start.x + lean, y: start.y - length),
                      controlPoint1: CGPoint(x: start.x - 8, y: start.y - length * 0.32),
                      controlPoint2: CGPoint(x: start.x + 11, y: start.y - length * 0.70))
        let vine = shape(path,
                         fill: .clear,
                         stroke: color,
                         lineWidth: 2.2,
                         lineCap: .round)
        node.addChild(vine)

        let leafA = makeLeaf(width: 4.5, height: 10, color: color.withAlphaComponent(0.74))
        leafA.position = CGPoint(x: start.x + lean * 0.3 - 4, y: start.y - length * 0.42)
        leafA.zRotation = -0.8
        node.addChild(leafA)

        let leafB = makeLeaf(width: 4, height: 9, color: color.withAlphaComponent(0.66))
        leafB.position = CGPoint(x: start.x + lean * 0.65 + 4, y: start.y - length * 0.68)
        leafB.zRotation = 0.8
        node.addChild(leafB)
        return node
    }

    private static func makeSparkle(color: UIColor, radius: CGFloat) -> SKNode {
        let node = SKNode()
        let vertical = line(from: CGPoint(x: 0, y: -radius),
                            to: CGPoint(x: 0, y: radius),
                            color: color.withAlphaComponent(0.82),
                            width: 1.4,
                            glow: 3)
        let horizontal = line(from: CGPoint(x: -radius, y: 0),
                              to: CGPoint(x: radius, y: 0),
                              color: color.withAlphaComponent(0.82),
                              width: 1.4,
                              glow: 3)
        node.addChild(vertical)
        node.addChild(horizontal)
        node.run(makeBreathAction(amount: 1.18, duration: 0.9))
        return node
    }

    private static func circle(radius: CGFloat,
                               fill: UIColor,
                               stroke: UIColor,
                               lineWidth: CGFloat = 0,
                               glow: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        applyStyle(to: node, fill: fill, stroke: stroke, lineWidth: lineWidth, glow: glow)
        return node
    }

    private static func ellipse(width: CGFloat,
                                height: CGFloat,
                                fill: UIColor,
                                stroke: UIColor,
                                lineWidth: CGFloat = 0,
                                glow: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        applyStyle(to: node, fill: fill, stroke: stroke, lineWidth: lineWidth, glow: glow)
        return node
    }

    private static func roundedRect(width: CGFloat,
                                    height: CGFloat,
                                    radius: CGFloat,
                                    fill: UIColor,
                                    stroke: UIColor,
                                    lineWidth: CGFloat = 0,
                                    glow: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: radius)
        applyStyle(to: node, fill: fill, stroke: stroke, lineWidth: lineWidth, glow: glow)
        return node
    }

    private static func line(from start: CGPoint,
                             to end: CGPoint,
                             color: UIColor,
                             width: CGFloat,
                             glow: CGFloat = 0) -> SKShapeNode {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        return shape(path, fill: .clear, stroke: color, lineWidth: width, glow: glow, lineCap: .round)
    }

    private static func shape(_ path: UIBezierPath,
                              fill: UIColor,
                              stroke: UIColor,
                              lineWidth: CGFloat = 0,
                              glow: CGFloat = 0,
                              lineCap: CGLineCap = .butt) -> SKShapeNode {
        let node = SKShapeNode(path: path.cgPath)
        applyStyle(to: node, fill: fill, stroke: stroke, lineWidth: lineWidth, glow: glow)
        node.lineCap = lineCap
        return node
    }

    private static func applyStyle(to node: SKShapeNode,
                                   fill: UIColor,
                                   stroke: UIColor,
                                   lineWidth: CGFloat,
                                   glow: CGFloat) {
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        node.glowWidth = glow
    }

    private static func makeBreathAction(amount: CGFloat, duration: TimeInterval) -> SKAction {
        .repeatForever(.sequence([
            eased(.scale(to: amount, duration: duration)),
            eased(.scale(to: 1.0, duration: duration))
        ]))
    }

    private static func eased(_ action: SKAction) -> SKAction {
        action.eaeInEaseOut()
        return action
    }
}
