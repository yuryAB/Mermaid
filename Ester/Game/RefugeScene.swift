//
//  RefugeScene.swift
//  Ester
//
//  The Refúgio das Marés is now its OWN SpriteKit scene, fully separate from
//  the ocean/exploration `GameScene`. Entering the refuge presents this scene
//  (via `RefugeFlowController`), so the ocean world stops updating entirely —
//  there is no more parallel map running behind the refuge. Leaving the refuge
//  recreates the ocean scene from the saved map position, exactly like a
//  region transition.
//
//  This scene hosts the existing `RefugeOverlay` content node and drives it
//  with a minimal `GameContext`. The refuge only needs the shared, in-memory
//  `MermaidStats`, plus lightweight `GrowthSystem` / `ResourceSupportSystem`
//  instances that operate purely on those stats.
//

import SpriteKit
import UIKit

final class RefugeScene: SKScene {

    /// Minimal context for the refuge. It reuses the shared in-memory stats so
    /// changes persist and carry back to the ocean scene on exit.
    private let refugeContext: GameContext
    private var overlay: RefugeOverlay?
    private var lastUpdateTime: TimeInterval = 0
    private var isReturning = false

    override init(size: CGSize) {
        let ctx = GameContext()
        ctx.stats = MermaidStats.load()
        // These systems only read/write `ctx.stats`; a throwaway world node is
        // enough for the few methods the refuge calls (e.g. evolutionNote()).
        ctx.growth = GrowthSystem(ctx: ctx, worldNode: SKNode())
        ctx.supportResources = ResourceSupportSystem(ctx: ctx)
        self.refugeContext = ctx

        super.init(size: size)
        // Center-based coordinate space so `RefugeOverlay` (which builds around
        // the screen center) lays out correctly without a camera.
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .aspectFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.12, blue: 0.20, alpha: 1)

        let insets = view.safeAreaInsets
        let overlay = RefugeOverlay(size: size,
                                    insets: insets,
                                    ctx: refugeContext,
                                    onClose: { [weak self] in
                                        self?.returnToOcean()
                                    })
        overlay.zPosition = 10
        addChild(overlay)
        self.overlay = overlay

        GameAudio.shared.startRefugeAmbience()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat
        if lastUpdateTime == 0 {
            dt = 0
        } else {
            dt = CGFloat(min(0.05, currentTime - lastUpdateTime))
        }
        lastUpdateTime = currentTime

        overlay?.update(dt: dt)
        // In the refuge, time is gentle: rest is accelerated (mirrors the old
        // in-overlay recovery bonus).
        refugeContext.stats.tick(dt: dt, energyDelta: 2.2)
    }

    /// Exits the refuge and returns to the ocean at the saved map position.
    private func returnToOcean() {
        guard !isReturning, let view = self.view else { return }
        isReturning = true

        refugeContext.stats.save(immediately: true)

        let ocean = MapSceneFactory.sceneForSavedMap(size: size)
        ocean.scaleMode = .aspectFill
        view.presentScene(ocean, transition: .crossFade(withDuration: 0.5))
    }
}
