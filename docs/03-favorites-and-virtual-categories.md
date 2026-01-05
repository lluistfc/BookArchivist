# Step 3 – Favorites & virtual categories (per-character DB)

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
Add favorites and computed categories to increase retention, without changing capture behavior.

## DB changes (non-breaking)
You already have `booksById`. Add fields if missing during migration / initialization:
- `BookEntry.isFavorite: boolean` (default `false`)
- Optional: `db.options.ui.virtualCategoriesEnabled: boolean` (default `true`)

**Do not** change storage scope (still per-character).

## Step-by-step

### 1) Add default field injection (safe backfill)
**Where:** DB init/migration pass (the same place you ensure other defaults exist).

```lua
for bookId, entry in pairs(db.booksById or {}) do
  if entry.isFavorite == nil then entry.isFavorite = false end
end
```

Validation:
- Existing books remain unchanged except for the new default field.

### 2) Implement a small Favorites service
**Where:** `Core/Favorites.lua` (or your existing UI/controller module).

Expose:
- `Favorites:Set(bookId, value)`
- `Favorites:Toggle(bookId)`
- `Favorites:IsFavorite(bookId) -> boolean`

Rules:
- If `bookId` not found: no-op (log only if debug enabled)
- When changing favorite: `entry.updatedAt = time()` (optional but consistent)

### 3) Add favorite toggle UI
Implement at least one:
- Book detail view: star button next to title (recommended)
- Book list rows: star per row (optional)

UI details:
- Tooltip text switches between “Add to Favorites” and “Remove from Favorites”.
- Star state reflects `entry.isFavorite`.

### 4) Add “Favorites” as a virtual category
Define category IDs:
- `__favorites__`
- (optional) `__all__`

Implementation:
- In your category provider/list builder, inject virtual categories at the top.
- When selected category is `__favorites__`, list books by filtering:
```lua
local out = {}
for id, e in pairs(db.booksById) do
  if e.isFavorite then table.insert(out, id) end
end
```

### 5) Sorting in favorites view
Pick one deterministic sort:
- Title ascending
- Or `lastSeenAt desc`, then title asc

Use your existing comparator where possible.

### 6) Persist lastCategoryId (optional now; required in Step 7)
When favorites category selected:
- `db.uiState.lastCategoryId = "__favorites__"` (if uiState exists; otherwise set later)

## Acceptance criteria
- Favoriting persists across `/reload`.
- Favorites category shows only favorited books.
- No Lua errors if a missing bookId is toggled.

## Rollback
- Leaving `isFavorite` fields in SavedVariables is harmless.
