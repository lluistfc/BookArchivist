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

-- Prefer templates that are loaded early and include a Text region.
local TAB_TEMPLATES = {
  "CharacterFrameTabButtonTemplate",
  "SpellBookFrameTabButtonTemplate",
  "PanelTopTabButtonTemplate",
  "TabButtonTemplate",
}
local TAB_OVERLAP_X = Metrics.TAB_OVERLAP_X or Metrics.TAB_OVERLAP or 16
local TAB_RAIL_H = Metrics.LIST_TAB_RAIL_H or 30
local TAB_Y_BIAS = Metrics.TAB_Y_BIAS or 0
local TAB_RAIL_W = Metrics.LIST_TAB_RAIL_W or (((Metrics.BTN_W or 100) * 2) + (Metrics.GAP_S or Metrics.GUTTER or 10))
local SEPARATOR_GUTTER = Metrics.SEPARATOR_GUTTER or Metrics.GAP_S or Metrics.GUTTER or 8

local function ClearAnchors(frame)
  if frame and frame.ClearAllPoints then
    frame:ClearAllPoints()
  end
end

local function hasMethod(obj, methodName)
  return obj and type(obj[methodName]) == "function"
end

local function canUsePanelTemplates(tabParent)
  if not tabParent or not tabParent.GetName then
    return false
  end
  local parentName = tabParent:GetName()
  if not parentName or parentName == "" then
    return false
  end
  if not (PanelTemplates_SetNumTabs and PanelTemplates_SetTab) then
    return false
  end
  local tab1 = _G[parentName .. "Tab1"]
  local tab2 = _G[parentName .. "Tab2"]
  if not (tab1 and tab2) then
    return false
  end
  if not (tab1.Text and tab2.Text) then
    return false
  end
  return true
end

local function ensureTabParent(self, listHeaderRow)
  local tabParent = self:GetFrame("listTabParent")
  if tabParent then
    return tabParent
  end

  tabParent = self:SafeCreateFrame("Frame", "BookArchivistListPanel", listHeaderRow)
  if not tabParent then
    self:LogError("Unable to create list tab parent.")
    return nil
  end
  tabParent:SetAllPoints(listHeaderRow)
  self:SetFrame("listTabParent", tabParent)
  return tabParent
end

local function ensureTabsRail(self, tabParent)
  local tabsRail = self:GetFrame("listTabsRail")
  if tabsRail then
    return tabsRail
  end

  tabsRail = self:SafeCreateFrame("Frame", nil, tabParent)
  if not tabsRail then
    self:LogError("Unable to create tabs rail.")
    return nil
  end

  local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
  tabsRail:SetPoint("TOPRIGHT", tabParent, "TOPRIGHT", -(padInset + SEPARATOR_GUTTER), TAB_Y_BIAS)
  tabsRail:SetHeight(TAB_RAIL_H)
  tabsRail:SetWidth(TAB_RAIL_W)
  self:SetFrame("listTabsRail", tabsRail)
  if Internal and Internal.registerGridTarget then
    Internal.registerGridTarget("list-tabs-rail", tabsRail)
  end
  return tabsRail
end

local function wireTabButton(self, tabButton)
  if not tabButton then
    return
  end

  tabButton:SetScript("OnClick", function(btn)
    local tabParent = btn and btn:GetParent()
    local tabId = btn and btn:GetID() or 1
    if tabParent and canUsePanelTemplates(tabParent) then
      PanelTemplates_SetTab(tabParent, tabId)
    end
    self:SetSelectedListTab(tabId)
    self:SetListMode(self:TabIdToMode(tabId))
  end)
end

local function isValidTab(tab)
  return tab and tab.Text ~= nil
end

local function createTabButton(self, name, parent)
  -- Use raw CreateFrame to avoid SafeCreateFrame falling back to a template-less button.
  for i = 1, #TAB_TEMPLATES do
    local template = TAB_TEMPLATES[i]
    if template then
      local ok, tab = pcall(CreateFrame, "Button", name, parent, template)
      if ok and isValidTab(tab) then
        return tab, template
      end
    end
  end
  self:LogError("Tab creation failed or missing Text region for " .. tostring(name))
  return nil, nil
end

function ListUI:EnsureListTabs(tabParent, tabsRail)
  if not tabParent or not tabsRail then
    return nil, nil
  end

  local parentName = tabParent:GetName()
  if not parentName or parentName == "" then
    self:LogError("List tab parent is missing a name; skipping tab creation.")
    return nil, nil
  end

  local tab1 = _G[parentName .. "Tab1"] or select(1, createTabButton(self, "$parentTab1", tabParent))
  local tab2 = _G[parentName .. "Tab2"] or select(1, createTabButton(self, "$parentTab2", tabParent))

  if not (tab1 and tab1.Text and tab2 and tab2.Text) then
    self:LogError("Unable to create list tabs with required Text region; check template availability.")
    return nil, nil
  end

  tab1:SetID(1)
  tab1:SetText("Books")
  if PanelTemplates_TabResize and tab1.Text then
    PanelTemplates_TabResize(tab1, 0)
  end
  tab1:ClearAllPoints()
  tab1:SetPoint("BOTTOMRIGHT", tabsRail, "BOTTOMRIGHT", 0, 0)

  tab2:SetID(2)
  tab2:SetText("Locations")
  if PanelTemplates_TabResize and tab2.Text then
    PanelTemplates_TabResize(tab2, 0)
  end
  tab2:ClearAllPoints()
  tab2:SetPoint("BOTTOMLEFT", tab1, "BOTTOMRIGHT", -TAB_OVERLAP_X, 0)

  wireTabButton(self, tab1)
  wireTabButton(self, tab2)

  if canUsePanelTemplates(tabParent) then
    PanelTemplates_SetNumTabs(tabParent, 2)
  end

  self:SetFrame("booksTabButton", tab1)
  self:SetFrame("locationsTabButton", tab2)
  return tab1, tab2
end

function ListUI:RefreshListTabsSelection()
  local tabParent = self:GetFrame("listTabParent")
  if not tabParent then
    self:LogError("List tabs missing parent; skipping tab sync.")
    return
  end

  if not canUsePanelTemplates(tabParent) then
    self:LogError("List tabs missing required PanelTemplates frames; skipping tab sync.")
    return
  end

  local selected = self:SyncSelectedTabFromMode()
  PanelTemplates_SetNumTabs(tabParent, 2)
  PanelTemplates_SetTab(tabParent, selected)
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
  local gap = Metrics.GAP_S or Metrics.GAP_XS or 6
  ClearAnchors(row)
  row:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -gap)
  row:SetPoint("TOPRIGHT", headerRow, "BOTTOMRIGHT", 0, -gap)
  local tipH = Metrics.TIP_ROW_H or Metrics.LIST_TIP_H or (Metrics.LIST_INFO_H or 18)
  row:SetHeight(math.max(tipH, Metrics.BTN_H or 22))
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
  local gap = Metrics.GAP_S or Metrics.GAP_XS or 6
  local inset = Metrics.PAD_INSET or Metrics.PAD or 8
  ClearAnchors(row)
  row:SetPoint("TOPLEFT", tipRow, "BOTTOMLEFT", 0, -gap)
  row:SetPoint("TOPRIGHT", tipRow, "BOTTOMRIGHT", 0, -gap)
  row:SetPoint("BOTTOMLEFT", listBlock, "BOTTOMLEFT", inset, inset)
  row:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -inset, inset)
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
  pagination:SetPoint("TOPRIGHT", tipRow, "TOPRIGHT", 0, 0)
  pagination:SetPoint("BOTTOMRIGHT", tipRow, "BOTTOMRIGHT", 0, 0)
  pagination:SetWidth(320)
  self:SetFrame("paginationFrame", pagination)

  local gap = Metrics.GAP_S or Metrics.GAP_XS or 4
  local btnH = Metrics.BTN_H or 22

  local prev = self:SafeCreateFrame("Button", "BookArchivistListPrevPage", pagination, "UIPanelButtonTemplate")
  if prev then
    prev:SetSize(60, btnH)
    prev:SetPoint("LEFT", pagination, "LEFT", 0, 0)
    prev:SetText("< Prev")
    prev:SetScript("OnClick", function()
      self:PrevPage()
    end)
    self:SetFrame("pagePrevButton", prev)
  end

  local nextBtn = self:SafeCreateFrame("Button", "BookArchivistListNextPage", pagination, "UIPanelButtonTemplate")
  if nextBtn then
    nextBtn:SetSize(60, btnH)
    nextBtn:SetPoint("LEFT", prev or pagination, prev and "RIGHT" or "LEFT", prev and gap or 0, 0)
    nextBtn:SetText("Next >")
    nextBtn:SetScript("OnClick", function()
      self:NextPage()
    end)
    self:SetFrame("pageNextButton", nextBtn)
  end

  local pageLabel = pagination:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pageLabel:SetJustifyH("CENTER")
  pageLabel:SetJustifyV("MIDDLE")
  pageLabel:SetHeight(btnH)
  pageLabel:SetText("Page 1 / 1")
  if prev and nextBtn then
    pageLabel:SetPoint("LEFT", nextBtn, "RIGHT", gap, 0)
  else
    pageLabel:SetPoint("LEFT", pagination, "LEFT", gap, 0)
  end
  self:SetFrame("pageLabel", pageLabel)

  local dropdown = CreateFrame and CreateFrame("Frame", "BookArchivistPageSizeDropdown", pagination, "UIDropDownMenuTemplate")
  if dropdown then
    dropdown:SetPoint("LEFT", pageLabel, "RIGHT", gap, 0)
    dropdown:SetPoint("RIGHT", pagination, "RIGHT", 0, 0)
    UIDropDownMenu_SetWidth(dropdown, 110)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    UIDropDownMenu_SetText(dropdown, string.format("%d / page", self:GetPageSize()))
    UIDropDownMenu_Initialize(dropdown, function(frame, level)
      for _, size in ipairs(self:GetPageSizes()) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = string.format("%d / page", size)
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
    titleText:SetText("Book Archivist")
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
    headerCount:SetText("Saving every page you read")
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
  local tabParent = ensureTabParent(self, listHeaderRow)
  local tabsRail = tabParent and ensureTabsRail(self, tabParent)
  if tabParent and tabsRail then
    self:EnsureListTabs(tabParent, tabsRail)
    self:RefreshListTabsSelection()
  end

  local listHeader = self:EnsureListHeader()
  if listHeader and tabsRail then
    listHeader:ClearAllPoints()
    listHeader:SetPoint("LEFT", listHeaderRow, "LEFT", 0, 0)
    listHeader:SetPoint("RIGHT", tabsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
  end

  local tipRow = self:EnsureListTipRow()
  self:EnsureInfoText()

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
  scrollFrame:ClearAllPoints()
  scrollFrame:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 0, -gap)
  scrollFrame:SetPoint("BOTTOMRIGHT", listScrollRow, "BOTTOMRIGHT", 0, 0)
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
