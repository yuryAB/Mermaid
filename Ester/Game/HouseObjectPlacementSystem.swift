//
//  HouseObjectPlacementSystem.swift
//  Ester
//
//  Architecture foundation for Mermaid House object placement.
//  Defines models for object definitions, placement rules, attachment
//  sides, surface compatibility, placed object instances, and a
//  placement resolver that validates and computes final positions.
//
//  The focused miniroom house has two active placement surfaces: floor
//  and back wall. Older ceiling/side-wall values remain decodable only
//  as legacy surface data.
//

import Foundation
import SpriteKit

// MARK: - Attachment side

/// Which side of an object "sticks" to the target surface.
/// This is the magnet side — the resolver aligns this edge against
/// the corresponding surface edge.
enum HouseObjectAttachmentSide: String, Codable, CaseIterable {
    /// Object sits on top of the floor (bottom edge touches floor top).
    case bottom
    /// Legacy attachment side for old ceiling debug objects.
    case top
    /// Legacy attachment side for old side-wall debug objects.
    case left
    /// Legacy attachment side for old side-wall debug objects.
    case right
    /// Object lies flat against the back wall (faces the camera).
    case back
}

// MARK: - Surface compatibility

/// Describes which surface kinds and attachment side work together
/// for a given placement rule.
struct HouseObjectSurfaceCompatibility: Codable {
    let supportedSurfaces: [HouseSurfaceKind]
    let attachmentSide: HouseObjectAttachmentSide
}

// MARK: - Object category

enum HouseObjectCategory: String, Codable, CaseIterable {
    case floorFurniture
    case backWallDecoration
    // Legacy debug categories kept for decode/source compatibility.
    case ceilingDecoration
    case leftWallDecoration
    case rightWallDecoration
    case functional
    case container
}

// MARK: - Placement rule

/// One placement rule for an object definition. An object may have
/// several rules if it can be placed on multiple surface kinds.
struct HouseObjectPlacementRule: Codable {
    /// All compatible (surface kind, attachment side) pairs.
    let surfaceCompatibilities: [HouseObjectSurfaceCompatibility]

    /// When `true`, the object snaps to discrete slots instead of
    /// free‑positioning within the surface.
    let requiresSlot: Bool

    /// When `true`, the player can drag the object freely within the
    /// surface bounds. When `false`, the object snaps to a fixed anchor.
    let allowsFreePositioning: Bool

    /// Default offset applied after the attachment alignment (in room‑local
    /// coordinates). Useful for visual tweaks so objects do not clip into
    /// the frame or floor edge.
    let defaultOffset: CGPoint

    /// Preferred z‑layer override. When `nil` the resolver picks a
    /// sensible default per surface kind.
    let preferredZLayer: CGFloat?

    init(surfaceCompatibilities: [HouseObjectSurfaceCompatibility],
         requiresSlot: Bool = false,
         allowsFreePositioning: Bool = true,
         defaultOffset: CGPoint = .zero,
         preferredZLayer: CGFloat? = nil) {
        self.surfaceCompatibilities = surfaceCompatibilities
        self.requiresSlot = requiresSlot
        self.allowsFreePositioning = allowsFreePositioning
        self.defaultOffset = defaultOffset
        self.preferredZLayer = preferredZLayer
    }

    /// Returns `true` when this rule supports at least one of the given
    /// surface kinds.
    func isCompatible(with surface: HouseSurfaceKind) -> Bool {
        surfaceCompatibilities.contains { $0.supportedSurfaces.contains(surface) }
    }

    /// Returns the attachment side for a specific surface kind, or `nil`
    /// when the surface is not compatible with this rule.
    func attachmentSide(for surface: HouseSurfaceKind) -> HouseObjectAttachmentSide? {
        surfaceCompatibilities.first { $0.supportedSurfaces.contains(surface) }?.attachmentSide
    }
}

// MARK: - Object definition

/// Describes what a future house object *is*. The definition is shared
/// across all placed instances of the same type (e.g. all dressers).
/// Instances are stored as `PlacedHouseObject`.
struct HouseObjectDefinition: Codable, Identifiable {
    let id: String
    let name: String
    let displayName: String          // pt‑BR
    let assetName: String?
    let category: HouseObjectCategory
    let placementRules: [HouseObjectPlacementRule]
    let defaultSize: CGSize
    let isInteractive: Bool
    let needsPhysics: Bool
    let placementOffset: CGPoint?    // optional fine‑tune offset

    init(id: String,
         name: String,
         displayName: String,
         assetName: String? = nil,
         category: HouseObjectCategory,
         placementRules: [HouseObjectPlacementRule],
         defaultSize: CGSize,
         isInteractive: Bool = false,
         needsPhysics: Bool = false,
         placementOffset: CGPoint? = nil) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.assetName = assetName
        self.category = category
        self.placementRules = placementRules
        self.defaultSize = defaultSize
        self.isInteractive = isInteractive
        self.needsPhysics = needsPhysics
        self.placementOffset = placementOffset
    }
}

// MARK: - Placed object instance

/// A single placed object instance inside a specific room.
struct PlacedHouseObject: Codable, Identifiable {
    let id: UUID
    let definitionID: String
    let roomPosition: HouseRoomSceneID
    let surface: HouseSurfaceKind
    var localPosition: CGPoint
    var scale: CGFloat
    var zLayerOverride: CGFloat?
    var statePayload: Data?         // future Codable state

    init(id: UUID = UUID(),
         definitionID: String,
         roomPosition: HouseRoomSceneID,
         surface: HouseSurfaceKind,
         localPosition: CGPoint,
         scale: CGFloat = 1,
         zLayerOverride: CGFloat? = nil,
         statePayload: Data? = nil) {
        self.id = id
        self.definitionID = definitionID
        self.roomPosition = roomPosition
        self.surface = surface
        self.localPosition = localPosition
        self.scale = scale
        self.zLayerOverride = zLayerOverride
        self.statePayload = statePayload
    }
}

// MARK: - Placement result

/// Returned by `HouseObjectPlacementResolver` after validating a
/// placement request. When `isValid` is `true`, `finalPosition` and
/// `zLayer` are usable values; otherwise `validationError` explains
/// the rejection.
struct HouseObjectPlacementResult {
    let isValid: Bool
    let validationError: String?
    let finalPosition: CGPoint
    let attachmentSide: HouseObjectAttachmentSide
    let surface: HouseSurfaceKind
    let zLayer: CGFloat
    let depthZone: HouseObjectDepthZone

    static func success(position: CGPoint,
                        attachmentSide: HouseObjectAttachmentSide,
                        surface: HouseSurfaceKind,
                        zLayer: CGFloat,
                        depthZone: HouseObjectDepthZone) -> HouseObjectPlacementResult {
        HouseObjectPlacementResult(isValid: true,
                                   validationError: nil,
                                   finalPosition: position,
                                   attachmentSide: attachmentSide,
                                   surface: surface,
                                   zLayer: zLayer,
                                   depthZone: depthZone)
    }

    static func failure(reason: String,
                        surface: HouseSurfaceKind = .backWall) -> HouseObjectPlacementResult {
        HouseObjectPlacementResult(isValid: false,
                                   validationError: reason,
                                   finalPosition: .zero,
                                   attachmentSide: .back,
                                   surface: surface,
                                   zLayer: 0,
                                   depthZone: .behindMermaid)
    }
}

// MARK: - Depth zone (which parent layer the object lives in)

enum HouseObjectDepthZone {
    /// Behind the mermaid — same depth as the back wall.
    case behindMermaid
    /// In front of the mermaid — between the mermaid and the front frame.
    case inFrontOfMermaid

    /// Parent‑layer zPosition inside `camera.worldNode` for this zone.
    var layerZPosition: CGFloat {
        switch self {
        case .behindMermaid:     return 3
        case .inFrontOfMermaid:  return 9_500
        }
    }
}

// MARK: - Placement resolver

/// Validates compatibility and computes the final position, attachment
/// alignment, and z‑layer for a future object being placed in a room.
final class HouseObjectPlacementResolver {

    // MARK: Z‑layer defaults per surface

    /// Default z‑positions per surface kind. These are used as hints by
    /// the scene controller; the final parent layer is chosen by
    /// `depthZone(surface:centerY:roomSize:)`.
    static func defaultZLayer(for surface: HouseSurfaceKind) -> CGFloat {
        switch surface.activeMiniroomSurface {
        case .floor:     return 10
        case .backWall:  return 3
        case .ceiling, .leftWall, .rightWall:
            return 3
        }
    }

    /// Determines which parent layer a placed object belongs in so the
    /// mermaid correctly passes in front of or behind furniture.
    ///
    /// For floor objects, `anchorY` is the bottom edge of the object;
    /// for ceiling it's the top edge; for walls it's the centre.
    /// The comparison uses the midpoint of the placement zone so the
    /// result is independent of object height.
    static func depthZone(surface: HouseSurfaceKind,
                          anchorY: CGFloat,
                          roomSize: CGSize) -> HouseObjectDepthZone {
        switch surface.activeMiniroomSurface {
        case .floor:
            let threshold = floorAnchorThreshold(roomSize: roomSize)
            return anchorY > threshold ? .behindMermaid : .inFrontOfMermaid
        case .backWall:
            return .behindMermaid
        case .ceiling, .leftWall, .rightWall:
            return .behindMermaid
        }
    }

    // MARK: Floor depth sorting

    /// Y‑axis midpoint of the floor surface band (room‑local).
    /// Used as the split‑point: anchor above this → behind mermaid,
    /// anchor at or below → in front.
    static func floorAnchorThreshold(roomSize: CGSize) -> CGFloat {
        let floorHeight = max(80, roomSize.height * 0.32)
        return -roomSize.height / 2 + floorHeight / 2 + 4
    }

    // MARK: Resolve

    /// Validates compatibility and computes the final placement result.
    ///
    /// - Parameters:
    ///   - definition: The object being placed.
    ///   - mapping: The target room's mapped surfaces.
    ///   - surface: Which surface the player tapped / selected.
    ///   - point: The desired point in room‑local space.
    ///   - slotID: Optional slot identifier for slot‑based placement.
    /// - Returns: A validated `HouseObjectPlacementResult`.
    func resolve(definition: HouseObjectDefinition,
                 mapping: RoomSurfaceMapping,
                 surface: HouseSurfaceKind,
                 point: CGPoint,
                 slotID: String? = nil) -> HouseObjectPlacementResult {

        let activeSurface = surface.activeMiniroomSurface

        // ---- 1. Find a compatible placement rule ---------------------------
        guard let rule = definition.placementRules.first(where: { $0.isCompatible(with: activeSurface) }),
              let attachmentSide = rule.attachmentSide(for: activeSurface) else {
            return .failure(
                reason: "\(definition.displayName) não pode ser colocado em \(activeSurface.debugLabel).",
                surface: activeSurface
            )
        }

        // ---- 2. Slot check ------------------------------------------------
        if rule.requiresSlot && slotID == nil {
            return .failure(
                reason: "\(definition.displayName) precisa de um espaço específico.",
                surface: activeSurface
            )
        }

        // ---- 3. Compute two containers ------------------------------------
        //
        //  anchorZone    – where the attachment edge may be placed. Floor
        //                  objects keep their bottom edge on the floor band;
        //                  back‑wall objects anchor anywhere on the room
        //                  interior.
        //  visualBounds  – room interior used to keep the full visible asset
        //                  inside the room frame (applied on top of the
        //                  anchor zone for objects that extend beyond it).
        let roomRect = mapping.backWall.localRect
        guard let surfaceRect = mapping.surfaces[activeSurface]?.localRect else {
            return .failure(
                reason: "\(definition.displayName) não pode ser colocado em \(activeSurface.debugLabel).",
                surface: activeSurface
            )
        }

        let anchorZone: CGRect = {
            switch activeSurface {
            case .floor:
                return surfaceRect
            case .backWall:
                return roomRect
            case .ceiling, .leftWall, .rightWall:
                return roomRect
            }
        }()
        let visualBounds = roomRect

        // ---- 4. Clamp: first to anchor zone, then visual containment ------
        let objectSize = definition.displaySize
        let clampedPoint: CGPoint
        if rule.allowsFreePositioning {
            clampedPoint = resolveAnchor(
                rawPoint: point,
                objectSize: objectSize,
                attachmentSide: attachmentSide,
                anchorZone: anchorZone,
                visualBounds: visualBounds
            )
        } else {
            clampedPoint = CGPoint(x: surfaceRect.midX, y: surfaceRect.midY)
        }

        // ---- 5. Compute final position based on attachment side ------------
        let finalLocalPosition = alignedCenter(
            attachmentSide: attachmentSide,
            objectSize: objectSize,
            point: clampedPoint
        )

        let offset = rule.defaultOffset
        let offsetPosition = CGPoint(x: finalLocalPosition.x + offset.x,
                                     y: finalLocalPosition.y + offset.y)

        // ---- 6. Determine z‑layer and depth zone --------------------------
        let depthZone = Self.depthZone(surface: activeSurface,
                                        anchorY: clampedPoint.y,
                                        roomSize: mapping.roomSize)
        let baseZLayer = rule.preferredZLayer ?? Self.defaultZLayer(for: activeSurface)
        let zLayer = baseZLayer

        // ---- 7. Log for debug / validation --------------------------------
        Self.logPlacement(definition: definition,
                          attachmentSide: attachmentSide,
                          surface: activeSurface,
                          finalPosition: offsetPosition,
                          zLayer: zLayer)

        return .success(position: offsetPosition,
                        attachmentSide: attachmentSide,
                        surface: activeSurface,
                        zLayer: zLayer,
                        depthZone: depthZone)
    }

    // MARK: Anchor‑point resolution (two‑stage clamping)

    /// First clamps the anchor point to the allowed placement zone, then
    /// further restricts it so the full object bounding rect stays inside
    /// `visualBounds`. Returns the safe anchor point.
    private func resolveAnchor(rawPoint: CGPoint,
                               objectSize: CGSize,
                               attachmentSide: HouseObjectAttachmentSide,
                               anchorZone: CGRect,
                               visualBounds: CGRect) -> CGPoint {
        let hw = objectSize.width / 2
        let hh = objectSize.height / 2

        // Stage A — anchor is free to move within the placement zone.
        let clampedX = rawPoint.x.clamped(to: anchorZone.minX...anchorZone.maxX)
        let clampedY = rawPoint.y.clamped(to: anchorZone.minY...anchorZone.maxY)
        var result = CGPoint(x: clampedX, y: clampedY)

        // Stage B — tighten so the full object stays inside visualBounds.
        switch attachmentSide {
        case .back:
            result.x = result.x.clamped(to: visualBounds.minX + hw ... visualBounds.maxX - hw)
            result.y = result.y.clamped(to: visualBounds.minY + hh ... visualBounds.maxY - hh)
        case .bottom:
            result.x = result.x.clamped(to: visualBounds.minX + hw ... visualBounds.maxX - hw)
            result.y = result.y.clamped(to: visualBounds.minY ... visualBounds.maxY - 2 * hh)
        case .top:
            result.x = result.x.clamped(to: visualBounds.minX + hw ... visualBounds.maxX - hw)
            result.y = result.y.clamped(to: visualBounds.minY + 2 * hh ... visualBounds.maxY)
        case .left:
            result.x = result.x.clamped(to: visualBounds.minX ... visualBounds.maxX - 2 * hw)
            result.y = result.y.clamped(to: visualBounds.minY + hh ... visualBounds.maxY - hh)
        case .right:
            result.x = result.x.clamped(to: visualBounds.minX + 2 * hw ... visualBounds.maxX)
            result.y = result.y.clamped(to: visualBounds.minY + hh ... visualBounds.maxY - hh)
        }

        return result
    }

    // MARK: Alignment helpers

    /// Converts the clamped anchor point to the object's center position
    /// based on attachment side.
    private func alignedCenter(attachmentSide: HouseObjectAttachmentSide,
                                objectSize: CGSize,
                                point: CGPoint) -> CGPoint {
        let hw = objectSize.width / 2
        let hh = objectSize.height / 2

        switch attachmentSide {
        case .bottom:
            return CGPoint(x: point.x, y: point.y + hh)
        case .top:
            return CGPoint(x: point.x, y: point.y - hh)
        case .left:
            return CGPoint(x: point.x + hw, y: point.y)
        case .right:
            return CGPoint(x: point.x - hw, y: point.y)
        case .back:
            return CGPoint(x: point.x, y: point.y)
        }
    }

    // MARK: Debug logging

    /// When `debugValidationEnabled` is `true`, logs each placement
    /// resolution to the console so developers can verify compatibility
    /// rules and final positions without running the full game.
    static var debugValidationEnabled = true

    private static func logPlacement(definition: HouseObjectDefinition,
                                     attachmentSide: HouseObjectAttachmentSide,
                                     surface: HouseSurfaceKind,
                                     finalPosition: CGPoint,
                                     zLayer: CGFloat) {
        guard debugValidationEnabled else { return }
        print("[HouseObjectPlacement] \(definition.displayName) → "
              + "surface=\(surface.rawValue) side=\(attachmentSide.rawValue) "
              + "pos=(\(String(format: "%.0f", finalPosition.x)),"
              + "\(String(format: "%.0f", finalPosition.y))) "
              + "z=\(String(format: "%.1f", zLayer))")
    }
}

// MARK: - Sample definitions (debug / architecture validation)

/// Static catalog of sample object definitions used only for
/// validation and architecture testing. Not exposed as gameplay
/// objects and never rendered in production.
extension HouseObjectDefinition {

    /// When `true`, `sampleDefinitions` and `makeDebugPlaceholder(for:)`
    /// are available. Toggle off before shipping.
    static var debugSamplesEnabled = true

    /// A handful of representative definitions covering the active miniroom
    /// surfaces so we can validate the resolver.
    static var sampleDefinitions: [HouseObjectDefinition] {
        guard debugSamplesEnabled else { return [] }
        return [
            HouseObjectDefinition(
                id: "sample_dresser",
                name: "Dresser",
                displayName: "Cômoda",
                assetName: nil,
                category: .floorFurniture,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.floor],
                                attachmentSide: .bottom
                            )
                        ],
                        defaultOffset: CGPoint(x: 0, y: 0)
                    )
                ],
                defaultSize: CGSize(width: 60, height: 48),
                isInteractive: true,
                needsPhysics: true
            ),
            HouseObjectDefinition(
                id: "sample_bed",
                name: "Bed",
                displayName: "Cama",
                assetName: nil,
                category: .floorFurniture,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.floor],
                                attachmentSide: .bottom
                            )
                        ],
                        defaultOffset: CGPoint(x: 0, y: 0)
                    )
                ],
                defaultSize: CGSize(width: 80, height: 20),
                isInteractive: true,
                needsPhysics: true
            ),
            HouseObjectDefinition(
                id: "sample_table",
                name: "Table",
                displayName: "Mesa",
                assetName: nil,
                category: .floorFurniture,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.floor],
                                attachmentSide: .bottom
                            )
                        ],
                        defaultOffset: CGPoint(x: 0, y: 0)
                    )
                ],
                defaultSize: CGSize(width: 70, height: 36),
                isInteractive: true,
                needsPhysics: true
            ),
            HouseObjectDefinition(
                id: "sample_painting",
                name: "Painting",
                displayName: "Quadro",
                assetName: nil,
                category: .backWallDecoration,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.backWall],
                                attachmentSide: .back
                            )
                        ],
                        defaultOffset: .zero
                    )
                ],
                defaultSize: CGSize(width: 40, height: 30),
                isInteractive: false,
                needsPhysics: false
            ),
        ]
    }

    // MARK: Debug placeholder visual

    /// Creates a simple coloured rectangle + label representing a placed
    /// object. This is a development‑only visual aid, never shown in
    /// production. Caller is responsible for adding the node to the
    /// correct layer and position.
    static func makeDebugPlaceholder(for definition: HouseObjectDefinition,
                                     at position: CGPoint,
                                     zLayer: CGFloat) -> SKNode {
        guard debugSamplesEnabled else { return SKNode() }

        let container = SKNode()
        container.name = "debug_placed_\(definition.id)"
        container.position = position
        container.zPosition = zLayer
        container.setScale(definition.displayScale)

        let rect = SKShapeNode(rectOf: definition.defaultSize, cornerRadius: 6)
        rect.fillColor = definition.category.debugPlaceholderFill
        rect.strokeColor = definition.category.debugPlaceholderStroke
        rect.lineWidth = 2
        container.addChild(rect)

        let label = SKLabelNode(text: definition.displayName)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = max(9, min(14, definition.defaultSize.width * 0.20))
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        container.addChild(label)

        return container
    }
}

// MARK: - Category debug colours

extension HouseObjectCategory {
    var debugPlaceholderFill: UIColor {
        switch self {
        case .floorFurniture:     return UIColor(red: 0.36, green: 0.42, blue: 0.28, alpha: 0.80)
        case .backWallDecoration: return UIColor(red: 0.30, green: 0.50, blue: 0.56, alpha: 0.80)
        case .ceilingDecoration, .leftWallDecoration, .rightWallDecoration:
            return UIColor(red: 0.30, green: 0.50, blue: 0.56, alpha: 0.80)
        case .functional:         return UIColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 0.80)
        case .container:          return UIColor(red: 0.44, green: 0.36, blue: 0.22, alpha: 0.80)
        }
    }

    var debugPlaceholderStroke: UIColor { .white.withAlphaComponent(0.65) }
}

// MARK: - Convenience: surface debug label for rejection messages

private extension HouseSurfaceKind {
    var debugLabel: String {
        switch self {
        case .floor:     return "chão"
        case .backWall:  return "parede"
        case .ceiling, .leftWall, .rightWall:
            return "parede"
        }
    }
}

// MARK: - Surface compatibility query

extension RoomSurfaceMapping {

    /// Returns all surface kinds this room currently maps, for
    /// quick runtime introspection (e.g. UI surface‑filter lists).
    var availableSurfaceKinds: [HouseSurfaceKind] {
        HouseSurfaceKind.activeMiniroomSurfaces.filter { surfaces[$0] != nil }
    }

    /// Quick check: does this room support the given surface kind?
    func supports(_ kind: HouseSurfaceKind) -> Bool {
        surfaces[kind] != nil
    }
}
