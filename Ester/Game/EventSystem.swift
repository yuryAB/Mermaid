//
//  EventSystem.swift
//  Ester
//
//  Eventos ambientais leves: correntezas, bolhas, peixes raros, sombras,
//  objetos humanos caindo, barcos e cristais que abrem Match-3 especial.
//  Sem morte: o pior que acontece é susto e volta ao abrigo.
//

import Foundation
import SpriteKit

final class EventSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?

    private var timer: CGFloat = 20
    private var driftResetTimer: CGFloat = -1

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        if driftResetTimer > 0 {
            driftResetTimer -= dt
            if driftResetTimer <= 0 {
                ctx.autonomy.drift = CGVector(dx: 0, dy: 0)
            }
        }

        guard ctx.stats.phase != .egg else { return }
        timer -= dt
        if timer <= 0 {
            timer = .random(in: 28...55)
            trigger()
        }
    }

    private func trigger() {
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        var options: [(weight: Int, run: () -> Void)] = [
            (4, bubbles),
            (3, current),
            (3, glowingFood),
            (2, rareFish)
        ]
        if zone == .mid || zone == .deep || zone == .abyss {
            options.append((3, bigShadow))
        }
        if (zone == .reef || zone == .mid || zone == .deep || zone == .abyss),
           ctx.match3.puzzlePoint == nil {
            options.append((2, crystalCluster))
        }
        if ctx.mermaidPosition.y > -700 {
            options.append((2, boatPassing))
            if ctx.stats.isUnlocked(.surface) {
                options.append((2, fallingObject))
            }
        }

        let total = options.reduce(0) { $0 + $1.weight }
        var roll = Int.random(in: 0..<total)
        for option in options {
            roll -= option.weight
            if roll < 0 {
                option.run()
                return
            }
        }
    }

    // MARK: - Eventos

    private func bubbles() {
        guard let world = worldNode else { return }
        let origin = ctx.mermaidPosition + CGPoint(x: .random(in: -400...400),
                                                   y: .random(in: -300...100))
        for i in 0..<8 {
            let bubble = SKShapeNode(circleOfRadius: .random(in: 6...16))
            bubble.fillColor = UIColor(white: 1, alpha: 0.25)
            bubble.strokeColor = UIColor(white: 1, alpha: 0.6)
            bubble.position = origin + CGPoint(x: .random(in: -40...40), y: 0)
            bubble.zPosition = 8
            world.addChild(bubble)
            let rise = SKAction.sequence([
                .wait(forDuration: Double(i) * 0.15),
                .group([
                    .moveBy(x: .random(in: -30...30), y: .random(in: 250...450), duration: 2.4),
                    .sequence([.wait(forDuration: 1.6), .fadeOut(withDuration: 0.8)])
                ]),
                .removeFromParent()
            ])
            bubble.run(rise)
        }
        if origin.distance(to: ctx.mermaidPosition) < 300 {
            ctx.stats.boostMood(2)
        }
    }

    private func current() {
        ctx.autonomy.drift = CGVector(dx: .random(in: -70...70), dy: .random(in: -25...25))
        driftResetTimer = 8
        ctx.say("Uma correnteza passou! 🌊")
    }

    private func glowingFood() {
        ctx.food.spawnRare(near: ctx.mermaidPosition)
        ctx.say("Algo brilhante apareceu por perto... ✨")
    }

    private func rareFish() {
        guard let world = worldNode else { return }
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        guard let fish = ctx.fish.spawnFish(zone: zone, near: ctx.mermaidPosition, rare: true) else { return }
        ctx.say("Um peixe raro está passando! 👀")

        // se ela estiver por perto quando ele some, vira memória
        world.run(.sequence([
            .wait(forDuration: 6),
            .run { [weak self] in
                guard let self else { return }
                if fish.position.distance(to: self.ctx.mermaidPosition) < 600 {
                    self.ctx.stats.gainXP(15)
                    self.ctx.stats.pearls += 2
                    self.ctx.stats.addMemory("Viu um peixe raro em \(zone.displayName)")
                    self.ctx.say("Ela observou o peixe raro de pertinho! ✨ 💠+2")
                }
            }
        ]))
    }

    private func bigShadow() {
        guard let world = worldNode else { return }
        let y = ctx.mermaidPosition.y - .random(in: 150...400)
        let fromLeft = Bool.random()
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 520, height: 130))
        shadow.fillColor = UIColor(white: 0, alpha: 0.45)
        shadow.strokeColor = .clear
        shadow.zPosition = 9
        shadow.position = CGPoint(x: fromLeft ? World.minX - 300 : World.maxX + 300, y: y)
        world.addChild(shadow)
        let travel = SKAction.moveTo(x: fromLeft ? World.maxX + 300 : World.minX - 300, duration: 9)
        shadow.run(.sequence([travel, .removeFromParent()]))

        if ctx.stats.courage < 45 {
            ctx.autonomy.scare(from: shadow.position)
            ctx.say("Uma sombra enorme... ela se assustou! 😨")
        } else {
            ctx.stats.gainXP(8)
            ctx.stats.courage = min(100, ctx.stats.courage + 0.5)
            ctx.say("Uma sombra enorme passou... ela ficou só observando, corajosa. 💪")
        }
    }

    private func crystalCluster() {
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        ctx.match3.spawnSpecialPoint(near: ctx.mermaidPosition, zone: zone)
        ctx.say("Cristais mágicos brilham por perto! 💎 (desafio especial)")
    }

    private func boatPassing() {
        guard let world = worldNode else { return }
        let fromLeft = Bool.random()
        let hull = UIBezierPath()
        hull.move(to: CGPoint(x: -160, y: 0))
        hull.addLine(to: CGPoint(x: 160, y: 0))
        hull.addLine(to: CGPoint(x: 110, y: -70))
        hull.addLine(to: CGPoint(x: -110, y: -70))
        hull.close()
        let boat = SKShapeNode(path: hull.cgPath)
        boat.fillColor = UIColor(red: 0.35, green: 0.25, blue: 0.2, alpha: 1)
        boat.strokeColor = .clear
        boat.zPosition = 9
        boat.position = CGPoint(x: fromLeft ? World.minX - 250 : World.maxX + 250,
                                y: World.waterlineY + 30)
        world.addChild(boat)
        boat.run(.sequence([
            .moveTo(x: fromLeft ? World.maxX + 250 : World.minX - 250, duration: 14),
            .removeFromParent()
        ]))
        ctx.say("Um barco passa lá em cima... ⛵️")

        if ctx.mermaidPosition.y > -350 && ctx.stats.courage < 50 {
            ctx.autonomy.scare(from: CGPoint(x: ctx.mermaidPosition.x, y: 50))
        }
    }

    private func fallingObject() {
        guard let world = worldNode else { return }
        let x = (ctx.mermaidPosition.x + .random(in: -250...250)).clamped(to: World.minX...World.maxX)
        let landingY = max(ctx.mermaidPosition.y, -600) - .random(in: 0...150)

        let object = SKShapeNode(rectOf: CGSize(width: 30, height: 30), cornerRadius: 6)
        object.fillColor = UIColor(red: 0.7, green: 0.72, blue: 0.78, alpha: 1)
        object.strokeColor = .white
        object.zPosition = 9
        object.position = CGPoint(x: x, y: World.waterlineY + 200)
        world.addChild(object)

        let fall = SKAction.move(to: CGPoint(x: x, y: landingY), duration: 2.4)
        fall.eaeInEaseOut()
        object.run(.sequence([
            fall,
            .run { [weak self] in
                guard let self, let world = self.worldNode else { return }
                let kind = FoodKind(name: "um objeto humano", weight: 1, nutrition: 5,
                                    xp: 12, pearls: 4, courage: 0.8,
                                    style: .crystal,
                                    color: UIColor(red: 0.7, green: 0.75, blue: 0.8, alpha: 1))
                self.ctx.food.spawn(kind: kind, at: object.position, in: world)
            },
            .removeFromParent()
        ]))
        ctx.say("Algo caiu da superfície! 📦")
    }
}
