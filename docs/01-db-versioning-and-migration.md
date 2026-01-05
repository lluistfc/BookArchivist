# Step 1 – DB versioning & migration (detailed)

## Objective
Make every future schema change safe by introducing explicit DB versioning and a deterministic migration pipeline.

---

## Step-by-step implementation

### 1. Define the target DB header
Add these top-level fields (do not remove existing ones yet):
- `dbVersion: number`
- keep existing `version` for legacy detection only

Expected state after this step:
```lua
BookArchivistDB = {
  dbVersion = 1,
  version = 1, -- legacy, read-only
  ...
}
```

---

### 2. Create DB initialization entrypoint
Create `Core/DB.lua`:

Responsibilities:
1. Ensure DB table exists
2. Detect legacy DBs
3. Run migrations in order
4. Return a usable DB reference

Minimal shape:
```lua
function DB:Init()
  if not BookArchivistDB then
    BookArchivistDB = { dbVersion = 1 }
    return BookArchivistDB
  end

  BookArchivistDB = Migrate(BookArchivistDB)
  return BookArchivistDB
end
```

---

### 3. Create migration dispatcher
Create `Core/Migrations.lua`:

```lua
local MIGRATIONS = {}

function Migrate(db)
  local v = db.dbVersion or 0
  if v < 1 then db = MIGRATIONS.v1(db) end
  return db
end
```

---

### 4. Implement migration v1 (annotation-only)
Migration v1 MUST NOT restructure data.

```lua
function MIGRATIONS.v1(db)
  db.dbVersion = 1
  return db
end
```

---

### 5. Wire DB init into addon load
- Call `DB:Init()` during addon initialization
- Replace direct references to `BookArchivistDB`

---

## Validation checklist
- [ ] Fresh install works
- [ ] Existing SavedVariables load without mutation
- [ ] Reload UI does not change book count
- [ ] `dbVersion` exists after login

---

## Rollback strategy
Safe to revert: no data mutation occurred.

---

## Output of this step
You now have:
- A stable migration framework
- Zero behavioral change
- A foundation for all future steps
