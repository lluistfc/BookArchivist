---@diagnostic disable: undefined-global
-- BookArchivist_Repository.lua
-- Central database repository - single source of truth for all DB access
-- Enables clean test isolation without global overrides

BookArchivist = BookArchivist or {}

local Repository = {}
BookArchivist.Repository = Repository

-- Active database (nil = use production DB, table = test override)
local activeDB = nil

---Initialize repository (called on addon load)
function Repository:Init()
	activeDB = nil
end

---Get current database (production or test override)
---@return table db The active database
function Repository:GetDB()
	if activeDB then
		return activeDB
	end
	-- Delegate to Core for production DB with migrations
	local Core = BookArchivist.Core
	if not Core or not Core.GetDB then
		error("BookArchivist.Repository: Core.GetDB not available - addon not properly initialized")
	end
	local db = Core:GetDB()
	if not db then
		error("BookArchivist.Repository: Core.GetDB returned nil - database not initialized")
	end
	return db
end

---Override database for testing (TestContainers pattern)
---@param db table Test database to use
function Repository:SetTestDB(db)
	activeDB = db
end

---Clear test override and return to production DB
function Repository:ClearTestDB()
	activeDB = nil
end

---Check if test database is active
---@return boolean
function Repository:IsTestMode()
	return activeDB ~= nil
end
