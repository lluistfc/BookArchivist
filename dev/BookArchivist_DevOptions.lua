---@diagnostic disable: undefined-global
-- BookArchivist_DevOptions.lua
-- Development-only UI options (debug checkbox)
-- This file is NOT loaded in production releases

local BA = BookArchivist
BA.DevTools = BA.DevTools or {}

local DevTools = BA.DevTools

-- ============================================================================
-- DEV OPTIONS UI INTEGRATION
-- ============================================================================

local function L(key)
	local t = BookArchivist and BookArchivist.L
	return (t and t[key]) or key
end

local function EnsureDB()
	BookArchivistDB = BookArchivistDB or {}
	BookArchivistDB.options = BookArchivistDB.options or {}
	return BookArchivistDB
end

-- Initialize debug options in database if needed
local function ensureDebugOptions()
	local db = EnsureDB()
	if db.options.debug == nil then
		db.options.debug = false
	end
	if db.options.uiDebug == nil then
		db.options.uiDebug = false
	end
	if db.options.gridVisible == nil then
		db.options.gridVisible = false
	end
	if db.options.echoRefreshOnRead == nil then
		db.options.echoRefreshOnRead = false
	end
end

-- ============================================================================
-- CORE FUNCTION OVERRIDES (for compatibility with production code)
-- ============================================================================

-- Provide Core functions that production expects but no longer has
if BookArchivist.Core then
	local Core = BookArchivist.Core

	function Core:IsDebugEnabled()
		local db = EnsureDB()
		-- Read from the actual saved variable that the Settings UI uses
		if db.options.debug ~= nil then
			return db.options.debug and true or false
		end
		-- Fallback to old key for migration
		return db.options.debugEnabled and true or false
	end

	function Core:SetDebugEnabled(state)
		local db = EnsureDB()
		-- Save to both keys for compatibility
		db.options.debug = state and true or false
		db.options.debugEnabled = state and true or false
	end

	function Core:IsUIDebugEnabled()
		local db = EnsureDB()
		return db.options.uiDebug and true or false
	end

	function Core:SetUIDebugEnabled(state)
		local db = EnsureDB()
		db.options.uiDebug = state and true or false
	end
end

-- Provide main addon functions that production expects but no longer has
local function syncOptionsUI()
	local optionsUI = BookArchivist.UI and BookArchivist.UI.Options
	if optionsUI and optionsUI.Sync then
		optionsUI:Sync()
	end
end

function BookArchivist:IsDebugEnabled()
	local Core = BookArchivist.Core
	if Core and Core.IsDebugEnabled then
		return Core:IsDebugEnabled()
	end
	return false
end

function BookArchivist:SetDebugEnabled(state)
	local Core = BookArchivist.Core
	if Core and Core.SetDebugEnabled then
		Core:SetDebugEnabled(state)
	end
	syncOptionsUI()
end

function BookArchivist:IsUIDebugEnabled()
	local Core = BookArchivist.Core
	if Core and Core.IsUIDebugEnabled then
		return Core:IsUIDebugEnabled()
	end
	local db = self:GetDB() or {}
	local opts = db.options or {}
	return opts.uiDebug and true or false
end

function BookArchivist:SetUIDebugEnabled(state)
	local Core = BookArchivist.Core
	if Core and Core.SetUIDebugEnabled then
		Core:SetUIDebugEnabled(state)
	else
		local db = self:GetDB() or {}
		db.options = db.options or {}
		db.options.uiDebug = state and true or false
	end

	local internal = self.UI and self.UI.Internal
	if internal and internal.setGridOverlayVisible then
		internal.setGridOverlayVisible(state and true or false)
	end

	syncOptionsUI()
end

-- ============================================================================
-- SETTINGS UI INJECTION
-- ============================================================================

local function InjectDebugSettingIntoOptionsPanel()
	-- Wait for addon to fully load and Settings API to be available
	if not BookArchivist or not BookArchivist.UI or not BookArchivist.UI.Options then
		return
	end

	if not Settings or not Settings.RegisterAddOnSetting then
		return
	end

	-- Find the BookArchivist category
	local category = BookArchivist.UI.Options.GetCategory and BookArchivist.UI.Options:GetCategory()
	if not category then
		-- Try to find it by name
		if Settings.GetCategory then
			category = Settings.GetCategory(L("ADDON_TITLE"))
		end
	end

	if not category then
		return
	end

	ensureDebugOptions()

	local db = BookArchivistDB

	-- Ensure gridMode setting exists
	if not db.options.gridMode then
		db.options.gridMode = "border"
	end

	-- Register debug checkbox
	do
		local variable = "debug"
		local variableKey = variable
		local variableTbl = BookArchivistDB.options
		local defaultValue = false
		local name = L("OPTIONS_DEBUG_LABEL") or "Enable Debug Mode"

		local setting =
			Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, "boolean", name, defaultValue)

		Settings.CreateCheckbox(
			category,
			setting,
			L("OPTIONS_DEBUG_TOOLTIP") or "Enable debug logging and UI grid overlays (dev mode)"
		)

		-- The Settings API automatically updates variableTbl.debug
		-- We just need to apply the dev tools state when it changes
		-- Callback signature: function(callbackId, setting)
		Settings.SetOnValueChangedCallback(variableKey, function(callbackId, setting)
			-- Get the actual current value from the setting object
			local currentValue = setting:GetValue()
			local state = currentValue and true or false

			-- Debug mode only controls chat logging
			-- Grid visibility is controlled separately via /badev grid
			DevTools.EnableDebugChat(state)
		end)
	end

	-- Register echo refresh checkbox (for testing Book Echo)
	do
		local variable = "echoRefreshOnRead"
		local variableKey = variable
		local variableTbl = BookArchivistDB.options
		local defaultValue = false
		local name = "Refresh Echo on Each Read"

		local setting =
			Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, "boolean", name, defaultValue)

		Settings.CreateCheckbox(
			category,
			setting,
			"Force Book Echo to recalculate on every book view (for testing echo logic)"
		)

		Settings.SetOnValueChangedCallback(variableKey, function(callbackId, setting)
			local currentValue = setting:GetValue()
			-- Option is automatically persisted to variableTbl.echoRefreshOnRead
			-- Reader will check BookArchivistDB.options.echoRefreshOnRead AND BookArchivist.DevTools exists
		end)
	end

	-- Register reset read counts button (manual creation)
	local resetButton
	local function CreateResetButton()
		if resetButton then return end
		
		-- Find the settings panel container (the right side content area)
		local settingsPanel = SettingsPanel
		if not settingsPanel then return end
		
		-- Get the container that holds the actual settings content
		local container = settingsPanel.Container
		if not container then return end
		
		-- Create button manually (positioned to the right of echo checkbox)
		resetButton = CreateFrame("Button", "BookArchivistResetCountsButton", container, "UIPanelButtonTemplate")
		resetButton:SetSize(180, 22)
		resetButton:SetText("Reset All Read Counts")
		-- Position to the right of "Refresh Echo on Each Read" checkbox
		-- Need to account for production options above (tooltip, resume, language, import button, debug mode)
		-- Each takes ~40-50px, so echo checkbox is around Y=-270
		resetButton:SetPoint("TOPLEFT", container, "TOPLEFT", 280, -270)
		
		resetButton:SetScript("OnClick", function()
			StaticPopup_Show("BOOKARCHIVIST_CONFIRM_RESET_COUNTS")
		end)
		
		resetButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Reset All Read Counts", 1, 1, 1)
			GameTooltip:AddLine("Reset readCount, firstReadLocation, and lastPageRead for all books (for testing echo feature)", nil, nil, nil, true)
			GameTooltip:Show()
		end)
		
		resetButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	-- Hook into settings panel show to create button
	hooksecurefunc(SettingsPanel, "Show", CreateResetButton)

	-- Register grid mode dropdown
	do
		local variable = "gridMode"
		local variableKey = variable
		local variableTbl = BookArchivistDB.options
		local defaultValue = "none"
		local name = "Grid Display Mode"

		local setting =
			Settings.RegisterAddOnSetting(category, variable, variableKey, variableTbl, "string", name, defaultValue)

		local function GetOptions()
			local container = Settings.CreateControlTextContainer()
			container:Add("none", "None (Disabled)")
			container:Add("border", "Border Only")
			container:Add("fill", "Fill Only")
			container:Add("both", "Border + Fill")
			return container:GetData()
		end

		Settings.CreateDropdown(category, setting, GetOptions, "Controls how debug grid overlays are displayed")

		Settings.SetOnValueChangedCallback(variableKey, function(callbackId, setting)
			local mode = setting:GetValue()
			if DevTools.SetGridMode then
				DevTools.SetGridMode(mode)
			end
		end)
	end
end

-- ============================================================================
-- RESET READ COUNTS DIALOG
-- ============================================================================

StaticPopupDialogs["BOOKARCHIVIST_CONFIRM_RESET_COUNTS"] = {
	text = "Reset read counts for all books?\n\nThis will reset:\n• Read count\n• First read location\n• Last page read\n\nBook Echo will treat all books as unread.",
	button1 = "Reset All",
	button2 = "Cancel",
	OnAccept = function()
		local db = BookArchivist and BookArchivist.GetDB and BookArchivist:GetDB()
		if not db or not db.booksById then
			print("|cFFFF0000[BookArchivist]|r No database found.")
			return
		end
		
		local count = 0
		for bookId, book in pairs(db.booksById) do
			if type(book) == "table" then
				book.readCount = 0
				book.firstReadLocation = nil
				book.lastPageRead = nil
				book.lastReadAt = nil
				count = count + 1
			end
		end
		
		print(string.format("|cFF00FF00[BookArchivist]|r Reset read counts for %d books.", count))
		
		-- Refresh UI if it's open
		if BookArchivist.UI and BookArchivist.UI.Core and BookArchivist.UI.Core.RefreshUI then
			BookArchivist.UI.Core:RefreshUI()
		end
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

ensureDebugOptions()

-- Note: Dev tools state is initialized automatically when the Settings callback
-- fires during checkbox creation. No need for separate initialization.

-- Inject debug checkbox after a short delay to ensure Settings UI is loaded
C_Timer.After(0.5, function()
	InjectDebugSettingIntoOptionsPanel()
end)
