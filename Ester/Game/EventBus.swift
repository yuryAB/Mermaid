//
//  EventBus.swift
//  Ester
//

import Foundation
import GameplayKit

protocol GameEvent {}

struct FoodCollectedEvent: GameEvent {
    let entity: GKEntity
    let foodKind: FoodKind
}

struct ChallengeCompletedEvent: GameEvent {
    let kind: ChallengeKind
    let result: ChallengeResult
}

struct RegionDiscoveredEvent: GameEvent {
    let region: Region
}

struct ZoneChangedEvent: GameEvent {
    let zone: DepthZone
}

struct MermaidStateChangedEvent: GameEvent {
    let emotionalState: MermaidEmotionalState
}

final class EventBus {
    static let shared = EventBus()

    private var handlers: [ObjectIdentifier: [(Any) -> Void]] = [:]
    private let queue = DispatchQueue(label: "com.ester.eventbus", attributes: .concurrent)

    func subscribe<T: GameEvent>(_ handler: @escaping (T) -> Void) -> NSObjectProtocol {
        let token = NSObject()
        let key = ObjectIdentifier(T.self)
        queue.async(flags: .barrier) {
            self.handlers[key, default: []].append { event in
                if let typed = event as? T {
                    handler(typed)
                }
            }
        }
        return token
    }

    func post<T: GameEvent>(_ event: T) {
        let key = ObjectIdentifier(T.self)
        queue.sync {
            guard let eventHandlers = handlers[key] else { return }
            for handler in eventHandlers {
                handler(event)
            }
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.handlers.removeAll()
        }
    }
}
