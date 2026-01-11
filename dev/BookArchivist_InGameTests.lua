---@diagnostic disable: undefined-global
-- BookArchivist_InGameTests.lua
-- In-game tests that use real WoW APIs
-- Registered with Mechanic for in-game execution

local Tests = {}
BookArchivist.InGameTests = Tests

-- ============================================================================
-- TEST UTILITIES
-- ============================================================================

-- Create a test database with sample data
local function createTestDB()
	return {
		dbVersion = 2,
		booksById = {
			["test_book_1"] = {
				bookId = "test_book_1",
				title = "Test Book 1",
				creator = "Test Author",
				material = "Parchment",
				pages = {
					[1] = "First page content",
					[2] = "Second page content",
					[3] = "Third page content",
				},
				lastSeenAt = time(),
				isFavorite = false,
				location = { zone = "Stormwind", object = "Test Object" },
			},
			["test_book_2"] = {
				bookId = "test_book_2",
				title = "Test Book 2",
				pages = {
					[1] = "Single page book",
				},
				lastSeenAt = time(),
				isFavorite = false,
			},
			["favorite_book"] = {
				bookId = "favorite_book",
				title = "Favorite Book",
				pages = {
					[1] = "Favorite content",
				},
				lastSeenAt = time(),
				isFavorite = true,
			},
		},
		order = { "test_book_1", "test_book_2", "favorite_book" },
		objectToBookId = {},
		itemToBookIds = {},
		titleToBookIds = {},
		recent = {
			cap = 50,
			list = {},
		},
		uiState = {},
		options = {},
	}
end

-- Test database isolation (TestContainers pattern)
local testDB = nil
local originalGetDB = nil
local originalBookArchivistDB = nil
local debugLog = {}

local function setupTestDB()
	-- Save original GetDB function AND global DB
	originalGetDB = BookArchivist.Core.GetDB
	originalBookArchivistDB = BookArchivistDB
	
	-- Create isolated test database
	testDB = createTestDB()
	
	-- Clear debug log
	debugLog = {}
	
	-- CRITICAL: Override BOTH the function AND the global
	-- Modules use local getDB() that falls back to BookArchivistDB global
	BookArchivistDB = testDB
	BookArchivist.Core.GetDB = function(self)
		table.insert(debugLog, "GetDB called, returning testDB")
		return testDB
	end
end

local function teardownTestDB()
	-- Restore original GetDB function AND global DB
	if originalGetDB then
		BookArchivist.Core.GetDB = originalGetDB
		originalGetDB = nil
	end
	if originalBookArchivistDB ~= nil then
		BookArchivistDB = originalBookArchivistDB
		originalBookArchivistDB = nil
	elseif originalBookArchivistDB == nil then
		-- DB was nil before, restore to nil
		BookArchivistDB = nil
	end
	
	-- Discard test database
	testDB = nil
	debugLog = {}
end

local function getDebugLog()
	return table.concat(debugLog, " | ")
end

-- ============================================================================
-- CORE MODULE TESTS
-- ============================================================================

-- Test: Favorites.Set marks a book as favorite
function Tests.test_favorites_set_true()
	local dbBefore = BookArchivist.Core:GetDB()
	local bookBefore = dbBefore.booksById["test_book_1"]
	if not bookBefore then
		return false, "Test DB setup failed: test_book_1 not found"
	end
	local initialFav = bookBefore.isFavorite
	
	-- Trace: Check what Favorites module will see
	local FavoritesModule = BookArchivist.Favorites
	if not FavoritesModule then
		return false, "Favorites module not loaded"
	end

	-- Set book as favorite
	BookArchivist.Favorites:Set("test_book_1", true)

	-- Verify - call GetDB again to see if it's still the same reference
	local dbAfter = BookArchivist.Core:GetDB()
	
	-- Check if they're literally the same table
	local sameDBRef = (dbBefore == dbAfter)
	
	local bookAfter = dbAfter.booksById["test_book_1"]
	if not bookAfter then
		return false, "Book disappeared after Favorites:Set()"
	end
	
	-- Check if book objects are same reference
	local sameBookRef = (bookBefore == bookAfter)

	-- Also check what the production DB says
	local prodDB = BookArchivistDB
	local prodBook = prodDB and prodDB.booksById and prodDB.booksById["test_book_1"]
	local prodFav = prodBook and prodBook.isFavorite or "NO_PROD_BOOK"

	if bookAfter.isFavorite ~= true then
		return false, string.format(
			"Favorites:Set did not work: expected true, got %s (initial=%s, sameDB=%s, sameBook=%s, prodFav=%s, dbCalls=%s)",
			tostring(bookAfter.isFavorite),
			tostring(initialFav),
			tostring(sameDBRef),
			tostring(sameBookRef),
			tostring(prodFav),
			getDebugLog()
		)
	end

	return true, "Book marked as favorite successfully"
end

-- Test: Favorites.Set removes favorite
function Tests.test_favorites_set_false()
	local dbBefore = BookArchivist.Core:GetDB()
	local bookBefore = dbBefore.booksById["favorite_book"]
	if not bookBefore then
		return false, "Test DB setup failed: favorite_book not found"
	end
	local initialFav = bookBefore.isFavorite

	-- Remove favorite
	BookArchivist.Favorites:Set("favorite_book", false)

	-- Verify
	local dbAfter = BookArchivist.Core:GetDB()
	local bookAfter = dbAfter.booksById["favorite_book"]
	if not bookAfter then
		return false, "Book disappeared after Favorites:Set()"
	end

	if bookAfter.isFavorite ~= false then
		return false, string.format(
			"Expected isFavorite=false, got %s (initial=%s, dbBefore=%s, dbAfter=%s)",
			tostring(bookAfter.isFavorite),
			tostring(initialFav),
			tostring(dbBefore),
			tostring(dbAfter)
		)
	end

	return true, "Favorite removed successfully"
end

-- Test: Favorites.Toggle toggles favorite state
function Tests.test_favorites_toggle()
	local dbBefore = BookArchivist.Core:GetDB()
	local bookBefore = dbBefore.booksById["test_book_1"]
	if not bookBefore then
		return false, "Test DB setup failed: test_book_1 not found"
	end

	-- Get initial state
	local wasFavorite = bookBefore.isFavorite

	-- Toggle
	BookArchivist.Favorites:Toggle("test_book_1")

	-- Verify
	local dbAfter = BookArchivist.Core:GetDB()
	local bookAfter = dbAfter.booksById["test_book_1"]
	if not bookAfter then
		return false, "Book disappeared after Favorites:Toggle()"
	end

	if bookAfter.isFavorite == wasFavorite then
		return false, string.format(
			"Toggle failed: was %s, still %s (dbBefore=%s, dbAfter=%s)",
			tostring(wasFavorite),
			tostring(bookAfter.isFavorite),
			tostring(dbBefore),
			tostring(dbAfter)
		)
	end

	return true, "Favorite toggled successfully"
end

-- Test: Recent.MarkOpened adds book to recent list
function Tests.test_recent_mark_opened()
	local db = BookArchivist.Core:GetDB()

	-- Mark as opened
	BookArchivist.Recent:MarkOpened("test_book_1")

	-- Verify
	if #db.recent.list == 0 then
		return false, "Recent list should not be empty"
	end

	if db.recent.list[1] ~= "test_book_1" then
		return false, "test_book_1 should be first in recent list"
	end

	return true, "Book added to recent list"
end

-- Test: Recent.GetList returns MRU order
function Tests.test_recent_get_list_mru()
	local db = BookArchivist.Core:GetDB()

	-- Mark multiple books as opened
	BookArchivist.Recent:MarkOpened("test_book_1")
	BookArchivist.Recent:MarkOpened("test_book_2")
	BookArchivist.Recent:MarkOpened("favorite_book")

	-- Get list
	local list = BookArchivist.Recent:GetList()

	-- Verify MRU order (most recent first)
	if #list ~= 3 then
		return false, "Expected 3 books in recent list, got " .. #list
	end

	if list[1] ~= "favorite_book" then
		return false, "Most recent book should be first, got " .. tostring(list[1])
	end

	return true, "Recent list in correct MRU order"
end

-- ============================================================================
-- SEARCH MODULE TESTS
-- ============================================================================

-- Test: Search.NormalizeSearchText lowercases input
function Tests.test_search_normalize_lowercase()
	local result = BookArchivist.Search.NormalizeSearchText("Hello WORLD")

	if result ~= "hello world" then
		return false, "Expected 'hello world', got '" .. result .. "'"
	end

	return true, "Text normalized to lowercase"
end

-- Test: Search.NormalizeSearchText strips color codes
function Tests.test_search_normalize_strips_colors()
	local result = BookArchivist.Search.NormalizeSearchText("|cFFFF0000Red|r Text")

	if result ~= "red text" then
		return false, "Expected 'red text', got '" .. result .. "'"
	end

	return true, "Color codes stripped"
end

-- Test: Search.BuildSearchText builds from title and pages
function Tests.test_search_build_from_title_and_pages()
	local pages = {
		[1] = "Page One Content",
		[2] = "Page Two Content",
	}

	local searchText = BookArchivist.Search.BuildSearchText("Test Title", pages)

	-- Should contain lowercase title
	if not searchText:find("test title", 1, true) then
		return false, "SearchText should contain lowercase title"
	end

	-- Should contain lowercase page content
	if not searchText:find("page one content", 1, true) then
		return false, "SearchText should contain page content"
	end

	return true, "SearchText built correctly"
end

-- ============================================================================
-- ORDER MODULE TESTS
-- ============================================================================

-- Test: Order.TouchOrder moves book to beginning
function Tests.test_order_touch_moves_to_beginning()
	local db = BookArchivist.Core:GetDB()

	-- Initial order: test_book_1, test_book_2, favorite_book
	-- Touch test_book_2 (middle)
	BookArchivist.Core:TouchOrder("test_book_2")

	-- Verify test_book_2 is now first
	if db.order[1] ~= "test_book_2" then
		return false, "test_book_2 should be first, got " .. tostring(db.order[1])
	end

	if #db.order ~= 3 then
		return false, "Order should still have 3 books, got " .. #db.order
	end

	return true, "Book moved to beginning"
end

-- Test: Order.AppendOrder moves book to end
function Tests.test_order_append_moves_to_end()
	local db = BookArchivist.Core:GetDB()

	-- Append test_book_1 (currently first)
	BookArchivist.Core:AppendOrder("test_book_1")

	-- Verify test_book_1 is now last
	if db.order[3] ~= "test_book_1" then
		return false, "test_book_1 should be last, got " .. tostring(db.order[3])
	end

	return true, "Book moved to end"
end

-- ============================================================================
-- UI MODULE TESTS (require actual frames)
-- ============================================================================

-- Test: Reader can display a book
function Tests.test_reader_display_book()
	-- This test requires UI to be loaded
	if not BookArchivist.UI or not BookArchivist.UI.Reader then
		return nil, "UI not loaded (test requires in-game)"
	end

	-- Try to render a book
	local success = pcall(function()
		BookArchivist.UI.Internal.setSelectedKey("test_book_1")
		BookArchivist.UI.Reader:RenderSelected()
	end)

	if not success then
		return false, "Failed to render book in reader"
	end

	return true, "Reader displayed book without errors"
end

-- Test: Reader page navigation
function Tests.test_reader_page_navigation()
	if not BookArchivist.UI or not BookArchivist.UI.Reader then
		return nil, "UI not loaded (test requires in-game)"
	end

	local success = pcall(function()
		-- Show book with 3 pages
		BookArchivist.UI.Internal.setSelectedKey("test_book_1")
		BookArchivist.UI.Reader:RenderSelected()

		-- Navigate forward
		BookArchivist.UI.Reader:ChangePage(1)

		-- Navigate backward
		BookArchivist.UI.Reader:ChangePage(-1)
	end)

	if not success then
		return false, "Failed to navigate pages"
	end

	return true, "Page navigation works"
end

-- ============================================================================
-- TEST REGISTRY
-- ============================================================================

-- Get all available tests
function Tests.GetAll()
	local allTests = {}

	-- Core module tests (no UI required)
	table.insert(allTests, {
		id = "favorites_set_true",
		name = "Favorites: Set favorite true",
		category = "Core",
		type = "auto",
		description = "Tests marking a book as favorite",
		func = Tests.test_favorites_set_true,
	})

	table.insert(allTests, {
		id = "favorites_set_false",
		name = "Favorites: Set favorite false",
		category = "Core",
		type = "auto",
		description = "Tests removing favorite status",
		func = Tests.test_favorites_set_false,
	})

	table.insert(allTests, {
		id = "favorites_toggle",
		name = "Favorites: Toggle favorite",
		category = "Core",
		type = "auto",
		description = "Tests toggling favorite state",
		func = Tests.test_favorites_toggle,
	})

	table.insert(allTests, {
		id = "recent_mark_opened",
		name = "Recent: Mark book opened",
		category = "Core",
		type = "auto",
		description = "Tests adding book to recent list",
		func = Tests.test_recent_mark_opened,
	})

	table.insert(allTests, {
		id = "recent_get_list_mru",
		name = "Recent: Get MRU list",
		category = "Core",
		type = "auto",
		description = "Tests recent list ordering",
		func = Tests.test_recent_get_list_mru,
	})

	table.insert(allTests, {
		id = "search_normalize_lowercase",
		name = "Search: Normalize to lowercase",
		category = "Core",
		type = "auto",
		description = "Tests text normalization",
		func = Tests.test_search_normalize_lowercase,
	})

	table.insert(allTests, {
		id = "search_normalize_strips_colors",
		name = "Search: Strip color codes",
		category = "Core",
		type = "auto",
		description = "Tests color code removal",
		func = Tests.test_search_normalize_strips_colors,
	})

	table.insert(allTests, {
		id = "search_build_searchtext",
		name = "Search: Build search text",
		category = "Core",
		type = "auto",
		description = "Tests search text generation",
		func = Tests.test_search_build_from_title_and_pages,
	})

	table.insert(allTests, {
		id = "order_touch_moves_to_beginning",
		name = "Order: Touch moves to beginning",
		category = "Core",
		type = "auto",
		description = "Tests TouchOrder functionality",
		func = Tests.test_order_touch_moves_to_beginning,
	})

	table.insert(allTests, {
		id = "order_append_moves_to_end",
		name = "Order: Append moves to end",
		category = "Core",
		type = "auto",
		description = "Tests AppendOrder functionality",
		func = Tests.test_order_append_moves_to_end,
	})

	-- UI tests (require addon UI to be loaded)
	table.insert(allTests, {
		id = "reader_display_book",
		name = "Reader: Display book",
		category = "UI",
		type = "auto",
		description = "Tests reader can display a book",
		func = Tests.test_reader_display_book,
	})

	table.insert(allTests, {
		id = "reader_page_navigation",
		name = "Reader: Page navigation",
		category = "UI",
		type = "auto",
		description = "Tests reader page navigation",
		func = Tests.test_reader_page_navigation,
	})

	return allTests
end

-- Run a specific test by ID
function Tests.Run(testId)
	local allTests = Tests.GetAll()

	for _, test in ipairs(allTests) do
		if test.id == testId then
			-- Setup isolated test database (NEVER touch production DB)
			setupTestDB()
			
			local success, result, message = pcall(test.func)

			-- Always teardown test database
			teardownTestDB()

			if not success then
				-- Test threw an error
				return {
					passed = false,
					message = "Test error: " .. tostring(result),
					duration = 0,
				}
			end

			-- Test returned result
			return {
				passed = result,
				message = message or (result and "Test passed" or "Test failed"),
				duration = 0, -- TODO: Track actual duration
			}
		end
	end

	return {
		passed = false,
		message = "Test not found: " .. testId,
		duration = 0,
	}
end

-- Run all tests
function Tests.RunAll()
	local allTests = Tests.GetAll()
	local passed = 0
	local total = #allTests
	local results = {}

	for _, test in ipairs(allTests) do
		local result = Tests.Run(test.id)
		results[test.id] = result

		if result.passed == true then
			passed = passed + 1
		end
	end

	return passed, total, results
end

print("|cff00ff00[BookArchivist]|r In-game tests module loaded (" .. #Tests.GetAll() .. " tests)")
