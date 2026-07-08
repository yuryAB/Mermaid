//
//  LifetimeComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class LifetimeComponent: GKComponent {
    var timeToLive: CGFloat
    var isExpired: Bool { timeToLive <= 0 }

    init(timeToLive: CGFloat) {
        self.timeToLive = timeToLive
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        timeToLive -= CGFloat(seconds)
    }
}
