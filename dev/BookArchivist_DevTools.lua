---@diagnostic disable: undefined-global
-- BookArchivist_DevTools.lua
-- Development-only debugging tools
-- This file is NOT loaded in production releases
-- DO NOT include this in BookArchivist.toc

BookArchivist = BookArchivist or {}

-- ============================================================================
-- DEV TOOLS MODULE
-- ============================================================================

local DevTools = {}
BookArchivist.DevTools = DevTools

local debugChatEnabled = false
local gridOverlaysVisible = false
local gridOverlays = {}
local overlayFrame = nil -- Single high-strata frame for all overlays
local gridMode = "none" -- "none", "border", "fill", or "both"
local mainUIFrame = nil -- Reference to main BookArchivist frame
local debugModeButtons = {} -- Quick-access buttons for grid modes
local debugButtonContainer = nil -- Container frame for debug buttons
local isSettingGridMode = false -- Recursion guard for SetGridMode

-- Frame purpose descriptions for tooltips
local framePurposes = {
	["MainFrame"] = "The entire addon window with its outer border\n\nCode: ui/BookArchivist_UI_Frame_Layout.lua",
	["HeaderFrame"] = "The brown/gold top bar with 'Book Archivist' title and buttons (Help, Options, etc.)\n\nCode: ui/BookArchivist_UI_Frame.lua (CreateHeaderBar)",
	["BodyFrame"] = "Container holding both the left (cyan) and right (magenta) panels below the header\n\nCode: ui/BookArchivist_UI_Frame_Layout.lua (createContentLayout)",
	["ListInset"] = "The CYAN/TEAL panel frame on the left (includes decorative InsetFrameTemplate3 border)\n\nCode: ui/BookArchivist_UI_Frame_Layout.lua\nSearch: 'listInset = safeCreateFrame'",
	["ReaderInset"] = "The MAGENTA/PINK panel frame on the right (includes decorative InsetFrameTemplate3 border)\n\nCode: ui/BookArchivist_UI_Frame_Layout.lua\nSearch: 'readerInset = safeCreateFrame'",
	["listBlock"] = "The actual book list content area INSIDE the cyan panel (where book titles appear)\n\nCode: ui/list/BookArchivist_UI_List_Layout.lua",
	["readerBlock"] = "The actual book reader content area INSIDE the magenta panel (where book text is displayed)\n\nCode: ui/reader/BookArchivist_UI_Reader_Layout.lua",
}

-- Create a high-strata overlay frame that sits above everything
local function ensureOverlayFrame()
	if overlayFrame then
		return overlayFrame
	end

	overlayFrame = CreateFrame("Frame", nil, UIParent)
	overlayFrame:SetAllPoints(UIParent)
	overlayFrame:SetFrameStrata("TOOLTIP")
	overlayFrame:SetFrameLevel(9999)
	overlayFrame:EnableMouse(false)
	overlayFrame:Hide()

	return overlayFrame
end

-- ============================================================================
-- DEBUG CHAT LOGGING
-- ============================================================================

local function chatMessage(msg)
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	elseif type(print) == "function" then
		print(msg)
	end
end

function DevTools.EnableDebugChat(state)
	local previousState = debugChatEnabled
	debugChatEnabled = state and true or false

	-- Only show message if state changed
	if previousState ~= debugChatEnabled then
		if debugChatEnabled then
			chatMessage("|cFF00FF00[DEV] Debug chat logging enabled|r")
		else
			chatMessage("|cFFFFA000[DEV] Debug chat logging disabled|r")
		end
	end
end

function DevTools.IsDebugChatEnabled()
	return debugChatEnabled
end

function DevTools.DebugPrint(...)
	if not debugChatEnabled then
		return
	end

	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring(select(i, ...))
	end

	local msg = "|cFF888888[DEV]|r " .. table.concat(parts, " ")
	chatMessage(msg)
end

-- ============================================================================
-- UI GRID OVERLAY (Frame Highlighting)
-- ============================================================================

local function createGridOverlay(frame, r, g, b, label)
	if not frame or not frame.GetObjectType then
		return nil
	end

	local overlayParent = ensureOverlayFrame()

	-- Create a separate frame for this overlay
	local overlayRegion = CreateFrame("Frame", nil, overlayParent)
	overlayRegion:SetAllPoints(frame)
	overlayRegion:SetFrameStrata("HIGH") -- HIGH is below TOOLTIP
	overlayRegion:SetFrameLevel(9999)

	-- Create fill texture (for "fill" and "both" modes)
	local fill = overlayRegion:CreateTexture(nil, "BACKGROUND")
	fill:SetColorTexture(r or 1, g or 0, b or 0, 0.3)
	fill:SetAllPoints(overlayRegion)
	fill:Hide()

	-- Create border edges (for "border" and "both" modes)
	local thickness = 2
	local alpha = 0.8

	local edges = {}
	-- Top edge
	edges.top = overlayRegion:CreateTexture(nil, "OVERLAY")
	edges.top:SetColorTexture(r or 1, g or 0, b or 0, alpha)
	edges.top:SetPoint("TOPLEFT", overlayRegion, "TOPLEFT", 0, 0)
	edges.top:SetPoint("TOPRIGHT", overlayRegion, "TOPRIGHT", 0, 0)
	edges.top:SetHeight(thickness)
	edges.top:Hide()

	-- Bottom edge
	edges.bottom = overlayRegion:CreateTexture(nil, "OVERLAY")
	edges.bottom:SetColorTexture(r or 1, g or 0, b or 0, alpha)
	edges.bottom:SetPoint("BOTTOMLEFT", overlayRegion, "BOTTOMLEFT", 0, 0)
	edges.bottom:SetPoint("BOTTOMRIGHT", overlayRegion, "BOTTOMRIGHT", 0, 0)
	edges.bottom:SetHeight(thickness)
	edges.bottom:Hide()

	-- Left edge
	edges.left = overlayRegion:CreateTexture(nil, "OVERLAY")
	edges.left:SetColorTexture(r or 1, g or 0, b or 0, alpha)
	edges.left:SetPoint("TOPLEFT", overlayRegion, "TOPLEFT", 0, 0)
	edges.left:SetPoint("BOTTOMLEFT", overlayRegion, "BOTTOMLEFT", 0, 0)
	edges.left:SetWidth(thickness)
	edges.left:Hide()

	-- Right edge
	edges.right = overlayRegion:CreateTexture(nil, "OVERLAY")
	edges.right:SetColorTexture(r or 1, g or 0, b or 0, alpha)
	edges.right:SetPoint("TOPRIGHT", overlayRegion, "TOPRIGHT", 0, 0)
	edges.right:SetPoint("BOTTOMRIGHT", overlayRegion, "BOTTOMRIGHT", 0, 0)
	edges.right:SetWidth(thickness)
	edges.right:Hide()

	-- Create interactive label frame with tooltip support
	local labelFrame = nil
	local labelText = nil
	if label then
		labelFrame = CreateFrame("Frame", nil, overlayRegion)
		labelFrame:SetSize(120, 18)

		-- Position labels at different corners to avoid overlap
		local anchorPoint = "TOP"
		local xOffset = 0
		local yOffset = -2

		if label == "MainFrame" then
			anchorPoint = "TOP"
			xOffset = 0
			yOffset = -5
		elseif label == "HeaderFrame" then
			anchorPoint = "TOPLEFT"
			xOffset = 10
			yOffset = -10
		elseif label == "BodyFrame" then
			anchorPoint = "TOP"
			xOffset = 0
			yOffset = -40
		elseif label == "ListInset" then
			anchorPoint = "BOTTOMLEFT"
			xOffset = 10
			yOffset = 10
		elseif label == "listBlock" then
			anchorPoint = "BOTTOMLEFT"
			xOffset = 10
			yOffset = 30
		elseif label == "ReaderInset" then
			anchorPoint = "BOTTOMRIGHT"
			xOffset = -10
			yOffset = 10
		elseif label == "readerBlock" then
			anchorPoint = "BOTTOMRIGHT"
			xOffset = -10
			yOffset = 30
		end

		labelFrame:SetPoint(anchorPoint, overlayRegion, anchorPoint, xOffset, yOffset)
		labelFrame:SetFrameStrata("TOOLTIP") -- Labels at TOOLTIP level
		labelFrame:SetFrameLevel(100) -- Low level within TOOLTIP strata so GameTooltip appears above
		labelFrame:EnableMouse(true)
		labelFrame:Hide()

		labelText = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		labelText:SetText("|cFFFFFF00" .. label .. "|r")
		labelText:SetPoint("CENTER", labelFrame, "CENTER", 0, 0)

		-- Tooltip on hover with dynamic frame information
		labelFrame:SetScript("OnEnter", function(self)
			local purpose = framePurposes[label] or "Unknown frame"
			local targetFrame = frame -- Use the frame parameter that's in scope

			-- GameTooltip has its own backdrop system, don't try to set it manually
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(label, 1, 0.82, 0, true) -- Gold title
			GameTooltip:AddLine(purpose, 1, 1, 1, true) -- White description

			-- Add dynamic frame information
			if targetFrame then
				GameTooltip:AddLine(" ", 1, 1, 1) -- Spacer

				-- Size
				local width = targetFrame:GetWidth() or 0
				local height = targetFrame:GetHeight() or 0
				GameTooltip:AddDoubleLine("Size:", string.format("%.0f x %.0f", width, height), 0.7, 0.7, 0.7, 1, 1, 1)

				-- Strata and Level
				local strata = targetFrame:GetFrameStrata() or "UNKNOWN"
				local level = targetFrame:GetFrameLevel() or 0
				GameTooltip:AddDoubleLine("Strata:", strata, 0.7, 0.7, 0.7, 1, 1, 1)
				GameTooltip:AddDoubleLine("Level:", tostring(level), 0.7, 0.7, 0.7, 1, 1, 1)

				-- Object Type
				local objType = targetFrame:GetObjectType() or "Unknown"
				GameTooltip:AddDoubleLine("Type:", objType, 0.7, 0.7, 0.7, 1, 1, 1)

				-- Check for name (useful for debugging)
				local frameName = targetFrame:GetName()
				if frameName then
					GameTooltip:AddDoubleLine("Name:", frameName, 0.7, 0.7, 0.7, 0.5, 1, 0.5)
				end
			end

			GameTooltip:Show()
		end)

		labelFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	return {
		region = overlayRegion,
		fill = fill,
		edges = edges,
		labelFrame = labelFrame,
		labelText = labelText,
		label = label,
		frame = frame,
	}
end

function DevTools.RegisterFrameForDebug(frame, name, color)
	if not frame then
		return
	end

	local r, g, b = 1, 0, 0 -- default red
	if color == "green" then
		r, g, b = 0, 1, 0
	elseif color == "blue" then
		r, g, b = 0, 0, 1
	elseif color == "yellow" then
		r, g, b = 1, 1, 0
	elseif color == "cyan" then
		r, g, b = 0, 1, 1
	elseif color == "magenta" then
		r, g, b = 1, 0, 1
	end

	local overlay = createGridOverlay(frame, r, g, b, name)
	if overlay then
		overlay.description = description -- Store description for later use
		table.insert(gridOverlays, overlay)
		chatMessage("|cFF00FF00[DEV] Registered frame:|r " .. tostring(name))

		-- ALWAYS show overlays immediately if grid is enabled
		if gridOverlaysVisible then
			DevTools.UpdateOverlayVisibility(overlay)
			if overlay.labelFrame then
				overlay.labelFrame:Show()
			end
		end
	else
		chatMessage("|cFFFF0000[DEV] Failed to create overlay for " .. tostring(name) .. "|r")
	end
end

function DevTools.UpdateOverlayVisibility(overlay)
	if not overlay then
		return
	end

	-- If mode is 'none', hide everything including labels
	if gridMode == "none" then
		if overlay.edges then
			for _, edge in pairs(overlay.edges) do
				edge:Hide()
			end
		end
		if overlay.fill then
			overlay.fill:Hide()
		end
		if overlay.labelFrame then
			overlay.labelFrame:Hide()
		end
		return
	end

	-- Show/hide based on current mode
	if gridMode == "border" or gridMode == "both" then
		if overlay.edges then
			for _, edge in pairs(overlay.edges) do
				edge:Show()
			end
		end
	else
		if overlay.edges then
			for _, edge in pairs(overlay.edges) do
				edge:Hide()
			end
		end
	end

	if gridMode == "fill" or gridMode == "both" then
		if overlay.fill then
			overlay.fill:Show()
		end
	else
		if overlay.fill then
			overlay.fill:Hide()
		end
	end

	-- Show labels when any mode is active
	if overlay.labelFrame and gridMode ~= "none" then
		overlay.labelFrame:Show()
	end
end

function DevTools.SetGridMode(mode)
	-- Guard against recursion from Settings callback
	if isSettingGridMode then
		return
	end

	if mode ~= "none" and mode ~= "border" and mode ~= "fill" and mode ~= "both" then
		chatMessage("|cFFFF0000[DEV] Invalid grid mode. Use: none, border, fill, or both|r")
		return
	end

	isSettingGridMode = true
	gridMode = mode

	-- Save to database
	local db = BookArchivistDB
	if db and db.options then
		db.options.gridMode = gridMode
	end

	-- Update Settings dropdown if it exists
	if Settings and Settings.SetValue then
		local setting = Settings.GetSetting("gridMode")
		if setting then
			-- Set the value without triggering callbacks (to avoid recursion)
			setting:SetValue(mode)
		end
	end

	chatMessage("|cFF00FF00[DEV] Grid mode set to: " .. mode .. "|r")

	-- Update all existing overlays
	if gridOverlaysVisible then
		for _, overlay in ipairs(gridOverlays) do
			DevTools.UpdateOverlayVisibility(overlay)
		end
	end

	-- Update button highlights
	DevTools.UpdateDebugButtonHighlights()

	isSettingGridMode = false
end

function DevTools.GetGridMode()
	return gridMode
end

function DevTools.SetGridOverlayVisible(visible, silent)
	local previousState = gridOverlaysVisible
	gridOverlaysVisible = visible and true or false

	-- Save to database
	local db = BookArchivistDB
	if db and db.options then
		db.options.gridVisible = gridOverlaysVisible
	end

	-- Check if main UI is actually visible
	local uiActuallyVisible = mainUIFrame and mainUIFrame:IsShown()

	-- Only show overlay parent if BOTH debug mode is on AND UI is visible
	local shouldShowOverlays = gridOverlaysVisible and uiActuallyVisible

	local overlayParent = ensureOverlayFrame()
	if shouldShowOverlays then
		overlayParent:Show()
	else
		overlayParent:Hide()
	end

	for _, overlay in ipairs(gridOverlays) do
		if shouldShowOverlays then
			if overlay.region then
				-- Update position to match current frame position
				overlay.region:ClearAllPoints()
				overlay.region:SetAllPoints(overlay.frame)
			end
			-- UpdateOverlayVisibility handles showing/hiding labels based on gridMode
			DevTools.UpdateOverlayVisibility(overlay)
		else
			if overlay.edges then
				for _, edge in pairs(overlay.edges) do
					edge:Hide()
				end
			end
			if overlay.fill then
				overlay.fill:Hide()
			end
			if overlay.labelFrame then
				overlay.labelFrame:Hide()
			end
		end
	end

	-- Only show message if state changed and not silent
	if not silent and previousState ~= gridOverlaysVisible then
		if visible then
			chatMessage("|cFF00FF00[DEV] Frame grid overlays enabled|r")
		else
			chatMessage("|cFFFFA000[DEV] Frame grid overlays disabled|r")
		end
	end
end

function DevTools.IsGridOverlayVisible()
	return gridOverlaysVisible
end

-- ============================================================================
-- INTEGRATION WITH MAIN ADDON
-- ============================================================================

-- Hook into the main addon's UI.Internal if it exists
if BookArchivist.UI and BookArchivist.UI.Internal then
	local Internal = BookArchivist.UI.Internal

	-- Override debug functions with dev versions
	Internal.debugPrint = DevTools.DebugPrint
	Internal.setGridOverlayVisible = DevTools.SetGridOverlayVisible
	Internal.getGridOverlayVisible = DevTools.IsGridOverlayVisible
	Internal.registerFrameForDebug = DevTools.RegisterFrameForDebug
end

-- Make debug chat state readable by main addon
local originalIsDebugEnabled = BookArchivist.IsDebugEnabled
function BookArchivist:IsDebugEnabled()
	if DevTools.IsDebugChatEnabled then
		return DevTools.IsDebugChatEnabled()
	end
	if originalIsDebugEnabled then
		return originalIsDebugEnabled(self)
	end
	return false
end

local originalSetDebugEnabled = BookArchivist.SetDebugEnabled
function BookArchivist:SetDebugEnabled(state)
	DevTools.EnableDebugChat(state)
	if originalSetDebugEnabled then
		originalSetDebugEnabled(self, state)
	end
end

-- ============================================================================
-- DEV SLASH COMMANDS
-- ============================================================================

SLASH_BOOKARCHIVISTDEV1 = "/badev"
SlashCmdList["BOOKARCHIVISTDEV"] = function(msg)
	-- Trim the message
	msg = msg:gsub("^%s*(.-)%s*$", "%1")

	-- Extract first word as command
	local cmd, args = msg:match("^(%S+)%s*(.*)$")
	if not cmd then
		cmd = ""
		args = ""
	else
		cmd = cmd:lower()
		args = args:gsub("^%s*(.-)%s*$", "%1") -- Trim args
	end

	if cmd == "chat" or cmd == "debug" then
		local newState = not DevTools.IsDebugChatEnabled()
		DevTools.EnableDebugChat(newState)
	elseif cmd == "grid" or cmd == "overlay" then
		local newState = not DevTools.IsGridOverlayVisible()
		DevTools.SetGridOverlayVisible(newState)
	elseif cmd == "mode" or cmd == "gridmode" then
		if args ~= "" then
			local mode = args:lower()
			DevTools.SetGridMode(mode)
		else
			chatMessage("|cFFFFD100Current grid mode:|r " .. DevTools.GetGridMode())
			chatMessage("|cFF888888Available modes: none, border, fill, both|r")
		end
	elseif cmd == "help" or cmd == "" then
		chatMessage("|cFFFFD100BookArchivist Dev Tools:|r")
		chatMessage("  /badev chat      - Toggle debug chat logging")
		chatMessage("  /badev grid      - Toggle UI frame grid overlay")
		chatMessage("  /badev mode <m>  - Set grid mode (border/fill/both)")
		chatMessage("  /badev help      - Show this help")
	else
		chatMessage("|cFFFF0000Unknown dev command:|r " .. msg)
		chatMessage("Type /badev help for available commands")
	end
end

-- ============================================================================
-- OVERRIDE /ba COMMANDS WITH DEV VERSIONS
-- ============================================================================

-- Hook into the main /ba slash command handler to enable dev commands
local function hookMainSlashCommands()
	local originalHandler = SlashCmdList["BOOKARCHIVIST"]
	if not originalHandler then
		return
	end

	SlashCmdList["BOOKARCHIVIST"] = function(msg)
		local verb, rest = msg:match("^(%S*)%s*(.-)$")
		verb = (verb or ""):lower()
		rest = rest or ""

		-- Module status diagnostic
		if verb == "modules" or verb == "modstatus" then
			chatMessage("|cFF00FF00BookArchivist Module Status:|r")
			chatMessage(string.format("  BookArchivist: %s", tostring(BookArchivist ~= nil)))
			chatMessage(string.format("  DevTools: %s", tostring(BookArchivist and BookArchivist.DevTools ~= nil)))
			chatMessage(string.format("  Profiler: %s", tostring(BookArchivist and BookArchivist.Profiler ~= nil)))
			chatMessage(string.format("  Iterator: %s", tostring(BookArchivist and BookArchivist.Iterator ~= nil)))
			chatMessage(
				string.format(
					"  FramePool: %s",
					tostring(BookArchivist and BookArchivist.UI and BookArchivist.UI.FramePool ~= nil)
				)
			)
			chatMessage(
				string.format(
					"  TestDataGenerator: %s",
					tostring(BookArchivist and BookArchivist.TestDataGenerator ~= nil)
				)
			)
			chatMessage(string.format("  DBSafety: %s", tostring(BookArchivist and BookArchivist.DBSafety ~= nil)))
			chatMessage(string.format("  Core: %s", tostring(BookArchivist and BookArchivist.Core ~= nil)))
			return
		end

		-- Frame pool statistics
		if verb == "pool" or verb == "pools" or verb == "poolstats" then
			local FramePool = BookArchivist.UI and BookArchivist.UI.FramePool
			if not FramePool then
				chatMessage("|cFFFF0000BookArchivist:|r FramePool module not loaded!")
				return
			end

			local allStats = FramePool:GetAllStats()
			if #allStats == 0 then
				chatMessage("|cFF00FF00Frame Pools:|r No pools created yet")
			else
				chatMessage("|cFF00FF00Frame Pool Statistics:|r")
				for _, stats in ipairs(allStats) do
					chatMessage(
						string.format(
							"  |cFFFFFF00%s:|r %d active, %d available, %d total (%d created, %.1f%% reuse)",
							stats.name,
							stats.active,
							stats.available,
							stats.total,
							stats.totalCreated,
							stats.reuseRatio * 100
						)
					)
				end
			end
			return
		end

		-- Profiler commands
		if verb == "profile" then
			local Profiler = BookArchivist.Profiler
			if not Profiler then
				chatMessage("|cFFFF0000BookArchivist:|r Profiler module not loaded!")
				return
			end

			local subCmd = rest:lower()

			if subCmd == "" or subCmd == "report" then
				local report = Profiler:Report("total")
				chatMessage(report)
				return
			elseif subCmd == "summary" then
				Profiler:PrintSummary()
				return
			elseif subCmd == "on" or subCmd == "enable" then
				Profiler:SetEnabled(true)
				chatMessage("|cFF00FF00BookArchivist Profiler:|r Enabled")
				return
			elseif subCmd == "off" or subCmd == "disable" then
				Profiler:SetEnabled(false)
				chatMessage("|cFFFF6B6BBookArchivist Profiler:|r Disabled")
				return
			elseif subCmd == "reset" or subCmd == "clear" then
				Profiler:Reset()
				chatMessage("|cFF00FF00BookArchivist Profiler:|r Data reset")
				return
			elseif subCmd == "help" then
				chatMessage("|cFF00FF00BookArchivist Profiler Commands:|r")
				chatMessage("  /ba profile [report] - Show full report (sorted by total time)")
				chatMessage("  /ba profile summary - Show quick summary")
				chatMessage("  /ba profile on|off - Enable/disable profiling")
				chatMessage("  /ba profile reset - Clear all profiling data")
				return
			else
				chatMessage("|cFFFF0000Unknown profile command:|r " .. subCmd)
				chatMessage("Type |cFFFFFF00/ba profile help|r for usage")
				return
			end
		end

		-- Iterator commands
		if verb == "iter" or verb == "iterator" then
			local Iterator = BookArchivist.Iterator
			if not Iterator then
				chatMessage("|cFFFF0000BookArchivist:|r Iterator module not loaded!")
				return
			end

			local subCmd, opName = rest:match("^(%S*)%s*(.-)$")
			subCmd = (subCmd or ""):lower()
			opName = (opName or ""):lower()

			if subCmd == "test" then
				chatMessage("|cFF00FF00Iterator:|r Starting test iteration...")
				Iterator:Start("test_iteration", BookArchivist:GetDB().booksById or {}, function(bookId, entry, context)
					-- Simulate slow processing
					local sum = 0
					for i = 1, 1000 do
						sum = sum + i
					end
					return true
				end, {
					chunkSize = 10,
					budgetMs = 5,
					onComplete = function()
						chatMessage("|cFF00FF00Iterator:|r Test complete")
					end,
				})
				return
			elseif subCmd == "" or subCmd == "status" then
				local operations = Iterator:GetActiveOperations()
				if #operations == 0 then
					chatMessage("|cFF00FF00Iterator:|r No active iterations")
				else
					chatMessage(string.format("|cFF00FF00Iterator:|r %d active operation(s):", #operations))
					for _, op in ipairs(operations) do
						local status = Iterator:GetStatus(op)
						if status then
							chatMessage(
								string.format(
									"  %s: %d/%d (%.1f%%) - %.1fs elapsed",
									op,
									status.current,
									status.total,
									status.progress * 100,
									status.elapsedSeconds
								)
							)
						end
					end
				end
				return
			elseif subCmd == "cancel" then
				if opName == "" then
					chatMessage("|cFFFF0000Usage:|r /ba iter cancel <operation>")
					return
				end
				if Iterator:Cancel(opName) then
					chatMessage(string.format("|cFF00FF00Iterator:|r Cancelled '%s'", opName))
				else
					chatMessage(string.format("|cFFFF0000Iterator:|r No such operation '%s'", opName))
				end
				return
			elseif subCmd == "cancelall" then
				local count = Iterator:CancelAll()
				chatMessage(string.format("|cFF00FF00Iterator:|r Cancelled %d operation(s)", count))
				return
			else
				chatMessage("|cFFFF0000Unknown iter command:|r " .. subCmd)
				chatMessage("Type |cFFFFFF00/ba help|r for usage")
				return
			end
		end

		-- Test data generator commands
		if verb == "gentest" then
			local Generator = BookArchivist.TestDataGenerator
			if not Generator then
				chatMessage("|cFFFF0000BookArchivist:|r TestDataGenerator not loaded!")
				return
			end

			local count = tonumber(rest)
			if count and count > 0 then
				Generator:GenerateBooks(count, { uniqueTitles = true })
			else
				chatMessage("|cFFFF0000Usage:|r /ba gentest <count>")
				chatMessage("Example: /ba gentest 1000")
			end
			return
		end

		if verb == "genpreset" then
			local Generator = BookArchivist.TestDataGenerator
			if not Generator then
				chatMessage("|cFFFF0000BookArchivist:|r TestDataGenerator not loaded!")
				return
			end

			if rest == "" then
				chatMessage("|cFF00FF00Available presets:|r")
				chatMessage("  small (100), medium (500), large (1000)")
				chatMessage("  xlarge (2500), stress (5000)")
				chatMessage("  minimal (50), rich (200)")
				chatMessage("|cFFFFFF00Usage:|r /ba genpreset <preset>")
			else
				Generator:GeneratePreset(rest)
			end
			return
		end

		if verb == "cleartest" then
			local Generator = BookArchivist.TestDataGenerator
			if not Generator then
				chatMessage("|cFFFF0000BookArchivist:|r TestDataGenerator not loaded!")
				return
			end

			StaticPopupDialogs["BOOKARCHIVIST_CLEARTEST"] = {
				text = "Delete all test books?\n\nThis will remove books matching test patterns.\n\n|cFFFF0000This cannot be undone!|r",
				button1 = "Delete",
				button2 = "Cancel",
				OnAccept = function()
					Generator:ClearTestData()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("BOOKARCHIVIST_CLEARTEST")
			return
		end

		if verb == "stats" then
			local Generator = BookArchivist.TestDataGenerator
			if not Generator then
				chatMessage("|cFFFF0000BookArchivist:|r TestDataGenerator not loaded!")
				return
			end

			Generator:PrintStats()
			return
		end

		-- UI grid debug commands
		if verb == "uigrid" or verb == "uidebug" then
			local Internal = BookArchivist.UI and BookArchivist.UI.Internal
			if not Internal then
				chatMessage("|cFFFF0000BookArchivist:|r UI not initialized")
				return
			end

			local desiredState
			if verb == "uidebug" and rest ~= "" then
				if rest == "on" then
					desiredState = true
				elseif rest == "off" then
					desiredState = false
				end
			end

			local visible
			if desiredState == nil then
				-- Toggle
				visible = not DevTools.IsGridOverlayVisible()
			else
				visible = desiredState
			end

			DevTools.SetGridOverlayVisible(visible)
			return
		end

		-- Not a dev command, pass to original handler
		originalHandler(msg)
	end
end

-- Hook commands after a short delay to ensure main addon is loaded
C_Timer.After(0.1, function()
	hookMainSlashCommands()
end)

-- ============================================================================
-- AUTO-REGISTER UI FRAMES FOR DEBUG GRID
-- ============================================================================

-- Forward declaration for CreateDebugModeButtons (defined later)
local CreateDebugModeButtons

-- Hook into ToggleUI to register frames when window opens
local function HookToggleUI()
	if not BookArchivist or not BookArchivist.ToggleUI then
		return false
	end

	local originalToggleUI = BookArchivist.ToggleUI
	local registered = false

	BookArchivist.ToggleUI = function(...)
		local result = originalToggleUI(...)

		-- Only register once, after window is shown
		if not registered then
			C_Timer.After(0.2, function()
				-- Get frame via Internal.getUIFrame (same way ToggleUI does)
				local Internal = BookArchivist.UI and BookArchivist.UI.Internal
				if not Internal or not Internal.getUIFrame then
					chatMessage("|cFFFF0000[DEV] Internal.getUIFrame not found|r")
					return
				end

				local frame = Internal.getUIFrame()
				if not frame then
					chatMessage("|cFFFF0000[DEV] getUIFrame() returned nil|r")
					return
				end

				mainUIFrame = frame -- Store reference
				chatMessage("|cFF00FF00[DEV] Registering frames for debug grid...|r")

				-- Register main frame
				DevTools.RegisterFrameForDebug(frame, "MainFrame", "red")

				-- Register named child frames by checking frame properties
				local namedFrames = {
					{ frame.HeaderFrame, "HeaderFrame", "green" },
					{ frame.BodyFrame, "BodyFrame", "blue" },
					{ frame.ListInset, "ListInset", "cyan" },
					{ frame.ReaderInset, "ReaderInset", "magenta" },
					{ frame.listBlock, "listBlock", "cyan" },
					{ frame.readerBlock, "readerBlock", "magenta" },
				}

				local frameCount = 1
				for _, entry in ipairs(namedFrames) do
					local childFrame, name, color = entry[1], entry[2], entry[3]
					if childFrame and childFrame.GetObjectType then
						DevTools.RegisterFrameForDebug(childFrame, name, color)
						frameCount = frameCount + 1
					end
				end

				registered = true
				chatMessage("|cFF888888[DEV] Registered " .. frameCount .. " frames|r")

				-- Create debug mode buttons now that mainUIFrame is set
				CreateDebugModeButtons()

				-- Show buttons immediately since UI is already open
				DevTools.ShowDebugButtons()

				-- If grid is enabled, show overlays immediately
				if gridOverlaysVisible then
					chatMessage("|cFF888888[DEV] Grid overlays are ENABLED|r")
					-- Trigger overlay visibility update
					DevTools.SetGridOverlayVisible(true, true)
				else
					chatMessage("|cFF888888[DEV] Use /badev grid to see overlays|r")
				end

				-- Hook frame show/hide to auto-toggle overlays and buttons
				frame:HookScript("OnShow", function()
					if gridOverlaysVisible then
						DevTools.SetGridOverlayVisible(true, true) -- silent refresh
					end
					-- Always show debug buttons when UI opens (dev tools are loaded)
					DevTools.ShowDebugButtons()
				end)

				frame:HookScript("OnHide", function()
					if gridOverlaysVisible then
						DevTools.SetGridOverlayVisible(true, true) -- silent refresh (will hide due to UI check)
					end
					-- Hide debug buttons when UI closes
					DevTools.HideDebugButtons()
				end)
			end)
		end

		return result
	end

	return true
end

-- Try to hook after addon loads
C_Timer.After(1.5, function()
	if HookToggleUI() then
		chatMessage("|cFF888888[DEV] Hooked BookArchivist.ToggleUI for frame registration|r")
	else
		chatMessage("|cFFFF0000[DEV] Failed to hook ToggleUI - UI not loaded yet?|r")
	end
end)

-- ============================================================================
-- DEBUG MODE QUICK-ACCESS BUTTONS
-- ============================================================================

CreateDebugModeButtons = function()
	if not mainUIFrame then
		chatMessage("|cFFFF0000[DEV] Cannot create debug buttons - mainUIFrame not set|r")
		return
	end

	-- Destroy existing container if any
	if debugButtonContainer then
		debugButtonContainer:Hide()
		debugButtonContainer:SetParent(nil)
		debugButtonContainer = nil
	end

	-- Destroy existing buttons
	for _, btn in ipairs(debugModeButtons) do
		if btn then
			btn:Hide()
			btn:SetParent(nil)
		end
	end
	debugModeButtons = {}

	-- Spacing system: 8px standard, 12px section gaps
	local SPACING_STANDARD = 8
	local SPACING_SECTION = 12
	local BUTTON_HEIGHT = 32 -- WoW standard button height
	local BUTTON_WIDTH = 80 -- Wider for clearer labels
	local TITLE_HEIGHT = 20 -- Clean header height

	-- Create container frame using InsetFrameTemplate for professional look
	local container = CreateFrame("Frame", nil, UIParent, "InsetFrameTemplate")
	debugButtonContainer = container

	local containerWidth = BUTTON_WIDTH + (SPACING_SECTION * 2)
	local containerHeight = TITLE_HEIGHT + (BUTTON_HEIGHT * 5) + (SPACING_STANDARD * 4) + (SPACING_SECTION * 3)

	container:SetSize(containerWidth, containerHeight)
	container:SetPoint("TOPRIGHT", mainUIFrame, "TOPLEFT", -SPACING_SECTION, 0)
	container:SetFrameStrata("HIGH")

	-- Title text using proper typography
	local title = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetText("Debug Grid")
	title:SetPoint("TOP", container, "TOP", 0, -SPACING_STANDARD)

	-- Button data with proper semantic labeling
	local buttonData = {
		{ mode = "none", label = "Off", desc = "Hide all overlays", color = { 0.6, 0.6, 0.6 } },
		{ mode = "border", label = "Border", desc = "Frame edges only", color = { 1, 0.6, 0 } },
		{ mode = "fill", label = "Fill", desc = "Solid overlays", color = { 0.2, 0.8, 1 } },
		{ mode = "both", label = "Both", desc = "Edges + fill", color = { 0.3, 1, 0.3 } },
	}

	-- Create buttons inside container with consistent spacing
	local firstButtonY = -(TITLE_HEIGHT + SPACING_SECTION)

	for i, data in ipairs(buttonData) do
		local btn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
		btn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

		-- Position using spacing system
		local yOffset = firstButtonY - ((i - 1) * (BUTTON_HEIGHT + SPACING_STANDARD))
		btn:SetPoint("TOP", container, "TOP", 0, yOffset)

		btn:SetText(data.label)

		-- Apply mode color with proper contrast
		local r, g, b = unpack(data.color)
		local normalTexture = btn:GetNormalTexture()
		if normalTexture then
			normalTexture:SetVertexColor(r, g, b, 0.9)
		end

		-- Hover state for better affordance
		btn:SetScript("OnEnter", function(self)
			local highlightTexture = self:GetHighlightTexture()
			if highlightTexture then
				highlightTexture:SetVertexColor(1, 1, 1, 0.3)
			end

			-- Clear tooltip with semantic structure
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:ClearLines()
			GameTooltip:AddLine(data.label, 1, 1, 1)
			GameTooltip:AddLine(data.desc, 0.7, 0.7, 0.7, true)
			GameTooltip:Show()
		end)

		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- Button click handler
		btn:SetScript("OnClick", function()
			DevTools.SetGridMode(data.mode)
			-- Enable grid visibility if it was off
			if not gridOverlaysVisible then
				DevTools.SetGridOverlayVisible(true)
			end
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
		end)

		-- Visual feedback for active mode
		if gridMode == data.mode then
			btn:LockHighlight()
		else
			btn:UnlockHighlight()
		end

		table.insert(debugModeButtons, btn)
	end

	-- Add "Copy Debug Log" button after a section gap
	local copyBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
	copyBtn:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)

	local copyBtnY = firstButtonY - (#buttonData * (BUTTON_HEIGHT + SPACING_STANDARD)) - SPACING_SECTION
	copyBtn:SetPoint("TOP", container, "TOP", 0, copyBtnY)
	copyBtn:SetText("Copy Log")

	-- Distinctive color for utility button
	local normalTexture = copyBtn:GetNormalTexture()
	if normalTexture then
		normalTexture:SetVertexColor(0.8, 0.4, 1, 0.9)
	end

	copyBtn:SetScript("OnEnter", function(self)
		local highlightTexture = self:GetHighlightTexture()
		if highlightTexture then
			highlightTexture:SetVertexColor(1, 1, 1, 0.3)
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("Copy Debug Log", 1, 1, 1)
		GameTooltip:AddLine("Copy all debug messages to clipboard", 0.7, 0.7, 0.7, true)
		GameTooltip:Show()
	end)

	copyBtn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	copyBtn:SetScript("OnClick", function()
		local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal
		if not Internal or not Internal.getDebugLog then
			chatMessage("|cFFFF0000[DEV] Debug log not available|r")
			return
		end

		local log = Internal.getDebugLog()
		if not log or #log == 0 then
			chatMessage("|cFFFFFF00[DEV] Debug log is empty|r")
			return
		end

		-- Format log entries with timestamps
		local lines = {}
		for _, entry in ipairs(log) do
			local timeStr = date("%H:%M:%S", entry.timestamp)
			table.insert(lines, string.format("[%s] %s", timeStr, entry.message))
		end

		local logText = table.concat(lines, "\n")

		-- Copy to clipboard using edit box trick
		local editBox = CreateFrame("EditBox", nil, UIParent)
		editBox:SetText(logText)
		editBox:SetFocus()
		editBox:HighlightText()
		editBox:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
			self:Hide()
		end)

		-- Give user time to Ctrl+C
		C_Timer.After(0.1, function()
			if editBox then
				editBox:HighlightText()
				editBox:SetFocus()
			end
		end)

		-- Auto-cleanup after 5 seconds
		C_Timer.After(5, function()
			if editBox then
				editBox:Hide()
				editBox:SetParent(nil)
			end
		end)

		chatMessage(string.format("|cFF00FF00[DEV] Copied %d debug log entries to clipboard (Ctrl+C)|r", #log))
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end)

	table.insert(debugModeButtons, copyBtn)

	container:Hide() -- Start hidden

	chatMessage("|cFF00FF00[DEV] Created debug grid panel|r")
end

function DevTools.ShowDebugButtons()
	if not debugButtonContainer then
		CreateDebugModeButtons()
	end

	if debugButtonContainer then
		debugButtonContainer:Show()
	end
end

function DevTools.HideDebugButtons()
	if debugButtonContainer then
		debugButtonContainer:Hide()
	end
end

function DevTools.UpdateDebugButtonHighlights()
	for i, btn in ipairs(debugModeButtons) do
		if btn then
			local buttonModes = { "none", "border", "fill", "both" }
			if gridMode == buttonModes[i] then
				btn:LockHighlight()
			else
				btn:UnlockHighlight()
			end
		end
	end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize state from saved variables
C_Timer.After(0.1, function()
	local db = BookArchivistDB
	if db and db.options then
		-- Restore grid mode
		if db.options.gridMode then
			gridMode = db.options.gridMode
			-- Apply the mode if grid is visible
			if gridOverlaysVisible then
				for _, overlay in ipairs(gridOverlays) do
					DevTools.UpdateOverlayVisibility(overlay)
				end
			end
		end

		-- Restore grid visibility state if it was saved
		if db.options.gridVisible ~= nil then
			gridOverlaysVisible = db.options.gridVisible
		end

		-- Note: Don't auto-show overlays here - they'll show when UI opens if enabled
	end
end)

chatMessage("|cFF00FF00BookArchivist Dev Tools loaded|r - Type /badev help")
