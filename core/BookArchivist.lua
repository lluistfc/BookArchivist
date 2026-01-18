---@diagnostic disable: undefined-global
-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}

-- Core modules resolve at runtime (not load time) due to TOC load order

-- Debug log storage (available before UI loads)
local debugLog = {}
local MAX_DEBUG_LOG_ENTRIES = 5000

-- Guard to prevent circular dependency during DB initialization
local isInitializing = false

local function storeDebugMessage(msg)
	table.insert(debugLog, {
		timestamp = time(),
		message = msg,
	})
	if #debugLog > MAX_DEBUG_LOG_ENTRIES then
		table.remove(debugLog, 1)
	end
end

local function chatMessage(msg)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	elseif type(print) == "function" then
		print(msg)
	end
end

-- Production-safe wrapper for debug state
-- DevTools may override this; otherwise delegates to Core
function BookArchivist:IsDebugEnabled()
	-- Prevent circular dependency during DB initialization
	if isInitializing then
		return false
	end
	if Core and Core.IsDebugEnabled then
		return Core:IsDebugEnabled()
	end
	return false
end

function BookArchivist:DebugPrint(...)
	if not self:IsDebugEnabled() then
		return
	end
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end
	local msg = table.concat(parts, " ")
	storeDebugMessage(msg)
	chatMessage(msg)
end

function BookArchivist:DebugMessage(msg)
	if not self:IsDebugEnabled() then
		return
	end
	storeDebugMessage(msg)
	chatMessage(msg)
end

function BookArchivist:GetDebugLog()
	return debugLog
end

function BookArchivist:ClearDebugLog()
	debugLog = {}
end

function BookArchivist:LogError(...)
	-- Try UI.Internal first for compatibility, fallback to simple error
	local ui = self.UI
	local internal = ui and ui.Internal
	if internal and type(internal.logError) == "function" then
		return internal.logError(...)
	end
	error(tostring(select(1, ...)) or "Unknown error", 2)
end

local globalCreateFrame = type(_G) == "table" and rawget(_G, "CreateFrame") or nil
local function createFrameShim(...)
	if globalCreateFrame then
		return globalCreateFrame(...)
	end

	local dummy = {}
	function dummy:RegisterEvent(...) end
	function dummy:SetScript(...) end
	return dummy
end

BookArchivist.__createFrame = createFrameShim

local function getOptionsUI()
	if not BookArchivist.UI then
		return nil
	end
	return BookArchivist.UI.Options
end

local function syncOptionsUI(newLang)
	local optionsUI = getOptionsUI()
	if optionsUI and optionsUI.Sync then
		optionsUI:Sync(newLang)
	end
end

local eventFrame = createFrameShim("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ITEM_TEXT_BEGIN")
eventFrame:RegisterEvent("ITEM_TEXT_READY")
eventFrame:RegisterEvent("ITEM_TEXT_CLOSED")
-- Simplified: treat all captures as item text books only

local function handleAddonLoaded(name)
	if name ~= ADDON_NAME then
		return
	end

	-- Set initialization guard to prevent circular dependency
	isInitializing = true
	
	-- DEBUG: Check SavedVariables loaded
	BookArchivist:DebugPrint("[BookArchivist] ADDON_LOADED: BookArchivistDB exists:", BookArchivistDB ~= nil)
	if BookArchivistDB then
		local orderCount = BookArchivistDB.order and #BookArchivistDB.order or 0
		local booksCount = 0
		if BookArchivistDB.booksById then
			for _ in pairs(BookArchivistDB.booksById) do
				booksCount = booksCount + 1
			end
		end
		BookArchivist:DebugPrint("[BookArchivist] ADDON_LOADED: order count:", orderCount, "booksById count:", booksCount)
	end
	
	-- Initialize Repository early (before EnsureDB needs it)
	-- Start with nil, EnsureDB will create/migrate the actual DB
	if BookArchivist.Repository and BookArchivist.Repository.Init then
		BookArchivist.Repository:Init(BookArchivistDB)
	end

	if BookArchivist.Core and BookArchivist.Core.EnsureDB then
		BookArchivist.Core:EnsureDB()
	end
	
	-- DEBUG: Check after EnsureDB
	if BookArchivistDB then
		local orderCount = BookArchivistDB.order and #BookArchivistDB.order or 0
		local booksCount = 0
		if BookArchivistDB.booksById then
			for _ in pairs(BookArchivistDB.booksById) do
				booksCount = booksCount + 1
			end
		end
		BookArchivist:DebugPrint("[BookArchivist] After EnsureDB: order count:", orderCount, "booksById count:", booksCount)
	end
	
	-- Re-initialize Repository with the ensured/migrated database
	if BookArchivist.Repository and BookArchivist.Repository.Init then
		BookArchivist.Repository:Init(BookArchivistDB)
	end

	-- Clear initialization guard after DB is ready
	isInitializing = false

	-- Initialize debug logging state from DB
	if type(BookArchivist.EnableDebugLogging) == "function" and BookArchivist.Core and BookArchivist.Core.IsDebugEnabled then
		local debugEnabled = BookArchivist.Core:IsDebugEnabled()
		BookArchivist.EnableDebugLogging(debugState, true)
	end

	local optionsUI = getOptionsUI()
	if optionsUI and optionsUI.OnAddonLoaded then
		optionsUI:OnAddonLoaded(name)
	end
	if BookArchivist.Minimap and BookArchivist.Minimap.Initialize then
		BookArchivist.Minimap:Initialize()
	end
	if BookArchivist.Tooltip and BookArchivist.Tooltip.Initialize then
		BookArchivist.Tooltip:Initialize()
	end
	if BookArchivist.ChatLinks and BookArchivist.ChatLinks.Init then
		BookArchivist.ChatLinks:Init()
	end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		handleAddonLoaded(...)
		return
	end

	if event == "ITEM_TEXT_BEGIN" then
		if Capture and Capture.OnBegin then
			Capture:OnBegin()
		end
	elseif event == "ITEM_TEXT_READY" then
		if Capture and Capture.OnReady then
			Capture:OnReady()
		end
	elseif event == "ITEM_TEXT_CLOSED" then
		if Capture and Capture.OnClosed then
			Capture:OnClosed()
		end
	end
end)

function BookArchivist:GetDB()
	if BookArchivist.Core and BookArchivist.Core.GetDB then
		return BookArchivist.Core:GetDB()
	end
	self:DebugPrint("[BookArchivist] GetDB: Core not available, returning empty table")
	return {}
end

function BookArchivist:ExportBook(bookId)
	if BookArchivist.Core and BookArchivist.Core.ExportBookToString then
		return BookArchivist.Core:ExportBookToString(bookId)
	end
	return nil, "export unavailable"
end

function BookArchivist:Delete(key)
	if BookArchivist.Core and BookArchivist.Core.Delete then
		BookArchivist.Core:Delete(key)
	else
		if BookArchivist and BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[BookArchivist] Delete: Core or Core.Delete is nil!")
		end
	end
	if type(self.RefreshUI) == "function" then
		self:RefreshUI()
	end
end

-- Create a new custom (player-authored) book.
-- This does not edit or mutate captured books.
function BookArchivist:CreateCustomBook(title, pages, location)
	if Core and Core.CreateCustomBook then
		return Core:CreateCustomBook(title, pages, location)
	end
	return nil
end

function BookArchivist:IsTooltipEnabled()
	if Core and Core.IsTooltipEnabled then
		return Core:IsTooltipEnabled()
	end
	local db = self:GetDB() or {}
	local opts = db.options or {}
	if opts.tooltip == nil then
		return true
	end
	return opts.tooltip and true or false
end

function BookArchivist:SetTooltipEnabled(state)
	if Core and Core.SetTooltipEnabled then
		Core:SetTooltipEnabled(state)
	else
		local db = self:GetDB() or {}
		db.options = db.options or {}
		db.options.tooltip = state and true or false
	end
end

function BookArchivist:IsResumeLastPageEnabled()
	if Core and Core.IsResumeLastPageEnabled then
		return Core:IsResumeLastPageEnabled()
	end
	return true
end

function BookArchivist:SetResumeLastPageEnabled(state)
	if Core and Core.SetResumeLastPageEnabled then
		Core:SetResumeLastPageEnabled(state)
	end
	syncOptionsUI()
end

function BookArchivist:GetListPageSize()
	if Core and Core.GetListPageSize then
		return Core:GetListPageSize()
	end
	return 25
end

function BookArchivist:SetListPageSize(size)
	if Core and Core.SetListPageSize then
		Core:SetListPageSize(size)
	end
end

function BookArchivist:GetListSortMode()
	if Core and Core.GetSortMode then
		return Core:GetSortMode()
	end
	return "lastSeen"
end

function BookArchivist:SetListSortMode(mode)
	if Core and Core.SetSortMode then
		Core:SetSortMode(mode)
	end
end

function BookArchivist:ExportLibrary()
	if Core and Core.ExportToString then
		return Core:ExportToString()
	end
	return nil, "export unavailable"
end

function BookArchivist:GetListFilters()
	if Core and Core.GetListFilters then
		return Core:GetListFilters()
	end
	return {}
end

function BookArchivist:SetListFilter(filterKey, state)
	if Core and Core.SetListFilter then
		Core:SetListFilter(filterKey, state)
	end
end

function BookArchivist:IsVirtualCategoriesEnabled()
	if Core and Core.IsVirtualCategoriesEnabled then
		return Core:IsVirtualCategoriesEnabled()
	end
	return true
end

function BookArchivist:GetLastCategoryId()
	if Core and Core.GetLastCategoryId then
		return Core:GetLastCategoryId()
	end
	return "__all__"
end

function BookArchivist:SetLastCategoryId(categoryId)
	if Core and Core.SetLastCategoryId then
		Core:SetLastCategoryId(categoryId)
	end
end

function BookArchivist:GetLastBookId()
	if Core and Core.GetLastBookId then
		return Core:GetLastBookId()
	end
	return nil
end

function BookArchivist:SetLastBookId(bookId)
	if Core and Core.SetLastBookId then
		Core:SetLastBookId(bookId)
	end
end

function BookArchivist:GetLanguage()
	if Core and Core.GetLanguage then
		return Core:GetLanguage()
	end
	return "enUS"
end

function BookArchivist:SetLanguage(lang)
	if Core and Core.SetLanguage then
		Core:SetLanguage(lang)
	end
	local internal = self.UI and self.UI.Internal
	if internal and internal.rebuildUIForLanguageChange then
		internal.rebuildUIForLanguageChange()
	elseif type(self.RefreshUI) == "function" then
		self:RefreshUI()
	end
	syncOptionsUI(lang)
end

function BookArchivist:OpenOptionsPanel()
	local optionsUI = getOptionsUI()
	if optionsUI and optionsUI.Open then
		optionsUI:Open()
	end
end

function BookArchivist_ToggleFromCompartment()
	if BookArchivist and type(BookArchivist.ToggleUI) == "function" then
		BookArchivist:ToggleUI()
	end
end
