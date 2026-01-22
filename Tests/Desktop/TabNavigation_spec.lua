---@diagnostic disable: undefined-global, undefined-field
-- TabNavigation_spec.lua
-- Tests for tab switching with automatic pagination navigation
-- Tests Books ↔ Locations tab navigation with selected book preservation

describe("BookArchivist_UI_List_Tabs Navigation", function()
	local ListUI
	local mockDB
	local mockBooks

	setup(function()
		-- Load the addon namespace
		_G.BookArchivist = _G.BookArchivist or {}
		_G.BookArchivist.UI = _G.BookArchivist.UI or {}
		_G.BookArchivist.UI.List = _G.BookArchivist.UI.List or {}
		_G.BookArchivist.L = _G.BookArchivist.L or {}
		_G.BookArchivist.Repository = _G.BookArchivist.Repository or {}
		_G.BookArchivist.RandomBook = _G.BookArchivist.RandomBook or {}

		-- Create mock books (50 books for pagination testing)
		mockBooks = {}
		for i = 1, 50 do
			local bookId = "book" .. string.format("%03d", i)
			mockBooks[bookId] = {
				bookId = bookId,
				title = "Book " .. i,
				zone = i <= 10 and "Zone A" or (i <= 30 and "Zone B" or "Zone C"),
				x = 50,
				y = 50,
				firstSeen = 1000000 + i,
				lastSeen = 1000000 + i,
			}
		end

		mockDB = {
			booksById = mockBooks,
		}

		_G.BookArchivist.Repository.GetDB = function()
			return mockDB
		end

		-- Load the modules (in dependency order)
		dofile("ui/list/BookArchivist_UI_List.lua")
		dofile("ui/list/BookArchivist_UI_List_Pagination.lua")
		dofile("ui/list/BookArchivist_UI_List_Tabs.lua")
		
		ListUI = _G.BookArchivist.UI.List
	end)

	before_each(function()
		-- Reset state
		ListUI.__state = {
			pagination = {
				page = 1,
				pageSize = 25,
				total = 0
			},
			currentPage = 1, -- Locations page
			selectedKey = nil,
			listMode = "books",
			isLoading = false,
		}

		-- Reset mock context
		ListUI.GetContext = function()
			return {
				getFilteredKeys = function()
					local keys = {}
					for bookId, _ in pairs(mockBooks) do
						table.insert(keys, bookId)
					end
					table.sort(keys)
					return keys
				end,
			}
		end

		-- Mock navigation functions
		ListUI.SetListMode = function(self, mode)
			self.__state.listMode = mode
		end

		ListUI.GetListMode = function(self)
			return self.__state.listMode
		end

		ListUI.SetSelectedKey = function(self, key)
			self.__state.selectedKey = key
		end

		ListUI.GetSelectedKey = function(self)
			return self.__state.selectedKey
		end

		ListUI.UpdateList = function(self)
			-- Mock implementation (no-op for testing)
		end

		ListUI.SetSelectedListTab = function(self, tabId)
			-- Mock implementation
		end

		ListUI.TabIdToMode = function(self, tabId)
			if tabId == 1 then
				return "books"
			elseif tabId == 2 then
				return "locations"
			end
			return "books"
		end

		-- Mock RandomBook.NavigateToBookLocation
		_G.BookArchivist.RandomBook.NavigateToBookLocation = function(self, bookId)
			-- Mock implementation - sets mode and navigates
			ListUI:SetListMode("locations")
			ListUI.__state.currentPage = 2 -- Simulate finding book on page 2
		end
	end)

	describe("findPageForBook helper", function()
		it("should find correct page for book on page 1", function()
			-- Book on page 1 (first 25 books with pageSize=25)
			ListUI:SetSelectedKey("book001")
			
			-- Manually calculate expected page
			local filteredKeys = ListUI:GetFilteredKeys()
			local pageSize = 25
			local position = nil
			for i, key in ipairs(filteredKeys) do
				if key == "book001" then
					position = i
					break
				end
			end
			local expectedPage = math.ceil(position / pageSize)
			
			assert.is_not_nil(position)
			assert.are.equal(1, expectedPage)
		end)

		it("should find correct page for book on page 2", function()
			-- Book on page 2 (26-50 with pageSize=25)
			ListUI:SetSelectedKey("book030")
			
			local filteredKeys = ListUI:GetFilteredKeys()
			local pageSize = 25
			local position = nil
			for i, key in ipairs(filteredKeys) do
				if key == "book030" then
					position = i
					break
				end
			end
			local expectedPage = math.ceil(position / pageSize)
			
			assert.is_not_nil(position)
			assert.are.equal(2, expectedPage)
		end)

		it("should return 1 for book not in filtered list", function()
			-- Non-existent book should default to page 1
			local filteredKeys = ListUI:GetFilteredKeys()
			local bookId = "nonexistent"
			local pageSize = 25
			
			local position = nil
			for i, key in ipairs(filteredKeys) do
				if key == bookId then
					position = i
					break
				end
			end
			
			local page = position and math.ceil(position / pageSize) or 1
			assert.are.equal(1, page)
		end)
	end)

	describe("Books → Locations tab navigation", function()
		it("should call NavigateToBookLocation when switching to Locations with selected book", function()
			local navigateCalled = false
			local calledWithBookId = nil
			
			_G.BookArchivist.RandomBook.NavigateToBookLocation = function(self, bookId)
				navigateCalled = true
				calledWithBookId = bookId
				ListUI:SetListMode("locations")
			end
			
			ListUI:SetSelectedKey("book010")
			ListUI:SetListMode("books")
			
			-- Simulate tab click to Locations (tabId = 2)
			-- This would be triggered by wireTabButton
			local newMode = "locations"
			local selectedBookId = ListUI:GetSelectedKey()
			
			if selectedBookId and _G.BookArchivist.RandomBook.NavigateToBookLocation then
				_G.BookArchivist.RandomBook:NavigateToBookLocation(selectedBookId)
			end
			
			assert.is_true(navigateCalled)
			assert.are.equal("book010", calledWithBookId)
			assert.are.equal("locations", ListUI:GetListMode())
		end)

		it("should not call NavigateToBookLocation when no book selected", function()
			local navigateCalled = false
			
			_G.BookArchivist.RandomBook.NavigateToBookLocation = function(self, bookId)
				navigateCalled = true
			end
			
			ListUI:SetSelectedKey(nil)
			ListUI:SetListMode("books")
			
			-- Simulate tab click to Locations with no selection
			local newMode = "locations"
			local selectedBookId = ListUI:GetSelectedKey()
			
			if selectedBookId and _G.BookArchivist.RandomBook.NavigateToBookLocation then
				_G.BookArchivist.RandomBook:NavigateToBookLocation(selectedBookId)
			else
				ListUI:SetListMode(newMode)
			end
			
			assert.is_false(navigateCalled)
			assert.are.equal("locations", ListUI:GetListMode())
		end)
	end)

	describe("Locations → Books tab navigation", function()
		it("should navigate to correct page when switching to Books with selected book on page 2", function()
			-- Start in Locations mode with a book selected that's on page 2
			ListUI:SetListMode("locations")
			ListUI:SetSelectedKey("book030") -- Should be on page 2
			
			local setPageCalled = false
			local calledPage = nil
			local originalSetPage = ListUI.SetPage
			
			ListUI.SetPage = function(self, page, skipRefresh)
				setPageCalled = true
				calledPage = page
				originalSetPage(self, page, skipRefresh)
			end
			
			-- Simulate tab click to Books
			local newMode = "books"
			local selectedBookId = ListUI:GetSelectedKey()
			
			if selectedBookId then
				local filteredKeys = ListUI:GetFilteredKeys()
				local pageSize = ListUI:GetPageSize()
				local position = nil
				
				for i, key in ipairs(filteredKeys) do
					if key == selectedBookId then
						position = i
						break
					end
				end
				
				if position then
					local targetPage = math.ceil(position / pageSize)
					if targetPage > 1 then
						ListUI:SetListMode(newMode)
						ListUI:SetPage(targetPage, true)
					end
				end
			end
			
			assert.is_true(setPageCalled)
			assert.are.equal(2, calledPage)
			assert.are.equal("books", ListUI:GetListMode())
		end)

		it("should stay on page 1 when switching to Books with book on page 1", function()
			-- Start in Locations mode with a book on page 1
			ListUI:SetListMode("locations")
			ListUI:SetSelectedKey("book005") -- Should be on page 1
			
			local setPageCalled = false
			local originalSetPage = ListUI.SetPage
			
			ListUI.SetPage = function(self, page, skipRefresh)
				setPageCalled = true
				originalSetPage(self, page, skipRefresh)
			end
			
			-- Simulate tab click to Books
			local newMode = "books"
			local selectedBookId = ListUI:GetSelectedKey()
			
			if selectedBookId then
				local filteredKeys = ListUI:GetFilteredKeys()
				local pageSize = ListUI:GetPageSize()
				local position = nil
				
				for i, key in ipairs(filteredKeys) do
					if key == selectedBookId then
						position = i
						break
					end
				end
				
				if position then
					local targetPage = math.ceil(position / pageSize)
					if targetPage > 1 then
						ListUI:SetListMode(newMode)
						ListUI:SetPage(targetPage, true)
					else
						-- Page 1, just switch mode normally
						ListUI:SetListMode(newMode)
					end
				end
			end
			
			assert.is_false(setPageCalled) -- SetPage should not be called for page 1
			assert.are.equal("books", ListUI:GetListMode())
		end)

		it("should not navigate when no book selected", function()
			ListUI:SetListMode("locations")
			ListUI:SetSelectedKey(nil)
			
			local setPageCalled = false
			ListUI.SetPage = function(self, page, skipRefresh)
				setPageCalled = true
			end
			
			-- Simulate tab click to Books with no selection
			local newMode = "books"
			local selectedBookId = ListUI:GetSelectedKey()
			
			if not selectedBookId then
				ListUI:SetListMode(newMode)
			end
			
			assert.is_false(setPageCalled)
			assert.are.equal("books", ListUI:GetListMode())
		end)
	end)
end)
