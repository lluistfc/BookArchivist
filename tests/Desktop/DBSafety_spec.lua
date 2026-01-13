-- DBSafety tests (corruption detection and database validation)
-- Tests SavedVariables structure validation and corruption handling

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Load bit library for hashing operations
helper.loadFile("tests/stubs/bit_library.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Mock functions
BookArchivist.DebugPrint = function(self, ...) end
_G.time = function()
	return 1234567890
end

-- Load DBSafety module
helper.loadFile("core/BookArchivist_DBSafety.lua")

describe("DBSafety (Corruption Detection)", function()
	local createdBackups = {}
	local originalDate = _G.date

	after_each(function()
		for _, name in ipairs(createdBackups) do
			_G[name] = nil
		end
		createdBackups = {}
		_G.BookArchivistDB = nil
		_G.date = originalDate
	end)

	describe("ValidateStructure", function()
		it("should accept valid modern database (v2)", function()
			local db = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = {},
					itemToBookIds = {},
					titleToBookIds = {},
				},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("should accept valid legacy database (v1)", function()
			local db = {
				version = 1,
				books = {}, -- Legacy structure
				order = {},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("should reject nil input", function()
			local valid, err = BookArchivist.DBSafety:ValidateStructure(nil)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("not a table") ~= nil)
		end)

		it("should reject non-table input", function()
			local valid, err = BookArchivist.DBSafety:ValidateStructure("not a table")

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("not a table") ~= nil)
		end)

		it("should reject database without books structure", function()
			local db = {
				order = {}, -- Missing both booksById and books
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("Neither booksById nor books") ~= nil)
		end)

		it("should reject database without order", function()
			local db = {
				booksById = {},
				-- Missing order
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("order is missing") ~= nil)
		end)

		it("should reject database with non-table order", function()
			local db = {
				booksById = {},
				order = "not a table",
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("order") ~= nil)
		end)

		it("should reject database with invalid dbVersion type", function()
			local db = {
				booksById = {},
				order = {},
				dbVersion = "not a number",
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("dbVersion") ~= nil)
		end)

		it("should reject database with invalid indexes structure", function()
			local db = {
				booksById = {},
				order = {},
				indexes = "not a table",
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("indexes") ~= nil)
		end)

		it("should reject database with invalid objectToBookId", function()
			local db = {
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = "not a table",
				},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("objectToBookId") ~= nil)
		end)

		it("should reject database with invalid options", function()
			local db = {
				booksById = {},
				order = {},
				options = "not a table",
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("options") ~= nil)
		end)

		it("should accept database with optional valid fields", function()
			local db = {
				dbVersion = 2,
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = {},
					itemToBookIds = {},
					titleToBookIds = {},
				},
				options = {
					debugMode = false,
				},
				recent = {
					cap = 50,
					list = {},
				},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_true(valid)
			assert.is_nil(err)
		end)
	end)

	describe("CloneTable", function()
		it("should clone simple values", function()
			assert.are.equal(42, BookArchivist.DBSafety:CloneTable(42))
			assert.are.equal("test", BookArchivist.DBSafety:CloneTable("test"))
			assert.are.equal(true, BookArchivist.DBSafety:CloneTable(true))
			assert.is_nil(BookArchivist.DBSafety:CloneTable(nil))
		end)

		it("should clone simple table", function()
			local original = { a = 1, b = 2, c = 3 }
			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal(original.a, clone.a)
			assert.are.equal(original.b, clone.b)
			assert.are.equal(original.c, clone.c)

			-- Verify it's a different table
			clone.a = 999
			assert.are.equal(1, original.a)
			assert.are.equal(999, clone.a)
		end)

		it("should clone nested table", function()
			local original = {
				level1 = {
					level2 = {
						level3 = "deep value",
					},
				},
			}
			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal("deep value", clone.level1.level2.level3)

			-- Verify independence
			clone.level1.level2.level3 = "changed"
			assert.are.equal("deep value", original.level1.level2.level3)
		end)

		it("should handle circular references", function()
			local original = { a = 1 }
			original.self = original

			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal(1, clone.a)
			assert.are.equal(clone, clone.self)
		end)

		it("should clone array-like tables", function()
			local original = { "a", "b", "c", "d", "e" }
			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal(5, #clone)
			for i = 1, 5 do
				assert.are.equal(original[i], clone[i])
			end

			-- Verify independence
			clone[1] = "changed"
			assert.are.equal("a", original[1])
		end)

		it("should clone mixed tables", function()
			local original = {
				[1] = "first",
				[2] = "second",
				name = "test",
				data = { nested = true },
			}
			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal("first", clone[1])
			assert.are.equal("second", clone[2])
			assert.are.equal("test", clone.name)
			assert.is_true(clone.data.nested)
		end)
	end)

	describe("InitializeFreshDB", function()
		it("should create database with v2 structure", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal(2, db.dbVersion)
			assert.are.equal("table", type(db.booksById))
			assert.are.equal("table", type(db.order))
		end)

		it("should create all required indexes", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal("table", type(db.indexes))
			assert.are.equal("table", type(db.indexes.objectToBookId))
			assert.are.equal("table", type(db.indexes.itemToBookIds))
			assert.are.equal("table", type(db.indexes.titleToBookIds))
		end)

		it("should create recent list with cap", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal("table", type(db.recent))
			assert.are.equal(50, db.recent.cap)
			assert.are.equal("table", type(db.recent.list))
			assert.are.equal(0, #db.recent.list)
		end)

		it("should create default UI state", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal("table", type(db.uiState))
			assert.are.equal("__all__", db.uiState.lastCategoryId)
		end)

		it("should set creation timestamp", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal("number", type(db.createdAt))
			assert.is_true(db.createdAt > 0)
		end)

		it("should create empty options", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			assert.are.equal("table", type(db.options))
		end)

		it("should pass validation", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_true(valid)
			assert.is_nil(err)
		end)
	end)

	describe("Integration scenarios", function()
		it("should detect corrupted database missing critical fields", function()
			local corrupted = {
				-- Missing booksById, books, and order
				someRandomField = "data",
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(corrupted)

			assert.is_false(valid)
			assert.is_not_nil(err)
		end)

		it("should accept database after migration from v1 to v2", function()
			local migratedDB = {
				version = 1, -- Legacy field preserved
				dbVersion = 2, -- New field
				books = {}, -- Legacy structure preserved
				booksById = {}, -- New structure
				order = {},
				indexes = {
					objectToBookId = {},
				},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(migratedDB)

			assert.is_true(valid)
			assert.is_nil(err)
		end)

		it("should handle partial corruption in indexes", function()
			local db = {
				dbVersion = 2,
				booksById = { book1 = { title = "Test" } },
				order = { "book1" },
				indexes = {
					objectToBookId = "CORRUPTED", -- Invalid type
				},
			}

			local valid, err = BookArchivist.DBSafety:ValidateStructure(db)

			assert.is_false(valid)
			assert.is_not_nil(err)
			assert.is_true(err:find("objectToBookId") ~= nil)
		end)

		it("should clone complex book structure", function()
			local original = {
				dbVersion = 2,
				booksById = {
					book1 = {
						title = "Test Book",
						pages = { [1] = "Page 1", [2] = "Page 2" },
						location = { zoneText = "Stormwind" },
						isFavorite = true,
					},
				},
				order = { "book1" },
			}

			local clone = BookArchivist.DBSafety:CloneTable(original)

			assert.are.equal("Test Book", clone.booksById.book1.title)
			assert.are.equal("Page 1", clone.booksById.book1.pages[1])

			-- Verify independence
			clone.booksById.book1.title = "Changed"
			assert.are.equal("Test Book", original.booksById.book1.title)
		end)
	end)

	describe("CreateBackup", function()
		it("clones the database into a timestamped global", function()
			_G.BookArchivistDB = {
				dbVersion = 2,
				booksById = {
					book1 = { title = "One", pages = { [1] = "Page" } },
				},
				order = { "book1" },
			}
			_G.date = function(pattern)
				assert.are.equal("%Y%m%d_%H%M%S", pattern)
				return "20260113_111111"
			end

			local backupName = BookArchivist.DBSafety:CreateBackup()
			table.insert(createdBackups, backupName)

			assert.are.equal("BookArchivistDB_Backup_20260113_111111", backupName)
			assert.is_table(_G[backupName])
			assert.are_not.equal(_G.BookArchivistDB, _G[backupName])
			_G.BookArchivistDB.booksById.book1.title = "Mutated"
			assert.are.equal("One", _G[backupName].booksById.book1.title)
		end)
	end)

	describe("HealthCheck", function()
		it("fails when database is missing", function()
			local healthy, issue = BookArchivist.DBSafety:HealthCheck(nil)
			assert.is_false(healthy)
			assert.is_true(issue:find("missing") ~= nil)
		end)

		it("reports orphaned order, invalid books, and invalid recents", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()
			db.booksById.good = { title = "Good", pages = { [1] = "Text" } }
			db.booksById.broken = "oops"
			db.order = { "good", "ghost" }
			db.recent.list = { "good", "missing" }

			local healthy, issue = BookArchivist.DBSafety:HealthCheck(db)
			assert.is_false(healthy)
			assert.is_true(issue:find("orphaned entries") ~= nil)
			assert.is_true(issue:find("books with invalid") ~= nil)
			assert.is_true(issue:find("invalid entries in recent") ~= nil)
		end)

		it("passes when structure is healthy", function()
			local db = BookArchivist.DBSafety:InitializeFreshDB()
			db.booksById.good = { title = "Good", pages = { [1] = "Text" } }
			db.order = { "good" }
			db.recent.list = { "good" }

			local healthy, issue = BookArchivist.DBSafety:HealthCheck(db)
			assert.is_true(healthy)
			assert.is_nil(issue)
		end)
	end)

	describe("RepairDatabase", function()
		it("repairs orphaned entries, invalid recents, ui state, and bad books", function()
			_G.BookArchivistDB = {
				booksById = {
					good = { title = "Good", pages = { [1] = "Text" } },
					bad = { title = nil, pages = nil },
				},
				order = { "good", "ghost1", "ghost2" },
				recent = { list = { "good", "ghostRecent" } },
				uiState = { lastBookId = "ghost1" },
			}

			local count, summary = BookArchivist.DBSafety:RepairDatabase()
			assert.are.equal(5, count)
			assert.is_true(summary:find("orphaned order") ~= nil)
			assert.is_true(summary:find("invalid recent") ~= nil)
			assert.is_true(summary:find("lastBookId") ~= nil)
			assert.is_true(summary:find("invalid book") ~= nil)
			assert.are.same({ "good" }, _G.BookArchivistDB.order)
			assert.are.same({ "good" }, _G.BookArchivistDB.recent.list)
			assert.is_nil(_G.BookArchivistDB.uiState.lastBookId)
			assert.is_nil(_G.BookArchivistDB.booksById.bad)
		end)

		it("recreates missing uiState", function()
			_G.BookArchivistDB = {
				booksById = { good = { title = "Good", pages = { [1] = "Text" } } },
				order = { "good" },
				recent = { list = { "good" } },
				uiState = nil,
			}

			local count, summary = BookArchivist.DBSafety:RepairDatabase()
			assert.are.equal(1, count)
			assert.is_true(summary:find("uiState") ~= nil)
			assert.are.equal("__all__", _G.BookArchivistDB.uiState.lastCategoryId)
		end)

		it("returns gracefully when db is missing", function()
			_G.BookArchivistDB = nil
			local count, summary = BookArchivist.DBSafety:RepairDatabase()
			assert.are.equal(0, count)
			assert.is_true(summary:find("Cannot repair") ~= nil)
		end)
	end)

	describe("GetAvailableBackups", function()
		it("lists backups with metadata sorted by name", function()
			local newer = "BookArchivistDB_Backup_20260113_020000"
			local older = "BookArchivistDB_Backup_CORRUPTED_20260113_010000"
			_G[newer] = { data = true }
			_G[older] = { nested = { value = true } }
			table.insert(createdBackups, newer)
			table.insert(createdBackups, older)

			local backups = BookArchivist.DBSafety:GetAvailableBackups()
			assert.are.equal(2, #backups)
			assert.are.equal(newer, backups[1].name)
			assert.is_false(backups[1].isCorrupted)
			assert.is_true(backups[1].size > 0)
			assert.are.equal(older, backups[2].name)
			assert.is_true(backups[2].isCorrupted)
		end)
	end)

	describe("EstimateSize", function()
		it("returns minimal values for primitives and estimates nested tables", function()
			assert.are.equal(0.001, BookArchivist.DBSafety:EstimateSize("string"))
			local size = BookArchivist.DBSafety:EstimateSize({
				one = true,
				two = { child = true },
			})
			assert.is_true(size > 0.1)
		end)
	end)
end)
