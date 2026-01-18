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
		local booksCount = 0
		if db and db.booksById then
			for _ in pairs(db.booksById) do
				booksCount = booksCount + 1
			end
		end
		BA:DebugPrint("[Repository] Init: database set (order:", orderCount, "books:", booksCount, ")")
	end
end

---Get current database
---@return table The active database
function Repository:GetDB()
	-- Return injected database if available
	if db then
		if BA and BA.DebugPrint then
			local orderCount = db.order and #db.order or 0
			local booksCount = 0
			if db.booksById then
				for _ in pairs(db.booksById) do
					booksCount = booksCount + 1
				end
			end
			BA:DebugPrint("[Repository] GetDB: returning injected db (order:", orderCount, "books:", booksCount, ")")
		end
		return db
	end
	-- Fallback to global BookArchivistDB (for initialization sequence)
	if BookArchivistDB then
		if BA and BA.DebugPrint then
			local orderCount = BookArchivistDB.order and #BookArchivistDB.order or 0
			local booksCount = 0
			if BookArchivistDB.booksById then
				for _ in pairs(BookArchivistDB.booksById) do
					booksCount = booksCount + 1
				end
			end
			BA:DebugPrint("[Repository] GetDB: returning global BookArchivistDB (order:", orderCount, "books:", booksCount, ")")
		end
		return BookArchivistDB
	end
	-- Error only if both are nil
	error("BookArchivist.Repository: Database not available - neither injected nor global exists")
end
