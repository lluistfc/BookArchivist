# Location Breadcrumbs – Implementation Plan

## Current Status (Phase 0 - COMPLETED)

**What was implemented:**
- ✅ Breadcrumb displayed in header via `GetLocationBreadcrumbText()` 
- ✅ Text truncation with `SetMaxLines(1)` and RIGHT anchor to prevent overflow
- ✅ Tooltip on hover showing full path when truncated (GameTooltip)
- ✅ Smart visual truncation using ellipsis (...)

**Files modified:**
- `ui/list/BookArchivist_UI_List_Header.lua` - Added breadcrumb to header display
- `ui/list/BookArchivist_UI_List_Layout.lua` - Added RIGHT anchor and SetMaxLines(1) to headerCount
- `ui/list/BookArchivist_UI_List_Location.lua` - GetLocationBreadcrumbText() returns full path

**Current behavior:**
- Header shows: `"Location Name • count"` (e.g., "Azeroth > Dalaran • 12 books in this location")
- Long paths truncate: `"Azeroth > Eastern Kingdoms > East... • 45 books"`
- Hovering shows full path in tooltip

**Limitation:**
- Very long location chains still truncate and compete with search bar space
- No navigation functionality in breadcrumbs

---

## Goal (Phase 1 - IN PROGRESS)

- Remove the full breadcrumb chain from the top header (it truncates and competes with search/buttons).
- Render breadcrumbs inside the left list panel (`listBlock`) as a multi-line vertical stack under the tabs.
- Keep the top header subtitle (`headerCountText`) for short, stable information (counts and optionally the leaf location name).

## Code map (current)

- Breadcrumb text is produced by:
  - `ListUI:GetLocationBreadcrumbText()` in `ui/list/BookArchivist_UI_List_Location.lua`
- Breadcrumb is currently displayed in the top header by:
  - `ListUI:UpdateCountsDisplay()` in `ui/list/BookArchivist_UI_List_Header.lua`
- Left panel layout is defined in:
  - `ui/list/BookArchivist_UI_List_Layout.lua`
  - Key rows: `listHeaderRow` (tabs live here), `listScrollRow` (scroll list), `listTipRow` (bottom info/pagination)

## Target UI behavior (Phase 1)

When in Locations mode:

- Breadcrumbs appear inside the left panel, directly below the tabs.
- Breadcrumbs are shown as up to 3 lines:
  - If path depth <= 3, show all segments.
  - If path depth > 3, show a leading "…" line, then the last 2 segments.
- Each non-root line is prefixed with `›`.
- The leaf (last visible segment) is emphasized (brighter font).

When in Books mode:

- Breadcrumb row is hidden.

## Implementation steps

### 1) Add a new row in the left panel for breadcrumbs

**File:** `ui/list/BookArchivist_UI_List_Layout.lua`

Add a new helper similar to the existing `EnsureListHeaderRow()` and `EnsureListScrollRow()`:

- `ListUI:EnsureListBreadcrumbRow()`

Recommended anchoring (minimal disruption):

1. Create `breadcrumbRow` as a child of `listBlock`.
2. Anchor it below `listHeaderRow`:
   - `breadcrumbRow:SetPoint("TOPLEFT", listHeaderRow, "BOTTOMLEFT", 0, 0)`
   - `breadcrumbRow:SetPoint("TOPRIGHT", listHeaderRow, "BOTTOMRIGHT", 0, 0)`
3. Change `EnsureListScrollRow()` so its top anchors to `breadcrumbRow` instead of `listHeaderRow`:
   - Replace `row:SetPoint("TOPLEFT", self:EnsureListHeaderRow(), ...)` with `breadcrumbRow`.

Row height:

- Use a fixed height in Phase 1 for layout stability.
- Suggested: `breadcrumbRow:SetHeight(46)` (enough for 3 small lines).

Store frame refs:

- `self:SetFrame("breadcrumbRow", breadcrumbRow)`

### 2) Create the breadcrumb line FontStrings

**File:** `ui/list/BookArchivist_UI_List_Layout.lua`

Inside `EnsureListBreadcrumbRow()` (or immediately after calling it in `Create()`), create 3 FontStrings:

- `breadcrumbLine1` (dim)
- `breadcrumbLine2` (dim)
- `breadcrumbLine3` (emphasized)

Implementation notes:

- Use WoW font objects you already use elsewhere:
  - `GameFontHighlightSmall` for lines 1 and 2
  - `GameFontHighlight` (or `GameFontNormal`) for line 3
- Keep `SetWordWrap(false)` and `SetMaxLines(1)` per line to avoid reflow.
- Vertical spacing: 2-3 px between lines.

Example layout:

- Line 1: `TOPLEFT` of breadcrumbRow
- Line 2: anchored below line 1
- Line 3: anchored below line 2

Store frame refs:

- `self:SetFrame("breadcrumbLine1", fs1)`
- `self:SetFrame("breadcrumbLine2", fs2)`
- `self:SetFrame("breadcrumbLine3", fs3)`

### 3) Add a segments-based breadcrumb API

**File:** `ui/list/BookArchivist_UI_List_Location.lua`

Right now you only have `GetLocationBreadcrumbText()` which returns a single string joined by ` > `.

Add two helpers:

1. `ListUI:GetLocationBreadcrumbSegments()`
   - Returns an array of strings.
   - If `state.path` is empty, return `{ t("LOCATIONS_BREADCRUMB_ROOT") }`.
   - Otherwise return the `state.path` segments.

2. `ListUI:GetLocationBreadcrumbDisplayLines(maxLines)`
   - Returns an array sized to `maxLines` containing what should be rendered line-by-line.
   - Suggested behavior for `maxLines == 3`:
     - If segments length == 1: `{ segments[1], "", "" }`
     - If segments length == 2: `{ segments[1], "› " .. segments[2], "" }`
     - If segments length >= 3:
       - If length == 3: `{ segments[1], "› " .. segments[2], "› " .. segments[3] }`
       - If length > 3: `{ "…", "› " .. segments[#segments-1], "› " .. segments[#segments] }`

This keeps the display logic centralized and makes the UI update function simple.

### 4) Implement `UpdateLocationBreadcrumbUI()`

**File:** can be placed in `ui/list/BookArchivist_UI_List_Location.lua` (recommended, because it depends on location state), or in a small new file if you prefer.

Responsibilities:

- If current mode is not Locations, hide `breadcrumbRow` and return.
- Ensure breadcrumb row and line FontStrings exist:
  - call `self:EnsureListBreadcrumbRow()` (which must also ensure font strings exist).
- Compute display lines:
  - `local lines = self:GetLocationBreadcrumbDisplayLines(3)`
- Render:
  - `breadcrumbLine1:SetText(dim(lines[1]))`
  - `breadcrumbLine2:SetText(dim(lines[2]))`
  - `breadcrumbLine3:SetText(emphasize(lines[3]))`
- If a line is empty, set it to `""`.

Coloring approach (simple and consistent):

- For dim lines, wrap in a light gray color code, for example `|cFFAAAAAA...|r`.
- For emphasized leaf line, use your existing accent color (you already use `|cFFFFD100` in the header).

### 5) Call breadcrumb UI updates at the right times

**File:** `ui/list/BookArchivist_UI_List_Location.lua`

After navigation and after rebuilds, call `UpdateLocationBreadcrumbUI()`:

- In `ListUI:NavigateInto(segment)` after `rebuildLocationRows(...)`
- In `ListUI:NavigateUp()` after `rebuildLocationRows(...)`
- In `ListUI:RebuildLocationTree()` after you have a valid `state.activeNode` and rows are rebuilt

Also call it on mode switches:

**File:** `ui/list/BookArchivist_UI_List_Layout.lua` (or wherever `UpdateListModeUI()` lives; it is currently at the end of `BookArchivist_UI_List_Layout.lua`)

- In `ListUI:UpdateListModeUI()` after `RefreshListTabsSelection()` add:
  - `if self.UpdateLocationBreadcrumbUI then self:UpdateLocationBreadcrumbUI() end`

### 6) Remove breadcrumb chain from the top header

**File:** `ui/list/BookArchivist_UI_List_Header.lua`

In `ListUI:UpdateCountsDisplay()` for Locations mode:

- Remove `local breadcrumb = self:GetLocationBreadcrumbText()` and the format string that includes breadcrumb.
- Replace with a short stable string.

Two safe options:

- Option A (counts only):
  - `headerCount:SetText(string.format("|cFFFFD100%s|r", countText))`
- Option B (leaf + counts):
  - derive leaf from location state:
    - `local leaf = (state.path and state.path[#state.path]) or t("LOCATIONS_BREADCRUMB_ROOT")`
  - `headerCount:SetText(string.format("|cFFCCCCCC%s|r  |cFF666666•|r  |cFFFFD100%s|r", leaf, countText))`

Do not include the full chain here.

## Acceptance checklist

### Visual

- In Locations mode, breadcrumb path is readable and does not truncate.
- Breadcrumbs do not compete with the top header controls.
- Leaf location is visually emphasized.
- Switching to Books mode hides the breadcrumb row.

### Functional

- Breadcrumbs update immediately when navigating into a location.
- Breadcrumbs update immediately when navigating up.
- Breadcrumbs remain correct after rebuild triggers (filters/search/category changes).

### Layout stability

- No overlap between breadcrumbs and scroll list.
- No anchor warnings or taint-related errors.

## Phase 2 (optional): Clickable breadcrumb navigation

Once Phase 1 is stable, you can make parent segments clickable without changing the layout.

Approach:

- Replace each breadcrumb line FontString with a small `Button` container holding a FontString.
- On click of line N, set `state.path` to the prefix ending at N (or N mapped to the correct segment when the first line is the `…` line).
- Call `ensureLocationPathValid(state)`, rebuild rows, then call `UpdateLocationBreadcrumbUI()`.

This is optional and can be done after the visual placement is validated.
