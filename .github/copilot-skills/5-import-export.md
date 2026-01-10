# Import/Export Pipeline

## Overview
BookArchivist supports sharing libraries between characters/players via **BDB1** (BookArchivist Data Bundle v1) format. The pipeline is asynchronous to prevent UI freezing during large imports.

## Export Format: BDB1

### Envelope Structure
```
BDB1|<schemaVersion>|<base64Payload>
```

**Example:**
```
BDB1|1|aW52IHNlcmlhbGl6ZWQgZGF0YQ==
```

**Components:**
1. **Magic:** `BDB1` (identifies format)
2. **Schema:** `1` (payload schema version)
3. **Payload:** Base64-encoded serialized Lua table

### Payload Schema (v1)
```lua
{
  schemaVersion = 1,       -- Must match envelope schema
  exportedAt = 1704908765, -- Unix timestamp
  character = "PlayerName-Realm",
  booksById = {            -- Book data (keyed by book ID)
    ["b2:abc123"] = <BookEntry>,
    ["b2:def456"] = <BookEntry>,
    -- ...
  },
  order = {                -- Insertion order
    "b2:abc123",
    "b2:def456",
    -- ...
  },
}
```

**BookEntry structure:** Same as `BookArchivistDB.booksById` (see `1-savedvariables-structure.md`).

## Export Flow

### Full Library Export
**File:** `core/BookArchivist_Export.lua` → `Export:ExportLibrary()`

```lua
Export:ExportLibrary()
  → Validate DB has books
  → Build payload table:
    {
      schemaVersion = 1,
      exportedAt = now(),
      character = GetUnitName("player", true),
      booksById = cloneTable(db.booksById),
      order = cloneTable(db.order),
    }
  → Serialize table: Serialize.SerializeTable(payload)
  → Base64 encode: Base64.Encode(serialized)
  → Build envelope: "BDB1|1|" .. encoded
  → Return envelope string
```

**Key behaviors:**
- **Deep clone:** Payload is copied (doesn't share references with DB)
- **Includes order:** Preserves insertion order for recipient
- **Character metadata:** Helps user track source of import

### UI Integration
**File:** `ui/options/BookArchivist_UI_Options.lua` → Export panel

```lua
ExportButton:OnClick()
  → payload = Export:ExportLibrary()
  → If payload:
    - Show in read-only editbox (AceGUI MultiLineEditBox)
    - Auto-select all text (Ctrl+C to copy)
  → Else:
    - Show error: "No books to export"
```

**UX:** User copies payload from editbox, pastes into chat/pastebin/Discord.

## Import Flow (Asynchronous)

### Phase-Based Worker
**File:** `core/BookArchivist_ImportWorker.lua` → `ImportWorker:Start()`

Import runs in **phases** to prevent UI freezing:

```
Phase 1: DECODE      → Parse BDB1 envelope
Phase 2: DESERIALIZE → Deserialize Lua table
Phase 3: MERGE       → Merge books into booksById
Phase 4: SEARCH      → Backfill searchText for imported books
Phase 5: TITLE       → Backfill title index for imported books
Phase 6: DONE        → Cleanup and report stats
```

### Phase Details

#### Phase 1: DECODE
```lua
Phase: "decode"
Budget: 8ms per frame

Flow:
  → Core._DecodeBDB1Envelope(rawPayload)
    → Split on "|" delimiter
    → Validate magic == "BDB1"
    → Validate schema version == 1
    → Extract base64 payload
    → Base64.Decode(payload) → serialized string
  → Store decoded → self.decoded
  → Advance to "deserialize"
```

**Errors:**
- Invalid envelope format
- Unsupported schema version
- Base64 decode failure

#### Phase 2: DESERIALIZE
```lua
Phase: "deserialize"
Budget: 8ms per frame

Flow:
  → Serialize.DeserializeTable(decoded)
    → Reconstruct Lua table from serialized string
    → Validate schemaVersion == 1
    → Validate booksById exists
  → Store payload → self.payload
  → Build incomingIds = sorted(payload.booksById keys)
  → Advance to "merge"
```

**Errors:**
- Deserialize failure (corrupted data)
- Missing required fields
- Schema version mismatch

#### Phase 3: MERGE
```lua
Phase: "merge"
Budget: 8ms per frame

Flow (per book):
  → bookId = incomingIds[incomingIdx]
  → incoming = payload.booksById[bookId]
  → existing = db.booksById[bookId]
  
  → If existing:
    - MergeOne(existing, incoming, bookId)
      → Merge counters: seenCount += incoming.seenCount
      → Merge timestamps: firstSeenAt = min, lastSeenAt = max
      → Merge pages: add missing pages, detect conflicts
      → Merge flags: isFavorite = true if either is true
      → Mark conflicts if metadata differs
    - stats.mergedCount++
  
  → Else (new book):
    - Clone incoming → db.booksById[bookId]
    - Prepend bookId to db.order
    - stats.newCount++
  
  → incomingIdx++
  → If incomingIdx > #incomingIds:
    - Advance to "search"
```

**Merge semantics:**
- **Pages:** Union (missing pages added, conflicts flagged)
- **Counters:** Sum (`seenCount += incoming.seenCount`)
- **Timestamps:** Min/max (`firstSeenAt = min(...)`)
- **Flags:** OR (`isFavorite = existing.isFavorite OR incoming.isFavorite`)
- **Conflicts:** Metadata mismatches flagged in `entry.legacy.importConflict`

#### Phase 4: SEARCH
```lua
Phase: "search"
Budget: 8ms per frame

Flow (per book):
  → bookId = needsIds[needsIdx]
  → entry = db.booksById[bookId]
  
  → If entry.searchText == nil:
    - entry.searchText = Core:BuildSearchText(entry.title, entry.pages)
      → Normalize title + all page text
      → Lowercase, strip markup, collapse whitespace
  
  → needsIdx++
  → If needsIdx > #needsIds:
    - Advance to "title"
```

**Why backfill searchText?**
- Imported books might be from older version (no searchText)
- Search optimization requires pre-built index
- Backfill ensures imported books searchable immediately

#### Phase 5: TITLE
```lua
Phase: "title"
Budget: 8ms per frame

Flow (per book):
  → bookId = needsIds[needsIdx]
  → entry = db.booksById[bookId]
  
  → Build title index:
    - key = Search.NormalizeSearchText(entry.title)
    - db.indexes.titleToBookIds[key] = db.indexes.titleToBookIds[key] or {}
    - db.indexes.titleToBookIds[key][bookId] = true
  
  → needsIdx++
  → If needsIdx > #needsIds:
    - Advance to "done"
```

**Why backfill title index?**
- Tooltip system uses title index for fallback lookups
- Import doesn't include indexes (only book data)

#### Phase 6: DONE
```lua
Phase: "done"

Flow:
  → Report stats:
    - newCount: Books added
    - mergedCount: Books merged
    - conflictCount: Books with metadata conflicts
  → Trigger UI refresh: RefreshUI()
  → Call onDone callback
  → Cleanup worker state
```

### Worker API
**File:** `core/BookArchivist_ImportWorker.lua`

```lua
-- Create worker
worker = ImportWorker:New(parentFrame)

-- Start import with callbacks
worker:Start(rawPayload, {
  onProgress = function(label, percent)
    -- Update progress bar/status text
  end,
  onDone = function(stats)
    -- Show completion message
    -- stats = { newCount, mergedCount, conflictCount }
  end,
  onError = function(message)
    -- Show error to user
  end,
})

-- Cancel import (mid-phase)
worker:Cancel()
```

### UI Integration
**File:** `ui/options/BookArchivist_UI_Options.lua` → Import panel

```lua
ImportButton:OnClick()
  → Read text from editbox
  → Create ImportWorker instance
  → worker:Start(rawPayload, callbacks)
    → onProgress: Update status label ("Merging books... 50%")
    → onDone: Show completion message ("Imported 42 new books, merged 13")
    → onError: Show error dialog
  → Disable import button during import
  → Re-enable on completion/error
```

**Progress updates:**
- "Decoded" (after phase 1)
- "Deserialized" (after phase 2)
- "Merging books... X%" (during phase 3)
- "Building search index... X%" (during phase 4)
- "Indexing titles... X%" (during phase 5)

## Conflict Detection

### What Causes Conflicts?
**Scenario:** Same book ID, different content.

**Examples:**
- Different title for same book
- Different page text for same page number
- Metadata mismatch (creator, material)

### Conflict Markers
```lua
entry.legacy = {
  importConflict = true,  -- Flag set during merge
}
```

**Effect:**
- Book marked as conflicted
- Included in `stats.conflictCount`
- **No resolution:** Both versions kept (last write wins)

**Future improvement:** Could show conflict resolution UI.

## Performance

### Export
- **Time:** ~50-100ms for 1000 books
- **Synchronous:** Blocks UI briefly (acceptable for export)
- **Memory spike:** 2x book data (clone + serialization)

### Import
- **Time:** ~5-10 seconds for 1000 books (asynchronous)
- **Frame budget:** 8ms per frame (60 FPS maintained)
- **Phases:** Each yields after time budget exhausted
- **Memory spike:** 2x book data (payload + merge)

### Bottlenecks
- **Serialization/deserialization:** Lua table → string conversion (CPU-intensive)
- **Base64 encoding:** String manipulation (CPU-intensive)
- **Merge phase:** Comparing pages, detecting conflicts (most work)

## Data Validation

### Envelope Validation
```lua
Core._DecodeBDB1Envelope(raw)
  → Check format: "BDB1|schema|payload"
  → Check schema: must be "1"
  → Check payload: must be valid base64
  → Reject if any check fails
```

### Payload Validation
```lua
Phase 2: "deserialize"
  → Check type(payload) == "table"
  → Check payload.schemaVersion == 1
  → Check type(payload.booksById) == "table"
  → Reject if any check fails
```

### Book Entry Validation
**None.** Import assumes incoming books are well-formed.

**Risk:** Malformed books could corrupt DB.
**Mitigation:** `DBSafety` repairs corruption on next load.

## Common Patterns

### Export all books
```lua
local Export = BookArchivist.Export
local payload = Export:ExportLibrary()
if payload then
  -- Copy to clipboard (pseudocode)
  SetClipboard(payload)
end
```

### Import from string
```lua
local ImportWorker = BookArchivist.ImportWorker
local worker = ImportWorker:New(UIParent)

worker:Start(payloadString, {
  onDone = function(stats)
    print(string.format(
      "Import complete: %d new, %d merged, %d conflicts",
      stats.newCount, stats.mergedCount, stats.conflictCount
    ))
  end,
  onError = function(err)
    print("Import failed: " .. err)
  end,
})
```

### Cancel import mid-flight
```lua
-- User closes import dialog
worker:Cancel()
  → Worker stops after current phase
  → Partial import is persisted (no rollback)
```

### Check if import is running
```lua
if worker.phase ~= "idle" then
  -- Import in progress
end
```

## Edge Cases

### Partial Import (Canceled Mid-Flight)
**Result:** Books merged up to cancellation point are persisted.
**No rollback:** Changes are incremental, no transaction model.

### Duplicate Import (Same Payload Twice)
**Result:** All books marked as "merged", `seenCount` incremented twice.
**No deduplication:** Worker doesn't detect re-import.

### Import into Empty DB
**Result:** All books marked as "new", `order` array built from payload.

### Import with Stale IDs
**Scenario:** Payload has book IDs that no longer exist in source DB.
**Result:** Books imported normally (IDs are deterministic, not tied to source).

### Large Imports (10,000+ books)
**Result:** Import takes ~1 minute, UI remains responsive (60 FPS).
**Limitation:** Memory usage spikes (2x book data).

## Important Notes

1. **One-way sync:** Export/import is manual (no auto-sync)
2. **No conflict resolution UI:** Merge picks last write (no user prompt)
3. **Partial imports are safe:** Canceling mid-flight persists partial data
4. **No rollback:** Once merged, can't undo (backup recommended)
5. **Incremental saves:** Each merged book is immediately persisted (SavedVariables)
6. **Progress is accurate:** Percentage reflects actual work completed
7. **Budget is tunable:** `budgetMs` can be adjusted (default 8ms)

## Related Files
- `core/BookArchivist_Export.lua` - Export logic
- `core/BookArchivist_ImportWorker.lua` - Import worker
- `core/BookArchivist_Serialize.lua` - Lua table serialization
- `core/BookArchivist_Base64.lua` - Base64 encoding/decoding
- `ui/options/BookArchivist_UI_Options.lua` - Import/Export UI

## Future Improvements (Not Implemented)
- Conflict resolution UI (show diffs, let user pick)
- Selective import (checkboxes for books to import)
- Import progress bar (visual indicator)
- Rollback/undo import
- Export filters (only Favorites, only Recent, date range)
- Compression (gzip payload before base64)
