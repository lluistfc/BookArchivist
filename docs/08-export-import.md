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

### 3) Implement `/ba export`
Behavior:
1. Build payload table
2. Serialize to string
3. Base64 encode
4. Show in modal edit box for copy

### 4) Implement `/ba import <payload>`
Behavior:
1. Base64 decode
2. Deserialize table
3. Validate:
   - schemaVersion supported
   - booksById is table
4. Merge into current `db.booksById`
5. Update `db.order` by appending new ids
6. Ensure derived fields:
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
If you want:
- `/ba import --dry <payload>` prints counts only

## Acceptance criteria
- Export/import roundtrip results in identical library for the same character.
- Import to another character merges without duplicates and without wiping local data.

## Rollback
- Remove slash commands; data remains.
