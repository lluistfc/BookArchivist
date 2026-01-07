#!BookArchivist/.github/copilot-instructions.md
# Copilot Instructions — BookArchivist (WoW Addon)

These instructions are repository-wide. Follow them unless the user explicitly overrides.

---

## Prime directive

### UI work
**When working on the main BookArchivist window UI, use native WoW CreateFrame with Blizzard templates.**
- The main UI is built with **native frames** using `CreateFrame(...)` and standard templates:
  - `InsetFrameTemplate3` for panel containers
  - `UIPanelButtonTemplate` for buttons
  - `UIPanelScrollFrameTemplate` for scroll areas
  - `BackdropTemplate` for modal dialogs
  - `SimpleHTML` frames for rich text rendering
- **AceGUI-3.0** is used **only** for `MultiLineEditBox` widgets in the Options/Import panel (for handling large paste operations)
- Use the `safeCreateFrame` helper functions that wrap `CreateFrame` with error handling
- Follow the established pattern of separating layout modules (`*_Layout.lua`) from behavior modules (`*.lua`)

### Layout goal
Rebuild (and keep) the **same structure and spatial relationships as the “old UI screenshots”**:
- Global top bar across the full width
- Left inset: tabs + list + footer
- Right inset: header + nav + content (+ status)
- Clear split between left/right panels
- No controls “floating” outside their row/panel

If changes do not preserve this structure, they are incorrect even if “visually acceptable”.

---

## Repository overview (stable runtime flow)

### Core runtime
- **Capture**: `core/BookArchivist_Capture.lua`
  - ItemText begin → start session
  - each text page → sanitize, persist
  - triggers UI refresh after capture updates
- **Persistence**: `core/BookArchivist_DB.lua` (and helpers)
- **Favorites**: `core/BookArchivist_Favorites.lua`
- **Recent**: `core/BookArchivist_Recent.lua`
- **Tooltip tag**: `core/BookArchivist_Tooltip.lua`
- **Import pipeline**: `core/BookArchivist_ImportWorker.lua`
  - staged phases (decode/parse/merge/search/titles) surfaced to Options UI
- **Event handling**: Vanilla WoW event frame with `OnEvent` script in `core/BookArchivist.lua`
- **Slash commands**: Native `SlashCmdList` registration in `ui/BookArchivist_UI_Runtime.lua`

### UI modules (expected separation of concerns)
- `ui/BookArchivist_UI.lua` / `ui/BookArchivist_UI_Core.lua`
  - shared UI state (selection, mode, filters), safe refresh pipeline
  - `safeCreateFrame` helpers for error-safe frame creation
- `ui/BookArchivist_UI_Frame_Layout.lua`
  - main window layout with native frames (header, body, left/right insets, splitter)
- `ui/options/BookArchivist_UI_Options.lua`
  - Blizzard Options page and Import UI (uses AceGUI MultiLineEditBox for text parsing)
- `ui/list/*`
  - left panel behaviour (books/locations mode, list interactions)
- `ui/reader/*`
  - right panel behaviour (header actions, navigation, content)
  - uses native frames with `SimpleHTML` for rich text

---

## Current known pitfalls (must not regress)

### 1) WoW EditBox paste quirks
- EditBox paste escapes `|` as `||`. If you read pasted text, normalize with `gsub("||","|")`.
- Large paste can be slow; avoid doing heavy work inside `OnTextChanged` without throttling.
- Use AceGUI MultiLineEditBox for large paste operations (import/export panels) - it handles these quirks better.

### 2) List performance
When rendering many books:
- implement pooling/virtualization (reuse row widgets, render visible range)
- never create thousands of frame rows

### 3) Frame anchoring
- Use explicit anchor points and offsets for layout
- When using `InsetFrameTemplate3`, account for the inset's border thickness
- Test layout with `/framestack` to verify anchor relationships

---

## Localization rules

- All user-visible strings must come from `BookArchivist.L` (see `core/BookArchivist_Locale.lua` and `locales/*`).
- **Do not hardcode English strings** in UI modules.
- If you add/rename a localization key, you must update **all locale files** (enUS, esES, caES, frFR, deDE, itIT, ptBR).
- If keys become unused, keep them for compatibility but mark them as deprecated in comments or remove only if you also remove all code paths and verify.

---

## How to validate changes (required)
1) Open main window; compare against the provided “old UI” screenshots:
   - top bar spans full width
   - tabs sit inside left panel
   - reader actions are in right header row (not stacked)
   - prev/page/next are in a nav row (not under delete/share)
2) Switch Books ↔ Locations modes:
   - list updates correctly, selection and breadcrumbs behave
3) Options → Import:
   - paste payload; phase status updates; import completes or errors cleanly
4) Reload UI (`/reload`) and reopen:
   - no nil errors, no taint, no runaway OnUpdate loops

---

## Coding conventions
- Prefer small functions; avoid deep nesting.
- Never swallow errors silently; log via `BookArchivist:LogError(...)` when available.
- Avoid global state unless it’s an addon singleton (`BookArchivist`, `BookArchivistDB`).
- Keep UI state changes in presenter/controller modules rather than inside widget constructors.

---
