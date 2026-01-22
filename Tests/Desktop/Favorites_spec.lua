-- Favorites_spec.lua
-- Sandbox tests for Favorites management

-- Load test helper
local helper = dofile("Tests/test_helper.lua")
helper.setupNamespace()

-- Mock Core module
BookArchivist.Core = BookArchivist.Core or {}
BookArchivist.DebugPrint = function(self, ...) end

-- Load Repository module (required by Favorites)
helper.loadFile("core/BookArchivist_Repository.lua")

-- Load Favorites module
helper.loadFile("core/BookArchivist_Favorites.lua")

-- Setup mock database
local function setupMockDB()
	BookArchivist.Core = BookArchivist.Core or {}

	-- Mock database
	local mockDB = {
		booksById = {
			["testbook1"] = {
				bookId = "testbook1",
				title = "Test Book 1",
				isFavorite = false,
				updatedAt = 0,
			},
			["testbook2"] = {
				bookId = "testbook2",
				title = "Test Book 2",
				isFavorite = true,
				updatedAt = 0,
			},
		},
	}

	-- Initialize Repository with mock database
	BookArchivist.Repository:Init(mockDB)

	BookArchivist.Core.GetDB = function()
		return mockDB
	end
	BookArchivist.Core.Now = function()
		return 12345
	end

	return mockDB
end

describe("Favorites.Set", function()
	it("marks a book as favorite", function()
		local db = setupMockDB()

		BookArchivist.Favorites:Set("testbook1", true)

		assert.is_true(db.booksById["testbook1"].isFavorite == true)
		assert.are.equal(12345, db.booksById["testbook1"].updatedAt)
	end)

	it("unmarks a book as favorite", function()
		local db = setupMockDB()

		BookArchivist.Favorites:Set("testbook2", false)

		assert.is_true(db.booksById["testbook2"].isFavorite == false)
		assert.are.equal(12345, db.booksById["testbook2"].updatedAt)
	end)

	it("handles nil bookId", function()
		setupMockDB()
		-- Should not error
		BookArchivist.Favorites:Set(nil, true)
	end)

	it("handles non-existent bookId", function()
		setupMockDB()
		-- Should not error (just logs debug)
		BookArchivist.Favorites:Set("nonexistent", true)
	end)

	it("does not update if value unchanged", function()
		local db = setupMockDB()
		db.booksById["testbook1"].updatedAt = 100

		BookArchivist.Favorites:Set("testbook1", false)

		-- updatedAt should not change
		assert.are.equal(100, db.booksById["testbook1"].updatedAt)
	end)
end)

describe("Favorites.Toggle", function()
	it("toggles from false to true", function()
		local db = setupMockDB()

		BookArchivist.Favorites:Toggle("testbook1")

		assert.is_true(db.booksById["testbook1"].isFavorite == true)
	end)

	it("toggles from true to false", function()
		local db = setupMockDB()

		BookArchivist.Favorites:Toggle("testbook2")

		assert.is_true(db.booksById["testbook2"].isFavorite == false)
	end)

	it("handles nil bookId", function()
		setupMockDB()
		-- Should not error and should not call Set
		local calls = 0
		local originalSet = BookArchivist.Favorites.Set
		BookArchivist.Favorites.Set = function()
			calls = calls + 1
		end
		BookArchivist.Favorites:Toggle(nil)
		BookArchivist.Favorites.Set = originalSet
		assert.are.equal(0, calls)
	end)

	it("handles non-existent bookId", function()
		setupMockDB()
		local calls = 0
		local originalSet = BookArchivist.Favorites.Set
		BookArchivist.Favorites.Set = function()
			calls = calls + 1
		end
		BookArchivist.Favorites:Toggle("nonexistent")
		BookArchivist.Favorites.Set = originalSet
		assert.are.equal(0, calls)
	end)
end)

describe("Favorites.IsFavorite", function()
	it("returns true for favorited book", function()
		setupMockDB()

		local result = BookArchivist.Favorites:IsFavorite("testbook2")

		assert.is_true(result == true)
	end)

	it("returns false for non-favorited book", function()
		setupMockDB()

		local result = BookArchivist.Favorites:IsFavorite("testbook1")

		assert.is_true(result == false)
	end)

	it("returns false for nil bookId", function()
		setupMockDB()

		local result = BookArchivist.Favorites:IsFavorite(nil)

		assert.is_true(result == false)
	end)

	it("returns false for non-existent book", function()
		setupMockDB()

		local result = BookArchivist.Favorites:IsFavorite("nonexistent")

		assert.is_true(result == false)
	end)
end)
