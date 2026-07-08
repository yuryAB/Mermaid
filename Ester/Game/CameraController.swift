//
//  CameraController.swift
//  Ester
//
//  Gerencia a câmera, backdrop do oceano e paralaxe.
//

import SpriteKit
import GameplayKit

final class CameraController {
    private unowned let scene: GameScene
    private unowned let ctx: GameContext
    private unowned let cameraNode: SKCameraNode
    private(set) var oceanBackdrop: OceanParallaxBackdrop?

    init(scene: GameScene, ctx: GameContext, cameraNode: SKCameraNode) {
        self.scene = scene
        self.ctx = ctx
        self.cameraNode = cameraNode
    }

    func setupOceanBackdrop(for parent: SKNode) {
        let backdrop = OceanParallaxBackdrop(size: scene.size)
        backdrop.zPosition = -90
        parent.addChild(backdrop)
        oceanBackdrop = backdrop
    }

    func setupCamera(for parent: SKNode) {
        cameraNode.setScale(2.0)
        parent.addChild(cameraNode)
    }

    func update(dt: CGFloat, cameraTarget: CGPoint) {
        let target = clampedCameraPosition(cameraTarget)
        let blend = min(1, dt * 3)
        cameraNode.position = CGPoint(
            x: cameraNode.position.x + (target.x - cameraNode.position.x) * blend,
            y: cameraNode.position.y + (target.y - cameraNode.position.y) * blend
        )
    }

    func snap(to position: CGPoint) {
        cameraNode.position = clampedCameraPosition(position)
    }

    func updateOceanBackdrop(dt: CGFloat, waterColor: UIColor) {
        let cameraZone = DepthZone.zone(atY: cameraNode.position.y)
        let environment = ctx.depth.environment(atY: cameraNode.position.y)
        let profile = scene.activeEcosystemProfile
        let biome = profile.subBiome(at: cameraNode.position, zone: cameraZone)
        oceanBackdrop?.update(dt: dt,
                              cameraPosition: cameraNode.position,
                              waterColor: waterColor,
                              zone: cameraZone,
                              environment: environment,
                              biome: biome)
    }

    private func clampedCameraPosition(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x.clamped(to: (World.minX + 700)...(World.maxX - 700)),
                y: p.y.clamped(to: (World.floorY + 500)...500))
    }
}
