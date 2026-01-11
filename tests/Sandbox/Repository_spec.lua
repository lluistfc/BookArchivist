---@diagnostic disable: undefined-global
-- Repository_spec.lua
-- Tests for the Repository pattern - single source of truth for DB access

describe("BookArchivist.Repository", function()
	local Repository

	before_each(function()
		-- Reset BookArchivist namespace
		BookArchivist = {
			Core = {},
			Repository = {}
		}
		
		-- Load the Repository module
		dofile("core/BookArchivist_Repository.lua")
		Repository = BookArchivist.Repository
		Repository:Init()
	end)

	after_each(function()
		-- Clean up after each test
		if Repository then
			Repository:ClearTestDB()
		end
	end)

	describe("GetDB", function()
		it("should return test DB when SetTestDB was called", function()
			local testDB = { test = true, booksById = {} }
			
			Repository:SetTestDB(testDB)
			local result = Repository:GetDB()
			
			assert.are.equal(testDB, result)
			assert.is_true(result.test)
		end)

		it("should return production DB from Core.GetDB when no test DB is set", function()
			local prodDB = { production = true, booksById = {} }
			BookArchivist.Core.GetDB = function(self)
				return prodDB
			end
			
			local result = Repository:GetDB()
			
			assert.are.equal(prodDB, result)
			assert.is_true(result.production)
		end)

		it("should error if Core.GetDB is not available", function()
			BookArchivist.Core.GetDB = nil
			
			assert.has_error(function()
				Repository:GetDB()
			end, "BookArchivist.Repository: Core.GetDB not available - addon not properly initialized")
		end)

		it("should error if Core.GetDB returns nil", function()
			BookArchivist.Core.GetDB = function(self)
				return nil
			end
			
			assert.has_error(function()
				Repository:GetDB()
			end, "BookArchivist.Repository: Core.GetDB returned nil - database not initialized")
		end)

		it("should prefer test DB over production DB", function()
			local testDB = { test = true, booksById = {} }
			local prodDB = { production = true, booksById = {} }
			
			BookArchivist.Core.GetDB = function(self)
				return prodDB
			end
			Repository:SetTestDB(testDB)
			
			local result = Repository:GetDB()
			
			assert.are.equal(testDB, result)
			assert.is_true(result.test)
			assert.is_nil(result.production)
		end)
	end)

	describe("SetTestDB and ClearTestDB", function()
		it("should allow setting and clearing test DB", function()
			local testDB = { test = true, booksById = {} }
			local prodDB = { production = true, booksById = {} }
			
			BookArchivist.Core.GetDB = function(self)
				return prodDB
			end
			
			-- Initially should return production DB
			local result1 = Repository:GetDB()
			assert.are.equal(prodDB, result1)
			
			-- Set test DB
			Repository:SetTestDB(testDB)
			local result2 = Repository:GetDB()
			assert.are.equal(testDB, result2)
			
			-- Clear test DB
			Repository:ClearTestDB()
			local result3 = Repository:GetDB()
			assert.are.equal(prodDB, result3)
		end)

		it("should allow calling ClearTestDB multiple times safely", function()
			Repository:ClearTestDB()
			Repository:ClearTestDB()
			-- Should not error
		end)
	end)

	describe("IsTestMode", function()
		it("should return false when no test DB is set", function()
			assert.is_false(Repository:IsTestMode())
		end)

		it("should return true when test DB is set", function()
			local testDB = { test = true }
			Repository:SetTestDB(testDB)
			
			assert.is_true(Repository:IsTestMode())
		end)

		it("should return false after clearing test DB", function()
			local testDB = { test = true }
			Repository:SetTestDB(testDB)
			assert.is_true(Repository:IsTestMode())
			
			Repository:ClearTestDB()
			assert.is_false(Repository:IsTestMode())
		end)
	end)

	describe("Test isolation", function()
		it("should not allow test DB to leak into production", function()
			local testDB = { test = true, booksById = { book1 = {} } }
			local prodDB = { production = true, booksById = {} }
			
			BookArchivist.Core.GetDB = function(self)
				return prodDB
			end
			
			-- Simulate a test
			Repository:SetTestDB(testDB)
			local db = Repository:GetDB()
			db.booksById["test_book"] = { title = "Test" }
			Repository:ClearTestDB()
			
			-- Production DB should be unchanged
			assert.is_nil(prodDB.booksById["test_book"])
			assert.is_not_nil(testDB.booksById["test_book"])
		end)

		it("should isolate multiple sequential tests", function()
			local prodDB = { production = true, booksById = {} }
			BookArchivist.Core.GetDB = function(self)
				return prodDB
			end
			
			-- Test 1
			local testDB1 = { test = 1, booksById = {} }
			Repository:SetTestDB(testDB1)
			Repository:GetDB().booksById["book1"] = { title = "Book 1" }
			Repository:ClearTestDB()
			
			-- Test 2
			local testDB2 = { test = 2, booksById = {} }
			Repository:SetTestDB(testDB2)
			local db2 = Repository:GetDB()
			
			-- Test 2 should not see Test 1's data
			assert.is_nil(db2.booksById["book1"])
			assert.are.equal(testDB2, db2)
			Repository:ClearTestDB()
			
			-- Production should be clean
			assert.is_nil(prodDB.booksById["book1"])
		end)
	end)
end)
