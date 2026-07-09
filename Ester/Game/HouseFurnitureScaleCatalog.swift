//
//  HouseFurnitureScaleCatalog.swift
//  Ester
//
//  Centralised display‑scale catalogue for every house furniture item.
//  Each entry maps a `HouseObjectDefinition.id` to the scale multiplier
//  applied when the furniture is rendered in‑game. Assets stay at their
//  original dimensions; only the in‑game scale is adjusted here.
//
//  Usage:
//    let scale = HouseFurnitureScaleCatalog.scale(for: definition.id)
//    node.setScale(scale)
//
//  Add a new entry whenever a furniture asset looks too large or too
//  small inside the house. Furniture without a custom entry falls back
//  to `defaultScale`.
//

import Foundation

struct HouseFurnitureScaleCatalog {

    /// Default scale for furniture IDs not listed in `scales`.
    static let defaultScale: CGFloat = 0.5

    /// Per‑furniture display‑scale overrides. To fine‑tune a furniture
    /// item, find its id below and edit the value. Adding a new id is
    /// safe — missing ids fall back to `defaultScale`.
    static let scales: [String: CGFloat] = [

        // ── Floor furniture (21 items from the shop "Móveis" tab) ─────
        "mermaid_sideboard":          0.5,   // Aparador sereia
        "mermaid_dresser":            0.5,   // Cômoda sereia
        "mermaid_low_bookcase":       0.5,   // Estante baixa
        "mermaid_nightstand":         0.5,   // Criado-mudo sereia
        "mermaid_wooden_bench":       0.5,   // Banco de madeira
        "mermaid_coral_pouf":         0.5,   // Puff de coral
        "mermaid_decorative_chest":   0.5,   // Baú decorativo
        "mermaid_shell_coat_rack":    0.5,   // Cabideiro de conchas
        "mermaid_coffee_table":       0.5,   // Mesa de centro
        "mermaid_birthday_table":     0.5,   // Mesa feliz aniversário
        "mermaid_large_seaweed_vase": 0.5,   // Vaso grande com alga
        "mermaid_coral_vase":         0.5,   // Vaso com coral
        "mermaid_stone_sculpture":    0.5,   // Escultura de pedra
        "mermaid_ancient_amphora":    0.5,   // Ânfora antiga
        "mermaid_book_stack":         0.5,   // Pilha de livros
        "mermaid_marine_globe":       0.5,   // Globo marinho
        "mermaid_shell_basket":       0.5,   // Cesta de conchas
        "mermaid_pearl_stand":        0.5,   // Suporte com pérolas
        "mermaid_sea_lyre":           0.5,   // Lira marinha
        "mermaid_ornamental_aquarium":0.5,   // Aquário ornamental
        "mermaid_small_statue":       0.5,   // Estátua pequena

        // ── Wall decorations ────────────────────────────────────────────
        "mermaid_birthday_wall_art":  0.5,   // Quadro feliz aniversário
        "mermaid_shell_mirror":       0.5,   // Espelho de concha
        "mermaid_pearl_clock":        0.5,   // Relógio de pérolas
        "mermaid_sea_map_frame":      0.5,   // Mapa dos mares
        "mermaid_coral_wall_shelf":   0.5,   // Prateleira coral
        "mermaid_starfish_garland":   0.5,   // Guirlanda de estrelas
        "mermaid_jellyfish_sconce":   0.5,   // Arandela medusa
        "mermaid_wave_tapestry":      0.5,   // Tapeçaria de ondas

        // ── Debug / architecture‑validation samples ──────────────────
        "sample_dresser":             0.5,   // Cômoda (debug)
        "sample_bed":                 0.5,   // Cama (debug)
        "sample_table":               0.5,   // Mesa (debug)
        "sample_painting":            0.5,   // Quadro (debug)
        "sample_ceiling_lamp":        0.5,   // Luminária de teto (debug)
        "sample_side_ornament":       0.5,   // Ornamento lateral (debug)
    ]

    /// Returns the configured display scale for the given furniture
    /// definition id, or `defaultScale` when no custom value exists.
    static func scale(for definitionID: String) -> CGFloat {
        scales[definitionID] ?? defaultScale
    }
}

extension HouseObjectDefinition {

    /// Display scale to apply when rendering this furniture item.
    /// Reads from `HouseFurnitureScaleCatalog` so manual tweaks in
    /// that file take effect everywhere automatically.
    var displayScale: CGFloat {
        HouseFurnitureScaleCatalog.scale(for: id)
    }

    /// Size to use when creating or sizing a display node for this
    /// furniture item. Applies `displayScale` on top of `defaultSize`.
    var displaySize: CGSize {
        CGSize(width: defaultSize.width * displayScale,
               height: defaultSize.height * displayScale)
    }
}
