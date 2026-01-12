# Feature Plan: Random Book with Location Context

**Date:** 2026-01-12  
**Status:** Approved - Ready for Implementation  
**Estimated Duration:** ~4 hours (with full TDD compliance)

---

## Executive Summary

A single button that opens a random book from the entire library while **preserving geographical context** by automatically switching to Locations mode, navigating to the book's location in the tree, and scrolling to make it visible.

This approach transforms a simple "surprise me" feature into a **serendipitous discovery tool** that teaches users about their collection's geographical distribution.

---

## Philosophy Alignment

✅ **Simplicity** - One button, clear behavior  
✅ **Native WoW UI** - Blizzard-style button and tooltip  
✅ **Performance** - O(1) selection, efficient navigation  
✅ **Data-driven** - Uses existing `location.zoneChain` data  
✅ **Non-intrusive** - Utility, not a toy  
✅ **Test-friendly** - Clear, testable logic at each phase

---

## Feature Specification

### User Interaction

**Trigger:** User clicks dice/shuffle button in list header

**System Response (sequential):**
1. Select random `bookId` from entire library (`db.booksById`)
2. Switch to Locations tab/mode
3. Navigate location tree to book's `location.zoneChain`
4. Expand location nodes to make book visible in list
5. Scroll to book's position within its location
6. Select/highlight the book row
7. Open book in reader

**Result:** User sees random book + WHERE it came from

### Edge Cases

- **Empty library** → Button disabled, tooltip: "No books in your library"
- **Single book** → Opens that book (no exclusion logic needed)
- **Currently open book** → Exclude if 2+ books exist
- **Missing location** → Fallback to "Unknown Location" (already handled)
- **Already in Locations mode** → Navigate smoothly without mode switch

---

## Technical Architecture

### Available Infrastructure (Verified)

✅ Books have `location.zoneChain` array  
✅ Locations mode builds tree from `zoneChain`  
✅ Tab switching exists (`BookArchivist_UI_List_Tabs.lua`)  
✅ Selection system exists (`ListUI:SetSelectedKey()`)  
✅ Reader opens books via `ShowBook(bookId)`

### New Components Required

1. **Selection Module** - Random book ID picker
2. **Navigation Module** - Location tree traversal + scroll positioning
3. **UI Button** - Dice icon in list header
4. **Integration** - Wire button → selection → navigation → reader

---

## Implementation Phases (TDD-Compliant)

### Phase 0: Data Audit ✓ MANDATORY FIRST

**Duration:** 15 minutes  
**Type:** Verification only (no code changes)

**Actions:**
1. Verify all books have `location.zoneChain`
2. Check fallback for books missing location
3. Confirm location tree navigation API exists

**Deliverable:** Data availability confirmation

---

### Phase 1: Core Random Selection

**Duration:** 1 hour  
**TDD Gate:** Tests written BEFORE implementation

#### Step 1: Write Tests (20 minutes)

Create `Tests/Desktop/RandomBook_spec.lua`:

```lua
describe("RandomBook Selection", function()
  it("should select random book from entire library")
  it("should exclude currently open book if multiple books exist")
  it("should handle single book library (no exclusion)")
  it("should return nil for empty library")
  it("should use uniform random distribution")
end)
```

Run `make test-errors` → Establish RED state

#### Step 2: Implement Module (30 minutes)

Create `core/BookArchivist_RandomBook.lua`:

```lua
local RandomBook = {}
BookArchivist.RandomBook = RandomBook

function RandomBook:SelectRandomBook(excludeBookId)
  local db = BookArchivist.Repository:GetDB()
  local order = db.order or {}
  
  if #order == 0 then
    return nil
  end
  
  -- Build candidate list
  local candidates = {}
  for _, bookId in ipairs(order) do
    if bookId ~= excludeBookId or #order == 1 then
      table.insert(candidates, bookId)
    end
  end
  
  if #candidates == 0 then
    return nil
  end
  
  -- Uniform random selection
  local index = math.random(1, #candidates)
  return candidates[index]
end
```

#### Step 3: Verify (10 minutes)

- Run `make test-errors` → Achieve GREEN state
- All 220 tests passing (5 new)
- No regressions

---

### Phase 2: Location Navigation

**Duration:** 1.5 hours  
**TDD Gate:** Tests written BEFORE implementation

#### Step 1: Write Tests (30 minutes)

Add to `Tests/Desktop/RandomBook_spec.lua`:

```lua
describe("RandomBook Navigation", function()
  it("should find location node for given zoneChain")
  it("should handle missing location gracefully")
  it("should expand parent nodes to make book visible")
  it("should calculate scroll position for book in location")
end)
```

Run `make test-errors` → Establish RED state

#### Step 2: Implement Navigation (45 minutes)

Add to `core/BookArchivist_RandomBook.lua`:

```lua
function RandomBook:NavigateToBookLocation(bookId)
  local db = BookArchivist.Repository:GetDB()
  local book = db.booksById[bookId]
  
  if not book then
    return false
  end
  
  local zoneChain = book.location and book.location.zoneChain
  if not zoneChain or #zoneChain == 0 then
    -- Fallback: open in Books mode
    return self:OpenInBooksMode(bookId)
  end
  
  -- 1. Switch to Locations mode
  local ListUI = BookArchivist.UI.List
  if ListUI and ListUI.SwitchToLocationsMode then
    ListUI:SwitchToLocationsMode()
  end
  
  -- 2. Navigate location tree
  -- (Expand nodes, find book position)
  -- Implementation depends on existing tree navigation API
  
  -- 3. Scroll to book
  -- (Calculate position, set scroll offset)
  
  -- 4. Select book
  if ListUI and ListUI.SetSelectedKey then
    ListUI:SetSelectedKey(bookId)
  end
  
  -- 5. Open in reader
  local Reader = BookArchivist.UI.Reader
  if Reader and Reader.ShowBook then
    Reader:ShowBook(bookId)
  end
  
  return true
end
```

#### Step 3: UI Integration (15 minutes)

- Add navigation helpers to `BookArchivist_UI_List_Location.lua`
- Add scroll-to-position helper
- Wire up mode switching

#### Step 4: Verify (10 minutes)

- Run `make test-errors` → Achieve GREEN state
- All 224 tests passing (4 new)
- No regressions

---

### Phase 3: UI Button

**Duration:** 45 minutes  
**TDD Gate:** Tests written BEFORE implementation

#### Step 1: Write Tests (15 minutes)

Create `Tests/InGame/RandomBook_UI_spec.lua`:

```lua
describe("RandomBook UI", function()
  it("should show dice button in list header")
  it("should disable button when library empty")
  it("should enable button when books exist")
  it("should show correct tooltip")
end)
```

#### Step 2: Add Button (20 minutes)

Modify `ui/list/BookArchivist_UI_List_Header.lua`:

```lua
-- Add dice/shuffle button next to other header controls
local randomBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
randomBtn:SetSize(24, 24)
randomBtn:SetPoint("RIGHT", header, "RIGHT", -10, 0)
randomBtn:SetText("🎲") -- Or use dice icon texture

randomBtn:SetScript("OnClick", function()
  local RandomBook = BookArchivist.RandomBook
  if RandomBook then
    local currentBookId = -- Get currently open book ID
    local randomBookId = RandomBook:SelectRandomBook(currentBookId)
    if randomBookId then
      RandomBook:NavigateToBookLocation(randomBookId)
    end
  end
end)

randomBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(L["RANDOM_BOOK_TOOLTIP"])
  GameTooltip:Show()
end)

randomBtn:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)
```

#### Step 3: Verify (10 minutes)

- Run `make test-errors` → All passing
- In-game visual verification
- Test button click behavior

---

### Phase 4: Polish & Localization

**Duration:** 30 minutes

#### Localization Strings

Add to all 7 locale files (`locales/*.lua`):

```lua
L["RANDOM_BOOK_TOOLTIP"] = "Open a random book from your library"
L["RANDOM_BOOK_EMPTY"] = "No books in your library"
```

#### Edge Case Handling

- Empty library → Button disabled, gray appearance
- Single book → Opens that book (no exclusion)
- Currently open book → Exclude if possible
- Missing location → Fallback to Books mode
- Smooth transitions between modes

#### Final Testing

- Test all edge cases manually in-game
- Verify tooltip displays correctly
- Check button enable/disable states
- Confirm smooth navigation to locations

---

## Success Criteria

All items must be ✓ before feature is considered complete:

- [ ] Button appears in list header
- [ ] Click selects random book from entire library
- [ ] UI switches to Locations mode automatically
- [ ] Location tree expands to show book's context
- [ ] List scrolls to make book visible
- [ ] Book row is highlighted/selected
- [ ] Reader opens the book
- [ ] All 228+ tests passing
- [ ] No regressions in existing functionality
- [ ] Empty library handled gracefully
- [ ] Single book handled correctly
- [ ] Currently open book excluded when possible
- [ ] All 7 locale files updated
- [ ] In-game verification complete

---

## Timeline Estimate

| Phase | Duration | Type |
|-------|----------|------|
| Phase 0: Data Audit | 15 min | Verification |
| Phase 1: Selection | 1 hour | TDD (write tests → implement → verify) |
| Phase 2: Navigation | 1.5 hours | TDD (write tests → implement → verify) |
| Phase 3: UI Button | 45 min | TDD (write tests → implement → verify) |
| Phase 4: Polish | 30 min | Localization + edge cases |
| **TOTAL** | **~4 hours** | Full TDD compliance |

---

## Commit Strategy

Each phase should be committed separately:

1. **Phase 1 commit:**
   ```
   feat: add random book selection core logic
   - SelectRandomBook() function with exclusion support
   - Handles empty/single book edge cases
   - All 220 tests passing (5 new tests)
   ```

2. **Phase 2 commit:**
   ```
   feat: add location navigation for random books
   - NavigateToBookLocation() expands tree and scrolls
   - Switches to Locations mode automatically
   - Handles missing location fallback
   - All 224 tests passing (4 new tests)
   ```

3. **Phase 3 commit:**
   ```
   feat: add Random Book button to list header
   - Dice icon button in header
   - Tooltip with description
   - Wired to selection + navigation pipeline
   - Button state reflects library status
   - All 228 tests passing (4 new UI tests)
   ```

4. **Phase 4 commit:**
   ```
   feat: complete Random Book feature with localization
   - Added strings to all 7 locale files
   - Edge case handling (empty/single/missing location)
   - In-game verification complete
   - All 228 tests passing
   ```

---

## Risk Mitigation

**Risk:** Missing location data for some books  
**Mitigation:** Fallback to Books mode + "Unknown Location" already implemented

**Risk:** TDD violation temptation  
**Mitigation:** DIRECTIVE ZERO enforcement, explicit test-first gates in each phase

**Risk:** UI placement conflicts with existing layout  
**Mitigation:** Use existing header frame structure, test with different window sizes

**Risk:** Performance impact from tree navigation  
**Mitigation:** Location tree already uses async Iterator, navigation is O(depth)

**Risk:** User confusion about mode switching  
**Mitigation:** Smooth animation, clear visual feedback, button tooltip explains behavior

---

## Future Enhancements (Out of Scope)

These are explicitly **NOT** part of this feature:

- ❌ Auto-play timer (no "DJ mode")
- ❌ Playlist management
- ❌ Weighted random (favorites bias)
- ❌ Random filters (genre, source, etc.)
- ❌ History tracking (avoid recent books)

If requested later, each would require separate planning and TDD implementation.

---

## Final Recommendation

**Status:** ✅ APPROVED FOR IMPLEMENTATION

This feature is:
- Philosophically aligned with BookArchivist's values
- Technically feasible with existing infrastructure
- Low-risk with clear test coverage
- High-delight with geographical discovery element

Proceed with Phase 0 data audit when ready to begin implementation.
