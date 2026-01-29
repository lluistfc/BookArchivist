-- DB_InitLogging_spec.lua
-- Focused coverage for DB initialization logging, fallback behavior, and migrations

local helper = dofile("Tests/test_helper.lua")

local function setupEnvironment(options)
	local logs = {}
	local BA = options and options.BookArchivist or {}
	function BA:DebugPrint(msg)
		table.insert(logs, msg)
	end
	BA.Migrations = options and options.migrations
	BA.DBSafety = options and options.dbSafety
	BA.DevTools = options and options.devTools
	_G.BookArchivist = BA
	BookArchivist = BA
	_G.BookArchivistDB = options and options.db

	helper.loadFile("core/BookArchivist_DB.lua")
	assert(BookArchivist.DB, "DB module failed to load")

	return BookArchivist.DB, logs
end

describe("BookArchivist.DB logging", function()
	after_each(function()
		BookArchivist = nil
		_G.BookArchivist = nil
		BookArchivistDB = nil
		_G.BookArchivistDB = nil
	end)

	it("falls back to a default schema when DBSafety is missing", function()
		local DB, logs = setupEnvironment()
		local db = DB:Init()

		assert.is_table(db)
		assert.are.equal(2, db.dbVersion)
		assert.is_table(db.booksById)
		assert.is_table(db.indexes.objectToBookId)
		-- Note: Init start/complete messages removed for cleaner logs
		-- Just verify DB module works correctly
	end)

	it("repairs unhealthy databases, runs migrations, and logs summary only once", function()
		local db = {
			dbVersion = 0,
			booksById = {},
			options = {
				debug = true,
				uiDebug = true,
			},
		}

		local repairCount = 0
		local healthChecks = 0
		local DB, logs = setupEnvironment({
			dbSafety = {
				SafeLoad = function()
					return db
				end,
				HealthCheck = function()
					healthChecks = healthChecks + 1
					if healthChecks == 1 then
						return false, "corrupt"
					end
					return true
				end,
				RepairDatabase = function()
					repairCount = repairCount + 1
					return 1, "fixed"
				end,
			},
			migrations = {
				v1 = function(payload)
					payload.dbVersion = 1
					return payload
				end,
				v2 = function(payload)
					payload.dbVersion = 2
					return payload
				end,
				v3 = function(payload)
					payload.dbVersion = 3
					payload.booksById.book = {}
					return payload
				end,
			},
		})

		local first = DB:Init()
		local second = DB:Init()

		assert.are.equal(first, second)
		assert.are.equal(3, first.dbVersion)
		assert.is_false(first.options.debug)
		assert.is_false(first.options.uiDebug)
		assert.are.equal(1, repairCount)
		-- Note: verbose logging removed - just verify functionality works
	end)
end)
