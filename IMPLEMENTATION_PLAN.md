# BookArchivist Implementation Plan
**Created:** January 8, 2026  
**Target Completion:** 6-8 weeks (assuming 10-15 hours/week)  
**Total Effort:** 60-80 hours

---

## 📋 EXECUTION PHILOSOPHY

**RULES:**
1. **No new features until Phase 1 is complete** (zero tolerance policy)
2. **Every change must include tests** (manual test protocol at minimum)
3. **Commit after each major step** (rollback capability)
4. **Profile before and after each optimization** (prove improvements)
5. **One PR/branch per phase** (reviewable chunks)

**IF YOU VIOLATE RULE #1, YOU'RE JUST ADDING MORE TECHNICAL DEBT.**

---

## 🎯 PHASE 0: PREPARATION (Week 1 - 8 hours)

### STOP. Before you write ANY code:

#### 0.1 Set Up Profiling Infrastructure (2 hours)
**Why:** You can't optimize what you can't measure.

```lua
-- Create: core/BookArchivist_Profiler.lua
local Profiler = {}
BookArchivist.Profiler = Profiler

local profiles = {}
local startTimes = {}

function Profiler:Start(label)
  startTimes[label] = debugprofilestop()
end

function Profiler:Stop(label)
  local elapsed = debugprofilestop() - (startTimes[label] or 0)
  profiles[label] = profiles[label] or { count = 0, total = 0, max = 0, min = math.huge }
  local p = profiles[label]
  p.count = p.count + 1
  p.total = p.total + elapsed
  p.max = math.max(p.max, elapsed)
  p.min = math.min(p.min, elapsed)
  startTimes[label] = nil
  return elapsed
end

function Profiler:Report()
  local lines = {"=== PERFORMANCE REPORT ==="}
  for label, data in pairs(profiles) do
    local avg = data.total / data.count
    table.insert(lines, string.format(
      "%s: avg=%.2fms, max=%.2fms, min=%.2fms, count=%d, total=%.2fms",
      label, avg, data.max, data.min, data.count, data.total
    ))
  end
  return table.concat(lines, "\n")
end

function Profiler:Reset()
  profiles = {}
  startTimes = {}
end
```

**Action Items:**
- [ ] Create Profiler module
- [ ] Add to .toc file
- [ ] Add `/ba profile` command to dump report
- [ ] Instrument existing hot paths (GetDB, UpdateList, BuildSearchText)

#### 0.2 Create Test Data Generator (3 hours)
**Why:** You need to test with 1000+ books, not your 50-book personal database.

```lua
-- Create: dev/BookArchivist_TestDataGenerator.lua
local Generator = {}

function Generator:CreateTestBook(index)
  local title = "Test Book " .. index
  local pages = {}
  local numPages = math.random(1, 50)
  for i = 1, numPages do
    pages[i] = string.format("Page %d of test book %d. Lorem ipsum dolor sit amet, consectetur adipiscing elit. " .. string.rep("Text ", 20), i, index)
  end
  
  return {
    title = title,
    creator = index % 3 == 0 and "Test Author " .. math.floor(index / 3) or "",
    material = index % 2 == 0 and "Parchment" or "",
    pages = pages,
    firstSeenAt = time() - (index * 3600),
    lastSeenAt = time() - (index * 1800),
    seenCount = math.random(1, 10),
    isFavorite = index % 10 == 0,
  }
end

function Generator:GenerateBooks(count)
  local Core = BookArchivist.Core
  local BookId = BookArchivist.BookId
  
  for i = 1, count do
    local entry = self:CreateTestBook(i)
    local bookId = BookId:MakeBookIdV2(entry.title, entry.pages)
    
    local db = Core:GetDB()
    db.booksById[bookId] = entry
    Core:AppendOrder(bookId)
    
    if i % 100 == 0 then
      print(string.format("Generated %d/%d books", i, count))
    end
  end
  
  print(string.format("Test data generation complete: %d books", count))
end

-- Slash command
SLASH_BAGENTESTDATA1 = "/bagentest"
SlashCmdList.BAGENTESTDATA = function(msg)
  local count = tonumber(msg) or 1000
  Generator:GenerateBooks(count)
  ReloadUI()
end
```

**Action Items:**
- [ ] Create test data generator
- [ ] Generate test profiles: 100, 500, 1000, 2500, 5000 books
- [ ] Verify performance degrades with larger datasets (baseline metrics)

#### 0.3 Establish Baseline Metrics (1 hour)
**Why:** Prove your optimizations actually work.

Run these tests with 1000 test books:
- [ ] Login time to ADDON_LOADED complete: _____ms
- [ ] Login time to UI fully rendered: _____ms
- [ ] Time to open main window: _____ms
- [ ] Time to refresh list (full): _____ms
- [ ] Time to search (10 character query): _____ms
- [ ] Memory usage after login: _____KB
- [ ] Memory usage after 5 UI refreshes: _____KB

**Document these in `PERFORMANCE_BASELINE.md`**

#### 0.4 Set Up Git Branches (1 hour)
```bash
git checkout -b refactor/phase-1-critical-fixes
git checkout -b refactor/phase-2-performance
git checkout -b refactor/phase-3-architecture
```

#### 0.5 Create Rollback Plan (1 hour)
**Because you WILL break things.**

**Action Items:**
- [ ] Backup current SavedVariables folder
- [ ] Create DB version bump strategy
- [ ] Document rollback procedure for users
- [ ] Create compatibility layer for old → new transitions

---

## 🔴 PHASE 1: CRITICAL FIXES (Weeks 2-3 - 20 hours)

**GOAL:** Prevent data loss and catastrophic performance issues.

### 1.1 SavedVariables Corruption Protection (4 hours)

**Current Danger:**
```lua
-- This WILL fail on corruption
BookArchivistDB = BookArchivistDB or {}
```

**Implementation:**

```lua
-- core/BookArchivist_DBSafety.lua
local DBSafety = {}
BookArchivist.DBSafety = DBSafety

local BACKUP_PREFIX = "BookArchivistDB_Backup_"

function DBSafety:ValidateStructure(db)
  if type(db) ~= "table" then
    return false, "DB is not a table"
  end
  
  if type(db.booksById) ~= "table" then
    return false, "booksById is not a table"
  end
  
  if type(db.order) ~= "table" then
    return false, "order is not a table"
  end
  
  -- Validate critical fields
  if db.dbVersion and type(db.dbVersion) ~= "number" then
    return false, "dbVersion is not a number"
  end
  
  return true, "Valid"
end

function DBSafety:CreateBackup()
  local timestamp = date("%Y%m%d_%H%M%S")
  local backupName = BACKUP_PREFIX .. timestamp
  
  _G[backupName] = {}
  for k, v in pairs(BookArchivistDB) do
    _G[backupName][k] = BookArchivist.Core.CloneTable(v)
  end
  
  return backupName
end

function DBSafety:SafeLoad()
  -- Check if DB exists and is valid
  if not BookArchivistDB then
    return self:InitializeFreshDB()
  end
  
  local valid, error = self:ValidateStructure(BookArchivistDB)
  if not valid then
    -- CORRUPTION DETECTED
    local corrupted = BookArchivistDB
    local backupName = self:CreateCorruptionBackup(corrupted)
    
    StaticPopupDialogs["BOOKARCHIVIST_CORRUPTION"] = {
      text = string.format(
        "BookArchivist detected SavedVariables corruption:\n\n%s\n\nYour data has been backed up to '%s'.\n\nA fresh database will be created.\n\nPlease report this to the addon author!",
        error, backupName
      ),
      button1 = "OK",
      timeout = 0,
      whileDead = true,
      hideOnEscape = false,
      preferredIndex = 3,
    }
    StaticPopup_Show("BOOKARCHIVIST_CORRUPTION")
    
    BookArchivistDB = self:InitializeFreshDB()
  end
  
  return BookArchivistDB
end

function DBSafety:CreateCorruptionBackup(corrupted)
  local timestamp = date("%Y%m%d_%H%M%S")
  local backupName = BACKUP_PREFIX .. "CORRUPTED_" .. timestamp
  _G[backupName] = corrupted
  return backupName
end

function DBSafety:InitializeFreshDB()
  return {
    dbVersion = 2,
    version = 1,
    createdAt = time(),
    order = {},
    options = {},
    booksById = {},
    indexes = { objectToBookId = {} },
  }
end
```

**Integration in BookArchivist_DB.lua:**
```lua
function DB:Init()
  -- REPLACE existing init logic
  local DBSafety = BookArchivist.DBSafety
  BookArchivistDB = DBSafety:SafeLoad()
  
  -- Continue with migrations...
end
```

**Action Items:**
- [ ] Create DBSafety module
- [ ] Integrate into DB:Init()
- [ ] Add corruption popup dialog
- [ ] Test with deliberately corrupted SavedVariables
- [ ] Document backup location for users

**Test Cases:**
```lua
-- Test 1: DB is a string
BookArchivistDB = "corrupted"
-- Expected: Backup created, fresh DB initialized, popup shown

-- Test 2: DB.booksById is missing
BookArchivistDB = { order = {} }
-- Expected: Backup created, fresh DB initialized

-- Test 3: Valid DB
BookArchivistDB = { booksById = {}, order = {}, dbVersion = 2 }
-- Expected: Validation passes, no popup
```

### 1.2 Database Iteration Throttling (8 hours)

**Current Problem:** Full table scans freeze UI

**Solution Architecture:**

```lua
-- core/BookArchivist_Iterator.lua
local Iterator = {}
BookArchivist.Iterator = Iterator

local activeIterations = {}

--- Create a throttled iterator that processes large tables in chunks
--- @param operation string Unique identifier for this operation
--- @param dataSource table Table to iterate over
--- @param callback function(key, value, context) -> shouldContinue
--- @param options table { chunkSize=number, budgetMs=number, onProgress=function, onComplete=function }
--- @return boolean success
function Iterator:Start(operation, dataSource, callback, options)
  if activeIterations[operation] then
    return false, "Operation already in progress"
  end
  
  options = options or {}
  local chunkSize = options.chunkSize or 50
  local budgetMs = options.budgetMs or 10
  local onProgress = options.onProgress
  local onComplete = options.onComplete
  
  -- Create array of keys for deterministic iteration
  local keys = {}
  for k in pairs(dataSource) do
    table.insert(keys, k)
  end
  table.sort(keys)
  
  local state = {
    keys = keys,
    total = #keys,
    index = 1,
    callback = callback,
    chunkSize = chunkSize,
    budgetMs = budgetMs,
    onProgress = onProgress,
    onComplete = onComplete,
    dataSource = dataSource,
    context = {},
  }
  
  activeIterations[operation] = state
  
  -- Create worker frame
  local frame = CreateFrame("Frame")
  frame:SetScript("OnUpdate", function()
    self:_ProcessChunk(operation, state)
  end)
  state.frame = frame
  
  return true
end

function Iterator:_ProcessChunk(operation, state)
  local startTime = debugprofilestop()
  local processed = 0
  
  while state.index <= state.total and processed < state.chunkSize do
    local key = state.keys[state.index]
    local value = state.dataSource[key]
    
    -- Call user callback
    local shouldContinue = state.callback(key, value, state.context)
    
    state.index = state.index + 1
    processed = processed + 1
    
    if not shouldContinue then
      self:Cancel(operation)
      return
    end
    
    -- Budget check
    local elapsed = debugprofilestop() - startTime
    if elapsed >= state.budgetMs then
      break
    end
  end
  
  -- Progress callback
  if state.onProgress then
    local progress = state.index / state.total
    state.onProgress(progress, state.index, state.total)
  end
  
  -- Check completion
  if state.index > state.total then
    if state.onComplete then
      state.onComplete(state.context)
    end
    self:Cancel(operation)
  end
end

function Iterator:Cancel(operation)
  local state = activeIterations[operation]
  if state and state.frame then
    state.frame:SetScript("OnUpdate", nil)
    activeIterations[operation] = nil
  end
end

function Iterator:IsRunning(operation)
  return activeIterations[operation] ~= nil
end
```

**Fix Title Index Backfill (Core.lua:168-176):**

```lua
-- REPLACE the immediate loop with throttled iteration
if not BookArchivistDB.indexes._titleIndexBackfilled then
  local Iterator = BookArchivist.Iterator
  
  Iterator:Start(
    "backfill_title_index",
    BookArchivistDB.booksById,
    function(bookId, entry, context)
      if type(entry) == "table" and entry.title and entry.title ~= "" then
        local key = normalizeKeyPart(entry.title)
        if key ~= "" then
          context.titleIndex = context.titleIndex or {}
          context.titleIndex[key] = context.titleIndex[key] or {}
          context.titleIndex[key][bookId] = true
        end
      end
      return true -- continue
    end,
    {
      chunkSize = 100,
      budgetMs = 8,
      onProgress = function(progress, current, total)
        if BookArchivist.DebugPrint then
          if current % 500 == 0 then
            BookArchivist:DebugPrint(string.format("Indexing titles: %d/%d (%.1f%%)", current, total, progress * 100))
          end
        end
      end,
      onComplete = function(context)
        BookArchivistDB.indexes.titleToBookIds = context.titleIndex or {}
        BookArchivistDB.indexes._titleIndexBackfilled = true
        BookArchivist:DebugPrint("Title index backfill complete")
      end
    }
  )
end
```

**Action Items:**
- [ ] Create Iterator module
- [ ] Replace title index backfill with throttled version
- [ ] Replace migration v2 iteration with throttled version
- [ ] Add progress UI overlay during long operations
- [ ] Test with 5000 book database

**Validation:**
- Login with 1000 books should complete in <500ms
- Title index backfill should run in background without freezing
- Progress should be visible to user

### 1.3 Frame Pooling System (8 hours)

**Current Problem:** Creating frames for every list row = memory leak

**Solution:**

```lua
-- ui/BookArchivist_UI_FramePool.lua
local FramePool = {}
BookArchivist.UI.FramePool = FramePool

local pools = {}

--- Create or get a frame pool
--- @param poolName string Unique pool identifier
--- @param frameType string Frame type ("Button", "Frame", etc)
--- @param parent Frame Parent frame
--- @param template string|nil Frame template
--- @return table pool
function FramePool:CreatePool(poolName, frameType, parent, template)
  if pools[poolName] then
    return pools[poolName]
  end
  
  local pool = {
    name = poolName,
    frameType = frameType,
    parent = parent,
    template = template,
    available = {},
    active = {},
    resetFunc = nil,
  }
  
  pools[poolName] = pool
  return pool
end

--- Set custom reset function for frames when released
function FramePool:SetResetFunction(poolName, resetFunc)
  local pool = pools[poolName]
  if pool then
    pool.resetFunc = resetFunc
  end
end

--- Acquire a frame from the pool
function FramePool:Acquire(poolName)
  local pool = pools[poolName]
  if not pool then
    return nil, "Pool not found"
  end
  
  local frame
  if #pool.available > 0 then
    -- Reuse existing frame
    frame = table.remove(pool.available)
  else
    -- Create new frame
    frame = CreateFrame(pool.frameType, nil, pool.parent, pool.template)
    frame.__poolName = poolName
  end
  
  frame:Show()
  pool.active[frame] = true
  return frame
end

--- Release a frame back to the pool
function FramePool:Release(frame)
  if not frame or not frame.__poolName then
    return false
  end
  
  local poolName = frame.__poolName
  local pool = pools[poolName]
  if not pool then
    return false
  end
  
  -- Reset frame state
  if pool.resetFunc then
    pool.resetFunc(frame)
  else
    self:DefaultReset(frame)
  end
  
  frame:Hide()
  frame:ClearAllPoints()
  
  pool.active[frame] = nil
  table.insert(pool.available, frame)
  
  return true
end

function FramePool:DefaultReset(frame)
  -- Clear common properties
  if frame.SetText then frame:SetText("") end
  if frame.SetNormalTexture then frame:SetNormalTexture(nil) end
  if frame.SetHighlightTexture then frame:SetHighlightTexture(nil) end
  -- Clear scripts
  frame:SetScript("OnClick", nil)
  frame:SetScript("OnEnter", nil)
  frame:SetScript("OnLeave", nil)
end

--- Release all active frames in a pool
function FramePool:ReleaseAll(poolName)
  local pool = pools[poolName]
  if not pool then return end
  
  local toRelease = {}
  for frame in pairs(pool.active) do
    table.insert(toRelease, frame)
  end
  
  for _, frame in ipairs(toRelease) do
    self:Release(frame)
  end
end

--- Get pool statistics
function FramePool:GetStats(poolName)
  local pool = pools[poolName]
  if not pool then return nil end
  
  local activeCount = 0
  for _ in pairs(pool.active) do
    activeCount = activeCount + 1
  end
  
  return {
    available = #pool.available,
    active = activeCount,
    total = #pool.available + activeCount,
  }
end
```

**Integration with List Rows:**

```lua
-- ui/list/BookArchivist_UI_List_Rows.lua
function ListUI:InitializeRowPool()
  local FramePool = BookArchivist.UI.FramePool
  local scrollBox = self:GetFrame("scrollBox")
  
  FramePool:CreatePool("listRows", "Button", scrollBox, "BackdropTemplate")
  
  -- Custom reset function for row buttons
  FramePool:SetResetFunction("listRows", function(frame)
    frame:SetText("")
    frame:SetNormalTexture(nil)
    frame.bookKey = nil
    frame.itemKind = nil
    -- Clear textures, fonts, etc.
  end)
end

function ListUI:UpdateList()
  local FramePool = BookArchivist.UI.FramePool
  local dataProvider = self:GetDataProvider()
  
  -- Release all existing rows back to pool
  FramePool:ReleaseAll("listRows")
  
  -- ... existing filtering logic ...
  
  for i = startIndex, endIndex do
    local key = filtered[i]
    if key then
      local entry = books[key]
      if entry then
        -- Acquire frame from pool instead of creating
        local row = FramePool:Acquire("listRows")
        
        -- Configure row
        row.bookKey = key
        row.itemKind = "book"
        row:SetText(entry.title)
        row:SetPoint("TOPLEFT", 0, -(i - startIndex) * ROW_HEIGHT)
        
        -- ... rest of row setup ...
      end
    end
  end
end
```

**Action Items:**
- [ ] Create FramePool module
- [ ] Initialize row pool in ListUI:Create()
- [ ] Replace row creation with pool acquisition
- [ ] Add pool stats to debug command (`/ba poolstats`)
- [ ] Test memory usage before/after (should be flat after initial creation)

**Validation:**
- Open list with 100 books, check memory
- Scroll through 1000 books, check memory
- Memory should NOT increase after initial pool creation
- Pool stats should show reuse (available frames being recycled)

---

## 🟠 PHASE 2: PERFORMANCE OPTIMIZATION (Weeks 4-5 - 20 hours)

**GOAL:** Smooth 60 FPS performance with 1000+ books.

### 2.1 Caching Layer (6 hours)

```lua
-- core/BookArchivist_Cache.lua
local Cache = {}
BookArchivist.Cache = Cache

local caches = {
  searchText = {},
  bookKeys = {},
  filteredLists = {},
  locationTree = {},
}

local cacheStats = {
  hits = {},
  misses = {},
}

function Cache:Get(cacheName, key)
  if not caches[cacheName] then
    return nil
  end
  
  local value = caches[cacheName][key]
  if value ~= nil then
    cacheStats.hits[cacheName] = (cacheStats.hits[cacheName] or 0) + 1
    return value
  end
  
  cacheStats.misses[cacheName] = (cacheStats.misses[cacheName] or 0) + 1
  return nil
end

function Cache:Set(cacheName, key, value)
  if not caches[cacheName] then
    caches[cacheName] = {}
  end
  caches[cacheName][key] = value
end

function Cache:Invalidate(cacheName, key)
  if not caches[cacheName] then return end
  
  if key then
    caches[cacheName][key] = nil
  else
    caches[cacheName] = {}
  end
end

function Cache:InvalidateBook(bookId)
  self:Invalidate("searchText", bookId)
  self:Invalidate("bookKeys", bookId)
  self:Invalidate("filteredLists") -- Full invalidation
end

function Cache:GetStats()
  local report = {}
  for cacheName, hits in pairs(cacheStats.hits) do
    local misses = cacheStats.misses[cacheName] or 0
    local total = hits + misses
    local hitRate = total > 0 and (hits / total * 100) or 0
    
    report[cacheName] = {
      hits = hits,
      misses = misses,
      hitRate = hitRate,
      size = caches[cacheName] and self:GetCacheSize(caches[cacheName]) or 0,
    }
  end
  return report
end

function Cache:GetCacheSize(cache)
  local count = 0
  for _ in pairs(cache) do
    count = count + 1
  end
  return count
end
```

**Integrate Caching:**

```lua
-- core/BookArchivist_Search.lua
function Core:BuildSearchText(title, pages)
  local Cache = BookArchivist.Cache
  local cacheKey = title .. ":" .. tostring(pages)
  
  local cached = Cache:Get("searchText", cacheKey)
  if cached then
    return cached
  end
  
  local result = buildSearchText(title, pages)
  Cache:Set("searchText", cacheKey, result)
  return result
end

-- core/BookArchivist_Core.lua
function Core:PersistSession(session)
  -- ... existing logic ...
  
  local bookId = persisted.id or persisted.key
  local Cache = BookArchivist.Cache
  Cache:InvalidateBook(bookId) -- Invalidate when book changes
  
  return persisted
end
```

**Action Items:**
- [ ] Create Cache module
- [ ] Add caching to BuildSearchText
- [ ] Add caching to makeKey
- [ ] Add cache invalidation on book create/update/delete
- [ ] Add `/ba cachestats` command
- [ ] Profile hit rates (target >80% hit rate for searchText)

### 2.2 String Optimization (4 hours)

**Replace all string concatenation in loops:**

```lua
-- BEFORE (BookArchivist_Search.lua)
function buildSearchText(title, pages)
  local out = normalizeSearchText(title or "")
  if type(pages) == "table" then
    for pageNum in pairs(pages) do
      local norm = normalizeSearchText(pages[pageNum])
      if norm ~= "" then
        if out ~= "" then
          out = out .. "\n" .. norm  -- BAD: creates new string every iteration
        else
          out = norm
        end
      end
    end
  end
  return out
end

-- AFTER
function buildSearchText(title, pages)
  local parts = {}
  local titleNorm = normalizeSearchText(title or "")
  if titleNorm ~= "" then
    table.insert(parts, titleNorm)
  end
  
  if type(pages) == "table" then
    -- Sort pages for deterministic results
    local pageNums = {}
    for pageNum in pairs(pages) do
      if type(pageNum) == "number" then
        table.insert(pageNums, pageNum)
      end
    end
    table.sort(pageNums)
    
    for _, pageNum in ipairs(pageNums) do
      local norm = normalizeSearchText(pages[pageNum])
      if norm ~= "" then
        table.insert(parts, norm)
      end
    end
  end
  
  return table.concat(parts, "\n")
end
```

**Action Items:**
- [ ] Replace concatenation in buildSearchText
- [ ] Replace concatenation in makeKey
- [ ] Replace concatenation in location breadcrumb building
- [ ] Profile string allocations (use `/run collectgarbage("count")` before/after)

### 2.3 Eliminate Redundant DB Access (3 hours)

**Current Problem:** Every function calls `GetDB()`

**Solution: Memoization pattern**

```lua
-- core/BookArchivist_Core.lua
local dbCache = nil
local dbCacheInvalid = false

function Core:InvalidateDBCache()
  dbCacheInvalid = true
end

function Core:GetDB()
  if dbCache and not dbCacheInvalid then
    return dbCache
  end
  
  dbCache = ensureDB()
  dbCacheInvalid = false
  return dbCache
end

-- Invalidate cache only when DB structure changes
function Core:PersistSession(session)
  -- ... existing logic ...
  self:InvalidateDBCache() -- Only if structure changed
end
```

**Action Items:**
- [ ] Add DB cache memoization
- [ ] Add invalidation on structure changes
- [ ] Profile GetDB() calls (should see dramatic reduction)

### 2.4 Optimize List Filtering (7 hours)

**Current Problem:** Full list rebuild on every filter change

**Solution: Incremental filtering**

```lua
-- ui/list/BookArchivist_UI_List_Filter.lua
local FilterEngine = {}

function FilterEngine:BuildFilteredList(allKeys, filters, searchQuery, categoryId)
  local Cache = BookArchivist.Cache
  
  -- Create cache key from filter state
  local cacheKey = self:GetFilterCacheKey(filters, searchQuery, categoryId)
  local cached = Cache:Get("filteredLists", cacheKey)
  if cached then
    return cached
  end
  
  -- Build filtered list
  local result = {}
  for i = 1, #allKeys do
    local key = allKeys[i]
    if self:PassesFilters(key, filters, searchQuery, categoryId) then
      table.insert(result, key)
    end
  end
  
  Cache:Set("filteredLists", cacheKey, result)
  return result
end

function FilterEngine:GetFilterCacheKey(filters, searchQuery, categoryId)
  local parts = {}
  for k, v in pairs(filters) do
    table.insert(parts, k .. "=" .. tostring(v))
  end
  table.sort(parts)
  table.insert(parts, "query=" .. (searchQuery or ""))
  table.insert(parts, "cat=" .. (categoryId or "__all__"))
  return table.concat(parts, "|")
end
```

**Action Items:**
- [ ] Create FilterEngine with caching
- [ ] Replace inline filtering in UpdateList
- [ ] Add filter cache invalidation on book changes
- [ ] Profile filter performance (target <16ms for 1000 books)

---

## 🔧 PHASE 3: ARCHITECTURAL IMPROVEMENTS (Weeks 6-7 - 20 hours)

**GOAL:** Clean, maintainable architecture.

### 3.1 Event Dispatcher System (4 hours)

```lua
-- core/BookArchivist_EventDispatcher.lua
local EventDispatcher = {}
BookArchivist.EventDispatcher = EventDispatcher

local handlers = {}
local eventFrame = nil

function EventDispatcher:Initialize()
  if eventFrame then return end
  
  eventFrame = CreateFrame("Frame")
  eventFrame:SetScript("OnEvent", function(_, event, ...)
    self:Dispatch(event, ...)
  end)
end

function EventDispatcher:Register(event, handler, priority)
  if not handlers[event] then
    handlers[event] = {}
    if eventFrame then
      eventFrame:RegisterEvent(event)
    end
  end
  
  table.insert(handlers[event], {
    handler = handler,
    priority = priority or 0,
  })
  
  -- Sort by priority (higher first)
  table.sort(handlers[event], function(a, b)
    return a.priority > b.priority
  end)
end

function EventDispatcher:Unregister(event, handler)
  if not handlers[event] then return end
  
  for i = #handlers[event], 1, -1 do
    if handlers[event][i].handler == handler then
      table.remove(handlers[event], i)
    end
  end
  
  if #handlers[event] == 0 then
    handlers[event] = nil
    if eventFrame then
      eventFrame:UnregisterEvent(event)
    end
  end
end

function EventDispatcher:Dispatch(event, ...)
  local eventHandlers = handlers[event]
  if not eventHandlers then return end
  
  for i = 1, #eventHandlers do
    local success, err = pcall(eventHandlers[i].handler, ...)
    if not success then
      if BookArchivist and BookArchivist.LogError then
        BookArchivist:LogError(string.format("Event handler error [%s]: %s", event, tostring(err)))
      end
    end
  end
end
```

**Refactor BookArchivist.lua:**

```lua
-- REPLACE monolithic OnEvent with dispatcher
local function initializeEventHandlers()
  local EventDispatcher = BookArchivist.EventDispatcher
  EventDispatcher:Initialize()
  
  EventDispatcher:Register("ADDON_LOADED", handleAddonLoaded, 100)
  EventDispatcher:Register("ITEM_TEXT_BEGIN", function(...)
    if Capture and Capture.OnBegin then
      Capture:OnBegin(...)
    end
  end, 0)
  EventDispatcher:Register("ITEM_TEXT_READY", function(...)
    if Capture and Capture.OnReady then
      Capture:OnReady(...)
    end
  end, 0)
  EventDispatcher:Register("ITEM_TEXT_CLOSED", function(...)
    if Capture and Capture.OnClosed then
      Capture:OnClosed(...)
    end
  end, 0)
end
```

**Action Items:**
- [ ] Create EventDispatcher module
- [ ] Refactor BookArchivist.lua to use dispatcher
- [ ] Move event registration to respective modules
- [ ] Test event handling still works correctly

### 3.2 API Surface Cleanup (4 hours)

```lua
-- Create: core/BookArchivist_PublicAPI.lua
-- EXPLICIT public API - only these are supported

local API = {}
BookArchivist.API = API

--- Get a book by ID
--- @param bookId string
--- @return table|nil book entry
function API:GetBook(bookId)
  local Core = BookArchivist._private.Core
  local db = Core:GetDB()
  return db.booksById[bookId]
end

--- Delete a book by ID
--- @param bookId string
--- @return boolean success
function API:DeleteBook(bookId)
  local Core = BookArchivist._private.Core
  Core:Delete(bookId)
  return true
end

--- Export a book to string format
--- @param bookId string
--- @return string|nil, string|nil data, error
function API:ExportBook(bookId)
  local Core = BookArchivist._private.Core
  return Core:ExportBookToString(bookId)
end

--- Get list of all book IDs
--- @return table bookIds
function API:GetAllBookIds()
  local Core = BookArchivist._private.Core
  local db = Core:GetDB()
  return db.order
end

--- Toggle favorite status
--- @param bookId string
function API:ToggleFavorite(bookId)
  local Favorites = BookArchivist._private.Favorites
  Favorites:Toggle(bookId)
end

-- Move internal modules to private namespace
BookArchivist._private = {
  Core = BookArchivist.Core,
  Capture = BookArchivist.Capture,
  Search = BookArchivist.Search,
  Favorites = BookArchivist.Favorites,
  -- etc.
}

-- Remove from public namespace
BookArchivist.Core = nil
BookArchivist.Capture = nil
BookArchivist.Search = nil
BookArchivist.Favorites = nil
```

**Action Items:**
- [ ] Create explicit public API module
- [ ] Move internals to `_private` namespace
- [ ] Document public API in README
- [ ] Add deprecation warnings for old access patterns

### 3.3 Error Boundaries (4 hours)

```lua
-- core/BookArchivist_ErrorBoundary.lua
local ErrorBoundary = {}
BookArchivist.ErrorBoundary = ErrorBoundary

local errorLog = {}
local MAX_ERROR_LOG = 100

function ErrorBoundary:Wrap(func, context)
  return function(...)
    local success, result = xpcall(func, function(err)
      return self:HandleError(err, context)
    end, ...)
    
    if success then
      return result
    else
      return nil, result -- result is error message
    end
  end
end

function ErrorBoundary:HandleError(err, context)
  local stack = debugstack(2, 10, 10)
  local errorEntry = {
    error = tostring(err),
    stack = stack,
    context = context,
    timestamp = time(),
  }
  
  table.insert(errorLog, errorEntry)
  if #errorLog > MAX_ERROR_LOG then
    table.remove(errorLog, 1)
  end
  
  -- Log to BugSack/chat
  if BookArchivist.LogError then
    BookArchivist:LogError(string.format("[%s] %s", context or "Unknown", tostring(err)))
  end
  
  return err
end

function ErrorBoundary:GetErrors()
  return errorLog
end
```

**Wrap Critical Sections:**

```lua
-- Wrap database operations
Core.PersistSession = ErrorBoundary:Wrap(Core.PersistSession, "PersistSession")

-- Wrap UI updates
ListUI.UpdateList = ErrorBoundary:Wrap(ListUI.UpdateList, "UpdateList")

-- Wrap event handlers (via dispatcher)
```

**Action Items:**
- [ ] Create ErrorBoundary module
- [ ] Wrap all public API methods
- [ ] Wrap UI refresh functions
- [ ] Add `/ba errors` command to view error log
- [ ] Test error recovery (intentionally throw errors, verify graceful handling)

### 3.4 Configuration Validation (4 hours)

```lua
-- core/BookArchivist_ConfigValidator.lua
local Validator = {}

local VALID_SORT_MODES = { title = true, zone = true, firstSeen = true, lastSeen = true }
local VALID_PAGE_SIZES = { [10] = true, [25] = true, [50] = true, [100] = true }
local VALID_LANGUAGES = { enUS = true, esES = true, caES = true, deDE = true, frFR = true, itIT = true, ptBR = true }

function Validator:ValidateOptions(options)
  options = options or {}
  
  -- Validate sort mode
  if options.list and options.list.sortMode then
    if not VALID_SORT_MODES[options.list.sortMode] then
      options.list.sortMode = "lastSeen" -- default
    end
  end
  
  -- Validate page size
  if options.list and options.list.pageSize then
    if not VALID_PAGE_SIZES[options.list.pageSize] then
      options.list.pageSize = 25 -- default
    end
  end
  
  -- Validate language
  if options.language and not VALID_LANGUAGES[options.language] then
    options.language = "enUS"
  end
  
  -- Validate boolean options
  options.debug = options.debug and true or false
  options.uiDebug = options.uiDebug and true or false
  
  return options
end

-- Call during DB initialization
function DB:Init()
  BookArchivistDB = DBSafety:SafeLoad()
  BookArchivistDB.options = Validator:ValidateOptions(BookArchivistDB.options)
  -- Continue...
end
```

**Action Items:**
- [ ] Create ConfigValidator module
- [ ] Validate options on DB load
- [ ] Add validation tests
- [ ] Document valid configuration values

### 3.5 Utilities Module (4 hours)

**Consolidate duplicated code:**

```lua
-- core/BookArchivist_Utils.lua
local Utils = {}
BookArchivist.Utils = Utils

function Utils:NormalizeKeyPart(s)
  s = self:Trim(s)
  s = s:lower()
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  s = s:gsub("%s+", " ")
  return s
end

function Utils:Trim(s)
  if not s then return "" end
  s = tostring(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

function Utils:CloneTable(src, visited)
  if type(src) ~= "table" then
    return src
  end
  
  visited = visited or {}
  if visited[src] then
    return visited[src]
  end
  
  local dst = {}
  visited[src] = dst
  
  for k, v in pairs(src) do
    dst[k] = self:CloneTable(v, visited)
  end
  
  return dst
end

function Utils:GetTimeProvider()
  local globalTime = type(_G) == "table" and rawget(_G, "time") or nil
  local osTime = type(os) == "table" and os.time or nil
  return globalTime or osTime or function() return 0 end
end

function Utils:Now()
  return self:GetTimeProvider()()
end
```

**Replace duplicated code with Utils calls.**

---

## 🧪 PHASE 4: TESTING & VALIDATION (Week 8 - 10 hours)

### 4.1 Performance Regression Tests (3 hours)

**Create test suite:**

```lua
-- dev/BookArchivist_PerformanceTests.lua
local PerfTests = {}

function PerfTests:RunAll()
  print("=== PERFORMANCE TEST SUITE ===")
  self:TestLoginTime()
  self:TestListRefresh()
  self:TestSearch()
  self:TestImport()
  print("=== TESTS COMPLETE ===")
end

function PerfTests:TestLoginTime()
  -- Measure ADDON_LOADED to UI ready
  -- Expected: <500ms for 1000 books
end

function PerfTests:TestListRefresh()
  -- Measure UpdateList with various filters
  -- Expected: <16ms (60 FPS)
end

function PerfTests:TestSearch()
  -- Measure search with 10 character query
  -- Expected: <50ms
end

function PerfTests:TestImport()
  -- Measure import of 100 books
  -- Expected: <2 seconds
end

-- Compare against PERFORMANCE_BASELINE.md
```

**Run tests and document results.**

### 4.2 Memory Leak Tests (2 hours)

```lua
function PerfTests:TestMemoryLeaks()
  collectgarbage("collect")
  local before = collectgarbage("count")
  
  -- Open/close UI 100 times
  for i = 1, 100 do
    BookArchivist.ToggleUI()
    BookArchivist.ToggleUI()
  end
  
  collectgarbage("collect")
  local after = collectgarbage("count")
  
  local leak = after - before
  print(string.format("Memory: before=%.2f KB, after=%.2f KB, leak=%.2f KB", before, after, leak))
  
  -- Expected: leak < 100 KB
end
```

### 4.3 Corruption Recovery Tests (2 hours)

**Test all corruption scenarios:**
- [ ] DB is string
- [ ] DB is number
- [ ] DB.booksById is missing
- [ ] DB.order is corrupted
- [ ] Partial corruption (some books invalid)

**Verify:**
- Backup created
- User notified
- Fresh DB initialized
- No data loss where avoidable

### 4.4 User Acceptance Testing (3 hours)

**Test with real usage patterns:**
- [ ] Import 1000 book library
- [ ] Search, filter, favorite operations
- [ ] Open/close UI repeatedly
- [ ] Login/logout cycles
- [ ] ReloadUI during operations

**Document any issues found.**

---

## 📊 SUCCESS CRITERIA

**Phase 1 Complete When:**
- [ ] No login freezes with 5000 books
- [ ] Corruption detection tested and working
- [ ] Frame pool implemented, memory flat
- [ ] No data loss scenarios

**Phase 2 Complete When:**
- [ ] List refresh <16ms (60 FPS) for 1000 books
- [ ] Search <50ms for any query
- [ ] Cache hit rate >80%
- [ ] Memory usage stable

**Phase 3 Complete When:**
- [ ] Public API documented
- [ ] Error boundaries catch all errors
- [ ] Event system modular
- [ ] Code duplication eliminated

**Phase 4 Complete When:**
- [ ] All performance tests pass
- [ ] No memory leaks detected
- [ ] Corruption recovery tested
- [ ] User acceptance testing complete

---

## 🚫 ANTI-PATTERNS TO AVOID

### Don't Do This:

**1. "I'll just add this one feature while I'm here"**
- NO. Finish the refactoring first.

**2. "This optimization is probably fine, I don't need to profile"**
- NO. Profile everything. Prove your changes work.

**3. "I'll write tests later"**
- NO. Write test cases as you go.

**4. "Users won't have 5000 books"**
- YES THEY WILL. Plan for it.

**5. "I'll document this after it works"**
- NO. Document as you write.

---

## 📝 DAILY WORKFLOW

**Every coding session:**
1. Git pull latest changes
2. Run `/bagentest 1000` to load test data
3. Run `/ba profile` before changes (baseline)
4. Make changes
5. Run `/ba profile` after changes (measure)
6. Run performance tests
7. Commit with descriptive message
8. Document what you learned

**Before pushing:**
- [ ] All tests pass
- [ ] No console errors
- [ ] Memory usage checked
- [ ] CHANGELOG updated

---

## 🎓 LEARNING RESOURCES

**If you get stuck on:**

**Frame Pooling:**
- Study Blizzard's ScrollBox implementation
- Look at TellMeWhen's row pooling

**Performance Profiling:**
- Use `/run local start = debugprofilestop(); YourFunction(); print(debugprofilestop() - start)`
- Study memory with `/run collectgarbage("count")`

**Table Iteration:**
- Never use `pairs()` for large tables without throttling
- Use `ipairs()` for ordered iteration
- Pre-sort keys into array for deterministic behavior

---

## 🏁 FINAL CHECKLIST

**Before declaring DONE:**

- [ ] All phases complete
- [ ] All success criteria met
- [ ] Performance baselines exceeded
- [ ] No known memory leaks
- [ ] No data loss scenarios
- [ ] Public API documented
- [ ] Code review by peer (if possible)
- [ ] Backup/recovery tested
- [ ] User migration plan ready
- [ ] Release notes written

---

## 💀 BRUTAL TRUTH

If you don't complete Phase 1, **your addon will fail catastrophically** as more users adopt it and their libraries grow.

If you skip Phase 2, **users will complain about lag** and switch to alternatives.

If you ignore Phase 3, **you won't be able to maintain your own code** in 6 months.

If you don't test (Phase 4), **you'll release broken code** and lose user trust.

**This is 60-80 hours of work. There are no shortcuts.**

Either commit to doing it right, or accept that your addon will always be "good enough but fragile."

**Your choice.**

---

**Questions? Get answers BEFORE you start coding.**
