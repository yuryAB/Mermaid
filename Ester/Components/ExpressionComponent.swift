//
//  ExpressionComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class ExpressionComponent: GKComponent {
    var currentEmotion: MermaidEmotion = .neutral
    var overrideEmotion: MermaidEmotion?
    var overrideTime: CGFloat = 0
    var blinkTimer: CGFloat = .random(in: 2.8...5.2)
    var blinkTime: CGFloat = 0

    override init() {
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showEmotion(_ emotion: MermaidEmotion, duration: CGFloat) {
        overrideEmotion = emotion
        overrideTime = max(0, duration)
        currentEmotion = emotion
    }
}
