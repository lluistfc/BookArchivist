---@diagnostic disable: undefined-global
-- BookArchivist_DB.lua
-- DB initialization entrypoint that wires in migrations.

local BA = BookArchivist
BookArchivistDB = BookArchivistDB or nil

local DB = BA.DB or {}
BA.DB = DB

local Migrations = BookArchivist.Migrations
local DBSafety = BookArchivist.DBSafety

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
	-- Safety check and load DB with corruption detection

	-- Use DBSafety to load and validate database
	if DBSafety and DBSafety.SafeLoad then
		BookArchivistDB = DBSafety:SafeLoad()

		-- Perform health check
		local healthy, issue = DBSafety:HealthCheck()
		if not healthy and issue then
			debug("Health check failed: " .. issue)
			-- Attempt automatic repair
			local repairCount, summary = DBSafety:RepairDatabase()
			if repairCount > 0 then
				debug("Auto-repair completed: " .. summary)
			end
		end
	elseif type(BookArchivistDB) ~= "table" then
		-- Fallback if DBSafety not loaded
		debug("DBSafety not available, using fallback initialization")
		BookArchivistDB = {
			dbVersion = 2,
			version = 1,
			createdAt = getTime(),
			order = {},
			options = {},
			booksById = {},
			indexes = {
				objectToBookId = {},
			},
		}
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
		if dbv < 3 and type(Migrations.v3) == "function" then
			debug("DB init: applying v3 (from dbVersion=" .. tostring(dbv) .. ")")
			BookArchivistDB = Migrations.v3(BookArchivistDB)
			dbv = tonumber(BookArchivistDB.dbVersion) or 0
		end
	end

	if type(BookArchivistDB.dbVersion) ~= "number" then
		BookArchivistDB.dbVersion = 1
	end

	-- Migration cleanup: Reset debug/uiDebug if dev tools not loaded
	-- This prevents users who had debug enabled in v1.0.2 from being
	-- stuck with debug mode when upgrading to v1.0.3+ without dev files
	-- NOTE: In local dev, dev files are in TOC but we still check if they initialized
	if BookArchivistDB.options then
		if BookArchivistDB.options.debug == true and not BookArchivist.DevTools then
			debug("Debug mode was enabled but dev tools not loaded - resetting to false")
			BookArchivistDB.options.debug = false
		end
		-- Disable uiDebug if dev tools not loaded
		if BookArchivistDB.options.uiDebug == true and not BookArchivist.DevTools then
			debug("UI debug was enabled but dev tools not loaded - resetting to false")
			BookArchivistDB.options.uiDebug = false
		end
	end

	hasLoggedInitSummary = true
	return BookArchivistDB
end
