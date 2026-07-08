//
//  FishBehaviorComponent.swift
//  Ester
//

import GameplayKit
import CoreGraphics
import UIKit

struct FishSpecies {
    let name: String
    let minSize: CGFloat
    let maxSize: CGFloat
    let speed: CGFloat
    let turnRate: CGFloat
    let colors: [UIColor]
    let finCount: Int
    let glowIntensity: CGFloat
}

enum FishSwimPattern {
    case wander
    case school(leader: GKEntity?)
    case flee
    case guide
}

final class FishBehaviorComponent: GKComponent {
    let species: FishSpecies
    var pattern: FishSwimPattern = .wander
    var wanderTarget: CGPoint = .zero
    var wanderTimer: CGFloat = 0
    var isRare: Bool = false
    var speedMultiplier: CGFloat = 1.0
    var swimPhase: CGFloat = .random(in: 0...(.pi * 2))

    init(species: FishSpecies, isRare: Bool = false) {
        self.species = species
        self.isRare = isRare
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
