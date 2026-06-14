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
import UIKit

class GameScene: SKScene {
    class var defaultRegionId: String? { nil }

    private let requestedRegionId: String?
    var shouldAnnounceArrival = false
    private var cameraNode: SKCameraNode!
    private var worldNode: SKNode!
    private var entityManager: EntityManager!
    private var mermaidEntity: MermaidEntity!
    private var hud: HUDLayer!
    private var plotOverlay: TideWeavingOverlay?
    private var climbOverlay: BubbleClimbOverlay?
    private var pendingPOIChallengeCompletion: ((ChallengeResult) -> Void)?
    private var challengeBackdrop: SKNode?
    private var regionMenu: RegionMenuOverlay?
    private var refugeOverlay: RefugeOverlay?
    private var refugePortal: RefugePortalNode?
    private var rigDebugTool: MermaidRigDebugTool?
    private var oceanBackdrop: OceanParallaxBackdrop?
    private var worldChunkManager: WorldChunkManager?
    private var temporaryCompanionNode: SKNode?
    private var temporaryCompanionTitle: String?
    private var temporaryCompanionPhase: CGFloat = 0
    private var showDebugControls: Bool {
#if DEBUG || DEVELOPMENT || DEV
        true
#else
        false
#endif
    }
    private let showRigDebugButton = false

    private let ctx = GameContext()
    private var stats: MermaidStats!
    private var activeRegion: Region!
    private var offlineSummary: String?
    private var lastEntryTextZone: DepthZone?

    private var lastUpdateTime: TimeInterval = 0
    private var saveTimer: CGFloat = 0

    // MARK: - Setup

    override init(size: CGSize) {
        requestedRegionId = Self.defaultRegionId
        super.init(size: size)
    }

    init(size: CGSize, regionId: String?) {
        requestedRegionId = regionId
        shouldAnnounceArrival = true
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        requestedRegionId = nil
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        GameAudio.shared.configure()
        GameAudio.shared.preloadCoreSounds()

        stats = MermaidStats.load()
        offlineSummary = OfflineProgressSystem.apply(stats: stats)
        ctx.stats = stats
        ctx.scene = self
        configureActiveRegion()

        worldNode = SKNode()
        addChild(worldNode)
        backgroundColor = ColorManager.shared.waters["shallow"]!
        setupEnvironmentDecor()

        setupMermaid()
        setupSystems()
        setupCamera()
        setupOceanBackdrop()
        setupHUD()
        setupAmbientBubbles()
        lastEntryTextZone = DepthZone.zone(atY: stats.posY)

        ctx.growth.setup()
        snapCameraToTarget()
        worldChunkManager?.update(dt: 1, cameraPosition: cameraNode.position)
        updateOceanBackdrop(dt: 0, waterColor: ctx.depth.waterColor(atY: cameraNode.position.y))
        GameAudio.shared.updateOceanAmbience(for: ctx.depth.currentZone)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(saveOnBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                guard let self else { return }
                if self.shouldAnnounceArrival {
                    GameAudio.shared.play(.travelArrive)
                    if let zone = self.lastEntryTextZone,
                       self.showEntryTextIfNeeded(for: zone) {
                        return
                    } else {
                        self.ctx.say("Chegada registrada: \(self.activeRegion.name).")
                    }
                } else if self.stats.phase == .egg {
                    self.ctx.say("Um ovo misterioso... Toque nele para aquecê-lo! 🥚")
                } else if let zone = self.lastEntryTextZone,
                          self.showEntryTextIfNeeded(for: zone) {
                    return
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

    private func configureActiveRegion() {
        let fallback = RegionDiscoverySystem.region(withId: "nascente")!
        let requestedId = requestedRegionId ?? stats.currentRegionId
        let resolved = RegionDiscoverySystem.region(withId: requestedId) ?? fallback
        let phaseAllowsRegion = stats.phase == .egg
            ? resolved.id == fallback.id
            : stats.phase >= resolved.minPhase
        let region = phaseAllowsRegion ? resolved : fallback
        let shouldUseStoredPosition = requestedRegionId == nil
            && region.playableXRange.contains(stats.posX)
            && (World.floorY...World.surfaceTopY).contains(stats.posY)
        let destinationPoint = shouldUseStoredPosition
            ? CGPoint(x: stats.posX, y: stats.posY)
            : (stats.savedMapPosition(for: region) ?? stats.entryPoint(for: region))
        let yRange = DepthSystem.allowedYRange(for: stats)
        let clampedPoint = CGPoint(x: destinationPoint.x.clamped(to: region.playableXRange),
                                   y: destinationPoint.y.clamped(to: yRange))

        activeRegion = region
        ctx.activeRegion = region
        stats.currentRegionId = region.id
        stats.discoveredRegionIds.insert(region.id)
        stats.posX = clampedPoint.x
        stats.posY = clampedPoint.y
        stats.rememberMapPosition(clampedPoint, in: region)
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
        ctx.challenges = ChallengeSystem(ctx: ctx)
        ctx.rewards = RewardSystem(ctx: ctx)
        ctx.events = EventSystem(ctx: ctx, worldNode: worldNode)
        ctx.growth = GrowthSystem(ctx: ctx, worldNode: worldNode)
        ctx.regions = RegionDiscoverySystem(ctx: ctx)
        ctx.travel = TravelSystem(ctx: ctx)
        ctx.pois = POISystem(ctx: ctx, worldNode: worldNode)
    }

    private func setupOceanBackdrop() {
        let backdrop = OceanParallaxBackdrop(size: size)
        backdrop.zPosition = -90
        addChild(backdrop)
        oceanBackdrop = backdrop
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
        hud = HUDLayer(size: size, insets: insets, enableDebugRigToolButton: showRigDebugButton)
        hud.zPosition = 100
        hud.onCommand = { [weak self] command in
            self?.ctx.autonomy.give(command)
        }
        hud.onGiveSpaceTap = { [weak self] in
            self?.ctx.autonomy.startGivingSpace()
        }
        hud.onNameEditTap = { [weak self] in
            self?.openMermaidNameEditor()
        }
        if showRigDebugButton {
            hud.onDebugRigToolTap = { [weak self] in
                self?.openRigDebugTool()
            }
        }
        ctx.hud = hud
        cameraNode.addChild(hud)
    }

    private func openMermaidNameEditor() {
        guard let presenter = view?.window?.rootViewController else { return }
        let alert = UIAlertController(title: "Nome da sereia",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { [weak self] field in
            field.text = self?.stats.mermaidName
            field.placeholder = "Eistrelinha"
            field.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Salvar", style: .default) { [weak self, weak alert] _ in
            guard let self else { return }
            let rawName = alert?.textFields?.first?.text ?? ""
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            self.stats.mermaidName = trimmed.isEmpty ? "Eistrelinha" : trimmed
            self.persistAndSave()
        })
        presenter.present(alert, animated: true)
    }

    private func openRigDebugTool() {
        guard showRigDebugButton else { return }
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
            let mermaid = mermaidEntity.mermaid
            mermaid.setForm(for: stats.phase)
            mermaid.reloadForm()
            mermaid.base.setScale(stats.phase.scale)
            mermaid.applyIdleMoveMode()
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

        setupDepthVeils()
        worldChunkManager = WorldChunkManager(parent: worldNode)
    }

    private func setupDepthVeils() {
        let width = (World.maxX - World.minX) + 1200
        for zone in DepthZone.allCases where zone != .surface {
            let rect = CGRect(x: World.minX - 600,
                              y: zone.yRange.lowerBound,
                              width: width,
                              height: zone.yRange.upperBound - zone.yRange.lowerBound)
            let veil = SKShapeNode(rect: rect)
            veil.fillColor = OceanPalette.veilColor(for: zone)
            veil.strokeColor = .clear
            veil.zPosition = -49
            worldNode.addChild(veil)
        }
    }

    private func setupCurrentRibbons() {
        let zones: [DepthZone] = [.clear, .shallow, .mid, .blue, .deep]
        let width = (World.maxX - World.minX) + 1000
        for zone in zones {
            let ribbonCount = zone == .deep ? 7 : 10
            for _ in 0..<ribbonCount {
                let y = CGFloat.random(in: (zone.yRange.lowerBound + 240)...(zone.yRange.upperBound - 160))
                let path = UIBezierPath()
                path.move(to: CGPoint(x: World.minX - 500, y: y))
                let segments = 16
                for step in 1...segments {
                    let x = World.minX - 500 + width * CGFloat(step) / CGFloat(segments)
                    let wave = sin(CGFloat(step) * 0.9 + CGFloat.random(in: -0.4...0.4)) * CGFloat.random(in: 35...90)
                    path.addLine(to: CGPoint(x: x, y: y + wave))
                }

                let ribbon = SKShapeNode(path: path.cgPath)
                ribbon.strokeColor = OceanPalette.currentColor(for: zone)
                ribbon.fillColor = .clear
                ribbon.lineWidth = CGFloat.random(in: 5...11)
                ribbon.glowWidth = CGFloat.random(in: 5...13)
                let baseAlpha = CGFloat.random(in: 0.28...0.52)
                ribbon.alpha = baseAlpha
                ribbon.zPosition = -18
                worldNode.addChild(ribbon)

                let low = SKAction.fadeAlpha(to: baseAlpha * 0.5, duration: Double.random(in: 3.0...5.2))
                let high = SKAction.fadeAlpha(to: baseAlpha, duration: Double.random(in: 3.0...5.2))
                low.eaeInEaseOut()
                high.eaeInEaseOut()

                let direction: CGFloat = Bool.random() ? 1 : -1
                let drift = SKAction.moveBy(x: direction * CGFloat.random(in: 110...240),
                                            y: CGFloat.random(in: -18...18),
                                            duration: Double.random(in: 5.5...8.5))
                let returnDrift = drift.reversed()
                drift.eaeInEaseOut()
                returnDrift.eaeInEaseOut()
                ribbon.run(.repeatForever(.group([
                    .sequence([low, high]),
                    .sequence([drift, returnDrift])
                ])))
            }
        }
    }

    private func setupReefGardens() {
        let plan: [(DepthZone, Int)] = [
            (.clear, 10),
            (.shallow, 18),
            (.mid, 16),
            (.blue, 13),
            (.deep, 9),
            (.abyss, 8)
        ]

        for (zone, count) in plan {
            for _ in 0..<count {
                addReefGarden(for: zone,
                              at: randomGardenPoint(in: zone),
                              scale: CGFloat.random(in: 0.75...1.7))
            }
        }

        let homeOffsets = [
            CGPoint(x: -560, y: -220),
            CGPoint(x: 520, y: 140),
            CGPoint(x: 120, y: -520),
            CGPoint(x: -120, y: 420)
        ]
        for offset in homeOffsets {
            addReefGarden(for: .mid,
                          at: CGPoint(x: World.startPosition.x + offset.x,
                                      y: (World.startPosition.y + offset.y).clamped(to: DepthZone.mid.yRange)),
                          scale: CGFloat.random(in: 0.9...1.45))
        }

        for zone in [DepthZone.clear, .shallow, .mid, .blue, .deep, .abyss] {
            for offset in [-520, 540] {
                addReefGarden(for: zone,
                              at: CGPoint(x: CGFloat(offset),
                                          y: (zone.midY + CGFloat.random(in: -520...520)).clamped(to: zone.yRange)),
                              scale: CGFloat.random(in: 0.8...1.35))
            }
        }
    }

    private func addReefGarden(for zone: DepthZone, at position: CGPoint, scale: CGFloat) {
        let garden = makeReefGarden(for: zone, scale: scale)
        garden.position = position
        garden.zPosition = CGFloat.random(in: -8...1)
        worldNode.addChild(garden)
    }

    private func randomGardenPoint(in zone: DepthZone) -> CGPoint {
        let y = CGFloat.random(in: (zone.yRange.lowerBound + 320)...(zone.yRange.upperBound - 220))
        return CGPoint(x: CGFloat.random(in: (World.minX + 700)...(World.maxX - 700)), y: y)
    }

    private func makeReefGarden(for zone: DepthZone, scale: CGFloat) -> SKNode {
        let garden = SKNode()
        garden.setScale(scale)

        let baseWidth = CGFloat.random(in: 150...330)
        let baseHeight = CGFloat.random(in: 28...74)
        let rock = SKShapeNode(ellipseOf: CGSize(width: baseWidth, height: baseHeight))
        rock.fillColor = OceanPalette.rockColor(for: zone)
        rock.strokeColor = OceanPalette.edgeColor(for: zone)
        rock.lineWidth = 2
        rock.alpha = CGFloat.random(in: 0.48...0.74)
        rock.zPosition = -2
        garden.addChild(rock)

        let kelpCount = zone == .deep || zone == .abyss ? Int.random(in: 1...3) : Int.random(in: 3...7)
        for _ in 0..<kelpCount {
            let height = OceanPalette.kelpHeight(for: zone) * CGFloat.random(in: 0.72...1.25)
            let frond = makeKelpFrond(height: height,
                                      color: OceanPalette.kelpColor(for: zone),
                                      width: CGFloat.random(in: 4...8))
            frond.position = CGPoint(x: CGFloat.random(in: -baseWidth * 0.44...baseWidth * 0.44),
                                     y: baseHeight * 0.12)
            frond.zPosition = CGFloat.random(in: -1...2)
            garden.addChild(frond)
        }

        let detailCount = Int.random(in: 2...5)
        for _ in 0..<detailCount {
            let detail: SKNode
            if zone == .deep || zone == .abyss {
                detail = makeCrystalCluster(color: OceanPalette.detailColor(for: zone))
            } else if Bool.random() {
                detail = makeCoralFan(color: OceanPalette.detailColor(for: zone))
            } else {
                detail = makeSpongePatch(color: OceanPalette.detailColor(for: zone))
            }
            detail.position = CGPoint(x: CGFloat.random(in: -baseWidth * 0.42...baseWidth * 0.42),
                                      y: baseHeight * 0.12)
            detail.zPosition = 2
            garden.addChild(detail)
        }

        return garden
    }

    private func makeKelpFrond(height: CGFloat, color: UIColor, width: CGFloat) -> SKNode {
        let frond = SKNode()
        let lean = CGFloat.random(in: -26...26)
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: lean * 0.45, y: height * 0.48),
                      controlPoint1: CGPoint(x: -lean * 0.25, y: height * 0.18),
                      controlPoint2: CGPoint(x: lean * 0.65, y: height * 0.32))
        path.addCurve(to: CGPoint(x: lean, y: height),
                      controlPoint1: CGPoint(x: lean * 0.2, y: height * 0.68),
                      controlPoint2: CGPoint(x: lean * 1.25, y: height * 0.82))

        let stem = SKShapeNode(path: path.cgPath)
        stem.strokeColor = color
        stem.fillColor = .clear
        stem.lineWidth = width
        stem.glowWidth = 2
        stem.alpha = CGFloat.random(in: 0.68...0.94)
        frond.addChild(stem)

        for i in 1...3 {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: height * 0.09,
                                                     height: height * CGFloat.random(in: 0.18...0.26)))
            leaf.fillColor = UIColor.lerp(color, .white, CGFloat.random(in: 0.05...0.18))
            leaf.strokeColor = .clear
            leaf.alpha = 0.54
            leaf.position = CGPoint(x: lean * CGFloat(i) / 4 + CGFloat.random(in: -8...8),
                                    y: height * CGFloat(i) / 4)
            leaf.zRotation = CGFloat.random(in: -0.7...0.7)
            frond.addChild(leaf)
        }

        let start = CGFloat.random(in: -0.06...0.06)
        frond.zRotation = start
        let left = SKAction.rotate(toAngle: start - CGFloat.random(in: 0.04...0.09),
                                   duration: Double.random(in: 2.2...4.2))
        let right = SKAction.rotate(toAngle: start + CGFloat.random(in: 0.04...0.09),
                                    duration: Double.random(in: 2.2...4.2))
        left.eaeInEaseOut()
        right.eaeInEaseOut()
        frond.run(.repeatForever(.sequence([left, right])))

        return frond
    }

    private func makeCoralFan(color: UIColor) -> SKNode {
        let fan = SKNode()
        let branchCount = Int.random(in: 4...7)
        for i in 0..<branchCount {
            let angle = CGFloat(i) / CGFloat(max(1, branchCount - 1)) * .pi - .pi * 0.85
            let length = CGFloat.random(in: 34...76)
            let end = CGPoint(x: cos(angle) * length * 0.7, y: abs(sin(angle)) * length)
            let path = UIBezierPath()
            path.move(to: .zero)
            path.addCurve(to: end,
                          controlPoint1: CGPoint(x: end.x * 0.25, y: length * 0.2),
                          controlPoint2: CGPoint(x: end.x * 0.75, y: length * 0.68))
            let branch = SKShapeNode(path: path.cgPath)
            branch.strokeColor = color.withAlphaComponent(0.78)
            branch.fillColor = .clear
            branch.lineWidth = CGFloat.random(in: 2...4)
            branch.glowWidth = 1
            fan.addChild(branch)

            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...5))
            dot.fillColor = UIColor.lerp(color, .white, 0.25)
            dot.strokeColor = .clear
            dot.position = end
            dot.alpha = 0.65
            fan.addChild(dot)
        }
        return fan
    }

    private func makeCrystalCluster(color: UIColor) -> SKNode {
        let cluster = SKNode()
        for _ in 0..<Int.random(in: 2...4) {
            let height = CGFloat.random(in: 28...74)
            let width = height * CGFloat.random(in: 0.26...0.42)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width / 2, y: 0))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.addLine(to: CGPoint(x: width / 2, y: 0))
            path.close()
            let shard = SKShapeNode(path: path.cgPath)
            shard.fillColor = color.withAlphaComponent(0.38)
            shard.strokeColor = UIColor.lerp(color, .white, 0.2).withAlphaComponent(0.7)
            shard.glowWidth = 5
            shard.position = CGPoint(x: CGFloat.random(in: -34...34), y: 0)
            shard.zRotation = CGFloat.random(in: -0.2...0.2)
            cluster.addChild(shard)
        }
        return cluster
    }

    private func makeSpongePatch(color: UIColor) -> SKNode {
        let patch = SKNode()
        for _ in 0..<Int.random(in: 3...6) {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...13))
            bubble.fillColor = color.withAlphaComponent(0.58)
            bubble.strokeColor = UIColor.lerp(color, .white, 0.22).withAlphaComponent(0.55)
            bubble.position = CGPoint(x: CGFloat.random(in: -34...34), y: CGFloat.random(in: 0...34))
            patch.addChild(bubble)
        }
        return patch
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
        if ctx.depth.currentZone != lastEntryTextZone {
            lastEntryTextZone = ctx.depth.currentZone
            showEntryTextIfNeeded(for: ctx.depth.currentZone)
        }
        ctx.food.update(dt: dt)
        ctx.fish.update(dt: dt)
        ctx.events.update(dt: dt)
        ctx.regions.update(dt: dt)
        ctx.travel.update(dt: dt)
        ctx.pois.update(dt: dt)
        updateTemporaryCompanion(dt: dt)

        // desafios modais com tempo/física próprios
        plotOverlay?.update(dt: dt)
        climbOverlay?.update(dt: dt)

        // no Refúgio o tempo é gentil: descanso acelerado
        if let refuge = refugeOverlay {
            refuge.update(dt: dt)
            stats.tick(dt: dt, energyDelta: 2.2)
        }

        let mermaidPosition = ctx.mermaidPosition
        let environment = ctx.depth.environment(atY: mermaidPosition.y)
        var water = environment.waterColor
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
                    objectiveAvailable: ctx.events.currentObjective != nil,
                    commandCooldowns: ctx.autonomy.commandCooldownsRemaining,
                    touchCooldownRemaining: ctx.autonomy.touchRequestCooldownRemaining,
                    bondRecoveryState: ctx.autonomy.bondRecoveryHUDState)

        updateCamera(dt: dt)
        worldChunkManager?.update(dt: dt, cameraPosition: cameraNode.position)
        updateOceanBackdrop(dt: dt, waterColor: water)
        if refugeOverlay == nil {
            GameAudio.shared.updateOceanAmbience(for: ctx.depth.currentZone)
        }

        saveTimer += dt
        if saveTimer > 20 {
            saveTimer = 0
            persistAndSave()
        }
    }

    private func persistAndSave() {
        let position = ctx.mermaidPosition
        let region = activeRegion ?? ctx.activeRegion ?? RegionDiscoverySystem.region(withId: stats.currentRegionId)
        if let region {
            let clampedPoint = CGPoint(x: position.x.clamped(to: region.playableXRange),
                                       y: position.y.clamped(to: World.floorY...World.surfaceTopY))
            stats.currentRegionId = region.id
            stats.posX = clampedPoint.x
            stats.posY = clampedPoint.y
            stats.rememberMapPosition(clampedPoint, in: region)
        } else {
            stats.posX = position.x
            stats.posY = position.y
        }
        stats.save()
    }

    private func updateTemporaryCompanion(dt: CGFloat) {
        guard stats.phase != .egg,
              let buff = stats.activeBuffs.first(where: { $0.kind == .temporaryPet && $0.expiresAt > Date() }) else {
            temporaryCompanionNode?.removeFromParent()
            temporaryCompanionNode = nil
            temporaryCompanionTitle = nil
            return
        }

        if temporaryCompanionNode == nil || temporaryCompanionTitle != buff.title {
            temporaryCompanionNode?.removeFromParent()
            let companion = makeTemporaryCompanionNode(title: buff.title)
            companion.position = ctx.mermaidPosition + CGPoint(x: -120, y: 78)
            worldNode.addChild(companion)
            temporaryCompanionNode = companion
            temporaryCompanionTitle = buff.title
        }

        guard let companion = temporaryCompanionNode else { return }
        temporaryCompanionPhase += dt
        let offset = CGPoint(x: -115 + sin(temporaryCompanionPhase * 1.7) * 16,
                             y: 78 + cos(temporaryCompanionPhase * 1.35) * 12)
        let target = ctx.mermaidPosition + offset
        let blend = min(1, dt * 3.8)
        companion.position = CGPoint(x: companion.position.x + (target.x - companion.position.x) * blend,
                                     y: companion.position.y + (target.y - companion.position.y) * blend)
    }

    private func makeTemporaryCompanionNode(title: String) -> SKNode {
        let node = SKNode()
        node.zPosition = 12

        let halo = SKShapeNode(circleOfRadius: 34)
        halo.fillColor = GameUI.accent.withAlphaComponent(0.12)
        halo.strokeColor = UIColor.white.withAlphaComponent(0.32)
        halo.lineWidth = 1
        halo.glowWidth = 8
        node.addChild(halo)

        let glyph = SKLabelNode(text: companionGlyph(for: title))
        glyph.fontName = "AvenirNext-DemiBold"
        glyph.fontSize = 28
        glyph.fontColor = UIColor(red: 0.76, green: 1.0, blue: 0.94, alpha: 1)
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        glyph.zPosition = 2
        node.addChild(glyph)

        let label = SKLabelNode(text: title.count > 18 ? "companhia" : title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 10
        label.fontColor = UIColor.white.withAlphaComponent(0.78)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -36)
        node.addChild(label)

        let pulse = SKAction.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.9),
            .scale(to: 1.0, duration: 1.0)
        ]))
        pulse.eaeInEaseOut()
        node.run(pulse, withKey: "temporary_companion_pulse")

        return node
    }

    private func companionGlyph(for title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("polvo") { return "🐙" }
        if lower.contains("cardume") { return "🐠" }
        return "🐟"
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

    private func updateOceanBackdrop(dt: CGFloat, environment: DepthEnvironment? = nil, waterColor: UIColor) {
        let cameraZone = DepthZone.zone(atY: cameraNode.position.y)
        let cameraEnvironment = environment ?? ctx.depth.environment(atY: cameraNode.position.y)
        let biome = AquaticBiome.biome(at: cameraNode.position, zone: cameraZone)
        oceanBackdrop?.update(dt: dt,
                              cameraPosition: cameraNode.position,
                              waterColor: waterColor,
                              zone: cameraZone,
                              environment: cameraEnvironment,
                              biome: biome)
    }

    private func clampedCameraPosition(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x.clamped(to: (World.minX + 700)...(World.maxX - 700)),
                y: p.y.clamped(to: (World.floorY + 500)...500))
    }

    // MARK: - Menu de regiões

    func openRegionMenu() {
        guard regionMenu == nil, !isChallengeOpen, refugeOverlay == nil else { return }
        GameAudio.shared.play(.uiOpenPanel)
        let menu = RegionMenuOverlay(size: size,
                                     stats: stats,
                                     currentRegionId: activeRegion?.id,
                                     destinationId: stats.destinationRegionId,
                                     currentPosition: ctx.mermaidPosition,
                                     onSelect: { [weak self] region in
                                         self?.ctx.travel.setDestination(region)
                                         self?.closeRegionMenu()
                                     },
                                     onPOISelect: { [weak self] poi in
                                         guard let self else { return }
                                         _ = self.ctx.pois.requestReturn(to: poi)
                                         self.closeRegionMenu()
                                     },
                                     onClose: { [weak self] in
                                         self?.closeRegionMenu()
                                     })
        menu.zPosition = 190
        cameraNode.addChild(menu)
        regionMenu = menu
    }

    private func closeRegionMenu() {
        if regionMenu != nil {
            GameAudio.shared.play(.uiClosePanel)
        }
        regionMenu?.removeFromParent()
        regionMenu = nil
    }

    @discardableResult
    private func showEntryTextIfNeeded(for zone: DepthZone) -> Bool {
        guard let activeRegion,
              stats.markEntryTextSeen(region: activeRegion, zone: zone) else { return false }
        ctx.say(EntryTextCatalog.text(for: activeRegion, zone: zone))
        return true
    }

    func transitionToMap(_ region: Region) {
        guard activeRegion?.id != region.id else {
            ctx.say("Ela já está em \(region.name).")
            return
        }

        persistAndSave()
        let entryPoint = stats.savedMapPosition(for: region) ?? stats.entryPoint(for: region)
        let yRange = DepthSystem.allowedYRange(for: stats)
        let clampedEntry = CGPoint(x: entryPoint.x.clamped(to: region.playableXRange),
                                   y: entryPoint.y.clamped(to: yRange))
        stats.currentRegionId = region.id
        stats.destinationRegionId = nil
        stats.posX = clampedEntry.x
        stats.posY = clampedEntry.y
        stats.rememberMapPosition(clampedEntry, in: region)
        stats.save()

        let nextScene = MapSceneFactory.scene(for: region.id, size: size, announceArrival: true)
        nextScene.scaleMode = scaleMode
        view?.presentScene(nextScene, transition: .crossFade(withDuration: 0.65))
    }

    func showRegionDiscoveryCue(for region: Region) {
        let cue = SKShapeNode(circleOfRadius: 260)
        cue.position = ctx.mermaidPosition
        cue.fillColor = region.tint.withAlphaComponent(0.18)
        cue.strokeColor = UIColor.lerp(region.tint, .white, 0.35).withAlphaComponent(0.75)
        cue.lineWidth = 2
        cue.glowWidth = 14
        cue.zPosition = 6
        worldNode.addChild(cue)

        cue.run(.sequence([
            .group([
                .scale(to: 1.75, duration: 1.4),
                .fadeAlpha(to: 0.15, duration: 1.4)
            ]),
            .group([
                .scale(to: 2.15, duration: 0.8),
                .fadeOut(withDuration: 0.8)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Refúgio das Marés (com portal de verdade)

    /// Passo 1: um portal se abre perto da sereia e ela nada até ele.
    func beginRefugeEntry() {
        guard refugeOverlay == nil, !isChallengeOpen, refugePortal == nil else { return }
        closeRegionMenu()
        GameAudio.shared.play(.refugePortalOpen)

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
        GameAudio.shared.play(.refugePortalEnter)

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
        GameAudio.shared.startRefugeAmbience()
    }

    private func closeRefuge(resume: Bool) {
        guard refugeOverlay != nil else { return }
        GameAudio.shared.play(.uiClosePanel)
        refugeOverlay?.removeFromParent()
        refugeOverlay = nil
        GameAudio.shared.updateOceanAmbience(for: ctx.depth.currentZone)
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
        GameAudio.shared.play(.challengeOpen)
        let special = giver.isSpecialChallenge
        let giverDisplay = giver.makeGiverDisplayNode()
        ctx.challenges.consumeChallenge(of: giver)
        presentChallenge(kind: kind, special: special, giverDisplay: giverDisplay)
    }

    /// Durante o ovo: o Desafio: Trama abre direto (energia de nascimento).
    func openHatchingChallenge() {
        guard !isChallengeOpen, refugeOverlay == nil else { return }
        GameAudio.shared.play(.challengeOpen)
        presentChallenge(kind: .plot, special: false, giverDisplay: nil, hatching: true)
    }

    @discardableResult
    func openPOIChallenge(for poi: WorldPOI,
                          onCompletion: @escaping (ChallengeResult) -> Void) -> Bool {
        guard !isChallengeOpen, refugeOverlay == nil else { return false }
        pendingPOIChallengeCompletion = onCompletion
        GameAudio.shared.play(.challengeOpen)
        presentChallenge(kind: .plot,
                         special: true,
                         giverDisplay: makePOIChallengeDisplay(for: poi))
        return true
    }

    private func makePOIChallengeDisplay(for poi: WorldPOI) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: 28)
        ring.fillColor = poi.visual.color.withAlphaComponent(0.18)
        ring.strokeColor = UIColor.white.withAlphaComponent(0.58)
        ring.lineWidth = 1.4
        ring.glowWidth = 5
        node.addChild(ring)

        let glyph = SKLabelNode(text: poi.visual.glyph)
        glyph.fontName = "AvenirNext-DemiBold"
        glyph.fontSize = 28
        glyph.fontColor = UIColor.lerp(poi.visual.color, .white, 0.28)
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        glyph.zPosition = 2
        node.addChild(glyph)
        return node
    }

    private func presentChallenge(kind: ChallengeKind,
                                  special: Bool,
                                  giverDisplay: SKNode?,
                                  hatching: Bool = false) {
        closeRegionMenu()
        let zone = ctx.depth.currentZone
        stats.energy = max(0, stats.energy - 8)
        ctx.autonomy.paused = true
        showChallengeBackdrop()

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
                                             phase: stats.phase,
                                             shellRewardMultiplier: stats.shellRewardMultiplier,
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
                                             shellRewardMultiplier: stats.shellRewardMultiplier,
                                             giverDisplay: giverDisplay) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            climbOverlay = overlay
        }
    }

    private func showChallengeBackdrop() {
        challengeBackdrop?.removeFromParent()

        let node = SKNode()
        node.zPosition = 190
        node.position = CGPoint(x: 0, y: -modalDropOffset)

        let veil = SKShapeNode(rectOf: CGSize(width: size.width * 2.4, height: size.height * 2.4))
        veil.fillColor = UIColor.black.withAlphaComponent(0.54)
        veil.strokeColor = .clear
        node.addChild(veil)

        for _ in 0..<18 {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...7.0))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.035)
            bubble.strokeColor = GameUI.palePaper.withAlphaComponent(0.10)
            bubble.lineWidth = 0.8
            bubble.position = CGPoint(x: CGFloat.random(in: -size.width * 0.55...size.width * 0.55),
                                      y: CGFloat.random(in: -size.height * 0.55...size.height * 0.55))
            node.addChild(bubble)
        }

        cameraNode.addChild(node)
        challengeBackdrop = node
    }

    private func closeChallenge(result: ChallengeResult, zone: DepthZone) {
        plotOverlay?.removeFromParent()
        plotOverlay = nil
        climbOverlay?.removeFromParent()
        climbOverlay = nil
        challengeBackdrop?.removeFromParent()
        challengeBackdrop = nil
        let poiCompletion = pendingPOIChallengeCompletion
        pendingPOIChallengeCompletion = nil

        let gainedPearls = result.isHatching ? 0 : stats.awardPearls(result.pearls)

        // Durante o ovo, o desafio reúne energia de nascimento
        if result.isHatching || stats.phase == .egg {
            ctx.growth.addHatchProgress(CGFloat(result.score) / 900)
            stats.save()
            GameAudio.shared.play(.eggTap, volumeMultiplier: 0.7)
            ctx.say("O desafio reuniu energia de nascimento! 🥚✨")
            return
        }

        stats.gainXP(result.xp)
        ctx.autonomy.paused = false
        ctx.autonomy.finishChallenge()
        stats.boostMood(8)
        let adaptation = stats.adaptation(for: zone)
        stats.setAdaptation(adaptation + 3, for: zone)
        if result.reachedTarget {
            stats.puzzlesSolved += 1
            stats.addMemory("Venceu o \(result.kind.title) em \(zone.displayName)")
        }
        stats.save()
        if let poiCompletion {
            poiCompletion(result)
        } else {
            ctx.say(result.reachedTarget
                    ? "Ela adorou o \(result.kind.title)! 🐚+\(gainedPearls)"
                    : "Quase! Ainda assim ganhou 🐚+\(gainedPearls)")
        }
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

        if let food = ctx.food.nearestFood(to: location, maxDistance: 150),
           food.kind.isShellCurrency {
            let collected = ctx.food.collectShellByPlayer(food) != nil
            showTouchRipple(at: food.position, accepted: collected)
            return
        }

        if ctx.autonomy.touchRequestCooldownRemaining > 0 {
            showTouchRipple(at: location, accepted: false)
            ctx.autonomy.showTouchCooldownFeedback()
            return
        }

        if let objectivePoint = ctx.events.currentObjective?.position(),
           objectivePoint.distance(to: location) < 180 {
            let accepted = ctx.autonomy.requestObjectiveFromTouch()
            showTouchRipple(at: objectivePoint, accepted: accepted)
            return
        }

        if let giver = ctx.challenges.nearestGiver(to: location, maxDistance: 170) {
            let accepted = ctx.autonomy.requestChallengeFromTouch(giver)
            showTouchRipple(at: giver.position, accepted: accepted)
            return
        }

        if let poi = ctx.pois.nearestVisiblePOI(to: location, maxDistance: 170) {
            let accepted = ctx.pois.requestReturn(to: poi)
            showTouchRipple(at: poi.position, accepted: accepted)
            return
        }

        if let fish = ctx.fish.nearestFish(to: location, maxDistance: 155) {
            let accepted = ctx.autonomy.requestFishFromTouch(fish)
            showTouchRipple(at: fish.position, accepted: accepted)
            return
        }

        if let food = ctx.food.nearestFood(to: location, maxDistance: 150) {
            let accepted = ctx.autonomy.requestFoodFromTouch(food)
            showTouchRipple(at: food.position, accepted: accepted)
            return
        }

        let accepted = ctx.autonomy.requestPointFromTouch(location)
        showTouchRipple(at: location, accepted: accepted)
    }

    private func showTouchRipple(at point: CGPoint, accepted: Bool = true) {
        GameAudio.shared.play(accepted ? .worldTapAccept : .worldTapReject)
        let color = accepted
            ? UIColor(white: 1, alpha: 0.75)
            : GameUI.coral.withAlphaComponent(0.82)
        let ring = SKShapeNode(circleOfRadius: 22)
        ring.position = point
        ring.zPosition = 16
        ring.fillColor = .clear
        ring.strokeColor = color
        ring.lineWidth = 2
        ring.glowWidth = 6
        worldNode.addChild(ring)

        let dot = SKShapeNode(circleOfRadius: 4)
        dot.fillColor = color.withAlphaComponent(0.95)
        dot.strokeColor = .clear
        dot.glowWidth = 5
        ring.addChild(dot)

        ring.run(.sequence([
            .group([
                .scale(to: 2.6, duration: 0.42),
                .fadeOut(withDuration: 0.42)
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: - Persistência

    @objc private func saveOnBackground() {
        persistAndSave()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

private enum OceanPalette {
    static func veilColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface:
            return .clear
        case .clear:
            return UIColor(red: 0.85, green: 1.0, blue: 0.95, alpha: 0.05)
        case .shallow:
            return UIColor(red: 0.15, green: 0.55, blue: 0.48, alpha: 0.05)
        case .mid:
            return UIColor(red: 0.05, green: 0.24, blue: 0.42, alpha: 0.07)
        case .blue:
            return UIColor(red: 0.03, green: 0.15, blue: 0.34, alpha: 0.12)
        case .deep:
            return UIColor(red: 0.02, green: 0.07, blue: 0.18, alpha: 0.18)
        case .abyss:
            return UIColor(red: 0.01, green: 0.02, blue: 0.07, alpha: 0.24)
        }
    }

    static func currentColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear:
            return UIColor(red: 0.86, green: 1.0, blue: 0.96, alpha: 0.5)
        case .shallow:
            return UIColor(red: 0.48, green: 0.92, blue: 0.78, alpha: 0.42)
        case .mid:
            return UIColor(red: 0.34, green: 0.72, blue: 0.86, alpha: 0.32)
        case .blue:
            return UIColor(red: 0.32, green: 0.56, blue: 0.92, alpha: 0.24)
        case .deep:
            return UIColor(red: 0.26, green: 0.42, blue: 0.74, alpha: 0.2)
        case .abyss:
            return UIColor(red: 0.36, green: 0.32, blue: 0.72, alpha: 0.16)
        }
    }

    static func rockColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear:
            return UIColor(red: 0.18, green: 0.44, blue: 0.46, alpha: 1)
        case .shallow:
            return UIColor(red: 0.12, green: 0.36, blue: 0.34, alpha: 1)
        case .mid:
            return UIColor(red: 0.08, green: 0.24, blue: 0.32, alpha: 1)
        case .blue:
            return UIColor(red: 0.05, green: 0.17, blue: 0.31, alpha: 1)
        case .deep:
            return UIColor(red: 0.04, green: 0.10, blue: 0.22, alpha: 1)
        case .abyss:
            return UIColor(red: 0.03, green: 0.04, blue: 0.12, alpha: 1)
        }
    }

    static func edgeColor(for zone: DepthZone) -> UIColor {
        UIColor.lerp(rockColor(for: zone), .white, zone == .abyss ? 0.12 : 0.2).withAlphaComponent(0.42)
    }

    static func kelpColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear:
            return UIColor(red: 0.34, green: 0.84, blue: 0.52, alpha: 1)
        case .shallow:
            return UIColor(red: 0.20, green: 0.66, blue: 0.44, alpha: 1)
        case .mid:
            return UIColor(red: 0.18, green: 0.52, blue: 0.50, alpha: 1)
        case .blue:
            return UIColor(red: 0.13, green: 0.42, blue: 0.58, alpha: 1)
        case .deep:
            return UIColor(red: 0.15, green: 0.34, blue: 0.56, alpha: 1)
        case .abyss:
            return UIColor(red: 0.24, green: 0.26, blue: 0.58, alpha: 1)
        }
    }

    static func detailColor(for zone: DepthZone) -> UIColor {
        switch zone {
        case .surface, .clear:
            return UIColor(red: 0.98, green: 0.58, blue: 0.54, alpha: 1)
        case .shallow:
            return UIColor(red: 0.92, green: 0.68, blue: 0.42, alpha: 1)
        case .mid:
            return UIColor(red: 0.42, green: 0.78, blue: 0.86, alpha: 1)
        case .blue:
            return UIColor(red: 0.45, green: 0.62, blue: 0.98, alpha: 1)
        case .deep:
            return UIColor(red: 0.42, green: 0.86, blue: 0.92, alpha: 1)
        case .abyss:
            return UIColor(red: 0.72, green: 0.46, blue: 0.96, alpha: 1)
        }
    }

    static func kelpHeight(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface, .clear: return 180
        case .shallow: return 260
        case .mid: return 220
        case .blue: return 170
        case .deep: return 120
        case .abyss: return 100
        }
    }
}

private final class OceanParallaxBackdrop: SKNode {
    private let sceneSize: CGSize
    private let gradientWash: SKSpriteNode
    private let farLayer = SKNode()
    private let causticLayer = SKNode()
    private let lifeLayer = SKNode()
    private let planktonLayer = SKNode()
    private let kelpCurtainLayer = SKNode()
    private var ambientLife: [AmbientLifeNode] = []
    private var elapsed: CGFloat = 0
    private static let softMistTexture: SKTexture = {
        let size = CGSize(width: 64, height: 64)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let rect = CGRect(origin: .zero, size: size)
            let context = renderer.cgContext
            context.clear(rect)

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let colors = [
                UIColor(white: 1, alpha: 0.70).cgColor,
                UIColor(white: 1, alpha: 0.22).cgColor,
                UIColor(white: 1, alpha: 0.0).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.42, 1.0]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors,
                                            locations: locations) else { return }
            context.drawRadialGradient(gradient,
                                       startCenter: center,
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: size.width / 2,
                                       options: [.drawsAfterEndLocation])
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }()

    init(size: CGSize) {
        sceneSize = size
        let washTexture = GameUI.gradientTexture(size: CGSize(width: 8, height: 512),
                                                 colors: [
                                                    UIColor(white: 1, alpha: 0.18),
                                                    UIColor(white: 1, alpha: 0.02),
                                                    UIColor(white: 0, alpha: 0.22)
                                                 ])
        gradientWash = SKSpriteNode(texture: washTexture)
        gradientWash.size = CGSize(width: max(1, size.width * 2.8),
                                   height: max(1, size.height * 2.8))
        gradientWash.zPosition = -100
        super.init()
        isUserInteractionEnabled = false

        addChild(gradientWash)
        addChild(farLayer)
        addChild(causticLayer)
        addChild(lifeLayer)
        addChild(planktonLayer)
        addChild(kelpCurtainLayer)

        farLayer.zPosition = -80
        causticLayer.zPosition = -62
        planktonLayer.zPosition = -46
        lifeLayer.zPosition = -36
        kelpCurtainLayer.zPosition = -24

        buildDistantParticleMist()
        buildCaustics()
        buildPlankton()
        buildKelpCurtains()
        buildAmbientLife()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat,
                cameraPosition: CGPoint,
                waterColor: UIColor,
                zone: DepthZone,
                environment: DepthEnvironment,
                biome: AquaticBiome) {
        elapsed += dt
        position = cameraPosition

        gradientWash.color = UIColor.lerp(waterColor, .white, 0.05)
        gradientWash.colorBlendFactor = 0.12
        gradientWash.alpha = gradientAlpha(for: zone) + environment.fogAlpha * 0.35

        farLayer.position = CGPoint(x: wrapped(-cameraPosition.x * 0.025, span: sceneSize.width),
                                    y: wrapped(-cameraPosition.y * 0.012, span: sceneSize.height))
        causticLayer.position = CGPoint(x: wrapped(-cameraPosition.x * 0.04 + elapsed * 10, span: sceneSize.width),
                                        y: wrapped(-cameraPosition.y * 0.014, span: sceneSize.height))
        lifeLayer.position = CGPoint(x: wrapped(-cameraPosition.x * 0.075, span: sceneSize.width),
                                     y: wrapped(-cameraPosition.y * 0.035, span: sceneSize.height))
        planktonLayer.position = CGPoint(x: wrapped(-cameraPosition.x * 0.11, span: sceneSize.width),
                                         y: wrapped(-cameraPosition.y * 0.08 + elapsed * 7, span: sceneSize.height))
        kelpCurtainLayer.position = CGPoint(x: wrapped(-cameraPosition.x * 0.16, span: sceneSize.width),
                                            y: wrapped(-cameraPosition.y * 0.07, span: sceneSize.height))

        causticLayer.alpha = environment.causticAlpha * biomeCausticMultiplier(for: biome)
        planktonLayer.alpha = planktonAlpha(for: zone) * environment.planktonDensity
        kelpCurtainLayer.alpha = curtainAlpha(for: zone) * biomeCurtainMultiplier(for: biome)
        lifeLayer.alpha = lifeAlpha(for: zone) * environment.lifeDensity * biomeLifeMultiplier(for: biome)

        for node in ambientLife {
            node.update(dt: dt, bounds: sceneSize)
        }
    }

    private func buildDistantParticleMist() {
        let coverage = CGSize(width: max(sceneSize.width * 3.4, 1200),
                              height: max(sceneSize.height * 2.8, 1400))
        let density = ((sceneSize.width * sceneSize.height) / (390 * 844)).clamped(to: 0.55...1.25)

        addDistantEmitter(color: UIColor(red: 0.04, green: 0.12, blue: 0.18, alpha: 1),
                          birthRate: min(4.4, 3.2 * density),
                          lifetime: 42,
                          scale: 2.1,
                          scaleRange: 1.4,
                          alpha: 0.16,
                          alphaRange: 0.08,
                          speed: 3,
                          coverage: coverage,
                          blendMode: .alpha,
                          zPosition: -2)

        addDistantEmitter(color: UIColor(red: 0.14, green: 0.28, blue: 0.32, alpha: 1),
                          birthRate: min(8.0, 5.8 * density),
                          lifetime: 28,
                          scale: 0.44,
                          scaleRange: 0.28,
                          alpha: 0.18,
                          alphaRange: 0.10,
                          speed: 9,
                          coverage: coverage,
                          blendMode: .alpha,
                          zPosition: -1)

        addDistantEmitter(color: UIColor(red: 0.70, green: 0.94, blue: 0.92, alpha: 1),
                          birthRate: min(2.1, 1.4 * density),
                          lifetime: 18,
                          scale: 0.18,
                          scaleRange: 0.12,
                          alpha: 0.22,
                          alphaRange: 0.12,
                          speed: 6,
                          coverage: coverage,
                          blendMode: .add,
                          zPosition: 0)
    }

    private func addDistantEmitter(color: UIColor,
                                   birthRate: CGFloat,
                                   lifetime: CGFloat,
                                   scale: CGFloat,
                                   scaleRange: CGFloat,
                                   alpha: CGFloat,
                                   alphaRange: CGFloat,
                                   speed: CGFloat,
                                   coverage: CGSize,
                                   blendMode: SKBlendMode,
                                   zPosition: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = Self.softMistTexture
        emitter.particleBirthRate = birthRate
        emitter.particleLifetime = lifetime
        emitter.particleLifetimeRange = lifetime * 0.32
        emitter.particlePositionRange = CGVector(dx: coverage.width, dy: coverage.height)
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.7
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = scale
        emitter.particleScaleRange = scaleRange
        emitter.particleScaleSpeed = -scale / max(lifetime, 1)
        emitter.particleAlpha = alpha
        emitter.particleAlphaRange = alphaRange
        emitter.particleAlphaSpeed = -alpha / max(lifetime, 1)
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = blendMode
        emitter.zPosition = zPosition
        emitter.targetNode = farLayer
        farLayer.addChild(emitter)
        emitter.advanceSimulationTime(TimeInterval(lifetime * 0.8))
    }

    private func buildCaustics() {
        let width = sceneSize.width * 3.0
        let height = sceneSize.height * 2.3
        for _ in 0..<16 {
            let path = UIBezierPath()
            let y = CGFloat.random(in: -height / 2...height / 2)
            path.move(to: CGPoint(x: -width / 2, y: y))
            for step in 0...9 {
                let x = -width / 2 + width * CGFloat(step) / 9
                let wave = sin(CGFloat(step) * 1.3 + CGFloat.random(in: 0...2)) * CGFloat.random(in: 10...30)
                path.addLine(to: CGPoint(x: x, y: y + wave))
            }

            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = UIColor(white: 1, alpha: CGFloat.random(in: 0.10...0.22))
            line.fillColor = .clear
            line.lineWidth = CGFloat.random(in: 1.4...3.2)
            line.glowWidth = CGFloat.random(in: 3...8)
            line.blendMode = .add
            line.zRotation = CGFloat.random(in: -0.18...0.18)
            causticLayer.addChild(line)

            let fadeLow = SKAction.fadeAlpha(to: 0.35, duration: Double.random(in: 2.0...4.0))
            let fadeHigh = SKAction.fadeAlpha(to: 1.0, duration: Double.random(in: 2.0...4.0))
            fadeLow.eaeInEaseOut()
            fadeHigh.eaeInEaseOut()
            line.run(.repeatForever(.sequence([fadeLow, fadeHigh])))
        }
    }

    private func buildPlankton() {
        let width = sceneSize.width * 2.8
        let height = sceneSize.height * 2.4
        for _ in 0..<90 {
            let radius = CGFloat.random(in: 1.0...3.6)
            let mote = SKShapeNode(circleOfRadius: radius)
            mote.fillColor = UIColor(red: 0.82, green: 1.0, blue: 0.92, alpha: CGFloat.random(in: 0.18...0.48))
            mote.strokeColor = .clear
            mote.position = CGPoint(x: CGFloat.random(in: -width / 2...width / 2),
                                    y: CGFloat.random(in: -height / 2...height / 2))
            mote.glowWidth = CGFloat.random(in: 0...4)
            planktonLayer.addChild(mote)

            let rise = SKAction.moveBy(x: CGFloat.random(in: -18...18),
                                       y: CGFloat.random(in: 40...95),
                                       duration: Double.random(in: 5.0...11.0))
            let reset = SKAction.moveBy(x: CGFloat.random(in: -12...12),
                                        y: CGFloat.random(in: -95...(-40)),
                                        duration: 0.01)
            mote.run(.repeatForever(.sequence([rise, reset])))
        }
    }

    private func buildKelpCurtains() {
        let height = sceneSize.height * 0.9
        let width = sceneSize.width * 1.35
        for side in [-1, 1] {
            for i in 0..<8 {
                let frond = makeCurtainFrond(height: height * CGFloat.random(in: 0.34...0.74),
                                             color: UIColor(red: 0.12, green: 0.54, blue: 0.46, alpha: 0.46))
                frond.position = CGPoint(x: CGFloat(side) * (width / 2 + CGFloat.random(in: -80...120)),
                                         y: -sceneSize.height * 0.48 + CGFloat(i) * 38)
                frond.zRotation = CGFloat(side) * CGFloat.random(in: 0.10...0.22)
                kelpCurtainLayer.addChild(frond)
            }
        }
    }

    private func buildAmbientLife() {
        for _ in 0..<12 {
            let node = AmbientLifeNode()
            node.position = CGPoint(x: CGFloat.random(in: -sceneSize.width * 1.2...sceneSize.width * 1.2),
                                    y: CGFloat.random(in: -sceneSize.height * 0.75...sceneSize.height * 0.75))
            lifeLayer.addChild(node)
            ambientLife.append(node)
        }
    }

    private func makeCurtainFrond(height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        let lean = CGFloat.random(in: -34...34)
        let path = UIBezierPath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: lean, y: height),
                      controlPoint1: CGPoint(x: -lean * 0.35, y: height * 0.25),
                      controlPoint2: CGPoint(x: lean * 1.25, y: height * 0.70))
        let shape = SKShapeNode(path: path.cgPath)
        shape.strokeColor = color
        shape.fillColor = .clear
        shape.lineWidth = CGFloat.random(in: 7...12)
        shape.glowWidth = 4
        node.addChild(shape)

        let left = SKAction.rotate(byAngle: -CGFloat.random(in: 0.04...0.08), duration: Double.random(in: 3.0...5.0))
        let right = SKAction.rotate(byAngle: CGFloat.random(in: 0.04...0.08), duration: Double.random(in: 3.0...5.0))
        left.eaeInEaseOut()
        right.eaeInEaseOut()
        node.run(.repeatForever(.sequence([left, right])))
        return node
    }

    private func gradientAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface, .clear: return 0.72
        case .shallow: return 0.64
        case .mid: return 0.58
        case .blue: return 0.52
        case .deep: return 0.48
        case .abyss: return 0.42
        }
    }

    private func causticAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface: return 0.95
        case .clear: return 0.8
        case .shallow: return 0.45
        case .mid: return 0.22
        case .blue: return 0.12
        case .deep, .abyss: return 0.05
        }
    }

    private func planktonAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface, .clear: return 0.42
        case .shallow: return 0.52
        case .mid: return 0.62
        case .blue: return 0.68
        case .deep: return 0.78
        case .abyss: return 0.88
        }
    }

    private func curtainAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface: return 0.0
        case .clear: return 0.28
        case .shallow: return 0.48
        case .mid: return 0.36
        case .blue: return 0.22
        case .deep: return 0.16
        case .abyss: return 0.12
        }
    }

    private func lifeAlpha(for zone: DepthZone) -> CGFloat {
        switch zone {
        case .surface: return 0.28
        case .clear, .shallow: return 0.5
        case .mid, .blue: return 0.42
        case .deep: return 0.34
        case .abyss: return 0.26
        }
    }

    private func biomeCausticMultiplier(for biome: AquaticBiome) -> CGFloat {
        switch biome {
        case .coralGarden, .kelpForest:
            return 1.12
        case .openWater:
            return 0.82
        case .deepVents, .abyssPlain:
            return 0.32
        default:
            return 0.72
        }
    }

    private func biomeCurtainMultiplier(for biome: AquaticBiome) -> CGFloat {
        switch biome {
        case .kelpForest:
            return 1.55
        case .coralGarden, .reefWall:
            return 1.12
        case .openWater, .abyssPlain:
            return 0.35
        default:
            return 0.72
        }
    }

    private func biomeLifeMultiplier(for biome: AquaticBiome) -> CGFloat {
        switch biome {
        case .coralGarden, .kelpForest:
            return 1.35
        case .openWater:
            return 0.72
        case .deepVents, .crystalField:
            return 0.82
        case .abyssPlain:
            return 0.42
        default:
            return 1.0
        }
    }

    private func wrapped(_ value: CGFloat, span: CGFloat) -> CGFloat {
        guard span > 0 else { return value }
        var result = value.truncatingRemainder(dividingBy: span)
        if result > span / 2 {
            result -= span
        } else if result < -span / 2 {
            result += span
        }
        return result
    }
}

private final class AmbientLifeNode: SKNode {
    private enum Style: CaseIterable {
        case ovalFish
        case needleFish
        case ray
        case jelly
    }

    private let swimSpeed: CGFloat
    private let direction: CGFloat
    private let wobbleSpeed: CGFloat
    private let wobbleHeight: CGFloat
    private var elapsed: CGFloat = 0

    override init() {
        let style = Style.allCases.randomElement()!
        swimSpeed = CGFloat.random(in: 14...46)
        direction = Bool.random() ? 1 : -1
        wobbleSpeed = CGFloat.random(in: 0.7...1.8)
        wobbleHeight = CGFloat.random(in: 7...22)
        super.init()
        xScale = direction
        setScale(CGFloat.random(in: 0.55...1.45))
        alpha = CGFloat.random(in: 0.18...0.38)
        build(style: style)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(dt: CGFloat, bounds: CGSize) {
        elapsed += dt
        position.x += direction * swimSpeed * dt
        position.y += sin(elapsed * wobbleSpeed) * wobbleHeight * dt

        let limitX = bounds.width * 1.35
        if direction > 0, position.x > limitX {
            position.x = -limitX
            position.y = CGFloat.random(in: -bounds.height * 0.75...bounds.height * 0.75)
        } else if direction < 0, position.x < -limitX {
            position.x = limitX
            position.y = CGFloat.random(in: -bounds.height * 0.75...bounds.height * 0.75)
        }
    }

    private func build(style: Style) {
        switch style {
        case .ovalFish:
            addChild(fishShape(length: CGFloat.random(in: 34...70),
                               height: CGFloat.random(in: 12...24),
                               color: UIColor(red: 0.02, green: 0.08, blue: 0.13, alpha: 0.55)))
        case .needleFish:
            addChild(fishShape(length: CGFloat.random(in: 64...120),
                               height: CGFloat.random(in: 8...16),
                               color: UIColor(red: 0.03, green: 0.13, blue: 0.18, alpha: 0.46)))
        case .ray:
            addChild(rayShape())
        case .jelly:
            addChild(jellyShape())
        }
    }

    private func fishShape(length: CGFloat, height: CGFloat, color: UIColor) -> SKNode {
        let node = SKNode()
        let body = SKShapeNode(ellipseOf: CGSize(width: length, height: height))
        body.fillColor = color
        body.strokeColor = .clear
        node.addChild(body)

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -length * 0.45, y: 0))
        tailPath.addLine(to: CGPoint(x: -length * 0.72, y: height * 0.55))
        tailPath.addLine(to: CGPoint(x: -length * 0.72, y: -height * 0.55))
        tailPath.close()
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.fillColor = color.withAlphaComponent(0.75)
        tail.strokeColor = .clear
        node.addChild(tail)
        return node
    }

    private func rayShape() -> SKNode {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -76, y: 0))
        path.addCurve(to: CGPoint(x: 76, y: 0),
                      controlPoint1: CGPoint(x: -35, y: 38),
                      controlPoint2: CGPoint(x: 35, y: 38))
        path.addCurve(to: CGPoint(x: -76, y: 0),
                      controlPoint1: CGPoint(x: 32, y: -28),
                      controlPoint2: CGPoint(x: -32, y: -28))
        let body = SKShapeNode(path: path.cgPath)
        body.fillColor = UIColor(red: 0.02, green: 0.06, blue: 0.13, alpha: 0.48)
        body.strokeColor = .clear

        let tailPath = UIBezierPath()
        tailPath.move(to: CGPoint(x: -66, y: -3))
        tailPath.addLine(to: CGPoint(x: -140, y: -18))
        let tail = SKShapeNode(path: tailPath.cgPath)
        tail.strokeColor = body.fillColor.withAlphaComponent(0.7)
        tail.lineWidth = 3

        let node = SKNode()
        node.addChild(body)
        node.addChild(tail)
        return node
    }

    private func jellyShape() -> SKNode {
        let node = SKNode()
        let bell = SKShapeNode(ellipseOf: CGSize(width: 48, height: 34))
        bell.fillColor = UIColor(red: 0.72, green: 0.88, blue: 1.0, alpha: 0.22)
        bell.strokeColor = UIColor(red: 0.78, green: 0.98, blue: 1.0, alpha: 0.32)
        bell.glowWidth = 6
        node.addChild(bell)

        for i in 0..<5 {
            let x = -18 + CGFloat(i) * 9
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: -12))
            path.addCurve(to: CGPoint(x: x + CGFloat.random(in: -10...10), y: -56),
                          controlPoint1: CGPoint(x: x + CGFloat.random(in: -12...12), y: -24),
                          controlPoint2: CGPoint(x: x + CGFloat.random(in: -12...12), y: -42))
            let tentacle = SKShapeNode(path: path.cgPath)
            tentacle.strokeColor = bell.strokeColor.withAlphaComponent(0.55)
            tentacle.fillColor = .clear
            tentacle.lineWidth = 1.4
            node.addChild(tentacle)
        }
        return node
    }
}
