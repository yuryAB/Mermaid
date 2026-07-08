//
//  ChallengeGiverComponent.swift
//  Ester
//

import GameplayKit

final class ChallengeGiverComponent: GKComponent {
    let challengeKind: ChallengeKind
    let goalRange: ChallengeGoalRange
    var isOffering: Bool = false

    init(kind: ChallengeKind, goalRange: ChallengeGoalRange) {
        self.challengeKind = kind
        self.goalRange = goalRange
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
