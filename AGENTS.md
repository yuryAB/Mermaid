# AGENTS.md

## Project Instructions

- Do not run builds automatically.
- Do not run final tests automatically.
- Make the requested changes and leave files ready for the user to verify.
- The user will run builds and tests manually.
- Lightweight checks that do not replace a build or test run, such as file reads, searches, `git diff --check`, and static inspections, may be used when they help validate an edit.
- If a task truly requires a build or test run for diagnosis, explain that to the user and wait for explicit confirmation before running it.

## Architecture And Ownership

- Do not place new feature flows, modal lifecycles, overlay state, rendering logic, or domain-specific UI behavior directly in `GameScene.swift`.
- `GameScene.swift` must stay an orchestration shell: route input, own scene-level wiring, and delegate feature work to dedicated systems/controllers.
- Every new gameplay/UI flow must have an owning file/type under `Ester/Game/`, such as `RegistroFlowController.swift`, `RegionSystem.swift`, or `ResourceSupportSystem.swift`.
- If a change needs scene-wide coordination, create a small coordinator/controller with explicit dependencies instead of adding broad state and lifecycle logic to `GameScene.swift`.
- Before adding logic to `GameScene.swift`, first search for the existing owner. If none exists, create one and keep `GameScene.swift` changes to construction, dependency injection, and one-line delegation.
- Do not hide feature state in unrelated systems or global helpers. State should live with its owner and expose narrow methods such as `open`, `close`, `update`, and `isOpen`.
- Modal overlays must be true modals: they block background input/update paths through their flow owner and must not rely on scattered guards across unrelated methods.
- When touching an existing messy area, move responsibility toward the correct owner instead of adding another special case in `GameScene.swift`.

## Knowledge Graph First

- Before any broad code search (scanning directories, grepping blindly, reading files one-by-one to understand structure), consult the project knowledge graph first via `/graphify query "<question>"`.
- Use the graph to locate the correct files, systems, components, or entities before touching code.
- Treat `graphify-out/graph.json` as the primary codebase map. Prefer graph traversal over raw file exploration.
- If no graph exists yet (`graphify-out/graph.json` is missing), the agent must create it immediately by running `/graphify` before doing any code exploration. Never start searching code blind when the graph can be built.
- Rebuild the graph with `/graphify` after significant refactors, new systems, renamed files, or any session that changed the codebase structure. The agent must proactively rebuild the graph at the end of such sessions — do not wait for the maintainer to ask.
- If only trivial or single-file edits were made (typo fix, small tweak), skip the rebuild.
- If `/graphify` is not available in the current environment, install it globally via `uv tool install graphifyy` so it becomes available for all projects using this harness. Do not skip graph queries just because the CLI is missing — install it first.

## Goal Mode Discipline

- When working in goal mode, define a concrete finish condition before doing open-ended exploration.
- Keep the work objective and bounded: identify the target outcome, make only the changes needed for that outcome, and stop when the condition is met.
- Do not loop indefinitely through repeated inspections, speculative refinements, or broad cleanup that is not required by the goal.
- If the goal becomes blocked, state the blocker clearly, explain what information or action is needed, and stop instead of continuing in circles.
- When the goal is complete, mark it complete and summarize the result, touched files, and any checks that were intentionally not run.

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
