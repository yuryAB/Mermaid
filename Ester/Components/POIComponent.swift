//
//  POIComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

enum POIState {
    case dormant
    case active
    case interacting
    case completed
}

final class POIComponent: GKComponent {
    let poiData: WorldPOI
    var state: POIState = .dormant

    init(poi: WorldPOI) {
        self.poiData = poi
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
