---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_UI_Frame_Builder.lua
-- Purely responsible for constructing the main Book Archivist frame visuals.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI
local Internal = BookArchivist.UI.Internal

local Metrics = BookArchivist.UI.Metrics or {
	PAD = 12,
	PAD_OUTER = 12,
	PAD_INSET = 10,
	GUTTER = 10,
	GAP_S = 6,
	GAP_M = 10,
	GAP_L = 14,
	HEADER_LEFT_SAFE_X = 54,
	HEADER_LEFT_W = 260,
	HEADER_CENTER_BIAS_Y = 0,
	HEADER_H = 90,
	LIST_HEADER_H = 34,
	LIST_TIP_H = 20,
	READER_HEADER_H = 54,
	READER_ACTIONS_W = 140,
	ROW_H = 36,
	BTN_H = 22,
	BTN_W = 100,
	HEADER_RIGHT_STACK_W = 110,
	HEADER_RIGHT_GUTTER = 12,
	SCROLLBAR_GUTTER = 18,
	SEPARATOR_W = 10,
	SEPARATOR_GAP = 6,
}

local DEFAULT_WIDTH = 900
local DEFAULT_HEIGHT = 680
local DEFAULT_PORTRAIT = "Interface\\Icons\\INV_Misc_Book_09"
local OPTIONS_TOOLTIP_TITLE = "Book Archivist Options"
local OPTIONS_TOOLTIP_DESC = "Open the settings panel"
local MIN_LIST_WIDTH = 260
local MIN_READER_WIDTH = 320
local HEADER_ROW_GAP_Y = Metrics.GAP_XS or 0
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

--[[
Layout invariants (Plan v4)
1. Only HeaderFrame and BodyFrame may anchor directly to the main frame shell.
2. Header is composed of left/center/right blocks; search input lives in HeaderCenter only.
3. List inset exposes three stacked rows at the top: ListHeaderRow, ListTipRow, and ListScroll beneath.
4. Reader inset exposes two stacked rows at the top: ReaderHeaderRow and ReaderNavRow, followed by ReaderScroll.
5. The vertical separator spans the BodyFrame content height and never anchors to list header internals.
]]

local function resolveSafeCreateFrame(override)
	if type(override) == "function" then
		return override
	end
	if Internal and type(Internal.safeCreateFrame) == "function" then
		return Internal.safeCreateFrame
	end
	if type(CreateFrame) == "function" then
		return CreateFrame
	end
	return nil
end

local function ClearAnchors(frame, resetSize)
	if not frame then
		return
	end
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if resetSize and frame.SetSize then
		frame:SetSize(1, 1)
	end
end

local function CreateContainer(name, parent, template, override)
	local safeCreateFrame = resolveSafeCreateFrame(override)
	if not safeCreateFrame or not parent then
		return nil
	end
	return safeCreateFrame("Frame", name, parent, template)
end

local function CreateRow(name, parent, height, template, override)
	local row = CreateContainer(name, parent, template, override)
	if row and height then
		row:SetHeight(height)
	end
	return row
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

FrameUI.CreateContainer = FrameUI.CreateContainer or CreateContainer
FrameUI.CreateRow = FrameUI.CreateRow or CreateRow
FrameUI.ClearAnchors = FrameUI.ClearAnchors or ClearAnchors
if Internal then
	Internal.CreateContainer = Internal.CreateContainer or CreateContainer
	Internal.CreateRow = Internal.CreateRow or CreateRow
	Internal.ClearAnchors = Internal.ClearAnchors or ClearAnchors
end

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

local function clampListWidth(container, width)
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local separatorWidth = Metrics.SEPARATOR_W or math.max(8, math.floor((Metrics.GAP_M or 10) * 0.6))
	local separatorGap = Metrics.SEPARATOR_GAP or Metrics.GAP_S or 6
	local available = (container and container:GetWidth()) or (DEFAULT_WIDTH - (padOuter * 2))
	local usable = available - (padInset * 2) - separatorWidth - separatorGap - MIN_READER_WIDTH
	local maxWidth = math.max(MIN_LIST_WIDTH, usable)
	return math.max(MIN_LIST_WIDTH, math.min(width, maxWidth))
end

local function configureSplitter(splitter)
	local handle = splitter:CreateTexture(nil, "ARTWORK")
	handle:SetAllPoints(true)
	handle:SetColorTexture(0.9, 0.75, 0.3, 0.25)
	local grip = splitter:CreateTexture(nil, "OVERLAY")
	grip:SetSize(4, 32)
	grip:SetPoint("CENTER")
	grip:SetColorTexture(1, 0.82, 0, 0.75)
	splitter:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
	end)
	splitter:SetScript("OnLeave", function(self)
		if not self.__isDragging then
			self:SetAlpha(0.85)
		end
	end)
	splitter:SetAlpha(0.85)
end

local function createContentLayout(frame, safeCreateFrame, opts)
	local header = frame.HeaderFrame or createHeaderBar(frame, safeCreateFrame)
	if not header then
		return nil
	end
	local body = safeCreateFrame("Frame", nil, frame)
	if not body then
		return nil
	end
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local bodyGap = Metrics.GAP_M or Metrics.GUTTER or 10
	ClearAnchors(body)
	body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -bodyGap)
	body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padOuter, padOuter)
	frame.ContentFrame = body
	frame.BodyFrame = body
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("body", body)
	end

	local listInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	local readerInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	if not listInset or not readerInset then
		return nil
	end

	local initialWidth = opts.getPreferredListWidth and opts.getPreferredListWidth() or 360
	local separatorGap = Metrics.SEPARATOR_GAP or Metrics.GAP_S or 6
	listInset:SetPoint("TOPLEFT", body, "TOPLEFT", padInset, -padInset)
	listInset:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", padInset, padInset)
	readerInset:SetPoint("TOPRIGHT", body, "TOPRIGHT", -padInset, -padInset)
	readerInset:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -padInset, padInset)

	local splitter = safeCreateFrame("Frame", nil, body)
	splitter:SetPoint("TOPLEFT", listInset, "TOPRIGHT", 0, 0)
	splitter:SetPoint("BOTTOMLEFT", listInset, "BOTTOMRIGHT", 0, 0)
	splitter:SetWidth(Metrics.SEPARATOR_W or math.max(8, math.floor((Metrics.GAP_M or 10) * 0.6)))
	splitter:EnableMouse(true)
	splitter:RegisterForDrag("LeftButton")
	configureSplitter(splitter)
	frame.SplitterFrame = splitter
	frame.SeparatorFrame = splitter

	readerInset:SetPoint("TOPLEFT", splitter, "TOPRIGHT", separatorGap, 0)
	readerInset:SetPoint("BOTTOMLEFT", splitter, "BOTTOMRIGHT", separatorGap, 0)
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-inset", listInset)
		Internal.registerGridTarget("reader-inset", readerInset)
		Internal.registerGridTarget("body-separator", splitter)
	end

	frame.listBlock = listInset
	frame.ListInset = listInset
	frame.readerBlock = readerInset
	frame.ReaderInset = readerInset

	local layoutState = {
		currentWidth = clampListWidth(body, initialWidth),
	}

	local function applyWidth(width, skipPersist)
		layoutState.currentWidth = clampListWidth(body, width)
		listInset:SetWidth(layoutState.currentWidth)
		frame.currentListWidth = layoutState.currentWidth
		if not skipPersist and opts.onListWidthChanged then
			opts.onListWidthChanged(layoutState.currentWidth)
		end
	end

	applyWidth(initialWidth, true)

	body:SetScript("OnSizeChanged", function()
		applyWidth(layoutState.currentWidth, true)
	end)

	local function finishDrag()
		splitter.__isDragging = false
		splitter:SetScript("OnUpdate", nil)
		splitter:SetAlpha(0.85)
		applyWidth(layoutState.currentWidth)
	end

	local function beginDrag()
		splitter.__isDragging = true
		splitter:SetAlpha(1)
		splitter:SetScript("OnUpdate", function()
			local cursorX = 0
			local scale = UIParent and UIParent:GetEffectiveScale() or 1
			if GetCursorPosition then
				cursorX = select(1, GetCursorPosition()) / scale
			end
			local bodyLeft = body:GetLeft()
			if bodyLeft then
				local desired = cursorX - bodyLeft
				applyWidth(desired, true)
			end
		end)
	end

	splitter:SetScript("OnMouseDown", beginDrag)
	splitter:SetScript("OnDragStart", beginDrag)
	splitter:SetScript("OnMouseUp", finishDrag)
	splitter:SetScript("OnDragStop", finishDrag)
	splitter:SetScript("OnHide", function()
		if splitter.__isDragging then
			finishDrag()
		end
	end)

	return true
end

local function attachListUI(listUI, frame)
	if not listUI or type(listUI.Create) ~= "function" then
		return
	end
	local ok, err = pcall(listUI.Create, listUI, frame)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist list UI failed: " .. tostring(err))
	end
end

local function attachReaderUI(readerUI, listUI, frame)
	if not readerUI or type(readerUI.Create) ~= "function" then
		return
	end
	local anchor
	if listUI and type(listUI.GetListBlock) == "function" then
		local ok, block = pcall(function()
			return listUI:GetListBlock()
		end)
		if ok and block then
			anchor = block
		end
	end
	local ok, err = pcall(readerUI.Create, readerUI, frame, anchor or frame)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist reader UI failed: " .. tostring(err))
	end
end

function FrameUI:Create(opts)
	opts = opts or {}
	local parent = opts.parent or UIParent
	local safeCreateFrame = opts.safeCreateFrame or CreateFrame

	if type(safeCreateFrame) ~= "function" or not parent then
		return nil, "Blizzard UI not ready yet. Please try again after entering the world."
	end

	local frame = safeCreateFrame(
		"Frame",
		"BookArchivistFrame",
		parent,
		"PortraitFrameTemplate",
		"ButtonFrameTemplate"
	)
	if not frame then
		return nil, "Unable to create BookArchivist frame."
	end

	frame:SetSize(opts.width or DEFAULT_WIDTH, opts.height or DEFAULT_HEIGHT)
	frame:SetPoint(
		opts.anchorPoint or "CENTER",
		opts.anchorTarget or UIParent,
		opts.anchorRelativePoint or "CENTER",
		opts.offsetX or 0,
		opts.offsetY or 0
	)
	frame:Hide()

	configureDrag(frame)
	applyPortrait(frame)
	configureTitle(frame, opts.title)
	configureOptionsButton(frame, safeCreateFrame, opts.onOptions)
	createHeaderBar(frame, safeCreateFrame)
	createContentLayout(frame, safeCreateFrame, opts)

	attachListUI(opts.listUI, frame)
	attachReaderUI(opts.readerUI, opts.listUI, frame)

	frame:SetScript("OnShow", function()
		if opts.debugPrint then
			opts.debugPrint("[BookArchivist] UI OnShow fired")
		end
		if type(opts.onShow) ~= "function" then
			return
		end
		local ok, err = pcall(opts.onShow, frame)
		if not ok and opts.logError then
			opts.logError("Error refreshing UI: " .. tostring(err))
		end
	end)

	if type(opts.onAfterCreate) == "function" then
		pcall(opts.onAfterCreate, frame)
	end

	if opts.debugPrint then
		opts.debugPrint("[BookArchivist] setupUI: creating BookArchivistFrame")
	end

	return frame
end
