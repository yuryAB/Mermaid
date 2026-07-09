//
//  MermaidHouseSystem.swift
//  Ester
//
//  Expandable "shelter" style Mermaid House (dollhouse / Fallout Shelter
//  side-view cutaway). This MVP replaces the old village-based house
//  interior. The player enters from the Refuge, sees an initial empty
//  3:5 room with the mermaid, can pan the camera freely across an
//  expandable room grid, select a valid empty neighboring slot, and
//  build a new placeholder room from the fixed bottom panel.
//
//  Design constraints for this MVP:
//  - Portrait only. Every room is a vertical rectangle with a 3:5
//    (width:height) proportion, taller than it is wide.
//  - Rooms are simple placeholder SKShapeNode rectangles for now. No
//    final artwork, no image-asset dependency. These nodes will later be
//    swapped for real room images.
//  - Construction is free (no shell cost, no confirmation, no locked
//    types). The player builds a generic empty room.
//  - No construction is allowed to the left of the root/entrance side.
//  - Architecture is prepared for future room types, room costs, object
//    inventories, furniture/decoration slots, and autonomous mermaid
//    movement between rooms.
//
//  All identifiers/comments are in English; every player-facing string is
//  in Brazilian Portuguese.
//

import Foundation
import SpriteKit
import UIKit

// MARK: - Grid model

/// A coordinate on the house construction grid.
///
/// `col` increases to the right, `row` increases upward. The root/entrance
/// room lives at `(0, 0)`. The entrance is on the left, so no room may ever
/// be placed at a negative column (see `HouseLayoutData.isConstructible`).
struct HouseGridPosition: Codable, Hashable {
    var col: Int
    var row: Int

    static let root = HouseGridPosition(col: 0, row: 0)

    var right: HouseGridPosition { HouseGridPosition(col: col + 1, row: row) }
    var left:  HouseGridPosition { HouseGridPosition(col: col - 1, row: row) }
    var up:    HouseGridPosition { HouseGridPosition(col: col, row: row + 1) }
    var down:  HouseGridPosition { HouseGridPosition(col: col, row: row - 1) }

    /// Orthogonal neighbors (right, left, up, down). Diagonals are not
    /// considered adjacent for construction in this MVP.
    var orthogonalNeighbors: [HouseGridPosition] { [right, left, up, down] }
}

// MARK: - MVP access policy

/// Temporary player-facing access rules for the first house MVP. The generic
/// grid model below stays broader so future vertical/paid expansion can return
/// without rewriting persistence.
private enum HouseMVPPolicy {
    static let entrance = HouseGridPosition.root
    static let firstRoom = HouseGridPosition.root.right
    static let unlockablePosition = HouseGridPosition.root.right.right
    static let initialRooms: [HouseGridPosition] = [entrance, firstRoom]
    static let visiblePositions: Set<HouseGridPosition> = [entrance, firstRoom, unlockablePosition]

    static func isPlayable(_ position: HouseGridPosition) -> Bool {
        position.row == 0 && position.col >= 0 && position.col <= 2
    }
}

// MARK: - Room model

/// The kind of a room. Only a generic empty room exists in this MVP, but the
/// enum is the extension point for future purchasable/decoratable room types
/// (bedroom, gift table room, nursery, etc.).
enum HouseRoomType: String, Codable, CaseIterable {
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

/// A single placed room. Persistent placement data plus room type. Future
/// tasks will attach decoration slots, furniture, and object inventories here.
struct HouseRoom: Codable, Hashable {
    var id: UUID
    var position: HouseGridPosition
    var type: HouseRoomType

    // TODO(house): add decoration slots, placed furniture, object inventory,
    // and any per-room state once decoration/purchasing lands.

    init(id: UUID = UUID(), position: HouseGridPosition, type: HouseRoomType = .empty) {
        self.id = id
        self.position = position
        self.type = type
    }
}

// MARK: - Persistent layout

/// The full, persistable house layout. This is intentionally a plain Codable
/// value type so it can be embedded in the existing `MermaidStats` save with
/// no extra persistence machinery. All construction rules live here so both
/// the UI and any future systems share one source of truth.
struct HouseLayoutData: Codable {
    var rooms: [HouseRoom]
    var placedObjects: [PlacedHouseObject]

    private enum CodingKeys: String, CodingKey {
        case rooms
        case placedObjects
    }

    /// Creates a fresh layout containing the entrance and the first room to
    /// the right. The third room is the only visible MVP expansion.
    init() {
        self.rooms = HouseMVPPolicy.initialRooms.map { HouseRoom(position: $0, type: .empty) }
        self.placedObjects = []
    }

    init(rooms: [HouseRoom], placedObjects: [PlacedHouseObject] = []) {
        self.rooms = rooms
        self.placedObjects = placedObjects
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rooms = try c.decodeIfPresent([HouseRoom].self, forKey: .rooms) ?? []
        placedObjects = try c.decodeIfPresent([PlacedHouseObject].self, forKey: .placedObjects) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rooms, forKey: .rooms)
        try c.encode(placedObjects, forKey: .placedObjects)
    }

    /// Guarantees the invariant that the MVP starting rooms always exist
    /// (defends against old/corrupted saves).
    mutating func ensureRootRoom() {
        for position in HouseMVPPolicy.initialRooms where !isOccupied(position) {
            rooms.append(HouseRoom(position: position, type: .empty))
        }
    }

    // MARK: Queries

    var occupiedPositions: Set<HouseGridPosition> { Set(rooms.map(\.position)) }

    func isOccupied(_ position: HouseGridPosition) -> Bool {
        rooms.contains { $0.position == position }
    }

    func room(at position: HouseGridPosition) -> HouseRoom? {
        rooms.first { $0.position == position }
    }

    /// Whether a column is allowed by the "no expansion to the left of the
    /// entrance/root" rule. The entrance is the left edge, so nothing can be
    /// built at a negative column.
    func isConstructible(_ position: HouseGridPosition) -> Bool {
        position.col >= 0
    }

    /// A position is a valid build target when it is empty, on the
    /// constructible side, and orthogonally adjacent to an existing room.
    func isBuildable(_ position: HouseGridPosition) -> Bool {
        buildRejection(at: position) == nil
    }

    /// Reason a position cannot be built on, or `nil` if it is valid. Used to
    /// pick the correct pt-BR feedback message.
    enum BuildRejection {
        case occupied
        case leftOfEntrance
        case notAdjacent
    }

    func buildRejection(at position: HouseGridPosition) -> BuildRejection? {
        if isOccupied(position) { return .occupied }
        if !isConstructible(position) { return .leftOfEntrance }
        let touchesExisting = position.orthogonalNeighbors.contains { isOccupied($0) }
        if !touchesExisting { return .notAdjacent }
        return nil
    }

    /// All empty positions orthogonally adjacent to any room, split by whether
    /// they are valid build targets or blocked by the left-side rule. Blocked
    /// slots are still surfaced so the UI can show clear feedback when tapped.
    func candidateSlots() -> (valid: [HouseGridPosition], blocked: [HouseGridPosition]) {
        var valid = Set<HouseGridPosition>()
        var blocked = Set<HouseGridPosition>()
        for room in rooms {
            for neighbor in room.position.orthogonalNeighbors where !isOccupied(neighbor) {
                if isConstructible(neighbor) {
                    valid.insert(neighbor)
                } else {
                    blocked.insert(neighbor)
                }
            }
        }
        return (Array(valid), Array(blocked))
    }

    // MARK: Mutation

    /// Builds a new room at `position` if it is a valid target. Returns the
    /// created room, or `nil` when construction is not allowed.
    @discardableResult
    mutating func addRoom(at position: HouseGridPosition,
                          type: HouseRoomType = .empty) -> HouseRoom? {
        guard isBuildable(position) else { return nil }
        let room = HouseRoom(position: position, type: type)
        rooms.append(room)
        return room
    }

    @discardableResult
    mutating func removeRoom(at position: HouseGridPosition) -> HouseRoom? {
        guard let index = rooms.firstIndex(where: { $0.position == position }) else { return nil }
        placedObjects.removeAll { $0.roomPosition == position }
        return rooms.remove(at: index)
    }

    mutating func addObject(_ object: PlacedHouseObject) {
        placedObjects.append(object)
    }

    mutating func updateObject(id: UUID, with object: PlacedHouseObject) {
        guard let index = placedObjects.firstIndex(where: { $0.id == id }) else { return }
        placedObjects[index] = object
    }
}

// MARK: - Grid <-> world geometry

/// Converts grid coordinates to world-space points and back. Rooms keep a
/// fixed 3:5 (width:height) proportion; a uniform gap separates cells.
struct HouseGridMetrics {
    let roomSize: CGSize      // 3:5 proportion (width < height)
    let gap: CGFloat

    var cellWidth: CGFloat { roomSize.width + gap }
    var cellHeight: CGFloat { roomSize.height + gap }

    /// World-space center of a grid cell. Root cell is at the world origin.
    func worldCenter(for position: HouseGridPosition) -> CGPoint {
        CGPoint(x: CGFloat(position.col) * cellWidth,
                y: CGFloat(position.row) * cellHeight)
    }

    /// World-space rect of a room placeholder at `position`.
    func worldRect(for position: HouseGridPosition) -> CGRect {
        let center = worldCenter(for: position)
        return CGRect(x: center.x - roomSize.width / 2,
                      y: center.y - roomSize.height / 2,
                      width: roomSize.width,
                      height: roomSize.height)
    }

    /// Rounds an arbitrary world point to the nearest grid position and
    /// returns it only if the point actually falls inside that room's rect
    /// (i.e. not in the gap between cells).
    func gridPosition(forWorldPoint point: CGPoint) -> HouseGridPosition? {
        let col = Int((point.x / cellWidth).rounded())
        let row = Int((point.y / cellHeight).rounded())
        let position = HouseGridPosition(col: col, row: row)
        let rect = worldRect(for: position)
        return rect.contains(point) ? position : nil
    }
}

// MARK: - Room node (placeholder visual)

/// Placeholder visual for a built room: a flat 3:5 rectangle with a pleasant
/// temporary color, clear borders, and a small readable label. This is the
/// node that will later be replaced by real room artwork.
final class HouseRoomNode: SKNode {
    let gridPosition: HouseGridPosition
    private(set) var surfaceMapping: RoomSurfaceMapping?
    private var floorSurfaceNode: SKShapeNode?

    init(room: HouseRoom, metrics: HouseGridMetrics) {
        self.gridPosition = room.position
        super.init()
        position = metrics.worldCenter(for: room.position)
        build(room: room, size: metrics.roomSize)

        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        surfaceMapping = mapping
        applySurfaceMapping(mapping)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(room: HouseRoom, size: CGSize) {
        let isRoot = room.position == .root
        let baseColor = room.type.placeholderColor

        let body = SKShapeNode(rectOf: size, cornerRadius: 10)
        body.fillColor = baseColor.withAlphaComponent(0.92)
        body.strokeColor = UIColor.white.withAlphaComponent(0.85)
        body.lineWidth = 2.5
        body.zPosition = 0
        addChild(body)

        let floor = SKShapeNode(rectOf: CGSize(width: size.width - 8,
                                                height: max(10, size.height * 0.10)),
                                cornerRadius: 4)
        floor.fillColor = UIColor.lerp(baseColor, .black, 0.28).withAlphaComponent(0.9)
        floor.strokeColor = .clear
        floor.position = CGPoint(x: 0, y: -size.height / 2 + max(10, size.height * 0.10) / 2 + 4)
        floor.zPosition = 1
        addChild(floor)
        floorSurfaceNode = floor

        let inner = SKShapeNode(rectOf: CGSize(width: size.width - 10, height: size.height - 10),
                                cornerRadius: 7)
        inner.fillColor = .clear
        inner.strokeColor = UIColor.white.withAlphaComponent(0.22)
        inner.lineWidth = 1
        inner.zPosition = 2
        addChild(inner)

        let label = SKLabelNode(text: isRoot ? "Entrada" : room.type.displayName)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = 12
        label.fontColor = UIColor.white.withAlphaComponent(0.92)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: size.height / 2 - 16)
        label.zPosition = 3
        addChild(label)
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
    let gridPosition: HouseGridPosition

    init(room: HouseRoom, metrics: HouseGridMetrics) {
        self.gridPosition = room.position
        super.init()
        position = metrics.worldCenter(for: room.position)
        build(size: metrics.roomSize)

        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        addFrameDebugOverlays(for: mapping)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size: CGSize) {
        let tint = UIColor.black
        let shadow = UIColor.black
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

// MARK: - Build slot node (empty position marker)

/// A tappable marker for an empty neighboring grid position. Valid slots can
/// be selected and built on; blocked slots (left of the entrance) are shown
/// dimmed and only produce feedback when tapped.
final class HouseBuildSlotNode: SKNode {
    enum Kind {
        case valid
        case blocked   // left of entrance/root — construction not allowed
    }

    let gridPosition: HouseGridPosition
    let kind: Kind
    private let size: CGSize
    private var outline: SKShapeNode!
    private var glyph: SKLabelNode!
    private var buildButtonBg: SKShapeNode?
    private var buildButtonLabel: SKLabelNode?
    private(set) var isSelected = false

    /// Local-space rect of the on-slot "Construir cômodo" button, sitting just
    /// below the "+" glyph. Shared by the node's drawing and the controller's
    /// hit-testing so both stay in sync.
    static func buildButtonLocalRect(roomSize: CGSize) -> CGRect {
        let width = roomSize.width * 0.82
        let height = max(30, roomSize.height * 0.075)
        let centerY = -roomSize.height * 0.05
        return CGRect(x: -width / 2, y: centerY - height / 2, width: width, height: height)
    }

    init(gridPosition: HouseGridPosition, kind: Kind, metrics: HouseGridMetrics) {
        self.gridPosition = gridPosition
        self.kind = kind
        self.size = metrics.roomSize
        super.init()
        position = metrics.worldCenter(for: gridPosition)
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let rect = CGRect(x: -size.width / 2, y: -size.height / 2,
                          width: size.width, height: size.height)
        let path = CGPath(roundedRect: rect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        let dashed = path.copy(dashingWithPhase: 0, lengths: [10, 7])

        outline = SKShapeNode(path: dashed)
        outline.lineWidth = 2
        addChild(outline)

        glyph = SKLabelNode()
        glyph.fontName = "AvenirNext-Bold"
        glyph.fontSize = size.width * 0.16
        glyph.verticalAlignmentMode = .center
        glyph.horizontalAlignmentMode = .center
        // "+" sits above center so the build button fits just below it.
        glyph.position = CGPoint(x: 0, y: size.height * 0.14)
        addChild(glyph)

        if kind == .valid {
            buildBuildButton()
        }

        applyStyle()
    }

    /// The "Construir cômodo" button now lives on the slot itself (below "+"),
    /// not in the bottom panel.
    private func buildBuildButton() {
        let buttonRect = Self.buildButtonLocalRect(roomSize: size)
        let bg = SKShapeNode(rect: buttonRect, cornerRadius: min(12, buttonRect.height * 0.4))
        bg.fillColor = UIColor(red: 0.16, green: 0.62, blue: 0.60, alpha: 1)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.55)
        bg.lineWidth = 1.5
        addChild(bg)
        buildButtonBg = bg

        let label = SKLabelNode(text: "Construir cômodo")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = buttonRect.height * 0.5
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.preferredMaxLayoutWidth = buttonRect.width - 12
        label.position = CGPoint(x: 0, y: buttonRect.midY)
        addChild(label)
        buildButtonLabel = label
    }

    /// Quick press feedback for the on-slot build button.
    func flashBuildButton() {
        guard let bg = buildButtonBg else { return }
        bg.removeAllActions()
        bg.run(.sequence([.scale(to: 0.94, duration: 0.06), .scale(to: 1.0, duration: 0.10)]))
    }

    private func applyStyle() {
        switch kind {
        case .valid:
            let tint = isSelected
                ? UIColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 1)   // gold highlight
                : UIColor.white
            outline.strokeColor = tint.withAlphaComponent(isSelected ? 0.95 : 0.55)
            outline.fillColor = tint.withAlphaComponent(isSelected ? 0.16 : 0.05)
            outline.lineWidth = isSelected ? 3 : 2
            glyph.text = "+"
            glyph.fontColor = tint.withAlphaComponent(isSelected ? 0.95 : 0.6)
        case .blocked:
            let tint = UIColor(red: 0.86, green: 0.42, blue: 0.40, alpha: 1)
            outline.strokeColor = tint.withAlphaComponent(0.5)
            outline.fillColor = tint.withAlphaComponent(0.06)
            outline.lineWidth = 2
            glyph.text = "✕"
            glyph.fontSize = size.width * 0.12
            glyph.position = .zero
            glyph.fontColor = tint.withAlphaComponent(0.6)
        }
    }

    func setSelected(_ selected: Bool) {
        guard kind == .valid, selected != isSelected else { return }
        isSelected = selected
        applyStyle()
    }
}

// MARK: - Camera controller

/// Owns the pannable, zoomable world container for the house. A world point
/// `P` maps to house-node space as `P * zoom + worldNode.position`. Panning is
/// free in all directions and pinch-zoom scales around an anchor. Both are
/// clamped to the current content bounds so the player can inspect the
/// entrance side while never scrolling into empty infinity.
final class HouseCameraController {
    let worldNode = SKNode()

    private let viewportRect: CGRect        // in house-node space
    private var contentBounds: CGRect       // in world space
    private let margin: CGFloat

    private(set) var zoom: CGFloat = 1
    private var minZoom: CGFloat = 0.3
    private var maxZoom: CGFloat = 3

    init(viewportRect: CGRect, margin: CGFloat) {
        self.viewportRect = viewportRect
        self.margin = margin
        self.contentBounds = .zero
    }

    /// Configures the zoom range and applies the default zoom.
    func configureZoom(default defaultZoom: CGFloat, min: CGFloat, max: CGFloat) {
        minZoom = min
        maxZoom = max
        setZoomValue(defaultZoom)
    }

    private func setZoomValue(_ value: CGFloat) {
        zoom = value.clamped(to: minZoom...maxZoom)
        worldNode.setScale(zoom)
    }

    /// Recomputes the scrollable content area from the union of all room and
    /// slot rects, padded by a margin. An extra left margin keeps the
    /// entrance side comfortably inspectable.
    func updateContentBounds(rects: [CGRect]) {
        guard var bounds = rects.first else { return }
        for rect in rects.dropFirst() { bounds = bounds.union(rect) }
        bounds = bounds.insetBy(dx: -margin, dy: -margin)
        // Extra room to pan toward the entrance (left) side.
        bounds.origin.x -= margin
        bounds.size.width += margin
        contentBounds = bounds
    }

    /// Centers the given world point in the viewport, then clamps.
    func center(on worldPoint: CGPoint) {
        worldNode.position = CGPoint(x: viewportRect.midX - worldPoint.x * zoom,
                                     y: viewportRect.midY - worldPoint.y * zoom)
        clamp()
    }

    /// Applies a drag delta (in house-node space) and clamps to bounds.
    func pan(by delta: CGPoint) {
        worldNode.position = CGPoint(x: worldNode.position.x + delta.x,
                                     y: worldNode.position.y + delta.y)
        clamp()
    }

    /// Zooms to `newZoom` keeping the world point under `anchor` (house-node
    /// space) fixed on screen.
    func setZoom(_ newZoom: CGFloat, anchor: CGPoint) {
        let clamped = newZoom.clamped(to: minZoom...maxZoom)
        guard clamped != zoom else { return }
        let anchorWorld = worldPoint(fromHousePoint: anchor)
        setZoomValue(clamped)
        worldNode.position = CGPoint(x: anchor.x - anchorWorld.x * zoom,
                                     y: anchor.y - anchorWorld.y * zoom)
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

// MARK: - Build panel (fixed bottom UI)

/// The fixed bottom house-management panel. It never moves with the camera and
/// is structured to grow later into a full decoration/expansion/inventory UI.
/// It exposes the "Demolir cômodo" action (shown when a built room is
/// selected) and a feedback line. "Construir cômodo" lives on the build slot.
final class HouseBuildPanel: SKNode {
    let buildButtonName = "house_build_button"
    let backButtonName = "house_back_button"
    let houseObjectButtonPrefix = "house_object_button_"

    private let panelSize: CGSize
    private var buildButtonBackground: SKShapeNode!
    private var buildButtonLabel: SKLabelNode!
    private var backButtonBackground: SKShapeNode!
    private var feedbackLabel: SKLabelNode!
    private var selectionLabel: SKLabelNode!
    private var objectRowNodes: [SKNode] = []

    /// Frames of the buttons in house-node space, for hit testing (the panel
    /// is added at the bottom of the house node).
    private(set) var buildButtonFrame: CGRect = .zero
    private(set) var backButtonFrame: CGRect = .zero
    private(set) var houseObjectButtonFrames: [String: CGRect] = [:]
    private(set) var primaryButtonIsVisible = false

    init(panelSize: CGSize, bottomCenterY: CGFloat) {
        self.panelSize = panelSize
        super.init()
        // Anchor the panel so its content sits at the bottom of the screen.
        position = CGPoint(x: 0, y: bottomCenterY)
        zPosition = 40
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build() {
        let bg = SKShapeNode(rectOf: panelSize, cornerRadius: 16)
        bg.fillColor = UIColor(red: 0.06, green: 0.16, blue: 0.26, alpha: 0.96)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.18)
        bg.lineWidth = 1
        addChild(bg)

        // The overlay's own "Voltar" button lives in the lower part of this
        // panel region, so all house controls are packed into the upper part.
        let topY = panelSize.height / 2

        selectionLabel = SKLabelNode(text: "Toque em um espaço livre para construir")
        selectionLabel.fontName = "AvenirNext-Regular"
        selectionLabel.fontSize = 11
        selectionLabel.fontColor = UIColor.white.withAlphaComponent(0.75)
        selectionLabel.verticalAlignmentMode = .center
        selectionLabel.preferredMaxLayoutWidth = panelSize.width - 28
        selectionLabel.numberOfLines = 1
        selectionLabel.position = CGPoint(x: 0, y: topY - 16)
        addChild(selectionLabel)

        feedbackLabel = SKLabelNode(text: "")
        feedbackLabel.fontName = "AvenirNext-DemiBold"
        feedbackLabel.fontSize = 12
        feedbackLabel.fontColor = UIColor(red: 0.98, green: 0.82, blue: 0.36, alpha: 1)
        feedbackLabel.verticalAlignmentMode = .center
        feedbackLabel.preferredMaxLayoutWidth = panelSize.width - 28
        feedbackLabel.numberOfLines = 1
        feedbackLabel.position = CGPoint(x: 0, y: topY - 34)
        addChild(feedbackLabel)

        // Primary panel action = contextual ("Demolir cômodo" / "Cancelar
        // colocação"). "Construir cômodo" lives on the build slot itself.
        let buildSize = CGSize(width: min(260, panelSize.width - 40), height: 42)
        let buildCenter = CGPoint(x: 0, y: topY - 118)

        let buildBg = SKShapeNode(rectOf: buildSize, cornerRadius: 11)
        buildBg.fillColor = UIColor(red: 0.16, green: 0.62, blue: 0.60, alpha: 1)
        buildBg.strokeColor = UIColor.white.withAlphaComponent(0.5)
        buildBg.lineWidth = 1.5
        buildBg.position = buildCenter
        buildBg.name = buildButtonName
        addChild(buildBg)
        buildButtonBackground = buildBg

        let buildLabel = SKLabelNode(text: "Demolir cômodo")
        buildLabel.fontName = "AvenirNext-Bold"
        buildLabel.fontSize = 16
        buildLabel.fontColor = .white
        buildLabel.verticalAlignmentMode = .center
        buildLabel.position = buildCenter
        buildLabel.name = buildButtonName
        addChild(buildLabel)
        buildButtonLabel = buildLabel
        setPrimaryButtonVisible(false)

        // "Voltar" secondary action.
        let backSize = CGSize(width: min(180, panelSize.width - 80), height: 34)
        let backCenter = CGPoint(x: 0, y: buildCenter.y - buildSize.height / 2 - backSize.height / 2 - 10)

        let backBg = SKShapeNode(rectOf: backSize, cornerRadius: 9)
        backBg.fillColor = UIColor(red: 0.10, green: 0.24, blue: 0.34, alpha: 1)
        backBg.strokeColor = UIColor.white.withAlphaComponent(0.4)
        backBg.lineWidth = 1.2
        backBg.position = backCenter
        backBg.name = backButtonName
        addChild(backBg)
        backButtonBackground = backBg

        let backLabel = SKLabelNode(text: "Voltar")
        backLabel.fontName = "AvenirNext-DemiBold"
        backLabel.fontSize = 14
        backLabel.fontColor = UIColor.white.withAlphaComponent(0.92)
        backLabel.verticalAlignmentMode = .center
        backLabel.position = backCenter
        backLabel.name = backButtonName
        addChild(backLabel)

        // Cache the button frames in house-node space for hit testing.
        buildButtonFrame = CGRect(x: buildCenter.x - buildSize.width / 2 + position.x,
                                  y: buildCenter.y - buildSize.height / 2 + position.y,
                                  width: buildSize.width,
                                  height: buildSize.height)
        backButtonFrame = CGRect(x: backCenter.x - backSize.width / 2 + position.x,
                                 y: backCenter.y - backSize.height / 2 + position.y,
                                 width: backSize.width,
                                 height: backSize.height)
    }

    /// Full panel frame in house-node space (used to distinguish panel touches
    /// from world/camera touches).
    var panelFrame: CGRect {
        CGRect(x: -panelSize.width / 2 + position.x,
               y: -panelSize.height / 2 + position.y,
               width: panelSize.width,
               height: panelSize.height)
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

    func configureHouseObjects(_ items: [(definition: HouseObjectDefinition, count: Int)]) {
        for node in objectRowNodes {
            node.removeFromParent()
        }
        objectRowNodes.removeAll()
        houseObjectButtonFrames.removeAll()

        let visibleItems = items.filter { $0.count > 0 || $0.definition.id == HouseObjectCatalog.mermaidSideboardID }
        guard !visibleItems.isEmpty else { return }

        let topY = panelSize.height / 2
        let rowWidth = panelSize.width - 32
        let rowHeight: CGFloat = 40
        let rowSpacing: CGFloat = 6
        let firstY = topY - 68

        for (index, item) in visibleItems.enumerated() {
            let center = CGPoint(x: 0, y: firstY - CGFloat(index) * (rowHeight + rowSpacing))
            let name = houseObjectButtonPrefix + item.definition.id
            let active = item.count > 0
            let tint = active
                ? UIColor(red: 0.95, green: 0.54, blue: 0.50, alpha: 1)
                : UIColor.white.withAlphaComponent(0.34)

            let row = SKNode()
            row.name = name
            row.position = center
            row.zPosition = 6
            row.alpha = active ? 1 : 0.58
            addChild(row)
            objectRowNodes.append(row)

            let bg = SKShapeNode(rectOf: CGSize(width: rowWidth, height: rowHeight), cornerRadius: 10)
            bg.fillColor = tint.withAlphaComponent(active ? 0.30 : 0.12)
            bg.strokeColor = tint.withAlphaComponent(active ? 0.75 : 0.35)
            bg.lineWidth = 1.2
            bg.name = name
            row.addChild(bg)

            let icon = GameUI.symbolIconNode(named: "cabinet.fill",
                                             fallback: "A",
                                             color: active ? tint : UIColor.white.withAlphaComponent(0.42),
                                             size: 17)
            icon.position = CGPoint(x: -rowWidth / 2 + 25, y: 0)
            icon.zPosition = 3
            row.addChild(icon)

            let label = SKLabelNode(text: item.definition.displayName)
            label.fontName = "AvenirNext-DemiBold"
            label.fontSize = 12
            label.fontColor = UIColor.white.withAlphaComponent(active ? 0.92 : 0.46)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -rowWidth / 2 + 48, y: 0)
            label.preferredMaxLayoutWidth = rowWidth - 110
            label.numberOfLines = 1
            label.name = name
            row.addChild(label)

            let count = SKLabelNode(text: "x\(item.count)")
            count.fontName = "AvenirNext-Bold"
            count.fontSize = 12
            count.fontColor = UIColor.white.withAlphaComponent(active ? 0.90 : 0.46)
            count.horizontalAlignmentMode = .right
            count.verticalAlignmentMode = .center
            count.position = CGPoint(x: rowWidth / 2 - 18, y: 0)
            count.name = name
            row.addChild(count)

            houseObjectButtonFrames[item.definition.id] = CGRect(x: center.x - rowWidth / 2 + position.x,
                                                                  y: center.y - rowHeight / 2 + position.y,
                                                                  width: rowWidth,
                                                                  height: rowHeight)
        }
    }

    /// Shows a transient pt-BR feedback message.
    func showFeedback(_ text: String, success: Bool) {
        feedbackLabel.removeAllActions()
        feedbackLabel.text = text
        feedbackLabel.fontColor = success
            ? UIColor(red: 0.56, green: 0.90, blue: 0.62, alpha: 1)
            : UIColor(red: 0.98, green: 0.62, blue: 0.42, alpha: 1)
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
    private let metrics: HouseGridMetrics

    private var currentRoom: HouseGridPosition = HouseMVPPolicy.entrance
    private var idleTimer: CGFloat = CGFloat.random(in: 8.0...14.0)
    private var idlePhase: CGFloat = CGFloat.random(in: 0...(2 * .pi))
    private var moveStart = CGPoint.zero
    private var moveEnd = CGPoint.zero
    private var moveElapsed: CGFloat = 0
    private var moveDuration: CGFloat = 1
    private var destinationRoom: HouseGridPosition?

    init(mermaid: Mermaid, metrics: HouseGridMetrics) {
        self.mermaid = mermaid
        self.metrics = metrics
        mermaid.base.position = restingPoint(for: currentRoom)
    }

    func update(dt: CGFloat, availableRooms: [HouseGridPosition]) {
        let playableRooms = availableRooms
            .filter { HouseMVPPolicy.isPlayable($0) }
            .sorted { lhs, rhs in
                lhs.col == rhs.col ? lhs.row < rhs.row : lhs.col < rhs.col
            }
        guard !playableRooms.isEmpty else { return }

        if !playableRooms.contains(currentRoom) {
            currentRoom = HouseMVPPolicy.entrance
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

    private func beginMove(to destination: HouseGridPosition) {
        destinationRoom = destination
        moveStart = mermaid.base.position
        moveEnd = restingPoint(for: destination)
        moveElapsed = 0
        let distance = moveStart.distance(to: moveEnd)
        moveDuration = max(2.6, min(5.2, distance / max(1, metrics.cellWidth * 0.34)))

        mermaid.setAnimationMode(.swing)
        if moveEnd.x > moveStart.x {
            mermaid.setVisualDirection(.right)
        } else if moveEnd.x < moveStart.x {
            mermaid.setVisualDirection(.left)
        }
    }

    private func finishMove(at room: HouseGridPosition) {
        currentRoom = room
        destinationRoom = nil
        mermaid.base.position = restingPoint(for: room)
        mermaid.setAnimationMode(.idle)
        idleTimer = CGFloat.random(in: 9.0...16.0)
        idlePhase = CGFloat.random(in: 0...(2 * .pi))
    }

    private func restingPoint(for room: HouseGridPosition) -> CGPoint {
        let center = metrics.worldCenter(for: room)
        return CGPoint(x: center.x, y: center.y - metrics.roomSize.height * 0.30)
    }
}

// MARK: - Scene controller

/// Top-level controller for the Mermaid House MVP. Owns the persistent layout,
/// the pannable world (rooms + slots + mermaid), and the fixed bottom panel,
/// and wires touch input into pan/select/build behavior.
///
/// It is deliberately self-contained: `RefugeHouseInteriorController` drives it
/// through `node`, `update(dt:)`, and the three touch entry points.
final class MermaidHouseSceneController {
    let node = SKNode()

    // Player-facing behavior text (shown by the Refuge overlay).
    private(set) var behaviorText = "descansando em casa"

    private unowned let ctx: GameContext
    private let overlaySize: CGSize
    private let persist: () -> Void
    private let onExit: () -> Void

    private var layout: HouseLayoutData
    private let metrics: HouseGridMetrics
    private let camera: HouseCameraController
    private let panel: HouseBuildPanel

    private let cropNode = SKCropNode()
    private var roomBackLayer = SKNode()
    private var objectsLayer = SKNode()
    private var roomFrontLayer = SKNode()
    private var slotsLayer = SKNode()
    private var mermaidAutonomy: HouseMermaidAutonomyController?

    private var slotNodes: [HouseBuildSlotNode] = []
    private var selectedSlot: HouseGridPosition?
    private var selectedDemolitionRoom: HouseGridPosition?
    private let placementResolver = HouseObjectPlacementResolver()
    private var activePlacement: ActiveHouseObjectPlacement?
    private var furnitureEditModeEnabled = false

    private let viewportRect: CGRect
    private let defaultZoom: CGFloat
    private let minZoom: CGFloat
    private let maxZoom: CGFloat

    // Multi-touch gesture tracking (pan with one finger, pinch-zoom with two).
    private var activeTouches: [ObjectIdentifier: CGPoint] = [:]
    private var pinchActive = false
    private var lastPinchDistance: CGFloat = 0
    private var lastPinchMidpoint: CGPoint = .zero
    private var panLastPoint: CGPoint?
    private var gestureStartPoint: CGPoint?
    private var gestureAccumulated: CGFloat = 0
    private var gestureDidPinch = false
    private var gestureStartedOnPanel = false
    private let tapThreshold: CGFloat = 14

    init(overlaySize: CGSize,
         insets _: UIEdgeInsets,
         ctx: GameContext,
         persist: @escaping () -> Void,
         onExit: @escaping () -> Void) {
        self.ctx = ctx
        self.overlaySize = overlaySize
        self.persist = persist
        self.onExit = onExit

        var loaded = ctx.stats.houseLayout
        loaded.ensureRootRoom()
        ctx.stats.houseLayout = loaded
        self.layout = loaded

        // --- Geometry ------------------------------------------------------
        let width = overlaySize.width
        let height = overlaySize.height

        let panelHeight = max(200, height * 0.22)
        let panelCenterY = -height / 2 + panelHeight / 2
        let panelTopY = -height / 2 + panelHeight

        let topY = height / 2
        let viewBottomY = panelTopY + 4
        let viewWidth = width
        let viewHeight = max(200, topY - viewBottomY)
        let viewRect = CGRect(x: -viewWidth / 2,
                              y: viewBottomY,
                              width: viewWidth,
                              height: viewHeight)
        self.viewportRect = viewRect

        // Rooms keep a fixed 3:5 (width:height) proportion and are flush
        // against each other (no gap). Their world size is a fixed reference;
        // the camera zoom decides how large they appear on screen.
        let roomHeight = viewHeight
        let roomWidth = roomHeight * 3.0 / 5.0
        self.metrics = HouseGridMetrics(roomSize: CGSize(width: roomWidth, height: roomHeight),
                                        gap: 0)

        // Default zoom fits the whole room inside the viewport (so by default a
        // single room fills the screen). Pinch can zoom in for detail or out to
        // survey several rooms.
        let fitByHeight = (viewHeight * 0.98) / roomHeight
        let fitByWidth = (viewWidth * 0.98) / roomWidth
        let fit = Swift.min(fitByHeight, fitByWidth)
        self.defaultZoom = fit
        self.minZoom = fit * 0.35
        self.maxZoom = fit * 2.4

        self.camera = HouseCameraController(viewportRect: viewRect,
                                            margin: metrics.cellHeight * 0.6)
        self.panel = HouseBuildPanel(panelSize: CGSize(width: width, height: panelHeight),
                                     bottomCenterY: panelCenterY)

        buildScene()
    }

    private struct ActiveHouseObjectPlacement {
        enum Source {
            case inventory
            case existing(UUID)
        }

        let definition: HouseObjectDefinition
        let roomPosition: HouseGridPosition
        let surface: HouseSurfaceKind
        let source: Source
        let previewNode: SKSpriteNode
        var localPoint: CGPoint
        var lastResult: HouseObjectPlacementResult
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

        // Viewport clip so panning content never bleeds over the top status
        // area or the bottom panel.
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
        slotsLayer.zPosition = 2
        // The mermaid rig has child nodes with their own zPositions; keep the
        // front silhouettes far above the whole rig so no body part can draw
        // over the room frame.
        roomFrontLayer.zPosition = 10_000
        camera.worldNode.addChild(slotsLayer)
        camera.worldNode.addChild(roomBackLayer)
        camera.worldNode.addChild(objectsLayer)
        camera.worldNode.addChild(roomFrontLayer)
        cropNode.addChild(camera.worldNode)

        rebuildWorld()
        installMermaid()

        // Fixed bottom panel (never moves with the camera).
        node.addChild(panel)
        refreshHouseObjectPanel()
        refreshPrimaryButtonState()

        // Apply the default zoom (room fills the screen) and focus the
        // initial/root room.
        camera.configureZoom(default: defaultZoom, min: minZoom, max: maxZoom)
        camera.center(on: metrics.worldCenter(for: .root))
    }

    /// Regenerates all room and slot nodes from the current layout, then
    /// refreshes the camera content bounds. Room counts are small, so a full
    /// rebuild keeps the code simple and correct.
    private func rebuildWorld() {
        roomBackLayer.removeAllChildren()
        objectsLayer.removeAllChildren()
        roomFrontLayer.removeAllChildren()
        slotsLayer.removeAllChildren()
        slotNodes.removeAll()

        let rooms = visibleBuiltRooms()
        for room in rooms {
            roomBackLayer.addChild(HouseRoomNode(room: room, metrics: metrics))
            roomFrontLayer.addChild(HouseRoomFrontFrameNode(room: room, metrics: metrics))
        }
        renderPlacedObjects()

        if mvpUnlockableSlotIsAvailable {
            let position = HouseMVPPolicy.unlockablePosition
            let slot = HouseBuildSlotNode(gridPosition: position, kind: .valid, metrics: metrics)
            slot.setSelected(position == selectedSlot)
            slotNodes.append(slot)
            slotsLayer.addChild(slot)
        } else if selectedSlot == HouseMVPPolicy.unlockablePosition {
            selectedSlot = nil
        }
        if let selectedDemolitionRoom,
           !layout.isOccupied(selectedDemolitionRoom) {
            self.selectedDemolitionRoom = nil
            panel.setPrimaryButtonText("Demolir cômodo")
            panel.setPrimaryButtonVisible(false)
        }

        refreshContentBounds()
        refreshHouseObjectPanel()
    }

    private func refreshContentBounds() {
        var rects: [CGRect] = visibleBuiltRooms().map { metrics.worldRect(for: $0.position) }
        for slot in slotNodes {
            rects.append(metrics.worldRect(for: slot.gridPosition))
        }
        camera.updateContentBounds(rects: rects)
    }

    private var mvpUnlockableSlotIsAvailable: Bool {
        layout.isOccupied(HouseMVPPolicy.firstRoom)
            && !layout.isOccupied(HouseMVPPolicy.unlockablePosition)
    }

    private func visibleBuiltRooms() -> [HouseRoom] {
        layout.rooms
            .filter { HouseMVPPolicy.visiblePositions.contains($0.position) }
            .sorted { lhs, rhs in
                lhs.position.col == rhs.position.col
                    ? lhs.position.row < rhs.position.row
                    : lhs.position.col < rhs.position.col
            }
    }

    private func availableRoomPositions() -> [HouseGridPosition] {
        visibleBuiltRooms().map(\.position)
    }

    private func renderPlacedObjects() {
        for object in layout.placedObjects {
            guard let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
                  layout.isOccupied(object.roomPosition) else { continue }
            let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
            let node = makeObjectNode(definition: definition)
            node.name = "placed_house_object_\(object.id.uuidString)"
            let roomCenter = metrics.worldCenter(for: object.roomPosition)
            let size = CGSize(width: definition.defaultSize.width * object.scale,
                              height: definition.defaultSize.height * object.scale)
            node.size = size
            node.position = CGPoint(x: roomCenter.x + object.localPosition.x,
                                    y: roomCenter.y + object.localPosition.y - size.height / 2)
            node.zPosition = object.zLayerOverride ?? HouseObjectPlacementResolver.defaultZLayer(for: object.surface)
            node.zRotation = object.rotation
            objectsLayer.addChild(node)
        }
    }

    private func makeObjectNode(definition: HouseObjectDefinition) -> SKSpriteNode {
        let node: SKSpriteNode
        if let assetName = definition.assetName {
            node = SKSpriteNode(imageNamed: assetName)
        } else {
            node = SKSpriteNode(color: GameUI.coral, size: definition.defaultSize)
        }
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.size = definition.defaultSize
        node.name = "house_object_\(definition.id)"
        return node
    }

    private func refreshHouseObjectPanel() {
        let items = HouseObjectCatalog.shopDefinitions.map {
            (definition: $0, count: HouseObjectCatalog.inventoryCount(for: $0.id, stats: ctx.stats))
        }
        panel.configureHouseObjects(items)
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

        // Stand the mermaid on the floor band of the root room.
        let rootCenter = metrics.worldCenter(for: .root)
        mermaid.base.position = CGPoint(x: rootCenter.x,
                                        y: rootCenter.y - metrics.roomSize.height * 0.30)
        mermaid.base.zPosition = 9_000

        camera.worldNode.addChild(mermaid.base)
        mermaidAutonomy = HouseMermaidAutonomyController(mermaid: mermaid, metrics: metrics)
    }

    // MARK: Update

    func update(dt: CGFloat) {
        mermaidAutonomy?.update(dt: dt, availableRooms: availableRoomPositions())
    }

    // MARK: Touch handling
    //
    // The Refuge overlay forwards the raw touch sets. One finger pans the
    // camera; two fingers pinch-zoom. In house mode the controller consumes
    // every touch inside the house area so the ocean map / refuge never
    // reacts behind it (no accidental exits, no parallel-scene bleed).

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
            panLastPoint = point
            if activePlacement != nil && viewportRect.contains(point) {
                updateActivePlacement(toHousePoint: point)
            }
        }

        if activeTouches.count >= 2 {
            pinchActive = false   // re-initialized on first pinch move
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
            handlePinch()
        } else if activeTouches.count == 1, let point = activeTouches.values.first {
            if let last = panLastPoint {
                let delta = CGPoint(x: point.x - last.x, y: point.y - last.y)
                gestureAccumulated += abs(delta.x) + abs(delta.y)
                if activePlacement != nil {
                    updateActivePlacement(toHousePoint: point)
                } else if !gestureStartedOnPanel {
                    camera.pan(by: delta)
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
            let wasTap = !gestureDidPinch && gestureAccumulated < tapThreshold
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
            pinchActive = false
        }
    }

    private func handlePinch() {
        let points = Array(activeTouches.values)
        guard points.count >= 2 else { return }
        let a = points[0]
        let b = points[1]
        let distance = a.distance(to: b)
        let midpoint = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)

        if pinchActive, lastPinchDistance > 0 {
            let factor = distance / lastPinchDistance
            camera.setZoom(camera.zoom * factor, anchor: midpoint)
            let panDelta = CGPoint(x: midpoint.x - lastPinchMidpoint.x,
                                   y: midpoint.y - lastPinchMidpoint.y)
            camera.pan(by: panDelta)
        } else {
            pinchActive = true
            gestureDidPinch = true
        }
        lastPinchDistance = distance
        lastPinchMidpoint = midpoint
        panLastPoint = nil
    }

    private func resetGesture() {
        pinchActive = false
        lastPinchDistance = 0
        panLastPoint = nil
        gestureStartPoint = nil
        gestureAccumulated = 0
        gestureDidPinch = false
        gestureStartedOnPanel = false
    }

    private func handlePanelTap(at point: CGPoint) {
        // The bottom panel's primary button is the "Demolir cômodo" action.
        // "Construir cômodo" now lives on the build slot itself.
        if panel.primaryButtonIsVisible && panel.buildButtonFrame.contains(point) {
            panel.flashBuildButton()
            if activePlacement != nil {
                cancelActivePlacement(showFeedback: true)
            } else if selectedDemolitionRoom != nil {
                performDemolition()
            } else {
                toggleFurnitureEditMode()
            }
        } else if panel.backButtonFrame.contains(point) {
            GameAudio.shared.play(.uiClosePanel)
            onExit()
        } else if let definitionID = panel.houseObjectButtonFrames.first(where: { $0.value.contains(point) })?.key {
            beginPlacement(definitionID: definitionID)
        }
    }

    // MARK: Interaction logic

    private func handleWorldTap(at housePoint: CGPoint) {
        // Ignore taps outside the viewport (e.g. top status strip).
        guard viewportRect.contains(housePoint) else { return }

        let worldPoint = camera.worldPoint(fromHousePoint: housePoint)
        if furnitureEditModeEnabled,
           let object = placedObject(at: worldPoint) {
            beginEditingPlacedObject(object)
            return
        }

        guard let position = metrics.gridPosition(forWorldPoint: worldPoint) else {
            deselectSelection()
            return
        }

        guard HouseMVPPolicy.isPlayable(position) else {
            deselectSelection()
            return
        }

        if layout.isOccupied(position) {
            if position == HouseMVPPolicy.unlockablePosition {
                selectRoomForDemolition(position)
            } else {
                deselectSelection()
            }
            return
        }

        // Empty buildable slot: the "Construir cômodo" button now lives on the
        // slot itself (below the "+"). Building only happens when that button
        // is tapped; tapping elsewhere on the frame does nothing.
        if position == HouseMVPPolicy.unlockablePosition && mvpUnlockableSlotIsAvailable {
            let slotCenter = metrics.worldCenter(for: position)
            let buttonRect = HouseBuildSlotNode.buildButtonLocalRect(roomSize: metrics.roomSize)
                .offsetBy(dx: slotCenter.x, dy: slotCenter.y)
            if buttonRect.contains(worldPoint) {
                deselectSelection()
                performBuild(at: position)
            }
        } else {
            deselectSelection()
        }
    }

    private func selectRoomForDemolition(_ position: HouseGridPosition) {
        selectedSlot = nil
        selectedDemolitionRoom = position
        for slot in slotNodes where slot.kind == .valid {
            slot.setSelected(false)
        }
        panel.setPrimaryButtonText("Demolir cômodo")
        panel.setPrimaryButtonVisible(true)
        panel.setSelectionText("Cômodo selecionado. Toque em “Demolir cômodo”.")
    }

    private func deselectSelection() {
        guard activePlacement == nil else { return }
        selectedSlot = nil
        selectedDemolitionRoom = nil
        for slot in slotNodes where slot.kind == .valid {
            slot.setSelected(false)
        }
        refreshPrimaryButtonState()
        panel.setSelectionText("Toque em um espaço livre para construir")
    }

    private func refreshPrimaryButtonState() {
        guard activePlacement == nil, selectedDemolitionRoom == nil else { return }
        if !layout.placedObjects.isEmpty {
            panel.setPrimaryButtonText(furnitureEditModeEnabled ? "Sair da edição" : "Editar móveis")
            panel.setPrimaryButtonVisible(true)
        } else {
            furnitureEditModeEnabled = false
            panel.setPrimaryButtonText("Demolir cômodo")
            panel.setPrimaryButtonVisible(false)
        }
    }

    private func toggleFurnitureEditMode() {
        guard activePlacement == nil,
              selectedDemolitionRoom == nil,
              !layout.placedObjects.isEmpty else { return }
        furnitureEditModeEnabled.toggle()
        panel.setSelectionText(furnitureEditModeEnabled
            ? "Edição de móveis: toque em um móvel"
            : "Toque em um espaço livre para construir")
        refreshPrimaryButtonState()
        GameAudio.shared.play(furnitureEditModeEnabled ? .uiOpenPanel : .uiClosePanel)
    }

    private func placedObject(at worldPoint: CGPoint) -> PlacedHouseObject? {
        layout.placedObjects.reversed().first { object in
            guard let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
                  layout.isOccupied(object.roomPosition) else { return false }
            let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
            let roomCenter = metrics.worldCenter(for: object.roomPosition)
            let size = CGSize(width: definition.defaultSize.width * object.scale,
                              height: definition.defaultSize.height * object.scale)
            let center = CGPoint(x: roomCenter.x + object.localPosition.x,
                                 y: roomCenter.y + object.localPosition.y)
            let rect = CGRect(x: center.x - size.width / 2,
                              y: center.y - size.height / 2,
                              width: size.width,
                              height: size.height)
            return rect.contains(worldPoint)
        }
    }

    private func currentVisibleRoomPosition() -> HouseGridPosition? {
        let visibleRooms = visibleBuiltRooms()
        guard !visibleRooms.isEmpty else { return nil }
        let center = camera.worldPoint(fromHousePoint: CGPoint(x: viewportRect.midX, y: viewportRect.midY))
        return visibleRooms.min { lhs, rhs in
            metrics.worldCenter(for: lhs.position).distance(to: center)
                < metrics.worldCenter(for: rhs.position).distance(to: center)
        }?.position
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

        selectedSlot = nil
        selectedDemolitionRoom = nil
        furnitureEditModeEnabled = false
        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let floor = mapping.floor.localRect
        let startPoint = CGPoint(x: floor.midX, y: floor.midY)
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: .floor,
                                               point: startPoint)
        guard result.isValid else {
            panel.showFeedback(result.validationError ?? "Não foi possível colocar", success: false)
            return
        }

        let preview = makeObjectNode(definition: definition)
        preview.alpha = 0.72
        preview.zPosition = result.zLayer + 1
        objectsLayer.addChild(preview)

        var placement = ActiveHouseObjectPlacement(definition: definition,
                                                   roomPosition: roomPosition,
                                                   surface: .floor,
                                                   source: .inventory,
                                                   previewNode: preview,
                                                   localPoint: startPoint,
                                                   lastResult: result)
        updatePreviewNode(for: &placement)
        activePlacement = placement
        panel.setPrimaryButtonText("Cancelar colocação")
        panel.setPrimaryButtonVisible(true)
        panel.setSelectionText("Arraste o móvel no chão e solte")
        GameAudio.shared.play(.uiOpenPanel)
    }

    private func beginEditingPlacedObject(_ object: PlacedHouseObject) {
        guard activePlacement == nil,
              let baseDefinition = HouseObjectCatalog.definition(id: object.definitionID),
              layout.isOccupied(object.roomPosition) else { return }
        let definition = HouseObjectCatalog.definition(baseDefinition, scaledFor: metrics.roomSize)
        let mapping = RoomSurfaceMapper.map(roomSize: metrics.roomSize)
        let result = placementResolver.resolve(definition: definition,
                                               mapping: mapping,
                                               surface: object.surface,
                                               point: object.localPosition)
        guard result.isValid else {
            panel.showFeedback(result.validationError ?? "Não foi possível editar", success: false)
            return
        }

        objectsLayer.childNode(withName: "placed_house_object_\(object.id.uuidString)")?.removeFromParent()
        let preview = makeObjectNode(definition: definition)
        preview.alpha = 0.72
        preview.zPosition = result.zLayer + 1
        objectsLayer.addChild(preview)

        var placement = ActiveHouseObjectPlacement(definition: definition,
                                                   roomPosition: object.roomPosition,
                                                   surface: object.surface,
                                                   source: .existing(object.id),
                                                   previewNode: preview,
                                                   localPoint: object.localPosition,
                                                   lastResult: result)
        updatePreviewNode(for: &placement)
        activePlacement = placement
        panel.setPrimaryButtonText("Cancelar colocação")
        panel.setPrimaryButtonVisible(true)
        panel.setSelectionText("Arraste o móvel e solte")
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
                                                 y: roomCenter.y + position.y - placement.definition.defaultSize.height / 2)
        placement.previewNode.size = placement.definition.defaultSize
        placement.previewNode.color = placement.lastResult.isValid ? .clear : UIColor.red
        placement.previewNode.colorBlendFactor = placement.lastResult.isValid ? 0 : 0.35
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
        case .existing(let id):
            let object = PlacedHouseObject(id: id,
                                           definitionID: placement.definition.id,
                                           roomPosition: placement.roomPosition,
                                           surface: placement.lastResult.surface,
                                           localPosition: placement.lastResult.finalPosition,
                                           zLayerOverride: placement.lastResult.zLayer)
            layout.updateObject(id: id, with: object)
        }
        activePlacement = nil
        placement.previewNode.removeFromParent()
        refreshPrimaryButtonState()
        panel.setSelectionText(furnitureEditModeEnabled
            ? "Edição de móveis: toque em um móvel"
            : "Toque em um espaço livre para construir")
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
        panel.setSelectionText(furnitureEditModeEnabled
            ? "Edição de móveis: toque em um móvel"
            : "Toque em um espaço livre para construir")
        if showFeedback {
            panel.showFeedback("Colocação cancelada", success: false)
            GameAudio.shared.play(.uiClosePanel)
        }
    }

    private func performDemolition() {
        guard let target = selectedDemolitionRoom,
              target == HouseMVPPolicy.unlockablePosition,
              layout.isOccupied(target) else {
            panel.showFeedback("Selecione o cômodo construído", success: false)
            deselectSelection()
            return
        }

        guard layout.removeRoom(at: target) != nil else {
            panel.showFeedback("Selecione o cômodo construído", success: false)
            deselectSelection()
            return
        }

        selectedDemolitionRoom = nil
        if layout.placedObjects.isEmpty {
            furnitureEditModeEnabled = false
        }
        rebuildWorld()
        panel.setSelectionText("Toque em um espaço livre para construir")
        refreshPrimaryButtonState()
        panel.showFeedback("Cômodo demolido", success: true)
        GameAudio.shared.play(.uiClosePanel)

        ctx.stats.houseLayout = layout
        persist()
    }

    /// Builds the room at `target` (triggered by the on-slot "Construir cômodo"
    /// button).
    private func performBuild(at target: HouseGridPosition) {
        guard target == HouseMVPPolicy.unlockablePosition,
              mvpUnlockableSlotIsAvailable else {
            panel.showFeedback("Selecione o espaço livre à direita", success: false)
            return
        }

        // Re-validate against the model in case the layout changed.
        switch layout.buildRejection(at: target) {
        case .leftOfEntrance:
            panel.showFeedback("Não é possível construir deste lado", success: false)
            return
        case .some:
            panel.showFeedback("Selecione um espaço vazio", success: false)
            return
        case .none:
            break
        }

        guard layout.addRoom(at: target, type: .empty) != nil else {
            panel.showFeedback("Selecione um espaço vazio", success: false)
            return
        }

        selectedSlot = nil
        rebuildWorld()
        panel.setSelectionText("Toque em um espaço livre para construir")
        panel.showFeedback("Cômodo criado", success: true)
        GameAudio.shared.play(.uiConfirm)

        // Persist the new layout through the existing save system.
        ctx.stats.houseLayout = layout
        persist()
    }
}
