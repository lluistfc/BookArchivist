---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local function entryToDisplay(entry)
  local title = entry.title or "(Untitled)"
  local creator = entry.creator or ""

  local titleColor = "|cFFFFD100"
  if entry.material and entry.material:lower():find("parchment") then
    titleColor = "|cFFE6CC80"
  end

  local result = titleColor .. title .. "|r"
  if creator ~= "" then
    result = result .. "\n|cFF999999   " .. creator .. "|r"
  end
  return result
end

local function resetButton(button)
  button:Hide()
  button:ClearAllPoints()
  button.bookKey = nil
  button.itemKind = nil
  button.locationName = nil
  if button.selected then button.selected:Hide() end
  if button.selectedEdge then button.selectedEdge:Hide() end
end

local function getScrollChild(self)
  return self:GetFrame("scrollChild") or self:GetWidget("scrollChild")
end

local function handleRowClick(self, button)
  local modes = self:GetListModes()
  if self:GetListMode() == modes.LOCATIONS then
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

  button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  button.text:SetPoint("TOPLEFT", 10, -6)
  button.text:SetPoint("BOTTOMRIGHT", -10, 6)
  button.text:SetJustifyH("LEFT")
  button.text:SetJustifyV("TOP")
  button.text:SetWordWrap(true)
  button.text:SetMaxLines(2)

  button:SetScript("OnClick", function(btn)
    if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    handleRowClick(self, btn)
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
    scrollChild:SetSize(336, totalHeight)

    for i = 1, total do
      local button = acquireButton(self)
      button:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)

      local key = filtered[i]
      if key then
        local entry = db.books[key]
        if entry then
          button.bookKey = key
          button.itemKind = "book"
          button.text:SetText(entryToDisplay(entry))

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

    local countText = string.format("|cFFFFD100%d|r book%s", total, total ~= 1 and "s" or "")
    if total ~= #(db.order or {}) then
      countText = countText .. string.format(" (filtered from |cFFFFD100%d|r)", #(db.order or {}))
    end
    if info then
      info:SetText(countText)
    end
    return
  end

  local rows = self:GetLocationRows()
  local total = #rows
  scrollChild:SetSize(336, math.max(1, total * rowHeight))
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
      button.text:SetText("|cFF00FF00⟵ Back|r\n|cFF999999Up one level|r")
      button.selected:Hide()
      button.selectedEdge:Hide()
    elseif row.kind == "location" then
      button.locationName = row.name
      button.bookKey = nil
      local childNode = row.node
      local childCount = childNode and childNode.childNames and #childNode.childNames or 0
      local bookCount = childNode and childNode.books and #childNode.books or 0
      local detail
      if childCount > 0 then
        detail = string.format("%d sub-location%s", childCount, childCount ~= 1 and "s" or "")
      elseif bookCount > 0 then
        detail = string.format("%d book%s", bookCount, bookCount ~= 1 and "s" or "")
      else
        detail = "Empty location"
      end
      button.text:SetText(string.format("|cFFFFD100%s|r\n|cFF999999%s|r", row.name, detail))
      button.selected:Hide()
      button.selectedEdge:Hide()
    elseif row.kind == "book" then
      local key = row.key
      button.bookKey = key
      button.locationName = nil
      local entry = key and db.books and db.books[key]
      button.text:SetText(entry and entryToDisplay(entry) or "|cFFFFD100Unknown Book|r")
      if key == self:GetSelectedKey() then
        button.selected:Show()
        button.selectedEdge:Show()
      else
        button.selected:Hide()
        button.selectedEdge:Hide()
      end
    else
      button.text:SetText("?")
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
end
