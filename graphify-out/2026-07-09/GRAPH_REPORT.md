# Graph Report - Mermaid  (2026-07-09)

## Corpus Check
- 349 files · ~3,504,748 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 4108 nodes · 14909 edges · 248 communities (159 shown, 89 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 1972 edges (avg confidence: 0.73)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7a30f586`
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
- Autonomy — Fish Play & Guidance
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
- Ester Game
- Tools Verify
- Ester Game
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
- BabyMermaidRig
- GridLines
- Mermaid
- floor

## God Nodes (most connected - your core abstractions)
1. `CGFloat` - 795 edges
2. `CGPoint` - 691 edges
3. `SKNode` - 493 edges
4. `String` - 393 edges
5. `CGSize` - 344 edges
6. `Int` - 297 edges
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

## Communities (248 total, 89 thin omitted)

### Community 0 - "Map Tiles — Mossy Terrain"
Cohesion: 0.13
Nodes (15): HouseFurnitureInventoryPanelItem, HouseFurniturePanelMode, inventory, placed, HouseFurniturePlacedPanelItem, HouseFurnitureTrayCategory, all, furniture (+7 more)

### Community 1 - "Mermaid House System"
Cohesion: 0.06
Nodes (21): SKNode, NSCoder, SupportResourceVisualFactory, UIColor, Interaction, enterHome, enterItemShop, enterUpgradeShop (+13 more)

### Community 2 - "Map Tiles — Mossy Autotile"
Cohesion: 0.10
Nodes (14): MermaidNameEditorViewController, GameViewController, Bool, IndexPath, Notification, NSLayoutConstraint, UIInterfaceOrientationMask, UITableView (+6 more)

### Community 3 - "Gameplay Models & Scene Construction"
Cohesion: 0.08
Nodes (6): AutonomySystem, HorizontalBoundarySide, left, right, ClosedRange, Mermaid

### Community 4 - "Challenge Flow Controller"
Cohesion: 0.09
Nodes (88): SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r03 c12, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r03 c13, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r03 c14, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r04 c01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r04 c02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r04 c03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r04 c04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r04 c05 (+80 more)

### Community 5 - "World Point & Rendering Primitives"
Cohesion: 0.10
Nodes (22): Decodable, Int, TimeInterval, TideMemoryRules, TideMemoryTimeRecovery, WorldTextureKey, Hashable, Hasher (+14 more)

### Community 6 - "Depth Environment & Ocean Parallax"
Cohesion: 0.13
Nodes (10): CGLineCap, CGPoint, Bool, SKShapeNode, SKTexture, TimeInterval, UIBezierPath, UIColor (+2 more)

### Community 7 - "Banquet of Tides Minigame"
Cohesion: 0.18
Nodes (9): ReefAsteroidsEngine, ReefFeedback, ReefFrame, ReefPlayer, ReefProjectile, ReefRock, UUID, Visual (+1 more)

### Community 8 - "Event System"
Cohesion: 0.07
Nodes (14): CoreMotion, BubbleClimbOverlay, ClimbBubble, ClimbVisual, Bool, Mermaid, NSCoder, Set (+6 more)

### Community 9 - "Species Registry & Mermaid Progression"
Cohesion: 0.11
Nodes (16): Bool, NSCoder, Set, SKLabelNode, SKShapeNode, UIColor, UIEvent, UITouch (+8 more)

### Community 10 - "Tide Memory Minigame"
Cohesion: 0.13
Nodes (11): CGSize, GameUI, CGRect, NSCache, NSString, SKSpriteNode, SKTexture, UIImage (+3 more)

### Community 11 - "Refuge Village Controller"
Cohesion: 0.12
Nodes (15): HUDTypography, String, AquaticSpecies, AquaticSpeciesCatalog, EntryTextCatalog, AquaticAnimalGroup, RegistroCatalog, RegistroMermaidObservationDefinition (+7 more)

### Community 12 - "Shelter System"
Cohesion: 0.11
Nodes (73): SharedGameData → Tiles → Mossy → terrain 256 → autotile preview, SharedGameData → Tiles → Mossy → terrain 256 → contact sheet, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 02 (+65 more)

### Community 13 - "Bubble Climb Minigame Overlay"
Cohesion: 0.11
Nodes (14): BanquetItemKind, crackedBone, moonRice, puffer, seaGrapes, sourKelp, sweetShell, whirlpool (+6 more)

### Community 14 - "Shell Snap Minigame"
Cohesion: 0.08
Nodes (26): EchoMelodyEngine, EchoMelodyInputResult, EchoMelodyNote, coral, kelp, moon, pearl, EchoMelodyOverlay (+18 more)

### Community 15 - "Echo Melody Minigame"
Cohesion: 0.10
Nodes (17): GridPos, Bool, NSCoder, Set, SKLabelNode, SKShapeNode, UIColor, UIEvent (+9 more)

### Community 16 - "Mermaid Stats & Inventory"
Cohesion: 0.20
Nodes (5): discoveryPointByRegion, StableMapRNG, ClosedRange, UInt64, OfflineProgressSystem

### Community 17 - "Resource Support & Shop"
Cohesion: 0.08
Nodes (11): WorldChunkManager, GameScene, Bool, Set, SKCameraNode, SKView, TimeInterval, UIColor (+3 more)

### Community 19 - "Game Scene Entries & Birth Waters"
Cohesion: 0.10
Nodes (13): RegistroMermaidObservation, RegistroOverlay, Bool, CGRect, ClosedRange, NSCoder, Set, SKLabelNode (+5 more)

### Community 20 - "Challenge Goals & Spawning"
Cohesion: 0.09
Nodes (9): EventSystem, UIColor, Void, WorldObjective, CGVector, GameContext, RewardSystem, TravelSystem (+1 more)

### Community 21 - "Mermaid Stats — Balance & Buffs"
Cohesion: 0.15
Nodes (5): CGPath, ReefAsteroidsOverlay, SKLabelNode, SKShapeNode, UIColor

### Community 22 - "Audio Manager & Sound Effects"
Cohesion: 0.18
Nodes (14): CGContext, CGRect, UIBezierPath, UIColor, WorldStampRenderer, CGContext, CGContext, UIColor (+6 more)

### Community 23 - "Bubble Climb Controls"
Cohesion: 0.07
Nodes (9): CoreText, UIColor, WorldStampRenderer, WorldStampRenderer, WorldTextureKey, OceanPalette, Foundation, SpriteKit (+1 more)

### Community 24 - "Tide Weaving System"
Cohesion: 0.08
Nodes (27): FishPattern, glowDots, plain, spots, stripes, FishVisualPalette, SpeciesVisualCatalog, SpeciesVisualProfile (+19 more)

### Community 25 - "World Stamp Rendering"
Cohesion: 0.04
Nodes (48): GameSound, ambientBubbleBurst, bigShadow, boatMuffled, challengeFail, challengeOpen, challengeSuccess, climbBounce (+40 more)

### Community 26 - "Mermaid Arms & Animation"
Cohesion: 0.16
Nodes (7): BanquetOfTidesOverlay, Mermaid, NSCoder, SKLabelNode, SKShapeNode, UIColor, Void

### Community 27 - "Challenge Giver Component"
Cohesion: 0.10
Nodes (11): CGFloat, HouseFurnitureScaleCatalog, HouseObjectDefinition, MermaidRigTransform, Decoder, OceanParallaxBackdrop, SKSpriteNode, SKTexture (+3 more)

### Community 28 - "Autonomy — Fish Play & Guidance"
Cohesion: 0.09
Nodes (26): CaseIterable, InteractionBalance, POIChallenge, POIDefinition, POIVisual, RepeatablePOIReward, StableRNG, ClosedRange (+18 more)

### Community 29 - "Mermaid Figures — Baby"
Cohesion: 0.11
Nodes (16): Equatable, BoundaryPaletteEffect, DepthBoundaryEdge, lower, upper, DepthEnvironment, DepthSystem, MermaidPaletteTransition (+8 more)

### Community 30 - "Reef Asteroids Minigame Engine"
Cohesion: 0.05
Nodes (44): CodingKeys, activeBuffs, adaptationByZone, babyGuaranteedRequestsUsed, balanceVersion, birthDate, collectedPOIRewardKeys, courage (+36 more)

### Community 31 - "Region System"
Cohesion: 0.12
Nodes (21): Codable, HouseObjectAttachmentSide, back, bottom, left, right, top, HouseObjectDefinition (+13 more)

### Community 32 - "Reef Asteroids Overlay"
Cohesion: 0.16
Nodes (4): ActiveHouseObjectPlacement, MermaidHouseSceneController, HouseSurfaceKind, SKSpriteNode

### Community 33 - "Map Tiles — JSON Manifest"
Cohesion: 0.09
Nodes (20): ShellSnapBoard, ShellSnapFall, ShellSnapOverlay, ShellSnapPop, ShellSnapPosition, ShellSnapRules, ShellSnapSpawn, ShellSnapTheme (+12 more)

### Community 34 - "Depth System"
Cohesion: 0.10
Nodes (18): CodingKey, PlacedHouseObject, Data, UUID, CodingKeys, placedObjects, rooms, HouseLayoutData (+10 more)

### Community 35 - "Gameplay Reward Models"
Cohesion: 0.26
Nodes (5): FishDrawingFactory, Bool, SKShapeNode, UIBezierPath, UIColor

### Community 36 - "Ecosystem Biome Catalog"
Cohesion: 0.05
Nodes (37): columns, connectionMaskCounts, 0, 1, 10, 11, 12, 13 (+29 more)

### Community 37 - "POI System"
Cohesion: 0.11
Nodes (17): WorldStampKind, coralBranch, coralFan, coralTube, crystalCluster, currentRibbon, kelpBlade, kelpBush (+9 more)

### Community 38 - "World Chunk Factory"
Cohesion: 0.10
Nodes (22): Array, EcosystemBiomeCatalog, EcosystemBiomeID, estuario, florestaKelp, manguezal, marAbertoTemperado, marAbertoTropical (+14 more)

### Community 39 - "Growth System"
Cohesion: 0.18
Nodes (4): POISystem, Bool, Date, WorldPOI

### Community 40 - "Mermaid Figures — Child"
Cohesion: 0.24
Nodes (7): HouseMermaidAutonomyController, HouseRoomSceneID, HouseSceneMetrics, Mermaid, NSCoder, UIEdgeInsets, Void

### Community 41 - "World Chunk — Detail Rendering"
Cohesion: 0.14
Nodes (5): CheatSystem, Suggestion, Bool, ClosedRange, Set

### Community 42 - "Documentation — Design Decisions"
Cohesion: 0.18
Nodes (6): ChallengeFlowController, Bool, SKCameraNode, Void, ChallengeResult, ResourceChoiceOverlay

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
Cohesion: 0.12
Nodes (18): Bool, CGRect, NSCoder, Set, SKLabelNode, SKShapeNode, UIColor, UIEdgeInsets (+10 more)

### Community 47 - "Fish Visual Models"
Cohesion: 0.17
Nodes (7): ReefAsteroidsRules, ReefRockSize, large, medium, small, Bool, floor

### Community 48 - "Food System"
Cohesion: 0.11
Nodes (69): SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c05, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c06, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c07, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c08, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r10 c09 (+61 more)

### Community 49 - "Region Map Cues & Expedition"
Cohesion: 0.08
Nodes (26): FishBehaviorComponent, FishSpecies, Bool, NSCoder, UIColor, FoodComponent, Bool, NSCoder (+18 more)

### Community 50 - "Movement Enums & Animation Modes"
Cohesion: 0.09
Nodes (10): AnyObject, ChallengeGiver, ChallengeSystem, FishNode, Bool, NSCoder, TimeInterval, UIColor (+2 more)

### Community 51 - "Fish Drawing Factory"
Cohesion: 0.16
Nodes (4): BabyMermaidFigure, Bool, Double, MermaidFigurePart

### Community 52 - "HUD Layer"
Cohesion: 0.16
Nodes (4): ChildMermaidFigure, Bool, Double, MermaidFigurePart

### Community 53 - "Expedition Grid Math"
Cohesion: 0.17
Nodes (6): DirectionalCore, MermaidBody, MotionProfile, Bool, Double, SKSpriteNode

### Community 54 - "World Stamp Drawing"
Cohesion: 0.06
Nodes (35): Calendar, RefugeShopCatalog, RefugeShopItem, RefugeShopPurchase, houseObject, resource, RefugeStoreOverlay, SupportResourceKind (+27 more)

### Community 55 - "Pearl Economy"
Cohesion: 0.12
Nodes (18): MermaidEmotion, adventurous, curious, eating, focused, happy, hungry, neutral (+10 more)

### Community 56 - "HUD — Biology Meter & Commands"
Cohesion: 0.09
Nodes (26): FaceTextureCache, MermaidExpressionLibrary, MermaidExpressionPreset, MermaidEyeAsset, closed, half, open, wide (+18 more)

### Community 57 - "Buff Coding Keys"
Cohesion: 0.10
Nodes (16): PlayerCommand, challenge, explore, goDown, goLeft, goRight, goUp, objective (+8 more)

### Community 58 - "Mermaid Name Editor"
Cohesion: 0.11
Nodes (16): UInt64, PlacedReefCluster, ReefCluster, Bool, CGRect, CGRect, WorldChunkCoord, WorldLayerSeed (+8 more)

### Community 59 - "Discovery & Depth Ranges"
Cohesion: 0.36
Nodes (4): MermaidFigurePart, Set, UIEvent, UITouch

### Community 60 - "Depth Zone Colors"
Cohesion: 0.08
Nodes (25): App, AppKit, AutotileSummary, ContentView, DepthRow, EditorToolbar, GridLines, MapCanvasView (+17 more)

### Community 61 - "Mermaid Emotion Component"
Cohesion: 0.21
Nodes (7): FoodKind, FoodNode, FoodSystem, Bool, NSCoder, SKTexture, UIColor

### Community 62 - "Command & Touch System"
Cohesion: 0.08
Nodes (13): CoreGraphics, ExpressionComponent, NSCoder, HealthComponent, NSCoder, IntentComponent, NSCoder, WorldPOIArtworkSize (+5 more)

### Community 63 - "Mermaid Rig Debug Tool"
Cohesion: 0.13
Nodes (14): AdultMermaidRig, MermaidFigurePart, MermaidRigPosition, BabyMermaidRig, MermaidFigurePart, MermaidRigPosition, ChildMermaidRig, MermaidFigurePart (+6 more)

### Community 64 - "Mermaid Core Entity"
Cohesion: 0.13
Nodes (9): SKAction, MermaidArms, Rotation, down, up, SKSpriteNode, MermaidHead, MovementDirectionProtocol (+1 more)

### Community 65 - "Game Sound Enum Values"
Cohesion: 0.10
Nodes (21): DepthZone, abyss, blue, clear, deep, mid, shallow, surface (+13 more)

### Community 66 - "Encoding Utilities"
Cohesion: 0.16
Nodes (11): A, B, C, EntityManager, GKComponent, GKEntity, ObjectIdentifier, Set (+3 more)

### Community 68 - "Mermaid Intent & Acceptance"
Cohesion: 0.10
Nodes (20): FishCompanionAction, guide, MermaidIntent, avoidingDanger, eating, enteringRefuge, followingFish, goingDeeper (+12 more)

### Community 69 - "Autotile Set Hashing"
Cohesion: 0.26
Nodes (5): HUDPalette, SKShapeNode, SKSpriteNode, UIBezierPath, UIColor

### Community 70 - "Mermaid Rig Models"
Cohesion: 0.21
Nodes (8): MermaidRigDebugTool, PreviewFit, Bool, MermaidFigurePart, NSCoder, SKLabelNode, UIEdgeInsets, Void

### Community 71 - "HUD — Active Effects Shelf"
Cohesion: 0.46
Nodes (3): ObjectIdentifier, Set, UITouch

### Community 72 - "Aquatic Biomes"
Cohesion: 0.18
Nodes (4): BanquetEngine, BanquetPlayer, Bool, CGRect

### Community 73 - "Mermaid Figure Part Positioning"
Cohesion: 0.07
Nodes (21): Reward, RewardKind, item, pearls, regionMap, story, supportResource, temporaryEffect (+13 more)

### Community 74 - "Map Editor — SwiftUI Content View"
Cohesion: 0.32
Nodes (3): AdultMermaidFigure, MermaidFigurePart, Bool

### Community 75 - "Map Editor — Depth Save"
Cohesion: 0.11
Nodes (18): Chegada em Mapa Novo, Conchas (Moeda), Coragem, Decisões Abertas, Desbloqueio Global vs Por Mapa, Energia e Exploração, Estrutura de Cada Mapa, Fases da Sereia (+10 more)

### Community 76 - "Event Bus"
Cohesion: 0.29
Nodes (6): FishSwimPattern, flee, guide, school, wander, GKEntity

### Community 77 - "Mermaid Body Dimensions"
Cohesion: 0.12
Nodes (16): MermaidFigurePart, chest, eyebrowLeft, eyebrowRight, eyeLeft, eyeRight, hairBack, hairFront (+8 more)

### Community 78 - "Map Editor Models"
Cohesion: 0.11
Nodes (18): Anatomia De Um Bom Movel, Checklist Antes De Gerar, Como Traduzir Tema De Sereia Para Moveis, Composicao, Funcao Antes Do Ornamento, Fundo Transparente, FURNITURE_ART_GUIDE, Integracao No Jogo (+10 more)

### Community 79 - "Refuge Entry & Energy"
Cohesion: 0.23
Nodes (5): SeededGenerator, Bool, ClosedRange, RandomNumberGenerator, UInt64

### Community 80 - "Ester Game"
Cohesion: 0.18
Nodes (13): ChallengeCompletedEvent, EventBus, FoodCollectedEvent, GameEvent, MermaidStateChangedEvent, RegionDiscoveredEvent, Any, GKEntity (+5 more)

### Community 81 - "Ester Game"
Cohesion: 0.27
Nodes (6): SKSpriteNode, WorldChunkFactory, NSCache, NSString, SKTexture, WorldTextureCache

### Community 82 - "Components"
Cohesion: 0.10
Nodes (18): ChallengeGiverComponent, Bool, NSCoder, ChallengeGoalRange, CodingKeys, buffKind, duration, expiresAt (+10 more)

### Community 83 - "Managers"
Cohesion: 0.13
Nodes (14): CHARACTER_ART_GUIDE, Checklist Antes De Gerar, Como Usar Concept Arts, Composicao, Fundo Transparente, Integracao No Jogo, Negativos Uteis, Nivel De Detalhe (+6 more)

### Community 84 - "Ester Game"
Cohesion: 0.17
Nodes (9): Mermaid, MermaidFigure, MermaidFormKind, adult, baby, child, young, Bool (+1 more)

### Community 85 - "Components"
Cohesion: 0.14
Nodes (14): HousePhysicsCategory, HouseSurface, HouseSurfaceKind, backWall, ceiling, leftWall, rightWall, RoomSurfaceMapper (+6 more)

### Community 86 - "Components"
Cohesion: 0.14
Nodes (14): MermaidExpressionName, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 87 - "Ester Game"
Cohesion: 0.10
Nodes (19): AVAudioPCMBuffer, AVAudioPlayer, AVFoundation, AmbienceSpec, GameAmbience, abyss, clear, deep (+11 more)

### Community 88 - "Ester Game"
Cohesion: 0.23
Nodes (8): NSCoder, SKLabelNode, VisualStyle, environment, npc, object, warmCurrentEnvironment, WorldPOINode

### Community 89 - "Managers"
Cohesion: 0.21
Nodes (7): AppDelegate, Any, Bool, UIApplication, UIApplicationDelegate, UIResponder, UIWindow

### Community 90 - "Managers"
Cohesion: 0.33
Nodes (5): ReefRockMotif, algaeStone, basalt, goldenCoral, roseCoral

### Community 91 - "Managers"
Cohesion: 0.22
Nodes (7): AmbientLifeNode, Style, jelly, needleFish, ovalFish, ray, NSCoder

### Community 92 - "Appdelegate"
Cohesion: 0.07
Nodes (12): inventoryItems, regionProgress, repeatablePOIRewardAvailableAtByKey, MermaidStats, Bool, Data, Date, Decoder (+4 more)

### Community 93 - "Components"
Cohesion: 0.33
Nodes (12): connection_mask(), fail(), inner_corner_mask(), main(), png_size(), preferred_exact_candidates(), preferred_inner_candidates(), rectangle() (+4 more)

### Community 94 - "Ester Game"
Cohesion: 0.07
Nodes (16): AncientRuinsGameScene, BirthWatersGameScene, CalmGardenGameScene, CaveMouthGameScene, CrystalFieldsGameScene, DistantSurfaceGameScene, EmeraldReefGameScene, GreatDeltaGameScene (+8 more)

### Community 95 - "Ester Game"
Cohesion: 0.17
Nodes (5): BondRecoveryHUDState, available, hidden, ready, waiting

### Community 96 - "Tools Verify"
Cohesion: 0.18
Nodes (11): Conceito, Coordenadas, Descoberta, Estrutura de Dados, Eventos Aleatórios — Upgrade, Pontos de Interesse (POIs), Retorno a POIs Descobertos, Sistema de Recompensas (+3 more)

### Community 97 - "Ester Game"
Cohesion: 0.13
Nodes (7): expeditionRevealByRegion, ExpeditionMapNode, Region, RegionDiscoverySystem, NSCoder, SKShapeNode, UIColor

### Community 98 - "Ester Game"
Cohesion: 0.25
Nodes (6): Channel, caustics, fog, particles, shader, OceanVisualTuning

### Community 99 - "Ester Game"
Cohesion: 0.18
Nodes (7): FishSilhouette, diamond, moon, needle, oval, ray, turtle

### Community 100 - "Ester Game"
Cohesion: 0.20
Nodes (9): 1. Required Context, 2. Size and Proportion, 3. Asset Catalog Location, 4. Tint and Color Configuration, 5. File and Asset Names, 6. Contents.json, 7. Code Integration, 8. Final Checklist (+1 more)

### Community 101 - "Ester Game"
Cohesion: 0.10
Nodes (17): MermaidEmotionalState, MermaidMoodCue, currentLift, currentStrain, encouraged, none, MermaidMoodTone, danger (+9 more)

### Community 102 - "Managers"
Cohesion: 0.39
Nodes (4): HUDTexture, NSCache, NSString, SKTexture

### Community 103 - "Ester Game"
Cohesion: 0.13
Nodes (12): CodingKeys, scale, x, y, z, MermaidRigDocument, MermaidRigStore, Any (+4 more)

### Community 104 - "Ester Game"
Cohesion: 0.10
Nodes (21): BadgePlacement, LayoutPoint, Location, house, professor, store, RefugeDioramaController, RefugeHubLayout (+13 more)

### Community 105 - "Ester Game"
Cohesion: 0.26
Nodes (5): MermaidFigurePart, YoungMermaidFigure, MermaidFigurePart, MermaidRigPosition, YoungMermaidRig

### Community 106 - "Components"
Cohesion: 0.16
Nodes (5): ClosedRange, mapPositionByRegion, RefugeFlowController, Bool, Void

### Community 107 - "Ester Game"
Cohesion: 0.11
Nodes (19): ChallengeChoiceOverlay, ChallengeKind, ascent, banquet, echoMelody, memory, plot, reefAsteroids (+11 more)

### Community 108 - "Ester Game"
Cohesion: 0.40
Nodes (5): LabelStyle, body, bodyBold, note, noteBold

### Community 109 - "Storyboard"
Cohesion: 0.79
Nodes (8): docs → storyboard → ref teacher →   (12), docs → storyboard → ref teacher →   (13), docs → storyboard → ref teacher → adult siren, docs → storyboard → ref teacher → baby siren, docs → storyboard → ref teacher → child siren, docs → storyboard → ref teacher → Octo Sheriff, docs → storyboard → ref teacher → Postcard designs   Barbara Dziadosz, docs → storyboard → ref teacher → young siren

### Community 110 - "Components"
Cohesion: 0.15
Nodes (6): MermaidEyes, SKSpriteNode, MermaidFace, SKSpriteNode, MermaidMouth, SKSpriteNode

### Community 111 - "Ester Game"
Cohesion: 0.25
Nodes (6): Architecture And Ownership, Goal Mode Discipline, Icons And Assets, Knowledge Graph First, Project Instructions, Sound Effects

### Community 112 - "Ester Game"
Cohesion: 0.25
Nodes (8): Adaptação para Ester, Como o Terraria faz (referência), Mini-mapa de Expedição, O que aparece no mini-mapa, O que NÃO aparece, Porcentagem de descoberta, Raio de visão — decisão fechada, Regras propostas para o mini-mapa

### Community 113 - "Ester Game"
Cohesion: 0.35
Nodes (6): RegionMenuOverlay, CGRect, Set, UIEvent, UITouch, Void

### Community 114 - "ColorManager"
Cohesion: 0.29
Nodes (5): ColorManager, UIColor, MermaidEyebrows, SKSpriteNode, SKSpriteNode

### Community 115 - "Managers"
Cohesion: 0.20
Nodes (9): MovementDirection, down, left, right, up, MovementType, fast, idle (+1 more)

### Community 117 - "ChallengeGiverComponent"
Cohesion: 0.47
Nodes (3): Set, UIEvent, UITouch

### Community 118 - "Mapeditor Mapeditor"
Cohesion: 0.46
Nodes (4): RegistroFlowController, Bool, UIEdgeInsets, Void

### Community 119 - "Ester Game"
Cohesion: 0.44
Nodes (4): FloorFurnitureSpec, HouseObjectCatalog, HouseObjectDefinition, WallDecorationSpec

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
Cohesion: 0.29
Nodes (5): HouseMiniroomTheme, HouseRoomFrontFrameNode, HouseRoomNode, RoomSurfaceMapping, UIColor

### Community 124 - "Ester Game"
Cohesion: 0.29
Nodes (5): ObjectiveComponent, Bool, NSCoder, TimeInterval, Void

### Community 125 - ".touchesBegan"
Cohesion: 0.32
Nodes (7): BondRecoveryBalance, FishPlayBalance, HorizontalBoundaryBalance, PassiveBondBalance, TimeInterval, TouchDirectionBalance, TrustBalance

### Community 126 - "Ester Game"
Cohesion: 0.20
Nodes (7): TimeInterval, VisualEffect, bob, fadeIn, fadeOut, glow, pulse

### Community 127 - "Gamescene"
Cohesion: 0.29
Nodes (6): Abrir, Autotile, Dados, MapEditor, Uso, Verificacao Leve

### Community 128 - "Mapeditor Mapeditor"
Cohesion: 0.33
Nodes (6): FishMotionMode, gatheringForPlay, guiding, normal, playing, Date

### Community 129 - "SupportResourceKind"
Cohesion: 0.22
Nodes (9): HouseObjectCategory, backWallDecoration, ceilingDecoration, container, floorFurniture, functional, leftWallDecoration, rightWallDecoration (+1 more)

### Community 130 - "Agents"
Cohesion: 0.29
Nodes (3): CameraController, SKCameraNode, UIColor

### Community 131 - ".touchesBegan"
Cohesion: 0.42
Nodes (3): Set, UIEvent, UITouch

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
Cohesion: 0.33
Nodes (6): POIComponent, POIState, active, completed, dormant, interacting

### Community 190 - "FoodStyle"
Cohesion: 0.29
Nodes (7): FoodStyle, critter, crystal, fruit, glow, leaf, pearl

### Community 229 - "TileImageCache"
Cohesion: 0.43
Nodes (5): NSCache, URL, TileImageCache, NSImage, NSURL

### Community 230 - "CodingKeys"
Cohesion: 0.33
Nodes (6): CodingKeys, goal, goalMultiplier, introText, kind, special

### Community 231 - "BondRecoveryState"
Cohesion: 0.40
Nodes (5): BondRecoveryState, idle, ready, waiting, Date

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

### Community 237 - ".addCommandButton"
Cohesion: 0.14
Nodes (7): HUDLayer, NSCoder, Set, UIEdgeInsets, UIEvent, UITouch, Void

### Community 238 - "IconKind"
Cohesion: 0.50
Nodes (4): IconKind, plankton, shell, wave

### Community 239 - "TideMemoryCardState"
Cohesion: 0.50
Nodes (4): TideMemoryCardState, faceDown, faceUp, matched

### Community 240 - ".touchesEnded"
Cohesion: 0.11
Nodes (16): Comparable, ChallengeRewardProfile, ChallengeVictoryReward, none, resource, shellBonus, GameBalance, MermaidPhase (+8 more)

### Community 241 - "EditorLayer"
Cohesion: 0.50
Nodes (4): EditorLayer, decoration, spawn, terrain

### Community 243 - "Orientation"
Cohesion: 0.67
Nodes (3): Orientation, horizontal, vertical

### Community 246 - "GridLines"
Cohesion: 0.47
Nodes (4): MermaidEntity, Mermaid, NSCoder, GKEntity

### Community 247 - "Mermaid"
Cohesion: 0.20
Nodes (7): Mermaid, Direction, down, left, none, right, up

### Community 259 - "floor"
Cohesion: 0.29
Nodes (4): CGRect, Mermaid, NSCoder, Void

## Knowledge Gaps
- **767 isolated node(s):** `wander`, `school`, `flee`, `guide`, `open` (+762 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **89 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CGFloat` connect `Challenge Giver Component` to `Map Tiles — Mossy Terrain`, `Mermaid House System`, `Gameplay Models & Scene Construction`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Tide Weaving System`, `Mermaid Arms & Animation`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `Gameplay Reward Models`, `World Chunk Factory`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Cheat System`, `Fish Visual Models`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `World Stamp Drawing`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Game Sound Enum Values`, `Autonomy — Bond Recovery`, `Autotile Set Hashing`, `Mermaid Rig Models`, `Aquatic Biomes`, `Mermaid Figure Part Positioning`, `Map Editor — SwiftUI Content View`, `Refuge Entry & Energy`, `Ester Game`, `Components`, `Ester Game`, `Components`, `Ester Game`, `Managers`, `Appdelegate`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Components`, `Ester Game`, `Mapeditor Mapeditor`, `Ester Game`, `Ester Game`, `.touchesBegan`, `Ester Game`, `Agents`, `.texture`, `.addCommandButton`, `.touchesEnded`, `ChildMermaidRig`, `floor`?**
  _High betweenness centrality (0.216) - this node is a cross-community bridge._
- **Why does `String` connect `Refuge Village Controller` to `Map Tiles — Mossy Terrain`, `Mermaid House System`, `Map Tiles — Mossy Autotile`, `Gameplay Models & Scene Construction`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `Gameplay Reward Models`, `World Chunk Factory`, `Growth System`, `World Chunk — Detail Rendering`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Autonomy — Eating Behavior`, `Cheat System`, `Region Map Cues & Expedition`, `World Stamp Drawing`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Game Sound Enum Values`, `Autonomy — Bond Recovery`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `Mermaid Figure Part Positioning`, `Mermaid Body Dimensions`, `Components`, `Ester Game`, `Components`, `Components`, `Ester Game`, `Ester Game`, `Managers`, `Appdelegate`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `ColorManager`, `Ester Game`, `FoodComponent`, `Ester Game`, `SupportResourceKind`, `CodingKeys`, `.texture`, `.addCommandButton`, `.touchesEnded`, `EditorLayer`?**
  _High betweenness centrality (0.179) - this node is a cross-community bridge._
- **Why does `CGPoint` connect `Depth Environment & Ocean Parallax` to `Map Tiles — Mossy Terrain`, `Mermaid House System`, `Gameplay Models & Scene Construction`, `World Point & Rendering Primitives`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Autonomy — Fish Play & Guidance`, `Region System`, `Reef Asteroids Overlay`, `Map Tiles — JSON Manifest`, `Depth System`, `Gameplay Reward Models`, `Growth System`, `Mermaid Figures — Child`, `Documentation — Design Decisions`, `Movement Vector Utilities`, `Component Base Classes`, `Cheat System`, `Fish Visual Models`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Core Entity`, `Game Sound Enum Values`, `Encoding Utilities`, `Autonomy — Bond Recovery`, `Autotile Set Hashing`, `Mermaid Rig Models`, `HUD — Active Effects Shelf`, `Aquatic Biomes`, `Mermaid Figure Part Positioning`, `Mermaid Body Dimensions`, `Refuge Entry & Energy`, `Ester Game`, `Components`, `Components`, `Ester Game`, `Managers`, `Appdelegate`, `Ester Game`, `Managers`, `Ester Game`, `Components`, `Ester Game`, `Components`, `Ester Game`, `Mapeditor Mapeditor`, `ChallengeGiverComponent`, `Orientation`, `Ester Game`, `Ester Game`, `Mapeditor Mapeditor`, `Agents`, `.touchesBegan`, `.addCommandButton`, `.touchesEnded`, `ChildMermaidRig`, `floor`?**
  _High betweenness centrality (0.131) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `CGFloat` (e.g. with `.update()` and `.drawReefSkirt()`) actually correct?**
  _`CGFloat` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 34 inferred relationships involving `CGPoint` (e.g. with `.update()` and `.openChallengeChoiceMenu()`) actually correct?**
  _`CGPoint` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 107 inferred relationships involving `SKNode` (e.g. with `.buildPlayer()` and `.showFeedback()`) actually correct?**
  _`SKNode` has 107 INFERRED edges - model-reasoned connections that need verification._
- **Are the 9 inferred relationships involving `String` (e.g. with `.touchesBegan()` and `.touchesBegan()`) actually correct?**
  _`String` has 9 INFERRED edges - model-reasoned connections that need verification._