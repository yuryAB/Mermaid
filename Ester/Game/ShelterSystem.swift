//
//  ShelterSystem.swift
//  Ester
//
//  O abrigo (concha) é a base da sereia: descanso acelerado, estoque
//  de comida e evolução visual procedural por nível.
//

import Foundation
import SpriteKit

final class ShelterSystem {
    unowned let ctx: GameContext

    let position = CGPoint(x: -1200, y: -7400)
    private let node = SKNode()
    private var decorations: [SKNode] = []
    private var feedCooldown: CGFloat = 0

    init(ctx: GameContext) {
        self.ctx = ctx
    }

    var capacity: Int { ctx.stats.shelterLevel * 3 }

    func setup(in world: SKNode) {
        node.position = position
        node.zPosition = -10
        node.name = "shelter"
        node.setScale(1.5)
        world.addChild(node)
        buildShell()
        rebuildDecorations()
    }

    private func buildShell() {
        // monte de areia
        let sand = SKShapeNode(ellipseOf: CGSize(width: 460, height: 110))
        sand.fillColor = UIColor(red: 0.76, green: 0.7, blue: 0.55, alpha: 1)
        sand.strokeColor = .clear
        sand.position = CGPoint(x: 0, y: -80)
        node.addChild(sand)

        // concha em meia-lua com sulcos
        let shellColor = UIColor(red: 0.9, green: 0.75, blue: 0.8, alpha: 1)
        for i in 0..<4 {
            let radius = 170 - CGFloat(i) * 38
            let path = UIBezierPath(arcCenter: .zero, radius: radius,
                                    startAngle: 0, endAngle: .pi, clockwise: true)
            let ridge = SKShapeNode(path: path.cgPath)
            ridge.strokeColor = shellColor.withAlphaComponent(1 - CGFloat(i) * 0.15)
            ridge.lineWidth = 14
            ridge.fillColor = i == 0 ? shellColor.withAlphaComponent(0.25) : .clear
            node.addChild(ridge)
        }

        let glow = SKShapeNode(circleOfRadius: 36)
        glow.fillColor = UIColor(red: 1, green: 0.95, blue: 0.8, alpha: 0.7)
        glow.strokeColor = .clear
        glow.glowWidth = 18
        glow.position = CGPoint(x: 0, y: 30)
        node.addChild(glow)
        let pulse = SKAction.repeatForever(.sequence([
            .fadeAlpha(to: 0.4, duration: 1.6),
            .fadeAlpha(to: 0.8, duration: 1.6)
        ]))
        pulse.eaeInEaseOut()
        glow.run(pulse)
    }

    /// Decorações por nível: pérolas ao redor da concha.
    private func rebuildDecorations() {
        decorations.forEach { $0.removeFromParent() }
        decorations.removeAll()
        let level = ctx.stats.shelterLevel
        guard level > 1 else { return }
        for i in 0..<(level - 1) {
            let pearl = SKShapeNode(circleOfRadius: 14)
            pearl.fillColor = UIColor(white: 0.95, alpha: 1)
            pearl.strokeColor = .white
            pearl.glowWidth = 5
            let angle = CGFloat.pi * (0.2 + CGFloat(i) * 0.18)
            pearl.position = CGPoint(x: cos(angle) * 200, y: sin(angle) * 200 - 40)
            node.addChild(pearl)
            decorations.append(pearl)
        }
    }

    func isHome(_ point: CGPoint) -> Bool {
        point.distance(to: position) < 320
    }

    /// Guarda uma comida encontrada quando ela não está com fome.
    func storeFood() -> Bool {
        guard ctx.stats.storedFood < capacity else { return false }
        ctx.stats.storedFood += 1
        return true
    }

    func update(dt: CGFloat) {
        feedCooldown -= dt
        // Com fome e em casa: come do estoque
        if feedCooldown <= 0,
           ctx.stats.hunger > 60,
           ctx.stats.storedFood > 0,
           isHome(ctx.mermaidPosition) {
            feedCooldown = 8
            ctx.stats.storedFood -= 1
            ctx.stats.hunger = max(0, ctx.stats.hunger - 25)
            ctx.stats.boostMood(4)
            ctx.say("Ela comeu do estoque do abrigo 🐚")
        }
    }

    /// Toque no abrigo tenta melhorá-lo com pérolas.
    func tryUpgrade() {
        let stats = ctx.stats!
        guard stats.shelterLevel < 5 else {
            ctx.say("O abrigo já está no nível máximo! 🐚✨")
            return
        }
        let cost = stats.shelterLevel * 40
        guard stats.pearls >= cost else {
            ctx.say("Melhorar o abrigo custa 💠\(cost). Faltam \(cost - stats.pearls).")
            return
        }
        stats.pearls -= cost
        stats.shelterLevel += 1
        stats.gainXP(20)
        rebuildDecorations()
        ctx.say("Abrigo melhorado para o nível \(stats.shelterLevel)! 🐚 (+capacidade)")
    }
}
