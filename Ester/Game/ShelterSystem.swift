//
//  ShelterSystem.swift
//  Ester
//
//  Refúgio das Marés: um espaço pessoal mágico acessível de qualquer
//  lugar do oceano (dimensão de bolso, não um ponto físico do mundo).
//  Lá a sereia descansa e mostra suas memórias. Ao sair, ela continua
//  de onde estava.
//

import Foundation
import SpriteKit

// MARK: - Portal do Refúgio (nó no mundo)

/// Pequeno portal mágico que se abre perto da sereia; ela nada até ele,
/// entra, e só então o Refúgio aparece.
final class RefugePortalNode: SKNode {
    private static let sparkTexture = SKTexture(imageNamed: "spark")
    private static let bokehTexture = SKTexture(imageNamed: "bokeh")
    private static let bubbleTexture = SKTexture(imageNamed: "bubble")

    private let backAura = SKShapeNode(ellipseOf: CGSize(width: 150, height: 220))
    private let outerRing = SKShapeNode(ellipseOf: CGSize(width: 112, height: 174))
    private let middleRing = SKShapeNode(ellipseOf: CGSize(width: 84, height: 134))
    private let innerSwirl = SKShapeNode(ellipseOf: CGSize(width: 62, height: 106))
    private let tideWell = SKShapeNode(ellipseOf: CGSize(width: 42, height: 78))
    private let core = SKShapeNode(ellipseOf: CGSize(width: 18, height: 42))
    private let threadLayer = SKNode()
    private let orbitLayer = SKNode()
    private let shaderTimeUniform = SKUniform(name: "u_time", float: 0)
    private var particleEmitters: [(node: SKEmitterNode, birthRate: CGFloat)] = []

    private static let portalShaderSource = """
    void main() {
        vec2 uv = v_tex_coord - vec2(0.5);
        uv.y *= 1.45;
        float d = length(uv);
        float angle = atan(uv.y, uv.x);
        float swirl = sin(angle * 3.0 + d * 18.0 - u_time * 2.1) * 0.5 + 0.5;
        float core = smoothstep(0.52, 0.0, d);
        float rim = smoothstep(0.42, 0.24, abs(d - 0.31));
        float alpha = (core * 0.34 + rim * 0.16 + swirl * core * 0.10);
        vec3 color = mix(vec3(0.10, 0.72, 0.86), vec3(0.74, 0.46, 0.96), swirl);
        gl_FragColor = vec4(color * alpha, alpha);
    }
    """

    override init() {
        super.init()
        zPosition = 9

        backAura.fillColor = UIColor(red: 0.16, green: 0.74, blue: 0.82, alpha: 0.05)
        backAura.strokeColor = UIColor(red: 0.75, green: 1.0, blue: 0.95, alpha: 0.09)
        backAura.lineWidth = 1.2
        backAura.glowWidth = 18
        backAura.blendMode = .add
        backAura.zPosition = -4
        addChild(backAura)

        outerRing.fillColor = UIColor(red: 0.22, green: 0.12, blue: 0.48, alpha: 0.18)
        outerRing.strokeColor = UIColor(red: 0.73, green: 0.95, blue: 1.0, alpha: 0.58)
        outerRing.lineWidth = 2.2
        outerRing.glowWidth = 10
        outerRing.blendMode = .add
        outerRing.zPosition = -1
        addChild(outerRing)

        middleRing.fillColor = UIColor(red: 0.18, green: 0.62, blue: 0.72, alpha: 0.08)
        middleRing.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 1.0, alpha: 0.32)
        middleRing.lineWidth = 1.0
        middleRing.glowWidth = 5
        middleRing.blendMode = .add
        middleRing.zPosition = 0
        addChild(middleRing)

        threadLayer.zPosition = 1
        addChild(threadLayer)
        buildTideThreads()

        innerSwirl.fillColor = UIColor(red: 0.48, green: 0.28, blue: 0.88, alpha: 0.12)
        innerSwirl.strokeColor = UIColor(red: 0.86, green: 1.0, blue: 0.96, alpha: 0.38)
        innerSwirl.lineWidth = 1.0
        innerSwirl.glowWidth = 5
        innerSwirl.blendMode = .add
        innerSwirl.zPosition = 2
        addChild(innerSwirl)

        tideWell.fillColor = UIColor(red: 0.02, green: 0.08, blue: 0.20, alpha: 0.52)
        tideWell.strokeColor = UIColor(red: 0.36, green: 0.94, blue: 0.98, alpha: 0.24)
        tideWell.lineWidth = 0.9
        tideWell.glowWidth = 5
        tideWell.zPosition = 3
        let portalShader = SKShader(source: Self.portalShaderSource)
        portalShader.uniforms = [shaderTimeUniform]
        tideWell.fillShader = portalShader
        addChild(tideWell)

        core.fillColor = UIColor(red: 0.95, green: 1.0, blue: 0.88, alpha: 0.56)
        core.strokeColor = .clear
        core.glowWidth = 7
        core.blendMode = .add
        core.zPosition = 4
        addChild(core)

        orbitLayer.zPosition = 5
        addChild(orbitLayer)
        buildOrbitingSparks()
        buildParticleEmitters()

        // começa fechado
        setScale(0.01)
        alpha = 0
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Abre devagar, com um giro suave — nada de pressa.
    func open() {
        setEmittersActive(true)
        run(.repeatForever(.customAction(withDuration: 12.0) { [weak self] _, elapsed in
            self?.shaderTimeUniform.floatValue = Float(elapsed)
        }), withKey: "portal_shader_time")

        let grow = SKAction.scale(to: 1.0, duration: 1.05)
        grow.eaeInEaseOut()
        run(.group([.fadeIn(withDuration: 0.7), grow]))
        backAura.run(.repeatForever(.sequence([
            .scale(to: 1.03, duration: 1.7),
            .scale(to: 0.99, duration: 1.7)
        ])))
        outerRing.run(.repeatForever(.sequence([
            .scale(to: 1.035, duration: 1.25),
            .scale(to: 1.0, duration: 1.0)
        ])))
        middleRing.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.36, duration: 1.0),
            .fadeAlpha(to: 0.78, duration: 1.3)
        ])))
        innerSwirl.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 6.0)))
        threadLayer.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 10.0)))
        orbitLayer.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 8.5)))
        tideWell.run(.repeatForever(.sequence([
            .scale(to: 0.96, duration: 1.1),
            .scale(to: 1.02, duration: 1.3)
        ])))
        core.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.26, duration: 0.8),
            .fadeAlpha(to: 0.64, duration: 1.0)
        ])))
    }

    /// Fecha e some do mundo.
    func close(after delay: TimeInterval = 0) {
        run(.sequence([
            .wait(forDuration: delay),
            .run { [weak self] in
                self?.setEmittersActive(false)
                self?.removeAction(forKey: "portal_shader_time")
            },
            .group([.scale(to: 0.01, duration: 0.5), .fadeOut(withDuration: 0.5)]),
            .removeFromParent()
        ]))
    }

    private func buildTideThreads() {
        for i in 0..<5 {
            let t = CGFloat(i) / 4
            let y = -48 + 96 * t
            let width = 34 + sin(t * .pi) * 38
            let bow = CGFloat(i.isMultiple(of: 2) ? 1 : -1) * CGFloat.random(in: 8...14)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -width / 2, y: y - 10))
            path.addCurve(to: CGPoint(x: width / 2, y: y + 10),
                          controlPoint1: CGPoint(x: -width * 0.14, y: y + bow),
                          controlPoint2: CGPoint(x: width * 0.18, y: y - bow))

            let thread = SKShapeNode(path: path.cgPath)
            let mix = CGFloat(i) / 8
            thread.strokeColor = UIColor.lerp(UIColor(red: 0.48, green: 0.96, blue: 1.0, alpha: 0.42),
                                              UIColor(red: 1.0, green: 0.76, blue: 0.98, alpha: 0.38),
                                              mix)
            thread.lineWidth = CGFloat.random(in: 0.7...1.4)
            thread.glowWidth = CGFloat.random(in: 1.5...4)
            thread.lineCap = .round
            thread.blendMode = .add
            thread.alpha = CGFloat.random(in: 0.18...0.38)
            thread.zRotation = CGFloat.random(in: -0.18...0.18)
            threadLayer.addChild(thread)

            thread.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.08, duration: Double.random(in: 0.9...1.4)),
                .fadeAlpha(to: thread.alpha, duration: Double.random(in: 0.8...1.4))
            ])))
        }
    }

    private func buildOrbitingSparks() {
        for i in 0..<8 {
            let angle = CGFloat(i) / 8 * .pi * 2
            let spark = SKSpriteNode(texture: Self.sparkTexture)
            let pointSize = CGFloat.random(in: 4...8)
            spark.size = CGSize(width: pointSize, height: pointSize)
            spark.position = CGPoint(x: cos(angle) * CGFloat.random(in: 48...62),
                                     y: sin(angle) * CGFloat.random(in: 68...88))
            spark.zRotation = angle
            spark.alpha = CGFloat.random(in: 0.18...0.42)
            spark.color = i.isMultiple(of: 3)
                ? UIColor(red: 1.0, green: 0.86, blue: 0.42, alpha: 1)
                : UIColor(red: 0.74, green: 1.0, blue: 0.96, alpha: 1)
            spark.colorBlendFactor = 0.55
            spark.blendMode = .add
            orbitLayer.addChild(spark)

            let pulse = SKAction.sequence([
                .scale(to: 0.75, duration: Double.random(in: 0.65...1.0)),
                .scale(to: 1.08, duration: Double.random(in: 0.65...1.0))
            ])
            spark.run(.repeatForever(.group([
                pulse,
                .rotate(byAngle: .pi * 2, duration: Double.random(in: 2.0...3.5))
            ])))
        }
    }

    private func buildParticleEmitters() {
        addParticleEmitter(texture: Self.bokehTexture,
                           birthRate: 3,
                           lifetime: 3.2,
                           speed: 8,
                           positionRange: CGVector(dx: 64, dy: 104),
                           scale: 0.2,
                           scaleRange: 0.12,
                           alpha: 0.12,
                           color: UIColor(red: 0.34, green: 0.95, blue: 1.0, alpha: 1),
                           zPosition: -2)
        addParticleEmitter(texture: Self.sparkTexture,
                           birthRate: 7,
                           lifetime: 1.6,
                           speed: 26,
                           positionRange: CGVector(dx: 84, dy: 128),
                           scale: 0.07,
                           scaleRange: 0.04,
                           alpha: 0.28,
                           color: UIColor(red: 1.0, green: 0.82, blue: 0.36, alpha: 1),
                           zPosition: 6)
        addParticleEmitter(texture: Self.sparkTexture,
                           birthRate: 5,
                           lifetime: 2.2,
                           speed: 18,
                           positionRange: CGVector(dx: 48, dy: 88),
                           scale: 0.1,
                           scaleRange: 0.06,
                           alpha: 0.22,
                           color: UIColor(red: 0.88, green: 0.72, blue: 1.0, alpha: 1),
                           zPosition: 2)
        addBubbleEmitter()
    }

    private func addBubbleEmitter() {
        let emitter = SKEmitterNode()
        emitter.particleTexture = Self.bubbleTexture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = 2.4
        emitter.particleLifetimeRange = 0.9
        emitter.particleSpeed = 34
        emitter.particleSpeedRange = 16
        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi / 5
        emitter.particlePositionRange = CGVector(dx: 76, dy: 26)
        emitter.particleScale = 0.08
        emitter.particleScaleRange = 0.04
        emitter.particleScaleSpeed = -0.018
        emitter.particleAlpha = 0.26
        emitter.particleAlphaRange = 0.12
        emitter.particleAlphaSpeed = -0.12
        emitter.particleColor = UIColor(red: 0.78, green: 1.0, blue: 0.96, alpha: 1)
        emitter.particleColorBlendFactor = 0.55
        emitter.particleBlendMode = .alpha
        emitter.zPosition = 4
        addChild(emitter)
        particleEmitters.append((node: emitter, birthRate: 14))
    }

    private func addParticleEmitter(texture: SKTexture,
                                    birthRate: CGFloat,
                                    lifetime: CGFloat,
                                    speed: CGFloat,
                                    positionRange: CGVector,
                                    scale: CGFloat,
                                    scaleRange: CGFloat,
                                    alpha: CGFloat,
                                    color: UIColor,
                                    zPosition: CGFloat) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleBirthRate = 0
        emitter.particleLifetime = lifetime
        emitter.particleLifetimeRange = lifetime * 0.38
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.8
        emitter.emissionAngleRange = .pi * 2
        emitter.particlePositionRange = positionRange
        emitter.particleScale = scale
        emitter.particleScaleRange = scaleRange
        emitter.particleScaleSpeed = -scale / max(lifetime, 0.1)
        emitter.particleAlpha = alpha
        emitter.particleAlphaRange = alpha * 0.45
        emitter.particleAlphaSpeed = -alpha / max(lifetime, 0.1)
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = .pi
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        emitter.zPosition = zPosition
        addChild(emitter)
        particleEmitters.append((node: emitter, birthRate: birthRate))
    }

    private func setEmittersActive(_ active: Bool) {
        for emitter in particleEmitters {
            emitter.node.particleBirthRate = active ? emitter.birthRate : 0
        }
    }
}

// MARK: - Cena do Refúgio (camada modal)

private struct RefugeArtDirection {
    let waterTop: UIColor
    let waterMid: UIColor
    let waterBottom: UIColor
    let shellPearl: UIColor
    let shellBlush: UIColor
    let reefRock: UIColor
    let warmWindow: UIColor
    let biolume: UIColor
    let shadow: UIColor
    let stageBiome: AquaticBiome

    static let pearlGrotto = RefugeArtDirection(
        waterTop: UIColor(red: 0.55, green: 0.88, blue: 0.94, alpha: 1),
        waterMid: UIColor(red: 0.14, green: 0.54, blue: 0.64, alpha: 1),
        waterBottom: UIColor(red: 0.05, green: 0.22, blue: 0.36, alpha: 1),
        shellPearl: UIColor(red: 0.94, green: 0.86, blue: 0.78, alpha: 1),
        shellBlush: UIColor(red: 0.88, green: 0.58, blue: 0.68, alpha: 1),
        reefRock: UIColor(red: 0.18, green: 0.31, blue: 0.34, alpha: 1),
        warmWindow: UIColor(red: 1.0, green: 0.66, blue: 0.32, alpha: 1),
        biolume: UIColor(red: 0.42, green: 0.96, blue: 0.92, alpha: 1),
        shadow: UIColor(red: 0.03, green: 0.10, blue: 0.18, alpha: 1),
        stageBiome: .coralGarden
    )
}

private final class RefugeVillageController {
    enum SceneState {
        case village
        case homeInterior
        case itemShopInterior
        case upgradeShopInterior
    }

    enum Interaction {
        case enterHome
        case enterItemShop
        case enterUpgradeShop
        case restInBedroom
        case talkToItemShopNpc
        case talkToUpgradeNpc
        case returnToVillage
    }

    private enum NpcKind {
        case itemShop
        case upgradeWorkshop
    }

    let node = SKNode()
    private let villageLayer = SKNode()
    private let exteriorWorldLayer = SKNode()
    private let interiorLayer = SKNode()
    private let itemShopInteriorLayer = SKNode()
    private let upgradeShopInteriorLayer = SKNode()
    private let charactersLayer = SKNode()
    private let effectsLayer = SKNode()

    private unowned let ctx: GameContext
    private let overlaySize: CGSize
    private let playableRect: CGRect
    private let art: RefugeArtDirection
    private let onOpenStore: () -> Void
    private let onOpenEnhancements: () -> Void
    private let onNeedsRefresh: () -> Void

    private var sceneState: SceneState = .village
    private var pendingInteraction: Interaction?
    private var isRouting = false
    private var isUserCommandActive = false
    private var suspendRoutineUntilExit = false
    private var routineTimer: CGFloat = 3
    private var routineIndex = 0
    private var restingBoostTimer: CGFloat = 0
    private var behaviorTextValue = "cruzando caminhos da vila"

    private var displayMermaid: Mermaid?
    private var mermaidBaseScale: CGFloat = 1

    private var plazaPoint = CGPoint.zero
    private var homeDoorPoint = CGPoint.zero
    private var homeExteriorDoorPoint = CGPoint.zero
    private var shopNpcPoint = CGPoint.zero
    private var workshopNpcPoint = CGPoint.zero
    private var shopExteriorDoorPoint = CGPoint.zero
    private var workshopExteriorDoorPoint = CGPoint.zero
    private var interiorDoorPoint = CGPoint.zero
    private var bedroomRestPoint = CGPoint.zero
    private var itemShopDoorPoint = CGPoint.zero
    private var itemShopNpcInteriorPoint = CGPoint.zero
    private var upgradeShopDoorPoint = CGPoint.zero
    private var upgradeShopNpcInteriorPoint = CGPoint.zero
    private var villageReturnPoint = CGPoint.zero
    private var lowerLaneY: CGFloat = 0
    private var lowerSurfaceY: CGFloat = 0
    private var exteriorBuildingScale: CGFloat = 1
    private var worldMinX: CGFloat = 0
    private var worldMaxX: CGFloat = 0
    private var worldWidth: CGFloat = 0

    private var homeHitFrame = CGRect.zero
    private var shopHitFrame = CGRect.zero
    private var workshopHitFrame = CGRect.zero
    private var homeBedFrame = CGRect.zero
    private var homeExitFrame = CGRect.zero
    private var itemShopExitFrame = CGRect.zero
    private var itemShopNpcFrame = CGRect.zero
    private var upgradeShopExitFrame = CGRect.zero
    private var upgradeShopNpcFrame = CGRect.zero
    var behaviorText: String { behaviorTextValue }
    init(overlaySize: CGSize,
         playableRect: CGRect,
         art: RefugeArtDirection,
         ctx: GameContext,
         onOpenStore: @escaping () -> Void,
         onOpenEnhancements: @escaping () -> Void,
         onNeedsRefresh: @escaping () -> Void) {
        self.overlaySize = overlaySize
        self.playableRect = playableRect
        self.art = art
        self.ctx = ctx
        self.onOpenStore = onOpenStore
        self.onOpenEnhancements = onOpenEnhancements
        self.onNeedsRefresh = onNeedsRefresh
        build()
    }

    private func build() {
        villageLayer.zPosition = 2
        interiorLayer.zPosition = 2.2
        itemShopInteriorLayer.zPosition = 2.2
        upgradeShopInteriorLayer.zPosition = 2.2
        charactersLayer.zPosition = 8
        effectsLayer.zPosition = 10

        node.addChild(villageLayer)
        node.addChild(interiorLayer)
        node.addChild(itemShopInteriorLayer)
        node.addChild(upgradeShopInteriorLayer)
        node.addChild(charactersLayer)
        node.addChild(effectsLayer)
        villageLayer.addChild(exteriorWorldLayer)

        buildVillageExterior()
        buildHomeInterior()
        buildItemShopInterior()
        buildUpgradeShopInterior()
        interiorLayer.isHidden = true
        interiorLayer.alpha = 0
        itemShopInteriorLayer.isHidden = true
        itemShopInteriorLayer.alpha = 0
        upgradeShopInteriorLayer.isHidden = true
        upgradeShopInteriorLayer.alpha = 0
        buildMermaid()
    }

    func update(dt: CGFloat) {
        if sceneState == .homeInterior, restingBoostTimer > 0 {
            restingBoostTimer = max(0, restingBoostTimer - dt)
            ctx.stats.energy = (ctx.stats.energy + dt * 1.4).clamped(to: 0...100)
            if restingBoostTimer == 0, !isUserCommandActive, !isRouting {
                if suspendRoutineUntilExit {
                    behaviorTextValue = "acordada no quarto de bolhas"
                    onNeedsRefresh()
                } else {
                    behaviorTextValue = "arrumando o quarto antes de sair"
                    onNeedsRefresh()
                    routeMermaid(to: interiorDoorPoint, interaction: .returnToVillage, userCommand: false)
                }
            }
        }

        if suspendRoutineUntilExit, sceneState != .village { return }

        guard !isRouting, !isUserCommandActive else { return }

        routineTimer -= dt
        guard routineTimer <= 0 else { return }
        routineTimer = CGFloat.random(in: 4.4...7.2)
        performAutonomousRoutineStep()
    }

    func handleTouch(at point: CGPoint) -> Bool {
        switch sceneState {
        case .village:
            guard playableRect.contains(point) else { return false }
            let worldPoint = exteriorWorldPoint(from: point)
            isUserCommandActive = true
            if matchesHit("village_home_door", at: point)
                || matchesHit("village_home", at: point)
                || homeHitFrame.contains(worldPoint) {
                routeMermaid(to: homeExteriorDoorPoint, interaction: .enterHome, userCommand: true)
                return true
            }
            if matchesHit("village_shop_door", at: point)
                || matchesHit("village_shop", at: point)
                || shopHitFrame.contains(worldPoint) {
                routeMermaid(to: shopExteriorDoorPoint, interaction: .enterItemShop, userCommand: true)
                return true
            }
            if matchesHit("village_workshop_door", at: point)
                || matchesHit("village_workshop", at: point)
                || workshopHitFrame.contains(worldPoint) {
                routeMermaid(to: workshopExteriorDoorPoint, interaction: .enterUpgradeShop, userCommand: true)
                return true
            }
            routeMermaid(to: exteriorPlatformTarget(for: point), interaction: nil, userCommand: true)
            return true
        case .homeInterior:
            guard playableRect.contains(point) else { return false }
            isUserCommandActive = true
            if matchesHit("home_bed", at: point) || homeBedFrame.contains(point) {
                routeMermaid(to: bedroomRestPoint, interaction: .restInBedroom, userCommand: true)
                return true
            }
            if matchesHit("home_exit", at: point) || homeExitFrame.contains(point) {
                routeMermaid(to: interiorDoorPoint, interaction: .returnToVillage, userCommand: true)
                return true
            }
            let target = CGPoint(x: point.x.clamped(to: playableRect.minX + 54...playableRect.maxX - 54),
                                 y: interiorDoorPoint.y)
            routeMermaid(to: target, interaction: nil, userCommand: true)
            return true
        case .itemShopInterior:
            guard playableRect.contains(point) else { return false }
            isUserCommandActive = true
            if matchesHit("item_shop_npc", at: point) || itemShopNpcFrame.contains(point) {
                routeMermaid(to: itemShopNpcInteriorPoint, interaction: .talkToItemShopNpc, userCommand: true)
                return true
            }
            if matchesHit("item_shop_exit", at: point) || itemShopExitFrame.contains(point) {
                routeMermaid(to: itemShopDoorPoint, interaction: .returnToVillage, userCommand: true)
                return true
            }
            let target = CGPoint(x: point.x.clamped(to: playableRect.minX + 54...playableRect.maxX - 54),
                                 y: itemShopDoorPoint.y)
            routeMermaid(to: target, interaction: nil, userCommand: true)
            return true
        case .upgradeShopInterior:
            guard playableRect.contains(point) else { return false }
            isUserCommandActive = true
            if matchesHit("upgrade_shop_npc", at: point) || upgradeShopNpcFrame.contains(point) {
                routeMermaid(to: upgradeShopNpcInteriorPoint, interaction: .talkToUpgradeNpc, userCommand: true)
                return true
            }
            if matchesHit("upgrade_shop_exit", at: point) || upgradeShopExitFrame.contains(point) {
                routeMermaid(to: upgradeShopDoorPoint, interaction: .returnToVillage, userCommand: true)
                return true
            }
            let target = CGPoint(x: point.x.clamped(to: playableRect.minX + 54...playableRect.maxX - 54),
                                 y: upgradeShopDoorPoint.y)
            routeMermaid(to: target, interaction: nil, userCommand: true)
            return true
        }
    }

    func requestReturnToVillage() -> Bool {
        guard sceneState != .village else { return false }
        isUserCommandActive = true
        routeMermaid(to: activeInteriorDoorPoint(), interaction: .returnToVillage, userCommand: true)
        return true
    }

    // MARK: - Exterior

    private func buildVillageExterior() {
        let stage = exteriorWorldLayer
        stage.removeAllChildren()
        stage.name = "village_world"
        stage.position = .zero

        lowerLaneY = playableRect.minY + max(92, playableRect.height * 0.25)
        lowerSurfaceY = lowerLaneY - 54
        exteriorBuildingScale = (playableRect.width / 340).clamped(to: 0.82...1)
        worldWidth = max(playableRect.width * 3.7, 1240)
        worldMinX = playableRect.minX
        worldMaxX = worldMinX + worldWidth

        plazaPoint = CGPoint(x: worldMinX + min(82, worldWidth * 0.08), y: lowerLaneY)
        homeDoorPoint = CGPoint(x: worldMinX + worldWidth * 0.15, y: lowerLaneY)
        shopNpcPoint = CGPoint(x: worldMinX + worldWidth * 0.48, y: lowerLaneY)
        workshopNpcPoint = CGPoint(x: worldMinX + worldWidth * 0.84, y: lowerLaneY)
        homeExteriorDoorPoint = homeDoorPoint + CGPoint(x: -16 * exteriorBuildingScale, y: 0)
        shopExteriorDoorPoint = shopNpcPoint + CGPoint(x: -38 * exteriorBuildingScale, y: 0)
        workshopExteriorDoorPoint = workshopNpcPoint + CGPoint(x: -22 * exteriorBuildingScale, y: 0)

        homeHitFrame = CGRect(x: homeExteriorDoorPoint.x - 58, y: lowerLaneY - 88, width: 116, height: 148)
        shopHitFrame = CGRect(x: shopExteriorDoorPoint.x - 60, y: lowerLaneY - 92, width: 120, height: 154)
        workshopHitFrame = CGRect(x: workshopExteriorDoorPoint.x - 62, y: lowerLaneY - 92, width: 124, height: 154)

        buildVillageSeafloor(stage: stage)
        buildVillagePaths(stage: stage)
        buildHorizontalVegetation(stage: stage)
        buildMermaidHouseExterior(stage: stage)
        buildItemShopExterior(stage: stage)
        buildUpgradeWorkshopExterior(stage: stage)
        buildExteriorLife(stage: stage)
    }

    private func buildVillageSeafloor(stage: SKNode) {
        let worldRect = CGRect(x: worldMinX,
                               y: playableRect.minY,
                               width: worldWidth,
                               height: playableRect.height)

        let water = SKShapeNode(rect: worldRect, cornerRadius: 24)
        water.fillColor = UIColor.white.withAlphaComponent(0.025)
        water.strokeColor = art.biolume.withAlphaComponent(0.08)
        water.lineWidth = 1
        water.zPosition = 0
        stage.addChild(water)

        let backRidge = UIBezierPath()
        backRidge.move(to: CGPoint(x: worldMinX - 30, y: playableRect.maxY - 48))
        backRidge.addCurve(to: CGPoint(x: worldMaxX + 30, y: playableRect.maxY - 58),
                           controlPoint1: CGPoint(x: worldMinX + worldWidth * 0.24, y: playableRect.maxY - 6),
                           controlPoint2: CGPoint(x: worldMaxX - worldWidth * 0.24, y: playableRect.maxY - 12))
        backRidge.addLine(to: CGPoint(x: worldMaxX + 30, y: playableRect.maxY - 126))
        backRidge.addCurve(to: CGPoint(x: worldMinX - 30, y: playableRect.maxY - 118),
                           controlPoint1: CGPoint(x: worldMaxX - worldWidth * 0.24, y: playableRect.maxY - 152),
                           controlPoint2: CGPoint(x: worldMinX + worldWidth * 0.20, y: playableRect.maxY - 148))
        backRidge.close()
        let ridge = SKShapeNode(path: backRidge.cgPath)
        ridge.fillColor = art.reefRock.withAlphaComponent(0.30)
        ridge.strokeColor = art.biolume.withAlphaComponent(0.10)
        ridge.lineWidth = 1
        ridge.zPosition = 0.3
        stage.addChild(ridge)

        let floor = UIBezierPath()
        floor.move(to: CGPoint(x: worldMinX - 38, y: playableRect.minY + 48))
        floor.addCurve(to: CGPoint(x: worldMaxX + 38, y: playableRect.minY + 46),
                       controlPoint1: CGPoint(x: worldMinX + worldWidth * 0.28, y: playableRect.minY + 8),
                       controlPoint2: CGPoint(x: worldMaxX - worldWidth * 0.25, y: playableRect.minY + 92))
        floor.addLine(to: CGPoint(x: worldMaxX + 38, y: playableRect.minY - 24))
        floor.addLine(to: CGPoint(x: worldMinX - 38, y: playableRect.minY - 24))
        floor.close()
        let seabed = SKShapeNode(path: floor.cgPath)
        seabed.fillColor = art.reefRock.withAlphaComponent(0.62)
        seabed.strokeColor = art.biolume.withAlphaComponent(0.16)
        seabed.lineWidth = 1.2
        seabed.zPosition = 0.8
        stage.addChild(seabed)

        addWorldStamp(kind: .reefSkirt,
                      variant: 27,
                      position: CGPoint(x: worldMinX + worldWidth / 2, y: playableRect.minY + 54),
                      size: CGSize(width: worldWidth * 0.98, height: min(124, playableRect.height * 0.24)),
                      z: 1.0,
                      alpha: 0.86,
                      stage: stage)
        addWorldStamp(kind: .kelpRibbon,
                      variant: 31,
                      position: CGPoint(x: worldMinX + 26, y: playableRect.midY),
                      size: CGSize(width: 70, height: min(190, playableRect.height * 0.58)),
                      z: 1.1,
                      alpha: 0.54,
                      stage: stage)
        addWorldStamp(kind: .kelpBush,
                      variant: 32,
                      position: CGPoint(x: worldMaxX - 24, y: playableRect.minY + playableRect.height * 0.56),
                      size: CGSize(width: 78, height: min(176, playableRect.height * 0.52)),
                      z: 1.1,
                      alpha: 0.50,
                      stage: stage)

        for index in 0..<10 {
            let lantern = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...4.5))
            lantern.fillColor = index.isMultiple(of: 3)
                ? art.warmWindow.withAlphaComponent(0.44)
                : art.biolume.withAlphaComponent(0.32)
            lantern.strokeColor = .clear
            lantern.glowWidth = 5
            lantern.position = CGPoint(x: CGFloat.random(in: worldMinX + 26...worldMaxX - 26),
                                       y: CGFloat.random(in: playableRect.minY + 56...playableRect.maxY - 50))
            lantern.zPosition = 1.2
            stage.addChild(lantern)
        }
    }

    private func buildVillagePaths(stage: SKNode) {
        buildSidePlatform(fromX: worldMinX - 18,
                          toX: worldMaxX + 18,
                          surfaceY: lowerSurfaceY,
                          height: 52,
                          tint: UIColor.lerp(art.reefRock, GameUI.algae, 0.22),
                          stage: stage)

        let plaza = SKShapeNode(rectOf: CGSize(width: 112, height: 18), cornerRadius: 7)
        plaza.fillColor = art.shellPearl.withAlphaComponent(0.34)
        plaza.strokeColor = art.biolume.withAlphaComponent(0.28)
        plaza.lineWidth = 1.2
        plaza.position = CGPoint(x: plazaPoint.x, y: lowerSurfaceY + 7)
        plaza.zPosition = 2.08
        stage.addChild(plaza)

        for index in 0..<11 {
            let shell = SKShapeNode(ellipseOf: CGSize(width: 11, height: 7))
            shell.fillColor = index.isMultiple(of: 3)
                ? art.shellBlush.withAlphaComponent(0.45)
                : art.shellPearl.withAlphaComponent(0.54)
            shell.strokeColor = UIColor.white.withAlphaComponent(0.16)
            shell.lineWidth = 0.5
            shell.position = CGPoint(x: worldMinX + 36 + CGFloat(index) * (worldWidth - 72) / 10,
                                     y: lowerSurfaceY + 17 + CGFloat(index % 2) * 2)
            shell.zPosition = 2.15
            stage.addChild(shell)
        }
    }

    private func buildHorizontalVegetation(stage: SKNode) {
        let clusters: [(x: CGFloat, width: CGFloat, variant: Int)] = [
            (homeDoorPoint.x + 160, 150, 41),
            (homeDoorPoint.x + 300, 122, 42),
            (shopNpcPoint.x + 170, 154, 43),
            (shopNpcPoint.x + 318, 120, 44),
            (workshopNpcPoint.x - 210, 142, 45)
        ]

        for cluster in clusters {
            addWorldStamp(kind: .kelpBush,
                          variant: cluster.variant,
                          position: CGPoint(x: cluster.x, y: lowerSurfaceY + 42),
                          size: CGSize(width: cluster.width,
                                       height: min(150, playableRect.height * 0.40)),
                          z: 2.32,
                          alpha: 0.58,
                          stage: stage)

            for index in 0..<5 {
                let blade = UIBezierPath()
                let x = cluster.x - cluster.width * 0.42 + CGFloat(index) * cluster.width * 0.21
                blade.move(to: CGPoint(x: x, y: lowerSurfaceY + 10))
                blade.addCurve(to: CGPoint(x: x + CGFloat(index % 2 == 0 ? 18 : -18), y: lowerSurfaceY + 62 + CGFloat(index % 3) * 10),
                               controlPoint1: CGPoint(x: x - 10, y: lowerSurfaceY + 28),
                               controlPoint2: CGPoint(x: x + 14, y: lowerSurfaceY + 44))
                let kelp = SKShapeNode(path: blade.cgPath)
                kelp.strokeColor = GameUI.algae.withAlphaComponent(0.56)
                kelp.lineWidth = 3.0
                kelp.lineCap = .round
                kelp.zPosition = 2.42
                stage.addChild(kelp)
            }

            for index in 0..<4 {
                let coral = SKShapeNode(ellipseOf: CGSize(width: 16 + CGFloat(index % 2) * 5,
                                                          height: 12 + CGFloat(index % 3) * 4))
                coral.fillColor = (index.isMultiple(of: 2) ? GameUI.coral : art.biolume).withAlphaComponent(0.30)
                coral.strokeColor = UIColor.white.withAlphaComponent(0.16)
                coral.lineWidth = 0.7
                coral.position = CGPoint(x: cluster.x - cluster.width * 0.35 + CGFloat(index) * cluster.width * 0.24,
                                         y: lowerSurfaceY + 18 + CGFloat(index % 2) * 4)
                coral.zPosition = 2.46
                stage.addChild(coral)
            }
        }
    }

    private func buildSidePlatform(fromX: CGFloat,
                                   toX: CGFloat,
                                   surfaceY: CGFloat,
                                   height: CGFloat,
                                   tint: UIColor,
                                   stage: SKNode) {
        let width = toX - fromX
        let top = SKShapeNode(rectOf: CGSize(width: width, height: 18), cornerRadius: 5)
        top.fillColor = art.shellPearl.withAlphaComponent(0.48)
        top.strokeColor = art.biolume.withAlphaComponent(0.18)
        top.lineWidth = 1
        top.position = CGPoint(x: fromX + width / 2, y: surfaceY)
        top.zPosition = 2.05
        stage.addChild(top)

        let body = UIBezierPath()
        body.move(to: CGPoint(x: fromX, y: surfaceY - 8))
        body.addLine(to: CGPoint(x: toX, y: surfaceY - 8))
        body.addLine(to: CGPoint(x: toX, y: surfaceY - height))
        for step in stride(from: toX, through: fromX, by: -18) {
            body.addLine(to: CGPoint(x: step - 9, y: surfaceY - height - CGFloat.random(in: 0...8)))
            body.addLine(to: CGPoint(x: max(fromX, step - 18), y: surfaceY - height))
        }
        body.close()
        let cliff = SKShapeNode(path: body.cgPath)
        cliff.fillColor = tint.withAlphaComponent(0.72)
        cliff.strokeColor = art.shadow.withAlphaComponent(0.30)
        cliff.lineWidth = 1
        cliff.zPosition = 1.92
        stage.addChild(cliff)

        for index in 0..<max(2, Int(width / 42)) {
            let tuft = UIBezierPath()
            let x = fromX + 18 + CGFloat(index) * 42
            tuft.move(to: CGPoint(x: x, y: surfaceY + 6))
            tuft.addCurve(to: CGPoint(x: x + CGFloat.random(in: -9...9), y: surfaceY + 28),
                          controlPoint1: CGPoint(x: x - 8, y: surfaceY + 12),
                          controlPoint2: CGPoint(x: x + 10, y: surfaceY + 20))
            let grass = SKShapeNode(path: tuft.cgPath)
            grass.strokeColor = GameUI.algae.withAlphaComponent(0.52)
            grass.lineWidth = CGFloat.random(in: 2.2...3.8)
            grass.lineCap = .round
            grass.zPosition = 2.18
            stage.addChild(grass)
        }
    }

    private func buildDoorPlaque(parent: SKNode,
                                 hitName: String,
                                 iconName: String,
                                 fallback: String,
                                 tint: UIColor,
                                 position: CGPoint) {
        let plaque = SKNode()
        plaque.name = hitName
        plaque.position = position
        plaque.zPosition = 6
        parent.addChild(plaque)

        let board = SKShapeNode(rectOf: CGSize(width: 40, height: 28), cornerRadius: 5)
        board.name = hitName
        board.fillColor = art.shellPearl.withAlphaComponent(0.50)
        board.strokeColor = tint.withAlphaComponent(0.56)
        board.lineWidth = 1.1
        plaque.addChild(board)

        let icon = GameUI.symbolIconNode(named: iconName,
                                         fallback: fallback,
                                         color: tint,
                                         size: 17)
        icon.name = hitName
        icon.zPosition = 1
        plaque.addChild(icon)

        let bead = SKShapeNode(circleOfRadius: 2.4)
        bead.name = hitName
        bead.fillColor = UIColor.white.withAlphaComponent(0.54)
        bead.strokeColor = .clear
        bead.position = CGPoint(x: 0, y: 12)
        bead.zPosition = 2
        plaque.addChild(bead)
    }

    private func buildDoorStep(parent: SKNode,
                               hitName: String,
                               tint: UIColor,
                               position: CGPoint,
                               width: CGFloat) {
        let step = SKShapeNode(rectOf: CGSize(width: width, height: 12), cornerRadius: 6)
        step.name = hitName
        step.fillColor = art.shellPearl.withAlphaComponent(0.44)
        step.strokeColor = tint.withAlphaComponent(0.24)
        step.lineWidth = 0.8
        step.position = position
        step.zPosition = 2.4
        parent.addChild(step)

        for index in 0..<3 {
            let pearl = SKShapeNode(circleOfRadius: 2.6)
            pearl.name = hitName
            pearl.fillColor = tint.withAlphaComponent(0.36)
            pearl.strokeColor = UIColor.white.withAlphaComponent(0.18)
            pearl.lineWidth = 0.4
            pearl.position = position + CGPoint(x: -width * 0.24 + CGFloat(index) * width * 0.24, y: 2)
            pearl.zPosition = 2.5
            parent.addChild(pearl)
        }
    }

    private func buildMermaidHouseExterior(stage: SKNode) {
        let home = SKNode()
        home.name = "village_home"
        home.position = homeDoorPoint
        home.zPosition = 3
        home.setScale(exteriorBuildingScale)
        stage.addChild(home)

        let foundation = SKShapeNode(ellipseOf: CGSize(width: 178, height: 58))
        foundation.name = "village_home"
        foundation.fillColor = art.shellPearl.withAlphaComponent(0.30)
        foundation.strokeColor = art.shellBlush.withAlphaComponent(0.36)
        foundation.lineWidth = 1.3
        foundation.position = CGPoint(x: 0, y: -28)
        home.addChild(foundation)

        let shell = UIBezierPath()
        shell.move(to: CGPoint(x: -84, y: -24))
        shell.addCurve(to: CGPoint(x: -34, y: 78),
                       controlPoint1: CGPoint(x: -84, y: 26),
                       controlPoint2: CGPoint(x: -66, y: 62))
        shell.addCurve(to: CGPoint(x: 64, y: 52),
                       controlPoint1: CGPoint(x: -2, y: 102),
                       controlPoint2: CGPoint(x: 42, y: 82))
        shell.addCurve(to: CGPoint(x: 86, y: -22),
                       controlPoint1: CGPoint(x: 82, y: 30),
                       controlPoint2: CGPoint(x: 96, y: 2))
        shell.addCurve(to: CGPoint(x: -84, y: -24),
                       controlPoint1: CGPoint(x: 38, y: 2),
                       controlPoint2: CGPoint(x: -34, y: -2))
        shell.close()
        let house = SKShapeNode(path: shell.cgPath)
        house.name = "village_home"
        house.fillColor = UIColor.lerp(art.shellPearl, art.shellBlush, 0.17).withAlphaComponent(0.76)
        house.strokeColor = art.shellBlush.withAlphaComponent(0.60)
        house.lineWidth = 1.8
        home.addChild(house)

        for i in 0..<8 {
            let ridge = UIBezierPath()
            let x = -62 + CGFloat(i) * 18
            ridge.move(to: CGPoint(x: x, y: -12))
            ridge.addCurve(to: CGPoint(x: -28 + CGFloat(i) * 11, y: 70),
                           controlPoint1: CGPoint(x: x - 8, y: 22),
                           controlPoint2: CGPoint(x: -48 + CGFloat(i) * 14, y: 48))
            let line = SKShapeNode(path: ridge.cgPath)
            line.name = "village_home"
            line.strokeColor = UIColor.white.withAlphaComponent(i.isMultiple(of: 2) ? 0.24 : 0.13)
            line.lineWidth = i.isMultiple(of: 2) ? 1.5 : 0.9
            line.lineCap = .round
            home.addChild(line)
        }

        let doorway = SKShapeNode(ellipseOf: CGSize(width: 48, height: 48))
        doorway.name = "village_home_door"
        doorway.fillColor = art.shadow.withAlphaComponent(0.42)
        doorway.strokeColor = art.biolume.withAlphaComponent(0.43)
        doorway.lineWidth = 1.3
        doorway.glowWidth = 4
        doorway.position = CGPoint(x: -16, y: -30)
        home.addChild(doorway)

        let doorShadow = SKShapeNode(rectOf: CGSize(width: 36, height: 42), cornerRadius: 10)
        doorShadow.name = "village_home_door"
        doorShadow.fillColor = art.shadow.withAlphaComponent(0.42)
        doorShadow.strokeColor = art.biolume.withAlphaComponent(0.28)
        doorShadow.lineWidth = 1
        doorShadow.position = CGPoint(x: -16, y: -34)
        doorShadow.zPosition = 1
        home.addChild(doorShadow)

        let window = SKShapeNode(ellipseOf: CGSize(width: 25, height: 18))
        window.name = "village_home"
        window.fillColor = art.warmWindow.withAlphaComponent(0.28)
        window.strokeColor = art.warmWindow.withAlphaComponent(0.64)
        window.lineWidth = 1
        window.glowWidth = 5
        window.position = CGPoint(x: 42, y: 28)
        home.addChild(window)

        let porch = SKShapeNode(rectOf: CGSize(width: 56, height: 14), cornerRadius: 7)
        porch.name = "village_home_door"
        porch.fillColor = art.shellPearl.withAlphaComponent(0.42)
        porch.strokeColor = .clear
        porch.position = CGPoint(x: -16, y: -50)
        home.addChild(porch)

        buildDoorPlaque(parent: home,
                        hitName: "village_home_door",
                        iconName: "house.fill",
                        fallback: "",
                        tint: art.warmWindow,
                        position: CGPoint(x: -16, y: 18))
    }

    private func buildItemShopExterior(stage: SKNode) {
        let market = SKNode()
        market.name = "village_shop"
        market.position = shopNpcPoint
        market.zPosition = 3
        market.setScale(exteriorBuildingScale)
        stage.addChild(market)

        let foundation = SKShapeNode(ellipseOf: CGSize(width: 166, height: 54))
        foundation.name = "village_shop"
        foundation.fillColor = UIColor.lerp(art.reefRock, GameUI.gold, 0.20).withAlphaComponent(0.66)
        foundation.strokeColor = GameUI.gold.withAlphaComponent(0.34)
        foundation.lineWidth = 1.2
        foundation.position = CGPoint(x: 0, y: -30)
        market.addChild(foundation)

        let counter = SKShapeNode(rectOf: CGSize(width: 126, height: 34), cornerRadius: 13)
        counter.name = "village_shop"
        counter.fillColor = art.shellPearl.withAlphaComponent(0.62)
        counter.strokeColor = GameUI.coral.withAlphaComponent(0.34)
        counter.lineWidth = 1.2
        counter.position = CGPoint(x: 6, y: -8)
        market.addChild(counter)

        let canopyPath = UIBezierPath()
        canopyPath.move(to: CGPoint(x: -72, y: -4))
        canopyPath.addCurve(to: CGPoint(x: 0, y: 58),
                            controlPoint1: CGPoint(x: -62, y: 36),
                            controlPoint2: CGPoint(x: -30, y: 62))
        canopyPath.addCurve(to: CGPoint(x: 74, y: -4),
                            controlPoint1: CGPoint(x: 33, y: 62),
                            controlPoint2: CGPoint(x: 63, y: 36))
        canopyPath.addCurve(to: CGPoint(x: -72, y: -4),
                            controlPoint1: CGPoint(x: 36, y: 10),
                            controlPoint2: CGPoint(x: -34, y: 10))
        canopyPath.close()
        let canopy = SKShapeNode(path: canopyPath.cgPath)
        canopy.name = "village_shop"
        canopy.fillColor = UIColor.lerp(art.shellPearl, GameUI.coral, 0.21).withAlphaComponent(0.72)
        canopy.strokeColor = GameUI.coral.withAlphaComponent(0.56)
        canopy.lineWidth = 1.5
        market.addChild(canopy)

        for i in 0..<6 {
            let jar = SKShapeNode(ellipseOf: CGSize(width: 14 + CGFloat(i % 2) * 3, height: 22 + CGFloat(i % 3) * 4))
            jar.name = "village_shop"
            jar.fillColor = art.biolume.withAlphaComponent(0.16 + CGFloat(i) * 0.018)
            jar.strokeColor = art.biolume.withAlphaComponent(0.42)
            jar.lineWidth = 0.9
            jar.position = CGPoint(x: -48 + CGFloat(i) * 20, y: -7 + CGFloat(i % 2) * 4)
            market.addChild(jar)
        }

        for i in 0..<4 {
            let box = SKShapeNode(rectOf: CGSize(width: 18, height: 13), cornerRadius: 3)
            box.name = "village_shop"
            box.fillColor = GameUI.gold.withAlphaComponent(0.34)
            box.strokeColor = GameUI.coral.withAlphaComponent(0.28)
            box.lineWidth = 0.8
            box.position = CGPoint(x: -40 + CGFloat(i) * 28, y: -27)
            market.addChild(box)
        }

        buildDoorPlaque(parent: market,
                        hitName: "village_shop_door",
                        iconName: "shippingbox.fill",
                        fallback: "",
                        tint: GameUI.coral,
                        position: CGPoint(x: -38, y: 24))

        let doorway = SKShapeNode(rectOf: CGSize(width: 42, height: 48), cornerRadius: 11)
        doorway.name = "village_shop_door"
        doorway.fillColor = art.shadow.withAlphaComponent(0.38)
        doorway.strokeColor = GameUI.coral.withAlphaComponent(0.34)
        doorway.lineWidth = 1
        doorway.position = CGPoint(x: -38, y: -36)
        doorway.zPosition = 2
        market.addChild(doorway)

        buildDoorStep(parent: market,
                      hitName: "village_shop_door",
                      tint: GameUI.coral,
                      position: CGPoint(x: -38, y: -61),
                      width: 58)
    }

    private func buildUpgradeWorkshopExterior(stage: SKNode) {
        let workshop = SKNode()
        workshop.name = "village_workshop"
        workshop.position = workshopNpcPoint
        workshop.zPosition = 3
        workshop.setScale(exteriorBuildingScale)
        stage.addChild(workshop)

        let foundation = SKShapeNode(ellipseOf: CGSize(width: 172, height: 56))
        foundation.name = "village_workshop"
        foundation.fillColor = UIColor.lerp(art.reefRock, art.biolume, 0.18).withAlphaComponent(0.62)
        foundation.strokeColor = art.biolume.withAlphaComponent(0.33)
        foundation.lineWidth = 1.2
        foundation.position = CGPoint(x: 0, y: -36)
        workshop.addChild(foundation)

        let dome = SKShapeNode(ellipseOf: CGSize(width: 146, height: 92))
        dome.name = "village_workshop"
        dome.fillColor = UIColor.lerp(art.reefRock, art.biolume, 0.16).withAlphaComponent(0.68)
        dome.strokeColor = art.biolume.withAlphaComponent(0.46)
        dome.lineWidth = 1.5
        dome.position = CGPoint(x: 8, y: 8)
        workshop.addChild(dome)

        let hatch = SKShapeNode(rectOf: CGSize(width: 50, height: 44), cornerRadius: 14)
        hatch.name = "village_workshop_door"
        hatch.fillColor = art.shadow.withAlphaComponent(0.36)
        hatch.strokeColor = art.biolume.withAlphaComponent(0.44)
        hatch.lineWidth = 1.2
        hatch.glowWidth = 3
        hatch.position = CGPoint(x: -22, y: -20)
        workshop.addChild(hatch)

        for i in 0..<5 {
            let crystal = UIBezierPath()
            let h = CGFloat(24 + i * 6)
            crystal.move(to: CGPoint(x: 0, y: h / 2))
            crystal.addLine(to: CGPoint(x: 9, y: 3))
            crystal.addLine(to: CGPoint(x: 4, y: -h / 2))
            crystal.addLine(to: CGPoint(x: -8, y: -h / 3))
            crystal.addLine(to: CGPoint(x: -10, y: 4))
            crystal.close()
            let shard = SKShapeNode(path: crystal.cgPath)
            shard.name = "village_workshop"
            shard.fillColor = UIColor.lerp(art.biolume, UIColor.white, 0.18).withAlphaComponent(0.40)
            shard.strokeColor = art.biolume.withAlphaComponent(0.62)
            shard.lineWidth = 1
            shard.glowWidth = 4
            shard.position = CGPoint(x: 30 + CGFloat(i) * 12, y: -10 + CGFloat(i % 2) * 8)
            workshop.addChild(shard)
        }

        let workbench = SKShapeNode(rectOf: CGSize(width: 68, height: 15), cornerRadius: 5)
        workbench.name = "village_workshop"
        workbench.fillColor = GameUI.gold.withAlphaComponent(0.30)
        workbench.strokeColor = art.biolume.withAlphaComponent(0.30)
        workbench.lineWidth = 0.8
        workbench.position = CGPoint(x: 18, y: -39)
        workshop.addChild(workbench)

        buildDoorPlaque(parent: workshop,
                        hitName: "village_workshop_door",
                        iconName: "gearshape.fill",
                        fallback: "",
                        tint: art.biolume,
                        position: CGPoint(x: -22, y: 24))

        let doorway = SKShapeNode(rectOf: CGSize(width: 42, height: 50), cornerRadius: 12)
        doorway.name = "village_workshop_door"
        doorway.fillColor = art.shadow.withAlphaComponent(0.36)
        doorway.strokeColor = art.biolume.withAlphaComponent(0.44)
        doorway.lineWidth = 1
        doorway.position = CGPoint(x: -22, y: -28)
        doorway.zPosition = 2
        workshop.addChild(doorway)

        buildDoorStep(parent: workshop,
                      hitName: "village_workshop_door",
                      tint: art.biolume,
                      position: CGPoint(x: -22, y: -55),
                      width: 58)
    }

    // MARK: - Interior

    private func buildHomeInterior() {
        let room = SKNode()
        room.name = "home_interior"
        interiorLayer.addChild(room)

        let interiorLaneY = playableRect.minY + max(96, playableRect.height * 0.31)
        interiorDoorPoint = CGPoint(x: playableRect.maxX - playableRect.width * 0.17,
                                    y: interiorLaneY)
        bedroomRestPoint = CGPoint(x: playableRect.minX + playableRect.width * 0.25,
                                   y: interiorLaneY)
        homeBedFrame = CGRect(x: bedroomRestPoint.x - 96, y: interiorLaneY - 84, width: 188, height: 142)
        homeExitFrame = CGRect(x: interiorDoorPoint.x - 58, y: interiorLaneY - 76, width: 116, height: 132)

        let shellRoom = UIBezierPath()
        shellRoom.move(to: CGPoint(x: playableRect.minX + 18, y: playableRect.minY + 32))
        shellRoom.addCurve(to: CGPoint(x: playableRect.midX, y: playableRect.maxY - 10),
                           controlPoint1: CGPoint(x: playableRect.minX + 14, y: playableRect.midY),
                           controlPoint2: CGPoint(x: playableRect.minX + playableRect.width * 0.24, y: playableRect.maxY + 18))
        shellRoom.addCurve(to: CGPoint(x: playableRect.maxX - 18, y: playableRect.minY + 32),
                           controlPoint1: CGPoint(x: playableRect.maxX - playableRect.width * 0.24, y: playableRect.maxY + 18),
                           controlPoint2: CGPoint(x: playableRect.maxX - 14, y: playableRect.midY))
        shellRoom.addCurve(to: CGPoint(x: playableRect.minX + 18, y: playableRect.minY + 32),
                           controlPoint1: CGPoint(x: playableRect.maxX - playableRect.width * 0.28, y: playableRect.minY - 2),
                           controlPoint2: CGPoint(x: playableRect.minX + playableRect.width * 0.28, y: playableRect.minY - 2))
        shellRoom.close()

        let walls = SKShapeNode(path: shellRoom.cgPath)
        walls.fillColor = UIColor.lerp(art.shellPearl, art.shellBlush, 0.12).withAlphaComponent(0.70)
        walls.strokeColor = art.shellBlush.withAlphaComponent(0.48)
        walls.lineWidth = 1.6
        walls.zPosition = 0.2
        room.addChild(walls)

        let floor = SKShapeNode(rectOf: CGSize(width: playableRect.width - 72, height: 22), cornerRadius: 7)
        floor.fillColor = art.shellPearl.withAlphaComponent(0.40)
        floor.strokeColor = art.biolume.withAlphaComponent(0.18)
        floor.lineWidth = 1
        floor.position = CGPoint(x: playableRect.midX, y: interiorLaneY - 54)
        floor.zPosition = 1.4
        room.addChild(floor)

        let floorCliff = SKShapeNode(rectOf: CGSize(width: playableRect.width - 86, height: 40), cornerRadius: 6)
        floorCliff.fillColor = UIColor.lerp(art.reefRock, art.shellPearl, 0.18).withAlphaComponent(0.38)
        floorCliff.strokeColor = .clear
        floorCliff.position = CGPoint(x: playableRect.midX, y: interiorLaneY - 84)
        floorCliff.zPosition = 1.1
        room.addChild(floorCliff)

        for i in 0..<11 {
            let ridge = UIBezierPath()
            let startX = playableRect.minX + playableRect.width * (0.12 + CGFloat(i) * 0.076)
            ridge.move(to: CGPoint(x: startX, y: playableRect.minY + 44))
            ridge.addCurve(to: CGPoint(x: playableRect.midX + (startX - playableRect.midX) * 0.18,
                                       y: playableRect.maxY - 24),
                           controlPoint1: CGPoint(x: startX - 18, y: playableRect.midY),
                           controlPoint2: CGPoint(x: playableRect.midX + (startX - playableRect.midX) * 0.35,
                                                  y: playableRect.maxY - 70))
            let line = SKShapeNode(path: ridge.cgPath)
            line.strokeColor = UIColor.white.withAlphaComponent(i.isMultiple(of: 2) ? 0.22 : 0.11)
            line.lineWidth = i.isMultiple(of: 2) ? 1.4 : 0.8
            line.lineCap = .round
            line.zPosition = 0.4
            room.addChild(line)
        }

        buildBedroomArea(room: room)
        buildHomeExit(room: room)
        buildInteriorDetails(room: room)
    }

    private func buildItemShopInterior() {
        let room = SKNode()
        room.name = "item_shop_interior"
        itemShopInteriorLayer.addChild(room)

        let laneY = playableRect.minY + max(96, playableRect.height * 0.31)
        itemShopDoorPoint = CGPoint(x: playableRect.minX + playableRect.width * 0.16, y: laneY)
        itemShopNpcInteriorPoint = CGPoint(x: playableRect.maxX - playableRect.width * 0.30, y: laneY)
        itemShopExitFrame = CGRect(x: itemShopDoorPoint.x - 58, y: laneY - 76, width: 116, height: 132)
        itemShopNpcFrame = CGRect(x: itemShopNpcInteriorPoint.x - 62, y: laneY - 82, width: 124, height: 146)

        buildShopRoomBackdrop(room: room,
                              laneY: laneY,
                              tint: GameUI.coral,
                              accent: GameUI.gold)

        let exit = SKNode()
        exit.name = "item_shop_exit"
        exit.position = itemShopDoorPoint
        exit.zPosition = 4
        room.addChild(exit)
        let door = SKShapeNode(rectOf: CGSize(width: 60, height: 64), cornerRadius: 12)
        door.name = "item_shop_exit"
        door.fillColor = art.shadow.withAlphaComponent(0.40)
        door.strokeColor = GameUI.coral.withAlphaComponent(0.42)
        door.lineWidth = 1.2
        door.glowWidth = 3
        exit.addChild(door)

        let counter = SKShapeNode(rectOf: CGSize(width: 138, height: 34), cornerRadius: 10)
        counter.fillColor = art.shellPearl.withAlphaComponent(0.62)
        counter.strokeColor = GameUI.coral.withAlphaComponent(0.30)
        counter.lineWidth = 1
        counter.position = CGPoint(x: itemShopNpcInteriorPoint.x, y: laneY - 36)
        counter.zPosition = 4.4
        room.addChild(counter)

        for index in 0..<6 {
            let jar = SKShapeNode(ellipseOf: CGSize(width: 17, height: 26))
            jar.fillColor = art.biolume.withAlphaComponent(0.16 + CGFloat(index) * 0.018)
            jar.strokeColor = art.biolume.withAlphaComponent(0.40)
            jar.lineWidth = 0.8
            jar.position = CGPoint(x: itemShopNpcInteriorPoint.x - 54 + CGFloat(index) * 20,
                                   y: laneY + 18 + CGFloat(index % 2) * 5)
            jar.zPosition = 3.6
            room.addChild(jar)
        }

        buildNpc(at: itemShopNpcInteriorPoint + CGPoint(x: 0, y: -20),
                 hitName: "item_shop_npc",
                 tint: GameUI.coral,
                 kind: .itemShop,
                 stage: room)
    }

    private func buildUpgradeShopInterior() {
        let room = SKNode()
        room.name = "upgrade_shop_interior"
        upgradeShopInteriorLayer.addChild(room)

        let laneY = playableRect.minY + max(96, playableRect.height * 0.31)
        upgradeShopDoorPoint = CGPoint(x: playableRect.minX + playableRect.width * 0.16, y: laneY)
        upgradeShopNpcInteriorPoint = CGPoint(x: playableRect.maxX - playableRect.width * 0.30, y: laneY)
        upgradeShopExitFrame = CGRect(x: upgradeShopDoorPoint.x - 58, y: laneY - 76, width: 116, height: 132)
        upgradeShopNpcFrame = CGRect(x: upgradeShopNpcInteriorPoint.x - 62, y: laneY - 82, width: 124, height: 146)

        buildShopRoomBackdrop(room: room,
                              laneY: laneY,
                              tint: art.biolume,
                              accent: GameUI.algae)

        let exit = SKNode()
        exit.name = "upgrade_shop_exit"
        exit.position = upgradeShopDoorPoint
        exit.zPosition = 4
        room.addChild(exit)
        let door = SKShapeNode(rectOf: CGSize(width: 60, height: 64), cornerRadius: 12)
        door.name = "upgrade_shop_exit"
        door.fillColor = art.shadow.withAlphaComponent(0.40)
        door.strokeColor = art.biolume.withAlphaComponent(0.44)
        door.lineWidth = 1.2
        door.glowWidth = 3
        exit.addChild(door)

        let bench = SKShapeNode(rectOf: CGSize(width: 150, height: 28), cornerRadius: 9)
        bench.fillColor = art.reefRock.withAlphaComponent(0.48)
        bench.strokeColor = art.biolume.withAlphaComponent(0.30)
        bench.lineWidth = 1
        bench.position = CGPoint(x: upgradeShopNpcInteriorPoint.x, y: laneY - 38)
        bench.zPosition = 4.4
        room.addChild(bench)

        for index in 0..<5 {
            let shard = UIBezierPath()
            let h = CGFloat(24 + index * 5)
            shard.move(to: CGPoint(x: 0, y: h / 2))
            shard.addLine(to: CGPoint(x: 9, y: 4))
            shard.addLine(to: CGPoint(x: 4, y: -h / 2))
            shard.addLine(to: CGPoint(x: -8, y: -h / 3))
            shard.addLine(to: CGPoint(x: -10, y: 3))
            shard.close()
            let crystal = SKShapeNode(path: shard.cgPath)
            crystal.fillColor = art.biolume.withAlphaComponent(0.34)
            crystal.strokeColor = art.biolume.withAlphaComponent(0.68)
            crystal.lineWidth = 1
            crystal.glowWidth = 4
            crystal.position = CGPoint(x: upgradeShopNpcInteriorPoint.x - 58 + CGFloat(index) * 28,
                                       y: laneY + 6 + CGFloat(index % 2) * 6)
            crystal.zPosition = 3.6
            room.addChild(crystal)
        }

        buildNpc(at: upgradeShopNpcInteriorPoint + CGPoint(x: 0, y: -20),
                 hitName: "upgrade_shop_npc",
                 tint: art.biolume,
                 kind: .upgradeWorkshop,
                 stage: room)
    }

    private func buildShopRoomBackdrop(room: SKNode,
                                       laneY: CGFloat,
                                       tint: UIColor,
                                       accent: UIColor) {
        let shellRoom = SKShapeNode(rectOf: CGSize(width: playableRect.width - 34,
                                                   height: playableRect.height - 34),
                                    cornerRadius: 24)
        shellRoom.fillColor = UIColor.lerp(art.reefRock, tint, 0.12).withAlphaComponent(0.44)
        shellRoom.strokeColor = tint.withAlphaComponent(0.30)
        shellRoom.lineWidth = 1.4
        shellRoom.position = CGPoint(x: playableRect.midX, y: playableRect.midY)
        shellRoom.zPosition = 0.2
        room.addChild(shellRoom)

        let floor = SKShapeNode(rectOf: CGSize(width: playableRect.width - 72, height: 22), cornerRadius: 7)
        floor.fillColor = art.shellPearl.withAlphaComponent(0.40)
        floor.strokeColor = tint.withAlphaComponent(0.22)
        floor.lineWidth = 1
        floor.position = CGPoint(x: playableRect.midX, y: laneY - 54)
        floor.zPosition = 1.4
        room.addChild(floor)

        let wallShelf = SKShapeNode(rectOf: CGSize(width: playableRect.width * 0.42, height: 16), cornerRadius: 6)
        wallShelf.fillColor = accent.withAlphaComponent(0.24)
        wallShelf.strokeColor = tint.withAlphaComponent(0.18)
        wallShelf.lineWidth = 1
        wallShelf.position = CGPoint(x: playableRect.midX, y: laneY + 58)
        wallShelf.zPosition = 2.2
        room.addChild(wallShelf)

        for index in 0..<7 {
            let lamp = SKShapeNode(circleOfRadius: CGFloat.random(in: 3.5...6.5))
            lamp.fillColor = tint.withAlphaComponent(0.28)
            lamp.strokeColor = UIColor.white.withAlphaComponent(0.14)
            lamp.lineWidth = 0.6
            lamp.glowWidth = 5
            lamp.position = CGPoint(x: playableRect.minX + playableRect.width * CGFloat.random(in: 0.18...0.84),
                                    y: playableRect.minY + playableRect.height * CGFloat.random(in: 0.50...0.84))
            lamp.zPosition = 2
            room.addChild(lamp)
        }
    }

    private func buildBedroomArea(room: SKNode) {
        let area = SKNode()
        area.name = "home_bed"
        area.position = bedroomRestPoint
        area.zPosition = 3
        room.addChild(area)

        let niche = SKShapeNode(ellipseOf: CGSize(width: 178, height: 116))
        niche.name = "home_bed"
        niche.fillColor = art.shadow.withAlphaComponent(0.14)
        niche.strokeColor = art.shellBlush.withAlphaComponent(0.30)
        niche.lineWidth = 1.1
        niche.position = CGPoint(x: 0, y: 8)
        area.addChild(niche)

        let bedShell = UIBezierPath()
        bedShell.move(to: CGPoint(x: -78, y: -8))
        bedShell.addCurve(to: CGPoint(x: 0, y: 56),
                          controlPoint1: CGPoint(x: -64, y: 36),
                          controlPoint2: CGPoint(x: -34, y: 58))
        bedShell.addCurve(to: CGPoint(x: 80, y: -8),
                          controlPoint1: CGPoint(x: 38, y: 58),
                          controlPoint2: CGPoint(x: 68, y: 36))
        bedShell.addCurve(to: CGPoint(x: -78, y: -8),
                          controlPoint1: CGPoint(x: 34, y: 15),
                          controlPoint2: CGPoint(x: -32, y: 15))
        bedShell.close()
        let shell = SKShapeNode(path: bedShell.cgPath)
        shell.name = "home_bed"
        shell.fillColor = art.shellPearl.withAlphaComponent(0.74)
        shell.strokeColor = art.shellBlush.withAlphaComponent(0.60)
        shell.lineWidth = 1.5
        area.addChild(shell)

        let mattress = SKShapeNode(ellipseOf: CGSize(width: 128, height: 42))
        mattress.name = "home_bed"
        mattress.fillColor = art.biolume.withAlphaComponent(0.18)
        mattress.strokeColor = art.biolume.withAlphaComponent(0.48)
        mattress.lineWidth = 1.2
        mattress.position = CGPoint(x: 3, y: -5)
        mattress.zPosition = 2
        area.addChild(mattress)

        for i in 0..<18 {
            let radius = CGFloat.random(in: 6...14)
            let bubble = SKShapeNode(circleOfRadius: radius)
            bubble.name = "home_bed"
            bubble.fillColor = UIColor.white.withAlphaComponent(0.12)
            bubble.strokeColor = art.biolume.withAlphaComponent(0.42)
            bubble.lineWidth = 1
            bubble.glowWidth = 3
            bubble.position = CGPoint(x: CGFloat.random(in: -58...62),
                                      y: CGFloat.random(in: -16...18))
            bubble.zPosition = 3
            area.addChild(bubble)
        }

        let pillow = SKShapeNode(ellipseOf: CGSize(width: 38, height: 23))
        pillow.name = "home_bed"
        pillow.fillColor = UIColor.white.withAlphaComponent(0.18)
        pillow.strokeColor = UIColor.white.withAlphaComponent(0.24)
        pillow.position = CGPoint(x: -40, y: 2)
        pillow.zPosition = 4
        area.addChild(pillow)
    }

    private func buildHomeExit(room: SKNode) {
        let door = SKNode()
        door.name = "home_exit"
        door.position = interiorDoorPoint
        door.zPosition = 4
        room.addChild(door)

        let opening = SKShapeNode(ellipseOf: CGSize(width: 64, height: 58))
        opening.name = "home_exit"
        opening.fillColor = art.shadow.withAlphaComponent(0.34)
        opening.strokeColor = art.biolume.withAlphaComponent(0.45)
        opening.lineWidth = 1.3
        opening.glowWidth = 4
        door.addChild(opening)

        let path = SKShapeNode(rectOf: CGSize(width: 86, height: 16), cornerRadius: 8)
        path.name = "home_exit"
        path.fillColor = art.shellPearl.withAlphaComponent(0.34)
        path.strokeColor = .clear
        path.position = CGPoint(x: 0, y: -38)
        door.addChild(path)

        let arrowShell = SKShapeNode(ellipseOf: CGSize(width: 18, height: 10))
        arrowShell.name = "home_exit"
        arrowShell.fillColor = art.biolume.withAlphaComponent(0.38)
        arrowShell.strokeColor = UIColor.white.withAlphaComponent(0.24)
        arrowShell.position = CGPoint(x: 0, y: 26)
        door.addChild(arrowShell)
    }

    private func buildInteriorDetails(room: SKNode) {
        for index in 0..<5 {
            let lamp = SKShapeNode(circleOfRadius: CGFloat.random(in: 3.5...6.5))
            lamp.fillColor = index.isMultiple(of: 2)
                ? art.warmWindow.withAlphaComponent(0.38)
                : art.biolume.withAlphaComponent(0.30)
            lamp.strokeColor = UIColor.white.withAlphaComponent(0.12)
            lamp.lineWidth = 0.6
            lamp.glowWidth = 6
            lamp.position = CGPoint(x: playableRect.minX + playableRect.width * CGFloat.random(in: 0.16...0.84),
                                    y: playableRect.minY + playableRect.height * CGFloat.random(in: 0.42...0.84))
            lamp.zPosition = 2
            room.addChild(lamp)
        }

        for index in 0..<9 {
            let strand = UIBezierPath()
            let x = playableRect.minX + playableRect.width * CGFloat.random(in: 0.09...0.91)
            let baseY = playableRect.minY + 50
            strand.move(to: CGPoint(x: x, y: baseY))
            strand.addCurve(to: CGPoint(x: x + CGFloat.random(in: -24...24),
                                        y: baseY + CGFloat.random(in: 44...86)),
                            controlPoint1: CGPoint(x: x + CGFloat.random(in: -16...16), y: baseY + 20),
                            controlPoint2: CGPoint(x: x + CGFloat.random(in: -22...22), y: baseY + 48))
            let kelp = SKShapeNode(path: strand.cgPath)
            kelp.strokeColor = GameUI.algae.withAlphaComponent(0.38)
            kelp.lineWidth = CGFloat.random(in: 2.0...4.0)
            kelp.lineCap = .round
            kelp.zPosition = 2
            room.addChild(kelp)
        }
    }

    // MARK: - Movimento e interação

    private func routeMermaid(to point: CGPoint, interaction: Interaction?, userCommand: Bool) {
        guard let mermaid = displayMermaid else { return }
        let destination = sceneState == .village
            ? clampedToVillageWorld(point)
            : clampedToPlayable(point, inset: 44)
        pendingInteraction = interaction
        isRouting = true
        isUserCommandActive = userCommand
        restingBoostTimer = interaction == .restInBedroom ? restingBoostTimer : 0

        behaviorTextValue = behaviorText(for: interaction, movingTo: destination)
        onNeedsRefresh()

        let base = mermaid.base
        base.removeAction(forKey: "refuge_route")
        base.removeAction(forKey: "refuge_idle")
        let dx = destination.x - base.position.x
        if abs(dx) > 3 {
            mermaid.setVisualDirection(dx < 0 ? .left : .right)
            base.xScale = abs(mermaidBaseScale) * (dx < 0 ? -1 : 1)
            base.yScale = abs(mermaidBaseScale)
        }
        mermaid.applyExpression(expression(for: interaction), animated: true)
        mermaid.setAnimationMode(.swing)

        let waypoints = platformWaypoints(from: base.position, to: destination)
        var current = base.position
        var totalDuration: TimeInterval = 0
        let routeActions = waypoints.compactMap { point -> SKAction? in
            let distance = hypot(point.x - current.x, point.y - current.y)
            guard distance > 1 else { return nil }
            current = point
            let duration = TimeInterval((distance / 140).clamped(to: 0.18...6.2))
            totalDuration += duration
            let move = SKAction.move(to: point, duration: duration)
            move.timingMode = .easeInEaseOut
            return move
        }
        let movement = routeActions.isEmpty ? SKAction.wait(forDuration: 0.01) : SKAction.sequence(routeActions)
        let pulseCount = max(1, Int(totalDuration / 0.36))
        let pulse = SKAction.repeat(.sequence([
            .scaleX(to: base.xScale * 1.018, y: base.yScale * 0.985, duration: 0.18),
            .scaleX(to: base.xScale, y: base.yScale, duration: 0.18)
        ]), count: pulseCount)
        var groupedActions: [SKAction] = [movement, pulse]
        if sceneState == .village {
            groupedActions.append(.customAction(withDuration: max(totalDuration, 0.01)) { [weak self, weak base] _, _ in
                guard let base else { return }
                self?.updateExteriorCamera(focusing: base.position.x)
            })
        }
        base.run(.sequence([
            .group(groupedActions),
            .run { [weak self] in
                if self?.sceneState == .village, let x = self?.displayMermaid?.base.position.x {
                    self?.updateExteriorCamera(focusing: x)
                }
                self?.isRouting = false
                self?.completePendingInteraction()
            }
        ]), withKey: "refuge_route")
    }

    private func platformWaypoints(from start: CGPoint, to destination: CGPoint) -> [CGPoint] {
        guard sceneState == .village else { return [destination] }
        return [CGPoint(x: destination.x, y: lowerLaneY)]
    }

    private func exteriorPlatformTarget(for point: CGPoint) -> CGPoint {
        let worldPoint = exteriorWorldPoint(from: point)
        return CGPoint(x: worldPoint.x.clamped(to: worldMinX + 42...worldMaxX - 42),
                       y: lowerLaneY)
    }

    private func completePendingInteraction() {
        guard let interaction = pendingInteraction else {
            settleMermaidIdle()
            isUserCommandActive = false
            behaviorTextValue = idleBehaviorText()
            onNeedsRefresh()
            return
        }
        pendingInteraction = nil

        switch interaction {
        case .enterHome:
            suspendRoutineUntilExit = isUserCommandActive
            GameAudio.shared.play(.uiConfirm)
            showHomeInterior()
        case .enterItemShop:
            suspendRoutineUntilExit = isUserCommandActive
            GameAudio.shared.play(.uiConfirm)
            showItemShopInterior()
        case .enterUpgradeShop:
            suspendRoutineUntilExit = isUserCommandActive
            GameAudio.shared.play(.uiConfirm)
            showUpgradeShopInterior()
        case .restInBedroom:
            GameAudio.shared.play(.uiConfirm)
            beginRestPose()
            restingBoostTimer = 8
            behaviorTextValue = "descansando no quartinho da casa"
            ctx.say("Ela se recolheu no ninho de algas para descansar.")
            isUserCommandActive = false
        case .talkToItemShopNpc:
            GameAudio.shared.play(.uiOpenPanel)
            settleMermaidIdle()
            behaviorTextValue = "conversando com o comerciante da loja"
            onOpenStore()
            isUserCommandActive = false
        case .talkToUpgradeNpc:
            GameAudio.shared.play(.uiOpenPanel)
            settleMermaidIdle()
            behaviorTextValue = "conversando com o inventor da oficina"
            onOpenEnhancements()
            isUserCommandActive = false
        case .returnToVillage:
            GameAudio.shared.play(.uiConfirm)
            showVillageExterior()
        }
        onNeedsRefresh()
    }

    private func showHomeInterior() {
        sceneState = .homeInterior
        villageReturnPoint = homeExteriorDoorPoint + CGPoint(x: 28, y: 0)
        hideInteriorLayers(except: interiorLayer)
        villageLayer.removeAllActions()
        villageLayer.run(.fadeOut(withDuration: 0.18)) { [weak self] in
            self?.villageLayer.isHidden = true
        }
        interiorLayer.removeAllActions()
        interiorLayer.isHidden = false
        interiorLayer.alpha = 0
        interiorLayer.run(.fadeIn(withDuration: 0.22))
        charactersLayer.position = .zero
        displayMermaid?.base.position = interiorDoorPoint
        displayMermaid?.setVisualDirection(.left)
        settleMermaidIdle()
        behaviorTextValue = "dentro da casa, perto da entrada"
        isUserCommandActive = false
    }

    private func showItemShopInterior() {
        sceneState = .itemShopInterior
        villageReturnPoint = shopExteriorDoorPoint
        hideInteriorLayers(except: itemShopInteriorLayer)
        villageLayer.removeAllActions()
        villageLayer.run(.fadeOut(withDuration: 0.18)) { [weak self] in
            self?.villageLayer.isHidden = true
        }
        itemShopInteriorLayer.removeAllActions()
        itemShopInteriorLayer.isHidden = false
        itemShopInteriorLayer.alpha = 0
        itemShopInteriorLayer.run(.fadeIn(withDuration: 0.22))
        charactersLayer.position = .zero
        displayMermaid?.base.position = itemShopDoorPoint
        displayMermaid?.setVisualDirection(.right)
        settleMermaidIdle()
        behaviorTextValue = "dentro da loja, diante do balcão"
        isUserCommandActive = false
    }

    private func showUpgradeShopInterior() {
        sceneState = .upgradeShopInterior
        villageReturnPoint = workshopExteriorDoorPoint
        hideInteriorLayers(except: upgradeShopInteriorLayer)
        villageLayer.removeAllActions()
        villageLayer.run(.fadeOut(withDuration: 0.18)) { [weak self] in
            self?.villageLayer.isHidden = true
        }
        upgradeShopInteriorLayer.removeAllActions()
        upgradeShopInteriorLayer.isHidden = false
        upgradeShopInteriorLayer.alpha = 0
        upgradeShopInteriorLayer.run(.fadeIn(withDuration: 0.22))
        charactersLayer.position = .zero
        displayMermaid?.base.position = upgradeShopDoorPoint
        displayMermaid?.setVisualDirection(.right)
        settleMermaidIdle()
        behaviorTextValue = "dentro da oficina, perto das bancadas"
        isUserCommandActive = false
    }

    private func showVillageExterior() {
        sceneState = .village
        suspendRoutineUntilExit = false
        hideInteriorLayers(except: nil)
        villageLayer.removeAllActions()
        villageLayer.isHidden = false
        villageLayer.alpha = 0
        villageLayer.run(.fadeIn(withDuration: 0.22))
        displayMermaid?.base.position = villageReturnPoint == .zero ? homeExteriorDoorPoint : villageReturnPoint
        updateExteriorCamera(focusing: displayMermaid?.base.position.x ?? plazaPoint.x)
        displayMermaid?.setVisualDirection(.right)
        settleMermaidIdle()
        behaviorTextValue = "voltando para a plataforma da vila"
        isUserCommandActive = false
    }

    private func hideInteriorLayers(except visibleLayer: SKNode?) {
        for layer in [interiorLayer, itemShopInteriorLayer, upgradeShopInteriorLayer] {
            guard layer !== visibleLayer else { continue }
            layer.removeAllActions()
            layer.run(.fadeOut(withDuration: 0.12)) {
                layer.isHidden = true
            }
        }
    }

    private func activeInteriorDoorPoint() -> CGPoint {
        switch sceneState {
        case .homeInterior: return interiorDoorPoint
        case .itemShopInterior: return itemShopDoorPoint
        case .upgradeShopInterior: return upgradeShopDoorPoint
        case .village: return homeExteriorDoorPoint
        }
    }

    private func idleBehaviorText() -> String {
        switch sceneState {
        case .village: return "nadando pelos caminhos da vila"
        case .homeInterior: return "descansando no quarto de bolhas"
        case .itemShopInterior: return "olhando as prateleiras da loja"
        case .upgradeShopInterior: return "observando ferramentas da oficina"
        }
    }

    private func performAutonomousRoutineStep() {
        switch sceneState {
        case .village:
            let stops: [(CGPoint, Interaction?)] = [
                (plazaPoint, nil),
                (homeExteriorDoorPoint + CGPoint(x: 34, y: 0), nil),
                (shopExteriorDoorPoint + CGPoint(x: 36, y: 0), nil),
                (CGPoint(x: (shopExteriorDoorPoint.x + workshopExteriorDoorPoint.x) / 2, y: lowerLaneY), nil),
                (workshopExteriorDoorPoint + CGPoint(x: 36, y: 0), nil),
                (homeExteriorDoorPoint, .enterHome)
            ]
            let stop = stops[routineIndex % stops.count]
            routineIndex += 1
            routeMermaid(to: stop.0, interaction: stop.1, userCommand: false)
        case .homeInterior:
            let stop: (CGPoint, Interaction?) = routineIndex.isMultiple(of: 2)
                ? (bedroomRestPoint, .restInBedroom)
                : (interiorDoorPoint, .returnToVillage)
            routineIndex += 1
            routeMermaid(to: stop.0, interaction: stop.1, userCommand: false)
        case .itemShopInterior:
            let stop: (CGPoint, Interaction?) = routineIndex.isMultiple(of: 2)
                ? (itemShopNpcInteriorPoint + CGPoint(x: -38, y: 0), nil)
                : (itemShopDoorPoint, .returnToVillage)
            routineIndex += 1
            routeMermaid(to: stop.0, interaction: stop.1, userCommand: false)
        case .upgradeShopInterior:
            let stop: (CGPoint, Interaction?) = routineIndex.isMultiple(of: 2)
                ? (upgradeShopNpcInteriorPoint + CGPoint(x: -38, y: 0), nil)
                : (upgradeShopDoorPoint, .returnToVillage)
            routineIndex += 1
            routeMermaid(to: stop.0, interaction: stop.1, userCommand: false)
        }
    }

    private func behaviorText(for interaction: Interaction?, movingTo point: CGPoint) -> String {
        guard let interaction else {
            return idleBehaviorText()
        }
        switch interaction {
        case .enterHome: return "nadando até a entrada da própria casa"
        case .enterItemShop: return "indo até a porta da loja"
        case .enterUpgradeShop: return "indo até a porta da oficina"
        case .restInBedroom: return "indo para o ninho de descanso"
        case .talkToItemShopNpc: return "nadando até o comerciante dentro da loja"
        case .talkToUpgradeNpc: return "nadando até o inventor dentro da oficina"
        case .returnToVillage: return "voltando para a vila"
        }
    }

    private func expression(for interaction: Interaction?) -> MermaidExpressionName {
        switch interaction {
        case .restInBedroom: return .tired
        case .talkToItemShopNpc, .talkToUpgradeNpc: return .curious
        case .enterHome, .enterItemShop, .enterUpgradeShop, .returnToVillage, nil: return .neutral
        }
    }

    private func settleMermaidIdle() {
        guard let mermaid = displayMermaid else { return }
        mermaid.setAnimationMode(.idle)
        mermaid.applyExpression(.neutral, animated: true)
        mermaid.base.removeAction(forKey: "refuge_idle")
        mermaid.base.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 1.3),
            .moveBy(x: 0, y: -3, duration: 1.3)
        ])), withKey: "refuge_idle")
    }

    private func beginRestPose() {
        guard let mermaid = displayMermaid else { return }
        mermaid.setAnimationMode(.idle)
        mermaid.applyExpression(.tired, animated: true)
        mermaid.base.removeAction(forKey: "refuge_idle")
        mermaid.base.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 2.5, duration: 1.4),
            .run { [weak self] in self?.emitMermaidBubbles(count: 1) },
            .moveBy(x: 0, y: -2.5, duration: 1.4)
        ])), withKey: "refuge_idle")
    }

    // MARK: - Personagens e props

    private func buildMermaid() {
        let mermaid = Mermaid()
        if ctx.stats.phase != .egg {
            mermaid.setForm(for: ctx.stats.phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.idle)
        let targetHeight = min(playableRect.height * 0.34,
                               overlaySize.height * 0.22,
                               playableRect.width * 0.34)
        mermaidBaseScale = ChallengeChrome.fitScale(for: mermaid.base, targetHeight: targetHeight)
        mermaid.base.setScale(mermaidBaseScale)
        mermaid.base.position = plazaPoint
        mermaid.base.zPosition = 4
        mermaid.setVisualDirection(.right)
        charactersLayer.addChild(mermaid.base)
        displayMermaid = mermaid
        updateExteriorCamera(focusing: mermaid.base.position.x)
        settleMermaidIdle()
    }

    private func buildNpc(at point: CGPoint,
                          hitName: String,
                          tint: UIColor,
                          kind: NpcKind,
                          stage: SKNode) {
        let npc = SKNode()
        npc.name = hitName
        npc.position = point
        npc.zPosition = 5
        stage.addChild(npc)

        let body = SKShapeNode(ellipseOf: kind == .itemShop
                               ? CGSize(width: 42, height: 54)
                               : CGSize(width: 38, height: 58))
        body.name = hitName
        body.fillColor = tint.withAlphaComponent(0.58)
        body.strokeColor = UIColor.white.withAlphaComponent(0.18)
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: 12)
        npc.addChild(body)

        let head = SKShapeNode(circleOfRadius: kind == .itemShop ? 18 : 16)
        head.name = hitName
        head.fillColor = UIColor.lerp(tint, art.shellPearl, 0.26).withAlphaComponent(0.78)
        head.strokeColor = UIColor.white.withAlphaComponent(0.22)
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 44)
        npc.addChild(head)

        for i in 0..<5 {
            let appendage = UIBezierPath()
            appendage.move(to: CGPoint(x: CGFloat(i - 2) * 7, y: -10))
            appendage.addCurve(to: CGPoint(x: CGFloat(i - 2) * 12, y: -34),
                               controlPoint1: CGPoint(x: CGFloat(i - 2) * 4, y: -18),
                               controlPoint2: CGPoint(x: CGFloat(i - 2) * 15, y: -26))
            let tentacle = SKShapeNode(path: appendage.cgPath)
            tentacle.name = hitName
            tentacle.strokeColor = tint.withAlphaComponent(0.58)
            tentacle.lineWidth = 3.2
            tentacle.lineCap = .round
            npc.addChild(tentacle)
        }

        if kind == .upgradeWorkshop {
            let goggles = SKShapeNode(rectOf: CGSize(width: 26, height: 10), cornerRadius: 5)
            goggles.name = hitName
            goggles.fillColor = art.shadow.withAlphaComponent(0.28)
            goggles.strokeColor = art.biolume.withAlphaComponent(0.48)
            goggles.lineWidth = 1
            goggles.position = CGPoint(x: 0, y: 45)
            npc.addChild(goggles)
        } else {
            let satchel = SKShapeNode(rectOf: CGSize(width: 25, height: 18), cornerRadius: 5)
            satchel.name = hitName
            satchel.fillColor = GameUI.gold.withAlphaComponent(0.40)
            satchel.strokeColor = GameUI.coral.withAlphaComponent(0.32)
            satchel.lineWidth = 1
            satchel.position = CGPoint(x: 19, y: 11)
            npc.addChild(satchel)
        }

        npc.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 4, duration: 1.4),
            .moveBy(x: 0, y: -4, duration: 1.4)
        ])))
        npc.run(.repeatForever(.sequence([
            .wait(forDuration: Double.random(in: 2.1...3.2)),
            .run { [weak self, weak npc] in
                guard let npc else { return }
                self?.emitNpcBubble(from: npc, tint: tint)
            },
            .wait(forDuration: Double.random(in: 2.1...3.2))
        ])))
    }

    private func buildExteriorLife(stage: SKNode) {
        for index in 0..<6 {
            let fish = FishDrawingFactory.fishDrawing(length: CGFloat.random(in: 14...24),
                                                      height: CGFloat.random(in: 5...10),
                                                      color: UIColor.white.withAlphaComponent(0.34),
                                                      animateTail: true,
                                                      silhouette: [.oval, .needle, .diamond].randomElement() ?? .oval,
                                                      pattern: .plain,
                                                      patternSeed: "refuge-village-fish-\(index)")
            fish.position = CGPoint(x: CGFloat.random(in: worldMinX + 20...worldMaxX - 20),
                                    y: CGFloat.random(in: playableRect.minY + 90...playableRect.maxY - 40))
            fish.zPosition = 1.5
            fish.alpha = CGFloat.random(in: 0.26...0.46)
            fish.setScale(CGFloat.random(in: 0.52...0.84))
            stage.addChild(fish)
            fish.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: 22...50), y: CGFloat.random(in: -7...9), duration: Double.random(in: 6...10)),
                .moveBy(x: CGFloat.random(in: -50 ... -22), y: CGFloat.random(in: -9...7), duration: Double.random(in: 6...10))
            ])))
        }
    }

    private func addWorldStamp(kind: WorldStampKind,
                               variant: Int,
                               position: CGPoint,
                               size: CGSize,
                               z: CGFloat,
                               alpha: CGFloat,
                               stage: SKNode) {
        let sprite = SKSpriteNode(texture: WorldStampRenderer.makeTexture(kind: kind,
                                                                          zone: .shallow,
                                                                          biome: art.stageBiome,
                                                                          variant: variant))
        sprite.size = size
        sprite.position = position
        sprite.zPosition = z
        sprite.alpha = alpha
        stage.addChild(sprite)
    }

    private func emitNpcBubble(from npc: SKNode, tint: UIColor) {
        let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.4...4.6))
        bubble.fillColor = UIColor.white.withAlphaComponent(0.18)
        bubble.strokeColor = tint.withAlphaComponent(0.36)
        bubble.lineWidth = 0.8
        bubble.position = CGPoint(x: CGFloat.random(in: -14...14), y: 58)
        bubble.zPosition = 8
        npc.addChild(bubble)
        bubble.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -8...8), y: 28, duration: 1.3),
                .fadeOut(withDuration: 1.3),
                .scale(to: 1.35, duration: 1.3)
            ]),
            .removeFromParent()
        ]))
    }

    private func emitMermaidBubbles(count: Int) {
        guard let base = displayMermaid?.base else { return }
        let basePosition = base.parent?.convert(base.position, to: effectsLayer) ?? base.position
        for index in 0..<count {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.18)
            bubble.strokeColor = GameUI.accent.withAlphaComponent(0.34)
            bubble.lineWidth = 1
            bubble.position = basePosition + CGPoint(x: CGFloat.random(in: -16...16),
                                                     y: CGFloat.random(in: 20...42))
            effectsLayer.addChild(bubble)
            bubble.run(.sequence([
                .wait(forDuration: Double(index) * 0.08),
                .group([
                    .moveBy(x: CGFloat.random(in: -12...12), y: CGFloat.random(in: 34...54), duration: 1.4),
                    .fadeOut(withDuration: 1.4),
                    .scale(to: 1.45, duration: 1.4)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func matchesHit(_ name: String, at point: CGPoint) -> Bool {
        var current: SKNode? = node.atPoint(point)
        while let candidate = current {
            if candidate.name == name { return true }
            current = candidate.parent
        }
        return false
    }

    private func exteriorWorldPoint(from screenPoint: CGPoint) -> CGPoint {
        CGPoint(x: screenPoint.x - exteriorWorldLayer.position.x,
                y: screenPoint.y)
    }

    private func updateExteriorCamera(focusing focusX: CGFloat) {
        let minOffset = min(0, playableRect.maxX - worldMaxX)
        let maxOffset = playableRect.minX - worldMinX
        let offset = (playableRect.midX - focusX).clamped(to: minOffset...maxOffset)
        exteriorWorldLayer.position = CGPoint(x: offset, y: 0)
        charactersLayer.position = CGPoint(x: offset, y: 0)
    }

    private func clampedToVillageWorld(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x.clamped(to: worldMinX + 42...worldMaxX - 42),
                y: lowerLaneY)
    }

    private func clampedToPlayable(_ point: CGPoint, inset: CGFloat) -> CGPoint {
        let minX = playableRect.minX + inset
        let maxX = playableRect.maxX - inset
        let minY = playableRect.minY + inset
        let maxY = playableRect.maxY - inset
        return CGPoint(x: point.x.clamped(to: minX...maxX),
                       y: point.y.clamped(to: minY...maxY))
    }
}

final class RefugeOverlay: SKNode {
    unowned let ctx: GameContext
    private let onClose: () -> Void
    private let overlaySize: CGSize
    private let art = RefugeArtDirection.pearlGrotto
    private let uiLayer = SKNode()
    private var villageController: RefugeVillageController?

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var careLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var memoryLabel: SKLabelNode!
    private var behaviorLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var enhancementsOverlay: RefugeEnhancementsOverlay?
    private var storeOverlay: RefugeStoreOverlay?
    private let safeAreaInsets: UIEdgeInsets

    init(size: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         onClose: @escaping () -> Void) {
        self.ctx = ctx
        self.onClose = onClose
        self.overlaySize = size
        self.safeAreaInsets = insets
        super.init()
        isUserInteractionEnabled = true
        build(size: size, insets: insets)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Construção

    private func build(size: CGSize, insets: UIEdgeInsets) {
        let topEdge = size.height / 2 - insets.top
        let bottomEdge = -size.height / 2 + insets.bottom
        let sideInset: CGFloat = 22
        let contentWidth = size.width - sideInset * 2

        let backdropSize = CGSize(width: size.width * 2, height: size.height * 2)
        let backdrop = SKShapeNode(rectOf: backdropSize)
        backdrop.fillTexture = GameUI.gradientTexture(size: backdropSize,
                                                      colors: [art.waterTop, art.waterMid, art.waterBottom])
        backdrop.fillColor = .white
        backdrop.strokeColor = .clear
        addChild(backdrop)

        uiLayer.zPosition = 30
        addChild(uiLayer)

        buildWaterBands(size: size)
        buildAmbientBubbles(size: size)

        let recordHeight = min(206, max(176, size.height * 0.25))
        let recordCenterY = bottomEdge + 94 + recordHeight / 2
        let environmentBottom = recordCenterY + recordHeight / 2 + 20
        let environmentTop = topEdge - 18
        let environmentHeight = max(220, environmentTop - environmentBottom)
        let villageRect = CGRect(x: -contentWidth / 2,
                                 y: environmentBottom,
                                 width: contentWidth,
                                 height: environmentHeight)

        let controller = RefugeVillageController(overlaySize: size,
                                                 playableRect: villageRect,
                                                 art: art,
                                                 ctx: ctx,
                                                 onOpenStore: { [weak self] in
                                                     self?.openStore()
                                                     self?.refreshLabels()
                                                 },
                                                 onOpenEnhancements: { [weak self] in
                                                     self?.openEnhancements()
                                                     self?.refreshLabels()
                                                 },
                                                 onNeedsRefresh: { [weak self] in
                                                     self?.refreshLabels()
                                                 })
        controller.node.zPosition = 2
        addChild(controller.node)
        villageController = controller

        buildObservationRecord(width: contentWidth,
                               height: recordHeight,
                               centerY: recordCenterY)

        let closeButton = makeActionButton(name: "refuge_close",
                                           text: "Voltar",
                                           width: min(220, contentWidth * 0.58),
                                           height: 44,
                                           tint: GameUI.accent)
        closeButton.position = CGPoint(x: 0, y: bottomEdge + 38)
        closeButton.zPosition = 8
        uiLayer.addChild(closeButton)

        refreshLabels()
    }

    private func buildWaterBands(size: CGSize) {
        for index in 0..<4 {
            let ray = SKShapeNode(rectOf: CGSize(width: size.width * CGFloat.random(in: 0.10...0.18),
                                                 height: size.height * 1.25))
            ray.fillColor = UIColor.white.withAlphaComponent(index.isMultiple(of: 2) ? 0.035 : 0.022)
            ray.strokeColor = .clear
            ray.zPosition = 0.1
            ray.position = CGPoint(x: -size.width * 0.35 + CGFloat(index) * size.width * 0.25,
                                   y: size.height * 0.05)
            ray.zRotation = CGFloat.random(in: -0.28...0.24)
            addChild(ray)
        }

        for index in 0..<7 {
            let path = UIBezierPath()
            let y = -size.height / 2 + CGFloat(index + 1) * size.height / 8
            path.move(to: CGPoint(x: -size.width / 2 - 40, y: y))
            path.addCurve(to: CGPoint(x: size.width / 2 + 40, y: y + CGFloat(index % 2 == 0 ? 14 : -12)),
                          controlPoint1: CGPoint(x: -size.width * 0.18, y: y + 24),
                          controlPoint2: CGPoint(x: size.width * 0.24, y: y - 22))
            let wave = SKShapeNode(path: path.cgPath)
            wave.strokeColor = UIColor.white.withAlphaComponent(index < 3 ? 0.060 : 0.032)
            wave.lineWidth = CGFloat(index < 3 ? 10 : 16)
            wave.lineCap = .round
            wave.zPosition = 0.2
            addChild(wave)
        }

        for index in 0..<11 {
            let fish = FishDrawingFactory.fishDrawing(length: CGFloat.random(in: 14...26),
                                                      height: CGFloat.random(in: 5...10),
                                                      color: UIColor.white.withAlphaComponent(0.34),
                                                      animateTail: true,
                                                      silhouette: [.oval, .needle, .diamond].randomElement() ?? .oval,
                                                      pattern: .plain,
                                                      patternSeed: "refuge-bg-\(index)")
            fish.position = CGPoint(x: CGFloat.random(in: -size.width * 0.48...size.width * 0.48),
                                    y: CGFloat.random(in: -size.height * 0.10...size.height * 0.39))
            fish.zPosition = 0.35
            fish.alpha = CGFloat.random(in: 0.28...0.50)
            fish.setScale(CGFloat.random(in: 0.55...0.90))
            addChild(fish)
            fish.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: 26...64), y: CGFloat.random(in: -5...8), duration: Double.random(in: 7...13)),
                .moveBy(x: CGFloat.random(in: -64 ... -26), y: CGFloat.random(in: -8...5), duration: Double.random(in: 7...13))
            ])))
        }
    }

    private func buildAmbientBubbles(size: CGSize) {
        for i in 0..<6 {
            let bubble = SKShapeNode(circleOfRadius: .random(in: 4...10))
            bubble.fillColor = GameUI.accent.withAlphaComponent(0.08)
            bubble.strokeColor = GameUI.accent.withAlphaComponent(0.24)
            bubble.lineWidth = 1
            bubble.position = CGPoint(x: .random(in: -size.width / 2...size.width / 2),
                                      y: .random(in: -size.height / 2...0))
            bubble.zPosition = 0.5
            addChild(bubble)
            let rise = SKAction.repeatForever(.sequence([
                .moveBy(x: .random(in: -20...20), y: size.height, duration: Double.random(in: 9...14)),
                .run { bubble.position.y = -size.height / 2 }
            ]))
            bubble.run(.sequence([.wait(forDuration: Double(i)), rise]))
        }
    }

    private func buildObservationRecord(width: CGFloat, height: CGFloat, centerY: CGFloat) {
        let card = GameUI.card(size: CGSize(width: width, height: height),
                               cornerRadius: 10,
                               tint: GameUI.accent.withAlphaComponent(0.72))
        card.position = CGPoint(x: 0, y: centerY)
        card.zPosition = 6
        uiLayer.addChild(card)

        let clip = SKShapeNode(rectOf: CGSize(width: 74, height: 18), cornerRadius: 5)
        clip.fillColor = GameUI.gold.withAlphaComponent(0.36)
        clip.strokeColor = GameUI.gold.withAlphaComponent(0.72)
        clip.position = CGPoint(x: 0, y: height / 2 + 2)
        clip.zPosition = 8
        card.addChild(clip)

        let clamp = SKShapeNode(rectOf: CGSize(width: 42, height: 7), cornerRadius: 3)
        clamp.fillColor = art.reefRock.withAlphaComponent(0.48)
        clamp.strokeColor = .clear
        clamp.position = CGPoint(x: 0, y: height / 2 - 6)
        clamp.zPosition = 9
        card.addChild(clamp)

        for y in [height / 2 - 38, height / 2 - 82, height / 2 - 126] {
            let hole = SKShapeNode(ellipseOf: CGSize(width: 8, height: 12))
            hole.fillColor = art.shadow.withAlphaComponent(0.18)
            hole.strokeColor = UIColor.white.withAlphaComponent(0.18)
            hole.lineWidth = 0.6
            hole.position = CGPoint(x: -width / 2 + 18, y: y)
            hole.zPosition = 7
            card.addChild(hole)
        }

        let pencil = SKShapeNode(rectOf: CGSize(width: 78, height: 6), cornerRadius: 3)
        pencil.fillColor = GameUI.gold.withAlphaComponent(0.70)
        pencil.strokeColor = GameUI.coral.withAlphaComponent(0.40)
        pencil.lineWidth = 0.8
        pencil.position = CGPoint(x: width / 2 - 58, y: height / 2 - 20)
        pencil.zRotation = -0.18
        pencil.zPosition = 7
        card.addChild(pencil)

        let recordTitle = makeLabel(fontSize: 12.5, bold: true)
        recordTitle.text = "Prancheta do biólogo"
        recordTitle.fontColor = GameUI.accent
        recordTitle.position = CGPoint(x: 0, y: height / 2 - 24)
        card.addChild(recordTitle)

        statusLabel = makeLabel(fontSize: 13, bold: true)
        statusLabel.position = CGPoint(x: 0, y: height / 2 - 50)
        statusLabel.preferredMaxLayoutWidth = width - 34
        statusLabel.numberOfLines = 1
        card.addChild(statusLabel)

        foodLabel = makeLabel(fontSize: 13)
        foodLabel.position = CGPoint(x: 0, y: height / 2 - 75)
        foodLabel.preferredMaxLayoutWidth = width - 34
        foodLabel.numberOfLines = 1
        card.addChild(foodLabel)

        careLabel = makeLabel(fontSize: 13)
        careLabel.position = CGPoint(x: 0, y: height / 2 - 98)
        careLabel.preferredMaxLayoutWidth = width - 34
        careLabel.numberOfLines = 1
        card.addChild(careLabel)

        pearlsLabel = makeLabel(fontSize: 13)
        pearlsLabel.position = CGPoint(x: 0, y: height / 2 - 121)
        pearlsLabel.preferredMaxLayoutWidth = width - 34
        pearlsLabel.numberOfLines = 1
        card.addChild(pearlsLabel)

        let memoriesTitle = makeLabel(fontSize: 12, bold: true)
        memoriesTitle.text = "Memórias recentes"
        memoriesTitle.fontColor = GameUI.accent
        memoriesTitle.position = CGPoint(x: 0, y: -height / 2 + 53)
        card.addChild(memoriesTitle)

        memoryLabel = makeLabel(fontSize: 11)
        memoryLabel.fontColor = GameUI.mutedInk
        memoryLabel.preferredMaxLayoutWidth = width - 34
        memoryLabel.numberOfLines = 2
        memoryLabel.lineBreakMode = .byWordWrapping
        memoryLabel.position = CGPoint(x: 0, y: -height / 2 + 27)
        card.addChild(memoryLabel)

        behaviorLabel = makeLabel(fontSize: 10.5, bold: true)
        behaviorLabel.fontColor = GameUI.algae
        behaviorLabel.position = CGPoint(x: 0, y: -height / 2 + 8)
        behaviorLabel.preferredMaxLayoutWidth = width - 34
        behaviorLabel.numberOfLines = 1
        card.addChild(behaviorLabel)
    }

    private func makeLabel(fontSize: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = GameUI.ink
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }

    private func makeActionButton(name: String,
                                  text: String,
                                  width: CGFloat,
                                  height: CGFloat,
                                  tint: UIColor) -> SKNode {
        let button = SKNode()
        button.name = name
        let bg = GameUI.card(size: CGSize(width: width, height: height),
                             cornerRadius: 9,
                             tint: tint)
        bg.name = name
        button.addChild(bg)

        let label = makeLabel(fontSize: 12.5, bold: true)
        label.text = text
        label.name = name
        label.verticalAlignmentMode = .center
        label.preferredMaxLayoutWidth = width - 12
        label.numberOfLines = 1
        label.zPosition = 3
        button.addChild(label)
        return button
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        refreshTimer -= dt
        if refreshTimer <= 0 {
            refreshTimer = 0.5
            refreshLabels()
        }

        guard enhancementsOverlay == nil, storeOverlay == nil else { return }
        villageController?.update(dt: dt)
    }

    private func refreshLabels() {
        let stats = ctx.stats!
        statusLabel.text = "\(stats.phase.displayName) · \(stats.ageText) · repouso observado"
        foodLabel.text = ctx.growth.evolutionNote()
        careLabel.text = "Energia \(Int(stats.energy))% · Alimentação \(Int(100 - stats.hunger))%"
        pearlsLabel.text = "Conchas \(GameUI.shellAmountText(stats.pearls))"
        let memories = ctx.stats.memories.suffix(2)
        memoryLabel.text = memories.isEmpty
            ? "Nenhuma memória registrada. Explore o oceano."
            : memories.joined(separator: "  ·  ")
        behaviorLabel.text = "Observação: \(villageController?.behaviorText ?? "explorando o refúgio")"
    }

    private func openEnhancements() {
        enhancementsOverlay?.removeFromParent()
        storeOverlay?.removeFromParent()
        storeOverlay = nil
        let overlay = RefugeEnhancementsOverlay(size: overlaySize,
                                                insets: safeAreaInsets,
                                                stats: ctx.stats)
        overlay.zPosition = 50
        addChild(overlay)
        enhancementsOverlay = overlay
    }

    private func openStore() {
        storeOverlay?.removeFromParent()
        enhancementsOverlay?.removeFromParent()
        enhancementsOverlay = nil
        let overlay = RefugeStoreOverlay(size: overlaySize,
                                         insets: safeAreaInsets,
                                         stats: ctx.stats)
        overlay.zPosition = 50
        addChild(overlay)
        storeOverlay = overlay
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if enhancementsOverlay == nil,
           storeOverlay == nil,
           villageController?.handleTouch(at: location) == true {
            refreshLabels()
            return
        }

        var node: SKNode? = atPoint(location)
        while let current = node {
            switch current.name {
            case "enhancements_close":
                GameAudio.shared.play(.uiClosePanel)
                enhancementsOverlay?.removeFromParent()
                enhancementsOverlay = nil
                refreshLabels()
                return
            case "store_close":
                GameAudio.shared.play(.uiClosePanel)
                storeOverlay?.removeFromParent()
                storeOverlay = nil
                refreshLabels()
                return
            case let name? where name.hasPrefix("store_item_"):
                let itemId = String(name.dropFirst("store_item_".count))
                guard let item = RefugeShopCatalog.item(withId: itemId) else { return }
                if ctx.supportResources.purchase(item) {
                    storeOverlay?.removeFromParent()
                    storeOverlay = nil
                    openStore()
                } else {
                    GameAudio.shared.play(.uiUpgradeFail)
                }
                refreshLabels()
                return
            case let name? where name.hasPrefix("upgrade_"):
                guard let raw = name.split(separator: "_").last,
                      let kind = MermaidStats.UpgradeKind(rawValue: String(raw)) else { return }
                if let cost = ctx.stats.upgradeCost(for: kind) {
                    guard ctx.stats.pearls >= cost else {
                        GameAudio.shared.play(.uiUpgradeFail)
                        ctx.say("\(kind.title) custa \(GameUI.shellAmountText(cost)) conchas. Faltam \(GameUI.shellAmountText(cost - ctx.stats.pearls)) conchas.")
                        return
                    }
                    if ctx.stats.buyUpgrade(kind) {
                        GameAudio.shared.play(.uiUpgradeBuy)
                        ctx.say("\(kind.title) melhorado para o nível \(ctx.stats.upgradeLevel(for: kind)).")
                        enhancementsOverlay?.removeFromParent()
                        enhancementsOverlay = nil
                        openEnhancements()
                        refreshLabels()
                    }
                } else {
                    GameAudio.shared.play(.uiUpgradeFail)
                    ctx.say("\(kind.title) já chegou ao nível máximo.")
                }
                return
            case "refuge_close":
                if villageController?.requestReturnToVillage() == true {
                    GameAudio.shared.play(.uiConfirm)
                    refreshLabels()
                    return
                }
                GameAudio.shared.play(.uiClosePanel)
                onClose()
                return
            default:
                node = current.parent
            }
        }
    }
}

final class RefugeEnhancementsOverlay: SKNode {
    private let stats: MermaidStats
    private let insets: UIEdgeInsets

    init(size: CGSize, insets: UIEdgeInsets, stats: MermaidStats) {
        self.stats = stats
        self.insets = insets
        super.init()
        isUserInteractionEnabled = false
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size: CGSize) {
        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillColor = GameUI.palePaper
        backdrop.strokeColor = GameUI.accent.withAlphaComponent(0.2)
        backdrop.zPosition = 0
        addChild(backdrop)

        let top = size.height / 2 - insets.top
        let title = makeLabel(text: "Aprimoramentos", fontSize: 21, bold: true, color: GameUI.ink)
        title.position = CGPoint(x: 0, y: top - 42)
        title.zPosition = 2
        addChild(title)

        let subtitle = makeLabel(text: "aprimoramentos comprados com conchas", fontSize: 12, color: GameUI.mutedInk)
        subtitle.position = CGPoint(x: 0, y: top - 66)
        subtitle.zPosition = 2
        addChild(subtitle)

        let pearlLine = makeLabel(text: "Conchas \(GameUI.shellAmountText(stats.pearls))", fontSize: 13, bold: true, color: GameUI.gold)
        pearlLine.position = CGPoint(x: 0, y: top - 92)
        pearlLine.zPosition = 2
        addChild(pearlLine)

        let rowWidth = min(size.width - 28, 420)
        let rowCount = MermaidStats.UpgradeKind.allCases.count
        let availableHeight = max(390, size.height - insets.top - insets.bottom - 228)
        let rowHeight = min(90, max(74, availableHeight / CGFloat(rowCount)))
        let firstY = top - 148

        for (index, kind) in MermaidStats.UpgradeKind.allCases.enumerated() {
            addRow(kind: kind,
                   width: rowWidth,
                   height: rowHeight - 8,
                   centerY: firstY - CGFloat(index) * rowHeight)
        }

        let closeButton = SKNode()
        closeButton.name = "enhancements_close"
        closeButton.position = CGPoint(x: 0, y: -size.height / 2 + insets.bottom + 48)
        closeButton.zPosition = 4
        let closeCard = GameUI.card(size: CGSize(width: min(220, size.width - 80), height: 44),
                                    cornerRadius: 9,
                                    tint: GameUI.accent)
        closeCard.name = "enhancements_close"
        closeButton.addChild(closeCard)
        let closeLabel = makeLabel(text: "Voltar ao refúgio", fontSize: 13, bold: true, color: GameUI.ink)
        closeLabel.name = "enhancements_close"
        closeLabel.verticalAlignmentMode = .center
        closeLabel.zPosition = 5
        closeButton.addChild(closeLabel)
        addChild(closeButton)
    }

    private func addRow(kind: MermaidStats.UpgradeKind,
                        width: CGFloat,
                        height: CGFloat,
                        centerY: CGFloat) {
        let level = stats.upgradeLevel(for: kind)
        let row = SKNode()
        row.position = CGPoint(x: 0, y: centerY)
        row.zPosition = 2
        addChild(row)

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 10)
        bg.fillColor = UIColor.white.withAlphaComponent(0.36)
        bg.strokeColor = GameUI.accent.withAlphaComponent(0.22)
        bg.lineWidth = 1
        row.addChild(bg)

        let title = makeLabel(text: "\(kind.title)  \(level)/100", fontSize: 13, bold: true, color: GameUI.ink)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: -width / 2 + 14, y: height / 2 - 22)
        row.addChild(title)

        let description = makeLabel(text: kind.description, fontSize: 10.5, color: GameUI.mutedInk)
        description.horizontalAlignmentMode = .left
        description.preferredMaxLayoutWidth = width - 126
        description.numberOfLines = 2
        description.lineBreakMode = .byWordWrapping
        description.position = CGPoint(x: -width / 2 + 14, y: -4)
        row.addChild(description)

        let actionName = "upgrade_\(kind.rawValue)"
        let button = SKNode()
        button.name = actionName
        button.position = CGPoint(x: width / 2 - 56, y: -4)
        button.zPosition = 4
        row.addChild(button)

        let buttonColor: UIColor = stats.upgradeCost(for: kind) == nil ? GameUI.mutedInk : GameUI.gold
        let buttonBg = GameUI.card(size: CGSize(width: 92, height: 48),
                                   cornerRadius: 8,
                                   tint: buttonColor)
        buttonBg.name = actionName
        button.addChild(buttonBg)

        let buttonText: String
        if let cost = stats.upgradeCost(for: kind) {
            buttonText = "comprar\n\(GameUI.shellAmountText(cost)) conchas"
        } else {
            buttonText = "nível\nmáximo"
        }
        let label = makeLabel(text: buttonText, fontSize: 10.5, bold: true, color: GameUI.ink)
        label.name = actionName
        label.numberOfLines = 2
        label.verticalAlignmentMode = .center
        label.zPosition = 5
        button.addChild(label)
    }

    private func makeLabel(text: String,
                           fontSize: CGFloat,
                           bold: Bool = false,
                           color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "AvenirNext-DemiBold" : "AvenirNext-Regular"
        label.fontSize = fontSize
        label.fontColor = color
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }
}
