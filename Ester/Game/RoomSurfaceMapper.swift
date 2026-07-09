//
//  RoomSurfaceMapper.swift
//  Ester
//
//  Automatic surface mapping for every room in the Mermaid House.
//  Identifies the five placement surfaces (floor, back wall, ceiling,
//  left wall, right wall) from a room's bounds and visual components.
//
//  Floor   = darker blue lower band inside the room  (static physics body)
//  Back wall = lighter blue background area             (attachment-only, no physics)
//  Ceiling = top frame/moldura bar                     (attachment surface)
//  Left wall  = left frame/moldura bar                 (attachment surface)
//  Right wall = right frame/moldura bar                (attachment surface)
//
//  All mapping is computed deterministically from the room size so every
//  room — built at game start or created later — maps automatically.
//
//  Debug outlines can be toggled with the `debugEnabled` flag.
//

import Foundation
import SpriteKit

// MARK: - Physics categories (prepared for future object placement)

enum HousePhysicsCategory {
    static let houseFloor: UInt32 = 0x1 << 0
    // Reserved for future placed objects (furniture, decorations, etc.)
    // static let placedObject: UInt32 = 0x1 << 1
}

// MARK: - Surface kinds

enum HouseSurfaceKind: String, Codable, CaseIterable {
    case floor
    case backWall
    case ceiling
    case leftWall
    case rightWall
}

// MARK: - Single surface description

struct HouseSurface {
    let kind: HouseSurfaceKind
    /// Rect in the room node's local coordinate space (center = origin).
    let localRect: CGRect

    init(kind: HouseSurfaceKind, localRect: CGRect) {
        self.kind = kind
        self.localRect = localRect
    }

    // MARK: Debug visualisation helpers

    private static let debugAlpha: CGFloat = 0.18

    var debugFillColor: UIColor {
        switch kind {
        case .floor:     return UIColor(red: 0.94, green: 0.68, blue: 0.30, alpha: Self.debugAlpha)
        case .backWall:  return UIColor(red: 0.40, green: 0.70, blue: 0.90, alpha: Self.debugAlpha)
        case .ceiling:   return UIColor(red: 0.98, green: 0.92, blue: 0.40, alpha: Self.debugAlpha)
        case .leftWall:  return UIColor(red: 0.96, green: 0.42, blue: 0.52, alpha: Self.debugAlpha)
        case .rightWall: return UIColor(red: 0.42, green: 0.80, blue: 0.56, alpha: Self.debugAlpha)
        }
    }

    var debugStrokeColor: UIColor {
        switch kind {
        case .floor:     return UIColor(red: 0.94, green: 0.68, blue: 0.30, alpha: 0.55)
        case .backWall:  return UIColor(red: 0.40, green: 0.70, blue: 0.90, alpha: 0.45)
        case .ceiling:   return UIColor(red: 0.98, green: 0.92, blue: 0.40, alpha: 0.50)
        case .leftWall:  return UIColor(red: 0.96, green: 0.42, blue: 0.52, alpha: 0.50)
        case .rightWall: return UIColor(red: 0.42, green: 0.80, blue: 0.56, alpha: 0.50)
        }
    }

    var debugLabelText: String {
        switch kind {
        case .floor:     return "chão"
        case .backWall:  return "parede"
        case .ceiling:   return "teto"
        case .leftWall:  return "esq."
        case .rightWall: return "dir."
        }
    }

    func makeDebugNode() -> SKNode {
        let container = SKNode()
        container.name = "surface_debug_\(kind.rawValue)"

        let shape = SKShapeNode(rectOf: localRect.size, cornerRadius: 4)
        shape.fillColor = debugFillColor
        shape.strokeColor = debugStrokeColor
        shape.lineWidth = 1.5
        shape.position = CGPoint(x: localRect.midX, y: localRect.midY)
        container.addChild(shape)

        let label = SKLabelNode(text: debugLabelText)
        label.fontName = "AvenirNext-DemiBold"
        label.fontSize = max(10, min(14, localRect.width * 0.18))
        label.fontColor = debugStrokeColor
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: localRect.midX, y: localRect.midY)
        container.addChild(label)

        return container
    }
}

// MARK: - Room surface mapping (all five surfaces for one room)

struct RoomSurfaceMapping {
    let roomSize: CGSize
    let surfaces: [HouseSurfaceKind: HouseSurface]

    var floor:     HouseSurface { surfaces[.floor]! }
    var backWall:  HouseSurface { surfaces[.backWall]! }
    var ceiling:   HouseSurface { surfaces[.ceiling]! }
    var leftWall:  HouseSurface { surfaces[.leftWall]! }
    var rightWall: HouseSurface { surfaces[.rightWall]! }

    /// Creates the mapping for a room of the given size. All surfaces are
    /// computed deterministically — the same visual-node logic used by
    /// `HouseRoomNode` and `HouseRoomFrontFrameNode` is replicated here.
    init(roomSize: CGSize) {
        self.roomSize = roomSize

        // --- Floor (darker blue band inside the room) -----------------------
        let floorHeight      = max(10, roomSize.height * 0.10)
        let floorWidth       = roomSize.width - 8
        let floorCenterY     = -roomSize.height / 2 + floorHeight / 2 + 4
        let floorRect = CGRect(x: -floorWidth / 2,
                               y: floorCenterY - floorHeight / 2,
                               width: floorWidth,
                               height: floorHeight)

        // --- Back wall (lighter blue main body) -----------------------------
        let wallRect = CGRect(x: -roomSize.width / 2,
                              y: -roomSize.height / 2,
                              width: roomSize.width,
                              height: roomSize.height)

        // --- Frame bar geometry (copied from HouseRoomFrontFrameNode) --------
        let thickness = max(7, roomSize.width * 0.026)
        let halfW     = roomSize.width / 2
        let halfH     = roomSize.height / 2

        // Ceiling: top bar of the frame.
        let ceilingRect = CGRect(x: -(roomSize.width + thickness) / 2,
                                 y: halfH - thickness,
                                 width: roomSize.width + thickness,
                                 height: thickness)

        // Left wall: left bar of the frame (spans full room height).
        let leftWallRect = CGRect(x: -halfW,
                                  y: -halfH,
                                  width: thickness,
                                  height: roomSize.height)

        // Right wall: right bar of the frame.
        let rightWallRect = CGRect(x: halfW - thickness,
                                   y: -halfH,
                                   width: thickness,
                                   height: roomSize.height)

        self.surfaces = [
            .floor:     HouseSurface(kind: .floor,     localRect: floorRect),
            .backWall:  HouseSurface(kind: .backWall,  localRect: wallRect),
            .ceiling:   HouseSurface(kind: .ceiling,   localRect: ceilingRect),
            .leftWall:  HouseSurface(kind: .leftWall,  localRect: leftWallRect),
            .rightWall: HouseSurface(kind: .rightWall, localRect: rightWallRect)
        ]
    }

    /// Creates a static physics body suitable for the floor surface so future
    /// objects can stand on it.
    func makeFloorPhysicsBody() -> SKPhysicsBody {
        let surface = surfaces[.floor]!
        let body = SKPhysicsBody(rectangleOf: surface.localRect.size)
        body.isDynamic = false
        body.restitution = 0
        body.friction = 0.2
        body.categoryBitMask = HousePhysicsCategory.houseFloor
        // No collision or contact masks yet — objects will be added later.
        body.collisionBitMask = 0
        body.contactTestBitMask = 0
        return body
    }
}

// MARK: - Surface mapper (top-level utility)

final class RoomSurfaceMapper {

    /// When `true`, rooms render translucent debug overlays showing the
    /// five mapped surfaces. Set to `false` to disable all visualisation.
    static var debugEnabled = false

    /// Builds a `RoomSurfaceMapping` for the given room size. If debug
    /// visualisation is enabled, the returned mapping includes debug nodes
    /// that should be added to the room's node tree.
    static func map(roomSize: CGSize) -> RoomSurfaceMapping {
        RoomSurfaceMapping(roomSize: roomSize)
    }

    /// Returns debug overlay nodes for the interior surfaces (floor, back wall).
    /// These should be added to the room's back‑layer node.
    static func makeInteriorDebugNodes(for mapping: RoomSurfaceMapping) -> [SKNode] {
        guard debugEnabled else { return [] }
        let kinds: [HouseSurfaceKind] = [.floor, .backWall]
        return kinds.map { mapping.surfaces[$0]!.makeDebugNode() }
    }

    /// Returns debug overlay nodes for the frame surfaces (ceiling, left wall,
    /// right wall). These should be added to the room's front‑layer node so they
    /// sit on top of the solid frame/moldura bars.
    static func makeFrameDebugNodes(for mapping: RoomSurfaceMapping) -> [SKNode] {
        guard debugEnabled else { return [] }
        let kinds: [HouseSurfaceKind] = [.ceiling, .leftWall, .rightWall]
        return kinds.map { mapping.surfaces[$0]!.makeDebugNode() }
    }
}
