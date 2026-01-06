# 04 — ImportWorker: Decode/Deserialize/Prepare/Merge (behavior parity)

## Goal
Implement phases up to and including `merge` such that DB results match `Core:ImportFromString()`,
but without building searchText or indexing titles inside the merge loop.

## Dependencies
- `BookArchivist.Base64.Decode` fileciteturn7file0
- `BookArchivist.Serialize.DeserializeTable` fileciteturn7file1
- `BookArchivist.Core:EnsureDB()` (exists; ensures per-character db tables) fileciteturn9file1
- `BookArchivistDB.booksById`, `BookArchivistDB.order`

## Phase: decode
In worker `_Step`, when `self.phase == "decode"`:
```lua
local decoded, err = BookArchivist.Base64.Decode(self.rawPayload)
if not decoded then return self:_Fail("Decode failed: " .. tostring(err)) end
self.decoded = decoded
self.phase = "deserialize"
self:_Progress("Decoded", 0)
```

## Phase: deserialize
```lua
local payload, err = BookArchivist.Serialize.DeserializeTable(self.decoded)
if not payload then return self:_Fail("Deserialize failed: " .. tostring(err)) end
if type(payload) ~= "table" then return self:_Fail("Invalid payload type") end

if payload.schemaVersion ~= 1 then
  return self:_Fail("Unsupported schemaVersion: " .. tostring(payload.schemaVersion))
end

if type(payload.booksById) ~= "table" then
  return self:_Fail("Payload missing booksById")
end

self.payload = payload
self.incomingBooks = payload.booksById
self.incomingIds = MakeSortedKeys(self.incomingBooks)
self.incomingIdx = 1
self.phase = "prepare"
self:_Progress("Parsed", 0)
```

## Phase: prepare
Build orderSet of existing order to avoid O(n^2) checks while appending:
```lua
BookArchivist.Core:EnsureDB()
local db = BookArchivistDB
db.booksById = db.booksById or {}
db.order = db.order or {}

self.orderSet = {}
for _, id in ipairs(db.order) do self.orderSet[id] = true end

self.phase = "merge"
```

## Merge semantics (must match Core)
Copy the exact merge logic from `Core:ImportFromString()`:
- new entry: clone + defaults + conflict fields off
- existing entry: add/min/max/OR + fill missing pages only + conflict flagging

**Important**: during merge, do NOT call `ensureImportedEntryDerivedFields()`.
Instead mark:
- `self.needsSearchText[bookId] = true`
- `self.needsIndex[bookId] = true`

### Merge helper: deep clone (required)
In Core, `cloneTable()` is local. Implement a local clone in the worker file identical to Core’s clone:
```lua
local function CloneTable(src)
  if type(src) ~= "table" then return src end
  local dst = {}
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = CloneTable(v)
    else
      dst[k] = v
    end
  end
  return dst
end
```

### Merge helper: mergeImportedEntry equivalent
Implement `ImportWorker:_MergeOne(db, bookId, inE)` with the same rules:
- seenCount add
- firstSeenAt min
- lastSeenAt max
- lastReadAt max
- isFavorite OR
- title conflict -> legacy.importConflict=true
- pages fill missing page indices, conflict -> legacy.importConflict=true

### Merge loop with per-slice cap
In phase `merge`:
```lua
local db = BookArchivistDB
local total = #self.incomingIds
local perSlice = 25
local processed = 0

while self.incomingIdx <= total and processed < perSlice do
  local bookId = self.incomingIds[self.incomingIdx]
  local inE = self.incomingBooks[bookId]

  local existing = db.booksById[bookId]
  if not existing then
    db.booksById[bookId] = CloneTable(inE)
    self.stats.newCount = self.stats.newCount + 1
  else
    -- call _MergeOne(existing, inE) and bump mergedCount
    self.stats.mergedCount = self.stats.mergedCount + 1
  end

  -- append to order if missing
  if not self.orderSet[bookId] then
    db.order[#db.order+1] = bookId
    self.orderSet[bookId] = true
  end

  self.needsSearchText[bookId] = true
  self.needsIndex[bookId] = true

  self.incomingIdx = self.incomingIdx + 1
  processed = processed + 1
end

self:_Progress("Merging", self.incomingIdx / math.max(1, total))

if self.incomingIdx > total then
  -- Build needs list for finalize phases
  self.needsIds = MakeSortedKeys(self.needsSearchText)
  self.needsIdx = 1
  self.phase = "finalize_searchtext"
end
```

## Acceptance checks
- Import of small payload produces identical DB fields for a few known books.
- `db.order` gains new book IDs without duplicates.
- No hitch when importing 1000 entries (merge runs across frames).
