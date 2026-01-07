# BookArchivist Cleanup + Refactor Plan (Interface 110000)

This plan MUST be implemented against the current addon codebase (BookArchivist_final.zip). Use the existing UI behavior shown in the provided screenshots as the functional reference (main UI, reader, locations navigation, options import, debug grid).

---

## 0) Update repo guidance (Copilot instructions + docs)

### 0.1 Update `.github/copilot-instructions.md`
**Change rule**: AceGUI MultiLineEditBox is allowed for:
- Options → Import textarea (already allowed)
- Options → Debug Log widget textarea (NEW requirement)

**Explicitly disallow**: any other Ace3/AceGUI usage (no AceEvent/AceConsole/AceConfigRegistry; no AceGUI for general UI).

Add a short section stating:
- “Allowed AceGUI widgets: MultiLineEditBox for Import and Debug Log only.”
- “All other UI uses native CreateFrame + Blizzard templates.”

### 0.2 Update `README.md`
- Ensure architecture mentions `ui/reader/BookArchivist_UI_Reader_Share.lua` as the canonical place for share logic.
- Keep README consistent with actual file paths after extraction.

---

## 1) Remove deprecated Blizzard Options API usage (Settings-only)

**Target file**: `ui/options/BookArchivist_UI_Options.lua`

### 1.1 Remove legacy registration
- Delete any usage of:
  - `InterfaceOptions_AddCategory(panel)`

### 1.2 Remove legacy open fallback
- In `OptionsUI:Open()` remove fallback:
  - `InterfaceOptionsFrame_OpenToCategory(panel)`

### 1.3 Keep only modern Settings API
- Ensure:
  - `Settings.RegisterCanvasLayoutCategory(...)` (or Vertical layout) is used
  - `Settings.RegisterAddOnCategory(category)` is used
  - `Settings.OpenToCategory(category:GetID())` (or equivalent working call) is used to open

**Acceptance**:
- Options appear in the modern Settings UI under AddOns.
- Opening options never touches InterfaceOptions APIs.

---

## 2) Merge “Enable debug logging” + “Debug mode” into one option

**Goal**: one toggle in options replaces two toggles:
- “Enable debug logging”
- “Debug mode”

### 2.1 Decide new single setting key/name
Use a single boolean in DB, e.g.:
- `debug.enabled` OR `debugMode` (pick one and apply consistently).

### 2.2 Update options UI layout
**Target file**: `ui/options/BookArchivist_UI_Options.lua`
- Remove one checkbox entirely.
- Rename the remaining checkbox label to something clear, e.g.:
  - “Debug mode (logging + UI helpers)”
- Any code that previously referenced the removed option must be updated to reference the new single option.

### 2.3 Update behavior mapping
When the single debug toggle is ON, it should:
- enable debug logging (whatever currently gates `debugPrint` / verbose logging)
- enable debug mode (whatever currently gates extra debug behavior)

When OFF:
- both behaviors are OFF.

### 2.4 Backward compatibility (SavedVariables migration)
If old settings exist (e.g. `enableDebugLogging` and `debugMode`):
- On load/migration, compute the new single flag as:
  - `newDebugEnabled = oldEnableDebugLogging OR oldDebugMode`
- Remove/ignore the old keys after migration (do not keep two sources of truth).

**Acceptance**:
- Only one checkbox exists.
- Toggling it reproduces the combined effect of the two old toggles.
- Existing users with either old toggle ON get the new toggle ON after upgrade.

---

## 3) Ensure MultiLineEditBox is used for BOTH Import and Debug Log widgets

**Target file**: `ui/options/BookArchivist_UI_Options.lua`

### 3.1 Import widget (keep / ensure)
- Continue using AceGUI `MultiLineEditBox` for Import if AceGUI is available.
- Keep the native fallback (ScrollFrame+EditBox) if AceGUI is missing.

### 3.2 Debug Log widget (REQUIRED)
- The debug widget MUST also use AceGUI `MultiLineEditBox` (same approach as Import):
  - If AceGUI available: create `AceGUI:Create("MultiLineEditBox")` and embed it.
  - If AceGUI missing: fallback to native `ScrollFrame+EditBox`.

### 3.3 Fix existing scope bug in debug logging
Currently, `debugPrint()` calls `AppendDebugLog(...)` which is not in scope (local inside widget function).
Fix by:
- Storing an append function on a stable object, e.g. `optionsPanel.AppendDebugLog = function(text) ... end`
- In `debugPrint()`, call:
  - `if optionsPanel and optionsPanel.AppendDebugLog then optionsPanel.AppendDebugLog(message) end`
- Never call `AppendDebugLog` as a free symbol.

**Acceptance**:
- Debug Log area appears in options and is editable/scrollable like Import.
- No Lua errors when debug logging tries to append.
- Works with and without AceGUI present.

---

## 4) Extract Share feature into `ui/reader/BookArchivist_UI_Reader_Share.lua`

### 4.1 Create new file
Create:
- `ui/reader/BookArchivist_UI_Reader_Share.lua`

This file MUST encapsulate all share-related UI + logic, including:
- Share popup frame creation (BackdropTemplate, title, close button, etc.)
- Export string generation / composition for sharing (if currently in reader)
- Copy/paste helper text box (likely MultiLineEditBox-like behavior if needed; native is fine here unless you intentionally reuse import widget patterns)
- The public API the reader uses to trigger sharing

### 4.2 Define a stable module API
In `BookArchivist_UI_Reader_Share.lua`, expose functions like:
- `BookArchivist_ReaderShare:Init(parentFrame, getStateFn)` or similar
- `BookArchivist_ReaderShare:Show(book)` (or `ShowForBook(bookId)`)

Keep API minimal and explicit. It should:
- Accept the currently selected book data (title, pages/content, metadata, location).
- Render the popup and populate the share text.

### 4.3 Update reader to delegate share behavior
**Targets**:
- `ui/reader/BookArchivist_UI_Reader.lua`
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` (already creates share button)

Actions:
- Remove inlined share popup creation/logic from `BookArchivist_UI_Reader.lua` (if any).
- Require/load the new share module and initialize it during reader init.
- In share button click handler:
  - call the share module (e.g. `ReaderShare:Show(currentBook)`).

### 4.4 Keep UI behavior consistent with screenshots
Share button location is already implemented in layout (header area near Favorite/Delete).
Ensure:
- Share button is disabled when no book selected
- enabled when a book is loaded
- clicking opens the share popup reliably
- popup does not break page nav or selection

**Acceptance**:
- No share logic remains in `BookArchivist_UI_Reader.lua` besides calling the share module.
- New file contains all share UI code.
- Share popup works and is reachable from reader header.

---

## 5) Optional (deferred) modernization items (do NOT block core changes)
These are legacy but can remain until later:
- `UIDropDownMenu*` usage (sorting/pagination/language)
- `PanelTemplates_*` tab usage

Do not refactor these in the same change set unless necessary; focus on the required items above.

---

## Implementation order (to minimize regressions)
1) Update `.github/copilot-instructions.md` (allow MultiLineEditBox for debug widget too).
2) Implement Settings-only options (remove InterfaceOptions fallbacks).
3) Merge debug options into a single setting + migration.
4) Ensure Debug Log widget uses MultiLineEditBox + fix debug append scope bug.
5) Create `ui/reader/BookArchivist_UI_Reader_Share.lua` and extract share logic; update reader to use it.
6) Update README to reflect new file/module.

---

## Verification checklist
- Options panel loads via Settings only (no InterfaceOptions calls).
- Only one debug toggle exists; old settings migrate correctly.
- Debug Log widget uses MultiLineEditBox and appends without errors.
- Share popup code lives exclusively in `ui/reader/BookArchivist_UI_Reader_Share.lua`.
- Share button works and is enabled/disabled correctly.
- No new Lua errors while browsing books, switching locations, importing, or sharing.
