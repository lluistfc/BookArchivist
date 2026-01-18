---@diagnostic disable: undefined-global
-- BookArchivist_DBSafety.lua
-- SavedVariables corruption detection, backup, and recovery system.

local BA = BookArchivist

local DBSafety = {}
BookArchivist.DBSafety = DBSafety

local BACKUP_PREFIX = "BookArchivistDB_Backup_"

local function extractBackupTimestamp(name)
	local suffix = name:sub(#BACKUP_PREFIX + 1)
	return suffix:gsub("^CORRUPTED_", "")
end

-- Module loaded confirmation
if BookArchivist and BookArchivist.DebugPrint then
	BookArchivist:DebugPrint("[DBSafety] Module loaded")
end

--- Validate the structure of the database
--- @param db any The database to validate
--- @return boolean valid Whether the DB is valid
--- @return string|nil error Error message if invalid
function DBSafety:ValidateStructure(db)
	-- Check if DB exists and is a table
	if type(db) ~= "table" then
		return false, "Database is not a table (found: " .. type(db) .. ")"
	end

	-- Check critical structure
	-- Accept either modern (booksById) or legacy v1.0.2 (books) structure
	local hasModernStructure = type(db.booksById) == "table"
	local hasLegacyStructure = type(db.books) == "table"

	if not hasModernStructure and not hasLegacyStructure then
		return false, "Neither booksById nor books table found"
	end

	if type(db.order) ~= "table" then
		return false, "order is missing or not a table"
	end

	-- Validate dbVersion
	if db.dbVersion and type(db.dbVersion) ~= "number" then
		return false, "dbVersion exists but is not a number"
	end

	-- Validate indexes
	if db.indexes then
		if type(db.indexes) ~= "table" then
			return false, "indexes exists but is not a table"
		end
		if db.indexes.objectToBookId and type(db.indexes.objectToBookId) ~= "table" then
			return false, "indexes.objectToBookId exists but is not a table"
		end
	end

	-- Validate options
	if db.options and type(db.options) ~= "table" then
		return false, "options exists but is not a table"
	end

	return true, nil
end

--- Create a backup of the current database
--- @return string backupName Global variable name where backup was stored
function DBSafety:CreateBackup()
	local dateFn = date or (os and os.date) or function()
		return "unknown"
	end
	local timestamp = dateFn("%Y%m%d_%H%M%S")
	local backupName = BACKUP_PREFIX .. timestamp

	_G[backupName] = self:CloneTable(BookArchivistDB)

	return backupName
end

--- Create a backup specifically for corrupted data
--- @param corrupted any The corrupted data
--- @return string backupName Global variable name where backup was stored
function DBSafety:CreateCorruptionBackup(corrupted)
	local dateFn = date or (os and os.date) or function()
		return "unknown"
	end
	local timestamp = dateFn("%Y%m%d_%H%M%S")
	local backupName = BACKUP_PREFIX .. "CORRUPTED_" .. timestamp

	-- Don't try to clone corrupted data - just store it as-is
	_G[backupName] = corrupted

	return backupName
end

--- Deep clone a table
--- @param src any Value to clone
--- @param visited table|nil Circular reference tracking
--- @return any clone
function DBSafety:CloneTable(src, visited)
	if type(src) ~= "table" then
		return src
	end

	visited = visited or {}

	-- Check for circular references
	if visited[src] then
		return visited[src]
	end

	local clone = {}
	visited[src] = clone

	for k, v in pairs(src) do
		clone[k] = self:CloneTable(v, visited)
	end

	return clone
end

--- Initialize a fresh database with default structure
--- @return table Fresh database
function DBSafety:InitializeFreshDB()
	local now = time and time() or (os and os.time and os.time()) or 0

	return {
		dbVersion = 2,
		version = 1,
		createdAt = now,
		order = {},
		options = {},
		booksById = {},
		indexes = {
			objectToBookId = {},
			itemToBookIds = {},
			titleToBookIds = {},
		},
		recent = {
			cap = 50,
			list = {},
		},
		uiState = {
			lastCategoryId = "__all__",
		},
	}
end

--- Safely load the database with corruption detection
--- @return table Database (fresh if corrupted)
function DBSafety:SafeLoad()
	-- Check if global DB exists
	if not BookArchivistDB then
		-- First-time initialization (only log if really needed)
		return self:InitializeFreshDB()
	end

	-- Validate structure
	local valid, error = self:ValidateStructure(BookArchivistDB)

	if not valid then
		-- CORRUPTION DETECTED - Handle it gracefully
		if BookArchivist and BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[DBSafety] CORRUPTION DETECTED: " .. tostring(error))
		end

		local corrupted = BookArchivistDB
		local backupName = self:CreateCorruptionBackup(corrupted)

		-- Show user a popup (delayed to ensure UI is ready)
		C_Timer.After(2, function()
			StaticPopupDialogs["BOOKARCHIVIST_CORRUPTION"] = {
				text = string.format(
					"|cFFFF0000BookArchivist Database Corruption Detected!|r\n\n"
						.. "Error: %s\n\n"
						.. "Your corrupted data has been backed up to:\n"
						.. "|cFFFFFF00%s|r\n\n"
						.. "A fresh database will be created.\n\n"
						.. "|cFF888888Please report this to the addon author with details about what you were doing when this occurred.|r",
					error or "Unknown error",
					backupName
				),
				button1 = "OK, Create Fresh Database",
				timeout = 0,
				whileDead = true,
				hideOnEscape = false,
				preferredIndex = 3,
				OnAccept = function()
					if BookArchivist and BookArchivist.DebugPrint then
						BookArchivist:DebugPrint("[DBSafety] User acknowledged corruption, continuing with fresh DB")
					end
				end,
			}
			StaticPopup_Show("BOOKARCHIVIST_CORRUPTION")
		end)

		-- Return fresh database
		BookArchivistDB = self:InitializeFreshDB()
		return BookArchivistDB
	end

	-- Database is valid - no message needed (reduces spam)
	return BookArchivistDB
end

--- Perform a safety check on the database (can be called periodically)
--- @param db table|nil Database to check (defaults to BookArchivistDB global)
--- @return boolean isHealthy
--- @return string|nil issue Description of any issues found
function DBSafety:HealthCheck(db)
	-- Default to global BookArchivistDB if no parameter provided
	db = db or BookArchivistDB
	
	if not db or type(db) ~= "table" then
		return false, "Database is missing or not a table"
	end
	local issues = {}

	-- Determine which structure we're using
	local booksTable = db.booksById or db.books
	local isModern = db.booksById ~= nil

	-- Check for orphaned order entries
	if db.order and booksTable then
		local orphanCount = 0
		for _, bookKey in ipairs(db.order) do
			if not booksTable[bookKey] then
				orphanCount = orphanCount + 1
			end
		end
		if orphanCount > 0 then
			table.insert(issues, string.format("%d orphaned entries in order", orphanCount))
		end
	end

	-- Check for books with missing required fields
	if booksTable then
		local invalidBooks = 0
		for bookKey, entry in pairs(booksTable) do
			if type(entry) ~= "table" then
				invalidBooks = invalidBooks + 1
			elseif not entry.title or not entry.pages then
				invalidBooks = invalidBooks + 1
			end
		end
		if invalidBooks > 0 then
			table.insert(issues, string.format("%d books with invalid structure", invalidBooks))
		end
	end

	-- Check recent list validity (only for modern structure)
	if isModern and db.recent and db.recent.list and booksTable then
		local invalidRecent = 0
		for _, bookId in ipairs(db.recent.list) do
			if not booksTable[bookId] then
				invalidRecent = invalidRecent + 1
			end
		end
		if invalidRecent > 0 then
			table.insert(issues, string.format("%d invalid entries in recent list", invalidRecent))
		end
	end

	if #issues > 0 then
		return false, table.concat(issues, "; ")
	end

	return true, nil
end

--- Repair common database issues (non-destructive)
--- @return number repairCount Number of issues repaired
--- @return string summary Summary of repairs
function DBSafety:RepairDatabase()
	if not BookArchivistDB or type(BookArchivistDB) ~= "table" then
		return 0, "Cannot repair: database is missing or invalid"
	end

	local db = BookArchivistDB
	local repairs = {}
	local repairCount = 0

	-- Determine which structure we're using
	local booksTable = db.booksById or db.books
	local isModern = db.booksById ~= nil

	-- Remove orphaned order entries
	if db.order and booksTable then
		local newOrder = {}
		local orphanedCount = 0
		for _, bookKey in ipairs(db.order) do
			if booksTable[bookKey] then
				table.insert(newOrder, bookKey)
			else
				orphanedCount = orphanedCount + 1
			end
		end
		if orphanedCount > 0 then
			db.order = newOrder
			repairCount = repairCount + orphanedCount
			table.insert(repairs, string.format("Removed %d orphaned order entries", orphanedCount))
		end
	end

	-- Clean up recent list (only for modern structure)
	if isModern and db.recent and db.recent.list and booksTable then
		local newRecent = {}
		local invalidCount = 0
		for _, bookId in ipairs(db.recent.list) do
			if booksTable[bookId] then
				table.insert(newRecent, bookId)
			else
				invalidCount = invalidCount + 1
			end
		end
		if invalidCount > 0 then
			db.recent.list = newRecent
			repairCount = repairCount + invalidCount
			table.insert(repairs, string.format("Removed %d invalid recent entries", invalidCount))
		end
	end

	-- Fix missing uiState (only for modern structure)
	if isModern then
		if not db.uiState then
			db.uiState = { lastCategoryId = "__all__" }
			repairCount = repairCount + 1
			table.insert(repairs, "Recreated missing uiState")
		elseif db.uiState.lastBookId and booksTable and not booksTable[db.uiState.lastBookId] then
			db.uiState.lastBookId = nil
			repairCount = repairCount + 1
			table.insert(repairs, "Cleared invalid lastBookId from uiState")
		end
	end

	-- Remove invalid book entries
	if booksTable then
		local removedBooks = 0
		local toRemove = {}
		for bookKey, entry in pairs(booksTable) do
			if type(entry) ~= "table" or not entry.title or not entry.pages then
				table.insert(toRemove, bookKey)
			end
		end
		for _, bookKey in ipairs(toRemove) do
			booksTable[bookKey] = nil
			removedBooks = removedBooks + 1
		end
		if removedBooks > 0 then
			repairCount = repairCount + removedBooks
			table.insert(repairs, string.format("Removed %d invalid book entries", removedBooks))
		end
	end

	local summary = repairCount > 0 and table.concat(repairs, "; ") or "No repairs needed"
	return repairCount, summary
end

--- Get list of all backup names stored in globals
--- @return table List of backup names
function DBSafety:GetAvailableBackups()
	local backups = {}

	for key, value in pairs(_G) do
		if type(key) == "string" and key:sub(1, #BACKUP_PREFIX) == BACKUP_PREFIX then
			table.insert(backups, {
				name = key,
				isCorrupted = key:find("CORRUPTED") ~= nil,
				size = self:EstimateSize(value),
			})
		end
	end

	-- Sort newest first by timestamp, falling back to corruption flag then name
	table.sort(backups, function(a, b)
		local aKey = extractBackupTimestamp(a.name)
		local bKey = extractBackupTimestamp(b.name)
		if aKey ~= bKey then
			return aKey > bKey
		end
		if a.isCorrupted ~= b.isCorrupted then
			return b.isCorrupted -- prefer non-corrupted
		end
		return a.name > b.name
	end)

	return backups
end

--- Estimate size of a value in KB (rough approximation)
--- @param value any
--- @return number sizeKB
function DBSafety:EstimateSize(value)
	if type(value) ~= "table" then
		return 0.001 -- Negligible
	end

	local count = 0
	for k, v in pairs(value) do
		count = count + 1
		if type(v) == "table" then
			count = count + 10 -- Rough estimate
		end
	end

	return count * 0.1 -- Very rough estimate in KB
end
