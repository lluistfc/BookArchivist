# BookArchivist UI Alignment Fix Plan (Post-Implementation)

Goal: eliminate pixel-level misalignment and inconsistent padding across header, list, and reader; ensure a stable “grid” so elements line up at all UI scales.

---

## 0) What’s visibly wrong in the current screenshot

### Header
- Search box is not vertically aligned with the title baseline; it floats too high.
- Sort dropdown (“Recently Read”) sits too low relative to title/search row.
- “Options” / “Help” buttons are not aligned to the same top/bottom baseline as the header content.
- Count text (“8 books”) is too detached and doesn’t share a consistent left gutter with the rest.

### Body
- List inset and reader inset don’t share the same top edge; the list panel starts lower.
- The “Saved Books” header line and the Books/Locations tabs are not aligned on a single row; “Saved Books” appears as a separate header with tabs floating.
- Reader placeholder text (“Select a book…”) is not aligned within a defined header/content area and visually collides with the delete button strip.
- Prev/Next/page label are not aligned to a shared row; they float in the content region.

### Global
- Inconsistent gutters: left padding differs between list rows, “Saved Books” header, and tabs.
- Mixed anchoring: some elements are anchored to parent edges, others to siblings with ad-hoc offsets, causing drift when sizes change.

---

## 1) Adopt a single layout grid (the real fix)

### 1.1 Define constants (one source of truth)
Create `UI_METRICS` and use it everywhere.

**Add to** `ui/BookArchivist_UI_Constants.lua` (or similar):
- `PAD = 12`
- `GUTTER = 10`
- `HEADER_H = 70`
- `SUBHEADER_H = 34` (for list header row / tabs row)
- `READER_HEADER_H = 54`
- `ROW_H = 36`
- `BTN_H = 22`
- `BTN_W = 90`

**Acceptance**
- No frame sets `SetPoint(..., x, y)` with magic numbers outside these metrics (except rare template quirks).

---

## 2) Header: rebuild as a 2-row structure (no floating anchors)

### 2.1 Create `HeaderFrame` with fixed height
**Structure**
- `HeaderFrame` (height = `HEADER_H`)
  - Row 1: Title (left), Search (center), Actions (right)
  - Row 2: Count (left), Sort+Filters (left/center)

**Implementation**
- Anchor `HeaderFrame` to main frame top-left/top-right with `PAD`.
- Place Row 1 elements by anchoring to `HeaderFrame` with explicit vertical centers:
  - `TitleText:SetPoint("TOPLEFT", HeaderFrame, "TOPLEFT", 0, -4)`
  - `SearchBox:SetPoint("TOP", HeaderFrame, "TOP", 0, -6)` (then vertically center it via `SetHeight(BTN_H)` and `SetPoint("CENTER", Row1, "CENTER")`)
  - `OptionsBtn:SetPoint("TOPRIGHT", HeaderFrame, "TOPRIGHT", 0, -4)`
  - `HelpBtn` anchored directly below Options with `-6` spacing, same right edge.

**Fixes**
- Stop anchoring the search to the main frame; anchor it to the header row container.
- Ensure all buttons share identical height (`BTN_H`) and text insets.

**Acceptance**
- Title, search, and Options button share the same top baseline visually.
- Sort dropdown aligns to count line and does not drift when search width changes.

---

## 3) Body: enforce equal top edges and consistent gutters

### 3.1 Create `BodyFrame` and anchor panels to it
**Structure**
- `BodyFrame` anchored below `HeaderFrame` with `GUTTER`.
- Inside `BodyFrame`:
  - `ListInset`
  - `ReaderInset`
  - optional splitter

**Implementation**
- `BodyFrame:SetPoint("TOPLEFT", HeaderFrame, "BOTTOMLEFT", 0, -GUTTER)`
- `BodyFrame:SetPoint("BOTTOMRIGHT", MainFrame, "BOTTOMRIGHT", -PAD, PAD)`

**Acceptance**
- List and reader insets share identical top and bottom edges.

---

## 4) List panel: collapse “Saved Books” header + tabs into ONE subheader row

### 4.1 Single `ListHeaderRow` (height = `SUBHEADER_H`)
**Structure**
- `ListHeaderRow` at top of `ListInset`
  - Left: “Saved Books”
  - Right: Tabs (Books / Locations), aligned to the same vertical center

**Implementation**
- Remove any separate “Saved Books” title anchored outside the inset.
- Create `ListHeaderRow` as a child of `ListInset`:
  - `ListHeaderRow:SetPoint("TOPLEFT", ListInset, "TOPLEFT", PAD, -PAD)`
  - `ListHeaderRow:SetPoint("TOPRIGHT", ListInset, "TOPRIGHT", -PAD, -PAD)`
  - `ListHeaderRow:SetHeight(SUBHEADER_H)`

**Tabs alignment rule**
- Tabs must anchor to `ListHeaderRow`’s RIGHT and CENTER, not to the inset or the list scroll frame.
- Ensure tab button heights are consistent and their text vertical offset is zeroed.

**Acceptance**
- “Saved Books” and the Books/Locations tabs live on the same line, centered vertically.

---

## 5) List content: ensure scroll region starts below header row

### 5.1 Anchor list scroll frame to `ListHeaderRow`
- `ListScroll:SetPoint("TOPLEFT", ListHeaderRow, "BOTTOMLEFT", 0, -GUTTER)`
- `ListScroll:SetPoint("BOTTOMRIGHT", ListInset, "BOTTOMRIGHT", -PAD, PAD)`

**Acceptance**
- First row never overlaps header/tabs.
- Left padding of row text matches header text padding.

---

## 6) Reader panel: introduce a real ReaderHeader (stop placing controls in content)

### 6.1 Create `ReaderHeader` (height = `READER_HEADER_H`)
**Structure**
- `ReaderHeader` at top of `ReaderInset`
  - Left: Title / placeholder (single line)
  - Center (optional): Page indicator
  - Right: Delete button
  - Bottom of header: Nav row (Prev / Next) OR keep nav row inside header aligned

**Implementation**
- `ReaderHeader:SetPoint("TOPLEFT", ReaderInset, "TOPLEFT", PAD, -PAD)`
- `ReaderHeader:SetPoint("TOPRIGHT", ReaderInset, "TOPRIGHT", -PAD, -PAD)`
- `ReaderHeader:SetHeight(READER_HEADER_H)`

**Controls**
- Delete:
  - `DeleteBtn:SetHeight(BTN_H)` and anchor `TOPRIGHT` of `ReaderHeader`.
- Title/placeholder:
  - Anchor `LEFT` of `ReaderHeader`, vertically centered, with max width = header width minus delete button width minus gutter.
- Nav row:
  - Either:
    - (A) inside `ReaderHeader` bottom-aligned, OR
    - (B) a `ReaderNavRow` right under header with fixed height.
  - In either case: Prev, page label, Next are aligned to the same vertical center and share identical baseline.

**Acceptance**
- Placeholder text never overlaps Delete.
- Prev/Next/page label sit on one clean row above the scroll content.

---

## 7) Reader scroll content: start below header/nav, with consistent margins

### 7.1 Anchor reader scroll frame properly
- `ReaderScroll:SetPoint("TOPLEFT", ReaderHeader (or ReaderNavRow), "BOTTOMLEFT", 0, -GUTTER)`
- `ReaderScroll:SetPoint("BOTTOMRIGHT", ReaderInset, "BOTTOMRIGHT", -PAD, PAD)`

**Acceptance**
- Reader text begins below controls; no floating UI elements inside scroll region.

---

## 8) Normalize template quirks (most common alignment offender)

### 8.1 Standardize font objects and vertical offsets
- Use one font object for header titles, one for metadata.
- Avoid mixing `GameFontNormalLarge` with custom sizes unless you also normalize line height.

**Action**
- For each `FontString`, explicitly set:
  - `:SetJustifyV("MIDDLE")`
  - `:SetJustifyH("LEFT")`

**Acceptance**
- No “half-pixel” visual drift between title, count, and list headers.

---

## 9) Add a debug overlay to catch drift fast (temporary dev feature)

### 9.1 Toggleable gridlines
Add `/ba uigrid` that draws:
- HeaderFrame bounds
- BodyFrame bounds
- ListHeaderRow bounds
- ReaderHeader bounds

**Implementation**
- Create thin texture lines (1px) and show/hide.
- Remove or keep behind a dev flag.

**Acceptance**
- You can visually verify all top edges and gutters are identical.

---

## 10) Codex Task Checklist (in strict order)

1. Add `UI_METRICS` constants and replace magic numbers.
2. Rebuild HeaderFrame as 2-row container; re-anchor search/sort/actions to rows.
3. Add BodyFrame and re-anchor ListInset + ReaderInset to it (same top/bottom).
4. Replace “Saved Books” + tabs with single `ListHeaderRow`.
5. Re-anchor list scroll frame to start below `ListHeaderRow`.
6. Add `ReaderHeader` (and optional `ReaderNavRow`); move Delete + placeholder + nav into it.
7. Re-anchor reader scroll frame to start below header/nav.
8. Normalize font vertical justification.
9. Add temporary `/ba uigrid` overlay for verification.

---

## Definition of Done (Alignment)

- Header: title, search, and Options button share a clean baseline; sort aligns with count row.
- Body: ListInset and ReaderInset share identical top/bottom edges.
- List: “Saved Books” and tabs are on the same row; list rows start below them with consistent left padding.
- Reader: Delete is confined to header; placeholder and nav are aligned and never overlap content.
- No element uses ad-hoc anchoring to main frame when a row/container exists.

---
