# Graph Report - Mermaid  (2026-07-09)

## Corpus Check
- 358 files · ~4,234,493 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 4112 nodes · 14931 edges · 243 communities (147 shown, 96 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 1968 edges (avg confidence: 0.73)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `341f96ad`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Map Tiles — Mossy Terrain
- Mermaid House System
- Map Tiles — Mossy Autotile
- Gameplay Models & Scene Construction
- Challenge Flow Controller
- World Point & Rendering Primitives
- Depth Environment & Ocean Parallax
- Banquet of Tides Minigame
- Event System
- Species Registry & Mermaid Progression
- Tide Memory Minigame
- Refuge Village Controller
- Shelter System
- Bubble Climb Minigame Overlay
- Shell Snap Minigame
- Echo Melody Minigame
- Mermaid Stats & Inventory
- Resource Support & Shop
- Entity Components — Visual Effects
- Game Scene Entries & Birth Waters
- Challenge Goals & Spawning
- Mermaid Stats — Balance & Buffs
- Audio Manager & Sound Effects
- Bubble Climb Controls
- Tide Weaving System
- World Stamp Rendering
- Mermaid Arms & Animation
- Challenge Giver Component
- Mermaid Figures — Baby
- Reef Asteroids Minigame Engine
- Region System
- Reef Asteroids Overlay
- Map Tiles — JSON Manifest
- Depth System
- Gameplay Reward Models
- Ecosystem Biome Catalog
- POI System
- World Chunk Factory
- Growth System
- Mermaid Figures — Child
- World Chunk — Detail Rendering
- Documentation — Design Decisions
- Movement Vector Utilities
- Component Base Classes
- Autonomy — Eating Behavior
- Cheat System
- Fish Visual Models
- Food System
- Region Map Cues & Expedition
- Movement Enums & Animation Modes
- Fish Drawing Factory
- HUD Layer
- Expedition Grid Math
- World Stamp Drawing
- Pearl Economy
- HUD — Biology Meter & Commands
- Buff Coding Keys
- Mermaid Name Editor
- Discovery & Depth Ranges
- Depth Zone Colors
- Mermaid Emotion Component
- Command & Touch System
- Mermaid Rig Debug Tool
- Mermaid Core Entity
- Game Sound Enum Values
- Encoding Utilities
- Autonomy — Bond Recovery
- Mermaid Intent & Acceptance
- Autotile Set Hashing
- Mermaid Rig Models
- HUD — Active Effects Shelf
- Aquatic Biomes
- Mermaid Figure Part Positioning
- Map Editor — SwiftUI Content View
- Map Editor — Depth Save
- Event Bus
- Mermaid Body Dimensions
- Map Editor Models
- Refuge Entry & Energy
- Ester Game
- Ester Game
- Components
- Managers
- Ester Game
- Components
- Components
- Ester Game
- Ester Game
- Managers
- Managers
- Managers
- Appdelegate
- Components
- Ester Game
- Tools Verify
- Ester Game
- Ester Game
- Ester Game
- Ester Game
- Managers
- Ester Game
- Ester Game
- Ester Game
- Components
- Ester Game
- Ester Game
- Storyboard
- Components
- Ester Game
- Ester Game
- ColorManager
- Managers
- Mapeditor Mapeditor
- ChallengeGiverComponent
- Mapeditor Mapeditor
- Ester Game
- FoodComponent
- Ester Game
- Ester Game
- Orientation
- Ester Game
- .touchesBegan
- Ester Game
- Gamescene
- Mapeditor Mapeditor
- SupportResourceKind
- Agents
- .touchesBegan
- Storyboard
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Agents
- Fonts
- Ester Game
- Ester Audio Asset Report
- Agents
- Regras
- Storyboard
- Storyboard
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- Assets
- LabelStyle
- FoodStyle
- GameScene Orchestration Shell Principle
- Freesound SFX Workflow
- Icon Asset Workflow
- Minigame Difficulty Criteria (1-5 Scale)
- Minigame Economy Balancing Formula
- Minigame Economic Profiles
- Character Chroma-Key Background Workflow
- Professor Octopus NPC Example
- Siren Reference Sprites
- Mermaid/Ester Character Visual Style
- Conchas (Shell) Economy
- Depth Layer System (7 Layers)
- Entry Text Storytelling System
- Map Access and Discovery Rules
- Map Discovery Flow
- Map Travel System
- Minimap System (Terraria-Inspired)
- Offline Movement System
- Points of Interest (POI) System
- RewardSystem
- Siren Phase Lifecycle
- World Model (Map, Phase, Depth Axes)
- Support Resource Types
- Ester/Assets.xcassets (Asset Catalog)
- Ambient Audio Depth Layers
- GameAudio System
- GameBalance
- GameScene.swift (Orchestration Shell)
- Graphify Knowledge Graph (graphify-out/graph.json)
- Autotile System
- MapEditor macOS App
- Refuge Shop (Loja)
- ResourceChoiceOverlay
- ResourceSupportSystem
- Mossy Terrain Tileset
- SupportResourceVisualFactory
- Freesound CLI Helper (Tools/freesound.cjs)
- Mossy Autotile Verification Script
- TileImageCache
- CodingKeys
- BondRecoveryState
- .texture
- Desbloqueio de Novos Mapas
- ReefFeedbackEffect
- SharedGameData
- TEMP_POI_VISUAL_TODO.md
- .addCommandButton
- IconKind
- TideMemoryCardState
- .touchesEnded
- EditorLayer
- ChildMermaidRig
- Orientation
- GridLines
- Mermaid

## God Nodes (most connected - your core abstractions)
1. `CGFloat` - 795 edges
2. `CGPoint` - 693 edges
3. `SKNode` - 493 edges
4. `String` - 393 edges
5. `CGSize` - 344 edges
6. `Int` - 299 edges
7. `DepthZone` - 168 edges
8. `GameContext` - 160 edges
9. `MermaidStats` - 136 edges
10. `GameUI` - 133 edges

## Surprising Connections (you probably didn't know these)
- `GridLines` --references--> `CGFloat`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/GameplayModels.swift
- `TileImageView` --references--> `CGFloat`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/GameplayModels.swift
- `EditorToolbar` --references--> `String`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/MermaidFigures/MermaidRigDebugTool.swift
- `AutotileSet` --references--> `String`  [EXTRACTED]
  MapEditor/MapEditor/EditorModels.swift → Ester/Game/MermaidFigures/MermaidRigDebugTool.swift
- `DepthDefinition` --references--> `String`  [EXTRACTED]
  MapEditor/MapEditor/EditorModels.swift → Ester/Game/MermaidFigures/MermaidRigDebugTool.swift

## Import Cycles
- None detected.

## Communities (243 total, 96 thin omitted)

### Community 0 - "Map Tiles — Mossy Terrain"
Cohesion: 0.13
Nodes (14): HouseFurnitureInventoryPanelItem, HouseFurniturePanelMode, inventory, placed, HouseFurniturePlacedPanelItem, HouseFurnitureTrayCategory, all, floor (+6 more)

### Community 1 - "Mermaid House System"
Cohesion: 0.07
Nodes (16): CGPoint, Interaction, enterHome, enterItemShop, enterUpgradeShop, restInBedroom, returnToVillage, talkToItemShopNpc (+8 more)

### Community 2 - "Map Tiles — Mossy Autotile"
Cohesion: 0.13
Nodes (10): MermaidNameEditorViewController, IndexPath, Notification, NSLayoutConstraint, UITableView, UITableViewCell, UITableViewDataSource, UITableViewDelegate (+2 more)

### Community 3 - "Gameplay Models & Scene Construction"
Cohesion: 0.09
Nodes (9): AutonomySystem, play, HorizontalBoundaryBalance, HorizontalBoundarySide, left, right, ClosedRange, Mermaid (+1 more)

### Community 4 - "Challenge Flow Controller"
Cohesion: 0.27
Nodes (5): RefugeStoreOverlay, RefugeEnhancementsOverlay, RefugeHouseInteriorController, RefugeOverlay, SKLabelNode

### Community 5 - "World Point & Rendering Primitives"
Cohesion: 0.12
Nodes (24): Decodable, Int, WorldTextureKey, Hashable, Hasher, Identifiable, AutotileSet, Color (+16 more)

### Community 6 - "Depth Environment & Ocean Parallax"
Cohesion: 0.13
Nodes (8): CGLineCap, SKShapeNode, SKTexture, TimeInterval, UIBezierPath, UIColor, UIImage, WorldPOIArtworkFactory

### Community 7 - "Banquet of Tides Minigame"
Cohesion: 0.05
Nodes (30): CGPath, ReefAsteroidsEngine, ReefAsteroidsOverlay, ReefAsteroidsRules, ReefFeedback, ReefFrame, ReefPlayer, ReefProjectile (+22 more)

### Community 8 - "Event System"
Cohesion: 0.08
Nodes (12): CoreMotion, BubbleClimbOverlay, ClimbBubble, ClimbVisual, Bool, Mermaid, NSCoder, Set (+4 more)

### Community 9 - "Species Registry & Mermaid Progression"
Cohesion: 0.08
Nodes (23): Bool, NSCoder, Set, SKLabelNode, SKShapeNode, TimeInterval, UIColor, UIEvent (+15 more)

### Community 10 - "Tide Memory Minigame"
Cohesion: 0.06
Nodes (22): SKNode, UIColor, CGSize, GameUI, CGRect, NSCache, NSString, SKSpriteNode (+14 more)

### Community 11 - "Refuge Village Controller"
Cohesion: 0.11
Nodes (12): AquaticSpecies, AquaticAnimalGroup, RegistroCatalog, RegistroMermaidObservationDefinition, RegistroProgressSnapshot, RegistroSpeciesDefinition, RegistroUnlockRequirement, challengeFromSpecies (+4 more)

### Community 12 - "Shelter System"
Cohesion: 0.07
Nodes (118): SharedGameData → Tiles → Mossy → terrain 256 → autotile preview, SharedGameData → Tiles → Mossy → terrain 256 → contact sheet, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 02 (+110 more)

### Community 13 - "Bubble Climb Minigame Overlay"
Cohesion: 0.11
Nodes (14): BanquetItemKind, crackedBone, moonRice, puffer, seaGrapes, sourKelp, sweetShell, whirlpool (+6 more)

### Community 14 - "Shell Snap Minigame"
Cohesion: 0.08
Nodes (26): EchoMelodyEngine, EchoMelodyInputResult, EchoMelodyNote, coral, kelp, moon, pearl, EchoMelodyOverlay (+18 more)

### Community 15 - "Echo Melody Minigame"
Cohesion: 0.11
Nodes (14): GridPos, Bool, Set, UIEvent, UITouch, Void, TideSessionType, basic (+6 more)

### Community 16 - "Mermaid Stats & Inventory"
Cohesion: 0.11
Nodes (15): PlayerCommand, challenge, explore, goDown, goLeft, goRight, goUp, objective (+7 more)

### Community 17 - "Resource Support & Shop"
Cohesion: 0.09
Nodes (8): GameScene, Bool, Set, SKCameraNode, SKView, UIEvent, UITouch, Void

### Community 19 - "Game Scene Entries & Birth Waters"
Cohesion: 0.11
Nodes (11): RegistroMermaidObservation, RegistroOverlay, Bool, CGRect, ClosedRange, Set, SKLabelNode, UIColor (+3 more)

### Community 20 - "Challenge Goals & Spawning"
Cohesion: 0.13
Nodes (6): EventSystem, UIColor, Void, WorldObjective, GameContext, TravelSystem

### Community 22 - "Audio Manager & Sound Effects"
Cohesion: 0.14
Nodes (19): SeededGenerator, Bool, ClosedRange, CGContext, CGRect, UIBezierPath, UIColor, WorldStampRenderer (+11 more)

### Community 23 - "Bubble Climb Controls"
Cohesion: 0.07
Nodes (12): CoreGraphics, UIColor, MermaidFigurePart, WorldChunkManager, WorldStampRenderer, WorldStampRenderer, SKTexture, WorldTextureKey (+4 more)

### Community 24 - "Tide Weaving System"
Cohesion: 0.08
Nodes (27): FishPattern, glowDots, plain, spots, stripes, FishVisualPalette, SpeciesVisualCatalog, SpeciesVisualProfile (+19 more)

### Community 25 - "World Stamp Rendering"
Cohesion: 0.04
Nodes (48): GameSound, ambientBubbleBurst, bigShadow, boatMuffled, challengeFail, challengeOpen, challengeSuccess, climbBounce (+40 more)

### Community 26 - "Mermaid Arms & Animation"
Cohesion: 0.19
Nodes (5): BanquetOfTidesOverlay, Mermaid, SKLabelNode, SKShapeNode, UIColor

### Community 27 - "Challenge Giver Component"
Cohesion: 0.10
Nodes (15): DepthZone, abyss, blue, clear, deep, mid, shallow, surface (+7 more)

### Community 29 - "Mermaid Figures — Baby"
Cohesion: 0.08
Nodes (19): Equatable, CameraController, SKCameraNode, UIColor, BoundaryPaletteEffect, DepthBoundaryEdge, lower, upper (+11 more)

### Community 30 - "Reef Asteroids Minigame Engine"
Cohesion: 0.04
Nodes (47): CodingKeys, activeBuffs, adaptationByZone, babyGuaranteedRequestsUsed, balanceVersion, birthDate, challengeHighScores, collectedPOIRewardKeys (+39 more)

### Community 31 - "Region System"
Cohesion: 0.09
Nodes (29): HouseObjectAttachmentSide, back, bottom, left, right, top, HouseObjectCategory, backWallDecoration (+21 more)

### Community 32 - "Reef Asteroids Overlay"
Cohesion: 0.12
Nodes (8): HouseCameraController, MermaidHouseSceneController, CGRect, ObjectIdentifier, Set, UIEdgeInsets, UITouch, Void

### Community 33 - "Map Tiles — JSON Manifest"
Cohesion: 0.10
Nodes (19): ShellSnapBoard, ShellSnapFall, ShellSnapOverlay, ShellSnapPop, ShellSnapPosition, ShellSnapRules, ShellSnapSpawn, ShellSnapTheme (+11 more)

### Community 34 - "Depth System"
Cohesion: 0.19
Nodes (8): PlacedHouseObject, Data, UUID, HouseLayoutData, HouseRoomScene, Decoder, Encoder, UUID

### Community 35 - "Gameplay Reward Models"
Cohesion: 0.11
Nodes (18): NSCoder, FishDrawingFactory, Bool, SKShapeNode, UIBezierPath, UIColor, UIColor, FishSilhouette (+10 more)

### Community 36 - "Ecosystem Biome Catalog"
Cohesion: 0.05
Nodes (37): columns, connectionMaskCounts, 0, 1, 10, 11, 12, 13 (+29 more)

### Community 37 - "POI System"
Cohesion: 0.11
Nodes (17): WorldStampKind, coralBranch, coralFan, coralTube, crystalCluster, currentRibbon, kelpBlade, kelpBush (+9 more)

### Community 38 - "World Chunk Factory"
Cohesion: 0.10
Nodes (23): Array, EcosystemBiomeCatalog, EcosystemBiomeID, estuario, florestaKelp, manguezal, marAbertoTemperado, marAbertoTropical (+15 more)

### Community 39 - "Growth System"
Cohesion: 0.19
Nodes (4): POISystem, Bool, Date, WorldPOI

### Community 40 - "Mermaid Figures — Child"
Cohesion: 0.26
Nodes (9): ActiveHouseObjectPlacement, HouseMermaidAutonomyController, HouseRoomSceneID, HouseSceneDefaults, HouseSceneMetrics, Source, existing, inventory (+1 more)

### Community 41 - "World Chunk — Detail Rendering"
Cohesion: 0.12
Nodes (4): CheatSystem, Suggestion, Bool, ClosedRange

### Community 42 - "Documentation — Design Decisions"
Cohesion: 0.17
Nodes (6): ChallengeFlowController, Bool, SKCameraNode, Void, ChallengeChoiceOverlay, ResourceChoiceOverlay

### Community 43 - "Movement Vector Utilities"
Cohesion: 0.15
Nodes (6): GrowthSystem, Requirement, Bool, Double, SKShapeNode, TimeInterval

### Community 44 - "Component Base Classes"
Cohesion: 0.14
Nodes (17): BanquetEntity, BanquetFeedback, BanquetFeedbackEffect, huge, pop, shake, spray, BanquetFeedbackTone (+9 more)

### Community 45 - "Autonomy — Eating Behavior"
Cohesion: 0.17
Nodes (12): EcosystemVegetationCategory, algae, chemosyntheticMat, coral, iceAlgae, kelp, macrophyte, mangroveRoot (+4 more)

### Community 46 - "Cheat System"
Cohesion: 0.16
Nodes (15): Bool, CGRect, NSCoder, SKLabelNode, SKShapeNode, UIColor, UIEdgeInsets, Void (+7 more)

### Community 47 - "Fish Visual Models"
Cohesion: 0.14
Nodes (17): BadgePlacement, LayoutPoint, Mode, house, map, professor, store, NpcKind (+9 more)

### Community 48 - "Food System"
Cohesion: 0.07
Nodes (112): SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c05, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c06, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c07, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r07 c08 (+104 more)

### Community 49 - "Region Map Cues & Expedition"
Cohesion: 0.09
Nodes (23): ExpressionComponent, NSCoder, FoodComponent, Bool, HealthComponent, NSCoder, IntentComponent, NSCoder (+15 more)

### Community 50 - "Movement Enums & Animation Modes"
Cohesion: 0.14
Nodes (6): FishNode, Bool, NSCoder, TimeInterval, FishSystem, Bool

### Community 51 - "Fish Drawing Factory"
Cohesion: 0.20
Nodes (3): BabyMermaidFigure, Bool, Double

### Community 52 - "HUD Layer"
Cohesion: 0.19
Nodes (4): ChildMermaidFigure, Bool, Double, SKAction

### Community 53 - "Expedition Grid Math"
Cohesion: 0.14
Nodes (8): DirectionalCore, MermaidBody, MotionProfile, Bool, Double, SKSpriteNode, MovementDirectionProtocol, MovementTypeProtocol

### Community 54 - "World Stamp Drawing"
Cohesion: 0.10
Nodes (22): Calendar, RefugeShopCatalog, RefugeShopItem, RefugeShopPurchase, houseObject, resource, ResourceSupportSystem, SupportResourceKind (+14 more)

### Community 55 - "Pearl Economy"
Cohesion: 0.13
Nodes (14): MermaidEmotion, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 56 - "HUD — Biology Meter & Commands"
Cohesion: 0.13
Nodes (19): MermaidExpressionLibrary, MermaidExpressionPreset, MermaidEyeAsset, closed, half, open, wide, MermaidEyebrowExpression (+11 more)

### Community 57 - "Buff Coding Keys"
Cohesion: 0.18
Nodes (5): HUDLayer, Bool, SKLabelNode, TimeInterval, Void

### Community 58 - "Mermaid Name Editor"
Cohesion: 0.08
Nodes (22): AquaticBiome, abyssPlain, ancientRuins, cavernMouth, coralGarden, crystalField, deepVents, kelpForest (+14 more)

### Community 59 - "Discovery & Depth Ranges"
Cohesion: 0.42
Nodes (3): Set, UIEvent, UITouch

### Community 60 - "Depth Zone Colors"
Cohesion: 0.08
Nodes (25): App, AppKit, AutotileSummary, ContentView, DepthRow, EditorToolbar, GridLines, MapCanvasView (+17 more)

### Community 61 - "Mermaid Emotion Component"
Cohesion: 0.18
Nodes (8): NSCoder, FoodKind, FoodNode, FoodSystem, Bool, NSCoder, SKTexture, UIColor

### Community 63 - "Mermaid Rig Debug Tool"
Cohesion: 0.15
Nodes (10): MermaidRigAxis, scale, x, y, z, MermaidRigTransform, Decoder, MermaidFigurePart (+2 more)

### Community 64 - "Mermaid Core Entity"
Cohesion: 0.21
Nodes (8): MermaidArms, Orientation, horizontal, vertical, Rotation, down, up, SKSpriteNode

### Community 65 - "Game Sound Enum Values"
Cohesion: 0.30
Nodes (4): ExpeditionMapNode, SKShapeNode, UIColor, WarmCurrentEnvironment

### Community 66 - "Encoding Utilities"
Cohesion: 0.16
Nodes (11): A, B, C, EntityManager, GKComponent, GKEntity, ObjectIdentifier, Set (+3 more)

### Community 67 - "Autonomy — Bond Recovery"
Cohesion: 0.17
Nodes (9): ChallengeChrome, ChallengeResult, Bool, SKLabelNode, ChallengeVictoryReward, none, resource, shellBonus (+1 more)

### Community 68 - "Mermaid Intent & Acceptance"
Cohesion: 0.11
Nodes (18): MermaidIntent, avoidingDanger, eating, enteringRefuge, followingFish, goingDeeper, goingToObjective, goingUp (+10 more)

### Community 69 - "Autotile Set Hashing"
Cohesion: 0.30
Nodes (4): HUDPalette, SKShapeNode, UIBezierPath, UIColor

### Community 70 - "Mermaid Rig Models"
Cohesion: 0.22
Nodes (7): MermaidRigDebugTool, Bool, MermaidFigurePart, NSCoder, SKLabelNode, UIEdgeInsets, Void

### Community 73 - "Mermaid Figure Part Positioning"
Cohesion: 0.05
Nodes (52): CaseIterable, Codable, Reward, RewardKind, item, pearls, regionMap, story (+44 more)

### Community 74 - "Map Editor — SwiftUI Content View"
Cohesion: 0.28
Nodes (3): AdultMermaidFigure, MermaidFigurePart, Bool

### Community 75 - "Map Editor — Depth Save"
Cohesion: 0.11
Nodes (18): Chegada em Mapa Novo, Conchas (Moeda), Coragem, Decisões Abertas, Desbloqueio Global vs Por Mapa, Energia e Exploração, Estrutura de Cada Mapa, Fases da Sereia (+10 more)

### Community 76 - "Event Bus"
Cohesion: 0.21
Nodes (11): FishBehaviorComponent, FishSpecies, FishSwimPattern, flee, guide, school, wander, Bool (+3 more)

### Community 77 - "Mermaid Body Dimensions"
Cohesion: 0.12
Nodes (16): MermaidFigurePart, chest, eyebrowLeft, eyebrowRight, eyeLeft, eyeRight, hairBack, hairFront (+8 more)

### Community 78 - "Map Editor Models"
Cohesion: 0.11
Nodes (18): Anatomia De Um Bom Movel, Checklist Antes De Gerar, Como Traduzir Tema De Sereia Para Moveis, Composicao, Funcao Antes Do Ornamento, Fundo Transparente, FURNITURE_ART_GUIDE, Integracao No Jogo (+10 more)

### Community 79 - "Refuge Entry & Energy"
Cohesion: 0.31
Nodes (4): MermaidEmotionComponent, Bool, Mermaid, NSCoder

### Community 80 - "Ester Game"
Cohesion: 0.18
Nodes (13): ChallengeCompletedEvent, EventBus, FoodCollectedEvent, GameEvent, MermaidStateChangedEvent, RegionDiscoveredEvent, Any, GKEntity (+5 more)

### Community 81 - "Ester Game"
Cohesion: 0.15
Nodes (11): PlacedReefCluster, ReefCluster, Bool, CGRect, SKSpriteNode, WorldChunkFactory, NSCache, NSString (+3 more)

### Community 82 - "Components"
Cohesion: 0.07
Nodes (29): CodingKey, CodingKeys, buffKind, duration, expiresAt, itemId, kind, pearlAmount (+21 more)

### Community 83 - "Managers"
Cohesion: 0.13
Nodes (14): CHARACTER_ART_GUIDE, Checklist Antes De Gerar, Como Usar Concept Arts, Composicao, Fundo Transparente, Integracao No Jogo, Negativos Uteis, Nivel De Detalhe (+6 more)

### Community 84 - "Ester Game"
Cohesion: 0.20
Nodes (8): Mermaid, MermaidFigure, MermaidFormKind, adult, baby, child, young, SKSpriteNode

### Community 85 - "Components"
Cohesion: 0.13
Nodes (15): HousePhysicsCategory, HouseSurface, HouseSurfaceKind, backWall, ceiling, floor, leftWall, rightWall (+7 more)

### Community 86 - "Components"
Cohesion: 0.12
Nodes (15): MermaidExpressionName, adventurous, curious, eating, focused, happy, hungry, neutral (+7 more)

### Community 87 - "Ester Game"
Cohesion: 0.11
Nodes (19): AVAudioPCMBuffer, AVAudioPlayer, AVFoundation, AmbienceSpec, GameAmbience, abyss, clear, deep (+11 more)

### Community 88 - "Ester Game"
Cohesion: 0.15
Nodes (14): Bool, NSCoder, SKLabelNode, VisualStyle, environment, npc, object, warmCurrentEnvironment (+6 more)

### Community 89 - "Managers"
Cohesion: 0.21
Nodes (7): AppDelegate, Any, Bool, UIApplication, UIApplicationDelegate, UIResponder, UIWindow

### Community 91 - "Managers"
Cohesion: 0.15
Nodes (11): AmbientLifeNode, OceanPalette, Style, jelly, needleFish, ovalFish, ray, NSCoder (+3 more)

### Community 92 - "Appdelegate"
Cohesion: 0.06
Nodes (15): ClosedRange, expeditionRevealByRegion, inventoryItems, mapPositionByRegion, repeatablePOIRewardAvailableAtByKey, MermaidStats, Bool, Data (+7 more)

### Community 93 - "Components"
Cohesion: 0.33
Nodes (12): connection_mask(), fail(), inner_corner_mask(), main(), png_size(), preferred_exact_candidates(), preferred_inner_candidates(), rectangle() (+4 more)

### Community 94 - "Ester Game"
Cohesion: 0.07
Nodes (16): AncientRuinsGameScene, BirthWatersGameScene, CalmGardenGameScene, CaveMouthGameScene, CrystalFieldsGameScene, DistantSurfaceGameScene, EmeraldReefGameScene, GreatDeltaGameScene (+8 more)

### Community 96 - "Tools Verify"
Cohesion: 0.18
Nodes (11): Conceito, Coordenadas, Descoberta, Estrutura de Dados, Eventos Aleatórios — Upgrade, Pontos de Interesse (POIs), Retorno a POIs Descobertos, Sistema de Recompensas (+3 more)

### Community 97 - "Ester Game"
Cohesion: 0.10
Nodes (11): Set, Region, RegionDiscoverySystem, RegionMenuOverlay, CGRect, ClosedRange, NSCoder, Set (+3 more)

### Community 98 - "Ester Game"
Cohesion: 0.25
Nodes (6): Channel, caustics, fog, particles, shader, OceanVisualTuning

### Community 100 - "Ester Game"
Cohesion: 0.20
Nodes (9): 1. Required Context, 2. Size and Proportion, 3. Asset Catalog Location, 4. Tint and Color Configuration, 5. File and Asset Names, 6. Contents.json, 7. Code Integration, 8. Final Checklist (+1 more)

### Community 101 - "Ester Game"
Cohesion: 0.09
Nodes (20): MermaidEmotionalState, MermaidMoodCue, currentLift, currentStrain, encouraged, none, MermaidMoodTone, danger (+12 more)

### Community 102 - "Managers"
Cohesion: 0.29
Nodes (5): HUDTexture, NSCache, NSString, SKSpriteNode, SKTexture

### Community 103 - "Ester Game"
Cohesion: 0.20
Nodes (7): MermaidRigDocument, MermaidRigStore, Any, Data, MermaidFigurePart, MermaidRigPosition, URL

### Community 104 - "Ester Game"
Cohesion: 0.21
Nodes (8): Location, house, professor, store, RefugeDioramaController, NSCoder, UIEdgeInsets, Void

### Community 106 - "Components"
Cohesion: 0.14
Nodes (7): RefugeFlowController, Bool, Void, RefugeScene, SKView, TimeInterval, SKScene

### Community 107 - "Ester Game"
Cohesion: 0.25
Nodes (7): POIChallengeOfferOverlay, NSCoder, Set, UIColor, UIEvent, UITouch, Void

### Community 108 - "Ester Game"
Cohesion: 0.14
Nodes (11): CoreText, HUDTypography, IconKind, plankton, shell, wave, LabelStyle, body (+3 more)

### Community 109 - "Storyboard"
Cohesion: 0.79
Nodes (8): docs → storyboard → ref teacher →   (12), docs → storyboard → ref teacher →   (13), docs → storyboard → ref teacher → adult siren, docs → storyboard → ref teacher → baby siren, docs → storyboard → ref teacher → child siren, docs → storyboard → ref teacher → Octo Sheriff, docs → storyboard → ref teacher → Postcard designs   Barbara Dziadosz, docs → storyboard → ref teacher → young siren

### Community 110 - "Components"
Cohesion: 0.21
Nodes (7): MermaidEyebrows, SKSpriteNode, MermaidEyes, SKSpriteNode, SKSpriteNode, MermaidMouth, SKSpriteNode

### Community 111 - "Ester Game"
Cohesion: 0.25
Nodes (6): Architecture And Ownership, Goal Mode Discipline, Icons And Assets, Knowledge Graph First, Project Instructions, Sound Effects

### Community 112 - "Ester Game"
Cohesion: 0.25
Nodes (8): Adaptação para Ester, Como o Terraria faz (referência), Mini-mapa de Expedição, O que aparece no mini-mapa, O que NÃO aparece, Porcentagem de descoberta, Raio de visão — decisão fechada, Regras propostas para o mini-mapa

### Community 115 - "Managers"
Cohesion: 0.18
Nodes (9): MovementDirection, down, left, right, up, MovementType, fast, idle (+1 more)

### Community 116 - "Mapeditor Mapeditor"
Cohesion: 0.49
Nodes (3): Set, UIEvent, UITouch

### Community 117 - "ChallengeGiverComponent"
Cohesion: 0.47
Nodes (3): Set, UIEvent, UITouch

### Community 118 - "Mapeditor Mapeditor"
Cohesion: 0.33
Nodes (4): RegistroFlowController, Bool, UIEdgeInsets, Void

### Community 119 - "Ester Game"
Cohesion: 0.17
Nodes (6): FloorFurnitureSpec, HouseObjectCatalog, HouseObjectDefinition, WallDecorationSpec, HouseSurfaceKind, SKSpriteNode

### Community 120 - "FoodComponent"
Cohesion: 0.14
Nodes (14): AquaticAnimalGroup, annelid, arthropod, bird, cephalopod, cnidarian, crustacean, echinoderm (+6 more)

### Community 121 - "Ester Game"
Cohesion: 0.29
Nodes (5): Balanceamento de Minigames, Criterio de Dificuldade, Formula, Perfis Atuais, Regra de Ajuste

### Community 122 - "Ester Game"
Cohesion: 0.29
Nodes (6): Adding A New Resource, Concept, Current Resources, Refuge Shop, Resource Flow, Resource Support System

### Community 123 - "Orientation"
Cohesion: 0.24
Nodes (6): HouseMiniroomTheme, HouseRoomFrontFrameNode, HouseRoomNode, NSCoder, RoomSurfaceMapping, UIColor

### Community 124 - "Ester Game"
Cohesion: 0.29
Nodes (5): ObjectiveComponent, Bool, NSCoder, TimeInterval, Void

### Community 125 - ".touchesBegan"
Cohesion: 0.12
Nodes (18): BondRecoveryBalance, BondRecoveryHUDState, available, hidden, ready, waiting, BondRecoveryState, idle (+10 more)

### Community 126 - "Ester Game"
Cohesion: 0.22
Nodes (7): TimeInterval, VisualEffect, bob, fadeIn, fadeOut, glow, pulse

### Community 127 - "Gamescene"
Cohesion: 0.29
Nodes (6): Abrir, Autotile, Dados, MapEditor, Uso, Verificacao Leve

### Community 128 - "Mapeditor Mapeditor"
Cohesion: 0.33
Nodes (6): FishMotionMode, gatheringForPlay, guiding, normal, playing, Date

### Community 129 - "SupportResourceKind"
Cohesion: 0.36
Nodes (3): Set, UIEvent, UITouch

### Community 130 - "Agents"
Cohesion: 0.42
Nodes (3): RefugePortalNode, SKTexture, SKEmitterNode

### Community 131 - ".touchesBegan"
Cohesion: 0.32
Nodes (6): FaceTextureCache, SKSpriteNode, SKTexture, NSCache, NSString, SKTexture

### Community 132 - "Storyboard"
Cohesion: 1.00
Nodes (3): docs → storyboard → ref seller →   (12), docs → storyboard → ref seller →   (13), docs → storyboard → ref seller → Mermay 01   PERSONAL WORK

### Community 133 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → challenge → challenge, Ester → Assets → Icons → customIcons → challenge → challenge@2x, Ester → Assets → Icons → customIcons → challenge → challenge@3x

### Community 134 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → compass → compass, Ester → Assets → Icons → customIcons → compass → compass@2x, Ester → Assets → Icons → customIcons → compass → compass@3x

### Community 135 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → conch → conch, Ester → Assets → Icons → customIcons → conch → conch@2x, Ester → Assets → Icons → customIcons → conch → conch@3x

### Community 136 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → eat → eat, Ester → Assets → Icons → customIcons → eat → eat@2x, Ester → Assets → Icons → customIcons → eat → eat@3x

### Community 137 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → objective → objective, Ester → Assets → Icons → customIcons → objective → objective@2x, Ester → Assets → Icons → customIcons → objective → objective@3x

### Community 138 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → refuge → refuge, Ester → Assets → Icons → customIcons → refuge → refuge@2x, Ester → Assets → Icons → customIcons → refuge → refuge@3x

### Community 139 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → roadmap → roadmap, Ester → Assets → Icons → customIcons → roadmap → roadmap@2x, Ester → Assets → Icons → customIcons → roadmap → roadmap@3x

### Community 140 - "Assets"
Cohesion: 1.00
Nodes (3): Ester → Assets → Icons → customIcons → sleep → sleep, Ester → Assets → Icons → customIcons → sleep → sleep@2x, Ester → Assets → Icons → customIcons → sleep → sleep@3x

### Community 143 - "Ester Game"
Cohesion: 0.40
Nodes (5): Floresta de Kelp × Média, Floresta de Kelp × Rasa, POIs da Fase Bebê, Recife Tropical × Média, Recife Tropical × Rasa

### Community 144 - "Ester Audio Asset Report"
Cohesion: 0.40
Nodes (4): Assets, Ester Audio Asset Report, Missing Download Commands, Summary

### Community 145 - "Agents"
Cohesion: 0.40
Nodes (4): Complete Event Mapping, Design Direction, Ester Sound Effect Map, Intentionally Silent

### Community 189 - "LabelStyle"
Cohesion: 0.25
Nodes (7): POIComponent, POIState, active, completed, dormant, interacting, NSCoder

### Community 190 - "FoodStyle"
Cohesion: 0.29
Nodes (7): FoodStyle, critter, crystal, fruit, glow, leaf, pearl

### Community 229 - "TileImageCache"
Cohesion: 0.43
Nodes (5): NSCache, URL, TileImageCache, NSImage, NSURL

### Community 230 - "CodingKeys"
Cohesion: 0.29
Nodes (5): BanquetPlayer, Bool, CGRect, NSCoder, Void

### Community 232 - ".texture"
Cohesion: 0.39
Nodes (5): MermaidTemplateTexture, NSCache, NSString, SKTexture, UIColor

### Community 233 - "Desbloqueio de Novos Mapas"
Cohesion: 0.50
Nodes (4): Arquitetura — GameScene por mapa, Como um novo mapa é descoberto, Desbloqueio de Novos Mapas, Fluxo de desbloqueio

### Community 234 - "ReefFeedbackEffect"
Cohesion: 0.29
Nodes (7): ReefFeedbackEffect, combo, crack, hit, score, surge, wave

### Community 235 - "SharedGameData"
Cohesion: 0.50
Nodes (3): SharedGameData, Tilesets, Verificacao

### Community 239 - "TideMemoryCardState"
Cohesion: 0.47
Nodes (3): ChildMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 240 - ".touchesEnded"
Cohesion: 0.06
Nodes (29): AnyObject, Comparable, ChallengeGiverComponent, Bool, NSCoder, ChallengeGiver, ChallengeKind, ascent (+21 more)

### Community 241 - "EditorLayer"
Cohesion: 0.60
Nodes (3): AdultMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 242 - "ChildMermaidRig"
Cohesion: 0.60
Nodes (3): BabyMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 246 - "GridLines"
Cohesion: 0.50
Nodes (4): MermaidEntity, Mermaid, NSCoder, GKEntity

### Community 247 - "Mermaid"
Cohesion: 0.20
Nodes (7): Mermaid, Direction, down, left, none, right, up

## Knowledge Gaps
- **768 isolated node(s):** `wander`, `school`, `flee`, `guide`, `open` (+763 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **96 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CGFloat` connect `Gameplay Reward Models` to `Map Tiles — Mossy Terrain`, `Mermaid House System`, `Map Tiles — Mossy Autotile`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Tide Weaving System`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Mermaid Figures — Baby`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `World Chunk Factory`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Cheat System`, `Fish Visual Models`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Game Sound Enum Values`, `Autonomy — Bond Recovery`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `HUD — Active Effects Shelf`, `Aquatic Biomes`, `Mermaid Figure Part Positioning`, `Map Editor — SwiftUI Content View`, `Event Bus`, `Refuge Entry & Energy`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Managers`, `Managers`, `Appdelegate`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `.touchesBegan`, `Ester Game`, `Agents`, `CodingKeys`, `BondRecoveryState`, `.texture`, `.addCommandButton`, `IconKind`, `TideMemoryCardState`, `.touchesEnded`, `EditorLayer`, `ChildMermaidRig`?**
  _High betweenness centrality (0.215) - this node is a cross-community bridge._
- **Why does `String` connect `Mermaid Figure Part Positioning` to `Map Tiles — Mossy Terrain`, `Mermaid House System`, `Map Tiles — Mossy Autotile`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `Gameplay Reward Models`, `World Chunk Factory`, `Growth System`, `World Chunk — Detail Rendering`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Autonomy — Eating Behavior`, `Cheat System`, `Region Map Cues & Expedition`, `World Stamp Drawing`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Game Sound Enum Values`, `Autonomy — Bond Recovery`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `Event Bus`, `Mermaid Body Dimensions`, `Components`, `Ester Game`, `Components`, `Components`, `Ester Game`, `Ester Game`, `Managers`, `Appdelegate`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `ColorManager`, `Ester Game`, `FoodComponent`, `Ester Game`, `SupportResourceKind`, `.touchesBegan`, `.texture`, `.addCommandButton`, `.touchesEnded`?**
  _High betweenness centrality (0.201) - this node is a cross-community bridge._
- **Why does `CGPoint` connect `Mermaid House System` to `Mapeditor Mapeditor`, `Map Tiles — Mossy Terrain`, `SupportResourceKind`, `Gameplay Models & Scene Construction`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Mermaid Figures — Baby`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `Gameplay Reward Models`, `Growth System`, `Mermaid Figures — Child`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Cheat System`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Game Sound Enum Values`, `Encoding Utilities`, `Autonomy — Bond Recovery`, `Autotile Set Hashing`, `Mermaid Rig Models`, `HUD — Active Effects Shelf`, `Aquatic Biomes`, `Mermaid Figure Part Positioning`, `Event Bus`, `Mermaid Body Dimensions`, `Ester Game`, `Ester Game`, `Managers`, `Managers`, `Appdelegate`, `Ester Game`, `CodingKeys`, `Managers`, `Ester Game`, `Components`, `Ester Game`, `.addCommandButton`, `.touchesEnded`, `ChallengeGiverComponent`, `Ester Game`, `Orientation`, `Ester Game`, `Ester Game`?**
  _High betweenness centrality (0.119) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `CGFloat` (e.g. with `.update()` and `.drawReefSkirt()`) actually correct?**
  _`CGFloat` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 34 inferred relationships involving `CGPoint` (e.g. with `.update()` and `.openChallengeChoiceMenu()`) actually correct?**
  _`CGPoint` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 107 inferred relationships involving `SKNode` (e.g. with `.buildPlayer()` and `.showFeedback()`) actually correct?**
  _`SKNode` has 107 INFERRED edges - model-reasoned connections that need verification._
- **Are the 9 inferred relationships involving `String` (e.g. with `.touchesBegan()` and `.touchesBegan()`) actually correct?**
  _`String` has 9 INFERRED edges - model-reasoned connections that need verification._