local addon = BookArchivist
local WoWUnit = rawget(_G or {}, "WoWUnit")
local tinsert = table.insert
if not addon or not WoWUnit then
	return
end

addon.UI = addon.UI or {}
local ReaderUI = addon.UI.Reader
if not ReaderUI or not ReaderUI.__ensureDeleteButton then
	return
end

local state = ReaderUI.__state or {}
ReaderUI.__state = state

local DeleteButtonGroup = WoWUnit("BookArchivist Delete Button", "PLAYER_LOGIN")

local function newFakeFrame(name)
	local frame = { __name = name }
	frame.shown = true
	frame.points = {}
	frame.frameLevel = 1
	frame.frameStrata = "MEDIUM"

	function frame:SetSize(width, height)
		self.width, self.height = width, height
	end

	function frame:ClearAllPoints()
		self.points = {}
	end

	function frame:SetPoint(...)
		tinsert(self.points, { ... })
	end

	function frame:SetFrameLevel(level)
		self.frameLevel = level
	end

	function frame:GetFrameLevel()
		return self.frameLevel
	end

	function frame:SetFrameStrata(strata)
		self.frameStrata = strata
	end

	function frame:GetFrameStrata()
		return self.frameStrata
	end

	function frame:SetToplevel(flag)
		self.toplevel = not not flag
	end

	function frame:SetParent(parent)
		self.parent = parent
	end

	function frame:GetParent()
		return self.parent
	end

	function frame:Show()
		self.shown = true
	end

	function frame:Hide()
		self.shown = false
	end

	function frame:IsShown()
		return not not self.shown
	end

	function frame:IsObjectType(typeName)
		return typeName == "Button" or typeName == "Frame"
	end

	return frame
end

local function newFakeButton()
	local button = newFakeFrame("DeleteButton")
	button.enabled = false

	function button:SetText(text)
		self.text = text
	end

	function button:SetNormalFontObject(font)
		self.font = font
	end

	function button:Disable()
		self.enabled = false
	end

	function button:Enable()
		self.enabled = true
	end

	function button:IsEnabled()
		return self.enabled
	end

	function button:SetMotionScriptsWhileDisabled()
	end

	function button:SetScript(kind, handler)
		self.scripts = self.scripts or {}
		self.scripts[kind] = handler
	end

	return button
end

local function restoreState(snapshot)
	state.deleteButton = snapshot.deleteButton
	state.readerBlock = snapshot.readerBlock
	state.uiFrame = snapshot.uiFrame
end

function DeleteButtonGroup:DeleteButtonBecomesVisibleWhenEnsured()
	local snapshot = {
		deleteButton = state.deleteButton,
		readerBlock = state.readerBlock,
		uiFrame = state.uiFrame,
	}

	local ok, err = pcall(function()
		local parent = newFakeFrame("ReaderBlock")
		parent:SetFrameLevel(4)
		parent:SetFrameStrata("LOW")

		local button = newFakeButton()
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
