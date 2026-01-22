---@diagnostic disable: undefined-global
-- Repository_spec.lua
-- Tests for the Repository pattern - single source of truth for DB access

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("BookArchivist.Repository", function()
	local Repository
	local originalDB

	before_each(function()
		-- Backup original global DB
		originalDB = BookArchivistDB
		
		-- Setup namespace
		helper.setupNamespace()
		
		-- Load the Repository module
		helper.loadFile("core/BookArchivist_Repository.lua")
		
		Repository = BookArchivist.Repository
		
		-- Create a test database for initialization
		BookArchivistDB = { booksById = {}, order = {} }
		Repository:Init(BookArchivistDB)
	end)

	after_each(function()
		-- Restore original global DB
		BookArchivistDB = originalDB
	end)

	describe("GetDB", function()
		it("should return the injected database", function()
			local testDB = { test = true, booksById = {} }
			Repository:Init(testDB)
			
			local result = Repository:GetDB()
			
			assert.are.equal(testDB, result)
			assert.is_true(result.test)
		end)

		it("should return nil if not initialized and global DB doesn't exist", function()
			-- Create fresh Repository without initialization
			helper.setupNamespace()
			helper.loadFile("core/BookArchivist_Repository.lua")
			local freshRepo = BookArchivist.Repository
			
			-- During early initialization, Repository returns nil instead of erroring
			-- This allows Core:GetDB() to fall back to ensureDB()
			local result = freshRepo:GetDB()
			assert.is_nil(result)
		end)
	end)

	describe("Test isolation via dependency injection", function()
		it("should allow tests to inject different databases", function()
			local prodDB = { production = true, booksById = {} }
			local testDB = { test = true, booksById = {} }
			
			-- Production init
			Repository:Init(prodDB)
			assert.are.equal(prodDB, Repository:GetDB())
			assert.is_true(Repository:GetDB().production)
			
			-- Test init (replaces production)
			Repository:Init(testDB)
			assert.are.equal(testDB, Repository:GetDB())
			assert.is_true(Repository:GetDB().test)
			
			-- Restore production
			Repository:Init(prodDB)
			assert.are.equal(prodDB, Repository:GetDB())
			assert.is_true(Repository:GetDB().production)
		end)

		it("should not leak test data between tests via dependency injection", function()
			local prodDB = { production = true, booksById = {} }
			
			-- Test 1
			local testDB1 = { test = 1, booksById = {} }
			Repository:Init(testDB1)
			Repository:GetDB().booksById["book1"] = { title = "Book 1" }
			
			-- Test 2 with fresh database
			local testDB2 = { test = 2, booksById = {} }
			Repository:Init(testDB2)
			local db2 = Repository:GetDB()
			
			-- Test 2 should not see Test 1's data
			assert.is_nil(db2.booksById["book1"])
			assert.are.equal(testDB2, db2)
			
			-- Production should be clean (never modified)
			Repository:Init(prodDB)
			assert.is_nil(prodDB.booksById["book1"])
		end)
	end)
end)
