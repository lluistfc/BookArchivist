---@diagnostic disable: undefined-global
-- BookArchivist_TestDataGenerator.lua
-- Development tool for generating test books to stress-test performance.
-- DO NOT load this in production - it's for development only.

local BA = BookArchivist

local Generator = {}
BA.TestDataGenerator = Generator

-- Module loaded confirmation
if BA and BA.DebugPrint then
	BA:DebugPrint("[TestDataGenerator] Module loaded")
end

local LOREM_IPSUM = {
	"Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
	"Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
	"Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
	"Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.",
	"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia.",
	"Nulla pariatur. Donec sollicitudin molestie malesuada.",
	"Vestibulum ac diam sit amet quam vehicula elementum sed sit amet dui.",
	"Pellentesque in ipsum id orci porta dapibus.",
	"Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.",
	"Mauris blandit aliquet elit, eget tincidunt nibh pulvinar a.",
}

local BOOK_TITLES = {
	"The Tome of Ancient Wisdom",
	"Chronicles of the Fallen Kingdom",
	"Secrets of the Arcane",
	"Journal of a Wandering Mage",
	"The Art of Enchantment",
	"Tales from the Eastern Kingdoms",
	"A History of Azeroth",
	"The Alchemy Codex",
	"Legends of the Titans",
	"Mysteries of the Old Gods",
	"The Druid's Path",
	"Warrior's Honor",
	"Songs of the Horde",
	"Alliance Military Tactics",
	"The Necromancer's Grimoire",
	"Cooking with Murlocs",
	"Flora and Fauna of Kalimdor",
	"Engineering for Beginners",
	"The Blacksmith's Manual",
	"Tailoring Techniques",
}

local AUTHORS = {
	"Archmage Antonidas",
	"Medivh the Guardian",
	"Khadgar",
	"Jaina Proudmoore",
	"Thrall",
	"Prophet Velen",
	"Malfurion Stormrage",
	"Tyrande Whisperwind",
	"Uther the Lightbringer",
	"Arthas Menethil",
	"Sylvanas Windrunner",
	"Vol'jin",
	"Baine Bloodhoof",
	"Genn Greymane",
	"Anduin Wrynn",
	"Unknown Author",
	"Anonymous Scribe",
	"Elder Historian",
	"Wandering Scholar",
	"Court Mage",
}

local MATERIALS = {
	"Parchment",
	"Vellum",
	"Ancient Leather",
	"Silk Paper",
	"Stone Tablet",
	"Enchanted Scroll",
	"Tattered Pages",
	"Bound Leather",
	"Golden Plates",
	"Runecloth",
}

local function getRandomElement(tbl)
	return tbl[math.random(1, #tbl)]
end

local function generatePageText(pageNum, totalPages, bookIndex)
	-- Make book index VERY prominent to ensure unique BookId
	-- Repeat it multiple times to guarantee uniqueness after normalization
	local uniquePrefix = string.format("TEST BOOK NUMBER %d %d %d", bookIndex, bookIndex, bookIndex)
	local pageHeader = string.format("Page %d of %d", pageNum, totalPages)

	local lines = { uniquePrefix, pageHeader, "" }

	-- Add some lorem ipsum content
	local numLines = 3 + ((bookIndex or 1) % 6)
	local offset = (bookIndex or 1) * 7

	for i = 1, numLines do
		local idx = ((offset + i - 1) % #LOREM_IPSUM) + 1
		table.insert(lines, LOREM_IPSUM[idx])
	end

	return table.concat(lines, " ")
end

--- Create a single test book with random content
--- @param index number Book index
--- @param options table|nil Configuration options
--- @return table book entry
function Generator:CreateTestBook(index, options)
	options = options or {}

	local titleSuffix = options.uniqueTitles and (" Vol. " .. index) or ""
	local title = getRandomElement(BOOK_TITLES) .. titleSuffix

	local numPages = options.pageCount or math.random(1, 50)
	local pages = {}
	for pageNum = 1, numPages do
		pages[pageNum] = generatePageText(pageNum, numPages, index)
	end

	local now = time and time() or (os and os.time and os.time()) or 0
	local ageInSeconds = index * 3600 -- 1 hour per book index

	return {
		title = title,
		creator = options.includeAuthors ~= false and getRandomElement(AUTHORS) or "",
		material = options.includeMaterials ~= false and getRandomElement(MATERIALS) or "",
		pages = pages,
		firstSeenAt = now - ageInSeconds,
		lastSeenAt = now - (ageInSeconds / 2),
		lastReadAt = nil,
		seenCount = math.random(1, 10),
		isFavorite = (index % 10 == 0), -- Every 10th book is favorite
		location = (options.includeLocations ~= false) and self:GenerateLocation(index) or nil,
	}
end

--- Generate a random location for a book
--- @param index number
--- @return table|nil location
function Generator:GenerateLocation(index)
	-- Define known location chains (continent > zone > subzone)
	local locationChains = {
		-- Eastern Kingdoms
		{ "Eastern Kingdoms", "Elwynn Forest", "Goldshire" },
		{ "Eastern Kingdoms", "Elwynn Forest", "Northshire Abbey" },
		{ "Eastern Kingdoms", "Elwynn Forest", "Stormwind City" },
		{ "Eastern Kingdoms", "Westfall", "Sentinel Hill" },
		{ "Eastern Kingdoms", "Duskwood", "Darkshire" },
		{ "Eastern Kingdoms", "Redridge Mountains", "Lakeshire" },
		
		-- Kalimdor
		{ "Kalimdor", "Durotar", "Orgrimmar" },
		{ "Kalimdor", "Durotar", "Razor Hill" },
		{ "Kalimdor", "The Barrens", "Crossroads" },
		{ "Kalimdor", "Mulgore", "Thunder Bluff" },
		{ "Kalimdor", "Teldrassil", "Darnassus" },
		{ "Kalimdor", "Darkshore", "Auberdine" },
		
		-- Northrend
		{ "Northrend", "Borean Tundra", "Valiance Keep" },
		{ "Northrend", "Howling Fjord", "Valgarde" },
		{ "Northrend", "Dragonblight", "Wintergarde Keep" },
		{ "Northrend", "Crystalsong Forest", "Dalaran" },
		
		-- Pandaria
		{ "Pandaria", "The Jade Forest", "Jade Temple" },
		{ "Pandaria", "Valley of the Four Winds", "Halfhill" },
		{ "Pandaria", "Kun-Lai Summit", "Temple of the White Tiger" },
	}
	
	-- Randomly assign location chains based on index
	-- 70% of books get a location, 30% have nil location (for Unknown Location)
	if (index % 10) < 7 then
		local chain = locationChains[(index % #locationChains) + 1]
		return {
			mapID = 1453 + (index % 100), -- Random map ID
			zone = chain[2], -- Zone name
			subzone = chain[3], -- Subzone name
			x = math.random(0, 100) / 100,
			y = math.random(0, 100) / 100,
			zoneChain = chain, -- Full location hierarchy
		}
	else
		-- No location (will appear in "Unknown Location")
		return nil
	end
end

--- Generate multiple test books and add them to the database
--- @param count number Number of books to generate
--- @param options table|nil Configuration options
function Generator:GenerateBooks(count, options)
	options = options or {}

	local Core = BookArchivist.Core
	local BookId = BookArchivist.BookId

	if not Core or not BookId then
		print("|cFFFF0000BookArchivist TestDataGenerator:|r Core modules not loaded!")
		return
	end

	print(string.format("|cFF00FF00Generating %d test books...|r", count))

	local startTime = debugprofilestop()
	local db = Core:GetDB()

	for i = 1, count do
		local entry = self:CreateTestBook(i, options)
		local bookId = BookId:MakeBookIdV2(entry) .. "_TEST_" .. i

		-- Add to database
		db.booksById[bookId] = entry
		Core:AppendOrder(bookId)

		-- Build search text if module exists
		if Core.BuildSearchText then
			entry.searchText = Core:BuildSearchText(entry.title, entry.pages)
		end

		-- Progress feedback every 100 books
		if i % 100 == 0 then
			print(string.format("  Generated %d/%d books (%.1f%%)", i, count, (i / count) * 100))
		end
	end

	local elapsed = debugprofilestop() - startTime

	-- Get final count to verify books were actually added
	local finalCount = db.order and #db.order or 0

	print(string.format("|cFF00FF00Test data generation complete:|r"))
	print(string.format("  Books created: %d", count))
	print(string.format("  Database now has: %d books total", finalCount))
	print(string.format("  Time elapsed: %.2f seconds", elapsed / 1000))
	print(string.format("  Avg per book: %.2f ms", elapsed / count))
	print("|cFFFFFF00Books added to database. Open UI with /ba to view them.|r")
	print("|cFF808080Tip: Use /ba stats to see database info|r")
end

--- Clear all test data (books with specific naming pattern)
--- WARNING: This will delete books! Use with caution.
function Generator:ClearTestData()
	local Core = BookArchivist.Core
	if not Core then
		print("|cFFFF0000BookArchivist TestDataGenerator:|r Core module not loaded!")
		return
	end

	local db = Core:GetDB()
	local deletedCount = 0

	-- Find and delete test books (those with titles matching our patterns)
	local toDelete = {}
	for bookId, entry in pairs(db.booksById) do
		if entry and entry.title then
			-- Check if title matches any of our test patterns
			for _, testTitle in ipairs(BOOK_TITLES) do
				if entry.title:find(testTitle, 1, true) then
					table.insert(toDelete, bookId)
					deletedCount = deletedCount + 1
					break
				end
			end
		end
	end

	-- Delete collected test books
	for _, bookId in ipairs(toDelete) do
		Core:Delete(bookId)
	end

	print(string.format("|cFFFF6B6BDeleted %d test books|r", deletedCount))
	print("|cFFFFFF00Books removed from database. Refresh UI to see changes.|r")
end

--- Get statistics about current database
function Generator:GetDatabaseStats()
	local Core = BookArchivist.Core
	if not Core then
		print("|cFFFF0000BookArchivist TestDataGenerator:|r Core module not loaded!")
		return
	end

	local db = Core:GetDB()
	local stats = {
		totalBooks = 0,
		totalPages = 0,
		withAuthors = 0,
		withLocations = 0,
		favorites = 0,
		avgPages = 0,
	}

	for bookId, entry in pairs(db.booksById) do
		if entry then
			stats.totalBooks = stats.totalBooks + 1

			if entry.pages then
				local pageCount = 0
				for _ in pairs(entry.pages) do
					pageCount = pageCount + 1
				end
				stats.totalPages = stats.totalPages + pageCount
			end

			if entry.creator and entry.creator ~= "" then
				stats.withAuthors = stats.withAuthors + 1
			end

			if entry.location then
				stats.withLocations = stats.withLocations + 1
			end

			if entry.isFavorite then
				stats.favorites = stats.favorites + 1
			end
		end
	end

	if stats.totalBooks > 0 then
		stats.avgPages = stats.totalPages / stats.totalBooks
	end

	return stats
end

--- Print database statistics
function Generator:PrintStats()
	local stats = self:GetDatabaseStats()
	if not stats then
		return
	end

	print("|cFF00FF00BookArchivist Database Statistics:|r")
	print(string.format("  Total books: %d", stats.totalBooks))
	print(string.format("  Total pages: %d", stats.totalPages))
	print(string.format("  Average pages per book: %.1f", stats.avgPages))
	print(
		string.format(
			"  Books with authors: %d (%.1f%%)",
			stats.withAuthors,
			(stats.withAuthors / stats.totalBooks) * 100
		)
	)
	print(
		string.format(
			"  Books with locations: %d (%.1f%%)",
			stats.withLocations,
			(stats.withLocations / stats.totalBooks) * 100
		)
	)
	print(string.format("  Favorite books: %d (%.1f%%)", stats.favorites, (stats.favorites / stats.totalBooks) * 100))

	-- Memory usage
	collectgarbage("collect")
	local memoryKB = collectgarbage("count")
	print(string.format("  Current memory: %.2f MB", memoryKB / 1024))
end

--- Generate preset test configurations
function Generator:GeneratePreset(preset)
	local presets = {
		small = { count = 100, uniqueTitles = true },
		medium = { count = 500, uniqueTitles = true },
		large = { count = 1000, uniqueTitles = true },
		xlarge = { count = 2500, uniqueTitles = true },
		stress = { count = 5000, uniqueTitles = true },
		minimal = { count = 50, pageCount = 5, includeAuthors = false, includeMaterials = false },
		rich = { count = 200, includeLocations = true, uniqueTitles = true },
	}

	local config = presets[preset]
	if not config then
		print("|cFFFF0000Unknown preset:|r " .. tostring(preset))
		print(
			"Available presets: small (100), medium (500), large (1000), xlarge (2500), stress (5000), minimal (50), rich (200)"
		)
		return
	end

	print(string.format("|cFF00FF00Generating preset:|r %s", preset))
	self:GenerateBooks(config.count, config)
end
