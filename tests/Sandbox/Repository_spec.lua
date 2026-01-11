---@diagnostic disable: undefined-global
-- Repository_spec.lua
-- Tests for the Repository pattern - single source of truth for DB access

describe("BookArchivist.Repository", function()
	local Repository
	local originalDB

	before_each(function()
		-- Backup original global DB
		originalDB = BookArchivistDB
		
		-- Reset BookArchivist namespace
		BookArchivist = {
			Repository = {}
		}
		
		-- Load the Repository module
		dofile("core/BookArchivist_Repository.lua")
		Repository = BookArchivist.Repository
		Repository:Init()
	end)

	after_each(function()
		-- Restore original global DB
		BookArchivistDB = originalDB
	end)

	describe("GetDB", function()
		it("should return the BookArchivistDB global", function()
			local testDB = { test = true, booksById = {} }
			BookArchivistDB = testDB
			
			local result = Repository:GetDB()
			
			assert.are.equal(testDB, result)
			assert.is_true(result.test)
		end)

		it("should error if BookArchivistDB is nil", function()
			BookArchivistDB = nil
			
			assert.has_error(function()
				Repository:GetDB()
			end, "BookArchivist.Repository: BookArchivistDB not initialized - database not available")
		end)
	end)

	describe("Test isolation via global replacement", function()
		it("should allow tests to replace global DB temporarily", function()
			local prodDB = { production = true, booksById = {} }
			local testDB = { test = true, booksById = {} }
			
			BookArchivistDB = prodDB
			assert.are.equal(prodDB, Repository:GetDB())
			
			-- Simulate test setup
			BookArchivistDB = testDB
			assert.are.equal(testDB, Repository:GetDB())
			
			-- Simulate test teardown
			BookArchivistDB = prodDB
			assert.are.equal(prodDB, Repository:GetDB())
		end)

		it("should not leak test data between tests", function()
			local prodDB = { production = true, booksById = {} }
			BookArchivistDB = prodDB
			
			-- Test 1
			local testDB1 = { test = 1, booksById = {} }
			BookArchivistDB = testDB1
			Repository:GetDB().booksById["book1"] = { title = "Book 1" }
			BookArchivistDB = prodDB
			
			-- Test 2
			local testDB2 = { test = 2, booksById = {} }
			BookArchivistDB = testDB2
			local db2 = Repository:GetDB()
			
			-- Test 2 should not see Test 1's data
			assert.is_nil(db2.booksById["book1"])
			assert.are.equal(testDB2, db2)
			BookArchivistDB = prodDB
			
			-- Production should be clean
			assert.is_nil(prodDB.booksById["book1"])
		end)
	end)
end)
