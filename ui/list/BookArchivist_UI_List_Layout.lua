---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

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
    info:SetPoint("BOTTOM", listBlock, "BOTTOM", 0, 6)
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

  local listBlock = self:GetFrame("listBlock")
  if not hasMethod(listBlock, "CreateFontString") then
    return nil
  end

  listHeader = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  if listHeader and hasMethod(listHeader, "SetPoint") then
    listHeader:SetPoint("TOPLEFT", listBlock, "TOPLEFT", 8, -8)
  end
  if listHeader and hasMethod(listHeader, "SetText") then
    listHeader:SetText("Saved Books")
  end
  return self:SetFrame("listHeader", listHeader)
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
    header:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", 58, -32)
    header:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -34, -32)
    header:SetHeight(78)
    uiFrame.HeaderFrame = header
  end

  local titleText = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
  titleText:SetPoint("TOPLEFT", 14, -10)
  titleText:SetText("Book Archivist")
  self:SetFrame("headerTitle", titleText)

  local headerCount = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  headerCount:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -4)
  headerCount:SetText("Saving every page you read")
  self:SetFrame("headerCountText", headerCount)

  local searchBox = self:SafeCreateFrame("EditBox", "BookArchivistSearchBox", header, "SearchBoxTemplate")
  if searchBox then
    self:SetFrame("searchBox", searchBox)
    searchBox:SetSize(260, 24)
    searchBox:SetPoint("TOP", header, "TOP", -40, -18)
    searchBox:SetAutoFocus(false)
    wireSearchHandlers(self, searchBox)
  end

  local clearButton = self:SafeCreateFrame("Button", nil, header, "UIPanelCloseButton")
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

  local sortDropdown = CreateFrame("Frame", "BookArchivistSortDropdown", header, "UIDropDownMenuTemplate")
  sortDropdown:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", -12, 4)
  self:InitializeSortDropdown(sortDropdown)

  local filterContainer = CreateFrame("Frame", nil, header)
  filterContainer:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -8, 6)
  filterContainer:SetHeight(30)
  local lastButton
  for _, def in ipairs(self:GetQuickFilters()) do
    local button = CreateFrame("Button", nil, filterContainer)
    button:SetSize(28, 28)
    if lastButton then
      button:SetPoint("RIGHT", lastButton, "LEFT", -6, 0)
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

  local actionButton = self:SafeCreateFrame("Button", nil, header, "UIPanelButtonTemplate")
  if actionButton then
    actionButton:SetSize(80, 22)
    actionButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", -10, -10)
    actionButton:SetText("Options")
    actionButton:SetScript("OnClick", function()
      local addon = self:GetAddon()
      if addon and addon.OpenOptionsPanel then
        addon:OpenOptionsPanel()
      elseif BookArchivist and BookArchivist.OpenOptionsPanel then
        BookArchivist:OpenOptionsPanel()
      end
    end)
  end

  local helpButton = self:SafeCreateFrame("Button", nil, header, "UIPanelButtonTemplate")
  if helpButton and actionButton then
    helpButton:SetSize(70, 22)
    helpButton:SetPoint("TOPRIGHT", actionButton, "BOTTOMRIGHT", 0, -4)
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

  local listBlock = uiFrame.listBlock or uiFrame.ListInset
  if not listBlock then
    listBlock = self:SafeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate3")
    listBlock:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", 4, -90)
    listBlock:SetPoint("BOTTOMLEFT", uiFrame, "BOTTOMLEFT", 4, 36)
    listBlock:SetWidth(380)
    uiFrame.listBlock = listBlock
  end
  self:SetFrame("listBlock", listBlock)

  local listHeader = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  listHeader:SetPoint("TOPLEFT", listBlock, "TOPLEFT", 12, -10)
  listHeader:SetPoint("RIGHT", listBlock, "RIGHT", -150, 0)
  listHeader:SetText("Saved Books")
  self:SetFrame("listHeader", listHeader)

  local breadcrumb = listBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  breadcrumb:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -2)
  breadcrumb:SetPoint("RIGHT", listBlock, "RIGHT", -160, 0)
  breadcrumb:SetJustifyH("LEFT")
  breadcrumb:SetWordWrap(false)
  breadcrumb:SetText("")
  breadcrumb:Hide()
  self:SetFrame("locationBreadcrumb", breadcrumb)

  local listSeparator = listBlock:CreateTexture(nil, "ARTWORK")
  listSeparator:SetHeight(1)
  listSeparator:SetPoint("TOPLEFT", breadcrumb, "BOTTOMLEFT", -4, -6)
  listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -10, -30)
  listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)
  self:SetFrame("listSeparator", listSeparator)

  local locationsModeButton = self:SafeCreateFrame("Button", nil, listBlock, "UIPanelButtonTemplate")
  if locationsModeButton then
    locationsModeButton:SetSize(90, 22)
    locationsModeButton:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -12, -8)
    locationsModeButton:SetText("Locations")
    locationsModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.LOCATIONS)
    end)
    self:SetFrame("locationsModeButton", locationsModeButton)
  end

  local booksModeButton = self:SafeCreateFrame("Button", nil, listBlock, "UIPanelButtonTemplate")
  if booksModeButton then
    booksModeButton:SetSize(70, 22)
    if locationsModeButton then
      booksModeButton:SetPoint("RIGHT", locationsModeButton, "LEFT", -6, 0)
    else
      booksModeButton:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -12, -8)
    end
    booksModeButton:SetText("Books")
    booksModeButton:SetScript("OnClick", function()
      local modes = self:GetListModes()
      self:SetListMode(modes.BOOKS)
    end)
    self:SetFrame("booksModeButton", booksModeButton)
  end

  local scrollFrame = self:SafeCreateFrame("ScrollFrame", "BookArchivistListScroll", listBlock, "UIPanelScrollFrameTemplate")
  if not scrollFrame then
    self:LogError("Unable to create list scroll frame.")
    return
  end
  scrollFrame:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 6, -6)
  scrollFrame:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -28, 36)
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
    listSeparator:SetPoint("TOPLEFT", anchorTarget, "BOTTOMLEFT", -4, -4)
    listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -8, -28)
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
