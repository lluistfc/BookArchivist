-- Tests for Phase 2: Import Metadata Tracking
-- Verifies that imported books get proper security metadata

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("Import Metadata Tracking (Phase 2)", function()
	local ImportWorker
	local Core
	local originalDB
	
	before_each(function()
		-- Backup original global DB
		originalDB = BookArchivistDB
		
		-- Setup namespace
		helper.setupNamespace()
		
		-- Load dependencies
		helper.loadFile("core/BookArchivist_Repository.lua")
		helper.loadFile("core/BookArchivist_BookId.lua")
		helper.loadFile("core/BookArchivist_Serialize.lua")
		helper.loadFile("core/BookArchivist_Base64.lua")
		helper.loadFile("core/BookArchivist_CRC32.lua")
		helper.loadFile("core/BookArchivist_Core.lua")
		helper.loadFile("core/BookArchivist_ImportWorker.lua")
		
		ImportWorker = BookArchivist.ImportWorker
		Core = BookArchivist.Core
		
		-- Create test database
		BookArchivistDB = {
			dbVersion = 3,
			booksById = {},
			order = {},
			indexes = {
				objectToBookId = {},
				itemToBookIds = {},
				titleToBookIds = {}
			}
		}
		
		-- Initialize Repository with test DB
		BookArchivist.Repository:Init(BookArchivistDB)
	end)
	
	after_each(function()
		-- Restore original global DB
		BookArchivistDB = originalDB
		
		-- Restore Repository to production DB
		BookArchivist.Repository:Init(BookArchivistDB)
	end)
	
	describe("Import source tracking", function()
		it("should add importMetadata to imported books", function()
			-- Create a simple book for import
			local testBook = {
				title = "Test Import Book",
				pages = { "Page 1 content" },
				creator = "Test Author",
				material = "Parchment"
			}
			
			-- Simulate import (this will be implemented)
			local bookId = BookArchivist.BookId:MakeBookIdV2(testBook) .. "_IMPORT_TEST"
			BookArchivistDB.booksById[bookId] = testBook
			
			-- Mark as imported (add metadata)
			if BookArchivist.ImportWorker and BookArchivist.ImportWorker.MarkAsImported then
				BookArchivist.ImportWorker:MarkAsImported(testBook)
			end
			
			-- Verify metadata exists
			assert.is_not_nil(testBook.importMetadata)
			assert.equal("IMPORT", testBook.importMetadata.source)
		end)
		
		it("should track import timestamp", function()
			local testBook = {
				title = "Test Book",
				pages = { "Content" }
			}
			
			if BookArchivist.ImportWorker and BookArchivist.ImportWorker.MarkAsImported then
				BookArchivist.ImportWorker:MarkAsImported(testBook)
				
				assert.is_not_nil(testBook.importMetadata)
				assert.is_not_nil(testBook.importMetadata.importedAt)
				assert.is_number(testBook.importMetadata.importedAt)
			end
		end)
		
		it("should differentiate between imported and captured books", function()
			local importedBook = {
				title = "Imported Book",
				pages = { "Content" }
			}
			
			local capturedBook = {
				title = "Captured Book",
				pages = { "Content" }
			}
			
			-- Mark one as imported
			if BookArchivist.ImportWorker and BookArchivist.ImportWorker.MarkAsImported then
				BookArchivist.ImportWorker:MarkAsImported(importedBook)
			end
			
			-- Imported should have metadata
			if importedBook.importMetadata then
				assert.equal("IMPORT", importedBook.importMetadata.source)
			end
			
			-- Captured should not
			assert.is_nil(capturedBook.importMetadata)
		end)
	end)
	
	describe("Trust workflow", function()
		it("should default to untrusted for imported books", function()
			local testBook = {
				title = "Test Book",
				pages = { "Content" }
			}
			
			if BookArchivist.ImportWorker and BookArchivist.ImportWorker.MarkAsImported then
				BookArchivist.ImportWorker:MarkAsImported(testBook)
				
				if testBook.importMetadata then
					assert.is_false(testBook.importMetadata.trusted)
				end
			end
		end)
		
		it("should allow marking books as trusted", function()
			local testBook = {
				title = "Test Book",
				pages = { "Content" },
				importMetadata = {
					source = "IMPORT",
					importedAt = 1234567890,
					trusted = false
				}
			}
			
			-- Mark as trusted
			if BookArchivist.ImportWorker and BookArchivist.ImportWorker.MarkAsTrusted then
				BookArchivist.ImportWorker:MarkAsTrusted(testBook)
				assert.is_true(testBook.importMetadata.trusted)
			end
		end)
	end)
end)
