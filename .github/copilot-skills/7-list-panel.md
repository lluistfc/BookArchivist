# List Panel (Books/Locations Modes)

## Overview
The List Panel displays book collections in two modes:
1. **Books Mode** - Flat list of all books (with category filters)
2. **Locations Mode** - Hierarchical tree of books grouped by location

Both modes share the same UI space (left panel) but use different rendering and interaction patterns.

## Panel Structure

### Visual Layout
```
┌─ Left Panel ────────────────┐
│ [Books] [Locations]  ← Tabs│
│ ┌─────────────────────────┐ │
│ │ Search: [_____________] │ │
│ └─────────────────────────┘ │
│ [All] [★ Fav] [Recent]  ←Filters│
│ ┌─────────────────────────┐ │
│ │ Book Title 1            │ │
│ │ > Book Title 2 ← Selected│
│ │ Book Title 3            │ │
│ │ ...                     │ │
│ │                         │ │
│ └─────────────────────────┘ │
│ Page 1 of 10 [<] [>] ← Pagination│
└─────────────────────────────┘
```

### Frame Hierarchy
```
LeftPanel
  ├─ TabContainer
  │   ├─ BooksTab (Button)
  │   └─ LocationsTab (Button)
  ├─ SearchBox (EditBox)
  ├─ FilterButtonRow
  │   ├─ AllBooksButton
  │   ├─ FavoritesButton
  │   └─ RecentButton
  ├─ ListScrollFrame
  │   └─ RowContainer (pooled buttons)
  └─ FooterRow
      ├─ PageLabel ("Page X of Y")
      ├─ PrevPageButton
      └─ NextPageButton
```

## Books Mode

### Data Flow
```
User interaction (search/filter/category)
  ↓
RebuildFiltered() → filteredKeys[]
  ↓
UpdateList() → Render visible rows
  ↓
User selects book
  ↓
setSelectedKey(bookId)
  ↓
RefreshReader()
```

### RebuildFiltered() Logic
**File:** `ui/list/BookArchivist_UI_List_Filter.lua`

```lua
RebuildFiltered()
  → Get base keys:
    - If category == "__recent__":
      baseKeys = Recent:GetList()  -- MRU order
    - Else:
      baseKeys = db.order  -- Insertion order
  
  → Parse search query:
    - tokens = split(query.lower(), " ")
  
  → For each bookId in baseKeys:
    - entry = db.booksById[bookId]
    - If matches(entry, tokens):
      → table.insert(filteredKeys, bookId)
  
  → Update pagination state
  → Trigger UpdateList()
```

**Match logic:**
```lua
matches(entry, tokens)
  → Check category filter:
    - If category == "__all__": pass
    - If category == "__favorites__": entry.isFavorite must be true
    - If category == "__recent__": already pre-filtered by Recent:GetList()
  
  → Check search tokens:
    - haystack = entry.searchText.lower()
    - For each token:
      - If not haystack.find(token): return false
  
  → Return true (all filters passed)
```

### Async Filtering (Performance)
**File:** `ui/list/BookArchivist_UI_List_Filter.lua`

```lua
RebuildFiltered()
  → If #baseKeys > 0:
    - Use Iterator for throttled filtering
    - Budget: 16ms per frame (maintains 60 FPS)
    - Show "Filtering books..." indicator
    - Disable tabs during filtering
  
  → Iterator.ThrottledForEach(baseKeys, processFn, onComplete)
    → processFn(bookId):
      - Check if matches filters
      - If yes: table.insert(filteredKeys, bookId)
    → onComplete():
      - UpdateList()
      - Enable tabs
      - Hide loading indicator
```

**Why async filtering?**
- Large libraries (1000+ books) cause UI freeze (100-200ms)
- Throttling yields to game engine every 16ms
- UI remains responsive (no freeze)

### UpdateList() Rendering
**File:** `ui/list/BookArchivist_UI_List_Rows.lua`

```lua
UpdateList()
  → Calculate visible range:
    - startIdx = (currentPage - 1) * pageSize + 1
    - endIdx = min(startIdx + pageSize - 1, #filteredKeys)
  
  → Release all pooled buttons: ReleaseAll()
  
  → For i = startIdx to endIdx:
    - bookId = filteredKeys[i]
    - entry = db.booksById[bookId]
    - button = GetPooledButton()
    - button:SetText(entry.title)
    - button:SetScript("OnClick", function() selectBook(bookId) end)
    - button:Show()
    - Position button at row (i - startIdx + 1)
  
  → Update pagination label: "Page X of Y"
  → Enable/disable prev/next buttons
```

**Row styling:**
- **Selected:** Blue highlight background
- **Unselected:** Transparent background
- **Hover:** Light gray background
- **Favorite:** Yellow star icon (prefix)

### Category Filters

#### Category Definitions
**File:** `ui/list/BookArchivist_UI_List_Categories.lua`

```lua
GetCategories()
  → If virtualCategoriesEnabled:
    - { id = "__all__", label = "All Books" }
    - { id = "__favorites__", label = "★ Favorites" }
    - { id = "__recent__", label = "Recent" }
  → Else:
    - { id = "__all__", label = "All Books" }
```

#### Filter Buttons UI
**File:** `ui/list/BookArchivist_UI_List_Header.lua`

```lua
CreateFilterButtons()
  → For each category:
    - button = CreateFrame("Button", ...)
    - button:SetText(category.label)
    - button:SetScript("OnClick", function()
        SetCategoryId(category.id)
        RebuildFiltered()
      end)
    - Position button in row
```

**Button states:**
- **Active:** Blue background (current category)
- **Inactive:** Gray background
- **Hover:** Light blue background

### Search Box

#### Search Input
**File:** `ui/list/BookArchivist_UI_List_Search.lua`

```lua
SearchBox:OnTextChanged()
  → Get query: SearchBox:GetText()
  → Store in state: state.search.query = query
  → Debounce: Cancel pending search
  → Schedule search after 300ms delay:
    C_Timer.After(0.3, function()
      RebuildFiltered()
    end)
```

**Why debounce?**
- Prevents re-filtering on every keystroke
- User types "dragon" (6 keystrokes) → only 1 filter pass
- Improves UX (no flicker during typing)

#### Search Query Parsing
```lua
-- Input: "dragon  book   fire"
-- Tokens: { "dragon", "book", "fire" }

-- Match logic: ALL tokens must be present (AND logic)
entry.searchText.find("dragon") AND
entry.searchText.find("book") AND
entry.searchText.find("fire")
```

**Case insensitive:** All tokens and haystack are lowercased.

### Pagination

#### Pagination State
```lua
state.pagination = {
  page = 1,          -- Current page (1-indexed)
  pageSize = 25,     -- Books per page
  lastQuery = "",    -- Last search query (for reset detection)
}
```

#### Pagination Controls
**File:** `ui/list/BookArchivist_UI_List_Pagination.lua`

```lua
UpdatePaginationControls()
  → totalPages = ceil(#filteredKeys / pageSize)
  → currentPage = clamp(state.pagination.page, 1, totalPages)
  
  → pageLabel:SetText(format("Page %d of %d", currentPage, totalPages))
  
  → prevButton:SetEnabled(currentPage > 1)
  → nextButton:SetEnabled(currentPage < totalPages)

PrevButton:OnClick()
  → state.pagination.page = state.pagination.page - 1
  → UpdateList()

NextButton:OnClick()
  → state.pagination.page = state.pagination.page + 1
  → UpdateList()
```

**Page reset triggers:**
- Search query changes
- Category changes
- Sort mode changes

### Sorting

#### Sort Modes
**File:** `ui/list/BookArchivist_UI_List_Sort.lua`

```lua
sortModes = {
  TITLE_ASC = "titleAsc",
  TITLE_DESC = "titleDesc",
  DATE_ASC = "dateAsc",
  DATE_DESC = "dateDesc",
  SEEN_ASC = "seenAsc",
  SEEN_DESC = "seenDesc",
}
```

**Default:** `TITLE_ASC` (alphabetical A-Z)

#### Sort Implementation
```lua
SortFiltered(mode)
  → compareFn = GetComparator(mode)
    - TITLE_ASC: entry1.title < entry2.title
    - DATE_DESC: entry1.lastSeenAt > entry2.lastSeenAt
    - SEEN_DESC: entry1.seenCount > entry2.seenCount
  
  → table.sort(filteredKeys, function(id1, id2)
      local entry1 = db.booksById[id1]
      local entry2 = db.booksById[id2]
      return compareFn(entry1, entry2)
    end)
  
  → UpdateList()
```

**Applied when:**
- Sort mode changes (user clicks column header)
- After RebuildFiltered() (maintains sort)

## Locations Mode

### Data Structure (Location Tree)
```lua
locationTree = {
  zoneText = "Kalimdor > Durotar > Orgrimmar",
  bookCount = 5,
  children = {
    ["Kalimdor"] = {
      zoneText = "Kalimdor",
      bookCount = 5,
      children = {
        ["Durotar"] = {
          zoneText = "Durotar",
          bookCount = 3,
          children = {
            ["Orgrimmar"] = {
              zoneText = "Orgrimmar",
              bookCount = 2,
              books = { "b2:abc", "b2:def" },
              children = {},
            }
          }
        }
      }
    }
  }
}
```

### Tree Building
**File:** `ui/list/BookArchivist_UI_List_Location.lua`

```lua
BuildLocationTree()
  → root = { children = {}, bookCount = 0 }
  
  → For each bookId in filteredKeys:
    - entry = db.booksById[bookId]
    - zoneChain = entry.location.zoneChain
    
    - If no zoneChain: use "Unknown Location"
    
    - Walk tree:
      node = root
      For each zone in zoneChain:
        - If not node.children[zone]:
          node.children[zone] = { children = {}, books = {} }
        - node = node.children[zone]
        - node.bookCount++
      
      - table.insert(node.books, bookId)
  
  → Return root
```

### Tree Rendering (Hierarchical Rows)
**File:** `ui/list/BookArchivist_UI_List_Location.lua`

```lua
RenderLocationTree()
  → Release all pooled buttons
  
  → visibleRows = FlattenTree(root, expandedNodes)
    → Depth-first traversal
    → Skip collapsed nodes
  
  → For each row in visibleRows[startIdx:endIdx]:
    - button = GetPooledButton()
    - indent = row.depth * 20  -- Indent children
    - button:SetText(("  "):rep(row.depth) .. row.label)
    
    - If row is folder:
      - icon = row.expanded ? "▼" : "▶"
      - button:SetScript("OnClick", ToggleExpand)
    
    - If row is book:
      - button:SetScript("OnClick", SelectBook)
    
    - Position button at visual index
```

**Expansion state:**
```lua
expandedNodes = {
  ["Kalimdor"] = true,
  ["Kalimdor > Durotar"] = true,
  -- Collapsed: ["Kalimdor > Durotar > Orgrimmar"]
}
```

**Stored in:** `BookArchivistDB.uiState.locationExpansion` (persisted across sessions)

### Location Breadcrumbs
**File:** `ui/list/BookArchivist_UI_List_Location.lua`

```lua
UpdateLocationBreadcrumb(locationPath)
  → breadcrumb = table.concat(locationPath, " > ")
  → breadcrumbLabel:SetText(breadcrumb)
  
  → If locationPath is empty:
    - Show "All Locations"
  → Else:
    - Show path: "Kalimdor > Durotar > Orgrimmar"
```

**Clickable breadcrumbs (future improvement):**
- Click "Kalimdor" → Navigate to Kalimdor node
- Click ">" separator → No action

## Tabs (Mode Switching)

### Tab State
**File:** `ui/list/BookArchivist_UI_List_Tabs.lua`

```lua
state.selectedListTab = 1  -- 1 = Books, 2 = Locations
```

**Persisted in:** `BookArchivistDB.uiState.listMode` ("books" or "locations")

### Tab Switching Logic
```lua
SwitchTab(tabId)
  → state.selectedListTab = tabId
  → mode = TabIdToMode(tabId)  -- 1 → "books", 2 → "locations"
  → setListMode(mode)
  
  → If mode == "locations":
    - BuildLocationTree()
    - RenderLocationTree()
  → Else:
    - RebuildFiltered()
    - UpdateList()
  
  → Update tab visuals (active/inactive)
```

**Tab locking during async operations:**
```lua
SetTabsEnabled(enabled)
  → BooksTab:SetEnabled(enabled)
  → LocationsTab:SetEnabled(enabled)
```

**Why lock?**
- Prevents tab switching during filtering (would break async iterator)
- Prevents race conditions (multiple RebuildFiltered() calls)

## Performance

### Filtering Performance
- **Small libraries (<100 books):** 1-5ms (synchronous)
- **Large libraries (1000+ books):** 500ms-1s (async, throttled)
- **Search with tokens:** +10-20% overhead per token

### Rendering Performance
- **Pooled buttons:** 0 allocation cost (reuse existing)
- **Pagination:** Only 25 rows rendered (not all 1000)
- **Anchor updates:** ~0.1ms per row

### Memory
- **filteredKeys array:** ~4KB per 1000 books
- **Button pool:** ~25 buttons × 2KB = 50KB (cached forever)
- **Location tree:** ~10KB per 1000 books (rebuilt each time)

## Common Patterns

### Trigger list refresh
```lua
ListUI:RebuildFiltered()
  → Rebuilds filteredKeys
  → Calls UpdateList() automatically
```

### Get current selection
```lua
local bookId = Internal.getSelectedKey()
```

### Change category
```lua
ListUI:SetCategoryId("__favorites__")
ListUI:RebuildFiltered()
```

### Search programmatically
```lua
local searchBox = ListUI:GetFrame("searchBox")
if searchBox then
  searchBox:SetText("dragon")
  -- Triggers OnTextChanged → RebuildFiltered()
end
```

### Get filtered count
```lua
local filtered = Internal.getFilteredKeys()
local count = #filtered
```

## Edge Cases

### Empty Library (No Books)
**Result:**
- "No books found" label displayed
- Pagination hidden
- Categories still visible

### All Books Filtered Out
**Result:**
- "No results found" label displayed
- Search box still active (user can clear search)

### Async Filtering Interrupted (Tab Switch)
**Result:**
- Filtering canceled
- Tabs re-enabled
- Partial filteredKeys discarded

### Location Tree with No Locations
**Result:**
- All books grouped under "Unknown Location"
- Single-level tree (no hierarchy)

### Search Query with No Matches
**Result:**
- filteredKeys = {}
- "No results found" displayed
- Search box highlighted (red border)

## Important Notes

1. **Async filtering is always used** - Even for small datasets (yields to prevent freeze)
2. **Pagination resets on query change** - User types new search → page resets to 1
3. **Category filters are mutually exclusive** - Only one category active at a time
4. **Location mode rebuilds tree every time** - Not cached (could be optimized)
5. **Search is AND logic** - All tokens must match (not OR)
6. **Sort is stable** - Books with same sort key preserve original order
7. **Tabs locked during async ops** - Prevents race conditions

## Related Files
- `ui/list/BookArchivist_UI_List.lua` - Main list module
- `ui/list/BookArchivist_UI_List_Filter.lua` - Filtering logic
- `ui/list/BookArchivist_UI_List_Rows.lua` - Row rendering
- `ui/list/BookArchivist_UI_List_Sort.lua` - Sorting logic
- `ui/list/BookArchivist_UI_List_Pagination.lua` - Pagination controls
- `ui/list/BookArchivist_UI_List_Tabs.lua` - Tab switching
- `ui/list/BookArchivist_UI_List_Location.lua` - Locations mode
- `ui/list/BookArchivist_UI_List_Search.lua` - Search box
- `ui/list/BookArchivist_UI_List_Categories.lua` - Category definitions

## Future Improvements (Not Implemented)
- Cache location tree (rebuild only when books change)
- OR logic for search tokens ("dragon OR book")
- Advanced filters (date range, seen count range)
- Multi-select (bulk favorite, bulk delete)
- Drag-and-drop sorting (custom order)
- Column headers for sorting (clickable)
- Export filtered subset (not entire library)
