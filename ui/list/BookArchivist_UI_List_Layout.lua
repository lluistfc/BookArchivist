---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics
	or {
		PAD = 12,
		GUTTER = 10,
		HEADER_H = 90,
		BTN_H = 22,
		BTN_W = 100,
		ROW_H = 36,
		LIST_HEADER_H = 34,
		LIST_TOPBAR_H = 28,
		PAD_OUTER = 12,
		PAD_INSET = 11,
		GAP_XS = 4,
		GAP_S = 6,
		GAP_M = 10,
		GAP_L = 14,
		HEADER_RIGHT_STACK_W = 110,
		HEADER_RIGHT_GUTTER = 12,
		SCROLLBAR_GUTTER = 18,
	}

-- Spacing constants for header layout
local HEADER_SPACING = {
	COLUMN_GAP = Metrics.HEADER_RIGHT_GUTTER or Metrics.GAP_M or 12,
	BUTTON_GAP = Metrics.GAP_S or 6,
	ELEMENT_GAP = Metrics.GAP_XS or 4,
}

local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local function ClearAnchors(frame)
	if frame and frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
end

local function hasMethod(obj, methodName)
	return obj and type(obj[methodName]) == "function"
end

function ListUI:EnsureListHeaderRow()
	local row = self:GetFrame("listHeaderRow")
	if row then
		return row
	end
	local listBlock = self:GetFrame("listBlock")
	if not listBlock then
		self:DebugPrint("[BookArchivist] EnsureListHeaderRow aborted (listBlock missing)")
		return nil
	end
	row = self:SafeCreateFrame("Frame", nil, listBlock)
	if not row then
		self:LogError("Unable to create list header row.")
		return nil
	end
	local inset = Metrics.PAD_INSET or Metrics.PAD or 8
	ClearAnchors(row)
	row:SetPoint("TOPLEFT", listBlock, "TOPLEFT", inset, -inset)
	row:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -inset, -inset)
	row:SetHeight(Metrics.LIST_HEADER_H or (Metrics.BTN_H or 22))
	self:SetFrame("listHeaderRow", row)
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-header-row", row)
	end
	return row
end

function ListUI:EnsureListTipRow()
	local row = self:GetFrame("listTipRow")
	if row then
		return row
	end
	local listBlock = self:GetFrame("listBlock")
	if not listBlock then
		return nil
	end
	local headerRow = self:EnsureListHeaderRow()
	if not headerRow then
		return nil
	end
	row = self:SafeCreateFrame("Frame", nil, listBlock)
	if not row then
		return nil
	end
	local inset = Metrics.PAD_INSET or Metrics.PAD or 8
	ClearAnchors(row)
	row:SetPoint("BOTTOMLEFT", listBlock, "BOTTOMLEFT", inset, inset)
	row:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -inset, inset)
	local gap = Metrics.GAP_S or Metrics.GAP_XS or 4
	local btnH = Metrics.BTN_H or 22
	local tipH = Metrics.TIP_ROW_H or Metrics.LIST_TIP_H or (Metrics.LIST_INFO_H or 18)
	row:SetHeight(math.max(tipH, (btnH * 2) + gap))
	self:SetFrame("listTipRow", row)
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-tip-row", row)
	end
	return row
end

function ListUI:EnsureListBreadcrumbRow()
	local row = self:GetFrame("breadcrumbRow")
	if row then
		return row
	end
	local listBlock = self:GetFrame("listBlock")
	if not listBlock then
		return nil
	end
	local headerRow = self:EnsureListHeaderRow()
	if not headerRow then
		return nil
	end

	row = self:SafeCreateFrame("Frame", nil, listBlock)
	if not row then
		return nil
	end

	-- Set frame strata to ensure breadcrumbs appear above ScrollBox content
	row:SetFrameStrata("MEDIUM")
	row:SetFrameLevel(100) -- Higher than default to appear on top

	-- Position directly below header row with minimal gap
	local gap = 2
	local inset = Metrics.PAD_INSET or Metrics.PAD or 8
	row:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -gap)
	row:SetPoint("TOPRIGHT", headerRow, "BOTTOMRIGHT", 0, -gap)
	row:SetHeight(86) -- Increased for 4 lines of breadcrumbs
	self:SetFrame("breadcrumbRow", row)

	-- Create subtle gradient background similar to Blizzard's breadcrumb
	local bgTop = row:CreateTexture(nil, "BACKGROUND", nil, -1)
	bgTop:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	bgTop:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
	bgTop:SetHeight(row:GetHeight() / 2)
	bgTop:SetGradient("VERTICAL", CreateColor(0.1, 0.1, 0.12, 0.8), CreateColor(0.05, 0.05, 0.06, 0.6))

	local bgBottom = row:CreateTexture(nil, "BACKGROUND", nil, -1)
	bgBottom:SetPoint("TOPLEFT", bgTop, "BOTTOMLEFT", 0, 0)
	bgBottom:SetPoint("TOPRIGHT", bgTop, "BOTTOMRIGHT", 0, 0)
	bgBottom:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
	bgBottom:SetGradient("VERTICAL", CreateColor(0.05, 0.05, 0.06, 0.6), CreateColor(0.02, 0.02, 0.03, 0.4))

	-- Add subtle top border
	local borderTop = row:CreateTexture(nil, "BORDER")
	borderTop:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	borderTop:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
	borderTop:SetHeight(1)
	borderTop:SetColorTexture(0.15, 0.15, 0.17, 0.5)

	-- Add subtle bottom border
	local borderBottom = row:CreateTexture(nil, "BORDER")
	borderBottom:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	borderBottom:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
	borderBottom:SetHeight(1)
	borderBottom:SetColorTexture(0.08, 0.08, 0.09, 0.8)

	-- Create 4 clickable button lines for breadcrumb navigation
	local lineHeight = 16
	local lineGap = 4
	local textPadding = 8

	-- Helper to create a clickable breadcrumb line
	local function createBreadcrumbButton(name, parent, prevLine)
		local btn = self:SafeCreateFrame("Button", nil, parent)
		if not btn then
			return nil
		end

		if prevLine then
			btn:SetPoint("TOPLEFT", prevLine, "BOTTOMLEFT", 0, -lineGap)
			btn:SetPoint("TOPRIGHT", prevLine, "BOTTOMRIGHT", 0, -lineGap)
		else
			btn:SetPoint("TOPLEFT", parent, "TOPLEFT", textPadding, -textPadding)
			btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -textPadding, -textPadding)
		end
		btn:SetHeight(lineHeight)

		local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		fs:SetAllPoints(btn)
		fs:SetJustifyH("LEFT")
		fs:SetWordWrap(false)
		fs:SetMaxLines(1)
		btn.text = fs

		-- Hover effect
		btn:SetScript("OnEnter", function(self)
			if self.isClickable then
				self.text:SetTextColor(1.0, 0.82, 0.0) -- Gold on hover
				GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
				GameTooltip:SetText("Click to navigate to this location", 1, 1, 1)
				GameTooltip:Show()
			end
		end)
		btn:SetScript("OnLeave", function(self)
			if self.isClickable then
				self.text:SetTextColor(0.67, 0.67, 0.67) -- Reset to dim
			end
			GameTooltip:Hide()
		end)

		return btn
	end

	local line1 = createBreadcrumbButton("breadcrumbLine1", row, nil)
	local line2 = createBreadcrumbButton("breadcrumbLine2", row, line1)
	local line3 = createBreadcrumbButton("breadcrumbLine3", row, line2)
	local line4 = createBreadcrumbButton("breadcrumbLine4", row, line3)

	if not (line1 and line2 and line3 and line4) then
		return nil
	end

	self:SetFrame("breadcrumbLine1", line1)
	self:SetFrame("breadcrumbLine2", line2)
	self:SetFrame("breadcrumbLine3", line3)
	self:SetFrame("breadcrumbLine4", line4)

	return row
end

function ListUI:UpdateListScrollRowAnchors()
	local row = self:GetFrame("listScrollRow")
	if not row then
		return
	end

	local tipRow = self:GetFrame("listTipRow")
	if not tipRow then
		return
	end

	local gap = Metrics.LIST_SCROLL_GAP or 0
	local mode = self:GetListMode()
	local modes = self:GetListModes()

	-- Determine top anchor based on mode and breadcrumb visibility
	local breadcrumbRow = self:GetFrame("breadcrumbRow")
	local topAnchor

	if mode == modes.LOCATIONS and breadcrumbRow and breadcrumbRow:IsShown() then
		-- In locations mode with breadcrumbs visible, anchor below breadcrumbs
		topAnchor = breadcrumbRow
	else
		-- In books mode or no breadcrumbs, anchor below header
		topAnchor = self:EnsureListHeaderRow()
	end

	if not topAnchor then
		return
	end

	ClearAnchors(row)
	row:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -gap)
	row:SetPoint("TOPRIGHT", topAnchor, "BOTTOMRIGHT", 0, -gap)
	row:SetPoint("BOTTOMLEFT", tipRow, "TOPLEFT", 0, gap * -1)
	row:SetPoint("BOTTOMRIGHT", tipRow, "TOPRIGHT", 0, gap * -1)
end

function ListUI:EnsureListScrollRow()
	local row = self:GetFrame("listScrollRow")
	if row then
		return row
	end
	local listBlock = self:GetFrame("listBlock")
	if not listBlock then
		return nil
	end
	local tipRow = self:EnsureListTipRow()
	if not tipRow then
		return nil
	end
	row = self:SafeCreateFrame("Frame", nil, listBlock)
	if not row then
		return nil
	end
	self:SetFrame("listScrollRow", row)
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-scroll-row", row)
	end

	-- Set initial anchors
	self:UpdateListScrollRowAnchors()
	return row
end

function ListUI:EnsureListHeader()
	local header = self:GetFrame("listHeader")
	if header then
		return header
	end
	local headerRow = self:EnsureListHeaderRow()
	if not headerRow then
		return nil
	end
	header = headerRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	header:SetPoint("LEFT", headerRow, "LEFT", 0, 0)
	header:SetPoint("TOP", headerRow, "TOP", 0, 0)
	header:SetPoint("BOTTOM", headerRow, "BOTTOM", 0, 0)
	header:SetJustifyH("LEFT")
	header:SetJustifyV("MIDDLE")
	header:SetText(t("BOOK_LIST_HEADER"))
	header:Hide() -- hidden because tabs replace the header label
	self:SetFrame("listHeader", header)
	return header
end

function ListUI:EnsureInfoText()
	local info = self:GetFrame("infoText")
	if info then
		return info
	end
	local tipRow = self:EnsureListTipRow()
	if not tipRow then
		self:DebugPrint("[BookArchivist] EnsureInfoText aborted (tip row missing)")
		return nil
	end
	local paginationFrame = self:EnsurePaginationControls()
	info = tipRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	info:SetJustifyH("LEFT")
	info:SetJustifyV("MIDDLE")
	info:SetText("")
	info:SetPoint("TOPLEFT", tipRow, "TOPLEFT", 0, 0)
	if paginationFrame then
		info:SetPoint("BOTTOMRIGHT", paginationFrame, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER or 10), 0)
	else
		info:SetPoint("BOTTOMRIGHT", tipRow, "BOTTOMRIGHT", 0, 0)
	end
	self:SetFrame("infoText", info)
	return info
end

function ListUI:Create(uiFrame)
	if not uiFrame then
		return
	end

	self:SetUIFrame(uiFrame)
	if Metrics.ROW_H then
		self:SetRowHeight(Metrics.ROW_H)
	end

	local header = uiFrame.HeaderFrame
	if not header then
		header = self:SafeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate3")
		header:SetPoint(
			"TOPLEFT",
			uiFrame,
			"TOPLEFT",
			Metrics.PAD_OUTER or Metrics.PAD,
			-(Metrics.PAD_OUTER or Metrics.PAD)
		)
		header:SetPoint(
			"TOPRIGHT",
			uiFrame,
			"TOPRIGHT",
			-(Metrics.PAD_OUTER or Metrics.PAD),
			-(Metrics.PAD_OUTER or Metrics.PAD)
		)
		header:SetHeight(Metrics.HEADER_H)
		uiFrame.HeaderFrame = header
	end

	local headerLeft = uiFrame.HeaderLeft or header
	local headerCenter = uiFrame.HeaderCenter or header
	local headerRight = uiFrame.HeaderRight or header
	local headerLeftTop = uiFrame.HeaderLeftTop or headerLeft
	local headerLeftBottom = uiFrame.HeaderLeftBottom or headerLeft
	local headerCenterTop = uiFrame.HeaderCenterTop or headerCenter
	local headerCenterBottom = uiFrame.HeaderCenterBottom or headerCenter
	local headerRightTop = uiFrame.HeaderRightTop or headerRight
	local headerRightBottom = uiFrame.HeaderRightBottom or headerRight

	-- ========================================
	-- HEADER LEFT: Logo/Title Container
	-- ========================================
	local titleHost = headerLeftTop or headerLeft
	local titleText
	if titleHost and titleHost.CreateFontString then
		titleText = titleHost:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
	end
	if titleText then
		titleText:SetPoint("LEFT", titleHost, "LEFT", 0, 0)
		titleText:SetPoint("RIGHT", titleHost, "RIGHT", 0, 0)
		titleText:SetJustifyH("LEFT")
		titleText:SetJustifyV("MIDDLE")
		titleText:SetText(t("ADDON_TITLE"))
		titleText:SetWordWrap(false)
		self:SetFrame("headerTitle", titleText)
	else
		self:LogError("Unable to create header title text (HeaderLeftTop missing?)")
	end

	-- Count text in bottom row
	local countHost = headerLeftBottom or headerLeft
	local headerCount
	if countHost and countHost.CreateFontString then
		headerCount = countHost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	end
	if headerCount then
		headerCount:SetPoint("LEFT", countHost, "LEFT", 0, 0)
		headerCount:SetPoint("RIGHT", countHost, "RIGHT", 0, 0)
		headerCount:SetJustifyH("LEFT")
		headerCount:SetJustifyV("MIDDLE")
		headerCount:SetText(t("BOOK_LIST_SUBHEADER"))
		headerCount:SetWordWrap(false)
		headerCount:SetMaxLines(1)
		self:SetFrame("headerCountText", headerCount)
	else
		self:LogError("Unable to create header count text (HeaderLeftBottom missing?)")
	end

	-- ========================================
	-- HEADER CENTER: Filter Bar + Search Bar
	-- ========================================

	-- Filter bar in top row: Sort dropdown
	local filterBarHost = headerCenterTop or headerCenter
	local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", filterBarHost, "UIDropDownMenuTemplate")
	sortDropdown:ClearAllPoints()
	UIDropDownMenu_SetWidth(sortDropdown, 120)
	-- Offset by 16px to align with search box right edge (compensates for dropdown button padding)
	sortDropdown:SetPoint("RIGHT", filterBarHost, "RIGHT", 16, 0)
	self:InitializeSortDropdown(sortDropdown)
	-- Store for future filter buttons
	self:SetFrame("filterBarHost", filterBarHost)

	-- Search bar in bottom row - full width
	local searchBarHost = headerCenterBottom or headerCenter
	local searchBox = self:SafeCreateFrame("EditBox", "BookArchivistSearchBox", searchBarHost, "SearchBoxTemplate")
	if searchBox then
		self:SetFrame("searchBox", searchBox)
		searchBox:SetHeight((Metrics.BTN_H or 22) + (Metrics.GAP_S or 0))
		searchBox:SetPoint("LEFT", searchBarHost, "LEFT", 0, 0)
		searchBox:SetPoint("RIGHT", searchBarHost, "RIGHT", 0, 0)
		searchBox:SetAutoFocus(false)
		searchBox:SetJustifyH("LEFT")
		if self.WireSearchBox then
			self:WireSearchBox(searchBox)
		end
	end

	local clearButton = self:SafeCreateFrame("Button", nil, searchBarHost, "UIPanelCloseButton")
	if clearButton and searchBox then
		clearButton:SetScale(0.7)
		clearButton:SetPoint("LEFT", searchBox, "RIGHT", -HEADER_SPACING.ELEMENT_GAP, 0)
		clearButton:SetScript("OnClick", function()
			searchBox:SetText("")
			self:RunSearchRefresh()
			self:UpdateSearchClearButton()
		end)
		self:SetFrame("searchClearButton", clearButton)
		clearButton:Hide()
	end

	-- ========================================
	-- HEADER RIGHT: Button Groups
	-- ========================================

	-- Top buttons container: Options + Help
	local topButtonsHost = headerRightTop or headerRight

	local optionsButton = self:SafeCreateFrame("Button", nil, topButtonsHost, "UIPanelButtonTemplate")
	if optionsButton then
		optionsButton:SetSize(Metrics.BTN_W, 26)
		optionsButton:SetPoint("TOPRIGHT", topButtonsHost, "TOPRIGHT", 0, 0)
		optionsButton:SetText(t("HEADER_BUTTON_OPTIONS"))
		optionsButton:SetNormalFontObject(GameFontNormal)
		local fontString = optionsButton:GetFontString()
		if fontString then
			fontString:SetTextColor(1.0, 0.82, 0.0)
		end
		optionsButton:SetScript("OnClick", function()
			local addon = self:GetAddon()
			if addon and addon.OpenOptionsPanel then
				addon:OpenOptionsPanel()
			elseif BookArchivist and BookArchivist.OpenOptionsPanel then
				BookArchivist:OpenOptionsPanel()
			end
		end)
		self:SetFrame("optionsButton", optionsButton)
	end

	local helpButton = self:SafeCreateFrame("Button", nil, topButtonsHost, "UIPanelButtonTemplate")
	if helpButton and optionsButton then
		helpButton:SetSize(Metrics.BTN_W - 12, 26)
		helpButton:SetPoint("RIGHT", optionsButton, "LEFT", -HEADER_SPACING.BUTTON_GAP, 0)
		helpButton:SetText(t("HEADER_BUTTON_HELP"))
		helpButton:SetNormalFontObject(GameFontNormal)
		local fontString = helpButton:GetFontString()
		if fontString then
			fontString:SetTextColor(1.0, 0.82, 0.0)
		end
		helpButton:SetScript("OnClick", function()
			local ctx = self:GetContext()
			local message = t("HEADER_HELP_CHAT")
			if ctx and ctx.chatMessage then
				ctx.chatMessage("|cFF00FF00BookArchivist:|r " .. message)
			elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00BookArchivist:|r " .. message)
			end
		end)
		self:SetFrame("helpButton", helpButton)
	end

	-- Bottom: Random button and Resume button
	local bottomButtonsHost = headerRightBottom or headerRight

	-- Random Book button
	local randomButton = self:SafeCreateFrame("Button", nil, bottomButtonsHost)
	if randomButton then
		randomButton:SetSize(26, 26)
		
		-- Use dice icon texture (no button template background)
		local texture = randomButton:CreateTexture(nil, "ARTWORK")
		if texture then
			texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
			texture:SetAllPoints(randomButton)
		end
		
		-- Highlight texture for hover effect
		local highlight = randomButton:CreateTexture(nil, "HIGHLIGHT")
		if highlight then
			highlight:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")
			highlight:SetAllPoints(randomButton)
			highlight:SetBlendMode("ADD")
		end
		
		-- Position at left of bottom row
		randomButton:SetPoint("LEFT", bottomButtonsHost, "LEFT", 0, 0)
		
		randomButton:SetScript("OnClick", function()
			local RandomBook = BookArchivist and BookArchivist.RandomBook
			if not RandomBook or not RandomBook.OpenRandomBook then
				return
			end
			
			-- Open a random book with location context
			RandomBook:OpenRandomBook()
		end)
		
		randomButton:SetScript("OnEnter", function(self)
			if not GameTooltip then
				return
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(t("RANDOM_BOOK_TOOLTIP"))
			GameTooltip:Show()
		end)
		
		randomButton:SetScript("OnLeave", function()
			if GameTooltip then
				GameTooltip:Hide()
			end
		end)
		
		self:SetFrame("randomButton", randomButton)
	end

	local resumeButton = self:SafeCreateFrame("Button", nil, bottomButtonsHost, "UIPanelButtonTemplate")
	if resumeButton then
		resumeButton:SetHeight(26)
		resumeButton:SetText(t("RESUME_LAST_BOOK"))
		resumeButton:SetNormalFontObject(GameFontNormal)
		local fontString = resumeButton:GetFontString()
		if fontString then
			fontString:SetTextColor(1.0, 0.82, 0.0)
			fontString:SetWordWrap(false)
		end
		resumeButton:SetWidth(Metrics.BTN_W + 20)
		resumeButton:SetPoint("RIGHT", bottomButtonsHost, "RIGHT", 0, 0)
		resumeButton:SetScript("OnClick", function()
			local addon = self.GetAddon and self:GetAddon()
			if not addon or not addon.GetLastBookId then
				return
			end
			local lastId = addon:GetLastBookId()
			if not lastId then
				return
			end
			if self.SetSelectedKey then
				self:SetSelectedKey(lastId)
			end
			if self.NotifySelectionChanged then
				self:NotifySelectionChanged()
			end
		end)
		self:SetFrame("resumeButton", resumeButton)
		resumeButton:Hide()
	end

	local listBlock = uiFrame.listBlock or uiFrame.ListInset
	if not listBlock then
		listBlock = self:SafeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate3")
		local host = uiFrame.BodyFrame or uiFrame
		local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
		listBlock:SetPoint("TOPLEFT", host, "TOPLEFT", padInset, -padInset)
		listBlock:SetPoint("BOTTOMLEFT", host, "BOTTOMLEFT", padInset, padInset)
		listBlock:SetWidth(380)
		uiFrame.listBlock = listBlock
	end
	self:SetFrame("listBlock", listBlock)

	local listHeaderRow = self:EnsureListHeaderRow()
	local tipRow = self:EnsureListTipRow()
	local listScrollRow = self:EnsureListScrollRow()
	local tabParent = self:EnsureListTabParent(listHeaderRow)
	local tabsRail = tabParent and self:EnsureListTabsRail(tabParent)
	if tabParent and tabsRail then
		self:EnsureListTabs(tabParent, tabsRail)
		self:RefreshListTabsSelection()
	end

	local listHeader = self:EnsureListHeader()
	if listHeader then
		listHeader:Hide()
	end

	local listSeparator = self:GetFrame("listSeparator") or listScrollRow:CreateTexture(nil, "ARTWORK")
	listSeparator:ClearAllPoints()
	listSeparator:SetHeight(1)
	local inset = Metrics.PAD_INSET or Metrics.PAD or 8
	listSeparator:SetPoint("TOPLEFT", listScrollRow, "TOPLEFT", -(inset * 0.25), 0)
	listSeparator:SetPoint("TOPRIGHT", listScrollRow, "TOPRIGHT", inset, 0)
	listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)
	self:SetFrame("listSeparator", listSeparator)

	local scrollBox = CreateFrame("Frame", "BookArchivistListScrollBox", listScrollRow, "WowScrollBoxList")
	if not scrollBox then
		self:LogError("Unable to create list scroll box.")
		return
	end
	local gap = Metrics.GAP_S or Metrics.GAP_XS or 6
	local gutter = Metrics.SCROLLBAR_GUTTER or 18
	scrollBox:ClearAllPoints()
	scrollBox:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 0, -gap)
	scrollBox:SetPoint("BOTTOMRIGHT", listScrollRow, "BOTTOMRIGHT", -gutter, 0)
	self:SetFrame("scrollBox", scrollBox)

	local scrollBar = CreateFrame("EventFrame", "BookArchivistListScrollBar", listScrollRow, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 0, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 0, 0)
	self:SetFrame("scrollBar", scrollBar)

	-- Create the data provider and scroll view
	local dataProvider = CreateDataProvider()
	self:SetDataProvider(dataProvider)

	local scrollView = CreateScrollBoxListLinearView()
	self:SetScrollView(scrollView)

	-- Link components
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

	-- Configure scrollbar to auto-hide when not needed
	if scrollBar.SetHideIfUnscrollable then
		scrollBar:SetHideIfUnscrollable(true)
	end

	-- Define element initializer
	local function InitializeListElement(button, elementData)
		if not button or not elementData then
			return
		end

		button.bookKey = elementData.bookKey
		button.itemKind = elementData.itemKind
		button.locationName = elementData.locationName
		button.nodeRef = elementData.nodeRef

		if button.titleText then
			button.titleText:SetText(elementData.title or "")
		end
		if button.metaText then
			button.metaText:SetText(elementData.meta or "")
		end

		if elementData.isSelected then
			if button.selected then
				button.selected:Show()
			end
			if button.selectedEdge then
				button.selectedEdge:Show()
			end
		else
			if button.selected then
				button.selected:Hide()
			end
			if button.selectedEdge then
				button.selectedEdge:Hide()
			end
		end

		if button.favoriteStar then
			button.favoriteStar:SetShown(elementData.isFavorite or false)
		end

		-- Sync match badges (handles text, positioning, and visibility)
		local hasBadges = false
		if elementData.bookKey and (elementData.showTitleBadge or elementData.showTextBadge) then
			local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
			if ListUI and ListUI.SyncMatchBadges then
				ListUI:SyncMatchBadges(button, elementData.bookKey)
				hasBadges = true
			end
		else
			-- Hide badges if no match
			if button.badgeTitle then
				button.badgeTitle:Hide()
			end
			if button.badgeText then
				button.badgeText:Hide()
			end
		end

		-- Adjust row content anchors based on badge visibility
		local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
		if ListUI and ListUI.SetRowContentAnchors then
			ListUI:SetRowContentAnchors(button, hasBadges)
		end

		-- Set up click handler
		button:SetScript("OnClick", function(btn, mouseButton)
			if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
			end
			local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
			if ListUI and ListUI.HandleRowClick then
				ListUI:HandleRowClick(btn, mouseButton)
			end
		end)
	end

	-- Set element factory BEFORE setting data provider
	local rowHeight = self:GetRowHeight()
	scrollView:SetElementExtent(rowHeight)

	local function ElementInitializer(button, elementData)
		-- Initialize the button structure on first creation only
		if not button.titleText then
			self:CreateRowButtonStructure(button, rowHeight)
		end
		InitializeListElement(button, elementData)
	end

	scrollView:SetElementInitializer("Button", ElementInitializer)

	-- NOW set the data provider after factory is configured
	scrollView:SetDataProvider(dataProvider)

	self:SetFrame("scrollFrame", scrollBox) -- For backward compatibility

	-- Initialize FramePool for list rows now that scrollBox exists
	local FramePool = BookArchivist.UI and BookArchivist.UI.FramePool
	if FramePool and not FramePool:PoolExists("listRows") then
		FramePool:CreatePool("listRows", "Button", scrollBox, nil)

		-- Set custom reset function that matches our row structure
		FramePool:SetResetFunction("listRows", function(button)
			button:Hide()
			button:ClearAllPoints()
			button.bookKey = nil
			button.itemKind = nil
			button.locationName = nil
			button.nodeRef = nil
			if button.titleText then
				button.titleText:SetText("")
			end
			if button.metaText then
				button.metaText:SetText("")
			end
			if button.selected then
				button.selected:Hide()
			end
			if button.selectedEdge then
				button.selectedEdge:Hide()
			end
			if button.favoriteStar then
				button.favoriteStar:Hide()
			end
			if button.badgeTitle then
				button.badgeTitle:Hide()
			end
			if button.badgeText then
				button.badgeText:Hide()
			end
		end)
	end

	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-scroll", scrollBox)
	end

	local noResults = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	noResults:SetPoint("CENTER", scrollBox, "CENTER", 0, 0)
	noResults:SetText("|cFF999999" .. t("LIST_EMPTY_SEARCH") .. "|r")
	noResults:Hide()
	self:SetFrame("noResultsText", noResults)

	self:UpdateSearchClearButton()
	self:UpdateSortDropdown()
	self:UpdateCountsDisplay()
	if self.UpdateResumeButton then
		self:UpdateResumeButton()
	end
	if self.UpdateRandomButton then
		self:UpdateRandomButton()
	end
	self:DebugPrint("[BookArchivist] ListUI created")
end

function ListUI:UpdateListModeUI()
	local mode = self:GetListMode()
	local modes = self:GetListModes()

	local listHeader = self:GetFrame("listHeader")
	if listHeader then
		listHeader:Hide()
	end

	local listSeparator = self:GetFrame("listSeparator")
	local listScrollRow = self:GetFrame("listScrollRow") or self:GetFrame("listBlock")
	if hasMethod(listSeparator, "ClearAllPoints") and hasMethod(listSeparator, "SetPoint") and listScrollRow then
		listSeparator:ClearAllPoints()
		local inset = Metrics.PAD_INSET or Metrics.PAD or 8
		listSeparator:SetPoint("TOPLEFT", listScrollRow, "TOPLEFT", -(inset * 0.25), 0)
		listSeparator:SetPoint("TOPRIGHT", listScrollRow, "TOPRIGHT", inset, 0)
	end

	self:RefreshListTabsSelection()

	if self.UpdateCountsDisplay then
		self:UpdateCountsDisplay()
	end

	-- Update breadcrumb display for location mode
	if self.UpdateLocationBreadcrumbUI then
		self:UpdateLocationBreadcrumbUI()
	end

	-- Re-anchor scroll row based on breadcrumb visibility
	if self.UpdateListScrollRowAnchors then
		self:UpdateListScrollRowAnchors()
	end
end
