//
//  HUDLayer.swift
//  Ester
//
//  Interface do cuidador: barras de fome/energia/humor, fase, idade,
//  profundidade, pérolas, intenção atual e os botões de comando.
//

import Foundation
import SpriteKit

final class HUDLayer: SKNode {
    var onCommand: ((PlayerCommand) -> Void)?

    private let sceneSize: CGSize

    private var phaseLabel: SKLabelNode!
    private var depthLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var intentLabel: SKLabelNode!
    private var storedFoodLabel: SKLabelNode!
    private var bars: [String: SKShapeNode] = [:]
    private var messageContainer: SKNode!
    private var messageLabel: SKLabelNode!

    init(size: CGSize) {
        self.sceneSize = size
        super.init()
        isUserInteractionEnabled = true
        buildTopInfo()
        buildBars()
        buildButtons()
        buildMessageBubble()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Construção

    private func makeLabel(fontSize: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontName = bold ? "Helvetica-Bold" : "Helvetica"
        label.fontSize = fontSize
        label.fontColor = .white
        return label
    }

    private func buildTopInfo() {
        let halfW = sceneSize.width / 2
        let halfH = sceneSize.height / 2

        phaseLabel = makeLabel(fontSize: 15, bold: true)
        phaseLabel.horizontalAlignmentMode = .left
        phaseLabel.position = CGPoint(x: -halfW + 16, y: halfH - 52)
        addChild(phaseLabel)

        depthLabel = makeLabel(fontSize: 15, bold: true)
        depthLabel.horizontalAlignmentMode = .right
        depthLabel.position = CGPoint(x: halfW - 16, y: halfH - 52)
        addChild(depthLabel)

        pearlsLabel = makeLabel(fontSize: 15, bold: true)
        pearlsLabel.horizontalAlignmentMode = .right
        pearlsLabel.position = CGPoint(x: halfW - 16, y: halfH - 78)
        addChild(pearlsLabel)

        storedFoodLabel = makeLabel(fontSize: 13)
        storedFoodLabel.horizontalAlignmentMode = .right
        storedFoodLabel.position = CGPoint(x: halfW - 16, y: halfH - 102)
        addChild(storedFoodLabel)

        intentLabel = makeLabel(fontSize: 14)
        intentLabel.fontColor = UIColor(white: 1, alpha: 0.85)
        intentLabel.position = CGPoint(x: 0, y: -halfH + 152)
        addChild(intentLabel)
    }

    private func buildBars() {
        let barNames: [(key: String, icon: String, color: UIColor)] = [
            ("satiety", "🍽", UIColor(red: 0.95, green: 0.6, blue: 0.3, alpha: 1)),
            ("energy", "⚡️", UIColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1)),
            ("mood", "😊", UIColor(red: 0.45, green: 0.85, blue: 0.55, alpha: 1)),
            ("evolution", "⭐️", UIColor(red: 0.6, green: 0.75, blue: 1, alpha: 1))
        ]
        let halfW = sceneSize.width / 2
        let halfH = sceneSize.height / 2
        let barWidth: CGFloat = 92
        let barHeight: CGFloat = 9

        for (index, info) in barNames.enumerated() {
            let y = halfH - 84 - CGFloat(index) * 23

            let icon = makeLabel(fontSize: 12)
            icon.text = info.icon
            icon.horizontalAlignmentMode = .left
            icon.verticalAlignmentMode = .center
            icon.position = CGPoint(x: -halfW + 16, y: y)
            addChild(icon)

            let bg = SKShapeNode(rect: CGRect(x: 0, y: -barHeight / 2, width: barWidth, height: barHeight),
                                 cornerRadius: barHeight / 2)
            bg.fillColor = UIColor(white: 0, alpha: 0.35)
            bg.strokeColor = UIColor(white: 1, alpha: 0.3)
            bg.position = CGPoint(x: -halfW + 42, y: y)
            addChild(bg)

            let fill = SKShapeNode(rect: CGRect(x: 0, y: -barHeight / 2 + 1.5, width: barWidth - 3, height: barHeight - 3),
                                   cornerRadius: (barHeight - 3) / 2)
            fill.fillColor = info.color
            fill.strokeColor = .clear
            fill.position = CGPoint(x: 1.5, y: 0)
            bg.addChild(fill)
            bars[info.key] = fill
        }
    }

    private func buildButtons() {
        let halfH = sceneSize.height / 2
        let commands: [[PlayerCommand]] = [
            [.explore, .seekFood, .rest, .interact],
            [.goUp, .goDown, .challenge, .goHome]
        ]
        let buttonWidth = (sceneSize.width - 50) / 4
        let buttonHeight: CGFloat = 48

        for (rowIndex, row) in commands.enumerated() {
            let y = -halfH + 110 - CGFloat(rowIndex) * 58
            for (columnIndex, command) in row.enumerated() {
                let x = -sceneSize.width / 2 + 25 + buttonWidth / 2 + CGFloat(columnIndex) * (buttonWidth + 0)
                let button = SKNode()
                button.name = "cmd_\(command.rawValue)"
                button.position = CGPoint(x: x, y: y)

                let bg = SKShapeNode(rectOf: CGSize(width: buttonWidth - 8, height: buttonHeight),
                                     cornerRadius: 12)
                bg.fillColor = UIColor(white: 1, alpha: 0.16)
                bg.strokeColor = UIColor(white: 1, alpha: 0.45)
                bg.name = button.name
                button.addChild(bg)

                let icon = makeLabel(fontSize: 17)
                icon.text = command.icon
                icon.position = CGPoint(x: 0, y: 4)
                icon.name = button.name
                button.addChild(icon)

                let text = makeLabel(fontSize: 10)
                text.text = command.label
                text.position = CGPoint(x: 0, y: -16)
                text.name = button.name
                button.addChild(text)

                addChild(button)
            }
        }
    }

    private func buildMessageBubble() {
        messageContainer = SKNode()
        messageContainer.position = CGPoint(x: 0, y: sceneSize.height / 2 - 180)
        messageContainer.alpha = 0
        messageContainer.zPosition = 5
        addChild(messageContainer)

        let bubble = SKShapeNode(rectOf: CGSize(width: sceneSize.width - 60, height: 46), cornerRadius: 14)
        bubble.fillColor = UIColor(white: 0, alpha: 0.55)
        bubble.strokeColor = UIColor(white: 1, alpha: 0.4)
        messageContainer.addChild(bubble)

        messageLabel = makeLabel(fontSize: 13)
        messageLabel.verticalAlignmentMode = .center
        messageLabel.preferredMaxLayoutWidth = sceneSize.width - 80
        messageLabel.numberOfLines = 2
        messageContainer.addChild(messageLabel)
    }

    // MARK: - Mensagens

    func showMessage(_ text: String, duration: TimeInterval = 3.2) {
        messageLabel.text = text
        messageContainer.removeAllActions()
        messageContainer.run(.sequence([
            .fadeIn(withDuration: 0.2),
            .wait(forDuration: duration),
            .fadeOut(withDuration: 0.5)
        ]))
    }

    // MARK: - Atualização

    func refresh(stats: MermaidStats,
                 intent: MermaidIntent,
                 zone: DepthZone,
                 depthMeters: CGFloat,
                 evolutionProgress: CGFloat,
                 shelterCapacity: Int) {
        phaseLabel.text = "🧜‍♀️ \(stats.phase.displayName) · \(stats.ageText)"
        depthLabel.text = "\(zone.displayName) · \(Int(depthMeters))m"
        pearlsLabel.text = "💠 \(stats.pearls)"
        storedFoodLabel.text = stats.storedFood > 0 ? "🐚 comida: \(stats.storedFood)/\(shelterCapacity)" : ""
        intentLabel.text = "✨ \(intent.displayName)"

        setBar("satiety", value: (100 - stats.hunger) / 100)
        setBar("energy", value: stats.energy / 100)
        setBar("mood", value: stats.mood / 100)
        setBar("evolution", value: evolutionProgress)

        // satisfação fica vermelha quando a fome aperta
        if let satiety = bars["satiety"] {
            satiety.fillColor = stats.hunger > 75
                ? UIColor(red: 0.9, green: 0.25, blue: 0.25, alpha: 1)
                : UIColor(red: 0.95, green: 0.6, blue: 0.3, alpha: 1)
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
                flashButton(named: name)
                onCommand?(command)
                return
            }
        }
    }

    private func flashButton(named name: String) {
        for child in children where child.name == name {
            child.run(.sequence([
                .scale(to: 0.88, duration: 0.08),
                .scale(to: 1.0, duration: 0.12)
            ]))
        }
    }
}
