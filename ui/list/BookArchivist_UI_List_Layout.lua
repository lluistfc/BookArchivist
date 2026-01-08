---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {
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
  local gap = Metrics.LIST_SCROLL_GAP or 0 -- zero gap so tabs sit directly on the separator line
  local inset = Metrics.PAD_INSET or Metrics.PAD or 8
  ClearAnchors(row)
  row:SetPoint("TOPLEFT", self:EnsureListHeaderRow(), "BOTTOMLEFT", 0, -gap)
  row:SetPoint("TOPRIGHT", self:EnsureListHeaderRow(), "BOTTOMRIGHT", 0, -gap)
  row:SetPoint("BOTTOMLEFT", tipRow, "TOPLEFT", 0, gap * -1)
  row:SetPoint("BOTTOMRIGHT", tipRow, "TOPRIGHT", 0, gap * -1)
  self:SetFrame("listScrollRow", row)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-scroll-row", row)
  end
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
    header:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", Metrics.PAD_OUTER or Metrics.PAD, -(Metrics.PAD_OUTER or Metrics.PAD))
    header:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -(Metrics.PAD_OUTER or Metrics.PAD), -(Metrics.PAD_OUTER or Metrics.PAD))
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

  local titleHost = headerLeftTop or headerLeft
  local titleText
  if titleHost and titleHost.CreateFontString then
    titleText = titleHost:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
  end
  if titleText then
    titleText:SetPoint("TOPLEFT", titleHost, "TOPLEFT", 0, 0)
    titleText:SetPoint("BOTTOMRIGHT", titleHost, "BOTTOMRIGHT", 0, 0)
    titleText:SetJustifyH("LEFT")
    titleText:SetJustifyV("MIDDLE")
	    titleText:SetText(t("ADDON_TITLE"))
    self:SetFrame("headerTitle", titleText)
  else
    self:LogError("Unable to create header title text (HeaderLeftTop missing?)")
  end

  local countHost = headerLeftBottom or headerLeft
  local headerCount
  if countHost and countHost.CreateFontString then
    headerCount = countHost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  end
  if headerCount then
    headerCount:SetPoint("TOPLEFT", countHost, "TOPLEFT", 0, 0)
    headerCount:SetPoint("BOTTOMRIGHT", countHost, "BOTTOMRIGHT", 0, 0)
    headerCount:SetJustifyH("LEFT")
    headerCount:SetJustifyV("MIDDLE")
	    headerCount:SetText(t("BOOK_LIST_SUBHEADER"))
    self:SetFrame("headerCountText", headerCount)
  else
    self:LogError("Unable to create header count text (HeaderLeftBottom missing?)")
  end

  local searchHost = headerCenterBottom or headerCenter
  local searchBox = self:SafeCreateFrame("EditBox", "BookArchivistSearchBox", searchHost, "SearchBoxTemplate")
  if searchBox then
    self:SetFrame("searchBox", searchBox)
    searchBox:SetHeight((Metrics.BTN_H or 22) + (Metrics.GAP_S or 0))
    searchBox:SetPoint("TOPLEFT", searchHost, "TOPLEFT", 0, Metrics.HEADER_CENTER_BIAS_Y or 0)

    -- Constrain the search box so it leaves room for the sort
    -- dropdown + resume button on the right, avoiding overlap.
    if headerRightBottom then
      local gap = Metrics.GAP_M or Metrics.GUTTER or 8
      local extra = 32 -- leave room before the sort dropdown
      searchBox:SetPoint("RIGHT", headerRightBottom, "LEFT", -(gap + extra), Metrics.HEADER_CENTER_BIAS_Y or 0)
    else
      searchBox:SetPoint("BOTTOMRIGHT", searchHost, "BOTTOMRIGHT", 0, Metrics.HEADER_CENTER_BIAS_Y or 0)
    end
    searchBox:SetAutoFocus(false)
    searchBox:SetJustifyH("LEFT")
    if self.WireSearchBox then
      self:WireSearchBox(searchBox)
    end
  end

  local clearButton = self:SafeCreateFrame("Button", nil, searchHost, "UIPanelCloseButton")
  if clearButton and searchBox then
    clearButton:SetScale(0.7)
    clearButton:SetPoint("LEFT", searchBox, "RIGHT", -(Metrics.GAP_XS or 4), 0)
    clearButton:SetScript("OnClick", function()
      searchBox:SetText("")
      self:RunSearchRefresh()
      self:UpdateSearchClearButton()
    end)
    self:SetFrame("searchClearButton", clearButton)
    clearButton:Hide()
  end

  local optionsButton = self:SafeCreateFrame("Button", nil, headerRightTop, "UIPanelButtonTemplate")
  if optionsButton then
    optionsButton:SetSize(Metrics.BTN_W, 26)
    optionsButton:SetPoint("TOPRIGHT", headerRightTop, "TOPRIGHT", 0, 0)
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

  local helpButton = self:SafeCreateFrame("Button", nil, headerRightTop, "UIPanelButtonTemplate")
  if helpButton and optionsButton then
    helpButton:SetSize(Metrics.BTN_W - 12, 26)
    helpButton:SetPoint("RIGHT", optionsButton, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER), 0)
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

  local resumeButton = self:SafeCreateFrame("Button", nil, headerRightBottom, "UIPanelButtonTemplate")
  if resumeButton then
    resumeButton:SetSize(Metrics.BTN_W, 26)
    resumeButton:SetPoint("RIGHT", headerRightBottom, "RIGHT", 0, 0)
    resumeButton:SetText(t("RESUME_LAST_BOOK"))
    resumeButton:SetNormalFontObject(GameFontNormal)
    local fontString = resumeButton:GetFontString()
    if fontString then
      fontString:SetTextColor(1.0, 0.82, 0.0)
    end
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

  local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", headerRightBottom, "UIDropDownMenuTemplate")
  sortDropdown:ClearAllPoints()
  local resumeBtn = self:GetFrame("resumeButton")
  if resumeBtn then
    sortDropdown:SetPoint("RIGHT", resumeBtn, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER or 6), 0)
  else
    sortDropdown:SetPoint("RIGHT", headerRightBottom, "RIGHT", 0, 0)
  end
  sortDropdown:SetPoint("CENTER", headerRightBottom, "CENTER", 0, 0)
  self:InitializeSortDropdown(sortDropdown)

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
  
  -- Define element initializer
  local function InitializeListElement(button, elementData)
    if not button or not elementData then return end
    
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
      if button.selected then button.selected:Show() end
      if button.selectedEdge then button.selectedEdge:Show() end
    else
      if button.selected then button.selected:Hide() end
      if button.selectedEdge then button.selectedEdge:Hide() end
    end
    
    if button.favoriteStar then
      button.favoriteStar:SetShown(elementData.isFavorite or false)
    end
    
    if button.badgeTitle then
      button.badgeTitle:SetShown(elementData.showTitleBadge or false)
    end
    if button.badgeText then
      button.badgeText:SetShown(elementData.showTextBadge or false)
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
  
  self:SetFrame("scrollFrame", scrollBox)  -- For backward compatibility
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
end
