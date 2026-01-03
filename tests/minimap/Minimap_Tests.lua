local addon = BookArchivist
local MinimapModule = addon and addon.Minimap
local Core = addon and addon.Core
local WoWUnit = rawget(_G or {}, "WoWUnit")

if not (MinimapModule and Core and WoWUnit) then
	return
end

local MinimapSuite = WoWUnit("BookArchivist Minimap", "PLAYER_LOGIN")

function MinimapSuite:AngleNormalizationWrapsValues()
	local opts = Core:GetMinimapButtonOptions()
	MinimapModule:SetAngle(725)
	WoWUnit.AreEqual(5, MinimapModule:GetAngle())
	WoWUnit.AreEqual(opts.angle, MinimapModule:GetAngle())
end

function MinimapSuite:RegisterAndClearButton()
	local fakeButton = { id = "button" }
	MinimapModule:RegisterButton(fakeButton)
	WoWUnit.AreEqual(fakeButton, MinimapModule:GetButton())
	MinimapModule:ClearButton()
	WoWUnit.IsNil(MinimapModule:GetButton())
end
