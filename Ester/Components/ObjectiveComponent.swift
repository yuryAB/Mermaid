//
//  ObjectiveComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class ObjectiveComponent: GKComponent {
    let label: String
    var positionProvider: (() -> CGPoint?)?
    let onReach: (() -> Void)?
    var timeRemaining: CGFloat

    init(label: String,
         positionProvider: (() -> CGPoint?)? = nil,
         onReach: (() -> Void)? = nil,
         timeRemaining: CGFloat) {
        self.label = label
        self.positionProvider = positionProvider
        self.onReach = onReach
        self.timeRemaining = timeRemaining
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        timeRemaining -= CGFloat(seconds)
    }

    var isExpired: Bool { timeRemaining <= 0 }
}
