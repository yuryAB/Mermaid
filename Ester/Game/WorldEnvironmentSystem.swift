//
//  WorldEnvironmentSystem.swift
//  Ester
//
//  Streaming visual do oceano: chunks seedados por coordenada para manter
//  o mundo grande sem deixar milhares de nos vivos longe da camera.
//

import Foundation
import SpriteKit

final class WorldChunkManager {
    private let rootNode = SKNode()
    private let activeRadius = 1
    private var chunks: [WorldChunkCoord: SKNode] = [:]
    private var updateAccumulator: CGFloat = 0
    private var lastCenter: WorldChunkCoord?

    init(parent: SKNode) {
        rootNode.zPosition = -12
        parent.addChild(rootNode)
    }

    func update(dt: CGFloat, cameraPosition: CGPoint) {
        updateAccumulator += dt
        let center = WorldChunkCoord.chunkCoord(for: cameraPosition)
        guard center != lastCenter || updateAccumulator >= 0.35 else { return }
        updateAccumulator = 0
        lastCenter = center

        var needed = Set<WorldChunkCoord>()
        for dx in -activeRadius...activeRadius {
            for dy in -activeRadius...activeRadius {
                let coord = WorldChunkCoord(x: center.x + dx, y: center.y + dy)
                guard coord.rect.maxX >= World.minX,
                      coord.rect.minX <= World.maxX,
                      coord.rect.maxY >= World.floorY,
                      coord.rect.minY <= World.surfaceTopY else { continue }
                needed.insert(coord)
            }
        }

        for coord in Array(chunks.keys) where !needed.contains(coord) {
            chunks.removeValue(forKey: coord)?.removeFromParent()
        }

        for coord in needed where chunks[coord] == nil {
            let node = WorldChunkFactory.makeChunk(coord)
            chunks[coord] = node
            rootNode.addChild(node)
        }
    }
}
