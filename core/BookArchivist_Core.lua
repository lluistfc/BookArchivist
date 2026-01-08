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
local CRC32 = BookArchivist.CRC32

-- BDB1 envelope decode and export helpers now live in
-- core/BookArchivist_Export.lua.

local LIST_WIDTH_DEFAULT = 360

local SUPPORTED_LANGUAGES = {
  enUS = true,
  esES = true,
  caES = true,
  deDE = true,
  frFR = true,
  itIT = true,
  ptBR = true,
}

local pruneLegacyAuthor

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
  if BookArchivistDB.options.debug == nil then
	BookArchivistDB.options.debug = false
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
    if type(entry) == "table" and entry.searchText == nil and Core.BuildSearchText then
      entry.searchText = Core:BuildSearchText(entry.title, entry.pages)
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

function Core:GetLanguage()
  local db = ensureDB()
  db.options = db.options or {}
  local opts = db.options
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

local function getListConfig()
  return BookArchivist and BookArchivist.ListConfig or nil
end

function Core:GetSortMode()
  local cfg = getListConfig()
  if cfg and cfg.GetSortMode then
    return cfg:GetSortMode()
  end

  local db = ensureDB()
  db.options = db.options or {}
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  if type(listOpts.sortMode) ~= "string" or listOpts.sortMode == "" then
    listOpts.sortMode = "lastSeen"
  end
  return listOpts.sortMode
end

function Core:SetSortMode(mode)
  local cfg = getListConfig()
  if cfg and cfg.SetSortMode then
    return cfg:SetSortMode(mode)
  end

  local db = ensureDB()
  db.options = db.options or {}
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  if type(mode) ~= "string" or mode == "" then
    mode = "lastSeen"
  end
  listOpts.sortMode = mode
end

function Core:GetListFilters()
  local cfg = getListConfig()
  if cfg and cfg.GetListFilters then
    return cfg:GetListFilters()
  end

  local db = ensureDB()
  db.options = db.options or {}
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  listOpts.filters = listOpts.filters or {}
  return listOpts.filters
end

function Core:SetListFilter(filterKey, state)
  if not filterKey then
    return
  end
  local cfg = getListConfig()
  local filters
  if cfg and cfg.SetListFilter then
    filters = cfg:SetListFilter(filterKey, state)
  else
    local db = ensureDB()
    db.options = db.options or {}
    db.options.list = db.options.list or {}
    local listOpts = db.options.list
    listOpts.filters = listOpts.filters or {}
    if listOpts.filters[filterKey] == nil then
      return
    end
    listOpts.filters[filterKey] = state and true or false
    filters = listOpts.filters
  end

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

function Core:GetListPageSize()
  local cfg = getListConfig()
  if cfg and cfg.GetListPageSize then
    return cfg:GetListPageSize()
  end

  local db = ensureDB()
  db.options = db.options or {}
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  if type(listOpts.pageSize) ~= "number" then
    listOpts.pageSize = 25
  end
  return listOpts.pageSize
end

function Core:SetListPageSize(size)
  local cfg = getListConfig()
  if cfg and cfg.SetListPageSize then
    return cfg:SetListPageSize(size)
  end

  local db = ensureDB()
  db.options = db.options or {}
  db.options.list = db.options.list or {}
  local listOpts = db.options.list
  listOpts.pageSize = tonumber(size) or 25
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

function Core:BuildExportPayloadForBook(bookId)
  if not bookId or bookId == "" then
    return nil, "invalid book ID"
  end
  
  local db = ensureDB()
  if not (db.booksById and db.booksById[bookId]) then
    return nil, "book not found"
  end
  
  local name, realm
  if type(UnitName) == "function" then
    name = UnitName("player")
  end
  if type(GetRealmName) == "function" then
    realm = GetRealmName()
  end
  
  -- Export only the selected book
  local singleBookTable = {}
  singleBookTable[bookId] = db.booksById[bookId]
  
  return {
    schemaVersion = 1,
    exportedAt = now(),
    character = {
      name = name or "?",
      realm = realm or "?",
    },
    booksById = singleBookTable,
    order = { bookId },
  }
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

  if Core.BuildSearchText then
    entry.searchText = Core:BuildSearchText(entry.title, entry.pages)
  end
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
  if Core.BuildSearchText then
    entry.searchText = entry.searchText or Core:BuildSearchText(entry.title, entry.pages)
  end

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

function Core:IsDebugEnabled()
  local db = ensureDB()
  return db.options.debug and true or false
end

function Core:SetDebugEnabled(state)
  local db = ensureDB()
  db.options.debug = state and true or false
end

function Core:IsUIDebugEnabled()
  local db = ensureDB()
  return db.options.uiDebug and true or false
end

function Core:SetUIDebugEnabled(state)
  local db = ensureDB()
  db.options.uiDebug = state and true or false
end
