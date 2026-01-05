# Step 7 – UI State Persistence (per-character DB)

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
Remember last selected category and last opened book, **per character**.

## DB changes (non-breaking)
Add:
- `db.uiState = { lastCategoryId=nil, lastBookId=nil }`

## Step-by-step

### 1) Ensure `uiState` exists during DB init
```lua
db.uiState = db.uiState or {}
```

### 2) Persist lastCategoryId on category change
When user selects a category in your UI:
```lua
db.uiState.lastCategoryId = categoryId
```

Category IDs must be stable:
- location category IDs (your current scheme)
- virtual: `__favorites__`, `__recent__`, etc.

### 3) Persist lastBookId on book open
When user opens a book in addon UI:
```lua
db.uiState.lastBookId = bookId
```

### 4) Restore on UI open
On opening main frame:
1. Determine category:
   - if `db.uiState.lastCategoryId` exists and is valid → select
   - else default (All)
2. Determine resume:
   - if `db.uiState.lastBookId` exists and book exists:
     - show “Resume last book” button
     - (optional) auto-open only if user setting enabled

Recommended: **do not auto-open**; provide resume button.

### 5) Defensive validation
If saved values are stale:
```lua
if db.uiState.lastBookId and not db.booksById[db.uiState.lastBookId] then
  db.uiState.lastBookId = nil
end
```

## Acceptance criteria
- `/reload` restores last category & resume book.
- Different characters keep independent state.

## Optional: resume on last page

Additional, non-breaking state can be tracked per entry to remember which page the player last viewed:

- Per-entry field: `booksById[bookId].lastPageNum` (numeric page key from `entry.pages`).
- Per-character option: `db.options.ui.resumeLastPage` (boolean, default `true`).

Behavior when `resumeLastPage` is enabled:
- When the reader renders a page for a given book, it updates `entry.lastPageNum` to the current page.
- When reopening that book, the reader looks for `lastPageNum` in the sorted `pageOrder` and, if found, starts on that page instead of page 1.
- When disabled, books always open on page 1 and any stored `lastPageNum` is ignored.

## Rollback
- Fields remain; harmless.
