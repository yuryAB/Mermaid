//
//  GameScene.swift
//  Ester
//
//  Created by yury antony on 11/06/24.
//
//  Cena principal: mundo vertical de profundidade, sereia autônoma,
//  sistemas de cuidado (fome/energia/humor), comida e peixes procedurais,
//  eventos ambientais e puzzles Match-3 integrados ao mundo.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var cameraNode: SKCameraNode!
    private var worldNode: SKNode!
    private var entityManager: EntityManager!
    private var mermaidEntity: MermaidEntity!
    private var hud: HUDLayer!
    private var match3Overlay: Match3Overlay?

    private let ctx = GameContext()
    private var stats: MermaidStats!

    private var lastUpdateTime: TimeInterval = 0
    private var saveTimer: CGFloat = 0

    // MARK: - Setup

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero

        stats = MermaidStats.load()
        ctx.stats = stats
        ctx.scene = self

        worldNode = SKNode()
        addChild(worldNode)
        backgroundColor = ColorManager.shared.waters["shallow"]!
        setupEnvironmentDecor()

        setupMermaid()
        setupSystems()
        setupCamera()
        setupHUD()
        setupAmbientBubbles()

        ctx.growth.setup()
        snapCameraToTarget()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(saveOnBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self else { return }
                if self.stats.phase == .egg {
                    self.ctx.say("Um ovo misterioso... Toque nele para aquecê-lo! 🥚")
                } else {
                    self.ctx.say("Bem-vindo de volta! Ela sentiu sua falta. 🌊")
                }
            },
            .wait(forDuration: 13),
            .run { [weak self] in
                guard let self else { return }
                if self.stats.phase == .egg && self.stats.hatchProgress < 0.6 {
                    self.ctx.say("Dica: desafios Match-3 também aquecem o ovo 💎")
                }
            }
        ]))
    }

    private func setupMermaid() {
        entityManager = EntityManager()
        mermaidEntity = MermaidEntity()
        entityManager.addEntity(mermaidEntity, to: worldNode)
        ctx.mermaidEntity = mermaidEntity

        let mermaid = mermaidEntity.mermaid
        mermaid.base.zPosition = 10
        mermaid.base.setScale(stats.phase.scale)
        mermaid.base.position = CGPoint(x: stats.posX, y: stats.posY)
        mermaid.setAnimationMode(.idle)
    }

    private func setupSystems() {
        ctx.depth = DepthSystem(ctx: ctx)
        ctx.autonomy = AutonomySystem(ctx: ctx)
        ctx.food = FoodSystem(ctx: ctx, worldNode: worldNode)
        ctx.fish = FishSystem(ctx: ctx, worldNode: worldNode)
        ctx.shelter = ShelterSystem(ctx: ctx)
        ctx.shelter.setup(in: worldNode)
        ctx.match3 = Match3System(ctx: ctx, worldNode: worldNode)
        ctx.events = EventSystem(ctx: ctx, worldNode: worldNode)
        ctx.growth = GrowthSystem(ctx: ctx, worldNode: worldNode)
    }

    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.setScale(2.0)
        camera = cameraNode
        addChild(cameraNode)
    }

    private func setupHUD() {
        let insets = view?.safeAreaInsets ?? .zero
        hud = HUDLayer(size: size, insets: insets)
        hud.zPosition = 100
        hud.onCommand = { [weak self] command in
            self?.ctx.autonomy.give(command)
        }
        ctx.hud = hud
        cameraNode.addChild(hud)
    }

    private func setupEnvironmentDecor() {
        // céu acima da linha d'água
        let sky = SKShapeNode(rect: CGRect(x: World.minX - 400, y: World.waterlineY,
                                           width: (World.maxX - World.minX) + 800, height: 1200))
        sky.fillColor = UIColor.lerp(ColorManager.shared.waters["surface"]!, .white, 0.45)
        sky.strokeColor = .clear
        sky.zPosition = -50
        worldNode.addChild(sky)

        // faixa cintilante na linha d'água
        let waterline = SKShapeNode(rect: CGRect(x: World.minX - 400, y: World.waterlineY - 10,
                                                 width: (World.maxX - World.minX) + 800, height: 20))
        waterline.fillColor = UIColor(white: 1, alpha: 0.4)
        waterline.strokeColor = .clear
        waterline.zPosition = -40
        worldNode.addChild(waterline)
        waterline.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.25, duration: 1.8),
            .fadeAlpha(to: 0.5, duration: 1.8)
        ])))

        // raios de luz perto da linha d'água (vistos só na Camada Clara)
        for i in 0..<5 {
            let ray = SKShapeNode(path: {
                let path = UIBezierPath()
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 120, y: 0))
                path.addLine(to: CGPoint(x: 380, y: -1800))
                path.addLine(to: CGPoint(x: 100, y: -1800))
                path.close()
                return path.cgPath
            }())
            ray.fillColor = UIColor(white: 1, alpha: 0.07)
            ray.strokeColor = .clear
            ray.zPosition = -30
            ray.position = CGPoint(x: -3000 + CGFloat(i) * 1500, y: World.waterlineY)
            worldNode.addChild(ray)
        }

        // leito do abismo
        let floor = SKShapeNode(rect: CGRect(x: World.minX - 400, y: World.floorY - 500,
                                             width: (World.maxX - World.minX) + 800, height: 520))
        floor.fillColor = UIColor(white: 0.02, alpha: 1)
        floor.strokeColor = .clear
        floor.zPosition = -40
        worldNode.addChild(floor)
    }

    private func setupAmbientBubbles() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "bubble")
        emitter.particleBirthRate = 1.5
        emitter.particleLifetime = 7
        emitter.particleLifetimeRange = 3
        emitter.particleSpeed = 55
        emitter.particleSpeedRange = 30
        emitter.emissionAngle = .pi / 2
        emitter.particleAlpha = 0.3
        emitter.particleAlphaRange = 0.2
        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.08
        emitter.particlePositionRange = CGVector(dx: size.width * 2.6, dy: size.height * 1.4)
        emitter.zPosition = 2
        emitter.targetNode = worldNode
        cameraNode.addChild(emitter)
    }

    // MARK: - Loop principal

    override func update(_ currentTime: TimeInterval) {
        var dt: CGFloat = lastUpdateTime == 0 ? 0.016 : CGFloat(currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        dt = min(dt, 0.1)

        ctx.growth.update(dt: dt)
        ctx.autonomy.update(dt: dt)
        ctx.depth.update(dt: dt)
        ctx.food.update(dt: dt)
        ctx.fish.update(dt: dt)
        ctx.events.update(dt: dt)
        ctx.shelter.update(dt: dt)
        ctx.match3.update(dt: dt)

        let mermaidY = ctx.mermaidPosition.y
        backgroundColor = ctx.depth.waterColor(atY: mermaidY)

        hud.refresh(stats: stats,
                    intent: ctx.autonomy.intent,
                    zone: ctx.depth.currentZone,
                    depthMeters: max(0, -mermaidY / 10),
                    evolutionProgress: ctx.growth.progressToNext(),
                    shelterCapacity: ctx.shelter.capacity)

        updateCamera(dt: dt)

        saveTimer += dt
        if saveTimer > 20 {
            saveTimer = 0
            persistAndSave()
        }
    }

    private func persistAndSave() {
        let position = ctx.mermaidPosition
        stats.posX = position.x
        stats.posY = position.y
        stats.save()
    }

    private var cameraTarget: CGPoint {
        ctx.growth.eggNode?.position ?? ctx.mermaidPosition
    }

    private func updateCamera(dt: CGFloat) {
        let target = clampedCameraPosition(cameraTarget)
        let blend = min(1, dt * 3)
        cameraNode.position = CGPoint(
            x: cameraNode.position.x + (target.x - cameraNode.position.x) * blend,
            y: cameraNode.position.y + (target.y - cameraNode.position.y) * blend
        )
    }

    private func snapCameraToTarget() {
        cameraNode.position = clampedCameraPosition(cameraTarget)
    }

    private func clampedCameraPosition(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x.clamped(to: (World.minX + 700)...(World.maxX - 700)),
                y: p.y.clamped(to: (World.floorY + 500)...500))
    }

    // MARK: - Match-3

    var isPuzzleOpen: Bool { match3Overlay != nil }

    func openMatch3(zone: DepthZone, special: Bool) {
        guard match3Overlay == nil else { return }
        stats.energy = max(0, stats.energy - 8)
        ctx.autonomy.paused = true

        // bem-estar alto melhora as recompensas (0.7x – 1.1x)
        let multiplier = 0.7 + stats.wellbeing / 250
        let overlay = Match3Overlay(size: size,
                                    zone: zone,
                                    special: special,
                                    rewardMultiplier: multiplier) { [weak self] result in
            self?.closeMatch3(result: result, zone: zone)
        }
        overlay.zPosition = 200
        cameraNode.addChild(overlay)
        match3Overlay = overlay
        ctx.match3.clearPoint()
    }

    private func closeMatch3(result: Match3Result, zone: DepthZone) {
        match3Overlay?.removeFromParent()
        match3Overlay = nil

        stats.pearls += result.pearls
        stats.gainXP(result.xp)

        // Durante o ovo, o desafio serve para aquecer o choco
        if stats.phase == .egg {
            ctx.growth.addHatchProgress(CGFloat(result.score) / 900)
            stats.save()
            ctx.say("O desafio aqueceu o ovo! 🥚✨ 💠+\(result.pearls)")
            return
        }

        ctx.autonomy.paused = false
        ctx.autonomy.finishPuzzle()
        stats.boostMood(8)
        let adaptation = stats.adaptation(for: zone)
        stats.setAdaptation(adaptation + 3, for: zone)
        stats.courage = min(100, stats.courage + (result.special ? 2 : 0.5))
        if result.reachedTarget {
            stats.puzzlesSolved += 1
            stats.addMemory("Resolveu um desafio em \(zone.displayName)")
        }
        stats.save()
        ctx.say(result.reachedTarget
                ? "Ela adorou o desafio! 💠+\(result.pearls)"
                : "Quase! Ainda assim ganhou 💠+\(result.pearls)")
    }

    // MARK: - Toques no mundo

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard match3Overlay == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let egg = ctx.growth.eggNode,
           egg.position.distance(to: location) < 180 {
            ctx.growth.tapEgg()
            return
        }
        if ctx.shelter.position.distance(to: location) < 320 {
            ctx.shelter.tryUpgrade()
            return
        }
        if let point = ctx.match3.puzzlePoint,
           point.position.distance(to: location) < 200 {
            ctx.autonomy.give(.challenge)
            return
        }
    }

    // MARK: - Persistência

    @objc private func saveOnBackground() {
        persistAndSave()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
