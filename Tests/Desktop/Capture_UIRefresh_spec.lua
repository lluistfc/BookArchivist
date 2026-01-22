-- Tests for Capture module UI refresh behavior
-- Verifies that RefreshUI is called the correct number of times

local helper = require("tests/test_helper")

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

		-- Load BookId module (required by Core.PersistSession)
		helper.loadFile("core/BookArchivist_CRC32.lua")
		helper.loadFile("core/BookArchivist_BookId.lua")

		-- Load Core module FIRST (Order module needs Core to exist)
		helper.loadFile("core/BookArchivist_Core.lua")
		Core = BookArchivist.Core
		
		-- Then load Order module (attaches methods to Core)
		helper.loadFile("core/BookArchivist_Order.lua")

		-- Load Capture module
		helper.loadFile("core/BookArchivist_Location.lua")
		helper.loadFile("core/BookArchivist_Capture.lua")
		Capture = BookArchivist.Capture

		-- Create a spy for RefreshUI using Busted's built-in spy functionality
		BookArchivist.RefreshUI = function() end
		refreshSpy = spy.on(BookArchivist, "RefreshUI")

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
		-- Restore production database (Repository pattern cleanup)
		if BookArchivist and BookArchivist.Repository and _G.BookArchivistDB then
			BookArchivist.Repository:Init(_G.BookArchivistDB)
		end
	end)

	describe("Single-page book capture", function()
		it("should call RefreshUI exactly once on close (not on each page)", function()
			-- Start capture
			Capture:OnBegin()
			assert.spy(refreshSpy).was_not.called()

			-- Read one page
			Capture:OnReady()
			assert.spy(refreshSpy).was_not.called()

			-- Close book
			Capture:OnClosed()
			
			-- Verify RefreshUI was called exactly once
			assert.spy(refreshSpy).was.called(1)
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
			assert.spy(refreshSpy).was_not.called()

			-- Read page 1
			Capture:OnReady()
			pageCount = pageCount + 1
			assert.spy(refreshSpy).was_not.called()

			-- Read page 2
			Capture:OnReady()
			pageCount = pageCount + 1
			assert.spy(refreshSpy).was_not.called()

			-- Read page 3 (final page)
			Capture:OnReady()
			pageCount = pageCount + 1
			assert.spy(refreshSpy).was_not.called()

			-- Close book
			Capture:OnClosed()
			assert.spy(refreshSpy).was.called(1)
		end)
	end)

	describe("Capture without session", function()
		it("should not call RefreshUI if OnClosed is called without a session", function()
			-- Call OnClosed without OnBegin/OnReady
			Capture:OnClosed()
			assert.spy(refreshSpy).was_not.called()
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
			assert.spy(refreshSpy).was_not.called()

			Capture:OnClosed()
			assert.spy(refreshSpy).was.called(1)
		end)
	end)
end)
