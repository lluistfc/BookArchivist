-- Order and Sorting tests
-- Tests order management (TouchOrder, AppendOrder, Delete) and sorting comparators

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Mock Core for Order module dependency
BookArchivist.Core = {
	__db = nil,
	EnsureDB = function(self)
		if not self.__db then
			self.__db = {
				order = {},
				booksById = {},
				recent = { list = {} },
				uiState = {},
			}
		end
		return self.__db
	end,
	GetDB = function(self)
		return self:EnsureDB()
	end,
}

-- Load Order module
helper.loadFile("core/BookArchivist_Order.lua")

-- Helper to reset database
local function resetDB()
	BookArchivist.Core.__db = {
		order = {},
		booksById = {},
		recent = { list = {} },
		uiState = {},
		indexes = {
			objectToBookId = {},
			itemToBookIds = {},
			titleToBookIds = {},
		},
	}
	return BookArchivist.Core.__db
end

describe("Order Management (Core Module)", function()
	describe("TouchOrder", function()
		it("should add new key to beginning of order", function()
			local db = resetDB()
			BookArchivist.Core:TouchOrder("book1")

			assert.are.equal(1, #db.order)
			assert.are.equal("book1", db.order[1])
		end)

		it("should move existing key to beginning", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:TouchOrder("book2")

			assert.are.equal(3, #db.order)
			assert.are.equal("book2", db.order[1])
			assert.are.equal("book1", db.order[2])
			assert.are.equal("book3", db.order[3])
		end)

		it("should handle key already at beginning", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:TouchOrder("book1")

			assert.are.equal(3, #db.order)
			assert.are.equal("book1", db.order[1])
		end)

		it("should move key from end to beginning", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:TouchOrder("book3")

			assert.are.equal(3, #db.order)
			assert.are.equal("book3", db.order[1])
			assert.are.equal("book1", db.order[2])
			assert.are.equal("book2", db.order[3])
		end)

		it("should handle nil key", function()
			local db = resetDB()
			db.order = { "book1" }

			BookArchivist.Core:TouchOrder(nil)

			assert.are.equal(1, #db.order)
			assert.are.equal("book1", db.order[1])
		end)
	end)

	describe("AppendOrder", function()
		it("should add new key to end of order", function()
			local db = resetDB()
			BookArchivist.Core:AppendOrder("book1")

			assert.are.equal(1, #db.order)
			assert.are.equal("book1", db.order[1])
		end)

		it("should move existing key to end", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:AppendOrder("book1")

			assert.are.equal(3, #db.order)
			assert.are.equal("book2", db.order[1])
			assert.are.equal("book3", db.order[2])
			assert.are.equal("book1", db.order[3])
		end)

		it("should handle key already at end", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:AppendOrder("book3")

			assert.are.equal(3, #db.order)
			assert.are.equal("book3", db.order[3])
		end)

		it("should move key from middle to end", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:AppendOrder("book2")

			assert.are.equal(3, #db.order)
			assert.are.equal("book1", db.order[1])
			assert.are.equal("book3", db.order[2])
			assert.are.equal("book2", db.order[3])
		end)

		it("should handle nil key", function()
			local db = resetDB()
			db.order = { "book1" }

			BookArchivist.Core:AppendOrder(nil)

			assert.are.equal(1, #db.order)
		end)
	end)

	describe("Delete", function()
		it("should remove book from booksById and order", function()
			local db = resetDB()
			db.booksById["book1"] = { title = "Test" }
			db.order = { "book1", "book2" }

			BookArchivist.Core:Delete("book1")

			assert.is_nil(db.booksById["book1"])
			assert.are.equal(1, #db.order)
			assert.are.equal("book2", db.order[1])
		end)

		it("should remove from recent list", function()
			local db = resetDB()
			db.booksById["book1"] = { title = "Test" }
			db.order = { "book1", "book2" }
			db.recent.list = { "book1", "book3" }

			BookArchivist.Core:Delete("book1")

			assert.are.equal(1, #db.recent.list)
			assert.are.equal("book3", db.recent.list[1])
		end)

		it("should clear uiState.lastBookId if deleted", function()
			local db = resetDB()
			db.booksById["book1"] = { title = "Test" }
			db.order = { "book1" }
			db.uiState.lastBookId = "book1"

			BookArchivist.Core:Delete("book1")

			assert.is_nil(db.uiState.lastBookId)
		end)

		it("should not clear uiState.lastBookId for different book", function()
			local db = resetDB()
			db.booksById["book1"] = { title = "Test" }
			db.booksById["book2"] = { title = "Other" }
			db.order = { "book1", "book2" }
			db.uiState.lastBookId = "book2"

			BookArchivist.Core:Delete("book1")

			assert.are.equal("book2", db.uiState.lastBookId)
		end)

		it("should handle deleting non-existent book", function()
			local db = resetDB()
			db.order = { "book1" }

			BookArchivist.Core:Delete("book2")

			assert.are.equal(1, #db.order)
			assert.are.equal("book1", db.order[1])
		end)

		it("should handle nil key", function()
			local db = resetDB()
			db.order = { "book1" }

			BookArchivist.Core:Delete(nil)

			assert.are.equal(1, #db.order)
		end)

		it("should remove last occurrence from order (reverse iteration)", function()
			local db = resetDB()
			db.booksById["book1"] = { title = "Test" }
			-- removeFromOrder iterates in reverse and returns after first match
			db.order = { "book1", "book2", "book1", "book3" }

			BookArchivist.Core:Delete("book1")

			-- Reverse iteration removes last occurrence, then booksById is nil so book1 won't be in order anymore
			-- Actually Delete calls removeFromOrder once, which removes from end going backwards
			assert.are.equal(3, #db.order)
			assert.are.equal("book1", db.order[1]) -- First book1 remains
			assert.are.equal("book2", db.order[2])
			assert.are.equal("book3", db.order[3])
		end)

		describe("Index cleanup", function()
			it("should remove book from title index", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "Test Book",
					pages = { "Content" },
				}
				db.order = { bookId }
				
				-- Manually set up title index
				db.indexes.titleToBookIds = db.indexes.titleToBookIds or {}
				db.indexes.titleToBookIds["test book"] = { bookId }
				
				BookArchivist.Core:Delete(bookId)
				
				-- Book should be removed from booksById
				assert.is_nil(db.booksById[bookId])
				
				-- Title index should be cleaned up
				assert.is_nil(db.indexes.titleToBookIds["test book"])
			end)

			it("should remove book from item index", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "Test Book",
					itemId = 12345,
					pages = { "Content" },
				}
				db.order = { bookId }
				
				-- Manually set up item index
				db.indexes.itemToBookIds = db.indexes.itemToBookIds or {}
				db.indexes.itemToBookIds[12345] = { bookId }
				
				BookArchivist.Core:Delete(bookId)
				
				-- Book should be removed from booksById
				assert.is_nil(db.booksById[bookId])
				
				-- Item index should be cleaned up
				assert.is_nil(db.indexes.itemToBookIds[12345])
			end)

			it("should remove book from object index", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "Test Book",
					objectId = 67890,
					pages = { "Content" },
				}
				db.order = { bookId }
				
				-- Manually set up object index
				db.indexes.objectToBookId = db.indexes.objectToBookId or {}
				db.indexes.objectToBookId[67890] = bookId
				
				BookArchivist.Core:Delete(bookId)
				
				-- Book should be removed from booksById
				assert.is_nil(db.booksById[bookId])
				
				-- Object index should be cleaned up
				assert.is_nil(db.indexes.objectToBookId[67890])
			end)

			it("should clean up all indexes for a book with multiple index entries", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "Complete Book",
					itemId = 12345,
					objectId = 67890,
					pages = { "Content" },
				}
				db.order = { bookId }
				
				-- Set up all indexes
				db.indexes.titleToBookIds = db.indexes.titleToBookIds or {}
				db.indexes.titleToBookIds["complete book"] = { bookId }
				db.indexes.itemToBookIds = db.indexes.itemToBookIds or {}
				db.indexes.itemToBookIds[12345] = { bookId }
				db.indexes.objectToBookId = db.indexes.objectToBookId or {}
				db.indexes.objectToBookId[67890] = bookId
				
				BookArchivist.Core:Delete(bookId)
				
				-- Book should be removed from booksById
				assert.is_nil(db.booksById[bookId])
				
				-- All indexes should be cleaned up
				assert.is_nil(db.indexes.titleToBookIds["complete book"])
				assert.is_nil(db.indexes.itemToBookIds[12345])
				assert.is_nil(db.indexes.objectToBookId[67890])
			end)

			it("should only remove target book from multi-book title index", function()
				local db = resetDB()
				local bookId1 = "book1"
				local bookId2 = "book2"
				
				db.booksById[bookId1] = {
					id = bookId1,
					title = "Shared Title",
					pages = { "Content 1" },
				}
				db.booksById[bookId2] = {
					id = bookId2,
					title = "Shared Title",
					pages = { "Content 2" },
				}
				db.order = { bookId1, bookId2 }
				
				-- Both books share the same title
				db.indexes.titleToBookIds = db.indexes.titleToBookIds or {}
				db.indexes.titleToBookIds["shared title"] = { bookId1, bookId2 }
				
				BookArchivist.Core:Delete(bookId1)
				
				-- bookId1 should be removed
				assert.is_nil(db.booksById[bookId1])
				
				-- bookId2 should remain in booksById
				assert.is_not_nil(db.booksById[bookId2])
				
				-- Title index should only contain bookId2
				assert.is_not_nil(db.indexes.titleToBookIds["shared title"])
				assert.are.equal(1, #db.indexes.titleToBookIds["shared title"])
				assert.are.equal(bookId2, db.indexes.titleToBookIds["shared title"][1])
			end)

			it("should handle book with no indexes gracefully", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "No Indexes Book",
					pages = { "Content" },
					-- No itemId, no objectId
				}
				db.order = { bookId }
				
				-- Don't set up any indexes
				
				-- Should not error
				assert.has_no.errors(function()
					BookArchivist.Core:Delete(bookId)
				end)
				
				-- Book should be removed
				assert.is_nil(db.booksById[bookId])
			end)

			it("should handle missing indexes table gracefully", function()
				local db = resetDB()
				local bookId = "book1"
				db.booksById[bookId] = {
					id = bookId,
					title = "Test",
					pages = { "Content" },
				}
				db.order = { bookId }
				
				-- Remove indexes table entirely
				db.indexes = nil
				
				-- Should not error
				assert.has_no.errors(function()
					BookArchivist.Core:Delete(bookId)
				end)
				
				-- Book should still be removed
				assert.is_nil(db.booksById[bookId])
			end)
		end)
	end)

	describe("Order consistency", function()
		it("should not create duplicates with TouchOrder", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:TouchOrder("book2")
			BookArchivist.Core:TouchOrder("book2")
			BookArchivist.Core:TouchOrder("book2")

			assert.are.equal(3, #db.order)
			-- Verify no duplicates
			local seen = {}
			for _, key in ipairs(db.order) do
				assert.is_nil(seen[key], "Found duplicate: " .. key)
				seen[key] = true
			end
		end)

		it("should not create duplicates with AppendOrder", function()
			local db = resetDB()
			db.order = { "book1", "book2", "book3" }

			BookArchivist.Core:AppendOrder("book2")
			BookArchivist.Core:AppendOrder("book2")

			assert.are.equal(3, #db.order)
			-- Verify no duplicates
			local seen = {}
			for _, key in ipairs(db.order) do
				assert.is_nil(seen[key], "Found duplicate: " .. key)
				seen[key] = true
			end
		end)

		it("should handle complex sequence of operations", function()
			local db = resetDB()

			BookArchivist.Core:AppendOrder("book1")
			BookArchivist.Core:AppendOrder("book2")
			BookArchivist.Core:TouchOrder("book3")
			BookArchivist.Core:AppendOrder("book4")
			BookArchivist.Core:TouchOrder("book2")

			assert.are.equal(4, #db.order)
			assert.are.equal("book2", db.order[1]) -- Touched last
			assert.are.equal("book3", db.order[2])
			assert.are.equal("book1", db.order[3])
			assert.are.equal("book4", db.order[4])
		end)
	end)
end)

-- Note: Sorting comparator tests would require loading the UI module
-- which has more dependencies. The sorting logic is already tested
-- indirectly through the integration tests that use filtering.
