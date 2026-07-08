//
//  ChallengeFlowController.swift
//  Ester
//
//  Gerencia o ciclo de vida completo dos desafios: abertura, overlay,
//  backdrop, e fechamento com resultado.
//

import SpriteKit
import GameplayKit

final class ChallengeFlowController {
    private unowned let scene: GameScene
    private unowned let ctx: GameContext
    private unowned let cameraNode: SKCameraNode
    private var stats: MermaidStats { ctx.stats }

    var plotOverlay: TideWeavingOverlay?
    var climbOverlay: BubbleClimbOverlay?
    var snapOverlay: ShellSnapOverlay?
    var banquetOverlay: BanquetOfTidesOverlay?
    var memoryOverlay: TideMemoryOverlay?
    var echoMelodyOverlay: EchoMelodyOverlay?
    var reefAsteroidsOverlay: ReefAsteroidsOverlay?
    var challengeBackdrop: SKNode?
    var challengeChoiceMenu: ChallengeChoiceOverlay?
    var resourceChoiceMenu: ResourceChoiceOverlay?
    var poiChallengeOffer: POIChallengeOfferOverlay?
    var pendingRegistroChallengeSpeciesId: String?
    var pendingPOIChallengeCompletion: ((ChallengeResult) -> Void)?

    private let modalDropOffset: CGFloat

    init(scene: GameScene, ctx: GameContext, cameraNode: SKCameraNode) {
        self.scene = scene
        self.ctx = ctx
        self.cameraNode = cameraNode
        self.modalDropOffset = max(scene.view?.safeAreaInsets.top ?? 0, 44)
    }

    var isChallengeOpen: Bool {
        plotOverlay != nil
            || climbOverlay != nil
            || snapOverlay != nil
            || banquetOverlay != nil
            || memoryOverlay != nil
            || echoMelodyOverlay != nil
            || reefAsteroidsOverlay != nil
    }

    func updateOverlays(dt: CGFloat) {
        plotOverlay?.update(dt: dt)
        climbOverlay?.update(dt: dt)
        snapOverlay?.update(dt: dt)
        banquetOverlay?.update(dt: dt)
        memoryOverlay?.update(dt: dt)
        echoMelodyOverlay?.update(dt: dt)
        reefAsteroidsOverlay?.update(dt: dt)
    }

    func openChallenge(giver: FishNode) {
        guard !isChallengeOpen,
              challengeChoiceMenu == nil,
              resourceChoiceMenu == nil,
              !scene.isRegistroOpen,
              poiChallengeOffer == nil,
              scene.refugeOverlay == nil else { return }
        guard let kind = giver.offeredChallenge else { return }
        guard kind.isAvailable else {
            ctx.challenges.consumeChallenge(of: giver)
            return
        }
        GameAudio.shared.play(.challengeOpen)
        let special = giver.isSpecialChallenge
        let challengeGoal = giver.offeredChallengeGoal
            ?? ctx.challenges.makeGoal(kind: kind, special: special, at: giver.position)
        let giverDisplay = giver.makeGiverDisplayNode()
        pendingRegistroChallengeSpeciesId = RegistroCatalog.challengeUnlockCandidate(
            giverSpeciesId: giver.species?.id,
            stats: stats
        )?.id
        ctx.challenges.consumeChallenge(of: giver)
        presentChallenge(kind: kind, special: special, challengeGoal: challengeGoal, giverDisplay: giverDisplay)
    }

    func openHatchingChallenge() {
        guard !isChallengeOpen,
              challengeChoiceMenu == nil,
              resourceChoiceMenu == nil,
              !scene.isRegistroOpen,
              poiChallengeOffer == nil,
              scene.refugeOverlay == nil else { return }
        pendingRegistroChallengeSpeciesId = nil
        GameAudio.shared.play(.challengeOpen)
        presentChallenge(kind: .plot, special: false, challengeGoal: 35, giverDisplay: nil, hatching: true)
    }

    func canPresentPOIChallengeOffer() -> Bool {
        !isChallengeOpen
            && challengeChoiceMenu == nil
            && resourceChoiceMenu == nil
            && scene.regionMenu == nil
            && !scene.isRegistroOpen
            && poiChallengeOffer == nil
            && scene.refugeOverlay == nil
            && scene.rigDebugTool == nil
    }

    @discardableResult
    func openPOIChallenge(for poi: WorldPOI,
                          onCompletion: @escaping (ChallengeResult) -> Void) -> Bool {
        guard canPresentPOIChallengeOffer() else { return false }
        guard let poiChallenge = poi.challenge,
              poiChallenge.kind.isAvailable else { return false }
        let challengeGoal = poiChallenge.goal
            ?? GameBalance.poiChallengeGoal(kind: poiChallenge.kind,
                                            at: poi.position,
                                            special: poiChallenge.special,
                                            multiplier: poiChallenge.goalMultiplier)
        ctx.say(poiChallenge.introText.isEmpty
                ? "Ela encontrou \(poi.name). Há um desafio esperando."
                : poiChallenge.introText)
        GameAudio.shared.play(.uiOpenPanel)
        let size = scene.size
        let offer = POIChallengeOfferOverlay(size: size,
                                             poi: poi,
                                             challengeGoal: challengeGoal,
                                             onAccept: { [weak self] in
                                                 guard let self else { return }
                                                 self.closePOIChallengeOffer(playSound: false)
                                                 self.startPOIChallenge(poi: poi,
                                                                        poiChallenge: poiChallenge,
                                                                        challengeGoal: challengeGoal,
                                                                        onCompletion: onCompletion)
                                             },
                                             onDecline: { [weak self] in
                                                 guard let self else { return }
                                                 self.closePOIChallengeOffer()
                                                 self.ctx.say("Ela deixou \(poi.name) para tentar depois.")
                                             })
        offer.zPosition = 190
        offer.position = CGPoint(x: 0, y: -modalDropOffset)
        cameraNode.addChild(offer)
        poiChallengeOffer = offer
        return true
    }

    func openChallengeChoiceMenu() {
        guard !isChallengeOpen,
              challengeChoiceMenu == nil,
              resourceChoiceMenu == nil,
              !scene.isRegistroOpen,
              poiChallengeOffer == nil,
              scene.refugeOverlay == nil else { return }
        GameAudio.shared.play(.uiTap)
        let choices = ChallengeKind.availableCases
        let recordSnapshots = choices.reduce(into: [ChallengeKind: ChallengeRecordSnapshot]()) { dict, kind in
            dict[kind] = ChallengeRecordSnapshot(kind: kind, bestScore: stats.highScore(for: kind))
        }
        let size = scene.size
        let menu = ChallengeChoiceOverlay(size: size,
                                          kinds: choices,
                                          records: recordSnapshots,
                                          onSelect: { [weak self] kind in
                                              guard let self else { return }
                                              self.closeChallengeChoiceMenu(playSound: false)
                                              guard let giver = self.ctx.challenges.ensureGiver(
                                                  near: self.ctx.mermaidPosition,
                                                  kind: kind
                                              ) else { return }
                                              self.openChallenge(giver: giver)
                                          },
                                          onClose: { [weak self] in
                                              self?.closeChallengeChoiceMenu()
                                          })
        menu.zPosition = 190
        menu.position = CGPoint(x: 0, y: -modalDropOffset)
        cameraNode.addChild(menu)
        challengeChoiceMenu = menu
    }

    func closeChallengeChoiceMenu(playSound: Bool = true) {
        challengeChoiceMenu?.removeFromParent()
        challengeChoiceMenu = nil
        if playSound { GameAudio.shared.play(.uiTap) }
    }

    func openResourceChoiceMenu(onSelect: @escaping (SupportResourceKind) -> Void) {
        guard !isChallengeOpen,
              resourceChoiceMenu == nil,
              !scene.isRegistroOpen,
              poiChallengeOffer == nil,
              scene.refugeOverlay == nil else { return }
        GameAudio.shared.play(.uiTap)
        let resources = SupportResourceKind.allCases
        let size = scene.size
        let counts = Dictionary(uniqueKeysWithValues: resources.map { ($0, 0) })
        let menu = ResourceChoiceOverlay(
            size: size,
            counts: counts,
            onSelect: { [weak self] kind in
                self?.closeResourceChoiceMenu(playSound: false)
                onSelect(kind)
            },
            onUnavailable: { kind in
                GameAudio.shared.play(.uiReject)
            },
            onClose: { [weak self] in
                self?.closeResourceChoiceMenu()
            }
        )
        menu.zPosition = 190
        menu.position = CGPoint(x: 0, y: -modalDropOffset)
        cameraNode.addChild(menu)
        resourceChoiceMenu = menu
    }

    func closeResourceChoiceMenu(playSound: Bool = true) {
        resourceChoiceMenu?.removeFromParent()
        resourceChoiceMenu = nil
        if playSound { GameAudio.shared.play(.uiTap) }
    }

    func closePOIChallengeOffer(playSound: Bool = true) {
        poiChallengeOffer?.removeFromParent()
        poiChallengeOffer = nil
        if playSound { GameAudio.shared.play(.uiTap) }
    }

    private func startPOIChallenge(poi: WorldPOI,
                                   poiChallenge: POIChallenge,
                                   challengeGoal: Int,
                                   onCompletion: @escaping (ChallengeResult) -> Void) {
        guard !isChallengeOpen,
              challengeChoiceMenu == nil,
              resourceChoiceMenu == nil,
              scene.regionMenu == nil,
              !scene.isRegistroOpen,
              scene.refugeOverlay == nil else { return }
        pendingPOIChallengeCompletion = onCompletion
        pendingRegistroChallengeSpeciesId = nil
        GameAudio.shared.play(.challengeOpen)
        presentChallenge(kind: poiChallenge.kind,
                         special: poiChallenge.special,
                         challengeGoal: challengeGoal,
                         giverDisplay: makePOIChallengeDisplay(for: poi))
    }

    private func makePOIChallengeDisplay(for poi: WorldPOI) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: 28)
        ring.fillColor = poi.visual.color.withAlphaComponent(0.18)
        ring.strokeColor = UIColor.white.withAlphaComponent(0.58)
        ring.lineWidth = 1.4
        ring.glowWidth = 5
        node.addChild(ring)

        let artwork = WorldPOIArtworkFactory.makeArtwork(for: poi, size: .challenge)
        artwork.zPosition = 2
        node.addChild(artwork)
        return node
    }

    private func consumePendingRegistroUnlock(result: ChallengeResult) -> RegistroSpeciesDefinition? {
        defer { pendingRegistroChallengeSpeciesId = nil }
        guard result.reachedTarget,
              let speciesId = pendingRegistroChallengeSpeciesId,
              let definition = RegistroCatalog.definition(for: speciesId) else { return nil }
        let didRegister = stats.registerSpecies(
            speciesId,
            memoryText: "Registrou \(definition.commonName) no Registro de \(definition.biomeName)"
        )
        return didRegister ? definition : nil
    }

    private func presentChallenge(kind: ChallengeKind,
                                  special: Bool,
                                  challengeGoal: Int,
                                  giverDisplay: SKNode?,
                                  hatching: Bool = false) {
        guard !scene.isRegistroOpen else {
            pendingRegistroChallengeSpeciesId = nil
            pendingPOIChallengeCompletion = nil
            return
        }
        guard hatching || kind.isAvailable else {
            pendingRegistroChallengeSpeciesId = nil
            pendingPOIChallengeCompletion = nil
            return
        }
        scene.closeRegionMenu()
        closeChallengeChoiceMenu(playSound: false)
        closeResourceChoiceMenu(playSound: false)
        closePOIChallengeOffer(playSound: false)
        let zone = ctx.depth.currentZone
        let record = ChallengeRecordSnapshot(kind: kind, bestScore: stats.highScore(for: kind))
        let isHatchingSession = hatching || stats.phase == .egg
        let victoryReward = GameBalance.challengeVictoryReward(
            special: special,
            isHatching: isHatchingSession,
            resourceCandidates: SupportResourceKind.challengeRewardCandidates
        )
        stats.energy = max(0, stats.energy - 8)
        ctx.autonomy.paused = true
        showChallengeBackdrop()
        let size = scene.size

        switch kind {
        case .plot:
            let session: TideSessionType
            if isHatchingSession {
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
                                             victoryReward: victoryReward,
                                             challengeGoal: challengeGoal,
                                             giverDisplay: giverDisplay,
                                             record: record) { [weak self] result in
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
                                             victoryReward: victoryReward,
                                             challengeGoal: challengeGoal,
                                             giverDisplay: giverDisplay,
                                             record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            climbOverlay = overlay

        case .snap:
            let overlay = ShellSnapOverlay(size: size,
                                           zone: zone,
                                           phase: stats.phase,
                                           special: special,
                                           shellRewardMultiplier: stats.shellRewardMultiplier,
                                           victoryReward: victoryReward,
                                           challengeGoal: challengeGoal,
                                           giverDisplay: giverDisplay,
                                           record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            snapOverlay = overlay

        case .banquet:
            let overlay = BanquetOfTidesOverlay(size: size,
                                                zone: zone,
                                                phase: stats.phase,
                                                special: special,
                                                shellRewardMultiplier: stats.shellRewardMultiplier,
                                                victoryReward: victoryReward,
                                                challengeGoal: challengeGoal,
                                                giverDisplay: giverDisplay,
                                                record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            banquetOverlay = overlay

        case .memory:
            let overlay = TideMemoryOverlay(size: size,
                                            zone: zone,
                                            phase: stats.phase,
                                            special: special,
                                            shellRewardMultiplier: stats.shellRewardMultiplier,
                                            victoryReward: victoryReward,
                                            initialGoal: challengeGoal,
                                            giverDisplay: giverDisplay,
                                            record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            memoryOverlay = overlay

        case .echoMelody:
            let overlay = EchoMelodyOverlay(size: size,
                                            zone: zone,
                                            phase: stats.phase,
                                            special: special,
                                            shellRewardMultiplier: stats.shellRewardMultiplier,
                                            victoryReward: victoryReward,
                                            challengeGoal: challengeGoal,
                                            giverDisplay: giverDisplay,
                                            record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            echoMelodyOverlay = overlay

        case .reefAsteroids:
            let overlay = ReefAsteroidsOverlay(size: size,
                                               zone: zone,
                                               phase: stats.phase,
                                               special: special,
                                               shellRewardMultiplier: stats.shellRewardMultiplier,
                                               victoryReward: victoryReward,
                                               challengeGoal: challengeGoal,
                                               giverDisplay: giverDisplay,
                                               record: record) { [weak self] result in
                self?.closeChallenge(result: result, zone: zone)
            }
            overlay.zPosition = 200
            overlay.position = CGPoint(x: 0, y: -modalDropOffset)
            cameraNode.addChild(overlay)
            reefAsteroidsOverlay = overlay
        }
    }

    private func showChallengeBackdrop() {
        challengeBackdrop?.removeFromParent()
        let size = scene.size

        let node = SKNode()
        node.zPosition = 190
        node.position = CGPoint(x: 0, y: -modalDropOffset)

        let shaderTime = SKUniform(name: "u_time", float: 0)
        let veil = SKShapeNode(rectOf: CGSize(width: size.width * 2.4, height: size.height * 2.4))
        veil.fillColor = UIColor.black.withAlphaComponent(0.54)
        veil.strokeColor = .clear
        let shader = SKShader(source: """
        void main() {
            vec2 uv = v_tex_coord;
            float wave = sin((uv.x + uv.y) * 18.0 + u_time * 1.6) * 0.5 + 0.5;
            vec4 base = v_color_mix;
            float alpha = base.a * (0.86 + wave * 0.08);
            vec3 tint = mix(base.rgb, vec3(0.05, 0.22, 0.24), 0.26 + wave * 0.08);
            gl_FragColor = vec4(tint * alpha, alpha);
        }
        """)
        shader.uniforms = [shaderTime]
        veil.fillShader = shader
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
        node.run(.repeatForever(.customAction(withDuration: 10.0) { _, elapsed in
            shaderTime.floatValue = Float(elapsed)
        }))
        challengeBackdrop = node
    }

    func closeChallenge(result: ChallengeResult, zone: DepthZone) {
        plotOverlay?.removeFromParent()
        plotOverlay = nil
        climbOverlay?.removeFromParent()
        climbOverlay = nil
        snapOverlay?.removeFromParent()
        snapOverlay = nil
        banquetOverlay?.removeFromParent()
        banquetOverlay = nil
        memoryOverlay?.removeFromParent()
        memoryOverlay = nil
        echoMelodyOverlay?.removeFromParent()
        echoMelodyOverlay = nil
        reefAsteroidsOverlay?.removeFromParent()
        reefAsteroidsOverlay = nil
        challengeBackdrop?.removeFromParent()
        challengeBackdrop = nil
        let poiCompletion = pendingPOIChallengeCompletion
        pendingPOIChallengeCompletion = nil

        let isPOIChallenge = poiCompletion != nil
        let gainedPearls = result.isHatching || isPOIChallenge
            ? 0
            : stats.awardChallengePearls(result.pearls, points: result.points)

        if result.isHatching || stats.phase == .egg {
            pendingRegistroChallengeSpeciesId = nil
            ctx.growth.addHatchProgress(CGFloat(result.points) / 900)
            stats.save()
            GameAudio.shared.play(.eggTap, volumeMultiplier: 0.7)
            ctx.say("O desafio reuniu energia de nascimento! 🥚✨")
            return
        }

        ctx.autonomy.paused = false
        ctx.autonomy.finishChallenge()
        stats.boostMood(8)
        let adaptation = stats.adaptation(for: zone)
        stats.setAdaptation(adaptation + 3, for: zone)
        let madeHighScore = stats.recordHighScore(result.points, for: result.kind)
        let registroUnlock = consumePendingRegistroUnlock(result: result)
        let resourceReward: SupportResourceKind?
        if result.reachedTarget {
            stats.puzzlesSolved += 1
            stats.addMemory("Venceu o \(result.kind.title) em \(zone.displayName)")
            if let kind = result.victoryReward.resourceKind, !result.special {
                ctx.supportResources.grantCommonChallengeCompletionReward(kind)
                resourceReward = kind
            } else {
                resourceReward = nil
            }
        } else {
            resourceReward = nil
        }
        stats.save()
        if let poiCompletion {
            poiCompletion(result)
        } else {
            let recordText = madeHighScore ? " Novo recorde!" : ""
            let victoryText: String
            if result.reachedTarget && result.victoryReward.grantsShellBonus {
                victoryText = " Vitória: +50% conchas." + registroVictoryText(registroUnlock)
            } else if result.reachedTarget, let resourceReward {
                victoryText = " Vitória: \(resourceReward.title) +1." + registroVictoryText(registroUnlock)
            } else if result.reachedTarget {
                victoryText = registroVictoryText(registroUnlock)
            } else {
                victoryText = ""
            }
            ctx.say(result.reachedTarget
                    ? "Ela adorou o \(result.kind.title)!\(recordText) 🐚+\(GameUI.shellAmountText(gainedPearls)).\(victoryText)"
                    : "Quase!\(recordText) Ainda assim ganhou 🐚+\(GameUI.shellAmountText(gainedPearls))")
        }
    }

    private func registroVictoryText(_ definition: RegistroSpeciesDefinition?) -> String {
        guard let definition else { return "" }
        return " Aprendeu sobre \(definition.commonName)!"
    }
}
