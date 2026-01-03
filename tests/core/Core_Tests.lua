local addon = BookArchivist
local Core = addon and addon.Core
local WoWUnit = rawget(_G or {}, "WoWUnit")
local Helpers = BookArchivistTests and BookArchivistTests.Helpers

if not (addon and Core and WoWUnit and Helpers) then
	return
end

local CoreSuite = WoWUnit("BookArchivist Core", "PLAYER_LOGIN")

local function freshDB()
	Helpers.resetSavedVariables()
	return Core:EnsureDB()
end

function CoreSuite:EnsureDBSeedsDefaults()
	local db = freshDB()
	WoWUnit.IsNotNil(db.books)
	WoWUnit.IsNotNil(db.order)
	WoWUnit.IsNotNil(db.options)
	WoWUnit.AreEqual(false, db.options.debugEnabled)
	WoWUnit.AreEqual(200, db.options.minimapButton.angle)
end

function CoreSuite:PersistSessionCreatesEntry()
	local db = freshDB()
	local session = {
		title = "Test Book",
		creator = "Archivist",
		author = "Archivist",
		material = "Parchment",
		pages = { [1] = "Hello there." },
		source = { kind = "itemtext" },
		location = { zoneText = "Testing Zone" },
		startedAt = 111,
	}

	local entry = Core:PersistSession(session)
	local key = entry.key

	WoWUnit.Exists(entry)
	if not entry then
		WoWUnit.Fail("Core:PersistSession returned nil entry")
		return
	end
	WoWUnit.AreEqual("Test Book", entry.title)
	WoWUnit.AreEqual("Hello there.", entry.pages[1])
	WoWUnit.AreEqual(key, db.order[1])
	WoWUnit.AreEqual(entry, db.books[key])
end

function CoreSuite:DeleteRemovesEntriesFromOrder()
	local db = freshDB()
	local entry = Core:PersistSession({
		title = "Delete Me",
		creator = "",
		author = "",
		material = "",
		pages = { [1] = "Page" },
		source = { kind = "itemtext" },
	})

	WoWUnit.Exists(entry)
	if not entry then
		WoWUnit.Fail("Core:PersistSession returned nil entry")
		return
	end

	WoWUnit.AreEqual(entry.key, db.order[1])

	Core:Delete(entry.key)

	WoWUnit.IsNil(db.books[entry.key])
	WoWUnit.AreEqual(0, #db.order)
end
