//
//  TransformComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class TransformComponent: GKComponent {
    var position: CGPoint
    var rotation: CGFloat
    var scale: CGFloat

    init(position: CGPoint = .zero, rotation: CGFloat = 0, scale: CGFloat = 1) {
        self.position = position
        self.rotation = rotation
        self.scale = scale
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
