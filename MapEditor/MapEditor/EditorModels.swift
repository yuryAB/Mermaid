import Foundation
import SwiftUI

struct DepthDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let accent: Color
}

struct TilePaletteItem: Identifiable, Hashable {
    let id: String
    let name: String
    let color: Color
    let imageURL: URL?
    let connectionMask: Int
    let innerCornerMask: Int
    let duplicateOf: String?
    let generated: Bool
    
    init(
        id: String,
        name: String,
        color: Color,
        imageURL: URL? = nil,
        connectionMask: Int = 0,
        innerCornerMask: Int = 0,
        duplicateOf: String? = nil,
        generated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.imageURL = imageURL
        self.connectionMask = connectionMask
        self.innerCornerMask = innerCornerMask
        self.duplicateOf = duplicateOf
        self.generated = generated
    }
    
    static func == (lhs: TilePaletteItem, rhs: TilePaletteItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum EditorLayer: String, CaseIterable, Identifiable {
    case terrain = "Terrain"
    case decoration = "Decor"
    case spawn = "Spawn"
    
    var id: String { rawValue }
}

enum PaintTool: String, CaseIterable, Identifiable {
    case brush = "Brush"
    case eraser = "Eraser"
    
    var id: String { rawValue }
}

struct TerrainCell: Codable, Hashable, Identifiable, Comparable {
    let x: Int
    let y: Int
    
    var id: String { "\(x),\(y)" }
    
    static func < (lhs: TerrainCell, rhs: TerrainCell) -> Bool {
        lhs.y == rhs.y ? lhs.x < rhs.x : lhs.y < rhs.y
    }
}

enum EditorDataLocation {
    static var sharedRootURL: URL {
        locateSharedData()
    }
    
    static var mapsURL: URL {
        sharedRootURL.appendingPathComponent("Maps", isDirectory: true)
    }
    
    static var tilesURL: URL {
        sharedRootURL.appendingPathComponent("Tiles", isDirectory: true)
    }
    
    static var sharedRoot: String { sharedRootURL.path }
    static var maps: String { mapsURL.path }
    static var tiles: String { tilesURL.path }
    
    private static func locateSharedData() -> URL {
        let sourceURL = URL(fileURLWithPath: #filePath)
        var cursor = sourceURL.deletingLastPathComponent()
        
        for _ in 0..<8 {
            let candidate = cursor.appendingPathComponent("SharedGameData", isDirectory: true)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            cursor.deleteLastPathComponent()
        }
        
        let fallback = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer/Mermaid/SharedGameData", isDirectory: true)
        return fallback
    }
}

enum TileLibrary {
    static func loadAutotileSet() -> AutotileSet {
        let tiles = loadTerrainTiles()
        return AutotileSet(
            id: "mossy-terrain-256",
            name: "Mossy Terrain",
            tileSize: 256,
            tiles: tiles
        )
    }
    
    static func loadTerrainTiles() -> [TilePaletteItem] {
        let manifestURL = EditorDataLocation.tilesURL
            .appendingPathComponent("Mossy/terrain-256/manifest.json")
        
        guard
            let data = try? Data(contentsOf: manifestURL),
            let manifest = try? JSONDecoder().decode(TileManifest.self, from: data)
        else {
            return TilePaletteItem.terrainSamples
        }
        
        let baseURL = manifestURL.deletingLastPathComponent()
        let tiles = manifest.tiles
            .filter(\.usable)
            .map { tile in
                TilePaletteItem(
                    id: tile.id,
                    name: tile.name,
                    color: .rockBlue,
                    imageURL: baseURL.appendingPathComponent(tile.file),
                    connectionMask: tile.connectionMask ?? 0,
                    innerCornerMask: tile.innerCornerMask ?? 0,
                    duplicateOf: tile.duplicateOf ?? nil,
                    generated: tile.generated ?? false
                )
            }
        
        return tiles.isEmpty ? TilePaletteItem.terrainSamples : tiles
    }
}

private struct TileManifest: Decodable {
    struct Tile: Decodable {
        let id: String
        let name: String
        let file: String
        let usable: Bool
        let connectionMask: Int?
        let innerCornerMask: Int?
        let duplicateOf: String?
        let generated: Bool?
    }
    
    let tiles: [Tile]
}

struct AutotileSet {
    static let north = 1
    static let east = 2
    static let south = 4
    static let west = 8
    
    let id: String
    let name: String
    let tileSize: Int
    let tiles: [TilePaletteItem]
    
    var paletteTiles: [TilePaletteItem] {
        uniqueTiles.sorted { lhs, rhs in
            naturalTileOrder(lhs.id) < naturalTileOrder(rhs.id)
        }
    }
    
    private var uniqueTiles: [TilePaletteItem] {
        let unique = tiles.filter { $0.duplicateOf == nil }
        return unique.isEmpty ? tiles : unique
    }
    
    private var candidatesByMask: [Int: [TilePaletteItem]] {
        Dictionary(grouping: uniqueTiles, by: \.connectionMask)
    }
    
    func tile(for cell: TerrainCell, in terrain: Set<TerrainCell>, variationSeed: Int) -> TilePaletteItem {
        let mask = connectionMask(for: cell, in: terrain)
        let innerMask = innerCornerMask(for: cell, in: terrain)
        
        if let exact = candidatesByMask[mask], !exact.isEmpty {
            let maskCandidates = preferredExactCandidates(from: exact, mask: mask)
            let innerCandidates = preferredInnerCandidates(from: maskCandidates, innerMask: innerMask)
            return choose(from: innerCandidates, cell: cell, mask: mask, innerMask: innerMask, variationSeed: variationSeed)
        }
        
        let best = bestFallbackCandidates(for: mask)
        return choose(from: best, cell: cell, mask: mask, innerMask: innerMask, variationSeed: variationSeed)
    }
    
    func connectionMask(for cell: TerrainCell, in terrain: Set<TerrainCell>) -> Int {
        var mask = 0
        if terrain.contains(TerrainCell(x: cell.x, y: cell.y - 1)) { mask |= Self.north }
        if terrain.contains(TerrainCell(x: cell.x + 1, y: cell.y)) { mask |= Self.east }
        if terrain.contains(TerrainCell(x: cell.x, y: cell.y + 1)) { mask |= Self.south }
        if terrain.contains(TerrainCell(x: cell.x - 1, y: cell.y)) { mask |= Self.west }
        return mask
    }
    
    private func preferredExactCandidates(from candidates: [TilePaletteItem], mask: Int) -> [TilePaletteItem] {
        let sparseMasks = [
            0,
            Self.north,
            Self.east,
            Self.south,
            Self.west,
            Self.north | Self.south,
            Self.east | Self.west
        ]
        
        guard sparseMasks.contains(mask) else {
            return candidates
        }
        
        let generated = candidates.filter { $0.generated }
        return generated.isEmpty ? candidates : generated
    }
    
    private func innerCornerMask(for cell: TerrainCell, in terrain: Set<TerrainCell>) -> Int {
        let north = terrain.contains(TerrainCell(x: cell.x, y: cell.y - 1))
        let east = terrain.contains(TerrainCell(x: cell.x + 1, y: cell.y))
        let south = terrain.contains(TerrainCell(x: cell.x, y: cell.y + 1))
        let west = terrain.contains(TerrainCell(x: cell.x - 1, y: cell.y))
        
        var mask = 0
        if north && west && !terrain.contains(TerrainCell(x: cell.x - 1, y: cell.y - 1)) {
            mask |= 1
        }
        if north && east && !terrain.contains(TerrainCell(x: cell.x + 1, y: cell.y - 1)) {
            mask |= 2
        }
        if south && west && !terrain.contains(TerrainCell(x: cell.x - 1, y: cell.y + 1)) {
            mask |= 4
        }
        if south && east && !terrain.contains(TerrainCell(x: cell.x + 1, y: cell.y + 1)) {
            mask |= 8
        }
        return mask
    }
    
    private func preferredInnerCandidates(from candidates: [TilePaletteItem], innerMask: Int) -> [TilePaletteItem] {
        if innerMask == 0 {
            let plain = candidates.filter { $0.innerCornerMask == 0 }
            return plain.isEmpty ? candidates : plain
        }
        
        let exact = candidates.filter { $0.innerCornerMask == innerMask }
        if !exact.isEmpty {
            return exact
        }
        
        let overlapping = candidates.filter { $0.innerCornerMask & innerMask != 0 }
        return overlapping.isEmpty ? candidates : overlapping
    }
    
    private func bestFallbackCandidates(for desiredMask: Int) -> [TilePaletteItem] {
        for fallbackMask in preferredFallbackMasks(for: desiredMask) {
            if let candidates = candidatesByMask[fallbackMask], !candidates.isEmpty {
                return candidates
            }
        }
        
        let scored = uniqueTiles.map { tile in
            (tile, fallbackScore(candidateMask: tile.connectionMask, desiredMask: desiredMask))
        }
        let bestScore = scored.map(\.1).max() ?? 0
        let best = scored.filter { $0.1 == bestScore }.map(\.0)
        return best.isEmpty ? uniqueTiles : best
    }
    
    private func preferredFallbackMasks(for desiredMask: Int) -> [Int] {
        switch desiredMask {
        case Self.east | Self.west:
            return [Self.east | Self.south | Self.west, Self.north | Self.east | Self.west]
        case Self.north | Self.south:
            return [Self.north | Self.east | Self.south, Self.north | Self.south | Self.west]
        case Self.east:
            return [Self.east | Self.south, Self.north | Self.east]
        case Self.west:
            return [Self.south | Self.west, Self.north | Self.west]
        case Self.north:
            return [Self.north | Self.east, Self.north | Self.west]
        case Self.south:
            return [Self.east | Self.south, Self.south | Self.west]
        default:
            return []
        }
    }
    
    private func fallbackScore(candidateMask: Int, desiredMask: Int) -> Int {
        var score = 0
        
        for bit in [Self.north, Self.east, Self.south, Self.west] {
            let wantsConnection = desiredMask & bit != 0
            let hasConnection = candidateMask & bit != 0
            
            switch (wantsConnection, hasConnection) {
            case (true, true):
                score += 12
            case (true, false):
                score -= 20
            case (false, true):
                score -= 5
            case (false, false):
                score += 2
            }
        }
        
        if desiredMask & Self.north == 0, candidateMask & Self.north == 0 {
            score += 3
        }
        
        return score
    }
    
    private func choose(
        from candidates: [TilePaletteItem],
        cell: TerrainCell,
        mask: Int,
        innerMask: Int,
        variationSeed: Int
    ) -> TilePaletteItem {
        let usableCandidates = candidates.isEmpty ? uniqueTiles : candidates
        guard !usableCandidates.isEmpty else {
            return TilePaletteItem.terrainSamples[0]
        }
        
        let index = stableIndex(
            x: cell.x,
            y: cell.y,
            mask: mask,
            innerMask: innerMask,
            seed: variationSeed,
            count: usableCandidates.count
        )
        return usableCandidates[index]
    }
    
    private func stableIndex(x: Int, y: Int, mask: Int, innerMask: Int, seed: Int, count: Int) -> Int {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for value in [x, y, mask, innerMask, seed] {
            hash ^= UInt64(bitPattern: Int64(value &* 16_777_619))
            hash = hash &* 1_099_511_628_211
        }
        return Int(hash % UInt64(count))
    }
    
    private func naturalTileOrder(_ id: String) -> Int {
        let parts = id.split(separator: "-")
        guard let rowPart = parts.first(where: { $0.hasPrefix("r") }),
              let columnPart = parts.first(where: { $0.hasPrefix("c") }),
              let row = Int(rowPart.dropFirst()),
              let column = Int(columnPart.dropFirst()) else {
            return Int.max
        }
        return row * 1_000 + column
    }
}

struct MapDocument: Codable {
    let id: String
    let depthID: String
    let tileSetID: String
    let tileSize: Int
    let width: Int
    let height: Int
    let variationSeed: Int?
    let terrain: [TerrainCell]
}

enum EditorMapStore {
    static func save(
        depth: DepthDefinition,
        tileSet: AutotileSet,
        width: Int,
        height: Int,
        variationSeed: Int,
        terrain: Set<TerrainCell>
    ) throws -> URL {
        try FileManager.default.createDirectory(
            at: EditorDataLocation.mapsURL,
            withIntermediateDirectories: true
        )
        
        let document = MapDocument(
            id: "\(depth.id)_map",
            depthID: depth.id,
            tileSetID: tileSet.id,
            tileSize: tileSet.tileSize,
            width: width,
            height: height,
            variationSeed: variationSeed,
            terrain: terrain.sorted()
        )
        
        let url = Self.url(for: depth)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: url, options: .atomic)
        return url
    }
    
    static func load(depth: DepthDefinition) throws -> MapDocument? {
        let url = Self.url(for: depth)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(MapDocument.self, from: data)
    }
    
    static func url(for depth: DepthDefinition) -> URL {
        EditorDataLocation.mapsURL.appendingPathComponent("\(depth.id).json")
    }
}

extension DepthDefinition {
    static let samples: [DepthDefinition] = [
        .init(id: "recife_tropical", name: "Recife Tropical", accent: .cyan),
        .init(id: "floresta_kelp", name: "Floresta de Kelp", accent: .mint),
        .init(id: "manguezal", name: "Manguezal", accent: .green),
        .init(id: "estuario", name: "Estuario", accent: .orange),
        .init(id: "oceano_profundo", name: "Oceano Profundo", accent: .indigo),
        .init(id: "zona_abissal", name: "Zona Abissal", accent: .purple)
    ]
}

extension TilePaletteItem {
    static let terrainSamples: [TilePaletteItem] = [
        .init(id: "surface", name: "Surface", color: .sand),
        .init(id: "middle", name: "Middle", color: .rockBlue),
        .init(id: "left_edge", name: "Left Edge", color: .teal),
        .init(id: "right_edge", name: "Right Edge", color: .teal.opacity(0.75)),
        .init(id: "bottom", name: "Bottom", color: .seaGreen),
        .init(id: "corner", name: "Corner", color: .coral)
    ]
}

extension Color {
    static let deepWater = Color(red: 0.05, green: 0.12, blue: 0.22)
    static let panelWater = Color(red: 0.08, green: 0.19, blue: 0.28)
    static let rockBlue = Color(red: 0.21, green: 0.43, blue: 0.55)
    static let sand = Color(red: 0.86, green: 0.74, blue: 0.50)
    static let coral = Color(red: 0.93, green: 0.36, blue: 0.45)
    static let seaGreen = Color(red: 0.22, green: 0.58, blue: 0.42)
}
