//
//  IntentComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class IntentComponent: GKComponent {
    var intent: MermaidIntent = .idle
    var target: CGPoint?
    var velocity: CGVector = CGVector(dx: 0, dy: 0)
    var drift: CGVector = CGVector(dx: 0, dy: 0)

    init(intent: MermaidIntent = .idle) {
        self.intent = intent
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
