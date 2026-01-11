-- test_migrations.lua
-- Unit tests for BookArchivist database migrations

local test_results = {
	passed = 0,
	failed = 0,
	tests = {},
}

local function assert_equal(actual, expected, message)
	if actual == expected then
		return true
	else
		error(
			string.format(
				"%s\nExpected: %s\nActual: %s",
				message or "Assertion failed",
				tostring(expected),
				tostring(actual)
			)
		)
	end
end

local function assert_not_nil(value, message)
	if value ~= nil then
		return true
	else
		error(message or "Expected non-nil value")
	end
end

local function assert_type(value, expectedType, message)
	local actualType = type(value)
	if actualType == expectedType then
		return true
	else
		error(
			string.format(
				"%s\nExpected type: %s\nActual type: %s",
				message or "Type assertion failed",
				expectedType,
				actualType
			)
		)
	end
end

local function run_test(name, test_fn)
	local success, err = pcall(test_fn)
	if success then
		test_results.passed = test_results.passed + 1
		table.insert(test_results.tests, { name = name, status = "PASS" })
		print(string.format("✓ %s", name))
	else
		test_results.failed = test_results.failed + 1
		table.insert(test_results.tests, { name = name, status = "FAIL", error = err })
		print(string.format("✗ %s\n  %s", name, err))
	end
end

-- Mock WoW global functions for testing
_G.time = os.time
_G.date = os.date

-- Polyfill bit library for Lua 5.2+ (WoW uses Lua 5.1 with bit library)
if not bit then
	bit = {
		bxor = function(a, b)
			local r = 0
			local p = 1
			for i = 1, 32 do
				local aa = a % 2
				local bb = b % 2
				if aa ~= bb then
					r = r + p
				end
				a = math.floor(a / 2)
				b = math.floor(b / 2)
				p = p * 2
			end
			return r
		end,
		bor = function(a, b)
			local r = 0
			local p = 1
			for i = 1, 32 do
				if (a % 2) == 1 or (b % 2) == 1 then
					r = r + p
				end
				a = math.floor(a / 2)
				b = math.floor(b / 2)
				p = p * 2
			end
			return r
		end,
		band = function(a, b)
			local r = 0
			local p = 1
			for i = 1, 32 do
				if (a % 2) == 1 and (b % 2) == 1 then
					r = r + p
				end
				a = math.floor(a / 2)
				b = math.floor(b / 2)
				p = p * 2
			end
			return r
		end,
	}
end

-- Load the modules we need to test
package.path = package.path .. ";../core/?.lua"

-- Initialize BookArchivist namespace
BookArchivist = BookArchivist or {}

-- Load dependencies
dofile("../core/BookArchivist_BookId.lua")
dofile("../core/BookArchivist_Migrations.lua")
dofile("../core/BookArchivist_DBSafety.lua")

-- Helper to create a v1.0.2 database structure
local function create_v102_db()
	return {
		createdAt = 1767991132,
		version = 1,
		order = {
			"test book 1||||||first page of test book one",
			"test book 2||||||first page of test book two",
		},
		migrations = {
			authorPruned = true,
		},
		options = {
			minimapButton = {
				angle = 127.0,
			},
			debugEnabled = false,
			language = "enUS",
		},
		books = {
			["test book 1||||||first page of test book one"] = {
				seenCount = 5,
				creator = "",
				source = {
					objectID = 12345,
					kind = "world",
					objectType = "GameObject",
				},
				firstSeenAt = 1767991200,
				createdAt = 1767991200,
				key = "test book 1||||||first page of test book one",
				lastSeenAt = 1767991300,
				location = {
					mapID = 84,
					capturedAt = 5382.814,
					context = "world",
				},
				material = "",
				pages = {
					"First page of test book one",
					"Second page of test book one",
				},
				title = "Test Book 1",
			},
			["test book 2||||||first page of test book two"] = {
				seenCount = 3,
				creator = "Test Author",
				source = {
					objectID = 12346,
					kind = "world",
					objectType = "GameObject",
				},
				firstSeenAt = 1767991250,
				createdAt = 1767991250,
				key = "test book 2||||||first page of test book two",
				lastSeenAt = 1767991350,
				material = "Parchment",
				pages = {
					"First page of test book two",
				},
				title = "Test Book 2",
			},
		},
	}
end

-- Test 1: Validate legacy structure is accepted
run_test("DBSafety validates v1.0.2 structure", function()
	local db = create_v102_db()
	local valid, error = BookArchivist.DBSafety:ValidateStructure(db)

	assert_equal(valid, true, "v1.0.2 structure should be valid")
	assert_equal(error, nil, "Should have no error for valid v1.0.2 structure")
end)

-- Test 2: Validate modern structure is accepted
run_test("DBSafety validates modern structure", function()
	local db = {
		dbVersion = 2,
		version = 1,
		createdAt = os.time(),
		order = {},
		options = {},
		booksById = {},
		indexes = {
			objectToBookId = {},
		},
	}

	local valid, error = BookArchivist.DBSafety:ValidateStructure(db)

	assert_equal(valid, true, "Modern structure should be valid")
	assert_equal(error, nil, "Should have no error for valid modern structure")
end)

-- Test 3: Validate missing both tables fails
run_test("DBSafety rejects structure without books or booksById", function()
	local db = {
		order = {},
		options = {},
	}

	local valid, error = BookArchivist.DBSafety:ValidateStructure(db)

	assert_equal(valid, false, "Should reject structure without books tables")
	assert_not_nil(error, "Should have error message")
end)

-- Test 4: Validate missing order fails
run_test("DBSafety rejects structure without order table", function()
	local db = {
		books = {},
		options = {},
	}

	local valid, error = BookArchivist.DBSafety:ValidateStructure(db)

	assert_equal(valid, false, "Should reject structure without order table")
	assert_not_nil(error, "Should have error message")
end)

-- Test 5: v1 migration adds dbVersion
run_test("v1 migration adds dbVersion=1", function()
	local db = create_v102_db()
	db.dbVersion = nil -- Ensure it's not present

	local result = BookArchivist.Migrations.v1(db)

	assert_equal(result.dbVersion, 1, "Should set dbVersion to 1")
end)

-- Test 6: v2 migration creates booksById
run_test("v2 migration creates booksById from books", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	assert_type(result.booksById, "table", "Should create booksById table")
	assert_equal(result.dbVersion, 2, "Should set dbVersion to 2")
end)

-- Test 7: v2 migration preserves book data
run_test("v2 migration preserves all book data", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local originalBookCount = 0
	for _ in pairs(db.books) do
		originalBookCount = originalBookCount + 1
	end

	local result = BookArchivist.Migrations.v2(db)

	local migratedBookCount = 0
	for _ in pairs(result.booksById) do
		migratedBookCount = migratedBookCount + 1
	end

	assert_equal(migratedBookCount, originalBookCount, "Should preserve all books during migration")
end)

-- Test 8: v2 migration preserves book titles
run_test("v2 migration preserves book titles", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	local foundBook1 = false
	local foundBook2 = false

	for bookId, book in pairs(result.booksById) do
		if book.title == "Test Book 1" then
			foundBook1 = true
			assert_equal(#book.pages, 2, "Book 1 should have 2 pages")
		elseif book.title == "Test Book 2" then
			foundBook2 = true
			assert_equal(book.creator, "Test Author", "Book 2 should preserve creator")
		end
	end

	assert_equal(foundBook1, true, "Should find Test Book 1")
	assert_equal(foundBook2, true, "Should find Test Book 2")
end)

-- Test 9: v2 migration preserves seenCount
run_test("v2 migration preserves seenCount", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	for bookId, book in pairs(result.booksById) do
		assert_not_nil(book.seenCount, "Should have seenCount")
		assert_type(book.seenCount, "number", "seenCount should be a number")
	end
end)

-- Test 10: v2 migration creates legacy snapshot
run_test("v2 migration creates legacy snapshot", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	assert_type(result.legacy, "table", "Should create legacy table")
	assert_type(result.legacy.books, "table", "Should preserve legacy books")
	assert_type(result.legacy.order, "table", "Should preserve legacy order")
end)

-- Test 11: v2 migration creates indexes
run_test("v2 migration creates objectToBookId index", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	assert_type(result.indexes, "table", "Should create indexes table")
	assert_type(result.indexes.objectToBookId, "table", "Should create objectToBookId index")
end)

-- Test 12: v2 migration is idempotent
run_test("v2 migration is idempotent", function()
	local db = create_v102_db()
	db.dbVersion = 1

	-- Run migration once
	local result1 = BookArchivist.Migrations.v2(db)

	local count1 = 0
	for _ in pairs(result1.booksById) do
		count1 = count1 + 1
	end

	-- Run migration again (should no-op)
	local result2 = BookArchivist.Migrations.v2(result1)

	local count2 = 0
	for _ in pairs(result2.booksById) do
		count2 = count2 + 1
	end

	assert_equal(count2, count1, "Running v2 migration twice should not duplicate books")
	assert_equal(result2.dbVersion, 2, "dbVersion should remain 2")
end)

-- Test 13: v2 migration updates order to use new IDs
run_test("v2 migration updates order array", function()
	local db = create_v102_db()
	db.dbVersion = 1

	local result = BookArchivist.Migrations.v2(db)

	assert_type(result.order, "table", "Should have order table")
	assert_equal(#result.order, 2, "Should have 2 entries in order")

	-- Verify order entries reference books in booksById
	for _, bookId in ipairs(result.order) do
		assert_not_nil(result.booksById[bookId], "Order entry should reference existing book: " .. tostring(bookId))
	end
end)

-- Test 14: HealthCheck works with legacy structure
run_test("HealthCheck accepts legacy structure", function()
	local db = create_v102_db()

	-- Temporarily set global for health check
	local old_db = BookArchivistDB
	BookArchivistDB = db

	local healthy, issue = BookArchivist.DBSafety:HealthCheck()

	BookArchivistDB = old_db

	assert_equal(healthy, true, "Legacy structure should be healthy")
end)

-- Test 15: HealthCheck works with modern structure
run_test("HealthCheck accepts modern structure", function()
	local db = create_v102_db()
	db.dbVersion = 1
	local migrated = BookArchivist.Migrations.v2(db)

	-- Temporarily set global for health check
	local old_db = BookArchivistDB
	BookArchivistDB = migrated

	local healthy, issue = BookArchivist.DBSafety:HealthCheck()

	BookArchivistDB = old_db

	assert_equal(healthy, true, "Modern structure should be healthy")
end)

-- Test 16: Real v1.0.2 data migration (from dev/BookArchivist_v1_0_2.lua)
run_test("Real v1.0.2 data migrates successfully", function()
	-- Load actual v1.0.2 data (file sets global BookArchivistDB)
	local old_global_db = BookArchivistDB
	BookArchivistDB = nil
	dofile("../dev/BookArchivist_v1_0_2.lua")
	local real_v102_data = BookArchivistDB
	BookArchivistDB = old_global_db

	assert_not_nil(real_v102_data, "Should load real v1.0.2 data")

	-- Validate original structure
	local valid, error = BookArchivist.DBSafety:ValidateStructure(real_v102_data)
	assert_equal(valid, true, "Real v1.0.2 data should be valid: " .. tostring(error))

	-- Count original books
	local originalBookCount = 0
	for _ in pairs(real_v102_data.books or {}) do
		originalBookCount = originalBookCount + 1
	end

	assert_equal(originalBookCount, 7, "Should have 7 books in real v1.0.2 data")

	-- Run v1 migration
	real_v102_data.dbVersion = nil -- Ensure no dbVersion
	local v1_migrated = BookArchivist.Migrations.v1(real_v102_data)
	assert_equal(v1_migrated.dbVersion, 1, "v1 migration should set dbVersion=1")

	-- Run v2 migration
	local v2_migrated = BookArchivist.Migrations.v2(v1_migrated)
	assert_equal(v2_migrated.dbVersion, 2, "v2 migration should set dbVersion=2")

	-- Verify booksById created
	assert_type(v2_migrated.booksById, "table", "Should create booksById")

	-- Count migrated books
	local migratedBookCount = 0
	for _ in pairs(v2_migrated.booksById) do
		migratedBookCount = migratedBookCount + 1
	end

	assert_equal(
		migratedBookCount,
		originalBookCount,
		"Should preserve all " .. originalBookCount .. " books during migration"
	)

	-- Verify specific book titles from real data
	local foundTitles = {}
	for bookId, book in pairs(v2_migrated.booksById) do
		foundTitles[book.title] = true
	end

	assert_equal(foundTitles["The New Horde"], true, "Should find 'The New Horde'")
	assert_equal(foundTitles["The Guardians of Tirisfal"], true, "Should find 'The Guardians of Tirisfal'")
	assert_equal(foundTitles["The Alliance of Lordaeron"], true, "Should find 'The Alliance of Lordaeron'")

	-- Verify legacy snapshot created
	assert_type(v2_migrated.legacy, "table", "Should create legacy snapshot")
	assert_type(v2_migrated.legacy.books, "table", "Should preserve legacy books")
	assert_equal(v2_migrated.legacy.version, 1, "Should preserve legacy version")

	-- Verify order converted
	assert_type(v2_migrated.order, "table", "Should have order array")
	assert_equal(#v2_migrated.order, originalBookCount, "Order should have all books")

	-- Verify all order entries reference valid books
	for _, bookId in ipairs(v2_migrated.order) do
		assert_not_nil(
			v2_migrated.booksById[bookId],
			"Order entry should reference existing book: " .. tostring(bookId)
		)
	end

	-- Verify indexes created
	assert_type(v2_migrated.indexes, "table", "Should create indexes")
	assert_type(v2_migrated.indexes.objectToBookId, "table", "Should create objectToBookId index")
end)

-- Test 17: v2 migration removes legacy debug options
run_test("v2 migration removes legacy debug options", function()
	local db = create_v102_db()
	db.dbVersion = 1

	-- Add legacy debug options that existed in v1.0.2 (inside options table)
	db.options.debugEnabled = true
	db.options.gridMode = "static"
	db.options.gridVisible = false
	db.options.ba_hidden_anchor = { x = 100, y = 200 }

	-- Add listWidth that should be removed
	db.options.ui = db.options.ui or {}
	db.options.ui.listWidth = 360

	local v2_migrated = BookArchivist.Migrations.v2(db)

	-- Verify legacy options removed from options table
	assert_equal(v2_migrated.options.debugEnabled, nil, "Should remove debugEnabled")
	assert_equal(v2_migrated.options.gridMode, nil, "Should remove gridMode")
	assert_equal(v2_migrated.options.gridVisible, nil, "Should remove gridVisible")
	assert_equal(v2_migrated.options.ba_hidden_anchor, nil, "Should remove ba_hidden_anchor")

	-- Verify listWidth removed from ui options
	if type(v2_migrated.options.ui) == "table" then
		assert_equal(v2_migrated.options.ui.listWidth, nil, "Should remove ui.listWidth")
	end

	-- Verify new structure still intact
	assert_type(v2_migrated.booksById, "table", "Should have booksById")
	assert_equal(v2_migrated.dbVersion, 2, "Should have dbVersion 2")
end)

-- Print summary
print("\n" .. string.rep("=", 60))
print("Test Summary")
print(string.rep("=", 60))
print(string.format("Passed: %d", test_results.passed))
print(string.format("Failed: %d", test_results.failed))
print(string.format("Total:  %d", test_results.passed + test_results.failed))
print(string.rep("=", 60))

if test_results.failed > 0 then
	print("\nFailed tests:")
	for _, test in ipairs(test_results.tests) do
		if test.status == "FAIL" then
			print(string.format("  - %s", test.name))
		end
	end
	os.exit(1)
else
	print("\n✓ All tests passed!")
	os.exit(0)
end
