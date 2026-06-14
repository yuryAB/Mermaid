//
//  WorldPOINode.swift
//  Ester
//

import SpriteKit
import UIKit

final class WorldPOINode: SKNode {
    let poiKey: String

    private let halo: SKShapeNode
    private let core: SKShapeNode
    private let glyph: SKLabelNode
    private let title: SKLabelNode
    private let collectedMark: SKLabelNode
    private let baseColor: UIColor
    private let normalScale: CGFloat

    init(poi: WorldPOI, discovered: Bool, rewardCollected: Bool, focused: Bool) {
        poiKey = poi.key
        baseColor = poi.visual.color
        normalScale = poi.visual.scale.clamped(to: 0.75...1.35)
        halo = SKShapeNode(circleOfRadius: 42)
        core = SKShapeNode(circleOfRadius: 26)
        glyph = SKLabelNode(text: poi.visual.glyph)
        title = SKLabelNode(text: Self.shortTitle(poi.name))
        collectedMark = SKLabelNode(text: "✓")

        super.init()

        name = "world_poi_\(poi.key)"
        isUserInteractionEnabled = false
        zPosition = 8
        setScale(normalScale)

        halo.fillColor = baseColor.withAlphaComponent(0.12)
        halo.strokeColor = UIColor.lerp(baseColor, .white, 0.35).withAlphaComponent(0.55)
        halo.lineWidth = 1.3
        halo.glowWidth = 8
        addChild(halo)

        core.fillColor = baseColor.withAlphaComponent(0.24)
        core.strokeColor = UIColor.white.withAlphaComponent(0.62)
        core.lineWidth = 1
        core.glowWidth = 4
        addChild(core)

        glyph.fontName = "AvenirNext-DemiBold"
        glyph.fontSize = 30
        glyph.fontColor = UIColor.lerp(baseColor, .white, 0.30)
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        glyph.zPosition = 2
        addChild(glyph)

        title.fontName = "AvenirNext-DemiBold"
        title.fontSize = 11
        title.fontColor = UIColor.white.withAlphaComponent(0.86)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: -47)
        title.zPosition = 2
        addChild(title)

        collectedMark.fontName = "AvenirNext-Bold"
        collectedMark.fontSize = 16
        collectedMark.fontColor = GameUI.gold
        collectedMark.verticalAlignmentMode = .center
        collectedMark.horizontalAlignmentMode = .center
        collectedMark.position = CGPoint(x: 26, y: 24)
        collectedMark.zPosition = 4
        addChild(collectedMark)

        let bob = SKAction.repeatForever(.sequence([
            .moveBy(x: 0, y: 7, duration: 1.35),
            .moveBy(x: 0, y: -7, duration: 1.45)
        ]))
        bob.eaeInEaseOut()
        run(bob, withKey: "poi_bob")

        update(discovered: discovered, rewardCollected: rewardCollected, focused: focused)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(discovered: Bool, rewardCollected: Bool, focused: Bool) {
        alpha = discovered ? (rewardCollected ? 0.72 : 1.0) : 0.38
        title.isHidden = !discovered
        collectedMark.isHidden = !rewardCollected

        if focused {
            halo.strokeColor = UIColor.white.withAlphaComponent(0.90)
            halo.glowWidth = 16
            if action(forKey: "poi_focus") == nil {
                let pulse = SKAction.repeatForever(.sequence([
                    .scale(to: normalScale * 1.11, duration: 0.45),
                    .scale(to: normalScale, duration: 0.55)
                ]))
                pulse.eaeInEaseOut()
                run(pulse, withKey: "poi_focus")
            }
        } else {
            halo.strokeColor = UIColor.lerp(baseColor, .white, 0.35).withAlphaComponent(0.55)
            halo.glowWidth = 8
            removeAction(forKey: "poi_focus")
            setScale(normalScale)
        }
    }

    private static func shortTitle(_ text: String) -> String {
        guard text.count > 26 else { return text }
        let end = text.index(text.startIndex, offsetBy: 23)
        return "\(text[..<end])..."
    }
}
