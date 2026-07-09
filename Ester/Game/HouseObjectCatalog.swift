//
//  HouseObjectCatalog.swift
//  Ester
//
//  Gameplay catalog for purchasable Mermaid House objects.
//

import Foundation
import SpriteKit
import UIKit

enum HouseObjectCatalog {
    static let mermaidSideboardID = "mermaid_sideboard"
    static let mermaidBirthdayTableID = "mermaid_birthday_table"
    static let mermaidBirthdayWallArtID = "mermaid_birthday_wall_art"
    static let mermaidShellMirrorID = "mermaid_shell_mirror"
    static let mermaidPearlClockID = "mermaid_pearl_clock"
    static let mermaidSeaMapFrameID = "mermaid_sea_map_frame"
    static let mermaidCoralWallShelfID = "mermaid_coral_wall_shelf"
    static let mermaidStarfishGarlandID = "mermaid_starfish_garland"
    static let mermaidJellyfishSconceID = "mermaid_jellyfish_sconce"
    static let mermaidWaveTapestryID = "mermaid_wave_tapestry"

    private struct FloorFurnitureSpec {
        let id: String
        let name: String
        let displayName: String
        let assetName: String
        let defaultSize: CGSize
        let roomWidthFraction: CGFloat
    }

    private struct WallDecorationSpec {
        let id: String
        let name: String
        let displayName: String
        let assetName: String
        let defaultSize: CGSize
        let roomWidthFraction: CGFloat
    }

    private static let floorPlacementRules = [
        HouseObjectPlacementRule(
            surfaceCompatibilities: [
                HouseObjectSurfaceCompatibility(supportedSurfaces: [.floor],
                                                attachmentSide: .bottom)
            ],
            allowsFreePositioning: true,
            preferredZLayer: HouseObjectPlacementResolver.defaultZLayer(for: .floor)
        )
    ]

    private static let backWallPlacementRules = [
        HouseObjectPlacementRule(
            surfaceCompatibilities: [
                HouseObjectSurfaceCompatibility(supportedSurfaces: [.backWall],
                                                attachmentSide: .back)
            ],
            allowsFreePositioning: true,
            preferredZLayer: HouseObjectPlacementResolver.defaultZLayer(for: .backWall)
        )
    ]

    private static let floorFurnitureSpecs: [FloorFurnitureSpec] = [
        FloorFurnitureSpec(id: mermaidSideboardID,
                           name: "Mermaid Sideboard",
                           displayName: "Aparador sereia",
                           assetName: "MermaidSideboard",
                           defaultSize: CGSize(width: 120, height: 80),
                           roomWidthFraction: 0.28),
        FloorFurnitureSpec(id: "mermaid_dresser",
                           name: "Mermaid Dresser",
                           displayName: "Cômoda sereia",
                           assetName: "MermaidDresser",
                           defaultSize: CGSize(width: 115, height: 100),
                           roomWidthFraction: 0.27),
        FloorFurnitureSpec(id: "mermaid_low_bookcase",
                           name: "Mermaid Low Bookcase",
                           displayName: "Estante baixa",
                           assetName: "MermaidLowBookcase",
                           defaultSize: CGSize(width: 130, height: 92),
                           roomWidthFraction: 0.32),
        FloorFurnitureSpec(id: "mermaid_nightstand",
                           name: "Mermaid Nightstand",
                           displayName: "Criado-mudo sereia",
                           assetName: "MermaidNightstand",
                           defaultSize: CGSize(width: 80, height: 90),
                           roomWidthFraction: 0.18),
        FloorFurnitureSpec(id: "mermaid_wooden_bench",
                           name: "Mermaid Wooden Bench",
                           displayName: "Banco de madeira",
                           assetName: "MermaidWoodenBench",
                           defaultSize: CGSize(width: 128, height: 92),
                           roomWidthFraction: 0.30),
        FloorFurnitureSpec(id: "mermaid_coral_pouf",
                           name: "Mermaid Coral Pouf",
                           displayName: "Puff de coral",
                           assetName: "MermaidCoralPouf",
                           defaultSize: CGSize(width: 95, height: 94),
                           roomWidthFraction: 0.20),
        FloorFurnitureSpec(id: "mermaid_decorative_chest",
                           name: "Mermaid Decorative Chest",
                           displayName: "Baú decorativo",
                           assetName: "MermaidDecorativeChest",
                           defaultSize: CGSize(width: 115, height: 98),
                           roomWidthFraction: 0.27),
        FloorFurnitureSpec(id: "mermaid_shell_coat_rack",
                           name: "Mermaid Shell Coat Rack",
                           displayName: "Cabideiro de conchas",
                           assetName: "MermaidShellCoatRack",
                           defaultSize: CGSize(width: 58, height: 110),
                           roomWidthFraction: 0.14),
        FloorFurnitureSpec(id: "mermaid_coffee_table",
                           name: "Mermaid Coffee Table",
                           displayName: "Mesa de centro",
                           assetName: "MermaidCoffeeTable",
                           defaultSize: CGSize(width: 125, height: 82),
                           roomWidthFraction: 0.29),
        FloorFurnitureSpec(id: mermaidBirthdayTableID,
                           name: "Mermaid Birthday Table",
                           displayName: "Mesa feliz aniversário",
                           assetName: "MermaidBirthdayTable",
                           defaultSize: CGSize(width: 132, height: 121),
                           roomWidthFraction: 0.34),
        FloorFurnitureSpec(id: "mermaid_large_seaweed_vase",
                           name: "Mermaid Large Seaweed Vase",
                           displayName: "Vaso grande com alga",
                           assetName: "MermaidLargeSeaweedVase",
                           defaultSize: CGSize(width: 68, height: 90),
                           roomWidthFraction: 0.16),
        FloorFurnitureSpec(id: "mermaid_coral_vase",
                           name: "Mermaid Coral Vase",
                           displayName: "Vaso com coral",
                           assetName: "MermaidCoralVase",
                           defaultSize: CGSize(width: 78, height: 90),
                           roomWidthFraction: 0.18),
        FloorFurnitureSpec(id: "mermaid_stone_sculpture",
                           name: "Mermaid Stone Sculpture",
                           displayName: "Escultura de pedra",
                           assetName: "MermaidStoneSculpture",
                           defaultSize: CGSize(width: 90, height: 100),
                           roomWidthFraction: 0.20),
        FloorFurnitureSpec(id: "mermaid_ancient_amphora",
                           name: "Mermaid Ancient Amphora",
                           displayName: "Ânfora antiga",
                           assetName: "MermaidAncientAmphora",
                           defaultSize: CGSize(width: 70, height: 100),
                           roomWidthFraction: 0.16),
        FloorFurnitureSpec(id: "mermaid_book_stack",
                           name: "Mermaid Book Stack",
                           displayName: "Pilha de livros",
                           assetName: "MermaidBookStack",
                           defaultSize: CGSize(width: 82, height: 95),
                           roomWidthFraction: 0.19),
        FloorFurnitureSpec(id: "mermaid_marine_globe",
                           name: "Mermaid Marine Globe",
                           displayName: "Globo marinho",
                           assetName: "MermaidMarineGlobe",
                           defaultSize: CGSize(width: 78, height: 96),
                           roomWidthFraction: 0.18),
        FloorFurnitureSpec(id: "mermaid_shell_basket",
                           name: "Mermaid Shell Basket",
                           displayName: "Cesta de conchas",
                           assetName: "MermaidShellBasket",
                           defaultSize: CGSize(width: 95, height: 84),
                           roomWidthFraction: 0.22),
        FloorFurnitureSpec(id: "mermaid_pearl_stand",
                           name: "Mermaid Pearl Stand",
                           displayName: "Suporte com pérolas",
                           assetName: "MermaidPearlStand",
                           defaultSize: CGSize(width: 74, height: 90),
                           roomWidthFraction: 0.17),
        FloorFurnitureSpec(id: "mermaid_sea_lyre",
                           name: "Mermaid Sea Lyre",
                           displayName: "Lira marinha",
                           assetName: "MermaidSeaLyre",
                           defaultSize: CGSize(width: 74, height: 98),
                           roomWidthFraction: 0.17),
        FloorFurnitureSpec(id: "mermaid_ornamental_aquarium",
                           name: "Mermaid Ornamental Aquarium",
                           displayName: "Aquário ornamental",
                           assetName: "MermaidOrnamentalAquarium",
                           defaultSize: CGSize(width: 105, height: 120),
                           roomWidthFraction: 0.24),
        FloorFurnitureSpec(id: "mermaid_small_statue",
                           name: "Mermaid Small Statue",
                           displayName: "Estátua pequena",
                           assetName: "MermaidSmallStatue",
                           defaultSize: CGSize(width: 52, height: 100),
                           roomWidthFraction: 0.12)
    ]

    private static let wallDecorationSpecs: [WallDecorationSpec] = [
        WallDecorationSpec(id: mermaidBirthdayWallArtID,
                           name: "Birthday Wall Art",
                           displayName: "Quadro feliz aniversário",
                           assetName: "MermaidBirthdayWallArt",
                           defaultSize: CGSize(width: 118, height: 118),
                           roomWidthFraction: 0.48),
        WallDecorationSpec(id: mermaidShellMirrorID,
                           name: "Shell Mirror",
                           displayName: "Espelho de concha",
                           assetName: "MermaidShellMirror",
                           defaultSize: CGSize(width: 92, height: 109),
                           roomWidthFraction: 0.38),
        WallDecorationSpec(id: mermaidPearlClockID,
                           name: "Pearl Clock",
                           displayName: "Relógio de pérolas",
                           assetName: "MermaidPearlClock",
                           defaultSize: CGSize(width: 88, height: 103),
                           roomWidthFraction: 0.34),
        WallDecorationSpec(id: mermaidSeaMapFrameID,
                           name: "Sea Map Frame",
                           displayName: "Mapa dos mares",
                           assetName: "MermaidSeaMapFrame",
                           defaultSize: CGSize(width: 128, height: 94),
                           roomWidthFraction: 0.54),
        WallDecorationSpec(id: mermaidCoralWallShelfID,
                           name: "Coral Wall Shelf",
                           displayName: "Prateleira coral",
                           assetName: "MermaidCoralWallShelf",
                           defaultSize: CGSize(width: 145, height: 42),
                           roomWidthFraction: 0.62),
        WallDecorationSpec(id: mermaidStarfishGarlandID,
                           name: "Starfish Garland",
                           displayName: "Guirlanda de estrelas",
                           assetName: "MermaidStarfishGarland",
                           defaultSize: CGSize(width: 146, height: 55),
                           roomWidthFraction: 0.62),
        WallDecorationSpec(id: mermaidJellyfishSconceID,
                           name: "Jellyfish Sconce",
                           displayName: "Arandela medusa",
                           assetName: "MermaidJellyfishSconce",
                           defaultSize: CGSize(width: 61, height: 128),
                           roomWidthFraction: 0.24),
        WallDecorationSpec(id: mermaidWaveTapestryID,
                           name: "Wave Tapestry",
                           displayName: "Tapeçaria de ondas",
                           assetName: "MermaidWaveTapestry",
                           defaultSize: CGSize(width: 79, height: 121),
                           roomWidthFraction: 0.32)
    ]

    private static let floorDefinitions: [HouseObjectDefinition] = floorFurnitureSpecs.map { spec in
        HouseObjectDefinition(
            id: spec.id,
            name: spec.name,
            displayName: spec.displayName,
            assetName: spec.assetName,
            category: .floorFurniture,
            placementRules: floorPlacementRules,
            defaultSize: spec.defaultSize
        )
    }

    private static let wallDefinitions: [HouseObjectDefinition] = wallDecorationSpecs.map { spec in
        HouseObjectDefinition(
            id: spec.id,
            name: spec.name,
            displayName: spec.displayName,
            assetName: spec.assetName,
            category: .backWallDecoration,
            placementRules: backWallPlacementRules,
            defaultSize: spec.defaultSize
        )
    }

    static let allDefinitions: [HouseObjectDefinition] = floorDefinitions + wallDefinitions

    static var shopDefinitions: [HouseObjectDefinition] {
        allDefinitions
    }

    static func definition(id: String) -> HouseObjectDefinition? {
        allDefinitions.first { $0.id == id }
    }

    static func inventoryItemID(_ definitionID: String) -> String {
        "house_object_\(definitionID)"
    }

    static func inventoryCount(for definitionID: String, stats: MermaidStats) -> Int {
        stats.inventoryCount(for: inventoryItemID(definitionID))
    }

    static func definition(_ definition: HouseObjectDefinition,
                           scaledFor roomSize: CGSize) -> HouseObjectDefinition {
        if let spec = floorFurnitureSpecs.first(where: { $0.id == definition.id }) {
            return scaledDefinition(definition,
                                    defaultSize: spec.defaultSize,
                                    roomWidthFraction: spec.roomWidthFraction,
                                    roomSize: roomSize)
        }
        if let spec = wallDecorationSpecs.first(where: { $0.id == definition.id }) {
            return scaledDefinition(definition,
                                    defaultSize: spec.defaultSize,
                                    roomWidthFraction: spec.roomWidthFraction,
                                    roomSize: roomSize)
        }
        return definition
    }

    private static func scaledDefinition(_ definition: HouseObjectDefinition,
                                         defaultSize: CGSize,
                                         roomWidthFraction: CGFloat,
                                         roomSize: CGSize) -> HouseObjectDefinition {
        guard defaultSize.width > 0 else {
            return definition
        }
        let width = roomSize.width * roomWidthFraction
        let height = width * (defaultSize.height / defaultSize.width)
        return HouseObjectDefinition(
            id: definition.id,
            name: definition.name,
            displayName: definition.displayName,
            assetName: definition.assetName,
            category: definition.category,
            placementRules: definition.placementRules,
            defaultSize: CGSize(width: width, height: height),
            isInteractive: definition.isInteractive,
            needsPhysics: definition.needsPhysics,
            placementOffset: definition.placementOffset
        )
    }
}
