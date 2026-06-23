//
//  RegistroFlowController.swift
//  Ester
//
//  Dono do fluxo modal do Registro: abertura, fechamento e bloqueio do mundo.
//

import SpriteKit
import UIKit

final class RegistroFlowController {
    private weak var cameraNode: SKNode?
    private weak var hud: HUDLayer?
    private let stats: MermaidStats
    private let sizeProvider: () -> CGSize
    private let insetsProvider: () -> UIEdgeInsets
    private let isAutonomyPaused: () -> Bool
    private let setAutonomyPaused: (Bool) -> Void

    private var overlay: RegistroOverlay?
    private var pausedAutonomyWasPaused = false

    var isOpen: Bool {
        overlay != nil
    }

    init(cameraNode: SKNode,
         hud: HUDLayer,
         stats: MermaidStats,
         sizeProvider: @escaping () -> CGSize,
         insetsProvider: @escaping () -> UIEdgeInsets,
         isAutonomyPaused: @escaping () -> Bool,
         setAutonomyPaused: @escaping (Bool) -> Void) {
        self.cameraNode = cameraNode
        self.hud = hud
        self.stats = stats
        self.sizeProvider = sizeProvider
        self.insetsProvider = insetsProvider
        self.isAutonomyPaused = isAutonomyPaused
        self.setAutonomyPaused = setAutonomyPaused
    }

    func open(playSound: Bool = true) {
        guard overlay == nil,
              let cameraNode else { return }
        if playSound {
            GameAudio.shared.play(.uiOpenPanel)
        }
        pausedAutonomyWasPaused = isAutonomyPaused()
        setAutonomyPaused(true)
        hud?.isUserInteractionEnabled = false

        let registro = RegistroOverlay(size: sizeProvider(),
                                       insets: insetsProvider(),
                                       stats: stats,
                                       onClose: { [weak self] in
                                           self?.close()
                                       })
        registro.zPosition = 190
        cameraNode.addChild(registro)
        overlay = registro
    }

    func close(playSound: Bool = true) {
        guard let overlay else { return }
        if playSound {
            GameAudio.shared.play(.uiClosePanel)
        }
        overlay.removeFromParent()
        self.overlay = nil
        setAutonomyPaused(pausedAutonomyWasPaused)
        hud?.isUserInteractionEnabled = true
    }
}
