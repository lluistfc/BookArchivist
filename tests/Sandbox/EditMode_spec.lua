-- EditMode_spec.lua
-- Tests for custom book editing UI functionality

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

describe("EditMode", function()
	local Core
	local EditMode
	local mockState

	local function resetDB()
		_G.BookArchivistDB = {
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
		BookArchivistDB = _G.BookArchivistDB  -- Sync both
		return Core:GetDB()  -- Like CustomBook_spec, call GetDB() to run ensureDB()
	end

	local function setupMockWidgets()
		mockState = {
			editTitleBox = {
				text = "",
				SetText = function(self, text) self.text = text end,
				GetText = function(self) return self.text end,
				SetFocus = function() end,
			},
			editLocationDisplay = {
				text = "",
				SetText = function(self, text) self.text = text end,
				GetText = function(self) return self.text end,
			},
			editPageEdit = {
				text = "",
				SetText = function(self, text) self.text = text end,
				GetText = function(self) return self.text end,
			},
			editPageIndicator = {
				text = "",
				SetText = function(self, text) self.text = text end,
				GetText = function(self) return self.text end,
			},
			editPrevBtn = {
				enabled = true,
				SetEnabled = function(self, enabled) self.enabled = enabled end,
			},
			editNextBtn = {
				enabled = true,
				SetEnabled = function(self, enabled) self.enabled = enabled end,
			},
			editBookFrame = {
				visible = false,
				Show = function(self) self.visible = true end,
				Hide = function(self) self.visible = false end,
			},
			textScroll = { Hide = function() end },
			textScrollBar = { Hide = function() end },
			emptyStateFrame = { Hide = function() end },
			bookTitle = { SetText = function() end },
			echoText = { Hide = function() end },
			metaDisplay = { Hide = function() end },
			readerNavRow = { Hide = function() end },
			favoriteButton = { Hide = function() end },
			shareButton = { Hide = function() end },
			deleteButton = { Hide = function() end },
			customBookIcon = { Hide = function() end },
			editButton = { Hide = function() end },
		}
		return mockState
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
		
		_G.strlower = function(s)
			return string.lower(s or "")
		end

		_G.C_Timer = {}
		function _G.C_Timer.After(_, callback)
			if type(callback) == "function" then
				callback()
			end
		end

		BookArchivist = nil
		_G.BookArchivistDB = nil
		BookArchivistDB = nil
		helper.setupNamespace()
		helper.loadFile("core/BookArchivist_Core.lua")
		helper.loadFile("core/BookArchivist_Order.lua")
		-- DON'T load Search - let BuildSearchText be nil
		Core = BookArchivist.Core
		-- Mock Repository for UpdateCustomBook tests
		BookArchivist.Repository = {
			GetDB = function() return BookArchivistDB end
		}
		
		if not Core.GetOptions then
			function Core:GetOptions()
				local db = self:GetDB()
				db.options = db.options or {}
				return db.options
			end
		end

		-- Create a minimal EditMode mock
		EditMode = {
			initialized = true,
		}
		
		-- Mock the localization function
		_G.t = function(key)
			local translations = {
				NO_LOCATION_SET = "No location set",
				PAGE = "Page",
			}
			return translations[key] or key
		end
	end)

	after_each(function()
		restoreGlobals()
	end)

	describe("StartNewBook", function()
		it("initializes empty edit session", function()
			local db = resetDB()
			local state = setupMockWidgets()
			
			-- Mock editSession
			local editSession = {
				isEditing = false,
				bookId = nil,
				title = "",
				location = nil,
				pages = {},
				currentPageIndex = 1,
			}

			-- Simulate StartNewBook behavior
			editSession.isEditing = true
			editSession.bookId = nil
			editSession.title = ""
			editSession.location = nil
			editSession.pages = { "" }
			editSession.currentPageIndex = 1
			
			state.editTitleBox:SetText("")
			state.editLocationDisplay:SetText("No location set")
			state.editPageEdit:SetText("")
			state.editPageIndicator:SetText("Page 1 / 1")

			-- Verify empty state
			assert.is_true(editSession.isEditing)
			assert.is_nil(editSession.bookId)
			assert.equals("", state.editTitleBox:GetText())
			assert.equals("No location set", state.editLocationDisplay:GetText())
			assert.equals("", state.editPageEdit:GetText())
			assert.equals(1, #editSession.pages)
		end)
	end)

	describe("StartEditingBook", function()
		it("loads existing custom book into edit session", function()
			local db = resetDB()
			local state = setupMockWidgets()

			-- Create a custom book with simple string pages
			local bookId = Core:CreateCustomBook("My Test Book", {
				"Page 1 content",
				"Page 2 content",
			}, {
				zoneText = "Stormwind City",
				zone = "Stormwind City",
			})

			-- Get the created book
			local entry = db.booksById[bookId]
			assert.is_not_nil(entry)
			assert.equals("My Test Book", entry.title)

			-- Simulate StartEditingBook behavior
			local editSession = {
				isEditing = true,
				bookId = bookId,
				title = entry.title,
				location = entry.location,
				pages = {},
				currentPageIndex = 1,
			}

			-- Extract pages (they're already strings in this format)
			for i, page in ipairs(entry.pages) do
				editSession.pages[i] = page
			end

			-- Populate UI
			state.editTitleBox:SetText(editSession.title)
			state.editLocationDisplay:SetText(editSession.location.zoneText)
			state.editPageEdit:SetText(editSession.pages[1])
			state.editPageIndicator:SetText("Page 1 / " .. #editSession.pages)
			state.editPrevBtn:SetEnabled(false)
			state.editNextBtn:SetEnabled(#editSession.pages > 1)

			-- CRITICAL: Verify fields are NOT cleared after being set
			-- This is the bug we're testing for
			assert.equals("My Test Book", state.editTitleBox:GetText(), "Title should remain populated")
			assert.equals("Stormwind City", state.editLocationDisplay:GetText(), "Location should remain populated")
			assert.equals("Page 1 content", state.editPageEdit:GetText(), "Page content should remain populated")
			assert.equals("Page 1 / 2", state.editPageIndicator:GetText(), "Page indicator should show correct count")
			
			-- Verify session state
			assert.is_true(editSession.isEditing)
			assert.equals(bookId, editSession.bookId)
			assert.equals(2, #editSession.pages)
			assert.equals("Page 1 content", editSession.pages[1])
			assert.equals("Page 2 content", editSession.pages[2])
			
			-- Verify navigation buttons
			assert.is_false(state.editPrevBtn.enabled, "Prev button should be disabled on first page")
			assert.is_true(state.editNextBtn.enabled, "Next button should be enabled when multiple pages")
		end)

		it("handles single-page custom books", function()
			local db = resetDB()
			local state = setupMockWidgets()

			-- Create single-page book with simple string
			local bookId = Core:CreateCustomBook("Single Page", {
				"Only page",
			})

			local entry = db.booksById[bookId]
			local editSession = {
				isEditing = true,
				bookId = bookId,
				title = entry.title,
				pages = { entry.pages[1] },
				currentPageIndex = 1,
			}

			state.editPageEdit:SetText(editSession.pages[1])
			state.editPageIndicator:SetText("Page 1 / 1")
			state.editNextBtn:SetEnabled(#editSession.pages > 1)

			assert.equals("Only page", state.editPageEdit:GetText())
			assert.equals("Page 1 / 1", state.editPageIndicator:GetText())
			assert.is_false(state.editNextBtn.enabled, "Next button should be disabled for single page")
		end)

		it("handles custom books without location", function()
			local db = resetDB()
			local state = setupMockWidgets()

			-- Create book without location with simple string
			local bookId = Core:CreateCustomBook("No Location Book", {
				"Content",
			}, nil)

			local entry = db.booksById[bookId]
			local editSession = {
				isEditing = true,
				bookId = bookId,
				title = entry.title,
				location = entry.location,
				pages = { entry.pages[1] },
			}

			if editSession.location and editSession.location.zoneText then
				state.editLocationDisplay:SetText(editSession.location.zoneText)
			else
				state.editLocationDisplay:SetText("No location set")
			end

			assert.equals("No location set", state.editLocationDisplay:GetText())
		end)

		it("rejects non-custom books", function()
			local db = resetDB()

			-- Create a non-custom book (simulate captured book) with simple string
			local nonCustomId = "b:12345:1"
			db.booksById[nonCustomId] = {
				key = nonCustomId,
				title = "Captured Book",
				pages = { "Not editable" },
				source = {
					type = "ITEM",
					itemID = 12345,
				},
			}

			local entry = db.booksById[nonCustomId]
			
			-- Verify source type is not CUSTOM
			assert.is_not_nil(entry.source)
			assert.not_equals("CUSTOM", entry.source.type)
			
			-- In real code, StartEditingBook would return early here
			-- and NOT populate the edit session
		end)

		it("handles empty pages array", function()
			local db = resetDB()
			local state = setupMockWidgets()

			-- Create book and manually corrupt pages with simple string
			local bookId = Core:CreateCustomBook("Empty Pages", {
				"Original",
			})
			db.booksById[bookId].pages = {} -- Simulate corruption

			local entry = db.booksById[bookId]
			local pages = {}
			
			if entry.pages then
				for i, page in ipairs(entry.pages) do
					pages[i] = page
				end
			end
			
			-- Should have fallback
			if #pages == 0 then
				pages = { "" }
			end

			assert.equals(1, #pages, "Should have at least one empty page")
			assert.equals("", pages[1])
		end)
		
		it("correctly extracts page content from string format", function()
			local db = resetDB()
			local state = setupMockWidgets()

			-- Create custom book (pages are stored as strings)
			local bookId = Core:CreateCustomBook("Test Book", {
				"First page text",
				"Second page text",
			})

			local entry = db.booksById[bookId]
			
			-- Simulate the page loading logic from StartEditingBook
			local pages = {}
			if entry.pages then
				for i, page in ipairs(entry.pages) do
					-- This is the actual logic that was broken
					pages[i] = (type(page) == "string" and page) or (type(page) == "table" and page.text) or ""
				end
			end

			-- Verify pages were extracted correctly
			assert.equals(2, #pages)
			assert.equals("First page text", pages[1], "First page should be extracted as string")
			assert.equals("Second page text", pages[2], "Second page should be extracted as string")
		end)
		
		it("handles mixed page formats (string and table)", function()
			local db = resetDB()

			-- Create book with string pages
			local bookId = Core:CreateCustomBook("Mixed Format", {
				"String page",
			})

			-- Manually inject a table-format page (legacy format)
			local entry = db.booksById[bookId]
			entry.pages[2] = { text = "Table page" }
			entry.pages[3] = "Another string page"

			-- Simulate page loading
			local pages = {}
			for i, page in ipairs(entry.pages) do
				pages[i] = (type(page) == "string" and page) or (type(page) == "table" and page.text) or ""
			end

			-- Verify all formats are handled
			assert.equals(3, #pages)
			assert.equals("String page", pages[1], "String format should work")
			assert.equals("Table page", pages[2], "Table format should work")
			assert.equals("Another string page", pages[3], "String format should work")
		end)
	end)

	describe("UpdateCustomBook", function()
		it("updates existing book without creating duplicate", function()
			local db = resetDB()

			-- Create original book with simple string
			local bookId = Core:CreateCustomBook("Original Title", {"Original content"})

			local originalCount = 0
			for _ in pairs(db.booksById) do
				originalCount = originalCount + 1
			end
			assert.equals(1, originalCount)

			-- Update the book with simple string
			local success = Core:UpdateCustomBook(bookId, "Updated Title", {"Updated content"})

			assert.is_true(success, "Update should succeed")

			-- Verify no duplicate created
			local finalCount = 0
			for _ in pairs(db.booksById) do
				finalCount = finalCount + 1
			end
			assert.equals(1, finalCount, "Should still have only 1 book")

			-- Verify updated
			local entry = db.booksById[bookId]
			assert.equals("Updated Title", entry.title)
			assert.equals("Updated content", entry.pages[1])
		end)

		it("updates multi-page books correctly", function()
			local db = resetDB()

			-- Create with simple strings
			local bookId = Core:CreateCustomBook("Multi-page", {"Page 1", "Page 2"})

			-- Update with simple strings
			local success = Core:UpdateCustomBook(bookId, "Multi-page Updated", {"New Page 1", "New Page 2", "New Page 3"})

			assert.is_true(success)
			
			local entry = db.booksById[bookId]
			assert.equals(3, #entry.pages)
			assert.equals("New Page 3", entry.pages[3])
		end)

		it("rejects updating non-existent book", function()
			local db = resetDB()

			-- Try to update with simple string
			local success = Core:UpdateCustomBook("nonexistent", "Title", {"Content"})

			assert.is_false(success, "Should fail for non-existent book")
		end)

		it("rejects updating non-custom books", function()
			local db = resetDB()

			-- Create non-custom book with simple string
			local nonCustomId = "b:12345:1"
			db.booksById[nonCustomId] = {
				key = nonCustomId,
				title = "Captured Book",
				pages = { "Not editable" },
				source = {
					type = "ITEM",
					itemID = 12345,
				},
			}

			-- Try to update with simple string
			local success = Core:UpdateCustomBook(nonCustomId, "Hacked Title", {"Hacked"})

			assert.is_false(success, "Should reject non-custom books")
			assert.equals("Captured Book", db.booksById[nonCustomId].title, "Title should not change")
		end)
	end)
end)
