-- RandomBook_spec.lua
-- Desktop tests for RandomBook selection

-- Load test helper
local helper = dofile("Tests/test_helper.lua")
helper.setupNamespace()

-- Mock Core module
BookArchivist.Core = BookArchivist.Core or {}
BookArchivist.DebugPrint = function(self, ...) end

-- Load Repository module
helper.loadFile("core/BookArchivist_Repository.lua")

-- Load RandomBook module (will be created)
helper.loadFile("core/BookArchivist_RandomBook.lua")

-- Setup mock database
local function setupMockDB()
	local mockDB = {
		dbVersion = 2,
		booksById = {},
		order = {},
		objectToBookId = {},
		itemToBookIds = {},
		titleToBookIds = {},
	}
	
	-- Initialize Repository with mock database
	BookArchivist.Repository:Init(mockDB)
	
	return mockDB
end

describe("RandomBook Selection", function()
	local RandomBook
	
	setup(function()
		RandomBook = BookArchivist.RandomBook
	end)
	
	before_each(function()
		-- Reset test database
	end)
	
	describe("SelectRandomBook", function()
		it("should return nil for empty library", function()
			local db = setupMockDB()
			local result = RandomBook:SelectRandomBook()
			assert.is_nil(result)
		end)
		
		it("should return the only book in single book library", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = { title = "Test Book" }
			db.order = { bookId }
			
			local result = RandomBook:SelectRandomBook()
			assert.equals(bookId, result)
		end)
		
		it("should return the only book even when excluded (single book edge case)", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = { title = "Test Book" }
			db.order = { bookId }
			
			-- Even when excluded, single book should be returned
			local result = RandomBook:SelectRandomBook(bookId)
			assert.equals(bookId, result)
		end)
		
		it("should exclude currently open book when multiple books exist", function()
			local db = setupMockDB()
			local book1 = "book1"
			local book2 = "book2"
			local book3 = "book3"
			db.booksById[book1] = { title = "Book 1" }
			db.booksById[book2] = { title = "Book 2" }
			db.booksById[book3] = { title = "Book 3" }
			db.order = { book1, book2, book3 }
			
			-- Run multiple times to ensure book1 is never returned
			local results = {}
			for i = 1, 20 do
				local result = RandomBook:SelectRandomBook(book1)
				results[result] = true
			end
			
			-- book1 should never appear in results
			assert.is_nil(results[book1])
			-- book2 or book3 should appear
			assert.is_true(results[book2] or results[book3])
		end)
		
		it("should select from entire library uniformly", function()
			local db = setupMockDB()
			-- Create 5 books
			for i = 1, 5 do
				local bookId = "book" .. i
				db.booksById[bookId] = { title = "Book " .. i }
				table.insert(db.order, bookId)
			end
			
			-- Run many times and check distribution
			local counts = {}
			for i = 1, 100 do
				local result = RandomBook:SelectRandomBook()
				counts[result] = (counts[result] or 0) + 1
			end
			
			-- Each book should be selected at least once in 100 runs
			for i = 1, 5 do
				local bookId = "book" .. i
				assert.is_not_nil(counts[bookId], "Book " .. i .. " should be selected at least once")
				assert.is_true(counts[bookId] > 0)
			end
		end)
		
		it("should handle nil exclude parameter gracefully", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = { title = "Test Book" }
			db.order = { bookId }
			
			local result = RandomBook:SelectRandomBook(nil)
			assert.equals(bookId, result)
		end)
		
		it("should handle non-existent exclude book gracefully", function()
			local db = setupMockDB()
			local book1 = "book1"
			local book2 = "book2"
			db.booksById[book1] = { title = "Book 1" }
			db.booksById[book2] = { title = "Book 2" }
			db.order = { book1, book2 }
			
			-- Exclude a book that doesn't exist
			local result = RandomBook:SelectRandomBook("nonexistent")
			assert.is_not_nil(result)
			assert.is_true(result == book1 or result == book2)
		end)
	end)
	
	describe("NavigateToBookLocation", function()
		local mockUI
		
		before_each(function()
			-- Setup mock UI for navigation
			mockUI = {
				modeSet = nil,
				keySet = nil,
				renderCalled = false,
				updateCalled = false,
				locationState = {
					path = {},
					currentPage = 1,
				},
				ensureLocationPathValidCalled = false,
				rebuildLocationRowsCalled = false,
				updateLocationBreadcrumbCalled = false,
			}
			
			BookArchivist.UI = BookArchivist.UI or {}
			BookArchivist.UI.List = {
				SetListMode = function(self, mode)
					mockUI.modeSet = mode
				end,
				SetSelectedKey = function(self, key)
					mockUI.keySet = key
				end,
				NotifySelectionChanged = function(self)
					-- Mock notification
				end,
				UpdateList = function(self)
					mockUI.updateCalled = true
				end,
				GetLocationState = function(self)
					return mockUI.locationState
				end,
				EnsureLocationPathValid = function(self, state)
					mockUI.ensureLocationPathValidCalled = true
				end,
				RebuildLocationRows = function(state, self, pageSize, page)
					mockUI.rebuildLocationRowsCalled = true
				end,
				UpdateLocationBreadcrumbUI = function(self)
					mockUI.updateLocationBreadcrumbCalled = true
				end,
				GetPageSize = function(self)
					return 25
				end,
			}
			BookArchivist.UI.Reader = {
				RenderSelected = function(self)
					mockUI.renderCalled = true
				end,
			}
		end)
		
		it("should switch to locations mode and select book", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				location = {
					zoneChain = { "Azeroth", "Stormwind", "Trade District" }
				}
			}
			db.order = { bookId }
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			assert.equals("locations", mockUI.modeSet)
			
			-- Verify location navigation
			assert.are.same({ "Azeroth", "Stormwind", "Trade District" }, mockUI.locationState.path)
			assert.equals(1, mockUI.locationState.currentPage)
			assert.is_true(mockUI.ensureLocationPathValidCalled)
			assert.is_true(mockUI.rebuildLocationRowsCalled)
			assert.is_true(mockUI.updateLocationBreadcrumbCalled)
			
			assert.is_true(mockUI.updateCalled)
			assert.equals(bookId, mockUI.keySet)
			assert.is_true(mockUI.renderCalled)
		end)
		
		it("should navigate to correct location path for book with zoneChain", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				location = {
					zoneChain = { "Eastern Kingdoms", "Elwynn Forest", "Goldshire" }
				}
			}
			db.order = { bookId }
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			-- Verify the exact path was set
			assert.are.same({ "Eastern Kingdoms", "Elwynn Forest", "Goldshire" }, mockUI.locationState.path)
			assert.equals(1, mockUI.locationState.currentPage)
		end)
		
		it("should reset page to 1 when navigating to location", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				location = {
					zoneChain = { "Kalimdor", "Durotar" }
				}
			}
			db.order = { bookId }
			
			-- Set page to something other than 1
			mockUI.locationState.currentPage = 5
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			-- Should reset to page 1
			assert.equals(1, mockUI.locationState.currentPage)
		end)
		
		it("should call all location navigation functions", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				location = {
					zoneChain = { "Zone1", "Zone2" }
				}
			}
			db.order = { bookId }
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			assert.is_true(mockUI.ensureLocationPathValidCalled)
			assert.is_true(mockUI.rebuildLocationRowsCalled)
			assert.is_true(mockUI.updateLocationBreadcrumbCalled)
		end)
		
		it("should handle missing book gracefully", function()
			local db = setupMockDB()
			
			local result = RandomBook:NavigateToBookLocation("nonexistent")
			
			assert.is_false(result)
			assert.is_nil(mockUI.modeSet)
			assert.is_nil(mockUI.keySet)
			assert.is_false(mockUI.renderCalled)
		end)
		
		it("should stay in current mode when location missing", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				-- No location data
			}
			db.order = { bookId }
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			-- Should not change mode when location is missing
			assert.is_nil(mockUI.modeSet)
			assert.equals(bookId, mockUI.keySet)
			assert.is_true(mockUI.renderCalled)
		end)
		
		it("should stay in current mode when zoneChain empty", function()
			local db = setupMockDB()
			local bookId = "book1"
			db.booksById[bookId] = {
				title = "Test Book",
				location = {
					zoneChain = {} -- Empty chain
				}
			}
			db.order = { bookId }
			
			local result = RandomBook:NavigateToBookLocation(bookId)
			
			assert.is_true(result)
			-- Should not change mode when zoneChain is empty
			assert.is_nil(mockUI.modeSet)
			assert.equals(bookId, mockUI.keySet)
			assert.is_true(mockUI.renderCalled)
		end)
		
		it("should handle nil book ID", function()
			local db = setupMockDB()
			
			local result = RandomBook:NavigateToBookLocation(nil)
			
			assert.is_false(result)
			assert.is_nil(mockUI.modeSet)
		end)
	end)
	
	describe("OpenRandomBook", function()
		local mockUI
		
		before_each(function()
			mockUI = {
				modeSet = nil,
				keySet = nil,
				renderCalled = false,
				updateCalled = false,
				locationState = {
					path = {},
					currentPage = 1,
				},
			}
			
			BookArchivist.UI = BookArchivist.UI or {}
			BookArchivist.UI.List = {
				SetListMode = function(self, mode)
					mockUI.modeSet = mode
				end,
				SetSelectedKey = function(self, key)
					mockUI.keySet = key
				end,
				GetSelectedKey = function(self)
					return mockUI.keySet
				end,
				GetLocationState = function(self)
					return mockUI.locationState
				end,
				GetListMode = function(self)
					return mockUI.modeSet
				end,
				RebuildLocationTree = function(self)
					-- Mock - tree doesn't exist, will trigger async path
				end,
				NotifySelectionChanged = function(self)
					-- Mock
				end,
				UpdateList = function(self)
					mockUI.updateCalled = true
				end,
			}
			BookArchivist.UI.Reader = {
				RenderSelected = function(self)
					mockUI.renderCalled = true
				end,
			}
		end)
		
		it("should select and navigate to random book", function()
			local db = setupMockDB()
			local book1 = "book1"
			local book2 = "book2"
			db.booksById[book1] = {
				title = "Book 1",
				location = { zoneChain = { "Zone1" } }
			}
			db.booksById[book2] = {
				title = "Book 2",
				location = { zoneChain = { "Zone2" } }
			}
			db.order = { book1, book2 }
			
			local result = RandomBook:OpenRandomBook()
			
			assert.is_true(result)
			assert.is_not_nil(mockUI.keySet)
			assert.is_true(mockUI.keySet == book1 or mockUI.keySet == book2)
			assert.equals("locations", mockUI.modeSet)
			assert.is_true(mockUI.renderCalled)
		end)
		
		it("should exclude currently selected book", function()
			local db = setupMockDB()
			local book1 = "book1"
			local book2 = "book2"
			db.booksById[book1] = {
				title = "Book 1",
				location = { zoneChain = { "Zone1" } }
			}
			db.booksById[book2] = {
				title = "Book 2",
				location = { zoneChain = { "Zone2" } }
			}
			db.order = { book1, book2 }
			
			-- Simulate book1 currently selected
			mockUI.keySet = book1
			
			local result = RandomBook:OpenRandomBook()
			
			assert.is_true(result)
			-- Should select book2 since book1 is current
			assert.equals(book2, mockUI.keySet)
		end)
		
		it("should return false for empty library", function()
			local db = setupMockDB()
			
			local result = RandomBook:OpenRandomBook()
			
			assert.is_false(result)
			assert.is_nil(mockUI.modeSet)
			assert.is_false(mockUI.renderCalled)
		end)
	end)
end)
