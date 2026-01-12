---@diagnostic disable: undefined-global
-- BookArchivist_Location.lua
-- Tracks player location context and loot provenance for BookArchivist entries.

BookArchivist = BookArchivist or {}

local Location = {}
BookArchivist.Location = Location

local recentLoot = {}
local guidNameCache = {}
local MAX_LOOT_AGE = 60 * 60 * 6 -- six hours

local function getGlobal(name)
	if type(_G) ~= "table" then
		return nil
	end
	return rawget(_G, name)
end

local function nowSeconds()
	local GetTime = getGlobal("GetTime")
	if GetTime then
		return GetTime()
	end
	local osTime = os and os.time
	return osTime and os.time() or 0
end

local function copyArray(arr)
	if not arr then
		return nil
	end
	local out = {}
	for i = 1, #arr do
		out[i] = arr[i]
	end
	return out
end

local function cloneLocation(data)
	if not data then
		return nil
	end
	local copy = {}
	for k, v in pairs(data) do
		if k == "zoneChain" then
			copy.zoneChain = copyArray(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function buildZoneData()
	local chain = {}
	local mapID
	local C_Map = getGlobal("C_Map")
	if C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo then
		local visited = {}
		local map = C_Map.GetBestMapForUnit("player")
		mapID = map
		while map and not visited[map] do
			visited[map] = true
			local info = C_Map.GetMapInfo(map)
			if not info or not info.name then
				break
			end
			local mapType = info.mapType
			local cosmic = Enum and Enum.UIMapType and Enum.UIMapType.Cosmic
			if not cosmic or mapType ~= cosmic then
				table.insert(chain, 1, info.name)
			end
			map = info.parentMapID
		end
	end

	if #chain == 0 then
		local GetRealZoneText = getGlobal("GetRealZoneText")
		local GetSubZoneText = getGlobal("GetSubZoneText")
		local zone = GetRealZoneText and GetRealZoneText() or ""
		local subZone = GetSubZoneText and GetSubZoneText() or ""
		if zone ~= "" then
			table.insert(chain, zone)
		end
		if subZone ~= "" and subZone ~= zone then
			table.insert(chain, subZone)
		end
	end

	if #chain == 0 then
		local L = BookArchivist and BookArchivist.L or {}
		local unknown = (L and L["LOCATION_UNKNOWN_ZONE"]) or "Unknown Zone"
		chain = { unknown }
	end

	local zoneText = table.concat(chain, " > ")
	return {
		zoneChain = chain,
		zoneText = zoneText,
		mapID = mapID,
	}
end

local function extractItemID(link)
	if not link then
		return nil
	end
	local itemID = link:match("item:(%d+)")
	return itemID and tonumber(itemID) or nil
end

local function pruneLootMemory()
	local now = nowSeconds()
	for itemID, data in pairs(recentLoot) do
		if not data.recordedAt or (now - data.recordedAt) > MAX_LOOT_AGE then
			recentLoot[itemID] = nil
		end
	end
end

local function fetchNameFromTooltip(guid)
	local TooltipInfo = getGlobal("C_TooltipInfo")
	if not TooltipInfo or not TooltipInfo.GetHyperlink or not guid then
		return nil
	end
	local ok, tooltip = pcall(TooltipInfo.GetHyperlink, "unit:" .. guid)
	if not ok or not tooltip or not tooltip.lines then
		return nil
	end
	local line = tooltip.lines[1]
	if line and line.leftText and line.leftText ~= "" then
		return line.leftText
	end
	return nil
end

local function resolveGuidName(guid)
	if not guid then
		return nil
	end
	if guidNameCache[guid] then
		return guidNameCache[guid]
	end
	local name = fetchNameFromTooltip(guid)
	if name and name ~= "" then
		guidNameCache[guid] = name
		return name
	end
	return nil
end

function Location:BuildWorldLocation()
	local zoneData = buildZoneData()
	return {
		context = "world",
		zoneChain = copyArray(zoneData.zoneChain),
		zoneText = zoneData.zoneText,
		mapID = zoneData.mapID,
		capturedAt = nowSeconds(),
	}
end

function Location:GetLootLocation(itemID)
	itemID = type(itemID) == "number" and itemID or tonumber(itemID)
	if not itemID then
		return nil
	end
	pruneLootMemory()
	local entry = recentLoot[itemID]
	if not entry then
		return nil
	end
	if not entry.recordedAt or (nowSeconds() - entry.recordedAt) > MAX_LOOT_AGE * 4 then
		return nil
	end
	return cloneLocation(entry)
end
