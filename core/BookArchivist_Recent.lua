---@diagnostic disable: undefined-global
-- BookArchivist_Recent.lua
-- Per-character "recently read" tracking on top of booksById.

BookArchivist = BookArchivist or {}
BookArchivist.Core = BookArchivist.Core or {}

local Recent = BookArchivist.Recent or {}
BookArchivist.Recent = Recent

local Core = BookArchivist.Core

local function now()
	if Core and Core.Now then
		return Core:Now()
	end
	local osTime = type(os) == "table" and os.time or nil
	return osTime and osTime() or 0
end

local function ensureRecentContainer(db)
	if not db then
		return nil
	end
	db.recent = db.recent or {}
	local recent = db.recent
	if type(recent.cap) ~= "number" or recent.cap <= 0 then
		recent.cap = 50
	end
	recent.list = recent.list or {}
	return recent
end

---Mark a book as opened in the reader.
---@param bookId string
function Recent:MarkOpened(bookId)
	if not bookId then
		return
	end
	local db = BookArchivist.Repository:GetDB()
	if not db or type(db.booksById) ~= "table" then
		return
	end
	local entry = db.booksById[bookId]
	if not entry then
		BookArchivist:DebugPrint("[Recent] MarkOpened called for missing bookId " .. tostring(bookId))
		return
	end

	local recent = ensureRecentContainer(db)
	if not recent then
		return
	end

	local ts = now()
	entry.lastReadAt = ts
	entry.updatedAt = ts

	local list = recent.list
	-- De-duplicate existing entries for this bookId.
	for i = #list, 1, -1 do
		if list[i] == bookId then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, bookId)

	local cap = recent.cap or 50
	while #list > cap do
		table.remove(list)
	end
end

---Return the sanitized MRU list of recently-read bookIds.
---@return string[]
function Recent:GetList()
	local db = BookArchivist.Repository:GetDB()
	if not db or type(db.booksById) ~= "table" then
		return {}
	end
	local recent = ensureRecentContainer(db)
	if not recent then
		return {}
	end

	local list = recent.list or {}
	local books = db.booksById or {}
	local filtered = {}
	local seen = {}

	for _, key in ipairs(list) do
		if books[key] and not seen[key] then
			table.insert(filtered, key)
			seen[key] = true
		end
	end

	-- Keep the stored list clean of stale or duplicate keys.
	recent.list = filtered

	return filtered
end
