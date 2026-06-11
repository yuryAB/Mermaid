//
//  HUDLayer.swift
//  Ester
//
//  Interface do cuidador em linguagem de diário de campo: ficha de
//  observação, medidores biológicos, notas do ambiente e ações em fichas.
//

import CoreText
import Foundation
import SpriteKit
import UIKit

final class HUDLayer: SKNode {
    var onCommand: ((PlayerCommand) -> Void)?
    var onDebugRigToolTap: (() -> Void)?
    var onNameEditTap: (() -> Void)?

    private let sceneSize: CGSize
    private let insets: UIEdgeInsets

    /// Inset superior efetivo: garante folga mesmo se a safe area vier zerada
    /// no momento da montagem, mantendo a ficha longe da Dynamic Island.
    private var topInset: CGFloat { max(insets.top, 44) }

    private var phaseLabel: SKLabelNode!
    private var titleLabel: SKLabelNode!
    private var depthLabel: SKLabelNode!
    private var growthLabel: SKLabelNode!
    private var pearlsLabel: SKLabelNode!
    private var intentLabel: SKLabelNode!
    private var barLabels: [String: SKLabelNode] = [:]
    private var bars: [String: SKShapeNode] = [:]
    private var buttons: [PlayerCommand: SKNode] = [:]
    private var buttonSizes: [PlayerCommand: CGSize] = [:]
    private var buttonHighlights: [PlayerCommand: SKShapeNode] = [:]
    private var buttonStamps: [PlayerCommand: SKNode] = [:]
    private var buttonCooldownOverlays: [PlayerCommand: SKNode] = [:]
    private var buttonCooldownFills: [PlayerCommand: SKShapeNode] = [:]
    private var buttonCooldownLines: [PlayerCommand: SKShapeNode] = [:]
    private var buttonCooldownLabels: [PlayerCommand: SKLabelNode] = [:]
    private var disabledCommands: Set<PlayerCommand> = []
    private var messageContainer: SKNode!
    private var messageTitleLabel: SKLabelNode!
    private var messageLabel: SKLabelNode!
    private var lastEggMode = false
    private var lastObjectiveAvailable: Bool?
    private let enableDebugRigToolButton: Bool
    private var debugRigToolButton: SKNode?
    private var nameEditButton: SKNode?
    private let commandCooldownAnimationSeconds: TimeInterval = 10

    init(size: CGSize, insets: UIEdgeInsets, enableDebugRigToolButton: Bool = false) {
        self.sceneSize = size
        self.insets = insets
        self.enableDebugRigToolButton = enableDebugRigToolButton
        super.init()
        HUDTypography.registerBundledFonts()
        isUserInteractionEnabled = true
        buildTopPanel()
        buildMessageBubble()
        buildIntentChip()
        buildButtons()
        buildDebugRigToolButton()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Tema

    private enum HUDPalette {
        static let paper = UIColor(red: 0.96, green: 0.93, blue: 0.84, alpha: 1)
        static let palePaper = UIColor(red: 0.92, green: 0.97, blue: 0.95, alpha: 1)
        static let disabledPaper = UIColor(red: 0.82, green: 0.84, blue: 0.80, alpha: 1)
        static let ink = UIColor(red: 0.04, green: 0.15, blue: 0.28, alpha: 1)
        static let mutedInk = UIColor(red: 0.28, green: 0.40, blue: 0.49, alpha: 1)
        static let line = UIColor(red: 0.20, green: 0.40, blue: 0.52, alpha: 1)
        static let aqua = UIColor(red: 0.47, green: 0.78, blue: 0.78, alpha: 1)
        static let teal = UIColor(red: 0.16, green: 0.50, blue: 0.52, alpha: 1)
        static let algae = UIColor(red: 0.33, green: 0.54, blue: 0.30, alpha: 1)
        static let coral = UIColor(red: 0.78, green: 0.34, blue: 0.30, alpha: 1)
        static let gold = UIColor(red: 0.83, green: 0.62, blue: 0.25, alpha: 1)
        static let blueInk = UIColor(red: 0.02, green: 0.24, blue: 0.43, alpha: 1)
    }

    private enum HUDTypography {
        private static var didRegister = false

        static func registerBundledFonts() {
            guard !didRegister else { return }
            didRegister = true
            ["Kalam-Regular", "Kalam-Bold", "Nunito-Regular", "Nunito-Italic"].forEach { name in
                guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { return }
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }

        static var body: String { available("Nunito-Regular", fallback: "AvenirNext-Regular") }
        static var bodyBold: String { available("Nunito-Bold", fallback: "AvenirNext-DemiBold") }
        static var note: String { available("Kalam-Regular", fallback: "MarkerFelt-Thin") }
        static var noteBold: String { available("Kalam-Bold", fallback: "MarkerFelt-Wide") }

        private static func available(_ preferred: String, fallback: String) -> String {
            if UIFont(name: preferred, size: 12) != nil { return preferred }
            if UIFont(name: fallback, size: 12) != nil { return fallback }
            return "Helvetica"
        }
    }

    private enum HUDTexture {
        private static var cache: [String: SKTexture] = [:]

        static func paper(size: CGSize, base: UIColor) -> SKTexture {
            let w = max(1, Int(ceil(size.width)))
            let h = max(1, Int(ceil(size.height)))
            let key = "\(w)x\(h)|\(base.hashValue)"
            if let cached = cache[key] { return cached }

            let image = UIGraphicsImageRenderer(size: CGSize(width: w, height: h)).image { context in
                let cg = context.cgContext
                base.setFill()
                cg.fill(CGRect(x: 0, y: 0, width: w, height: h))

                cg.setStrokeColor(HUDPalette.aqua.withAlphaComponent(0.08).cgColor)
                cg.setLineWidth(1)
                for y in stride(from: CGFloat(14), to: CGFloat(h), by: CGFloat(18)) {
                    cg.move(to: CGPoint(x: 0, y: y))
                    cg.addLine(to: CGPoint(x: CGFloat(w), y: y + 0.8))
                    cg.strokePath()
                }

                for i in 0..<72 {
                    let x = CGFloat((i * 47 + 13) % w)
                    let y = CGFloat((i * 83 + 19) % h)
                    let radius = CGFloat((i % 3) + 1) * 0.55
                    let alpha = i.isMultiple(of: 2) ? 0.035 : 0.02
                    HUDPalette.ink.withAlphaComponent(alpha).setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: radius, height: radius))
                }

                let wash = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [UIColor.white.withAlphaComponent(0.14).cgColor,
                                               HUDPalette.aqua.withAlphaComponent(0.06).cgColor,
                                               UIColor.black.withAlphaComponent(0.03).cgColor] as CFArray,
                                      locations: [0, 0.55, 1])
                if let wash {
                    cg.drawLinearGradient(wash,
                                          start: CGPoint(x: 0, y: 0),
                                          end: CGPoint(x: CGFloat(w), y: CGFloat(h)),
                                          options: [])
                }
            }

            let texture = SKTexture(image: image)
            cache[key] = texture
            return texture
        }
    }

    private enum LabelStyle {
        case body
        case bodyBold
        case note
        case noteBold
    }

    private func makeLabel(text: String = "",
                           fontSize: CGFloat,
                           style: LabelStyle = .body,
                           color: UIColor = HUDPalette.ink) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        switch style {
        case .body:
            label.fontName = HUDTypography.body
        case .bodyBold:
            label.fontName = HUDTypography.bodyBold
        case .note:
            label.fontName = HUDTypography.note
        case .noteBold:
            label.fontName = HUDTypography.noteBold
        }
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        return label
    }

    private static func paperCard(size: CGSize,
                                  cornerRadius: CGFloat = 8,
                                  fill: UIColor = HUDPalette.paper,
                                  stroke: UIColor = HUDPalette.line.withAlphaComponent(0.45),
                                  shadowAlpha: CGFloat = 0.18) -> SKNode {
        let container = SKNode()

        let shadow = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        shadow.fillColor = UIColor(white: 0, alpha: shadowAlpha)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -4)
        shadow.zPosition = -2
        container.addChild(shadow)

        let base = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        base.fillTexture = HUDTexture.paper(size: size, base: fill)
        base.fillColor = .white
        base.strokeColor = stroke
        base.lineWidth = 1.2
        base.zPosition = 0
        container.addChild(base)

        let inner = SKShapeNode(rectOf: CGSize(width: size.width - 8, height: size.height - 8),
                                cornerRadius: max(2, cornerRadius - 2))
        inner.fillColor = .clear
        inner.strokeColor = UIColor.white.withAlphaComponent(0.28)
        inner.lineWidth = 0.8
        inner.zPosition = 1
        container.addChild(inner)

        return container
    }

    private func makeTag(size: CGSize,
                         accent: UIColor,
                         fill: UIColor = HUDPalette.palePaper) -> (node: SKNode, label: SKLabelNode) {
        let node = HUDLayer.paperCard(size: size,
                                      cornerRadius: 6,
                                      fill: fill,
                                      stroke: accent.withAlphaComponent(0.62),
                                      shadowAlpha: 0.10)

        let accentLine = SKShapeNode(rectOf: CGSize(width: 3, height: size.height - 8),
                                     cornerRadius: 1.5)
        accentLine.fillColor = accent.withAlphaComponent(0.72)
        accentLine.strokeColor = .clear
        accentLine.position = CGPoint(x: -size.width / 2 + 7, y: 0)
        accentLine.zPosition = 3
        node.addChild(accentLine)

        let label = makeLabel(fontSize: 10, style: .bodyBold, color: HUDPalette.ink)
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 3, y: 0)
        label.zPosition = 4
        node.addChild(label)
        return (node, label)
    }

    private func makeStamp(text: String, color: UIColor) -> SKNode {
        let node = SKNode()
        node.zRotation = -0.08

        let bg = SKShapeNode(rectOf: CGSize(width: 62, height: 17), cornerRadius: 3)
        bg.fillColor = color.withAlphaComponent(0.08)
        bg.strokeColor = color.withAlphaComponent(0.70)
        bg.lineWidth = 1.1
        node.addChild(bg)

        let label = makeLabel(text: text.uppercased(),
                              fontSize: 8,
                              style: .bodyBold,
                              color: color.withAlphaComponent(0.86))
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        node.addChild(label)
        return node
    }

    // MARK: - Ficha superior

    private var topPanelBottomY: CGFloat = 0

    private func buildTopPanel() {
        let panelWidth = sceneSize.width - 24
        let panelHeight: CGFloat = 156
        let topEdge = sceneSize.height / 2 - topInset
        let panelCenterY = topEdge - 28 - panelHeight / 2

        let panel = HUDLayer.paperCard(size: CGSize(width: panelWidth, height: panelHeight),
                                       cornerRadius: 8,
                                       fill: HUDPalette.paper,
                                       stroke: HUDPalette.blueInk.withAlphaComponent(0.50),
                                       shadowAlpha: 0.20)
        panel.position = CGPoint(x: -2, y: panelCenterY)
        panel.zRotation = -0.006
        addChild(panel)
        topPanelBottomY = panelCenterY - panelHeight / 2

        let panelContent = SKNode()
        panelContent.zPosition = 5
        panel.addChild(panelContent)

        let halfW = panelWidth / 2

        let clip = SKShapeNode(rectOf: CGSize(width: 34, height: 9), cornerRadius: 4)
        clip.fillColor = UIColor(red: 0.76, green: 0.77, blue: 0.70, alpha: 1)
        clip.strokeColor = HUDPalette.ink.withAlphaComponent(0.28)
        clip.lineWidth = 1
        clip.position = CGPoint(x: -halfW + 42, y: panelHeight / 2 - 5)
        clip.zPosition = 7
        panelContent.addChild(clip)

        titleLabel = makeLabel(text: "Registro da Eistrelinha",
                               fontSize: 16,
                               style: .noteBold,
                               color: HUDPalette.ink)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -halfW + 22, y: panelHeight / 2 - 25)
        panelContent.addChild(titleLabel)

        let editButton = SKNode()
        editButton.name = "cmd_edit_mermaid_name"
        editButton.position = CGPoint(x: -halfW + 204, y: panelHeight / 2 - 25)
        editButton.zPosition = 8
        let editHit = SKShapeNode(circleOfRadius: 14)
        editHit.fillColor = HUDPalette.palePaper.withAlphaComponent(0.82)
        editHit.strokeColor = HUDPalette.teal.withAlphaComponent(0.52)
        editHit.lineWidth = 1
        editHit.name = editButton.name
        editButton.addChild(editHit)
        let pen = HUDLayer.pathNode(points: [
            CGPoint(x: -5, y: -5),
            CGPoint(x: 4, y: 4)
        ], color: HUDPalette.teal, width: 2)
        pen.name = editButton.name
        editButton.addChild(pen)
        let nib = HUDLayer.pathNode(points: [
            CGPoint(x: 4, y: 4),
            CGPoint(x: 7, y: 7)
        ], color: HUDPalette.gold, width: 2.2)
        nib.name = editButton.name
        editButton.addChild(nib)
        panelContent.addChild(editButton)
        nameEditButton = editButton

        let stamp = makeStamp(text: "CAMPO", color: HUDPalette.teal)
        stamp.position = CGPoint(x: halfW - 45, y: panelHeight / 2 - 26)
        stamp.zPosition = 8
        panelContent.addChild(stamp)

        phaseLabel = makeLabel(fontSize: 14, style: .bodyBold, color: HUDPalette.blueInk)
        phaseLabel.horizontalAlignmentMode = .left
        phaseLabel.verticalAlignmentMode = .center
        phaseLabel.position = CGPoint(x: -halfW + 22, y: panelHeight / 2 - 51)
        panelContent.addChild(phaseLabel)

        depthLabel = makeLabel(fontSize: 11, style: .body, color: HUDPalette.mutedInk)
        depthLabel.horizontalAlignmentMode = .left
        depthLabel.verticalAlignmentMode = .center
        depthLabel.position = CGPoint(x: -halfW + 22, y: panelHeight / 2 - 70)
        panelContent.addChild(depthLabel)

        growthLabel = makeLabel(fontSize: 10, style: .note, color: HUDPalette.teal)
        growthLabel.horizontalAlignmentMode = .left
        growthLabel.verticalAlignmentMode = .center
        growthLabel.position = CGPoint(x: -halfW + 22, y: panelHeight / 2 - 88)
        growthLabel.preferredMaxLayoutWidth = max(140, panelWidth - 172)
        growthLabel.numberOfLines = 1
        panelContent.addChild(growthLabel)

        let planktonIcon = HUDLayer.iconNode(kind: .shell, color: HUDPalette.gold)
        planktonIcon.position = CGPoint(x: halfW - 126, y: panelHeight / 2 - 52)
        planktonIcon.zPosition = 8
        panelContent.addChild(planktonIcon)

        let pearlsTag = makeTag(size: CGSize(width: 104, height: 24), accent: HUDPalette.gold)
        pearlsTag.node.position = CGPoint(x: halfW - 64, y: panelHeight / 2 - 52)
        panelContent.addChild(pearlsTag.node)
        pearlsLabel = pearlsTag.label

        let divider = HUDLayer.pathNode(points: [
            CGPoint(x: -halfW + 18, y: -22),
            CGPoint(x: halfW - 18, y: -20)
        ], color: HUDPalette.line.withAlphaComponent(0.28), width: 1)
        divider.zPosition = 3
        panelContent.addChild(divider)

        let barConfigs: [(key: String, label: String, color: UIColor, column: Int, row: Int)] = [
            ("hunger", "Alimentação", HUDPalette.algae, 0, 0),
            ("energy", "Energia", HUDPalette.gold, 1, 0),
            ("mood", "Disposição", HUDPalette.algae, 0, 1),
            ("bond", "Vínculo", HUDPalette.teal, 1, 1)
        ]

        let columnWidth = (panelWidth - 54) / 2
        for config in barConfigs {
            let x = config.column == 0 ? -halfW + 22 : -halfW + 22 + columnWidth + 12
            let y = -panelHeight / 2 + 38 - CGFloat(config.row) * 24
            addBiologyMeter(key: config.key,
                            title: config.label,
                            color: config.color,
                            width: columnWidth,
                            at: CGPoint(x: x, y: y),
                            parent: panelContent)
        }
    }

    private func addBiologyMeter(key: String,
                                 title: String,
                                 color: UIColor,
                                 width: CGFloat,
                                 at position: CGPoint,
                                 parent: SKNode) {
        let label = makeLabel(text: title, fontSize: 9, style: .bodyBold, color: HUDPalette.ink)
        label.horizontalAlignmentMode = .left
        label.position = position
        label.zPosition = 4
        parent.addChild(label)
        barLabels[key] = label

        let meterWidth = width - 66
        let meter = SKNode()
        meter.position = CGPoint(x: position.x + 61, y: position.y)
        meter.zPosition = 4
        parent.addChild(meter)

        let bg = SKShapeNode(rect: CGRect(x: 0, y: -4, width: meterWidth, height: 8),
                             cornerRadius: 4)
        bg.fillColor = UIColor.white.withAlphaComponent(0.38)
        bg.strokeColor = HUDPalette.line.withAlphaComponent(0.35)
        bg.lineWidth = 0.8
        meter.addChild(bg)

        for tick in 1...4 {
            let x = CGFloat(tick) * meterWidth / 5
            let mark = HUDLayer.pathNode(points: [CGPoint(x: x, y: -6), CGPoint(x: x, y: 6)],
                                         color: HUDPalette.line.withAlphaComponent(0.22),
                                         width: 0.8)
            mark.zPosition = 2
            meter.addChild(mark)
        }

        let fill = SKShapeNode(rect: CGRect(x: 0, y: -3, width: meterWidth, height: 6),
                               cornerRadius: 3)
        fill.fillColor = color.withAlphaComponent(0.72)
        fill.strokeColor = .clear
        fill.zPosition = 1
        meter.addChild(fill)
        bars[key] = fill
    }

    // MARK: - Mensagens

    private func buildMessageBubble() {
        messageContainer = SKNode()
        messageContainer.position = CGPoint(x: -10, y: topPanelBottomY - 44)
        messageContainer.alpha = 0
        messageContainer.zPosition = 6
        messageContainer.zRotation = -0.018
        addChild(messageContainer)

        let bubbleSize = CGSize(width: sceneSize.width - 62, height: 64)
        let bubble = HUDLayer.paperCard(size: bubbleSize,
                                        cornerRadius: 8,
                                        fill: HUDPalette.palePaper,
                                        stroke: HUDPalette.teal.withAlphaComponent(0.58),
                                        shadowAlpha: 0.16)
        messageContainer.addChild(bubble)

        let halfW = bubbleSize.width / 2
        let wave = HUDLayer.iconNode(kind: .wave, color: HUDPalette.teal)
        wave.position = CGPoint(x: -halfW + 25, y: -2)
        wave.zPosition = 5
        messageContainer.addChild(wave)

        messageTitleLabel = makeLabel(fontSize: 10, style: .bodyBold, color: HUDPalette.teal)
        messageTitleLabel.horizontalAlignmentMode = .left
        messageTitleLabel.position = CGPoint(x: -halfW + 48, y: 14)
        messageTitleLabel.zPosition = 5
        messageContainer.addChild(messageTitleLabel)

        messageLabel = makeLabel(fontSize: 12, style: .body, color: HUDPalette.ink)
        messageLabel.horizontalAlignmentMode = .left
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: -halfW + 48, y: -10)
        messageLabel.preferredMaxLayoutWidth = bubbleSize.width - 68
        messageLabel.numberOfLines = 2
        messageLabel.zPosition = 5
        messageContainer.addChild(messageLabel)
    }

    func showMessage(_ text: String, duration: TimeInterval = 0) {
        let note = fieldNote(from: text)
        let holdTime = duration > 0 ? duration : max(3.0, Double(note.body.count) * 0.07)
        messageTitleLabel.text = note.title
        messageLabel.text = note.body
        messageContainer.removeAllActions()
        messageContainer.alpha = 0
        messageContainer.setScale(0.96)
        messageContainer.run(.sequence([
            .group([
                .fadeIn(withDuration: 0.18),
                .scale(to: 1.0, duration: 0.18)
            ]),
            .wait(forDuration: holdTime),
            .fadeOut(withDuration: 0.45)
        ]))
    }

    private func fieldNote(from rawText: String) -> (title: String, body: String) {
        let lower = rawText.lowercased()
        var title = "Observação rápida"
        var body = rawText

        if lower.contains("correnteza") {
            title = "Registro do ambiente"
            body = "Correnteza registrada na região."
        } else if lower.contains("objetivo disponivel") || lower.contains("objetivo disponível") {
            title = "Nova observação"
            body = cleanFieldText(rawText)
                .replacingOccurrences(of: "(Objetivo disponivel)", with: "Objetivo disponível.")
                .replacingOccurrences(of: "(Objetivo disponível)", with: "Objetivo disponível.")
        } else if lower.contains("refugio") || lower.contains("refúgio") {
            title = "Registro do refúgio"
            body = cleanFieldText(rawText)
        } else if lower.contains("desafio") || lower.contains("trama") {
            title = "Desafio registrado"
            body = cleanFieldText(rawText)
        } else if lower.contains("camada") || lower.contains("profund") {
            title = "Camada observada"
            body = cleanFieldText(rawText)
        } else if lower.contains("fome") || lower.contains("faminta") || lower.contains("comer") {
            title = "Sinais biológicos"
            body = cleanFieldText(rawText)
        } else {
            body = cleanFieldText(rawText)
        }

        return (title, body)
    }

    private func cleanFieldText(_ text: String) -> String {
        var result = text
        let removals = [
            "🌊", "🥚", "🌀", "✨", "👀", "😨", "💪", "💎", "🏆",
            "⛵️", "📦", "🐚", "😴", "🍽", "😋", "🧜‍♀️", "⚡️", "😊", "⭐️"
        ]
        removals.forEach { result = result.replacingOccurrences(of: $0, with: "") }
        result = result.replacingOccurrences(of: "!", with: ".")
        result = result.replacingOccurrences(of: "...", with: ".")
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? "Nova observação registrada." : result
    }

    // MARK: - Etiqueta de comportamento

    private var intentChip: SKShapeNode!

    private func buildIntentChip() {
        let chipY = buttonRowY(0) + 50
        let chipSize = CGSize(width: min(286, sceneSize.width - 68), height: 30)
        intentChip = SKShapeNode(rectOf: chipSize, cornerRadius: 8)
        intentChip.fillTexture = HUDTexture.paper(size: chipSize, base: HUDPalette.palePaper)
        intentChip.fillColor = .white
        intentChip.strokeColor = HUDPalette.teal.withAlphaComponent(0.48)
        intentChip.lineWidth = 1
        intentChip.position = CGPoint(x: 7, y: chipY)
        intentChip.zRotation = 0.012
        addChild(intentChip)

        let pencil = HUDLayer.pathNode(points: [
            CGPoint(x: -chipSize.width / 2 + 16, y: -4),
            CGPoint(x: -chipSize.width / 2 + 28, y: 5)
        ], color: HUDPalette.gold, width: 2.0)
        pencil.zPosition = 2
        intentChip.addChild(pencil)

        intentLabel = makeLabel(fontSize: 12, style: .note, color: HUDPalette.ink)
        intentLabel.horizontalAlignmentMode = .center
        intentLabel.verticalAlignmentMode = .center
        intentLabel.zPosition = 2
        intentChip.addChild(intentLabel)
    }

    // MARK: - Botoes de comando

    private func buttonRowY(_ row: Int) -> CGFloat {
        -sceneSize.height / 2 + insets.bottom + 72 - CGFloat(row) * 60
    }

    private func buildButtons() {
        let bottomCommands: [PlayerCommand] = [.seekFood, .rest, .challenge, .objective, .refuge]
        let bottomWidth = min(CGFloat(68), (sceneSize.width - 36) / CGFloat(bottomCommands.count))
        let bottomSpacing = max(CGFloat(4), (sceneSize.width - bottomWidth * CGFloat(bottomCommands.count) - 24) / CGFloat(bottomCommands.count - 1))
        let bottomStartX = -sceneSize.width / 2 + 12 + bottomWidth / 2
        for (index, command) in bottomCommands.enumerated() {
            let x = bottomStartX + CGFloat(index) * (bottomWidth + bottomSpacing)
            addCommandButton(command,
                             size: CGSize(width: bottomWidth, height: 54),
                             position: CGPoint(x: x, y: buttonRowY(0)),
                             tilt: buttonTilt(seed: index),
                             primary: true,
                             showsLabel: true)
        }

        let sideSize = CGSize(width: 56, height: 56)
        let sideOffset: CGFloat = 33
        let sideY: CGFloat = -6
        let leftX = -sceneSize.width / 2 + insets.left + 38
        addCommandButton(.goUp,
                         size: sideSize,
                         position: CGPoint(x: leftX, y: sideY + sideOffset),
                         tilt: -0.008,
                         primary: false,
                         showsLabel: false)
        addCommandButton(.goDown,
                         size: sideSize,
                         position: CGPoint(x: leftX, y: sideY - sideOffset),
                         tilt: 0.010,
                         primary: false,
                         showsLabel: false)

        let rightX = sceneSize.width / 2 - insets.right - 38
        addCommandButton(.explore,
                         size: sideSize,
                         position: CGPoint(x: rightX, y: sideY + sideOffset),
                         tilt: 0.006,
                         primary: false,
                         showsLabel: false)
        addCommandButton(.travel,
                         size: sideSize,
                         position: CGPoint(x: rightX, y: sideY - sideOffset),
                         tilt: -0.008,
                         primary: false,
                         showsLabel: false)
    }

    private func buttonTilt(seed: Int) -> CGFloat {
        [-0.012, 0.006, -0.004, 0.008, -0.010][seed % 5]
    }

    private func addCommandButton(_ command: PlayerCommand,
                                  size: CGSize,
                                  position: CGPoint,
                                  tilt: CGFloat,
                                  primary: Bool,
                                  showsLabel: Bool) {
        let button = SKNode()
        button.name = "cmd_\(command.rawValue)"
        button.position = position
        button.zRotation = tilt

        let card = makeActionCard(size: size,
                                  accent: command.tint,
                                  primary: primary)
        button.addChild(card)

        let highlight = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4),
                                    cornerRadius: 7)
        highlight.fillColor = command.tint.withAlphaComponent(0.10)
        highlight.strokeColor = command.tint.withAlphaComponent(0.72)
        highlight.lineWidth = 1.5
        highlight.glowWidth = 1.5
        highlight.zPosition = 4
        highlight.isHidden = true
        button.addChild(highlight)
        buttonHighlights[command] = highlight

        let icon = HUDLayer.iconNode(for: command, color: command.tint)
        icon.position = CGPoint(x: 0, y: showsLabel ? 10 : 0)
        icon.zPosition = 5
        button.addChild(icon)

        if showsLabel {
            let text = makeLabel(text: command.label,
                                 fontSize: 9.2,
                                 style: .bodyBold,
                                 color: HUDPalette.ink)
            text.horizontalAlignmentMode = .center
            text.position = CGPoint(x: 0, y: -18)
            text.preferredMaxLayoutWidth = size.width - 8
            text.numberOfLines = 1
            text.zPosition = 5
            button.addChild(text)
        }

        if command == .objective {
            let stamp = makeStamp(text: "Sem reg.", color: HUDPalette.mutedInk)
            stamp.position = CGPoint(x: size.width / 2 - 32, y: size.height / 2 - 13)
            stamp.zPosition = 7
            stamp.isHidden = true
            button.addChild(stamp)
            buttonStamps[command] = stamp
        }

        addCooldownOverlay(for: command, size: size, to: button)

        addChild(button)
        buttons[command] = button
        buttonSizes[command] = size
    }

    private func addCooldownOverlay(for command: PlayerCommand, size: CGSize, to button: SKNode) {
        let overlay = SKNode()
        overlay.isHidden = true
        overlay.zPosition = 8
        button.addChild(overlay)
        buttonCooldownOverlays[command] = overlay

        let veil = SKShapeNode(rectOf: size, cornerRadius: 8)
        veil.fillColor = HUDPalette.ink.withAlphaComponent(0.10)
        veil.strokeColor = HUDPalette.blueInk.withAlphaComponent(0.20)
        veil.lineWidth = 0.8
        veil.zPosition = 1
        overlay.addChild(veil)

        let fill = SKShapeNode()
        fill.fillColor = HUDPalette.blueInk.withAlphaComponent(0.34)
        fill.strokeColor = .clear
        fill.zPosition = 2
        overlay.addChild(fill)
        buttonCooldownFills[command] = fill

        let line = SKShapeNode()
        line.fillColor = .clear
        line.strokeColor = command.tint.withAlphaComponent(0.9)
        line.lineWidth = 2
        line.lineCap = .round
        line.zPosition = 3
        overlay.addChild(line)
        buttonCooldownLines[command] = line

        let label = makeLabel(text: "", fontSize: 10, style: .bodyBold, color: HUDPalette.paper)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.zPosition = 4
        overlay.addChild(label)
        buttonCooldownLabels[command] = label
    }

    private func makeActionCard(size: CGSize, accent: UIColor, primary: Bool) -> SKNode {
        let node = HUDLayer.paperCard(size: size,
                                      cornerRadius: 8,
                                      fill: primary ? HUDPalette.paper : HUDPalette.palePaper,
                                      stroke: HUDPalette.blueInk.withAlphaComponent(primary ? 0.42 : 0.34),
                                      shadowAlpha: primary ? 0.18 : 0.13)

        let tab = SKShapeNode(rectOf: CGSize(width: size.width - 14, height: primary ? 4 : 3),
                              cornerRadius: 2)
        tab.fillColor = accent.withAlphaComponent(primary ? 0.70 : 0.55)
        tab.strokeColor = .clear
        tab.position = CGPoint(x: 0, y: size.height / 2 - 8)
        tab.zPosition = 3
        node.addChild(tab)

        let stitch = HUDLayer.pathNode(points: [
            CGPoint(x: -size.width / 2 + 10, y: -size.height / 2 + 9),
            CGPoint(x: size.width / 2 - 10, y: -size.height / 2 + 8)
        ], color: HUDPalette.line.withAlphaComponent(0.20), width: 1)
        stitch.zPosition = 3
        node.addChild(stitch)

        return node
    }

    private func buildDebugRigToolButton() {
        guard enableDebugRigToolButton else { return }
        let button = SKNode()
        button.name = "cmd_debug_rig_tool"
        button.position = CGPoint(
            x: -sceneSize.width / 2 + 31 + insets.left,
            y: buttonRowY(0) + 118
        )

        let background = SKShapeNode(circleOfRadius: 22)
        background.fillTexture = HUDTexture.paper(size: CGSize(width: 44, height: 44), base: HUDPalette.paper)
        background.fillColor = .white
        background.strokeColor = HUDPalette.blueInk.withAlphaComponent(0.62)
        background.lineWidth = 1.4
        background.name = button.name
        button.addChild(background)

        let icon = makeLabel(text: "↻", fontSize: 17, style: .bodyBold, color: HUDPalette.blueInk)
        icon.position = CGPoint(x: 0, y: 2)
        icon.name = button.name
        button.addChild(icon)

        let text = makeLabel(text: "rig", fontSize: 8, style: .bodyBold, color: HUDPalette.ink)
        text.position = CGPoint(x: 0, y: -26)
        text.name = button.name
        button.addChild(text)

        addChild(button)
        debugRigToolButton = button
    }

    // MARK: - Atualizacao

    func refresh(stats: MermaidStats,
                 intent: MermaidIntent,
                 zone: DepthZone,
                 regionName: String?,
                 evolutionProgress: CGFloat,
                 evolutionNote: String,
                 objectiveAvailable: Bool,
                 commandCooldowns: [PlayerCommand: TimeInterval]) {
        let eggMode = stats.phase == .egg
        titleLabel.text = "Registro da \(stats.mermaidName)"
        updateNameEditPosition()

        if eggMode {
            phaseLabel.text = "Ovo misterioso · \(Int(evolutionProgress * 100))% chocado"
            growthLabel.text = evolutionNote
            intentLabel.text = "Registro: incubação em andamento"
            barLabels["bond"]?.text = "Nascimento"
        } else {
            phaseLabel.text = "Sereia \(stats.phase.displayName.lowercased()) · \(stats.ageText) observada"
            growthLabel.text = evolutionNote
            intentLabel.text = "Comportamento: \(intent.displayName)"
            barLabels["bond"]?.text = "Vínculo"
        }

        let zoneText = zone.displayName.lowercased()
        if let regionName {
            depthLabel.text = "\(regionName) · \(zoneText)"
        } else {
            depthLabel.text = "Camada atual: \(zoneText)"
        }
        pearlsLabel.text = "Conchas \(stats.pearls)"

        let nourishment = 1 - stats.hunger / 100
        setBar("hunger", value: nourishment)
        setBar("energy", value: stats.energy / 100)
        setBar("mood", value: stats.disposition / 100)
        setBar("bond", value: eggMode ? evolutionProgress : stats.trust / 100)

        if let hunger = bars["hunger"] {
            hunger.fillColor = nourishment < 0.28
                ? HUDPalette.coral.withAlphaComponent(0.86)
                : HUDPalette.algae.withAlphaComponent(0.70)
        }

        disabledCommands = Set(commandCooldowns.keys.filter { (commandCooldowns[$0] ?? 0) > 0 })
        let stateChanged = eggMode != lastEggMode || objectiveAvailable != lastObjectiveAvailable
        lastEggMode = eggMode
        lastObjectiveAvailable = objectiveAvailable
        for (command, button) in buttons {
            var active = !eggMode || command == .challenge
            if command == .objective {
                active = active && objectiveAvailable
                buttonStamps[command]?.isHidden = active
            }
            let coolingDown = disabledCommands.contains(command)
            if coolingDown { active = false }
            button.alpha = coolingDown || active ? 1 : (command == .objective ? 0.82 : 0.42)
            updateCooldownOverlay(for: command, remaining: commandCooldowns[command] ?? 0)
        }

        if stateChanged {
            if objectiveAvailable, !eggMode, let button = buttons[.objective] {
                button.removeAllActions()
                button.run(.sequence([
                    .scale(to: 1.08, duration: 0.18),
                    .scale(to: 1.0, duration: 0.22)
                ]))
            }
        }

        let activeCommand = highlightedCommand(for: intent)
        for (command, highlight) in buttonHighlights {
            highlight.isHidden = command != activeCommand || disabledCommands.contains(command)
        }
    }

    private func updateCooldownOverlay(for command: PlayerCommand, remaining: TimeInterval) {
        guard let overlay = buttonCooldownOverlays[command],
              let size = buttonSizes[command],
              let fill = buttonCooldownFills[command],
              let line = buttonCooldownLines[command],
              let label = buttonCooldownLabels[command] else { return }

        guard remaining > 0 else {
            overlay.isHidden = true
            return
        }

        overlay.isHidden = false
        let normalized = max(0, min(1, remaining / commandCooldownAnimationSeconds))
        let progress = CGFloat(normalized)
        let fillHeight = max(1, size.height * progress)
        let rect = CGRect(x: -size.width / 2,
                          y: -size.height / 2,
                          width: size.width,
                          height: fillHeight)
        fill.path = UIBezierPath(roundedRect: rect,
                                 cornerRadius: min(8, fillHeight / 2)).cgPath

        let topY = -size.height / 2 + fillHeight
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: -size.width / 2 + 7, y: topY))
        linePath.addLine(to: CGPoint(x: size.width / 2 - 7, y: topY))
        line.path = linePath.cgPath
        line.alpha = progress > 0.03 ? 1 : 0

        label.text = "\(Int(ceil(remaining)))s"
        label.alpha = progress > 0.16 ? 1 : 0
    }

    private func setBar(_ key: String, value: CGFloat) {
        bars[key]?.xScale = value.clamped(to: 0.02...1)
    }

    private func updateNameEditPosition() {
        guard let nameEditButton else { return }
        let frame = titleLabel.calculateAccumulatedFrame()
        let maxX = sceneSize.width / 2 - 74
        nameEditButton.position.x = min(frame.maxX + 18, maxX)
    }

    private func highlightedCommand(for intent: MermaidIntent) -> PlayerCommand? {
        switch intent {
        case .wandering, .observing:
            return .explore
        case .seekingFood, .eating:
            return .seekFood
        case .resting:
            return .rest
        case .seekingChallenge, .inChallenge:
            return .challenge
        case .goingToObjective:
            return .objective
        case .goingDeeper:
            return .goDown
        case .goingUp:
            return .goUp
        case .traveling:
            return .travel
        case .enteringRefuge, .returningHome:
            return .refuge
        default:
            return nil
        }
    }

    // MARK: - Toques

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        var node: SKNode? = atPoint(location)
        while let current = node {
            if let name = current.name {
                if name == "cmd_edit_mermaid_name" {
                    flashNode(nameEditButton)
                    onNameEditTap?()
                    return
                }
                if name.hasPrefix("cmd_"),
                   let command = PlayerCommand(rawValue: String(name.dropFirst(4))) {
                    guard !disabledCommands.contains(command) else { return }
                    flashButton(command)
                    onCommand?(command)
                    return
                }
                if name == "cmd_debug_rig_tool" {
                    flashNode(debugRigToolButton)
                    onDebugRigToolTap?()
                    return
                }
            }
            node = current.parent
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

    // MARK: - Icones desenhados

    private enum IconKind {
        case plankton
        case shell
        case wave
    }

    private static func iconNode(kind: IconKind, color: UIColor) -> SKNode {
        let node = SKNode()
        switch kind {
        case .plankton:
            let star = UIBezierPath()
            for i in 0..<8 {
                let angle = CGFloat(i) * CGFloat.pi / 4
                let radius: CGFloat = i.isMultiple(of: 2) ? 7 : 3
                let p = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                i == 0 ? star.move(to: p) : star.addLine(to: p)
            }
            star.close()
            let shape = pathNode(path: star, color: color, width: 1.5)
            node.addChild(shape)
            addDot(to: node, at: CGPoint(x: 10, y: 4), radius: 1.4, color: color)
            addDot(to: node, at: CGPoint(x: -9, y: -5), radius: 1.1, color: color)
        case .shell:
            if let symbol = sfSymbolNode(name: "fossil.shell.fill", color: color, size: 22) {
                node.addChild(symbol)
                return node
            }
            addShellDrawing(to: node, color: color)
        case .wave:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -11, y: -2))
            path.addCurve(to: CGPoint(x: -2, y: -2),
                          controlPoint1: CGPoint(x: -8, y: 5),
                          controlPoint2: CGPoint(x: -5, y: 5))
            path.addCurve(to: CGPoint(x: 9, y: -2),
                          controlPoint1: CGPoint(x: 2, y: -8),
                          controlPoint2: CGPoint(x: 5, y: -8))
            node.addChild(pathNode(path: path, color: color, width: 2.1))
            addDot(to: node, at: CGPoint(x: 10, y: 6), radius: 1.2, color: color)
            addDot(to: node, at: CGPoint(x: -8, y: 7), radius: 1.0, color: color)
        }
        return node
    }

    private static func sfSymbolNode(name: String, color: UIColor, size: CGFloat) -> SKNode? {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        guard let image = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) else { return nil }
        let sprite = SKSpriteNode(texture: SKTexture(image: image))
        sprite.size = image.size
        return sprite
    }

    private static func addShellDrawing(to node: SKNode, color: UIColor) {
        let shell = UIBezierPath()
        shell.move(to: CGPoint(x: -9, y: -7))
        shell.addCurve(to: CGPoint(x: 9, y: -7),
                       controlPoint1: CGPoint(x: -7, y: 9),
                       controlPoint2: CGPoint(x: 7, y: 9))
        shell.addCurve(to: CGPoint(x: -9, y: -7),
                       controlPoint1: CGPoint(x: 5, y: -10),
                       controlPoint2: CGPoint(x: -5, y: -10))
        node.addChild(pathNode(path: shell, color: color, width: 1.8))
        for x in [CGFloat(-5), 0, 5] {
            node.addChild(pathNode(points: [CGPoint(x: 0, y: -7), CGPoint(x: x, y: 7)],
                                  color: color.withAlphaComponent(0.78),
                                  width: 1.1))
        }
    }

    private static func iconNode(for command: PlayerCommand, color: UIColor) -> SKNode {
        let node = SKNode()
        switch command {
        case .explore:
            let circle = SKShapeNode(circleOfRadius: 10)
            circle.fillColor = .clear
            circle.strokeColor = color
            circle.lineWidth = 1.8
            node.addChild(circle)
            node.addChild(pathNode(points: [CGPoint(x: -3, y: -5), CGPoint(x: 4, y: 7), CGPoint(x: 1, y: -2)],
                                  color: color,
                                  width: 1.8))
        case .seekFood:
            node.addChild(pathNode(points: [CGPoint(x: 0, y: -10), CGPoint(x: 0, y: 10)],
                                  color: color,
                                  width: 1.8))
            node.addChild(pathNode(points: [CGPoint(x: 0, y: -2), CGPoint(x: -8, y: 4), CGPoint(x: -3, y: 7)],
                                  color: color,
                                  width: 1.7))
            node.addChild(pathNode(points: [CGPoint(x: 0, y: 2), CGPoint(x: 8, y: 6), CGPoint(x: 4, y: 9)],
                                  color: color,
                                  width: 1.7))
        case .rest:
            let moon = UIBezierPath()
            moon.move(to: CGPoint(x: 5, y: 9))
            moon.addCurve(to: CGPoint(x: 3, y: -9),
                          controlPoint1: CGPoint(x: -5, y: 6),
                          controlPoint2: CGPoint(x: -6, y: -5))
            moon.addCurve(to: CGPoint(x: 9, y: 5),
                          controlPoint1: CGPoint(x: -1, y: -4),
                          controlPoint2: CGPoint(x: 2, y: 4))
            node.addChild(pathNode(path: moon, color: color, width: 1.9))
            addDot(to: node, at: CGPoint(x: -8, y: -5), radius: 1.4, color: color)
            addDot(to: node, at: CGPoint(x: -10, y: 5), radius: 1.1, color: color)
        case .challenge:
            let star = UIBezierPath()
            for i in 0..<10 {
                let angle = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 5
                let radius: CGFloat = i.isMultiple(of: 2) ? 10 : 5
                let p = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
                i == 0 ? star.move(to: p) : star.addLine(to: p)
            }
            star.close()
            node.addChild(pathNode(path: star, color: color, width: 1.7))
        case .objective:
            let box = SKShapeNode(rectOf: CGSize(width: 17, height: 19), cornerRadius: 3)
            box.fillColor = .clear
            box.strokeColor = color
            box.lineWidth = 1.6
            node.addChild(box)
            node.addChild(pathNode(points: [CGPoint(x: -5, y: 3), CGPoint(x: -2, y: 0), CGPoint(x: 5, y: 6)],
                                  color: color,
                                  width: 1.7))
            node.addChild(pathNode(points: [CGPoint(x: -5, y: -5), CGPoint(x: 6, y: -5)],
                                  color: color,
                                  width: 1.4))
        case .refuge:
            addShellDrawing(to: node, color: color)
        case .goUp:
            node.addChild(pathNode(points: [CGPoint(x: 0, y: -9), CGPoint(x: 0, y: 9)],
                                  color: color,
                                  width: 1.9))
            node.addChild(pathNode(points: [CGPoint(x: -6, y: 3), CGPoint(x: 0, y: 9), CGPoint(x: 6, y: 3)],
                                  color: color,
                                  width: 1.9))
            addDot(to: node, at: CGPoint(x: -8, y: -4), radius: 1.2, color: color)
            addDot(to: node, at: CGPoint(x: 8, y: 1), radius: 1.0, color: color)
        case .goDown:
            node.addChild(pathNode(points: [CGPoint(x: 0, y: 9), CGPoint(x: 0, y: -9)],
                                  color: color,
                                  width: 1.9))
            node.addChild(pathNode(points: [CGPoint(x: -6, y: -3), CGPoint(x: 0, y: -9), CGPoint(x: 6, y: -3)],
                                  color: color,
                                  width: 1.9))
            addDot(to: node, at: CGPoint(x: -8, y: 4), radius: 1.2, color: color)
            addDot(to: node, at: CGPoint(x: 8, y: -1), radius: 1.0, color: color)
        case .travel:
            let map = UIBezierPath()
            map.move(to: CGPoint(x: -10, y: -8))
            map.addLine(to: CGPoint(x: -3, y: -5))
            map.addLine(to: CGPoint(x: 4, y: -8))
            map.addLine(to: CGPoint(x: 10, y: -5))
            map.addLine(to: CGPoint(x: 10, y: 8))
            map.addLine(to: CGPoint(x: 4, y: 5))
            map.addLine(to: CGPoint(x: -3, y: 8))
            map.addLine(to: CGPoint(x: -10, y: 5))
            map.close()
            node.addChild(pathNode(path: map, color: color, width: 1.6))
            node.addChild(pathNode(points: [CGPoint(x: -3, y: -5), CGPoint(x: -3, y: 8)],
                                  color: color.withAlphaComponent(0.70),
                                  width: 1.1))
            node.addChild(pathNode(points: [CGPoint(x: 4, y: -8), CGPoint(x: 4, y: 5)],
                                  color: color.withAlphaComponent(0.70),
                                  width: 1.1))
        }
        return node
    }

    private static func pathNode(points: [CGPoint], color: UIColor, width: CGFloat) -> SKShapeNode {
        let path = UIBezierPath()
        guard let first = points.first else { return SKShapeNode() }
        path.move(to: first)
        points.dropFirst().forEach { path.addLine(to: $0) }
        return pathNode(path: path, color: color, width: width)
    }

    private static func pathNode(path: UIBezierPath, color: UIColor, width: CGFloat) -> SKShapeNode {
        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = .clear
        shape.strokeColor = color
        shape.lineWidth = width
        shape.lineCap = .round
        shape.lineJoin = .round
        return shape
    }

    private static func addDot(to node: SKNode, at point: CGPoint, radius: CGFloat, color: UIColor) {
        let dot = SKShapeNode(circleOfRadius: radius)
        dot.fillColor = color.withAlphaComponent(0.82)
        dot.strokeColor = .clear
        dot.position = point
        node.addChild(dot)
    }
}
