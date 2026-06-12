# AGENTS.md

## Project Instructions

- Do not run builds automatically.
- Do not run final tests automatically.
- Make the requested changes and leave files ready for the user to verify.
- The user will run builds and tests manually.
- Lightweight checks that do not replace a build or test run, such as file reads, searches, `git diff --check`, and static inspections, may be used when they help validate an edit.
- If a task truly requires a build or test run for diagnosis, explain that to the user and wait for explicit confirmation before running it.

## Icons And Assets

- Before adding, exporting, renaming, resizing, replacing, or organizing icons/assets, read and follow `docs/ICON_EXPORT_INSTRUCTIONS.md`.
- Before replacing an existing icon, inspect the exact app context and preserve the visual language of that flow.
- If the current asset looks ambiguous, inconsistent, or affected by a naming conflict, inspect local assets and git history before replacing it.
- Do not invent or swap icons without this verification.

## Sound Effects

- When the user asks for game sound effects, use the local Freesound helper at `Tools/freesound.cjs`.
- Do not reference or depend on files from any other project for this workflow.
- Do not generate synthetic placeholder SFX, generic beeps, or invented audio unless the user explicitly asks.
- Use Freesound preview files for fast SFX selection; original-quality Freesound downloads require OAuth2, while this helper uses token-authenticated search and preview downloads.
- To use the helper, create a Freesound API key at `https://freesound.org/apiv2/apply`, then set `FREESOUND_API_KEY` in `.env.local` or in the shell environment.
- Search with commands like `node Tools/freesound.cjs search "underwater bubble pop" --page-size 8 --duration-max 1.2 --license cc0-or-attribution`.
- Download a search result with commands like `node Tools/freesound.cjs pick "soft water swish" --index 0 --out Ester/Audio/water-swish`.
- Download a known sound id with commands like `node Tools/freesound.cjs download 123456 --out Ester/Audio/shell-click`.
- Store downloaded SFX in `Ester/Audio/` unless the app structure later establishes a more specific audio folder.
- Keep the generated `.freesound.json` sidecar beside each downloaded audio file for attribution and license review.
- Before using SFX in the game, review the license in the `.freesound.json`; prefer `Creative Commons 0` when possible, and use `Attribution` only when attribution can be preserved.
- Use descriptive, stable file names such as `bubble-pop.mp3`, `shell-click.mp3`, `soft-chime.mp3`, and `water-swish.mp3`.
- When adding audio to the app, ensure the file is included in the correct Xcode target and playback uses the appropriate native API, such as `AVAudioPlayer`, `SKAction.playSoundFileNamed`, or an existing project helper.
- Do not run builds or final tests automatically after adding SFX; leave files ready for manual verification.
