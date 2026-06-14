//
//  MapSceneFactory.swift
//  Ester
//

import SpriteKit

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
