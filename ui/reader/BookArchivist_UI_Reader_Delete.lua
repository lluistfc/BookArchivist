---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = BookArchivist.UI.Reader or {}
BookArchivist.UI.Reader = ReaderUI

local function t(key)
	local L = BookArchivist and BookArchivist.L or {}
	return (L and L[key]) or key
end

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

local popupRegistry = type(StaticPopupDialogs) == "table" and StaticPopupDialogs or nil
if popupRegistry and not popupRegistry.BOOKARCHIVIST_CONFIRM_DELETE then
	popupRegistry.BOOKARCHIVIST_CONFIRM_DELETE = {
		text = t("READER_DELETE_CONFIRM"),
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
elseif popupRegistry and popupRegistry.BOOKARCHIVIST_CONFIRM_DELETE then
	-- Ensure popup text is refreshed to the active locale on reload.
	popupRegistry.BOOKARCHIVIST_CONFIRM_DELETE.text = t("READER_DELETE_CONFIRM")
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
	local size = Metrics.BTN_H or 22
	button:SetSize(size, size)
	-- Enable mouse clicks
	button:EnableMouse(true)
	button:RegisterForClicks("LeftButtonUp")
	button:Disable()
	button:SetMotionScriptsWhileDisabled(true)
	
	-- Create icon texture for delete/trash
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()
	if icon.SetAtlas then
		-- Try red X icon first
		local success = pcall(function() icon:SetAtlas("common-icon-redx", true) end)
		if not success then
			-- Fallback: close/X button
			success = pcall(function() icon:SetAtlas("transmog-icon-remove", true) end)
			if not success then
				-- Final fallback: use X button texture
				icon:SetTexture("Interface\\Buttons\\UI-StopButton")
				-- Tint red for delete
				icon:SetVertexColor(1, 0.2, 0.2)
			end
		end
	end
	button.icon = icon
	
	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self:IsEnabled() then
			GameTooltip:SetText(t("READER_DELETE_BUTTON"), 1, 1, 1)
			GameTooltip:AddLine(t("READER_DELETE_TOOLTIP_ENABLED_BODY"), 1, 0.82, 0, true)
		else
			GameTooltip:SetText(t("READER_DELETE_BUTTON"), 1, 0.9, 0)
			GameTooltip:AddLine(t("READER_DELETE_TOOLTIP_DISABLED_BODY"), 0.9, 0.9, 0.9, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
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
			local books
			if db and db.booksById and next(db.booksById) ~= nil then
				books = db.booksById
			else
				books = db and db.books or nil
			end
			local entry = books and books[key]
			local title = entry and entry.title or key
			if StaticPopup_Show and popupRegistry and popupRegistry.BOOKARCHIVIST_CONFIRM_DELETE then
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
							chatMessage(t("READER_DELETE_CHAT_SUCCESS"))
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
					chatMessage(t("READER_DELETE_CHAT_SUCCESS"))
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
		button = safeCreateFrame("Button", "BookArchivistDeleteButton", parent)
		if not button then
			deleteDebug("buildDeleteButton: named creation failed, retrying anonymous")
			button = safeCreateFrame("Button", nil, parent)
		end
	end

	if not button and CreateFrame then
		deleteDebug("buildDeleteButton: fallback to CreateFrame")
		local ok, created = pcall(CreateFrame, "Button", nil, parent)
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
	local size = Metrics.BTN_H or 22
	button:SetSize(size, size)
	button:ClearAllPoints()
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
