---@diagnostic disable: undefined-global
-- BookArchivist_ListConfig.lua
-- Centralized configuration for list options (page sizes, filters, sort modes).

BookArchivist = BookArchivist or {}

local ListConfig = {}
BookArchivist.ListConfig = ListConfig

local Core = BookArchivist.Core

-- Page sizes and defaults
local LIST_PAGE_SIZE_DEFAULT = 25
local LIST_PAGE_SIZES = {
	[10] = true,
	[25] = true,
	[50] = true,
	[100] = true,
}

-- Filter defaults for the quick filters / list filters stored in SavedVariables
local LIST_FILTER_DEFAULTS = {
	hasLocation = false,
	multiPage = false,
	unread = false,
	favoritesOnly = false,
}

-- Valid sort modes for the list view
local LIST_SORT_DEFAULT = "lastSeen"
local VALID_SORT_MODES = {
	title = true,
	zone = true,
	firstSeen = true,
	lastSeen = true,
}

local function ensureDB()
	if not Core or type(Core.EnsureDB) ~= "function" then
		BookArchivistDB = BookArchivistDB or {}
		BookArchivistDB.options = BookArchivistDB.options or {}
		BookArchivistDB.options.list = BookArchivistDB.options.list or {}
		return BookArchivistDB
	end
	return Core:EnsureDB()
end

function ListConfig:EnsureListOptions()
	local db = ensureDB()
	db.options = db.options or {}
	db.options.list = db.options.list or {}
	local listOpts = db.options.list

	if type(listOpts.sortMode) ~= "string" or listOpts.sortMode == "" then
		listOpts.sortMode = LIST_SORT_DEFAULT
	end

	if type(listOpts.pageSize) ~= "number" or not LIST_PAGE_SIZES[listOpts.pageSize] then
		listOpts.pageSize = LIST_PAGE_SIZE_DEFAULT
	end

	listOpts.filters = listOpts.filters or {}
	for key, defaultValue in pairs(LIST_FILTER_DEFAULTS) do
		if listOpts.filters[key] == nil then
			listOpts.filters[key] = defaultValue
		end
	end
	-- Drop legacy filter keys that are no longer used.
	listOpts.filters.hasAuthor = nil

	return listOpts
end

function ListConfig:GetSortMode()
	local listOpts = self:EnsureListOptions()
	local mode = listOpts.sortMode or LIST_SORT_DEFAULT
	if not VALID_SORT_MODES[mode] then
		if mode == "recent" then
			mode = LIST_SORT_DEFAULT
		end
		if not VALID_SORT_MODES[mode] then
			mode = LIST_SORT_DEFAULT
		end
		listOpts.sortMode = mode
	end
	return mode
end

function ListConfig:SetSortMode(mode)
	local listOpts = self:EnsureListOptions()
	if type(mode) ~= "string" or not VALID_SORT_MODES[mode] then
		mode = LIST_SORT_DEFAULT
	end
	listOpts.sortMode = mode
end

function ListConfig:NormalizePageSize(size)
	size = tonumber(size)
	if LIST_PAGE_SIZES[size] then
		return size
	end
	return LIST_PAGE_SIZE_DEFAULT
end

function ListConfig:GetListPageSize()
	local listOpts = self:EnsureListOptions()
	listOpts.pageSize = self:NormalizePageSize(listOpts.pageSize)
	return listOpts.pageSize
end

function ListConfig:SetListPageSize(size)
	local listOpts = self:EnsureListOptions()
	listOpts.pageSize = self:NormalizePageSize(size)
end

function ListConfig:GetListFilters()
	local listOpts = self:EnsureListOptions()
	return listOpts.filters
end

function ListConfig:SetListFilter(filterKey, state)
	if not filterKey then
		return
	end
	local listOpts = self:EnsureListOptions()
	if listOpts.filters[filterKey] == nil then
		return
	end
	listOpts.filters[filterKey] = state and true or false
	return listOpts.filters
end

function ListConfig:GetPageSizes()
	local sizes = {}
	for size, allowed in pairs(LIST_PAGE_SIZES) do
		if allowed then
			table.insert(sizes, size)
		end
	end
	table.sort(sizes)
	return sizes
end
