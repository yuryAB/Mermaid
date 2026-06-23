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
        switch RegionDiscoverySystem.canonicalRegionId(regionId) {
        case "recife_tropical":
            scene = BirthWatersGameScene(size: size)
        case "floresta_kelp":
            scene = CalmGardenGameScene(size: size)
        case "manguezal":
            scene = EmeraldReefGameScene(size: size)
        case "estuario":
            scene = GreatDeltaGameScene(size: size)
        case "mar_aberto_tropical":
            scene = OpenBlueSeaGameScene(size: size)
        case "mar_aberto_temperado":
            scene = CaveMouthGameScene(size: size)
        case "rio_amazonico":
            scene = CrystalFieldsGameScene(size: size)
        case "oceano_profundo":
            scene = AncientRuinsGameScene(size: size)
        case "zona_abissal":
            scene = LivingAbyssGameScene(size: size)
        case "regiao_polar":
            scene = DistantSurfaceGameScene(size: size)
        default:
            scene = GameScene(size: size, regionId: regionId)
        }
        scene.shouldAnnounceArrival = announceArrival
        return scene
    }
}
