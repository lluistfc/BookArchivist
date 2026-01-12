# Feature Plan: Book Echo - Memory Reflection

**Date:** 2026-01-12  
**Status:** Approved - Ready for Implementation  
**Estimated Duration:** ~3 hours (with full TDD compliance)

---

## Executive Summary

A single, factual, one-line memory displayed below the book title in the reader, derived from the user's reading history. Not lore, not narration, not interpretation - just quiet reflection on when and how you've encountered this book before.

The **player supplies the meaning**. We just show the facts.

---

## Philosophy Alignment

✅ **Simplicity** - One line of text, dynamically computed  
✅ **Data-driven** - Uses only tracked metadata  
✅ **Non-intrusive** - Italic, secondary color, easy to ignore  
✅ **Quietly interesting** - Context without explanation  
✅ **Performance** - Computed on-demand, no storage overhead  
✅ **Test-friendly** - Pure function with clear inputs/outputs

---

## Feature Specification

### Visual Presentation

**Location:** Below book title in reader panel  
**Style:** Italic, secondary text color (e.g., `GameFontNormalSmall` with 70% alpha)  
**Content:** Single line, no multiple echoes  
**Behavior:** Updates when book changes, disappears if no echo available

### Echo Priority Logic

Only **one echo** is ever shown. Priority order (first match wins):

1. **First reopen** (`seenCount == 2`) → Origin context
2. **Multiple reads** (`seenCount > 2`) → Recurrence pattern
3. **Resume state** (`lastPageRead exists and < totalPages`) → Continuity
4. **Fallback** (`lastReadAt exists`) → Recency

### Example Echoes (Final Tone)

More narrative—memory-like, evocative echoes:

- `"First discovered among the shelves of Stormwind. Now, the book has returned to you."`
- `"You've returned to these pages 3 times. Each reading leaves its mark."`
- `"Left open at page 4. The rest of the tale awaits."`
- `"Untouched for 12 days. Time has passed since last you turned these pages."`

Echoes that resonate, not just state facts.

---

## Location Context Dictionary

### Philosophy

Instead of static "among the shelves of {location}", we use **location-aware context phrases** that match the environment where the book was discovered.

### Context Patterns

| Location Pattern | Discovery Phrase | Example |
|------------------|------------------|----------|
| **Cities** (Stormwind, Ironforge, Orgrimmar, etc.) | "among the shelves of" | "among the shelves of Stormwind" |
| **Libraries/Archives** (contains "Library", "Archive") | "in the archives of" | "in the archives of Karazhan" |
| **Caves/Caverns** (contains "Cave", "Cavern", "Grotto") | "in the depths of" | "in the depths of Deepholm" |
| **Ruins** (contains "Ruin", "Temple", "Tomb") | "among the ruins of" | "among the ruins of Ahn'Qiraj" |
| **Forests** (contains "Forest", "Grove", "Jungle") | "beneath the canopy of" | "beneath the canopy of Teldrassil" |
| **Deserts** (contains "Desert", "Dunes", "Sands") | "in the sands of" | "in the sands of Silithus" |
| **Mountains** (contains "Mountain", "Peak", "Summit") | "high among the peaks of" | "high among the peaks of Highmountain" |
| **Ships/Vessels** (contains "Ship", "Vessel", "Boat") | "aboard" | "aboard the Skyfire" |
| **Dungeons/Raids** (contains "Citadel", "Sanctum", "Fortress") | "in the shadows of" | "in the shadows of Icecrown Citadel" |
| **Underground** (contains "Undermine", "Undercity", "Below") | "deep within" | "deep within the Undercity" |
| **Wilderness** (contains "Barrens", "Plains", "Wasteland") | "across the wilds of" | "across the wilds of the Barrens" |
| **Shores/Coasts** (contains "Shore", "Coast", "Bay") | "along the shores of" | "along the shores of Vashj'ir" |
| **Islands** (contains "Isle", "Island") | "upon the isle of" | "upon the isle of Quel'Danas" |
| **Generic Fallback** | "in" | "in Tanaris" |

### Pattern Matching Logic

```lua
local LOCATION_CONTEXTS = {
  -- Order matters: check most specific patterns first
  {pattern = "Library", phrase = "in the archives of"},
  {pattern = "Archive", phrase = "in the archives of"},
  {pattern = "Cave", phrase = "in the depths of"},
  {pattern = "Cavern", phrase = "in the depths of"},
  {pattern = "Grotto", phrase = "in the depths of"},
  {pattern = "Ruin", phrase = "among the ruins of"},
  {pattern = "Temple", phrase = "among the ruins of"},
  {pattern = "Tomb", phrase = "among the ruins of"},
  {pattern = "Forest", phrase = "beneath the canopy of"},
  {pattern = "Grove", phrase = "beneath the canopy of"},
  {pattern = "Jungle", phrase = "beneath the canopy of"},
  {pattern = "Desert", phrase = "in the sands of"},
  {pattern = "Dunes", phrase = "in the sands of"},
  {pattern = "Sands", phrase = "in the sands of"},
  {pattern = "Mountain", phrase = "high among the peaks of"},
  {pattern = "Peak", phrase = "high among the peaks of"},
  {pattern = "Summit", phrase = "high among the peaks of"},
  {pattern = "Ship", phrase = "aboard"},
  {pattern = "Vessel", phrase = "aboard"},
  {pattern = "Boat", phrase = "aboard"},
  {pattern = "Citadel", phrase = "in the shadows of"},
  {pattern = "Sanctum", phrase = "in the shadows of"},
  {pattern = "Fortress", phrase = "in the shadows of"},
  {pattern = "Undermine", phrase = "deep within"},
  {pattern = "Undercity", phrase = "deep within"},
  {pattern = "Below", phrase = "deep within"},
  {pattern = "Barrens", phrase = "across the wilds of"},
  {pattern = "Plains", phrase = "across the wilds of"},
  {pattern = "Wasteland", phrase = "across the wilds of"},
  {pattern = "Shore", phrase = "along the shores of"},
  {pattern = "Coast", phrase = "along the shores of"},
  {pattern = "Bay", phrase = "along the shores of"},
  {pattern = "Isle", phrase = "upon the isle of"},
  {pattern = "Island", phrase = "upon the isle of"},
  
  -- City-specific patterns (after generic checks)
  {pattern = "Stormwind", phrase = "among the shelves of"},
  {pattern = "Ironforge", phrase = "among the shelves of"},
  {pattern = "Darnassus", phrase = "among the shelves of"},
  {pattern = "Orgrimmar", phrase = "among the shelves of"},
  {pattern = "Thunder Bluff", phrase = "among the shelves of"},
  {pattern = "Undercity", phrase = "among the shelves of"},
  {pattern = "Silvermoon", phrase = "among the shelves of"},
  {pattern = "Exodar", phrase = "among the shelves of"},
  {pattern = "Shattrath", phrase = "among the shelves of"},
  {pattern = "Dalaran", phrase = "among the shelves of"},
}

local function getLocationContext(locationName)
  if not locationName then return "in" end
  
  -- Check patterns in order
  for _, context in ipairs(LOCATION_CONTEXTS) do
    if locationName:find(context.pattern) then
      return context.phrase
    end
  end
  
  -- Fallback
  return "in"
end
```

### Updated Echo Format

Instead of:
```lua
"First discovered among the shelves of %s. Now, the book has returned to you."
```

We use:
```lua
local contextPhrase = getLocationContext(book.firstReadLocation)
string.format(
  "First discovered %s %s. Now, the book has returned to you.",
  contextPhrase,
  book.firstReadLocation
)
```

### Example Output

| Location | Echo |
|----------|------|
| Stormwind Library | "First discovered **among the shelves of** Stormwind Library. Now, the book has returned to you." |
| Silithus | "First discovered **in the sands of** Silithus. Now, the book has returned to you." |
| Deepholm Cavern | "First discovered **in the depths of** Deepholm. Now, the book has returned to you." |
| Ahn'Qiraj Ruins | "First discovered **among the ruins of** Ahn'Qiraj. Now, the book has returned to you." |
| Icecrown Citadel | "First discovered **in the shadows of** Icecrown Citadel. Now, the book has returned to you." |
| Unknown location | "First discovered **in** Unknown Region. Now, the book has returned to you." |

---

## Data Availability Audit

### Currently Tracked (Verified ✓)

| Field | Type | Tracked When | Available |
|-------|------|--------------|-----------|
| `createdAt` | number (timestamp) | Book first captured | ✅ YES |
| `firstSeenAt` | number (timestamp) | First encounter with book | ✅ YES |
| `lastSeenAt` | number (timestamp) | Most recent capture | ✅ YES |
| `seenCount` | number | Increments each time book recaptured | ✅ YES |
| `lastReadAt` | number (timestamp) | Recent module tracks reader opens | ✅ YES |
| `location.zoneChain` | array | Zone hierarchy when captured | ✅ YES |
| `location.zoneText` | string | Human-readable location | ✅ YES |

### NOT Currently Tracked (Need to Add)

| Field | Type | Purpose | Schema Version |
|-------|------|---------|----------------|
| `firstReadLocation` | string | Zone where first opened in reader | v3 (new) |
| `readCount` | number | How many times opened in reader | v3 (new) |
| `lastPageRead` | number | Last page viewed in reader | v3 (new) |

**Note:** `seenCount` tracks **captures** (looting books from world), not **reads** (opening in reader). We need separate `readCount`.

---

## Schema Enhancement (v2 → v3 Migration)

### New Fields to Add

```lua
-- In BookArchivist_Core.lua CreateOrUpdateEntry()
entry.readCount = entry.readCount or 0
entry.firstReadLocation = entry.firstReadLocation or nil
entry.lastPageRead = entry.lastPageRead or nil
```

### Migration Function

Create `core/BookArchivist_Migrations.lua` → `Migrations.v3()`:

```lua
function Migrations.v3(db)
  -- Add readCount, firstReadLocation, lastPageRead to all books
  for bookId, book in pairs(db.booksById or {}) do
    book.readCount = book.readCount or 0
    book.firstReadLocation = book.firstReadLocation or nil
    book.lastPageRead = book.lastPageRead or nil
  end
  
  db.dbVersion = 3
  return db
end
```

### Reader Tracking Integration

Modify `BookArchivist_UI_Reader.lua` → `ShowBook()`:

```lua
function Reader:ShowBook(bookId)
  -- Existing code...
  
  -- Track read count and first read location
  local book = db.booksById[bookId]
  if book then
    book.readCount = (book.readCount or 0) + 1
    
    -- Capture first read location only once
    if not book.firstReadLocation then
      local Location = BookArchivist.Location
      if Location and Location.BuildWorldLocation then
        local loc = Location:BuildWorldLocation()
        if loc and loc.zoneText then
          book.firstReadLocation = loc.zoneText
        end
      end
    end
  end
  
  -- Existing rendering...
end
```

Modify page navigation to track `lastPageRead`:

```lua
function Reader:SetPage(bookId, pageIndex)
  -- Existing code...
  
  -- Track last page
  local book = db.booksById[bookId]
  if book then
    book.lastPageRead = pageIndex
  end
end
```

---

## Implementation Phases (TDD-Compliant)

### Phase 0: Schema Enhancement & Migration

**Duration:** 1 hour  
**TDD Gate:** Tests written BEFORE migration

#### Step 1: Write Migration Tests (20 minutes)

Add to `Tests/Desktop/Migrations_spec.lua`:

```lua
describe("Migrations v2→v3", function()
  it("should add readCount to all books")
  it("should add firstReadLocation to all books")
  it("should add lastPageRead to all books")
  it("should preserve existing data")
  it("should set dbVersion to 3")
end)
```

Run `make test-errors` → Establish RED state

#### Step 2: Implement Migration (20 minutes)

Create `Migrations.v3()` in `core/BookArchivist_Migrations.lua`

#### Step 3: Wire Migration (10 minutes)

Add v3 migration call to `BookArchivist_DB.lua` init sequence

#### Step 4: Verify (10 minutes)

- Run `make test-errors` → Achieve GREEN state
- All 220 tests passing (5 new migration tests)

---

### Phase 1: Reader Tracking Integration

**Duration:** 45 minutes  
**TDD Gate:** Tests written BEFORE implementation

#### Step 1: Write Tracking Tests (20 minutes)

Create `Tests/Desktop/BookEcho_Tracking_spec.lua`:

```lua
describe("Book Echo Tracking", function()
  it("should increment readCount when book opened")
  it("should capture firstReadLocation only once")
  it("should update lastPageRead on page change")
  it("should not overwrite existing firstReadLocation")
end)
```

Run `make test-errors` → Establish RED state

#### Step 2: Implement Tracking (20 minutes)

Modify `BookArchivist_UI_Reader.lua`:
- Track `readCount` in `ShowBook()`
- Capture `firstReadLocation` in `ShowBook()`
- Track `lastPageRead` in page navigation

#### Step 3: Verify (5 minutes)

- Run `make test-errors` → Achieve GREEN state
- All 224 tests passing (4 new tracking tests)

---

### Phase 2: Echo Computation Logic

**Duration:** 1 hour  
**TDD Gate:** Tests written BEFORE implementation

#### Step 1: Write Echo Tests (40 minutes)

Create `Tests/Desktop/BookEcho_spec.lua`:

```lua
describe("BookEcho", function()
  describe("Priority: First reopen", function()
    it("should show first read location when readCount == 2")
    it("should handle missing firstReadLocation gracefully")
    it("should use 'among the shelves of' for cities like Stormwind")
    it("should use 'in the depths of' for caves and caverns")
    it("should use 'among the ruins of' for temples and ruins")
    it("should use 'in the sands of' for deserts")
    it("should use 'aboard' for ships and vessels")
    it("should use 'in the shadows of' for dungeons and citadels")
    it("should use generic 'in' as fallback for unknown locations")
  end)
  
  describe("Priority: Multiple reads", function()
    it("should show read count when readCount > 2")
    it("should format plural correctly")
  end)
  
  describe("Priority: Resume state", function()
    it("should show last page when lastPageRead < totalPages")
    it("should not show when book fully read")
  end)
  
  describe("Priority: Recency", function()
    it("should show time since last read as fallback")
    it("should format time units correctly (days, hours, minutes)")
  end)
  
  describe("Edge cases", function()
    it("should return nil when no echo available")
    it("should handle missing book data")
    it("should handle corrupted timestamps")
  end)
end)
```

Run `make test-errors` → Establish RED state

#### Step 2: Implement Echo Module (25 minutes)

Create `core/BookArchivist_BookEcho.lua`:

```lua
local BookEcho = {}
BookArchivist.BookEcho = BookEcho

local L = BookArchivist.L or {}

-- Location context patterns (order matters: most specific first)
local LOCATION_CONTEXTS = {
  {pattern = "Library", phrase = "in the archives of"},
  {pattern = "Archive", phrase = "in the archives of"},
  {pattern = "Cave", phrase = "in the depths of"},
  {pattern = "Cavern", phrase = "in the depths of"},
  {pattern = "Grotto", phrase = "in the depths of"},
  {pattern = "Ruin", phrase = "among the ruins of"},
  {pattern = "Temple", phrase = "among the ruins of"},
  {pattern = "Tomb", phrase = "among the ruins of"},
  {pattern = "Forest", phrase = "beneath the canopy of"},
  {pattern = "Grove", phrase = "beneath the canopy of"},
  {pattern = "Jungle", phrase = "beneath the canopy of"},
  {pattern = "Desert", phrase = "in the sands of"},
  {pattern = "Dunes", phrase = "in the sands of"},
  {pattern = "Sands", phrase = "in the sands of"},
  {pattern = "Mountain", phrase = "high among the peaks of"},
  {pattern = "Peak", phrase = "high among the peaks of"},
  {pattern = "Summit", phrase = "high among the peaks of"},
  {pattern = "Ship", phrase = "aboard"},
  {pattern = "Vessel", phrase = "aboard"},
  {pattern = "Boat", phrase = "aboard"},
  {pattern = "Citadel", phrase = "in the shadows of"},
  {pattern = "Sanctum", phrase = "in the shadows of"},
  {pattern = "Fortress", phrase = "in the shadows of"},
  {pattern = "Undermine", phrase = "deep within"},
  {pattern = "Below", phrase = "deep within"},
  {pattern = "Barrens", phrase = "across the wilds of"},
  {pattern = "Plains", phrase = "across the wilds of"},
  {pattern = "Wasteland", phrase = "across the wilds of"},
  {pattern = "Shore", phrase = "along the shores of"},
  {pattern = "Coast", phrase = "along the shores of"},
  {pattern = "Bay", phrase = "along the shores of"},
  {pattern = "Isle", phrase = "upon the isle of"},
  {pattern = "Island", phrase = "upon the isle of"},
  {pattern = "Stormwind", phrase = "among the shelves of"},
  {pattern = "Ironforge", phrase = "among the shelves of"},
  {pattern = "Darnassus", phrase = "among the shelves of"},
  {pattern = "Orgrimmar", phrase = "among the shelves of"},
  {pattern = "Thunder Bluff", phrase = "among the shelves of"},
  {pattern = "Silvermoon", phrase = "among the shelves of"},
  {pattern = "Exodar", phrase = "among the shelves of"},
  {pattern = "Shattrath", phrase = "among the shelves of"},
  {pattern = "Dalaran", phrase = "among the shelves of"},
}

local function getLocationContext(locationName)
  if not locationName then return "in" end
  
  -- Check patterns in order
  for _, context in ipairs(LOCATION_CONTEXTS) do
    if locationName:find(context.pattern) then
      return context.phrase
    end
  end
  
  -- Fallback
  return "in"
end

local function formatTimeAgo(timestamp)
  if not timestamp then return nil end
  
  local now = BookArchivist.Core and BookArchivist.Core:Now() or os.time()
  local diff = now - timestamp
  
  if diff < 0 then return nil end
  
  local days = math.floor(diff / 86400)
  if days > 0 then
    return string.format(L["ECHO_TIME_DAYS"] or "%d days ago", days)
  end
  
  local hours = math.floor(diff / 3600)
  if hours > 0 then
    return string.format(L["ECHO_TIME_HOURS"] or "%d hours ago", hours)
  end
  
  local minutes = math.floor(diff / 60)
  return string.format(L["ECHO_TIME_MINUTES"] or "%d minutes ago", minutes)
end

function BookEcho:GetEchoText(bookId)
  if not bookId then return nil end
  
  local db = BookArchivist.Repository:GetDB()
  local book = db.booksById[bookId]
  if not book then return nil end
  
  -- Priority 1: First reopen (readCount == 2)
  if book.readCount == 2 and book.firstReadLocation then
    local contextPhrase = getLocationContext(book.firstReadLocation)
    return string.format(
      L["ECHO_FIRST_READ"] or "First discovered %s %s. Now, the book has returned to you.",
      contextPhrase,
      book.firstReadLocation
    )
  end
  
  -- Priority 2: Multiple reads (readCount > 2)
  if book.readCount and book.readCount > 2 then
    return string.format(
      L["ECHO_RETURNED"] or "You've returned to these pages %d times. Each reading leaves its mark.",
      book.readCount - 1  -- Subtract current read
    )
  end
  
  -- Priority 3: Resume state (lastPageRead < totalPages)
  if book.lastPageRead and book.pages then
    local totalPages = 0
    for _ in pairs(book.pages) do
      totalPages = totalPages + 1
    end
    
    if book.lastPageRead < totalPages then
      return string.format(
        L["ECHO_LAST_PAGE"] or "Left open at page %d. The rest of the tale awaits.",
        book.lastPageRead
      )
    end
  end
  
  -- Priority 4: Recency (fallback)
  if book.lastReadAt then
    local timeAgo = formatTimeAgo(book.lastReadAt)
    if timeAgo then
      return string.format(
        L["ECHO_LAST_OPENED"] or "Untouched for %s. Time has passed since last you turned these pages.",
        timeAgo
      )
    end
  end
  
  return nil  -- No echo available
end
```

#### Step 3: Verify (5 minutes)

- Run `make test-errors` → Achieve GREEN state
- All 243 tests passing (19 new echo logic tests: 11 base + 8 location context)

---

### Phase 3: UI Integration

**Duration:** 30 minutes  
**TDD Gate:** Visual verification (hard to unit test UI rendering)

#### Step 1: Add Echo Display (20 minutes)

Modify `BookArchivist_UI_Reader.lua`:

```lua
function Reader:UpdateEchoText(bookId)
  local echoFrame = self:GetFrame("echoText")
  if not echoFrame then
    -- Create echo text frame below title
    local titleFrame = self:GetFrame("titleText")
    if not titleFrame then return end
    
    echoFrame = titleFrame:GetParent():CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    echoFrame:SetPoint("TOP", titleFrame, "BOTTOM", 0, -2)
    echoFrame:SetWidth(titleFrame:GetWidth())
    echoFrame:SetJustifyH("LEFT")
    echoFrame:SetTextColor(0.7, 0.7, 0.7, 0.8)  -- Secondary color, slightly transparent
    echoFrame:SetFontObject("GameFontNormalSmall")
    
    -- Make italic if possible
    local font, size = echoFrame:GetFont()
    if font then
      echoFrame:SetFont(font, size, "ITALIC")
    end
    
    self:SetFrame("echoText", echoFrame)
  end
  
  local BookEcho = BookArchivist.BookEcho
  if not BookEcho then
    echoFrame:SetText("")
    return
  end
  
  local echoText = BookEcho:GetEchoText(bookId)
  if echoText then
    echoFrame:SetText(echoText)
    echoFrame:Show()
  else
    echoFrame:SetText("")
    echoFrame:Hide()
  end
end

-- Call in ShowBook() after title is set
function Reader:ShowBook(bookId)
  -- Existing code...
  
  -- Update echo after title
  self:UpdateEchoText(bookId)
end
```

#### Step 2: In-Game Verification (10 minutes)

- `/reload` and test various books
- Verify echo displays correctly
- Check all 4 priority cases manually
- Confirm italic styling and color

---

### Phase 4: Localization

**Duration:** 30 minutes

#### Add to ALL 7 Locale Files

`locales/enUS.lua`, `esES.lua`, `caES.lua`, `frFR.lua`, `deDE.lua`, `itIT.lua`, `ptBR.lua`:

```lua
-- Book Echo strings
L["ECHO_FIRST_READ"] = "First discovered %s %s. Now, the book has returned to you."
L["ECHO_RETURNED"] = "You've returned to these pages %d times. Each reading leaves its mark."
L["ECHO_LAST_PAGE"] = "Left open at page %d. The rest of the tale awaits."
L["ECHO_LAST_OPENED"] = "Untouched for %s. Time has passed since last you turned these pages."
L["ECHO_TIME_DAYS"] = "%d days ago"
L["ECHO_TIME_HOURS"] = "%d hours ago"
L["ECHO_TIME_MINUTES"] = "%d minutes ago"
```

**Translation Notes:**
- `%s` = string placeholder
- `%d` = number placeholder
- **Note:** `ECHO_FIRST_READ` uses TWO `%s` placeholders: first for context phrase ("among the shelves of", "in the depths of", etc.), second for location name
- Location context phrases are NOT localized (they're computed dynamically in code)
- Keep grammar simple (no complex constructions)
- Preserve placeholder order

**Location Context Phrases** (add these as separate locale keys):

```lua
-- Location context phrases
L["LOC_CONTEXT_SHELVES"] = "among the shelves of"
L["LOC_CONTEXT_ARCHIVES"] = "in the archives of"
L["LOC_CONTEXT_DEPTHS"] = "in the depths of"
L["LOC_CONTEXT_RUINS"] = "among the ruins of"
L["LOC_CONTEXT_CANOPY"] = "beneath the canopy of"
L["LOC_CONTEXT_SANDS"] = "in the sands of"
L["LOC_CONTEXT_PEAKS"] = "high among the peaks of"
L["LOC_CONTEXT_ABOARD"] = "aboard"
L["LOC_CONTEXT_SHADOWS"] = "in the shadows of"
L["LOC_CONTEXT_DEEP"] = "deep within"
L["LOC_CONTEXT_WILDS"] = "across the wilds of"
L["LOC_CONTEXT_SHORES"] = "along the shores of"
L["LOC_CONTEXT_ISLE"] = "upon the isle of"
L["LOC_CONTEXT_IN"] = "in"  -- Generic fallback
```

---

## Success Criteria

All items must be ✓ before feature is considered complete:

- [ ] Schema v2→v3 migration complete
- [ ] All books have `readCount`, `firstReadLocation`, `lastPageRead` fields
- [ ] Reader tracks `readCount` on book open
- [ ] Reader captures `firstReadLocation` once per book
- [ ] Reader tracks `lastPageRead` on page change
- [ ] Echo computation follows priority logic correctly
- [ ] Location context phrases work for all environment types
- [ ] Location context fallback handles unknown zones gracefully
- [ ] Echo displays below title in reader
- [ ] Echo uses italic, secondary color styling
- [ ] Echo updates when book changes
- [ ] Echo hides when no data available
- [ ] All 235+ tests passing
- [ ] No regressions in existing functionality
- [ ] All 7 locale files updated
- [ ] In-game verification for all 4 echo types
- [ ] Time formatting works correctly (days/hours/minutes)

---

## Timeline Estimate

| Phase | Duration | Type |
|-------|----------|------|
| Phase 0: Schema Enhancement | 1 hour | TDD (migration + tests) |
| Phase 1: Reader Tracking | 45 min | TDD (tracking integration) |
| Phase 2: Echo Logic | 1 hour | TDD (computation + tests) |
| Phase 3: UI Integration | 30 min | UI rendering + visual verification |
| Phase 4: Localization | 30 min | Update all 7 locale files |
| **TOTAL** | **~3.5 hours** | Full TDD compliance |

---

## Commit Strategy

Each phase should be committed separately:

1. **Phase 0 commit:**
   ```
   feat(schema): add v3 migration for Book Echo tracking fields
   - Add readCount, firstReadLocation, lastPageRead to schema
   - Migration preserves all existing data
   - dbVersion bumped to 3
   - All 220 tests passing (5 new migration tests)
   ```

2. **Phase 1 commit:**
   ```
   feat(reader): track reading history for Book Echo
   - Increment readCount when book opened
   - Capture firstReadLocation on first reader open
   - Track lastPageRead on page navigation
   - All 224 tests passing (4 new tracking tests)
   ```

3. **Phase 2 commit:**
   ```
   feat(echo): implement Book Echo computation logic
   - Priority: first reopen > multiple reads > resume > recency
   - GetEchoText() returns factual one-line memory
   - Time formatting (days/hours/minutes ago)
   - All 235 tests passing (11 new echo logic tests)
   ```

4. **Phase 3 commit:**
   ```
   feat(ui): display Book Echo below title in reader
   - Italic, secondary color styling
   - Updates when book changes
   - Hides when no echo available
   - Non-intrusive presentation
   ```

5. **Phase 4 commit:**
   ```
   feat(locale): add Book Echo translations for 7 languages
   - ECHO_FIRST_READ, ECHO_RETURNED, ECHO_LAST_PAGE, ECHO_LAST_OPENED
   - ECHO_TIME_DAYS, ECHO_TIME_HOURS, ECHO_TIME_MINUTES
   - Simple variable substitution, no complex grammar
   ```

---

## Technical Considerations

### Why Dynamic Computation?

**Advantages:**
- ✅ No migration pain when echo logic changes
- ✅ No storage overhead (no `echoText` field)
- ✅ Localization flexibility (templates can change)
- ✅ Easy to A/B test different echo priorities

**Performance:**
- Computed once per book open (negligible cost)
- Simple conditionals + string formatting
- No heavy processing or iteration

### Why These Specific Fields?

**`readCount` vs `seenCount`:**
- `seenCount` tracks **looting** (world interaction)
- `readCount` tracks **reading** (UI interaction)
- Echo cares about reading, not looting

**`firstReadLocation` vs `location`:**
- `location` = where book was **found** (capture location)
- `firstReadLocation` = where book was **first opened** (reader location)
- Echo cares about reader context, not loot context

**`lastPageRead` for resume:**
- Enables "pick up where you left off" context
- Only meaningful when user didn't finish book
- Simple number, no complex bookmark structure

---

## Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| Brand new book (readCount = 0) | No echo shown |
| First read (readCount = 1) | No echo shown (needs 2+ for context) |
| First reopen (readCount = 2) | Show "First read in {location}" |
| Missing firstReadLocation | Skip to next priority (multiple reads) |
| Book fully read | Skip resume priority (no "last page") |
| Missing lastReadAt | No fallback echo (return nil) |
| Corrupted timestamp | formatTimeAgo returns nil, skip echo |
| Empty pages | totalPages = 0, resume logic skips |

---

## Future Enhancements (Out of Scope)

These are explicitly **NOT** part of this feature:

- ❌ Multiple echoes at once
- ❌ Echo history/log
- ❌ User-configurable echo priorities
- ❌ Echo for books not yet opened (speculation)
- ❌ Mood/tone/interpretation of data
- ❌ Weather integration (we killed this, remember?)

The echo is **quietly factual**. If users want more context, they can interpret the data themselves. We supply facts, not meaning.

---

## Final Recommendation

**Status:** ✅ APPROVED FOR IMPLEMENTATION

This feature is:
- Philosophically aligned with BookArchivist's "quiet utility" values
- Technically feasible with schema enhancement (v2→v3 migration)
- Low-risk with clear test coverage
- High-delight with subtle, personal context

**Critical Dependency:** Must complete schema v2→v3 migration BEFORE any reader tracking or echo logic. Migration must be tested thoroughly to prevent data corruption.

Proceed with Phase 0 schema enhancement when ready to begin implementation.
