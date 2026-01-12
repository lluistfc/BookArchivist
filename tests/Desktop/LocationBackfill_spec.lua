---@diagnostic disable: undefined-global
-- LocationBackfill_spec.lua
-- Tests for automatic location backfill on re-read

describe("Location Backfill on Re-read", function()
	local Core, Location, Repository, BookId
	local testDB
	
	setup(function()
		-- Mock WoW environment
		_G.time = os.time
		_G.BookArchivist = {}
		_G.BookArchivist.L = {
			LOCATION_UNKNOWN_ZONE = "Unknown Zone",
		}
		
		-- Load modules in dependency order (matching TOC order)
		dofile("./core/BookArchivist_Repository.lua")
		dofile("./core/BookArchivist_BookId.lua")
		dofile("./core/BookArchivist_Serialize.lua")
		dofile("./core/BookArchivist_Base64.lua")
		dofile("./core/BookArchivist_CRC32.lua")
		dofile("./core/BookArchivist_Core.lua")  -- Core must load before Order/Search
		dofile("./core/BookArchivist_Location.lua")
		dofile("./core/BookArchivist_Search.lua")
		dofile("./core/BookArchivist_Order.lua")
		
		Repository = BookArchivist.Repository
		Core = BookArchivist.Core
		Location = BookArchivist.Location
		BookId = BookArchivist.BookId
	end)
	
	before_each(function()
		-- Create clean test database
		testDB = {
			dbVersion = 2,
			booksById = {},
			objectToBookId = {},
			itemToBookIds = {},
			titleToBookIds = {},
			order = {},
		}
		
		-- Initialize Repository with test DB
		Repository:Init(testDB)
		
		-- Mock C_Map API
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
		
		-- Mock C_Timer for Core module
		_G.C_Timer = {
			After = function(delay, callback)
				callback()
			end,
		}
	end)
	
	after_each(function()
		-- Restore production DB
		Repository:Init(BookArchivistDB)
	end)
	
	describe("Backfill behavior", function()
		it("should NOT overwrite existing location data on re-read", function()
			-- Build a location for initial capture
			local initialLocation = Location:BuildWorldLocation()
			
			-- First read - capture book with location
			local session1 = {
				title = "Test Book",
				creator = "Author",
				material = "Parchment",
				pages = { [1] = "Page 1 content" },
				source = { kind = "world" },
				location = initialLocation,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			local bookId = book1.id
			
			-- Verify initial location
			assert.is_not_nil(book1.location)
			assert.equals("Eastern Kingdoms", book1.location.zoneChain[1])
			assert.equals("Stormwind City", book1.location.zoneChain[3])
			local originalZoneText = book1.location.zoneText
			
			-- Change location (player moved to Orgrimmar)
			_G.C_Map.GetBestMapForUnit = function(unit)
				return 1519 -- Orgrimmar
			end
			_G.C_Map.GetMapInfo = function(mapID)
				if mapID == 1519 then
					return {
						name = "Orgrimmar",
						mapType = 3,
						parentMapID = 1414,
					}
				elseif mapID == 1414 then
					return {
						name = "Kalimdor",
						mapType = 2,
						parentMapID = nil,
					}
				end
				return nil
			end
			
			local newLocation = Location:BuildWorldLocation()
			
			-- Second read - same book, different location
			local session2 = {
				title = "Test Book",
				creator = "Author",
				material = "Parchment",
				pages = { [1] = "Page 1 content" },
				source = { kind = "world" },
				location = newLocation,
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- CRITICAL: Location should NOT change (preserve original)
			assert.equals(bookId, book2.id)
			assert.is_not_nil(book2.location)
			assert.equals(originalZoneText, book2.location.zoneText)
			assert.equals("Eastern Kingdoms", book2.location.zoneChain[1])
			assert.equals("Stormwind City", book2.location.zoneChain[3])
		end)
		
		it("should backfill location data when book has none (v2.0.2 bug fix)", function()
			-- Simulate book captured during v2.0.2-v2.0.3 bug (no location data)
			local session1 = {
				title = "Broken Book",
				creator = "Unknown",
				material = "Paper",
				pages = { [1] = "Lost location" },
				source = { kind = "world" },
				location = nil, -- Bug: no location captured
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			local bookId = book1.id
			
			-- Verify no location exists (simulates v2.0.2 bug)
			assert.is_nil(book1.location)
			
			-- Player re-reads the book with location capture working
			local currentLocation = Location:BuildWorldLocation()
			
			local session2 = {
				title = "Broken Book",
				creator = "Unknown",
				material = "Paper",
				pages = { [1] = "Lost location" },
				source = { kind = "world" },
				location = currentLocation, -- Now has location
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- BACKFILL: Location should now be populated
			assert.equals(bookId, book2.id)
			assert.is_not_nil(book2.location, "Location should be backfilled")
			assert.is_not_nil(book2.location.zoneChain)
			assert.equals(3, #book2.location.zoneChain)
			assert.equals("Eastern Kingdoms", book2.location.zoneChain[1])
			assert.equals("Elwynn Forest", book2.location.zoneChain[2])
			assert.equals("Stormwind City", book2.location.zoneChain[3])
		end)
		
		it("should handle new book capture with location (normal flow)", function()
			-- Normal capture with working location system
			local currentLocation = Location:BuildWorldLocation()
			
			local session = {
				title = "New Book",
				creator = "Scribe",
				material = "Vellum",
				pages = { [1] = "Fresh content" },
				source = { kind = "world" },
				location = currentLocation,
				startedAt = 1000,
			}
			
			local book = Core:PersistSession(session)
			
			-- Should have location from first capture
			assert.is_not_nil(book.location)
			assert.is_not_nil(book.location.zoneChain)
			assert.equals(3, #book.location.zoneChain)
			assert.equals("Eastern Kingdoms", book.location.zoneChain[1])
		end)
		
		it("should handle book with no location on either capture", function()
			-- Edge case: both captures fail to get location (very rare)
			local session1 = {
				title = "No Location Book",
				creator = "Ghost",
				material = "Ectoplasm",
				pages = { [1] = "Nowhere" },
				source = { kind = "world" },
				location = nil,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			assert.is_nil(book1.location)
			
			-- Re-read, still no location
			local session2 = {
				title = "No Location Book",
				creator = "Ghost",
				material = "Ectoplasm",
				pages = { [1] = "Nowhere" },
				source = { kind = "world" },
				location = nil,
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- Should still have no location (nothing to backfill)
			assert.equals(book1.id, book2.id)
			assert.is_nil(book2.location)
		end)
		
		it("should clone location data (not reference)", function()
			-- Verify that location is cloned, not referenced
			local location1 = Location:BuildWorldLocation()
			
			local session1 = {
				title = "Clone Test Book",
				creator = "Cloner",
				material = "Paper",
				pages = { [1] = "Test cloning" },
				source = { kind = "world" },
				location = location1,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			
			-- Modify the original session location
			location1.zoneChain[1] = "MODIFIED"
			location1.zoneText = "MODIFIED TEXT"
			
			-- Book's location should NOT be affected
			assert.are_not.equals("MODIFIED", book1.location.zoneChain[1])
			assert.are_not.equals("MODIFIED TEXT", book1.location.zoneText)
		end)
		
		it("should handle backfill with partial location data", function()
			-- Book with missing location
			local session1 = {
				title = "Partial Book",
				creator = "Incomplete",
				material = "Fragment",
				pages = { [1] = "Partial" },
				source = { kind = "world" },
				location = nil,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			assert.is_nil(book1.location)
			
			-- Re-read with location that has only some fields
			local partialLocation = {
				context = "world",
				zoneText = "Test Zone",
				capturedAt = 2000,
				-- Missing zoneChain (unusual but testing robustness)
			}
			
			local session2 = {
				title = "Partial Book",
				creator = "Incomplete",
				material = "Fragment",
				pages = { [1] = "Partial" },
				source = { kind = "world" },
				location = partialLocation,
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- Should backfill with whatever location data is available
			assert.is_not_nil(book2.location)
			assert.equals("world", book2.location.context)
			assert.equals("Test Zone", book2.location.zoneText)
		end)
		
		it("should handle empty location table (edge case)", function()
			-- Book without location
			local session1 = {
				title = "Empty Location Book",
				creator = "Void",
				material = "Nothing",
				pages = { [1] = "Empty" },
				source = { kind = "world" },
				location = nil,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			assert.is_nil(book1.location)
			
			-- Re-read with empty table (pathological case)
			local session2 = {
				title = "Empty Location Book",
				creator = "Void",
				material = "Nothing",
				pages = { [1] = "Empty" },
				source = { kind = "world" },
				location = {}, -- Empty table
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- Should backfill even with empty table (truthy value)
			assert.equals(book1.id, book2.id)
			assert.is_not_nil(book2.location)
			assert.equals("table", type(book2.location))
		end)
		
		it("should not backfill if book already has location even if incomplete", function()
			-- First read with minimal location
			local minimalLocation = {
				context = "world",
				zoneText = "Original Zone",
			}
			
			local session1 = {
				title = "Minimal Location Book",
				creator = "First",
				material = "Original",
				pages = { [1] = "First read" },
				source = { kind = "world" },
				location = minimalLocation,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			assert.is_not_nil(book1.location)
			assert.equals("Original Zone", book1.location.zoneText)
			
			-- Second read with complete location
			local completeLocation = Location:BuildWorldLocation()
			
			local session2 = {
				title = "Minimal Location Book",
				creator = "First",
				material = "Original",
				pages = { [1] = "First read" },
				source = { kind = "world" },
				location = completeLocation,
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			
			-- Should preserve original location (even if incomplete)
			assert.equals(book1.id, book2.id)
			assert.equals("Original Zone", book2.location.zoneText)
			-- Should NOT have the complete location's zones
			assert.are_not.equals(completeLocation.zoneText, book2.location.zoneText)
		end)
		
		it("should handle multiple re-reads with different locations", function()
			-- Book without location (v2.0.2 bug scenario)
			local session1 = {
				title = "Multi-Read Book",
				creator = "Traveler",
				material = "Diary",
				pages = { [1] = "Journey" },
				source = { kind = "world" },
				location = nil,
				startedAt = 1000,
			}
			
			local book1 = Core:PersistSession(session1)
			assert.is_nil(book1.location)
			
			-- First re-read in Stormwind
			local swLocation = Location:BuildWorldLocation()
			local session2 = {
				title = "Multi-Read Book",
				creator = "Traveler",
				material = "Diary",
				pages = { [1] = "Journey" },
				source = { kind = "world" },
				location = swLocation,
				startedAt = 2000,
			}
			
			local book2 = Core:PersistSession(session2)
			assert.is_not_nil(book2.location)
			local firstBackfillLocation = book2.location.zoneText
			
			-- Second re-read in Orgrimmar (change location)
			_G.C_Map.GetBestMapForUnit = function(unit)
				return 1519 -- Orgrimmar
			end
			_G.C_Map.GetMapInfo = function(mapID)
				if mapID == 1519 then
					return {
						name = "Orgrimmar",
						mapType = 3,
						parentMapID = 1414,
					}
				elseif mapID == 1414 then
					return {
						name = "Kalimdor",
						mapType = 2,
						parentMapID = nil,
					}
				end
				return nil
			end
			
			local orgLocation = Location:BuildWorldLocation()
			local session3 = {
				title = "Multi-Read Book",
				creator = "Traveler",
				material = "Diary",
				pages = { [1] = "Journey" },
				source = { kind = "world" },
				location = orgLocation,
				startedAt = 3000,
			}
			
			local book3 = Core:PersistSession(session3)
			
			-- Should keep first backfilled location (Stormwind)
			assert.equals(book1.id, book3.id)
			assert.equals(firstBackfillLocation, book3.location.zoneText)
			-- Should NOT have Orgrimmar location
			assert.are_not.equals("Kalimdor", book3.location.zoneChain[1])
		end)
	end)
end)
