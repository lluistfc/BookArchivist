# Book Capture System (Reading Flow)

## Overview
The Capture system hooks into WoW's ItemText events to automatically record book/letter content when players read them in-game. All captures flow through an incremental persistence model.

## Event Flow

### WoW ItemText Event Sequence
```
Player opens book/letter
  ↓
ITEM_TEXT_BEGIN
  ↓
ITEM_TEXT_READY (page 1)
  ↓
[User clicks Next Page]
  ↓
ITEM_TEXT_READY (page 2)
  ↓
[Repeat for each page]
  ↓
ITEM_TEXT_CLOSED
```

## Capture Session Lifecycle

### 1. Session Start (ITEM_TEXT_BEGIN)
**File:** `core/BookArchivist_Capture.lua` → `Capture:OnBegin()`

**Flow:**
```lua
Capture:OnBegin()
  → Create session table:
    {
      title = "",
      creator = "",
      material = "",
      pages = {},
      source = currentSourceInfo(),       -- Extract from ItemTextFrame + GUID
      firstPageSeen = nil,
      startedAt = now(),
      itemID = ItemTextFrame.itemID,
      sourceKind = "inventory"|"world",
      location = nil,
      seenPages = {},
    }
  → If not itemID: ensureSessionLocation(session)  -- Build world location
```

**Source Detection:**
- **itemID:** From `ItemTextFrame.itemID` (if player opened an item)
- **GUID:** From `UnitGUID("npc")` (if player interacted with NPC/GameObject)
- **objectID:** Extracted from GUID (used for stable book ID)
- **sourceKind:** "inventory" (item in bags) or "world" (NPC/GameObject)

### 2. Page Capture (ITEM_TEXT_READY)
**File:** `core/BookArchivist_Capture.lua` → `Capture:OnReady()`

**Flow:**
```lua
Capture:OnReady()
  → If no session: call OnBegin() (defensive)
  → Resolve page number: ItemTextGetPage() or default to 1
  → Extract metadata:
    - title: ItemTextGetTitle() or ItemTextGetItem()
    - creator: ItemTextGetCreator()
    - material: ItemTextGetMaterial()
    - text: ItemTextGetText()
  → Sanitize all text (trim whitespace)
  → Store in session.pages[pageNum]
  → Mark page as seen: session.seenPages[pageNum] = true
  → Ensure location data: ensureSessionLocation(session)
  → **Incremental persist:** Core:PersistSession(session)
    → Index item: Core:IndexItemForBook(itemID, bookId)
    → Index object: Core:IndexObjectForBook(objectID, bookId)
  → Refresh UI (if open): BookArchivist.RefreshUI()
```

**Key Behavior:**
- **Incremental persistence:** Book is saved AFTER EACH PAGE
  - Protects against UI closure (other addons, player exit)
  - User never loses data even if they close early
- **Metadata updates:** title/creator/material updated on every page (last page wins)
- **Page merging:** If book already exists, pages are merged (existing pages preserved)

### 3. Session End (ITEM_TEXT_CLOSED)
**File:** `core/BookArchivist.lua` → event handler

**Flow:**
```lua
eventFrame:OnEvent("ITEM_TEXT_CLOSED")
  → Capture:OnClose()
    → Log final page count
    → **Final persist:** Core:PersistSession(session)
    → Clear session = nil
    → Refresh UI: BookArchivist.RefreshUI()
```

**Why final persist?**
- Defensive: Ensures any missed pages are saved
- In practice, redundant (already persisted incrementally)

## Location Resolution

### Location Data Structure
```lua
location = {
  -- Zone hierarchy
  zoneChain = { "Kalimdor", "Durotar", "Orgrimmar" },
  zoneText = "Kalimdor > Durotar > Orgrimmar",
  mapID = 85,  -- C_Map map ID
  
  -- Loot context (if available)
  context = "loot"|"world",
  sourceName = "Mysterious Crate",
  sourceGUID = "GameObject-0-...",
  isFallback = true,  -- True if location is guessed
}
```

### Location Resolution Logic
**File:** `core/BookArchivist_Location.lua`

```lua
ensureSessionLocation(session)
  → If session.itemID exists:
    - Try Location:GetLootLocation(itemID)
      → Check recentLoot cache (6-hour TTL)
      → Return loot context with source NPC/container name
  → Fallback to Location:BuildWorldLocation()
    → C_Map.GetBestMapForUnit("player")
    → Walk parent chain to build zoneChain
    → Exclude Cosmic map types (universe/dimensions)
    → If no map data, fallback to GetRealZoneText() + GetSubZoneText()
    → If still empty, use "Unknown Zone" localized string
```

### Loot Tracking
**File:** `core/BookArchivist_Location.lua` → `Location:RememberLootFrom()`

**Flow:**
```lua
LOOT_OPENED event
  → Location:RememberUnit("target")
    → UnitGUID("target") + UnitName("target")
    → Store in guidNameCache
  → LOOT_SLOT_CLEARED event (per item)
    → Extract item link → itemID
    → Store in recentLoot[itemID]:
      {
        recordedAt = now(),
        sourceGUID = targetGUID,
        sourceName = targetName,
      }
```

**Important:** Loot events fire BEFORE ItemText events, so loot context is available during capture.

## Persistence Details

### Core:PersistSession(session) Flow
**File:** `core/BookArchivist_Core.lua`

```lua
Core:PersistSession(session)
  → Generate stable book ID:
    bookId = BookId.MakeBookIdV2(session)
      → Hash(objectID | normalizedTitle | normalizedFirstPage)
      → "b2:<hash>"
  
  → Check if book exists:
    existing = booksById[bookId]
  
  → If new book:
    - Create new entry with session data
    - Set seenCount = 1
    - Set firstSeenAt = now()
    - Prepend bookId to order[] array
  
  → If existing book (re-read):
    - Merge session pages into existing.pages
    - Increment existing.seenCount
    - Update existing.lastSeenAt = now()
    - Update metadata if empty (title/creator/material)
    - Update location if empty
  
  → Build searchText:
    existing.searchText = Core:BuildSearchText(title, pages)
      → Normalize title + all page text
      → Lowercase, strip markup, collapse whitespace
      → Join with newlines
  
  → Update indexes:
    - objectToBookId[objectID] = bookId
    - itemToBookIds[itemID][bookId] = true  (set)
    - titleToBookIds[normalizedTitle][bookId] = true  (set)
  
  → Return persisted entry
```

### Merge Semantics (Re-reading Books)
When a player re-reads a book:
- **Pages:** Merge (new pages added, existing pages preserved)
- **Counters:** Increment `seenCount`
- **Timestamps:** Update `lastSeenAt`, preserve `firstSeenAt`
- **Metadata:** Only update if existing field is empty (prefer original)
- **Location:** Only update if existing field is empty

### Conflict Detection (Import Only)
Not used during capture, only during import. See `5-import-export.md`.

## Source Information

### Source Object Structure
```lua
source = {
  kind = "itemtext",               -- Always "itemtext" (simplified in recent versions)
  itemID = 12345,                  -- Item ID from ItemTextFrame.itemID
  guid = "GameObject-0-...",       -- Unit GUID from UnitGUID("npc")
  objectType = "GameObject",       -- Parsed from GUID
  objectID = 12345,                -- Parsed from GUID
  page = 1,                        -- ItemTextFrame.page
}
```

### GUID Parsing
**File:** `core/BookArchivist_Capture.lua` → `parseGuid(guid)`

```lua
-- GameObject: "GameObject-0-1234-5678-9ABC-objectID"
objectType, objectID = parseGuid(guid)

-- Creature: "Creature-0-1234-5678-instanceID-objectID-hash"
-- Vehicle: "Vehicle-0-..." (treated as Creature)
-- Item: "Item-0-1234-5678-9ABC-objectID"
```

**objectID** is the stable NPC/GameObject ID used for:
- Book ID generation (deterministic hashing)
- `objectToBookId` index (fast lookup by world object)

## UI Integration

### Capture Events → UI Refresh
```lua
ITEM_TEXT_READY
  → Capture:OnReady()
    → Core:PersistSession()
      → BookArchivist.RefreshUI()  -- If UI is open
        → List panel updates (new book appears)
        → If book is selected, reader updates
```

**Refresh behavior:**
- Only triggers if UI is currently open
- Debounced to prevent spam (see `6-ui-refresh-flow.md`)
- Uses safe refresh pipeline (see `ui/BookArchivist_UI_Core.lua`)

## Error Handling

### Defensive Patterns
1. **Session recovery:** If `OnReady()` called without session, create one
2. **Page deduplication:** `seenPages` tracks which pages were captured
3. **Nil safety:** All Blizzard API calls have nil checks
4. **Incremental saves:** Data never lost even if capture interrupted

### Common Edge Cases
- **Multi-addon conflicts:** Other addons closing ItemTextFrame early
  - **Solution:** Incremental persistence (data saved immediately)
- **Missing GUID:** Some items have no associated NPC/GameObject
  - **Solution:** Use itemID only, objectID = 0 in book ID
- **Unknown zones:** Player in instance/scenario with no map data
  - **Solution:** Fallback to "Unknown Zone" localized string

## Performance

### Capture Performance
- **Per-page overhead:** ~1-2ms (GUID parsing, text normalization, persistence)
- **Index updates:** O(1) map lookups, very fast
- **searchText generation:** O(n) where n = total characters in book
- **No blocking operations:** All synchronous, no yielding needed

### Memory
- **Session size:** ~1-5KB per book (depends on page count/length)
- **Location cache:** `recentLoot` pruned every 6 hours (see `Location:PruneLootMemory()`)
- **GUID cache:** `guidNameCache` grows unbounded (could be improved)

## Common Patterns

### Hook into capture events (other addons)
```lua
-- Listen for BookArchivist captures
local frame = CreateFrame("Frame")
frame:RegisterEvent("ITEM_TEXT_READY")
frame:SetScript("OnEvent", function()
  -- Wait for BookArchivist to persist
  C_Timer.After(0.1, function()
    local db = BookArchivistDB
    local lastBook = db.booksById[db.order[1]]
    -- Process captured book
  end)
end)
```

### Manually trigger capture (testing)
```lua
-- Simulate capture session
local session = {
  title = "Test Book",
  creator = "Test Author",
  material = "Parchment",
  pages = { [1] = "Test page 1", [2] = "Test page 2" },
  source = { kind = "itemtext", objectID = 0 },
  startedAt = time(),
}
BookArchivist.Core:PersistSession(session)
```

### Check if item has been archived
```lua
local itemID = 12345
local db = BookArchivist.Core:GetDB()
local bookIds = db.indexes.itemToBookIds[itemID]
local isArchived = bookIds and next(bookIds) ~= nil
```

## Important Notes

1. **Incremental is key:** Data persisted after every page (not just at end)
2. **Merge-friendly:** Re-reading books is safe (no data loss, no duplication)
3. **Stable IDs:** Same book always generates same book ID (across characters)
4. **Location is best-effort:** World location might be "Unknown Zone" in edge cases
5. **Loot tracking is optional:** Works if LOOT_OPENED fires before ITEM_TEXT_BEGIN
6. **No rollback:** Persistence is immediate (no transaction model)

## Related Files
- `core/BookArchivist_Capture.lua` - Main capture logic
- `core/BookArchivist_Location.lua` - Location tracking
- `core/BookArchivist_Core.lua` - Persistence (`PersistSession`)
- `core/BookArchivist_BookId.lua` - Book ID generation
- `core/BookArchivist.lua` - Event wiring (main event frame)
