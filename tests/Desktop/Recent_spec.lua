-- Recent_spec.lua
-- Sandbox tests for Recent books tracking

-- Load test helper
local helper = dofile("Tests/test_helper.lua")
helper.setupNamespace()

-- Mock Core module
BookArchivist.Core = BookArchivist.Core or {}
BookArchivist.DebugPrint = function(self, ...) end

-- Load Recent module
helper.loadFile("core/BookArchivist_Recent.lua")

-- Setup mock database
local function setupMockDB()
	BookArchivist.Core = BookArchivist.Core or {}

	local mockTime = 1000

	local mockDB = {
		booksById = {
			["book1"] = { bookId = "book1", title = "Book 1", lastReadAt = 0, updatedAt = 0 },
			["book2"] = { bookId = "book2", title = "Book 2", lastReadAt = 0, updatedAt = 0 },
			["book3"] = { bookId = "book3", title = "Book 3", lastReadAt = 0, updatedAt = 0 },
		},
		recent = {
			cap = 50,
			list = {},
		},
	}

	BookArchivist.Core.GetDB = function()
		return mockDB
	end
	BookArchivist.Core.Now = function()
		mockTime = mockTime + 1
		return mockTime
	end

	return mockDB, function()
		return mockTime
	end
end

describe("Recent.MarkOpened", function()
	it("adds book to recent list", function()
		local db = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")

		assert.are.equal(1, #db.recent.list)
		assert.are.equal("book1", db.recent.list[1])
	end)

	it("moves existing book to front", function()
		local db = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")
		BookArchivist.Recent:MarkOpened("book2")
		BookArchivist.Recent:MarkOpened("book1") -- Move book1 to front

		assert.are.equal(2, #db.recent.list)
		assert.are.equal("book1", db.recent.list[1])
		assert.are.equal("book2", db.recent.list[2])
	end)

	it("respects cap limit", function()
		local db = setupMockDB()
		db.recent.cap = 2

		BookArchivist.Recent:MarkOpened("book1")
		BookArchivist.Recent:MarkOpened("book2")
		BookArchivist.Recent:MarkOpened("book3")

		assert.are.equal(2, #db.recent.list)
		assert.are.equal("book3", db.recent.list[1])
		assert.are.equal("book2", db.recent.list[2])
	end)

	it("handles nil bookId", function()
		setupMockDB()
		-- Should not error
		BookArchivist.Recent:MarkOpened(nil)
	end)

	it("handles non-existent bookId", function()
		setupMockDB()
		-- Should not error (just logs debug)
		BookArchivist.Recent:MarkOpened("nonexistent")
	end)

	it("updates lastReadAt timestamp", function()
		local db, getTime = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")

		local expectedTime = getTime()
		assert.are.equal(expectedTime, db.booksById["book1"].lastReadAt)
	end)

	it("updates updatedAt timestamp", function()
		local db, getTime = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")

		local expectedTime = getTime()
		assert.are.equal(expectedTime, db.booksById["book1"].updatedAt)
	end)
end)

describe("Recent.GetList", function()
	it("returns empty list when no recent books", function()
		setupMockDB()

		local result = BookArchivist.Recent:GetList()

		assert.are.equal(0, #result)
	end)

	it("returns MRU order", function()
		local db = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")
		BookArchivist.Recent:MarkOpened("book2")
		BookArchivist.Recent:MarkOpened("book3")

		local result = BookArchivist.Recent:GetList()

		assert.are.equal(3, #result)
		assert.are.equal("book3", result[1])
		assert.are.equal("book2", result[2])
		assert.are.equal("book1", result[3])
	end)

	it("filters deleted books", function()
		local db = setupMockDB()

		BookArchivist.Recent:MarkOpened("book1")
		BookArchivist.Recent:MarkOpened("book2")

		-- Delete book1
		db.booksById["book1"] = nil

		local result = BookArchivist.Recent:GetList()

		assert.are.equal(1, #result)
		assert.are.equal("book2", result[1])
	end)

	it("removes duplicates from list", function()
		local db = setupMockDB()

		-- Manually inject duplicates
		db.recent.list = { "book1", "book2", "book1", "book3" }

		local result = BookArchivist.Recent:GetList()

		assert.are.equal(3, #result)
		-- Should keep first occurrence of each
		assert.are.equal("book1", result[1])
		assert.are.equal("book2", result[2])
		assert.are.equal("book3", result[3])
	end)

	it("cleans up stale entries in stored list", function()
		local db = setupMockDB()

		db.recent.list = { "book1", "deleted_book", "book2" }

		BookArchivist.Recent:GetList()

		-- After GetList, the stored list should be cleaned
		assert.are.equal(2, #db.recent.list)
	end)
end)
