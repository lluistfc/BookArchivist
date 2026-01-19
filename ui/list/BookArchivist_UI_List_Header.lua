---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {}
local DEFAULT_ROW_HEIGHT = Metrics.ROW_H or 36

local function getZoneLabel(entry)
	if not entry or not entry.location then
		return nil
	end
	local location = entry.location
	if location.zoneText and location.zoneText ~= "" then
		return location.zoneText
	end
	if location.zoneChain and #location.zoneChain > 0 then
		return table.concat(location.zoneChain, " > ")
	end
	return nil
end

local function entryPageCount(entry)
	if not entry or not entry.pages then
		return 0
	end
	local count = 0
	for _ in pairs(entry.pages) do
		count = count + 1
	end
	return count
end

local function entryHasLocation(entry)
	return getZoneLabel(entry) ~= nil
end

local function entryIsUnread(entry)
	if not entry then
		return false
	end
	if entry.seenCount and entry.seenCount > 1 then
		return false
	end
	if entry.lastSeenAt and entry.firstSeenAt and entry.lastSeenAt ~= entry.firstSeenAt then
		return false
	end
	return true
end

function ListUI:GetRowHeight()
	return self.__state.constants.rowHeight or DEFAULT_ROW_HEIGHT
end

function ListUI:SetRowHeight(height)
	if type(height) == "number" and height > 0 then
		self.__state.constants.rowHeight = height
	end
end

function ListUI:FormatRowMetadata(entry)
	if not entry then
		return ""
	end
	local parts = {}
	if entry.creator and entry.creator ~= "" then
		table.insert(parts, entry.creator)
	end

	local zone = getZoneLabel(entry)
	if zone then
		table.insert(parts, zone)
	end

	if #parts == 0 then
		return t("BOOK_META_FALLBACK")
	end
	return table.concat(parts, "  |cFF666666•|r  ")
end

function ListUI:EntryMatchesFilters(entry)
	local filters = self:GetFiltersState()
	if not filters then
		return true
	end
	if filters.hasLocation and not entryHasLocation(entry) then
		return false
	end
	if filters.multiPage and entryPageCount(entry) <= 1 then
		return false
	end
	if filters.unread and not entryIsUnread(entry) then
		return false
	end
	if filters.favoritesOnly and not (entry and entry.isFavorite) then
		return false
	end
	return true
end

function ListUI:UpdateCountsDisplay()
	local headerCount = self:GetFrame("headerCountText")
	if not headerCount or not headerCount.SetText then
		return
	end
	local BA = self:GetAddon()
	local db = BA and BA:GetDB() or {}
	local total = db.order and #db.order or 0
	local modes = self:GetListModes()
	local mode = self:GetListMode()

	if mode == modes.BOOKS then
		local filtered = #self:GetFilteredKeys()
		if total == 0 then
			headerCount:SetText(t("BOOK_LIST_EMPTY_HEADER"))
		elseif filtered == total then
			local key = (total == 1) and "COUNT_BOOK_SINGULAR" or "COUNT_BOOK_PLURAL"
			headerCount:SetText(string.format("|cFFFFD100" .. t(key) .. "|r", total))
		else
			headerCount:SetText(
				string.format("|cFFFFD100" .. t("COUNT_BOOKS_FILTERED_FORMAT") .. "|r", filtered, total)
			)
		end
		return
	end

	local state = self:GetLocationState()
	local node = state.activeNode or state.root
	if not node then
		headerCount:SetText(t("LOCATIONS_BROWSE_HEADER"))
		return
	end

	-- Get leaf location name (last segment in path)
	local leaf = (state.path and state.path[#state.path]) or t("LOCATIONS_BREADCRUMB_ROOT")
	local locationBooks = node.totalBooks or (node.books and #node.books) or 0
	local childCount = node.childNames and #node.childNames or 0

	local countText
	if childCount > 0 then
		local key = (childCount == 1) and "COUNT_LOCATION_SINGULAR" or "COUNT_LOCATION_PLURAL"
		countText = string.format(t(key), childCount)
	else
		local key = (locationBooks == 1) and "COUNT_BOOKS_IN_LOCATION_SINGULAR" or "COUNT_BOOKS_IN_LOCATION_PLURAL"
		countText = string.format(t(key), locationBooks)
	end

	-- Format: "Leaf Location • count" (full path now shown in breadcrumb row)
	headerCount:SetText(string.format("|cFFCCCCCC%s|r  |cFF666666•|r  |cFFFFD100%s|r", leaf, countText))
end

function ListUI:UpdateResumeButton()
	local button = self:GetFrame("resumeButton")
	if not button then
		return
	end
	local addon = self:GetAddon()
	if not addon or not addon.GetLastBookId or not addon.GetDB then
		button:Hide()
		return
	end
	local lastId = addon:GetLastBookId()
	if not lastId then
		button:Hide()
		return
	end
	local db = addon:GetDB() or {}
	local books = (db.booksById and next(db.booksById) ~= nil) and db.booksById or db.books
	if not (books and books[lastId]) then
		button:Hide()
		return
	end
	button:Show()
end

function ListUI:UpdateRandomButton()
	local button = self:GetFrame("randomButton")
	if not button then
		return
	end
	
	local addon = self:GetAddon()
	if not addon or not addon.GetDB then
		button:Disable()
		return
	end
	
	local db = addon:GetDB() or {}
	local order = db.order or {}
	
	if #order == 0 then
		-- No books in library - disable button
		button:Disable()
		if button.SetAlpha then
			button:SetAlpha(0.5)
		end
	else
		-- Books exist - enable button
		button:Enable()
		if button.SetAlpha then
			button:SetAlpha(1.0)
		end
	end
end
