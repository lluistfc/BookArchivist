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
