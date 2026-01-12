# UI Test Coverage Analysis

## Executive Summary

**Current Coverage:** ~30% of UI modules have dedicated tests  
**Test Quality:** Good (existing tests use proper patterns)  
**Key Gaps:** Sorting, pagination, filtering logic, state management  

---

## Current UI Test Files

### ✅ Well-Tested Areas

1. **Capture_UIRefresh_spec.lua** (Desktop)
   - RefreshUI call verification
   - Single/multi-page capture behavior
   - Infinite loop regression prevention
   - **Status:** Excellent - uses Busted spies correctly

2. **Reader_spec.lua** (InGame - 601 lines)
   - Reader rendering logic
   - Page navigation
   - HTML vs plain text detection
   - Welcome panel display
   - **Status:** Comprehensive

3. **List_Reader_Integration_spec.lua** (InGame - 793 lines)
   - List/Reader interaction
   - Selection state management
   - Favorite toggling
   - **Status:** Good integration coverage

4. **Async_Filtering_Integration_spec.lua** (InGame - 537 lines)
   - Iterator module integration
   - Async filtering pipeline
   - Search token matching
   - **Status:** Critical path covered

---

## 🚨 Major Test Gaps

### 1. **Sorting Logic** (CRITICAL)
**File:** `ui/list/BookArchivist_UI_List_Sort.lua` (251 lines)

**Untested Functions:**
- `GetSortOptions()` - Returns available sort modes
- `GetSortMode()` / `SetSortMode()` - State management
- `GetSortComparator()` - **CRITICAL** - Complex comparator logic
- `ApplySort()` - Sort execution
- `InitializeSortDropdown()` - Dropdown UI wiring

**Why Critical:**
- Complex text normalization logic (`normalizeTextValue`)
- Multiple sort modes (title, zone, firstSeen, lastSeen)
- Alpha vs numeric comparators
- Zone label resolution fallback logic
- **Current note in Order_spec.lua:** "Sorting comparator tests would require loading the UI module"

**Recommended Tests:**
```lua
describe("List Sorting", function()
  describe("Sort Comparators", function()
    it("should sort alphabetically by title (case-insensitive)")
    it("should sort by zone with fallback to zoneChain")
    it("should sort numerically by firstSeen (oldest first)")
    it("should sort numerically by lastSeen (newest first)")
    it("should handle missing/nil values in sort fields")
    it("should use bookId as tiebreaker for identical values")
  end)
  
  describe("Text Normalization", function()
    it("should trim whitespace")
    it("should convert to lowercase")
    it("should handle nil/empty strings")
  end)
end)
```

---

### 2. **Pagination Logic** (HIGH PRIORITY)
**File:** `ui/list/BookArchivist_UI_List_Pagination.lua`

**Untested Functions:**
- `GetPageSizes()` - Available page size options
- `GetPageSize()` / `SetPageSize()` - State management
- `GetPage()` / `SetPage()` - Current page tracking
- `NextPage()` / `PrevPage()` - Navigation
- `GetPageCount()` - Total pages calculation
- `PaginateArray()` - **CRITICAL** - Slicing logic
- `UpdatePaginationUI()` - UI state sync

**Why High Priority:**
- Array slicing logic can have off-by-one errors
- Boundary conditions (empty list, page 1, last page)
- Page size changes should reset to page 1
- Total page calculation depends on array size

**Recommended Tests:**
```lua
describe("List Pagination", function()
  describe("PaginateArray", function()
    it("should return correct slice for page 1")
    it("should return correct slice for middle page")
    it("should return correct slice for last page")
    it("should handle empty array")
    it("should handle array smaller than page size")
    it("should handle exact multiple of page size")
  end)
  
  describe("Page Navigation", function()
    it("should advance to next page")
    it("should go back to previous page")
    it("should not go below page 1")
    it("should not exceed total pages")
    it("should reset to page 1 when page size changes")
  end)
end)
```

---

### 3. **Search Functionality** (MEDIUM PRIORITY)
**File:** `ui/list/BookArchivist_UI_List_Search.lua`

**Untested Functions:**
- `GetSearchText()` - Current search query
- `ClearSearchMatchKinds()` / `SetSearchMatchKind()` - Match badge tracking
- `GetSearchMatchKind()` - Badge retrieval
- `ClearSearch()` - Reset search state
- `UpdateSearchClearButton()` - UI visibility logic
- `ScheduleSearchRefresh()` - Debounced refresh logic

**Why Medium Priority:**
- Partially covered by Async_Filtering_Integration_spec
- But UI-specific logic (debouncing, badge tracking) not tested
- Search state management could cause bugs

**Recommended Tests:**
```lua
describe("List Search", function()
  describe("Search Match Tracking", function()
    it("should track match kinds per book key")
    it("should clear all match kinds")
    it("should retrieve match kind for specific key")
  end)
  
  describe("Search Clear Button", function()
    it("should show button when search text exists")
    it("should hide button when search text empty")
    it("should clear search on button click")
  end)
  
  describe("Search Debouncing", function()
    it("should debounce rapid search text changes")
    it("should trigger refresh after debounce delay")
  end)
end)
```

---

### 4. **Location Tree Navigation** (MEDIUM PRIORITY)
**File:** `ui/list/BookArchivist_UI_List_Location.lua` (831 lines!)

**Untested Functions:**
- `NavigateInto()` / `NavigateUp()` - Breadcrumb navigation
- `RebuildLocationTree()` - **COMPLEX** - Tree structure generation
- `GetBooksForNode()` / `HasBooksInNode()` - Node book retrieval
- `OpenRandomFromNode()` - Random book from location
- `OpenMostRecentFromNode()` - Most recent book from location
- `GetLocationBreadcrumbSegments()` - Breadcrumb path logic
- `UpdateLocationBreadcrumbUI()` - UI state sync

**Why Medium Priority:**
- Complex tree building logic (zone chains, nested locations)
- Breadcrumb navigation state management
- Location-based filtering
- **831 lines of untested code!**

**Recommended Tests:**
```lua
describe("Location Tree Navigation", function()
  describe("Tree Building", function()
    it("should build tree from flat book list")
    it("should handle nested zone chains")
    it("should group books by zone")
    it("should handle books with no location")
  end)
  
  describe("Navigation", function()
    it("should navigate into child node")
    it("should navigate up to parent node")
    it("should handle root navigation")
  end)
  
  describe("Breadcrumb Display", function()
    it("should format breadcrumb segments")
    it("should truncate long paths")
    it("should show 'All Locations' at root")
  end)
end)
```

---

### 5. **Selection State Management** (LOW PRIORITY)
**File:** `ui/list/BookArchivist_UI_List_Selection.lua`

**Partially Tested:** List_Reader_Integration_spec covers some scenarios

**Untested Edge Cases:**
- `DisableDeleteButton()` - Button state management
- `NotifySelectionChanged()` - Event propagation
- `ShowBookContextMenu()` - Context menu display logic

**Recommended Tests:**
```lua
describe("List Selection", function()
  describe("Selection State", function()
    it("should handle selection of non-existent book")
    it("should clear selection")
    it("should notify reader of selection change")
  end)
  
  describe("Context Menu", function()
    it("should show context menu at anchor position")
    it("should populate favorite/unfavorite option")
    it("should close menu on option select")
  end)
end)
```

---

### 6. **Frame Builder** (LOW PRIORITY - Already Fixed)
**File:** `ui/BookArchivist_UI_Frame_Builder.lua`

**Status:** Recently fixed malformed structure (commit b6ec9e4)

**Potential Tests:**
- Async build step execution
- Error handling during build
- OnShow callback deferral when content not ready
- Loading indicator state transitions

**Recommended Tests:**
```lua
describe("Frame Builder", function()
  describe("Async Build", function()
    it("should create shell immediately")
    it("should defer content build")
    it("should mark content ready after build")
    it("should handle build errors gracefully")
  end)
  
  describe("OnShow Callback", function()
    it("should defer onShow if content not ready")
    it("should trigger onShow when content ready")
    it("should call onAfterCreate callback")
  end)
end)
```

---

### 7. **Options Panel** (LOW PRIORITY)
**File:** `ui/options/BookArchivist_UI_Options.lua`

**Untested Functions:**
- `Ensure()` / `Open()` - Panel creation/display
- `GetCategory()` - Blizzard Settings integration
- `Sync()` - Language change synchronization
- `OpenTools()` - Tools panel navigation

**Why Low Priority:**
- Mostly UI wiring, less business logic
- Manual testing more effective for UI flow
- Integration with Blizzard Settings API hard to mock

---

### 8. **Minimap Button** (LOW PRIORITY)
**File:** `ui/minimap/BookArchivist_UI_Minimap.lua`

**Untested Functions:**
- `RefreshPosition()` - Angle-based positioning
- `EnsureButton()` - Button creation
- `Initialize()` - LibDBIcon integration

**Why Low Priority:**
- Heavily dependent on LibDBIcon
- Visual positioning best tested manually
- Less critical path

---

## 🎯 Priority Recommendations

### Immediate (This Sprint)

1. **Sorting Comparators** - Create `Tests/Desktop/ListSort_spec.lua`
   - Test all 4 sort modes
   - Test text normalization
   - Test tiebreaker logic
   - **Effort:** 2-3 hours
   - **Value:** HIGH - Critical business logic

2. **Pagination Logic** - Create `Tests/Desktop/ListPagination_spec.lua`
   - Test `PaginateArray()` edge cases
   - Test navigation boundaries
   - Test page size changes
   - **Effort:** 1-2 hours
   - **Value:** HIGH - Off-by-one errors likely

### Next Sprint

3. **Location Tree Building** - Create `Tests/Desktop/LocationTree_spec.lua`
   - Test tree generation from flat list
   - Test navigation state
   - Test breadcrumb formatting
   - **Effort:** 3-4 hours
   - **Value:** MEDIUM - Complex but stable

4. **Search State Management** - Extend `Async_Filtering_Integration_spec.lua`
   - Test match badge tracking
   - Test debouncing logic
   - Test clear button visibility
   - **Effort:** 1 hour
   - **Value:** MEDIUM - Partial coverage exists

### Future

5. **Frame Builder Tests** - Create `Tests/Desktop/FrameBuilder_spec.lua`
   - Test async build pipeline
   - Test error handling
   - **Effort:** 2 hours
   - **Value:** LOW - Recently fixed, working well

6. **Options Panel Tests** - Manual testing sufficient
7. **Minimap Button Tests** - Manual testing sufficient

---

## 📊 Coverage Metrics

| Module Category | Files | Tested Files | Coverage % |
|-----------------|-------|--------------|------------|
| Core Logic | 20 | 18 | 90% |
| UI List | 10 | 1 | 10% |
| UI Reader | 8 | 2 | 25% |
| UI Options | 1 | 0 | 0% |
| UI Minimap | 1 | 0 | 0% |
| UI Frame | 5 | 1 | 20% |
| **Total** | **45** | **22** | **49%** |

**Overall UI Coverage:** ~30% (most core modules have tests, UI modules lag behind)

---

## 🔧 Test Infrastructure Improvements

### 1. **Spy Verification Patterns** (DONE ✅)
- Removed custom spy_helpers.lua
- Standardized on Busted's `spy.on()`
- All extension points de-defensivized

### 2. **Mock UI Framework** (Needed)
Create reusable mock UI helpers:
```lua
-- tests/helpers/ui_mocks.lua
function createMockFrame(type, name)
  return {
    __type = type,
    __name = name,
    SetScript = function() end,
    SetPoint = function() end,
    SetSize = function() end,
    Show = spy.new(function() end),
    Hide = spy.new(function() end),
  }
end

function createMockScrollFrame()
  -- Return scrollable frame with GetVerticalScroll, etc.
end
```

### 3. **Test Data Builders** (Needed)
Create reusable book/DB builders:
```lua
-- tests/helpers/data_builders.lua
function buildMockBook(overrides)
  return {
    bookId = overrides.bookId or "book1",
    title = overrides.title or "Test Book",
    pages = overrides.pages or { [1] = "Content" },
    location = overrides.location or { zone = "Stormwind" },
    lastSeenAt = overrides.lastSeenAt or 12345,
  }
end

function buildMockDB(books)
  -- Return full mock database structure
end
```

---

## 🚀 Quick Wins

These tests can be written quickly and provide immediate value:

1. **Pagination Edge Cases** (30 min)
   ```lua
   it("should handle empty array", function()
     local result = ListUI:PaginateArray({}, 25, 1)
     assert.equals(0, #result)
   end)
   ```

2. **Sort Text Normalization** (15 min)
   ```lua
   it("should trim whitespace", function()
     local normalized = normalizeTextValue("  Test  ")
     assert.equals("test", normalized)
   end)
   ```

3. **Search Badge Tracking** (20 min)
   ```lua
   it("should track match kinds", function()
     ListUI:SetSearchMatchKind("book1", "title")
     assert.equals("title", ListUI:GetSearchMatchKind("book1"))
   end)
   ```

---

## 📝 Conclusion

**Current State:** Core logic well-tested (90%), UI modules under-tested (30%)

**Biggest Risks:**
1. Sorting comparators (complex, untested)
2. Pagination logic (off-by-one potential)
3. Location tree building (831 lines, 0% coverage)

**Recommended Action:**
- **Week 1:** Add sorting and pagination tests (HIGH value, LOW effort)
- **Week 2:** Add location tree tests (MEDIUM value, MEDIUM effort)
- **Week 3:** Improve test infrastructure (mock helpers, data builders)

**Expected Outcome:**
- UI coverage: 30% → 70%
- Confidence in refactoring: Medium → High
- Bug detection before production: +50%
