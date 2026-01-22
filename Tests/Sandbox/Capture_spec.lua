---@diagnostic disable: undefined-global
-- Capture_spec.lua
-- Integration tests for book capture system

describe("Capture System", function()
	local Capture, Location
	
	setup(function()
		-- Mock WoW environment
		_G.time = os.time
		_G.BookArchivist = {}
		
		-- Mock localization
		_G.BookArchivist.L = {
			LOCATION_UNKNOWN_ZONE = "Unknown Zone",
		}
		
		-- Load only the modules we need to verify
		dofile("./core/BookArchivist_Location.lua")
		dofile("./core/BookArchivist_Capture.lua")
		
		Location = BookArchivist.Location
		Capture = BookArchivist.Capture
	end)
	
	before_each(function()
		-- Mock C_Map API for location capture
		_G.C_Map = {
			GetBestMapForUnit = function(unit)
				return 1453 -- Stormwind City
			end,
			GetMapInfo = function(mapID)
				if mapID == 1453 then
					return {
						name = "Stormwind City",
						mapType = 3,
						parentMapID = 1429,
					}
				elseif mapID == 1429 then
					return {
						name = "Elwynn Forest",
						mapType = 3,
						parentMapID = 1415,
					}
				elseif mapID == 1415 then
					return {
						name = "Eastern Kingdoms",
						mapType = 2,
						parentMapID = nil,
					}
				end
				return nil
			end,
		}
		
		_G.Enum = {
			UIMapType = {
				Cosmic = 0,
			},
		}
		
		_G.GetTime = function()
			return 1234567890.5
		end
	end)

	local function getCaptureUpvalue(name)
		assert(Capture, "Capture module must be loaded")
		local targets = { Capture.OnBegin, Capture.OnReady, Capture.OnClosed }
		for _, fn in ipairs(targets) do
			if type(fn) == "function" then
				local idx = 1
				while true do
					local upvalueName, value = debug.getupvalue(fn, idx)
					if not upvalueName then break end
					if upvalueName == name then
						return value, fn, idx
					end
					idx = idx + 1
				end
			end
		end
	end

	local function getFunctionUpvalue(fn, name)
		if type(fn) ~= "function" then
			return nil, nil
		end
		local idx = 1
		while true do
			local upvalueName, value = debug.getupvalue(fn, idx)
			if not upvalueName then
				return nil, nil
			end
			if upvalueName == name then
				return value, idx
			end
			idx = idx + 1
		end
	end
	
	describe("BuildWorldLocation Function - Regression Test", function()
		-- This test would have caught the v2.0.2 bug where BuildWorldLocation was removed
		it("must exist and be callable", function()
			assert.is_not_nil(Location, "Location module must exist")
			assert.is_function(Location.BuildWorldLocation, "BuildWorldLocation must be a function")
			local result = Location:BuildWorldLocation()
			assert.is_not_nil(result, "BuildWorldLocation must return a value")
			assert.equals("table", type(result), "BuildWorldLocation must return a table")
		end)

		it("must return location with required fields", function()
			local location = Location:BuildWorldLocation()
			assert.is_not_nil(location.context, "Must have context field")
			assert.is_not_nil(location.zoneChain, "Must have zoneChain field")
			assert.is_not_nil(location.zoneText, "Must have zoneText field")
			assert.is_not_nil(location.capturedAt, "Must have capturedAt field")
			assert.equals("table", type(location.zoneChain), "zoneChain must be a table")
			assert.equals("string", type(location.zoneText), "zoneText must be a string")
			assert.equals("number", type(location.capturedAt), "capturedAt must be a number")
		end)

		it("must build hierarchical location chain", function()
			local location = Location:BuildWorldLocation()
			assert.is_not_nil(location.zoneChain)
			assert.is_true(#location.zoneChain >= 1, "zoneChain must have at least one entry")
			assert.equals(3, #location.zoneChain, "Should have continent > zone > subzone")
			assert.equals("Eastern Kingdoms", location.zoneChain[1])
			assert.equals("Elwynn Forest", location.zoneChain[2])
			assert.equals("Stormwind City", location.zoneChain[3])
		end)

		it("must handle API unavailable gracefully", function()
			_G.C_Map = nil
			_G.GetRealZoneText = function() return "" end
			_G.GetSubZoneText = function() return "" end
			local location = Location:BuildWorldLocation()
			assert.is_not_nil(location, "Must return location even when API unavailable")
			assert.is_not_nil(location.zoneChain, "Must have zoneChain fallback")
			assert.equals(1, #location.zoneChain, "Should have fallback zone")
			assert.equals("Unknown Zone", location.zoneChain[1], "Should use Unknown Zone fallback")
		end)
	end)
	
	describe("GetLootLocation Function - Regression Test", function()
		-- This test would have caught the v2.0.2 bug where GetLootLocation was removed
		it("must exist and be callable", function()
			assert.is_not_nil(Location, "Location module must exist")
			assert.is_function(Location.GetLootLocation, "GetLootLocation must be a function")
			
			-- Should not error when called
			local result = Location:GetLootLocation(12345)
			-- Can be nil for unknown items, but should not error
			assert.is_true(result == nil or type(result) == "table", "Must return nil or table")
		end)
		
		it("must accept itemID parameter", function()
			-- These calls should not error
			local result1 = Location:GetLootLocation(nil)
			local result2 = Location:GetLootLocation(12345)
			local result3 = Location:GetLootLocation("12345")
			
			-- All should return nil for unknown items, but no errors
			assert.is_nil(result1)
			assert.is_nil(result2)
			assert.is_nil(result3)
		end)
	end)
	
	describe("Location-Capture Integration", function()
		it("verifies Location module is available for Capture", function()
			-- The Capture module depends on Location being available
			-- This test verifies the integration point exists
			assert.is_not_nil(BookArchivist.Location, "Location module must be in BookArchivist namespace")
			assert.is_function(BookArchivist.Location.BuildWorldLocation, "BuildWorldLocation must be accessible")
			assert.is_function(BookArchivist.Location.GetLootLocation, "GetLootLocation must be accessible")
		end)
	end)
	
	describe("Capture Module Existence", function()
		it("should load Capture module without errors", function()
			-- Load Capture module to verify it doesn't have syntax errors
			dofile("./core/BookArchivist_Capture.lua")
			assert.is_not_nil(BookArchivist.Capture, "Capture module must exist")
		end)
		
		it("should have public API functions", function()
			dofile("./core/BookArchivist_Capture.lua")
			local Capture = BookArchivist.Capture
			
			assert.is_function(Capture.OnBegin, "OnBegin must be a function")
			assert.is_function(Capture.OnReady, "OnReady must be a function")
			assert.is_function(Capture.OnClosed, "OnClosed must be a function")
		end)
	end)

	describe("Capture helper functions", function()
		it("handles missing global table gracefully", function()
			local getGlobal = getCaptureUpvalue("getGlobal")
			assert.is_function(getGlobal)
			local originalG = _G
			local ok, result
			_G = "notatable"
			ok, result = pcall(getGlobal, "ItemTextFrame")
			_G = originalG
			assert.is_true(ok)
			assert.is_nil(result)
		end)

		it("falls back to os.time when Core is unavailable", function()
			local nowFn = getCaptureUpvalue("now")
			local coreValue, coreOwner, coreIdx = getCaptureUpvalue("Core")
			local originalOsTime = os.time
			local testTime = 987654
			os.time = function() return testTime end
			debug.setupvalue(coreOwner, coreIdx, nil)
			local ok, result = pcall(nowFn)
			debug.setupvalue(coreOwner, coreIdx, coreValue)
			os.time = originalOsTime
			assert.is_true(ok)
			assert.are.equal(testTime, result)
		end)

		it("normalizes nil via trim", function()
			local trimFn = getCaptureUpvalue("trim")
			assert.are.equal("", trimFn(nil))
		end)

		it("parses item and creature GUIDs", function()
			local currentSourceInfo = getCaptureUpvalue("currentSourceInfo")
			local parseGuid = select(1, getFunctionUpvalue(currentSourceInfo, "parseGuid"))
			assert.is_function(parseGuid)
			local objectType, objectID = parseGuid("Item-0-0-0-0-777")
			assert.are.equal("Item", objectType)
			assert.are.equal(777, objectID)
			local creatureType, creatureID = parseGuid("Creature-0-0-0-555-000000000000")
			assert.are.equal("Creature", creatureType)
			assert.are.equal(555, creatureID)
			assert.is_nil(parseGuid(12345))
		end)

		it("captures frame metadata and world GUID info", function()
			local currentSourceInfo = getCaptureUpvalue("currentSourceInfo")
			local originalFrame = _G.ItemTextFrame
			local originalUnitGUID = _G.UnitGUID
			_G.ItemTextFrame = { itemID = 444, page = 3 }
			_G.UnitGUID = function()
				return "GameObject-0-0-0-0-222"
			end
			local src = currentSourceInfo()
			_G.ItemTextFrame = originalFrame
			_G.UnitGUID = originalUnitGUID
			assert.are.equal(444, src.itemID)
			assert.are.equal(3, src.page)
			assert.are.equal("world", src.kind)
			assert.are.equal(222, src.objectID)
		end)

		it("marks inventory sources when GUID is an item", function()
			local currentSourceInfo = getCaptureUpvalue("currentSourceInfo")
			local originalUnitGUID = _G.UnitGUID
			_G.UnitGUID = function()
				return "Item-0-0-0-0-999"
			end
			local src = currentSourceInfo()
			_G.UnitGUID = originalUnitGUID
			assert.are.equal("inventory", src.kind)
			assert.are.equal(999, src.objectID)
		end)

		it("defaults to page 1 when the API is missing", function()
			local resolvePageNumber = getCaptureUpvalue("resolvePageNumber")
			local originalGetPage = _G.ItemTextGetPage
			_G.ItemTextGetPage = function()
				return nil
			end
			local page = resolvePageNumber()
			_G.ItemTextGetPage = originalGetPage
			assert.are.equal(1, page)
		end)

		it("prefers loot locations when available", function()
			local ensureSessionLocation = getCaptureUpvalue("ensureSessionLocation")
			local locationValue, locationIdx = getFunctionUpvalue(ensureSessionLocation, "Location")
			local mockLocation = {
				GetLootLocation = function(_, itemID)
					return { zoneText = "Loot " .. tostring(itemID) }
				end,
			}
			debug.setupvalue(ensureSessionLocation, locationIdx, mockLocation)
			local ok, err = pcall(function()
				local target = { itemID = 321 }
				ensureSessionLocation(target)
				assert.are.equal("Loot 321", target.location.zoneText)
			end)
			debug.setupvalue(ensureSessionLocation, locationIdx, locationValue)
			assert.is_true(ok, err)
		end)

		it("builds fallback world locations with loot context", function()
			local ensureSessionLocation = getCaptureUpvalue("ensureSessionLocation")
			local locationValue, locationIdx = getFunctionUpvalue(ensureSessionLocation, "Location")
			local mockLocation = {
				GetLootLocation = function()
					return nil
				end,
				BuildWorldLocation = function()
					return { zoneText = "Stormwind" }
				end,
			}
			debug.setupvalue(ensureSessionLocation, locationIdx, mockLocation)
			local ok, err = pcall(function()
				local target = { itemID = 654 }
				ensureSessionLocation(target)
				assert.are.equal("Stormwind", target.location.zoneText)
				assert.are.equal("loot", target.location.context)
				assert.is_true(target.location.isFallback)
			end)
			debug.setupvalue(ensureSessionLocation, locationIdx, locationValue)
			assert.is_true(ok, err)
		end)
	end)

	describe("Capture session flow", function()
		local sessionOriginal, sessionOwner, sessionIdx = getCaptureUpvalue("session")
		local coreOriginal, coreOwner, coreIdx = getCaptureUpvalue("Core")

		before_each(function()
			debug.setupvalue(sessionOwner, sessionIdx, nil)
			debug.setupvalue(coreOwner, coreIdx, nil)
			_G.ItemTextFrame = nil
			_G.UnitGUID = nil
			_G.ItemTextGetPage = nil
			_G.ItemTextGetTitle = nil
			_G.ItemTextGetItem = nil
			_G.ItemTextGetCreator = nil
			_G.ItemTextGetMaterial = nil
			_G.ItemTextGetText = nil
			BookArchivist.Core = nil
			BookArchivist.RefreshUI = nil
		end)

			after_each(function()
			debug.setupvalue(sessionOwner, sessionIdx, sessionOriginal)
			debug.setupvalue(coreOwner, coreIdx, coreOriginal)
			_G.ItemTextFrame = nil
			_G.UnitGUID = nil
			_G.ItemTextGetPage = nil
			_G.ItemTextGetTitle = nil
			_G.ItemTextGetItem = nil
			_G.ItemTextGetCreator = nil
			_G.ItemTextGetMaterial = nil
			_G.ItemTextGetText = nil
			BookArchivist.Core = nil
			BookArchivist.RefreshUI = nil
		end)

		it("converts string itemIDs to numbers on begin", function()
			_G.ItemTextFrame = { itemID = "42" }
			_G.UnitGUID = function() return nil end
			Capture:OnBegin()
			local newSession = select(1, getCaptureUpvalue("session"))
			assert.is_not_nil(newSession)
			assert.are.equal(42, newSession.itemID)
			assert.are.equal("inventory", newSession.sourceKind)
		end)

		it("captures world locations when no itemID exists", function()
			local ensureSessionLocation = getCaptureUpvalue("ensureSessionLocation")
			local locationValue, locationIdx = getFunctionUpvalue(ensureSessionLocation, "Location")
			local mockLocation = {
				GetLootLocation = function()
					return nil
				end,
				BuildWorldLocation = function()
					return { zoneText = "Fallback" }
				end,
			}
			debug.setupvalue(ensureSessionLocation, locationIdx, mockLocation)
			_G.ItemTextFrame = nil
			Capture:OnBegin()
			local newSession = select(1, getCaptureUpvalue("session"))
			assert.is_not_nil(newSession.location)
			assert.are.equal("Fallback", newSession.location.zoneText)
			debug.setupvalue(ensureSessionLocation, locationIdx, locationValue)
		end)

		it("persists and indexes during OnReady", function()
			local stubCore = {}
			function stubCore:Now()
				return 1111
			end
			function stubCore:PersistSession(data)
				self.persisted = data
				return { id = "book-xyz" }
			end
			function stubCore:IndexItemForBook(itemID, bookId)
				self.indexedItem = { itemID = itemID, bookId = bookId }
			end
			function stubCore:IndexObjectForBook(objectID, bookId)
				self.indexedObject = { objectID = objectID, bookId = bookId }
			end
			BookArchivist.Core = stubCore
			debug.setupvalue(coreOwner, coreIdx, stubCore)
			_G.ItemTextFrame = { itemID = 909, page = 2 }
			_G.ItemTextGetPage = function() return nil end
			_G.ItemTextGetTitle = function() return nil end
			_G.ItemTextGetItem = function() return "Fallback Title" end
			_G.ItemTextGetCreator = function() return nil end
			_G.ItemTextGetMaterial = function() return nil end
			_G.ItemTextGetText = function() return " Page body " end
			_G.UnitGUID = function()
				return "GameObject-0-0-0-0-303"
			end
			Capture:OnReady()
			assert.is_not_nil(stubCore.persisted)
			assert.are.equal("Fallback Title", stubCore.persisted.title)
			assert.are.equal("Page body", stubCore.persisted.pages[1])
			assert.are.equal(909, stubCore.indexedItem.itemID)
			assert.are.equal(303, stubCore.indexedObject.objectID)
		end)

		it("indexes and refreshes when closing session", function()
			local stubCore = {}
			function stubCore:PersistSession(data)
				self.closed = data
				return { id = "book-close" }
			end
			function stubCore:IndexItemForBook(itemID, bookId)
				self.closedItem = { itemID = itemID, bookId = bookId }
			end
			function stubCore:IndexObjectForBook(objectID, bookId)
				self.closedObject = { objectID = objectID, bookId = bookId }
			end
			BookArchivist.Core = stubCore
			debug.setupvalue(coreOwner, coreIdx, stubCore)
			local refreshCount = 0
			BookArchivist.RefreshUI = function()
				refreshCount = refreshCount + 1
			end
			local sessionData = {
				itemID = 700,
				source = { objectID = 808, objectType = "GameObject" },
				pages = {},
				seenPages = {},
			}
			debug.setupvalue(sessionOwner, sessionIdx, sessionData)
			Capture:OnClosed()
			assert.are.equal(700, stubCore.closedItem.itemID)
			assert.are.equal(808, stubCore.closedObject.objectID)
			assert.are.equal(1, refreshCount)
			assert.is_nil(select(1, getCaptureUpvalue("session")))
		end)

		it("returns immediately when closing without session", function()
			debug.setupvalue(sessionOwner, sessionIdx, nil)
			assert.has_no.errors(function()
				Capture:OnClosed()
			end)
		end)
	end)
end)
