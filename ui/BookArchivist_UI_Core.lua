---@diagnostic disable: undefined-global, undefined-field
local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal
local ListUI = Internal.ListUI
local ReaderUI = Internal.ReaderUI

local function logError(message)
	local formatted = "|cFFFF0000BookArchivist:|r " .. (message or "Unknown error")
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(formatted)
	elseif print then
		print(formatted)
	end
end
Internal.logError = logError

local function chatMessage(msg)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	elseif type(print) == "function" then
		print(msg)
	end
end
Internal.chatMessage = chatMessage

local function pullDebugPreference()
	if addonRoot and type(addonRoot.IsDebugEnabled) == "function" then
		local ok, value = pcall(addonRoot.IsDebugEnabled, addonRoot)
		if ok then
			return value and true or false
		end
	end
	return false
end

local DEBUG_LOGGING = pullDebugPreference()

local function debugMessage(msg)
	if DEBUG_LOGGING then
		chatMessage(msg)
	end
end
Internal.debugMessage = debugMessage

local function debugPrint(...)
	if not DEBUG_LOGGING then
		return
	end
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	chatMessage(table.concat(parts, " "))
end
Internal.debugPrint = debugPrint

function addonRoot.EnableDebugLogging(state, skipPersist)
	DEBUG_LOGGING = state and true or false
	if not skipPersist and type(addonRoot.SetDebugEnabled) == "function" then
		addonRoot:SetDebugEnabled(DEBUG_LOGGING)
		return
	end
	if DEBUG_LOGGING then
		chatMessage("|cFF00FF00BookArchivist debug logging enabled.|r")
		if type(addonRoot.RefreshUI) == "function" then
			addonRoot.RefreshUI()
		end
	else
		chatMessage("|cFFFFA000BookArchivist debug logging disabled.|r")
	end
end

local function captureError(err)
	if type(debugstack) == "function" then
		local stack = debugstack(2, 8, 8)
		if stack and stack ~= "" then
			return string.format("%s\n%s", tostring(err), stack)
		end
	end
	return tostring(err)
end

local function safeStep(label, fn)
	local ok, err = xpcall(fn, captureError)
	if not ok then
		logError(string.format("%s failed: %s", label, err))
	end
	return ok
end
Internal.safeStep = safeStep

Internal.safeCreateFrame = function(frameType, name, parent, ...)
	if not CreateFrame then
		logError(string.format("CreateFrame missing; unable to build '%s'", name or frameType))
		return nil
	end

	local templates = { ... }
	local lastErr
	for i = 1, #templates do
		local template = templates[i]
		if template then
			local ok, frameOrErr = pcall(CreateFrame, frameType, name, parent, template)
			if ok and frameOrErr then
				return frameOrErr
			elseif not ok then
				lastErr = frameOrErr
			end
		end
	end

	local ok, frameOrErr = pcall(CreateFrame, frameType, name, parent)
	if ok and frameOrErr then
		return frameOrErr
	end

	lastErr = lastErr or frameOrErr or "unknown failure"
	logError(string.format("Unable to create frame '%s' (%s). %s", name or "unnamed", frameType, tostring(lastErr)))
	return nil
end

local listModuleContext

local function initializeModules()
	if ListUI and ListUI.Init then
		listModuleContext = {
			getAddon = Internal.getAddon,
			getWidget = Internal.getWidget,
			rememberWidget = Internal.rememberWidget,
			safeCreateFrame = Internal.safeCreateFrame,
			setSelectedKey = Internal.setSelectedKey,
			getSelectedKey = Internal.getSelectedKey,
			getFilteredKeys = Internal.getFilteredKeys,
			getListMode = Internal.getListMode,
			setListMode = Internal.setListMode,
			listModes = Internal.listModes,
			fmtTime = Internal.fmtTime,
			formatLocationLine = Internal.formatLocationLine,
			debugPrint = debugPrint,
			logError = logError,
			debugMessage = debugMessage,
			getUIFrame = Internal.getUIFrame,
			getSortMode = function()
				local addon = Internal.getAddon()
				if addon and addon.GetListSortMode then
					return addon:GetListSortMode()
				end
			end,
			setSortMode = function(mode)
				local addon = Internal.getAddon()
				if addon and addon.SetListSortMode then
					addon:SetListSortMode(mode)
				end
			end,
			getPageSize = function()
				local addon = Internal.getAddon()
				if addon and addon.GetListPageSize then
					return addon:GetListPageSize()
				end
				return nil
			end,
			setPageSize = function(size)
				local addon = Internal.getAddon()
				if addon and addon.SetListPageSize then
					addon:SetListPageSize(size)
				end
			end,
			getFilters = function()
				local addon = Internal.getAddon()
				if addon and addon.GetListFilters then
					return addon:GetListFilters()
				end
				return nil
			end,
			setFilter = function(filterKey, state)
				local addon = Internal.getAddon()
				if addon and addon.SetListFilter then
					addon:SetListFilter(filterKey, state)
				end
			end,
		}
		ListUI:Init(listModuleContext)
	end

	if ReaderUI and ReaderUI.Init then
		ReaderUI:Init({
			getAddon = Internal.getAddon,
			getWidget = Internal.getWidget,
			rememberWidget = Internal.rememberWidget,
			safeCreateFrame = Internal.safeCreateFrame,
			getSelectedKey = Internal.getSelectedKey,
			setSelectedKey = Internal.setSelectedKey,
			fmtTime = Internal.fmtTime,
			formatLocationLine = Internal.formatLocationLine,
			debugPrint = debugPrint,
			logError = logError,
			chatMessage = chatMessage,
			getUIFrame = Internal.getUIFrame,
		})
	end

	if listModuleContext and ReaderUI then
		listModuleContext.disableDeleteButton = function()
			if ReaderUI.DisableDeleteButton then
				ReaderUI:DisableDeleteButton()
			end
		end
		listModuleContext.onSelectionChanged = function()
			if ReaderUI.RenderSelected then
				ReaderUI:RenderSelected()
			end
		end
	end
end

initializeModules()

local function rebuildFiltered()
	if ListUI and ListUI.RebuildFiltered then
		return ListUI:RebuildFiltered()
	end
end
Internal.rebuildFiltered = rebuildFiltered

local function renderSelected()
	if ReaderUI and ReaderUI.RenderSelected then
		return ReaderUI:RenderSelected()
	end
end
Internal.renderSelected = renderSelected

local function updateList()
	if ListUI and ListUI.UpdateList then
		return ListUI:UpdateList()
	end
end
Internal.updateList = updateList
