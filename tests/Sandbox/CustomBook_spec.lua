-- CustomBook_spec.lua
-- Tests for creating custom (player-authored) books

local helper = dofile("Tests/test_helper.lua")

local originalGlobals = {
	UnitName = _G.UnitName,
	GetRealmName = _G.GetRealmName,
	GetLocale = _G.GetLocale,
	time = _G.time,
	os_time = os.time,
}

local function restoreGlobals()
	_G.UnitName = originalGlobals.UnitName
	_G.GetRealmName = originalGlobals.GetRealmName
	_G.GetLocale = originalGlobals.GetLocale
	_G.time = originalGlobals.time
	os.time = originalGlobals.os_time
end

describe("Custom Book Creation", function()
	local Core

	local function resetDB()
		BookArchivistDB = {
			version = 2,
			dbVersion = 2,
			createdAt = 0,
			order = {},
			booksById = {},
			options = {},
			indexes = {
				_titleIndexBackfilled = true,
				_titleIndexPending = false,
				objectToBookId = {},
				itemToBookIds = {},
				titleToBookIds = {},
				custom = { counter = 0 },
			},
			recent = { cap = 50, list = {} },
			uiState = {},
		}
		return Core:GetDB()
	end

	before_each(function()
		os.time = function()
			return 1234567890
		end
		_G.time = nil

		_G.UnitName = function()
			return "TestPlayer"
		end
		_G.GetRealmName = function()
			return "TestRealm"
		end
		_G.GetLocale = function()
			return "enUS"
		end

		_G.C_Timer = {}
		function _G.C_Timer.After(_, callback)
			if type(callback) == "function" then
				callback()
			end
		end

		BookArchivist = nil
		BookArchivistDB = nil
		helper.setupNamespace()
		helper.loadFile("core/BookArchivist_Book.lua") -- Load Book aggregate module
		helper.loadFile("core/BookArchivist_Core.lua")
		helper.loadFile("core/BookArchivist_Order.lua") -- Load Order module for AppendOrder
		Core = BookArchivist.Core
		BookArchivist.Repository = nil
		
		if not Core.GetOptions then
			function Core:GetOptions()
				local db = self:GetDB()
				db.options = db.options or {}
				return db.options
			end
		end
	end)

	after_each(function()
		restoreGlobals()
	end)

	describe("NextCustomBookId", function()
		it("generates unique custom book IDs with monotonic counter", function()
			local db = resetDB()

			local id1 = Core:NextCustomBookId()
			local id2 = Core:NextCustomBookId()
			local id3 = Core:NextCustomBookId()

			-- Should have format "c:<timestamp>:<counter>"
			assert.matches("^c:%d+:%d+$", id1)
			assert.matches("^c:%d+:%d+$", id2)
			assert.matches("^c:%d+:%d+$", id3)

			-- Should be different
			assert.are_not.equal(id1, id2)
			assert.are_not.equal(id2, id3)

			-- Counter should increment (3 IDs generated so far)
			assert.are.equal(3, db.indexes.custom.counter)
			local id4 = Core:NextCustomBookId()
			assert.are.equal(4, db.indexes.custom.counter)
		end)

		it("initializes custom index if missing", function()
			local db = resetDB()
			db.indexes.custom = nil

			local id = Core:NextCustomBookId()

			assert.is_table(db.indexes.custom)
			assert.are.equal(1, db.indexes.custom.counter)
			assert.matches("^c:%d+:%d+$", id)
		end)
	end)

	describe("CreateCustomBook", function()
		it("creates a custom book with title and single page", function()
			local db = resetDB()

			local title = "My Test Book"
			local pages = { "This is page one content." }

			local bookId = Core:CreateCustomBook(title, pages)

			assert.is_not_nil(bookId)
			assert.matches("^c:%d+:%d+$", bookId)

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.are.equal(bookId, entry.key)
			assert.are.equal(title, entry.title)
			assert.are.equal("TestPlayer", entry.creator)
			assert.are.equal("CUSTOM", entry.source.type)
			assert.is_true(entry.source.custom)
			assert.is_table(entry.pages)
			assert.are.equal(1, #entry.pages)
			assert.are.equal("This is page one content.", entry.pages[1])
		end)

		it("creates a custom book with multiple pages", function()
			local db = resetDB()

			local title = "Multi-Page Book"
			local pages = {
				"Page 1 content",
				"Page 2 content",
				"Page 3 content",
			}

			local bookId = Core:CreateCustomBook(title, pages)

			assert.is_not_nil(bookId)

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.are.equal(3, #entry.pages)
			assert.are.equal("Page 1 content", entry.pages[1])
			assert.are.equal("Page 2 content", entry.pages[2])
			assert.are.equal("Page 3 content", entry.pages[3])
		end)

		it("creates a custom book with location", function()
			local db = resetDB()

			local title = "Located Book"
			local pages = { "Content here." }
			local location = {
				context = "world",
				zoneChain = { "Azeroth", "Elwynn Forest", "Goldshire" },
				zoneText = "Azeroth > Elwynn Forest > Goldshire",
				mapID = 1429,
				capturedAt = 1234567890,
			}

			-- New signature: CreateCustomBook(title, pages, creator, location)
			local bookId = Core:CreateCustomBook(title, pages, nil, location)

			assert.is_not_nil(bookId)

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.is_table(entry.location)
			assert.are.equal("world", entry.location.context)
			assert.are.equal("Azeroth > Elwynn Forest > Goldshire", entry.location.zoneText)
			assert.are.equal(1429, entry.location.mapID)
		end)

		it("handles nil title gracefully", function()
			local db = resetDB()

			local pages = { "Some content" }
			local bookId = Core:CreateCustomBook(nil, pages)

			assert.is_not_nil(bookId)

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			-- Now provides default "Untitled Book" instead of empty string
			assert.are.equal("Untitled Book", entry.title)
		end)

		it("handles nil pages gracefully", function()
			local db = resetDB()

			local title = "Empty Book"
			local bookId = Core:CreateCustomBook(title, nil)

			assert.is_not_nil(bookId)

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.is_table(entry.pages)
			assert.are.equal(1, #entry.pages)
			assert.are.equal("", entry.pages[1])
		end)

		it("adds book to order list with append flag", function()
			local db = resetDB()

			-- Pre-populate with existing books
			db.order = { "book1", "book2", "book3" }

			local title = "New Custom Book"
			local pages = { "Content" }
			local bookId = Core:CreateCustomBook(title, pages)

			assert.is_not_nil(bookId)

			-- Should be appended to end of order
			assert.are.equal(4, #db.order)
			assert.are.equal(bookId, db.order[4])
		end)

		it("sets timestamps on creation", function()
			local db = resetDB()
			local testTime = 1234567890
			os.time = function()
				return testTime
			end

			local bookId = Core:CreateCustomBook("Test", { "Content" })

			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.are.equal(testTime, entry.createdAt)
			assert.are.equal(testTime, entry.updatedAt)
		end)

		it("creates multiple distinct custom books", function()
			local db = resetDB()

			local id1 = Core:CreateCustomBook("Book 1", { "Content 1" })
			local id2 = Core:CreateCustomBook("Book 2", { "Content 2" })
			local id3 = Core:CreateCustomBook("Book 3", { "Content 3" })

			assert.are_not.equal(id1, id2)
			assert.are_not.equal(id2, id3)

			assert.is_not_nil(db.booksById[id1])
			assert.is_not_nil(db.booksById[id2])
			assert.is_not_nil(db.booksById[id3])

			assert.are.equal("Book 1", db.booksById[id1].title)
			assert.are.equal("Book 2", db.booksById[id2].title)
			assert.are.equal("Book 3", db.booksById[id3].title)
		end)

		it("returns bookId for successful creation", function()
			local db = resetDB()

			local bookId = Core:CreateCustomBook("Test Title", { "Test Content" })

			assert.is_string(bookId)
			assert.matches("^c:", bookId)
			assert.is_not_nil(db.booksById[bookId])
		end)
	end)

	describe("Custom Book Detection", function()
		it("identifies custom books by source type", function()
			local db = resetDB()

			-- Create a custom book
			local customId = Core:CreateCustomBook("Custom", { "Content" })
			local customEntry = db.booksById[customId]

			assert.are.equal("CUSTOM", customEntry.source.type)
			assert.is_true(customEntry.source.custom)
		end)

		it("differentiates custom books from captured books", function()
			local db = resetDB()

			-- Create a custom book
			local customId = Core:NextCustomBookId()
			db.booksById[customId] = {
				key = customId,
				title = "Custom Book",
				source = { type = "CUSTOM", custom = true },
				pages = { "Custom content" },
			}

			-- Simulate a captured book
			local capturedId = "item:12345:goldshire"
			db.booksById[capturedId] = {
				key = capturedId,
				title = "Captured Book",
				source = { type = "ITEM", itemID = 12345 },
				pages = { "Captured content" },
			}

			local customEntry = db.booksById[customId]
			local capturedEntry = db.booksById[capturedId]

			assert.are.equal("CUSTOM", customEntry.source.type)
			assert.are_not.equal("CUSTOM", capturedEntry.source.type)
			assert.is_true(customEntry.source.custom)
			assert.is_nil(capturedEntry.source.custom)
		end)
	end)

	describe("Integration with InjectEntry", function()
		it("properly stores custom book in booksById", function()
			local db = resetDB()

			local bookId = Core:CreateCustomBook("Test", { "Page 1", "Page 2" })

			assert.is_not_nil(db.booksById[bookId])
			assert.are.equal(bookId, db.booksById[bookId].key)
		end)

		it("adds custom book to order list", function()
			local db = resetDB()
			local initialOrderCount = #db.order

			local bookId = Core:CreateCustomBook("Test", { "Content" })

			assert.are.equal(initialOrderCount + 1, #db.order)
			assert.are.equal(bookId, db.order[#db.order])
		end)

		it("builds search text for custom books", function()
			local db = resetDB()

			-- Mock BuildSearchText (though Book aggregate builds its own)
			local searchTextBuilt = false
			Core.BuildSearchText = function(self, title, pages)
				searchTextBuilt = true
				return (title or "") .. " " .. table.concat(pages or {}, " ")
			end

			local bookId = Core:CreateCustomBook("Searchable Title", { "Searchable content" })

			local entry = db.booksById[bookId]
			-- InjectEntry will call BuildSearchText, so this should be true
			assert.is_true(searchTextBuilt)
			assert.is_string(entry.searchText)
			-- SearchText is normalized (lowercase, etc.) by Book aggregate
			assert.matches("searchable", entry.searchText:lower())
			assert.matches("title", entry.searchText:lower())
			assert.matches("content", entry.searchText:lower())
		end)
	end)
end)
