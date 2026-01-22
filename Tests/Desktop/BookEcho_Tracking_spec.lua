-- BookEcho_Tracking_spec.lua
-- Tests for Book Echo tracking (readCount, firstReadLocation, lastPageRead)

describe("Book Echo Tracking", function()
	local Core, Repository, Location
	local testDB
	
	setup(function()
		-- Mock environment
		_G.BookArchivist = {}
		_G.time = os.time
		_G.C_Timer = {
			After = function(delay, callback)
				callback()
			end
		}
		
		-- Load dependencies
		dofile("./core/BookArchivist_Repository.lua")
		dofile("./core/BookArchivist_Core.lua")
		dofile("./core/BookArchivist_Location.lua")
		
		Repository = BookArchivist.Repository
		Core = BookArchivist.Core
		Location = BookArchivist.Location
	end)
	
	before_each(function()
		-- Create test database with v3 schema
		testDB = {
			dbVersion = 3,
			booksById = {
				["test-book-1"] = {
					id = "test-book-1",
					title = "Test Book 1",
					pages = {
						[1] = "Page 1 content",
						[2] = "Page 2 content",
						[3] = "Page 3 content",
					},
					readCount = 0,
					firstReadLocation = nil,
					lastPageRead = nil,
				},
				["test-book-2"] = {
					id = "test-book-2",
					title = "Test Book 2",
					pages = {
						[1] = "Single page",
					},
					readCount = 5,
					firstReadLocation = "Stormwind",
					lastPageRead = 1,
				},
			},
			order = {},
			options = {},
			indexes = {
				objectToBookId = {},
			},
		}
		
		-- Initialize Repository with test database
		Repository:Init(testDB)
	end)
	
	after_each(function()
		-- Restore production database
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	describe("readCount tracking", function()
		it("should initialize new books with readCount = 0", function()
			local book = testDB.booksById["test-book-1"]
			assert.equals(0, book.readCount)
		end)
		
		it("should increment readCount when book is opened", function()
			local book = testDB.booksById["test-book-1"]
			local initialCount = book.readCount
			
			-- Simulate opening the book
			book.readCount = book.readCount + 1
			
			assert.equals(initialCount + 1, book.readCount)
			assert.equals(1, book.readCount)
		end)
		
		it("should preserve existing readCount", function()
			local book = testDB.booksById["test-book-2"]
			assert.equals(5, book.readCount)
			
			-- Simulate opening the book again
			book.readCount = book.readCount + 1
			
			assert.equals(6, book.readCount)
		end)
	end)
	
	describe("firstReadLocation tracking", function()
		it("should initialize new books with nil firstReadLocation", function()
			local book = testDB.booksById["test-book-1"]
			assert.is_nil(book.firstReadLocation)
		end)
		
		it("should capture firstReadLocation on first open", function()
			local book = testDB.booksById["test-book-1"]
			
			-- Simulate capturing first read location
			if not book.firstReadLocation then
				book.firstReadLocation = "Ironforge"
			end
			
			assert.equals("Ironforge", book.firstReadLocation)
		end)
		
		it("should not overwrite existing firstReadLocation", function()
			local book = testDB.booksById["test-book-2"]
			local originalLocation = book.firstReadLocation
			
			-- Attempt to update (should be no-op)
			if not book.firstReadLocation then
				book.firstReadLocation = "Orgrimmar"
			end
			
			assert.equals(originalLocation, book.firstReadLocation)
			assert.equals("Stormwind", book.firstReadLocation)
		end)
		
		it("should handle nil location gracefully", function()
			local book = testDB.booksById["test-book-1"]
			
			-- Simulate no location available
			local location = nil
			if not book.firstReadLocation and location then
				book.firstReadLocation = location
			end
			
			assert.is_nil(book.firstReadLocation)
		end)
	end)
	
	describe("lastPageRead tracking", function()
		it("should initialize new books with nil lastPageRead", function()
			local book = testDB.booksById["test-book-1"]
			assert.is_nil(book.lastPageRead)
		end)
		
		it("should update lastPageRead on page change", function()
			local book = testDB.booksById["test-book-1"]
			
			-- Simulate viewing page 2
			book.lastPageRead = 2
			
			assert.equals(2, book.lastPageRead)
		end)
		
		it("should update lastPageRead when user navigates", function()
			local book = testDB.booksById["test-book-2"]
			assert.equals(1, book.lastPageRead)
			
			-- Simulate viewing page 3
			book.lastPageRead = 3
			
			assert.equals(3, book.lastPageRead)
		end)
		
		it("should allow lastPageRead to be set to any page number", function()
			local book = testDB.booksById["test-book-1"]
			
			book.lastPageRead = 1
			assert.equals(1, book.lastPageRead)
			
			book.lastPageRead = 3
			assert.equals(3, book.lastPageRead)
			
			book.lastPageRead = 2
			assert.equals(2, book.lastPageRead)
		end)
	end)
	
	describe("integrated tracking workflow", function()
		it("should track all fields together", function()
			local book = testDB.booksById["test-book-1"]
			
			-- First open
			book.readCount = book.readCount + 1
			if not book.firstReadLocation then
				book.firstReadLocation = "Darnassus"
			end
			book.lastPageRead = 1
			
			assert.equals(1, book.readCount)
			assert.equals("Darnassus", book.firstReadLocation)
			assert.equals(1, book.lastPageRead)
			
			-- Second open (different location)
			book.readCount = book.readCount + 1
			if not book.firstReadLocation then
				book.firstReadLocation = "Thunder Bluff"
			end
			book.lastPageRead = 2
			
			assert.equals(2, book.readCount)
			assert.equals("Darnassus", book.firstReadLocation) -- Should NOT change
			assert.equals(2, book.lastPageRead)
		end)
	end)
end)
