local addon = BookArchivist
local Location = addon and addon.Location
local Helpers = BookArchivistTests and BookArchivistTests.Helpers
local WoWUnit = rawget(_G or {}, "WoWUnit")

if not (Location and Helpers and WoWUnit) then
	return
end

local LocationSuite = WoWUnit("BookArchivist Location", "PLAYER_LOGIN")

function LocationSuite:FormatZoneTextHandlesEmpty()
	WoWUnit.AreEqual("Unknown Zone", Location:FormatZoneText(nil))
	WoWUnit.AreEqual("Unknown Zone", Location:FormatZoneText({}))
	WoWUnit.AreEqual("Stormwind", Location:FormatZoneText({ "Stormwind" }))
end

function LocationSuite:BuildWorldLocationFallsBackToZoneText()
	local originalCMap = rawget(_G, "C_Map")
	_G.C_Map = nil

	local restoreZone = Helpers.stub(_G, "GetRealZoneText", function()
		return "Stormwind City"
	end)
	local restoreSubZone = Helpers.stub(_G, "GetSubZoneText", function()
		return "Trade District"
	end)

	local loc = Location:BuildWorldLocation()
	WoWUnit.Exists(loc)
	if loc then
		WoWUnit.AreEqual("Stormwind City > Trade District", loc.zoneText)
		WoWUnit.AreEqual("world", loc.context)
	end

	restoreZone()
	restoreSubZone()
	_G.C_Map = originalCMap
end
