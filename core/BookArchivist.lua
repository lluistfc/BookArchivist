---@diagnostic disable: undefined-global
-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}

-- CRITICAL: Core modules MUST be resolved at runtime (not file load time)
-- TOC loads this file before BookArchivist_Core.lua, so BookArchivist.Core is nil at load time.
-- NEVER use: local Core = BookArchivist.Core (captures nil permanently)
-- ALWAYS use: if BookArchivist.Core and BookArchivist.Core.Method then ... (runtime resolution)

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
	local BA = BookArchivist
	if BA.Core and BA.Core.IsDebugEnabled then
		return BA.Core:IsDebugEnabled()
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
	
	-- Initialize Repository with current DB state (may be nil on fresh install)
	-- Repository's GetDB() will return nil, which Core:GetDB() handles via ensureDB() fallback
	if BookArchivist.Repository and BookArchivist.Repository.Init then
		BookArchivist.Repository:Init(BookArchivistDB)
	end

	-- EnsureDB handles fresh installs, migrations, and corruption detection
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
		local BA = BookArchivist
		if BA.Capture and BA.Capture.OnBegin then
			BA.Capture:OnBegin()
		end
	elseif event == "ITEM_TEXT_READY" then
		local BA = BookArchivist
		if BA.Capture and BA.Capture.OnReady then
			BA.Capture:OnReady()
		end
	elseif event == "ITEM_TEXT_CLOSED" then
		local BA = BookArchivist
		if BA.Capture and BA.Capture.OnClosed then
			BA.Capture:OnClosed()
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
	local BA = BookArchivist
	if BA.Core and BA.Core.CreateCustomBook then
		return BA.Core:CreateCustomBook(title, pages, location)
	end
	return nil
end

function BookArchivist:IsTooltipEnabled()
	local BA = BookArchivist
	if BA.Core and BA.Core.IsTooltipEnabled then
		return BA.Core:IsTooltipEnabled()
	end
	local db = self:GetDB() or {}
	local opts = db.options or {}
	if opts.tooltip == nil then
		return true
	end
	return opts.tooltip and true or false
end

function BookArchivist:SetTooltipEnabled(state)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetTooltipEnabled then
		BA.Core:SetTooltipEnabled(state)
	else
		local db = self:GetDB() or {}
		db.options = db.options or {}
		db.options.tooltip = state and true or false
	end
end

function BookArchivist:IsResumeLastPageEnabled()
	local BA = BookArchivist
	if BA.Core and BA.Core.IsResumeLastPageEnabled then
		return BA.Core:IsResumeLastPageEnabled()
	end
	return true
end

function BookArchivist:SetResumeLastPageEnabled(state)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetResumeLastPageEnabled then
		BA.Core:SetResumeLastPageEnabled(state)
	end
	syncOptionsUI()
end

function BookArchivist:GetListPageSize()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetListPageSize then
		return BA.Core:GetListPageSize()
	end
	return 25
end

function BookArchivist:SetListPageSize(size)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetListPageSize then
		BA.Core:SetListPageSize(size)
	end
end

function BookArchivist:GetListSortMode()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetSortMode then
		return BA.Core:GetSortMode()
	end
	return "lastSeen"
end

function BookArchivist:SetListSortMode(mode)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetSortMode then
		BA.Core:SetSortMode(mode)
	end
end

function BookArchivist:ExportLibrary()
	local BA = BookArchivist
	if BA.Core and BA.Core.ExportToString then
		return BA.Core:ExportToString()
	end
	return nil, "export unavailable"
end

function BookArchivist:GetListFilters()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetListFilters then
		return BA.Core:GetListFilters()
	end
	return {}
end

function BookArchivist:SetListFilter(filterKey, state)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetListFilter then
		BA.Core:SetListFilter(filterKey, state)
	end
end

function BookArchivist:IsVirtualCategoriesEnabled()
	local BA = BookArchivist
	if BA.Core and BA.Core.IsVirtualCategoriesEnabled then
		return BA.Core:IsVirtualCategoriesEnabled()
	end
	return true
end

function BookArchivist:GetLastCategoryId()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetLastCategoryId then
		return BA.Core:GetLastCategoryId()
	end
	return "__all__"
end

function BookArchivist:SetLastCategoryId(categoryId)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetLastCategoryId then
		BA.Core:SetLastCategoryId(categoryId)
	end
end

function BookArchivist:GetLastBookId()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetLastBookId then
		return BA.Core:GetLastBookId()
	end
	return nil
end

function BookArchivist:SetLastBookId(bookId)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetLastBookId then
		BA.Core:SetLastBookId(bookId)
	end
end

function BookArchivist:GetLanguage()
	local BA = BookArchivist
	if BA.Core and BA.Core.GetLanguage then
		return BA.Core:GetLanguage()
	end
	return "enUS"
end

function BookArchivist:SetLanguage(lang)
	local BA = BookArchivist
	if BA.Core and BA.Core.SetLanguage then
		BA.Core:SetLanguage(lang)
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
