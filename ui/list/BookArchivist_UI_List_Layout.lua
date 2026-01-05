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

  -- Virtual category selector (All / Favorites) anchored in the tip row,
  -- to the left of the pagination controls.
  if paginationFrame and self.IsVirtualCategoriesEnabled and self:IsVirtualCategoriesEnabled() then
    local dropdown = CreateFrame and CreateFrame("Frame", "BookArchivistCategoryDropdown", tipRow, "UIDropDownMenuTemplate")
    if dropdown then
      dropdown:ClearAllPoints()
      dropdown:SetPoint("RIGHT", paginationFrame, "LEFT", -(Metrics.GAP_S or Metrics.GAP_XS or 4), 0)
      UIDropDownMenu_SetWidth(dropdown, 140)
      UIDropDownMenu_JustifyText(dropdown, "LEFT")
      UIDropDownMenu_Initialize(dropdown, function(frame, level)
        local function addCategory(id, labelKey)
          local info = UIDropDownMenu_CreateInfo()
          info.text = t(labelKey)
          info.value = id
          info.func = function()
            self:SetCategoryId(id)
          end
          info.checked = (self:GetCategoryId() == id)
          UIDropDownMenu_AddButton(info, level)
        end
        addCategory("__all__", "CATEGORY_ALL")
        addCategory("__favorites__", "CATEGORY_FAVORITES")
      end)

      -- Keep initial label in sync with persisted category.
      local currentId = self:GetCategoryId()
      local currentLabelKey = (currentId == "__favorites__") and "CATEGORY_FAVORITES" or "CATEGORY_ALL"
      UIDropDownMenu_SetText(dropdown, t(currentLabelKey))

      self:SetFrame("categoryDropdown", dropdown)
    end
  end
  return info
end

function ListUI:EnsurePaginationControls()
  local pagination = self:GetFrame("paginationFrame")
  if pagination then
    return pagination
  end

  local tipRow = self:EnsureListTipRow()
  if not tipRow then
    return nil
  end

  pagination = self:SafeCreateFrame("Frame", nil, tipRow)
  if not pagination then
    return nil
  end
	pagination:ClearAllPoints()
	pagination:SetPoint("CENTER", tipRow, "CENTER", 0, 0)
  pagination:SetWidth(320)
  local gap = Metrics.GAP_S or Metrics.GAP_XS or 4
  local btnH = Metrics.BTN_H or 22
  pagination:SetHeight((btnH * 2) + gap)
  self:SetFrame("paginationFrame", pagination)

  local gap = Metrics.GAP_S or Metrics.GAP_XS or 4
  local btnH = Metrics.BTN_H or 22

  local topRow = self:SafeCreateFrame("Frame", nil, pagination)
  if topRow then
    topRow:SetPoint("TOPLEFT", pagination, "TOPLEFT", 0, 0)
    topRow:SetPoint("TOPRIGHT", pagination, "TOPRIGHT", 0, 0)
    topRow:SetHeight(btnH)
  end

  local bottomRow = self:SafeCreateFrame("Frame", nil, pagination)
  if bottomRow then
    if topRow then
      bottomRow:SetPoint("TOPLEFT", topRow, "BOTTOMLEFT", 0, -gap)
      bottomRow:SetPoint("TOPRIGHT", topRow, "BOTTOMRIGHT", 0, -gap)
    else
      bottomRow:SetPoint("TOPLEFT", pagination, "TOPLEFT", 0, 0)
      bottomRow:SetPoint("TOPRIGHT", pagination, "TOPRIGHT", 0, 0)
    end
    bottomRow:SetPoint("BOTTOMLEFT", pagination, "BOTTOMLEFT", 0, 0)
    bottomRow:SetPoint("BOTTOMRIGHT", pagination, "BOTTOMRIGHT", 0, 0)
    bottomRow:SetHeight(btnH)
  end

  local prev = self:SafeCreateFrame("Button", "BookArchivistListPrevPage", bottomRow or pagination, "UIPanelButtonTemplate")
  if prev then
    prev:SetSize(60, btnH)
	    prev:SetText(t("PAGINATION_PREV"))
    prev:SetScript("OnClick", function()
      self:PrevPage()
    end)
    self:SetFrame("pagePrevButton", prev)
  end

  local nextBtn = self:SafeCreateFrame("Button", "BookArchivistListNextPage", bottomRow or pagination, "UIPanelButtonTemplate")
  if nextBtn then
    nextBtn:SetSize(60, btnH)
	    nextBtn:SetText(t("PAGINATION_NEXT"))
    nextBtn:SetScript("OnClick", function()
      self:NextPage()
    end)
    self:SetFrame("pageNextButton", nextBtn)
  end

  local pageLabelHost = bottomRow or pagination
  local pageLabel = pageLabelHost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageLabel:SetJustifyH("CENTER")
  pageLabel:SetJustifyV("MIDDLE")
  pageLabel:SetHeight(btnH)
	pageLabel:SetText(t("PAGINATION_PAGE_SINGLE"))
  if prev and nextBtn then
    pageLabel:ClearAllPoints()
    pageLabel:SetPoint("CENTER", pageLabelHost, "CENTER", 0, 0)
    prev:ClearAllPoints()
    prev:SetPoint("RIGHT", pageLabel, "LEFT", -gap, 0)
    nextBtn:ClearAllPoints()
    nextBtn:SetPoint("LEFT", pageLabel, "RIGHT", gap, 0)
  else
    pageLabel:SetPoint("CENTER", pageLabelHost, "CENTER", 0, 0)
  end
  self:SetFrame("pageLabel", pageLabel)

  local dropdownHost = topRow or pagination
  local dropdown = CreateFrame and CreateFrame("Frame", "BookArchivistPageSizeDropdown", dropdownHost, "UIDropDownMenuTemplate")
  if dropdown then
    dropdown:ClearAllPoints()
    dropdown:SetPoint("CENTER", dropdownHost, "CENTER", 0, 0)
    UIDropDownMenu_SetWidth(dropdown, 110)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
	    UIDropDownMenu_SetText(dropdown, string.format(t("PAGINATION_PAGE_SIZE_FORMAT"), self:GetPageSize()))
    UIDropDownMenu_Initialize(dropdown, function(frame, level)
      for _, size in ipairs(self:GetPageSizes()) do
        local info = UIDropDownMenu_CreateInfo()
	        info.text = string.format(t("PAGINATION_PAGE_SIZE_FORMAT"), size)
        info.func = function()
          self:SetPageSize(size)
        end
        info.checked = (size == self:GetPageSize())
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    self:SetFrame("pageSizeDropdown", dropdown)
  end

  return pagination
end

local function wireSearchHandlers(self, searchBox)
  if not (self and searchBox) then
    return
  end

  local instructions = searchBox.Instructions
  if instructions and instructions.SetText then
		instructions:SetText(t("BOOK_SEARCH_PLACEHOLDER"))
  end

  local function syncInstructions(box)
    if not instructions then
      return
    end
    if (box:GetText() or "") == "" then
      instructions:Show()
    else
      instructions:Hide()
    end
  end

  searchBox:SetScript("OnEditFocusGained", function(box)
    if instructions then
      instructions:Hide()
    end
  end)

  searchBox:SetScript("OnEditFocusLost", function(box)
    syncInstructions(box)
  end)

  searchBox:SetScript("OnEscapePressed", function(box)
    box:SetText("")
    box:ClearFocus()
    syncInstructions(box)
    self:RunSearchRefresh()
    self:UpdateSearchClearButton()
  end)

  searchBox:SetScript("OnEnterPressed", function(box)
    box:ClearFocus()
  end)

  searchBox:SetScript("OnTextChanged", function(box, userInput)
    syncInstructions(box)
    if userInput then
      if self.ScheduleSearchRefresh then
        self:ScheduleSearchRefresh()
      else
        self:RunSearchRefresh()
      end
      self:UpdateSearchClearButton()
    end
  end)

  syncInstructions(searchBox)
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
    searchBox:SetPoint("BOTTOMRIGHT", searchHost, "BOTTOMRIGHT", 0, Metrics.HEADER_CENTER_BIAS_Y or 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetJustifyH("LEFT")
    wireSearchHandlers(self, searchBox)
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
    optionsButton:SetSize(Metrics.BTN_W, Metrics.BTN_H)
    optionsButton:SetPoint("TOPRIGHT", headerRightTop, "TOPRIGHT", 0, 0)
	    optionsButton:SetText(t("HEADER_BUTTON_OPTIONS"))
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
    helpButton:SetSize(Metrics.BTN_W - 12, Metrics.BTN_H)
    helpButton:SetPoint("RIGHT", optionsButton, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER), 0)
	    helpButton:SetText(t("HEADER_BUTTON_HELP"))
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

  local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", headerRightBottom, "UIDropDownMenuTemplate")
  sortDropdown:ClearAllPoints()
  sortDropdown:SetPoint("RIGHT", headerRightBottom, "RIGHT", 0, 0)
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

  local scrollFrame = self:SafeCreateFrame("ScrollFrame", "BookArchivistListScroll", listScrollRow, "UIPanelScrollFrameTemplate")
  if not scrollFrame then
    self:LogError("Unable to create list scroll frame.")
    return
  end
  local gap = Metrics.GAP_S or Metrics.GAP_XS or 6
  local gutter = Metrics.SCROLLBAR_GUTTER or 18
  scrollFrame:ClearAllPoints()
  scrollFrame:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 0, -gap)
  scrollFrame:SetPoint("BOTTOMRIGHT", listScrollRow, "BOTTOMRIGHT", -gutter, 0)
  self:SetFrame("scrollFrame", scrollFrame)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-scroll", scrollFrame)
  end

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(336, 1)
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
  scrollFrame:SetScrollChild(scrollChild)
  self:SetFrame("scrollChild", scrollChild)

  local noResults = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  noResults:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
	noResults:SetText("|cFF999999" .. t("LIST_EMPTY_SEARCH") .. "|r")
  noResults:Hide()
  self:SetFrame("noResultsText", noResults)

  local rowHeight = self:GetRowHeight()
  scrollFrame:SetScript("OnMouseWheel", function(frame, delta)
    local current = frame:GetVerticalScroll()
    local maxScroll = frame:GetVerticalScrollRange()
    local newScroll = math.max(0, math.min(maxScroll, current - (delta * rowHeight * 3)))
    frame:SetVerticalScroll(newScroll)
  end)

  self:UpdateSearchClearButton()
  self:UpdateSortDropdown()
  self:UpdateCountsDisplay()
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
