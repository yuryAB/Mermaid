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
    private var plotOverlay: TideWeavingOverlay?
    private var climbOverlay: BubbleClimbOverlay?
    private var regionMenu: RegionMenuOverlay?
    private var refugeOverlay: RefugeOverlay?
    private var refugePortal: RefugePortalNode?
    private var rigDebugTool: MermaidRigDebugTool?
    private var showDebugControls: Bool {
#if DEBUG || DEVELOPMENT || DEV
        true
#else
        false
#endif
    }

    private let ctx = GameContext()
    private var stats: MermaidStats!
    private var offlineSummary: String?

    private var lastUpdateTime: TimeInterval = 0
    private var saveTimer: CGFloat = 0

    // MARK: - Setup

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero

        stats = MermaidStats.load()
        offlineSummary = OfflineProgressSystem.apply(stats: stats)
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
            .wait(forDuration: 2.5),
            .run { [weak self] in
                guard let self else { return }
                if let summary = self.offlineSummary {
                    self.ctx.say(summary)
                    self.offlineSummary = nil
                }
            },
            .wait(forDuration: 11),
            .run { [weak self] in
                guard let self else { return }
                if self.stats.phase == .egg && self.stats.hatchProgress < 0.6 {
                    self.ctx.say("Jogue o Desafio: Trama para reunir energia de nascimento 🌀")
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
        if stats.phase != .egg {
            mermaid.setForm(for: stats.phase)
        }
        mermaid.setAnimationMode(.idle)
    }

    private func setupSystems() {
        ctx.depth = DepthSystem(ctx: ctx)
        ctx.autonomy = AutonomySystem(ctx: ctx)
        ctx.food = FoodSystem(ctx: ctx, worldNode: worldNode)
        ctx.fish = FishSystem(ctx: ctx, worldNode: worldNode)
        ctx.shelter = ShelterSystem(ctx: ctx)
        ctx.challenges = ChallengeSystem(ctx: ctx)
        ctx.events = EventSystem(ctx: ctx, worldNode: worldNode)
        ctx.growth = GrowthSystem(ctx: ctx, worldNode: worldNode)
        ctx.regions = RegionDiscoverySystem(ctx: ctx)
        ctx.travel = TravelSystem(ctx: ctx)
    }

    /// Quanto descer os painéis modais (desafios) para escaparem da
    /// Dynamic Island. Usa a safe area, com um mínimo de segurança.
    private var modalDropOffset: CGFloat {
        max(view?.safeAreaInsets.top ?? 0, 44)
    }

    private func setupCamera() {
        cameraNode = SKCameraNode()
        cameraNode.setScale(2.0)
        camera = cameraNode
        addChild(cameraNode)
    }

    private func setupHUD() {
        let insets = view?.safeAreaInsets ?? .zero
        hud = HUDLayer(size: size, insets: insets, enableDebugRigToolButton: showDebugControls)
        hud.zPosition = 100
        hud.onCommand = { [weak self] command in
            self?.ctx.autonomy.give(command)
        }
        if showDebugControls {
            hud.onDebugRigToolTap = { [weak self] in
                self?.openRigDebugTool()
            }
        }
        ctx.hud = hud
        cameraNode.addChild(hud)
    }

    private func openRigDebugTool() {
        guard showDebugControls else { return }
        if rigDebugTool != nil {
            closeRigDebugTool()
            return
        }

        closeRegionMenu()
        closeRefuge(resume: false)
        refugePortal?.close()
        refugePortal = nil
        ctx.autonomy.cancelRefugeEntry()
        ctx.autonomy.paused = true

        let tool = MermaidRigDebugTool(size: size,
                                       insets: view?.safeAreaInsets ?? .zero,
                                       initialForm: mermaidEntity.mermaid.formKind)
        tool.zPosition = 260
        tool.onClose = { [weak self] in
            self?.closeRigDebugTool()
        }
        cameraNode.addChild(tool)
        rigDebugTool = tool
    }

    private func closeRigDebugTool() {
        rigDebugTool?.removeFromParent()
        rigDebugTool = nil
        if stats.phase != .egg {
            ctx.autonomy.paused = false
            mermaidEntity.mermaid.setForm(for: stats.phase)
            mermaidEntity.mermaid.base.setScale(stats.phase.scale)
            mermaidEntity.mermaid.applyIdleMoveMode()
        }
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
        ctx.regions.update(dt: dt)
        ctx.travel.update(dt: dt)

        // o desafio de subida precisa de loop próprio
        climbOverlay?.update(dt: dt)

        // no Refúgio o tempo é gentil: descanso acelerado
        if let refuge = refugeOverlay {
            refuge.update(dt: dt)
            stats.tick(dt: dt, energyDelta: 2.2)
        }

        let mermaidPosition = ctx.mermaidPosition
        var water = ctx.depth.waterColor(atY: mermaidPosition.y)
        if let tint = ctx.regions.waterTint(at: mermaidPosition) {
            water = .lerp(water, tint.color, tint.strength)
        }
        backgroundColor = water

        hud.refresh(stats: stats,
                    intent: ctx.autonomy.intent,
                    zone: ctx.depth.currentZone,
                    regionName: ctx.regions.currentRegion?.name,
                    evolutionProgress: ctx.growth.progressToNext(),
                    evolutionNote: ctx.growth.evolutionNote(),
                    shelterCapacity: ctx.shelter.capacity,
                    objectiveAvailable: ctx.events.currentObjective != nil)

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

    // MARK: - Menu de regiões

    func openRegionMenu() {
        guard regionMenu == nil, !isChallengeOpen, refugeOverlay == nil else { return }
        let menu = RegionMenuOverlay(size: size,
                                     stats: stats,
                                     currentRegionId: ctx.regions.currentRegion?.id,
                                     destinationId: stats.destinationRegionId,
                                     onSelect: { [weak self] region in
                                         self?.ctx.travel.setDestination(region)
                                         self?.closeRegionMenu()
                                     },
                                     onClose: { [weak self] in
                                         self?.closeRegionMenu()
                                     })
        menu.zPosition = 190
        cameraNode.addChild(menu)
        regionMenu = menu
    }

    private func closeRegionMenu() {
        regionMenu?.removeFromParent()
        regionMenu = nil
    }

    // MARK: - Refúgio das Marés (com portal de verdade)

    /// Passo 1: um portal se abre perto da sereia e ela nada até ele.
    func beginRefugeEntry() {
        guard refugeOverlay == nil, !isChallengeOpen, refugePortal == nil else { return }
        closeRegionMenu()

        let mermaidPos = ctx.mermaidPosition
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 260...340)
        let yRange = ctx.depth.allowedYRange()
        let portal = RefugePortalNode()
        portal.position = CGPoint(
            x: (mermaidPos.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (mermaidPos.y + sin(angle) * distance).clamped(to: yRange)
        )
        worldNode.addChild(portal)
        portal.open()
        refugePortal = portal

        ctx.autonomy.goToRefugePortal(at: portal.position)
        ctx.say("Um portal para o Refúgio se abriu ali perto... 🌀")
    }

    /// Passo 2: ela chegou ao portal — entra devagar e some nele.
    func mermaidReachedRefugePortal() {
        guard let portal = refugePortal else { return }
        ctx.autonomy.paused = true

        let base = mermaidEntity.mermaid.base
        let enter = SKAction.group([
            .move(to: portal.position, duration: 0.6),
            .scale(to: 0.02, duration: 0.6),
            .fadeOut(withDuration: 0.6)
        ])
        enter.eaeInEaseOut()
        base.run(.sequence([
            enter,
            .wait(forDuration: 0.25),
            .run { [weak self] in self?.presentRefuge() }
        ]))
        portal.close(after: 0.7)
    }

    /// Passo 3: só agora o Refúgio aparece.
    private func presentRefuge() {
        refugePortal = nil

        // restaura o visual dela (fica escondida atrás do overlay)
        let base = mermaidEntity.mermaid.base
        base.removeAllActions()
        base.alpha = 1
        base.setScale(stats.phase.scale)
        mermaidEntity.mermaid.applyIdleMoveMode()

        let overlay = RefugeOverlay(size: size,
                                    insets: view?.safeAreaInsets ?? .zero,
                                    ctx: ctx,
                                    onClose: { [weak self] in
                                        self?.closeRefuge(resume: true)
                                    })
        overlay.zPosition = 195
        cameraNode.addChild(overlay)
        refugeOverlay = overlay
    }

    private func closeRefuge(resume: Bool) {
        guard refugeOverlay != nil else { return }
        refugeOverlay?.removeFromParent()
        refugeOverlay = nil
        if resume {
            if stats.phase != .egg {
                ctx.autonomy.paused = false
            }
            persistAndSave()
            ctx.say("De volta ao oceano, do mesmo lugar de antes 🌊")
        }
    }

    // MARK: - Desafios

    var isChallengeOpen: Bool { plotOverlay != nil || climbOverlay != nil }

    /// Abre o desafio oferecido por um NPC (hoje, um peixe).
    func openChallenge(giver: FishNode) {
        guard !isChallengeOpen, refugeOverlay == nil else { return }
        guard let kind = giver.offeredChallenge else { return }
        let special = giver.isSpecialChallenge
        let giverDisplay = giver.makeGiverDisplayNode()
        ctx.challenges.consumeChallenge(of: giver)
        presentChallenge(kind: kind, special: special, giverDisplay: giverDisplay)
    }

    /// Durante o ovo: o Desafio: Trama abre direto (energia de nascimento).
    func openHatchingChallenge() {
        guard !isChallengeOpen, refugeOverlay == nil else { return }
        presentChallenge(kind: .plot, special: false, giverDisplay: nil, hatching: true)
    }

    private func presentChallenge(kind: ChallengeKind,
                                  special: Bool,
                                  giverDisplay: SKNode?,
                                  hatching: Bool = false) {
        closeRegionMenu()
        let zone = ctx.depth.currentZone
        stats.energy = max(0, stats.energy - 8)
        ctx.autonomy.paused = true

        // bem-estar alto melhora as recompensas (0.7x – 1.1x)
        let multiplier = 0.7 + stats.wellbeing / 250

        switch kind {
        case .plot:
            let session: TideSessionType
            if hatching || stats.phase == .egg {
                session = .hatching
            } else if special {
                session = .event
            } else if ctx.regions.currentRegion != nil {
                session = .region
            } else {
                session = .basic
            }
            let overlay = TideWeavingOverlay(size: size,
                                             zone: zone,
                                             region: ctx.regions.currentRegion,
                                             session: session,
                                             rewardMultiplier: multiplier,
                                             giverDisplay: giverDisplay) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            plotOverlay = overlay

        case .ascent:
            let overlay = BubbleClimbOverlay(size: size,
                                             phase: stats.phase,
                                             palette: ctx.depth.mermaidPalette(atY: ctx.mermaidPosition.y),
                                             special: special,
                                             rewardMultiplier: multiplier,
                                             giverDisplay: giverDisplay) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            climbOverlay = overlay
        }
    }

    private func closeChallenge(result: ChallengeResult, zone: DepthZone) {
        plotOverlay?.removeFromParent()
        plotOverlay = nil
        climbOverlay?.removeFromParent()
        climbOverlay = nil

        stats.pearls += result.pearls
        stats.gainXP(result.xp)

        // Durante o ovo, o desafio reúne energia de nascimento
        if result.isHatching || stats.phase == .egg {
            ctx.growth.addHatchProgress(CGFloat(result.score) / 900)
            stats.save()
            ctx.say("O desafio reuniu energia de nascimento! 🥚✨ 💠+\(result.pearls)")
            return
        }

        ctx.autonomy.paused = false
        ctx.autonomy.finishChallenge()
        stats.boostMood(8)
        let adaptation = stats.adaptation(for: zone)
        stats.setAdaptation(adaptation + 3, for: zone)
        stats.courage = min(100, stats.courage + (result.special ? 2 : 0.5))
        if result.reachedTarget {
            stats.puzzlesSolved += 1
            stats.addMemory("Venceu o \(result.kind.title) em \(zone.displayName)")
        }
        stats.save()
        ctx.say(result.reachedTarget
                ? "Ela adorou o \(result.kind.title)! 💠+\(result.pearls)"
                : "Quase! Ainda assim ganhou 💠+\(result.pearls)")
    }

    // MARK: - Toques no mundo

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isChallengeOpen, regionMenu == nil, refugeOverlay == nil, rigDebugTool == nil,
              let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let egg = ctx.growth.eggNode,
           egg.position.distance(to: location) < 180 {
            ctx.growth.tapEgg()
            return
        }
        // tocar num peixe com desafio também manda ela para lá
        if ctx.challenges.nearestGiver(to: location, maxDistance: 160) != nil {
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
