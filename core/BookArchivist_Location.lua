---@diagnostic disable: undefined-global
-- BookArchivist_Location.lua
-- Tracks player location context and loot provenance for BookArchivist entries.

local BA = BookArchivist

local Location = {}
BA.Location = Location

local guidNameCache = {}

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
		local L = BA and BA.L or {}
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

-- Get player map position (x, y coordinates) for the current map
-- Returns nil if position cannot be determined (e.g., in instances)
local function getPlayerPosition()
	local C_Map = getGlobal("C_Map")
	if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then
		return nil, nil
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		return nil, nil
	end
	local position = C_Map.GetPlayerMapPosition(mapID, "player")
	if not position then
		return nil, nil
	end
	-- GetXY returns normalized coordinates (0-1 range)
	local x, y = position:GetXY()
	if x and y and (x > 0 or y > 0) then
		return x, y
	end
	return nil, nil
end

function Location:BuildWorldLocation()
	local zoneData = buildZoneData()
	local posX, posY = getPlayerPosition()
	return {
		context = "world",
		zoneChain = copyArray(zoneData.zoneChain),
		zoneText = zoneData.zoneText,
		mapID = zoneData.mapID,
		posX = posX,
		posY = posY,
		capturedAt = nowSeconds(),
	}
end

-- Loot location tracking is not implemented.
-- Inventory items don't have discoverable coordinates.
-- The tooltip directs users to Wowhead to find item sources.
function Location:GetLootLocation(itemID)
	return nil
end
