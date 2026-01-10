# Tooltip Integration System

## Overview
BookArchivist integrates with WoW's GameTooltip to show "Archived" status on:
1. **Inventory items** (bags, bank, vendor frames)
2. **World objects** (GameObjects, NPCs with books)
3. **Item links** (chat, quest rewards, etc.)

Tooltip integration uses the **index system** for O(1) lookups (no iteration).

## Visual Indicator

### Tooltip Text
When an item/object has archived content:
```
[Item Name]
Archived ✓
[Rest of tooltip]
```

**Color:** Green (`|cFF00FF00`)
**Position:** Added as new line after item name (typically line 2)

### Tooltip NOT Shown When:
- User has disabled tooltip in settings (`options.tooltip.enabled = false`)
- No archived books exist for this item/object
- Tooltip is not a GameTooltip (edge cases with custom tooltip frames)

## Core Logic

### Tooltip Hook Setup
**File:** `core/BookArchivist_Tooltip.lua` → `Tooltip:Initialize()`

```lua
Tooltip:Initialize()
  → Hook TooltipDataProcessor callbacks:
    - TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        handleItemTooltip
      )
    - TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Object,
        handleObjectTooltip
      )
```

**Hook timing:** Called during `ADDON_LOADED` event for BookArchivist.

### Item Tooltip Handler
**File:** `core/BookArchivist_Tooltip.lua` → `handleItemTooltip(tooltip, data)`

```lua
handleItemTooltip(tooltip, data)
  → Check if tooltip enabled: isTooltipEnabled()
  → Extract item ID: data.id
  → Check if archived: isItemArchived(itemID)
    → Lookup in db.indexes.itemToBookIds[itemID]
    → Verify at least one book exists in booksById
  → If archived:
    - L["Archived"] → localized string
    - tooltip:AddLine(text, 0, 1, 0)  -- Green color
```

**Alternate fallback (if data.id unavailable):**
```lua
handleTooltipForItem(tooltip, itemID)
  → Get tooltip title: getTooltipTitle(tooltip)
  → Check if title archived: isTitleArchived(title)
    → Normalize title (lowercase, strip markup)
    → Lookup in db.indexes.titleToBookIds[normalizedTitle]
```

**Why fallback?** Some tooltip contexts don't provide `data.id` (legacy frames).

### Object Tooltip Handler
**File:** `core/BookArchivist_Tooltip.lua` → `handleObjectTooltip(tooltip, data)`

```lua
handleObjectTooltip(tooltip, data)
  → Check if tooltip enabled: isTooltipEnabled()
  → Extract object GUID: data.guid
  → Parse GUID for objectID: parseGuid(guid)
  → Check if archived: isObjectArchived(objectID)
    → Lookup in db.indexes.objectToBookId[objectID]
    → Verify book exists in booksById
  → If archived:
    - L["Archived"] → localized string
    - tooltip:AddLine(text, 0, 1, 0)  -- Green color
```

**GUID parsing:**
```lua
-- GameObject: "GameObject-0-1234-5678-9ABC-objectID"
-- Creature: "Creature-0-1234-5678-instanceID-objectID-hash"
local objectType, objectID = parseGuid(guid)
```

## Index Lookups

### Item Index (itemToBookIds)
```lua
-- Structure: { [itemID] = { [bookId] = true } }
db.indexes.itemToBookIds[itemID]
  → Returns set of book IDs (or nil)
  → Multiple books can share same item ID

-- Example:
itemToBookIds = {
  [12345] = {
    ["b2:abc123"] = true,
    ["b2:def456"] = true,  -- Item contains 2 different books
  },
}
```

**Lookup logic:**
```lua
isItemArchived(itemID)
  → bookIds = db.indexes.itemToBookIds[itemID]
  → If bookIds:
    - For each bookId in set:
      - If booksById[bookId] exists: return true
  → Return false
```

**Why check booksById?**
- Index might be stale (book deleted)
- Defensive: Ensures book actually exists

### Object Index (objectToBookId)
```lua
-- Structure: { [objectID] = bookId }
db.indexes.objectToBookId[objectID]
  → Returns book ID (or nil)
  → One-to-one mapping (last capture wins)

-- Example:
objectToBookId = {
  [12345] = "b2:abc123",  -- GameObject 12345 last gave this book
}
```

**Lookup logic:**
```lua
isObjectArchived(objectID)
  → bookId = db.indexes.objectToBookId[objectID]
  → If bookId:
    - If booksById[bookId] exists: return true
  → Return false
```

### Title Index (titleToBookIds)
```lua
-- Structure: { [normalizedTitle] = { [bookId] = true } }
db.indexes.titleToBookIds["normalized title"]
  → Returns set of book IDs (or nil)
  → Multiple books can have same title

-- Example:
titleToBookIds = {
  ["the journal of khadgar"] = {
    ["b2:abc123"] = true,
    ["b2:def456"] = true,  -- Same title, different content
  },
}
```

**Lookup logic:**
```lua
isTitleArchived(title)
  → key = normalizeTitleKey(title)
    → Lowercase, strip markup, collapse whitespace
  → bookIds = db.indexes.titleToBookIds[key]
  → If bookIds:
    - For each bookId in set:
      - If booksById[bookId] exists: return true
  → Return false
```

**When is title index used?**
- Fallback when `data.id` is unavailable
- Less accurate than item/object index (title collisions possible)

## Title Normalization

### normalizeTitleKey(title)
**File:** `core/BookArchivist_Tooltip.lua`

```lua
normalizeTitleKey(title)
  → Strip WoW color codes: gsub("|c%x%x%x%x%x%x%x%x", "")
  → Strip color reset: gsub("|r", "")
  → Trim whitespace: gsub("^%s+", ""), gsub("%s+$", "")
  → Lowercase: lower()
  → Collapse multiple spaces: gsub("%s+", " ")
  → Return normalized string
```

**Examples:**
```lua
"|cFF00FF00The Journal|r of Khadgar"
  → "the journal of khadgar"

"  The   Tome  "
  → "the tome"
```

**Why normalize?**
- Item names in tooltips include color codes
- Player-typed names might have extra spaces
- Case-insensitive matching ("The Tome" = "the tome")

## Settings Integration

### Enable/Disable Tooltip
**File:** `core/BookArchivist_Core.lua` → `ensureDB()`

```lua
-- Default settings
BookArchivistDB.options.tooltip = { enabled = true }
```

**Settings Panel:**
- Checkbox: "Show archived status in tooltips"
- Enabled by default
- Changes take effect immediately (no `/reload` needed)

### isTooltipEnabled() Logic
**File:** `core/BookArchivist_Tooltip.lua`

```lua
isTooltipEnabled(db)
  → opts = db.options or {}
  → tooltipOpts = opts.tooltip
  → If tooltipOpts == nil: return true (default enabled)
  → If tooltipOpts is table:
    - If tooltipOpts.enabled == false: return false
    - Else: return true
  → If tooltipOpts is boolean:
    - Return tooltipOpts
```

**Migration logic:** Old versions stored boolean, new versions store table.

## Performance

### Lookup Performance
- **Item/Object lookups:** O(1) map lookup + O(k) book validation (k = books per item, usually 1)
- **Title lookup:** O(1) map lookup + O(m) book validation (m = books per title, usually 1-5)
- **No iteration:** Never scans `booksById` or `order` arrays

### Tooltip Frequency
- **High-frequency event:** Tooltips fire constantly (mouseover spam)
- **Must be fast:** Any lag causes game stuttering
- **Index design critical:** O(1) lookups ensure no performance impact

### Memory Overhead
- **itemToBookIds:** ~4 bytes per (itemID → bookId) mapping
- **objectToBookId:** ~4 bytes per (objectID → bookId) mapping
- **titleToBookIds:** ~50 bytes per (title → bookIds) mapping (string keys larger)
- **Total:** ~500 bytes per 100 books (negligible)

## Edge Cases

### Item with Multiple Books
**Scenario:** Crate drops 3 different books at different times.

**Result:**
```lua
itemToBookIds[12345] = {
  ["b2:abc"] = true,
  ["b2:def"] = true,
  ["b2:ghi"] = true,
}
```

**Tooltip:** Shows "Archived ✓" (doesn't specify which book or count).

### Object Replaced by Different Book
**Scenario:** GameObject gives Book A, later patched to give Book B.

**Result:**
```lua
-- First capture
objectToBookId[12345] = "b2:aaa"

-- Later capture (overwrites)
objectToBookId[12345] = "b2:bbb"
```

**Effect:** Tooltip reflects most recent book only.

### Deleted Book with Stale Index
**Scenario:** Book deleted, but index entry remains.

**Result:**
```lua
itemToBookIds[12345] = { ["b2:deleted"] = true }
booksById["b2:deleted"] = nil  -- Deleted
```

**Tooltip:** NOT shown (validation check fails).

**Cleanup:** Stale indexes are harmless (always validated against `booksById`).

### Title Collision
**Scenario:** Two different books have same title.

**Result:**
```lua
titleToBookIds["the journal"] = {
  ["b2:aaa"] = true,  -- Quest book
  ["b2:bbb"] = true,  -- Loot book
}
```

**Tooltip:** Shows "Archived ✓" if EITHER book exists.

**Limitation:** Can't distinguish which book (title-based lookup is ambiguous).

## Common Patterns

### Check if item is archived (script)
```lua
local itemID = 12345
local db = BookArchivist.Core:GetDB()
local bookIds = db.indexes.itemToBookIds[itemID]
if bookIds then
  for bookId in pairs(bookIds) do
    if db.booksById[bookId] then
      print("Item is archived")
      break
    end
  end
end
```

### Manually add tooltip line (other addons)
```lua
-- Hook into BookArchivist's tooltip system
local function myTooltipHandler(tooltip, data)
  if not data or not data.id then return end
  local itemID = data.id
  
  -- Check BookArchivist index
  local db = BookArchivistDB
  if db and db.indexes and db.indexes.itemToBookIds then
    local bookIds = db.indexes.itemToBookIds[itemID]
    if bookIds and next(bookIds) then
      tooltip:AddLine("Also see: BookArchivist", 0, 1, 1)
    end
  end
end

TooltipDataProcessor.AddTooltipPostCall(
  Enum.TooltipDataType.Item,
  myTooltipHandler
)
```

### Disable tooltips for performance testing
```lua
BookArchivistDB.options.tooltip.enabled = false
-- Tooltips stop immediately (no reload needed)
```

## Important Notes

1. **Index-based, not scan-based:** Never iterates books (O(1) performance)
2. **Always validated:** Checks `booksById` existence (stale indexes ignored)
3. **Multi-book support:** Items can map to multiple books (shows "Archived" for any)
4. **Title fallback:** Uses title index when item ID unavailable (less accurate)
5. **Green color:** Hardcoded RGB (0, 1, 0) - no theme support
6. **No count display:** Doesn't show "3 books archived" (just "Archived ✓")
7. **Instant updates:** Index updated during capture (tooltips reflect new books immediately)

## Related Files
- `core/BookArchivist_Tooltip.lua` - Main tooltip logic
- `core/BookArchivist_Core.lua` - Index management (`IndexItemForBook`, `IndexObjectForBook`)
- `core/BookArchivist_Capture.lua` - Index updates during capture
- `locales/*.lua` - Localized "Archived" string

## Future Improvements (Not Implemented)
- Show book count in tooltip ("3 books archived")
- Click tooltip to open BookArchivist to that book
- Colorize by category (Favorite = gold, Recent = blue)
- Cleanup stale indexes (currently harmless but wastes memory)
