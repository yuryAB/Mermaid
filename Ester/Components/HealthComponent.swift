//
//  HealthComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics

final class HealthComponent: GKComponent {
    var hunger: CGFloat
    var energy: CGFloat
    var mood: CGFloat
    var trust: CGFloat

    init(hunger: CGFloat = 25, energy: CGFloat = 85, mood: CGFloat = 70, trust: CGFloat = 50) {
        self.hunger = hunger
        self.energy = energy
        self.mood = mood
        self.trust = trust
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
