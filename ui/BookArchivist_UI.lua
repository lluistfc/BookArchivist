---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_UI.lua
-- Core state and lightweight helpers shared by the UI modules.

local isInitialized = false
local needsRefresh = false

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ListUI = BookArchivist.UI.List
local ReaderUI = BookArchivist.UI.Reader

local Internal = BookArchivist.UI.Internal or {}
BookArchivist.UI.Internal = Internal
Internal.ListUI = ListUI
Internal.ReaderUI = ReaderUI

local function ensureAddon()
	if not BookArchivist or not BookArchivist.GetDB then
		return nil
	end
	return BookArchivist
end

local cachedAddon = ensureAddon()

local function getAddon()
	if cachedAddon and cachedAddon.GetDB then
		return cachedAddon
	end
	cachedAddon = ensureAddon()
	return cachedAddon
end

Internal.getAddon = getAddon

local LIST_MODES = {
	BOOKS = "books",
	LOCATIONS = "locations",
}

Internal.listModes = LIST_MODES

local ViewModel = {
	filteredKeys = {},
	selectedKey = nil,
	listMode = LIST_MODES.BOOKS,
}

local function setSelectedKey(key)
	ViewModel.selectedKey = key
end
Internal.setSelectedKey = setSelectedKey

local function getSelectedKey()
	return ViewModel.selectedKey
end
Internal.getSelectedKey = getSelectedKey

local function getFilteredKeys()
	return ViewModel.filteredKeys
end
Internal.getFilteredKeys = getFilteredKeys

local function fmtTime(ts)
	if not ts then
		return ""
	end
	return date("%Y-%m-%d %H:%M", ts)
end
Internal.fmtTime = fmtTime

local UI
local Widgets = {}

Internal.getUIFrame = function()
	return UI
end

Internal.setUIFrame = function(frame)
	UI = frame
end

Internal.getIsInitialized = function()
	return isInitialized
end

Internal.setIsInitialized = function(state)
	isInitialized = state and true or false
end

Internal.getNeedsRefresh = function()
	return needsRefresh
end

Internal.setNeedsRefresh = function(state)
	needsRefresh = state and true or false
end

local function getWidget(name)
	local widget = Widgets[name]
	if widget then
		return widget
	end
	if UI and UI[name] then
		Widgets[name] = UI[name]
		return Widgets[name]
	end
	return nil
end
Internal.getWidget = getWidget

local function rememberWidget(name, widget)
	if widget then
		Widgets[name] = widget
		if UI then
			UI[name] = widget
		end
	end
	return widget
end
Internal.rememberWidget = rememberWidget

local function getListMode()
	return ViewModel.listMode or LIST_MODES.BOOKS
end
Internal.getListMode = getListMode

local function rebuildLocationView()
	if ListUI and ListUI.RebuildLocationTree then
		ListUI:RebuildLocationTree()
	end
end
Internal.rebuildLocationView = rebuildLocationView

local function updateListModeUI()
	if ListUI and ListUI.UpdateListModeUI then
		ListUI:UpdateListModeUI()
	end
end
Internal.updateListModeUI = updateListModeUI

local function runUpdateList()
	if Internal.updateList then
		Internal.updateList()
	end
end

local function setListMode(mode)
	if mode ~= LIST_MODES.BOOKS and mode ~= LIST_MODES.LOCATIONS then
		mode = LIST_MODES.BOOKS
	end

	if ViewModel.listMode == mode then
		if mode == LIST_MODES.LOCATIONS then
			rebuildLocationView()
		end
		updateListModeUI()
		return
	end

	ViewModel.listMode = mode
	if mode == LIST_MODES.LOCATIONS then
		rebuildLocationView()
	else
		updateListModeUI()
	end

	runUpdateList()
end
Internal.setListMode = setListMode

local function flushPendingRefresh()
	if not needsRefresh then
		if Internal.debugPrint then
			Internal.debugPrint("[BookArchivist] flushPendingRefresh: nothing queued")
		end
		return
	end

	if not UI then
		if Internal.debugPrint then
			Internal.debugPrint("[BookArchivist] flushPendingRefresh: UI missing")
		end
		return
	end

	if not isInitialized then
		if Internal.debugPrint then
			Internal.debugPrint("[BookArchivist] flushPendingRefresh: UI not initialized")
		end
		return
	end

	if Internal.debugPrint then
		Internal.debugPrint("[BookArchivist] flushPendingRefresh: running refreshAll")
	end
	if Internal.debugMessage then
		Internal.debugMessage("|cFFFFFF00BookArchivist UI refreshing...|r")
	end

	local refreshFn = Internal.refreshAll
	if not refreshFn then
		if Internal.debugPrint then
			Internal.debugPrint("[BookArchivist] flushPendingRefresh: refresh handler missing")
		end
		return
	end

	refreshFn()
end
Internal.flushPendingRefresh = flushPendingRefresh

local function formatZoneText(chain)
	if not chain or #chain == 0 then
		return "Unknown Zone"
	end
	return table.concat(chain, " > ")
end

local function formatLocationLine(loc)
	if not loc then
		return nil
	end

	local zoneText = loc.zoneText
	if not zoneText or zoneText == "" then
		zoneText = formatZoneText(loc.zoneChain)
	end

	if loc.context == "loot" then
		local mob = loc.mobName or "Unknown Mob"
		return string.format("|cFFFFD100Looted:|r %s > %s", zoneText, mob)
	end

	return string.format("|cFFFFD100Location:|r %s", zoneText)
end
Internal.formatLocationLine = formatLocationLine

