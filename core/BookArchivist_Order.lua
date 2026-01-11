---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
if not Core then
	return
end

local function removeFromOrder(order, key)
	if not key or not order then
		return
	end
	for i = #order, 1, -1 do
		if order[i] == key then
			table.remove(order, i)
			return
		end
	end
end

function Core:TouchOrder(key)
	if not key then
		return
	end
	local db = self:EnsureDB()
	local order = db.order
	removeFromOrder(order, key)
	table.insert(order, 1, key)
end

function Core:AppendOrder(key)
	if not key then
		return
	end
	local db = self:EnsureDB()
	local order = db.order
	removeFromOrder(order, key)
	table.insert(order, key)
end

function Core:Delete(key)
	if not key then
		return
	end
	local db = self:EnsureDB()
	if db.booksById and not db.booksById[key] then
		return
	end
	if db.booksById then
		db.booksById[key] = nil
	end
	removeFromOrder(db.order, key)
	if db.recent and type(db.recent.list) == "table" then
		removeFromOrder(db.recent.list, key)
	end
	if db.uiState and db.uiState.lastBookId == key then
		db.uiState.lastBookId = nil
	end
end
