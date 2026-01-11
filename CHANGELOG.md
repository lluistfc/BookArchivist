# Changelog

All notable changes to this project are documented here.

## [2.1.0-beta] - 2026-01-11

**Infrastructure and quality improvements release (internal improvements for development)**

### Added

- **Testing Infrastructure**
  - Comprehensive test suite with 200 automated tests (execution time: 4.19 seconds)
  - Test categories: Sandbox (6 tests), Desktop (5 tests), InGame (3 tests)
  - Implemented Repository pattern with dependency injection for test isolation
  - Added catastrophic failure protection ensuring production database is always restored
  - Test runners for Windows (PowerShell) and Unix/macOS (Bash)

- **Development Tooling**
  - Integrated Mechanic CLI for addon development automation
  - Cross-platform Makefile build system with 20+ targets:
    - Validation: `make validate`, `make lint`, `make verify`, `make warnings`
    - Testing: `make test`, `make test-errors`, `make test-detailed`, `make test-pattern`
    - Mechanic: `make output`, `make sync`, `make link`, `make unlink`
    - Dashboard: `make run`, `make stop` (with duplicate detection)
    - Release: `make release/alpha/beta TAG=x.x.x`
  - Platform-specific setup scripts: `scripts/setup-mechanic.ps1` (Windows), `scripts/setup-mechanic.sh` (Unix)
  - Smart Mechanic CLI path detection (system PATH → local venv fallback)

- **Continuous Integration**
  - GitHub Actions CI/CD pipeline with multi-platform testing (Ubuntu, Windows, macOS)
  - Automated test execution on every push and pull request
  - Uses community-maintained GitHub Actions for Lua and LuaRocks

- **Code Quality**
  - Enforced Test-Driven Development (TDD) practices in development guidelines
  - Zero lint errors, all 77 files validated
  - Comprehensive documentation: AGENTS.md, tests/README.md, DEV_SETUP.md

- **Production Build**
  - Cleaned production packages to 97 files (down from 200+)
  - Enhanced `.pkgmeta` and `.gitattributes` exclusions (dev/, tests/, scripts/, docs/)
  - Proper handling of CurseForge release changelog

### Changed

- **Core Architecture**
  - Implemented Repository pattern for database access (`BookArchivist.Repository:GetDB()`)
  - All modules now use dependency injection for database access
  - Production database restoration happens once after all tests complete (even on catastrophic failures)

- **Project Organization**
  - Moved test runners from `Tests/` to `scripts/` folder
  - Reorganized documentation with consolidated testing guide
  - Updated all 7 locale files with consistent structure

### Developer Notes

*This is an infrastructure release focused on improving development workflow, code quality, and testing reliability. All changes are internal improvements with no user-facing feature changes or bug fixes. Users who have opted into beta releases on CurseForge will see this update, but it will not affect gameplay or addon functionality.*

*Key metrics: 200/200 tests passing, 0 lint errors, 2860 style warnings (conventions), 77 files validated, Interface version 120001 (The War Within).*

## [2.0.3] - 2026-01-10

**Enhancement release**

### Added

- Added confirmation dialogs for chat link imports showing book title on success and error details on failure (previously only visible in debug logs)

### Changed

- Excluded README.md from release packages (GitHub-only documentation)

## [2.0.2] - 2026-01-10

**Bug fix release**

### Fixed

- **Search/Filter Issues**
  - Fixed search getting stuck on "Filtering books..." after searching for text with no results
  - Iterator operations now properly cancel before starting new ones to prevent collision errors
  - Empty search results now correctly rebuild filtered list when search is cleared

- **Options Panel Issues**
  - Fixed tooltip checkbox showing incorrect state after reopening settings panel (schema mismatch: Core expected `options.tooltip.enabled` but UI was using `options.tooltip` directly)
  - Fixed language change reload dialog appearing when clicking any checkbox (now only shows on actual language changes)
  - Fixed language dropdown not updating addon UI (invalid "auto" default value, missing validation for saved values, callback not firing for dropdowns)
  - Fixed options panel labels not updating when language changes (Blizzard Settings API caches labels - added reload confirmation dialog in new language)

- **Code Quality**
  - Fixed duplicate `Delete` function definition that was breaking book deletion (second definition was actually `IsTooltipEnabled`)
  - Fixed locale key misuse causing English fallbacks in non-English clients (`LOCATION_UNKNOWN_ZONE` and `LOCATION_UNKNOWN_MOB` were referenced as literal strings)
  - Fixed DevTools guard referencing non-existent `InitDebugGrid` function

### Removed

- Removed ~510 lines of dead code across 17 files (unused functions, legacy frame builders, informational getters)
- Removed unused locale keys (`SEARCH_MATCH_TITLE`, `SEARCH_MATCH_CONTENT`)

## [2.0.1] - 2026-01-10

**Hotfix release**

### Fixed

- Fixed critical production mode error: `IsDebugEnabled` method not available causing addon to fail on load
- Fixed stack overflow from circular dependency during database initialization (DebugPrint → IsDebugEnabled → GetOptions → EnsureDB → Init → DebugPrint)
- Added initialization guard to prevent debug calls from triggering DB access during DB setup

## [2.0.0] - 2026-01-10

**Major version release with breaking database changes.** This version includes automatic migration from v1.0.2, but **you cannot downgrade** after upgrading. Your data will be preserved during the upgrade.

### Added

- **Database versioning and migrations**
  - Introduced a centralized DB initialization and migration pipeline:
    - `core/BookArchivist_DB.lua` initializes `BookArchivistDB` and applies versioned migrations.
    - `core/BookArchivist_Migrations.lua` manages `dbVersion` and performs the BookId v2 migration.
  - Added `core/BookArchivist_BookId.lua` to generate stable v2 book IDs and rewrite the legacy `books`/`order` structures into `booksById` with consistent keys.

- **Favorites and virtual categories**
  - Implemented a per-book favorites system in `core/BookArchivist_Favorites.lua` that tracks `entry.isFavorite` on `booksById`.
  - Extended list UI to:
    - Show a star icon for favorite books in the list.
    - Filter favorites via quick filters and a virtual "Favorites" category.

- **Recently read (MRU list)**
  - Added `core/BookArchivist_Recent.lua` to maintain a per-character MRU list of recently-read books (`BookArchivistDB.recent`).
  - Updated the reader and list UI to:
    - Track `lastReadAt` timestamps when a book is opened.
    - Expose a virtual "Recent" category in the sort/category dropdown.

- **Tooltip integration**
  - Introduced `core/BookArchivist_Tooltip.lua` to integrate with GameTooltip and TooltipDataProcessor APIs.
  - Tooltips now show when a readable item/object/title has archived text for the current character.

- **Search and index optimizations**
  - Improved search behavior and performance:
    - Core now builds and maintains a normalized `searchText` field per entry and uses it for queries.
    - Added title and item indexes to speed up lookups for search and tooltips (`indexes.titleToBookIds`, `indexes.itemToBookIds`).
  - Updated list UI to visually distinguish whether matches come from the title or content (badges column in rows).

- **UI state persistence and resume reading**
  - Added per-character UI state in `BookArchivistDB.uiState`:
    - Stores last selected book ID and last selected virtual category.
    - Added an option to resume reading from the last page.
  - Updated the main header to include a "Resume last book" button that jumps back to the last opened book and page.

- **Export / import pipeline**
  - Added export helpers in `core/BookArchivist_Core.lua` to:
    - Build an export payload for the current character.
    - Serialize and encode it via `core/BookArchivist_Serialize.lua` and `core/BookArchivist_Base64.lua`.
  - Implemented an import worker in `core/BookArchivist_ImportWorker.lua` and corresponding UI wiring that:
    - Parses incoming payloads.
    - Merges books into `booksById` with conflict detection.
    - Reports counts of new vs merged entries.

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
- Fixed async filtering deadlock and empty results for filtered categories
- Fixed books list not visible on first open (async timing issue)
- Fixed loading overlay stuck on first open
- Fixed v1.0.2 migration edge cases (added comprehensive test suite)
- Eliminated visible gap between loading overlay and list appearing
- Fixed pagination after async filtering
- Fixed scrollbar appearing when no scroll is needed
- Fixed text overflow in buttons

### Removed

- Removed resize/splitter functionality (left panel now fixed at 360px width)
- Removed deprecated planning files and documentation
- Cleaned up legacy debug options in v2 migration

---

[2.0.0]: https://github.com/lluistfc/BookArchivist/releases/tag/v2.0.0

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
