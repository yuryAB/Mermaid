//
//  NodeComponent.swift
//  Ester
//
//  GKComponent wrapper genérico para qualquer SKNode.
//  Substitui o antigo BaseSpriteComponent.
//

import GameplayKit
import SpriteKit

final class NodeComponent: GKComponent {
    let node: SKNode

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        super.didAddToEntity()
        node.entity = entity
    }

    override func willRemoveFromEntity() {
        super.willRemoveFromEntity()
        node.entity = nil
    }
}
