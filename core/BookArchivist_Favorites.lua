---@diagnostic disable: undefined-global
-- BookArchivist_Favorites.lua
-- Per-character favorites helpers on top of booksById.

local BA = BookArchivist

local Favorites = BookArchivist.Favorites or {}
BookArchivist.Favorites = Favorites

local Core = BookArchivist.Core

local function now()
	if Core and Core.Now then
		return Core:Now()
	end
	local osTime = type(os) == "table" and os.time or nil
	return osTime and osTime() or 0
end

---Set favorite state for a given bookId.
---@param bookId string
---@param value boolean
function Favorites:Set(bookId, value)
	if not bookId then
		return
	end
	local db = BookArchivist.Repository:GetDB()
	if not db or type(db.booksById) ~= "table" then
		return
	end
	local entry = db.booksById[bookId]
	if not entry then
		BookArchivist:DebugPrint("[Favorites] Set called for missing bookId " .. tostring(bookId))
		return
	end
	local flag = value and true or false
	if entry.isFavorite == flag then
		return
	end
	entry.isFavorite = flag
	entry.updatedAt = now()
end

---Toggle favorite state for a given bookId.
---@param bookId string
function Favorites:Toggle(bookId)
	if not bookId then
		return
	end
	local db = BookArchivist.Repository:GetDB()
	if not db or type(db.booksById) ~= "table" then
		return
	end
	local entry = db.booksById[bookId]
	if not entry then
		BookArchivist:DebugPrint("[Favorites] Toggle called for missing bookId " .. tostring(bookId))
		return
	end
	local newValue = not (entry.isFavorite and true or false)
	self:Set(bookId, newValue)
end

---Check whether a given bookId is marked as favorite.
---@param bookId string
---@return boolean
function Favorites:IsFavorite(bookId)
	if not bookId then
		return false
	end
	local db = BookArchivist.Repository:GetDB()
	if not db or type(db.booksById) ~= "table" then
		return false
	end
	local entry = db.booksById[bookId]
	if not entry then
		return false
	end
	return entry.isFavorite and true or false
end
