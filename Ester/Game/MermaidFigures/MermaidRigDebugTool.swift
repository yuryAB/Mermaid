//
//  MermaidRigDebugTool.swift
//  Ester
//

import Foundation
import SpriteKit
import UIKit

final class MermaidRigDebugTool: SKNode {
    var onClose: (() -> Void)?

    private let sceneSize: CGSize
    private let insets: UIEdgeInsets
    private var selectedForm: MermaidFormKind
    private var selectedPart: MermaidFigurePart = .head
    private let content = SKNode()
    private let valueLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
    private var activeStepperName: String?
    private let stepperRepeatActionKey = "rig_stepper_repeat"
    private var exportMessage: String?

    init(size: CGSize, insets: UIEdgeInsets, initialForm: MermaidFormKind) {
        self.sceneSize = size
        self.insets = insets
        self.selectedForm = initialForm
        super.init()
        isUserInteractionEnabled = true
        build()
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let dim = SKShapeNode(rectOf: sceneSize)
        dim.fillColor = UIColor(white: 0, alpha: 0.62)
        dim.strokeColor = .clear
        addChild(dim)

        let panel = SKShapeNode(rectOf: CGSize(width: sceneSize.width - 24,
                                               height: sceneSize.height - insets.top - insets.bottom - 36),
                                cornerRadius: 18)
        panel.fillColor = UIColor(red: 0.02, green: 0.06, blue: 0.1, alpha: 0.92)
        panel.strokeColor = UIColor(white: 1, alpha: 0.24)
        panel.lineWidth = 1.5
        addChild(panel)
        content.zPosition = 2
        addChild(content)
    }

    private func refresh() {
        content.removeAllChildren()
        if MermaidRigStore.shared.transform(for: selectedForm, part: selectedPart) == nil,
           let availablePart = MermaidFigurePart.allCases.first(where: { MermaidRigStore.shared.transform(for: selectedForm, part: $0) != nil }) {
            selectedPart = availablePart
        }

        let topY = sceneSize.height / 2 - insets.top - 44
        let leftX = -sceneSize.width / 2 + 28 + insets.left
        let rightX = sceneSize.width / 2 - 118 - insets.right
        let panelRightX = sceneSize.width / 2 - 28 - insets.right
        let editorBottomY = -sceneSize.height / 2 + insets.bottom + 50
        let editorTopY = editorBottomY + 142
        let partsTop = topY - 102
        let editorWidth = sceneSize.width - insets.left - insets.right - 56

        let title = label("Rig Tool", size: 17, bold: true)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: leftX, y: topY)
        content.addChild(title)

        addButton(id: "rig_export", text: "exportar", position: CGPoint(x: rightX - 42, y: topY), width: 92)
        addButton(id: "rig_close", text: "fechar", position: CGPoint(x: rightX + 62, y: topY), width: 92)

        if let exportMessage {
            let message = label(exportMessage, size: 10, bold: false)
            message.horizontalAlignmentMode = .right
            message.fontColor = UIColor(white: 1, alpha: 0.76)
            message.position = CGPoint(x: rightX + 108, y: topY - 28)
            content.addChild(message)
        }

        var phaseX = leftX + 40
        for form in MermaidFormKind.allCases {
            addButton(id: "rig_form_\(form.rawValue)",
                      text: form.displayName,
                      position: CGPoint(x: phaseX, y: topY - 44),
                      width: 76,
                      active: form == selectedForm)
            phaseX += 82
        }

        let partButtonWidth: CGFloat = 102
        let partColumnGap: CGFloat = 10
        let partsWidth = partButtonWidth * 2 + partColumnGap
        let previewLeftX = leftX + partsWidth + 42
        let previewAvailableWidth = panelRightX - previewLeftX
        let previewWidth = min(280, max(180, previewAvailableWidth))
        let previewTopY = topY - 86
        let previewBottomY = editorTopY + 18
        let previewHeight = max(210, min(308, previewTopY - previewBottomY))
        let previewCenter = CGPoint(x: panelRightX - previewWidth / 2,
                                    y: previewTopY - previewHeight / 2)
        addPreview(center: previewCenter, size: CGSize(width: previewWidth, height: previewHeight))

        for (index, part) in MermaidFigurePart.allCases.enumerated() {
            let enabled = MermaidRigStore.shared.transform(for: selectedForm, part: part) != nil
            let column = index % 2
            let row = index / 2
            addButton(id: "rig_part_\(part.rawValue)",
                      text: part.displayName,
                      position: CGPoint(x: leftX + partButtonWidth / 2 + CGFloat(column) * (partButtonWidth + partColumnGap),
                                        y: partsTop - CGFloat(row) * 34),
                      width: partButtonWidth,
                      active: part == selectedPart,
                      enabled: enabled)
        }

        addEditorPanel(center: CGPoint(x: leftX + editorWidth / 2, y: editorBottomY + 64),
                       size: CGSize(width: editorWidth, height: 124))

        valueLabel.fontSize = 14
        valueLabel.fontColor = .white
        valueLabel.horizontalAlignmentMode = .left
        valueLabel.verticalAlignmentMode = .center
        valueLabel.text = valueText()
        valueLabel.position = CGPoint(x: leftX, y: editorTopY - 12)
        content.addChild(valueLabel)

        let stepperLeftX = leftX + editorWidth * 0.25
        let stepperRightX = leftX + editorWidth * 0.75
        addAxisStepper(axis: "x", label: "X", x: stepperLeftX, y: editorBottomY + 70)
        addAxisStepper(axis: "y", label: "Y", x: stepperRightX, y: editorBottomY + 70)
        addAxisStepper(axis: "z", label: "Z", x: stepperLeftX, y: editorBottomY + 18)
        addAxisStepper(axis: "scale", label: "Scale", x: stepperRightX, y: editorBottomY + 18)
    }

    private func valueText() -> String {
        guard let transform = MermaidRigStore.shared.transform(for: selectedForm, part: selectedPart) else {
            return "\(selectedForm.displayName).\(selectedPart.displayName): indisponivel"
        }
        return "\(selectedForm.displayName).\(selectedPart.displayName) | x: \(Int(transform.x)) y: \(Int(transform.y)) z: \(Int(transform.z)) scale: \(formatScale(transform.scale))"
    }

    private func addPreview(center: CGPoint, size: CGSize) {
        let frame = SKShapeNode(rectOf: size, cornerRadius: 16)
        frame.position = center
        frame.fillColor = UIColor(red: 0.01, green: 0.035, blue: 0.06, alpha: 0.82)
        frame.strokeColor = UIColor(white: 1, alpha: 0.22)
        frame.lineWidth = 1
        content.addChild(frame)

        let previewLabel = label("preview", size: 12, bold: true)
        previewLabel.position = CGPoint(x: center.x, y: center.y + size.height / 2 - 24)
        content.addChild(previewLabel)

        let mermaid = Mermaid()
        mermaid.setForm(selectedForm)
        mermaid.reloadForm()
        mermaid.applyIdleMoveMode()
        mermaid.applyPalette(.main)
        fitPreview(mermaid.base,
                   maxSize: CGSize(width: size.width - 58, height: size.height - 94),
                   center: CGPoint(x: center.x, y: center.y - 18))
        mermaid.base.zPosition = 4
        content.addChild(mermaid.base)
    }

    private func addEditorPanel(center: CGPoint, size: CGSize) {
        let panel = SKShapeNode(rectOf: size, cornerRadius: 14)
        panel.position = center
        panel.fillColor = UIColor(red: 0.01, green: 0.03, blue: 0.05, alpha: 0.46)
        panel.strokeColor = UIColor(white: 1, alpha: 0.12)
        panel.lineWidth = 1
        panel.zPosition = -1
        content.addChild(panel)
    }

    private func fitPreview(_ node: SKNode, maxSize: CGSize, center: CGPoint) {
        node.position = .zero
        node.setScale(1)

        let rawFrame = node.calculateAccumulatedFrame()
        guard rawFrame.width > 0, rawFrame.height > 0 else {
            node.position = center
            return
        }

        let scale = min(maxSize.width / rawFrame.width, maxSize.height / rawFrame.height) * 0.92
        node.setScale(scale)

        let scaledFrame = node.calculateAccumulatedFrame()
        node.position = CGPoint(x: center.x - scaledFrame.midX, y: center.y - scaledFrame.midY)
    }

    private func addAxisStepper(axis: String, label title: String, x: CGFloat, y: CGFloat) {
        let axisLabel = self.label(title, size: 13, bold: true)
        axisLabel.position = CGPoint(x: x, y: y + 22)
        content.addChild(axisLabel)

        addButton(id: "rig_axis_\(axis)_minus", text: "-", position: CGPoint(x: x - 48, y: y), width: 34)

        let value = label(axisValueText(axis), size: 11, bold: false)
        value.position = CGPoint(x: x, y: y)
        content.addChild(value)

        addButton(id: "rig_axis_\(axis)_plus", text: "+", position: CGPoint(x: x + 48, y: y), width: 34)
    }

    private func axisValueText(_ axis: String) -> String {
        guard let transform = MermaidRigStore.shared.transform(for: selectedForm, part: selectedPart) else {
            return "-"
        }

        switch axis {
        case "x":
            return "\(Int(transform.x))"
        case "y":
            return "\(Int(transform.y))"
        case "z":
            return "\(Int(transform.z))"
        case "scale":
            return formatScale(transform.scale)
        default:
            return "-"
        }
    }

    private func formatScale(_ scale: CGFloat) -> String {
        String(format: "%.2f", scale)
    }

    private func addButton(id: String, text: String, position: CGPoint, width: CGFloat, active: Bool = false, enabled: Bool = true) {
        let node = SKNode()
        node.name = enabled ? id : nil
        node.position = position

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 28), cornerRadius: 8)
        bg.name = enabled ? id : nil
        bg.fillColor = active
            ? UIColor(red: 0.2, green: 0.48, blue: 0.72, alpha: 0.96)
            : UIColor(red: 0.08, green: 0.14, blue: 0.2, alpha: enabled ? 0.95 : 0.36)
        bg.strokeColor = UIColor(white: 1, alpha: active ? 0.65 : 0.25)
        bg.lineWidth = 1
        node.addChild(bg)

        let textNode = label(text, size: 11, bold: active)
        textNode.name = enabled ? id : nil
        textNode.alpha = enabled ? 1 : 0.36
        textNode.verticalAlignmentMode = .center
        node.addChild(textNode)

        content.addChild(node)
    }

    private func label(_ text: String, size: CGFloat, bold: Bool = false) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = bold ? "Helvetica-Bold" : "Helvetica"
        label.fontSize = size
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        guard let name = nodes(at: location).compactMap(\.name).first(where: { $0.hasPrefix("rig_") }) else { return }

        if name == "rig_close" {
            onClose?()
            return
        }

        if name == "rig_export" {
            stopStepperRepeat()
            if let json = MermaidRigStore.shared.exportJSONString() {
                UIPasteboard.general.string = json
                exportMessage = "JSON copiado"
            } else {
                exportMessage = "erro ao exportar"
            }
            refresh()
            return
        }

        if let raw = name.removingPrefix("rig_form_"),
           let form = MermaidFormKind(rawValue: raw) {
            selectedForm = form
            refresh()
            return
        }

        if let raw = name.removingPrefix("rig_part_"),
           let part = MermaidFigurePart(rawValue: raw) {
            selectedPart = part
            refresh()
            return
        }

        if name.hasPrefix("rig_axis_") {
            startStepperRepeat(named: name)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeStepperName,
              let location = touches.first?.location(in: self) else { return }

        let isStillOnStepper = nodes(at: location).contains { $0.name == activeStepperName }
        if !isStillOnStepper {
            stopStepperRepeat()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopStepperRepeat()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopStepperRepeat()
    }

    private func startStepperRepeat(named name: String) {
        stopStepperRepeat()
        activeStepperName = name
        applyStepper(named: name)

        let repeatAction = SKAction.sequence([
            .wait(forDuration: 0.32),
            .repeatForever(.sequence([
                .run { [weak self] in
                    guard let self, self.activeStepperName == name else { return }
                    self.applyStepper(named: name)
                },
                .wait(forDuration: 0.075)
            ]))
        ])
        run(repeatAction, withKey: stepperRepeatActionKey)
    }

    private func stopStepperRepeat() {
        activeStepperName = nil
        removeAction(forKey: stepperRepeatActionKey)
    }

    private func applyStepper(named name: String) {
        let pieces = name.split(separator: "_")
        guard pieces.count == 4 else { return }

        let axis: MermaidRigAxis
        switch pieces[2] {
        case "x":
            axis = .x
        case "y":
            axis = .y
            case "z":
                axis = .z
            case "scale":
                axis = .scale
            default:
                return
            }

        let step: CGFloat = axis == .scale ? 0.05 : 1
        let delta: CGFloat = pieces[3] == "plus" ? step : -step
        MermaidRigStore.shared.add(delta, axis: axis, form: selectedForm, part: selectedPart)
        refresh()
    }
}

private extension String {
    func removingPrefix(_ prefix: String) -> String? {
        guard hasPrefix(prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }
}
