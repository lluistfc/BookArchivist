local addon = BookArchivist
local UI = addon and addon.UI
local ListUI = UI and UI.List
local Helpers = BookArchivistTests and BookArchivistTests.Helpers
local WoWUnit = rawget(_G or {}, "WoWUnit")

if not (ListUI and Helpers and WoWUnit) then
	return
end

local ListSuite = WoWUnit("BookArchivist List UI", "PLAYER_LOGIN")

local function withState(fn)
	local state = ListUI.__state
	local snapshot = state and Helpers.snapshotTable(state)
	local ok, err = pcall(fn)
	if state and snapshot then
		Helpers.restoreTable(state, snapshot)
	end
	if not ok then
		error(err)
	end
end

function ListSuite:InitHonorsCustomListModes()
	withState(function()
		local messages = 0
		ListUI:Init({
			debugPrint = function()
				messages = messages + 1
			end,
			listModes = {
				BOOKS = "b",
				LOCATIONS = "l",
			},
		})
		ListUI:DebugPrint("ping")
		WoWUnit.AreEqual("b", ListUI:GetListModes().BOOKS)
		WoWUnit.AreEqual("l", ListUI:GetListModes().LOCATIONS)
		WoWUnit.AreEqual(1, messages)
	end)
end

function ListSuite:SetFrameCachesWidgets()
	withState(function()
		ListUI:Init()
		local widget = Helpers.newFrame("SearchBox")
		ListUI:SetFrame("searchBox", widget)
		WoWUnit.AreEqual(widget, ListUI:GetFrame("searchBox"))
	end)
end

function ListSuite:SafeCreateFrameUsesContext()
	withState(function()
		local created = {}
		ListUI:SetCallbacks({
			safeCreateFrame = function(_, frameType, name)
				created[#created + 1] = { frameType, name }
				return { __created = true }
			end,
		})

		local frame = ListUI:SafeCreateFrame("Frame", "TestFrame", nil)
		WoWUnit.IsTrue(frame.__created)
		WoWUnit.AreEqual(1, #created)
		WoWUnit.AreEqual("Frame", created[1][1])
	end)
end
