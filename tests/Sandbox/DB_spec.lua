---@diagnostic disable: undefined-global
-- DB_spec.lua
-- Tests for BookArchivist.DB (database initialization and migration)

describe("DB Module", function()
	local DB, DBSafety, Migrations, Repository
	local originalDB
	
	setup(function()
		-- Save original state
		originalDB = _G.BookArchivistDB
		
		-- Mock environment
		_G.BookArchivist = {}
		_G.time = os.time
		_G.C_Timer = {
			After = function(delay, callback)
				-- Immediately execute callback in tests
				callback()
			end
		}
		_G.StaticPopupDialogs = {} -- Mock for DBSafety corruption detection
		_G.StaticPopup_Show = function(dialogName) -- Mock popup function
			-- Do nothing in tests
		end
		
		-- Load modules in dependency order
		dofile("./core/BookArchivist_Repository.lua")
		dofile("./core/BookArchivist_Serialize.lua")
		dofile("./core/BookArchivist_DBSafety.lua")
		dofile("./core/BookArchivist_Migrations.lua")
		dofile("./core/BookArchivist_DB.lua")
		
		Repository = BookArchivist.Repository
		DB = BookArchivist.DB
		DBSafety = BookArchivist.DBSafety
		Migrations = BookArchivist.Migrations
	end)
	
	before_each(function()
		-- Reset global DB before each test
		_G.BookArchivistDB = nil
	end)
	
	after_each(function()
		-- Restore production DB after each test
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	teardown(function()
		-- Restore original state
		_G.BookArchivistDB = originalDB
		Repository:Init(_G.BookArchivistDB or {})
	end)
	
	describe("Module Loading", function()
		it("should load DB module without errors", function()
			assert.is_not_nil(DB)
			assert.equals("table", type(DB))
		end)
		
		it("should have Init function", function()
			assert.equals("function", type(DB.Init))
		end)
	end)
	
	describe("Init", function()
		it("should create BookArchivistDB if nil", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			
			assert.is_not_nil(_G.BookArchivistDB)
			assert.equals("table", type(_G.BookArchivistDB))
		end)
		
		it("should create v2 schema structure", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			
			local db = _G.BookArchivistDB
			assert.is_not_nil(db.dbVersion)
			assert.is_not_nil(db.booksById)
			assert.is_not_nil(db.order)
			assert.is_not_nil(db.options)
			assert.is_not_nil(db.indexes)
		end)
		
		it("should set dbVersion to 2", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			
			assert.equals(2, _G.BookArchivistDB.dbVersion)
		end)
		
		it("should create required indexes", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			
			local db = _G.BookArchivistDB
			assert.is_not_nil(db.indexes)
			assert.is_not_nil(db.indexes.objectToBookId)
		end)
		
		it("should set createdAt timestamp", function()
			_G.BookArchivistDB = nil
			
			local beforeTime = os.time()
			DB:Init()
			local afterTime = os.time()
			
			assert.is_not_nil(_G.BookArchivistDB.createdAt)
			assert.is_true(_G.BookArchivistDB.createdAt >= beforeTime)
			assert.is_true(_G.BookArchivistDB.createdAt <= afterTime)
		end)
	end)
	
	describe("Migration from v1 to v2", function()
		it("should migrate v1 database to v2", function()
			-- Create v1 database
			_G.BookArchivistDB = {
				dbVersion = 1,
				books = {
					["old-key"] = {
						title = "Old Book",
						pages = { [1] = "Content" }
					}
				},
				order = { "old-key" }
			}
			
			DB:Init()
			
			local db = _G.BookArchivistDB
			assert.equals(2, db.dbVersion)
			assert.is_not_nil(db.booksById)
			assert.is_not_nil(db.legacy)
		end)
		
		it("should preserve legacy data in v1 migration", function()
			_G.BookArchivistDB = {
				books = {
					["key1"] = { title = "Book 1" }
				},
				order = { "key1" }
			}
			
			DB:Init()
			
			local db = _G.BookArchivistDB
			assert.is_not_nil(db.legacy)
			assert.is_not_nil(db.legacy.books)
			assert.is_not_nil(db.legacy.order)
		end)
	end)
	
	describe("Existing v2 Database", function()
		it("should not re-migrate existing v2 database", function()
			-- Create a fully valid v2 database to avoid DBSafety reinitialization
			_G.BookArchivistDB = DBSafety:InitializeFreshDB()
			_G.BookArchivistDB.booksById["book-id-123"] = {
				id = "book-id-123",
				title = "Existing Book",
				pages = { [1] = "Content" }
			}
			_G.BookArchivistDB.order = { "book-id-123" }
			
			local originalTitle = _G.BookArchivistDB.booksById["book-id-123"].title
			
			DB:Init()
			
			-- Should preserve existing v2 structure
			assert.equals(2, _G.BookArchivistDB.dbVersion)
			assert.is_not_nil(_G.BookArchivistDB.booksById["book-id-123"])
			assert.equals(originalTitle, _G.BookArchivistDB.booksById["book-id-123"].title)
		end)
		
		it("should not create legacy snapshot for v2 database", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = {}
				},
				options = {}
			}
			
			DB:Init()
			
			-- v2 databases should not have legacy snapshots created
			assert.is_nil(_G.BookArchivistDB.legacy)
		end)
	end)
	
	describe("Corruption Handling", function()
		it("should handle completely invalid database", function()
			_G.BookArchivistDB = "not a table"
			
			DB:Init()
			
			-- Should create fresh database
			assert.equals("table", type(_G.BookArchivistDB))
			assert.is_not_nil(_G.BookArchivistDB.dbVersion)
		end)
		
		it("should validate and repair database structure", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {}, -- Valid
				order = "invalid", -- Invalid (should be table)
				indexes = {} -- Valid
			}
			
			DB:Init()
			
			-- DBSafety should repair the invalid structure
			assert.equals("table", type(_G.BookArchivistDB.order))
		end)
	end)
	
	describe("Debug Options Cleanup", function()
		it("should disable debug mode if DevTools not loaded", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = { objectToBookId = {} },
				options = {
					debug = true -- User had debug enabled
				}
			}
			
			-- Ensure DevTools is not loaded
			BookArchivist.DevTools = nil
			
			DB:Init()
			
			-- Debug should be disabled
			assert.equals(false, _G.BookArchivistDB.options.debug)
		end)
		
		it("should preserve debug mode if DevTools loaded", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = { objectToBookId = {} },
				options = {
					debug = true
				}
			}
			
			-- Simulate DevTools being loaded
			BookArchivist.DevTools = { enabled = true }
			
			DB:Init()
			
			-- Debug should remain enabled
			assert.equals(true, _G.BookArchivistDB.options.debug)
			
			-- Cleanup
			BookArchivist.DevTools = nil
		end)
		
		it("should disable uiDebug if DevTools not loaded", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = { objectToBookId = {} },
				options = {
					uiDebug = true
				}
			}
			
			BookArchivist.DevTools = nil
			
			DB:Init()
			
			assert.equals(false, _G.BookArchivistDB.options.uiDebug)
		end)
	end)
	
	describe("Safety Integration", function()
		it("should use DBSafety for safe loading", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			
			-- DBSafety should have created a valid structure
			local valid, err = DBSafety:ValidateStructure(_G.BookArchivistDB)
			assert.is_true(valid)
			assert.is_nil(err)
		end)
		
		it("should perform health check after loading", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = {}
				},
				options = {}
			}
			
			DB:Init()
			
			local healthy, issue = DBSafety:HealthCheck()
			assert.is_true(healthy)
			assert.is_nil(issue)
		end)
	end)
	
	describe("Multiple Init Calls", function()
		it("should handle multiple Init calls safely", function()
			_G.BookArchivistDB = nil
			
			DB:Init()
			local db1 = _G.BookArchivistDB
			
			DB:Init()
			local db2 = _G.BookArchivistDB
			
			-- Should return same reference
			assert.equals(db1, db2)
			assert.equals(2, db2.dbVersion)
		end)
		
		it("should preserve data across multiple Init calls", function()
			-- Create fully valid v2 database
			_G.BookArchivistDB = DBSafety:InitializeFreshDB()
			_G.BookArchivistDB.booksById["test-id"] = {
				id = "test-id",
				title = "Test Book",
				pages = { [1] = "Content" }
			}
			_G.BookArchivistDB.order = { "test-id" }
			
			DB:Init()
			
			assert.is_not_nil(_G.BookArchivistDB.booksById["test-id"])
			assert.equals("Test Book", _G.BookArchivistDB.booksById["test-id"].title)
			
			DB:Init()
			
			-- Data should still be there
			assert.is_not_nil(_G.BookArchivistDB.booksById["test-id"])
			assert.equals("Test Book", _G.BookArchivistDB.booksById["test-id"].title)
		end)
	end)
	
	describe("Edge Cases", function()
		it("should handle database with missing dbVersion", function()
			_G.BookArchivistDB = {
				booksById = {},
				order = {}
			}
			
			DB:Init()
			
			assert.is_not_nil(_G.BookArchivistDB.dbVersion)
			assert.equals("number", type(_G.BookArchivistDB.dbVersion))
		end)
		
		it("should handle database with string dbVersion", function()
			_G.BookArchivistDB = {
				dbVersion = "2", -- String instead of number
				booksById = {},
				order = {},
				indexes = { objectToBookId = {} }
			}
			
			DB:Init()
			
			assert.equals("number", type(_G.BookArchivistDB.dbVersion))
		end)
		
		it("should handle empty database object", function()
			_G.BookArchivistDB = {}
			
			DB:Init()
			
			assert.is_not_nil(_G.BookArchivistDB.dbVersion)
			assert.is_not_nil(_G.BookArchivistDB.booksById)
			assert.is_not_nil(_G.BookArchivistDB.order)
		end)
	end)
end)
