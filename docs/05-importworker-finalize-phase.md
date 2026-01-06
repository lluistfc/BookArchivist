# 05 — ImportWorker: Finalize phases (searchText, title index, recent sanitize)

## Goal
Finish import by computing expensive derived fields and indexes in slices.

## Prerequisites
- `Core:BuildSearchText(title, pages)` added in plan 02.
- `Core:IndexTitleForBook(title, bookId)` already exists and should be reused.

## Phase: finalize_searchtext
Process `self.needsIds` (the book IDs imported/merged) in small slices.

```lua
local db = BookArchivistDB
local ids = self.needsIds or {}
local total = #ids
local perSlice = 15
local processed = 0

while self.needsIdx <= total and processed < perSlice do
  local bookId = ids[self.needsIdx]
  local e = db.booksById[bookId]
  if e then
    -- Mimic ensureImportedEntryDerivedFields defaulting behavior:
    e.isFavorite = (e.isFavorite == true) -- ensure boolean
    e.lastReadAt = e.lastReadAt or 0
    e.searchText = BookArchivist.Core:BuildSearchText(e.title, e.pages)
  end
  self.needsIdx = self.needsIdx + 1
  processed = processed + 1
end

self:_Progress("Building search", self.needsIdx / math.max(1, total))

if self.needsIdx > total then
  self.needsIdx = 1
  self.phase = "finalize_index"
end
```

## Phase: finalize_index
Chunk title indexing. Use existing core method `IndexTitleForBook` (already used in sync import).

```lua
local db = BookArchivistDB
local ids = self.needsIds or {}
local total = #ids
local perSlice = 40
local processed = 0

while self.needsIdx <= total and processed < perSlice do
  local bookId = ids[self.needsIdx]
  local e = db.booksById[bookId]
  if e and e.title and e.title ~= "" then
    BookArchivist.Core:IndexTitleForBook(e.title, bookId)
  end
  self.needsIdx = self.needsIdx + 1
  processed = processed + 1
end

self:_Progress("Indexing titles", self.needsIdx / math.max(1, total))

if self.needsIdx > total then
  self.phase = "finalize_recent"
end
```

## Phase: finalize_recent
Sync import does a pcall on Recent list to sanitize. Do it once.

```lua
local ok = pcall(function()
  if BookArchivist.Recent and BookArchivist.Recent.GetList then
    BookArchivist.Recent:GetList()
  end
end)

self.phase = "done"
```

## Phase: done
Call onDone once with a summary string. Example:
```lua
local summary = ("Imported: %d new, %d merged"):format(self.stats.newCount, self.stats.mergedCount)
self:Cancel()
if self.onDone then self.onDone(summary) end
```

## Acceptance checks
- searchText exists for all imported IDs.
- Title search behaves same as sync import.
- Recent list remains valid.
