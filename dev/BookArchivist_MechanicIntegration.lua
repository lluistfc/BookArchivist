---@diagnostic disable: undefined-global
-- BookArchivist_MechanicIntegration.lua
-- Mechanic integration module (dev-only)
-- Registers BookArchivist with Mechanic's development hub
-- This file is NOT loaded in production releases

-- ============================================================================
-- MECHANIC INTEGRATION MODULE
-- ============================================================================

local Integration = {}
BookArchivist.MechanicIntegration = Integration

local isRegistered = false
local originalDebugPrint = nil

-- Lazy-load MechanicLib (it might not be available at file load time)
local function getMechanicLib()
	return LibStub and LibStub("MechanicLib-1.0", true)
end

-- ============================================================================
-- LOGGING INTEGRATION
-- ============================================================================

-- Map BookArchivist debug categories to Mechanic log categories
local categoryMap = {
	["CAPTURE"] = "EVENT",     -- Book capture events
	["SEARCH"] = "CORE",       -- Search operations
	["FILTER"] = "CORE",       -- List filtering
	["RENDER"] = "PERF",       -- UI rendering
	["DB"] = "CORE",           -- Database operations
	["IMPORT"] = "CORE",       -- Import operations
	["EXPORT"] = "CORE",       -- Export operations
	["UI"] = "TRIGGER",        -- UI interactions
	["PERFORMANCE"] = "PERF",  -- Performance metrics
	["ERROR"] = "VALIDATION",  -- Errors and validation
}

-- Parse category from debug message prefix
local function parseCategory(msg)
	-- Look for patterns like "[BookArchivist CATEGORY]" or "[CATEGORY]"
	local category = msg:match("%[BookArchivist%s+(%u+)%]") or msg:match("%[(%u+)%]")
	return categoryMap[category] or "CORE"
end

-- Hook DebugPrint to send messages to Mechanic
local function hookDebugPrint()
	local MechanicLib = getMechanicLib()
	if not MechanicLib or not MechanicLib:IsEnabled() then
		return
	end
	
	-- Store original
	originalDebugPrint = BookArchivist.DebugPrint
	
	-- Replace with hooked version
	function BookArchivist:DebugPrint(...)
		-- Call original to maintain existing behavior
		originalDebugPrint(self, ...)
		
		-- Also send to Mechanic if available
		local MechanicLib = getMechanicLib()
		if MechanicLib and MechanicLib:IsEnabled() then
			local parts = {}
			for i = 1, select("#", ...) do
				parts[i] = tostring(select(i, ...))
			end
			local msg = table.concat(parts, " ")
			local category = parseCategory(msg)
			MechanicLib:Log("BookArchivist", msg, category)
		end
	end
end

-- Restore original DebugPrint
local function unhookDebugPrint()
	if originalDebugPrint then
		BookArchivist.DebugPrint = originalDebugPrint
		originalDebugPrint = nil
	end
end

-- ============================================================================
-- TESTS CAPABILITY
-- ============================================================================
--
-- TEST CATEGORIZATION:
-- 
-- 1. SANDBOX TESTS (Tests/Sandbox/) - Pure logic, fast, no WoW API needed
--    - Base64, BookId, CRC32, Order, Serialize
--    - Run via: mech call sandbox.test '{"addon": "BookArchivist"}'
--
-- 2. DESKTOP TESTS (Tests/Desktop/) - Complex mocking with Busted
--    - DBSafety, Export, Favorites, Recent, Search
--    - Run via: busted from addon root (uses .busted config)
--
-- 3. IN-GAME TESTS (Tests/InGame/) - Require actual WoW APIs
--    - Currently: Reader, Async_Filtering, List_Reader (need rewriting)
--    - Run via: Mechanic UI Tests tab → "Run Selected" or "Run All Auto"
--    - These are the ONLY tests registered with MechanicLib below
--
-- NOTE: Sandbox/Desktop tests (10 tests) do NOT appear in Mechanic UI.
--       They run via CLI only. Only in-game tests appear in UI.
--
-- ============================================================================

local testCapability = {}
local testResults = {}  -- Store test results for retrieval

-- Get all available IN-GAME test suites
-- These are tests that MUST run inside WoW with real APIs
function testCapability.getAll()
	-- Use the in-game tests from BookArchivist_InGameTests.lua
	if BookArchivist.InGameTests then
		return BookArchivist.InGameTests.GetAll()
	end
	
	-- Fallback if tests not loaded yet
	return {}
end

-- Get test categories
function testCapability.getCategories()
	return { "Core", "UI" }  -- Core tests + UI tests
end

-- Run a specific test
function testCapability.run(testId)
	if not testId then
		return {
			passed = false,
			message = "Test ID required"
		}
	end
	
	-- Use the in-game test runner
	if not BookArchivist.InGameTests then
		return {
			passed = false,
			message = "In-game tests not loaded"
		}
	end
	
	local result = BookArchivist.InGameTests.Run(testId)
	
	-- Store result for retrieval
	testResults[testId] = result
	
	return result
end

-- Run all tests
function testCapability.runAll()
	-- Use the in-game test runner
	if not BookArchivist.InGameTests then
		return 0, 0  -- No tests available
	end
	
	local passed, total, results = BookArchivist.InGameTests.RunAll()
	
	-- Store all results
	for testId, result in pairs(results) do
		testResults[testId] = result
	end
	
	return passed, total
end

-- Get test result
function testCapability.getResult(testId)
	-- Return stored result or indicate no result available
	return testResults[testId] or {
		passed = nil,
		message = "Test not yet run. Click 'Run Selected' or 'Run All Auto' to execute."
	}
end

-- Clear test results
function testCapability.clearResults()
	testResults = {}
	return { success = true }
end

-- ============================================================================
-- PERFORMANCE CAPABILITY
-- ============================================================================

local performanceCapability = {}

-- Get sub-metrics for performance tracking
function performanceCapability.getSubMetrics()
	local db = BookArchivist.Core and BookArchivist.Core:GetDB()
	if not db then
		return {}
	end
	
	-- Calculate database statistics
	local bookCount = 0
	local pageCount = 0
	local totalBytes = 0
	
	if db.booksById then
		for bookId, book in pairs(db.booksById) do
			bookCount = bookCount + 1
			if book.pages then
				pageCount = pageCount + #book.pages
				for _, page in ipairs(book.pages) do
					if page.text then
						totalBytes = totalBytes + #page.text
					end
				end
			end
		end
	end
	
	return {
		{
			name = "Books",
			value = bookCount,
			unit = "count",
			category = "Database"
		},
		{
			name = "Pages",
			value = pageCount,
			unit = "count",
			category = "Database"
		},
		{
			name = "Storage",
			value = string.format("%.2f KB", totalBytes / 1024),
			unit = "size",
			category = "Database"
		},
		{
			name = "Avg Pages/Book",
			value = bookCount > 0 and string.format("%.1f", pageCount / bookCount) or "0",
			unit = "average",
			category = "Database"
		}
	}
end

-- ============================================================================
-- TOOLS CAPABILITY
-- ============================================================================

local toolsCapability = {}
local toolsPanel = nil

-- Create custom tools panel in Mechanic
function toolsCapability.createPanel(parent)
	if toolsPanel then
		return toolsPanel
	end
	
	toolsPanel = CreateFrame("Frame", nil, parent)
	toolsPanel:SetAllPoints()
	
	-- Title
	local title = toolsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 10, -10)
	title:SetText("BookArchivist Dev Tools")
	
	-- Database stats section
	local statsHeader = toolsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	statsHeader:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
	statsHeader:SetText("Database Statistics:")
	
	local statsText = toolsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	statsText:SetPoint("TOPLEFT", statsHeader, "BOTTOMLEFT", 10, -5)
	statsText:SetJustifyH("LEFT")
	statsText:SetWidth(400)
	
	-- Update stats function
	local function updateStats()
		local metrics = performanceCapability.getSubMetrics()
		local lines = {}
		for _, metric in ipairs(metrics) do
			table.insert(lines, string.format("%s: %s", metric.name, metric.value))
		end
		statsText:SetText(table.concat(lines, "\n"))
	end
	
	-- Refresh button
	local refreshBtn = CreateFrame("Button", nil, toolsPanel, "UIPanelButtonTemplate")
	refreshBtn:SetSize(100, 22)
	refreshBtn:SetPoint("TOPLEFT", statsText, "BOTTOMLEFT", -5, -10)
	refreshBtn:SetText("Refresh")
	refreshBtn:SetScript("OnClick", updateStats)
	
	-- Export button
	local exportBtn = CreateFrame("Button", nil, toolsPanel, "UIPanelButtonTemplate")
	exportBtn:SetSize(120, 22)
	exportBtn:SetPoint("LEFT", refreshBtn, "RIGHT", 5, 0)
	exportBtn:SetText("Export All Books")
	exportBtn:SetScript("OnClick", function()
		if BookArchivist.Export and BookArchivist.Export.ExportAll then
			BookArchivist.Export:ExportAll()
			print("|cff00ff00[BookArchivist]|r Export started. Check export window.")
		end
	end)
	
	-- Clear debug log button
	local clearLogBtn = CreateFrame("Button", nil, toolsPanel, "UIPanelButtonTemplate")
	clearLogBtn:SetSize(120, 22)
	clearLogBtn:SetPoint("LEFT", exportBtn, "RIGHT", 5, 0)
	clearLogBtn:SetText("Clear Debug Log")
	clearLogBtn:SetScript("OnClick", function()
		if BookArchivist.ClearDebugLog then
			BookArchivist:ClearDebugLog()
			print("|cff00ff00[BookArchivist]|r Debug log cleared.")
		end
	end)
	
	-- Debug info section
	local debugHeader = toolsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	debugHeader:SetPoint("TOPLEFT", refreshBtn, "BOTTOMLEFT", 5, -20)
	debugHeader:SetText("Debug Settings:")
	
	local debugCheckbox = CreateFrame("CheckButton", nil, toolsPanel, "UICheckButtonTemplate")
	debugCheckbox:SetPoint("TOPLEFT", debugHeader, "BOTTOMLEFT", 0, -5)
	debugCheckbox:SetSize(24, 24)
	debugCheckbox.text = debugCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	debugCheckbox.text:SetPoint("LEFT", debugCheckbox, "RIGHT", 5, 0)
	debugCheckbox.text:SetText("Enable Debug Mode")
	debugCheckbox:SetChecked(BookArchivist:IsDebugEnabled())
	debugCheckbox:SetScript("OnClick", function(self)
		if BookArchivist.SetDebugEnabled then
			BookArchivist:SetDebugEnabled(self:GetChecked())
		end
	end)
	
	-- Initial stats
	updateStats()
	
	return toolsPanel
end

-- Destroy custom tools panel
function toolsCapability.destroyPanel(panel)
	if panel and panel == toolsPanel then
		toolsPanel:Hide()
		toolsPanel = nil
	end
end

-- ============================================================================
-- REGISTRATION
-- ============================================================================

function Integration:Register()
	local MechanicLib = getMechanicLib()
	if not MechanicLib then
		return false, "MechanicLib not available"
	end
	
	if not MechanicLib:IsEnabled() then
		return false, "Mechanic not enabled"
	end
	
	if isRegistered then
		return true, "Already registered"
	end
	
	-- Get addon version from TOC (use modern API)
	local version = C_AddOns and C_AddOns.GetAddOnMetadata("BookArchivist", "Version") or "dev"
	
	-- Register with Mechanic (void function, doesn't return success)
	MechanicLib:Register("BookArchivist", {
		version = version,
		tests = testCapability,
		performance = performanceCapability,
		tools = toolsCapability,
	})
	
	isRegistered = true
	hookDebugPrint()
	print("|cff00ff00[BookArchivist]|r Registered with Mechanic v" .. version)
	return true, "Registered successfully"
end

function Integration:Unregister()
	if not isRegistered then
		return false, "Not registered"
	end
	
	unhookDebugPrint()
	isRegistered = false
	
	local MechanicLib = getMechanicLib()
	if MechanicLib then
		MechanicLib:Unregister("BookArchivist")
	end
	
	print("|cff00ff00[BookArchivist]|r Unregistered from Mechanic")
	return true, "Unregistered successfully"
end

function Integration:IsRegistered()
	return isRegistered
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Auto-register when Mechanic is loaded
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(self, event, addonName)
	if event == "ADDON_LOADED" then
		if addonName == "!Mechanic" or addonName == "Mechanic" then
			-- Wait a frame to ensure everything is loaded
			C_Timer.After(0.1, function()
				local success, msg = Integration:Register()
				if success then
					print("|cff00ff00[BookArchivist]|r " .. (msg or "Registered with Mechanic"))
				else
					print("|cffff0000[BookArchivist]|r Failed to register: " .. (msg or "unknown error"))
				end
			end)
		end
	elseif event == "PLAYER_LOGOUT" then
		Integration:Unregister()
	end
end)

print("|cff00ff00[BookArchivist]|r Mechanic integration module loaded (dev)")
