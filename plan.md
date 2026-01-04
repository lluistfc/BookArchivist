# Implementation Plan — Enforced Container Ownership (Strict Order)

This plan assumes uidebug stays ON while implementing and you do **not** “fix padding” until Step 8.

---

## Step 0 — Pre-flight (1 commit)
**Goal:** Freeze the current UI so you can safely rebuild without regressions.

- Keep `/ba uidebug on` defaulted in dev builds (or persisted option).
- Add a `UI_METRICS` table if not already present:
  - `PAD_OUTER`, `PAD_INSET`, `GAP_S`, `GAP_M`, `HEADER_H`, `ROW_H`, `BTN_H`, `RIGHT_W`, `TIP_ROW_H`, `NAV_ROW_H`
- Add a small helper file (or in `UI_Frame_Builder`) with reusable constructors:
  - `CreateContainer(name, parent)`
  - `CreateRow(name, parent, height)`
  - `ClearAnchors(frame)` (calls `ClearAllPoints()` and optionally resets size)

**Acceptance**
- You can toggle uidebug and see container bounds.
- No functional changes yet.

Files:
- `ui/BookArchivist_UI_Frame_Builder.lua` (main)
- optionally `ui/BookArchivist_UI_Metrics.lua`

---

## Step 1 — Hard reset: top-level containers only (HeaderFrame + BodyFrame)
**Goal:** Only `HeaderFrame` and `BodyFrame` are allowed to anchor to `MainFrame`.

1. In `UI_Frame_Builder`, locate where `HeaderFrame` and `BodyFrame` are created.
2. Apply:
   - `HeaderFrame:ClearAllPoints()`
   - `HeaderFrame:SetPoint("TOPLEFT", MainFrame, "TOPLEFT", PAD_OUTER, -PAD_OUTER)`
   - `HeaderFrame:SetPoint("TOPRIGHT", MainFrame, "TOPRIGHT", -PAD_OUTER, -PAD_OUTER)`
   - `HeaderFrame:SetHeight(HEADER_H)`
3. Apply:
   - `BodyFrame:ClearAllPoints()`
   - `BodyFrame:SetPoint("TOPLEFT", HeaderFrame, "BOTTOMLEFT", 0, -GAP_M)`
   - `BodyFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -PAD_OUTER, PAD_OUTER)`

**Acceptance**
- uidebug shows HeaderFrame and BodyFrame aligned and stable.
- Nothing else anchors to MainFrame after this (audit in code).

---

## Step 2 — Header rebuild: enforce 3 columns (Left/Center/Right)
**Goal:** Create `HeaderLeft`, `HeaderCenter`, `HeaderRight` as children of HeaderFrame only.

1. Create containers:
   - `HeaderLeft`, `HeaderCenter`, `HeaderRight`
2. Define left “safe start” to avoid portrait overlap:
   - `LEFT_SAFE_X = 54` (or anchor to portrait frame right edge if you have it)
3. Anchor:
   - `HeaderRight:SetPoint("TOPRIGHT", HeaderFrame, "TOPRIGHT", 0, 0)`
   - `HeaderRight:SetPoint("BOTTOMRIGHT", HeaderFrame, "BOTTOMRIGHT", 0, 0)`
   - `HeaderRight:SetWidth(RIGHT_W)`
   - `HeaderLeft:SetPoint("TOPLEFT", HeaderFrame, "TOPLEFT", LEFT_SAFE_X, 0)`
   - `HeaderLeft:SetPoint("BOTTOMLEFT", HeaderFrame, "BOTTOMLEFT", LEFT_SAFE_X, 0)`
   - `HeaderLeft:SetPoint("RIGHT", HeaderFrame, "LEFT", 0, 0)` **(do not do this)**
   - Instead: set `HeaderLeft` width later by letting it grow to content; easiest is to anchor `HeaderCenter` between:
     - `HeaderCenter:SetPoint("TOPLEFT", HeaderLeft, "TOPRIGHT", GAP_M, 0)`
     - `HeaderCenter:SetPoint("BOTTOMRIGHT", HeaderRight, "BOTTOMLEFT", -GAP_M, 0)`
   - For `HeaderLeft`, anchor to center:
     - `HeaderLeft:SetPoint("TOPRIGHT", HeaderCenter, "TOPLEFT", -GAP_M, 0)`
     - `HeaderLeft:SetPoint("BOTTOMRIGHT", HeaderCenter, "BOTTOMLEFT", -GAP_M, 0)`

**Acceptance**
- The cyan boxes for HeaderLeft/Center/Right share exact top/bottom edges.
- Search cannot overlap HeaderRight (it’s bounded by HeaderCenter).

---

## Step 3 — Header rebuild: enforce 2 rows inside each column
**Goal:** No header widget anchors outside its row.

For each column (`HeaderLeft`, `HeaderCenter`, `HeaderRight`):
1. Create `TopRow` + `BottomRow` with fixed heights:
   - `TopRow` height: ~32
   - `BottomRow` height: ~32
2. Anchor rows:
   - `TopRow:SetPoint("TOPLEFT", col, "TOPLEFT", 0, 0)`
   - `TopRow:SetPoint("TOPRIGHT", col, "TOPRIGHT", 0, 0)`
   - `BottomRow:SetPoint("BOTTOMLEFT", col, "BOTTOMLEFT", 0, 0)`
   - `BottomRow:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", 0, 0)`
   - `TopRow:SetPoint("BOTTOM", BottomRow, "TOP", 0, 0)`

Then place widgets ONLY within:
- `HeaderLeftTopRow`: Title
- `HeaderLeftBottomRow`: Count
- `HeaderCenterBottomRow`: Search (centered vertically in this row)
- `HeaderRightTopRow`: Help + Options
- `HeaderRightBottomRow`: Sort dropdown + filter icons

**Acceptance**
- The sort dropdown is a child of `HeaderRightBottomRow` (verify in code and visually).
- No header widget anchors to HeaderFrame directly anymore.

---

## Step 4 — Body split: create ListInset + ReaderInset (and only then separator)
**Goal:** List and reader share exact top/bottom edges and live entirely in BodyFrame.

1. Create:
   - `ListInset` (left)
   - `ReaderInset` (right)
   - optional `SplitHandle` (draggable)
2. Anchor:
   - `ListInset:SetPoint("TOPLEFT", BodyFrame, "TOPLEFT", 0, 0)`
   - `ListInset:SetPoint("BOTTOMLEFT", BodyFrame, "BOTTOMLEFT", 0, 0)`
   - `ReaderInset:SetPoint("TOPRIGHT", BodyFrame, "TOPRIGHT", 0, 0)`
   - `ReaderInset:SetPoint("BOTTOMRIGHT", BodyFrame, "BOTTOMRIGHT", 0, 0)`
   - Use either:
     - fixed `LIST_W` for ListInset and let Reader fill, or
     - persisted width + clamp
3. Create `Separator` as child of BodyFrame only:
   - `Separator:SetPoint("TOP", BodyFrame, "TOP", 0, 0)`
   - `Separator:SetPoint("BOTTOM", BodyFrame, "BOTTOM", 0, 0)`
   - Horizontal position is tied to list width boundary.

**Acceptance**
- Separator starts at BodyFrame top and ends at BodyFrame bottom.
- Separator never references ListHeaderRow/Tabs.

---

## Step 5 — ListInset rebuild: enforce 3 top rows (HeaderRow, TipRow, ScrollRow)
**Goal:** Stop anchoring tabs/tip/scroll to each other arbitrarily.

Inside `ListInset` create:
1. `ListHeaderRow` (height `LIST_HEADER_H`)
2. `ListTipRow` (height `TIP_ROW_H`)
3. `ListScrollRow` (fills remainder)

Anchor:
- `ListHeaderRow` top inside inset with `PAD_INSET`
- `ListTipRow` directly below HeaderRow with `GAP_S`
- `ListScrollRow` below TipRow with `GAP_S`, down to bottom with `PAD_INSET`

Then:
- Place “Saved Books” inside ListHeaderRow (left).
- Create `TabsRail` inside ListHeaderRow (right) with right padding:
  - `TabsRail` right inset: `PAD_INSET`
- Anchor tabs ONLY within `TabsRail`.
- Tip text ONLY inside `ListTipRow`.
- ScrollFrame ONLY fills `ListScrollRow`.

**Acceptance**
- Tabs cannot collide with separator because TabsRail has explicit right inset.
- First list row starts below tip row consistently.

---

## Step 6 — ReaderInset rebuild: enforce 2 rows + scroll (HeaderRow, NavRow, ScrollRow)
**Goal:** Lock the page label and buttons into stable rows.

Inside `ReaderInset` create:
1. `ReaderHeaderRow` (height `READER_HEADER_H`)
2. `ReaderNavRow` (height `NAV_ROW_H`)
3. `ReaderScrollRow` (fills remainder)

Place:
- Title + metadata inside `ReaderHeaderRow` (left).
- Create `ReaderActionsRail` inside `ReaderHeaderRow` (right, fixed width).
  - Delete + Next live here.
- Prev button inside `ReaderNavRow` (left).
- Page label inside `ReaderNavRow` (center).
- Reader ScrollFrame fills `ReaderScrollRow`.

**Acceptance**
- Page label no longer moves when title length changes.
- No reader control anchors to ReaderScrollRow.

---

## Step 7 — Audit: enforce “no cross-row anchors”
**Goal:** Ensure ownership is real, not just intended.

Do a quick code audit:
- Grep for `SetPoint(` calls and confirm:
  - No widget anchors to MainFrame except HeaderFrame/BodyFrame.
  - No header widgets anchor to HeaderFrame directly (must anchor to their rows).
  - No list widgets anchor to ListInset directly except the 3 rows.
  - No reader widgets anchor to ReaderInset directly except the 3 rows.

**Acceptance**
- uidebug rectangles show clean stacked rows; no “floating” widgets.

---

## Step 8 — Only now: apply padding and visual tweaks
**Goal:** Make it look right without breaking the grid.

Allowed tweaks:
- Add `PAD_INSET` to row contents
- Add small *bias constants* per rail (e.g., `TAB_Y_BIAS`, `SEARCH_Y_BIAS`) but only at the rail/row level, never per-widget.
- Ensure list row text has a `RowContent` safe area to avoid scrollbar overlap.

**Acceptance**
- All tweaks happen by adjusting constants or rail-level bias, not by ad-hoc widget offsets.

---

## Step 9 — Remove/disable uidebug by default (keep toggle)
- Keep the command and DB flag.
- Default it OFF for releases.

---

# Deliverables per step (commit boundaries)

1. Add helpers + metrics + keep uidebug.
2. Re-anchor HeaderFrame + BodyFrame only.
3. Header: 3 columns + 2 rows; move all header widgets into rows.
4. Body: ListInset + ReaderInset + Separator anchored to BodyFrame.
5. ListInset: 3 rows; move Saved Books / Tabs / Tip / Scroll into proper rows.
6. ReaderInset: 3 rows; move header/nav/scroll into proper rows.
7. Audit pass: remove any remaining cross-row anchors.
8. Padding pass: tune look using constants only.
9. Release hygiene: uidebug default off.

---
