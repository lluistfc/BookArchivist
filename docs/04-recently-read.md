# Step 4 – Recently Read (per-character DB)

> Assumptions for these documents
>
> - Steps 1 and 2 are already implemented (DB versioning + migration framework, and `booksById` + stable `bookId` migration).
> - **Database is per-character** (SavedVariablesPerCharacter). Do not introduce account-wide storage in these steps.
> - You must not lose existing per-character data for current users.
>
> Notation:
> - `db` refers to `BookArchivistDB` for the currently logged-in character.
> - `booksById[bookId]` refers to the post-Step-2 canonical store.


## Objective
Track and surface recently opened books, per character.

## DB changes (non-breaking)
Add:
- `BookEntry.lastReadAt: number|nil`
- `db.recent = { cap = 50, list = {} }`

Defaults:
- `cap = 50`
- `list = {}`

## Step-by-step

### 1) Ensure the `recent` container exists
During DB init:
```lua
db.recent = db.recent or { cap = 50, list = {} }
db.recent.cap = db.recent.cap or 50
db.recent.list = db.recent.list or {}
```

### 2) Add a Recent service
Create `Core/Recent.lua` with:
- `Recent:MarkOpened(bookId)`
- `Recent:GetList() -> array bookId` (filtered to existing books)

Implementation:
```lua
function Recent:MarkOpened(bookId)
  local e = db.booksById[bookId]
  if not e then return end

  local now = time()
  e.lastReadAt = now
  e.updatedAt = now

  local list = db.recent.list
  for i = #list, 1, -1 do
    if list[i] == bookId then table.remove(list, i) end
  end
  table.insert(list, 1, bookId)

  local cap = db.recent.cap or 50
  while #list > cap do table.remove(list) end
end
```

### 3) Call `MarkOpened` from the UI open-book path
Wherever your UI transitions to a book page/detail, call:
- `Recent:MarkOpened(bookId)`

### 4) Add `__recent__` virtual category
Category ID: `__recent__`

List builder:
- Use `db.recent.list` order
- Filter out missing ids (stale cleanup)

Optional: add “Clear recent” button:
```lua
db.recent.list = {}
```

## Acceptance criteria
- Opening a stored book adds it to Recently Read.
- Order is most-recent-first.
- List is capped.

## Rollback
- Fields remain; harmless.
