---@diagnostic disable: undefined-global
local BA = BookArchivist

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
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: no key provided")
		end
		return
	end
	local db = self:EnsureDB()
	if db.booksById and not db.booksById[key] then
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: book not found:", key)
		end
		return
	end
	
	if BA and BA.DebugPrint then
		BA:DebugPrint("[Order] Delete: starting deletion for key:", key)
	end
	
	-- Get the book entry before deletion for index cleanup
	local entry = db.booksById and db.booksById[key]
	
	if BA and BA.DebugPrint then
		BA:DebugPrint("[Order] Delete: entry exists:", entry ~= nil, "hasIndexes:", db.indexes ~= nil)
	end
	
	-- Remove from main storage
	if db.booksById then
		db.booksById[key] = nil
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: removed from booksById")
		end
	end
	
	-- Remove from order list
	removeFromOrder(db.order, key)
	if BA and BA.DebugPrint then
		BA:DebugPrint("[Order] Delete: removed from order list")
	end
	
	-- Remove from recent list
	if db.recent and type(db.recent.list) == "table" then
		removeFromOrder(db.recent.list, key)
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: removed from recent list")
		end
	end
	
	-- Clear UI state if this was the selected book
	if db.uiState and db.uiState.lastBookId == key then
		db.uiState.lastBookId = nil
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: cleared UI state")
		end
	end
	
	-- Clean up indexes if entry exists
	if entry and db.indexes then
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: starting index cleanup")
		end
		-- Remove from title index
		if entry.title and db.indexes.titleToBookIds then
			local normalizedTitle = entry.title:lower():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			local titleMap = db.indexes.titleToBookIds[normalizedTitle]
			if titleMap then
				for i = #titleMap, 1, -1 do
					if titleMap[i] == key then
						table.remove(titleMap, i)
					end
				end
				-- Clean up empty arrays
				if #titleMap == 0 then
					db.indexes.titleToBookIds[normalizedTitle] = nil
				end
				if BA and BA.DebugPrint then
					BA:DebugPrint("[Order] Delete: cleaned up title index for:", entry.title)
				end
			end
		end
		
		-- Remove from item index
		if entry.itemId and db.indexes.itemToBookIds then
			local itemMap = db.indexes.itemToBookIds[entry.itemId]
			if itemMap then
				for i = #itemMap, 1, -1 do
					if itemMap[i] == key then
						table.remove(itemMap, i)
					end
				end
				-- Clean up empty arrays
				if #itemMap == 0 then
					db.indexes.itemToBookIds[entry.itemId] = nil
				end
				if BA and BA.DebugPrint then
					BA:DebugPrint("[Order] Delete: cleaned up item index for itemId:", entry.itemId)
				end
			end
		end
		
		-- Remove from object index
		if entry.objectId and db.indexes.objectToBookId then
			if db.indexes.objectToBookId[entry.objectId] == key then
				db.indexes.objectToBookId[entry.objectId] = nil
				if BA and BA.DebugPrint then
					BA:DebugPrint("[Order] Delete: cleaned up object index for objectId:", entry.objectId)
				end
			end
		end
		
		if BA and BA.DebugPrint then
			BA:DebugPrint("[Order] Delete: index cleanup complete")
		end
	end
	
	if BA and BA.DebugPrint then
		BA:DebugPrint("[Order] Delete: deletion complete for key:", key)
	end
end
