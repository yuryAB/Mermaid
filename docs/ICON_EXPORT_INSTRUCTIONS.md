# Icon Export Instructions

This document defines how to prepare and add icon assets to Mermaid. Use it whenever a new icon is provided, exported from a design tool, converted from SVG/PDF/PNG, renamed, resized, or moved into `Ester/Assets.xcassets/`.

## 1. Required Context

Before adding or replacing an icon, identify:

- where the icon will be used in the app;
- whether an icon already exists in that flow;
- the source/origin provided by the icon author;
- whether the code expects an asset name, an SF Symbol, an `.imageset`, or a `.symbolset`.

Do not invent the origin, name, or visual usage. If the source is unclear and that affects catalog organization, ask for confirmation.

## 2. Size and Proportion

Interface icons must be prepared inside a **24 x 24 px** area.

- If the provided file uses another size, adjust the canvas/viewBox to `24 x 24`.
- If the artwork is not square, preserve the artwork proportion and center it inside the `24 x 24` area; do not stretch or distort the geometry.
- For SVG files, the `viewBox` should be compatible with `0 0 24 24`, unless there is a clear technical reason to keep a different coordinate system.
- Preserve the original stroke, fill, corner treatment, and optical alignment. Canvas adjustment must not silently redesign the icon.
- Remove export leftovers that affect framing, such as unnecessary invisible frames, accidental offsets, empty groups, or tool-generated wrappers.

Illustration, character, particle, and sprite assets do not need to fit the 24 x 24 interface-icon rule. For those assets, preserve the intended source canvas, animation alignment, and existing catalog conventions.

## 3. Asset Catalog Location

The default destination is:

`Ester/Assets.xcassets/`

Choose the folder based on use and origin:

- General interface icons: create or reuse `Icons/`.
- Source-specific reusable icon sets: use a short English source folder under `Icons/`, such as `Icons/untitledIcons/`, `Icons/phosphorIcons/`, or `Icons/iconoir/`.
- Custom Mermaid/Ester icons or icons created specifically for the app: use `Icons/customIcons/`.
- Existing character, face, color, particle, or app icon assets: keep them in their established folders unless the task explicitly reorganizes the catalog.

If the author provides another recurring source, create a short English source folder that matches the catalog style. For custom campaigns or one-off collections, keep the icons under `customIcons` or create an English subfolder only when that materially improves organization.

Use `.imageset` for regular image assets. Use `.symbolset` only when the asset is intentionally a custom symbol and the existing code path expects symbol behavior.

## 4. Tint and Color Configuration

Icons used by the app should remain editable/tintable by SwiftUI color modifiers when they appear in buttons, menus, controls, or other UI chrome.

For template `.imageset` assets:

- Set the asset to render as a template image.
- In `Contents.json`, include `"template-rendering-intent": "template"` under `properties`.
- Prefer SVG paths that use `currentColor` or a single monochrome source color compatible with template rendering.
- Do not export multicolor, rasterized, gradient, or fixed-color artwork for icons that need to receive app colors, unless the user explicitly asks for a non-tintable decorative asset.
- Do not leave the asset as original rendering when the icon is used in UI where `foregroundStyle`, `foregroundColor`, or dynamic color changes are expected.

Character parts, illustrations, particles, app icons, and decorative images may keep original rendering when their colors are part of the artwork.

## 5. File and Asset Names

Rename exported files before adding them to the catalog when the provided name is generic, strange, localized, or polluted by design-tool output.

Rules:

- Use English names.
- Do not use Portuguese names.
- Use ASCII.
- Prefer `kebab-case` for new `.imageset` folders and internal SVG/PNG files.
- Preserve existing project naming when editing an established asset family, such as `settingsIcon`, `eye_open`, `mouth_smile`, or character-part names.
- Preserve source prefixes when the project already uses them, such as `ph-` for Phosphor assets or `noir-` for Iconoir assets.
- For custom symbols that already use dot-separated names, preserve that convention when appropriate.
- Remove export suffixes such as `copy`, `final`, `new`, `frame`, `group`, `layer`, dates, random IDs, or meaningless numbers.
- The `.imageset` name must match the name used in code and should usually match the internal image filename.

Examples:

- Bad: `icone_configuracao_final 2.svg`
- Good: `settings.svg` inside `settings.imageset`
- Bad: `Grupo 183.svg`
- Good: `sparkle.svg` inside `sparkle.imageset`

## 6. Contents.json

When creating a template SVG `.imageset`, keep the structure compatible with Xcode asset catalogs:

```json
{
  "images": [
    {
      "filename": "icon-name.svg",
      "idiom": "universal",
      "scale": "1x"
    },
    {
      "idiom": "universal",
      "scale": "2x"
    },
    {
      "idiom": "universal",
      "scale": "3x"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  },
  "properties": {
    "template-rendering-intent": "template"
  }
}
```

For raster or non-template artwork, match the nearby `Contents.json` pattern and only add template rendering when the asset must be tintable.

For `.symbolset` assets, follow an existing symbolset pattern or confirm the expected rendering behavior before adding one.

## 7. Code Integration

After adding the asset:

- use the final asset name in code without the file extension;
- update required mappings or enums if the icon is part of a picker, control set, or reusable icon registry;
- keep the asset name aligned with the visual/domain meaning, not with temporary wording from the request;
- do not replace existing icons without checking the in-app context and the intent of the change.

Avoid ambiguous names that can collide with SF Symbols when the intended output is a custom asset.

## 8. Final Checklist

- The interface icon is inside a `24 x 24` area.
- The artwork was scaled proportionally and centered without distortion.
- The asset is in the correct catalog folder.
- The name is English, ASCII, and consistent with project conventions.
- `Contents.json` matches the chosen asset type.
- Template rendering is configured when the app must edit/tint the icon color.
- The SVG artwork is compatible with color editing and does not accidentally lock the icon to a non-editable color.
- The name used in code exactly matches the asset name.
- No icon, folder, or file was left with a Portuguese name or raw export name.
