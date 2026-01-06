---@diagnostic disable: undefined-global
-- BookArchivist_Core.lua
-- Shared data helpers, persistence, and SavedVariables management.

BookArchivist = BookArchivist or {}
BookArchivistDB = BookArchivistDB or nil

local globalTime = type(_G) == "table" and rawget(_G, "time") or nil
local osTime = type(os) == "table" and os.time or nil
local timeProvider = globalTime or osTime or function()
  return 0
end

local Core = {}
BookArchivist.Core = Core

local BookId = BookArchivist.BookId
local Serialize = BookArchivist.Serialize
local Base64 = BookArchivist.Base64

local LIST_WIDTH_DEFAULT = 360
local LIST_SORT_DEFAULT = "lastSeen"
local LIST_PAGE_SIZE_DEFAULT = 25
local LIST_PAGE_SIZES = {
  [10] = true,
  [25] = true,
  [50] = true,
  [100] = true,
}
local LIST_FILTER_DEFAULTS = {
  hasLocation = false,
  multiPage = false,
  unread = false,
  favoritesOnly = false,
}

local VALID_SORT_MODES = {
  title = true,
  zone = true,
  firstSeen = true,
  lastSeen = true,
}

local SUPPORTED_LANGUAGES = {
  enUS = true,
  esES = true,
  caES = true,
  deDE = true,
  frFR = true,
  itIT = true,
  ptBR = true,
}

local function normalizeLanguageTag(tag)
  tag = tostring(tag or "")
  if SUPPORTED_LANGUAGES[tag] then
    return tag
  end
  if tag == "esMX" then
    return "esES"
  elseif tag == "ptPT" then
    return "ptBR"
  end
  return "enUS"
end

local pruneLegacyAuthor

local function now()
  return timeProvider()
end

local function trim(s)
  if not s then return "" end
  s = tostring(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

local function safeLower(s)
  s = trim(s)
  return s:lower()
end

local function normalizeKeyPart(s)
  s = safeLower(s)
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  s = s:gsub("%s+", " ")
  return s
end

-- Step 6 – Search Optimization
-- Normalize free-text fields for search and build a cached searchText
-- blob per entry so we don't have to concatenate title/pages on every
-- query. We intentionally include the full pages set for best match
-- completeness.

local function normalizeSearchText(text)
  text = tostring(text or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub("%s+", " ")
  return text:lower()
end

local function buildSearchText(title, pages)
  local out = normalizeSearchText(title or "")
  if type(pages) == "table" then
    local first = (out ~= "") and ("\n" .. out) or ""
    -- Preserve deterministic output by iterating page numbers in
    -- ascending order when possible.
    local indices = {}
    for pageNum in pairs(pages) do
      if type(pageNum) == "number" then
        table.insert(indices, pageNum)
      end
    end
    table.sort(indices)
    if #indices == 0 then
      -- Fallback to generic pairs order when pages are keyed
      -- unusually; this keeps search behavior correct even if
      -- ordering is undefined.
      for _, text in pairs(pages) do
        local norm = normalizeSearchText(text)
        if norm ~= "" then
          if out ~= "" then
            out = out .. "\n" .. norm
          else
            out = norm
          end
        end
      end
    else
      for _, pageNum in ipairs(indices) do
        local norm = normalizeSearchText(pages[pageNum])
        if norm ~= "" then
          if out ~= "" then
            out = out .. "\n" .. norm
          else
            out = norm
          end
        end
      end
    end
  end
  return out
end

local function cloneTable(value)
  if type(value) ~= "table" then
    return value
  end
  local copy = {}
  for k, v in pairs(value) do
    copy[k] = cloneTable(v)
  end
  return copy
end

local function makeKey(title, creator, material, firstPageText)
  local t = normalizeKeyPart(title)
  local c = normalizeKeyPart(creator)
  local m = normalizeKeyPart(material)
  local fp = normalizeKeyPart(firstPageText):sub(1, 80)
  return table.concat({t, c, m, fp}, "||")
end

local function ensureDB()
	-- Always resolve the DB module at call time so load order
	-- issues don't prevent migrations from running.
	local DBModule = BookArchivist.DB
  if DBModule and type(DBModule.Init) == "function" then
    DBModule:Init()
  elseif not BookArchivistDB or type(BookArchivistDB) ~= "table" then
    BookArchivistDB = {
      version = 1,
      createdAt = now(),
      order = {},
      options = {},
      booksById = {},
      indexes = {
        objectToBookId = {},
      },
    }
  end
  BookArchivistDB.booksById = BookArchivistDB.booksById or {}
  BookArchivistDB.order = BookArchivistDB.order or {}
  BookArchivistDB.options = BookArchivistDB.options or {}
  if BookArchivistDB.options.debugEnabled == nil then
	BookArchivistDB.options.debugEnabled = false
  end
  if BookArchivistDB.options.uiDebug == nil then
    BookArchivistDB.options.uiDebug = false
  end
  if type(BookArchivistDB.options.language) ~= "string" or BookArchivistDB.options.language == "" then
    local gameLocale = (type(GetLocale) == "function" and GetLocale()) or "enUS"
    BookArchivistDB.options.language = normalizeLanguageTag(gameLocale)
  end
  BookArchivistDB.options.tooltip = BookArchivistDB.options.tooltip or { enabled = true }
  BookArchivistDB.options.ui = BookArchivistDB.options.ui or {}
  local uiOpts = BookArchivistDB.options.ui
  if type(uiOpts.listWidth) ~= "number" then
    uiOpts.listWidth = LIST_WIDTH_DEFAULT
  end
  if uiOpts.virtualCategoriesEnabled == nil then
    uiOpts.virtualCategoriesEnabled = true
  end

  BookArchivistDB.options.list = BookArchivistDB.options.list or {}
  local listOpts = BookArchivistDB.options.list
  if type(listOpts.sortMode) ~= "string" then
    listOpts.sortMode = LIST_SORT_DEFAULT
  end
  listOpts.filters = listOpts.filters or {}
  for key, defaultValue in pairs(LIST_FILTER_DEFAULTS) do
    if listOpts.filters[key] == nil then
      listOpts.filters[key] = defaultValue
    end
  end

  -- Recently read (Step 4): ensure per-character MRU container exists.
  BookArchivistDB.recent = BookArchivistDB.recent or {}
  local recent = BookArchivistDB.recent
  if type(recent.cap) ~= "number" or recent.cap <= 0 then
    recent.cap = 50
  end
  recent.list = recent.list or {}

  BookArchivistDB.indexes = BookArchivistDB.indexes or {}
  BookArchivistDB.indexes.objectToBookId = BookArchivistDB.indexes.objectToBookId or {}
  BookArchivistDB.indexes.itemToBookIds = BookArchivistDB.indexes.itemToBookIds or {}
  BookArchivistDB.indexes.titleToBookIds = BookArchivistDB.indexes.titleToBookIds or {}
  if not BookArchivistDB.indexes._titleIndexBackfilled then
    local titleIndex = BookArchivistDB.indexes.titleToBookIds
    for bookId, entry in pairs(BookArchivistDB.booksById or {}) do
      if type(entry) == "table" and entry.title and entry.title ~= "" then
        local key = normalizeKeyPart(entry.title)
        if key ~= "" then
          titleIndex[key] = titleIndex[key] or {}
          titleIndex[key][bookId] = true
        end
      end
    end
    BookArchivistDB.indexes._titleIndexBackfilled = true
  end

  local minimapDefaults = {
    angle = 200,
  }
  local minimap = BookArchivistDB.options.minimapButton
  if type(minimap) ~= "table" then
    minimap = {}
    BookArchivistDB.options.minimapButton = minimap
  end
  if type(minimap.angle) ~= "number" then
    minimap.angle = minimapDefaults.angle
  end

  -- Favorites & virtual categories (Step 3): backfill default
  -- flags on existing entries and ensure ui options table exists.
  for bookId, entry in pairs(BookArchivistDB.booksById or {}) do
    if type(entry) == "table" and entry.isFavorite == nil then
      entry.isFavorite = false
    end
  end

	-- Step 6 – backfill searchText so existing entries can use the
	-- optimized search path without changing user-visible results.
	for bookId, entry in pairs(BookArchivistDB.booksById or {}) do
		if type(entry) == "table" and entry.searchText == nil then
			entry.searchText = buildSearchText(entry.title, entry.pages)
		end
	end

  -- Step 7 – UI state container (per-character, non-breaking).
  BookArchivistDB.uiState = BookArchivistDB.uiState or {}
  local uiState = BookArchivistDB.uiState
  if type(uiState.lastCategoryId) ~= "string" or uiState.lastCategoryId == "" then
    uiState.lastCategoryId = "__all__"
  end
  -- Defensive: drop a stale lastBookId reference if the entry no
  -- longer exists in the current booksById map.
  if uiState.lastBookId and not BookArchivistDB.booksById[uiState.lastBookId] then
    uiState.lastBookId = nil
  end

  pruneLegacyAuthor(BookArchivistDB)
  return BookArchivistDB
end

local function ensureUIOptions()
  local db = ensureDB()
  db.options.ui = db.options.ui or {}
  local uiOpts = db.options.ui
  if type(uiOpts.listWidth) ~= "number" then
    uiOpts.listWidth = LIST_WIDTH_DEFAULT
  end
  if uiOpts.virtualCategoriesEnabled == nil then
    uiOpts.virtualCategoriesEnabled = true
  end
  if uiOpts.resumeLastPage == nil then
    uiOpts.resumeLastPage = true
  end
  return uiOpts
end

local function ensureListOptions()
  local db = ensureDB()
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  if type(listOpts.sortMode) ~= "string" then
    listOpts.sortMode = LIST_SORT_DEFAULT
  end
  if type(listOpts.pageSize) ~= "number" or not LIST_PAGE_SIZES[listOpts.pageSize] then
    listOpts.pageSize = LIST_PAGE_SIZE_DEFAULT
  end
  listOpts.filters = listOpts.filters or {}
  for key, defaultValue in pairs(LIST_FILTER_DEFAULTS) do
    if listOpts.filters[key] == nil then
      listOpts.filters[key] = defaultValue
    end
  end
  listOpts.filters.hasAuthor = nil
  return listOpts
end

pruneLegacyAuthor = function(db)
  if not db then
    return
  end
  db.migrations = db.migrations or {}
  if db.migrations.authorPruned then
    return
  end
  if db.books then
    for _, entry in pairs(db.books) do
      if type(entry) == "table" then
        entry.author = nil
      end
    end
  end
  if db.options and db.options.list and db.options.list.filters then
    db.options.list.filters.hasAuthor = nil
  end
  db.migrations.authorPruned = true
end

local function removeFromOrder(order, key)
  if not key then return end
  for i = #order, 1, -1 do
    if order[i] == key then
      table.remove(order, i)
      return
    end
  end
end

function Core:EnsureDB()
  return ensureDB()
end

function Core:GetDB()
  return ensureDB()
end

function Core:TouchOrder(key)
  if not key then return end
  local db = ensureDB()
  local order = db.order
  removeFromOrder(order, key)
  table.insert(order, 1, key)
end

function Core:AppendOrder(key)
  if not key then return end
  local db = ensureDB()
  local order = db.order
  removeFromOrder(order, key)
  table.insert(order, key)
end

function Core:Delete(key)
  if not key then return end
  local db = ensureDB()
  if db.booksById and not db.booksById[key] then return end
	if db.booksById then
		db.booksById[key] = nil
	end
  removeFromOrder(db.order, key)
  if db.recent and type(db.recent.list) == "table" then
    removeFromOrder(db.recent.list, key)
  end
  -- Clear resume pointer if it referenced the deleted entry.
  if db.uiState and db.uiState.lastBookId == key then
    db.uiState.lastBookId = nil
  end
end

function Core:GetOptions()
  local db = ensureDB()
  db.options = db.options or {}
  if db.options.debugEnabled == nil then
	db.options.debugEnabled = false
  end
  return db.options
end

function Core:GetLanguage()
  local opts = self:GetOptions()
  if type(opts.language) ~= "string" or opts.language == "" then
    local gameLocale = (type(GetLocale) == "function" and GetLocale()) or "enUS"
    opts.language = normalizeLanguageTag(gameLocale)
  end
  return normalizeLanguageTag(opts.language)
end

function Core:SetLanguage(lang)
  local opts = self:GetOptions()
  opts.language = normalizeLanguageTag(lang)
end

function Core:GetMinimapButtonOptions()
  local opts = self:GetOptions()
  opts.minimapButton = opts.minimapButton or {}
  if type(opts.minimapButton.angle) ~= "number" then
    opts.minimapButton.angle = 200
  end
  return opts.minimapButton
end

function Core:IsDebugEnabled()
  local opts = self:GetOptions()
  return opts.debugEnabled and true or false
end

function Core:SetDebugEnabled(state)
  local opts = self:GetOptions()
  opts.debugEnabled = state and true or false
end

function Core:IsTooltipEnabled()
  local opts = self:GetOptions()
  local tooltipOpts = opts.tooltip
  if tooltipOpts == nil then
    return true
  end
  if type(tooltipOpts) == "table" then
    if tooltipOpts.enabled == nil then
      tooltipOpts.enabled = true
    end
    return tooltipOpts.enabled and true or false
  end
  if type(tooltipOpts) == "boolean" then
    return tooltipOpts and true or false
  end
  return true
end

function Core:SetTooltipEnabled(state)
  local opts = self:GetOptions()
  opts.tooltip = opts.tooltip or {}
  if type(opts.tooltip) ~= "table" then
    opts.tooltip = { enabled = state and true or false }
  else
    opts.tooltip.enabled = state and true or false
  end
end

function Core:IsUIDebugEnabled()
  local opts = self:GetOptions()
  return opts.uiDebug and true or false
end

function Core:SetUIDebugEnabled(state)
  local opts = self:GetOptions()
  opts.uiDebug = state and true or false
end

function Core:GetUIFrameOptions()
  return ensureUIOptions()
end

function Core:GetListWidth()
  local uiOpts = ensureUIOptions()
  return uiOpts.listWidth or LIST_WIDTH_DEFAULT
end

function Core:SetListWidth(width)
  local uiOpts = ensureUIOptions()
  if type(width) == "number" then
    uiOpts.listWidth = math.max(260, math.min(math.floor(width + 0.5), 600))
  end
end

function Core:IsVirtualCategoriesEnabled()
  local uiOpts = ensureUIOptions()
  if uiOpts.virtualCategoriesEnabled == nil then
    uiOpts.virtualCategoriesEnabled = true
  end
  return uiOpts.virtualCategoriesEnabled and true or false
end

function Core:IsResumeLastPageEnabled()
  local uiOpts = ensureUIOptions()
  if uiOpts.resumeLastPage == nil then
    uiOpts.resumeLastPage = true
  end
  return uiOpts.resumeLastPage and true or false
end

function Core:SetResumeLastPageEnabled(state)
  local uiOpts = ensureUIOptions()
  uiOpts.resumeLastPage = state and true or false
end

function Core:GetSortMode()
  local listOpts = ensureListOptions()
  local mode = listOpts.sortMode or LIST_SORT_DEFAULT
  if not VALID_SORT_MODES[mode] then
    -- Gracefully remap the legacy "recent" sort mode (which used the
    -- capture order) to the new default instead of leaving an invalid
    -- value in SavedVariables.
    if mode == "recent" then
      mode = LIST_SORT_DEFAULT
    end
    if not VALID_SORT_MODES[mode] then
      mode = LIST_SORT_DEFAULT
    end
    listOpts.sortMode = mode
  end
  return mode
end

function Core:SetSortMode(mode)
  local listOpts = ensureListOptions()
  if type(mode) ~= "string" or not VALID_SORT_MODES[mode] then
    mode = LIST_SORT_DEFAULT
  end
  listOpts.sortMode = mode
end

function Core:GetListFilters()
  local listOpts = ensureListOptions()
  return listOpts.filters
end

function Core:SetListFilter(filterKey, state)
  if not filterKey then
    return
  end
  local listOpts = ensureListOptions()
  if listOpts.filters[filterKey] == nil then
    return
  end
  listOpts.filters[filterKey] = state and true or false

  -- Keep virtual category state in sync with the favorites-only
  -- filter so category-aware UIs can treat it as a view selector.
  if filterKey == "favoritesOnly" then
    if state then
      self:SetLastCategoryId("__favorites__")
    else
      self:SetLastCategoryId("__all__")
    end
  end
end

local function normalizePageSize(size)
  size = tonumber(size)
  if LIST_PAGE_SIZES[size] then
    return size
  end
  return LIST_PAGE_SIZE_DEFAULT
end

function Core:GetListPageSize()
  local listOpts = ensureListOptions()
  listOpts.pageSize = normalizePageSize(listOpts.pageSize)
  return listOpts.pageSize
end

function Core:SetListPageSize(size)
  local listOpts = ensureListOptions()
  listOpts.pageSize = normalizePageSize(size)
end

-- Step 8 – Export / Import helpers

function Core:BuildExportPayload()
  local db = ensureDB()
  local name, realm
  if type(UnitName) == "function" then
    name = UnitName("player")
  end
  if type(GetRealmName) == "function" then
    realm = GetRealmName()
  end
  return {
    schemaVersion = 1,
    exportedAt = now(),
    character = {
      name = name or "?",
      realm = realm or "?",
    },
    booksById = db.booksById or {},
    order = db.order or {},
  }
end

function Core:ExportToString()
  if not (Serialize and Serialize.SerializeTable) then
    return nil, "serializer unavailable"
  end
  if not (Base64 and Base64.Encode) then
    return nil, "base64 encoder unavailable"
  end
  local payload = self:BuildExportPayload()
  local serialized, err = Serialize.SerializeTable(payload)
  if not serialized then
    return nil, err or "serialization failed"
  end
  local encoded = Base64.Encode(serialized)
  return encoded, nil
end

local function ensureImportedEntryDerivedFields(entry)
  if not entry then return end
  if entry.isFavorite == nil then
    entry.isFavorite = false
  else
    entry.isFavorite = entry.isFavorite and true or false
  end
  entry.searchText = buildSearchText(entry.title, entry.pages)
end

local function mergeImportedEntry(self, existing, incoming, bookId)
  if not incoming or type(incoming) ~= "table" then
    return false
  end
  if not existing then
    return false
  end

  if type(incoming.seenCount) == "number" then
    existing.seenCount = (existing.seenCount or 0) + incoming.seenCount
  end
  if type(incoming.firstSeenAt) == "number" then
    if not existing.firstSeenAt or incoming.firstSeenAt < existing.firstSeenAt then
      existing.firstSeenAt = incoming.firstSeenAt
    end
  end
  if type(incoming.lastSeenAt) == "number" then
    if not existing.lastSeenAt or incoming.lastSeenAt > existing.lastSeenAt then
      existing.lastSeenAt = incoming.lastSeenAt
    end
  end
  if type(incoming.lastReadAt) == "number" then
    if not existing.lastReadAt or incoming.lastReadAt > existing.lastReadAt then
      existing.lastReadAt = incoming.lastReadAt
    end
  end
  if incoming.isFavorite then
    existing.isFavorite = true
  end

  if incoming.title and incoming.title ~= "" then
    if not existing.title or existing.title == "" then
      existing.title = incoming.title
    elseif existing.title ~= incoming.title then
      existing.legacy = existing.legacy or {}
      existing.legacy.importConflict = true
    end
  end

  if type(incoming.pages) == "table" then
    existing.pages = existing.pages or {}
    for pageNum, text in pairs(incoming.pages) do
      if existing.pages[pageNum] == nil then
        existing.pages[pageNum] = text
      elseif text and text ~= "" and existing.pages[pageNum] ~= text then
        existing.legacy = existing.legacy or {}
        existing.legacy.importConflict = true
      end
    end
  end

  ensureImportedEntryDerivedFields(existing)
  if self and self.IndexTitleForBook then
    self:IndexTitleForBook(existing.title or incoming.title, bookId)
  end
  return true
end

function Core:ImportFromString(encoded, opts)
  opts = opts or {}
  local dryRun = opts.dry and true or false
  if type(encoded) ~= "string" or encoded == "" then
    return nil, "empty payload"
  end
  if not (Serialize and Serialize.DeserializeTable) then
    return nil, "serializer unavailable"
  end
  if not (Base64 and Base64.Decode) then
    return nil, "base64 decoder unavailable"
  end

  local decoded, derr = Base64.Decode(encoded)
  if not decoded then
    return nil, derr or "base64 decode failed"
  end
  local payload, perr = Serialize.DeserializeTable(decoded)
  if not payload then
    return nil, perr or "deserialize failed"
  end
  if type(payload) ~= "table" then
    return nil, "payload must be a table"
  end
  if payload.schemaVersion ~= 1 then
    return nil, "unsupported schemaVersion"
  end
  if type(payload.booksById) ~= "table" then
    return nil, "payload missing booksById"
  end

  local db = ensureDB()
  db.booksById = db.booksById or {}
  db.order = db.order or {}

  local targetBooks = db.booksById
  local targetOrder = db.order
  if dryRun then
    targetBooks = cloneTable(targetBooks)
    local copyOrder = {}
    for i, id in ipairs(db.order) do
      copyOrder[i] = id
    end
    targetOrder = copyOrder
  end

  local orderSet = {}
  for _, id in ipairs(targetOrder) do
    orderSet[id] = true
  end

  local newCount, mergedCount = 0, 0

  for bookId, inEntry in pairs(payload.booksById) do
    if type(bookId) == "string" and type(inEntry) == "table" then
      local existing = targetBooks[bookId]
      if not existing then
        local cloned = cloneTable(inEntry)
        ensureImportedEntryDerivedFields(cloned)
        targetBooks[bookId] = cloned
        if (not dryRun) and self and self.IndexTitleForBook then
          self:IndexTitleForBook(cloned.title, bookId)
        end
        newCount = newCount + 1
      else
        if mergeImportedEntry(self, existing, inEntry, bookId) then
          mergedCount = mergedCount + 1
        end
      end
      if not orderSet[bookId] then
        table.insert(targetOrder, bookId)
        orderSet[bookId] = true
      end
    end
  end

  -- Let the Recent module sanitize its MRU list after new keys.
  if (not dryRun) and BookArchivist and BookArchivist.Recent and BookArchivist.Recent.GetList then
    pcall(BookArchivist.Recent.GetList, BookArchivist.Recent)
  end

  return { new = newCount, merged = mergedCount }, nil
end

function Core:GetLastBookId()
  local db = ensureDB()
  db.uiState = db.uiState or {}
  local id = db.uiState.lastBookId
  if type(id) ~= "string" or id == "" then
    return nil
  end
  if not (db.booksById and db.booksById[id]) then
    db.uiState.lastBookId = nil
    return nil
  end
  return id
end

function Core:SetLastBookId(bookId)
  local db = ensureDB()
  db.uiState = db.uiState or {}
  if type(bookId) ~= "string" or bookId == "" then
    db.uiState.lastBookId = nil
    return
  end
  if db.booksById and db.booksById[bookId] then
    db.uiState.lastBookId = bookId
  else
    db.uiState.lastBookId = nil
  end
end

function Core:GetLastCategoryId()
  local db = ensureDB()
  db.uiState = db.uiState or {}
  local id = db.uiState.lastCategoryId
  if type(id) ~= "string" or id == "" then
    id = "__all__"
    db.uiState.lastCategoryId = id
  end
  return id
end

function Core:SetLastCategoryId(categoryId)
  local db = ensureDB()
  db.uiState = db.uiState or {}
  local id = (type(categoryId) == "string" and categoryId ~= "") and categoryId or "__all__"
  db.uiState.lastCategoryId = id

  -- Mirror category choice into the favorites-only list filter so the
  -- list builder can continue to rely on filters for actual selection.
  local listOpts = ensureListOptions()
  listOpts.filters = listOpts.filters or {}
  if id == "__favorites__" then
    listOpts.filters.favoritesOnly = true
  else
    listOpts.filters.favoritesOnly = false
  end
end

function Core:PersistSession(session)
  if not session then return end
  local db = ensureDB()

  local pages = session.pages or {}
  local firstText = pages[1] or pages[session.firstPageSeen or 1] or ""
  local bookId
  if BookId and type(BookId.MakeBookIdV2) == "function" then
    bookId = BookId.MakeBookIdV2({
      title = session.title,
      pages = pages,
      source = session.source,
    })
  end
  bookId = bookId or makeKey(session.title, session.creator, session.material, firstText)

  db.booksById = db.booksById or {}
  local entry = db.booksById[bookId]
  local capturedAt = now()

  if not entry then
    entry = {
	  id = bookId,
	  key = bookId,
      title = session.title,
      creator = session.creator,
      material = session.material,
      createdAt = capturedAt,
      firstSeenAt = session.startedAt or capturedAt,
      lastSeenAt = capturedAt,
      seenCount = 1,
      source = session.source,
      pages = {},
      location = cloneTable(session.location),
    }
  	db.booksById[bookId] = entry
  else
    entry.lastSeenAt = capturedAt
    entry.seenCount = (entry.seenCount or 0) + 1
    entry.firstSeenAt = entry.firstSeenAt or session.startedAt or capturedAt
  end

  entry.pages = entry.pages or {}
  for pageNum, text in pairs(pages) do
    if text and text ~= "" then
      entry.pages[pageNum] = text
    end
  end

  entry.title = entry.title ~= "" and entry.title or session.title
  entry.creator = entry.creator ~= "" and entry.creator or session.creator
  entry.material = entry.material ~= "" and entry.material or session.material
  entry.source = entry.source or session.source
  if session.location then
    entry.location = cloneTable(session.location)
  end

	entry.searchText = buildSearchText(entry.title, entry.pages)
	self:IndexTitleForBook(entry.title or session.title, bookId)
	self:TouchOrder(bookId)
  return entry
end

function Core:IndexItemForBook(itemID, bookId)
  if not itemID or not bookId then
    return
  end
  local db = ensureDB()
  db.indexes = db.indexes or {}
  db.indexes.itemToBookIds = db.indexes.itemToBookIds or {}
  local map = db.indexes.itemToBookIds
  local id = tonumber(itemID) or itemID
  if not id then
    return
  end
  map[id] = map[id] or {}
  map[id][bookId] = true
end

function Core:IndexObjectForBook(objectID, bookId)
  if not objectID or not bookId then
    return
  end
  local db = ensureDB()
  db.indexes = db.indexes or {}
  db.indexes.objectToBookId = db.indexes.objectToBookId or {}
  local index = db.indexes.objectToBookId
  local id = tonumber(objectID) or objectID
  if not id then
    return
  end
  index[id] = bookId
end

function Core:IndexTitleForBook(title, bookId)
  if not title or title == "" or not bookId then
    return
  end
  local db = ensureDB()
  db.indexes = db.indexes or {}
  db.indexes.titleToBookIds = db.indexes.titleToBookIds or {}
  local key = normalizeKeyPart(title)
  if key == "" then
    return
  end
  local map = db.indexes.titleToBookIds
  map[key] = map[key] or {}
  map[key][bookId] = true
end

function Core:InjectEntry(entry, opts)
  if not entry or not entry.key then return end
  opts = opts or {}
  ensureDB()
	local db = BookArchivistDB
	db.booksById = db.booksById or {}
	db.booksById[entry.key] = entry
  entry.pages = entry.pages or {}
	entry.searchText = entry.searchText or buildSearchText(entry.title, entry.pages)

  if opts.append then
    self:AppendOrder(entry.key)
  else
    self:TouchOrder(entry.key)
  end
end

function Core:Now()
  return now()
end

function Core:Trim(text)
  return trim(text)
end
