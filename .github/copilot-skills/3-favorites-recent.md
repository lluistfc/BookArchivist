# Favorites & Recent Systems

## Overview
BookArchivist provides two special categories for organizing books:
1. **Favorites** - User-marked books for quick access
2. **Recent** - Most Recently Used (MRU) list of opened books

Both systems are per-character (stored in `BookArchivistDB`).

## Favorites System

### Data Storage
**Location:** `BookArchivistDB.booksById[bookId].isFavorite`

```lua
-- Each book entry has a favorite flag
{
  id = "b2:abc123",
  title = "My Book",
  isFavorite = true,  -- Boolean flag
  -- ... other fields
}
```

### Core API
**File:** `core/BookArchivist_Favorites.lua`

```lua
-- Set favorite state
Favorites:Set(bookId, value)
  → Update entry.isFavorite = true|false
  → Update entry.updatedAt = now()
  → Auto-persisted (SavedVariables)

-- Toggle favorite state
Favorites:Toggle(bookId)
  → Read current state
  → Call Set(bookId, !currentState)

-- Check if book is favorite
Favorites:IsFavorite(bookId) → boolean
  → Return entry.isFavorite or false
```

### UI Integration

**List Panel - Favorites Category:**
```lua
-- Category filter (see 7-list-panel.md)
categoryId = "__favorites__"

-- Filter logic (BookArchivist_UI_List_Filter.lua)
EntryMatchesFilters(entry)
  → If categoryId == "__favorites__":
    return entry.isFavorite == true
```

**Reader Panel - Favorite Button:**
```lua
-- Toggle button in reader header
OnClick: Favorites:Toggle(currentBookId)
  → Update button visual state (star icon)
  → Refresh list (book may appear/disappear from Favorites category)
```

**Reader Button States:**
- **Favorited:** Yellow star icon
- **Not favorited:** Gray star icon (outline)
- **No book selected:** Button disabled

### Backfilling Default State
**File:** `core/BookArchivist_Core.lua` → `ensureDB()`

```lua
-- All existing books get isFavorite = false if missing
for bookId, entry in pairs(BookArchivistDB.booksById) do
  if entry.isFavorite == nil then
    entry.isFavorite = false
  end
end
```

**Why?** Ensures consistent filtering (no nil checks needed in UI).

## Recent System (MRU)

### Data Storage
**Location:** `BookArchivistDB.recent`

```lua
BookArchivistDB.recent = {
  cap = 50,                      -- Maximum MRU entries (configurable)
  list = {                       -- Array of book IDs
    "b2:xyz789",  -- Most recent
    "b2:abc123",
    "b2:def456",
    -- ... up to cap entries
  },
}
```

**Additional per-book tracking:**
```lua
-- Each book entry tracks last read time
{
  id = "b2:abc123",
  lastReadAt = 1704908765,  -- Unix timestamp
  -- ... other fields
}
```

### Core API
**File:** `core/BookArchivist_Recent.lua`

```lua
-- Mark book as opened (called when reader displays book)
Recent:MarkOpened(bookId)
  → Update entry.lastReadAt = now()
  → Update entry.updatedAt = now()
  → Remove bookId from list (if present)
  → Prepend bookId to list (index 1 = most recent)
  → Truncate list to cap (default 50)
  → Auto-persisted (SavedVariables)

-- Get sanitized MRU list
Recent:GetList() → bookIds[]
  → Read db.recent.list
  → Filter out stale/duplicate entries:
    - Remove if book no longer exists in booksById
    - Remove duplicates (keep first occurrence)
  → Update db.recent.list with cleaned array
  → Return filtered array
```

### MRU Maintenance
```lua
ensureRecentContainer(db)
  → Ensure db.recent table exists
  → Set db.recent.cap = 50 (if not configured)
  → Ensure db.recent.list = {} (if missing)
```

Called during:
- `MarkOpened()` - Ensure container before updating
- `GetList()` - Ensure container before reading

### UI Integration

**List Panel - Recent Category:**
```lua
-- Category filter (see 7-list-panel.md)
categoryId = "__recent__"

-- Data source override (BookArchivist_UI_List_Filter.lua)
RebuildFiltered()
  → If categoryId == "__recent__":
    baseKeys = Recent:GetList()  -- Use MRU order, not db.order
  → Else:
    baseKeys = db.order  -- Normal insertion order
```

**Reader Panel - Auto-tracking:**
```lua
-- Called when reader displays a book
ReaderUI:ShowBook(bookId)
  → Reader content rendered
  → Recent:MarkOpened(bookId)
    → Book moves to top of MRU list
  → No UI refresh needed (list order unchanged from user perspective)
```

### Recent Category Behavior
- **Order:** Reverse-chronological (most recently opened first)
- **Size:** Limited to 50 books (configurable via `recent.cap`)
- **Persistence:** Updates on every book open (incremental)
- **Cross-category:** Books can be in Recent AND another category (Favorites, All Books, etc.)

### Stale Entry Cleanup
```lua
Recent:GetList()
  → Iterate db.recent.list
  → For each bookId:
    - Check if booksById[bookId] exists
    - Check if already seen (deduplicate)
    - If invalid, skip (don't add to filtered)
  → Overwrite db.recent.list with filtered array
  → Return filtered
```

**When does cleanup happen?**
- Every call to `GetList()` (typically when switching to Recent category)
- No background cleanup (on-demand only)

**Why is cleanup needed?**
- Books can be deleted (see `8-reader-panel.md`)
- Import/migration might leave stale IDs
- Ensures list never references non-existent books

## Virtual Categories Toggle

### UI Option
**File:** `core/BookArchivist_Core.lua` → `ensureDB()`

```lua
BookArchivistDB.options.ui.virtualCategoriesEnabled = true  -- Default
```

**Settings Panel:**
- Checkbox: "Show Favorites and Recent Categories"
- Enabled by default
- When disabled: Favorites/Recent tabs hidden, but data preserved

### Category Filtering Logic
**File:** `ui/list/BookArchivist_UI_List_Categories.lua`

```lua
GetCategories()
  → Check db.options.ui.virtualCategoriesEnabled
  → If false:
    categories = { { id = "__all__", label = "All Books" } }
  → If true:
    categories = {
      { id = "__all__", label = "All Books" },
      { id = "__favorites__", label = "★ Favorites" },
      { id = "__recent__", label = "Recent" },
    }
  → Return categories
```

**Effect:** Tabs disappear from UI, but backend logic still works (data not lost).

## Data Flow Diagrams

### Favorite Toggle Flow
```
User clicks favorite button in reader
  ↓
Favorites:Toggle(bookId)
  ↓
Update entry.isFavorite
  ↓
Refresh list panel
  ↓
If viewing "__favorites__" category:
  → RebuildFiltered() re-evaluates filters
  → Book appears/disappears from list
```

### Recent Update Flow
```
User selects book from list
  ↓
ReaderUI:ShowBook(bookId)
  ↓
Render book content
  ↓
Recent:MarkOpened(bookId)
  ↓
Update entry.lastReadAt
  ↓
Update db.recent.list (prepend, dedupe, truncate)
  ↓
No UI refresh needed (list already showing this book)
```

### Recent Category Display Flow
```
User selects "Recent" category tab
  ↓
List panel calls RebuildFiltered()
  ↓
categoryId == "__recent__"
  ↓
baseKeys = Recent:GetList()
  ↓
GetList() cleans stale entries
  ↓
List rendered in MRU order
```

## Performance

### Favorites
- **Toggle:** O(1) - Simple flag update
- **Filter:** O(n) - Must check each book's flag
- **Memory:** 1 byte per book (boolean flag)

### Recent
- **MarkOpened:** O(n) where n = recent.cap (max 50)
  - Linear scan to remove duplicates
  - Array manipulation (prepend, truncate)
- **GetList:** O(n) where n = recent.cap (max 50)
  - Cleanup pass filters invalid entries
- **Memory:** ~200 bytes (50 book IDs × ~4 bytes each)

**Why is MarkOpened O(n)?**
- Must scan array to remove existing entry (deduplicate)
- Could be optimized with reverse lookup map, but 50-item scan is negligible

## Common Patterns

### Add book to favorites
```lua
local Favorites = BookArchivist.Favorites
Favorites:Set(bookId, true)
```

### Remove from favorites
```lua
Favorites:Set(bookId, false)
```

### Check if book is in recent list
```lua
local Recent = BookArchivist.Recent
local recentList = Recent:GetList()
for _, id in ipairs(recentList) do
  if id == bookId then
    -- Book is in recent list
    break
  end
end
```

### Get most recently opened book
```lua
local Recent = BookArchivist.Recent
local recentList = Recent:GetList()
if #recentList > 0 then
  local mostRecentId = recentList[1]
  -- ...
end
```

### Clear recent history (manual)
```lua
-- WARNING: Deletes all recent tracking
BookArchivistDB.recent.list = {}
-- Individual lastReadAt timestamps remain on book entries
```

### Adjust recent list capacity
```lua
-- Increase capacity to 100 books
BookArchivistDB.recent.cap = 100
-- Next MarkOpened() will honor new cap
```

## Edge Cases

### Favoriting Deleted Books
**Problem:** User favorites a book, then deletes it.
**Solution:** Book is removed from `booksById`, so favorite flag disappears with it.
**No cleanup needed:** Favorites are stored per-book, not in separate index.

### Recent List After Delete
**Problem:** User deletes a book that's in recent list.
**Solution:** `GetList()` filters out invalid IDs during next read.
**Timing:** Stale ID removed on next Recent category view.

### Concurrent Favorites (Multi-window)
**Problem:** Two BookArchivist windows open, user toggles favorite in one.
**Solution:** Both windows share same `BookArchivistDB` reference (SavedVariables).
**Effect:** Changes are immediately visible (no sync needed).

### Recent Cap Overflow
**Problem:** User sets cap too high (e.g., 10,000 books).
**Solution:** No safety limit enforced. UI may slow down if cap > 1000.
**Recommendation:** Keep cap ≤ 100 for performance.

## Important Notes

1. **Per-character:** Favorites/Recent are NOT account-wide (each character has own list)
2. **No timestamps on favorites:** Only boolean flag (no "favorited at" tracking)
3. **Recent includes deleted books:** Until next `GetList()` cleanup
4. **Recent is insertion-order agnostic:** Overrides `db.order` when viewing Recent category
5. **Virtual categories can be disabled:** Data preserved, UI hidden
6. **No undo:** Toggling favorite or opening book is instant (no confirmation)

## Related Files
- `core/BookArchivist_Favorites.lua` - Favorites API
- `core/BookArchivist_Recent.lua` - Recent (MRU) API
- `ui/list/BookArchivist_UI_List_Categories.lua` - Category definitions
- `ui/list/BookArchivist_UI_List_Filter.lua` - Category filtering logic
- `ui/reader/BookArchivist_UI_Reader.lua` - Favorite button UI
