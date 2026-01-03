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
    box.Instructions:SetText("Search books...")
  end

  box:SetScript("OnTextChanged", function(input)
    if input.Instructions then
      if input:GetText() ~= "" then
        input.Instructions:Hide()
      else
        input.Instructions:Show()
      end
    end
    listUI:RebuildFiltered()
    listUI:UpdateList()
    listUI:DebugPrint("[BookArchivist] search text changed; rebuild/update")
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

  local container = CreateFrame("Frame", nil, uiFrame)
  container:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", 58, -28)
  container:SetPoint("TOPRIGHT", uiFrame, "TOPRIGHT", -30, -28)
  container:SetHeight(32)

  local searchBox = self:SafeCreateFrame("EditBox", nil, container, "SearchBoxTemplate", "InputBoxTemplate")
  if searchBox then
    self:SetFrame("searchBox", searchBox)
    searchBox:SetSize(200, 20)
    searchBox:SetPoint("LEFT", 0, 0)
    searchBox:SetAutoFocus(false)
    wireSearchHandlers(self, searchBox)
  end

  local searchLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  searchLabel:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
  searchLabel:SetText("|cFFFFD100Title, Creator, or Text|r")

  local listBlock = self:SafeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate")
  if not listBlock then
    self:LogError("Unable to create book list panel.")
    return
  end
  listBlock:SetPoint("TOPLEFT", uiFrame, "TOPLEFT", 4, -65)
  listBlock:SetSize(365, 485)
  self:SetFrame("listBlock", listBlock)

  local listHeader = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  listHeader:SetPoint("TOPLEFT", listBlock, "TOPLEFT", 8, -8)
  listHeader:SetText("Saved Books")
  self:SetFrame("listHeader", listHeader)

  local breadcrumb = listBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  breadcrumb:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -2)
  breadcrumb:SetPoint("RIGHT", listBlock, "RIGHT", -150, 0)
  breadcrumb:SetJustifyH("LEFT")
  breadcrumb:SetWordWrap(false)
  breadcrumb:SetText("")
  breadcrumb:Hide()
  self:SetFrame("locationBreadcrumb", breadcrumb)

  local listSeparator = listBlock:CreateTexture(nil, "ARTWORK")
  listSeparator:SetHeight(1)
  listSeparator:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", -4, -4)
  listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -8, -28)
  listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)
  self:SetFrame("listSeparator", listSeparator)

  local locationsModeButton = self:SafeCreateFrame("Button", nil, listBlock, "UIPanelButtonTemplate")
  if locationsModeButton then
    locationsModeButton:SetSize(88, 22)
    locationsModeButton:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -8, -6)
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
      booksModeButton:SetPoint("RIGHT", locationsModeButton, "LEFT", -4, 0)
    else
      booksModeButton:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -8, -6)
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
  scrollFrame:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 4, -4)
  scrollFrame:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -28, 28)
  self:SetFrame("scrollFrame", scrollFrame)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollFrame:SetScrollChild(scrollChild)
  scrollChild:SetSize(336, 1)
  scrollChild:ClearAllPoints()
  scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
  scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -14, 0)
  self:SetFrame("scrollChild", scrollChild)

  local rowHeight = self:GetRowHeight()
  scrollFrame:SetScript("OnMouseWheel", function(frame, delta)
    local current = frame:GetVerticalScroll()
    local maxScroll = frame:GetVerticalScrollRange()
    local newScroll = math.max(0, math.min(maxScroll, current - (delta * rowHeight * 3)))
    frame:SetVerticalScroll(newScroll)
  end)

  self:EnsureInfoText()
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
end
