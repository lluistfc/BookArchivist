local addon = BookArchivist
local UI = addon and addon.UI
local ReaderUI = UI and UI.Reader
local Helpers = BookArchivistTests and BookArchivistTests.Helpers
local WoWUnit = rawget(_G or {}, "WoWUnit")

if not (ReaderUI and Helpers and WoWUnit) then
	return
end

local state = ReaderUI.__state or {}
ReaderUI.__state = state

local ReaderSuite = WoWUnit("BookArchivist Reader UI", "PLAYER_LOGIN")

local function snapshotState()
	return {
		deleteButton = state.deleteButton,
		readerBlock = state.readerBlock,
		uiFrame = state.uiFrame,
	}
end

local function restoreState(snapshot)
	state.deleteButton = snapshot.deleteButton
	state.readerBlock = snapshot.readerBlock
	state.uiFrame = snapshot.uiFrame
end

function ReaderSuite:EnsureDeleteButtonShowsWidget()
	local snapshot = snapshotState()
	local ok, err = pcall(function()
		local parent = Helpers.newFrame("ReaderBlock", { frameLevel = 4, frameStrata = "LOW" })
		local button = Helpers.newButton("DeleteButton")
		button:Hide()
		button:SetParent(nil)

		state.readerBlock = nil
		state.uiFrame = parent
		state.deleteButton = button

		local ensureDeleteButton = ReaderUI.__ensureDeleteButton
		WoWUnit.Exists(ensureDeleteButton)
		local result = ensureDeleteButton(parent)

		WoWUnit.AreEqual(button, result)
		WoWUnit.IsTrue(button:IsShown())
		WoWUnit.AreEqual(parent, button:GetParent())
		WoWUnit.AreEqual(true, button.toplevel)
		WoWUnit.AreEqual(math.min(parent:GetFrameLevel() + 25, 128), button:GetFrameLevel())
		WoWUnit.AreEqual(parent:GetFrameStrata(), button:GetFrameStrata())
	end)
	restoreState(snapshot)
	if not ok then
		error(err)
	end
end

function ReaderSuite:DisableDeleteButtonDisablesButton()
	local snapshot = snapshotState()
	local ok, err = pcall(function()
		local button = Helpers.newButton("DeleteButton", { enabled = true })
		state.deleteButton = button
		ReaderUI:DisableDeleteButton()
		WoWUnit.IsTrue(button:IsEnabled() == false)
	end)
	restoreState(snapshot)
	if not ok then
		error(err)
	end
end
