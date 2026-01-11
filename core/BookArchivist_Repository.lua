---@diagnostic disable: undefined-global
-- BookArchivist_Repository.lua
-- Central database repository - single source of truth for all DB access

BookArchivist = BookArchivist or {}

local Repository = {}
BookArchivist.Repository = Repository

---Initialize repository (called on addon load)
function Repository:Init()
	-- Nothing to initialize in production
end

---Get current database
---@return table db The active database
function Repository:GetDB()
	-- Access production database global
	local db = BookArchivistDB
	if not db then
		error("BookArchivist.Repository: BookArchivistDB not initialized - database not available")
	end
	return db
end
