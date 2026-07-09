# Graph Report - .  (2026-07-08)

## Corpus Check
- Large corpus: 628 files · ~677,141 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 3782 nodes · 14037 edges · 189 communities (134 shown, 55 thin omitted)
- Extraction: 86% EXTRACTED · 14% INFERRED · 0% AMBIGUOUS · INFERRED: 1939 edges (avg confidence: 0.73)
- Token cost: 0 input · 0 output

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

## God Nodes (most connected - your core abstractions)
1. `CGFloat` - 761 edges
2. `CGPoint` - 646 edges
3. `SKNode` - 469 edges
4. `String` - 350 edges
5. `CGSize` - 312 edges
6. `Int` - 289 edges
7. `DepthZone` - 168 edges
8. `GameContext` - 157 edges
9. `MermaidStats` - 135 edges
10. `GameScene` - 123 edges

## Surprising Connections (you probably didn't know these)
- `GameScene Orchestration Shell Principle` --semantically_similar_to--> `Map Travel System`  [INFERRED] [semantically similar]
  AGENTS.md → docs/REGRAS_MUNDO.md
- `Depth Layer System (7 Layers)` --semantically_similar_to--> `Ambient Audio Depth Layers`  [INFERRED] [semantically similar]
  docs/REGRAS_MUNDO.md → Ester/Audio/SOUND_MAP.md
- `GridLines` --references--> `CGFloat`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/GameplayModels.swift
- `TileImageView` --references--> `CGFloat`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/GameplayModels.swift
- `EditorToolbar` --references--> `String`  [EXTRACTED]
  MapEditor/MapEditor/ContentView.swift → Ester/Game/MermaidFigures/MermaidRigDebugTool.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Core World Progression System** — docs_regras_mundo_world_model, docs_regras_mundo_siren_phases, docs_regras_mundo_map_access_rules, docs_regras_mundo_depth_system [EXTRACTED 1.00]
- **Resource Support Delivery Flow** — docs_resource_support_system, refuge_shop, docs_resource_support_system_resource_types, resourcesupportsystem, gamesscene_swift [EXTRACTED 1.00]
- **Minigame-to-Conchas Economy Pipeline** — docs_balanceamento_minigames_economy_formula, docs_balanceamento_minigames_difficulty_criteria, docs_balanceamento_minigames_minigame_profiles, docs_regras_mundo_conchas_economy, gamebalance [INFERRED 0.85]

## Communities (189 total, 55 thin omitted)

### Community 0 - "Map Tiles — Mossy Terrain"
Cohesion: 0.06
Nodes (130): SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c11, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c12, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c13, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r05 c14, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r06 c01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r06 c02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r06 c03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain r06 c04 (+122 more)

### Community 1 - "Mermaid House System"
Cohesion: 0.06
Nodes (37): CGPath, Codable, BuildRejection, leftOfEntrance, notAdjacent, occupied, HouseBuildPanel, HouseBuildSlotNode (+29 more)

### Community 2 - "Map Tiles — Mossy Autotile"
Cohesion: 0.08
Nodes (100): SharedGameData → Tiles → Mossy → terrain 256 → autotile preview, SharedGameData → Tiles → Mossy → terrain 256 → contact sheet, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 02, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 03, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto e 04, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 01, SharedGameData → Tiles → Mossy → terrain 256 → mossy terrain auto ew 02 (+92 more)

### Community 3 - "Gameplay Models & Scene Construction"
Cohesion: 0.08
Nodes (18): SKLabelNode, SKShapeNode, NSCoder, SKShapeNode, CGSize, GameUI, CGRect, NSCache (+10 more)

### Community 4 - "Challenge Flow Controller"
Cohesion: 0.06
Nodes (20): ChallengeFlowController, Bool, SKCameraNode, Void, ChallengeChoiceOverlay, POIChallengeOfferOverlay, Set, UIEvent (+12 more)

### Community 5 - "World Point & Rendering Primitives"
Cohesion: 0.11
Nodes (13): CGLineCap, SKShapeNode, SKTexture, TimeInterval, UIBezierPath, UIColor, UIImage, WorldPOIArtworkFactory (+5 more)

### Community 6 - "Depth Environment & Ocean Parallax"
Cohesion: 0.08
Nodes (16): DepthEnvironment, UIColor, CGFloat, World, Bool, AmbientLifeNode, OceanParallaxBackdrop, NSCoder (+8 more)

### Community 7 - "Banquet of Tides Minigame"
Cohesion: 0.06
Nodes (34): BanquetEngine, BanquetEntity, BanquetFeedback, BanquetFeedbackEffect, huge, pop, shake, spray (+26 more)

### Community 8 - "Event System"
Cohesion: 0.07
Nodes (17): EventSystem, UIColor, Void, WorldObjective, GameContext, NSCoder, TravelSystem, ResourceSupportSystem (+9 more)

### Community 9 - "Species Registry & Mermaid Progression"
Cohesion: 0.09
Nodes (14): RegistroMermaidObservation, RegistroOverlay, Bool, CGRect, ClosedRange, NSCoder, Set, SKLabelNode (+6 more)

### Community 10 - "Tide Memory Minigame"
Cohesion: 0.10
Nodes (19): Bool, Set, SKLabelNode, SKShapeNode, UIColor, UIEvent, UITouch, Void (+11 more)

### Community 11 - "Refuge Village Controller"
Cohesion: 0.13
Nodes (6): SKNode, RefugeArtDirection, RefugeVillageController, CGRect, Mermaid, UIColor

### Community 12 - "Shelter System"
Cohesion: 0.06
Nodes (31): BadgePlacement, Interaction, enterHome, enterItemShop, enterUpgradeShop, restInBedroom, returnToVillage, talkToItemShopNpc (+23 more)

### Community 13 - "Bubble Climb Minigame Overlay"
Cohesion: 0.08
Nodes (6): SKLabelNode, UIColor, CGPoint, Bool, TimeInterval, SKShapeNode

### Community 14 - "Shell Snap Minigame"
Cohesion: 0.10
Nodes (18): ShellSnapBoard, ShellSnapFall, ShellSnapOverlay, ShellSnapPop, ShellSnapPosition, ShellSnapRules, ShellSnapSpawn, ShellSnapTheme (+10 more)

### Community 15 - "Echo Melody Minigame"
Cohesion: 0.08
Nodes (25): EchoMelodyEngine, EchoMelodyInputResult, EchoMelodyNote, coral, kelp, moon, pearl, EchoMelodyOverlay (+17 more)

### Community 16 - "Mermaid Stats & Inventory"
Cohesion: 0.07
Nodes (17): inventoryItems, repeatablePOIRewardAvailableAtByKey, MermaidEmotionalState, MermaidMoodCue, currentLift, currentStrain, encouraged, none (+9 more)

### Community 17 - "Resource Support & Shop"
Cohesion: 0.09
Nodes (25): Calendar, RefugeShopCatalog, RefugeShopItem, RefugeShopPurchase, resource, RefugeStoreOverlay, Date, NSCoder (+17 more)

### Community 18 - "Entity Components — Visual Effects"
Cohesion: 0.07
Nodes (29): ExpressionComponent, NSCoder, HealthComponent, NSCoder, IntentComponent, NSCoder, LifetimeComponent, Bool (+21 more)

### Community 19 - "Game Scene Entries & Birth Waters"
Cohesion: 0.06
Nodes (18): CoreMotion, AncientRuinsGameScene, BirthWatersGameScene, ClimbVisual, CalmGardenGameScene, CaveMouthGameScene, CrystalFieldsGameScene, DistantSurfaceGameScene (+10 more)

### Community 20 - "Challenge Goals & Spawning"
Cohesion: 0.08
Nodes (17): ChallengeGoalRange, ChallengeRewardProfile, GameBalance, MermaidPhase, adult, baby, child, egg (+9 more)

### Community 21 - "Mermaid Stats — Balance & Buffs"
Cohesion: 0.04
Nodes (45): CodingKeys, activeBuffs, adaptationByZone, babyGuaranteedRequestsUsed, balanceVersion, birthDate, collectedPOIRewardKeys, courage (+37 more)

### Community 22 - "Audio Manager & Sound Effects"
Cohesion: 0.04
Nodes (48): GameSound, ambientBubbleBurst, bigShadow, boatMuffled, challengeFail, challengeOpen, challengeSuccess, climbBounce (+40 more)

### Community 23 - "Bubble Climb Controls"
Cohesion: 0.10
Nodes (9): BubbleClimbOverlay, ClimbBubble, Bool, Mermaid, NSCoder, Set, UIEvent, UITouch (+1 more)

### Community 24 - "Tide Weaving System"
Cohesion: 0.12
Nodes (15): GridPos, Bool, Set, SKLabelNode, UIEvent, UITouch, Void, TideSessionType (+7 more)

### Community 25 - "World Stamp Rendering"
Cohesion: 0.18
Nodes (18): SeededGenerator, ClosedRange, CGContext, CGRect, UIBezierPath, UIColor, WorldStampRenderer, CGContext (+10 more)

### Community 26 - "Mermaid Arms & Animation"
Cohesion: 0.12
Nodes (10): SKAction, MermaidArms, Orientation, horizontal, vertical, Rotation, down, up (+2 more)

### Community 27 - "Challenge Giver Component"
Cohesion: 0.08
Nodes (20): AnyObject, ChallengeGiverComponent, Bool, NSCoder, ChallengeGiver, ChallengeKind, ascent, banquet (+12 more)

### Community 28 - "Autonomy — Fish Play & Guidance"
Cohesion: 0.10
Nodes (5): FishNode, Bool, NSCoder, TimeInterval, UIColor

### Community 29 - "Mermaid Figures — Baby"
Cohesion: 0.13
Nodes (9): BabyMermaidFigure, Bool, Double, MermaidFigurePart, MovementDirection, down, left, right (+1 more)

### Community 30 - "Reef Asteroids Minigame Engine"
Cohesion: 0.13
Nodes (14): ReefAsteroidsEngine, ReefAsteroidsRules, ReefFeedback, ReefFrame, ReefPlayer, ReefProjectile, ReefRock, ReefRockSize (+6 more)

### Community 31 - "Region System"
Cohesion: 0.10
Nodes (24): CaseIterable, InteractionBalance, POIDefinition, POIVisual, RepeatablePOIReward, StableRNG, ClosedRange, TimeInterval (+16 more)

### Community 32 - "Reef Asteroids Overlay"
Cohesion: 0.11
Nodes (9): ReefAsteroidsOverlay, Mermaid, NSCoder, Set, SKLabelNode, UIColor, UIEvent, UITouch (+1 more)

### Community 33 - "Map Tiles — JSON Manifest"
Cohesion: 0.05
Nodes (37): columns, connectionMaskCounts, 0, 1, 10, 11, 12, 13 (+29 more)

### Community 34 - "Depth System"
Cohesion: 0.12
Nodes (14): Equatable, BoundaryPaletteEffect, DepthBoundaryEdge, lower, upper, DepthSystem, MermaidPaletteTransition, MermaidPaletteZone (+6 more)

### Community 35 - "Gameplay Reward Models"
Cohesion: 0.09
Nodes (17): Reward, RewardKind, item, pearls, regionMap, story, supportResource, temporaryEffect (+9 more)

### Community 36 - "Ecosystem Biome Catalog"
Cohesion: 0.10
Nodes (23): Array, EcosystemBiomeCatalog, EcosystemBiomeID, estuario, florestaKelp, manguezal, marAbertoTemperado, marAbertoTropical (+15 more)

### Community 37 - "POI System"
Cohesion: 0.18
Nodes (4): POISystem, Bool, Date, WorldPOI

### Community 38 - "World Chunk Factory"
Cohesion: 0.10
Nodes (17): PlacedReefCluster, ReefCluster, Bool, CGRect, CGRect, WorldChunkCoord, WorldLayerSeed, biome (+9 more)

### Community 39 - "Growth System"
Cohesion: 0.16
Nodes (6): GrowthSystem, Requirement, Bool, Double, SKShapeNode, TimeInterval

### Community 40 - "Mermaid Figures — Child"
Cohesion: 0.16
Nodes (4): ChildMermaidFigure, Bool, Double, MermaidFigurePart

### Community 41 - "World Chunk — Detail Rendering"
Cohesion: 0.11
Nodes (21): SKSpriteNode, WorldChunkFactory, WorldStampKind, coralBranch, coralFan, coralTube, crystalCluster, currentRibbon (+13 more)

### Community 42 - "Documentation — Design Decisions"
Cohesion: 0.07
Nodes (33): GameScene Orchestration Shell Principle, Freesound SFX Workflow, Minigame Difficulty Criteria (1-5 Scale), Minigame Economy Balancing Formula, Minigame Economic Profiles, Professor Octopus NPC Example, Siren Reference Sprites, Mermaid/Ester Character Visual Style (+25 more)

### Community 43 - "Movement Vector Utilities"
Cohesion: 0.12
Nodes (9): BanquetOfTidesOverlay, Bool, CGRect, Mermaid, NSCoder, Set, UIEvent, UITouch (+1 more)

### Community 44 - "Component Base Classes"
Cohesion: 0.08
Nodes (12): CoreGraphics, FoodComponent, Bool, NSCoder, ObjectiveComponent, Bool, NSCoder, TimeInterval (+4 more)

### Community 45 - "Autonomy — Eating Behavior"
Cohesion: 0.13
Nodes (7): AutonomySystem, HorizontalBoundarySide, left, right, ClosedRange, Mermaid, CGVector

### Community 46 - "Cheat System"
Cohesion: 0.15
Nodes (5): CheatSystem, Suggestion, Bool, ClosedRange, Set

### Community 47 - "Fish Visual Models"
Cohesion: 0.11
Nodes (22): FishVisualPalette, SpeciesVisualCatalog, SpeciesVisualProfile, SpeciesVisualTrait, bill, bodySpots, cetaceanFluke, claws (+14 more)

### Community 48 - "Food System"
Cohesion: 0.14
Nodes (14): FoodKind, FoodNode, FoodStyle, critter, crystal, fruit, glow, leaf (+6 more)

### Community 49 - "Region Map Cues & Expedition"
Cohesion: 0.15
Nodes (3): EntryTextCatalog, Region, RegionDiscoverySystem

### Community 50 - "Movement Enums & Animation Modes"
Cohesion: 0.13
Nodes (10): MovementType, fast, idle, swing, DirectionalCore, MermaidBody, MotionProfile, Bool (+2 more)

### Community 51 - "Fish Drawing Factory"
Cohesion: 0.27
Nodes (5): FishDrawingFactory, Bool, SKShapeNode, UIBezierPath, UIColor

### Community 52 - "HUD Layer"
Cohesion: 0.15
Nodes (8): HUDLayer, Bool, Set, SKLabelNode, TimeInterval, UIEvent, UITouch, Void

### Community 53 - "Expedition Grid Math"
Cohesion: 0.19
Nodes (4): ExpeditionMapNode, NSCoder, SKShapeNode, UIColor

### Community 54 - "World Stamp Drawing"
Cohesion: 0.08
Nodes (15): WorldStampRenderer, WorldStampRenderer, SKTexture, WorldTextureKey, Channel, caustics, fog, particles (+7 more)

### Community 55 - "Pearl Economy"
Cohesion: 0.17
Nodes (8): ChallengeChrome, ChallengeResult, ChallengeVictoryReward, none, resource, shellBonus, NSCoder, NSCoder

### Community 56 - "HUD — Biology Meter & Commands"
Cohesion: 0.25
Nodes (4): HUDPalette, SKShapeNode, UIBezierPath, UIColor

### Community 57 - "Buff Coding Keys"
Cohesion: 0.08
Nodes (25): CodingKey, CodingKeys, buffKind, duration, expiresAt, itemId, kind, pearlAmount (+17 more)

### Community 58 - "Mermaid Name Editor"
Cohesion: 0.13
Nodes (10): MermaidNameEditorViewController, IndexPath, Notification, NSLayoutConstraint, UITableView, UITableViewCell, UITableViewDataSource, UITableViewDelegate (+2 more)

### Community 59 - "Discovery & Depth Ranges"
Cohesion: 0.15
Nodes (8): ClosedRange, discoveryPointByRegion, mapEntryPointByRegion, mapPositionByRegion, StableMapRNG, ClosedRange, UInt64, OfflineProgressSystem

### Community 60 - "Depth Zone Colors"
Cohesion: 0.16
Nodes (11): DepthZone, abyss, blue, clear, deep, mid, shallow, surface (+3 more)

### Community 61 - "Mermaid Emotion Component"
Cohesion: 0.14
Nodes (18): MermaidExpressionLibrary, MermaidExpressionPreset, MermaidEyeAsset, closed, half, open, wide, MermaidEyebrowExpression (+10 more)

### Community 63 - "Mermaid Rig Debug Tool"
Cohesion: 0.19
Nodes (9): MermaidFigurePart, MermaidRigDebugTool, PreviewFit, Bool, MermaidFigurePart, NSCoder, SKLabelNode, UIEdgeInsets (+1 more)

### Community 64 - "Mermaid Core Entity"
Cohesion: 0.19
Nodes (9): Mermaid, MermaidFigure, MermaidFormKind, adult, baby, child, young, Bool (+1 more)

### Community 65 - "Game Sound Enum Values"
Cohesion: 0.16
Nodes (11): A, B, C, EntityManager, GKComponent, GKEntity, ObjectIdentifier, Set (+3 more)

### Community 66 - "Encoding Utilities"
Cohesion: 0.14
Nodes (11): Encoder, Date, Decoder, TimedBuff, TimedBuffKind, eagerCompanion, fishGuide, fishPlay (+3 more)

### Community 67 - "Autonomy — Bond Recovery"
Cohesion: 0.12
Nodes (19): BondRecoveryBalance, BondRecoveryHUDState, available, hidden, ready, waiting, BondRecoveryState, idle (+11 more)

### Community 68 - "Mermaid Intent & Acceptance"
Cohesion: 0.11
Nodes (18): MermaidIntent, avoidingDanger, eating, enteringRefuge, followingFish, goingDeeper, goingToObjective, goingUp (+10 more)

### Community 69 - "Autotile Set Hashing"
Cohesion: 0.20
Nodes (5): Hasher, AutotileSet, Set, TileLibrary, TilePaletteItem

### Community 70 - "Mermaid Rig Models"
Cohesion: 0.18
Nodes (7): MermaidRigDocument, MermaidRigStore, Any, Data, MermaidFigurePart, MermaidRigPosition, URL

### Community 71 - "HUD — Active Effects Shelf"
Cohesion: 0.11
Nodes (13): CoreText, HUDTypography, IconKind, plankton, shell, wave, LabelStyle, body (+5 more)

### Community 72 - "Aquatic Biomes"
Cohesion: 0.11
Nodes (12): AquaticBiome, abyssPlain, ancientRuins, cavernMouth, coralGarden, crystalField, deepVents, kelpForest (+4 more)

### Community 73 - "Mermaid Figure Part Positioning"
Cohesion: 0.12
Nodes (16): MermaidFigurePart, chest, eyebrowLeft, eyebrowRight, eyeLeft, eyeRight, hairBack, hairFront (+8 more)

### Community 74 - "Map Editor — SwiftUI Content View"
Cohesion: 0.18
Nodes (15): App, AppKit, AutotileSummary, DepthRow, EditorToolbar, MapCanvasView, PathSummary, Double (+7 more)

### Community 75 - "Map Editor — Depth Save"
Cohesion: 0.19
Nodes (5): Comparable, ContentView, Bool, Set, TerrainCell

### Community 76 - "Event Bus"
Cohesion: 0.18
Nodes (13): ChallengeCompletedEvent, EventBus, FoodCollectedEvent, GameEvent, MermaidStateChangedEvent, RegionDiscoveredEvent, Any, GKEntity (+5 more)

### Community 77 - "Mermaid Body Dimensions"
Cohesion: 0.15
Nodes (7): FishSilhouette, diamond, moon, needle, oval, ray, turtle

### Community 78 - "Map Editor Models"
Cohesion: 0.26
Nodes (10): Decodable, Color, DepthDefinition, EditorDataLocation, EditorMapStore, MapDocument, Bool, URL (+2 more)

### Community 80 - "Ester Game"
Cohesion: 0.17
Nodes (7): RefugeFlowController, Bool, Void, RefugeScene, SKView, TimeInterval, SKScene

### Community 81 - "Ester Game"
Cohesion: 0.22
Nodes (9): Bool, NSCoder, SKLabelNode, VisualStyle, environment, npc, object, warmCurrentEnvironment (+1 more)

### Community 82 - "Components"
Cohesion: 0.13
Nodes (14): MermaidEmotion, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 85 - "Components"
Cohesion: 0.27
Nodes (4): MermaidEmotionComponent, Bool, Mermaid, NSCoder

### Community 86 - "Components"
Cohesion: 0.14
Nodes (14): MermaidExpressionName, adventurous, curious, eating, focused, happy, hungry, neutral (+6 more)

### Community 87 - "Ester Game"
Cohesion: 0.14
Nodes (14): AquaticAnimalGroup, annelid, arthropod, bird, cephalopod, cnidarian, crustacean, echinoderm (+6 more)

### Community 88 - "Ester Game"
Cohesion: 0.31
Nodes (3): AquaticSpecies, AquaticSpeciesCatalog, RegistroCatalog

### Community 89 - "Managers"
Cohesion: 0.21
Nodes (7): MermaidEyebrows, SKSpriteNode, MermaidEyes, SKSpriteNode, SKSpriteNode, MermaidMouth, SKSpriteNode

### Community 90 - "Managers"
Cohesion: 0.22
Nodes (9): AVAudioPCMBuffer, AVFoundation, AmbienceSpec, SoundSpec, Bool, Double, TimeInterval, Float (+1 more)

### Community 91 - "Managers"
Cohesion: 0.29
Nodes (3): AVAudioPlayer, GameAudio, URL

### Community 92 - "Appdelegate"
Cohesion: 0.21
Nodes (7): AppDelegate, Any, Bool, UIApplication, UIApplicationDelegate, UIResponder, UIWindow

### Community 93 - "Components"
Cohesion: 0.21
Nodes (11): FishBehaviorComponent, FishSpecies, FishSwimPattern, flee, guide, school, wander, Bool (+3 more)

### Community 94 - "Ester Game"
Cohesion: 0.15
Nodes (13): PlayerCommand, challenge, explore, goDown, goLeft, goRight, goUp, objective (+5 more)

### Community 95 - "Ester Game"
Cohesion: 0.28
Nodes (3): AdultMermaidFigure, MermaidFigurePart, Bool

### Community 96 - "Tools Verify"
Cohesion: 0.33
Nodes (12): connection_mask(), fail(), inner_corner_mask(), main(), png_size(), preferred_exact_candidates(), preferred_inner_candidates(), rectangle() (+4 more)

### Community 97 - "Ester Game"
Cohesion: 0.17
Nodes (12): EcosystemVegetationCategory, algae, chemosyntheticMat, coral, iceAlgae, kelp, macrophyte, mangroveRoot (+4 more)

### Community 98 - "Ester Game"
Cohesion: 0.35
Nodes (6): RegionMenuOverlay, CGRect, Set, UIEvent, UITouch, Void

### Community 100 - "Ester Game"
Cohesion: 0.29
Nodes (3): CameraController, SKCameraNode, UIColor

### Community 101 - "Ester Game"
Cohesion: 0.29
Nodes (5): HUDTexture, NSCache, NSString, SKSpriteNode, SKTexture

### Community 102 - "Managers"
Cohesion: 0.20
Nodes (7): Mermaid, Direction, down, left, none, right, up

### Community 103 - "Ester Game"
Cohesion: 0.42
Nodes (3): Set, UIEvent, UITouch

### Community 104 - "Ester Game"
Cohesion: 0.22
Nodes (7): MermaidRigAxis, scale, x, y, z, MermaidRigTransform, Decoder

### Community 106 - "Components"
Cohesion: 0.25
Nodes (7): POIComponent, POIState, active, completed, dormant, interacting, NSCoder

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
Cohesion: 0.29
Nodes (5): FishPattern, glowDots, plain, spots, stripes

### Community 112 - "Ester Game"
Cohesion: 0.39
Nodes (5): MermaidTemplateTexture, NSCache, NSString, SKTexture, UIColor

### Community 113 - "Ester Game"
Cohesion: 0.29
Nodes (6): UpgradeKind, disposition, energy, feeding, shellGain, speed

### Community 114 - "Managers"
Cohesion: 0.25
Nodes (7): GameAmbience, abyss, clear, deep, mid, refuge, shallow

### Community 115 - "Managers"
Cohesion: 0.29
Nodes (4): ColorManager, UIColor, SKSpriteNode, SKSpriteNode

### Community 116 - "Mapeditor Mapeditor"
Cohesion: 0.25
Nodes (8): Identifiable, EditorLayer, decoration, spawn, terrain, PaintTool, brush, eraser

### Community 117 - "Ester Game"
Cohesion: 0.29
Nodes (7): ReefFeedbackEffect, combo, crack, hit, score, surge, wave

### Community 118 - "Mapeditor Mapeditor"
Cohesion: 0.43
Nodes (5): NSCache, URL, TileImageCache, NSImage, NSURL

### Community 119 - "Ester Game"
Cohesion: 0.33
Nodes (6): FishMotionMode, gatheringForPlay, guiding, normal, playing, Date

### Community 120 - "Ester Game"
Cohesion: 0.47
Nodes (3): BabyMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 121 - "Ester Game"
Cohesion: 0.47
Nodes (3): ChildMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 122 - "Ester Game"
Cohesion: 0.33
Nodes (5): ReefRockMotif, algaeStone, basalt, goldenCoral, roseCoral

### Community 123 - "Entitys"
Cohesion: 0.50
Nodes (4): MermaidEntity, Mermaid, NSCoder, GKEntity

### Community 124 - "Ester Game"
Cohesion: 0.60
Nodes (3): AdultMermaidRig, MermaidFigurePart, MermaidRigPosition

### Community 125 - "Ester Game"
Cohesion: 0.60
Nodes (3): MermaidFigurePart, MermaidRigPosition, YoungMermaidRig

### Community 126 - "Ester Game"
Cohesion: 0.40
Nodes (5): MermaidMoodTone, danger, positive, steady, warning

### Community 127 - "Gamescene"
Cohesion: 0.40
Nodes (5): Style, jelly, needleFish, ovalFish, ray

### Community 128 - "Mapeditor Mapeditor"
Cohesion: 0.40
Nodes (4): GridLines, CGRect, Path, Shape

### Community 129 - "Mapeditor Readme"
Cohesion: 0.40
Nodes (5): Autotile System, MapEditor macOS App, Mossy Terrain Tileset, SharedGameData Directory, Mossy Autotile Verification Script

### Community 130 - "Agents"
Cohesion: 0.50
Nodes (4): Icon Asset Workflow, Character Chroma-Key Background Workflow, Icon Export Instructions, Ester/Assets.xcassets (Asset Catalog)

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

## Knowledge Gaps
- **618 isolated node(s):** `wander`, `school`, `flee`, `guide`, `open` (+613 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **55 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CGFloat` connect `Depth Environment & Ocean Parallax` to `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Depth System`, `Gameplay Reward Models`, `Ecosystem Biome Catalog`, `POI System`, `World Chunk Factory`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Movement Vector Utilities`, `Component Base Classes`, `Autonomy — Eating Behavior`, `Cheat System`, `Fish Visual Models`, `Food System`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `World Stamp Drawing`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Mermaid Name Editor`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Encoding Utilities`, `Autonomy — Bond Recovery`, `Mermaid Intent & Acceptance`, `Mermaid Rig Models`, `Aquatic Biomes`, `Map Editor — SwiftUI Content View`, `Map Editor — Depth Save`, `Mermaid Body Dimensions`, `Refuge Entry & Energy`, `Ester Game`, `Ester Game`, `Components`, `Managers`, `Ester Game`, `Components`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Mapeditor Mapeditor`?**
  _High betweenness centrality (0.206) - this node is a cross-community bridge._
- **Why does `String` connect `Gameplay Reward Models` to `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Bubble Climb Minigame Overlay`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Resource Support & Shop`, `Entity Components — Visual Effects`, `Game Scene Entries & Birth Waters`, `Challenge Goals & Spawning`, `Mermaid Stats — Balance & Buffs`, `Audio Manager & Sound Effects`, `Bubble Climb Controls`, `Tide Weaving System`, `Challenge Giver Component`, `Autonomy — Fish Play & Guidance`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Depth System`, `Ecosystem Biome Catalog`, `POI System`, `Growth System`, `Movement Vector Utilities`, `Component Base Classes`, `Cheat System`, `Fish Visual Models`, `Food System`, `Region Map Cues & Expedition`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `World Stamp Drawing`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Buff Coding Keys`, `Mermaid Name Editor`, `Discovery & Depth Ranges`, `Depth Zone Colors`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Mermaid Core Entity`, `Encoding Utilities`, `Mermaid Intent & Acceptance`, `Autotile Set Hashing`, `Mermaid Rig Models`, `HUD — Active Effects Shelf`, `Mermaid Figure Part Positioning`, `Map Editor — SwiftUI Content View`, `Map Editor — Depth Save`, `Mermaid Body Dimensions`, `Map Editor Models`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Ester Game`, `Managers`, `Managers`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Components`, `Ester Game`, `Ester Game`, `Managers`, `Managers`, `Mapeditor Mapeditor`, `Ester Game`?**
  _High betweenness centrality (0.158) - this node is a cross-community bridge._
- **Why does `CGPoint` connect `Bubble Climb Minigame Overlay` to `Mapeditor Mapeditor`, `Mermaid House System`, `Gameplay Models & Scene Construction`, `Challenge Flow Controller`, `World Point & Rendering Primitives`, `Depth Environment & Ocean Parallax`, `Banquet of Tides Minigame`, `Event System`, `Species Registry & Mermaid Progression`, `Tide Memory Minigame`, `Refuge Village Controller`, `Shelter System`, `Shell Snap Minigame`, `Echo Melody Minigame`, `Mermaid Stats & Inventory`, `Entity Components — Visual Effects`, `Challenge Goals & Spawning`, `Bubble Climb Controls`, `Tide Weaving System`, `World Stamp Rendering`, `Mermaid Arms & Animation`, `Challenge Giver Component`, `Autonomy — Fish Play & Guidance`, `Mermaid Figures — Baby`, `Reef Asteroids Minigame Engine`, `Region System`, `Reef Asteroids Overlay`, `Gameplay Reward Models`, `POI System`, `World Chunk Factory`, `Growth System`, `Mermaid Figures — Child`, `World Chunk — Detail Rendering`, `Movement Vector Utilities`, `Component Base Classes`, `Autonomy — Eating Behavior`, `Food System`, `Region Map Cues & Expedition`, `Movement Enums & Animation Modes`, `Fish Drawing Factory`, `HUD Layer`, `Expedition Grid Math`, `Pearl Economy`, `HUD — Biology Meter & Commands`, `Discovery & Depth Ranges`, `Mermaid Emotion Component`, `Command & Touch System`, `Mermaid Rig Debug Tool`, `Game Sound Enum Values`, `Encoding Utilities`, `HUD — Active Effects Shelf`, `Mermaid Figure Part Positioning`, `Map Editor — Depth Save`, `Refuge Entry & Energy`, `Ester Game`, `Managers`, `Ester Game`, `Components`, `Components`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Ester Game`, `Managers`, `Ester Game`?**
  _High betweenness centrality (0.123) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `CGFloat` (e.g. with `.update()` and `.drawReefSkirt()`) actually correct?**
  _`CGFloat` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 35 inferred relationships involving `CGPoint` (e.g. with `.update()` and `.openChallengeChoiceMenu()`) actually correct?**
  _`CGPoint` has 35 INFERRED edges - model-reasoned connections that need verification._
- **Are the 99 inferred relationships involving `SKNode` (e.g. with `.buildPlayer()` and `.showFeedback()`) actually correct?**
  _`SKNode` has 99 INFERRED edges - model-reasoned connections that need verification._
- **Are the 8 inferred relationships involving `String` (e.g. with `.touchesBegan()` and `.touchesBegan()`) actually correct?**
  _`String` has 8 INFERRED edges - model-reasoned connections that need verification._