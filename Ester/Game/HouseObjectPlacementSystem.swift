//
//  HouseObjectPlacementSystem.swift
//  Ester
//
//  Architecture foundation for future Mermaid House object placement.
//  Defines models for object definitions, placement rules, attachment
//  sides, surface compatibility, placed object instances, and a
//  placement resolver that validates and computes final positions.
//
//  No real furniture, decorations, purchasable objects, inventory, or
//  drag‑and‑drop is implemented yet. This file only establishes the
//  types and resolver that future features will build on.
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
    /// Object hangs from the ceiling (top edge touches ceiling bottom).
    case top
    /// Object attaches to the left edge of a surface (e.g. left‑wall decor).
    case left
    /// Object attaches to the right edge of a surface.
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
    case ceilingDecoration
    case backWallDecoration
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
    let roomPosition: HouseGridPosition
    let surface: HouseSurfaceKind
    var localPosition: CGPoint
    var rotation: CGFloat
    var scale: CGFloat
    var zLayerOverride: CGFloat?
    var statePayload: Data?         // future Codable state

    init(id: UUID = UUID(),
         definitionID: String,
         roomPosition: HouseGridPosition,
         surface: HouseSurfaceKind,
         localPosition: CGPoint,
         rotation: CGFloat = 0,
         scale: CGFloat = 1,
         zLayerOverride: CGFloat? = nil,
         statePayload: Data? = nil) {
        self.id = id
        self.definitionID = definitionID
        self.roomPosition = roomPosition
        self.surface = surface
        self.localPosition = localPosition
        self.rotation = rotation
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

    static func success(position: CGPoint,
                        attachmentSide: HouseObjectAttachmentSide,
                        surface: HouseSurfaceKind,
                        zLayer: CGFloat) -> HouseObjectPlacementResult {
        HouseObjectPlacementResult(isValid: true,
                                   validationError: nil,
                                   finalPosition: position,
                                   attachmentSide: attachmentSide,
                                   surface: surface,
                                   zLayer: zLayer)
    }

    static func failure(reason: String,
                        surface: HouseSurfaceKind = .backWall) -> HouseObjectPlacementResult {
        HouseObjectPlacementResult(isValid: false,
                                   validationError: reason,
                                   finalPosition: .zero,
                                   attachmentSide: .back,
                                   surface: surface,
                                   zLayer: 0)
    }
}

// MARK: - Placement resolver

/// Validates compatibility and computes the final position, attachment
/// alignment, and z‑layer for a future object being placed in a room.
final class HouseObjectPlacementResolver {

    // MARK: Z‑layer defaults per surface

    /// Sensible default z‑positions per surface kind so objects render
    /// in the correct depth order relative to the room layers.
    static func defaultZLayer(for surface: HouseSurfaceKind) -> CGFloat {
        switch surface {
        case .floor:     return 10
        case .backWall:  return 3
        case .ceiling:   return 10_010
        case .leftWall:  return 10_010
        case .rightWall: return 10_010
        }
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

        // ---- 1. Find a compatible placement rule ---------------------------
        guard let rule = definition.placementRules.first(where: { $0.isCompatible(with: surface) }),
              let attachmentSide = rule.attachmentSide(for: surface) else {
            return .failure(
                reason: "\(definition.displayName) não pode ser colocado em \(surface.debugLabel).",
                surface: surface
            )
        }

        // ---- 2. Slot check ------------------------------------------------
        if rule.requiresSlot && slotID == nil {
            return .failure(
                reason: "\(definition.displayName) precisa de um espaço específico.",
                surface: surface
            )
        }

        // ---- 3. Clamp point to surface bounds when free‑positioning --------
        let surfaceRect = mapping.surfaces[surface]!.localRect
        let clampedPoint: CGPoint
        if rule.allowsFreePositioning {
            clampedPoint = CGPoint(
                x: point.x.clamped(to: surfaceRect.minX...surfaceRect.maxX),
                y: point.y.clamped(to: surfaceRect.minY...surfaceRect.maxY)
            )
        } else {
            clampedPoint = CGPoint(x: surfaceRect.midX, y: surfaceRect.midY)
        }

        // ---- 4. Compute final position based on attachment side ------------
        let objectSize = definition.defaultSize
        let finalLocalPosition = alignedCenter(
            attachmentSide: attachmentSide,
            objectSize: objectSize,
            surfaceRect: surfaceRect,
            point: clampedPoint,
            offset: rule.defaultOffset
        )

        // ---- 5. Determine z‑layer -----------------------------------------
        let zLayer = rule.preferredZLayer ?? Self.defaultZLayer(for: surface)

        // ---- 6. Log for debug / validation --------------------------------
        Self.logPlacement(definition: definition,
                          attachmentSide: attachmentSide,
                          surface: surface,
                          finalPosition: finalLocalPosition,
                          zLayer: zLayer)

        return .success(position: finalLocalPosition,
                        attachmentSide: attachmentSide,
                        surface: surface,
                        zLayer: zLayer)
    }

    // MARK: Alignment helpers

    /// Computes the center point of the object so its attachment side
    /// aligns flush against the target surface edge.
    private func alignedCenter(attachmentSide: HouseObjectAttachmentSide,
                               objectSize: CGSize,
                               surfaceRect: CGRect,
                               point: CGPoint,
                               offset: CGPoint) -> CGPoint {
        let hw = objectSize.width / 2
        let hh = objectSize.height / 2

        let base: CGPoint
        switch attachmentSide {
        case .bottom:
            // Bottom edge of object sits on top edge of floor surface.
            base = CGPoint(x: point.x, y: surfaceRect.maxY + hh)
        case .top:
            // Top edge of object touches bottom edge of ceiling surface.
            base = CGPoint(x: point.x, y: surfaceRect.minY - hh)
        case .left:
            // Left edge of object touches right edge of left‑wall surface.
            base = CGPoint(x: surfaceRect.maxX + hw, y: point.y)
        case .right:
            // Right edge of object touches left edge of right‑wall surface.
            base = CGPoint(x: surfaceRect.minX - hw, y: point.y)
        case .back:
            // Object lies flat against the back wall at the tapped point.
            base = CGPoint(x: point.x, y: point.y)
        }

        return CGPoint(x: base.x + offset.x, y: base.y + offset.y)
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

    /// A handful of representative definitions covering every surface
    /// kind and attachment side so we can validate the resolver.
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
            HouseObjectDefinition(
                id: "sample_ceiling_lamp",
                name: "Ceiling Lamp",
                displayName: "Luminária de teto",
                assetName: nil,
                category: .ceilingDecoration,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.ceiling],
                                attachmentSide: .top
                            )
                        ],
                        allowsFreePositioning: false,
                        defaultOffset: .zero
                    )
                ],
                defaultSize: CGSize(width: 22, height: 28),
                isInteractive: false,
                needsPhysics: false
            ),
            HouseObjectDefinition(
                id: "sample_side_ornament",
                name: "Side Ornament",
                displayName: "Ornamento lateral",
                assetName: nil,
                category: .leftWallDecoration,
                placementRules: [
                    HouseObjectPlacementRule(
                        surfaceCompatibilities: [
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.leftWall],
                                attachmentSide: .left
                            ),
                            HouseObjectSurfaceCompatibility(
                                supportedSurfaces: [.rightWall],
                                attachmentSide: .right
                            )
                        ],
                        defaultOffset: .zero
                    )
                ],
                defaultSize: CGSize(width: 8, height: 36),
                isInteractive: false,
                needsPhysics: false
            )
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
        case .ceilingDecoration:  return UIColor(red: 0.60, green: 0.54, blue: 0.22, alpha: 0.80)
        case .backWallDecoration: return UIColor(red: 0.30, green: 0.50, blue: 0.56, alpha: 0.80)
        case .leftWallDecoration: return UIColor(red: 0.54, green: 0.28, blue: 0.38, alpha: 0.80)
        case .rightWallDecoration:return UIColor(red: 0.28, green: 0.52, blue: 0.40, alpha: 0.80)
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
        case .ceiling:   return "teto"
        case .leftWall:  return "parede esquerda"
        case .rightWall: return "parede direita"
        }
    }
}

// MARK: - Surface compatibility query

extension RoomSurfaceMapping {

    /// Returns all surface kinds this room currently maps, for
    /// quick runtime introspection (e.g. UI surface‑filter lists).
    var availableSurfaceKinds: [HouseSurfaceKind] {
        Array(surfaces.keys)
    }

    /// Quick check: does this room support the given surface kind?
    func supports(_ kind: HouseSurfaceKind) -> Bool {
        surfaces[kind] != nil
    }
}
