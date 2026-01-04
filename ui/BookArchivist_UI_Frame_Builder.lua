---@diagnostic disable: undefined-global, undefined-field
-- BookArchivist_UI_Frame_Builder.lua
-- Purely responsible for constructing the main Book Archivist frame visuals.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI

local DEFAULT_WIDTH = 900
local DEFAULT_HEIGHT = 600
local DEFAULT_PORTRAIT = "Interface\\Icons\\INV_Misc_Book_09"
local OPTIONS_TOOLTIP_TITLE = "Book Archivist Options"
local OPTIONS_TOOLTIP_DESC = "Open the settings panel"
local HEADER_TOP_OFFSET = -32
local HEADER_LEFT_OFFSET = 56
local HEADER_RIGHT_OFFSET = -34
local HEADER_HEIGHT = 78
local CONTENT_BOTTOM_OFFSET = 38
local MIN_LIST_WIDTH = 260
local MIN_READER_WIDTH = 320

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
	local header = safeCreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
	if not header then
		return nil
	end
	header:SetPoint("TOPLEFT", frame, "TOPLEFT", HEADER_LEFT_OFFSET, HEADER_TOP_OFFSET)
	header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", HEADER_RIGHT_OFFSET, HEADER_TOP_OFFSET)
	header:SetHeight(HEADER_HEIGHT)
	header.TitleRegion = header:CreateTexture(nil, "BACKGROUND", nil, -1)
	header.TitleRegion:SetAllPoints(true)
	header.TitleRegion:SetColorTexture(0, 0, 0, 0.45)
	frame.HeaderFrame = header
	return header
end

local function clampListWidth(content, width)
	local totalWidth = content:GetWidth() or (DEFAULT_WIDTH - (HEADER_LEFT_OFFSET + math.abs(HEADER_RIGHT_OFFSET)))
	local maxWidth = math.max(MIN_LIST_WIDTH, totalWidth - MIN_READER_WIDTH)
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
	local content = safeCreateFrame("Frame", nil, frame)
	if not content then
		return nil
	end
	content:SetPoint("TOPLEFT", header or frame, "BOTTOMLEFT", 0, -12)
	content:SetPoint("TOPRIGHT", header or frame, "BOTTOMRIGHT", 0, -12)
	content:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", HEADER_LEFT_OFFSET, CONTENT_BOTTOM_OFFSET)
	content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", HEADER_RIGHT_OFFSET, CONTENT_BOTTOM_OFFSET)
	frame.ContentFrame = content

	local listInset = safeCreateFrame("Frame", nil, content, "InsetFrameTemplate3")
	local readerInset = safeCreateFrame("Frame", nil, content, "InsetFrameTemplate3")
	if not listInset or not readerInset then
		return nil
	end

	local initialWidth = opts.getPreferredListWidth and opts.getPreferredListWidth() or 360
	listInset:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	listInset:SetPoint("BOTTOMLEFT", content, "BOTTOMLEFT", 0, 0)
	listInset:SetWidth(initialWidth)
	readerInset:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
	readerInset:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0, 0)

	local splitter = safeCreateFrame("Frame", nil, content)
	splitter:SetPoint("TOPLEFT", listInset, "TOPRIGHT", 0, 0)
	splitter:SetPoint("BOTTOMLEFT", listInset, "BOTTOMRIGHT", 0, 0)
	splitter:SetWidth(10)
	splitter:EnableMouse(true)
	splitter:RegisterForDrag("LeftButton")
	configureSplitter(splitter)
	frame.SplitterFrame = splitter

	readerInset:SetPoint("TOPLEFT", splitter, "TOPRIGHT", 6, 0)
	readerInset:SetPoint("BOTTOMLEFT", splitter, "BOTTOMRIGHT", 6, 0)

	frame.listBlock = listInset
	frame.ListInset = listInset
	frame.readerBlock = readerInset
	frame.ReaderInset = readerInset

	local layoutState = {
		currentWidth = clampListWidth(content, initialWidth),
	}

	local function applyWidth(width, skipPersist)
		layoutState.currentWidth = clampListWidth(content, width)
		listInset:SetWidth(layoutState.currentWidth)
		frame.currentListWidth = layoutState.currentWidth
		if not skipPersist and opts.onListWidthChanged then
			opts.onListWidthChanged(layoutState.currentWidth)
		end
	end

	applyWidth(initialWidth, true)

	content:SetScript("OnSizeChanged", function()
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
			local contentLeft = content:GetLeft()
			if contentLeft then
				local desired = cursorX - contentLeft
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
