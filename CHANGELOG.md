# Changelog

All notable changes to this project are documented here.

## [2.3.5] - 2026-01-22

**Fix: CurseForge release packaging**

### Fixed

- **Tests Folder in Release**
  - Fixed Git tracking Tests folder with wrong case (tests → Tests)
  - CurseForge packager (Linux, case-sensitive) was including the folder despite ignore rules
  - Added lowercase `tests` to .pkgmeta ignore as safety net

## [2.3.4] - 2026-01-22

**Hotfix: Fresh install initialization**

### Fixed

- **Fresh Install Corruption Detection**
  - Fixed false corruption detection on fresh addon installs
  - Database was not being properly initialized before validation ran
  - Repository returns nil during early init instead of throwing error
  - Core:GetDB falls back to ensureDB() when Repository returns nil
  - ListConfig returns defaults when Core unavailable (prevents empty DB creation)
  - UI_Options uses Core:EnsureDB() instead of creating empty tables
  - Added nil checks in BookEcho and RandomBook modules

- **Dev Environment Stack Overflow** (Dev mode only)
  - Fixed circular call chain causing stack overflow on fresh install
  - DevOptions now accesses BookArchivistDB directly to avoid circular calls

### Technical

- Eliminated circular dependency: GetDB → Core:EnsureDB → DebugPrint → IsDebugEnabled → GetDB
- DBSafety now logs debug info when detecting corruption
- Fixed variable name bug in DBSafety corruption popup (error → errorMsg)
- 801 tests passing

## [2.3.3] - 2026-01-21

**Hotfix: Dev options UI leak**

### Fixed

- **Reset Button UI Leak** (Dev mode only)
  - Fixed "Reset all read counts" button appearing in all options panels
  - Button now only visible when viewing BookArchivist's options
  - Properly scoped visibility to BookArchivist settings category

## [2.3.2] - 2026-01-20

**Quality of life improvements for book creation and location navigation**

### Added

- **Smart Location Default**
  - New custom books automatically use your current location as default
  - Location field now pre-populated when creating books
  - "Use Current Location" button remains available for manual updates when editing

- **Improved Location Navigation**
  - Books in subzones now visible when viewing parent zones that contain books
  - Cleaner navigation through zones without books (shows only subzones)
  - Recursive book collection from all descendant locations
  - Example: Books in "Isle of Dorn > Fungal Folly" now appear when viewing "Isle of Dorn"

### Changed

- **Location Filtering Logic**
  - Zones with direct books show both subzones and all descendant books
  - Zones without direct books show only subzones for navigation
  - Improved drill-down experience through location hierarchies

### Technical

- Refactored to Book Aggregate Root pattern for better module encapsulation
- Added `collectAllBooksRecursive()` for hierarchical book collection
- Added comprehensive tests for location filtering with subzones
- Tests cover deeply nested locations (4+ levels)
- 801 tests passing (3 new tests added)

## [2.3.1] - 2026-01-17

**Feature release: Minimap improvements and library management tools**

### Added

- **Minimap Icon Improvements**
  - Migrated to LibDBIcon for minimap button management
  - Better integration with other addons using LibDBIcon
  - More reliable drag behavior and position persistence
  - Automatic compartment mode support (addon compartment button)

- **Library Management Tools**
  - New `make download-libs` command to download external libraries via SVN/git
  - New `make junction-libs` command to create directory junctions to existing libraries
  - Unified git repository downloads (LibDataBroker + LibDeflate) with optional tag support
  - Added LIB_* environment variables to .env.dist for junction configuration
  - Developers can now share library folders across multiple addons without duplication

### Changed

- **CI/CD Improvements**
  - Added library caching to GitHub Actions workflow (based on .pkgmeta hash)
  - Automatic Subversion installation when cache is missed
  - Faster CI runs after first build (~30 seconds saved per run)

- **Developer Experience**
  - Simplified .gitignore to exclude entire libs/ directory
  - Updated README with comprehensive library management documentation
  - Updated .env.dist showing complete junction configuration

## [2.3.0] - 2026-01-18

**Feature release with Book Echo system and comprehensive test coverage improvements**

### Added

- **Book Echo Feature**
  - New flavor text system that provides contextual commentary after reading a book
  - Echoes appear in the reader panel below book content
  - Displays read count tracking ("You've read this X times")
  - Context-aware messages based on content, creator, or rarity
  - Fully localized support for 7 languages: enUS, esES, caES, frFR, deDE, itIT, ptBR
  - 50+ unique echo templates covering various book types and scenarios

- **Developer Tools Enhancements**
  - New "Refresh Echo" dev command to preview echo display without full reload
  - DB Reset button in developer options (confirms before executing)
  - Enhanced dev tools panel with echo testing capabilities
  - Additional debug commands for echo system diagnostics

- **Test Coverage Improvements**
  - Added 20 new tests across core modules (641 → 661 total tests)
  - Recent module: 86.21% → 94.83% coverage (+8.62%)
  - RandomBook module: 90.48% → 97.12% coverage (+6.64%)
  - Search module: 84.21% → 94.74% coverage (+10.53%)
  - Migrations module: 83.82% → 85.29% coverage (+1.47%)
  - Export module: Enhanced EncodeBDB1Envelope coverage (compression, chunking, error paths)
  - 13 modules now maintain 90%+ coverage (Core, Repository, DB, BookId, etc.)

### Changed

- **Database Schema Evolution**
  - Migrated to v3 schema for Book Echo support
  - Added readCount tracking per book entry
  - Automatic migration from v2 → v3 on addon load

- **Export System**
  - Implemented metadata stripping for cleaner export payloads
  - Export now excludes echo-related transient data
  - Reduced export string size for chat compatibility

- **Page Turn Detection**
  - Enhanced page turn detection logic in reader panel
  - Improved tracking of when users actually advance pages
  - More accurate readCount increments

### Fixed

- **List Panel Pagination**
  - Fixed pagination sync issues in Locations tab
  - Fixed incorrect pagination boundaries causing blank pages
  - Improved pagination state management between tab switches

- **Edge Cases**
  - Fixed nil guard issues in Recent module (db without booksById)
  - Fixed orphaned books not appearing in migrated database order
  - Fixed RandomBook crashes when UI.List unavailable
  - Fixed FindPageForBook handling of nil returns

### Developer Notes

*This release introduces the Book Echo system, a delightful flavor text feature that adds personality to your reading experience. With 50+ unique echo templates and full localization support across 7 languages, echoes provide contextual commentary based on book content, creators, and rarity. Test coverage has been significantly improved with 20 new tests, bringing 13 core modules to 90%+ coverage (661 tests total). The v3 database migration adds readCount tracking for future analytics features.*

*Key metrics: 661/661 tests passing, 51.79% overall coverage (90%+ on 13 core modules), 0 critical lint errors, Interface version 120001 (The War Within).*

## [2.2.0] - 2026-01-13

**Feature release with Random Book and UI improvements**

### Added

- **Random Book Feature**
  - New "Random" button opens a random book from your library
  - Automatically navigates to book's location in Locations tab for geographic context
  - Smart pagination: displays the exact page where the book appears
  - Excludes currently open book when selecting (unless it's the only book)
  - Handles books without location data gracefully

- **Testing Infrastructure Enhancements**
  - Integrated Mechanic wow_stubs for comprehensive WoW API mocking (650+ API definitions)
  - Added Mechanic CLI integration for local development (faster test execution)
  - Enhanced test output: `make test-errors` now shows full Busted stack traces
  - Code coverage support with luacov (`make test-coverage`, `make coverage-stats`)
  - Added 130+ new tests: LocationTree (29), ListPagination (39), ListSort (34), Iterator (14), Location (28), Capture (16), ChatLinks (9)
  - Created reusable UI mock helpers library (20+ mock utilities)
  - Total test count: 489 passing tests

- **Developer Documentation**
  - Migrated documentation to Claude skills format for AI-assisted development
  - Added comprehensive coverage analysis and TDD enforcement guidelines
  - Created structured knowledge base for 8 major systems

- **Compression & Performance**
  - Added LibDeflate compression for export strings (75%+ size reduction)
  - Implemented capability negotiation for cross-version chat link compatibility

- **Location System**
  - Echo integration: location-aware context system with 603 WoW zones
  - Location capture and backfill functionality (fixes v2.0.2 regression)
  - Enhanced zone chain processing for accurate geographic data

### Changed

- **UI Improvements**
  - Independent pagination for Books and Locations tabs (no cross-contamination)
  - Books tab uses `state.pagination.page`, Locations tab uses `state.currentPage`
  - Pagination UI now mode-aware, displays correct page numbers per tab
  - Fixed Locations tab pagination not updating content when changing pages

- **Testing Workflow**
  - Smart test runner: uses Mechanic CLI locally, Busted directly in CI
  - Coverage mode forces Busted (Mechanic doesn't collect coverage)
  - Improved error display with full stack traces instead of JSON parsing

- **Code Quality**
  - Removed overly defensive type checks in favor of duck-typing
  - Refactored Frame_Builder steps table structure
  - Cleaned up unused spy helpers

### Fixed

- **Pagination Issues**
  - Fixed Books tab inheriting page number from Locations tab when switching modes
  - Fixed Random Book feature not paginating to correct page
  - Fixed pagination UI showing wrong page number in Locations mode
  - Fixed Locations pagination not updating content when page changes

- **UI Refresh Loop**
  - Fixed infinite UI refresh loop during multi-page book capture
  - Added refresh guards to prevent cascading calls
  - Location tree cache now properly invalidated on rebuild

- **Location System**
  - Restored location capture functions broken in v2.0.2
  - Fixed location tree not persisting in state (now stored in `state.root`)
  - UI refreshes after book capture to update Locations tab

- **Test Infrastructure**
  - Added WoW API mocks for DB corruption handling tests
  - Fixed CI-compatible fallback mocks in test bootstrap
  - Removed test count references from documentation (auto-updated)

### Developer Notes

*This beta includes significant new functionality (Random Book feature) and extensive testing improvements (489 passing tests with 130+ new tests added). The Random Book feature provides a fun way to rediscover books in your library with automatic location context. Pagination improvements ensure Books and Locations tabs maintain independent state. All changes validated with comprehensive test coverage.*

*Key metrics: 489/489 tests passing, code coverage tracking enabled, 0 critical lint errors, Interface version 120001 (The War Within).*

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
