# Copilot Instructions — BookArchivist (WoW Addon)

These instructions are repository-wide. Follow them for all changes unless the user explicitly overrides.

---

## Project overview

BookArchivist is a World of Warcraft addon that records every “book” (anything rendered through the default `ItemTextFrame`) the player reads and lets them revisit it later in a custom two-pane library UI. It listens to `ITEM_TEXT_*` events, captures pages, stores them in `BookArchivistDB` (SavedVariables), and exposes a main UI with list + reader panes plus minimap + slash command entry points. :contentReference[oaicite:0]{index=0}

Key runtime flow:
- ItemText begins → `Capture:OnBegin` starts a session.
- Each `ITEM_TEXT_READY` → `Capture:OnReady` sanitizes & persists page text through `Core:PersistSession`, then calls `BookArchivist.RefreshUI()` to enqueue a UI refresh.
- `RefreshUI` ensures UI exists and runs a safe refresh pipeline: rebuild filtered list → rebuild location tree → update rows → render selected entry. :contentReference[oaicite:1]{index=1}

---

## Repository map (where to change what)

- `BookArchivist.toc` — load order, SavedVariables declaration, and addon metadata (version, title, notes). :contentReference[oaicite:2]{index=2}
- `core/BookArchivist.lua` — addon bootstrap, event wiring, high-level helpers (`RefreshUI`, `ToggleUI`).
- `core/BookArchivist_DB.lua` — DB initialization entrypoint; runs migrations and ensures `BookArchivistDB` has a current `dbVersion`.
- `core/BookArchivist_Migrations.lua` — centralized `BookArchivistDB` migration dispatcher (BookId v2, legacy snapshot, index backfill).
- `core/BookArchivist_BookId.lua` — stable book ID generation helpers (v2 IDs used by `booksById`).
- `core/BookArchivist_Core.lua` — SavedVariables schema defaults, keying, ordering, list options, search-text caching, export/import helpers.
- `core/BookArchivist_Capture.lua` — ItemText capture sessions, incremental persistence.
- `core/BookArchivist_Favorites.lua` — per-book favorite state on top of `booksById` (used by virtual categories and stars in UI).
- `core/BookArchivist_Recent.lua` — per-character MRU of recently read books (`recent.list`, `lastReadAt`).
- `core/BookArchivist_Tooltip.lua` — GameTooltip integration; shows when an item/object/title has archived text for the current character.
- `core/BookArchivist_Location.lua` — provenance (zone chain, mob names) for breadcrumbs.
- `core/BookArchivist_Minimap.lua` — minimap persistence (angle/state) centralized here.
- `core/BookArchivist_Locale.lua` — locale selection, fallback, and `BookArchivist.L` dispatcher (uses dictionaries from `locales/`).
- `core/BookArchivist_Base64.lua` — Base64 helpers used by export/import.
- `core/BookArchivist_Serialize.lua` — table serialization helpers used by export/import.
- `core/BookArchivist_ImportWorker.lua` — staged import pipeline (parse, merge, finalize) used by Core’s import helpers.
- `ui/BookArchivist_UI.lua` — shared UI state & `BookArchivist.UI.Internal` helpers (selection, list mode, widget registry).
- `ui/BookArchivist_UI_Core.lua` — binds list + reader modules to injected helpers; safe wrappers/logging.
- `ui/BookArchivist_UI_Frame_Layout.lua` + `ui/BookArchivist_UI_Frame_Chrome.lua` — frame body layout/splitter and frame chrome (dragging, portrait, title, options).
- `ui/BookArchivist_UI_Frame_Builder.lua` — thin orchestrator that wires `Frame` helpers together.
- `ui/BookArchivist_UI_Frame.lua` — top-level frame entry that calls into the builder.
- `ui/BookArchivist_UI_Runtime.lua` — orchestration, `/ba` commands, safe refresh sequencing.
- `ui/list/BookArchivist_UI_List.lua` — list controller, modes, wiring into Internal selection.
- `ui/list/BookArchivist_UI_List_Layout.lua` — list header/search/pagination/scroll layout.
- `ui/list/BookArchivist_UI_List_Tabs.lua` — list `Books/Locations` tabs, tab parent/rail helpers.
- `ui/list/BookArchivist_UI_List_Filter.lua` — filter state and controls.
- `ui/list/BookArchivist_UI_List_Location.lua` — location tree mode and rows.
- `ui/list/BookArchivist_UI_List_Rows.lua` — row creation, pooling, and update.
- `ui/reader/BookArchivist_UI_Reader.lua` — reader controller: selection, metadata lines, render pipeline choice.
- `ui/reader/BookArchivist_UI_Reader_HTML.lua` — shared HTML detection/stripping/normalization helpers.
- `ui/reader/BookArchivist_UI_Reader_ArtifactAtlas.lua` — local artifact book atlas data and lookup.
- `ui/reader/BookArchivist_UI_Reader_Rich_Parse.lua` — HTML → block parsing for the rich renderer.
- `ui/reader/BookArchivist_UI_Reader_Rich.lua` — rich reader: block layout engine and pools.
- `ui/reader/BookArchivist_UI_Reader_Delete.lua` — delete button behavior and confirmation flow.
- `ui/reader/BookArchivist_UI_Reader_Layout.lua` — reader header/nav/scroll/text layout.
- `ui/minimap/*` — minimap button UI (persistence stays in core minimap module).
- `ui/options/*` — Settings panel + Blizzard Settings integration (favorites, recent, tooltip, search, UI state). :contentReference[oaicite:3]{index=3}
- `locales/BookArchivist_Locale_*.lua` — per-locale translation dictionaries keyed by game locale tag (e.g. `enUS`, `esES`, `caES`).
 - `docs/*.md` — internal design notes for DB versioning, BookId v2, favorites/virtual categories, recently-read, tooltip integration, search optimization, UI state, export/import, and list modularization.

---

## Non-negotiable conventions

### Global namespace
- Use the `BookArchivist` global table for modules; avoid leaking new globals. :contentReference[oaicite:4]{index=4}

### Defensive coding
- Guard against missing Blizzard APIs / nil frames.
- Keep code test-friendly (some modules rely on injected callbacks and safe wrappers). :contentReference[oaicite:5]{index=5}

### UI creation
- Always use `Internal.safeCreateFrame` (or injected equivalents) when creating frames/templates.
- Use `rememberWidget` / widget cache patterns to avoid nil refs during refreshes. :contentReference[oaicite:6]{index=6}

### Refresh pipeline
- Avoid full rebuilds on small changes.
- Prefer flags (`needsListRefresh`, `needsReaderRefresh`, etc.) and a single flush that runs only necessary steps.

---

## UI layout rules (current direction)

The UI is being aligned and “Blizzard-ified”. Do not anchor ad-hoc directly to the main frame when there is a row/container to anchor to.

### Layout grid and metrics
- Define UI spacing constants once (e.g., `UI_METRICS`) and use them everywhere.
- No magic numbers in `SetPoint` offsets unless there is a template quirk that demands it.

Recommended constants (use/extend existing):
- `PAD_OUTER`, `PAD_INSET`
- `GAP_XS`, `GAP_S`, `GAP_M`, `GAP_L`
- `HEADER_H`, `LIST_HEADER_H`, `ROW_H`, `BTN_H`
- `SCROLLBAR_GUTTER`

### Header placement (avoid collisions)
- Header must be split into explicit blocks:
  - Left block (title, count)
  - Center block (search)
  - Right block (`HeaderRightBlock`) reserved width for:
    - Help/Options
    - filter icon buttons (“Show only …”)
- Search box must be constrained between left and right blocks; never underlays right-side controls.

### List header & tabs placement (avoid overlap with separator)
- “Saved Books” and `Books/Locations` tabs must share the same header row (`ListHeaderRow`).
- Tabs must live inside a `TabsRail` that is inset from the list’s right edge / separator by at least `PAD_INSET`.
- Separator/splitter must not visually intersect the tabs row.

### List rows padding + scrollbar safety
- Rows must have consistent left/right padding.
- Row text must not render under the scrollbar:
  - Use a `RowContent` child frame with `BOTTOMRIGHT` inset by `SCROLLBAR_GUTTER`.
- Selection highlight textures must be inset and never clip the inset borders.

### Reader header controls
- Reader controls (Delete/Next/Prev/Page label) must stay in `ReaderHeader` (and optional `ReaderNavRow`), never floating inside scroll content.
- If needed, use `ReaderActionsRail` to align right-side buttons cleanly.

---

## SavedVariables and migrations

- `BookArchivistDB` now uses `dbVersion` for schema migrations and `version` as a legacy marker; do not overload these.
- DB initialization flows through `core/BookArchivist_DB.lua`, which calls into `BookArchivist.Migrations` to apply `v1`, `v2`, etc. Keep new migrations additive and idempotent.
- `core/BookArchivist_Migrations.lua` owns the BookId v2 migration: it snapshots legacy `books`/`order`, builds `booksById` with stable IDs, rewrites `order`, and backfills basic indexes.
- `Core` key generation and schema changes can orphan existing entries. If you change keying or schema, add an explicit migration (or compatibility shim) instead of mutating `BookArchivistDB` ad-hoc. :contentReference[oaicite:7]{index=7}
- Keep minimap persistence in `core/BookArchivist_Minimap.lua`.
 - Per-book reading state such as `lastPageNum` and `lastReadAt` should live on `booksById[bookId]` entries and be treated as optional, non-breaking data.
- Favorites state (`isFavorite`) is per-book and lives on `booksById[bookId]`; use `core/BookArchivist_Favorites.lua` helpers instead of rolling your own.
- Recently-read (`BookArchivistDB.recent`) is managed by `core/BookArchivist_Recent.lua`; treat it as an MRU cache that can be safely rebuilt.
- Tooltip-related indexes (`indexes.itemToBookIds`, `indexes.titleToBookIds`, `indexes.objectToBookId`) must remain in sync with `booksById`. Prefer calling Core helpers that already backfill/maintain these when adding new entries.
- UI state such as `uiState.lastBookId` and `uiState.lastCategoryId` is per-character and optional; changes here should be non-breaking and default-safe.

---

## Packaging / release expectations (CurseForge-compatible zip)

Repo root contains `BookArchivist.toc` and the addon code, but the published zip must contain a top-level folder:
- `BookArchivist/BookArchivist.toc`
- `BookArchivist/core/...`
- `BookArchivist/ui/...`

Automation:
- Use GitHub Actions + `git archive --prefix="BookArchivist/" ...`
- Exclude docs from packaged builds using `.gitattributes`:
  - `*.md export-ignore`
  - (optionally) `.github/ export-ignore`, `.gitignore export-ignore`

Important:
- GitHub Actions workflows must live under `.github/workflows/` (plural).

Release discipline:
- When cutting a new release tag (e.g., `v1.0.3`), always:
  - Update `CHANGELOG.md` with a section for that version, summarizing changes since the previous tag.
  - Update `README.md` if user-facing behavior, features, or usage have changed.
  - Only bump the version in `BookArchivist.toc` once the changelog and README are accurate and you intend to publish a build.
  - Generate a `CURSE_FORGE_RELEASE_CHANGELOG` file in the repo root with a short, non-technical summary of the changes in that version, suitable for display on the addon’s public CurseForge page.

---

## How to make changes

When implementing UI changes:
1. Identify the right module (`Frame_Builder`, `ui/list/*`, `ui/reader/*`).
2. Apply layout changes by adjusting container frames first (header rows/rails), then children.
3. Keep refresh logic minimal: only rebuild the sections affected.
4. Validate visually at different UI scales; ensure no overlaps with separator, scrollbars, or adjacent controls.
5. If you introduce new options, wire them through `ui/options/*` and call `OptionsUI:Sync()` after updating saved values. :contentReference[oaicite:8]{index=8}

---

## Maintain this file

If you make significant changes, update `.github/copilot-instructions.md` in the same PR/commit.

“Significant changes” includes:
- New folders/modules or major file moves/renames.
- Changes to `BookArchivistDB` schema, key generation, ordering logic, or migrations.
- Changes to refresh pipeline architecture or injected UI module contracts.
- Major UI layout architecture changes (new header blocks/rails, new metrics scheme).
- Changes to packaging/release automation or required zip structure.
 - Any feature work that would meaningfully change how contributors should navigate the repo (new core modules, new UI subsystems, new long-lived docs like design notes or migration guides).

Update process:
- Keep instructions concise.
- Add/adjust only what’s needed for Copilot to make correct future edits.
- Prefer adding a small bullet under the relevant section rather than expanding prose.

---
