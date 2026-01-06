# Changelog

All notable changes to this project are documented here.

## [1.0.3] - Unreleased

Changes since **v1.0.2** (tag `v1.0.2`) up to the current commit.

### Added

- **Database versioning and migrations**
  - Introduced a centralized DB initialization and migration pipeline:
    - `core/BookArchivist_DB.lua` initializes `BookArchivistDB` and applies versioned migrations.
    - `core/BookArchivist_Migrations.lua` manages `dbVersion` and performs the BookId v2 migration.
  - Added `core/BookArchivist_BookId.lua` to generate stable v2 book IDs and rewrite the legacy `books`/`order` structures into `booksById` with consistent keys.
  - Documented DB and BookId behavior in:
    - `docs/01-db-versioning-and-migration.md`
    - `docs/02-bookid-and-legacy-migration.md`

- **Favorites and virtual categories**
  - Implemented a per-book favorites system in `core/BookArchivist_Favorites.lua` that tracks `entry.isFavorite` on `booksById`.
  - Extended list UI to:
    - Show a star icon for favorite books in the list.
    - Filter favorites via quick filters and a virtual "Favorites" category.
  - Captured design details in `docs/03-favorites-and-virtual-categories.md`.

- **Recently read (MRU list)**
  - Added `core/BookArchivist_Recent.lua` to maintain a per-character MRU list of recently-read books (`BookArchivistDB.recent`).
  - Updated the reader and list UI to:
    - Track `lastReadAt` timestamps when a book is opened.
    - Expose a virtual "Recent" category in the sort/category dropdown.
  - Described behavior in `docs/04-recently-read.md`.

- **Tooltip integration**
  - Introduced `core/BookArchivist_Tooltip.lua` to integrate with GameTooltip and TooltipDataProcessor APIs.
  - Tooltips now show when a readable item/object/title has archived text for the current character.
  - Added configuration and documentation in `docs/05-tooltip-integration.md` and the options UI.

- **Search and index optimizations**
  - Improved search behavior and performance:
    - Core now builds and maintains a normalized `searchText` field per entry and uses it for queries.
    - Added title and item indexes to speed up lookups for search and tooltips (`indexes.titleToBookIds`, `indexes.itemToBookIds`).
  - Updated list UI to visually distinguish whether matches come from the title or content (badges column in rows).
  - Captured design in `docs/06-search-optimization.md`.

- **UI state persistence and resume reading**
  - Added per-character UI state in `BookArchivistDB.uiState`:
    - Stores last selected book ID and last selected virtual category.
    - Added an option to resume reading from the last page.
  - Updated the main header to include a "Resume last book" button that jumps back to the last opened book and page.
  - Documented this in `docs/07-ui-state-persistence.md`.

- **Export / import pipeline**
  - Added export helpers in `core/BookArchivist_Core.lua` to:
    - Build an export payload for the current character.
    - Serialize and encode it via `core/BookArchivist_Serialize.lua` and `core/BookArchivist_Base64.lua`.
  - Implemented an import worker in `core/BookArchivist_ImportWorker.lua` and corresponding UI wiring that:
    - Parses incoming payloads.
    - Merges books into `booksById` with conflict detection.
    - Reports counts of new vs merged entries.
  - Documented the flow in `docs/08-export-import.md`.

- **Options UI enhancements**
  - Extended `ui/options/BookArchivist_UI_Options.lua` to surface new settings for:
    - Favorites/virtual categories and the Recent view.
    - Tooltip visibility.
    - Search behavior and page size.
    - UI-state features like "resume last page".

- **Packaging and CI**
  - Updated `.gitattributes` to better control which files are included in release archives.
  - Reworked GitHub Actions workflows:
    - `.github/workflows/package.yml` now builds release zips and publishes stable/beta builds to CurseForge.
    - Removed redundant workflow files and large release assets to reduce addon package size.

### Changed

- **Core and capture behavior**
  - `core/BookArchivist_Core.lua` now delegates DB initialization to `core/BookArchivist_DB.lua` and assumes `booksById` as the primary store.
  - Capture and location modules were adjusted to work with BookId v2 and the new index structures while preserving legacy data.

- **List UI**
  - `ui/list/BookArchivist_UI_List.lua` gained:
    - Awareness of virtual categories (All, Favorites, Recent) and their interaction with sort modes.
    - Improved filter handling so favorites-only filters and virtual categories remain in sync.
  - `ui/list/BookArchivist_UI_List_Rows.lua` was updated to:
    - Render favorite stars.
    - Show search match badges (title vs content).
  - `ui/list/BookArchivist_UI_List_Filter.lua` and `ui/list/BookArchivist_UI_List_Layout.lua` were refined to support the new filters, pagination, and header layout while keeping the "Blizzard-ified" look.

- **Reader UI**
  - `ui/reader/BookArchivist_UI_Reader.lua` now tracks `lastReadAt` and updates recently-read state when a book is opened.
  - `ui/reader/BookArchivist_UI_Reader_Layout.lua` was added/extended to support new header controls and the resume-reading behavior.

- **Runtime and options wiring**
  - `ui/BookArchivist_UI_Runtime.lua` and `ui/options/BookArchivist_UI_Options.lua` were wired to the new Core helpers for favorites, recent, tooltip, search, and export/import.

### Fixed

- Maintained consistent behavior between the Books and Locations tabs when filtering by favorites, ensuring both views honor the same favorite state and filters.
- Cleaned up the DB initialization path so migrations run exactly once and do not spam debug logs.
- Ensured recently-read and favorites logic degrade gracefully when SavedVariables are missing or partially populated.

---

[1.0.3]: https://github.com/your-org/BookArchivist/releases/tag/v1.0.3

## [1.0.2] - 2026-01-05

Hotfix release on top of 1.0.1.

### Fixed

- Resolved a logout taint issue by avoiding problematic Blizzard popup/settings hooks when the addon is active.
- Cleaned up the GitHub Actions workflow configuration and permissions to ensure release artifacts are generated reliably.

---

## [1.0.1] - 2026-01-05

Localization and small fixes.

### Added

- Multi-language support for the main UI and messages:
  - Added locale files and strings for Italian, French, German, and Portuguese.

### Fixed

- Addressed issues where some texts were not updating correctly when switching languages or refreshing UI elements.
- Removed an undesired artifact from the repository and adjusted the release workflow to avoid similar issues.

---

## [1.0.0] - 2026-01-04

Initial public release of BookArchivist.

### Added

- Automatic capture of any “book” shown in the default ItemText frame into per-character SavedVariables.
- Two-pane library UI:
  - Left: searchable, paginated list of saved books and a Locations view.
  - Right: reader with metadata and page navigation.
- Rich HTML reader that preserves headings, spacing, and embedded images where possible.
- Location navigation mode and breadcrumbs for where books were read.
- Minimap button and options panel for configuring the addon.
- Delete button with confirmation for removing books from the archive.
- Basic GitHub Actions workflow to build and publish release zips.

---

[1.0.2]: https://github.com/your-org/BookArchivist/releases/tag/v1.0.2
[1.0.1]: https://github.com/your-org/BookArchivist/releases/tag/v1.0.1
[1.0.0]: https://github.com/your-org/BookArchivist/releases/tag/v1.0.0
