---@diagnostic disable: undefined-global, undefined-field
local BA = BookArchivist
BA.UI = BA.UI or {}

local ReaderUI = BA.UI.Reader or {}
BA.UI.Reader = ReaderUI

--
-- Static atlas data for Legion artifact book artwork. This is copied
-- from DialogueUI's BookUI_Atlas so that we can crop the large
-- 512x256 textures down to the visible sword/staff area without
-- depending on any external addon at runtime.
--
local ArtifactBookAtlas = (function()
	local atlas = {}
	local WIDTH, HEIGHT = 512, 256
	local PREFIX = "interface\\pictures\\artifactbook-"
	local Info = {
		["warrior-scaleoftheearthwarder"] = { 0, 178 },
		["warrior-stromkar"] = { 24, 104 },
		["warrior-warswordsofthevalarjar"] = { 12, 140 },

		["paladin-ashbringer"] = { 18, 112 },
		["paladin-silverhand"] = { 0, 138 },
		["paladin-truthguard"] = { 0, 174 },

		["hunter-talonclaw"] = { 0, 118 },
		["hunter-thasdorah"] = { 0, 118 },
		["hunter-titanstrike"] = { 24, 104 },

		["rogue-dreadblades"] = { 0, 134 },
		["rogue-fangsofthedevourer"] = { 0, 106 },
		["rogue-kingslayers"] = { 14, 128 },

		["priest-lightswrath"] = { 24, 130 },
		["priest-tuure"] = { 24, 130 },
		["priest-xalatath"] = { 0, 140 },

		["deathknight-apocalypse"] = { 0, 128 },
		["deathknight-bladesofthefallenprince"] = { 36, 106 },
		["deathknight-mawofthedamned"] = { 0, 148 },

		["shaman-doomhammer"] = { 0, 120 },
		["shaman-fistofraden"] = { 4, 138 },
		["shaman-sharasdal"] = { 6, 112 },

		["mage-aluneth"] = { 0, 126 },
		["mage-ebonchill"] = { 12, 78 },
		["mage-felomelorn"] = { 10, 78 },

		["warlock-scepterofsargeras"] = { 0, 140 },
		["warlock-skullofthemanari"] = { 0, 162 },
		["warlock-ulthalesh"] = { 0, 132 },

		["monk-fists"] = { 8, 134 },
		["monk-fuzan"] = { 0, 150 },
		["monk-sheilun"] = { 0, 114 },

		["druid-ghanirthemothertree"] = { 0, 120 },
		["druid-scytheofelune"] = { 0, 160 },
		["druid-theclawsofursoc"] = { 8, 134 },
		["druid-thefangsofashamane"] = { 8, 136 },

		["demonhunter-thealdrachiwarblades"] = { 0, 140 },
		["demonhunter-twinbladesofthedeceiver"] = { 0, 134 },
	}

	for name, bounds in pairs(Info) do
		local topPx, bottomPx = bounds[1], bounds[2]
		local ratio = (bottomPx - topPx) / WIDTH
		local left = 0 / WIDTH
		local right = WIDTH / WIDTH
		local top = topPx / HEIGHT
		local bottom = bottomPx / HEIGHT
		atlas[PREFIX .. name] = { ratio, left, right, top, bottom }
	end

	return atlas
end)()

function ReaderUI.GetArtifactBookTexInfo(path)
	if not path or path == "" then
		return nil
	end
	return ArtifactBookAtlas[path:lower()]
end
