# Graph Report - Mermaid  (2026-07-08)

## Corpus Check
- 267 files · ~678,594 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3920 nodes · 14180 edges · 248 communities (159 shown, 89 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 1941 edges (avg confidence: 0.73)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `a05f6e96`
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
- Managers
- Managers
- Mapeditor Mapeditor
- Ester Game
- Mapeditor Mapeditor
- Ester Game
- Ester Game
- Ester Game
- Ester Game
- Entitys
- Ester Game
- Ester Game
- Ester Game
- Gamescene
- Mapeditor Mapeditor
- Mapeditor Readme
- Agents
- Ester Game
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
- Ester Game
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
- MermaidEyes
- TEMP_POI_VISUAL_TODO.md
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
- .init
- .touchesBegan
- .touchesBegan
- MermaidFacePose
- MermaidMouthAsset
- BondRecoveryHUDState
- .texture
- .addCommandButton
- RefugePortalNode
- BanquetFeedbackTone
- .paper
- ReefFeedbackEffect
- BondRecoveryState
- BanquetFeedbackEffect
- ChildMermaidRig
- Mode
- GridLines
- TideMemoryCardState
- Orientation

## God Nodes (most connected - your core abstractions)
1. `CGFloat` - 762 edges
2. `CGPoint` - 649 edges
3. `SKNode` - 472 edges
4. `String` - 352 edges
5. `CGSize` - 316 edges
6. `Int` - 289 edges
7. `DepthZone` - 168 edges
8. `GameContext` - 157 edges
9. `MermaidStats` - 135 edges
10. `GameScene` - 123 edges

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
Cohesion: 0.06
Nodes (138): SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c05, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c06, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c07, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c08, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c09, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c10 (+130 more)

### Community 1 - "Mermaid House System"
Cohesion: 0.19
Nodes (6): HouseBuildPanel, MermaidHouseSceneController, ObjectIdentifier, Set, UITouch, Void

### Community 2 - "Map Tiles — Mossy Autotile"
Cohesion: 0.09
Nodes (92): SharedGameData → Tiles → Mossy → terrain 256 → autotile preview, SharedGameData → Tiles → Mossy → terrain 256 → contact sheet, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 02 (+84 more)

### Community 3 - "Gameplay Models & Scene Construction"
Cohesion: 0.20
Nodes (10): NSCoder, UIColor, GameUI, CGRect, NSCache, NSString, SKSpriteNode, SKTexture (+2 more)

### Community 4 - "Challenge Flow Controller"
Cohesion: 0.08
Nodes (7): mapPositionByRegion, GameScene, Bool, SKCameraNode, SKView, TimeInterval, Void

### Community 5 - "World Point & Rendering Primitives"
Cohesion: 0.31
Nodes (5): SKSpriteNode, SKTexture, WaterRippleNode, Float, SKUniform

### Community 6 - "Depth Environment & Ocean Parallax"
Cohesion: 0.15
Nodes (9): AmbientLifeNode, Style, jelly, needleFish, ovalFish, ray, NSCoder, UIColor (+1 more)

### Community 7 - "Banquet of Tides Minigame"
Cohesion: 0.09
Nodes (20): BanquetEngine, BanquetEntity, BanquetFeedback, BanquetFrame, BanquetItemKind, crackedBone, moonRice, puffer (+12 more)

### Community 8 - "Event System"
Cohesion: 0.11
Nodes (8): EventSystem, UIColor, Void, WorldObjective, CGVector, GameContext, TravelSystem, ResourceSupportSystem

### Community 9 - "Species Registry & Mermaid Progression"
Cohesion: 0.10
Nodes (14): RegistroMermaidObservation, RegistroOverlay, Bool, CGRect, ClosedRange, NSCoder, Set, SKLabelNode (+6 more)

### Community 10 - "Tide Memory Minigame"
Cohesion: 0.11
Nodes (16): Bool, NSCoder, Set, SKLabelNode, SKShapeNode, UIColor, UIEvent, UITouch (+8 more)

### Community 11 - "Refuge Village Controller"
Cohesion: 0.16
Nodes (6): SKNode, CGSize, SKSpriteNode, NSCoder, RefugeArtDirection, UIColor

### Community 12 - "Shelter System"
Cohesion: 0.11
Nodes (18): BadgePlacement, LayoutPoint, Location, house, professor, store, NpcKind, itemShop (+10 more)

### Community 13 - "Bubble Climb Minigame Overlay"
Cohesion: 0.11
Nodes (12): Interaction, enterHome, enterItemShop, enterUpgradeShop, restInBedroom, returnToVillage, talkToItemShopNpc, talkToTeacherNpc (+4 more)

### Community 14 - "Shell Snap Minigame"
Cohesion: 0.09
Nodes (20): ShellSnapBoard, ShellSnapFall, ShellSnapOverlay, ShellSnapPop, ShellSnapPosition, ShellSnapRules, ShellSnapSpawn, ShellSnapTheme (+12 more)

### Community 15 - "Echo Melody Minigame"
Cohesion: 0.08
Nodes (26): EchoMelodyEngine, EchoMelodyInputResult, EchoMelodyNote, coral, kelp, moon, pearl, EchoMelodyOverlay (+18 more)

### Community 16 - "Mermaid Stats & Inventory"
Cohesion: 0.07
Nodes (12): expeditionRevealByRegion, inventoryItems, repeatablePOIRewardAvailableAtByKey, MermaidStats, Bool, Data, Date, Decoder (+4 more)

### Community 17 - "Resource Support & Shop"
Cohesion: 0.09
Nodes (24): Calendar, RefugeShopCatalog, RefugeShopItem, RefugeShopPurchase, resource, ResourceChoiceOverlay, SupportResourceKind, calmShell (+16 more)

### Community 18 - "Entity Components — Visual Effects"
Cohesion: 0.07
Nodes (22): CoreGraphics, FoodComponent, Bool, HealthComponent, NSCoder, IntentComponent, NSCoder, LifetimeComponent (+14 more)

### Community 19 - "Game Scene Entries & Birth Waters"
Cohesion: 0.09
Nodes (11): AncientRuinsGameScene, BirthWatersGameScene, CalmGardenGameScene, CaveMouthGameScene, CrystalFieldsGameScene, DistantSurfaceGameScene, EmeraldReefGameScene, GreatDeltaGameScene (+3 more)

### Community 20 - "Challenge Goals & Spawning"
Cohesion: 0.09
Nodes (12): Comparable, ChallengeRewardProfile, GameBalance, MermaidPhase, adult, baby, child, egg (+4 more)

### Community 21 - "Mermaid Stats — Balance & Buffs"
Cohesion: 0.04
Nodes (46): CodingKeys, activeBuffs, adaptationByZone, babyGuaranteedRequestsUsed, balanceVersion, birthDate, challengeHighScores, collectedPOIRewardKeys (+38 more)

### Community 22 - "Audio Manager & Sound Effects"
Cohesion: 0.04
Nodes (48): GameSound, ambientBubbleBurst, bigShadow, boatMuffled, challengeFail, challengeOpen, challengeSuccess, climbBounce (+40 more)

### Community 23 - "Bubble Climb Controls"
Cohesion: 0.07
Nodes (14): CoreMotion, BubbleClimbOverlay, ClimbBubble, ClimbVisual, Bool, Mermaid, NSCoder, Set (+6 more)

### Community 24 - "Tide Weaving System"
Cohesion: 0.09
Nodes (18): GridPos, Bool, NSCoder, Set, SKLabelNode, SKShapeNode, UIColor, UIEvent (+10 more)

### Community 25 - "World Stamp Rendering"
Cohesion: 0.17
Nodes (15): ClosedRange, CGContext, CGRect, UIBezierPath, UIColor, WorldStampRenderer, CGContext, CGContext (+7 more)

### Community 26 - "Mermaid Arms & Animation"
Cohesion: 0.26
Nodes (6): SKAction, MermaidArms, Rotation, down, up, SKSpriteNode

### Community 27 - "Challenge Giver Component"
Cohesion: 0.60
Nodes (3): Set, UIEvent, UITouch

### Community 28 - "Autonomy — Fish Play & Guidance"
Cohesion: 0.12
Nodes (6): FishNode, Bool, TimeInterval, UIColor, FishSystem, Bool

### Community 29 - "Mermaid Figures — Baby"
Cohesion: 0.16
Nodes (4): BabyMermaidFigure, Bool, Double, MermaidFigurePart

### Community 30 - "Reef Asteroids Minigame Engine"
Cohesion: 0.09
Nodes (22): ReefAsteroidsEngine, ReefAsteroidsRules, ReefFeedback, ReefFrame, ReefPlayer, ReefProjectile, ReefRock, ReefRockMotif (+14 more)

### Community 31 - "Region System"
Cohesion: 0.18
Nodes (4): POISystem, Bool, Date, WorldPOI

### Community 32 - "Reef Asteroids Overlay"
Cohesion: 0.13
Nodes (7): ReefAsteroidsOverlay, Mermaid, NSCoder, SKLabelNode, SKShapeNode, UIColor, Void

### Community 33 - "Map Tiles — JSON Manifest"
Cohesion: 0.05
Nodes (37): columns, connectionMaskCounts, 0, 1, 10, 11, 12, 13 (+29 more)

### Community 34 - "Depth System"
Cohesion: 0.11
Nodes (16): Equatable, BoundaryPaletteEffect, DepthBoundaryEdge, lower, upper, DepthEnvironment, DepthSystem, MermaidPaletteTransition (+8 more)

### Community 35 - "Gameplay Reward Models"
Cohesion: 0.14
Nodes (11): Encoder, Date, Decoder, TimedBuff, TimedBuffKind, eagerCompanion, fishGuide, fishPlay (+3 more)

### Community 36 - "Ecosystem Biome Catalog"
Cohesion: 0.18
Nodes (11): Array, EcosystemBiomeCatalog, EcosystemBiomeProfile, EcosystemVegetationRule, EcosystemVegetationSlot, detail, plant, EcosystemZoneConfig (+3 more)

### Community 37 - "POI System"
Cohesion: 0.16
Nodes (9): ChallengeFlowController, Bool, SKCameraNode, Void, ChallengeChoiceOverlay, ChallengeRecordSnapshot, ChallengeResult, POIChallengeOfferOverlay (+1 more)

### Community 38 - "World Chunk Factory"
Cohesion: 0.11
Nodes (17): WorldStampKind, coralBranch, coralFan, coralTube, crystalCluster, currentRibbon, kelpBlade, kelpBush (+9 more)

### Community 39 - "Growth System"
Cohesion: 0.15
Nodes (6): GrowthSystem, Requirement, Bool, Double, SKShapeNode, TimeInterval

### Community 40 - "Mermaid Figures — Child"
Cohesion: 0.16
Nodes (4): ChildMermaidFigure, Bool, Double, MermaidFigurePart

### Community 41 - "World Chunk — Detail Rendering"
Cohesion: 0.21
Nodes (8): PlacedReefCluster, ReefCluster, CGRect, SKSpriteNode, WorldChunkFactory, SeededGenerator, Bool, RandomNumberGenerator

### Community 42 - "Documentation — Design Decisions"
Cohesion: 0.29
Nodes (6): Adding A New Resource, Concept, Current Resources, Refuge Shop, Resource Flow, Resource Support System

### Community 43 - "Movement Vector Utilities"
Cohesion: 0.13
Nodes (10): BanquetOfTidesOverlay, Bool, CGRect, Mermaid, NSCoder, SKLabelNode, SKShapeNode, UIColor (+2 more)

### Community 44 - "Component Base Classes"
Cohesion: 0.14
Nodes (7): WorldPOIArtworkSize, challenge, listSmall, mapSmall, world, OceanPalette, GameplayKit

### Community 45 - "Autonomy — Eating Behavior"
Cohesion: 0.09
Nodes (6): AutonomySystem, HorizontalBoundarySide, left, right, ClosedRange, Mermaid

### Community 46 - "Cheat System"
Cohesion: 0.14
Nodes (5): CheatSystem, Suggestion, Bool, ClosedRange, Set

### Community 47 - "Fish Visual Models"
Cohesion: 0.05
Nodes (50): CGLineCap, FishDrawingFactory, Bool, SKShapeNode, UIBezierPath, UIColor, NSCoder, FishPattern (+42 more)

### Community 48 - "Food System"
Cohesion: 0.18
Nodes (8): NSCoder, FoodKind, FoodNode, FoodSystem, Bool, NSCoder, SKTexture, UIColor

### Community 49 - "Region Map Cues & Expedition"
Cohesion: 0.18
Nodes (5): ClosedRange, discoveryPointByRegion, OfflineProgressSystem, Region, RegionDiscoverySystem

### Community 50 - "Movement Enums & Animation Modes"
Cohesion: 0.15
Nodes (6): DirectionalCore, MermaidBody, MotionProfile, Bool, Double, SKSpriteNode

### Community 51 - "Fish Drawing Factory"
Cohesion: 0.18
Nodes (14): Codable, BuildRejection, leftOfEntrance, notAdjacent, occupied, HouseGridPosition, HouseLayoutData, HouseMVPPolicy (+6 more)

### Community 52 - "HUD Layer"
Cohesion: 0.17
Nodes (6): HUDLayer, Set, TimeInterval, UIEvent, UITouch, Void

### Community 53 - "Expedition Grid Math"
Cohesion: 0.15
Nodes (11): ExpeditionMapNode, RegionMenuOverlay, CGRect, NSCoder, Set, SKShapeNode, UIColor, UIEvent (+3 more)

### Community 54 - "World Stamp Drawing"
Cohesion: 0.10
Nodes (11): CGFloat, InteractionBalance, TimeInterval, Channel, caustics, fog, particles, shader (+3 more)

### Community 55 - "Pearl Economy"
Cohesion: 0.23
Nodes (7): ChallengeChrome, Bool, SKLabelNode, ChallengeVictoryReward, none, resource, shellBonus

### Community 56 - "HUD — Biology Meter & Commands"
Cohesion: 0.20
Nodes (9): CGPath, HouseBuildSlotNode, HouseRoomFrontFrameNode, Kind, blocked, valid, SKLabelNode, SKShapeNode (+1 more)

### Community 57 - "Buff Coding Keys"
Cohesion: 0.15
Nodes (13): CodingKeys, buffKind, duration, expiresAt, itemId, kind, pearlAmount, quantity (+5 more)

### Community 58 - "Mermaid Name Editor"
Cohesion: 0.12
Nodes (10): MermaidNameEditorViewController, IndexPath, Notification, NSLayoutConstraint, UITableView, UITableViewCell, UITableViewDataSource, UITableViewDelegate (+2 more)

### Community 59 - "Discovery & Depth Ranges"
Cohesion: 0.08
Nodes (20): MermaidEmotionalState, MermaidMoodCue, currentLift, currentStrain, encouraged, none, MermaidMoodTone, danger (+12 more)

### Community 60 - "Depth Zone Colors"
Cohesion: 0.17
Nodes (11): DepthZone, abyss, blue, clear, deep, mid, shallow, surface (+3 more)

### Community 61 - "Mermaid Emotion Component"
Cohesion: 0.24
Nodes (8): MermaidExpressionLibrary, MermaidExpressionPreset, MermaidEyeAsset, closed, half, open, wide, MermaidEyebrowExpression

### Community 62 - "Command & Touch System"
Cohesion: 0.15
Nodes (11): RefugeStoreOverlay, RefugeEnhancementsOverlay, RefugeHouseInteriorController, RefugeOverlay, NSCoder, Set, SKLabelNode, UIEdgeInsets (+3 more)

### Community 63 - "Mermaid Rig Debug Tool"
Cohesion: 0.20
Nodes (8): MermaidRigDebugTool, PreviewFit, Bool, MermaidFigurePart, NSCoder, SKLabelNode, UIEdgeInsets, Void

### Community 64 - "Mermaid Core Entity"
Cohesion: 0.14
Nodes (14): Direction, down, left, none, right, up, Mermaid, MermaidFigure (+6 more)

### Community 65 - "Game Sound Enum Values"
Cohesion: 0.16
Nodes (11): A, B, C, EntityManager, GKComponent, GKEntity, ObjectIdentifier, Set (+3 more)

### Community 66 - "Encoding Utilities"
Cohesion: 0.14
Nodes (14): HouseRoomNode, HousePhysicsCategory, HouseSurface, HouseSurfaceKind, backWall, ceiling, leftWall, rightWall (+6 more)

### Community 67 - "Autonomy — Bond Recovery"
Cohesion: 0.32
Nodes (7): BondRecoveryBalance, FishPlayBalance, HorizontalBoundaryBalance, PassiveBondBalance, TimeInterval, TouchDirectionBalance, TrustBalance

### Community 68 - "Mermaid Intent & Acceptance"
Cohesion: 0.10
Nodes (20): FishCompanionAction, guide, MermaidIntent, avoidingDanger, eating, enteringRefuge, followingFish, goingDeeper (+12 more)

### Community 69 - "Autotile Set Hashing"
Cohesion: 0.15
Nodes (10): Int, TimeInterval, TideMemoryRules, TideMemoryTimeRecovery, Hasher, AutotileSet, Bool, Set (+2 more)

### Community 70 - "Mermaid Rig Models"
Cohesion: 0.20
Nodes (7): MermaidRigDocument, MermaidRigStore, Any, Data, MermaidFigurePart, MermaidRigPosition, URL

### Community 71 - "HUD — Active Effects Shelf"
Cohesion: 0.40
Nodes (5): LabelStyle, body, bodyBold, note, noteBold

### Community 72 - "Aquatic Biomes"
Cohesion: 0.09
Nodes (21): AquaticBiome, abyssPlain, ancientRuins, cavernMouth, coralGarden, crystalField, deepVents, kelpForest (+13 more)

### Community 73 - "Mermaid Figure Part Positioning"
Cohesion: 0.12
Nodes (16): MermaidFigurePart, chest, eyebrowLeft, eyebrowRight, eyeLeft, eyeRight, hairBack, hairFront (+8 more)

### Community 74 - "Map Editor — SwiftUI Content View"
Cohesion: 0.12
Nodes (17): AppKit, AutotileSummary, ContentView, DepthRow, EditorToolbar, MapCanvasView, PathSummary, Bool (+9 more)

### Community 75 - "Map Editor — Depth Save"
Cohesion: 0.12
Nodes (18): App, Decodable, Color, DepthDefinition, EditorDataLocation, EditorLayer, decoration, spawn (+10 more)

### Community 76 - "Event Bus"
Cohesion: 0.18
Nodes (13): ChallengeCompletedEvent, EventBus, FoodCollectedEvent, GameEvent, MermaidStateChangedEvent, RegionDiscoveredEvent, Any, GKEntity (+5 more)

### Community 77 - "Mermaid Body Dimensions"
Cohesion: 0.11
Nodes (18): Chegada em Mapa Novo, Conchas (Moeda), Coragem, Decisões Abertas, Desbloqueio Global vs Por Mapa, Energia e Exploração, Estrutura de Cada Mapa, Fases da Sereia (+10 more)

### Community 78 - "Map Editor Models"
Cohesion: 0.13
Nodes (14): CHARACTER_ART_GUIDE, Checklist Antes De Gerar, Como Usar Concept Arts, Composicao, Fundo Transparente, Integracao No Jogo, Negativos Uteis, Nivel De Detalhe (+6 more)

### Community 80 - "Ester Game"
Cohesion: 0.36
Nodes (3): RefugeFlowController, Bool, Void

### Community 81 - "Ester Game"
Cohesion: 0.07
Nodes (9): CoreText, World, Mermaid, UIColor, WorldStampRenderer, WorldStampRenderer, Foundation, SpriteKit (+1 more)

### Community 82 - "Components"
Cohesion: 0.13
Nodes (14): MermaidEmotion, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 83 - "Managers"
Cohesion: 0.13
Nodes (5): MermaidFace, MermaidHead, SKSpriteNode, MovementDirectionProtocol, MovementTypeProtocol

### Community 84 - "Ester Game"
Cohesion: 0.11
Nodes (17): AnyObject, ChallengeGiverComponent, Bool, NSCoder, ChallengeGiver, ChallengeKind, ascent, banquet (+9 more)

### Community 85 - "Components"
Cohesion: 0.31
Nodes (4): MermaidEmotionComponent, Bool, Mermaid, NSCoder

### Community 86 - "Components"
Cohesion: 0.14
Nodes (14): MermaidExpressionName, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 87 - "Ester Game"
Cohesion: 0.13
Nodes (14): AquaticAnimalGroup, annelid, arthropod, bird, cephalopod, cnidarian, crustacean, echinoderm (+6 more)

### Community 88 - "Ester Game"
Cohesion: 0.07
Nodes (24): Reward, RewardKind, item, pearls, regionMap, story, supportResource, temporaryEffect (+16 more)

### Community 89 - "Managers"
Cohesion: 0.16
Nodes (9): ColorManager, UIColor, MermaidEyebrows, SKSpriteNode, MermaidEyes, SKSpriteNode, SKSpriteNode, MermaidMouth (+1 more)

### Community 90 - "Managers"
Cohesion: 0.11
Nodes (20): POIDefinition, POIVisual, RepeatablePOIReward, StableRNG, ClosedRange, UInt64, WorldPOIActionKind, challenge (+12 more)

### Community 91 - "Managers"
Cohesion: 0.10
Nodes (18): AVAudioPCMBuffer, AVAudioPlayer, AVFoundation, AmbienceSpec, GameAmbience, abyss, clear, deep (+10 more)

### Community 92 - "Appdelegate"
Cohesion: 0.21
Nodes (7): AppDelegate, Any, Bool, UIApplication, UIApplicationDelegate, UIResponder, UIWindow

### Community 93 - "Components"
Cohesion: 0.14
Nodes (13): FishBehaviorComponent, FishSpecies, FishSwimPattern, flee, guide, school, wander, Bool (+5 more)

### Community 94 - "Ester Game"
Cohesion: 0.17
Nodes (12): CodingKey, CodingKeys, scale, x, y, z, CodingKeys, goal (+4 more)

### Community 95 - "Ester Game"
Cohesion: 0.21
Nodes (6): AdultMermaidFigure, MermaidFigurePart, AdultMermaidRig, MermaidFigurePart, MermaidRigPosition, Bool

### Community 96 - "Tools Verify"
Cohesion: 0.33
Nodes (12): connection_mask(), fail(), inner_corner_mask(), main(), png_size(), preferred_exact_candidates(), preferred_inner_candidates(), rectangle() (+4 more)

### Community 97 - "Ester Game"
Cohesion: 0.17
Nodes (12): EcosystemVegetationCategory, algae, chemosyntheticMat, coral, iceAlgae, kelp, macrophyte, mangroveRoot (+4 more)

### Community 98 - "Ester Game"
Cohesion: 0.11
Nodes (17): CaseIterable, EcosystemBiomeID, estuario, florestaKelp, manguezal, marAbertoTemperado, marAbertoTropical, oceanoProfundo (+9 more)

### Community 99 - "Ester Game"
Cohesion: 0.26
Nodes (5): MermaidFigurePart, YoungMermaidFigure, MermaidFigurePart, MermaidRigPosition, YoungMermaidRig

### Community 100 - "Ester Game"
Cohesion: 0.29
Nodes (3): CameraController, SKCameraNode, UIColor

### Community 101 - "Ester Game"
Cohesion: 0.18
Nodes (11): Conceito, Coordenadas, Descoberta, Estrutura de Dados, Eventos Aleatórios — Upgrade, Pontos de Interesse (POIs), Retorno a POIs Descobertos, Sistema de Recompensas (+3 more)

### Community 104 - "Ester Game"
Cohesion: 0.22
Nodes (7): MermaidRigAxis, scale, x, y, z, MermaidRigTransform, Decoder

### Community 105 - "Ester Game"
Cohesion: 0.24
Nodes (8): TimeInterval, VisualEffect, bob, fadeIn, fadeOut, glow, pulse, VisualEffectComponent

### Community 106 - "Components"
Cohesion: 0.22
Nodes (7): POIComponent, POIState, active, completed, dormant, interacting, NSCoder

### Community 107 - "Ester Game"
Cohesion: 0.20
Nodes (9): MovementDirection, down, left, right, up, MovementType, fast, idle (+1 more)

### Community 108 - "Ester Game"
Cohesion: 0.39
Nodes (4): RegistroFlowController, Bool, UIEdgeInsets, Void

### Community 109 - "Storyboard"
Cohesion: 0.79
Nodes (8): docs → storyboard → ref teacher →   (12), docs → storyboard → ref teacher →   (13), docs → storyboard → ref teacher → adult siren, docs → storyboard → ref teacher → baby siren, docs → storyboard → ref teacher → child siren, docs → storyboard → ref teacher → Octo Sheriff, docs → storyboard → ref teacher → Postcard designs   Barbara Dziadosz, docs → storyboard → ref teacher → young siren

### Community 110 - "Components"
Cohesion: 0.32
Nodes (6): FaceTextureCache, SKSpriteNode, SKTexture, NSCache, NSString, SKTexture

### Community 111 - "Ester Game"
Cohesion: 0.25
Nodes (6): Architecture And Ownership, Goal Mode Discipline, Icons And Assets, Knowledge Graph First, Project Instructions, Sound Effects

### Community 112 - "Ester Game"
Cohesion: 0.39
Nodes (5): MermaidTemplateTexture, NSCache, NSString, SKTexture, UIColor

### Community 113 - "Ester Game"
Cohesion: 0.25
Nodes (8): Adaptação para Ester, Como o Terraria faz (referência), Mini-mapa de Expedição, O que aparece no mini-mapa, O que NÃO aparece, Porcentagem de descoberta, Raio de visão — decisão fechada, Regras propostas para o mini-mapa

### Community 114 - "Managers"
Cohesion: 0.35
Nodes (3): HUDPalette, SKShapeNode, UIColor

### Community 115 - "Managers"
Cohesion: 0.47
Nodes (3): Set, UIEvent, UITouch

### Community 116 - "Mapeditor Mapeditor"
Cohesion: 0.29
Nodes (5): Balanceamento de Minigames, Criterio de Dificuldade, Formula, Perfis Atuais, Regra de Ajuste

### Community 117 - "Ester Game"
Cohesion: 0.15
Nodes (13): PlayerCommand, challenge, explore, goDown, goLeft, goRight, goUp, objective (+5 more)

### Community 118 - "Mapeditor Mapeditor"
Cohesion: 0.43
Nodes (5): NSCache, URL, TileImageCache, NSImage, NSURL

### Community 119 - "Ester Game"
Cohesion: 0.33
Nodes (6): FishMotionMode, gatheringForPlay, guiding, normal, playing, Date

### Community 120 - "Ester Game"
Cohesion: 0.60
Nodes (3): BabyMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 121 - "Ester Game"
Cohesion: 0.29
Nodes (5): ObjectiveComponent, Bool, NSCoder, TimeInterval, Void

### Community 122 - "Ester Game"
Cohesion: 0.29
Nodes (7): FoodStyle, critter, crystal, fruit, glow, leaf, pearl

### Community 123 - "Entitys"
Cohesion: 0.24
Nodes (6): ExpressionComponent, NSCoder, MermaidEntity, Mermaid, NSCoder, GKEntity

### Community 124 - "Ester Game"
Cohesion: 0.15
Nodes (9): MapSceneFactory, RefugeScene, SKView, TimeInterval, GameViewController, Bool, SKScene, UIInterfaceOrientationMask (+1 more)

### Community 126 - "Ester Game"
Cohesion: 0.29
Nodes (6): Abrir, Autotile, Dados, MapEditor, Uso, Verificacao Leve

### Community 127 - "Gamescene"
Cohesion: 0.40
Nodes (5): Floresta de Kelp × Média, Floresta de Kelp × Rasa, POIs da Fase Bebê, Recife Tropical × Média, Recife Tropical × Rasa

### Community 128 - "Mapeditor Mapeditor"
Cohesion: 0.40
Nodes (4): Assets, Ester Audio Asset Report, Missing Download Commands, Summary

### Community 129 - "Mapeditor Readme"
Cohesion: 0.50
Nodes (3): SharedGameData, Tilesets, Verificacao

### Community 130 - "Agents"
Cohesion: 0.20
Nodes (9): 1. Required Context, 2. Size and Proportion, 3. Asset Catalog Location, 4. Tint and Color Configuration, 5. File and Asset Names, 6. Contents.json, 7. Code Integration, 8. Final Checklist (+1 more)

### Community 131 - "Ester Game"
Cohesion: 0.40
Nodes (4): Complete Event Mapping, Design Direction, Ester Sound Effect Map, Intentionally Silent

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
Cohesion: 0.50
Nodes (4): Arquitetura — GameScene por mapa, Como um novo mapa é descoberto, Desbloqueio de Novos Mapas, Fluxo de desbloqueio

### Community 144 - "Ester Game"
Cohesion: 0.22
Nodes (5): IconKind, plankton, shell, wave, SKSpriteNode

### Community 145 - "Agents"
Cohesion: 0.40
Nodes (3): Set, UIEvent, UITouch

### Community 189 - "MermaidEyes"
Cohesion: 0.24
Nodes (8): NSCoder, SKLabelNode, VisualStyle, environment, npc, object, warmCurrentEnvironment, WorldPOINode

### Community 229 - ".init"
Cohesion: 0.38
Nodes (3): HouseGridMetrics, NSCoder, UIEdgeInsets

### Community 230 - ".touchesBegan"
Cohesion: 0.30
Nodes (3): Set, UIEvent, UITouch

### Community 231 - ".touchesBegan"
Cohesion: 0.36
Nodes (4): MermaidFigurePart, Set, UIEvent, UITouch

### Community 232 - "MermaidFacePose"
Cohesion: 0.28
Nodes (4): MermaidFacePose, Bool, Bool, Bool

### Community 233 - "MermaidMouthAsset"
Cohesion: 0.22
Nodes (9): MermaidMouthAsset, chew, frown, neutral, o, open, pout, sleepy (+1 more)

### Community 234 - "BondRecoveryHUDState"
Cohesion: 0.22
Nodes (6): BondRecoveryHUDState, available, hidden, ready, waiting, UIBezierPath

### Community 235 - ".texture"
Cohesion: 0.33
Nodes (6): SKTexture, NSCache, NSString, SKTexture, WorldTextureCache, WorldTextureKey

### Community 237 - "RefugePortalNode"
Cohesion: 0.46
Nodes (3): RefugePortalNode, SKTexture, SKEmitterNode

### Community 238 - "BanquetFeedbackTone"
Cohesion: 0.29
Nodes (7): BanquetFeedbackTone, bump, danger, fresh, goal, growth, rotten

### Community 239 - ".paper"
Cohesion: 0.48
Nodes (4): HUDTexture, NSCache, NSString, SKTexture

### Community 240 - "ReefFeedbackEffect"
Cohesion: 0.29
Nodes (7): ReefFeedbackEffect, combo, crack, hit, score, surge, wave

### Community 241 - "BondRecoveryState"
Cohesion: 0.40
Nodes (5): BondRecoveryState, idle, ready, waiting, Date

### Community 242 - "BanquetFeedbackEffect"
Cohesion: 0.40
Nodes (5): BanquetFeedbackEffect, huge, pop, shake, spray

### Community 243 - "ChildMermaidRig"
Cohesion: 0.60
Nodes (3): ChildMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 244 - "Mode"
Cohesion: 0.40
Nodes (5): Mode, house, map, professor, store

### Community 245 - "GridLines"
Cohesion: 0.40
Nodes (4): GridLines, CGRect, Path, Shape

### Community 246 - "TideMemoryCardState"
Cohesion: 0.50
Nodes (4): TideMemoryCardState, faceDown, faceUp, matched

### Community 247 - "Orientation"
Cohesion: 0.67
Nodes (3): Orientation, horizontal, vertical

## Knowledge Gaps
- **729 isolated node(s):** `wander`, `school`, `flee`, `guide`, `open` (+724 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **89 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CGFloat` connect `World Stamp Drawing` to `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Challenge Goals & Spawning`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Depth System`, `Gameplay Reward Models`, `Ecosystem Biome Catalog`, `POI System`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Movement Vector Utilities`, `Component Base Classes`, `Autonomy — Eating Behavior`, `Cheat System`, `Fish Visual Models`, `Food System`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `HUD Layer`, `Expedition Grid Math`, `Pearl Economy`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Encoding Utilities`, `Autonomy — Bond Recovery`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `Map Editor — SwiftUI Content View`, `Refuge Entry & Energy`, `Ester Game`, `Components`, `Managers`, `Ester Game`, `Components`, `Ester Game`, `Managers`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Entitys`, `Ester Game`, `Ester Game`, `Ester Game`, `MermaidEyes`, `.init`, `MermaidFacePose`, `BondRecoveryHUDState`, `.addCommandButton`, `RefugePortalNode`, `.paper`, `ChildMermaidRig`, `GridLines`?**
  _High betweenness centrality (0.224) - this node is a cross-community bridge._
- **Why does `String` connect `Ester Game` to `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Bubble Climb Controls`, `Tide Weaving System`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Depth System`, `Gameplay Reward Models`, `Ecosystem Biome Catalog`, `POI System`, `Growth System`, `Movement Vector Utilities`, `Cheat System`, `Fish Visual Models`, `Food System`, `Region Map Cues & Expedition`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `World Stamp Drawing`, `Pearl Economy`, `Buff Coding Keys`, `Mermaid Name Editor`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Encoding Utilities`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `Mermaid Figure Part Positioning`, `Map Editor — SwiftUI Content View`, `Map Editor — Depth Save`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Managers`, `Managers`, `Managers`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Components`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `MermaidEyes`, `.touchesBegan`, `MermaidMouthAsset`, `.texture`, `.paper`?**
  _High betweenness centrality (0.161) - this node is a cross-community bridge._
- **Why does `CGPoint` connect `Fish Visual Models` to `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Challenge Goals & Spawning`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Gameplay Reward Models`, `POI System`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Movement Vector Utilities`, `Autonomy — Eating Behavior`, `Food System`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `HUD Layer`, `Expedition Grid Math`, `World Stamp Drawing`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Game Sound Enum Values`, `Encoding Utilities`, `Autotile Set Hashing`, `Aquatic Biomes`, `Mermaid Figure Part Positioning`, `Refuge Entry & Energy`, `Ester Game`, `Managers`, `Ester Game`, `Managers`, `Components`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Managers`, `Ester Game`, `Ester Game`, `Ester Game`, `Agents`, `MermaidEyes`, `.init`, `.touchesBegan`, `MermaidFacePose`, `BondRecoveryHUDState`, `.texture`, `.addCommandButton`, `.paper`, `GridLines`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `CGFloat` (e.g. with `.update()` and `.drawReefSkirt()`) actually correct?**
  _`CGFloat` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 36 inferred relationships involving `CGPoint` (e.g. with `.update()` and `.openChallengeChoiceMenu()`) actually correct?**
  _`CGPoint` has 36 INFERRED edges - model-reasoned connections that need verification._
- **Are the 99 inferred relationships involving `SKNode` (e.g. with `.buildPlayer()` and `.showFeedback()`) actually correct?**
  _`SKNode` has 99 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `String` (e.g. with `.touchesBegan()` and `.touchesBegan()`) actually correct?**
  _`String` has 8 INFERRED edges - model-reasoned connections that need verification._