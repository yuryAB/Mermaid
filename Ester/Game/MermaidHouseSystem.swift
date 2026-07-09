//
//  MermaidHouseSystem.swift
//  Ester
//
//  Focused "miniroom" Mermaid House. The player enters from the Refuge and
//  sees one framed room scene at a time, with the mermaid living inside it
//  and a visual bottom tray for decorating or managing placed furniture.
//
//  Design constraints:
//  - Rooms render as complete 2D scenes.
//  - Furniture positioning is 2D only: drag, release, move, and store.
//  - Existing layout persistence is preserved, but room switching is presented
//    as scene navigation.
//  - Architecture remains prepared for future themes, room art, decoration
//    categories, inventories, and autonomous mermaid behavior.
//
//  All identifiers/comments are in English; every player-facing string is
//  in Brazilian Portuguese.
//

import Foundation
import SpriteKit
import UIKit

// MARK: - Scene ID model

/// Stable saved identifier for a room scene.
struct HouseRoomSceneID: Codable, Hashable {
    var col: Int
    var row: Int

    static let root = HouseRoomSceneID(col: 0, row: 0)
}

// MARK: - Scene defaults

/// Stable scene identifiers kept for save compatibility and room labels.
private enum HouseSceneDefaults {
    static let entrance = HouseRoomSceneID.root
    static let firstRoom = HouseRoomSceneID(col: 1, row: 0)
    static let legacyThirdRoom = HouseRoomSceneID(col: 2, row: 0)
    static let initialRooms: [HouseRoomSceneID] = [entrance]
}

// MARK: - Room model

/// The kind of a room scene. Only a generic empty room exists for now, but the
/// enum is the extension point for future purchasable/decoratable room types
/// (bedroom, gift table room, nursery, etc.).
enum HouseRoomSceneType: String, Codable, CaseIterable {
    case empty

    /// Player-facing label (pt-BR).
    var displayName: String {
        switch self {
        case .empty: return "Cômodo"
        }
    }

    /// Temporary placeholder tint used while real room art does not exist yet.
    var placeholderColor: UIColor {
        switch self {
        case .empty: return UIColor(red: 0.36, green: 0.58, blue: 0.72, alpha: 1)
        }
    }
}

/// A saved room scene. Future tasks can attach theme and room-specific state
/// here without changing the furniture placement model.
struct HouseRoomScene: Codable, Hashable {
    var id: UUID
    var position: HouseRoomSceneID
    var type: HouseRoomSceneType

    // TODO(house): add room themes and any per-room state once themed room
    // editing lands.

    init(id: UUID = UUID(), position: HouseRoomSceneID, type: HouseRoomSceneType = .empty) {
        self.id = id
        self.position = position
        self.type = type
    }
}

// MARK: - Persistent layout

/// The full, persistable house layout. This is intentionally a plain Codable
/// value type so it can be embedded in the existing `MermaidStats` save with
/// no extra persistence machinery.
struct HouseLayoutData: Codable {
    var rooms: [HouseRoomScene]
    var placedObjects: [PlacedHouseObject]
    var defaultFurnitureRevision: Int

    private enum CodingKeys: String, CodingKey {
        case rooms
        case placedObjects
        case defaultFurnitureRevision
    }

    /// Creates a fresh layout containing the main focused room scene.
    init() {
        self.rooms = HouseSceneDefaults.initialRooms.map { HouseRoomScene(position: $0, type: .empty) }
        self.placedObjects = []
        self.defaultFurnitureRevision = 0
    }

    init(rooms: [HouseRoomScene],
         placedObjects: [PlacedHouseObject] = [],
         defaultFurnitureRevision: Int = 0) {
        self.rooms = rooms
        self.placedObjects = placedObjects
        self.defaultFurnitureRevision = defaultFurnitureRevision
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rooms = try c.decodeIfPresent([HouseRoomScene].self, forKey: .rooms) ?? []
        placedObjects = try c.decodeIfPresent([PlacedHouseObject].self, forKey: .placedObjects) ?? []
        defaultFurnitureRevision = try c.decodeIfPresent(Int.self, forKey: .defaultFurnitureRevision) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rooms, forKey: .rooms)
        try c.encode(placedObjects, forKey: .placedObjects)
        try c.encode(defaultFurnitureRevision, forKey: .defaultFurnitureRevision)
    }

    /// Guarantees the invariant that the starting room always exists.
    mutating func ensureRootRoom() {
        for position in HouseSceneDefaults.initialRooms where !isOccupied(position) {
            rooms.append(HouseRoomScene(position: position, type: .empty))
        }
    }

    // MARK: Queries

    func isOccupied(_ position: HouseRoomSceneID) -> Bool {
        rooms.contains { $0.position == position }
    }

    func room(at position: HouseRoomSceneID) -> HouseRoomScene? {
        rooms.first { $0.position == position }
    }

    // MARK: Mutation

    mutating func addObject(_ object: PlacedHouseObject) {
        placedObjects.append(object)
    }

    mutating func updateObject(id: UUID, with object: PlacedHouseObject) {
        guard let index = placedObjects.firstIndex(where: { $0.id == id }) else { return }
        placedObjects[index] = object
    }

    @discardableResult
    mutating func removeObject(id: UUID) -> PlacedHouseObject? {
        guard let index = placedObjects.firstIndex(where: { $0.id == id }) else { return nil }
        return placedObjects.remove(at: index)
    }

    func object(id: UUID) -> PlacedHouseObject? {
        placedObjects.first { $0.id == id }
    }

}

// MARK: - Scene <-> world geometry

/// Converts saved room coordinates to world-space points and back. The current
/// presentation shows one room scene at a time; the coordinates remain only as
/// persistent room identifiers.
struct HouseSceneMetrics {
    let roomSize: CGSize
    let gap: CGFloat

    var sceneStepWidth: CGFloat { roomSize.width + gap }
    var sceneStepHeight: CGFloat { roomSize.height + gap }

    /// World-space center of a saved room scene. Root scene is at the origin.
    func worldCenter(for position: HouseRoomSceneID) -> CGPoint {
        CGPoint(x: CGFloat(position.col) * sceneStepWidth,
                y: CGFloat(position.row) * sceneStepHeight)
    }

    /// World-space rect of a room placeholder at `position`.
    func worldRect(for position: HouseRoomSceneID) -> CGRect {
        let center = worldCenter(for: position)
        return CGRect(x: center.x - roomSize.width / 2,
                      y: center.y - roomSize.height / 2,
                      width: roomSize.width,
                      height: roomSize.height)
    }

}

// MARK: - Room node (miniroom visual)

private struct HouseMiniroomTheme {
    let wallTop: UIColor
    let wallBottom: UIColor
    let floor: UIColor
    let floorLine: UIColor
    let frame: UIColor
    let accent: UIColor

    static func theme(for position: HouseRoomSceneID) -> HouseMiniroomTheme {
        switch abs(position.col + position.row) % 3 {
        case 1:
            return HouseMiniroomTheme(
                wallTop: UIColor(red: 0.55, green: 0.74, blue: 0.76, alpha: 1),
                wallBottom: UIColor(red: 0.76, green: 0.88, blue: 0.83, alpha: 1),
                floor: UIColor(red: 0.70, green: 0.56, blue: 0.48, alpha: 1),
                floorLine: UIColor(red: 0.42, green: 0.30, blue: 0.28, alpha: 0.26),
                frame: UIColor(red: 0.37, green: 0.25, blue: 0.30, alpha: 1),
                accent: UIColor(red: 0.86, green: 0.48, blue: 0.42, alpha: 1)
            )
        case 2:
            return HouseMiniroomTheme(
                wallTop: UIColor(red: 0.45, green: 0.53, blue: 0.71, alpha: 1),
                wallBottom: UIColor(red: 0.68, green: 0.73, blue: 0.86, alpha: 1),
                floor: UIColor(red: 0.58, green: 0.52, blue: 0.66, alpha: 1),
                floorLine: UIColor(red: 0.28, green: 0.24, blue: 0.38, alpha: 0.24),
                frame: UIColor(red: 0.30, green: 0.24, blue: 0.42, alpha: 1),
                accent: UIColor(red: 0.88, green: 0.70, blue: 0.38, alpha: 1)
            )
        default:
            return HouseMiniroomTheme(
                wallTop: UIColor(red: 0.38, green: 0.64, blue: 0.73, alpha: 1),
                wallBottom: UIColor(red: 0.70, green: 0.86, blue: 0.82, alpha: 1),
                floor: UIColor(red: 0.64, green: 0.49, blue: 0.43, alpha: 1),
                floorLine: UIColor(red: 0.34, green: 0.22, blue: 0.22, alpha: 0.25),
                frame: UIColor(red: 0.27, green: 0.22, blue: 0.33, alpha: 1),
                accent: GameUI.coral
            )
        }
    }
}

/// The focused room scene. It behaves like a framed miniroom stage.
final class HouseRoomNode: SKNode {
    let sceneID: HouseRoomSceneID
    private(set) var surfaceMapping: RoomSurfaceMapping?
    private var floorSurfaceNode: SKShapeNode?

    init(room: HouseRoomScene, metrics: HouseSceneMetrics) {
        self.sceneID = room.position
        super.init()
        position = metrics.worldCenter(for: room.position)
        build(room: room, size: metrics.roomSize)

        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        surfaceMapping = mapping
        applySurfaceMapping(mapping)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(room: HouseRoomScene, size: CGSize) {
        let theme = HouseMiniroomTheme.theme(for: room.position)

        let shadow = SKShapeNode(rectOf: CGSize(width: size.width + 12, height: size.height + 12),
                                 cornerRadius: 22)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.20)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -5)
        shadow.zPosition = -2
        addChild(shadow)

        let body = SKShapeNode(rectOf: size, cornerRadius: 18)
        body.fillTexture = GameUI.gradientTexture(size: size, colors: [theme.wallTop, theme.wallBottom])
        body.fillColor = .white
        body.strokeColor = theme.frame.withAlphaComponent(0.95)
        body.lineWidth = 5
        body.zPosition = 0
        addChild(body)

        let wallpaperHeight = size.height * 0.72
        for i in 0..<6 {
            let x = -size.width / 2 + CGFloat(i + 1) * size.width / 7
            let stripe = SKShapeNode(rectOf: CGSize(width: 1.2, height: wallpaperHeight), cornerRadius: 0.6)
            stripe.fillColor = UIColor.white.withAlphaComponent(0.18)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: x, y: size.height * 0.12)
            stripe.zPosition = 0.5
            addChild(stripe)
        }

        addWindow(size: size, theme: theme)

        let floorHeight = max(80, size.height * 0.32)
        let floor = SKShapeNode(rectOf: CGSize(width: size.width - 14, height: floorHeight),
                                cornerRadius: 6)
        floor.fillColor = theme.floor
        floor.strokeColor = theme.floorLine.withAlphaComponent(0.38)
        floor.lineWidth = 1
        floor.position = CGPoint(x: 0, y: -size.height / 2 + floorHeight / 2 + 7)
        floor.zPosition = 2
        addChild(floor)
        floorSurfaceNode = floor

        for i in 0..<5 {
            let y = floor.position.y - floorHeight / 2 + CGFloat(i + 1) * floorHeight / 6
            let line = SKShapeNode(rectOf: CGSize(width: size.width - 34, height: 1), cornerRadius: 0.5)
            line.fillColor = theme.floorLine
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: y)
            line.zPosition = 2.2
            addChild(line)
        }

        let rug = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.38, height: floorHeight * 0.34))
        rug.fillColor = theme.accent.withAlphaComponent(0.32)
        rug.strokeColor = UIColor.white.withAlphaComponent(0.25)
        rug.lineWidth = 1
        rug.position = CGPoint(x: 0, y: floor.position.y - floorHeight * 0.18)
        rug.zPosition = 2.4
        addChild(rug)

        let inner = SKShapeNode(rectOf: CGSize(width: size.width - 14, height: size.height - 14),
                                cornerRadius: 14)
        inner.fillColor = .clear
        inner.strokeColor = UIColor.white.withAlphaComponent(0.32)
        inner.lineWidth = 1.1
        inner.zPosition = 5
        addChild(inner)
    }

    private func addWindow(size: CGSize, theme: HouseMiniroomTheme) {
        let windowSize = CGSize(width: size.width * 0.24, height: size.height * 0.28)
        let frame = SKShapeNode(rectOf: windowSize, cornerRadius: 9)
        frame.fillColor = UIColor(red: 0.75, green: 0.91, blue: 0.96, alpha: 0.72)
        frame.strokeColor = theme.frame.withAlphaComponent(0.48)
        frame.lineWidth = 2
        frame.position = CGPoint(x: -size.width * 0.22, y: size.height * 0.18)
        frame.zPosition = 1
        addChild(frame)

        let vertical = SKShapeNode(rectOf: CGSize(width: 2, height: windowSize.height - 10), cornerRadius: 1)
        vertical.fillColor = UIColor.white.withAlphaComponent(0.55)
        vertical.strokeColor = .clear
        vertical.position = frame.position
        vertical.zPosition = 1.1
        addChild(vertical)

        let horizontal = SKShapeNode(rectOf: CGSize(width: windowSize.width - 10, height: 2), cornerRadius: 1)
        horizontal.fillColor = UIColor.white.withAlphaComponent(0.55)
        horizontal.strokeColor = .clear
        horizontal.position = frame.position
        horizontal.zPosition = 1.1
        addChild(horizontal)
    }

    // MARK: Surface mapping

    private func applySurfaceMapping(_ mapping: RoomSurfaceMapping) {
        addDebugOverlays(for: mapping)
        installFloorPhysics(for: mapping)
    }

    private func addDebugOverlays(for mapping: RoomSurfaceMapping) {
        let debugNodes = RoomSurfaceMapper.makeInteriorDebugNodes(for: mapping)
        for node in debugNodes {
            node.zPosition = 500
            addChild(node)
        }
    }

    private func installFloorPhysics(for mapping: RoomSurfaceMapping) {
        guard let floor = floorSurfaceNode else { return }
        floor.physicsBody = mapping.makeFloorPhysicsBody()
    }
}

/// Front trim drawn above the mermaid so she visually passes behind the room
/// face while moving through horizontal openings.
final class HouseRoomFrontFrameNode: SKNode {
    let sceneID: HouseRoomSceneID

    init(room: HouseRoomScene, metrics: HouseSceneMetrics) {
        self.sceneID = room.position
        super.init()
        position = metrics.worldCenter(for: room.position)
        build(room: room, size: metrics.roomSize)

        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        addFrameDebugOverlays(for: mapping)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(room: HouseRoomScene, size: CGSize) {
        let theme = HouseMiniroomTheme.theme(for: room.position)
        let tint = theme.frame
        let shadow = UIColor.black.withAlphaComponent(0.28)
        let thickness = max(7, size.width * 0.026)
        let halfW = size.width / 2
        let halfH = size.height / 2

        addBar(size: CGSize(width: size.width + thickness, height: thickness),
               position: CGPoint(x: 0, y: halfH - thickness / 2),
               fill: tint,
               stroke: shadow)
        addBar(size: CGSize(width: size.width + thickness, height: thickness),
               position: CGPoint(x: 0, y: -halfH + thickness / 2),
               fill: tint,
               stroke: shadow)
        addBar(size: CGSize(width: thickness, height: halfH * 2),
               position: CGPoint(x: -halfW + thickness / 2, y: 0),
               fill: tint,
               stroke: shadow)
        addBar(size: CGSize(width: thickness, height: halfH * 2),
               position: CGPoint(x: halfW - thickness / 2, y: 0),
               fill: tint,
               stroke: shadow)
    }

    private func addBar(size: CGSize, position: CGPoint, fill: UIColor, stroke: UIColor) {
        let bar = SKShapeNode(rectOf: size, cornerRadius: min(size.width, size.height) * 0.45)
        bar.fillColor = fill
        bar.strokeColor = stroke
        bar.lineWidth = 1
        bar.position = position
        addChild(bar)
    }

    private func addFrameDebugOverlays(for mapping: RoomSurfaceMapping) {
        let debugNodes = RoomSurfaceMapper.makeFrameDebugNodes(for: mapping)
        for node in debugNodes {
            node.zPosition = 500
            addChild(node)
        }
    }
}

// MARK: - Camera controller

/// Owns the fixed miniroom world container. A world point `P` maps to
/// house-node space as `P * zoom + worldNode.position`; `zoom` is now a fixed
/// fit scale, not a player gesture.
final class HouseCameraController {
    let worldNode = SKNode()

    private let viewportRect: CGRect        // in house-node space
    private var contentBounds: CGRect       // in world space
    private let margin: CGFloat

    private(set) var zoom: CGFloat = 1

    init(viewportRect: CGRect, margin: CGFloat) {
        self.viewportRect = viewportRect
        self.margin = margin
        self.contentBounds = .zero
    }

    /// Applies the fixed fit scale for the focused room.
    func configureZoom(default defaultZoom: CGFloat) {
        zoom = max(0.01, defaultZoom)
        worldNode.setScale(zoom)
    }

    /// Recomputes the focused content bounds from the active room rect.
    func updateContentBounds(rects: [CGRect]) {
        guard var bounds = rects.first else { return }
        for rect in rects.dropFirst() { bounds = bounds.union(rect) }
        bounds = bounds.insetBy(dx: -margin, dy: -margin)
        contentBounds = bounds
    }

    /// Centers the given world point in the viewport, then clamps.
    func center(on worldPoint: CGPoint) {
        worldNode.position = CGPoint(x: viewportRect.midX - worldPoint.x * zoom,
                                     y: viewportRect.midY - worldPoint.y * zoom)
        clamp()
    }

    /// Converts a house-node-space point to world space.
    func worldPoint(fromHousePoint point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x - worldNode.position.x) / zoom,
                y: (point.y - worldNode.position.y) / zoom)
    }

    private func clamp() {
        worldNode.position.x = clampAxis(value: worldNode.position.x,
                                         viewMin: viewportRect.minX,
                                         viewMax: viewportRect.maxX,
                                         contentMin: contentBounds.minX,
                                         contentMax: contentBounds.maxX)
        worldNode.position.y = clampAxis(value: worldNode.position.y,
                                         viewMin: viewportRect.minY,
                                         viewMax: viewportRect.maxY,
                                         contentMin: contentBounds.minY,
                                         contentMax: contentBounds.maxY)
    }

    /// Clamps one axis so the visible window stays inside the content bounds
    /// (accounting for zoom). When the scaled content is smaller than the
    /// viewport on that axis, the content is centered instead.
    private func clampAxis(value: CGFloat,
                           viewMin: CGFloat, viewMax: CGFloat,
                           contentMin: CGFloat, contentMax: CGFloat) -> CGFloat {
        let viewExtent = viewMax - viewMin
        let scaledContentExtent = (contentMax - contentMin) * zoom
        if scaledContentExtent <= viewExtent {
            // Center the content within the viewport.
            let viewCenter = (viewMin + viewMax) / 2
            let contentCenter = (contentMin + contentMax) / 2
            return viewCenter - contentCenter * zoom
        }
        let lower = viewMax - contentMax * zoom
        let upper = viewMin - contentMin * zoom
        return Swift.min(Swift.max(value, lower), upper)
    }
}

// MARK: - Miniroom tray (fixed bottom UI)

private enum HouseFurniturePanelMode: Equatable {
    case inventory
    case placed
}

private struct HouseFurnitureInventoryPanelItem {
    let definition: HouseObjectDefinition
    let availableCount: Int
}

private struct HouseFurniturePlacedPanelItem {
    let object: PlacedHouseObject
    let definition: HouseObjectDefinition
}

private enum HouseFurnitureTrayCategory: CaseIterable {
    case all
    case floor
    case wall

    var title: String {
        switch self {
        case .all: return "Tudo"
        case .floor: return "Chão"
        case .wall: return "Parede"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .floor: return "rectangle.bottomthird.inset.filled"
        case .wall: return "rectangle.portrait.fill"
        }
    }

    var fallback: String {
        switch self {
        case .all: return "*"
        case .floor: return "C"
        case .wall: return "P"
        }
    }

    func includes(_ definition: HouseObjectDefinition) -> Bool {
        switch self {
        case .all:
            return true
        case .floor:
            return definition.placementRules.contains { $0.isCompatible(with: .floor) }
        case .wall:
            return definition.placementRules.contains { $0.isCompatible(with: .backWall) }
        }
    }
}

/// Miniroom-style bottom tray inspired by the reference screens: the room is
/// the hero, and the panel is a visual shelf for decorating or managing placed
/// objects.
final class HouseMiniroomPanel: SKNode {
    let buildButtonName = "house_build_button"
    let storeButtonName = "house_store_button"
    let backButtonName = "house_back_button"
    let houseObjectButtonPrefix = "house_object_button_"
    let placedObjectButtonPrefix = "placed_house_object_button_"

    private let panelSize: CGSize
    private var buildButtonBackground: SKShapeNode!
    private var buildButtonLabel: SKLabelNode!
    private var storeButtonBackground: SKShapeNode!
    private var storeButtonLabel: SKLabelNode!
    private var feedbackLabel: SKLabelNode!
    private var selectionLabel: SKLabelNode!
    private var backButtonBackground: SKShapeNode!
    private var backButtonLabel: SKLabelNode!
    private var trayBackground: SKShapeNode!
    private var emptyLabel: SKLabelNode?
    private var categoryNodes: [HouseFurnitureTrayCategory: SKNode] = [:]
    private var categoryButtonFrames: [HouseFurnitureTrayCategory: CGRect] = [:]
    private var itemNodes: [SKNode] = []
    private var inventoryItems: [HouseFurnitureInventoryPanelItem] = []
    private var placedItems: [HouseFurniturePlacedPanelItem] = []
    private var mode: HouseFurniturePanelMode = .inventory
    private var selectedCategory: HouseFurnitureTrayCategory = .all
    private var selectedPlacedID: UUID?
    private var scrollOffset: CGFloat = 0
    private var trayMinX: CGFloat = 0
    private var trayMaxX: CGFloat = 0
    private var trayCenterY: CGFloat = 0
    private var trayHeight: CGFloat = 0
    private let tileSize: CGFloat = 76
    private let tileSpacing: CGFloat = 14

    private(set) var buildButtonFrame: CGRect = .zero
    private(set) var storeButtonFrame: CGRect = .zero
    private(set) var backButtonFrame: CGRect = .zero
    private(set) var houseObjectButtonFrames: [String: CGRect] = [:]
    private(set) var placedObjectButtonFrames: [UUID: CGRect] = [:]
    private(set) var primaryButtonIsVisible = false
    private(set) var storeButtonIsVisible = false

    init(panelSize: CGSize, bottomCenterY: CGFloat) {
        self.panelSize = panelSize
        super.init()
        position = CGPoint(x: 0, y: bottomCenterY)
        zPosition = 40
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var panelFrame: CGRect {
        CGRect(x: -panelSize.width / 2 + position.x,
               y: -panelSize.height / 2 + position.y,
               width: panelSize.width,
               height: panelSize.height)
    }

    private func build() {
        let topY = panelSize.height / 2
        let bottomY = -panelSize.height / 2

        let bg = SKShapeNode(rectOf: panelSize, cornerRadius: 18)
        bg.fillTexture = GameUI.paperTexture(size: panelSize, base: GameUI.paper)
        bg.fillColor = .white
        bg.strokeColor = GameUI.line.withAlphaComponent(0.50)
        bg.lineWidth = 1.8
        addChild(bg)

        selectionLabel = SKLabelNode(text: "Decoração da casa")
        selectionLabel.fontName = "AvenirNext-Bold"
        selectionLabel.fontSize = 14
        selectionLabel.fontColor = GameUI.ink
        selectionLabel.verticalAlignmentMode = .center
        selectionLabel.horizontalAlignmentMode = .left
        selectionLabel.preferredMaxLayoutWidth = panelSize.width * 0.58
        selectionLabel.numberOfLines = 1
        selectionLabel.position = CGPoint(x: -panelSize.width / 2 + 18, y: topY - 20)
        addChild(selectionLabel)

        feedbackLabel = SKLabelNode(text: "")
        feedbackLabel.fontName = "AvenirNext-DemiBold"
        feedbackLabel.fontSize = 11
        feedbackLabel.fontColor = GameUI.coral
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.horizontalAlignmentMode = .right
        feedbackLabel.preferredMaxLayoutWidth = panelSize.width * 0.38
        feedbackLabel.numberOfLines = 1
        feedbackLabel.position = CGPoint(x: panelSize.width / 2 - 18, y: topY - 20)
        addChild(feedbackLabel)

        let actionHeight: CGFloat = 28
        let actionWidth = min(112, (panelSize.width - 52) / 2)
        let actionY = topY - 52
        buildButtonBackground = actionButton(size: CGSize(width: actionWidth, height: actionHeight),
                                             center: CGPoint(x: -actionWidth / 2 - 6, y: actionY),
                                             fill: GameUI.accent,
                                             name: buildButtonName)
        buildButtonLabel = makeButtonLabel("Mover", size: 12, center: buildButtonBackground.position)
        buildButtonLabel.name = buildButtonName
        addChild(buildButtonLabel)
        setPrimaryButtonVisible(false)

        storeButtonBackground = actionButton(size: CGSize(width: actionWidth, height: actionHeight),
                                             center: CGPoint(x: actionWidth / 2 + 6, y: actionY),
                                             fill: GameUI.coral,
                                             name: storeButtonName)
        storeButtonLabel = makeButtonLabel("Guardar", size: 12, center: storeButtonBackground.position)
        storeButtonLabel.name = storeButtonName
        addChild(storeButtonLabel)
        setStoreButtonVisible(false)

        buildCategoryRow(centerY: topY - 72)

        let buttonHeight: CGFloat = 44
        let buttonBottomPadding: CGFloat = 20
        let buttonY = bottomY + buttonBottomPadding + buttonHeight / 2
        let trayBottom = buttonY + buttonHeight / 2 + 12
        let trayTop = topY - 98
        trayHeight = max(96, trayTop - trayBottom)
        trayCenterY = trayBottom + trayHeight / 2
        let trayWidth = panelSize.width - 28
        trayMinX = -trayWidth / 2
        trayMaxX = trayWidth / 2
        trayBackground = SKShapeNode(rectOf: CGSize(width: trayWidth, height: trayHeight), cornerRadius: 14)
        trayBackground.fillColor = GameUI.palePaper.withAlphaComponent(0.78)
        trayBackground.strokeColor = GameUI.line.withAlphaComponent(0.26)
        trayBackground.lineWidth = 1.2
        trayBackground.position = CGPoint(x: 0, y: trayCenterY)
        addChild(trayBackground)

        let backWidth = min(260, panelSize.width - 64)
        backButtonBackground = tabButton(size: CGSize(width: backWidth, height: buttonHeight),
                                         center: CGPoint(x: 0, y: buttonY),
                                         name: backButtonName)
        backButtonLabel = makeButtonLabel("Voltar", size: 14, center: backButtonBackground.position)
        backButtonLabel.fontColor = GameUI.mutedInk
        backButtonLabel.name = backButtonName
        addChild(backButtonLabel)

        buildButtonFrame = frame(for: buildButtonBackground, size: CGSize(width: actionWidth, height: actionHeight))
        storeButtonFrame = frame(for: storeButtonBackground, size: CGSize(width: actionWidth, height: actionHeight))
        backButtonFrame = frame(for: backButtonBackground, size: CGSize(width: backWidth, height: buttonHeight))
        updateTabs()
        updateCategoryButtons()
    }

    private func actionButton(size: CGSize, center: CGPoint, fill: UIColor, name: String) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: 10)
        button.fillColor = fill
        button.strokeColor = UIColor.white.withAlphaComponent(0.42)
        button.lineWidth = 1.2
        button.position = center
        button.name = name
        addChild(button)
        return button
    }

    private func tabButton(size: CGSize, center: CGPoint, name: String) -> SKShapeNode {
        let button = SKShapeNode(rectOf: size, cornerRadius: 10)
        button.fillColor = GameUI.paper
        button.strokeColor = GameUI.line.withAlphaComponent(0.38)
        button.lineWidth = 1.1
        button.position = center
        button.name = name
        addChild(button)
        return button
    }

    private func buildCategoryRow(centerY: CGFloat) {
        let categories = HouseFurnitureTrayCategory.allCases
        let chipWidth = min(92, (panelSize.width - 44) / CGFloat(categories.count))
        let chipHeight: CGFloat = 30
        let gap: CGFloat = 7
        let totalWidth = CGFloat(categories.count) * chipWidth + CGFloat(categories.count - 1) * gap
        var x = -totalWidth / 2 + chipWidth / 2

        for category in categories {
            let container = SKNode()
            container.position = CGPoint(x: x, y: centerY)
            container.zPosition = 7
            addChild(container)
            categoryNodes[category] = container

            let bg = SKShapeNode(rectOf: CGSize(width: chipWidth, height: chipHeight), cornerRadius: 10)
            bg.name = "house_category_\(category.title)"
            container.addChild(bg)

            let icon = GameUI.symbolIconNode(named: category.symbolName,
                                             fallback: category.fallback,
                                             color: GameUI.mutedInk,
                                             size: 13)
            icon.position = CGPoint(x: -chipWidth / 2 + 15, y: 0)
            container.addChild(icon)

            let label = SKLabelNode(text: category.title)
            label.fontName = "AvenirNext-DemiBold"
            label.fontSize = 10
            label.fontColor = GameUI.mutedInk
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: -chipWidth / 2 + 28, y: 0)
            label.name = bg.name
            container.addChild(label)

            categoryButtonFrames[category] = CGRect(x: container.position.x - chipWidth / 2 + position.x,
                                                    y: container.position.y - chipHeight / 2 + position.y,
                                                    width: chipWidth,
                                                    height: chipHeight)
            x += chipWidth + gap
        }
    }

    private func makeButtonLabel(_ text: String, size: CGFloat, center: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = size
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = center
        return label
    }

    private func frame(for node: SKNode, size: CGSize) -> CGRect {
        CGRect(x: node.position.x - size.width / 2 + position.x,
               y: node.position.y - size.height / 2 + position.y,
               width: size.width,
               height: size.height)
    }

    func setSelectionText(_ text: String) {
        selectionLabel.text = text
    }

    func setPrimaryButtonText(_ text: String) {
        buildButtonLabel.text = text
    }

    func setPrimaryButtonVisible(_ visible: Bool) {
        primaryButtonIsVisible = visible
        buildButtonBackground.isHidden = !visible
        buildButtonLabel.isHidden = !visible
    }

    func setStoreButtonVisible(_ visible: Bool) {
        storeButtonIsVisible = visible
        storeButtonBackground.isHidden = !visible
        storeButtonLabel.isHidden = !visible
    }

    fileprivate func configureFurniture(inventory: [HouseFurnitureInventoryPanelItem],
                                        placed: [HouseFurniturePlacedPanelItem],
                                        mode: HouseFurniturePanelMode,
                                        selectedPlacedID: UUID?) {
        if self.mode != mode {
            scrollOffset = 0
        }
        self.inventoryItems = inventory
        self.placedItems = placed
        self.mode = mode
        self.selectedPlacedID = selectedPlacedID
        clampScrollOffset()
        updateTabs()
        rebuildItems()
    }

    @discardableResult
    func scroll(by deltaX: CGFloat) -> Bool {
        let oldValue = scrollOffset
        scrollOffset += deltaX
        clampScrollOffset()
        guard abs(oldValue - scrollOffset) > 0.5 else { return false }
        rebuildItems()
        return true
    }

    private func updateTabs() {
        styleTab(backButtonBackground, label: backButtonLabel, active: false)
        backButtonLabel.text = "Voltar"
        for (_, node) in categoryNodes {
            node.isHidden = mode != .inventory
        }
    }

    private func styleTab(_ bg: SKShapeNode, label: SKLabelNode, active: Bool) {
        bg.fillColor = active ? GameUI.accent : GameUI.paper
        bg.strokeColor = GameUI.line.withAlphaComponent(active ? 0.64 : 0.34)
        label.fontColor = active ? .white : GameUI.mutedInk
    }

    private func updateCategoryButtons() {
        for category in HouseFurnitureTrayCategory.allCases {
            guard let container = categoryNodes[category],
                  let bg = container.children.compactMap({ $0 as? SKShapeNode }).first else { continue }
            let active = category == selectedCategory
            bg.fillColor = active ? GameUI.coral.withAlphaComponent(0.92) : GameUI.paper.withAlphaComponent(0.92)
            bg.strokeColor = active ? UIColor.white.withAlphaComponent(0.72) : GameUI.line.withAlphaComponent(0.28)
            bg.lineWidth = active ? 1.4 : 1.0
            for child in container.children {
                if let label = child as? SKLabelNode {
                    label.fontColor = active ? .white : GameUI.mutedInk
                }
            }
        }
    }

    @discardableResult
    func handleCategoryTap(at point: CGPoint) -> Bool {
        guard mode == .inventory,
              let category = categoryButtonFrames.first(where: { $0.value.contains(point) })?.key else {
            return false
        }
        guard selectedCategory != category else { return true }
        selectedCategory = category
        scrollOffset = 0
        clampScrollOffset()
        updateCategoryButtons()
        rebuildItems()
        setSelectionText("Decoração da casa")
        return true
    }

    private func rebuildItems() {
        itemNodes.forEach { $0.removeFromParent() }
        itemNodes.removeAll()
        houseObjectButtonFrames.removeAll()
        placedObjectButtonFrames.removeAll()
        emptyLabel?.removeFromParent()
        emptyLabel = nil

        switch mode {
        case .inventory:
            rebuildInventoryTiles()
        case .placed:
            rebuildPlacedTiles()
        }
    }

    private func rebuildInventoryTiles() {
        let visibleItems = filteredInventoryItems()
        guard !visibleItems.isEmpty else {
            let text = selectedCategory == .all ? "Nenhum móvel disponível" : "Nenhum item nessa categoria"
            showEmptyText(text)
            return
        }

        for (index, item) in visibleItems.enumerated() {
            let center = tileCenter(for: index)
            guard tileIsVisible(center.x) else { continue }
            let active = item.availableCount > 0
            let name = houseObjectButtonPrefix + item.definition.id
            let node = makeTile(name: name,
                                definition: item.definition,
                                title: item.definition.displayName,
                                tint: active ? GameUI.coral : GameUI.mutedInk.withAlphaComponent(0.38),
                                selected: false,
                                alpha: active ? 1 : 0.55)
            node.position = center
            addChild(node)
            itemNodes.append(node)

            let badge = badgeNode(text: "x\(item.availableCount)", active: active)
            badge.position = CGPoint(x: tileSize * 0.27, y: tileSize * 0.31)
            badge.name = name
            node.addChild(badge)
            houseObjectButtonFrames[item.definition.id] = tileFrame(center: center)
        }
    }

    private func rebuildPlacedTiles() {
        guard !placedItems.isEmpty else {
            showEmptyText("Nenhum móvel colocado")
            return
        }

        for (index, item) in placedItems.enumerated() {
            let center = tileCenter(for: index)
            guard tileIsVisible(center.x) else { continue }
            let selected = item.object.id == selectedPlacedID
            let name = placedObjectButtonPrefix + item.object.id.uuidString
            let node = makeTile(name: name,
                                definition: item.definition,
                                title: item.definition.displayName,
                                tint: selected ? GameUI.gold : GameUI.accent,
                                selected: selected,
                                alpha: 1)
            node.position = center
            addChild(node)
            itemNodes.append(node)
            if selected {
                let badge = badgeNode(text: "ok", active: true)
                badge.position = CGPoint(x: tileSize * 0.27, y: tileSize * 0.31)
                badge.name = name
                node.addChild(badge)
            }
            placedObjectButtonFrames[item.object.id] = tileFrame(center: center)
        }
    }

    private func makeTile(name: String,
                          definition: HouseObjectDefinition,
                          title: String,
                          tint: UIColor,
                          selected: Bool,
                          alpha: CGFloat) -> SKNode {
        let node = SKNode()
        node.name = name
        node.zPosition = 8
        node.alpha = alpha

        let bg = SKShapeNode(circleOfRadius: tileSize * 0.39)
        bg.fillColor = UIColor.white.withAlphaComponent(selected ? 0.97 : 0.86)
        bg.strokeColor = tint.withAlphaComponent(selected ? 0.95 : 0.58)
        bg.lineWidth = selected ? 2.0 : 1.1
        bg.name = name
        node.addChild(bg)

        let icon = thumbnailNode(for: definition, fallback: "M", tint: tint)
        icon.position = CGPoint(x: 0, y: 6)
        icon.zPosition = 3
        node.addChild(icon)

        let label = SKLabelNode(text: title)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 9
        label.fontColor = GameUI.ink.withAlphaComponent(0.86)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: -tileSize * 0.44)
        label.preferredMaxLayoutWidth = tileSize + 8
        label.numberOfLines = 2
        label.name = name
        node.addChild(label)
        return node
    }

    private func thumbnailNode(for definition: HouseObjectDefinition,
                               fallback: String,
                               tint: UIColor) -> SKNode {
        let container = SKNode()
        if let assetName = definition.assetName {
            let thumbnail = SKSpriteNode(imageNamed: assetName)
            let textureSize = thumbnail.texture?.size() ?? thumbnail.size
            let maxSize = CGSize(width: 43, height: 39)
            let scale = min(maxSize.width / max(1, textureSize.width),
                            maxSize.height / max(1, textureSize.height))
            thumbnail.size = CGSize(width: textureSize.width * scale,
                                    height: textureSize.height * scale)
            thumbnail.alpha = 0.96
            container.addChild(thumbnail)
        } else {
            container.addChild(GameUI.symbolIconNode(named: "cabinet.fill",
                                                     fallback: fallback,
                                                     color: tint,
                                                     size: 20))
        }
        return container
    }

    private func badgeNode(text: String, active: Bool) -> SKNode {
        let badge = SKShapeNode(circleOfRadius: 12)
        badge.fillColor = active ? GameUI.coral : GameUI.fadedPaper
        badge.strokeColor = UIColor.white.withAlphaComponent(0.82)
        badge.lineWidth = 1

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 9
        label.fontColor = active ? .white : GameUI.mutedInk
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        badge.addChild(label)
        return badge
    }

    private func tileCenter(for index: Int) -> CGPoint {
        CGPoint(x: trayMinX + tileSize / 2 + scrollOffset + CGFloat(index) * (tileSize + tileSpacing),
                y: trayCenterY + 5)
    }

    private func tileFrame(center: CGPoint) -> CGRect {
        CGRect(x: center.x - tileSize / 2 + position.x,
               y: center.y - tileSize / 2 + position.y,
               width: tileSize,
               height: tileSize)
    }

    private func tileIsVisible(_ centerX: CGFloat) -> Bool {
        centerX + tileSize / 2 >= trayMinX && centerX - tileSize / 2 <= trayMaxX
    }

    private func showEmptyText(_ text: String) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 13
        label.fontColor = GameUI.mutedInk.withAlphaComponent(0.72)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: trayCenterY)
        addChild(label)
        emptyLabel = label
    }

    private func clampScrollOffset() {
        scrollOffset = scrollOffset.clamped(to: -maxScrollOffset...0)
    }

    private var maxScrollOffset: CGFloat {
        let count: Int
        switch mode {
        case .inventory:
            count = filteredInventoryItems().count
        case .placed:
            count = placedItems.count
        }
        guard count > 0 else { return 0 }
        let contentWidth = CGFloat(count) * tileSize + CGFloat(max(0, count - 1)) * tileSpacing
        let trayWidth = max(1, trayMaxX - trayMinX)
        return max(0, contentWidth - trayWidth)
    }

    private func filteredInventoryItems() -> [HouseFurnitureInventoryPanelItem] {
        inventoryItems.filter { item in
            item.availableCount > 0 && selectedCategory.includes(item.definition)
        }
    }

    func showFeedback(_ text: String, success: Bool) {
        feedbackLabel.removeAllActions()
        feedbackLabel.text = text
        feedbackLabel.fontColor = success ? GameUI.algae : GameUI.coral
        feedbackLabel.alpha = 1
        feedbackLabel.run(.sequence([.wait(forDuration: 2.4), .fadeOut(withDuration: 0.5)]))
    }

    func flashBuildButton() {
        guard primaryButtonIsVisible else { return }
        buildButtonBackground.removeAllActions()
        buildButtonBackground.run(.sequence([
            .scale(to: 0.94, duration: 0.06),
            .scale(to: 1.0, duration: 0.10)
        ]))
    }
}

// MARK: - Mermaid autonomy

final class HouseMermaidAutonomyController {
    private let mermaid: Mermaid
    private let metrics: HouseSceneMetrics

    private var currentRoom: HouseRoomSceneID = HouseSceneDefaults.entrance
    private var idleTimer: CGFloat = CGFloat.random(in: 8.0...14.0)
    private var idlePhase: CGFloat = CGFloat.random(in: 0...(2 * .pi))
    private var moveStart = CGPoint.zero
    private var moveEnd = CGPoint.zero
    private var moveElapsed: CGFloat = 0
    private var moveDuration: CGFloat = 1
    private var destinationRoom: HouseRoomSceneID?

    init(mermaid: Mermaid, metrics: HouseSceneMetrics) {
        self.mermaid = mermaid
        self.metrics = metrics
        mermaid.base.position = restingPoint(for: currentRoom)
    }

    func snap(to room: HouseRoomSceneID) {
        currentRoom = room
        destinationRoom = nil
        mermaid.base.position = restingPoint(for: room)
        mermaid.setAnimationMode(.idle)
        idleTimer = CGFloat.random(in: 9.0...16.0)
    }

    func update(dt: CGFloat, availableRooms: [HouseRoomSceneID]) {
        let playableRooms = availableRooms
            .sorted { lhs, rhs in
                lhs.col == rhs.col ? lhs.row < rhs.row : lhs.col < rhs.col
            }
        guard !playableRooms.isEmpty else { return }

        if !playableRooms.contains(currentRoom) {
            currentRoom = playableRooms[0]
            mermaid.base.position = restingPoint(for: currentRoom)
        }

        if let destination = destinationRoom {
            guard playableRooms.contains(destination) else {
                finishMove(at: currentRoom)
                return
            }
            moveElapsed += dt
            let progress = min(1, moveElapsed / moveDuration)
            let eased = progress * progress * (3 - 2 * progress)
            mermaid.base.position = CGPoint(x: moveStart.x + (moveEnd.x - moveStart.x) * eased,
                                            y: moveStart.y + (moveEnd.y - moveStart.y) * eased)
            if progress >= 1 {
                finishMove(at: destination)
            }
            return
        }

        idlePhase += dt * 2.4
        let rest = restingPoint(for: currentRoom)
        mermaid.base.position = CGPoint(x: rest.x, y: rest.y + sin(idlePhase) * 2.2)

        idleTimer -= dt
        guard idleTimer <= 0 else { return }

        let choices = playableRooms.filter { $0 != currentRoom }
        guard let next = choices.randomElement() else {
            idleTimer = CGFloat.random(in: 8.0...14.0)
            return
        }
        beginMove(to: next)
    }

    private func beginMove(to destination: HouseRoomSceneID) {
        destinationRoom = destination
        moveStart = mermaid.base.position
        moveEnd = restingPoint(for: destination)
        moveElapsed = 0
        let distance = moveStart.distance(to: moveEnd)
        moveDuration = max(2.6, min(5.2, distance / max(1, metrics.sceneStepWidth * 0.34)))

        mermaid.setAnimationMode(.swing)
        if moveEnd.x > moveStart.x {
            mermaid.setVisualDirection(.right)
        } else if moveEnd.x < moveStart.x {
            mermaid.setVisualDirection(.left)
        }
    }

    private func finishMove(at room: HouseRoomSceneID) {
        currentRoom = room
        destinationRoom = nil
        mermaid.base.position = restingPoint(for: room)
        mermaid.setAnimationMode(.idle)
        idleTimer = CGFloat.random(in: 9.0...16.0)
        idlePhase = CGFloat.random(in: 0...(2 * .pi))
    }

    private func restingPoint(for room: HouseRoomSceneID) -> CGPoint {
        let center = metrics.worldCenter(for: room)
        return CGPoint(x: center.x, y: center.y - metrics.roomSize.height * 0.27)
    }
}

// MARK: - Scene controller

/// Top-level controller for the Mermaid House miniroom. Owns the persistent
/// layout, the focused room scene, the mermaid, and the fixed decoration tray.
/// It wires touch input into scene switching, object selection, placement,
/// moving, and storing.
///
/// It is deliberately self-contained: `RefugeHouseInteriorController` drives it
/// through `node`, `update(dt:)`, and the three touch entry points.
final class MermaidHouseSceneController {
    private static let currentDefaultFurnitureRevision = 2
    private static let defaultBirthdayTableObjectID = UUID(uuidString: "25000000-0000-4000-8000-000000000025")!

    let node = SKNode()

    // Player-facing behavior text (shown by the Refuge overlay).
    private(set) var behaviorText = "descansando em casa"

    private unowned let ctx: GameContext
    private let overlaySize: CGSize
    private let safeAreaInsets: UIEdgeInsets
    private let persist: () -> Void
    private let onExit: () -> Void

    private var layout: HouseLayoutData
    private let metrics: HouseSceneMetrics
    private let camera: HouseCameraController
    private let panel: HouseMiniroomPanel

    private let cropNode = SKCropNode()
    private var roomBackLayer = SKNode()
    private var objectsLayer = SKNode()
    private var objectsFrontLayer = SKNode()
    private var roomFrontLayer = SKNode()
    private var mermaidAutonomy: HouseMermaidAutonomyController?

    private var activeRoomPosition: HouseRoomSceneID = .root
    private let placementResolver = HouseObjectPlacementResolver()
    private var activePlacement: ActiveHouseObjectPlacement?
    private var furniturePanelMode: HouseFurniturePanelMode = .inventory
    private var selectedPlacedObjectID: UUID?
    private var roomTitleLabel: SKLabelNode?
    private var roomSubtitleLabel: SKLabelNode?
    private var roomCounterLabel: SKLabelNode?
    private var previousRoomButton: SKNode?
    private var nextRoomButton: SKNode?
    private var previousRoomButtonFrame: CGRect = .zero
    private var nextRoomButtonFrame: CGRect = .zero

    private let viewportRect: CGRect
    private let defaultZoom: CGFloat

    // Gesture tracking: tap/select, horizontal tray scroll, and object drag.
    private var activeTouches: [ObjectIdentifier: CGPoint] = [:]
    private var panLastPoint: CGPoint?
    private var gestureStartPoint: CGPoint?
    private var gestureAccumulated: CGFloat = 0
    private var gestureDidPinch = false
    private var gestureStartedOnPanel = false
    private var gesturePanelDidScroll = false
    private let tapThreshold: CGFloat = 14

    init(overlaySize: CGSize,
         insets: UIEdgeInsets,
         ctx: GameContext,
         persist: @escaping () -> Void,
         onExit: @escaping () -> Void) {
        self.ctx = ctx
        self.overlaySize = overlaySize
        self.safeAreaInsets = insets
        self.persist = persist
        self.onExit = onExit

        var loaded = ctx.stats.houseLayout
        loaded.ensureRootRoom()
        ctx.stats.houseLayout = loaded
        self.layout = loaded
        self.activeRoomPosition = Self.initialRoomPosition(in: loaded)

        // --- Geometry ------------------------------------------------------
        let width = overlaySize.width
        let height = overlaySize.height
        let topSafe = max(0, insets.top)
        let bottomSafe = max(0, insets.bottom)

        let panelHeight = max(270, height * 0.30)
        let panelCenterY = -height / 2 + bottomSafe + panelHeight / 2
        let panelTopY = -height / 2 + bottomSafe + panelHeight

        let topY = height / 2
        let headerHeight = max(96, topSafe + 64)
        let viewBottomY = panelTopY + 8
        let viewTopY = topY - headerHeight
        let viewWidth = width
        let viewHeight = max(220, viewTopY - viewBottomY)
        let viewRect = CGRect(x: -viewWidth / 2,
                              y: viewBottomY,
                              width: viewWidth,
                              height: viewHeight)
        self.viewportRect = viewRect

        // Minirooms are framed scenes, close to a portrait/square stage.
        let roomWidth = viewWidth * 0.84
        let roomHeight = min(viewHeight * 0.92, roomWidth * 1.08)
        self.metrics = HouseSceneMetrics(roomSize: CGSize(width: roomWidth, height: roomHeight),
                                        gap: 0)

        // Fixed fit scale for the focused room.
        let fitByHeight = (viewHeight * 0.98) / roomHeight
        let fitByWidth = (viewWidth * 0.98) / roomWidth
        let fit = Swift.min(fitByHeight, fitByWidth)
        self.defaultZoom = fit

        self.camera = HouseCameraController(viewportRect: viewRect,
                                            margin: 0)
        self.panel = HouseMiniroomPanel(panelSize: CGSize(width: width, height: panelHeight),
                                        bottomCenterY: panelCenterY)

        applyDefaultFurnitureMigrationIfNeeded()
        buildScene()
    }

    private struct ActiveHouseObjectPlacement {
        enum Source {
            case inventory
            case existing(UUID)
        }

        let definition: HouseObjectDefinition
        let roomPosition: HouseRoomSceneID
        let surface: HouseSurfaceKind
        let source: Source
        let previewNode: SKSpriteNode
        var localPoint: CGPoint
        var lastResult: HouseObjectPlacementResult
    }

    private static func initialRoomPosition(in layout: HouseLayoutData) -> HouseRoomSceneID {
        if layout.isOccupied(.root) { return .root }
        return layout.rooms.first?.position ?? .root
    }

    private func applyDefaultFurnitureMigrationIfNeeded() {
        guard layout.defaultFurnitureRevision < Self.currentDefaultFurnitureRevision else { return }

        var changed = false
        changed = removeLegacyDefaultSideboardIfSafe() || changed
        changed = installDefaultBirthdayTableIfNeeded() || changed
        changed = installDefaultBirthdayWallArtIfNeeded() || changed
        layout.defaultFurnitureRevision = Self.currentDefaultFurnitureRevision
        changed = true

        if changed {
            ctx.stats.houseLayout = layout
            persist()
        }
    }

    private func removeLegacyDefaultSideboardIfSafe() -> Bool {
        let sideboards = layout.placedObjects.filter {
            $0.definitionID == HouseObjectCatalog.mermaidSideboardID
            && $0.roomPosition == HouseSceneDefaults.entrance
        }
        guard sideboards.count == 1,
              layout.placedObjects.count == 1,
              let sideboard = sideboards.first else {
            return false
        }
        return layout.removeObject(id: sideboard.id) != nil
    }

    private func installDefaultBirthdayTableIfNeeded() -> Bool {
        guard !layout.placedObjects.contains(where: {
            $0.definitionID == HouseObjectCatalog.mermaidBirthdayTableID
            && $0.roomPosition == HouseSceneDefaults.entrance
        }) else {
            return false
        }
        guard let baseDefinition = HouseObjectCatalog.definition(id: HouseObjectCatalog.mermaidBirthdayTableID),
              layout.isOccupied(HouseSceneDefaults.entrance) else {
            return false
        }

        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let floor = mapping.floor.localRect
        let placementPoint = CGPoint(x: floor.midX - floor.width * 0.23,
                                     y: floor.minY + floor.height * 0.20)
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: .floor,
                                               point: placementPoint)
        guard result.isValid else { return false }

        let objectID = layout.object(id: Self.defaultBirthdayTableObjectID) == nil
            ? Self.defaultBirthdayTableObjectID
            : UUID()
        let object = PlacedHouseObject(id: objectID,
                                       definitionID: definition.id,
                                       roomPosition: HouseSceneDefaults.entrance,
                                       surface: result.surface,
                                       localPosition: result.finalPosition,
                                       zLayerOverride: result.zLayer)
        layout.addObject(object)
        return true
    }

    private static let defaultBirthdayWallArtObjectID = UUID(uuidString: "25000000-0000-4000-8000-000000000026")!

    private func installDefaultBirthdayWallArtIfNeeded() -> Bool {
        guard !layout.placedObjects.contains(where: {
            $0.definitionID == HouseObjectCatalog.mermaidBirthdayWallArtID
            && $0.roomPosition == HouseSceneDefaults.entrance
        }) else {
            return false
        }
        guard let baseDefinition = HouseObjectCatalog.definition(id: HouseObjectCatalog.mermaidBirthdayWallArtID),
              layout.isOccupied(HouseSceneDefaults.entrance) else {
            return false
        }

        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let backWall = mapping.backWall.localRect
        let placementPoint = CGPoint(x: backWall.width * 0.20,
                                      y: backWall.height * 0.24)
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: .backWall,
                                               point: placementPoint)
        guard result.isValid else { return false }

        let objectID = layout.object(id: Self.defaultBirthdayWallArtObjectID) == nil
            ? Self.defaultBirthdayWallArtObjectID
            : UUID()
        let object = PlacedHouseObject(id: objectID,
                                       definitionID: definition.id,
                                       roomPosition: HouseSceneDefaults.entrance,
                                       surface: result.surface,
                                       localPosition: result.finalPosition,
                                       zLayerOverride: result.zLayer)
        layout.addObject(object)
        return true
    }

    // MARK: Scene assembly

    private func buildScene() {
        node.zPosition = 2

        // Full-screen opaque backdrop so the ocean world / refuge decorations
        // behind the overlay never show through while inside the house (the
        // house is a self-contained space, not the exploration map).
        let fullBackdrop = SKShapeNode(rectOf: CGSize(width: overlaySize.width + 8,
                                                      height: overlaySize.height + 8))
        fullBackdrop.fillTexture = GameUI.gradientTexture(
            size: CGSize(width: overlaySize.width, height: overlaySize.height),
            colors: [UIColor(red: 0.10, green: 0.26, blue: 0.36, alpha: 1),
                     UIColor(red: 0.05, green: 0.15, blue: 0.24, alpha: 1),
                     UIColor(red: 0.03, green: 0.09, blue: 0.16, alpha: 1)])
        fullBackdrop.fillColor = .white
        fullBackdrop.strokeColor = .clear
        fullBackdrop.zPosition = -1
        node.addChild(fullBackdrop)
        buildRoomChrome()

        // Viewport clip so the room scene never bleeds over the top status
        // area or the bottom tray.
        let mask = SKShapeNode(rect: CGRect(x: viewportRect.minX,
                                            y: viewportRect.minY,
                                            width: viewportRect.width,
                                            height: viewportRect.height),
                               cornerRadius: 4)
        mask.fillColor = .white
        mask.strokeColor = .clear
        cropNode.maskNode = mask
        cropNode.zPosition = 2
        node.addChild(cropNode)

        // Subtle backdrop inside the viewport to ground the cutaway.
        let backdrop = SKShapeNode(rect: CGRect(x: viewportRect.minX,
                                                y: viewportRect.minY,
                                                width: viewportRect.width,
                                                height: viewportRect.height),
                                   cornerRadius: 4)
        backdrop.fillColor = UIColor(red: 0.05, green: 0.13, blue: 0.22, alpha: 0.35)
        backdrop.strokeColor = UIColor.white.withAlphaComponent(0.12)
        backdrop.lineWidth = 1
        backdrop.zPosition = 0
        cropNode.addChild(backdrop)

        roomBackLayer.zPosition = 1
        objectsLayer.zPosition = 3
        objectsFrontLayer.zPosition = 9_500
        roomFrontLayer.zPosition = 10_000
        camera.worldNode.addChild(roomBackLayer)
        camera.worldNode.addChild(objectsLayer)
        camera.worldNode.addChild(objectsFrontLayer)
        camera.worldNode.addChild(roomFrontLayer)
        cropNode.addChild(camera.worldNode)

        rebuildWorld()
        installMermaid()

        // Fixed bottom tray.
        node.addChild(panel)
        refreshHouseObjectPanel()
        refreshPrimaryButtonState()
        updateRoomChrome()

        // Apply the fixed fit scale and focus the active room.
        camera.configureZoom(default: defaultZoom)
        camera.center(on: metrics.worldCenter(for: activeRoomPosition))
    }

    private func buildRoomChrome() {
        let titleY = overlaySize.height / 2 - max(44, safeAreaInsets.top + 18)

        let title = SKLabelNode(text: "CASA DA SEREIA")
        title.fontName = "AvenirNext-Heavy"
        title.fontSize = 24
        title.fontColor = .white
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: titleY)
        title.zPosition = 35
        node.addChild(title)
        roomTitleLabel = title

        let subtitle = SKLabelNode(text: "")
        subtitle.fontName = "AvenirNext-DemiBold"
        subtitle.fontSize = 13
        subtitle.fontColor = UIColor.white.withAlphaComponent(0.78)
        subtitle.verticalAlignmentMode = .center
        subtitle.horizontalAlignmentMode = .center
        subtitle.position = CGPoint(x: 0, y: titleY - 24)
        subtitle.zPosition = 35
        node.addChild(subtitle)
        roomSubtitleLabel = subtitle

        let counter = SKLabelNode(text: "")
        counter.fontName = "AvenirNext-Bold"
        counter.fontSize = 11
        counter.fontColor = GameUI.paper.withAlphaComponent(0.92)
        counter.verticalAlignmentMode = .center
        counter.horizontalAlignmentMode = .center
        counter.position = CGPoint(x: 0, y: viewportRect.maxY - 18)
        counter.zPosition = 35
        node.addChild(counter)
        roomCounterLabel = counter

        let buttonY = viewportRect.midY
        let buttonSize = CGSize(width: 44, height: 54)
        previousRoomButton = makeRoomSwitchButton(symbol: "chevron.left",
                                                  fallback: "<",
                                                  center: CGPoint(x: viewportRect.minX + 28, y: buttonY),
                                                  size: buttonSize)
        nextRoomButton = makeRoomSwitchButton(symbol: "chevron.right",
                                              fallback: ">",
                                              center: CGPoint(x: viewportRect.maxX - 28, y: buttonY),
                                              size: buttonSize)
        previousRoomButtonFrame = CGRect(x: viewportRect.minX + 6,
                                         y: buttonY - buttonSize.height / 2,
                                         width: buttonSize.width,
                                         height: buttonSize.height)
        nextRoomButtonFrame = CGRect(x: viewportRect.maxX - 50,
                                     y: buttonY - buttonSize.height / 2,
                                     width: buttonSize.width,
                                     height: buttonSize.height)
    }

    private func makeRoomSwitchButton(symbol: String,
                                      fallback: String,
                                      center: CGPoint,
                                      size: CGSize) -> SKNode {
        let container = SKNode()
        container.position = center
        container.zPosition = 36

        let bg = SKShapeNode(rectOf: size, cornerRadius: 12)
        bg.fillColor = GameUI.paper.withAlphaComponent(0.88)
        bg.strokeColor = GameUI.line.withAlphaComponent(0.42)
        bg.lineWidth = 1.2
        container.addChild(bg)

        let icon = GameUI.symbolIconNode(named: symbol,
                                         fallback: fallback,
                                         color: GameUI.mutedInk,
                                         size: 22)
        container.addChild(icon)
        node.addChild(container)
        return container
    }

    /// Regenerates the active room scene and its placed objects. Room counts
    /// are small, so a full rebuild keeps the code simple and correct.
    private func rebuildWorld() {
        roomBackLayer.removeAllChildren()
        objectsLayer.removeAllChildren()
        objectsFrontLayer.removeAllChildren()
        roomFrontLayer.removeAllChildren()

        let rooms = visibleBuiltRooms()
        for room in rooms {
            roomBackLayer.addChild(HouseRoomNode(room: room, metrics: metrics))
            roomFrontLayer.addChild(HouseRoomFrontFrameNode(room: room, metrics: metrics))
        }
        renderPlacedObjects()

        refreshContentBounds()
        refreshHouseObjectPanel()
        updateRoomChrome()
    }

    private func refreshContentBounds() {
        let rects: [CGRect] = visibleBuiltRooms().map { metrics.worldRect(for: $0.position) }
        camera.updateContentBounds(rects: rects)
    }

    private func visibleBuiltRooms() -> [HouseRoomScene] {
        guard let room = layout.room(at: activeRoomPosition) ?? layout.rooms.first else { return [] }
        return [room]
    }

    private func availableRoomPositions() -> [HouseRoomSceneID] {
        [activeRoomPosition]
    }

    private func layerForPlacedObject(surface: HouseSurfaceKind,
                                       localPosition: CGPoint,
                                       displayHeight: CGFloat) -> SKNode {
        let activeSurface = surface.activeMiniroomSurface
        let anchorY: CGFloat = {
            switch activeSurface {
            case .floor:
                return localPosition.y - displayHeight / 2
            default:
                return localPosition.y
            }
        }()
        let zone = HouseObjectPlacementResolver.depthZone(surface: activeSurface,
                                                           anchorY: anchorY,
                                                           roomSize: metrics.roomSize)
        return zone == .inFrontOfMermaid ? objectsFrontLayer : objectsLayer
    }

    private func layerForPlacementResult(_ result: HouseObjectPlacementResult) -> SKNode {
        result.depthZone == .inFrontOfMermaid ? objectsFrontLayer : objectsLayer
    }

    private func renderPlacedObjects() {
        for object in layout.placedObjects where object.roomPosition == activeRoomPosition {
            guard let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
                  layout.isOccupied(object.roomPosition) else { continue }
            let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
            let node = makeObjectNode(definition: definition)
            node.name = "placed_house_object_\(object.id.uuidString)"
            let roomCenter = metrics.worldCenter(for: object.roomPosition)
            let size = CGSize(width: definition.displaySize.width * object.scale,
                              height: definition.displaySize.height * object.scale)
            node.size = size
            node.position = CGPoint(x: roomCenter.x + object.localPosition.x,
                                    y: roomCenter.y + object.localPosition.y - size.height / 2)
            node.zPosition = object.zLayerOverride ?? 0
            if object.id == selectedPlacedObjectID {
                node.addChild(makeSelectedObjectFrame(size: size))
            }
            let targetLayer = layerForPlacedObject(surface: object.surface,
                                                    localPosition: object.localPosition,
                                                    displayHeight: definition.displaySize.height)
            targetLayer.addChild(node)
        }
    }

    private func makeSelectedObjectFrame(size: CGSize) -> SKShapeNode {
        let frame = SKShapeNode(rectOf: CGSize(width: size.width + 14, height: size.height + 14),
                                cornerRadius: 8)
        frame.position = CGPoint(x: 0, y: size.height / 2)
        frame.fillColor = UIColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 0.12)
        frame.strokeColor = UIColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 0.95)
        frame.lineWidth = 2
        frame.zPosition = -1
        return frame
    }

    private func makeObjectNode(definition: HouseObjectDefinition) -> SKSpriteNode {
        let node: SKSpriteNode
        if let assetName = definition.assetName {
            node = SKSpriteNode(imageNamed: assetName)
        } else {
            node = SKSpriteNode(color: GameUI.coral, size: definition.displaySize)
        }
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.size = definition.displaySize
        node.name = "house_object_\(definition.id)"
        return node
    }

    private func refreshHouseObjectPanel() {
        if let selectedPlacedObjectID,
           layout.object(id: selectedPlacedObjectID) == nil {
            self.selectedPlacedObjectID = nil
        }

        let inventoryItems = HouseObjectCatalog.shopDefinitions
            .map { definition in
                HouseFurnitureInventoryPanelItem(
                    definition: definition,
                    availableCount: HouseObjectCatalog.inventoryCount(for: definition.id, stats: ctx.stats)
                )
            }
            .filter { $0.availableCount > 0 }
        let placedItems = layout.placedObjects.compactMap { object -> HouseFurniturePlacedPanelItem? in
            guard object.roomPosition == activeRoomPosition else { return nil }
            guard layout.isOccupied(object.roomPosition),
                  let definition = HouseObjectCatalog.definition(id: object.definitionID) else { return nil }
            return HouseFurniturePlacedPanelItem(object: object,
                                                 definition: definition)
        }
        panel.configureFurniture(inventory: inventoryItems,
                                 placed: placedItems,
                                 mode: furniturePanelMode,
                                 selectedPlacedID: selectedPlacedObjectID)
    }

    private func roomLabel(for position: HouseRoomSceneID) -> String {
        if position == HouseSceneDefaults.entrance { return "Quarto da Sereia" }
        if position == HouseSceneDefaults.firstRoom { return "Sala Coral" }
        if position == HouseSceneDefaults.legacyThirdRoom { return "Ateliê Submerso" }
        return "Cena \(position.col + 1)"
    }

    private func sceneRoomPositions() -> [HouseRoomSceneID] {
        [.root]
    }

    private func updateRoomChrome() {
        let positions = sceneRoomPositions()
        let index = positions.firstIndex(of: activeRoomPosition) ?? 0
        roomTitleLabel?.text = roomLabel(for: activeRoomPosition).uppercased()
        roomSubtitleLabel?.text = "Casa da Sereia"
        roomCounterLabel?.text = positions.count > 1 ? "\(index + 1) / \(positions.count)" : ""
        let canSwitch = positions.count > 1
        previousRoomButton?.isHidden = !canSwitch
        nextRoomButton?.isHidden = !canSwitch
    }

    private func installMermaid() {
        let mermaid = Mermaid()
        if ctx.stats.phase != .egg {
            mermaid.setForm(for: ctx.stats.phase)
        }
        mermaid.applyPalette(.main)
        mermaid.setAnimationMode(.idle)
        mermaid.applyExpression(.neutral, animated: false)

        // Keep the mermaid comfortably smaller than the room so the room reads
        // as a space she lives in, not a tight frame around her.
        let targetHeight = metrics.roomSize.height * 0.11
        let scale = ChallengeChrome.fitScale(for: mermaid.base, targetHeight: targetHeight)
        mermaid.base.setScale(scale)
        mermaid.setVisualDirection(.right)

        // Stand the mermaid inside the focused miniroom.
        let roomCenter = metrics.worldCenter(for: activeRoomPosition)
        mermaid.base.position = CGPoint(x: roomCenter.x,
                                        y: roomCenter.y - metrics.roomSize.height * 0.27)
        mermaid.base.zPosition = 9_000

        camera.worldNode.addChild(mermaid.base)
        mermaidAutonomy = HouseMermaidAutonomyController(mermaid: mermaid, metrics: metrics)
        mermaidAutonomy?.snap(to: activeRoomPosition)
    }

    // MARK: Update

    func update(dt: CGFloat) {
        mermaidAutonomy?.update(dt: dt, availableRooms: availableRoomPositions())
    }

    // MARK: Touch handling
    //
    // The Refuge overlay forwards the raw touch sets. In house mode the
    // controller consumes every touch inside the house area so the ocean map /
    // refuge never reacts behind it.

    /// Returns true if the house consumes this gesture (blocking overlay
    /// handling). Touches outside the house area (e.g. the top strip) are not
    /// consumed so any overlay/HUD controls there keep working.
    func touchesBegan(_ touches: Set<UITouch>, in ref: SKNode) -> Bool {
        let firstFinger = activeTouches.isEmpty
        for touch in touches {
            activeTouches[ObjectIdentifier(touch)] = touch.location(in: ref)
        }

        if firstFinger, let point = touches.first?.location(in: ref) {
            gestureStartPoint = point
            gestureAccumulated = 0
            gestureDidPinch = false
            gestureStartedOnPanel = panel.panelFrame.contains(point)
            gesturePanelDidScroll = false
            panLastPoint = point
            if activePlacement != nil && viewportRect.contains(point) {
                updateActivePlacement(toHousePoint: point)
            }
        }

        if activeTouches.count >= 2 {
            gestureDidPinch = true
        }

        // The house is a self-contained space: consume every touch so the
        // ocean map / refuge behind the overlay never reacts (no accidental
        // exits, no parallel-scene interaction). Taps outside the viewport or
        // panel are simply ignored by the tap handlers.
        return true
    }

    func touchesMoved(_ touches: Set<UITouch>, in ref: SKNode) {
        for touch in touches {
            let key = ObjectIdentifier(touch)
            if activeTouches[key] != nil {
                activeTouches[key] = touch.location(in: ref)
            }
        }

        if activeTouches.count >= 2 {
            gestureDidPinch = true
            panLastPoint = nil
        } else if activeTouches.count == 1, let point = activeTouches.values.first {
            if let last = panLastPoint {
                let delta = CGPoint(x: point.x - last.x, y: point.y - last.y)
                gestureAccumulated += abs(delta.x) + abs(delta.y)
                if activePlacement != nil {
                    updateActivePlacement(toHousePoint: point)
                } else if gestureStartedOnPanel {
                    if panel.scroll(by: delta.x) {
                        gesturePanelDidScroll = true
                    }
                }
            }
            panLastPoint = point
        }
    }

    func touchesEnded(_ touches: Set<UITouch>, in ref: SKNode) {
        for touch in touches {
            activeTouches[ObjectIdentifier(touch)] = nil
        }

        if activeTouches.isEmpty {
            let wasTap = !gestureDidPinch && !gesturePanelDidScroll && gestureAccumulated < tapThreshold
            if wasTap, let point = gestureStartPoint {
                if gestureStartedOnPanel {
                    handlePanelTap(at: point)
                } else if activePlacement != nil {
                    updateActivePlacement(toHousePoint: point)
                    finalizeActivePlacement()
                } else {
                    handleWorldTap(at: point)
                }
            } else if activePlacement != nil, let point = panLastPoint ?? gestureStartPoint {
                updateActivePlacement(toHousePoint: point)
                finalizeActivePlacement()
            }
            resetGesture()
        } else if activeTouches.count == 1 {
            // Dropped from two fingers to one: rebase the pan anchor so the
            // remaining finger does not cause a jump.
            panLastPoint = activeTouches.values.first
        }
    }

    private func resetGesture() {
        panLastPoint = nil
        gestureStartPoint = nil
        gestureAccumulated = 0
        gestureDidPinch = false
        gestureStartedOnPanel = false
        gesturePanelDidScroll = false
    }

    private func handlePanelTap(at point: CGPoint) {
        if panel.primaryButtonIsVisible && panel.buildButtonFrame.contains(point) {
            panel.flashBuildButton()
            if activePlacement != nil {
                cancelActivePlacement(showFeedback: true)
            } else if selectedPlacedObjectID != nil {
                beginMovingSelectedObject()
            } else {
                refreshPrimaryButtonState()
            }
        } else if panel.storeButtonIsVisible && panel.storeButtonFrame.contains(point) {
            storeSelectedObject()
        } else if panel.backButtonFrame.contains(point) {
            GameAudio.shared.play(.uiClosePanel)
            onExit()
        } else if panel.handleCategoryTap(at: point) {
            GameAudio.shared.play(.uiOpenPanel)
        } else if let definitionID = panel.houseObjectButtonFrames.first(where: { $0.value.contains(point) })?.key {
            beginPlacement(definitionID: definitionID)
        } else if let objectID = panel.placedObjectButtonFrames.first(where: { $0.value.contains(point) })?.key {
            selectPlacedObject(id: objectID, centerCamera: true)
        }
    }

    // MARK: Interaction logic

    private func handleWorldTap(at housePoint: CGPoint) {
        if previousRoomButton?.isHidden == false,
           previousRoomButtonFrame.contains(housePoint) {
            switchRoom(by: -1)
            return
        }
        if nextRoomButton?.isHidden == false,
           nextRoomButtonFrame.contains(housePoint) {
            switchRoom(by: 1)
            return
        }

        // Ignore taps outside the viewport (e.g. top status strip).
        guard viewportRect.contains(housePoint) else { return }

        let worldPoint = camera.worldPoint(fromHousePoint: housePoint)
        if let object = placedObject(at: worldPoint) {
            selectPlacedObject(id: object.id, centerCamera: false)
            return
        }

        deselectSelection()
    }

    private func switchRoom(by direction: Int) {
        let positions = sceneRoomPositions()
        guard positions.count > 1 else { return }
        if activePlacement != nil {
            cancelActivePlacement(showFeedback: false)
        }
        let currentIndex = positions.firstIndex(of: activeRoomPosition) ?? 0
        let nextIndex = (currentIndex + direction + positions.count) % positions.count
        activeRoomPosition = positions[nextIndex]
        selectedPlacedObjectID = nil
        furniturePanelMode = .inventory
        camera.center(on: metrics.worldCenter(for: activeRoomPosition))
        mermaidAutonomy?.snap(to: activeRoomPosition)
        rebuildWorld()
        refreshPrimaryButtonState()
        panel.setSelectionText(roomLabel(for: activeRoomPosition))
        GameAudio.shared.play(.uiOpenPanel)
    }

    private func deselectSelection() {
        guard activePlacement == nil else { return }
        selectedPlacedObjectID = nil
        furniturePanelMode = .inventory
        refreshPrimaryButtonState()
        panel.setSelectionText("Decoração da casa")
        rebuildWorld()
    }

    private func refreshPrimaryButtonState() {
        guard activePlacement == nil else { return }
        if selectedPlacedObjectID != nil {
            panel.setPrimaryButtonText("Mover")
            panel.setPrimaryButtonVisible(true)
            panel.setStoreButtonVisible(true)
        } else {
            panel.setPrimaryButtonVisible(false)
            panel.setStoreButtonVisible(false)
        }
        refreshHouseObjectPanel()
    }

    private func selectPlacedObject(id: UUID, centerCamera: Bool) {
        guard activePlacement == nil,
              let object = layout.object(id: id) else { return }
        selectedPlacedObjectID = id
        furniturePanelMode = .placed
        if centerCamera {
            activeRoomPosition = object.roomPosition
            camera.center(on: metrics.worldCenter(for: object.roomPosition))
            mermaidAutonomy?.snap(to: activeRoomPosition)
        }
        panel.setSelectionText("Móvel selecionado")
        refreshPrimaryButtonState()
        rebuildWorld()
        GameAudio.shared.play(.uiOpenPanel)
    }

    private func beginMovingSelectedObject() {
        guard let selectedPlacedObjectID,
              let object = layout.object(id: selectedPlacedObjectID) else {
            refreshPrimaryButtonState()
            return
        }
        beginEditingPlacedObject(object)
    }

    private func storeSelectedObject() {
        guard activePlacement == nil,
              let selectedPlacedObjectID,
              let object = layout.removeObject(id: selectedPlacedObjectID) else {
            refreshPrimaryButtonState()
            return
        }
        self.selectedPlacedObjectID = nil
        furniturePanelMode = .inventory
        ctx.stats.addInventoryItem(id: HouseObjectCatalog.inventoryItemID(object.definitionID),
                                   amount: 1,
                                   autosave: false)
        ctx.stats.houseLayout = layout
        persist()
        rebuildWorld()
        refreshPrimaryButtonState()
        panel.setSelectionText("Móvel guardado no inventário")
        panel.showFeedback("Móvel guardado", success: true)
        GameAudio.shared.play(.uiClosePanel)
    }

    private func placedObject(at worldPoint: CGPoint) -> PlacedHouseObject? {
        layout.placedObjects.reversed().first { object in
            guard object.roomPosition == activeRoomPosition else { return false }
            guard let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
                  layout.isOccupied(object.roomPosition) else { return false }
            let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
            let roomCenter = metrics.worldCenter(for: object.roomPosition)
            let size = CGSize(width: definition.displaySize.width * object.scale,
                              height: definition.displaySize.height * object.scale)
            let center = CGPoint(x: roomCenter.x + object.localPosition.x,
                                 y: roomCenter.y + object.localPosition.y)
            let rect = CGRect(x: center.x - size.width / 2,
                              y: center.y - size.height / 2,
                              width: size.width,
                              height: size.height)
            return rect.contains(worldPoint)
        }
    }

    private func currentVisibleRoomPosition() -> HouseRoomSceneID? {
        layout.isOccupied(activeRoomPosition) ? activeRoomPosition : layout.rooms.first?.position
    }

    private func initialPlacementTarget(for definition: HouseObjectDefinition,
                                        mapping: RoomSurfaceMapping) -> (surface: HouseSurfaceKind, point: CGPoint)? {
        for rule in definition.placementRules {
            for compatibility in rule.surfaceCompatibilities {
                for surface in compatibility.supportedSurfaces {
                    guard let rect = mapping.surfaces[surface]?.localRect else { continue }
                    return (surface, initialPlacementPoint(for: surface, in: rect))
                }
            }
        }
        return nil
    }

    private func initialPlacementPoint(for surface: HouseSurfaceKind, in rect: CGRect) -> CGPoint {
        switch surface.activeMiniroomSurface {
        case .backWall:
            return CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.14)
        case .floor:
            return CGPoint(x: rect.midX, y: rect.midY)
        case .ceiling, .leftWall, .rightWall:
            return CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.14)
        }
    }

    private func beginPlacement(definitionID: String) {
        guard activePlacement == nil else { return }
        guard HouseObjectCatalog.inventoryCount(for: definitionID, stats: ctx.stats) > 0 else {
            panel.showFeedback("Móvel sem estoque", success: false)
            return
        }
        guard let baseDefinition = HouseObjectCatalog.definition(id: definitionID),
              let roomPosition = currentVisibleRoomPosition(),
              layout.isOccupied(roomPosition) else {
            panel.showFeedback("Abra um cômodo para colocar", success: false)
            return
        }

        selectedPlacedObjectID = nil
        furniturePanelMode = .inventory
        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        guard let target = initialPlacementTarget(for: definition, mapping: mapping) else {
            panel.showFeedback("Não foi possível colocar", success: false)
            return
        }
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: target.surface,
                                               point: target.point)
        guard result.isValid else {
            panel.showFeedback(result.validationError ?? "Não foi possível colocar", success: false)
            return
        }

        let preview = makeObjectNode(definition: definition)
        preview.alpha = 0.72
        preview.zPosition = 0
        layerForPlacementResult(result).addChild(preview)

        var placement = ActiveHouseObjectPlacement(definition: definition,
                                                   roomPosition: roomPosition,
                                                   surface: target.surface,
                                                   source: .inventory,
                                                   previewNode: preview,
                                                   localPoint: target.point,
                                                   lastResult: result)
        updatePreviewNode(for: &placement)
        activePlacement = placement
        panel.setPrimaryButtonText("Cancelar colocação")
        panel.setPrimaryButtonVisible(true)
        panel.setStoreButtonVisible(false)
        panel.setSelectionText("Posicionando móvel")
        refreshHouseObjectPanel()
        GameAudio.shared.play(.uiOpenPanel)
    }

    private func beginEditingPlacedObject(_ object: PlacedHouseObject) {
        guard activePlacement == nil,
              let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
              layout.isOccupied(object.roomPosition) else { return }
        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let activeSurface = object.surface.activeMiniroomSurface
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: activeSurface,
                                               point: object.localPosition)
        guard result.isValid else {
            panel.showFeedback(result.validationError ?? "Não foi possível editar", success: false)
            return
        }

        let nodeName = "placed_house_object_\(object.id.uuidString)"
        objectsLayer.childNode(withName: nodeName)?.removeFromParent()
        objectsFrontLayer.childNode(withName: nodeName)?.removeFromParent()
        let preview = makeObjectNode(definition: definition)
        preview.alpha = 0.72
        preview.zPosition = 0
        layerForPlacementResult(result).addChild(preview)

        var placement = ActiveHouseObjectPlacement(definition: definition,
                                                   roomPosition: object.roomPosition,
                                                   surface: activeSurface,
                                                   source: .existing(object.id),
                                                   previewNode: preview,
                                                   localPoint: object.localPosition,
                                                   lastResult: result)
        updatePreviewNode(for: &placement)
        activePlacement = placement
        panel.setPrimaryButtonText("Cancelar colocação")
        panel.setPrimaryButtonVisible(true)
        panel.setStoreButtonVisible(false)
        panel.setSelectionText("Reposicionando móvel")
        refreshHouseObjectPanel()
        GameAudio.shared.play(.uiOpenPanel)
    }

    private func updateActivePlacement(toHousePoint housePoint: CGPoint) {
        guard var placement = activePlacement else { return }
        let worldPoint = camera.worldPoint(fromHousePoint: housePoint)
        let roomCenter = metrics.worldCenter(for: placement.roomPosition)
        let localPoint = CGPoint(x: worldPoint.x - roomCenter.x,
                                 y: worldPoint.y - roomCenter.y)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let result = placementResolver.resolve(definition: placement.definition,
                                               mapping: mapping,
                                               surface: placement.surface,
                                               point: localPoint)
        placement.localPoint = localPoint
        placement.lastResult = result
        updatePreviewNode(for: &placement)
        activePlacement = placement
    }

    private func updatePreviewNode(for placement: inout ActiveHouseObjectPlacement) {
        let roomCenter = metrics.worldCenter(for: placement.roomPosition)
        let position = placement.lastResult.isValid ? placement.lastResult.finalPosition : placement.localPoint
        placement.previewNode.position = CGPoint(x: roomCenter.x + position.x,
                                                 y: roomCenter.y + position.y - placement.definition.displaySize.height / 2)
        placement.previewNode.size = placement.definition.displaySize
        placement.previewNode.color = placement.lastResult.isValid ? .clear : UIColor.red
        placement.previewNode.colorBlendFactor = placement.lastResult.isValid ? 0 : 0.35

        if placement.lastResult.isValid {
            let targetLayer = layerForPlacementResult(placement.lastResult)
            if placement.previewNode.parent !== targetLayer {
                placement.previewNode.removeFromParent()
                targetLayer.addChild(placement.previewNode)
            }
        }
    }

    private func finalizeActivePlacement() {
        guard let placement = activePlacement else { return }
        guard placement.lastResult.isValid else {
            panel.showFeedback(placement.lastResult.validationError ?? "Não foi possível colocar", success: false)
            return
        }
        switch placement.source {
        case .inventory:
            guard ctx.stats.spendInventoryItem(id: HouseObjectCatalog.inventoryItemID(placement.definition.id),
                                               amount: 1,
                                               autosave: false) else {
                cancelActivePlacement(showFeedback: false)
                panel.showFeedback("Móvel sem estoque", success: false)
                return
            }
            let object = PlacedHouseObject(definitionID: placement.definition.id,
                                           roomPosition: placement.roomPosition,
                                           surface: placement.lastResult.surface,
                                           localPosition: placement.lastResult.finalPosition,
                                           zLayerOverride: placement.lastResult.zLayer)
            layout.addObject(object)
            selectedPlacedObjectID = object.id
        case .existing(let id):
            let object = PlacedHouseObject(id: id,
                                           definitionID: placement.definition.id,
                                           roomPosition: placement.roomPosition,
                                           surface: placement.lastResult.surface,
                                           localPosition: placement.lastResult.finalPosition,
                                           zLayerOverride: placement.lastResult.zLayer)
            layout.updateObject(id: id, with: object)
            selectedPlacedObjectID = id
        }
        activePlacement = nil
        placement.previewNode.removeFromParent()
        furniturePanelMode = .placed
        refreshPrimaryButtonState()
        panel.setSelectionText("Móvel selecionado")
        panel.showFeedback("Móvel colocado", success: true)
        GameAudio.shared.play(.uiConfirm)
        ctx.stats.houseLayout = layout
        persist()
        rebuildWorld()
    }

    private func cancelActivePlacement(showFeedback: Bool) {
        guard let placement = activePlacement else { return }
        placement.previewNode.removeFromParent()
        activePlacement = nil
        rebuildWorld()
        refreshPrimaryButtonState()
        panel.setSelectionText(selectedPlacedObjectID == nil
            ? "Decoração da casa"
            : "Móvel selecionado")
        if showFeedback {
            panel.showFeedback("Colocação cancelada", success: false)
            GameAudio.shared.play(.uiClosePanel)
        }
    }

}
