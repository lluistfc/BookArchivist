---@diagnostic disable: undefined-global
-- BookArchivist_DB.lua
-- DB initialization entrypoint that wires in migrations.

BookArchivist = BookArchivist or {}
BookArchivistDB = BookArchivistDB or nil

local DB = BookArchivist.DB or {}
BookArchivist.DB = DB

local Migrations = BookArchivist.Migrations

-- Only log the init summary once per session to avoid spam when
-- ensureDB()/GetDB() are called many times during UI refresh.
local hasLoggedInitSummary = false

local function debug(msg)
  local BA = BookArchivist
  if BA and type(BA.DebugPrint) == "function" then
    BA:DebugPrint("[DB] " .. tostring(msg))
  end
end

local function getTime()
  local globalTime = type(_G) == "table" and rawget(_G, "time") or nil
  local osTime = type(os) == "table" and os.time or nil
  local provider = globalTime or osTime or function()
    return 0
  end
  return provider()
end

function DB:Init()
  -- We still want to see at least one init line when debug is
  -- enabled, but printing on every call is too noisy. Most calls
  -- to Init() after the first are idempotent (no new migrations),
  -- so we gate logs behind hasLoggedInitSummary.
  if not hasLoggedInitSummary then
    debug("Init start; existing DB type=" .. tostring(type(BookArchivistDB)) .. ", dbVersion=" .. tostring(BookArchivistDB and BookArchivistDB.dbVersion))
  end

  -- Fresh DB: create minimal header and containers; Core will
  -- continue to populate defaults (options, minimap, etc.).
  if type(BookArchivistDB) ~= "table" then
		debug("Initializing fresh DB (no existing BookArchivistDB)")
    BookArchivistDB = {
      dbVersion = 2,
      version = 1, -- legacy marker; do not mutate in migrations
      createdAt = getTime(),
      order = {},
      options = {},
      booksById = {},
      indexes = {
      objectToBookId = {},
      },
    }
		debug("Fresh DB initialized with dbVersion=" .. tostring(BookArchivistDB.dbVersion))
		hasInitialized = true
    return BookArchivistDB
  end

  -- Existing DB: run migrations explicitly by version to ensure we
  -- always advance to the latest schema, even if older dispatcher
  -- logic changes.
  local dbv = tonumber(BookArchivistDB.dbVersion) or 0
  if Migrations then
    if dbv < 1 and type(Migrations.v1) == "function" then
      debug("DB init: applying v1 (from dbVersion=" .. tostring(dbv) .. ")")
      BookArchivistDB = Migrations.v1(BookArchivistDB)
      dbv = tonumber(BookArchivistDB.dbVersion) or 0
    end
    if dbv < 2 and type(Migrations.v2) == "function" then
      debug("DB init: applying v2 (from dbVersion=" .. tostring(dbv) .. ")")
      BookArchivistDB = Migrations.v2(BookArchivistDB)
      dbv = tonumber(BookArchivistDB.dbVersion) or 0
    end
  end

  if type(BookArchivistDB.dbVersion) ~= "number" then
    BookArchivistDB.dbVersion = 1
  end

  if not hasLoggedInitSummary then
    debug("DB init complete; effective dbVersion=" .. tostring(BookArchivistDB.dbVersion or 0)
      .. ", has legacy books=" .. tostring(BookArchivistDB.books and next(BookArchivistDB.books) ~= nil)
      .. ", has booksById=" .. tostring(BookArchivistDB.booksById and next(BookArchivistDB.booksById) ~= nil))
    hasLoggedInitSummary = true
  end

  return BookArchivistDB
end
