---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local WoWUnit = rawget(_G or {}, "WoWUnit")
if not WoWUnit then
	return
end

BookArchivistTests = BookArchivistTests or {}
local Helpers = {}

local function deepcopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepcopy(v)
	end
	return copy
end

function Helpers.resetSavedVariables()
	BookArchivistDB = nil
end

function Helpers.snapshotTable(tbl)
	if not tbl then
		return nil
	end
	return deepcopy(tbl)
end

function Helpers.restoreTable(target, snapshot)
	if snapshot == nil then
		return
	end
	for k in pairs(target) do
		target[k] = nil
	end
	for k, v in pairs(snapshot) do
		target[k] = deepcopy(v)
	end
end

function Helpers.stub(target, key, replacement)
	target = target or {}
	local original = target[key]
	target[key] = replacement
	return function()
		target[key] = original
	end
end

function Helpers.withStub(target, key, replacement, fn)
	local restore = Helpers.stub(target, key, replacement)
	local ok, err = pcall(fn)
	restore()
	if not ok then
		error(err)
	end
end

local function attachFrameAPI(frame)
	function frame:SetSize(width, height)
		self.width, self.height = width, height
	end

	function frame:ClearAllPoints()
		self.points = {}
	end

	function frame:SetPoint(...)
		table.insert(self.points, { ... })
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

function Helpers.newFrame(name, opts)
	opts = opts or {}
	local frame = {
		__name = name or "Frame",
		shown = opts.shown ~= false,
		points = {},
		frameLevel = opts.frameLevel or 1,
		frameStrata = opts.frameStrata or "MEDIUM",
	}
	return attachFrameAPI(frame)
end

function Helpers.newButton(name, opts)
	local button = Helpers.newFrame(name or "Button", opts)
	button.enabled = opts and opts.enabled or false

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
		return not not self.enabled
	end

	function button:SetMotionScriptsWhileDisabled()
	end

	function button:SetScript(kind, handler)
		self.scripts = self.scripts or {}
		self.scripts[kind] = handler
	end

	return button
end

function Helpers.spy()
	local calls = {}
	return function(...)
		table.insert(calls, { ... })
	end, function()
		return #calls, calls
	end
end

BookArchivistTests.Helpers = Helpers
