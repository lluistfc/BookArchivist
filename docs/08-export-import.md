# Step 8 – Export / Import (per-character DB)

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
Enable backup/sharing of a character library with merge-safe import.

## Constraints
- Keep DB per-character.
- Import merges into the current character DB.
- No automatic account-wide sync in this step.

## Export payload (schemaVersion=1)
```lua
payload = {
  schemaVersion = 1,
  exportedAt = time(),
  character = { name = UnitName("player"), realm = GetRealmName() },
  booksById = db.booksById,
  order = db.order,
}
```

## Step-by-step

### 1) Implement deterministic serialize/deserialize
Create `Core/Serialize.lua`:
- `SerializeTable(t) -> string`
- `DeserializeTable(s) -> table|nil, err`

Requirements:
- Only supports primitives, tables, arrays, no functions/metatables.
- Avoid recursion bombs (depth limit).

### 2) Add base64 wrapper
Create `Core/Base64.lua` (or embed a tiny encoder/decoder):
- `Encode(str) -> str`
- `Decode(str) -> str|nil`

### 3) UI wiring: Export text area
Behavior:
1. Add an "Export / Import" section to the options panel.
2. Add a button "Generate export string" that:
  - Builds the payload table
  - Serializes it to a string
  - Base64 encodes the result
  - Fills a multi-line, copyable text area and focuses + selects it.
3. Keep the export text area hidden until the first successful export.

### 4) UI wiring: Import text area
Behavior:
1. Add a multi-line "Import string" text area to the options panel.
2. Add an "Import" button that:
  - Reads the text box contents
  - Base64 decodes
  - Deserializes the table
  - Validates:
    - schemaVersion supported
    - booksById is table
  - Merges into the current `db.booksById`
  - Updates `db.order` by appending new ids
  - Ensures derived fields:
    - `searchText` exists (Step 6)
    - `isFavorite` default exists (Step 3)
    - `recent` integrity (Step 4)

### 5) Merge rules (deterministic)
For each imported entry `inE`:
- If not exists → insert
- If exists `e` → merge:
  - `seenCount`: sum
  - `firstSeenAt`: min
  - `lastSeenAt`: max
  - `lastReadAt`: max
  - `isFavorite`: OR
  - `title/pages`: keep existing unless missing; if both present and differ → keep existing, set `e.legacy = e.legacy or {}; e.legacy.importConflict = true`

### 6) User feedback
After import:
- print summary: `Imported X new books, merged Y existing books`

### 7) Safety: optional dry-run mode
If you want an advanced/debug path, you can keep a non-UI entry point that:
- Accepts a payload string and a `dry` flag
- Runs the same decode/deserialize/validate/merge logic against a copy of the DB
- Returns counts only: `new`, `merged`

## Acceptance criteria
- Export/import roundtrip results in identical library for the same character.
- Import to another character merges without duplicates and without wiping local data.

## Rollback
- Remove the Export / Import section from the options panel; data remains.
