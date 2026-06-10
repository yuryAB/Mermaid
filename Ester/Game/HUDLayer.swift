//
//  HUDLayer.swift
//  Ester
//
//  Interface do cuidador: painel de status agrupado (fase, profundidade,
//  pérolas e barras), bolha de mensagens, chip de intenção e botões de
//  comando com SF Symbols. Respeita as safe areas (Dynamic Island).
//

import Foundation
import SpriteKit

final class HUDLayer: SKNode {
    var onCommand: ((PlayerCommand) -> Void)?
    var onDebugRigToolTap: (() -> Void)?

    private let sceneSize: CGSize
    private let insets: UIEdgeInsets

    private var phaseLabel: SKLabelNode!
    private var depthLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var storedFoodLabel: SKLabelNode!
    private var intentLabel: SKLabelNode!
    private var bars: [String: SKShapeNode] = [:]
    private var buttons: [PlayerCommand: SKNode] = [:]
    private var messageContainer: SKNode!
    private var messageLabel: SKLabelNode!
    private var lastEggMode = false
    private let enableDebugRigToolButton: Bool
    private var debugRigToolButton: SKNode?

    init(size: CGSize, insets: UIEdgeInsets, enableDebugRigToolButton: Bool = false) {
        self.sceneSize = size
        self.insets = insets
        self.enableDebugRigToolButton = enableDebugRigToolButton
        super.init()
        isUserInteractionEnabled = true
        buildTopPanel()
        buildMessageBubble()
        buildIntentChip()
        buildButtons()
        buildDebugRigToolButton()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - SF Symbols (com fallback para emoji)

    private static func symbolNode(_ name: String,
                                   fallback: String,
                                   pointSize: CGFloat,
                                   color: UIColor) -> SKNode {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        if let image = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) {
            let renderer = UIGraphicsImageRenderer(size: image.size)
            let flattened = renderer.image { _ in image.draw(at: .zero) }
            let sprite = SKSpriteNode(texture: SKTexture(image: flattened))
            sprite.size = image.size
            return sprite
        }
        let label = SKLabelNode(text: fallback)
        label.fontSize = pointSize
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }

    private func makeLabel(fontSize: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontName = bold ? "Helvetica-Bold" : "Helvetica"
        label.fontSize = fontSize
        label.fontColor = .white
        return label
    }

    // MARK: - Painel superior

    private func buildTopPanel() {
        let panelWidth = sceneSize.width - 24
        let panelHeight: CGFloat = 122
        let topEdge = sceneSize.height / 2 - insets.top

        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight),
                                cornerRadius: 18)
        panel.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.14, alpha: 0.45)
        panel.strokeColor = UIColor(white: 1, alpha: 0.18)
        panel.lineWidth = 1
        // margem extra para ficar confortavelmente abaixo da Dynamic Island
        panel.position = CGPoint(x: 0, y: topEdge - 20 - panelHeight / 2)
        addChild(panel)

        let halfW = panelWidth / 2
        let row1Y = panelHeight / 2 - 24
        let row2Y = panelHeight / 2 - 47

        phaseLabel = makeLabel(fontSize: 15, bold: true)
        phaseLabel.horizontalAlignmentMode = .left
        phaseLabel.verticalAlignmentMode = .center
        phaseLabel.position = CGPoint(x: -halfW + 14, y: row1Y)
        panel.addChild(phaseLabel)

        let pearlIcon = HUDLayer.symbolNode("sparkles", fallback: "💠", pointSize: 13,
                                            color: UIColor(red: 0.7, green: 0.88, blue: 1, alpha: 1))
        pearlIcon.position = CGPoint(x: halfW - 92, y: row1Y)
        panel.addChild(pearlIcon)

        pearlsLabel = makeLabel(fontSize: 14, bold: true)
        pearlsLabel.horizontalAlignmentMode = .left
        pearlsLabel.verticalAlignmentMode = .center
        pearlsLabel.position = CGPoint(x: halfW - 78, y: row1Y)
        panel.addChild(pearlsLabel)

        depthLabel = makeLabel(fontSize: 12)
        depthLabel.fontColor = UIColor(white: 1, alpha: 0.75)
        depthLabel.horizontalAlignmentMode = .left
        depthLabel.verticalAlignmentMode = .center
        depthLabel.position = CGPoint(x: -halfW + 14, y: row2Y)
        panel.addChild(depthLabel)

        storedFoodLabel = makeLabel(fontSize: 12)
        storedFoodLabel.fontColor = UIColor(white: 1, alpha: 0.7)
        storedFoodLabel.horizontalAlignmentMode = .right
        storedFoodLabel.verticalAlignmentMode = .center
        storedFoodLabel.position = CGPoint(x: halfW - 14, y: row2Y)
        panel.addChild(storedFoodLabel)

        // barras em duas colunas
        let barConfigs: [(key: String, symbol: String, fallback: String, color: UIColor, column: Int, row: Int)] = [
            ("satiety", "fork.knife", "🍽", UIColor(red: 0.95, green: 0.6, blue: 0.3, alpha: 1), 0, 0),
            ("energy", "bolt.fill", "⚡️", UIColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1), 1, 0),
            ("mood", "face.smiling", "😊", UIColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 1), 0, 1),
            ("evolution", "star.fill", "⭐️", UIColor(red: 0.6, green: 0.75, blue: 1, alpha: 1), 1, 1)
        ]
        let barWidth = panelWidth / 2 - 52
        let barHeight: CGFloat = 9

        for config in barConfigs {
            let y = -panelHeight / 2 + 40 - CGFloat(config.row) * 24
            let iconX: CGFloat = config.column == 0 ? -halfW + 22 : 14
            let barX: CGFloat = config.column == 0 ? -halfW + 40 : 32

            let icon = HUDLayer.symbolNode(config.symbol, fallback: config.fallback,
                                           pointSize: 11, color: config.color)
            icon.position = CGPoint(x: iconX, y: y)
            panel.addChild(icon)

            let bg = SKShapeNode(rect: CGRect(x: 0, y: -barHeight / 2, width: barWidth, height: barHeight),
                                 cornerRadius: barHeight / 2)
            bg.fillColor = UIColor(white: 0, alpha: 0.4)
            bg.strokeColor = UIColor(white: 1, alpha: 0.22)
            bg.position = CGPoint(x: barX, y: y)
            panel.addChild(bg)

            let fill = SKShapeNode(rect: CGRect(x: 0, y: -barHeight / 2 + 1.5, width: barWidth - 3, height: barHeight - 3),
                                   cornerRadius: (barHeight - 3) / 2)
            fill.fillColor = config.color
            fill.strokeColor = .clear
            fill.position = CGPoint(x: 1.5, y: 0)
            bg.addChild(fill)
            bars[config.key] = fill
        }
    }

    // MARK: - Mensagens

    private func buildMessageBubble() {
        let topEdge = sceneSize.height / 2 - insets.top
        messageContainer = SKNode()
        messageContainer.position = CGPoint(x: 0, y: topEdge - 20 - 122 - 36)
        messageContainer.alpha = 0
        messageContainer.zPosition = 5
        addChild(messageContainer)

        let bubble = SKShapeNode(rectOf: CGSize(width: sceneSize.width - 56, height: 48), cornerRadius: 14)
        bubble.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.14, alpha: 0.62)
        bubble.strokeColor = UIColor(white: 1, alpha: 0.32)
        messageContainer.addChild(bubble)

        messageLabel = makeLabel(fontSize: 13)
        messageLabel.verticalAlignmentMode = .center
        messageLabel.preferredMaxLayoutWidth = sceneSize.width - 88
        messageLabel.numberOfLines = 2
        messageContainer.addChild(messageLabel)
    }

    func showMessage(_ text: String, duration: TimeInterval = 0) {
        let holdTime = duration > 0 ? duration : max(3.0, Double(text.count) * 0.07)
        messageLabel.text = text
        messageContainer.removeAllActions()
        messageContainer.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: holdTime),
            .fadeOut(withDuration: 0.5)
        ]))
    }

    // MARK: - Chip de intenção

    private var intentChip: SKShapeNode!

    private func buildIntentChip() {
        let chipY = buttonRowY(0) + 50
        intentChip = SKShapeNode(rectOf: CGSize(width: 250, height: 26), cornerRadius: 13)
        intentChip.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.14, alpha: 0.4)
        intentChip.strokeColor = UIColor(white: 1, alpha: 0.18)
        intentChip.position = CGPoint(x: 0, y: chipY)
        addChild(intentChip)

        intentLabel = makeLabel(fontSize: 12)
        intentLabel.fontColor = UIColor(white: 1, alpha: 0.9)
        intentLabel.verticalAlignmentMode = .center
        intentChip.addChild(intentLabel)
    }

    // MARK: - Botões de comando

    private func buttonRowY(_ row: Int) -> CGFloat {
        -sceneSize.height / 2 + insets.bottom + 134 - CGFloat(row) * 62
    }

    private func buildButtons() {
        let commands: [[PlayerCommand]] = [
            [.explore, .seekFood, .tideWeave, .rest],
            [.goUp, .goDown, .travel, .refuge]
        ]
        let buttonWidth = (sceneSize.width - 60) / 4
        let buttonHeight: CGFloat = 54

        for (rowIndex, row) in commands.enumerated() {
            let y = buttonRowY(rowIndex)
            for (columnIndex, command) in row.enumerated() {
                let x = -sceneSize.width / 2 + 18 + buttonWidth / 2 + CGFloat(columnIndex) * (buttonWidth + 8)
                let button = SKNode()
                button.name = "cmd_\(command.rawValue)"
                button.position = CGPoint(x: x, y: y)

                let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight),
                                     cornerRadius: 14)
                bg.fillColor = UIColor(red: 0.02, green: 0.07, blue: 0.14, alpha: 0.5)
                bg.strokeColor = command.tint.withAlphaComponent(0.55)
                bg.lineWidth = 1.5
                bg.name = button.name
                button.addChild(bg)

                let icon = HUDLayer.symbolNode(command.symbolName, fallback: command.icon,
                                               pointSize: 17, color: command.tint)
                icon.position = CGPoint(x: 0, y: 8)
                icon.name = button.name
                button.addChild(icon)

                let text = makeLabel(fontSize: 10)
                text.text = command.label
                text.fontColor = UIColor(white: 1, alpha: 0.92)
                text.position = CGPoint(x: 0, y: -19)
                text.name = button.name
                button.addChild(text)

                addChild(button)
                buttons[command] = button
            }
        }
    }

    private func buildDebugRigToolButton() {
        guard enableDebugRigToolButton else { return }
        let button = SKNode()
        button.name = "cmd_debug_rig_tool"
        button.position = CGPoint(
            x: -sceneSize.width / 2 + 36 + insets.left,
            y: 0
        )

        let background = SKShapeNode(circleOfRadius: 30)
        background.fillColor = UIColor(red: 0.08, green: 0.16, blue: 0.26, alpha: 0.78)
        background.strokeColor = UIColor(red: 0.9, green: 0.95, blue: 1, alpha: 0.8)
        background.lineWidth = 1.8
        background.name = button.name
        button.addChild(background)

        let icon = HUDLayer.symbolNode("arrow.clockwise.circle.fill",
                                      fallback: "↻",
                                      pointSize: 20,
                                      color: UIColor(red: 0.95, green: 0.95, blue: 1, alpha: 0.95))
        icon.position = CGPoint(x: 0, y: 1)
        icon.name = button.name
        button.addChild(icon)

        let text = makeLabel(fontSize: 10)
        text.text = "rig"
        text.position = CGPoint(x: 0, y: -34)
        text.fontColor = UIColor(white: 1, alpha: 0.9)
        text.name = button.name
        button.addChild(text)

        addChild(button)
        debugRigToolButton = button
    }

    // MARK: - Atualização

    func refresh(stats: MermaidStats,
                 intent: MermaidIntent,
                 zone: DepthZone,
                 regionName: String?,
                 evolutionProgress: CGFloat,
                 shelterCapacity: Int) {
        let eggMode = stats.phase == .egg

        if eggMode {
            phaseLabel.text = "Ovo · \(Int(evolutionProgress * 100))% chocado"
            intentLabel.text = "reunindo energia de nascimento..."
        } else {
            phaseLabel.text = "\(stats.phase.displayName) · \(stats.ageText)"
            intentLabel.text = "• \(intent.displayName)"
        }
        if let regionName {
            depthLabel.text = "\(regionName) · \(zone.displayName)"
        } else {
            depthLabel.text = zone.displayName
        }
        pearlsLabel.text = "\(stats.pearls)"
        storedFoodLabel.text = stats.storedFood > 0 ? "abrigo: \(stats.storedFood)/\(shelterCapacity)" : ""

        setBar("satiety", value: (100 - stats.hunger) / 100)
        setBar("energy", value: stats.energy / 100)
        setBar("mood", value: stats.mood / 100)
        setBar("evolution", value: evolutionProgress)

        // saciedade fica vermelha quando a fome aperta
        if let satiety = bars["satiety"] {
            satiety.fillColor = stats.hunger > 75
                ? UIColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 1)
                : UIColor(red: 0.95, green: 0.6, blue: 0.3, alpha: 1)
        }

        // durante o ovo, só a Trama fica ativa
        if eggMode != lastEggMode {
            lastEggMode = eggMode
            for (command, button) in buttons {
                let active = !eggMode || command == .tideWeave
                button.alpha = active ? 1 : 0.32
            }
        }
    }

    private func setBar(_ key: String, value: CGFloat) {
        bars[key]?.xScale = value.clamped(to: 0.02...1)
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for node in nodes(at: location) {
            if let name = node.name, name.hasPrefix("cmd_"),
               let command = PlayerCommand(rawValue: String(name.dropFirst(4))) {
                flashButton(command)
                onCommand?(command)
                return
            }
            if node.name == "cmd_debug_rig_tool" {
                flashNode(debugRigToolButton)
                onDebugRigToolTap?()
                return
            }
        }
    }

    private func flashButton(_ command: PlayerCommand) {
        buttons[command]?.run(.sequence([
            .scale(to: 0.88, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))
    }

    private func flashNode(_ node: SKNode?) {
        node?.run(.sequence([
            .scale(to: 0.9, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))
    }
}
