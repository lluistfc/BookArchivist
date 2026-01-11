# BookArchivist - Copilot Skills Index

## Purpose
This directory contains comprehensive documentation of BookArchivist's architecture, data flows, and implementation details. Use these skills as reference when implementing new features or fixing bugs.

## Quick Reference

### When You Need To...

**Work with saved data:**
→ Read: `1-savedvariables-structure.md`
- Database schema (BookArchivistDB)
- Book entry structure
- Index system (item/object/title lookups)
- Migration system

**Understand book capture:**
→ Read: `2-capture-system.md`
- ItemText event flow
- Session lifecycle (begin → ready → close)
- Incremental persistence (why it's critical)
- Location resolution (loot tracking)
- Source detection (GUID parsing)

**Add/modify Favorites or Recent features:**
→ Read: `3-favorites-recent.md`
- Favorites API (Set/Toggle/IsFavorite)
- Recent MRU list management
- Virtual categories toggle
- Category filtering logic

**Work with tooltip integration:**
→ Read: `4-tooltip-integration.md`
- GameTooltip hooks
- Index lookups (O(1) performance)
- Item vs Object vs Title detection
- Enable/disable settings

**Implement import/export features:**
→ Read: `5-import-export.md`
- BDB1 envelope format
- Async import worker (phase-based)
- Merge semantics (handling duplicates)
- Conflict detection
- Export library flow

**Debug UI refresh issues:**
→ Read: `6-ui-refresh-flow.md`
- ViewModel (shared state)
- Refresh pipeline (safe execution)
- Frame creation patterns (safeCreateFrame)
- Module communication (context injection)
- Async frame building

**Modify the list panel (left side):**
→ Read: `7-list-panel.md`
- Books vs Locations modes
- Async filtering (performance)
- Category filters (All/Favorites/Recent)
- Search box (debouncing)
- Pagination controls
- Sorting logic
- Location tree rendering

**Modify the reader panel (right side):**
→ Read: `8-reader-panel.md`
- ShowBook() flow
- Header/Actions/Nav rendering
- SimpleHTML content rendering
- Page navigation
- Delete confirmation
- Favorite button
- Share functionality

## Skill Documents

### 1. SavedVariables Structure & Database Layer
**File:** `1-savedvariables-structure.md`

**Key Topics:**
- `BookArchivistDB` schema (v2)
- Repository pattern: `Repository:Init(db)` and `Repository:GetDB()`
- `booksById` structure (main storage)
- `order`, `uiState`, `options`, `recent` tables
- Index system: `objectToBookId`, `itemToBookIds`, `titleToBookIds`
- BookEntry schema (pages, metadata, source, location, stats, flags)
- Migration system (v1 → v2)
- Book ID generation (FNV-1a hash)
- Database initialization (Repository → Core:EnsureDB())
- Test isolation via dependency injection
- Common patterns and edge cases

**When to use:**
- Adding new saved data fields
- Understanding persistence model
- Working with indexes
- Debugging data corruption
- Implementing migrations

---

### 2. Book Capture System (Reading Flow)
**File:** `2-capture-system.md`

**Key Topics:**
- WoW ItemText event sequence (BEGIN → READY → CLOSED)
- Capture session lifecycle
- Incremental persistence (saves after each page)
- Source detection (itemID, GUID, objectID)
- Location resolution (loot tracking, zone chains)
- Core:PersistSession() flow
- Merge semantics (re-reading books)
- GUID parsing (GameObject, Creature, Item)
- Performance characteristics

**When to use:**
- Debugging capture failures
- Adding new source types
- Improving location detection
- Understanding why books duplicate (or don't)
- Tracking down missing pages

---

### 3. Favorites & Recent Systems
**File:** `3-favorites-recent.md`

**Key Topics:**
- Favorites API (`Set`, `Toggle`, `IsFavorite`)
- Recent MRU list (`MarkOpened`, `GetList`)
- Data storage (per-book flag vs MRU array)
- Virtual categories toggle (show/hide)
- Category filtering logic
- Stale entry cleanup (Recent only)
- Performance (O(1) favorite, O(n) recent)

**When to use:**
- Adding new category types
- Debugging missing books in categories
- Implementing new filter rules
- Understanding MRU capacity limits
- Customizing category UI

---

### 4. Tooltip Integration System
**File:** `4-tooltip-integration.md`

**Key Topics:**
- GameTooltip hook setup (TooltipDataProcessor)
- Item vs Object vs Title detection
- Index lookups (itemToBookIds, objectToBookId, titleToBookIds)
- Title normalization (lowercase, strip markup)
- Enable/disable settings
- Performance (O(1) lookups, no iteration)
- Edge cases (stale indexes, title collisions)

**When to use:**
- Debugging missing tooltip indicators
- Adding new tooltip information
- Optimizing tooltip performance
- Understanding index validation
- Supporting new tooltip types

---

### 5. Import/Export Pipeline
**File:** `5-import-export.md`

**Key Topics:**
- BDB1 envelope format (magic|schema|payload)
- Export flow (serialize → base64 → envelope)
- Import worker (async, phase-based)
- Import phases: DECODE → DESERIALIZE → MERGE → SEARCH → TITLE → DONE
- Merge semantics (union pages, sum counters, OR flags)
- Conflict detection (metadata mismatches)
- Progress callbacks (onProgress, onDone, onError)
- Performance (8ms budget per frame)

**When to use:**
- Adding new export formats
- Implementing selective import
- Debugging import failures
- Understanding merge conflicts
- Optimizing import performance

---

### 6. UI Architecture & Refresh Flow
**File:** `6-ui-refresh-flow.md`

**Key Topics:**
- Frame hierarchy (TitleBar → Body → LeftPanel/RightPanel)
- ViewModel (shared state: filteredKeys, selectedKey, listMode)
- Refresh pipeline (ensureUI → flushPendingRefresh → refreshAll)
- Safe execution wrappers (safeStep, xpcall)
- safeCreateFrame (template fallback)
- Frame pooling (list rows)
- Module communication (context injection)
- Async frame building (yields every 8ms)
- Error handling (re-throw for BugSack)

**When to use:**
- Debugging UI refresh issues
- Adding new UI panels
- Understanding frame creation
- Implementing new refresh triggers
- Optimizing UI performance

---

### 7. List Panel (Books/Locations Modes)
**File:** `7-list-panel.md`

**Key Topics:**
- Books mode (flat list with filters)
- Locations mode (hierarchical tree)
- RebuildFiltered() (async filtering with Iterator)
- UpdateList() (render visible rows)
- Category filters (All/Favorites/Recent)
- Search box (debounced, AND logic)
- Pagination (page size, controls)
- Sorting (title, date, seen count)
- Location tree building (recursive)
- Tab switching (Books ↔ Locations)
- Performance (async filtering, button pooling)

**When to use:**
- Modifying list rendering
- Adding new filter types
- Implementing new sort modes
- Debugging search issues
- Optimizing filtering performance
- Customizing location tree

---

### 8. Reader Panel & Navigation
**File:** `8-reader-panel.md`

**Key Topics:**
- ShowBook() entry point
- Header rendering (title, creator, material, metadata)
- Action buttons (Favorite, Delete, Share)
- Page navigation (prev/next, page order)
- SimpleHTML content rendering
- HTML generation (parse WoW markup → HTML)
- Delete confirmation dialog
- Share functionality (export library)
- Status bar (location display)
- Scroll behavior (auto-hide scrollbar)
- Performance (HTML parsing, SimpleHTML layout)

**When to use:**
- Modifying reader layout
- Adding new action buttons
- Implementing new text formatting
- Debugging page navigation
- Understanding delete flow
- Customizing HTML rendering

---

## Data Flow Summary

### High-Level Architecture
```
WoW Game Events
    ↓
Capture System → Core:PersistSession()
    ↓
BookArchivistDB (SavedVariables)
    ↓
UI Refresh Pipeline
    ↓
List Panel (filteredKeys) + Reader Panel (currentBook)
```

### Capture → Persistence → UI
```
ITEM_TEXT_READY
  → Capture:OnReady()
    → Extract page text + metadata
    → Core:PersistSession(session)
      → Generate book ID (BookId.MakeBookIdV2)
      → Merge into booksById
      → Update indexes (item/object/title)
      → Prepend to order[]
    → BookArchivist.RefreshUI()
      → List panel updates (new book appears)
      → Reader updates (if viewing this book)
```

### User Interaction → UI Update
```
User selects book in list
  → ListUI:OnRowClick()
    → setSelectedKey(bookId)
    → ReaderUI:ShowBook(bookId)
      → Render header/actions/nav/content/status
      → Recent:MarkOpened(bookId)
        → Update lastReadAt
        → Update recent.list (MRU)
```

### Search/Filter → List Rebuild
```
User types in search box
  → SearchBox:OnTextChanged()
    → Debounce 300ms
    → RebuildFiltered()
      → Async filtering (Iterator)
        → For each book in baseKeys:
          - Check category filter
          - Check search tokens (AND logic)
          - If match: add to filteredKeys
        → UpdateList()
          → Render visible rows (pagination)
```

### Import → Merge → Refresh
```
User pastes payload
  → ImportWorker:Start(rawPayload)
    → Phase 1: Decode BDB1 envelope
    → Phase 2: Deserialize Lua table
    → Phase 3: Merge books into booksById
    → Phase 4: Backfill searchText
    → Phase 5: Backfill title index
    → Phase 6: Report stats + refresh UI
```

## Critical Concepts

### Incremental Persistence
**Why it matters:** Books are saved after EACH page during capture.
- Protects against UI closure (other addons, player exit)
- User never loses data even if they close ItemTextFrame early
- No "commit" or "save" button needed

### Stable Book IDs
**Why it matters:** Same book always generates same ID across captures/characters.
- Hash of: objectID | normalizedTitle | normalizedFirstPage
- Enables merge semantics (re-reading doesn't duplicate)
- Format: `"b2:<hash>"` (v2 schema)

### Index System (O(1) Lookups)
**Why it matters:** Tooltip integration is high-frequency (constant mouseover events).
- Never iterates `booksById` or `order` (would be O(n))
- Uses maps: `itemToBookIds`, `objectToBookId`, `titleToBookIds`
- Always validates against `booksById` (stale indexes ignored)

### Async Operations (UI Responsiveness)
**Why it matters:** Large libraries (1000+ books) can freeze UI for 1+ seconds.
- Filtering: Throttled iteration (yields every 16ms)
- Import: Phase-based worker (yields every 8ms)
- Frame building: Async construction (yields every 8ms)
- Result: UI maintains 60 FPS, game remains playable

### Merge Semantics (Re-reading Books)
**Why it matters:** Players often re-read books (quests, collectibles).
- Pages: Union (new pages added, existing preserved)
- Counters: Sum (`seenCount += incoming`)
- Timestamps: Min/max (`firstSeenAt = min(...)`)
- Flags: OR (`isFavorite = existing OR incoming`)
- No duplication: Same book ID → merge, not duplicate

## Common Pitfalls

### ❌ DON'T: Iterate `booksById` in hot paths
```lua
-- BAD: O(n) scan on every tooltip
for bookId, book in pairs(db.booksById) do
  if book.itemID == itemID then
    return true
  end
end

-- GOOD: O(1) index lookup
local bookIds = db.indexes.itemToBookIds[itemID]
return bookIds and next(bookIds) ~= nil
```

### ❌ DON'T: Refresh UI on every keystroke
```lua
-- BAD: Rebuilds filtered list on every character typed
SearchBox:OnTextChanged(function()
  RebuildFiltered()
end)

-- GOOD: Debounce to 300ms
SearchBox:OnTextChanged(function()
  ScheduleRebuild(0.3)  -- Only fires once after typing stops
end)
```

### ❌ DON'T: Create frames in loops without pooling
```lua
-- BAD: Creates 1000 buttons (1-second freeze)
for i, bookId in ipairs(filteredKeys) do
  local button = CreateFrame("Button", ...)
  -- render button
end

-- GOOD: Reuse pooled buttons
for i = 1, visibleRowCount do
  local button = GetPooledButton()  -- Cached
  -- render button
end
```

### ❌ DON'T: Assume SavedVariables are always valid
```lua
-- BAD: Assumes structure exists
local book = BookArchivistDB.booksById[bookId]
book.title = "New Title"  -- Crashes if bookId invalid

-- GOOD: Defensive checks
local db = Core:GetDB()  -- Ensures DB initialized
if db and db.booksById and db.booksById[bookId] then
  db.booksById[bookId].title = "New Title"
end
```

### ❌ DON'T: Modify `order` array without updating `booksById`
```lua
-- BAD: Out of sync
table.remove(db.order, 5)
-- booksById still has entry, index broken

-- GOOD: Remove from both
local bookId = db.order[5]
table.remove(db.order, 5)
db.booksById[bookId] = nil
```

## Performance Budgets

### Acceptable Latency
- **Frame creation:** <10ms per frame
- **Filtering (async):** <16ms per yield (60 FPS)
- **Import (async):** <8ms per yield (120 FPS)
- **Tooltip lookup:** <1ms (high-frequency)
- **Page navigation:** <10ms (re-parse HTML)

### Memory Limits
- **Frame cache:** ~100KB (acceptable)
- **Button pool:** ~50KB (acceptable)
- **Filtered array:** ~4KB per 1000 books (negligible)
- **Location tree:** ~10KB per 1000 books (rebuilt each time)

## Testing Checklist

When making changes, verify:

- [ ] **Capture:** Read a book in-game → appears in list
- [ ] **Search:** Type query → filtered list updates
- [ ] **Favorite:** Toggle star → book appears/disappears in Favorites
- [ ] **Delete:** Confirm dialog → book removed, next book selected
- [ ] **Import:** Paste payload → books merge correctly
- [ ] **Pagination:** Next/Prev → correct pages shown
- [ ] **Reader:** Select book → content renders, navigation works
- [ ] **Tooltip:** Mouseover item → "Archived ✓" shown
- [ ] **Locations mode:** Switch tab → tree renders correctly
- [ ] **Refresh:** Close/reopen UI → state preserved

## Debugging Tips

### Enable Debug Logging
```lua
/run BookArchivistDB.options.debug = true
/reload
-- Now check chat for debug messages
```

### Inspect Database
```lua
/run DevTools_Dump(BookArchivistDB)
```

### Check Filtered Keys
```lua
/run print(#BookArchivist.UI.Internal.getFilteredKeys())
```

### Force Full Refresh
```lua
/run BookArchivist.RefreshUI()
```

### Inspect Current Selection
```lua
/run print(BookArchivist.UI.Internal.getSelectedKey())
```

## Contributing Guidelines

When adding features:

1. **Update relevant skill document** - Keep documentation in sync
2. **Follow existing patterns** - Use context injection, safe wrappers, etc.
3. **Consider performance** - Profile hot paths, avoid O(n) in loops
4. **Add defensive checks** - Validate inputs, check for nil
5. **Test with large datasets** - 1000+ books should not freeze UI
6. **Preserve backward compatibility** - Don't break existing savedvariables

## Related Documentation

- **Main README:** `../../README.md`
- **Changelog:** `../../CHANGELOG.md`
- **Copilot Instructions:** `../.github/copilot-instructions.md`
- **Agent Instructions:** `../../AGENTS.md`

---

**Last Updated:** January 2026
**Maintained By:** BookArchivist Development Team
