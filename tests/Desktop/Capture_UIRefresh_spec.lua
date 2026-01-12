-- Tests for Capture module UI refresh behavior
-- Verifies that RefreshUI is called the correct number of times

local helper = require("tests/test_helper")
local SpyHelpers = require("tests/helpers/spy_helpers")

describe("Capture System UI Refresh Behavior", function()
	local Capture
	local Core
	local BookArchivist
	local refreshSpy

	before_each(function()
		-- Reset globals
		_G.BookArchivist = nil
		_G.BookArchivistDB = nil

		-- Setup namespace
		helper.setupNamespace()
		BookArchivist = _G.BookArchivist

		-- Load Repository module first (required for dependency injection)
		helper.loadFile("core/BookArchivist_Repository.lua")

		-- Initialize a test database
		local testDB = {
			dbVersion = 2,
			booksById = {},
			order = {},
			indexes = {
				objectToBookId = {},
				itemToBookIds = {},
				titleToBookIds = {}
			},
			options = {},
			recent = { list = {}, cap = 50 },
			uiState = {}
		}

		-- Initialize Repository with test database (dependency injection)
		BookArchivist.Repository:Init(testDB)

		-- Load Core module FIRST (Order module needs Core to exist)
		helper.loadFile("core/BookArchivist_Core.lua")
		Core = BookArchivist.Core
		
		-- Then load Order module (attaches methods to Core)
		helper.loadFile("core/BookArchivist_Order.lua")

		-- Load Capture module
		helper.loadFile("core/BookArchivist_Location.lua")
		helper.loadFile("core/BookArchivist_Capture.lua")
		Capture = BookArchivist.Capture

		-- Create a mock RefreshUI function that we can spy on
		BookArchivist.RefreshUI = SpyHelpers.mockFunction()
		refreshSpy = BookArchivist.RefreshUI

		-- Mock WoW API functions
		_G.ItemTextGetTitle = function() return "Test Book" end
		_G.ItemTextGetCreator = function() return "Test Author" end
		_G.ItemTextGetMaterial = function() return "Parchment" end
		_G.ItemTextGetText = function() return "Page content" end
		_G.ItemTextGetPage = function() return 1 end
		_G.ItemTextHasNextPage = function() return false end
		_G.UnitGUID = function() return "GameObject-0-123456" end

		-- Mock C_Timer API (required by Core module)
		_G.C_Timer = {
			After = function(delay, callback)
				-- Execute immediately in tests
				if callback then callback() end
			end
		}

		-- Mock C_Map API
		_G.C_Map = {
			GetBestMapForUnit = function() return 1950 end,
			GetMapInfo = function(mapID)
				if mapID == 1950 then
					return { name = "Stormwind City", mapType = 3 }
				end
				return nil
			end,
			GetMapGroupMembersInfo = function() return {} end
		}

		_G.GetRealZoneText = function() return "Stormwind City" end
		_G.GetSubZoneText = function() return "" end
	end)

	after_each(function()
		if refreshSpy then
			refreshSpy.reset()
		end
		
		-- Restore production database (Repository pattern cleanup)
		if BookArchivist and BookArchivist.Repository and _G.BookArchivistDB then
			BookArchivist.Repository:Init(_G.BookArchivistDB)
		end
	end)

	describe("Single-page book capture", function()
		it("should call RefreshUI exactly once on close (not on each page)", function()
			-- Start capture
			Capture:OnBegin()
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on Begin")

			-- Read one page
			Capture:OnReady()
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on page read (OnReady)")

			-- Close book
			Capture:OnClosed()
			SpyHelpers.assertCalledTimes(refreshSpy, 1, "RefreshUI should be called exactly once on Close")
		end)
	end)

	describe("Multi-page book capture", function()
		it("should call RefreshUI exactly once regardless of page count", function()
			-- Simulate a 3-page book
			local pageCount = 0
			_G.ItemTextHasNextPage = function()
				return pageCount < 2 -- Has next page for first 2 calls
			end
			_G.ItemTextGetPage = function()
				return pageCount + 1
			end

			-- Start capture
			Capture:OnBegin()
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on Begin")

			-- Read page 1
			Capture:OnReady()
			pageCount = pageCount + 1
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on page 1")

			-- Read page 2
			Capture:OnReady()
			pageCount = pageCount + 1
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on page 2")

			-- Read page 3 (final page)
			Capture:OnReady()
			pageCount = pageCount + 1
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called on page 3")

			-- Close book
			Capture:OnClosed()
			SpyHelpers.assertCalledTimes(refreshSpy, 1, "RefreshUI should be called exactly once after reading all pages")
		end)
	end)

	describe("Capture without session", function()
		it("should not call RefreshUI if OnClosed is called without a session", function()
			-- Call OnClosed without OnBegin/OnReady
			Capture:OnClosed()
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called if no session exists")
		end)
	end)

	describe("Regression: Infinite refresh loop prevention", function()
		it("should not cause cascading refreshes on multi-page books", function()
			-- This test ensures we don't regress to the infinite loop bug
			-- where OnReady called RefreshUI on every page
			
			local pageCount = 0
			_G.ItemTextHasNextPage = function() return pageCount < 4 end
			_G.ItemTextGetPage = function() return pageCount + 1 end

			Capture:OnBegin()

			-- Simulate reading 5 pages
			for i = 1, 5 do
				Capture:OnReady()
				pageCount = pageCount + 1
			end

			-- At this point, if there was a bug, RefreshUI would have been called 5 times
			SpyHelpers.assertNotCalled(refreshSpy, "RefreshUI should not be called during page reads")

			Capture:OnClosed()
			SpyHelpers.assertCalledTimes(refreshSpy, 1, "RefreshUI should only be called once on close")
		end)
	end)
end)
