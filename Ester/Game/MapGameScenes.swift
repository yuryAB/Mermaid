//
//  MapGameScenes.swift
//  Ester
//
//  GameScenes concretas por mapa. Cada classe carrega uma região própria,
//  mantendo a troca de mapas como troca real de scene.
//

import SpriteKit

final class BirthWatersGameScene: GameScene {
    override class var defaultRegionId: String? { "nascente" }
}

final class CalmGardenGameScene: GameScene {
    override class var defaultRegionId: String? { "jardim_calmo" }
}

final class EmeraldReefGameScene: GameScene {
    override class var defaultRegionId: String? { "recife" }
}

final class GreatDeltaGameScene: GameScene {
    override class var defaultRegionId: String? { "delta" }
}

final class OpenBlueSeaGameScene: GameScene {
    override class var defaultRegionId: String? { "mar_azul_aberto" }
}

final class CaveMouthGameScene: GameScene {
    override class var defaultRegionId: String? { "cavernas" }
}

final class CrystalFieldsGameScene: GameScene {
    override class var defaultRegionId: String? { "campos_cristal" }
}

final class AncientRuinsGameScene: GameScene {
    override class var defaultRegionId: String? { "ruinas" }
}

final class LivingAbyssGameScene: GameScene {
    override class var defaultRegionId: String? { "abismo_vivo" }
}

final class DistantSurfaceGameScene: GameScene {
    override class var defaultRegionId: String? { "superficie_distante" }
}

enum MapSceneFactory {
    static func sceneForSavedMap(size: CGSize) -> GameScene {
        let stats = MermaidStats.load()
        return scene(for: stats.currentRegionId, size: size, announceArrival: false)
    }

    static func scene(for regionId: String, size: CGSize, announceArrival: Bool = false) -> GameScene {
        let scene: GameScene
        switch regionId {
        case "nascente":
            scene = BirthWatersGameScene(size: size)
        case "jardim_calmo":
            scene = CalmGardenGameScene(size: size)
        case "recife":
            scene = EmeraldReefGameScene(size: size)
        case "delta":
            scene = GreatDeltaGameScene(size: size)
        case "mar_azul_aberto":
            scene = OpenBlueSeaGameScene(size: size)
        case "cavernas":
            scene = CaveMouthGameScene(size: size)
        case "campos_cristal":
            scene = CrystalFieldsGameScene(size: size)
        case "ruinas":
            scene = AncientRuinsGameScene(size: size)
        case "abismo_vivo":
            scene = LivingAbyssGameScene(size: size)
        case "superficie_distante":
            scene = DistantSurfaceGameScene(size: size)
        default:
            scene = GameScene(size: size, regionId: regionId)
        }
        scene.shouldAnnounceArrival = announceArrival
        return scene
    }
}
