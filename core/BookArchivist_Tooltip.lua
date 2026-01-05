---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_Tooltip.lua
-- Lightweight GameTooltip integration to show whether a readable item
-- has its text archived for the current character.

BookArchivist = BookArchivist or {}

local Tooltip = BookArchivist.Tooltip or {}
BookArchivist.Tooltip = Tooltip

local function getDB()
	local Core = BookArchivist.Core
	if Core and Core.GetDB then
		return Core:GetDB()
	end
	return rawget(_G or {}, "BookArchivistDB") or {}
end

local function isTooltipEnabled(db)
	db = db or getDB()
	local opts = db.options or {}
	local tooltipOpts = opts.tooltip
	if tooltipOpts == nil then
		return true
	end
	if type(tooltipOpts) == "table" and tooltipOpts.enabled == false then
		return false
	end
	if type(tooltipOpts) == "boolean" then
		return tooltipOpts and true or false
	end
	return true
end

local function extractItemID(link)
	if type(link) ~= "string" then
		return nil
	end
	local id = link:match("item:(%d+)")
	if not id then
		return nil
	end
	return tonumber(id)
end

local function normalizeTitleKey(title)
	if not title then
		return ""
	end
	local s = tostring(title)
	s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	s = s:lower()
	s = s:gsub("%s+", " ")
	return s
end

local function isTitleArchived(title)
	local key = normalizeTitleKey(title)
	if key == "" then
		return false
	end
	local db = getDB()
	if not db or type(db.indexes) ~= "table" then
		return false
	end
	local map = db.indexes.titleToBookIds
	if type(map) ~= "table" then
		return false
	end
	local set = map[key]
	if not set then
		return false
	end
	local books = db.booksById or {}
	for bookId in pairs(set) do
		if books[bookId] then
			return true
		end
	end
	return false
end

local function getTooltipTitle(tooltip)
	if not tooltip or not tooltip.GetName then
		return nil
	end
	local name = tooltip:GetName()
	if not name then
		return nil
	end
	local region = _G and _G[name .. "TextLeft1"] or nil
	if region and region.GetText then
		return region:GetText()
	end
	return nil
end

local function isItemArchived(itemID)
	if not itemID then
		return false
	end
	local db = getDB()
	if not db or type(db.indexes) ~= "table" then
		return false
	end
	local map = db.indexes.itemToBookIds
	if type(map) ~= "table" then
		return false
	end
	local set = map[itemID]
	if not set then
		return false
	end
	local books = db.booksById or {}
	for bookId in pairs(set) do
		if books[bookId] then
			return true
		end
	end
	return false
end

local function isObjectArchived(objectID)
	if not objectID then
		return false
	end
	local db = getDB()
	if not db or type(db.indexes) ~= "table" then
		return false
	end
	local index = db.indexes.objectToBookId
	if type(index) ~= "table" then
		return false
	end
	local id = tonumber(objectID) or objectID
	if not id then
		return false
	end
	local bookId = index[id]
	if not bookId then
		return false
	end
	local books = db.booksById or {}
	return books[bookId] ~= nil
end

local function handleTooltipForItem(tooltip, itemID)
	if not tooltip or not tooltip.AddLine then
		return
	end
	local db = getDB()
	if not isTooltipEnabled(db) then
		return
	end
	if not itemID and tooltip.GetItem then
		local _, link = tooltip:GetItem()
		if link then
			itemID = extractItemID(link)
		end
	end
	if not itemID then
		return
	end
	if not isItemArchived(itemID) then
		return
	end
	local L = BookArchivist and BookArchivist.L or {}
	local label = (L and L["TOOLTIP_ARCHIVED"]) or "Book Archivist: Archived"
	tooltip:AddLine(label)
end

local function handleTooltipForObject(tooltip, objectID)
	if not tooltip or not tooltip.AddLine then
		return
	end
	local db = getDB()
	if not isTooltipEnabled(db) then
		return
	end
	local title = getTooltipTitle(tooltip)
	if objectID and isObjectArchived(objectID) then
		local L = BookArchivist and BookArchivist.L or {}
		local label = (L and L["TOOLTIP_ARCHIVED"]) or "Book Archivist: Archived"
		tooltip:AddLine(label)
		return
	end
	if title and isTitleArchived(title) then
		local L = BookArchivist and BookArchivist.L or {}
		local label = (L and L["TOOLTIP_ARCHIVED"]) or "Book Archivist: Archived"
		tooltip:AddLine(label)
		return
	end
end

local function onTooltipSetItem(tooltip)
	handleTooltipForItem(tooltip, nil)
end

function Tooltip:Initialize()
	if Tooltip._initialized then
		return
	end
	local hooked = false
	local tooltip = _G and _G.GameTooltip
	if tooltip and tooltip.HookScript then
		local canHook = true
		if tooltip.HasScript then
			canHook = tooltip:HasScript("OnTooltipSetItem") and true or false
		end
		if canHook then
			local ok = pcall(tooltip.HookScript, tooltip, "OnTooltipSetItem", onTooltipSetItem)
			if ok then
				hooked = true
			end
		end
	end

	if _G then
		local TDP = _G.TooltipDataProcessor
		local EnumTable = _G.Enum
		if TDP and TDP.AddTooltipPostCall and EnumTable and EnumTable.TooltipDataType then
			if EnumTable.TooltipDataType.Item then
				TDP.AddTooltipPostCall(EnumTable.TooltipDataType.Item, function(tooltipFrame, data)
					local itemID = data and data.id or nil
					handleTooltipForItem(tooltipFrame, itemID)
				end)
				hooked = true
			end
			if EnumTable.TooltipDataType.Object then
				TDP.AddTooltipPostCall(EnumTable.TooltipDataType.Object, function(tooltipFrame, data)
					local objectID = data and data.id or nil
					handleTooltipForObject(tooltipFrame, objectID)
				end)
				hooked = true
			end
		end
	end

	if hooked then
		Tooltip._initialized = true
	end
end
