---@diagnostic disable: undefined-global
-- ListConfig_spec.lua
-- Tests for BookArchivist.ListConfig (list options management)

describe("ListConfig Module", function()
	local ListConfig, Repository
	local testDB
	
	setup(function()
		-- Mock environment
		_G.BookArchivist = {}
		_G.BookArchivistDB = nil
		
		-- Load modules
		dofile("./core/BookArchivist_Repository.lua")
		dofile("./core/BookArchivist_Core.lua") -- Core module needed for ListConfig
		dofile("./core/BookArchivist_ListConfig.lua")
		
		Repository = BookArchivist.Repository
		ListConfig = BookArchivist.ListConfig
	end)
	
	before_each(function()
		-- Create clean test database
		testDB = {
			dbVersion = 2,
			booksById = {},
			options = {}
		}
		
		Repository:Init(testDB)
	end)
	
	teardown(function()
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	describe("Module Loading", function()
		it("should load ListConfig module without errors", function()
			assert.is_not_nil(ListConfig)
			assert.equals("table", type(ListConfig))
		end)
		
		it("should have public API functions", function()
			assert.equals("function", type(ListConfig.EnsureListOptions))
			assert.equals("function", type(ListConfig.GetSortMode))
			assert.equals("function", type(ListConfig.SetSortMode))
			assert.equals("function", type(ListConfig.NormalizePageSize))
			assert.equals("function", type(ListConfig.GetListPageSize))
			assert.equals("function", type(ListConfig.SetListPageSize))
			assert.equals("function", type(ListConfig.GetListFilters))
			assert.equals("function", type(ListConfig.SetListFilter))
			assert.equals("function", type(ListConfig.GetPageSizes))
		end)
	end)
	
	describe("EnsureListOptions", function()
		it("should create options structure if missing", function()
			testDB.options = nil
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.is_not_nil(testDB.options)
			assert.is_not_nil(testDB.options.list)
			assert.is_not_nil(listOpts)
		end)
		
		it("should set default sortMode if missing", function()
			testDB.options = {}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.equals("lastSeen", listOpts.sortMode)
		end)
		
		it("should set default pageSize if missing", function()
			testDB.options = {}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.equals(25, listOpts.pageSize)
		end)
		
		it("should create filters table if missing", function()
			testDB.options = {}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.is_not_nil(listOpts.filters)
			assert.equals("table", type(listOpts.filters))
		end)
		
		it("should set filter defaults", function()
			testDB.options = {}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.equals(false, listOpts.filters.hasLocation)
			assert.equals(false, listOpts.filters.multiPage)
			assert.equals(false, listOpts.filters.unread)
			assert.equals(false, listOpts.filters.favoritesOnly)
		end)
		
		it("should remove legacy hasAuthor filter", function()
			testDB.options = {
				list = {
					filters = {
						hasAuthor = true
					}
				}
			}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.is_nil(listOpts.filters.hasAuthor)
		end)
		
		it("should preserve existing valid options", function()
			testDB.options = {
				list = {
					sortMode = "title",
					pageSize = 50,
					filters = {
						multiPage = true,
						favoritesOnly = true
					}
				}
			}
			
			local listOpts = ListConfig:EnsureListOptions()
			
			assert.equals("title", listOpts.sortMode)
			assert.equals(50, listOpts.pageSize)
			assert.equals(true, listOpts.filters.multiPage)
			assert.equals(true, listOpts.filters.favoritesOnly)
		end)
	end)
	
	describe("GetSortMode", function()
		it("should return default sortMode (lastSeen)", function()
			testDB.options = {}
			
			local mode = ListConfig:GetSortMode()
			
			assert.equals("lastSeen", mode)
		end)
		
		it("should return configured sortMode", function()
			testDB.options = {
				list = {
					sortMode = "title"
				}
			}
			
			local mode = ListConfig:GetSortMode()
			
			assert.equals("title", mode)
		end)
		
		it("should normalize invalid sortMode to default", function()
			testDB.options = {
				list = {
					sortMode = "invalid"
				}
			}
			
			local mode = ListConfig:GetSortMode()
			
			assert.equals("lastSeen", mode)
		end)
		
		it("should migrate legacy 'recent' to 'lastSeen'", function()
			testDB.options = {
				list = {
					sortMode = "recent"
				}
			}
			
			local mode = ListConfig:GetSortMode()
			
			assert.equals("lastSeen", mode)
			assert.equals("lastSeen", testDB.options.list.sortMode)
		end)
		
		it("should accept all valid sort modes", function()
			local validModes = { "title", "zone", "firstSeen", "lastSeen" }
			
			for _, validMode in ipairs(validModes) do
				testDB.options = {
					list = {
						sortMode = validMode
					}
				}
				
				local mode = ListConfig:GetSortMode()
				assert.equals(validMode, mode)
			end
		end)
	end)
	
	describe("SetSortMode", function()
		it("should set valid sortMode", function()
			testDB.options = {}
			
			ListConfig:SetSortMode("zone")
			
			local mode = ListConfig:GetSortMode()
			assert.equals("zone", mode)
		end)
		
		it("should reject invalid sortMode and use default", function()
			testDB.options = {}
			
			ListConfig:SetSortMode("invalid")
			
			local mode = ListConfig:GetSortMode()
			assert.equals("lastSeen", mode)
		end)
		
		it("should reject non-string sortMode", function()
			testDB.options = {}
			
			ListConfig:SetSortMode(123)
			
			local mode = ListConfig:GetSortMode()
			assert.equals("lastSeen", mode)
		end)
	end)
	
	describe("NormalizePageSize", function()
		it("should accept valid page size (10)", function()
			local size = ListConfig:NormalizePageSize(10)
			assert.equals(10, size)
		end)
		
		it("should accept valid page size (25)", function()
			local size = ListConfig:NormalizePageSize(25)
			assert.equals(25, size)
		end)
		
		it("should accept valid page size (50)", function()
			local size = ListConfig:NormalizePageSize(50)
			assert.equals(50, size)
		end)
		
		it("should accept valid page size (100)", function()
			local size = ListConfig:NormalizePageSize(100)
			assert.equals(100, size)
		end)
		
		it("should normalize invalid size to default (25)", function()
			local size = ListConfig:NormalizePageSize(37)
			assert.equals(25, size)
		end)
		
		it("should normalize nil to default", function()
			local size = ListConfig:NormalizePageSize(nil)
			assert.equals(25, size)
		end)
		
		it("should normalize string number", function()
			local size = ListConfig:NormalizePageSize("50")
			assert.equals(50, size)
		end)
		
		it("should normalize invalid string to default", function()
			local size = ListConfig:NormalizePageSize("invalid")
			assert.equals(25, size)
		end)
	end)
	
	describe("GetListPageSize", function()
		it("should return default page size (25)", function()
			testDB.options = {}
			
			local size = ListConfig:GetListPageSize()
			
			assert.equals(25, size)
		end)
		
		it("should return configured page size", function()
			testDB.options = {
				list = {
					pageSize = 50
				}
			}
			
			local size = ListConfig:GetListPageSize()
			
			assert.equals(50, size)
		end)
		
		it("should normalize invalid configured page size", function()
			testDB.options = {
				list = {
					pageSize = 999
				}
			}
			
			local size = ListConfig:GetListPageSize()
			
			assert.equals(25, size)
			assert.equals(25, testDB.options.list.pageSize)
		end)
	end)
	
	describe("SetListPageSize", function()
		it("should set valid page size", function()
			testDB.options = {}
			
			ListConfig:SetListPageSize(100)
			
			local size = ListConfig:GetListPageSize()
			assert.equals(100, size)
		end)
		
		it("should normalize invalid page size to default", function()
			testDB.options = {}
			
			ListConfig:SetListPageSize(77)
			
			local size = ListConfig:GetListPageSize()
			assert.equals(25, size)
		end)
	end)
	
	describe("GetListFilters", function()
		it("should return filters table", function()
			testDB.options = {}
			
			local filters = ListConfig:GetListFilters()
			
			assert.is_not_nil(filters)
			assert.equals("table", type(filters))
		end)
		
		it("should include all default filters", function()
			testDB.options = {}
			
			local filters = ListConfig:GetListFilters()
			
			assert.is_not_nil(filters.hasLocation)
			assert.is_not_nil(filters.multiPage)
			assert.is_not_nil(filters.unread)
			assert.is_not_nil(filters.favoritesOnly)
		end)
		
		it("should return configured filter values", function()
			testDB.options = {
				list = {
					filters = {
						multiPage = true,
						favoritesOnly = true
					}
				}
			}
			
			local filters = ListConfig:GetListFilters()
			
			assert.equals(true, filters.multiPage)
			assert.equals(true, filters.favoritesOnly)
			assert.equals(false, filters.hasLocation)
			assert.equals(false, filters.unread)
		end)
	end)
	
	describe("SetListFilter", function()
		it("should set filter to true", function()
			testDB.options = {}
			
			ListConfig:SetListFilter("multiPage", true)
			
			local filters = ListConfig:GetListFilters()
			assert.equals(true, filters.multiPage)
		end)
		
		it("should set filter to false", function()
			testDB.options = {
				list = {
					filters = {
						multiPage = true
					}
				}
			}
			
			ListConfig:SetListFilter("multiPage", false)
			
			local filters = ListConfig:GetListFilters()
			assert.equals(false, filters.multiPage)
		end)
		
		it("should coerce truthy values to true", function()
			testDB.options = {}
			
			ListConfig:SetListFilter("favoritesOnly", "yes")
			
			local filters = ListConfig:GetListFilters()
			assert.equals(true, filters.favoritesOnly)
		end)
		
		it("should coerce falsy values to false", function()
			testDB.options = {}
			
			ListConfig:SetListFilter("unread", nil)
			
			local filters = ListConfig:GetListFilters()
			assert.equals(false, filters.unread)
		end)
		
		it("should ignore nil filterKey", function()
			testDB.options = {}
			
			ListConfig:SetListFilter(nil, true)
			
			-- Should not crash
			assert.is_not_nil(testDB)
		end)
		
		it("should ignore unknown filter keys", function()
			testDB.options = {}
			ListConfig:EnsureListOptions()
			
			local filters = ListConfig:GetListFilters()
			local originalKeys = {}
			for k in pairs(filters) do
				originalKeys[k] = true
			end
			
			ListConfig:SetListFilter("unknownKey", true)
			
			-- Filter should not be added
			filters = ListConfig:GetListFilters()
			assert.is_nil(filters.unknownKey)
			
			-- Original keys should still exist
			for k in pairs(originalKeys) do
				assert.is_not_nil(filters[k])
			end
		end)
	end)
	
	describe("GetPageSizes", function()
		it("should return array of valid page sizes", function()
			local sizes = ListConfig:GetPageSizes()
			
			assert.is_not_nil(sizes)
			assert.equals("table", type(sizes))
			assert.is_true(#sizes > 0)
		end)
		
		it("should include all standard sizes", function()
			local sizes = ListConfig:GetPageSizes()
			
			local found = {}
			for _, size in ipairs(sizes) do
				found[size] = true
			end
			
			assert.is_true(found[10])
			assert.is_true(found[25])
			assert.is_true(found[50])
			assert.is_true(found[100])
		end)
		
		it("should return sorted array", function()
			local sizes = ListConfig:GetPageSizes()
			
			for i = 2, #sizes do
				assert.is_true(sizes[i] > sizes[i-1])
			end
		end)
	end)
	
	describe("Integration", function()
		it("should persist changes across calls", function()
			testDB.options = {}
			
			ListConfig:SetSortMode("title")
			ListConfig:SetListPageSize(100)
			ListConfig:SetListFilter("multiPage", true)
			
			-- Verify persistence
			assert.equals("title", ListConfig:GetSortMode())
			assert.equals(100, ListConfig:GetListPageSize())
			assert.equals(true, ListConfig:GetListFilters().multiPage)
		end)
		
		it("should handle multiple EnsureListOptions calls safely", function()
			testDB.options = {}
			
			ListConfig:EnsureListOptions()
			local opts1 = testDB.options.list
			
			ListConfig:EnsureListOptions()
			local opts2 = testDB.options.list
			
			-- Should return same reference
			assert.equals(opts1, opts2)
		end)
	end)
end)
