//
//  FoodComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class FoodComponent: GKComponent {
    let kind: FoodKind
    var isConsumed: Bool = false

    init(kind: FoodKind) {
        self.kind = kind
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
