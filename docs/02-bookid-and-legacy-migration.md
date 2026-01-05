# Step 2 – BookId & legacy migration (detailed)

## Objective
Replace fragile string keys with stable book IDs without wiping existing libraries.

---

## Step-by-step implementation

### 1. Freeze legacy data
Before touching anything:
- Copy `books` and `order` into `legacy`

```lua
db.legacy = {
  version = db.version,
  books = db.books,
  order = db.order,
}
```

---

### 2. Define BookId v2 algorithm
Inputs:
- `source.objectID` (if present)
- normalized title
- normalized first page (512 chars)

Output:
```
b2:<hash>
```

This guarantees deterministic conversion.

---

### 3. Implement ID helpers
Create `Core/BookId.lua`:
- `NormalizeText`
- `MakeBookIdV2(book)`

No DB writes here.

---

### 4. Convert books table
Create new table:
```lua
db.booksById = {}
```

Loop:
1. For each legacy book
2. Compute `bookId`
3. If missing → insert
4. If exists → merge counters + timestamps

---

### 5. Convert order
Replace old keys with new `bookId` values.

---

### 6. Build objectID index (best-effort)
```lua
db.indexes.objectToBookId[objectID] = bookId
```
Skip conflicts.

---

### 7. Remove write paths to legacy storage
- Stop writing to `db.books`
- Reads must now go through `booksById`

---

## Validation checklist
- [ ] Same book count before/after
- [ ] Order preserved
- [ ] No duplicate lore entries
- [ ] Reload-safe

---

## Rollback strategy
Restore `db.legacy` and remove `booksById`.

---

## Output of this step
All books now have stable IDs and are future-proof.
