---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist.UI.Metrics or {
  PAD = 12,
  GUTTER = 10,
  HEADER_H = 70,
  SUBHEADER_H = 34,
  READER_HEADER_H = 54,
  ROW_H = 36,
  BTN_H = 22,
  BTN_W = 90,
}
local Internal = BookArchivist.UI.Internal

local function hasMethod(obj, methodName)
  return obj and type(obj[methodName]) == "function"
end

local function wireSearchHandlers(listUI, box)
  if not box then
    return
  end

  if box.Instructions then
    box.Instructions:SetText("Search title, author, or text…")
  end

  box:SetScript("OnTextChanged", function(input)
    if input.Instructions then
      if input:GetText() ~= "" then
        input.Instructions:Hide()
      else
        input.Instructions:Show()
      end
    end
    listUI:UpdateSearchClearButton()
    listUI:ScheduleSearchRefresh()
    listUI:DebugPrint("[BookArchivist] search text changed; scheduled refresh")
  end)

  box:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  box:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
    listUI:RunSearchRefresh()
  end)
end

function ListUI:EnsureInfoText()
  local info = self:GetFrame("infoText")
  if info and info.GetObjectType and info:GetObjectType() == "FontString" then
    info:Show()
    return info
  end

  local listBlock = self:GetFrame("listBlock")
  if not hasMethod(listBlock, "CreateFontString") then
    return nil
  end

  info = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  if hasMethod(info, "SetPoint") then
    info:SetPoint("BOTTOM", listBlock, "BOTTOM", 0, Metrics.PAD)
  end
  if hasMethod(info, "SetText") then
    info:SetText("|cFF00FF00Tip:|r Open books normally - pages save automatically")
  end
  self:SetFrame("infoText", info)
  return info
end

function ListUI:EnsureListHeader()
  local listHeader = self:GetFrame("listHeader")
  if listHeader and hasMethod(listHeader, "SetText") then
    return listHeader
  end

  local row = self:GetFrame("listHeaderRow")
  if not row then
    row = self:EnsureListHeaderRow()
  end
  if not row or not hasMethod(row, "CreateFontString") then
    return nil
  end

  listHeader = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  if listHeader and hasMethod(listHeader, "SetPoint") then
    listHeader:SetPoint("LEFT", row, "LEFT", 0, 0)
    local tabsAnchor = self:GetFrame("listHeaderTabsAnchor")
    if tabsAnchor then
      listHeader:SetPoint("RIGHT", tabsAnchor, "LEFT", -Metrics.GUTTER, 0)
    else
      listHeader:SetPoint("RIGHT", row, "RIGHT", -Metrics.PAD, 0)
    end
  end
  if listHeader and hasMethod(listHeader, "SetJustifyV") then
    listHeader:SetJustifyV("MIDDLE")
  end
  if listHeader and hasMethod(listHeader, "SetText") then
    listHeader:SetText("Saved Books")
  end
  return self:SetFrame("listHeader", listHeader)
end

function ListUI:EnsureListHeaderRow()
  local row = self:GetFrame("listHeaderRow")
  if row and hasMethod(row, "SetHeight") then
    return row
  end

  local listBlock = self:GetFrame("listBlock")
  if not listBlock or not self.SafeCreateFrame then
    return nil
  end

  row = self:SafeCreateFrame("Frame", nil, listBlock)
  if not row then
    return nil
  end

  row:SetPoint("TOPLEFT", listBlock, "TOPLEFT", Metrics.PAD, -Metrics.PAD)
  row:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -Metrics.PAD, -Metrics.PAD)
  row:SetHeight(Metrics.SUBHEADER_H)
  self:SetFrame("listHeaderRow", row)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-header", row)
  end
  return row
end

function ListUI:GetListBlock()
  return self:GetFrame("listBlock")
end

function ListUI:Create(uiFrame)
  if not uiFrame then
    return
  end

  self:SetUIFrame(uiFrame)

  local header = uiFrame.HeaderFrame
  if not header then
    header = self:SafeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate3")
    header:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", Metrics.PAD, -Metrics.PAD)
    header:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -Metrics.PAD, -Metrics.PAD)
    header:SetHeight(Metrics.HEADER_H)
    uiFrame.HeaderFrame = header
  end
  local headerRow1 = uiFrame.HeaderRow1 or header
  local headerRow2 = uiFrame.HeaderRow2 or header

  local titleText = headerRow1:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
  titleText:SetPoint("LEFT", headerRow1, "LEFT", 0, 0)
  titleText:SetPoint("RIGHT", headerRow1, "CENTER", -Metrics.GUTTER, 0)
  titleText:SetJustifyH("LEFT")
  titleText:SetJustifyV("MIDDLE")
  titleText:SetText("Book Archivist")
  self:SetFrame("headerTitle", titleText)

  local searchBox = self:SafeCreateFrame("EditBox", "BookArchivistSearchBox", headerRow1, "SearchBoxTemplate")
  if searchBox then
    self:SetFrame("searchBox", searchBox)
    searchBox:SetWidth(280)
    searchBox:SetHeight(Metrics.BTN_H + 6)
    searchBox:SetPoint("CENTER", headerRow1, "CENTER", 0, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetJustifyH("LEFT")
    wireSearchHandlers(self, searchBox)
  end

  local clearButton = self:SafeCreateFrame("Button", nil, headerRow1, "UIPanelCloseButton")
  if clearButton and searchBox then
    clearButton:SetScale(0.7)
    clearButton:SetPoint("LEFT", searchBox, "RIGHT", -6, 0)
    clearButton:SetScript("OnClick", function()
      searchBox:SetText("")
      self:RunSearchRefresh()
      self:UpdateSearchClearButton()
    end)
    self:SetFrame("searchClearButton", clearButton)
    clearButton:Hide()
  end

  local optionsButton = self:SafeCreateFrame("Button", nil, headerRow1, "UIPanelButtonTemplate")
  if optionsButton then
    optionsButton:SetSize(Metrics.BTN_W, Metrics.BTN_H)
    optionsButton:SetPoint("RIGHT", headerRow1, "RIGHT", 0, 0)
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

  local helpButton = self:SafeCreateFrame("Button", nil, headerRow1, "UIPanelButtonTemplate")
  if helpButton and optionsButton then
    helpButton:SetSize(Metrics.BTN_W - 12, Metrics.BTN_H)
    helpButton:SetPoint("RIGHT", optionsButton, "LEFT", -Metrics.GUTTER, 0)
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

  local headerCount = headerRow2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerCount:SetPoint("LEFT", headerRow2, "LEFT", 0, 0)
  headerCount:SetJustifyH("LEFT")
  headerCount:SetJustifyV("MIDDLE")
  headerCount:SetText("Saving every page you read")
  self:SetFrame("headerCountText", headerCount)

  local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", headerRow2, "UIDropDownMenuTemplate")
  sortDropdown:ClearAllPoints()
  sortDropdown:SetPoint("LEFT", headerCount, "RIGHT", Metrics.GUTTER, -6)
  self:InitializeSortDropdown(sortDropdown)

  local filterContainer = CreateFrame("Frame", nil, headerRow2)
  filterContainer:SetPoint("RIGHT", headerRow2, "RIGHT", 0, 0)
  filterContainer:SetPoint("BOTTOM", headerRow2, "BOTTOM", 0, 0)
  filterContainer:SetHeight(Metrics.BTN_H)
  self:SetFrame("filterContainer", filterContainer)
  local lastButton
  for _, def in ipairs(self:GetQuickFilters()) do
    local button = CreateFrame("Button", nil, filterContainer)
    button:SetSize(Metrics.BTN_H, Metrics.BTN_H)
    if lastButton then
      button:SetPoint("RIGHT", lastButton, "LEFT", -Metrics.GUTTER * 0.6, 0)
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
    listBlock:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", Metrics.PAD, -Metrics.HEADER_H)
    listBlock:SetPoint("BOTTOMLEFT", uiFrame, "BOTTOMLEFT", Metrics.PAD, Metrics.PAD)
    listBlock:SetWidth(380)
    uiFrame.listBlock = listBlock
  end
  self:SetFrame("listBlock", listBlock)

  local listHeaderRow = self:EnsureListHeaderRow()
  local tabsAnchor = self:SafeCreateFrame("Frame", nil, listHeaderRow)
  tabsAnchor:SetPoint("RIGHT", listHeaderRow, "RIGHT", 0, 0)
  tabsAnchor:SetPoint("BOTTOM", listHeaderRow, "BOTTOM", 0, 0)
  tabsAnchor:SetHeight(Metrics.BTN_H)
  tabsAnchor:SetWidth((Metrics.BTN_W * 2) + Metrics.GUTTER)
  self:SetFrame("listHeaderTabsAnchor", tabsAnchor)

  local locationsModeButton = self:SafeCreateFrame("Button", nil, tabsAnchor, "UIPanelButtonTemplate")
  if locationsModeButton then
    locationsModeButton:SetSize(Metrics.BTN_W, Metrics.BTN_H)
    locationsModeButton:SetPoint("RIGHT", tabsAnchor, "RIGHT", 0, 0)
    locationsModeButton:SetText("Locations")
    locationsModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.LOCATIONS)
    end)
    self:SetFrame("locationsModeButton", locationsModeButton)
  end

  local booksModeButton = self:SafeCreateFrame("Button", nil, tabsAnchor, "UIPanelButtonTemplate")
  if booksModeButton then
    booksModeButton:SetSize(Metrics.BTN_W - 12, Metrics.BTN_H)
    if locationsModeButton then
      booksModeButton:SetPoint("RIGHT", locationsModeButton, "LEFT", -Metrics.GUTTER * 0.5, 0)
    else
      booksModeButton:SetPoint("RIGHT", tabsAnchor, "RIGHT", 0, 0)
    end
    booksModeButton:SetText("Books")
    booksModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.BOOKS)
    end)
    self:SetFrame("booksModeButton", booksModeButton)
  end

  local listHeader = self:EnsureListHeader()
  if listHeader and tabsAnchor then
    listHeader:ClearAllPoints()
    listHeader:SetPoint("LEFT", listHeaderRow, "LEFT", 0, 0)
    listHeader:SetPoint("RIGHT", tabsAnchor, "LEFT", -Metrics.GUTTER, 0)
  end

  local breadcrumb = listBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  breadcrumb:SetPoint("TOPLEFT", listHeaderRow, "BOTTOMLEFT", 0, -2)
  breadcrumb:SetPoint("RIGHT", listBlock, "RIGHT", -Metrics.PAD, 0)
  breadcrumb:SetJustifyH("LEFT")
  breadcrumb:SetJustifyV("MIDDLE")
  breadcrumb:SetWordWrap(false)
  breadcrumb:SetText("")
  breadcrumb:Hide()
  self:SetFrame("locationBreadcrumb", breadcrumb)

  local listSeparator = listBlock:CreateTexture(nil, "ARTWORK")
  listSeparator:SetHeight(1)
  listSeparator:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", -Metrics.PAD * 0.5, -Metrics.GUTTER * 0.4)
  listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -Metrics.PAD, -Metrics.PAD)
  listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)
  self:SetFrame("listSeparator", listSeparator)

  local scrollFrame = self:SafeCreateFrame("ScrollFrame", "BookArchivistListScroll", listBlock, "UIPanelScrollFrameTemplate")
  if not scrollFrame then
    self:LogError("Unable to create list scroll frame.")
    return
  end
  scrollFrame:SetPoint("TOPLEFT", listHeaderRow, "BOTTOMLEFT", 0, -Metrics.GUTTER)
  scrollFrame:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -Metrics.PAD, Metrics.PAD)
  self:SetFrame("scrollFrame", scrollFrame)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(336, 1)
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -14, 0)
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

  self:EnsureInfoText()
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

  local breadcrumb = self:GetFrame("locationBreadcrumb")
  if breadcrumb and hasMethod(breadcrumb, "SetText") then
    local shouldShow = mode == modes.LOCATIONS and self:GetLocationState().root
    if shouldShow then
      breadcrumb:SetText("|cFFCCCCCC" .. (self:GetLocationBreadcrumbText() or "") .. "|r")
      if hasMethod(breadcrumb, "Show") then
        breadcrumb:Show()
      end
    else
      breadcrumb:SetText("")
      if hasMethod(breadcrumb, "Hide") then
        breadcrumb:Hide()
      end
    end
  end

  local listSeparator = self:GetFrame("listSeparator")
  local listBlock = self:GetFrame("listBlock")
  if hasMethod(listSeparator, "ClearAllPoints") and hasMethod(listSeparator, "SetPoint") and listBlock then
    listSeparator:ClearAllPoints()
    local anchorTarget = listHeader
    if mode == modes.LOCATIONS and breadcrumb and hasMethod(breadcrumb, "IsShown") and breadcrumb:IsShown() then
      anchorTarget = breadcrumb
    end
    anchorTarget = anchorTarget or listBlock
    listSeparator:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", -Metrics.PAD * 0.25, -Metrics.GUTTER * 0.5)
    listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -Metrics.PAD, -Metrics.PAD)
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
