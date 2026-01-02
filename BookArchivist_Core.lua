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

local function makeKey(title, author, creator, material, firstPageText)
  local t = normalizeKeyPart(title)
  local a = normalizeKeyPart(author ~= "" and author or creator)
  local m = normalizeKeyPart(material)
  local fp = normalizeKeyPart(firstPageText):sub(1, 80)
  return table.concat({t, a, m, fp}, "||")
end

local function ensureDB()
  if not BookArchivistDB or type(BookArchivistDB) ~= "table" then
    BookArchivistDB = {
      version = 1,
      createdAt = now(),
      books = {},
      order = {},
      options = {},
    }
  end
  BookArchivistDB.books = BookArchivistDB.books or {}
  BookArchivistDB.order = BookArchivistDB.order or {}
  BookArchivistDB.options = BookArchivistDB.options or {}
  if BookArchivistDB.options.debugEnabled == nil then
    BookArchivistDB.options.debugEnabled = false
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
  return BookArchivistDB
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
  if not db.books[key] then return end
  db.books[key] = nil
  removeFromOrder(db.order, key)
end

function Core:GetOptions()
  local db = ensureDB()
  db.options = db.options or {}
  if db.options.debugEnabled == nil then
    db.options.debugEnabled = false
  end
  return db.options
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

function Core:PersistSession(session)
  if not session then return end
  ensureDB()

  local pages = session.pages or {}
  local firstText = pages[1] or pages[session.firstPageSeen or 1] or ""
  local key = makeKey(session.title, session.author, session.creator, session.material, firstText)
  local entry = BookArchivistDB.books[key]
  local capturedAt = now()

  if not entry then
    entry = {
      key = key,
      title = session.title,
      creator = session.creator,
      author = session.author,
      material = session.material,
      createdAt = capturedAt,
      firstSeenAt = session.startedAt or capturedAt,
      lastSeenAt = capturedAt,
      seenCount = 1,
      source = session.source,
      pages = {},
      location = cloneTable(session.location),
    }
    BookArchivistDB.books[key] = entry
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
  entry.author = entry.author ~= "" and entry.author or session.author
  entry.material = entry.material ~= "" and entry.material or session.material
  entry.source = entry.source or session.source
  if session.location then
    entry.location = cloneTable(session.location)
  end

  self:TouchOrder(key)
  return entry
end

function Core:InjectEntry(entry, opts)
  if not entry or not entry.key then return end
  opts = opts or {}
  ensureDB()
  BookArchivistDB.books[entry.key] = entry
  entry.pages = entry.pages or {}

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
