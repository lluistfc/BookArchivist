---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {
  PAD = 12,
  GUTTER = 10,
  HEADER_H = 72,
  BTN_H = 22,
  BTN_W = 100,
  ROW_H = 36,
  LIST_HEADER_H = 34,
  LIST_TOPBAR_H = 28,
  PAD_OUTER = 12,
  PAD_INSET = 10,
  GAP_XS = 4,
  GAP_S = 6,
  GAP_M = 10,
  GAP_L = 14,
  HEADER_RIGHT_STACK_W = 120,
  HEADER_RIGHT_GUTTER = 12,
  SCROLLBAR_GUTTER = 18,
}

local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal

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
  local gap = Metrics.GAP_XS or 4
  row:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -gap)
  row:SetPoint("TOPRIGHT", headerRow, "BOTTOMRIGHT", 0, -gap)
  row:SetHeight(Metrics.LIST_TIP_H or (Metrics.LIST_INFO_H or 18))
  self:SetFrame("listTipRow", row)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-tip-row", row)
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
  header:SetText("Saved Books")
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
  info = tipRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  info:SetJustifyH("LEFT")
  info:SetJustifyV("MIDDLE")
  info:SetText("")
  info:SetPoint("TOPLEFT", tipRow, "TOPLEFT", 0, 0)
  info:SetPoint("BOTTOMRIGHT", tipRow, "BOTTOMRIGHT", 0, 0)
  self:SetFrame("infoText", info)
  return info
end

local function wireSearchHandlers(self, searchBox)
  if not (self and searchBox) then
    return
  end

  local instructions = searchBox.Instructions
  if instructions and instructions.SetText then
    instructions:SetText("Search title or text…")
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
  local headerRightTop = uiFrame.HeaderRightTop or headerRight
  local headerRightBottom = uiFrame.HeaderRightBottom or headerRight

  local titleText = headerLeft:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
  titleText:SetPoint("TOPLEFT", headerLeft, "TOPLEFT", 0, 0)
  titleText:SetPoint("TOPRIGHT", headerLeft, "TOPRIGHT", 0, 0)
  titleText:SetJustifyH("LEFT")
  titleText:SetJustifyV("TOP")
  titleText:SetText("Book Archivist")
  self:SetFrame("headerTitle", titleText)

  local headerCount = headerLeft:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerCount:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -(Metrics.GAP_XS or 4))
  headerCount:SetPoint("RIGHT", headerLeft, "RIGHT", 0, 0)
  headerCount:SetJustifyH("LEFT")
  headerCount:SetJustifyV("TOP")
  headerCount:SetText("Saving every page you read")
  self:SetFrame("headerCountText", headerCount)

  local searchBox = self:SafeCreateFrame("EditBox", "BookArchivistSearchBox", headerCenter, "SearchBoxTemplate")
  if searchBox then
    self:SetFrame("searchBox", searchBox)
    searchBox:SetHeight((Metrics.BTN_H or 22) + (Metrics.GAP_S or 0))
    searchBox:SetPoint("CENTER", headerCenter, "CENTER", 0, Metrics.HEADER_CENTER_BIAS_Y or 0)
    searchBox:SetPoint("LEFT", headerCenter, "LEFT", 0, 0)
    searchBox:SetPoint("RIGHT", headerCenter, "RIGHT", 0, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetJustifyH("LEFT")
    wireSearchHandlers(self, searchBox)
  end

  local clearButton = self:SafeCreateFrame("Button", nil, headerCenter, "UIPanelCloseButton")
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
    optionsButton:SetText("Options")
    optionsButton:SetScript("OnClick", function()
      local addon = self:GetAddon()
      if addon and addon.OpenOptionsPanel then
        addon:OpenOptionsPanel()
      elseif BookArchivist and BookArchivist.OpenOptionsPanel then
        BookArchivist:OpenOptionsPanel()
      end
    end)
  end

  local helpButton = self:SafeCreateFrame("Button", nil, headerRightTop, "UIPanelButtonTemplate")
  if helpButton and optionsButton then
    helpButton:SetSize(Metrics.BTN_W - 12, Metrics.BTN_H)
    helpButton:SetPoint("RIGHT", optionsButton, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER), 0)
    helpButton:SetText("Help")
    helpButton:SetScript("OnClick", function()
      local ctx = self:GetContext()
      local message = "Use the search, filters, and sort menu to find any saved book instantly."
      if ctx and ctx.chatMessage then
        ctx.chatMessage("|cFF00FF00BookArchivist:|r " .. message)
      elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00BookArchivist:|r " .. message)
      end
    end)
  end

  local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", headerRightBottom, "UIDropDownMenuTemplate")
  sortDropdown:ClearAllPoints()
  sortDropdown:SetPoint("RIGHT", headerRightBottom, "RIGHT", 0, 0)
  sortDropdown:SetPoint("CENTER", headerRightBottom, "CENTER", 0, 0)
  self:InitializeSortDropdown(sortDropdown)
  headerCount:SetPoint("RIGHT", sortDropdown, "LEFT", -(Metrics.GAP_L or Metrics.GAP_M or (Metrics.GUTTER or 10)), 0)

  local filterContainer = CreateFrame("Frame", nil, headerRightBottom)
  filterContainer:SetPoint("LEFT", headerRightBottom, "LEFT", 0, 0)
  filterContainer:SetPoint("RIGHT", sortDropdown, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER * 0.5), 0)
  filterContainer:SetPoint("TOP", headerRightBottom, "TOP", 0, 0)
  filterContainer:SetPoint("BOTTOM", headerRightBottom, "BOTTOM", 0, 0)
  filterContainer:SetHeight(Metrics.BTN_H)
  self:SetFrame("filterContainer", filterContainer)
  local lastButton
  for _, def in ipairs(self:GetQuickFilters()) do
    local button = CreateFrame("Button", nil, filterContainer)
    button:SetSize(Metrics.BTN_H, Metrics.BTN_H)
    if lastButton then
      button:SetPoint("RIGHT", lastButton, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER * 0.5), 0)
    else
      button:SetPoint("RIGHT", filterContainer, "RIGHT", 0, 0)
    end
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints(true)
    button.bg:SetColorTexture(0, 0, 0, 0.35)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(true)
    button.icon:SetTexture(def.icon)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button:SetScript("OnClick", function()
      if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
      end
      self:ToggleFilter(def.key)
    end)
    button:SetScript("OnEnter", function(btn)
      if GameTooltip then
        GameTooltip:SetOwner(btn, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(def.tooltip or "Toggle filter", 1, 0.82, 0)
      end
    end)
    button:SetScript("OnLeave", function()
      if GameTooltip then
        GameTooltip:Hide()
      end
    end)
    self:SetFilterButton(def.key, button)
    lastButton = button
  end
  self:UpdateFilterButtons()

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
  local tabsRail = self:GetFrame("listTabsRail")
  if not tabsRail then
    tabsRail = self:SafeCreateFrame("Frame", nil, listHeaderRow)
    tabsRail:SetPoint("RIGHT", listHeaderRow, "RIGHT", -((Metrics.PAD_INSET or Metrics.PAD) + (Metrics.GAP_S or 6)), 0)
    tabsRail:SetPoint("BOTTOM", listHeaderRow, "BOTTOM", 0, 0)
    tabsRail:SetHeight(Metrics.LIST_HEADER_H)
    tabsRail:SetWidth((Metrics.BTN_W * 2) + (Metrics.GAP_S or Metrics.GUTTER))
    self:SetFrame("listTabsRail", tabsRail)
    if Internal and Internal.registerGridTarget then
      Internal.registerGridTarget("list-tabs-rail", tabsRail)
    end
  end

  local locationsModeButton = self:SafeCreateFrame("Button", nil, tabsRail, "UIPanelButtonTemplate")
  if locationsModeButton then
    locationsModeButton:SetSize(Metrics.BTN_W, Metrics.BTN_H)
    locationsModeButton:SetPoint("RIGHT", tabsRail, "RIGHT", 0, 0)
    locationsModeButton:SetText("Locations")
    locationsModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.LOCATIONS)
    end)
    self:SetFrame("locationsModeButton", locationsModeButton)
  end

  local booksModeButton = self:SafeCreateFrame("Button", nil, tabsRail, "UIPanelButtonTemplate")
  if booksModeButton then
    booksModeButton:SetSize(Metrics.BTN_W - 12, Metrics.BTN_H)
    if locationsModeButton then
      booksModeButton:SetPoint("RIGHT", locationsModeButton, "LEFT", -(Metrics.GAP_S or Metrics.GUTTER * 0.5), 0)
    else
      booksModeButton:SetPoint("RIGHT", tabsRail, "RIGHT", 0, 0)
    end
    booksModeButton:SetText("Books")
    booksModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.BOOKS)
    end)
    self:SetFrame("booksModeButton", booksModeButton)
  end

  local listHeader = self:EnsureListHeader()
  if listHeader and tabsRail then
    listHeader:ClearAllPoints()
    listHeader:SetPoint("LEFT", listHeaderRow, "LEFT", 0, 0)
    listHeader:SetPoint("RIGHT", tabsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
  end

  local tipRow = self:EnsureListTipRow()
  self:EnsureInfoText()

  local listSeparator = listBlock:CreateTexture(nil, "ARTWORK")
  listSeparator:SetHeight(1)
  local inset = Metrics.PAD_INSET or Metrics.PAD or 8
  listSeparator:SetPoint("TOPLEFT", tipRow or listHeaderRow, "BOTTOMLEFT", -(inset * 0.25), -(Metrics.GAP_XS or 4))
  listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -inset, -inset)
  listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)
  self:SetFrame("listSeparator", listSeparator)

  local scrollFrame = self:SafeCreateFrame("ScrollFrame", "BookArchivistListScroll", listBlock, "UIPanelScrollFrameTemplate")
  if not scrollFrame then
    self:LogError("Unable to create list scroll frame.")
    return
  end
  local scrollAnchor = listSeparator or tipRow or listHeaderRow
  scrollFrame:SetPoint("TOPLEFT", scrollAnchor, "BOTTOMLEFT", 0, -(Metrics.GAP_M or Metrics.GUTTER))
  scrollFrame:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -(Metrics.PAD_INSET or Metrics.PAD), Metrics.PAD_INSET or Metrics.PAD)
  self:SetFrame("scrollFrame", scrollFrame)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-scroll", scrollFrame)
  end

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(336, 1)
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -(Metrics.SCROLLBAR_GUTTER or 18), 0)
  scrollFrame:SetScrollChild(scrollChild)
  self:SetFrame("scrollChild", scrollChild)

  local noResults = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  noResults:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
  noResults:SetText("|cFF999999No matches. Clear filters or search.|r")
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

  local listHeader = self:EnsureListHeader()
  if listHeader and hasMethod(listHeader, "SetText") then
    if mode == modes.BOOKS then
      listHeader:SetText("Saved Books")
    else
      listHeader:SetText("Browse by Location")
    end
  end

  local listSeparator = self:GetFrame("listSeparator")
  local listBlock = self:GetFrame("listBlock")
  if hasMethod(listSeparator, "ClearAllPoints") and hasMethod(listSeparator, "SetPoint") and listBlock then
    listSeparator:ClearAllPoints()
    local inset = Metrics.PAD_INSET or Metrics.PAD or 8
    listSeparator:SetPoint("TOPLEFT", self:GetFrame("listTipRow") or listHeader or listBlock, "BOTTOMLEFT", -(inset * 0.25), -(Metrics.GAP_XS or 4))
    listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -inset, -inset)
  end

  local booksModeButton = self:GetFrame("booksModeButton")
  local locationsModeButton = self:GetFrame("locationsModeButton")
  if hasMethod(booksModeButton, "SetEnabled") and hasMethod(locationsModeButton, "SetEnabled") then
    booksModeButton:SetEnabled(mode ~= modes.BOOKS)
    locationsModeButton:SetEnabled(mode ~= modes.LOCATIONS)
  end

  if self.UpdateCountsDisplay then
    self:UpdateCountsDisplay()
  end
end
