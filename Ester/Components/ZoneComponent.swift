//
//  ZoneComponent.swift
//  Ester
//

import GameplayKit

final class ZoneComponent: GKComponent {
    var zone: DepthZone

    init(zone: DepthZone) {
        self.zone = zone
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
