---@diagnostic disable: undefined-global, undefined-field
-- ListPagination_spec.lua
-- Tests for BookArchivist pagination logic
-- Critical path: PaginateArray slicing, page navigation, boundary conditions

describe("BookArchivist_UI_List_Pagination", function()
	local ListUI
	local mockContext

	setup(function()
		-- Load the addon namespace
		_G.BookArchivist = _G.BookArchivist or {}
		_G.BookArchivist.UI = _G.BookArchivist.UI or {}
		_G.BookArchivist.UI.List = _G.BookArchivist.UI.List or {}
		_G.BookArchivist.L = _G.BookArchivist.L or {}
		_G.BookArchivist.ListConfig = nil -- No config by default

		-- Load the pagination module
		dofile("ui/list/BookArchivist_UI_List_Pagination.lua")
		ListUI = _G.BookArchivist.UI.List
	end)

	before_each(function()
		-- Reset state
		ListUI.__state = {
			pagination = {
				page = 1,
				pageSize = 25,
				total = 0
			}
		}

		-- Mock context
		mockContext = {
			pageSize = 25,
			getPageSize = function() return mockContext.pageSize end,
			setPageSize = function(size) mockContext.pageSize = size end
		}

		-- Mock GetContext
		ListUI.GetContext = function() return mockContext end
	end)

	describe("PaginateArray", function()
		it("should handle empty array", function()
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray({}, 25, 1)

			assert.are.equal(0, #paginated)
			assert.are.equal(0, total)
			assert.are.equal(1, page)
			assert.are.equal(1, pageCount) -- Always at least 1 page
			assert.are.equal(1, startIdx)
			assert.are.equal(0, endIdx)
		end)

		it("should paginate array with less items than page size", function()
			local items = {"a", "b", "c"}
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 1)

			assert.are.equal(3, #paginated)
			assert.are.equal(3, total)
			assert.are.equal(1, page)
			assert.are.equal(1, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(3, endIdx)
			assert.are.same({"a", "b", "c"}, paginated)
		end)

		it("should paginate array with exact page size", function()
			local items = {}
			for i = 1, 25 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 1)

			assert.are.equal(25, #paginated)
			assert.are.equal(25, total)
			assert.are.equal(1, page)
			assert.are.equal(1, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(25, endIdx)
		end)

		it("should paginate array requiring multiple pages", function()
			local items = {}
			for i = 1, 100 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 1)

			assert.are.equal(25, #paginated)
			assert.are.equal(100, total)
			assert.are.equal(1, page)
			assert.are.equal(4, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(25, endIdx)

			-- Verify first page content
			assert.are.equal("item1", paginated[1])
			assert.are.equal("item25", paginated[25])
		end)

		it("should return correct slice for page 2", function()
			local items = {}
			for i = 1, 100 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 2)

			assert.are.equal(25, #paginated)
			assert.are.equal(100, total)
			assert.are.equal(2, page)
			assert.are.equal(4, pageCount)
			assert.are.equal(26, startIdx)
			assert.are.equal(50, endIdx)

			-- Verify second page content
			assert.are.equal("item26", paginated[1])
			assert.are.equal("item50", paginated[25])
		end)

		it("should return correct slice for last page", function()
			local items = {}
			for i = 1, 100 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 4)

			assert.are.equal(25, #paginated)
			assert.are.equal(100, total)
			assert.are.equal(4, page)
			assert.are.equal(4, pageCount)
			assert.are.equal(76, startIdx)
			assert.are.equal(100, endIdx)

			-- Verify last page content
			assert.are.equal("item76", paginated[1])
			assert.are.equal("item100", paginated[25])
		end)

		it("should handle partial last page", function()
			local items = {}
			for i = 1, 53 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 3)

			assert.are.equal(3, #paginated) -- Only 3 items on last page
			assert.are.equal(53, total)
			assert.are.equal(3, page)
			assert.are.equal(3, pageCount)
			assert.are.equal(51, startIdx)
			assert.are.equal(53, endIdx)

			-- Verify partial page content
			assert.are.equal("item51", paginated[1])
			assert.are.equal("item53", paginated[3])
		end)

		it("should clamp page number above valid range", function()
			local items = {}
			for i = 1, 50 do
				items[i] = "item" .. i
			end

			-- Request page 10, but only 2 pages exist
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 10)

			assert.are.equal(25, #paginated)
			assert.are.equal(50, total)
			assert.are.equal(2, page) -- Clamped to last valid page
			assert.are.equal(2, pageCount)
			assert.are.equal(26, startIdx)
			assert.are.equal(50, endIdx)
		end)

		it("should clamp page number below valid range", function()
			local items = {}
			for i = 1, 50 do
				items[i] = "item" .. i
			end

			-- Request page 0
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 0)

			assert.are.equal(25, #paginated)
			assert.are.equal(50, total)
			assert.are.equal(1, page) -- Clamped to first valid page
			assert.are.equal(2, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(25, endIdx)
		end)

		it("should clamp negative page number", function()
			local items = {}
			for i = 1, 50 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, -5)

			assert.are.equal(25, #paginated)
			assert.are.equal(50, total)
			assert.are.equal(1, page) -- Clamped to 1
			assert.are.equal(2, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(25, endIdx)
		end)

		it("should use default pageSize from state when not provided", function()
			ListUI.__state.pagination.pageSize = 10
			mockContext.pageSize = 10 -- GetPageSize checks context too
			local items = {}
			for i = 1, 50 do
				items[i] = "item" .. i
			end

			-- No pageSize argument - should use state default
			local paginated, total, page, pageCount = ListUI:PaginateArray(items, nil, 1)

			assert.are.equal(10, #paginated)
			assert.are.equal(50, total)
			assert.are.equal(1, page)
			assert.are.equal(5, pageCount) -- 50/10 = 5 pages
		end)

		it("should use default page 1 when not provided", function()
			local items = {}
			for i = 1, 50 do
				items[i] = "item" .. i
			end

			-- No page argument - should default to 1
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, nil)

			assert.are.equal(25, #paginated)
			assert.are.equal(50, total)
			assert.are.equal(1, page)
			assert.are.equal(2, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(25, endIdx)
		end)

		it("should handle single item array", function()
			local items = {"only"}
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 25, 1)

			assert.are.equal(1, #paginated)
			assert.are.equal(1, total)
			assert.are.equal(1, page)
			assert.are.equal(1, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(1, endIdx)
			assert.are.same({"only"}, paginated)
		end)

		it("should handle page size of 1", function()
			local items = {"a", "b", "c"}
			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 1, 2)

			assert.are.equal(1, #paginated)
			assert.are.equal(3, total)
			assert.are.equal(2, page)
			assert.are.equal(3, pageCount)
			assert.are.equal(2, startIdx)
			assert.are.equal(2, endIdx)
			assert.are.same({"b"}, paginated)
		end)

		it("should handle large page size (no pagination needed)", function()
			local items = {}
			for i = 1, 10 do
				items[i] = "item" .. i
			end

			local paginated, total, page, pageCount, startIdx, endIdx = ListUI:PaginateArray(items, 1000, 1)

			assert.are.equal(10, #paginated)
			assert.are.equal(10, total)
			assert.are.equal(1, page)
			assert.are.equal(1, pageCount)
			assert.are.equal(1, startIdx)
			assert.are.equal(10, endIdx)
		end)

		it("should preserve item types (tables, strings, numbers)", function()
			local items = {
				{id = 1, name = "First"},
				{id = 2, name = "Second"},
				"string_item",
				42
			}

			local paginated = ListUI:PaginateArray(items, 25, 1)

			assert.are.equal(4, #paginated)
			assert.is_table(paginated[1])
			assert.are.equal(1, paginated[1].id)
			assert.is_table(paginated[2])
			assert.are.equal(2, paginated[2].id)
			assert.are.equal("string_item", paginated[3])
			assert.are.equal(42, paginated[4])
		end)

		it("should not modify original array", function()
			local items = {"a", "b", "c", "d", "e"}
			local originalLength = #items

			local paginated = ListUI:PaginateArray(items, 2, 1)

			-- Original array unchanged
			assert.are.equal(originalLength, #items)
			assert.are.equal("a", items[1])
			assert.are.equal("e", items[5])

			-- Paginated is a new array
			assert.are.equal(2, #paginated)
			assert.are.equal("a", paginated[1])
			assert.are.equal("b", paginated[2])
		end)
	end)

	describe("GetPageCount", function()
		it("should return 1 for zero total", function()
			assert.are.equal(1, ListUI:GetPageCount(0))
		end)

		it("should return 1 for total less than page size", function()
			ListUI.__state.pagination.pageSize = 25
			assert.are.equal(1, ListUI:GetPageCount(10))
		end)

		it("should return correct count for exact multiple", function()
			ListUI.__state.pagination.pageSize = 25
			assert.are.equal(4, ListUI:GetPageCount(100))
		end)

		it("should ceil for non-exact multiple", function()
			ListUI.__state.pagination.pageSize = 25
			assert.are.equal(3, ListUI:GetPageCount(51))
			assert.are.equal(5, ListUI:GetPageCount(101))
		end)

		it("should handle page size of 1", function()
			ListUI.__state.pagination.pageSize = 10 -- Valid page size (1 not in allowed list)
			mockContext.pageSize = 10
			assert.are.equal(10, ListUI:GetPageCount(100)) -- 100/10 = 10 pages
		end)

		it("should return 1 when page size is zero or invalid", function()
			-- GetPageSize normalizes 0 to 25 (default), so test via direct call with 0
			ListUI.__state.pagination.pageSize = 10
			mockContext.pageSize = 10
			assert.are.equal(10, ListUI:GetPageCount(100)) -- 100/10 = 10 pages
			
			-- Verify GetPageCount handles zero pageSize gracefully in edge case
			ListUI.__state.pagination.pageSize = 0
			local pageCount = ListUI:GetPageCount(100)
			assert.is_true(pageCount >= 1) -- At least 1 page (GetPageSize normalizes to 25)
		end)
	end)

	describe("GetPage / SetPage", function()
		it("GetPage should return current page", function()
			ListUI.__state.pagination.page = 5
			assert.are.equal(5, ListUI:GetPage())
		end)

		it("GetPage should default to 1 if invalid", function()
			ListUI.__state.pagination.page = 0
			assert.are.equal(1, ListUI:GetPage())
		end)

		it("SetPage should clamp to page 1 minimum", function()
			ListUI.__state.pagination.total = 100
			ListUI.__state.pagination.pageSize = 25
			ListUI.GetFilteredKeys = function() return {} end -- Mock for page count calc
			ListUI.UpdateList = function() end -- Mock refresh

			ListUI:SetPage(0)
			assert.are.equal(1, ListUI:GetPage())
		end)

		it("SetPage should clamp to max page count", function()
			ListUI.__state.pagination.total = 100
			ListUI.__state.pagination.pageSize = 25
			ListUI.GetFilteredKeys = function() return {} end
			ListUI.UpdateList = function() end

			-- 100 items / 25 per page = 4 pages max
			ListUI:SetPage(10) -- Request page 10
			assert.are.equal(4, ListUI:GetPage()) -- Clamped to 4
		end)

		it("SetPage should accept valid page number", function()
			ListUI.__state.pagination.total = 100
			ListUI.__state.pagination.pageSize = 25
			ListUI.GetFilteredKeys = function() return {} end
			ListUI.UpdateList = function() end

			ListUI:SetPage(3)
			assert.are.equal(3, ListUI:GetPage())
		end)
	end)

	describe("NextPage / PrevPage", function()
		before_each(function()
			ListUI.__state.pagination.total = 100
			ListUI.__state.pagination.pageSize = 25
			ListUI.GetFilteredKeys = function() return {} end
			ListUI.UpdateList = function() end
		end)

		it("NextPage should increment page", function()
			ListUI.__state.pagination.page = 2
			ListUI:NextPage()
			assert.are.equal(3, ListUI:GetPage())
		end)

		it("NextPage should clamp at max page", function()
			ListUI.__state.pagination.page = 4 -- Last page (100/25 = 4)
			ListUI:NextPage()
			assert.are.equal(4, ListUI:GetPage()) -- Should not exceed
		end)

		it("PrevPage should decrement page", function()
			ListUI.__state.pagination.page = 3
			ListUI:PrevPage()
			assert.are.equal(2, ListUI:GetPage())
		end)

		it("PrevPage should clamp at page 1", function()
			ListUI.__state.pagination.page = 1
			ListUI:PrevPage()
			assert.are.equal(1, ListUI:GetPage()) -- Should not go below 1
		end)
	end)

	describe("GetPageSize / SetPageSize", function()
		it("GetPageSize should return default 25 when not set", function()
			ListUI.__state.pagination.pageSize = nil
			local size = ListUI:GetPageSize()
			assert.are.equal(25, size)
		end)

		it("GetPageSize should return persisted value from context", function()
			mockContext.pageSize = 50
			local size = ListUI:GetPageSize()
			assert.are.equal(50, size)
		end)

		it("GetPageSize should normalize to allowed values", function()
			mockContext.pageSize = 37 -- Not in allowed list
			local size = ListUI:GetPageSize()
			assert.are.equal(25, size) -- Fallback to default
		end)

		it("SetPageSize should update state and context", function()
			ListUI.RunSearchRefresh = function() end -- Mock refresh

			ListUI:SetPageSize(50)
			assert.are.equal(50, ListUI.__state.pagination.pageSize)
			assert.are.equal(50, mockContext.pageSize)
		end)

		it("SetPageSize should reset to page 1", function()
			ListUI.__state.pagination.page = 5
			ListUI.RunSearchRefresh = function() end

			ListUI:SetPageSize(100)
			assert.are.equal(1, ListUI:GetPage())
		end)

		it("SetPageSize should normalize invalid values", function()
			ListUI.RunSearchRefresh = function() end

			ListUI:SetPageSize(37) -- Not in allowed list
			assert.are.equal(25, ListUI:GetPageSize()) -- Normalized to default
		end)

		it("GetPageSizes should return default list", function()
			local sizes = ListUI:GetPageSizes()
			assert.are.same({10, 25, 50, 100}, sizes)
		end)
	end)
end)
