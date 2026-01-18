---@diagnostic disable: undefined-global
-- BookArchivist_Migrations.lua
-- Central migration dispatcher for BookArchivistDB.

local BA = BookArchivist

local Migrations = BA.Migrations or {}
BA.Migrations = Migrations

local MIGRATIONS = {}

local function debug(msg)
	local BA = BookArchivist
	if BA and type(BA.DebugPrint) == "function" then
		BA:DebugPrint("[MIGRATIONS] " .. tostring(msg))
	end
end

-- v1: annotation-only migration. Do NOT restructure data.
function MIGRATIONS.v1(db)
	if type(db) ~= "table" then
		db = {}
	end
	debug("Applying v1 (annotate dbVersion=1)")
	db.dbVersion = 1
	return db
end

-- v2: introduce stable book IDs and indexes while freezing legacy data.
-- This migration is safe to run multiple times; it will no-op if
-- booksById already exists and dbVersion >= 2.
function MIGRATIONS.v2(db)
	if type(db) ~= "table" then
		db = {}
	end

	if type(db.dbVersion) == "number" and db.dbVersion >= 2 and type(db.booksById) == "table" then
		return db
	end

	debug("Applying v2 (booksById + legacy freeze)")

	local BookId = BA and BA.BookId or nil
	local makeBookId = BookId and BookId.MakeBookIdV2 or nil

	local legacyBooks = db.books or {}
	local legacyOrder = db.order or {}

	-- 1) Freeze legacy snapshot if not already present.
	db.legacy = db.legacy or {}
	if type(db.legacy.books) ~= "table" or type(db.legacy.order) ~= "table" then
		db.legacy.version = db.version
		db.legacy.books = legacyBooks
		db.legacy.order = legacyOrder
	end

	-- 2) Build booksById with merge semantics.
	local booksById = {}
	local keyToId = {}

	local function mergeEntry(target, source)
		if not source then
			return
		end
		if not target then
			return source
		end

		-- Counters and timestamps
		local sSeen = tonumber(source.seenCount) or 1
		local tSeen = tonumber(target.seenCount) or 0
		target.seenCount = tSeen + sSeen

		local function firstSeen(e)
			return e.firstSeenAt or e.createdAt or 0
		end

		local function lastSeen(e)
			return e.lastSeenAt or e.createdAt or 0
		end

		local fs = math.min(firstSeen(target), firstSeen(source))
		local ls = math.max(lastSeen(target), lastSeen(source))
		target.firstSeenAt = fs ~= 0 and fs or nil
		target.lastSeenAt = ls ~= 0 and ls or nil

		-- Prefer non-empty titles/metadata from either entry.
		if (not target.title or target.title == "") and (source.title and source.title ~= "") then
			target.title = source.title
		end
		if (not target.creator or target.creator == "") and (source.creator and source.creator ~= "") then
			target.creator = source.creator
		end
		if (not target.material or target.material == "") and (source.material and source.material ~= "") then
			target.material = source.material
		end

		-- Take source/location if target is missing.
		if not target.source and source.source then
			target.source = source.source
		end
		if not target.location and source.location then
			target.location = source.location
		end

		-- Merge pages, preferring non-empty text.
		target.pages = target.pages or {}
		for pageNum, text in pairs(source.pages or {}) do
			if text and text ~= "" then
				target.pages[pageNum] = text
			end
		end

		return target
	end

	for legacyKey, entry in pairs(legacyBooks) do
		if type(entry) == "table" then
			local bookId
			if makeBookId then
				bookId = makeBookId(entry)
			end
			-- Fallback to legacy key if ID generation fails for any reason.
			bookId = bookId or tostring(legacyKey)

			local existing = booksById[bookId]
			if existing then
				booksById[bookId] = mergeEntry(existing, entry)
			else
				entry.key = legacyKey
				entry.id = bookId
				booksById[bookId] = entry
			end
			keyToId[legacyKey] = bookId
		end
	end

	-- 3) Convert order to use bookId values.
	local newOrder = {}
	local seenIds = {}
	for _, legacyKey in ipairs(legacyOrder) do
		local bookId = keyToId[legacyKey]
		if bookId and not seenIds[bookId] then
			seenIds[bookId] = true
			newOrder[#newOrder + 1] = bookId
		end
	end

	-- Append any books not present in the legacy order.
	for bookId, _ in pairs(booksById) do
		if not seenIds[bookId] then
			seenIds[bookId] = true
			newOrder[#newOrder + 1] = bookId
		end
	end

	-- 4) Build objectID index (best-effort).
	db.indexes = db.indexes or {}
	db.indexes.objectToBookId = db.indexes.objectToBookId or {}
	local objectIndex = db.indexes.objectToBookId

	for bookId, entry in pairs(booksById) do
		local source = type(entry) == "table" and entry.source or nil
		local objectID = source and source.objectID or nil
		if objectID ~= nil then
			local numeric = tonumber(objectID) or objectID
			if numeric ~= nil then
				if objectIndex[numeric] == nil or objectIndex[numeric] == bookId then
					objectIndex[numeric] = bookId
				end
			end
		end
	end

	-- 5) Attach new structures and bump dbVersion.
	db.booksById = booksById
	db.order = newOrder
	db.dbVersion = 2

	-- 6) Clean up legacy v1.0.2 options
	if type(db.options) == "table" then
		db.options.debugEnabled = nil -- Legacy duplicate of 'debug'
		db.options.gridMode = nil -- Dev-only feature
		db.options.gridVisible = nil -- Dev-only feature
		db.options.ba_hidden_anchor = nil -- Dev-only feature

		-- Clean up ui.listWidth (hardcoded to 360, no UI to change it)
		if type(db.options.ui) == "table" then
			db.options.ui.listWidth = nil
		end
	end

	return db
end

-- v3: add Book Echo tracking fields (readCount, firstReadLocation, lastPageRead)
function MIGRATIONS.v3(db)
	if type(db) ~= "table" then
		db = {}
	end

	if type(db.dbVersion) == "number" and db.dbVersion >= 3 then
		return db
	end

	debug("Applying v3 (Book Echo tracking fields)")

	-- Add readCount, firstReadLocation, lastPageRead to all books
	for bookId, book in pairs(db.booksById or {}) do
		if type(book) == "table" then
			-- Initialize readCount to 0 if not present
			if book.readCount == nil then
				book.readCount = 0
			end

			-- Initialize firstReadLocation to nil if not present
			if book.firstReadLocation == nil then
				book.firstReadLocation = nil
			end

			-- Initialize lastPageRead to nil if not present
			if book.lastPageRead == nil then
				book.lastPageRead = nil
			end
		end
	end

	db.dbVersion = 3

	return db
end

local function migrate(db)
	if type(db) ~= "table" then
		db = {}
	end
	local v = tonumber(db.dbVersion) or 0
	debug("Starting migration dispatch from dbVersion=" .. tostring(v))

	if v < 1 then
		db = MIGRATIONS.v1(db)
	end

	if (tonumber(db.dbVersion) or 0) < 2 then
		db = MIGRATIONS.v2(db)
	end

	if (tonumber(db.dbVersion) or 0) < 3 then
		db = MIGRATIONS.v3(db)
	end

	debug("Finished migration dispatch at dbVersion=" .. tostring(db.dbVersion or 0))

	return db
end

function Migrations.Migrate(db)
	return migrate(db)
end

-- Expose individual migration helpers on the public table so
-- other modules (like DB init) can explicitly invoke a specific
-- version when needed (e.g., safety nets for legacy data).
Migrations.v1 = MIGRATIONS.v1
Migrations.v2 = MIGRATIONS.v2
Migrations.v3 = MIGRATIONS.v3
