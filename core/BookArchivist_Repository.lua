---@diagnostic disable: undefined-global
-- BookArchivist_Repository.lua
-- Central database repository - single source of truth for all DB access

local BA = BookArchivist

local Repository = {}
BA.Repository = Repository

-- The database instance to use (injected via Init)
local db = nil

---Initialize repository with a database instance
---@param database table The database to use
function Repository:Init(database)
	db = database
end

---Get current database
---@return table The active database
function Repository:GetDB()
	if not db then
		error("BookArchivist.Repository: Not initialized - call Init(db) first")
	end
	return db
end
