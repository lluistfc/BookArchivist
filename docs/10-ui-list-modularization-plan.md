# UI List Modularization Plan

## Scope

Targets these modules:
- core/BookArchivist_Core.lua
- ui/list/BookArchivist_UI_List.lua
- ui/list/BookArchivist_UI_List_Layout.lua
- ui/list/BookArchivist_UI_List_Rows.lua

Goals:
- Core: persistence + list options, no UI details.
- List controller: state, search, sorting, pagination, selection.
- Layout: frame construction/wiring only.
- Rows: row button creation + rendering only.

---

## Phase 1 – Centralize list configuration in Core

**Targets**
- core/BookArchivist_Core.lua
- ui/list/BookArchivist_UI_List.lua

**Plan**
- Extract list-related configuration from Core into a dedicated module, e.g. core/BookArchivist_ListConfig.lua:
  - LIST_PAGE_SIZES
  - LIST_PAGE_SIZE_DEFAULT
  - VALID_SORT_MODES
  - LIST_FILTER_DEFAULTS
  - normalizePageSize (or equivalent helper)
- Make Core’s list option helpers delegate to the new ListConfig module:
  - ensureListOptions
  - GetSortMode / SetSortMode
  - GetListPageSize / SetListPageSize
  - GetListFilters / SetListFilter
- Update ListUI to obtain page-size and sort configuration from callbacks into Core/ListConfig instead of hardcoding:
  - Replace PAGE_SIZES, PAGE_SIZE_DEFAULT, and its own normalizePageSize with calls into Core (via context callbacks).
- Outcome: there is a single source of truth for sort modes, page sizes, and list filters shared between Core and UI.

---

## Phase 2 – Extract shared search logic

**Targets**
- ui/list/BookArchivist_UI_List_Layout.lua
- ui/list/BookArchivist_UI_List.lua

**Plan**
- Introduce a small search helper module in the List namespace, e.g. ui/list/BookArchivist_UI_List_Search.lua, responsible for:
  - Wiring search box handlers (currently local wireSearchHandlers in Layout):
    - Placeholder text
    - Tooltip behavior
    - ESC / Enter behavior
    - Text change handling and debounce scheduling
  - Search state (ListUI.__state.search), including pendingToken and matchFlags.
  - Debounced execution of RunSearchRefresh / ScheduleSearchRefresh.
- Change Layout to only:
  - Create the search EditBox and host frame.
  - Call a search helper entry point to wire handlers, e.g. ListSearch.WireSearchBox(ListUI, searchBox).
- Reimplement ListUI’s search-related methods as thin wrappers onto the search helper:
  - RunSearchRefresh
  - ScheduleSearchRefresh
  - ClearSearch
  - ClearSearchMatchKinds / SetSearchMatchKind / GetSearchMatchKind
- Outcome: Layout only knows about frames; all search behavior and state live in a reusable helper that the controller exposes.

---

## Phase 3 – Extract pagination UI and behavior

**Targets**
- ui/list/BookArchivist_UI_List_Layout.lua
- ui/list/BookArchivist_UI_List.lua

**Plan**
- Create a pagination module, e.g. ui/list/BookArchivist_UI_List_Pagination.lua, that owns:
  - Frame construction for pagination controls:
    - Prev/Next buttons
    - Current page label
    - Page size dropdown
  - Pagination state and math:
    - GetPageSizes / GetPageSize / SetPageSize
    - GetPage / SetPage / NextPage / PrevPage
    - GetPageCount
  - Updating the pagination UI (UpdatePaginationUI).
- Update Layout so it calls a single pagination helper to build/attach controls to the list tip row instead of inlining:
  - Example: ListPagination.EnsureControls(ListUI, tipRow).
- Keep ListUI’s public pagination API unchanged but delegate into the pagination module internally so callers do not need to change.
- Outcome: all page math, dropdown text, and button enable/disable logic live in one clearly named module.

---

## Phase 4 – Extract row button factory and pool

**Targets**
- ui/list/BookArchivist_UI_List_Rows.lua
- ui/list/BookArchivist_UI_List.lua
- ui/list/BookArchivist_UI_List_Layout.lua

**Plan**
- Introduce a dedicated row core module, e.g. ui/list/BookArchivist_UI_List_Rows_Core.lua, responsible for:
  - Button creation and pooling:
    - createRowButton
    - acquireButton
    - releaseAllButtons
    - management of ListUI.__state.buttonPool
  - Layout metrics for rows:
    - ROW_PAD_* values
    - SCROLLBAR_GUTTER
    - ROW_HILITE_INSET / ROW_EDGE_W
    - BADGE_COL_W / BADGE_H / BADGE_GAP_Y
  - Shared row visuals:
    - Selection highlight and edge textures
    - Favorite star indicator and sync (syncRowFavorite)
    - Search badge rendering based on matchFlags (syncMatchBadges)
  - Click dispatch:
    - handleRowClick that calls back into ListUI through a narrow surface, e.g.:
      - ListUI:OnRowBookClick(bookKey, mouseButton)
      - ListUI:OnRowLocationClick(locationName, nodeRef, mouseButton)
      - ListUI:OnRowBackClick(mouseButton)
- Refactor BookArchivist_UI_List_Rows.lua to:
  - Use row-core to acquire/release buttons.
  - Focus on populating button content per mode (BOOKS vs LOCATIONS):
    - Setting titleText/metaText via FormatRowMetadata, getZoneLabel, etc.
    - Setting itemKind, bookKey, nodeRef, locationName.
  - Defer layout anchoring and badge/favorite visuals to row-core.
- Keep ListUI’s external API the same (UpdateList, GetButtonPool, etc.) but internally wire those into the new row-core functions.
- Outcome: list rows have a single factory/pool implementation, and rendering logic is mode-specific but structurally consistent.

---

## Phase 5 – Clarify controller vs layout responsibilities

**Targets**
- ui/list/BookArchivist_UI_List.lua
- ui/list/BookArchivist_UI_List_Layout.lua

**Plan**
- Define a compact API contract that Layout relies on from ListUI, e.g. ListUI must provide:
  - GetContext, SafeCreateFrame, GetRowHeight
  - GetListMode / GetListModes
  - RefreshListTabsSelection
  - UpdateCountsDisplay
  - UpdateResumeButton
  - Search and pagination entry points (ScheduleSearchRefresh, RunSearchRefresh, UpdateSearchClearButton, UpdatePaginationUI).
- Ensure Layout does not:
  - Read from the DB directly.
  - Inspect selection, categories, or favorites state.
- Move any remaining business logic out of Layout into ListUI or the new helper modules:
  - Help/options/resume button behaviors remain in ListUI (or context callbacks).
  - Sort dropdown initialization remains a ListUI concern, with Layout only hosting the dropdown frame.
- Outcome: BookArchivist_UI_List_Layout.lua becomes responsible only for frame construction and anchoring, while BookArchivist_UI_List.lua and helpers handle all behavior.

---

## Phase 6 – Separate books vs locations mode helpers

**Targets**
- ui/list/BookArchivist_UI_List_Rows.lua
- ui/list/BookArchivist_UI_List.lua

**Plan**
- Extract location-tree-specific logic into a location mode helper, e.g. ui/list/BookArchivist_UI_List_LocationMode.lua:
  - GetLocationState / GetLocationRows
  - NavigateInto / NavigateUp
  - GetLocationBreadcrumbText
  - Info-text composition for the location mode (counts, breadcrumbs, empty-state messages).
- Keep book-mode-specific rendering either:
  - In a small BookMode helper (ui/list/BookArchivist_UI_List_BookMode.lua), or
  - In clearly separated sections within BookArchivist_UI_List_Rows.lua, but still using the shared row-core.
- Have UpdateList in the Rows module become a dispatcher:
  - Ask ListUI which mode is active.
  - Delegate to BooksRenderer:RenderPage(...) or LocationsRenderer:RenderPage(...).
- Outcome: adding new list modes or adjusting location-tree behavior becomes localized to the new mode helper modules.

---

## Phase 7 – Transitional shims and cleanup

**Targets**
- All four modules and new helpers.

**Plan**
- During the initial refactor, keep old functions as shims that delegate into new modules:
  - wireSearchHandlers in Layout calls into ListSearch.
  - EnsurePaginationControls in Layout calls into ListPagination.
  - Existing UpdateList entry point in ListUI continues to be called by the rest of the addon but internally delegates to the row/mode helpers.
- Test in-game across scenarios before removing shims:
  - Books mode: search, filters, paging, sort changes, favorites, recent category.
  - Locations mode: navigation, breadcrumbs, counts, empty states.
  - UI chrome: header counts, resume button visibility, dropdown labeling.
- Once behavior is stable, remove transitional wrappers and dead code, keeping each module’s responsibilities narrow and documented.

---

## Implementation Notes

- Prefer non-breaking, additive changes first:
  - Introduce new helper modules and wire them up via the existing ListUI interface.
  - Avoid renaming public methods or changing Core APIs in the first pass.
- Keep SavedVariables schema stable:
  - All changes should reuse existing options containers (BookArchivistDB.options.list, BookArchivistDB.options.ui, BookArchivistDB.recent).
- Update .github/copilot-instructions.md if:
  - New modules become the canonical place for list search/pagination/rows.
  - The refresh pipeline or UI layout contracts change in a significant way.
