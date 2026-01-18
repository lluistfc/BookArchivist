-- BookArchivist_Capture.lua
-- Converts ItemText events into persisted entries via the core module.

local BA = BookArchivist

local Core = BA.Core
local Location = BA.Location
local Capture = {}
BA.Capture = Capture

---@class BookArchivistCaptureSession
---@field title string
---@field creator string
---@field material string
---@field pages table<number, string>
---@field source table
---@field firstPageSeen number|nil
---@field startedAt number
---@field itemID number|nil
---@field sourceKind string|nil
---@field location table|nil
---@field seenPages table<number, boolean>|nil
---@field caching boolean|nil
---@field cachingComplete boolean|nil
---@field returningToFirst boolean|nil
local session ---@type BookArchivistCaptureSession|nil

local function getGlobal(name)
	if type(_G) ~= "table" then
		return nil
	end
	return rawget(_G, name)
end

local function now()
	if Core and Core.Now then
		return Core:Now()
	end
	local osTime = type(os) == "table" and os.time
	return osTime and osTime() or 0
end

local function trim(s)
	if not s then
		return ""
	end
	s = tostring(s)
	return s:gsub("^%s+", ""):gsub("%s+$", "")
end

-- All captures are treated as book item text; heuristics removed for simplicity

local function parseGuid(guid)
	if type(guid) ~= "string" then
		return nil
	end
	local objectType = guid:match("^(%a+)%-")
	if objectType == "GameObject" then
		local id = guid:match("GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)")
		return objectType, id and tonumber(id) or nil
	elseif objectType == "Item" then
		local id = guid:match("Item%-%d+%-%d+%-%d+%-%d+%-(%d+)")
		return objectType, id and tonumber(id) or nil
	elseif objectType == "Creature" or objectType == "Vehicle" then
		local id = guid:match("%a+%-%d+%-%d+%-%d+%-(%d+)%-%x+")
		return objectType, id and tonumber(id) or nil
	end
	return objectType
end

local function currentSourceInfo()
	local src = { kind = "itemtext" }

	local frame = getGlobal("ItemTextFrame")
	if frame then
		if frame.itemID then
			src.itemID = frame.itemID
		end
		if type(frame.page) == "number" then
			src.page = frame.page
		end
	end

	local UnitGUIDFn = getGlobal("UnitGUID")
	local guid = UnitGUIDFn and UnitGUIDFn("npc")
	if guid then
		local objectType, objectID = parseGuid(guid)
		src.guid = guid
		src.objectType = objectType
		src.objectID = objectID
		if objectType == "GameObject" then
			src.kind = "world"
		elseif objectType == "Item" then
			src.kind = "inventory"
		end
	end

	return src
end

local function resolvePageNumber()
	local getPage = getGlobal("ItemTextGetPage")
	if getPage then
		local page = getPage()
		if type(page) == "number" and page >= 1 then
			return page
		end
	end
	return 1
end

local function ensureSessionLocation(target)
	if not target or target.location then
		return
	end

	if target.itemID and Location and Location.GetLootLocation then
		target.location = Location:GetLootLocation(target.itemID)
	end

	if (not target.location) and Location and Location.BuildWorldLocation then
		local loc = Location:BuildWorldLocation()
		if loc then
			if target.itemID then
				loc.context = "loot"
				loc.isFallback = true
			end
			target.location = loc
		end
	end
end

function Capture:OnBegin()
	local frame = getGlobal("ItemTextFrame")
	local itemID = frame and frame.itemID or nil
	if type(itemID) == "string" then
		itemID = tonumber(itemID)
	end
	session = {
		title = "",
		creator = "",
		material = "",
		pages = {},
		source = currentSourceInfo(),
		firstPageSeen = nil,
		startedAt = now(),
		itemID = itemID,
		sourceKind = itemID and "inventory" or "world",
		location = nil,
		seenPages = {},
	}

	if not itemID then
		ensureSessionLocation(session)
	end
end

function Capture:OnReady()
	if not session then
		self:OnBegin()
	end

	local activeSession = session
	if not activeSession then
		return
	end

	local pageNum = resolvePageNumber()
	local ItemTextGetTitle = getGlobal("ItemTextGetTitle")
	local ItemTextGetCreator = getGlobal("ItemTextGetCreator")
	local ItemTextGetMaterial = getGlobal("ItemTextGetMaterial")
	local ItemTextGetText = getGlobal("ItemTextGetText")
	local ItemTextGetItem = getGlobal("ItemTextGetItem")

	local title = ItemTextGetTitle and ItemTextGetTitle() or ""
	if (not title or title == "") and ItemTextGetItem then
		title = ItemTextGetItem()
	end
	local creator = ItemTextGetCreator and ItemTextGetCreator() or ""
	local material = ItemTextGetMaterial and ItemTextGetMaterial() or ""
	local text = ItemTextGetText and ItemTextGetText() or ""

	activeSession.title = trim(title)
	activeSession.creator = trim(creator)
	activeSession.material = trim(material)

	if not activeSession.firstPageSeen then
		activeSession.firstPageSeen = pageNum
	end

	activeSession.pages = activeSession.pages or {}
	activeSession.pages[pageNum] = trim(text)
	activeSession.seenPages[pageNum] = true

	ensureSessionLocation(activeSession)

	-- Persist incrementally so we don't lose data if the close event is skipped by other UIs.
	if Core and Core.PersistSession then
		local persisted = Core:PersistSession(activeSession)
		if persisted and activeSession.itemID and Core.IndexItemForBook then
			Core:IndexItemForBook(activeSession.itemID, persisted.id or persisted.key)
		end
		local src = activeSession.source or {}
		if persisted and src.objectID and src.objectType == "GameObject" and Core.IndexObjectForBook then
			Core:IndexObjectForBook(src.objectID, persisted.id or persisted.key)
		end
		-- Don't refresh UI on every page read - wait for OnClosed to refresh once
	end
end

function Capture:OnClosed()
	if not session then
		return
	end
	ensureSessionLocation(session)
	if Core and Core.PersistSession then
		local persisted = Core:PersistSession(session)
		if persisted and session.itemID and Core.IndexItemForBook then
			Core:IndexItemForBook(session.itemID, persisted.id or persisted.key)
		end
		local src = session.source or {}
		if persisted and src.objectID and src.objectType == "GameObject" and Core.IndexObjectForBook then
			Core:IndexObjectForBook(src.objectID, persisted.id or persisted.key)
		end
		-- Refresh UI to update location data (including backfilled locations)
		if BookArchivist and BookArchivist.RefreshUI then
			BookArchivist.RefreshUI()
		end
	end
	session = nil
end
