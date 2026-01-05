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

local refreshFlags = {
	list = true,
	reader = true,
	location = true,
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

local function requestFullRefresh()
	refreshFlags.list = true
	refreshFlags.reader = true
	refreshFlags.location = true
	Internal.setNeedsRefresh(true)
end
Internal.requestFullRefresh = requestFullRefresh

local function requestListRefresh()
	refreshFlags.list = true
	Internal.setNeedsRefresh(true)
end
Internal.requestListRefresh = requestListRefresh

local function requestReaderRefresh()
	refreshFlags.reader = true
	Internal.setNeedsRefresh(true)
end
Internal.requestReaderRefresh = requestReaderRefresh

local function requestLocationRefresh()
	refreshFlags.location = true
	Internal.setNeedsRefresh(true)
end
Internal.requestLocationRefresh = requestLocationRefresh

local function getRefreshFlags()
	return refreshFlags
end
Internal.getRefreshFlags = getRefreshFlags

local function markRefreshComplete(kind)
	if refreshFlags[kind] ~= nil then
		refreshFlags[kind] = false
	end
	if not refreshFlags.list and not refreshFlags.reader and not refreshFlags.location then
		Internal.setNeedsRefresh(false)
	end
end
Internal.markRefreshComplete = markRefreshComplete

local function flushPendingRefresh()
	if not needsRefresh then
		BookArchivist:DebugPrint("[BookArchivist] flushPendingRefresh: nothing queued")
		return
	end

	if not UI then
		BookArchivist:DebugPrint("[BookArchivist] flushPendingRefresh: UI missing")
		return
	end

	if not isInitialized then
		BookArchivist:DebugPrint("[BookArchivist] flushPendingRefresh: UI not initialized")
		return
	end

	BookArchivist:DebugPrint("[BookArchivist] flushPendingRefresh: running refreshAll")
	BookArchivist:DebugMessage("|cFFFFFF00BookArchivist UI refreshing...|r")

	local refreshFn = Internal.refreshAll
	if not refreshFn then
		BookArchivist:DebugPrint("[BookArchivist] flushPendingRefresh: refresh handler missing")
		return
	end

	refreshFn()
end
Internal.flushPendingRefresh = flushPendingRefresh

local function formatZoneText(chain)
	if not chain or #chain == 0 then
		local L = BookArchivist and BookArchivist.L or {}
		return (L and L["LOCATION_UNKNOWN_ZONE"]) or "Unknown Zone"
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
		local L = BookArchivist and BookArchivist.L or {}
		local mob = loc.mobName or ((L and L["LOCATION_UNKNOWN_MOB"]) or "Unknown Mob")
		local label = (L and L["LOCATION_LOOTED_LABEL"]) or "Looted:"
		return string.format("|cFFFFD100%s|r %s > %s", label, zoneText, mob)
	end

	local L = BookArchivist and BookArchivist.L or {}
	local label = (L and L["LOCATION_LOCATION_LABEL"]) or "Location:"
	return string.format("|cFFFFD100%s|r %s", label, zoneText)
end
Internal.formatLocationLine = formatLocationLine

local gridOverlay = {
	targets = {},
	outlines = {},
	visible = false,
}

local function createGridOutline(frame)
	if not frame or not frame.CreateTexture then
		return nil
	end
	local color = { 0, 0.85, 1, 0.6 }
	local thickness = 1
	local segments = {}
	local function addSegment()
		local tex = frame:CreateTexture(nil, "OVERLAY", nil, 7)
		tex:SetColorTexture(color[1], color[2], color[3], color[4])
		tex:Hide()
		table.insert(segments, tex)
		return tex
	end
	local top = addSegment()
	top:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
	top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
	top:SetHeight(thickness)
	local bottom = addSegment()
	bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
	bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
	bottom:SetHeight(thickness)
	local left = addSegment()
	left:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
	left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -1, -1)
	left:SetWidth(thickness)
	local right = addSegment()
	right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 1)
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
	right:SetWidth(thickness)
	return { frame = frame, segments = segments }
end

local function ensureGridOutline(name)
	local target = gridOverlay.targets[name]
	if not target then
		return nil
	end
	local outline = gridOverlay.outlines[name]
	if outline and outline.frame ~= target then
		for _, tex in ipairs(outline.segments) do
			tex:Hide()
			tex:SetParent(nil)
		end
		outline = nil
	end
	if not outline then
		outline = createGridOutline(target)
		gridOverlay.outlines[name] = outline
	end
	return outline
end

local function applyGridVisibility(name, visible)
	local outline = visible and ensureGridOutline(name) or gridOverlay.outlines[name]
	if not outline then
		return
	end
	for _, tex in ipairs(outline.segments) do
		if visible then
			tex:Show()
		else
			tex:Hide()
		end
	end
end

function Internal.registerGridTarget(name, frame)
	if not name or not frame then
		return
	end
	gridOverlay.targets[name] = frame
	if gridOverlay.visible then
		applyGridVisibility(name, true)
	else
		local outline = gridOverlay.outlines[name]
		if outline then
			for _, tex in ipairs(outline.segments) do
				tex:Hide()
			end
		end
	end
end

function Internal.setGridOverlayVisible(state)
	local allow = true
	if state and (not BookArchivistDB or not BookArchivistDB.options or not BookArchivistDB.options.uiDebug) then
		allow = false
	end
	gridOverlay.visible = (state and allow) and true or false
	for name in pairs(gridOverlay.targets) do
		applyGridVisibility(name, gridOverlay.visible)
	end
end

function Internal.toggleGridOverlay()
	Internal.setGridOverlayVisible(not gridOverlay.visible)
	return gridOverlay.visible
end

function Internal.getGridOverlayVisible()
	return gridOverlay.visible
end

