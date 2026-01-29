---@diagnostic disable: undefined-global, undefined-field
local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal
local ListUI = Internal.ListUI
local ReaderUI = Internal.ReaderUI

local function logError(message)
	-- Disabled: Let errors propagate to BugSack instead of printing to chat
	-- local formatted = "|cFFFF0000BookArchivist:|r " .. (message or "Unknown error")
	-- if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
	-- 	DEFAULT_CHAT_FRAME:AddMessage(formatted)
	-- elseif print then
	-- 	print(formatted)
	-- end

	-- Re-throw the error so BugSack can catch it
	error(message or "Unknown error", 2)
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

-- Debug functions now delegate to BookArchivist core
local function debugMessage(msg)
	if addonRoot and addonRoot.DebugMessage then
		addonRoot:DebugMessage(msg)
	end
end
Internal.debugMessage = debugMessage

local function debugPrint(...)
	if addonRoot and addonRoot.DebugPrint then
		addonRoot:DebugPrint(...)
	end
end
Internal.debugPrint = debugPrint

function Internal.getDebugLog()
	if addonRoot and addonRoot.GetDebugLog then
		return addonRoot:GetDebugLog()
	end
	return {}
end

function Internal.clearDebugLog()
	if addonRoot and addonRoot.ClearDebugLog then
		addonRoot:ClearDebugLog()
	end
end

function addonRoot.EnableDebugLogging(state, skipPersist)
	-- Clear log when disabling debug mode
	if not state and addonRoot and addonRoot.ClearDebugLog then
		addonRoot:ClearDebugLog()
	end
	if not skipPersist and addonRoot.SetDebugEnabled then
		addonRoot:SetDebugEnabled(DEBUG_LOGGING)
		return
	end
	-- If skipPersist is true, we're during initialization - just set the state silently
	if skipPersist then
		return
	end
	if DEBUG_LOGGING then
		chatMessage("|cFF00FF00BookArchivist debug logging enabled.|r")
		if addonRoot.RefreshUI then
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
				local BA = Internal.getAddon()
				if BA and BA.GetListSortMode then
					return BA:GetListSortMode()
				end
			end,
			setSortMode = function(mode)
				local BA = Internal.getAddon()
				if BA and BA.SetListSortMode then
					BA:SetListSortMode(mode)
				end
			end,
			getPageSize = function()
				local BA = Internal.getAddon()
				if BA and BA.GetListPageSize then
					return BA:GetListPageSize()
				end
				return nil
			end,
			setPageSize = function(size)
				local BA = Internal.getAddon()
				if BA and BA.SetListPageSize then
					BA:SetListPageSize(size)
				end
			end,
			getFilters = function()
				local BA = Internal.getAddon()
				if BA and BA.GetListFilters then
					return BA:GetListFilters()
				end
				return nil
			end,
			setFilter = function(filterKey, state)
				local BA = Internal.getAddon()
				if BA and BA.SetListFilter then
					BA:SetListFilter(filterKey, state)
				end
			end,
			getCategoryId = function()
				local BA = Internal.getAddon()
				if BA and BA.GetLastCategoryId then
					return BA:GetLastCategoryId()
				end
				return "__all__"
			end,
			setCategoryId = function(categoryId)
				local BA = Internal.getAddon()
				if BA then
					if BA.DebugPrint then
						BA:DebugPrint(string.format("[UI_Core.setCategoryId] called with '%s'", tostring(categoryId)))
					end
					if BA.SetLastCategoryId then
						BA:SetLastCategoryId(categoryId)
					else
						if BA.LogError then
							BA:LogError("[UI_Core] ERROR: BA.SetLastCategoryId is nil!")
						end
					end
				else
					if debugPrint then
						debugPrint("[UI_Core] ERROR: BA is nil in setCategoryId!")
					end
				end
			end,
			isVirtualCategoriesEnabled = function()
				local BA = Internal.getAddon()
				if BA and BA.IsVirtualCategoriesEnabled then
					return BA:IsVirtualCategoriesEnabled()
				end
				return true
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

-- ============================================================================
-- Page Navigation (for keybindings / accessibility)
-- ============================================================================

local function navigatePageNext()
	if ReaderUI and ReaderUI.ChangePage then
		ReaderUI:ChangePage(1)
	end
end
Internal.navigatePageNext = navigatePageNext

local function navigatePagePrev()
	if ReaderUI and ReaderUI.ChangePage then
		ReaderUI:ChangePage(-1)
	end
end
Internal.navigatePagePrev = navigatePagePrev
