# Resource Support System

## Concept

The bottom HUD action formerly used for direct feeding is now `Recursos`.
The player remains an observer/biologist: they do not order the mermaid to eat.
Instead, they send support resources from the Refuge inventory when the mermaid
needs help or when the player wants to prepare her for exploration.

## Resource Flow

1. The player buys stock in the Refuge `Loja`.
2. Bought support items are stored in `MermaidStats.inventoryItems`.
3. The HUD `Recursos` button opens `ResourceChoiceOverlay`.
4. Selecting a stocked resource reserves one item immediately.
5. `GameScene` animates the visible object dropping from above toward the mermaid.
6. On arrival, the resource-specific consumption effect plays and
   `ResourceSupportSystem.applyDeliveredResource(_:)` applies the gameplay effect.

This keeps economy, inventory, UI choice, world delivery animation, and stat
mutation separated.

## Current Resources

- `foodBag`: reduces hunger by a fixed amount, counts as a meal, and gives a
  small mood/trust gain. Phase differences should come from upgrades and other
  progression systems, not from hidden resource scaling.
- `calmShell`: reduces fear pressure and improves disposition/trust.
- `currentAmpoule`: grants energy and a temporary `swiftCurrent` buff.
- `coralToy`: improves mood/trust and grants a temporary `eagerCompanion` buff.
- `growthPotion`: skips one hour of growth wait when sent to the mermaid.

## Refuge Shop

The Refuge shop sells support resources plus `Porção acelerar`.
Growth acceleration moved out of `Aprimoramentos` and now costs
`GameBalance.growthAccelerateShellCost` (`1000` shells). Buying it adds one
`growthPotion` to inventory. The growth wait is skipped only after the player
sends that potion through `Recursos`.

## Adding A New Resource

Add one `SupportResourceKind` case and define:

- Inventory id through `itemId`.
- Player-facing strings: `title`, `shortTitle`, `blurb`, `deliveredMessage`.
- Presentation values: `tint`, `glyph`, `symbolName`.
- Gameplay behavior in `ResourceSupportSystem.applyDeliveredResource(_:)`.
- Delivery artwork in `SupportResourceVisualFactory.makeNode(for:)`.
- Arrival/consumption animation in `SupportResourceVisualFactory.makeArrivalEffect(for:)`.
- Shop entry in `RefugeShopCatalog.items`, if the resource should be purchasable.

Keep direct mermaid commands out of this flow. A resource helps her environment
or gives her something to receive; it should not override autonomous behavior.
