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
import UIKit

// MARK: - Objetivo no mundo

/// Algo acontecendo por perto que o jogador pode pedir para a sereia
/// investigar (botão "Objetivo").
struct WorldObjective {
    let label: String
    /// Posição atual (nil quando o alvo sumiu do mundo).
    let position: () -> CGPoint?
    /// Recompensa em conchas ao interagir, limitada pelo sistema.
    let pearlReward: Int
    /// Recompensa extra ao chegar (opcional).
    let onReach: (() -> Void)?
    var timeRemaining: CGFloat
}

final class EventSystem {
    unowned let ctx: GameContext
    private weak var worldNode: SKNode?
    private let objectivePearlReward = 12
    private let maxObjectivePearlReward = 40
    private let currentEnergyDrainPerSecond: CGFloat = 1.6

    private var timer: CGFloat = 20
    private var driftResetTimer: CGFloat = -1
    private var driftDuration: CGFloat = 1
    private var activeCurrentDrift = CGVector(dx: 0, dy: 0)

    /// Objetivo ativo no momento, se houver.
    private(set) var currentObjective: WorldObjective?

    init(ctx: GameContext, worldNode: SKNode) {
        self.ctx = ctx
        self.worldNode = worldNode
    }

    func update(dt: CGFloat) {
        if driftResetTimer > 0 {
            drainEnergyFromCurrent(dt: min(dt, driftResetTimer))
            driftResetTimer -= dt
            if driftResetTimer <= 0 {
                ctx.autonomy.drift = CGVector(dx: 0, dy: 0)
                activeCurrentDrift = CGVector(dx: 0, dy: 0)
            } else {
                let progress = (driftResetTimer / driftDuration).clamped(to: 0...1)
                let easing = progress * progress
                ctx.autonomy.drift = CGVector(dx: activeCurrentDrift.dx * easing,
                                              dy: activeCurrentDrift.dy * easing)
            }
        }

        // expira ou invalida o objetivo atual
        if var objective = currentObjective {
            objective.timeRemaining -= dt
            if objective.timeRemaining <= 0 || objective.position() == nil {
                currentObjective = nil
            } else {
                currentObjective = objective
            }
        }

        guard ctx.stats.phase != .egg else { return }
        timer -= dt
        if timer <= 0 {
            timer = .random(in: 28...55)
            trigger()
        }
    }

    // MARK: - Objetivos

    private func setObjective(label: String,
                              duration: CGFloat,
                              position: @escaping () -> CGPoint?,
                              pearlReward: Int = 12,
                              onReach: (() -> Void)? = nil) {
        currentObjective = WorldObjective(label: label,
                                          position: position,
                                          pearlReward: pearlReward,
                                          onReach: onReach,
                                          timeRemaining: duration)
    }

    /// A sereia chegou ao objetivo: recompensa e limpa.
    func completeObjective() {
        guard let objective = currentObjective else { return }
        currentObjective = nil
        let basePearls = min(max(objective.pearlReward, objectivePearlReward), maxObjectivePearlReward)
        let gainedPearls = ctx.stats.awardPearls(basePearls)
        ctx.stats.boostMood(6)
        ctx.stats.gainXP(10)
        ctx.stats.curiosity = min(100, ctx.stats.curiosity + 1)
        ctx.stats.addMemory("Investigou \(objective.label)")
        objective.onReach?()
        ctx.say("Ela investigou \(objective.label)! ✨ 🐚+\(gainedPearls)")
    }

    func clearObjective() {
        currentObjective = nil
    }

    private func trigger() {
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        var options: [(weight: Int, run: () -> Void)] = [
            (4, bubbles),
            (3, current),
            (3, glowingFood),
            (2, rareFish)
        ]
        if zone == .blue || zone == .deep || zone == .abyss {
            options.append((3, bigShadow))
        }
        if zone != .surface && zone != .clear {
            options.append((2, specialChallengeFish))
        }
        if ctx.mermaidPosition.y > -2500 {
            options.append((2, boatPassing))
            if ctx.stats.isUnlocked(.surface) {
                options.append((2, fallingObject))
            }
        }
        // o Grande Delta é terra de correntes
        if ctx.regions.currentRegion?.id == "delta" {
            options.append((3, current))
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
        let position = ctx.mermaidPosition
        let horizontalDirection: CGFloat
        if position.x < World.minX + 1400 {
            horizontalDirection = 1
        } else if position.x > World.maxX - 1400 {
            horizontalDirection = -1
        } else {
            horizontalDirection = Bool.random() ? 1 : -1
        }

        let yRange = ctx.depth.allowedYRange()
        let verticalDirection: CGFloat
        if position.y < yRange.lowerBound + 500 {
            verticalDirection = .random(in: 0.08...0.38)
        } else if position.y > yRange.upperBound - 500 {
            verticalDirection = .random(in: -0.38 ... -0.08)
        } else {
            verticalDirection = .random(in: -0.28...0.28)
        }

        let drift = CGVector(dx: horizontalDirection * .random(in: 320...460),
                             dy: verticalDirection * .random(in: 220...320))
        activeCurrentDrift = drift
        driftDuration = .random(in: 4.2...5.4)
        driftResetTimer = driftDuration
        ctx.autonomy.drift = drift
        spawnCurrentBurst(drift: drift, near: position)
        ctx.say("Uma correnteza passou! 🌊")
    }

    private func drainEnergyFromCurrent(dt: CGFloat) {
        let force = (activeCurrentDrift.length / 420).clamped(to: 0.75...1.25)
        ctx.stats.energy = max(0, ctx.stats.energy - currentEnergyDrainPerSecond * force * dt)
    }

    private func spawnCurrentBurst(drift: CGVector, near position: CGPoint) {
        guard let world = worldNode else { return }
        let zone = DepthZone.zone(atY: position.y)
        let speed = max(1, drift.length)
        let unit = CGVector(dx: drift.dx / speed, dy: drift.dy / speed)
        let perp = CGVector(dx: -unit.dy, dy: unit.dx)
        let color = currentBurstColor(for: zone)
        let band = SKNode()
        band.position = position
        band.zPosition = 9
        world.addChild(band)

        for i in 0..<7 {
            let lane = (CGFloat(i) - 3) * CGFloat.random(in: 44...70)
            let length = CGFloat.random(in: 1450...2050)
            let path = UIBezierPath()
            for step in 0...9 {
                let t = CGFloat(step) / 9
                let along = -length / 2 + length * t
                let ripple = sin(t * .pi * 4 + CGFloat(i) * 0.7) * CGFloat.random(in: 18...42)
                let point = CGPoint(x: unit.dx * along + perp.dx * (lane + ripple),
                                    y: unit.dy * along + perp.dy * (lane + ripple))
                if step == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }

            let ribbon = SKShapeNode(path: path.cgPath)
            ribbon.strokeColor = color.withAlphaComponent(CGFloat.random(in: 0.38...0.68))
            ribbon.fillColor = .clear
            ribbon.lineWidth = CGFloat.random(in: 9...17)
            ribbon.glowWidth = CGFloat.random(in: 9...16)
            ribbon.alpha = 0
            band.addChild(ribbon)

            let appear = SKAction.fadeAlpha(to: CGFloat.random(in: 0.72...0.95), duration: 0.16)
            let hold = SKAction.wait(forDuration: Double.random(in: 0.35...0.7))
            let vanish = SKAction.fadeOut(withDuration: Double.random(in: 1.0...1.5))
            ribbon.run(.sequence([appear, hold, vanish]))
        }

        for i in 0..<24 {
            let fleck = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            fleck.fillColor = UIColor(white: 1, alpha: CGFloat.random(in: 0.45...0.82))
            fleck.strokeColor = color.withAlphaComponent(0.45)
            fleck.glowWidth = 2
            let along = CGFloat.random(in: -700...300)
            let lane = CGFloat.random(in: -250...250)
            fleck.position = CGPoint(x: unit.dx * along + perp.dx * lane,
                                     y: unit.dy * along + perp.dy * lane)
            fleck.alpha = 0
            band.addChild(fleck)

            let delay = SKAction.wait(forDuration: Double(i) * 0.015)
            let travel = SKAction.group([
                .fadeAlpha(to: CGFloat.random(in: 0.5...0.9), duration: 0.08),
                .moveBy(x: unit.dx * CGFloat.random(in: 650...1150),
                        y: unit.dy * CGFloat.random(in: 650...1150),
                        duration: Double.random(in: 1.0...1.8))
            ])
            let fade = SKAction.fadeOut(withDuration: 0.45)
            fleck.run(.sequence([delay, travel, fade]))
        }

        let shove = SKAction.moveBy(x: unit.dx * 540, y: unit.dy * 540, duration: 2.2)
        shove.timingMode = .easeOut
        band.run(.sequence([
            .group([shove, .sequence([.wait(forDuration: 1.4), .fadeOut(withDuration: 0.8)])]),
            .removeFromParent()
        ]))
    }

    private func currentBurstColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear:
            return UIColor(red: 0.78, green: 1.0, blue: 0.95, alpha: 1)
        case .shallow:
            return UIColor(red: 0.38, green: 0.95, blue: 0.78, alpha: 1)
        case .mid:
            return UIColor(red: 0.25, green: 0.78, blue: 0.95, alpha: 1)
        case .blue:
            return UIColor(red: 0.28, green: 0.56, blue: 1.0, alpha: 1)
        case .deep:
            return UIColor(red: 0.30, green: 0.44, blue: 0.90, alpha: 1)
        case .abyss:
            return UIColor(red: 0.45, green: 0.36, blue: 0.95, alpha: 1)
        }
    }

    private func glowingFood() {
        guard let food = ctx.food.spawnRare(near: ctx.mermaidPosition) else { return }
        ctx.say("Algo brilhante apareceu por perto... ✨ (Objetivo disponível)")
        setObjective(label: "algo brilhante",
                     duration: 60,
                     position: { [weak food] in
                         guard let food, food.parent != nil else { return nil }
                         return food.position
                     })
    }

    private func rareFish() {
        guard let world = worldNode else { return }
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        guard let fish = ctx.fish.spawnFish(zone: zone, near: ctx.mermaidPosition, rare: true) else { return }
        ctx.say("Um peixe raro está passando! 👀 (Objetivo disponível)")
        setObjective(label: "o peixe raro",
                     duration: 45,
                     position: { [weak fish] in
                         guard let fish, fish.parent != nil else { return nil }
                         return fish.position
                     },
                     onReach: { [weak self] in
                         self?.ctx.stats.awardPearls(1)
                     })

        // se ela estiver por perto quando ele some, vira memória
        world.run(.sequence([
            .wait(forDuration: 6),
            .run { [weak self] in
                guard let self else { return }
                if fish.position.distance(to: self.ctx.mermaidPosition) < 600 {
                    self.ctx.stats.gainXP(15)
                    let gained = self.ctx.stats.awardPearls(2)
                    self.ctx.stats.addMemory("Viu um peixe raro em \(zone.displayName)")
                    self.ctx.say("Ela observou o peixe raro de pertinho! ✨ 🐚+\(gained)")
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

    private func specialChallengeFish() {
        let zone = DepthZone.zone(atY: ctx.mermaidPosition.y)
        ctx.challenges.spawnSpecialGiver(near: ctx.mermaidPosition, zone: zone)
        ctx.say("Um peixe dourado trouxe um Desafio especial! 💎🏆")
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
        let landingY = max(ctx.mermaidPosition.y, -2200) - .random(in: 0...150)

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
        ctx.say("Algo caiu da superfície! 📦 (Objetivo disponível)")

        let landingPoint = CGPoint(x: x, y: landingY)
        setObjective(label: "o objeto que caiu",
                     duration: 75,
                     position: { landingPoint })
    }
}
