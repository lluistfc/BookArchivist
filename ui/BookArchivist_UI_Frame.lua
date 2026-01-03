---@diagnostic disable: undefined-global, undefined-field
local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI or not addonRoot.UI.Internal then
	return
end

local Internal = addonRoot.UI.Internal
local ListUI = Internal.ListUI
local ReaderUI = Internal.ReaderUI

local initializationError

local function debugPrint(...)
	if Internal.debugPrint then
		Internal.debugPrint(...)
	end
end

local function debugMessage(msg)
	if Internal.debugMessage then
		Internal.debugMessage(msg)
	end
end

local function logError(msg)
	if Internal.logError then
		Internal.logError(msg)
	end
end

local function configureDrag(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
end

local function configureOptionsButton(uiFrame, safeCreateFrame)
	local button = safeCreateFrame("Button", "BookArchivistCogButton", uiFrame, "UIPanelCloseButton")
	if not button then
		return
	end

	local closeButton = uiFrame.CloseButton or uiFrame.CloseButtonFrame or uiFrame.CloseButton2
	local width = closeButton and closeButton:GetWidth() or 26
	local height = closeButton and closeButton:GetHeight() or 26
	button:SetSize(width, height)
	if closeButton then
		button:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", 0, 0)
	else
		button:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -40, 0)
	end

	button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
	button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

	local function tint(tex, r, g, b)
		if tex then
			tex:SetTexCoord(0, 1, 0, 1)
			tex:SetVertexColor(r, g, b, 1)
		end
	end

	tint(button:GetNormalTexture(), 0.75, 0.05, 0.05)
	tint(button:GetPushedTexture(), 0.6, 0.03, 0.03)
	tint(button:GetDisabledTexture(), 0.3, 0.03, 0.03)

	local highlight = button:GetHighlightTexture()
	if highlight then
		highlight:SetTexCoord(0, 1, 0, 1)
		highlight:SetVertexColor(1, 0.8, 0.2, 0.65)
	end

	local icon = button:CreateTexture(nil, "ARTWORK", nil, 1)
	icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon:SetPoint("CENTER", 0, 0)
	icon:SetSize(width - 12, height - 12)
	icon:SetVertexColor(0.95, 0.75, 0.1, 1)
	button.icon = icon

	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetText("Book Archivist Options", 1, 0.82, 0)
		GameTooltip:AddLine("Open the settings panel", 0.9, 0.9, 0.9)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnClick", function()
		if addonRoot and type(addonRoot.OpenOptionsPanel) == "function" then
			addonRoot:OpenOptionsPanel()
		end
	end)

	uiFrame.optionsButton = button
end

local function setupUI()
	local existing = Internal.getUIFrame()
	if existing then
		debugMessage("|cFF00FF00BookArchivist UI (setupUI) already initialized.|r")
		return true
	end

	if not CreateFrame or not UIParent then
		return false, "Blizzard UI not ready yet. Please try again after entering the world."
	end

	local safeCreateFrame = Internal.safeCreateFrame or CreateFrame
	local frame = safeCreateFrame("Frame", "BookArchivistFrame", UIParent, "PortraitFrameTemplate", "ButtonFrameTemplate")
	if not frame then
		return false, "Unable to create BookArchivist frame."
	end

	Internal.setUIFrame(frame)
	frame:SetSize(900, 600)
	frame:SetPoint("CENTER")
	frame:Hide()
	configureDrag(frame)

	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.portrait = frame.PortraitContainer.portrait
	end
	if frame.portrait then
		frame.portrait:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
	end

	if frame.TitleText then
		frame.TitleText:SetText("Book Archivist")
	end

	configureOptionsButton(frame, safeCreateFrame)

	if ListUI and ListUI.Create then
		ListUI:Create(frame)
	end

	if ReaderUI and ReaderUI.Create then
		local anchor = ListUI and ListUI.GetListBlock and ListUI:GetListBlock() or frame
		ReaderUI:Create(frame, anchor)
	end
	debugPrint("[BookArchivist] setupUI: creating BookArchivistFrame")

	frame:SetScript("OnShow", function()
		local refreshFn = Internal.refreshAll
		local ok, err = pcall(function()
			if refreshFn then
				refreshFn()
			end
		end)
		debugPrint("[BookArchivist] UI OnShow fired")
		if not ok then
			logError("Error refreshing UI: " .. tostring(err))
		end
	end)

	if Internal.updateListModeUI then
		Internal.updateListModeUI()
	end

	Internal.setIsInitialized(true)
	frame.__BookArchivistInitialized = true
	Internal.setNeedsRefresh(true)
	debugPrint("[BookArchivist] setupUI: finished, pending refresh")
	if Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.setupUI = setupUI

local function ensureUI()
	local ui = Internal.getUIFrame()
	if ui then
		if not Internal.getIsInitialized() then
			debugPrint("[BookArchivist] ensureUI: repairing missing initialization flag")
			Internal.setIsInitialized(true)
		end
		debugPrint(string.format(
			"[BookArchivist] ensureUI: already initialized (isInitialized=%s needsRefresh=%s)",
			tostring(Internal.getIsInitialized()),
			tostring(Internal.getNeedsRefresh())
		))
		if Internal.flushPendingRefresh then
			Internal.flushPendingRefresh()
		end
		return true
	end

	if Internal.chatMessage then
		Internal.chatMessage("|cFFFFFF00BookArchivist UI not initialized, creating...|r")
	end

	local ok, err = setupUI()
	if not ok then
		initializationError = err or "BookArchivist UI failed to initialize."
		return false, initializationError
	end

	initializationError = nil
	Internal.setIsInitialized(true)
	debugPrint("[BookArchivist] ensureUI: initialized via setup (needsRefresh=" .. tostring(Internal.getNeedsRefresh()) .. ")")
	if Internal.getNeedsRefresh() and Internal.flushPendingRefresh then
		Internal.flushPendingRefresh()
	end
	return true
end

Internal.ensureUI = ensureUI
