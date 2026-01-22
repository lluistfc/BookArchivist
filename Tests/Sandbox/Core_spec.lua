-- Core_spec.lua
-- Covers BookArchivist core helpers that previously lacked coverage

local helper = dofile("Tests/test_helper.lua")

local originalGlobals = {
	UnitName = _G.UnitName,
	GetRealmName = _G.GetRealmName,
	GetLocale = _G.GetLocale,
	LibStub = _G.LibStub,
	C_Timer = _G.C_Timer,
	time = _G.time,
	os_time = os.time,
}

local function restoreGlobals()
	_G.UnitName = originalGlobals.UnitName
	_G.GetRealmName = originalGlobals.GetRealmName
	_G.GetLocale = originalGlobals.GetLocale
	_G.LibStub = originalGlobals.LibStub
	_G.time = originalGlobals.time
	_G.C_Timer = originalGlobals.C_Timer
	os.time = originalGlobals.os_time
end

describe("BookArchivist Core", function()
	local Core

	local function resetDB()
		BookArchivistDB = {
			version = 1,
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
			},
			recent = {},
			uiState = {},
		}
		return Core:GetDB()
	end

	before_each(function()
		os.time = function()
			return 123456
		end
		_G.time = nil

		_G.UnitName = function()
			return "Testy"
		end
		_G.GetRealmName = function()
			return "Realm"
		end
		_G.GetLocale = function()
			return "enUS"
		end
		_G.LibStub = nil

		_G.C_Timer = {}
		function _G.C_Timer.After(_, callback)
			if type(callback) == "function" then
				callback()
			end
		end

		BookArchivist = nil
		BookArchivistDB = nil
		helper.setupNamespace()
		helper.loadFile("core/BookArchivist_Core.lua")
		Core = BookArchivist.Core
		BookArchivist.Iterator = nil
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

	describe("database defaults", function()
		it("initializes BookArchivistDB with sane defaults and normalized locale", function()
			_G.GetLocale = function()
				return "esMX"
			end
			local db = resetDB()

			assert.is_table(db.booksById)
			assert.is_table(db.order)
			assert.is_table(db.indexes.objectToBookId)
			assert.is_true(db.options.tooltip.enabled)
			assert.are.equal("esES", db.options.language)
			assert.are.equal(50, db.recent.cap)
			assert.is_table(db.recent.list)
			assert.are.equal(200, db.options.minimapButton.angle)
			assert.are.equal("__all__", db.uiState.lastCategoryId)
		end)

		it("returns repository-provided databases when available", function()
			local fakeDB = { marker = true }
			BookArchivist.Repository = {
				GetDB = function()
					return fakeDB
				end,
			}

			local db = Core:GetDB()
			assert.are.equal(fakeDB, db)
		end)
	end)

	describe("language helpers", function()
		it("falls back to a sanitized locale when options are invalid", function()
			local db = resetDB()
			db.options.language = ""
			_G.GetLocale = function()
				return "ptPT"
			end

			local lang = Core:GetLanguage()
			assert.are.equal("ptBR", lang)
			assert.are.equal("ptBR", db.options.language)
		end)

		it("normalizes input when setting language", function()
			local db = resetDB()
			Core:SetLanguage("esMX")
			assert.are.equal("esES", db.options.language)
		end)
	end)

	describe("list configuration (fallback)", function()
		it("stores sort mode locally when ListConfig is missing", function()
			local db = resetDB()
			db.options.list = db.options.list or {}
			db.options.list.sortMode = ""

			assert.are.equal("lastSeen", Core:GetSortMode())

			Core:SetSortMode("title")
			assert.are.equal("title", db.options.list.sortMode)

			Core:SetSortMode(nil)
			assert.are.equal("lastSeen", db.options.list.sortMode)
		end)

		it("returns a stable filters table and updates favoritesOnly state", function()
			local db = resetDB()
			local filters = Core:GetListFilters()
			filters.favoritesOnly = false

			local sameFilters = Core:GetListFilters()
			assert.are.equal(filters, sameFilters)

			local originalSetter = Core.SetLastCategoryId
			local categorySelections = {}
			Core.SetLastCategoryId = function(_, categoryId)
				table.insert(categorySelections, categoryId)
			end

			Core:SetListFilter("favoritesOnly", true)
			assert.is_true(filters.favoritesOnly)

			Core:SetListFilter("favoritesOnly", false)
			assert.is_false(filters.favoritesOnly)

			Core:SetListFilter("unknown", true)

			assert.are.same({ "__favorites__", "__all__" }, categorySelections)
			Core.SetLastCategoryId = originalSetter
		end)

		it("uses defaults for list page size and converts inputs", function()
			local db = resetDB()
			db.options.list = db.options.list or {}
			db.options.list.pageSize = nil

			assert.are.equal(25, Core:GetListPageSize())

			Core:SetListPageSize("40")
			assert.are.equal(40, db.options.list.pageSize)
		end)
	end)

	describe("ListConfig delegation", function()
		it("delegates getters and setters when ListConfig is present", function()
			local filtersTable = {}
			local captured = {
				setSortMode = nil,
				setFilter = nil,
				setPageSize = nil,
			}

			BookArchivist.ListConfig = {
				GetSortMode = function()
					return "title"
				end,
				SetSortMode = function(_, mode)
					captured.setSortMode = mode
				end,
				GetListFilters = function()
					return filtersTable
				end,
				SetListFilter = function(_, key, state)
					captured.setFilter = { key = key, state = state }
					return filtersTable
				end,
				GetListPageSize = function()
					return 12
				end,
				SetListPageSize = function(_, size)
					captured.setPageSize = size
				end,
			}

			assert.are.equal("title", Core:GetSortMode())
			Core:SetSortMode("zone")
			assert.are.equal("zone", captured.setSortMode)

			assert.are.equal(filtersTable, Core:GetListFilters())
			Core:SetListFilter("favoritesOnly", true)
			assert.are.same({ key = "favoritesOnly", state = true }, captured.setFilter)

			assert.are.equal(12, Core:GetListPageSize())
			Core:SetListPageSize(99)
			assert.are.equal(99, captured.setPageSize)

			BookArchivist.ListConfig = nil
		end)
	end)

	describe("export helpers", function()
		it("builds payloads without LibDeflate using schema version 1", function()
			local db = resetDB()
			db.booksById.book1 = { title = "Test" }
			db.order = { "book1" }
			_G.LibStub = nil

			local payload = Core:BuildExportPayload()
			assert.are.equal(1, payload.schemaVersion)
			assert.is_table(payload.booksById)
			assert.are.same(db.booksById, payload.booksById)
			assert.are.equal("Testy", payload.character.name)
			assert.are.equal("Realm", payload.character.realm)
		end)

		it("upgrades schema when LibDeflate is available", function()
			local db = resetDB()
			db.booksById.book1 = { title = "Another" }
			db.order = { "book1" }
			_G.LibStub = function(name)
				if name == "LibDeflate" then
					return {}
				end
			end

			local payload = Core:BuildExportPayload()
			assert.are.equal(2, payload.schemaVersion)
		end)

		it("builds single-book payloads without echo metadata", function()
			local db = resetDB()
			db.booksById.book1 = {
				title = "Entry",
				pages = { [1] = "Text" },
				readCount = 4,
				firstReadLocation = {},
				lastPageRead = 2,
				lastReadAt = 1000,
			}
			db.order = { "book1" }

			local payload, err = Core:BuildExportPayloadForBook("book1")
			assert.is_nil(err)
			assert.are.equal(1, payload.schemaVersion)
			local exported = payload.booksById.book1
			assert.is_nil(exported.readCount)
			assert.is_nil(exported.firstReadLocation)
			assert.is_nil(exported.lastPageRead)
			assert.is_nil(exported.lastReadAt)
			assert.are.equal("Entry", exported.title)
		end)

		it("validates book IDs before exporting", function()
			resetDB()
			local payload, err = Core:BuildExportPayloadForBook("")
			assert.is_nil(payload)
			assert.are.equal("invalid book ID", err)

			local payload2, err2 = Core:BuildExportPayloadForBook("missing")
			assert.is_nil(payload2)
			assert.are.equal("book not found", err2)
		end)
	end)

	describe("selection state", function()
		it("manages last book identifiers", function()
			local db = resetDB()
			db.booksById.book1 = {}

			Core:SetLastBookId("book1")
			assert.are.equal("book1", Core:GetLastBookId())

			Core:SetLastBookId("missing")
			assert.is_nil(Core:GetLastBookId())

			Core:SetLastBookId(nil)
			assert.is_nil(Core:GetLastBookId())
		end)

		it("defaults last category to __all__ and syncs favorites filter", function()
			local db = resetDB()
			db.uiState.lastCategoryId = ""

			assert.are.equal("__all__", Core:GetLastCategoryId())

			local listOptions = { filters = {} }
			BookArchivist.ListConfig = {
				EnsureListOptions = function()
					return listOptions
				end,
			}

			Core:SetLastCategoryId("__favorites__")
			assert.are.equal("__favorites__", db.uiState.lastCategoryId)
			assert.is_true(listOptions.filters.favoritesOnly)

			Core:SetLastCategoryId(nil)
			assert.are.equal("__all__", db.uiState.lastCategoryId)
			assert.is_false(listOptions.filters.favoritesOnly)

			BookArchivist.ListConfig = nil
		end)
	end)

	describe("index helpers", function()
		it("indexes items, objects, and normalized titles", function()
			local db = resetDB()

			Core:IndexItemForBook("42", "book1")
			assert.is_true(db.indexes.itemToBookIds[42].book1)

			Core:IndexObjectForBook("npc:12", "book2")
			assert.are.equal("book2", db.indexes.objectToBookId["npc:12"])

			Core:IndexTitleForBook(" |cff00ff00The  Story|r ", "book3")
			assert.is_true(db.indexes.titleToBookIds["the story"].book3)
		end)

		it("ignores invalid indexing input", function()
			resetDB()
			Core:IndexItemForBook(nil, "book1")
			Core:IndexObjectForBook(nil, "book1")
			Core:IndexTitleForBook("", "book1")
		end)
	end)

	describe("entry injection", function()
		it("injects entries, builds search text, and respects append option", function()
			resetDB()
			local appended, touched
			local originalAppend = Core.AppendOrder
			local originalTouch = Core.TouchOrder
			local originalBuildSearch = Core.BuildSearchText

			Core.AppendOrder = function(_, key)
				appended = key
			end
			Core.TouchOrder = function(_, key)
				touched = key
			end
			Core.BuildSearchText = function(_, title, pages)
				pages = pages or {}
				return string.format("%s:%s", title or "", pages[1] or "")
			end

			local entry = {
				key = "book-injected",
				title = "Injected",
				pages = { [1] = "Page" },
			}

			Core:InjectEntry(entry, { append = true })
			assert.are.equal("book-injected", appended)
			assert.are.equal("Injected:Page", entry.searchText)

			Core:InjectEntry(entry)
			assert.are.equal("book-injected", touched)

			Core.AppendOrder = originalAppend
			Core.TouchOrder = originalTouch
			Core.BuildSearchText = originalBuildSearch
		end)
	end)

	describe("utility wrappers", function()
		it("returns the stubbed time value", function()
			assert.are.equal(123456, Core:Now())
		end)

		it("trims whitespace and handles nil strings", function()
			assert.are.equal("alpha", Core:Trim("  alpha  "))
			assert.are.equal("", Core:Trim(nil))
		end)
	end)
end)
