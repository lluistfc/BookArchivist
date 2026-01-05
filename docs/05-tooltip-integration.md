# Step 5 – Tooltip Integration (per-character DB)

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
When hovering readable items, show whether that item’s text is archived **for this character**.

## Performance constraints (non-negotiable)
Tooltip events fire constantly.
- No DB scan per hover
- O(1) lookups only
- Early-exit on nearly all tooltips

## DB changes (non-breaking)
Add:
- `db.indexes = db.indexes or {}`
- `db.indexes.itemToBookIds = { [itemId] = { [bookId]=true, ... } }` (multi-map)
- `db.options.tooltip.enabled` (default `true`)

## Step-by-step

### 1) Add tooltip option default
During DB init:
```lua
db.options = db.options or {}
db.options.tooltip = db.options.tooltip or { enabled = true }
```

### 2) Create/ensure the item index container
During DB init:
```lua
db.indexes = db.indexes or {}
db.indexes.itemToBookIds = db.indexes.itemToBookIds or {}
```

### 3) Maintain item index at capture/import time
Whenever you store a book and you know `itemID`:
```lua
local map = db.indexes.itemToBookIds
map[itemID] = map[itemID] or {}
map[itemID][bookId] = true
```

If your current capture path cannot determine `itemID` reliably:
- Implement tooltip MVP as “Archived only when indexed”
- Do NOT attempt to detect “Not archived” yet

### 4) Implement tooltip hook with strict gating
Hook once (on addon init):
```lua
GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
  if not db.options.tooltip.enabled then return end

  local name, link = tooltip:GetItem()
  if not link then return end

  local itemID = ExtractItemID(link)
  if not itemID then return end

  local set = db.indexes.itemToBookIds[itemID]
  if not set then return end -- MVP: only show if known

  tooltip:AddLine("Book Archivist: Archived")
end)
```

### 5) Implement `ExtractItemID(link)` without allocations
Typical pattern:
- parse `item:(%d+)`

### 6) Defensive cleanup on init (optional but recommended)
Remove bookIds that no longer exist:
```lua
for itemID, set in pairs(db.indexes.itemToBookIds) do
  for bookId in pairs(set) do
    if not db.booksById[bookId] then set[bookId] = nil end
  end
  if next(set) == nil then db.indexes.itemToBookIds[itemID] = nil end
end
```

## Acceptance criteria
- Hovering random items causes no lag (no visible hitching).
- Hovering an indexed readable item shows “Archived”.
- Tooltip setting can disable everything.

## Rollback
- Disable by setting default `enabled=false`.
- Index remains; harmless.

## Branch recommendation
This is hook-heavy. Use a short-lived branch for this step.
