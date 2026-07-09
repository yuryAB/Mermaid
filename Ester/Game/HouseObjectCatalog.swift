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

    static let allDefinitions: [HouseObjectDefinition] = [
        HouseObjectDefinition(
            id: mermaidSideboardID,
            name: "Mermaid Sideboard",
            displayName: "Aparador sereia",
            assetName: "MermaidSideboard",
            category: .floorFurniture,
            placementRules: [
                HouseObjectPlacementRule(
                    surfaceCompatibilities: [
                        HouseObjectSurfaceCompatibility(supportedSurfaces: [.floor],
                                                        attachmentSide: .bottom)
                    ],
                    allowsFreePositioning: true,
                    preferredZLayer: HouseObjectPlacementResolver.defaultZLayer(for: .floor)
                )
            ],
            defaultSize: CGSize(width: 120, height: 80)
        )
    ]

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
        guard definition.id == mermaidSideboardID else { return definition }
        let width = roomSize.width * 0.55
        let height = width * (2.0 / 3.0)
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
