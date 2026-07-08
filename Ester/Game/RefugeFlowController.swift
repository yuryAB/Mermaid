//
//  RefugeFlowController.swift
//  Ester
//
//  Owns the pocket-dimension transition around the Refuge overlay.
//

import Foundation
import SpriteKit
import UIKit

final class RefugeFlowController {
    private unowned let ctx: GameContext
    private weak var worldNode: SKNode?
    private weak var cameraNode: SKCameraNode?
    private let mermaidBase: () -> SKNode?
    private let mermaidScale: () -> CGFloat
    private let restoreMermaidForOverlay: () -> Void
    private let canBegin: () -> Bool
    private let closeBlockingUI: () -> Void
    private let sceneSize: () -> CGSize
    private let safeAreaInsets: () -> UIEdgeInsets
    private let getOverlay: () -> RefugeOverlay?
    private let setOverlay: (RefugeOverlay?) -> Void
    private let persistAndSave: () -> Void

    private var portal: RefugePortalNode?
    private var savedOceanPosition: CGPoint?

    var isBusy: Bool {
        portal != nil || getOverlay() != nil
    }

    init(ctx: GameContext,
         worldNode: SKNode,
         cameraNode: SKCameraNode,
         mermaidBase: @escaping () -> SKNode?,
         mermaidScale: @escaping () -> CGFloat,
         restoreMermaidForOverlay: @escaping () -> Void,
         canBegin: @escaping () -> Bool,
         closeBlockingUI: @escaping () -> Void,
         sceneSize: @escaping () -> CGSize,
         safeAreaInsets: @escaping () -> UIEdgeInsets,
         getOverlay: @escaping () -> RefugeOverlay?,
         setOverlay: @escaping (RefugeOverlay?) -> Void,
         persistAndSave: @escaping () -> Void) {
        self.ctx = ctx
        self.worldNode = worldNode
        self.cameraNode = cameraNode
        self.mermaidBase = mermaidBase
        self.mermaidScale = mermaidScale
        self.restoreMermaidForOverlay = restoreMermaidForOverlay
        self.canBegin = canBegin
        self.closeBlockingUI = closeBlockingUI
        self.sceneSize = sceneSize
        self.safeAreaInsets = safeAreaInsets
        self.getOverlay = getOverlay
        self.setOverlay = setOverlay
        self.persistAndSave = persistAndSave
    }

    func beginEntry() {
        guard canBegin(), portal == nil else { return }
        closeBlockingUI()
        GameAudio.shared.play(.refugePortalOpen)

        let mermaidPos = ctx.mermaidPosition
        savedOceanPosition = mermaidPos
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 260...340)
        let yRange = ctx.depth.allowedYRange()
        let portal = RefugePortalNode()
        portal.position = CGPoint(
            x: (mermaidPos.x + cos(angle) * distance).clamped(to: World.minX...World.maxX),
            y: (mermaidPos.y + sin(angle) * distance).clamped(to: yRange)
        )
        worldNode?.addChild(portal)
        portal.open()
        self.portal = portal

        ctx.autonomy.goToRefugePortal(at: portal.position)
        ctx.say("Um portal para o Refúgio se abriu ali perto...")
    }

    func mermaidReachedPortal() {
        guard let portal else { return }
        ctx.autonomy.paused = true
        GameAudio.shared.play(.refugePortalEnter)

        guard let base = mermaidBase() else {
            presentRefuge()
            return
        }

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

    func close(resume: Bool) {
        if !resume {
            getOverlay()?.removeFromParent()
            setOverlay(nil)
            portal?.close()
            portal = nil
            GameAudio.shared.updateOceanAmbience(for: ctx.depth.currentZone)
            return
        }

        guard let overlay = getOverlay() else { return }
        GameAudio.shared.play(.uiClosePanel)
        overlay.isUserInteractionEnabled = false
        overlay.run(.sequence([
            .fadeOut(withDuration: 0.26),
            .run { [weak self, weak overlay] in
                overlay?.removeFromParent()
                self?.setOverlay(nil)
                self?.playReturnTransition()
            }
        ]))
    }

    private func presentRefuge() {
        portal = nil
        restoreMermaidForOverlay()

        let overlay = RefugeOverlay(size: sceneSize(),
                                    insets: safeAreaInsets(),
                                    ctx: ctx,
                                    onClose: { [weak self] in
                                        self?.close(resume: true)
                                    })
        overlay.zPosition = 195
        overlay.alpha = 0
        cameraNode?.addChild(overlay)
        setOverlay(overlay)
        overlay.run(.fadeIn(withDuration: 0.24))
        GameAudio.shared.startRefugeAmbience()
    }

    private func playReturnTransition() {
        let returnPoint = savedOceanPosition ?? ctx.mermaidPosition
        savedOceanPosition = nil

        let returnPortal = RefugePortalNode()
        returnPortal.position = returnPoint
        worldNode?.addChild(returnPortal)
        returnPortal.open()
        portal = returnPortal

        guard let base = mermaidBase() else {
            finishReturnTransition()
            return
        }

        base.removeAllActions()
        base.position = returnPoint
        base.alpha = 0
        base.setScale(0.02)

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.58),
            .scale(to: mermaidScale(), duration: 0.58)
        ])
        appear.eaeInEaseOut()
        base.run(.sequence([
            .wait(forDuration: 0.18),
            appear,
            .run { [weak self] in self?.finishReturnTransition() }
        ]))
        returnPortal.close(after: 0.85)
    }

    private func finishReturnTransition() {
        portal = nil
        ctx.autonomy.cancelRefugeEntry()
        if ctx.stats.phase != .egg {
            ctx.autonomy.paused = false
        }
        GameAudio.shared.updateOceanAmbience(for: ctx.depth.currentZone)
        persistAndSave()
        ctx.say("De volta ao oceano, do mesmo lugar de antes.")
    }
}
