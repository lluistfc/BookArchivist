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
	if BA and BA.DebugPrint then
		local orderCount = db and db.order and #db.order or 0
		local hasBooks = db and db.booksById and next(db.booksById) ~= nil
		BA:DebugPrint("[Repository] Init: database set (order:", orderCount, "hasBooks:", hasBooks, ")")
	end
end

---Get current database
---@return table|nil The active database (nil during early initialization)
function Repository:GetDB()
	-- Return injected database if available
	if db then
		return db
	end
	-- Fallback to global BookArchivistDB (for initialization sequence)
	if BookArchivistDB then
		return BookArchivistDB
	end
	-- During initialization, both might be nil - return nil instead of erroring
	-- Caller (Core:GetDB) will handle this with its own fallback to ensureDB()
	return nil
end
