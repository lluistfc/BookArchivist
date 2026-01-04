---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = BookArchivist.UI.Reader or {}
BookArchivist.UI.Reader = ReaderUI

local Metrics = BookArchivist.UI.Metrics or {
	BTN_H = 22,
	BTN_W = 90,
}

local rememberWidget = ReaderUI.__rememberWidget
local getAddon = ReaderUI.__getAddon
local safeCreateFrame = ReaderUI.__safeCreateFrame
local getSelectedKey = ReaderUI.__getSelectedKey
local setSelectedKey = ReaderUI.__setSelectedKey
local chatMessage = ReaderUI.__chatMessage
local state = ReaderUI.__state or {}
ReaderUI.__state = state

StaticPopupDialogs = StaticPopupDialogs or {}
if not StaticPopupDialogs.BOOKARCHIVIST_CONFIRM_DELETE then
	StaticPopupDialogs.BOOKARCHIVIST_CONFIRM_DELETE = {
		text = "Delete '%s'? This cannot be undone.",
		button1 = YES,
		button2 = NO,
		OnAccept = function(_, data)
			if data and data.onAccept then
				data.onAccept()
			end
		end,
		hideOnEscape = true,
		whileDead = true,
		timeout = 0,
		preferredIndex = 3,
	}
end

local tableUnpack = table and table.unpack or nil
---@diagnostic disable-next-line: deprecated
local fallbackUnpack = type(_G) == "table" and (_G.unpack or _G.table and _G.table.unpack) or nil

local function deleteDebug(...)
	local args = { ... }
	if #args == 0 then
		return
	end
	table.insert(args, 1, "[BookArchivist][DeleteBtn]")
	if tableUnpack then
		BookArchivist:DebugPrint(tableUnpack(args))
	elseif fallbackUnpack then
		BookArchivist:DebugPrint(fallbackUnpack(args))
	else
		BookArchivist:DebugPrint(table.concat(args, " "))
	end
end

local function describeFrame(frame)
	if not frame then
		return "<nil>"
	end
	local ok, name
	if type(frame.GetName) == "function" then
		ok, name = pcall(frame.GetName, frame)
		if ok and name and name ~= "" then
			return name
		end
	end
	if type(frame.GetDebugName) == "function" then
		ok, name = pcall(frame.GetDebugName, frame)
		if ok and name and name ~= "" then
			return name
		end
	end
	return tostring(frame)
end

local function configureDeleteButton(button)
	if not button then
		return
	end
	button:SetSize(Metrics.BTN_W + 20, Metrics.BTN_H)
	button:SetText("Delete")
	button:SetNormalFontObject("GameFontNormal")
	button:Disable()
	button:SetMotionScriptsWhileDisabled(true)
	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self:IsEnabled() then
			GameTooltip:SetText("Delete this book", 1, 1, 1)
			GameTooltip:AddLine("This will permanently remove the book from your archive.", 1, 0.82, 0, true)
		else
			GameTooltip:SetText("Select a saved book", 1, 0.9, 0)
			GameTooltip:AddLine("Choose a book from the list to enable deletion.", 0.9, 0.9, 0.9, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnClick", function()
		local addon = getAddon and getAddon()
		if not addon then
			return
		end
		local key = getSelectedKey and getSelectedKey()
		if key then
			local db = addon.GetDB and addon:GetDB()
			local entry = db and db.books and db.books[key]
			local title = entry and entry.title or key
			if StaticPopup_Show then
				StaticPopup_Show("BOOKARCHIVIST_CONFIRM_DELETE", title, nil, {
					onAccept = function()
						addon:Delete(key)
						if setSelectedKey then
							setSelectedKey(nil)
						end
						if ReaderUI.RenderSelected then
							ReaderUI:RenderSelected()
						end
						if chatMessage then
							chatMessage("|cFFFF0000Book deleted from archive.|r")
						end
					end,
				})
			else
				addon:Delete(key)
				if setSelectedKey then
					setSelectedKey(nil)
				end
				if ReaderUI.RenderSelected then
					ReaderUI:RenderSelected()
				end
				if chatMessage then
					chatMessage("|cFFFF0000Book deleted from archive.|r")
				end
			end
		end
	end)
end

local function buildDeleteButton(parent)
	if not parent then
		deleteDebug("buildDeleteButton: parent missing; abort")
		return nil
	end

	deleteDebug("buildDeleteButton: starting", describeFrame(parent))

	local button
	if safeCreateFrame then
		deleteDebug("buildDeleteButton: attempting safeCreateFrame with named button")
		button = safeCreateFrame("Button", "BookArchivistDeleteButton", parent, "UIPanelButtonTemplate")
		if not button then
			deleteDebug("buildDeleteButton: named creation failed, retrying anonymous")
			button = safeCreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		end
	end

	if not button and CreateFrame then
		deleteDebug("buildDeleteButton: fallback to CreateFrame")
		local ok, created = pcall(CreateFrame, "Button", nil, parent, "UIPanelButtonTemplate")
		if ok then
			button = created
		else
			deleteDebug("buildDeleteButton: CreateFrame pcall failed", tostring(created))
		end
	end

	if button then
		deleteDebug("buildDeleteButton: success", describeFrame(button))
	else
		deleteDebug("buildDeleteButton: failed to create button (returning nil)")
	end

	return button
end

local function anchorDeleteButton(button, parent)
	if not button or not parent then
		return
	end
	button:SetHeight(Metrics.BTN_H)
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
	local levelSource = (parent.GetFrameLevel and parent:GetFrameLevel()) or 0
	button:SetFrameLevel(math.min(levelSource + 25, 128))
	local strataSource
	if state.uiFrame and state.uiFrame.GetFrameStrata then
		strataSource = state.uiFrame:GetFrameStrata()
	end
	if not strataSource and parent.GetFrameStrata then
		strataSource = parent:GetFrameStrata()
	end
	button:SetFrameStrata(strataSource or "MEDIUM")
	button:SetToplevel(true)
end

local function ensureDeleteButton(parent)
	parent = parent or state.readerBlock or state.uiFrame
	if not parent then
		deleteDebug("ensureDeleteButton: parent missing")
		return nil
	end

	local button = state.deleteButton
	if not button or not button.IsObjectType or not button:IsObjectType("Button") then
		deleteDebug("ensureDeleteButton: creating new button on", describeFrame(parent))
		button = buildDeleteButton(parent)
		if not button then
			deleteDebug("ensureDeleteButton: creation failed")
			return nil
		end
		state.deleteButton = button
		if rememberWidget then
			rememberWidget("deleteBtn", button)
		end
		if state.uiFrame then
			state.uiFrame.deleteBtn = button
		end
		configureDeleteButton(button)
	else
		deleteDebug("ensureDeleteButton: reusing existing button", describeFrame(button))
	end

	if button:GetParent() ~= parent then
		button:SetParent(parent)
	end

	anchorDeleteButton(button, parent)
	button:Show()
	return button
end

ReaderUI.__ensureDeleteButton = ensureDeleteButton
