---@diagnostic disable: undefined-global, undefined-field
-- Frame chrome (header, portrait, title, options button) helpers.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI
local Internal = BookArchivist.UI.Internal

local Metrics = BookArchivist.UI.Metrics or {
	PAD_OUTER = 12,
	PAD_INSET = 10,
	GAP_M = 10,
	HEADER_LEFT_SAFE_X = 54,
	HEADER_LEFT_W = 260,
	HEADER_H = 90,
	BTN_H = 22,
	BTN_W = 100,
	HEADER_RIGHT_STACK_W = 360,
	HEADER_RIGHT_GUTTER = 12,
}

local function computeHeaderRowHeights()
	local headerH = Metrics.HEADER_H or 72
	local inset = Metrics.PAD_INSET or Metrics.PAD or 10
	local innerH = math.max(20, headerH - (inset * 2))
	local base = math.max(24, (Metrics.BTN_H or 22) + (Metrics.GAP_S or 6))
	local top = base
	local bottom = base
	local total = top + bottom
	if total > innerH then
		local scale = innerH / total
		top = math.max(20, math.floor(top * scale))
		bottom = math.max(20, innerH - top)
	end
	return top, bottom
end

local HEADER_TOP_ROW_H, HEADER_BOTTOM_ROW_H = computeHeaderRowHeights()

local ClearAnchors = FrameUI.ClearAnchors or function(frame, resetSize)
	if not frame then return end
	if frame.ClearAllPoints then frame:ClearAllPoints() end
	if resetSize and frame.SetSize then frame:SetSize(1, 1) end
end

local DEFAULT_PORTRAIT = FrameUI.DEFAULT_PORTRAIT or "Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png"
local OPTIONS_TOOLTIP_TITLE = "Book Archivist Options"
local OPTIONS_TOOLTIP_DESC = "Open the settings panel"

local function configureDrag(frame)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
end

local function applyPortrait(frame)
	if frame.PortraitContainer and frame.PortraitContainer.portrait then
		frame.portrait = frame.PortraitContainer.portrait
	end
	if frame.portrait then
		frame.portrait:SetTexture(DEFAULT_PORTRAIT)
	end
end

local function configureTitle(frame, title)
	if frame.TitleText then
		frame.TitleText:SetText(title or "Book Archivist")
	end
end

local function tint(texture, r, g, b)
	if not texture then
		return
	end
	texture:SetTexCoord(0, 1, 0, 1)
	texture:SetVertexColor(r, g, b, 1)
end

local function configureOptionsButton(frame, safeCreateFrame, onOptions)
	local button = safeCreateFrame("Button", "BookArchivistCogButton", frame, "UIPanelCloseButton")
	if not button then
		return
	end

	local closeButton = frame.CloseButton or frame.CloseButtonFrame or frame.CloseButton2
	local width = closeButton and closeButton:GetWidth() or 26
	local height = closeButton and closeButton:GetHeight() or 26
	button:SetSize(width, height)
	if closeButton then
		button:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", 0, 0)
	else
		button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, 0)
	end

	button:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	button:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled")
	button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")

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
		GameTooltip:SetText(OPTIONS_TOOLTIP_TITLE, 1, 0.82, 0)
		GameTooltip:AddLine(OPTIONS_TOOLTIP_DESC, 0.9, 0.9, 0.9)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnClick", function()
		if type(onOptions) == "function" then
			local ok, err = pcall(onOptions)
			if not ok and BookArchivist and BookArchivist.LogError then
				BookArchivist:LogError("BookArchivist options button failed: " .. tostring(err))
			end
			return
		end
		if BookArchivist and type(BookArchivist.OpenOptionsPanel) == "function" then
			BookArchivist:OpenOptionsPanel()
		end
	end)

	frame.optionsButton = button
end

local function createColumnRows(column, safeCreateFrame)
	if not column or type(safeCreateFrame) ~= "function" then
		return column, column
	end
	local top = safeCreateFrame("Frame", nil, column)
	local bottom = safeCreateFrame("Frame", nil, column)
	if not top or not bottom then
		return column, column
	end
	top:SetPoint("TOPLEFT", column, "TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", column, "TOPRIGHT", 0, 0)
	top:SetHeight(HEADER_TOP_ROW_H)
	bottom:SetPoint("BOTTOMLEFT", column, "BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", column, "BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(HEADER_BOTTOM_ROW_H)
	return top, bottom
end

local function createHeaderBar(frame, safeCreateFrame)
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local gap = Metrics.HEADER_RIGHT_GUTTER or Metrics.GAP_M or 12
	local header = safeCreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	if not header then
		return nil
	end
	ClearAnchors(header)
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", padOuter, -padOuter)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padOuter, -padOuter)
	header:SetHeight(Metrics.HEADER_H)
	header.TitleRegion = header:CreateTexture(nil, "BACKGROUND", nil, -1)
	header.TitleRegion:SetAllPoints(true)
	header.TitleRegion:SetColorTexture(0, 0, 0, 0.45)

	local safeLeft = padInset + (Metrics.HEADER_LEFT_SAFE_X or 54)

	local headerRight = safeCreateFrame("Frame", nil, header)
	ClearAnchors(headerRight)
	headerRight:SetPoint("TOPRIGHT", header, "TOPRIGHT", -padInset, -padInset)
	headerRight:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -padInset, padInset)
	local baseRightWidth = Metrics.HEADER_RIGHT_STACK_W or 0
	local minRightWidth = ((Metrics.BTN_W or 100) * 2) + (Metrics.GAP_S or 6) + (Metrics.PAD_INSET or 10)
	local headerRightWidth = math.max(baseRightWidth, minRightWidth)
	headerRight:SetWidth(headerRightWidth)

	local headerLeftWidth = Metrics.HEADER_LEFT_W or 260
	local headerLeft = safeCreateFrame("Frame", nil, header)
	ClearAnchors(headerLeft)
	headerLeft:SetPoint("TOPLEFT", header, "TOPLEFT", safeLeft, -padInset)
	headerLeft:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", safeLeft, padInset)
	headerLeft:SetWidth(headerLeftWidth)

	local headerCenter = safeCreateFrame("Frame", nil, header)
	ClearAnchors(headerCenter)
	local centerLeftOffset = safeLeft + headerLeftWidth + gap
	local centerRightInset = padInset + gap + headerRightWidth
	headerCenter:SetPoint("TOPLEFT", header, "TOPLEFT", centerLeftOffset, -padInset)
	headerCenter:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", centerLeftOffset, padInset)
	headerCenter:SetPoint("TOPRIGHT", header, "TOPRIGHT", -centerRightInset, -padInset)
	headerCenter:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -centerRightInset, padInset)

	local headerLeftTop, headerLeftBottom = createColumnRows(headerLeft, safeCreateFrame)
	local headerCenterTop, headerCenterBottom = createColumnRows(headerCenter, safeCreateFrame)
	local headerRightTop, headerRightBottom = createColumnRows(headerRight, safeCreateFrame)

	frame.HeaderFrame = header
	frame.HeaderLeft = headerLeft
	frame.HeaderCenter = headerCenter
	frame.HeaderRight = headerRight
	frame.HeaderLeftTop = headerLeftTop
	frame.HeaderLeftBottom = headerLeftBottom
	frame.HeaderCenterTop = headerCenterTop
	frame.HeaderCenterBottom = headerCenterBottom
	frame.HeaderRightTop = headerRightTop
	frame.HeaderRightBottom = headerRightBottom

	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("header-frame", header)
		Internal.registerGridTarget("header-left", headerLeft)
		Internal.registerGridTarget("header-center", headerCenter)
		Internal.registerGridTarget("header-right", headerRight)
		Internal.registerGridTarget("header-left-top", headerLeftTop)
		Internal.registerGridTarget("header-left-bottom", headerLeftBottom)
		Internal.registerGridTarget("header-center-top", headerCenterTop)
		Internal.registerGridTarget("header-center-bottom", headerCenterBottom)
		Internal.registerGridTarget("header-right-top", headerRightTop)
		Internal.registerGridTarget("header-right-bottom", headerRightBottom)
	end

	return header
end

FrameUI.ConfigureDrag = FrameUI.ConfigureDrag or configureDrag
FrameUI.ApplyPortrait = FrameUI.ApplyPortrait or applyPortrait
FrameUI.ConfigureTitle = FrameUI.ConfigureTitle or configureTitle
FrameUI.ConfigureOptionsButton = FrameUI.ConfigureOptionsButton or configureOptionsButton
FrameUI.CreateHeaderBar = FrameUI.CreateHeaderBar or createHeaderBar
