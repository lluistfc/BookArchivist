---@diagnostic disable: undefined-global, undefined-field
-- ListSort_spec.lua
-- Tests for BookArchivist sorting comparators and sort logic
-- Critical path: 251 lines of untested sorting logic

describe("BookArchivist_UI_List_Sort", function()
	local ListUI
	local mockDB
	local mockContext

	setup(function()
		-- Load the addon namespace
		_G.BookArchivist = _G.BookArchivist or {}
		_G.BookArchivist.UI = _G.BookArchivist.UI or {}
		_G.BookArchivist.UI.List = _G.BookArchivist.UI.List or {}
		_G.BookArchivist.L = _G.BookArchivist.L or {}

		-- Load the sort module
		dofile("ui/list/BookArchivist_UI_List_Sort.lua")
		ListUI = _G.BookArchivist.UI.List
	end)

	before_each(function()
		-- Create mock database with v2 schema (booksById)
		mockDB = {
			dbVersion = 2,
			booksById = {
				["book1"] = {
					title = "Alpha Book",
					location = {
						zoneText = "Stormwind City",
						zoneChain = { "Eastern Kingdoms", "Elwynn Forest", "Stormwind City" }
					},
					firstSeenAt = 1000,
					lastSeenAt = 5000,
					createdAt = 1000
				},
				["book2"] = {
					title = "Zeta Book",
					location = {
						zoneText = "Orgrimmar",
						zoneChain = { "Kalimdor", "Durotar", "Orgrimmar" }
					},
					firstSeenAt = 2000,
					lastSeenAt = 4000,
					createdAt = 2000
				},
				["book3"] = {
					title = "  Beta Book  ", -- Has leading/trailing whitespace
					location = {
						zoneText = "",
						zoneChain = { "Broken Isles", "Dalaran" }
					},
					firstSeenAt = 3000,
					lastSeenAt = 3000,
					createdAt = 3000
				},
				["book4"] = {
					title = "GAMMA BOOK", -- All caps
					location = {
						zoneText = nil, -- No zoneText, only zoneChain
						zoneChain = { "Northrend", "Icecrown" }
					},
					firstSeenAt = 4000,
					lastSeenAt = 2000,
					createdAt = 4000
				},
				["book5"] = {
					title = "Delta Book",
					location = nil, -- No location at all
					firstSeenAt = nil, -- No firstSeenAt, should fall back to createdAt
					lastSeenAt = nil,
					createdAt = 5000
				}
			}
		}

		-- Mock context with sort state
		mockContext = {
			sortMode = "title",
			getSortMode = function()
				return mockContext.sortMode
			end,
			setSortMode = function(mode)
				mockContext.sortMode = mode
			end
		}

		-- Mock GetContext
		ListUI.GetContext = function()
			return mockContext
		end
	end)

	describe("GetSortOptions", function()
		it("should return all sort options with translated labels", function()
			local options = ListUI:GetSortOptions()

			assert.is_not_nil(options)
			assert.equals(4, #options)
			assert.equals("title", options[1].value)
			assert.equals("zone", options[2].value)
			assert.equals("firstSeen", options[3].value)
			assert.equals("lastSeen", options[4].value)
		end)
	end)

	describe("GetSortMode", function()
		it("should return current sort mode from context", function()
			mockContext.sortMode = "zone"
			local mode = ListUI:GetSortMode()
			assert.equals("zone", mode)
		end)

		it("should return default 'title' when context returns empty string", function()
			mockContext.getSortMode = function()
				return ""
			end
			local mode = ListUI:GetSortMode()
			assert.equals("title", mode)
		end)

		it("should return default 'title' when context is nil", function()
			ListUI.GetContext = function()
				return nil
			end
			local mode = ListUI:GetSortMode()
			assert.equals("title", mode)
		end)
	end)

	describe("SetSortMode", function()
		it("should update sort mode via context", function()
			ListUI:SetSortMode("lastSeen")
			assert.equals("lastSeen", mockContext.sortMode)
		end)

		it("should handle nil context gracefully", function()
			ListUI.GetContext = function()
				return nil
			end
			assert.has_no.errors(function()
				ListUI:SetSortMode("zone")
			end)
		end)
	end)

	describe("GetSortComparator - title sort", function()
		it("should sort books alphabetically by title (case-insensitive)", function()
			local comparator = ListUI:GetSortComparator("title", mockDB)
			local keys = { "book1", "book2", "book3", "book4", "book5" }
			table.sort(keys, comparator)

			-- Expected order (normalized lowercase, trimmed):
			-- "alpha book", "beta book", "delta book", "gamma book", "zeta book"
			assert.equals("book1", keys[1]) -- Alpha Book
			assert.equals("book3", keys[2]) -- Beta Book (trimmed)
			assert.equals("book5", keys[3]) -- Delta Book
			assert.equals("book4", keys[4]) -- GAMMA BOOK
			assert.equals("book2", keys[5]) -- Zeta Book
		end)

		it("should handle nil titles (sort to beginning)", function()
			mockDB.booksById["book6"] = { title = nil }
			local comparator = ListUI:GetSortComparator("title", mockDB)
			local keys = { "book1", "book6" }
			table.sort(keys, comparator)

			assert.equals("book6", keys[1]) -- nil title sorts first
			assert.equals("book1", keys[2])
		end)

		it("should use bookId as tiebreaker for identical titles", function()
			mockDB.booksById["bookA"] = { title = "Same Title" }
			mockDB.booksById["bookB"] = { title = "Same Title" }
			local comparator = ListUI:GetSortComparator("title", mockDB)
			local keys = { "bookB", "bookA" }
			table.sort(keys, comparator)

			assert.equals("bookA", keys[1]) -- "bookA" < "bookB" lexically
			assert.equals("bookB", keys[2])
		end)
	end)

	describe("GetSortComparator - zone sort", function()
		it("should sort by zoneText when available", function()
			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "book1", "book2" } -- Stormwind City vs Orgrimmar
			table.sort(keys, comparator)

			-- "orgrimmar" < "stormwind city" alphabetically
			assert.equals("book2", keys[1]) -- Orgrimmar
			assert.equals("book1", keys[2]) -- Stormwind City
		end)

		it("should use zoneChain when zoneText is empty", function()
			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "book3", "book4" }
			-- book3: "Broken Isles > Dalaran"
			-- book4: "Northrend > Icecrown"
			table.sort(keys, comparator)

			-- "broken isles > dalaran" < "northrend > icecrown"
			assert.equals("book3", keys[1])
			assert.equals("book4", keys[2])
		end)

		it("should sort books with no location to end (using 'zzzzz')", function()
			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "book1", "book5" } -- book5 has no location
			table.sort(keys, comparator)

			assert.equals("book1", keys[1]) -- Stormwind City
			assert.equals("book5", keys[2]) -- No location (zzzzz)
		end)

		it("should use bookId as tiebreaker for same zone", function()
			mockDB.booksById["zoneA"] = { location = { zoneText = "Same Zone" } }
			mockDB.booksById["zoneB"] = { location = { zoneText = "Same Zone" } }
			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "zoneB", "zoneA" }
			table.sort(keys, comparator)

			assert.equals("zoneA", keys[1])
			assert.equals("zoneB", keys[2])
		end)
	end)

	describe("GetSortComparator - firstSeen sort", function()
		it("should sort by firstSeenAt (ascending, oldest first)", function()
			local comparator = ListUI:GetSortComparator("firstSeen", mockDB)
			local keys = { "book4", "book1", "book2", "book3" }
			-- firstSeenAt: book1=1000, book2=2000, book3=3000, book4=4000
			table.sort(keys, comparator)

			assert.equals("book1", keys[1]) -- 1000
			assert.equals("book2", keys[2]) -- 2000
			assert.equals("book3", keys[3]) -- 3000
			assert.equals("book4", keys[4]) -- 4000
		end)

		it("should fallback to createdAt when firstSeenAt is nil", function()
			local comparator = ListUI:GetSortComparator("firstSeen", mockDB)
			local keys = { "book5", "book1" }
			-- book5: firstSeenAt=nil, createdAt=5000
			-- book1: firstSeenAt=1000
			table.sort(keys, comparator)

			assert.equals("book1", keys[1]) -- 1000
			assert.equals("book5", keys[2]) -- 5000 (from createdAt)
		end)

		it("should use bookId as tiebreaker for same timestamp", function()
			mockDB.booksById["timeA"] = { firstSeenAt = 1000 }
			mockDB.booksById["timeB"] = { firstSeenAt = 1000 }
			local comparator = ListUI:GetSortComparator("firstSeen", mockDB)
			local keys = { "timeB", "timeA" }
			table.sort(keys, comparator)

			assert.equals("timeA", keys[1])
			assert.equals("timeB", keys[2])
		end)

		it("should handle missing both firstSeenAt and createdAt (default to 0)", function()
			mockDB.booksById["book6"] = { firstSeenAt = nil, createdAt = nil }
			local comparator = ListUI:GetSortComparator("firstSeen", mockDB)
			local keys = { "book1", "book6" }
			table.sort(keys, comparator)

			assert.equals("book6", keys[1]) -- 0 (default)
			assert.equals("book1", keys[2]) -- 1000
		end)
	end)

	describe("GetSortComparator - lastSeen sort", function()
		it("should sort by lastSeenAt (descending, newest first)", function()
			local comparator = ListUI:GetSortComparator("lastSeen", mockDB)
			local keys = { "book1", "book2", "book3", "book4" }
			-- lastSeenAt: book1=5000, book2=4000, book3=3000, book4=2000
			table.sort(keys, comparator)

			assert.equals("book1", keys[1]) -- 5000 (newest)
			assert.equals("book2", keys[2]) -- 4000
			assert.equals("book3", keys[3]) -- 3000
			assert.equals("book4", keys[4]) -- 2000 (oldest)
		end)

		it("should fallback to createdAt when lastSeenAt is nil", function()
			local comparator = ListUI:GetSortComparator("lastSeen", mockDB)
			local keys = { "book5", "book1" }
			-- book5: lastSeenAt=nil, createdAt=5000
			-- book1: lastSeenAt=5000
			table.sort(keys, comparator)

			-- Both have effective value 5000, tiebreaker by bookId
			assert.equals("book1", keys[1]) -- "book1" < "book5"
			assert.equals("book5", keys[2])
		end)

		it("should use bookId as tiebreaker for same timestamp", function()
			mockDB.booksById["timeA"] = { lastSeenAt = 4000 }
			mockDB.booksById["timeB"] = { lastSeenAt = 4000 }
			local comparator = ListUI:GetSortComparator("lastSeen", mockDB)
			local keys = { "timeB", "timeA" }
			table.sort(keys, comparator)

			assert.equals("timeA", keys[1])
			assert.equals("timeB", keys[2])
		end)

		it("should handle missing both lastSeenAt and createdAt (default to 0)", function()
			mockDB.booksById["book6"] = { lastSeenAt = nil, createdAt = nil }
			local comparator = ListUI:GetSortComparator("lastSeen", mockDB)
			local keys = { "book1", "book6" }
			table.sort(keys, comparator)

			assert.equals("book1", keys[1]) -- 5000 (newest)
			assert.equals("book6", keys[2]) -- 0 (default, oldest)
		end)
	end)

	describe("GetSortComparator - edge cases", function()
		it("should return nil for invalid sort mode", function()
			local comparator = ListUI:GetSortComparator("invalid", mockDB)
			assert.is_nil(comparator)
		end)

		it("should return nil when database is nil", function()
			local comparator = ListUI:GetSortComparator("title", nil)
			assert.is_nil(comparator)
		end)

		it("should return nil when database has no books", function()
			local emptyDB = { booksById = {} }
			local comparator = ListUI:GetSortComparator("title", emptyDB)
			assert.is_nil(comparator)
		end)

		it("should support legacy v1 schema (books table)", function()
			local legacyDB = {
				version = 1,
				books = {
					["item:1234:page:1"] = { title = "Legacy Book" }
				}
			}
			local comparator = ListUI:GetSortComparator("title", legacyDB)
			assert.is_not_nil(comparator)
		end)
	end)

	describe("ApplySort", function()
		before_each(function()
			-- Mock UpdateSortDropdown
			ListUI.UpdateSortDropdown = function()
				-- noop for tests
			end
			ListUI.GetCategoryId = function()
				return "__all__"
			end
		end)

		it("should sort filtered keys using current sort mode", function()
			mockContext.sortMode = "title"
			local keys = { "book2", "book1", "book3" }

			ListUI:ApplySort(keys, mockDB)

			assert.equals("book1", keys[1]) -- Alpha Book
			assert.equals("book3", keys[2]) -- Beta Book
			assert.equals("book2", keys[3]) -- Zeta Book
		end)

		it("should respect different sort modes", function()
			mockContext.sortMode = "zone"
			local keys = { "book1", "book2" }

			ListUI:ApplySort(keys, mockDB)

			assert.equals("book2", keys[1]) -- Orgrimmar
			assert.equals("book1", keys[2]) -- Stormwind City
		end)

		it("should handle empty keys array", function()
			local keys = {}

			assert.has_no.errors(function()
				ListUI:ApplySort(keys, mockDB)
			end)
			assert.equals(0, #keys)
		end)

		it("should call UpdateSortDropdown after sorting", function()
			local called = false
			ListUI.UpdateSortDropdown = function()
				called = true
			end

			local keys = { "book1", "book2" }
			ListUI:ApplySort(keys, mockDB)

			assert.is_true(called)
		end)

		it("should not crash when comparator is nil", function()
			mockContext.sortMode = "invalid"
			local keys = { "book1", "book2" }

			assert.has_no.errors(function()
				ListUI:ApplySort(keys, mockDB)
			end)
			-- Keys should remain in original order
			assert.equals("book1", keys[1])
			assert.equals("book2", keys[2])
		end)
	end)

	describe("normalizeTextValue (internal function behavior)", function()
		it("should normalize text: lowercase, trim whitespace", function()
			-- Test via comparator behavior
			mockDB.booksById["test1"] = { title = "  SAME  " }
			mockDB.booksById["test2"] = { title = "same" }

			local comparator = ListUI:GetSortComparator("title", mockDB)
			local keys = { "test1", "test2" }
			table.sort(keys, comparator)

			-- Both normalize to "same", tiebreaker by key
			assert.equals("test1", keys[1]) -- "test1" < "test2"
		end)

		it("should handle non-string values (convert to string)", function()
			mockDB.booksById["test1"] = { title = 123 } -- Number
			mockDB.booksById["test2"] = { title = "123" } -- String

			local comparator = ListUI:GetSortComparator("title", mockDB)
			local keys = { "test1", "test2" }
			table.sort(keys, comparator)

			-- Both normalize to "123", tiebreaker by key
			assert.equals("test1", keys[1])
		end)
	end)

	describe("getZoneLabel (internal function behavior)", function()
		it("should prefer zoneText over zoneChain", function()
			-- Test via zone sort comparator
			mockDB.booksById["zone1"] = {
				location = {
					zoneText = "A Zone",
					zoneChain = { "Z", "Z", "Z" }
				}
			}
			mockDB.booksById["zone2"] = {
				location = {
					zoneText = "B Zone",
					zoneChain = { "A", "A", "A" }
				}
			}

			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "zone2", "zone1" }
			table.sort(keys, comparator)

			-- zoneText is used: "a zone" < "b zone"
			assert.equals("zone1", keys[1])
			assert.equals("zone2", keys[2])
		end)

		it("should concatenate zoneChain with ' > ' separator", function()
			mockDB.booksById["chain1"] = {
				location = {
					zoneText = "",
					zoneChain = { "Broken Isles", "Dalaran", "Violet Citadel" }
				}
			}
			mockDB.booksById["chain2"] = {
				location = {
					zoneText = "",
					zoneChain = { "Broken Isles", "Azsuna" }
				}
			}

			local comparator = ListUI:GetSortComparator("zone", mockDB)
			local keys = { "chain1", "chain2" }
			table.sort(keys, comparator)

			-- "broken isles > azsuna" < "broken isles > dalaran > violet citadel"
			assert.equals("chain2", keys[1])
			assert.equals("chain1", keys[2])
		end)
	end)
end)
