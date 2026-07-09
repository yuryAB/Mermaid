//
//  RefugeFlowController.swift
//  Ester
//
//  Owns the ocean-side transition into the Refúgio das Marés. A portal opens
//  near the mermaid, she swims into it, and then the app presents a dedicated
//  `RefugeScene` (a fully separate SKScene). The ocean `GameScene` is no longer
//  running behind the refuge — the two are distinct scenes. Returning from the
//  refuge is handled by `RefugeScene`, which recreates the ocean scene from the
//  saved map position (just like a region transition).
//

import Foundation
import SpriteKit
import UIKit

final class RefugeFlowController {
    private unowned let ctx: GameContext
    private weak var worldNode: SKNode?
    private let mermaidBase: () -> SKNode?
    private let canBegin: () -> Bool
    private let closeBlockingUI: () -> Void
    private let persistAndSave: () -> Void

    private var portal: RefugePortalNode?
    private var isEntering = false

    /// True while a portal is open or the entry animation is running, so the
    /// ocean scene can gate other interactions during the transition.
    var isBusy: Bool {
        portal != nil || isEntering
    }

    init(ctx: GameContext,
         worldNode: SKNode,
         mermaidBase: @escaping () -> SKNode?,
         canBegin: @escaping () -> Bool,
         closeBlockingUI: @escaping () -> Void,
         persistAndSave: @escaping () -> Void) {
        self.ctx = ctx
        self.worldNode = worldNode
        self.mermaidBase = mermaidBase
        self.canBegin = canBegin
        self.closeBlockingUI = closeBlockingUI
        self.persistAndSave = persistAndSave
    }

    /// Step 1: a portal opens near the mermaid and she swims toward it.
    func beginEntry() {
        guard canBegin(), portal == nil, !isEntering else { return }
        closeBlockingUI()
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
        worldNode?.addChild(portal)
        portal.open()
        self.portal = portal

        ctx.autonomy.goToRefugePortal(at: portal.position)
        ctx.say("Um portal para o Refúgio se abriu ali perto...")
    }

    /// Step 2: she reached the portal — she shrinks into it, then the refuge
    /// scene is presented.
    func mermaidReachedPortal() {
        guard let portal, !isEntering else { return }
        isEntering = true
        ctx.autonomy.paused = true
        GameAudio.shared.play(.refugePortalEnter)

        guard let base = mermaidBase() else {
            presentRefugeScene()
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
            .run { [weak self] in self?.presentRefugeScene() }
        ]))
        portal.close(after: 0.7)
    }

    /// Cancels an in-progress entry (e.g. before opening a debug tool). Safe to
    /// call when nothing is happening.
    func cancelEntry() {
        portal?.close()
        portal = nil
        isEntering = false
    }

    private func presentRefugeScene() {
        portal?.close()
        portal = nil

        // Save the current ocean position so returning restores the same spot.
        persistAndSave()

        guard let oceanScene = ctx.scene, let view = oceanScene.view else {
            isEntering = false
            return
        }

        let refuge = RefugeScene(size: oceanScene.size)
        refuge.scaleMode = .aspectFill
        view.presentScene(refuge, transition: .crossFade(withDuration: 0.5))
        isEntering = false
    }
}
