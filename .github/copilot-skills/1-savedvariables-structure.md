# SavedVariables Structure & Database Layer

## Overview
BookArchivist persists all data in `BookArchivistDB` (SavedVariablesPerCharacter), meaning each character has their own library.

## Core Database Schema (v2)

### BookArchivistDB Structure
```lua
BookArchivistDB = {
  -- Schema control
  dbVersion = 2,              -- Migration version (v1->v2 introduces booksById)
  version = 1,                -- Legacy version field
  createdAt = <timestamp>,    -- Unix timestamp of DB creation
  
  -- Primary storage (v2+)
  booksById = {               -- Main book storage (keyed by stable book ID)
    ["b2:<hash>"] = <BookEntry>
  },
  
  -- Ordering & UI state
  order = { "b2:abc123", ... },  -- Array of book IDs (insertion order)
  uiState = {                    -- Per-character UI state (v2+)
    lastCategoryId = "__all__",  -- Last selected category/filter
    lastBookId = "b2:abc123",    -- Last opened book
  },
  
  -- User preferences
  options = {
    language = "enUS",           -- Locale (enUS, esES, caES, deDE, frFR, itIT, ptBR)
    debug = false,               -- Debug logging (dev-only)
    uiDebug = false,             -- UI debug grid (dev-only)
    tooltip = { enabled = true }, -- GameTooltip integration
    ui = {
      virtualCategoriesEnabled = true,  -- Show/hide Favorites/Recent categories
    },
    minimapButton = {
      angle = 200,               -- Minimap button position (degrees)
    },
  },
  
  -- Recently read tracking (v2+)
  recent = {
    cap = 50,                    -- Max MRU entries
    list = { "b2:xyz", ... },    -- Book IDs in reverse-chronological order
  },
  
  -- Indexes for fast lookups
  indexes = {
    objectToBookId = { [objectID] = "b2:hash" },     -- GameObject/NPC -> book
    itemToBookIds = { [itemID] = { ["b2:hash"] = true } }, -- Item -> books (set)
    titleToBookIds = { ["normalized title"] = { ["b2:hash"] = true } }, -- Title -> books (set)
    _titleIndexBackfilled = true,  -- Flag: title index backfill complete
    _titleIndexPending = false,     -- Flag: title index backfill in progress
  },
  
  -- Legacy data (frozen after v2 migration, read-only)
  legacy = {
    version = 1,
    books = { ... },   -- Original books table (by compound key)
    order = { ... },   -- Original order array
  },
  
  -- Migration tracking
  migrations = {
    authorPruned = true,  -- Flag: legacy author field cleaned up
  },
}
```

### BookEntry Schema
```lua
{
  -- Unique identifier (v2)
  id = "b2:<hash>",         -- Stable ID (FNV-1a hash of objectID + title + first page)
  
  -- Metadata
  title = "Book Title",
  creator = "Author Name",  -- Displayed as "Author" in UI (renamed from "author")
  material = "Parchment",
  
  -- Content
  pages = {
    [1] = "Page 1 text...",
    [2] = "Page 2 text...",
  },
  
  -- Search optimization (v2+)
  searchText = "normalized title\npage 1 text\npage 2 text",  -- Pre-built lowercase search index
  
  -- Provenance
  source = {
    kind = "itemtext"|"world"|"inventory",  -- Capture source type
    itemID = 12345,                         -- Item ID (if applicable)
    guid = "GameObject-0-...",              -- GUID of source NPC/object
    objectType = "GameObject"|"Creature",   -- Type from GUID
    objectID = 12345,                       -- Extracted from GUID
    page = 1,                               -- ItemTextFrame page number
  },
  
  location = {
    -- Zone chain
    zoneChain = { "Kalimdor", "Durotar", "Orgrimmar" },  -- Hierarchical zone path
    zoneText = "Kalimdor > Durotar > Orgrimmar",         -- Display string
    mapID = 85,                             -- C_Map map ID
    
    -- Loot context (if available)
    context = "loot"|"world",               -- How book was acquired
    sourceName = "Mysterious Crate",        -- Container/NPC name
    sourceGUID = "GameObject-0-...",        -- Source GUID
    isFallback = true,                      -- True if location is guessed (no loot data)
  },
  
  -- Statistics
  seenCount = 3,           -- Number of times captured (increments on re-read)
  firstSeenAt = <ts>,      -- Unix timestamp of first capture
  lastSeenAt = <ts>,       -- Unix timestamp of last capture
  createdAt = <ts>,        -- Unix timestamp of entry creation
  updatedAt = <ts>,        -- Unix timestamp of last update
  lastReadAt = <ts>,       -- Unix timestamp of last UI open (for Recent tracking)
  
  -- Flags
  isFavorite = false,      -- User favorite flag (for Favorites category)
  
  -- Legacy conflict marker
  legacy = {
    importConflict = true,  -- Set if import merging detected conflicting data
  },
}
```

## Key Functions

### Database Initialization
**File:** `core/BookArchivist_DB.lua`

```lua
-- Initialize/migrate database
BookArchivist.DB:Init()
  → DBSafety:SafeLoad()           -- Load DB with corruption detection
  → DBSafety:HealthCheck()        -- Validate structure
  → DBSafety:RepairDatabase()     -- Auto-repair if needed
  → Migrations.v1(db)             -- Apply v1 migration (annotation only)
  → Migrations.v2(db)             -- Apply v2 migration (booksById + indexes)
```

### Core Database Operations
**File:** `core/BookArchivist_Core.lua`

```lua
-- Access database (auto-initializes)
Core:GetDB() → BookArchivistDB

-- Persist a capture session to booksById
Core:PersistSession(session) → persistedEntry
  → BookId.MakeBookIdV2(session)   -- Generate stable book ID
  → Merge with existing entry (if ID exists)
  → Update indexes (objectToBookId, itemToBookIds, titleToBookIds)
  → Prepend to order[] array
  → Return entry reference

-- Index management
Core:IndexItemForBook(itemID, bookId)
Core:IndexObjectForBook(objectID, bookId)
```

### Migrations
**File:** `core/BookArchivist_Migrations.lua`

- **v1:** Annotation-only (sets `dbVersion = 1`)
- **v2:** Introduces `booksById` and stable book IDs
  - Freezes legacy data in `db.legacy`
  - Converts `db.books` → `db.booksById` with merge semantics
  - Builds `objectToBookId`, `itemToBookIds`, `titleToBookIds` indexes
  - Updates `db.order` to use new book IDs

### Book ID Generation
**File:** `core/BookArchivist_BookId.lua`

```lua
-- Generate stable v2 book ID
BookId.MakeBookIdV2(book) → "b2:<hash>"
  → Extract objectID from source (or use 0)
  → Normalize title (lowercase, strip markup, collapse whitespace)
  → Extract and normalize first page text (first 512 chars)
  → Concatenate: objectID|titleNorm|firstPageNorm
  → FNV-1a 32-bit hash
  → Return "b2:<hash>"
```

## Data Flow

### Read Path
1. User opens BookArchivist UI
2. `Core:GetDB()` ensures DB is initialized/migrated
3. UI reads from `booksById`, `order`, `uiState`
4. Indexes used for fast lookups (tooltips, item detection)

### Write Path (Capture)
1. `ITEM_TEXT_BEGIN` → `Capture:OnBegin()` → create session
2. `ITEM_TEXT_READY` → `Capture:OnReady()` → capture page text
3. After each page: `Core:PersistSession()` → update `booksById`, `order`, indexes
4. Indexes automatically updated for item/object/title lookups

### Write Path (Import)
1. User pastes payload → `ImportWorker:Start()`
2. Decode BDB1 envelope → deserialize → validate schema
3. Merge incoming books into `booksById` (by book ID)
4. Update `order[]` with new IDs
5. Backfill `searchText` and indexes for imported books

## Index Usage

### Object Index (objectToBookId)
- **Key:** GameObject/Creature ID (from GUID)
- **Value:** Book ID
- **Use Case:** Tooltip on world objects, auto-open on interaction

### Item Index (itemToBookIds)
- **Key:** Item ID
- **Value:** Set of book IDs (multiple books can come from same item)
- **Use Case:** Tooltip on inventory items, loot tracking

### Title Index (titleToBookIds)
- **Key:** Normalized title (lowercase, no markup, single spaces)
- **Value:** Set of book IDs
- **Use Case:** Fast title-based search/duplicate detection

## Important Notes

1. **Per-Character:** `BookArchivistDB` is `SavedVariablesPerCharacter` - no account-wide sharing
2. **Stable IDs:** v2 book IDs are deterministic (same book = same ID across characters)
3. **Incremental Persistence:** Books are saved after EACH page during capture (safe against UI closures)
4. **Merge Semantics:** Re-reading a book increments `seenCount`, updates timestamps, merges pages
5. **Legacy Freeze:** v1 data is frozen in `db.legacy`, never modified by new code
6. **Index Backfilling:** Title index is backfilled asynchronously with 2s delay + throttled iteration
7. **Corruption Handling:** `DBSafety` detects/repairs common corruption patterns (missing tables, nil entries)

## Common Patterns

### Check if book exists by ID
```lua
local db = Core:GetDB()
local book = db.booksById[bookId]
if book then
  -- Book exists
end
```

### Get all books in order
```lua
local db = Core:GetDB()
for _, bookId in ipairs(db.order) do
  local book = db.booksById[bookId]
  -- Process book
end
```

### Find books by item ID
```lua
local db = Core:GetDB()
local bookIds = db.indexes.itemToBookIds[itemID]
if bookIds then
  for bookId in pairs(bookIds) do
    local book = db.booksById[bookId]
    -- Process book
  end
end
```

### Update book metadata
```lua
local db = Core:GetDB()
local book = db.booksById[bookId]
if book then
  book.isFavorite = true
  book.updatedAt = time()
  -- Changes are automatically persisted (SavedVariables)
end
```
