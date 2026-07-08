//
//  VelocityComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class VelocityComponent: GKComponent {
    var dx: CGFloat
    var dy: CGFloat

    init(dx: CGFloat = 0, dy: CGFloat = 0) {
        self.dx = dx
        self.dy = dy
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
