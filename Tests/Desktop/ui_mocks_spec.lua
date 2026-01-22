---@diagnostic disable: undefined-global, undefined-field
-- ui_mocks_spec.lua
-- Tests for the ui_mocks helper module itself
-- Verifies that our mock utilities work correctly
--
-- NOTE: WoW API tests (wipe, C_Timer, time) removed - now provided by Mechanic

describe("UIMocks Helper", function()
	local UIMocks

	setup(function()
		UIMocks = dofile("Tests/helpers/ui_mocks.lua")
	end)

	describe("Database Mocks", function()
		it("createMockDB should create v2 schema database", function()
			local db = UIMocks.createMockDB()
			assert.are.equal(2, db.dbVersion)
			assert.is_table(db.booksById)
			assert.is_table(db.order)
			assert.is_table(db.indexes)
			assert.is_table(db.recent)
			assert.is_table(db.uiState)
		end)

		it("createMockDB should accept overrides", function()
			local db = UIMocks.createMockDB({
				dbVersion = 3,
				booksById = { book1 = {} },
			})
			assert.are.equal(3, db.dbVersion)
			assert.is_not_nil(db.booksById.book1)
		end)

		it("createMockAddon should return addon with GetDB", function()
			local db = UIMocks.createMockDB()
			local addon = UIMocks.createMockAddon(db)
			assert.is_function(addon.GetDB)
			assert.are.equal(db, addon:GetDB())
		end)

		it("createMockBook should create book entry", function()
			local book = UIMocks.createMockBook()
			assert.is_string(book.title)
			assert.is_table(book.pages)
			assert.is_table(book.location)
			assert.is_number(book.createdAt)
		end)

		it("createMockBook should accept overrides", function()
			local book = UIMocks.createMockBook({ title = "Custom Title" })
			assert.are.equal("Custom Title", book.title)
		end)
	end)

	describe("UI Component Mocks", function()
		it("createMockContext should create context with getters/setters", function()
			local ctx = UIMocks.createMockContext()
			assert.is_function(ctx.getPageSize)
			assert.is_function(ctx.setPageSize)
			assert.are.equal(25, ctx.getPageSize())

			ctx.setPageSize(50)
			assert.are.equal(50, ctx.getPageSize())
		end)

		it("createMockListState should create UI state structure", function()
			local state = UIMocks.createMockListState()
			assert.is_table(state.pagination)
			assert.is_table(state.location)
			assert.is_table(state.search)
		end)

		it("createMockSearchBox should create functional search box", function()
			local box = UIMocks.createMockSearchBox("initial")
			assert.are.equal("initial", box:GetText())

			box:SetText("new text")
			assert.are.equal("new text", box:GetText())

			box:ClearFocus()
			assert.is_false(box.focused)
		end)

		it("createMockButton should create functional button", function()
			local button = UIMocks.createMockButton(true)
			assert.is_true(button:IsVisible())

			button:Hide()
			assert.is_false(button:IsVisible())

			button:Click()
			assert.are.equal(1, button.clickCount)
		end)

		it("createFrameManager should manage frame storage", function()
			local mgr = UIMocks.createFrameManager()
			local frame = {}
			mgr:SetFrame("testFrame", frame)
			assert.are.equal(frame, mgr:GetFrame("testFrame"))
		end)
	end)

	describe("Function Mocks", function()
		it("createSpy should track function calls", function()
			local spy, tracker = UIMocks.createSpy("return value")
			assert.is_function(spy)
			assert.is_false(tracker.called)

			local result = spy("arg1", "arg2")
			assert.are.equal("return value", result)
			assert.is_true(tracker.called)
			assert.are.equal(1, tracker.callCount)
			assert.are.equal("arg1", tracker.args[1][1])
		end)

		it("createNoop should return no-op function", function()
			local noop = UIMocks.createNoop()
			assert.is_function(noop)
			assert.has_no.errors(function()
				noop()
			end)
		end)
	end)

	describe("Helper Functions", function()
		it("createMockPaginateArray should paginate correctly", function()
			local paginate = UIMocks.createMockPaginateArray()
			local items = { 1, 2, 3, 4, 5 }
			local paginated, total, page, pageCount = paginate(nil, items, 2, 1)

			assert.are.equal(2, #paginated)
			assert.are.equal(5, total)
			assert.are.equal(1, page)
			assert.are.equal(3, pageCount)
		end)

		it("setupNamespace should create BookArchivist tables", function()
			UIMocks.setupNamespace()
			assert.is_table(_G.BookArchivist)
			assert.is_table(_G.BookArchivist.UI)
			assert.is_table(_G.BookArchivist.UI.List)
		end)

		it("createMockLocalization should return fallback table", function()
			local L = UIMocks.createMockLocalization({ KNOWN_KEY = "Known Value" })
			assert.are.equal("Known Value", L.KNOWN_KEY)
			assert.are.equal("UNKNOWN_KEY", L.UNKNOWN_KEY) -- Fallback
		end)
	end)

	teardown(function()
		UIMocks.resetGlobals()
	end)
end)
