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

final class RefugeOverlay: SKNode {
    unowned let ctx: GameContext
    private let onClose: () -> Void
    private let overlaySize: CGSize

    private var statusLabel: SKLabelNode!
    private var foodLabel: SKLabelNode!
    private var careLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var memoryLabel: SKLabelNode!
    private var behaviorLabel: SKLabelNode!
    private var refreshTimer: CGFloat = 0
    private var behaviorTimer: CGFloat = 1.1
    private var restingBoostTimer: CGFloat = 0
    private var displayMermaid: Mermaid?
    private var enhancementsOverlay: RefugeEnhancementsOverlay?
    private var storeOverlay: RefugeStoreOverlay?
    private let safeAreaInsets: UIEdgeInsets
    private var restPoint: CGPoint = .zero
    private var upgradePoint: CGPoint = .zero
    private var storePoint: CGPoint = .zero
    private var memoryPoint: CGPoint = .zero
    private var driftPoints: [CGPoint] = []
    private var currentBehavior: RefugeBehavior = .drifting
    private var mermaidBaseScale: CGFloat = 1
    private var memoryDisplayNodes: [SKNode] = []
    private var memoryShelfNode: SKNode?
    private var renderedMemoryKey = ""
    private let mermaidBubbleLayer = SKNode()

    private enum RefugeBehavior: CaseIterable {
        case drifting
        case resting
        case observingMemories
        case visitingUpgrade
        case visitingStore

        var label: String {
            switch self {
            case .drifting: return "nado lento pelo refúgio"
            case .resting: return "descansando na cama de algas"
            case .observingMemories: return "observando lembranças"
            case .visitingUpgrade: return "conversando com o inventor"
            case .visitingStore: return "visitando a lojista"
            }
        }
    }

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

        let backdrop = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        backdrop.fillTexture = GameUI.paperTexture(size: CGSize(width: size.width * 2, height: size.height * 2),
                                                   base: GameUI.palePaper)
        backdrop.fillColor = .white
        backdrop.strokeColor = .clear
        addChild(backdrop)

        buildWaterBands(size: size)
        buildAmbientBubbles(size: size)

        let title = makeLabel(fontSize: 21, bold: true)
        title.text = "Registro do Refúgio"
        title.position = CGPoint(x: 0, y: topEdge - 42)
        addChild(title)

        let subtitle = makeLabel(fontSize: 12)
        subtitle.text = "dimensão de descanso, cuidado e observação"
        subtitle.fontColor = GameUI.mutedInk
        subtitle.position = CGPoint(x: 0, y: topEdge - 64)
        addChild(subtitle)

        let closeButton = makeActionButton(name: "refuge_close",
                                           text: "Voltar",
                                           width: min(220, contentWidth * 0.58),
                                           height: 44,
                                           tint: GameUI.accent)
        closeButton.position = CGPoint(x: 0, y: bottomEdge + 38)
        closeButton.zPosition = 8
        addChild(closeButton)

        let recordHeight = min(206, max(176, size.height * 0.25))
        let recordCenterY = bottomEdge + 94 + recordHeight / 2
        let environmentBottom = recordCenterY + recordHeight / 2 + 20
        let environmentTop = topEdge - 92
        let environmentHeight = max(220, environmentTop - environmentBottom)
        let environmentCenterY = (environmentTop + environmentBottom) / 2

        buildRefugeEnvironment(size: size,
                               width: contentWidth,
                               top: environmentTop,
                               bottom: environmentBottom,
                               centerY: environmentCenterY,
                               height: environmentHeight)
        buildObservationRecord(width: contentWidth,
                               height: recordHeight,
                               centerY: recordCenterY)
        buildMermaid(in: CGSize(width: contentWidth, height: environmentHeight),
                     centerY: environmentCenterY)

        refreshLabels()
        chooseNextBehavior(force: .drifting)
    }

    private func buildWaterBands(size: CGSize) {
        let colors = [
            GameUI.accent.withAlphaComponent(0.10),
            GameUI.algae.withAlphaComponent(0.08),
            GameUI.coral.withAlphaComponent(0.055)
        ]
        for index in 0..<5 {
            let path = UIBezierPath()
            let y = -size.height / 2 + CGFloat(index + 1) * size.height / 6
            path.move(to: CGPoint(x: -size.width / 2 - 40, y: y))
            path.addCurve(to: CGPoint(x: size.width / 2 + 40, y: y + CGFloat(index % 2 == 0 ? 18 : -16)),
                          controlPoint1: CGPoint(x: -size.width * 0.18, y: y + 34),
                          controlPoint2: CGPoint(x: size.width * 0.24, y: y - 30))
            let wave = SKShapeNode(path: path.cgPath)
            wave.strokeColor = colors[index % colors.count]
            wave.lineWidth = 18
            wave.lineCap = .round
            wave.zPosition = 0.2
            addChild(wave)
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

    private func buildRefugeEnvironment(size: CGSize,
                                        width: CGFloat,
                                        top: CGFloat,
                                        bottom: CGFloat,
                                        centerY: CGFloat,
                                        height: CGFloat) {
        let stage = SKNode()
        stage.zPosition = 1
        addChild(stage)

        let tidePool = SKShapeNode(ellipseOf: CGSize(width: width * 0.94, height: height * 0.72))
        tidePool.fillColor = GameUI.accent.withAlphaComponent(0.08)
        tidePool.strokeColor = GameUI.accent.withAlphaComponent(0.20)
        tidePool.lineWidth = 1.2
        tidePool.position = CGPoint(x: 0, y: centerY - height * 0.04)
        stage.addChild(tidePool)

        let shelfPath = UIBezierPath()
        shelfPath.move(to: CGPoint(x: -width / 2 + 6, y: bottom + 26))
        shelfPath.addCurve(to: CGPoint(x: width / 2 - 6, y: bottom + 18),
                           controlPoint1: CGPoint(x: -width * 0.12, y: bottom + 2),
                           controlPoint2: CGPoint(x: width * 0.16, y: bottom + 52))
        shelfPath.addLine(to: CGPoint(x: width / 2 - 18, y: bottom - 8))
        shelfPath.addLine(to: CGPoint(x: -width / 2 + 18, y: bottom - 8))
        shelfPath.close()
        let shelf = SKShapeNode(path: shelfPath.cgPath)
        shelf.fillColor = GameUI.algae.withAlphaComponent(0.18)
        shelf.strokeColor = GameUI.algae.withAlphaComponent(0.38)
        shelf.lineWidth = 1.2
        stage.addChild(shelf)

        restPoint = CGPoint(x: -width * 0.28, y: bottom + 82)
        upgradePoint = CGPoint(x: width * 0.29, y: bottom + height * 0.34)
        storePoint = CGPoint(x: -width * 0.33, y: min(top - 78, bottom + height * 0.68))
        memoryPoint = CGPoint(x: width * 0.30, y: min(top - 76, bottom + height * 0.72))
        driftPoints = [
            CGPoint(x: -width * 0.08, y: centerY + height * 0.10),
            CGPoint(x: width * 0.10, y: centerY - height * 0.02),
            CGPoint(x: -width * 0.20, y: centerY - height * 0.14),
            CGPoint(x: width * 0.22, y: centerY + height * 0.08)
        ]

        buildRestArea(at: restPoint, stage: stage)
        buildMemoryShelf(at: memoryPoint, stage: stage)
        buildNpc(at: upgradePoint,
                 name: "refuge_enhancements",
                 title: "Inventor",
                 subtitle: "aprimorar",
                 tint: GameUI.gold,
                 kind: .upgrade,
                 stage: stage)
        buildNpc(at: storePoint,
                 name: "refuge_store",
                 title: "Lojista",
                 subtitle: "itens",
                 tint: GameUI.coral,
                 kind: .store,
                 stage: stage)
    }

    private func buildMermaid(in stageSize: CGSize, centerY: CGFloat) {
        let mermaid = Mermaid()
        if ctx.stats.phase != .egg {
            mermaid.setForm(for: ctx.stats.phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.idle)
        let targetMermaidHeight = min(stageSize.height * 0.36,
                                      overlaySize.height * 0.23,
                                      stageSize.width * 0.44)
        let scale = ChallengeChrome.fitScale(for: mermaid.base,
                                             targetHeight: targetMermaidHeight)
        mermaidBaseScale = scale
        mermaid.base.setScale(scale)
        mermaid.base.alpha = 1
        let mermaidFrame = mermaid.base.calculateAccumulatedFrame()
        mermaid.base.position = CGPoint(x: 0, y: centerY - mermaidFrame.midY)
        mermaid.base.zPosition = 4
        addChild(mermaid.base)
        displayMermaid = mermaid
        mermaidBubbleLayer.zPosition = 3.8
        addChild(mermaidBubbleLayer)
    }

    private func buildObservationRecord(width: CGFloat, height: CGFloat, centerY: CGFloat) {
        let card = GameUI.card(size: CGSize(width: width, height: height),
                               cornerRadius: 10,
                               tint: GameUI.accent.withAlphaComponent(0.72))
        card.position = CGPoint(x: 0, y: centerY)
        card.zPosition = 6
        addChild(card)

        let clip = SKShapeNode(rectOf: CGSize(width: 74, height: 18), cornerRadius: 5)
        clip.fillColor = GameUI.gold.withAlphaComponent(0.36)
        clip.strokeColor = GameUI.gold.withAlphaComponent(0.72)
        clip.position = CGPoint(x: 0, y: height / 2 + 2)
        clip.zPosition = 8
        card.addChild(clip)

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

    private enum RefugeNpcKind {
        case upgrade
        case store
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

    private func buildRestArea(at point: CGPoint, stage: SKNode) {
        let node = SKNode()
        node.name = "refuge_rest"
        node.position = point
        node.zPosition = 2
        stage.addChild(node)

        let glow = SKShapeNode(ellipseOf: CGSize(width: 118, height: 54))
        glow.name = "refuge_rest"
        glow.fillColor = GameUI.algae.withAlphaComponent(0.10)
        glow.strokeColor = GameUI.algae.withAlphaComponent(0.34)
        glow.lineWidth = 1.4
        glow.glowWidth = 3
        node.addChild(glow)

        for i in 0..<7 {
            let blade = SKShapeNode(rectOf: CGSize(width: 7, height: CGFloat(28 + i * 3)), cornerRadius: 4)
            blade.name = "refuge_rest"
            blade.fillColor = UIColor.lerp(GameUI.algae, GameUI.accent, CGFloat(i) / 10).withAlphaComponent(0.72)
            blade.strokeColor = .clear
            blade.position = CGPoint(x: -42 + CGFloat(i) * 14, y: 8 + CGFloat(i % 2) * 4)
            blade.zRotation = CGFloat(i - 3) * 0.10
            node.addChild(blade)
        }

        let shell = SKShapeNode(ellipseOf: CGSize(width: 50, height: 22))
        shell.name = "refuge_rest"
        shell.fillColor = GameUI.coral.withAlphaComponent(0.18)
        shell.strokeColor = GameUI.coral.withAlphaComponent(0.42)
        shell.lineWidth = 1
        shell.position = CGPoint(x: 8, y: -1)
        node.addChild(shell)

        let tag = makeMiniTag(text: "descansar", tint: GameUI.algae, name: "refuge_rest")
        tag.position = CGPoint(x: 0, y: -38)
        node.addChild(tag)
    }

    private func buildMemoryShelf(at point: CGPoint, stage: SKNode) {
        let node = SKNode()
        node.position = point
        node.zPosition = 2
        stage.addChild(node)

        let shelf = SKShapeNode(rectOf: CGSize(width: 112, height: 18), cornerRadius: 8)
        shelf.fillColor = GameUI.gold.withAlphaComponent(0.14)
        shelf.strokeColor = GameUI.gold.withAlphaComponent(0.34)
        shelf.lineWidth = 1
        node.addChild(shelf)

        let label = makeLabel(fontSize: 10.5, bold: true)
        label.text = "lembranças"
        label.fontColor = GameUI.mutedInk
        label.position = CGPoint(x: 0, y: -24)
        node.addChild(label)

        memoryShelfNode = node
        refreshMemoryTokens()
    }

    private func makeMemoryToken(index: Int, memory: String?) -> SKNode {
        let node = SKNode()
        let colors = [GameUI.coral, GameUI.gold, GameUI.accent]
        let tint = colors[index % colors.count]
        let radius: CGFloat = memory == nil ? 9 : 12
        let gem = SKShapeNode(circleOfRadius: radius)
        gem.fillColor = tint.withAlphaComponent(memory == nil ? 0.14 : 0.42)
        gem.strokeColor = tint.withAlphaComponent(memory == nil ? 0.28 : 0.68)
        gem.lineWidth = 1
        node.addChild(gem)

        if let memory {
            let mark = makeLabel(fontSize: 7.5, bold: true)
            mark.text = shortMemoryMark(memory, index: index)
            mark.fontColor = GameUI.ink
            node.addChild(mark)
        }

        node.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 1.4 + Double(index) * 0.2),
            .moveBy(x: 0, y: -3, duration: 1.4 + Double(index) * 0.2)
        ])))
        return node
    }

    private func buildNpc(at point: CGPoint,
                          name: String,
                          title: String,
                          subtitle: String,
                          tint: UIColor,
                          kind: RefugeNpcKind,
                          stage: SKNode) {
        let npc = SKNode()
        npc.name = name
        npc.position = point
        npc.zPosition = 3
        stage.addChild(npc)

        let halo = SKShapeNode(circleOfRadius: 38)
        halo.name = name
        halo.fillColor = tint.withAlphaComponent(0.08)
        halo.strokeColor = tint.withAlphaComponent(0.28)
        halo.lineWidth = 1.2
        halo.glowWidth = 3
        npc.addChild(halo)
        halo.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.48, duration: 1.0),
            .fadeAlpha(to: 1.0, duration: 1.2)
        ])))

        switch kind {
        case .upgrade:
            buildSeahorseInventor(in: npc, name: name, tint: tint)
        case .store:
            buildCrabMerchant(in: npc, name: name, tint: tint)
        }

        let icon = GameUI.symbolIconNode(named: kind == .upgrade ? "sparkles" : "shippingbox.fill",
                                         fallback: kind == .upgrade ? "*" : "#",
                                         color: tint,
                                         size: 18)
        icon.name = name
        icon.position = CGPoint(x: 0, y: 50)
        icon.zPosition = 5
        npc.addChild(icon)

        let tag = makeMiniTag(text: subtitle, tint: tint, name: name)
        tag.position = CGPoint(x: 0, y: -50)
        npc.addChild(tag)

        let titleLabel = makeLabel(fontSize: 10, bold: true)
        titleLabel.text = title
        titleLabel.fontColor = GameUI.ink
        titleLabel.name = name
        titleLabel.position = CGPoint(x: 0, y: -70)
        npc.addChild(titleLabel)
    }

    private func buildSeahorseInventor(in npc: SKNode, name: String, tint: UIColor) {
        let body = SKShapeNode(ellipseOf: CGSize(width: 28, height: 52))
        body.name = name
        body.fillColor = tint.withAlphaComponent(0.38)
        body.strokeColor = tint.withAlphaComponent(0.78)
        body.lineWidth = 1.2
        body.position = CGPoint(x: 0, y: 2)
        npc.addChild(body)

        let head = SKShapeNode(ellipseOf: CGSize(width: 28, height: 22))
        head.name = name
        head.fillColor = tint.withAlphaComponent(0.44)
        head.strokeColor = tint.withAlphaComponent(0.78)
        head.position = CGPoint(x: -8, y: 31)
        npc.addChild(head)

        let snout = SKShapeNode(rectOf: CGSize(width: 22, height: 8), cornerRadius: 4)
        snout.name = name
        snout.fillColor = tint.withAlphaComponent(0.34)
        snout.strokeColor = .clear
        snout.position = CGPoint(x: -24, y: 31)
        npc.addChild(snout)

        let tail = SKShapeNode(circleOfRadius: 11)
        tail.name = name
        tail.fillColor = .clear
        tail.strokeColor = tint.withAlphaComponent(0.78)
        tail.lineWidth = 4
        tail.position = CGPoint(x: 8, y: -30)
        npc.addChild(tail)
    }

    private func buildCrabMerchant(in npc: SKNode, name: String, tint: UIColor) {
        let body = SKShapeNode(ellipseOf: CGSize(width: 54, height: 34))
        body.name = name
        body.fillColor = tint.withAlphaComponent(0.34)
        body.strokeColor = tint.withAlphaComponent(0.76)
        body.lineWidth = 1.2
        npc.addChild(body)

        for side in [-1, 1] {
            let claw = SKShapeNode(circleOfRadius: 10)
            claw.name = name
            claw.fillColor = tint.withAlphaComponent(0.32)
            claw.strokeColor = tint.withAlphaComponent(0.72)
            claw.lineWidth = 1
            claw.position = CGPoint(x: CGFloat(side) * 38, y: 9)
            npc.addChild(claw)

            let arm = SKShapeNode(rectOf: CGSize(width: 28, height: 5), cornerRadius: 3)
            arm.name = name
            arm.fillColor = tint.withAlphaComponent(0.30)
            arm.strokeColor = .clear
            arm.position = CGPoint(x: CGFloat(side) * 25, y: 2)
            arm.zRotation = CGFloat(side) * 0.28
            npc.addChild(arm)
        }

        let crate = SKShapeNode(rectOf: CGSize(width: 38, height: 18), cornerRadius: 4)
        crate.name = name
        crate.fillColor = GameUI.gold.withAlphaComponent(0.22)
        crate.strokeColor = GameUI.gold.withAlphaComponent(0.54)
        crate.lineWidth = 1
        crate.position = CGPoint(x: 0, y: -24)
        npc.addChild(crate)
    }

    private func makeMiniTag(text: String, tint: UIColor, name: String) -> SKNode {
        let tag = SKNode()
        tag.name = name
        let bg = SKShapeNode(rectOf: CGSize(width: 78, height: 22), cornerRadius: 8)
        bg.name = name
        bg.fillColor = GameUI.paper.withAlphaComponent(0.82)
        bg.strokeColor = tint.withAlphaComponent(0.58)
        bg.lineWidth = 1
        tag.addChild(bg)

        let label = makeLabel(fontSize: 9.5, bold: true)
        label.name = name
        label.text = text
        label.fontColor = GameUI.ink
        tag.addChild(label)
        return tag
    }

    // MARK: - Atualização

    func update(dt: CGFloat) {
        refreshTimer -= dt
        if refreshTimer <= 0 {
            refreshTimer = 0.5
            refreshLabels()
        }

        guard enhancementsOverlay == nil, storeOverlay == nil else { return }

        if currentBehavior == .resting {
            ctx.stats.energy = (ctx.stats.energy + dt * 1.4).clamped(to: 0...100)
        }

        restingBoostTimer = max(0, restingBoostTimer - dt)
        behaviorTimer -= dt
        if behaviorTimer <= 0 {
            if restingBoostTimer > 0 {
                chooseNextBehavior(force: .resting)
            } else {
                chooseNextBehavior(force: nil)
            }
        }
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
        behaviorLabel.text = "Observação: \(currentBehavior.label)"
        refreshMemoryTokens()
    }

    private func refreshMemoryTokens() {
        let memories = Array(ctx.stats.memories.suffix(3))
        let key = memories.joined(separator: "|")
        guard key != renderedMemoryKey || memoryDisplayNodes.isEmpty else { return }
        renderedMemoryKey = key

        memoryDisplayNodes.forEach { $0.removeFromParent() }
        memoryDisplayNodes.removeAll()

        let displayCount = memories.isEmpty ? 3 : memories.count
        for i in 0..<displayCount {
            let item = makeMemoryToken(index: i, memory: memories.indices.contains(i) ? memories[i] : nil)
            item.position = CGPoint(x: -34 + CGFloat(i) * 34, y: 20 + CGFloat(i % 2) * 3)
            memoryShelfNode?.addChild(item)
            memoryDisplayNodes.append(item)
        }
    }

    private func chooseNextBehavior(force: RefugeBehavior?) {
        let behavior = force ?? RefugeBehavior.allCases.randomElement() ?? .drifting
        currentBehavior = behavior
        behaviorTimer = CGFloat.random(in: 4.2...7.2)
        refreshLabels()

        switch behavior {
        case .drifting:
            moveMermaid(to: driftPoints.randomElement() ?? .zero,
                        duration: TimeInterval.random(in: 2.0...3.4),
                        expression: .neutral,
                        mode: .swing)
        case .resting:
            moveMermaid(to: restPoint + CGPoint(x: 4, y: 20),
                        duration: 1.6,
                        expression: .tired,
                        mode: .idle) { [weak self] in
                self?.beginRestPose()
            }
        case .observingMemories:
            moveMermaid(to: memoryPoint + CGPoint(x: -46, y: 10),
                        duration: 1.9,
                        expression: .curious,
                        mode: .swing) { [weak self] in
                self?.emitMermaidBubbles(count: 2)
            }
        case .visitingUpgrade:
            moveMermaid(to: upgradePoint + CGPoint(x: -48, y: 0),
                        duration: 2.0,
                        expression: .curious,
                        mode: .swing)
        case .visitingStore:
            moveMermaid(to: storePoint + CGPoint(x: 50, y: -2),
                        duration: 2.0,
                        expression: .happy,
                        mode: .swing)
        }
    }

    private func moveMermaid(to point: CGPoint,
                             duration: TimeInterval,
                             expression: MermaidExpressionName,
                             mode: MovementType,
                             completion: (() -> Void)? = nil) {
        guard let mermaid = displayMermaid else { return }
        let base = mermaid.base
        base.removeAction(forKey: "refuge_behavior")
        base.removeAction(forKey: "refuge_idle_motion")

        let dx = point.x - base.position.x
        if abs(dx) > 4 {
            mermaid.setVisualDirection(dx < 0 ? .left : .right)
            base.xScale = abs(mermaidBaseScale) * (dx < 0 ? -1 : 1)
            base.yScale = abs(mermaidBaseScale)
        }
        mermaid.applyExpression(expression, animated: true)
        mermaid.setAnimationMode(mode)

        let move = SKAction.move(to: point, duration: duration)
        move.timingMode = .easeInEaseOut
        let bob = SKAction.sequence([
            .scaleX(to: base.xScale * 1.02, y: base.yScale * 0.98, duration: duration / 2),
            .scaleX(to: base.xScale, y: base.yScale, duration: duration / 2)
        ])
        base.run(.sequence([
            .group([move, bob]),
            .run { completion?() }
        ]), withKey: "refuge_behavior")
    }

    private func beginRestPose() {
        guard let mermaid = displayMermaid else { return }
        mermaid.setAnimationMode(.idle)
        mermaid.applyExpression(.tired, animated: true)
        let base = mermaid.base
        base.removeAction(forKey: "refuge_idle_motion")
        base.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 1.2),
            .run { [weak self] in self?.emitMermaidBubbles(count: 1) },
            .moveBy(x: 0, y: -3, duration: 1.2)
        ])), withKey: "refuge_idle_motion")
    }

    private func emitMermaidBubbles(count: Int) {
        guard let base = displayMermaid?.base else { return }
        for index in 0..<count {
            let bubble = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            bubble.fillColor = UIColor.white.withAlphaComponent(0.18)
            bubble.strokeColor = GameUI.accent.withAlphaComponent(0.34)
            bubble.lineWidth = 1
            bubble.position = base.position + CGPoint(x: CGFloat.random(in: -16...16),
                                                      y: CGFloat.random(in: 20...42))
            mermaidBubbleLayer.addChild(bubble)
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

    private func shortMemoryMark(_ memory: String, index: Int) -> String {
        let trimmed = memory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "\(index + 1)" }
        return String(first).uppercased()
    }

    private func openEnhancements() {
        enhancementsOverlay?.removeFromParent()
        storeOverlay?.removeFromParent()
        storeOverlay = nil
        let overlay = RefugeEnhancementsOverlay(size: overlaySize,
                                                insets: safeAreaInsets,
                                                stats: ctx.stats)
        overlay.zPosition = 20
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
        overlay.zPosition = 20
        addChild(overlay)
        storeOverlay = overlay
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var node: SKNode? = atPoint(touch.location(in: self))
        while let current = node {
            switch current.name {
            case "refuge_enhancements":
                GameAudio.shared.play(.uiOpenPanel)
                openEnhancements()
                refreshLabels()
                return
            case "refuge_store":
                GameAudio.shared.play(.uiOpenPanel)
                openStore()
                refreshLabels()
                return
            case "refuge_rest":
                GameAudio.shared.play(.uiConfirm)
                restingBoostTimer = 8
                chooseNextBehavior(force: .resting)
                ctx.say("Ela se ajeitou na cama de algas para descansar.")
                return
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
