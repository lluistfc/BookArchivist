local addon = BookArchivist
local Capture = addon and addon.Capture
local Core = addon and addon.Core
local Location = addon and addon.Location
local Helpers = BookArchivistTests and BookArchivistTests.Helpers
local WoWUnit = rawget(_G or {}, "WoWUnit")

if not (addon and Capture and Core and Location and Helpers and WoWUnit) then
	return
end

local CaptureSuite = WoWUnit("BookArchivist Capture", "ITEM_TEXT_READY")

local function withItemText(data, fn)
	local restores = {}
	local function addRestore(target, key, value)
		table.insert(restores, Helpers.stub(target, key, value))
	end

	addRestore(_G, "ItemTextGetTitle", function()
		return data.title
	end)
	addRestore(_G, "ItemTextGetCreator", function()
		return data.creator
	end)
	addRestore(_G, "ItemTextGetMaterial", function()
		return data.material
	end)
	addRestore(_G, "ItemTextGetText", function()
		return data.text
	end)
	addRestore(_G, "ItemTextGetItem", function()
		return data.item or data.title
	end)
	addRestore(_G, "ItemTextGetPage", function()
		return data.page or 1
	end)

	local ok, err = pcall(fn)
	for i = #restores, 1, -1 do
		restores[i]()
	end
	if not ok then
		error(err)
	end
end

function CaptureSuite:OnReadyPersistsSessionAndRefreshesUI()
	Helpers.resetSavedVariables()
	Core:EnsureDB()

	local refreshCount = 0
	local restoreRefresh = Helpers.stub(BookArchivist, "RefreshUI", function()
		refreshCount = refreshCount + 1
	end)

	local restoreBuild = Helpers.stub(Location, "BuildWorldLocation", function()
		return { zoneText = "Mock Zone", zoneChain = { "Mock" } }
	end)
	local restoreLoot = Helpers.stub(Location, "GetLootLocation", function()
		return nil
	end)

	_G.ItemTextFrame = { itemID = 9001, page = 1 }

	withItemText({
		title = "Mock Volume",
		creator = "Unknown",
		material = "Parchment",
		text = "Page body",
		item = "Fallback",
		page = 1,
	}, function()
		Capture:OnBegin()
		Capture:OnReady()
		Capture:OnClosed()
	end)

	local db = Core:GetDB()
	WoWUnit.AreEqual(1, #db.order)
	local key = db.order[1]
	local entry = db.books[key]
	WoWUnit.Exists(entry)
	if entry then
		WoWUnit.AreEqual("Mock Volume", entry.title)
		WoWUnit.AreEqual("Page body", entry.pages[1])
		WoWUnit.AreEqual("Mock Zone", entry.location.zoneText)
	end
	WoWUnit.AreEqual(1, refreshCount)

	restoreRefresh()
	restoreBuild()
	restoreLoot()
	_G.ItemTextFrame = nil
end
