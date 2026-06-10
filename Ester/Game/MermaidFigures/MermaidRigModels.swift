//
//  MermaidRigModels.swift
//  Ester
//

import Foundation
import CoreGraphics

enum MermaidRigAxis: Equatable {
    case x
    case y
    case z
    case scale
}

struct MermaidRigTransform: Codable {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    var scale: CGFloat

    init(x: CGFloat = 0, y: CGFloat = 0, z: CGFloat = 0, scale: CGFloat = 1) {
        self.x = x
        self.y = y
        self.z = z
        self.scale = scale
    }

    private enum CodingKeys: String, CodingKey {
        case x
        case y
        case z
        case scale
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        z = try container.decodeIfPresent(CGFloat.self, forKey: .z) ?? 0
        scale = try container.decodeIfPresent(CGFloat.self, forKey: .scale) ?? 1
    }

    var point: CGPoint {
        CGPoint(x: x, y: y)
    }

    mutating func set(_ value: CGFloat, axis: MermaidRigAxis) {
        switch axis {
        case .x:
            x = value
        case .y:
            y = value
        case .z:
            z = value
        case .scale:
            scale = max(0.05, value)
        }
    }

    mutating func add(_ delta: CGFloat, axis: MermaidRigAxis) {
        switch axis {
        case .x:
            x += delta
        case .y:
            y += delta
        case .z:
            z += delta
        case .scale:
            scale = max(0.05, scale + delta)
        }
    }
}

typealias MermaidRigPosition = MermaidRigTransform

struct MermaidRigDocument: Codable {
    var baby = BabyMermaidRig()
    var child = ChildMermaidRig()
    var young = YoungMermaidRig()
    var adult = AdultMermaidRig()
}

final class MermaidRigStore {
    static let shared = MermaidRigStore()

    private(set) var document: MermaidRigDocument
    #if DEBUG
    private let projectDefaultsURL = URL(fileURLWithPath: "/Users/yuryantony/Developer/Mermaid/Ester/Game/MermaidFigures/MermaidRigs.json")
    #endif

    private init() {
        #if DEBUG
        document = Self.loadDocument(from: projectDefaultsURL)
            ?? Self.loadBundledDefaults()
            ?? MermaidRigDocument()
        #else
        document = Self.loadBundledDefaults()
            ?? MermaidRigDocument()
        #endif
    }

    func rig(for form: MermaidFormKind) -> Any {
        switch form {
        case .baby:
            return document.baby
        case .child:
            return document.child
        case .young:
            return document.young
        case .adult:
            return document.adult
        }
    }

    func transform(for form: MermaidFormKind, part: MermaidFigurePart) -> MermaidRigTransform? {
        switch form {
        case .baby:
            return document.baby.position(for: part)
        case .child:
            return document.child.position(for: part)
        case .young:
            return document.young.position(for: part)
        case .adult:
            return document.adult.position(for: part)
        }
    }

    func position(for form: MermaidFormKind, part: MermaidFigurePart) -> MermaidRigPosition? {
        transform(for: form, part: part)
    }

    func add(_ delta: CGFloat, axis: MermaidRigAxis, form: MermaidFormKind, part: MermaidFigurePart) {
        switch form {
        case .baby:
            document.baby.add(delta, axis: axis, part: part)
        case .child:
            document.child.add(delta, axis: axis, part: part)
        case .young:
            document.young.add(delta, axis: axis, part: part)
        case .adult:
            document.adult.add(delta, axis: axis, part: part)
        }
        save()
    }

    func save() {
        // RigTool edits are kept in memory. Use exportJSONString() to copy
        // the canonical JSON and paste it into MermaidRigs.json.
    }

    func exportJSONString() -> String? {
        guard let data = encodedDocumentData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func encodedDocumentData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(document)
    }

    private static func loadDocument(from url: URL) -> MermaidRigDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MermaidRigDocument.self, from: data)
    }

    private static func loadBundledDefaults() -> MermaidRigDocument? {
        guard let url = Bundle.main.url(forResource: "MermaidRigs", withExtension: "json") else {
            return nil
        }
        return loadDocument(from: url)
    }
}
