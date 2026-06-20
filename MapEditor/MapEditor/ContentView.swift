import AppKit
import SwiftUI

struct ContentView: View {
    private let autotileSet: AutotileSet
    private let terrainTiles: [TilePaletteItem]
    private let mapColumns = 48
    private let mapRows = 28

    @State private var selectedDepth: DepthDefinition.ID? = DepthDefinition.samples.first?.id
    @State private var previewTile: TilePaletteItem
    @State private var paintTool = PaintTool.brush
    @State private var brushSize = 1
    @State private var terrainCells: Set<TerrainCell> = []
    @State private var undoStack: [Set<TerrainCell>] = []
    @State private var redoStack: [Set<TerrainCell>] = []
    @State private var variationSeed = 0
    @State private var zoom = 1.0
    @State private var hasUnsavedChanges = false
    @State private var isRestoringDepthSelection = false
    @State private var statusText = "Autoterrain ready"

    init() {
        let tileSet = TileLibrary.loadAutotileSet()
        autotileSet = tileSet
        terrainTiles = tileSet.paletteTiles
        _previewTile = State(initialValue: tileSet.paletteTiles.first ?? TilePaletteItem.terrainSamples[0])
    }

    private var selectedDepthDefinition: DepthDefinition {
        DepthDefinition.samples.first { $0.id == selectedDepth } ?? DepthDefinition.samples[0]
    }

    var body: some View {
        NavigationSplitView {
            List(DepthDefinition.samples, selection: $selectedDepth) { depth in
                DepthRow(depth: depth)
                    .tag(depth.id)
            }
            .navigationTitle("Depths")
        } content: {
            VStack(alignment: .leading, spacing: 16) {
                AutotileSummary(tileSet: autotileSet, tileCount: terrainTiles.count)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                        ForEach(terrainTiles) { tile in
                            TilePaletteButton(tile: tile, isSelected: tile == previewTile) {
                                previewTile = tile
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tile Inspector")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TileImageView(tile: previewTile, cornerRadius: 8)
                        .frame(width: 96, height: 96)
                        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                    Text(previewTile.name)
                        .font(.caption)
                        .lineLimit(1)
                }

                PathSummary()
            }
            .padding()
            .navigationTitle("Autotile Tiles")
        } detail: {
            VStack(spacing: 0) {
                EditorToolbar(
                    depth: selectedDepthDefinition,
                    tileSet: autotileSet,
                    tileCount: terrainCells.count,
                    mapSize: "\(mapColumns)x\(mapRows)",
                    statusText: statusText,
                    hasUnsavedChanges: hasUnsavedChanges,
                    canUndo: !undoStack.isEmpty,
                    canRedo: !redoStack.isEmpty,
                    paintTool: $paintTool,
                    brushSize: $brushSize,
                    zoom: $zoom,
                    undoAction: undoTerrainChange,
                    redoAction: redoTerrainChange,
                    saveAction: saveCurrentMap,
                    loadAction: reloadCurrentMap,
                    clearAction: clearMap,
                    shuffleAction: shuffleVariations
                )

                MapCanvasView(
                    terrainCells: $terrainCells,
                    paintTool: paintTool,
                    brushSize: brushSize,
                    autotileSet: autotileSet,
                    variationSeed: variationSeed,
                    zoom: zoom,
                    columns: mapColumns,
                    rows: mapRows,
                    commitStroke: recordTerrainChange
                )
                .background(
                    LinearGradient(
                        colors: [.deepWater, .panelWater, .rockBlue.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .navigationTitle(selectedDepthDefinition.name)
        }
        .frame(minWidth: 1280, minHeight: 820)
        .onAppear(perform: loadCurrentMap)
        .onChange(of: selectedDepth) { oldDepthID, _ in
            if isRestoringDepthSelection {
                isRestoringDepthSelection = false
                return
            }

            guard autosaveDepthIfNeeded(oldDepthID) else {
                isRestoringDepthSelection = true
                selectedDepth = oldDepthID
                return
            }

            loadCurrentMap()
        }
    }

    private func saveCurrentMap() {
        hasUnsavedChanges = !saveMap(for: selectedDepthDefinition, statusPrefix: "Saved")
    }

    private func reloadCurrentMap() {
        guard autosaveDepthIfNeeded(selectedDepth) else {
            return
        }

        loadCurrentMap()
    }

    @discardableResult
    private func saveMap(for depth: DepthDefinition, statusPrefix: String) -> Bool {
        do {
            let url = try EditorMapStore.save(
                depth: depth,
                tileSet: autotileSet,
                width: mapColumns,
                height: mapRows,
                variationSeed: variationSeed,
                terrain: terrainCells
            )
            statusText = "\(statusPrefix) \(url.lastPathComponent)"
            return true
        } catch {
            statusText = "Save failed: \(error.localizedDescription)"
            return false
        }
    }

    private func autosaveDepthIfNeeded(_ depthID: DepthDefinition.ID?) -> Bool {
        guard hasUnsavedChanges else {
            return true
        }

        guard let depthID,
              let depth = DepthDefinition.samples.first(where: { $0.id == depthID }) else {
            return false
        }

        if saveMap(for: depth, statusPrefix: "Autosaved") {
            hasUnsavedChanges = false
            return true
        }

        return false
    }

    private func loadCurrentMap() {
        do {
            if let document = try EditorMapStore.load(depth: selectedDepthDefinition) {
                terrainCells = Set(document.terrain)
                variationSeed = document.variationSeed ?? 0
                statusText = "Loaded \(selectedDepthDefinition.name)"
            } else {
                terrainCells = []
                variationSeed = 0
                statusText = "New \(selectedDepthDefinition.name)"
            }
            undoStack.removeAll()
            redoStack.removeAll()
            hasUnsavedChanges = false
        } catch {
            terrainCells = []
            variationSeed = 0
            undoStack.removeAll()
            redoStack.removeAll()
            hasUnsavedChanges = false
            statusText = "Load failed: \(error.localizedDescription)"
        }
    }

    private func clearMap() {
        guard !terrainCells.isEmpty else {
            return
        }
        pushUndoSnapshot(terrainCells)
        terrainCells.removeAll()
        redoStack.removeAll()
        hasUnsavedChanges = true
        statusText = "Cleared terrain"
    }

    private func shuffleVariations() {
        variationSeed += 1
        hasUnsavedChanges = true
        statusText = "Variations \(variationSeed)"
    }

    private func recordTerrainChange(from previousTerrain: Set<TerrainCell>) {
        guard previousTerrain != terrainCells else {
            return
        }

        pushUndoSnapshot(previousTerrain)
        redoStack.removeAll()
        hasUnsavedChanges = true
        statusText = "\(paintTool.rawValue) \(terrainCells.count)"
    }

    private func undoTerrainChange() {
        guard let previousTerrain = undoStack.popLast() else {
            return
        }

        redoStack.append(terrainCells)
        terrainCells = previousTerrain
        hasUnsavedChanges = true
        statusText = "Undo \(terrainCells.count)"
    }

    private func redoTerrainChange() {
        guard let nextTerrain = redoStack.popLast() else {
            return
        }

        undoStack.append(terrainCells)
        terrainCells = nextTerrain
        hasUnsavedChanges = true
        statusText = "Redo \(terrainCells.count)"
    }

    private func pushUndoSnapshot(_ terrain: Set<TerrainCell>) {
        undoStack.append(terrain)
        if undoStack.count > 80 {
            undoStack.removeFirst()
        }
    }
}

private struct DepthRow: View {
    let depth: DepthDefinition

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(depth.accent)
                .frame(width: 10, height: 10)
            Text(depth.name)
        }
        .padding(.vertical, 4)
    }
}

private struct AutotileSummary: View {
    let tileSet: AutotileSet
    let tileCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(tileSet.name, systemImage: "square.grid.3x3")
                .font(.headline)
            HStack(spacing: 12) {
                Label("\(tileCount)", systemImage: "photo.stack")
                Label("\(tileSet.tileSize)", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.panelWater.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TilePaletteButton: View {
    let tile: TilePaletteItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TileImageView(tile: tile, cornerRadius: 6)
                    .frame(width: 56, height: 56)
                    .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.25), lineWidth: isSelected ? 3 : 1)
                    }
                Text(tile.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct TileImageView: View {
    let tile: TilePaletteItem
    let cornerRadius: CGFloat

    var body: some View {
        if let url = tile.imageURL, let image = TileImageCache.shared.image(for: url) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.medium)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(tile.color.gradient)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.sand)
                        .frame(height: tile.id == "surface" ? 14 : 0)
                }
        }
    }
}

private final class TileImageCache {
    static let shared = TileImageCache()

    private let images: NSCache<NSURL, NSImage> = {
        let cache = NSCache<NSURL, NSImage>()
        cache.name = "TileImageCache.images"
        cache.countLimit = 128
        cache.totalCostLimit = 48 * 1024 * 1024
        return cache
    }()

    func image(for url: URL) -> NSImage? {
        let cacheKey = url as NSURL
        if let image = images.object(forKey: cacheKey) {
            return image
        }

        guard let image = NSImage(contentsOf: url) else {
            return nil
        }

        images.setObject(image, forKey: cacheKey, cost: approximateCost(for: image))
        return image
    }

    private func approximateCost(for image: NSImage) -> Int {
        if let representation = image.representations.first {
            let pixels = max(1, representation.pixelsWide * representation.pixelsHigh)
            return pixels * 4
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let width = max(1, Int(ceil(image.size.width * scale)))
        let height = max(1, Int(ceil(image.size.height * scale)))
        return width * height * 4
    }
}

private struct EditorToolbar: View {
    let depth: DepthDefinition
    let tileSet: AutotileSet
    let tileCount: Int
    let mapSize: String
    let statusText: String
    let hasUnsavedChanges: Bool
    let canUndo: Bool
    let canRedo: Bool
    @Binding var paintTool: PaintTool
    @Binding var brushSize: Int
    @Binding var zoom: Double
    let undoAction: () -> Void
    let redoAction: () -> Void
    let saveAction: () -> Void
    let loadAction: () -> Void
    let clearAction: () -> Void
    let shuffleAction: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(depth.name)
                .font(.headline)
            Divider()
                .frame(height: 18)
            Label(tileSet.name, systemImage: "leaf")
            Label(mapSize, systemImage: "rectangle.grid.2x2")
            Label("\(tileCount)", systemImage: "square.stack.3d.up")

            Picker("Tool", selection: $paintTool) {
                ForEach(PaintTool.allCases) { tool in
                    Text(tool.rawValue).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            Stepper("Size \(brushSize)", value: $brushSize, in: 1...5)
                .frame(width: 92)

            Label("Zoom", systemImage: "magnifyingglass")
            Slider(value: $zoom, in: 0.75...2.5)
                .frame(width: 140)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 220, alignment: .leading)
            if hasUnsavedChanges {
                Label("Unsaved", systemImage: "circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer()

            Button(action: undoAction) {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!canUndo)
            Button(action: redoAction) {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!canRedo)
            Button(action: shuffleAction) {
                Label("Shuffle", systemImage: "shuffle")
            }
            Button(action: clearAction) {
                Label("Clear", systemImage: "trash")
            }
            Button(action: loadAction) {
                Label("Load", systemImage: "folder")
            }
            .keyboardShortcut("o", modifiers: .command)
            Button(action: saveAction) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }
}

private struct MapCanvasView: View {
    @Binding var terrainCells: Set<TerrainCell>
    @State private var strokeStartTerrain: Set<TerrainCell>?

    let paintTool: PaintTool
    let brushSize: Int
    let autotileSet: AutotileSet
    let variationSeed: Int
    let zoom: Double
    let columns: Int
    let rows: Int
    let commitStroke: (Set<TerrainCell>) -> Void

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            let tileSize = CGFloat(32 * zoom)
            let boardWidth = tileSize * CGFloat(columns)
            let boardHeight = tileSize * CGFloat(rows)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(.black.opacity(0.16))

                ForEach(terrainCells.sorted()) { cell in
                    let tile = autotileSet.tile(for: cell, in: terrainCells, variationSeed: variationSeed)
                    TileImageView(tile: tile, cornerRadius: 0)
                        .frame(width: tileSize, height: tileSize)
                        .offset(x: CGFloat(cell.x) * tileSize, y: CGFloat(cell.y) * tileSize)
                }

                GridLines(columns: columns, rows: rows, tileSize: tileSize)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .frame(width: boardWidth, height: boardHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if strokeStartTerrain == nil {
                            strokeStartTerrain = terrainCells
                        }
                        applyPaint(at: value.location, tileSize: tileSize)
                    }
                    .onEnded { _ in
                        if let strokeStartTerrain {
                            commitStroke(strokeStartTerrain)
                        }
                        strokeStartTerrain = nil
                    }
            )
            .overlay {
                Rectangle()
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .padding(24)
        }
    }

    private func applyPaint(at location: CGPoint, tileSize: CGFloat) {
        guard tileSize > 0 else {
            return
        }

        let x = Int(location.x / tileSize)
        let y = Int(location.y / tileSize)
        guard x >= 0, x < columns, y >= 0, y < rows else {
            return
        }

        let start = -((brushSize - 1) / 2)
        let end = brushSize / 2

        for brushY in (y + start)...(y + end) {
            for brushX in (x + start)...(x + end) {
                applyPaint(to: TerrainCell(x: brushX, y: brushY))
            }
        }
    }

    private func applyPaint(to cell: TerrainCell) {
        guard cell.x >= 0, cell.x < columns, cell.y >= 0, cell.y < rows else {
            return
        }

        switch paintTool {
        case .brush:
            terrainCells.insert(cell)
        case .eraser:
            terrainCells.remove(cell)
        }
    }
}

private struct GridLines: Shape {
    let columns: Int
    let rows: Int
    let tileSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for column in 0...columns {
            let x = CGFloat(column) * tileSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * tileSize))
        }

        for row in 0...rows {
            let y = CGFloat(row) * tileSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: CGFloat(columns) * tileSize, y: y))
        }

        return path
    }
}

private struct PathSummary: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Maps")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(EditorDataLocation.maps)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
            Text("Tiles")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(EditorDataLocation.tiles)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.panelWater.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
