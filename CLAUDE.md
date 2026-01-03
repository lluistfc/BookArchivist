# CLAUDE.md

## Overview
Book Archivist is a World of Warcraft® addon that records every "book" (anything rendered through the default `ItemTextFrame`) you read and lets you revisit them later in a custom UI. The addon watches `ITEM_TEXT_*` events, persists pages into a SavedVariables table (`BookArchivistDB`), and exposes a two-pane library UI with minimap + slash command entry points. Optional WoWUnit tests cover high-risk UI helpers.

## Repository tour
| Path | Purpose |
| --- | --- |
| `BookArchivist.toc` | Declares load order, SavedVariables, and slash-compartment metadata for the addon. |
| `core/BookArchivist.lua` | Bootstraps addon globals, wires WoW events, and surfaces high-level helpers (`RefreshUI`, `ToggleUI`, debug shims). |
| `core/BookArchivist_Core.lua` | Data engine: SavedVariables schema, key generation, ordering, and persistence helpers. |
| `core/BookArchivist_Capture.lua` | Translates ItemText events into capture sessions and streams them into the core module. |
| `core/BookArchivist_Location.lua` | Tracks player/loot provenance (zone chain, mob names) so saved books remember where they came from. |
| `core/BookArchivist_Minimap.lua` | Persists minimap button state (angle, registration) independent of UI code. |
| `ui/BookArchivist_UI.lua` | Shared UI state (selection, list mode, widget cache) plus Internal helper surface consumed by other UI modules. |
| `ui/BookArchivist_UI_Core.lua` | Binds List + Reader modules to Internal helpers, manages debug logging, and exposes safe execution wrappers. |
| `ui/BookArchivist_UI_Frame.lua` & `ui/BookArchivist_UI_Frame_Builder.lua` | Build and manage the main two-pane UI frame, wiring list + reader panes and frame behaviors. |
| `ui/list/*` | List pane modules: layout, filtering, location tree, and row management. |
| `ui/reader/*` | Reader pane modules: render metadata, HTML/plain text, and delete button behavior. |
| `ui/minimap/BookArchivist_UI_Minimap.lua` | Creates the physical minimap button, handles dragging/clicking, and defers persistence to `core/BookArchivist_Minimap.lua`. |
| `ui/options/BookArchivist_UI_Options.lua` | Settings panel, Blizzard Settings integration, and debug checkbox wiring. |
| `ui/BookArchivist_UI_Runtime.lua` | Runtime orchestration: `RefreshUI`, slash commands, UI creation on login, and safe refresh sequencing. |
| `tests/BookArchivist_Tests.lua` | WoWUnit suite currently validating the reader delete-button helper. |

## Runtime architecture
1. **Boot**: `core/BookArchivist.lua` registers for `ADDON_LOADED` and ItemText events. On load it ensures the DB, wires the minimap module, and configures the options UI.
2. **Capture**: `core/BookArchivist_Capture.lua` builds a session per open ItemText page and persists incrementally via `Core:PersistSession`, guaranteeing minimal data loss even if the panel closes unexpectedly.
3. **Location tagging**: `core/BookArchivist_Location.lua` listens to loot/mouseover context to attach zone chains and mob names, enabling location breadcrumbs inside the reader UI.
4. **SavedVariables schema** (`BookArchivistDB`):
   - `books[key]` — title, creator/author/material, timestamps, provenance, and a sparse `pages` table.
   - `order` — MRU list driving sidebar ordering.
   - `options` — `debugEnabled`, `minimapButton.angle`, future toggles.
5. **UI core**: `ui/BookArchivist_UI.lua` maintains the selected book, list filters, and widget registry exposed via `BookArchivist.UI.Internal`. Other UI modules import those helpers to avoid tight coupling.
6. **Main frame lifecycle**: `ui/BookArchivist_UI_Frame.lua` ensures the frame exists (via `Frame_Builder`), caches it in `Internal`, and keeps `needsRefresh` in sync so `BookArchivist.RefreshUI()` can throttle heavy rebuilds.
7. **List module**: `ui/list/BookArchivist_UI_List.lua` is context-driven; it expects callbacks (get/set selected key, safeCreateFrame, etc.) injected during `UI_Core` initialization, making the module test-friendly.
8. **Reader module**: `ui/reader/BookArchivist_UI_Reader.lua` reads from the selected key, handles HTML vs plain text rendering, prints metadata, and exposes test seams like `__ensureDeleteButton`.
9. **Minimap + slash commands**: `ui/minimap/BookArchivist_UI_Minimap.lua` drives the on-screen button, while `UI_Runtime` registers `/ba` and `/balist`, delegating to `BookArchivist.ToggleUI` or printing archive data.

### Data flow snapshot
- ItemText begins → `Capture:OnBegin` creates a session.
- Each `ITEM_TEXT_READY` → `Capture:OnReady` writes sanitized text to `BookArchivistDB` through `Core:PersistSession` and calls `BookArchivist.RefreshUI` to enqueue a visual refresh.
- `RefreshUI` flags `needsRefresh`, ensures UI exists (building if necessary), then `flushPendingRefresh` runs a safe pipeline: rebuild filtered list → rebuild location tree → update rows → render selected entry.

## Build & install
- **Interface version**: `110000` (The War Within launch patch). Confirm the `.toc` number before packaging for other game versions.
- **Installation**: copy the `BookArchivist` folder (containing `BookArchivist.toc`, `core/`, `ui/`, `tests/`) into `_retail_/Interface/AddOns/` (already structured here for local development).
- **Dependencies**: no hard externals. Optional: `WoWUnit` (shipped separately in this workspace) for running unit tests inside the client.
- **Debugging**: enable the "Enable debug logging" checkbox in the options panel (or `/run BookArchivist:EnableDebugLogging(true)`), which routes extra messages via `DEFAULT_CHAT_FRAME`.

## Testing
- **Framework**: [WoWUnit](https://github.com/Gethe/WoWUnit) (packaged locally under `../WoWUnit`). Tests run in-game or in a WoWUnit-capable harness because they rely on Blizzard UI widget APIs.
- **Current coverage**: `tests/BookArchivist_Tests.lua` validates the reader delete-button helper to ensure proper parenting/frame strata when recreated.
- **How to run**:
  1. Install/enable the WoWUnit addon alongside BookArchivist.
  2. Log in, load the character with both addons enabled.
  3. WoWUnit will execute suites automatically on `PLAYER_LOGIN`; open the WoWUnit UI (`/wu`) to see pass/fail results.
- **Extending tests**: follow the existing pattern—mock Blizzard frames/helpers, call into UI internals (e.g., `ReaderUI.__ensureDeleteButton`), and assert via WoWUnit helpers (`WoWUnit.AreEqual`, etc.).

## Common workflows
- **Adding a new capture heuristic**: extend `core/BookArchivist_Capture.lua` to enrich `session.source` (e.g., quest context), then update `Reader` metadata formatting to render the new fields.
- **Tweaking minimap behavior**: adjust UI-side interactions in `ui/minimap/BookArchivist_UI_Minimap.lua`; persistence should stay within `core/BookArchivist_Minimap.lua` to keep SavedVariables logic centralized.
- **UI changes**: modify layout builders (`ui/BookArchivist_UI_Frame_Builder.lua`, `ui/list/*`, `ui/reader/*`). Remember to update cached widgets via `rememberWidget` to avoid nil references when refreshing.
- **Options panel**: extend `ui/options/BookArchivist_UI_Options.lua`; call `OptionsUI:Sync()` after touching new SavedVariables to keep the checkbox states aligned.

## Debugging & troubleshooting
- **UI fails to open**: `/ba` prints "UI not initialized" if Blizzard frames aren’t ready (e.g., before entering the world). Wait for `PLAYER_LOGIN` or run `/reload`.
- **Refresh loops**: `Internal.flushPendingRefresh` logs verbose messages when debug logging is on; watch chat for "refreshAll" breadcrumbs to spot failing steps.
- **Missing minimap button**: ensure `BookArchivist.Core` was able to ensure the DB (SavedVariables not tainted). Run `/run BookArchivist.Minimap:Initialize()` to attempt a re-create.
- **SavedVariables corruption**: `Core:EnsureDB` is defensive; deleting `WTF/Account/<acct>/SavedVariables/BookArchivist.lua` resets the archive but keeps code intact.

## Conventions & gotchas
- **Global namespace**: Follows WoW addon norms—modules attach to the `BookArchivist` global. Keep new components under that table to avoid leaks.
- **Defensive coding**: Most functions guard against missing Blizzard APIs (nil-safe frames). Maintain those checks so automated tests (or non-WoW Lua runners) can execute without crashing.
- **UI creation**: Always use `Internal.safeCreateFrame` (or the context-injected equivalent) so template fallbacks and error logging remain consistent.
- **Key generation**: `Core` derives book keys from title/author/material/first-page text; altering the algorithm will orphan existing entries unless you provide a migration.
- **Location freshness**: Loot provenance expires after 6 hours (`MAX_LOOT_AGE`). If you extend contexts, adjust pruning windows accordingly.

## Roadmap ideas
- Add more WoWUnit suites around `ListUI` filtering to prevent regressions.
- Support exporting/importing archives (e.g., to a CSV or WeakAura message).
- Surface search facets (material, creator, zone) in the UI by reusing `Location` metadata.
- Consider a Dragonflight+ "Combined" settings panel via `Settings.RegisterAddOnCategory` so the options UI stays future-proof.
