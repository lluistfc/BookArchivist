---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local BACK_ICON_TAG = "|TInterface\\Buttons\\UI-SpellbookIcon-PrevPage-Up:14:14:0:0|t"

local function hasMethod(obj, methodName)
  return obj and type(obj[methodName]) == "function"
end

local function resetButton(button)
  button:Hide()
  button:ClearAllPoints()
  button.bookKey = nil
  button.itemKind = nil
  button.locationName = nil
  button.nodeRef = nil
  if button.titleText then button.titleText:SetText("") end
  if button.metaText then button.metaText:SetText("") end
  if button.selected then button.selected:Hide() end
  if button.selectedEdge then button.selectedEdge:Hide() end
end

local function getScrollChild(self)
  return self:GetFrame("scrollChild") or self:GetWidget("scrollChild")
end

local function handleRowClick(self, button, mouseButton)
  mouseButton = mouseButton or "LeftButton"
  local modes = self:GetListModes()
  if self:GetListMode() == modes.LOCATIONS then
    if mouseButton == "RightButton" and button.itemKind == "location" and button.nodeRef and self.ShowLocationContextMenu then
      self:ShowLocationContextMenu(button, button.nodeRef)
      return
    end
    if button.itemKind == "location" and button.locationName then
      self:NavigateInto(button.locationName)
      self:UpdateList()
      self:UpdateListModeUI()
      return
    elseif button.itemKind == "back" then
      self:NavigateUp()
      self:UpdateList()
      self:UpdateListModeUI()
      return
    end
  end

  if button.bookKey then
    self:SetSelectedKey(button.bookKey)
    self:NotifySelectionChanged()
    self:UpdateList()
  end
end

local function createRowButton(self)
  local parent = getScrollChild(self)
  local rowHeight = self:GetRowHeight()
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(340, rowHeight)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints(true)
  button.bg:SetColorTexture(0, 0, 0, 0)

  button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
  button.highlight:SetAllPoints(true)
  local hasAtlas = pcall(function() button.highlight:SetAtlas("search-highlight") end)
  if not hasAtlas then
    button.highlight:SetColorTexture(1, 1, 1, 0.1)
  end
  button.highlight:SetAlpha(0.5)

  button.selected = button:CreateTexture(nil, "BACKGROUND", nil, 1)
  button.selected:SetAllPoints(true)
  local hasSelAtlas = pcall(function() button.selected:SetAtlas("groupfinder-button-cover") end)
  if not hasSelAtlas then
    button.selected:SetColorTexture(0.2, 0.4, 0.8, 0.3)
  end
  button.selected:SetAlpha(0.7)
  button.selected:Hide()

  button.selectedEdge = button:CreateTexture(nil, "OVERLAY")
  button.selectedEdge:SetSize(2, rowHeight - 2)
  button.selectedEdge:SetPoint("LEFT", 2, 0)
  button.selectedEdge:SetColorTexture(1, 0.82, 0, 1)
  button.selectedEdge:Hide()

  button.titleText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  button.titleText:SetPoint("TOPLEFT", 12, -6)
  button.titleText:SetPoint("RIGHT", -12, 0)
  button.titleText:SetJustifyH("LEFT")
  button.titleText:SetJustifyV("TOP")
  button.titleText:SetWordWrap(false)

  button.metaText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  button.metaText:SetPoint("BOTTOMLEFT", 12, 6)
  button.metaText:SetPoint("RIGHT", -12, 0)
  button.metaText:SetJustifyH("LEFT")
  button.metaText:SetTextColor(0.75, 0.75, 0.75)
  button.metaText:SetWordWrap(false)
  button.metaText:SetMaxLines(1)

  button:SetScript("OnClick", function(btn, mouseButton)
    if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    handleRowClick(self, btn, mouseButton)
  end)

  return button
end

local function acquireButton(self)
  local pool = self:GetButtonPool()
  local button = table.remove(pool.free)
  if not button then
    button = createRowButton(self)
    self:DebugPrint("[BookArchivist] ButtonPool: created new row button")
  end
  button:Show()
  table.insert(pool.active, button)
  return button
end

local function releaseAllButtons(self)
  local pool = self:GetButtonPool()
  for _, button in ipairs(pool.active) do
    resetButton(button)
    table.insert(pool.free, button)
  end
  wipe(pool.active)
end

local function ensureEntryInfo(self)
  local info = self:EnsureInfoText()
  if info then
    return info
  end
  return nil
end

function ListUI:UpdateList()
  local scrollChild = getScrollChild(self)
  if not scrollChild then
    self:DebugPrint("[BookArchivist] updateList skipped (scroll child missing)")
    return
  end
  local scrollFrame = self:GetFrame("scrollFrame") or self:GetWidget("scrollFrame")

  local addon = self:GetAddon()
  if not addon then
    self:DebugPrint("[BookArchivist] updateList: addon missing")
    return
  end
  local db = addon:GetDB()
  if not db then
    self:DebugPrint("[BookArchivist] updateList: DB missing")
    return
  end

  local mode = self:GetListMode()
  local modes = self:GetListModes()
  self:UpdateListModeUI()
  releaseAllButtons(self)

  local info = ensureEntryInfo(self)
  local rowHeight = self:GetRowHeight()

  if mode == modes.BOOKS then
    local filtered = self:GetFilteredKeys()
    local total = #filtered
    local dbCount = db.order and #db.order or 0
    self:DebugPrint(string.format("[BookArchivist] updateList filtered=%d totalDB=%d", total, dbCount))

    local totalHeight = math.max(1, total * rowHeight)
    if hasMethod(scrollChild, "SetSize") then
      local width = (scrollFrame and scrollFrame:GetWidth()) or 336
      scrollChild:SetSize(width, totalHeight)
    else
      self:DebugPrint("[BookArchivist] scrollChild missing SetSize; skipping resize")
    end

    for i = 1, total do
      local button = acquireButton(self)
      button:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)

      local key = filtered[i]
      if key then
        local entry = db.books[key]
        if entry then
          button.bookKey = key
          button.itemKind = "book"
          button.titleText:SetText(entry.title or "(Untitled)")
          button.metaText:SetText(self:FormatRowMetadata(entry))

          if key == self:GetSelectedKey() then
            button.selected:Show()
            button.selectedEdge:Show()
          else
            button.selected:Hide()
            button.selectedEdge:Hide()
          end
        end
      end
    end

    if info then
      info:SetText("|cFF888888Tip: Books save automatically as you read them.|r")
    end

    local noResults = self:GetFrame("noResultsText")
    if noResults then
      if total == 0 then
        if self:GetSearchQuery() ~= "" or self:HasActiveFilters() then
          noResults:SetText("|cFF999999No matches. Clear filters or search.|r")
        else
          noResults:SetText("|cFF999999No books saved yet. Read any in-game book to capture it.|r")
        end
        noResults:Show()
      else
        noResults:Hide()
      end
    end

    self:UpdateCountsDisplay()
    return
  end

  local rows = self:GetLocationRows()
  local total = #rows
  if hasMethod(scrollChild, "SetSize") then
    local width = (scrollFrame and scrollFrame:GetWidth()) or 336
    scrollChild:SetSize(width, math.max(1, total * rowHeight))
  else
    self:DebugPrint("[BookArchivist] scrollChild missing SetSize; skipping resize")
  end
  local state = self:GetLocationState()
  local activeNode = state.activeNode or state.root

  for i = 1, total do
    local row = rows[i]
    local button = acquireButton(self)
    button:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)
    button.itemKind = row.kind

    if row.kind == "back" then
      button.locationName = nil
      button.bookKey = nil
      button.nodeRef = nil
      button.titleText:SetText(BACK_ICON_TAG .. " Back")
      button.metaText:SetText("|cFF999999Up one level|r")
      button.selected:Hide()
      button.selectedEdge:Hide()
    elseif row.kind == "location" then
      button.locationName = row.name
      button.bookKey = nil
      local childNode = row.node
      button.nodeRef = childNode
      local childCount = childNode and childNode.childNames and #childNode.childNames or 0
      local bookCount = childNode and childNode.books and #childNode.books or 0
      local totalBooks = childNode and childNode.totalBooks or bookCount
      local detail
      if childCount > 0 then
        detail = string.format("%d sub-location%s", childCount, childCount ~= 1 and "s" or "")
      elseif bookCount > 0 or totalBooks > 0 then
        detail = string.format("%d book%s", totalBooks, totalBooks ~= 1 and "s" or "")
      else
        detail = "Empty location"
      end
      button.titleText:SetText(string.format("|cFFFFD100%s|r", row.name))
      button.metaText:SetText("|cFF999999" .. detail .. "|r")
      button.selected:Hide()
      button.selectedEdge:Hide()
    elseif row.kind == "book" then
      local key = row.key
      button.bookKey = key
      button.locationName = nil
      button.nodeRef = nil
      local entry = key and db.books and db.books[key]
      if entry then
        button.titleText:SetText(entry.title or "(Untitled)")
        button.metaText:SetText(self:FormatRowMetadata(entry))
      else
        button.titleText:SetText("|cFFFFD100Unknown Book|r")
        button.metaText:SetText("|cFF999999Missing data|r")
      end
      if key == self:GetSelectedKey() then
        button.selected:Show()
        button.selectedEdge:Show()
      else
        button.selected:Hide()
        button.selectedEdge:Hide()
      end
    else
      button.titleText:SetText("?")
      button.metaText:SetText("")
      button.selected:Hide()
      button.selectedEdge:Hide()
    end
  end

  local infoMessage
  if not activeNode or (total == 0 and (#(state.path or {}) == 0)) then
    infoMessage = "|cFF888888No saved locations yet|r"
  else
    local hasChildren = activeNode.childNames and #activeNode.childNames > 0
    if hasChildren then
      local count = #activeNode.childNames
      infoMessage = string.format("|cFFFFD100%d|r location%s", count, count ~= 1 and "s" or "")
    else
      local count = activeNode.books and #activeNode.books or 0
      infoMessage = string.format("|cFFFFD100%d|r book%s in this location", count, count ~= 1 and "s" or "")
    end
  end

  if info then
    info:SetText(infoMessage)
  end

  local noResults = self:GetFrame("noResultsText")
  if noResults then
    if total == 0 then
      noResults:SetText("|cFF999999No locations or books available here.|r")
      noResults:Show()
    else
      noResults:Hide()
    end
  end

  self:UpdateCountsDisplay()
end
