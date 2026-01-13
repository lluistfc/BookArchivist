---@diagnostic disable: undefined-global
-- BookArchivist_BookEcho.lua
-- Memory reflection system - generates contextual echoes based on reading history

BookArchivist = BookArchivist or {}

local BookEcho = {}
BookArchivist.BookEcho = BookEcho

local L = BookArchivist.L or {}

-- Location context patterns (order matters: most specific first)
local LOCATION_CONTEXTS = {
	{pattern = "Library", phrase = "LOC_CONTEXT_ARCHIVES"},
	{pattern = "Archive", phrase = "LOC_CONTEXT_ARCHIVES"},
	{pattern = "Cave", phrase = "LOC_CONTEXT_DEPTHS"},
	{pattern = "Cavern", phrase = "LOC_CONTEXT_DEPTHS"},
	{pattern = "Grotto", phrase = "LOC_CONTEXT_DEPTHS"},
	{pattern = "Ruin", phrase = "LOC_CONTEXT_RUINS"},
	{pattern = "Temple", phrase = "LOC_CONTEXT_RUINS"},
	{pattern = "Tomb", phrase = "LOC_CONTEXT_RUINS"},
	{pattern = "Forest", phrase = "LOC_CONTEXT_CANOPY"},
	{pattern = "Grove", phrase = "LOC_CONTEXT_CANOPY"},
	{pattern = "Jungle", phrase = "LOC_CONTEXT_CANOPY"},
	{pattern = "Desert", phrase = "LOC_CONTEXT_SANDS"},
	{pattern = "Dunes", phrase = "LOC_CONTEXT_SANDS"},
	{pattern = "Sands", phrase = "LOC_CONTEXT_SANDS"},
	{pattern = "Mountain", phrase = "LOC_CONTEXT_PEAKS"},
	{pattern = "Peak", phrase = "LOC_CONTEXT_PEAKS"},
	{pattern = "Summit", phrase = "LOC_CONTEXT_PEAKS"},
	{pattern = "Ship", phrase = "LOC_CONTEXT_ABOARD"},
	{pattern = "Vessel", phrase = "LOC_CONTEXT_ABOARD"},
	{pattern = "Boat", phrase = "LOC_CONTEXT_ABOARD"},
	{pattern = "Citadel", phrase = "LOC_CONTEXT_SHADOWS"},
	{pattern = "Sanctum", phrase = "LOC_CONTEXT_SHADOWS"},
	{pattern = "Fortress", phrase = "LOC_CONTEXT_SHADOWS"},
	{pattern = "Undermine", phrase = "LOC_CONTEXT_DEEP"},
	{pattern = "Below", phrase = "LOC_CONTEXT_DEEP"},
	{pattern = "Barrens", phrase = "LOC_CONTEXT_WILDS"},
	{pattern = "Plains", phrase = "LOC_CONTEXT_WILDS"},
	{pattern = "Wasteland", phrase = "LOC_CONTEXT_WILDS"},
	{pattern = "Shore", phrase = "LOC_CONTEXT_SHORES"},
	{pattern = "Coast", phrase = "LOC_CONTEXT_SHORES"},
	{pattern = "Bay", phrase = "LOC_CONTEXT_SHORES"},
	{pattern = "Isle", phrase = "LOC_CONTEXT_ISLE"},
	{pattern = "Island", phrase = "LOC_CONTEXT_ISLE"},
	
	-- City-specific patterns (check after generic patterns)
	{pattern = "Stormwind", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Ironforge", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Darnassus", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Orgrimmar", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Thunder Bluff", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Undercity", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Silvermoon", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Exodar", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Shattrath", phrase = "LOC_CONTEXT_SHELVES"},
	{pattern = "Dalaran", phrase = "LOC_CONTEXT_SHELVES"},
}

local function getLocationContext(locationName)
	if not locationName then 
		return L["LOC_CONTEXT_IN"] or "in"
	end
	
	-- Check patterns in order
	for _, context in ipairs(LOCATION_CONTEXTS) do
		if locationName:find(context.pattern) then
			return L[context.phrase] or "in"
		end
	end
	
	-- Fallback
	return L["LOC_CONTEXT_IN"] or "in"
end

local function formatTimeAgo(timestamp)
	if not timestamp then return nil end
	
	local now = BookArchivist.Core and BookArchivist.Core:Now() or time()
	local diff = now - timestamp
	
	if diff < 0 then return nil end
	
	local days = math.floor(diff / 86400)
	if days > 0 then
		return string.format(L["ECHO_TIME_DAYS"] or "%d days", days)
	end
	
	local hours = math.floor(diff / 3600)
	if hours > 0 then
		return string.format(L["ECHO_TIME_HOURS"] or "%d hours", hours)
	end
	
	local minutes = math.floor(diff / 60)
	return string.format(L["ECHO_TIME_MINUTES"] or "%d minutes", minutes)
end

function BookEcho:GetEchoText(bookId)
	if not bookId then return nil end
	
	local db = BookArchivist.Repository:GetDB()
	local book = db.booksById[bookId]
	if not book then return nil end
	
	-- Priority 1: First reopen (readCount == 2)
	if book.readCount == 2 and book.firstReadLocation then
		local contextPhrase = getLocationContext(book.firstReadLocation)
		return string.format(
			L["ECHO_FIRST_READ"] or "First discovered %s %s. Now, the book has returned to you.",
			contextPhrase,
			book.firstReadLocation
		)
	end
	
	-- Priority 2: Multiple reads (readCount > 2)
	if book.readCount and book.readCount > 2 then
		return string.format(
			L["ECHO_RETURNED"] or "You've returned to these pages %d times. Each reading leaves its mark.",
			book.readCount - 1  -- Subtract current read
		)
	end
	
	-- Priority 3: Resume state (lastPageRead < totalPages)
	if book.lastPageRead and book.pages then
		local totalPages = 0
		for _ in pairs(book.pages) do
			totalPages = totalPages + 1
		end
		
		if book.lastPageRead < totalPages then
			return string.format(
				L["ECHO_LAST_PAGE"] or "Left open at page %d. The rest of the tale awaits.",
				book.lastPageRead
			)
		end
	end
	
	-- Priority 4: Recency (fallback)
	if book.lastReadAt then
		local timeAgo = formatTimeAgo(book.lastReadAt)
		if timeAgo then
			return string.format(
				L["ECHO_LAST_OPENED"] or "Untouched for %s. Time has passed since last you turned these pages.",
				timeAgo
			)
		end
	end
	
	return nil  -- No echo available
end
