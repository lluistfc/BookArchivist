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
---@return table The active database
function Repository:GetDB()
	-- Return injected database if available
	if db then
		if BA and BA.DebugPrint then
			local orderCount = db.order and #db.order or 0
			local hasBooks = db.booksById and next(db.booksById) ~= nil
			BA:DebugPrint("[Repository] GetDB: returning injected db (order:", orderCount, "hasBooks:", hasBooks, ")")
		end
		return db
	end
	-- Fallback to global BookArchivistDB (for initialization sequence)
	if BookArchivistDB then
		if BA and BA.DebugPrint then
			local orderCount = BookArchivistDB.order and #BookArchivistDB.order or 0
			local hasBooks = BookArchivistDB.booksById and next(BookArchivistDB.booksById) ~= nil
			BA:DebugPrint("[Repository] GetDB: returning global BookArchivistDB (order:", orderCount, "hasBooks:", hasBooks, ")")
		end
		return BookArchivistDB
	end
	-- Error only if both are nil
	error("BookArchivist.Repository: Database not available - neither injected nor global exists")
end
