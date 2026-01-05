# Step 6 – Search Optimization (per-character DB)

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
Keep search fast as the library grows, without changing user-visible results.

## DB changes
Ensure:
- `BookEntry.searchText: string`

## Step-by-step

### 1) Decide the searchable content scope
Pick one (document your decision in code comments):
- **Full**: all pages concatenated (best completeness, more DB size)
- **Partial**: title + first 2 pages (smaller DB, might miss later-page hits)

Recommendation for lore books: **Full**.

### 2) Implement `BuildSearchText(title, pages)`
```lua
local function BuildSearchText(title, pages)
  local t = NormalizeText(title or "")
  local out = t
  for i = 1, #(pages or {}) do
    out = out .. "\n" .. NormalizeText(pages[i] or "")
  end
  return string.lower(out)
end
```

### 3) Write-time computation
Whenever you insert/update a book entry:
- `entry.searchText = BuildSearchText(entry.title, entry.pages)`

### 4) Backfill during DB init/migration
```lua
for id, entry in pairs(db.booksById or {}) do
  if not entry.searchText then
    entry.searchText = BuildSearchText(entry.title, entry.pages)
  end
end
```

### 5) Refactor search to use `searchText` only
At query time:
- normalize query
- split into tokens
- check tokens in `entry.searchText`

Avoid:
- concatenating title/pages on every query

### 6) Add a lightweight per-session cache (optional)
If user types in a search box with keystrokes:
- cache `lastQuery -> lastResultIds`
- only recompute when query changes

## Acceptance criteria
- Search results match current behavior.
- Search stays responsive for 1000+ books.

## Rollback
- Keep `searchText`; you can revert query-time logic without data loss.
