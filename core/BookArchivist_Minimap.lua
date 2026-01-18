---@diagnostic disable: undefined-global
-- BookArchivist_Minimap.lua
-- Minimap button integration using LibDBIcon

local ADDON_NAME = ...

local BA = BookArchivist

local MinimapModule = {}
BA.Minimap = MinimapModule

local LibStub = _G.LibStub
local L = BA.L or {}

-- LibDataBroker object
local ldb = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local icon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)

local dataObject

function MinimapModule:Initialize()
	BookArchivist:DebugPrint("[Minimap] Initialize called, ldb:", ldb ~= nil, "icon:", icon ~= nil)
	if not ldb or not icon then
		BookArchivist:DebugPrint("[Minimap] LibDBIcon not available")
		return false
	end

	if self.initialized then
		return true
	end

	-- Create LibDataBroker data object
	dataObject = ldb:NewDataObject("BookArchivist", {
		type = "launcher",
		icon = "Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png",
		OnClick = function(_, button)
			if button == "LeftButton" then
				if BookArchivist.ToggleUI then
					BookArchivist.ToggleUI()
				end
			elseif button == "RightButton" then
				if BookArchivist.OpenOptionsPanel then
					BookArchivist:OpenOptionsPanel()
				end
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then
				return
			end
			tooltip:SetText((L["ADDON_TITLE"]) or "Book Archivist", 1, 0.82, 0)
			tooltip:AddLine((L["MINIMAP_TIP_LEFT"]) or "Left-click: Open library", 0.9, 0.9, 0.9)
			tooltip:AddLine((L["MINIMAP_TIP_RIGHT"]) or "Right-click: Open options", 0.9, 0.9, 0.9)
			tooltip:AddLine((L["MINIMAP_TIP_DRAG"]) or "Drag: Move button", 0.9, 0.9, 0.9)
		end,
	})

	-- Get or create minimap settings
	local db = BookArchivist:GetDB()
	if not db.minimap then
		db.minimap = { hide = false }
	end

	-- Register with LibDBIcon
	icon:Register("BookArchivist", dataObject, db.minimap)

	self.initialized = true
	BookArchivist:DebugPrint("[Minimap] Initialized with LibDBIcon")
	return true
end

function MinimapModule:Show()
	if icon and dataObject then
		icon:Show("BookArchivist")
	end
end

function MinimapModule:Hide()
	if icon and dataObject then
		icon:Hide("BookArchivist")
	end
end

function MinimapModule:IsShown()
	if icon and dataObject then
		return not icon:IsHidden("BookArchivist")
	end
	return false
end

function MinimapModule:GetButtonOptions()
	local db = BookArchivist:GetDB()
	return db and db.minimap or { hide = false }
end
