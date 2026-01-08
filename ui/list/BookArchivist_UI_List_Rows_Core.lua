---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist.UI and BookArchivist.UI.Metrics or {}
local ROW_PAD_L = Metrics.ROW_PAD_L or Metrics.PAD_INSET or Metrics.PAD or 8
local ROW_PAD_R = Metrics.ROW_PAD_R or Metrics.PAD_INSET or Metrics.PAD or 8
local ROW_PAD_T = Metrics.ROW_PAD_T or 4
local SCROLLBAR_GUTTER = Metrics.SCROLLBAR_GUTTER or 18
local ROW_HILITE_INSET = Metrics.ROW_HILITE_INSET or 0
local ROW_EDGE_W = Metrics.ROW_EDGE_W or 3
local BADGE_COL_W = Metrics.SEARCH_BADGE_COL_W or 52
local BADGE_H = Metrics.SEARCH_BADGE_H or 16
local BADGE_GAP_Y = Metrics.SEARCH_BADGE_GAP_Y or 2

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local function getMatchBadgeTexts()
  local Ltbl = BookArchivist and BookArchivist.L or {}
  local title = (Ltbl and Ltbl["MATCH_TITLE"]) or "TITLE"
  local text = (Ltbl and Ltbl["MATCH_TEXT"]) or "TEXT"
  return title, text
end

local function syncRowFavorite(button, entry)
  if not button or not button.favoriteStar then
    return
  end
  local isFav = entry and entry.isFavorite and true or false
  button.favoriteStar:SetShown(isFav)
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
  if button.favoriteStar then button.favoriteStar:Hide() end
  if button.badgeTitle then button.badgeTitle:Hide() end
  if button.badgeText then button.badgeText:Hide() end
end

local function syncMatchBadges(self, button, key)
  if not button or not self or not self.GetSearchMatchKind then
    return
  end
  if self.GetSearchQuery and self:GetSearchQuery() == "" then
    if button.badgeTitle then button.badgeTitle:Hide() end
    if button.badgeText then button.badgeText:Hide() end
    return
  end
  local flags = self:GetSearchMatchKind(key)
  if not flags then
    if button.badgeTitle then button.badgeTitle:Hide() end
    if button.badgeText then button.badgeText:Hide() end
    return
  end
  local titleLabel, textLabel = getMatchBadgeTexts()
  local hasTitle = flags.title and true or false
  local hasText = flags.text and true or false
  if not hasTitle and not hasText then
    if button.badgeTitle then button.badgeTitle:Hide() end
    if button.badgeText then button.badgeText:Hide() end
    return
  end
  local container = button.badgeContainer
  if not container then return end
  if hasTitle and hasText then
    button.badgeTitle:Show()
    button.badgeText:Show()
    button.badgeTitle:ClearAllPoints()
    button.badgeText:ClearAllPoints()
    button.badgeTitle:SetPoint("TOP", container, "TOP", 0, -(ROW_PAD_T or 4))
    button.badgeText:SetPoint("TOP", button.badgeTitle, "BOTTOM", 0, -BADGE_GAP_Y)
    button.badgeTitle.text:SetText(titleLabel)
    button.badgeText.text:SetText(textLabel)
  elseif hasTitle then
    button.badgeTitle:Show()
    button.badgeText:Hide()
    button.badgeTitle:ClearAllPoints()
    button.badgeTitle:SetPoint("CENTER", container, "CENTER", 0, 0)
    button.badgeTitle.text:SetText(titleLabel)
  elseif hasText then
    button.badgeTitle:Hide()
    button.badgeText:Show()
    button.badgeText:ClearAllPoints()
    button.badgeText:SetPoint("CENTER", container, "CENTER", 0, 0)
    button.badgeText.text:SetText(textLabel)
  end
end

local function getScrollChild(self)
  return self:GetFrame("scrollChild") or self:GetWidget("scrollChild")
end

local function setRowContentAnchors(button, useBadgeColumn)
  local rowContent = button and button.content
  if not rowContent then
    return
  end
  rowContent:ClearAllPoints()
  if useBadgeColumn and button.badgeContainer then
    rowContent:SetPoint("TOPLEFT", button.badgeContainer, "TOPRIGHT", (Metrics.GAP_S or 4), -ROW_PAD_T)
  else
    rowContent:SetPoint("TOPLEFT", button, "TOPLEFT", ROW_PAD_L, -ROW_PAD_T)
  end
  rowContent:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -(ROW_PAD_R + SCROLLBAR_GUTTER), ROW_PAD_T)
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
      if self.NavigateInto then
        self:NavigateInto(button.locationName)
      end
      if self.UpdateList then
        self:UpdateList()
      end
      if self.UpdateListModeUI then
        self:UpdateListModeUI()
      end
      return
    elseif button.itemKind == "back" then
      if self.NavigateUp then
        self:NavigateUp()
      end
      if self.UpdateList then
        self:UpdateList()
      end
      if self.UpdateListModeUI then
        self:UpdateListModeUI()
      end
      return
    end
  end

  if button.bookKey then
    if mouseButton == "RightButton" and self.ShowBookContextMenu then
      self:ShowBookContextMenu(button, button.bookKey)
      return
    end
    if self.SetSelectedKey then
      self:SetSelectedKey(button.bookKey)
    end
    if self.NotifySelectionChanged then
      self:NotifySelectionChanged()
    end
    if self.UpdateList then
      self:UpdateList()
    end
  end
end

local function createRowButton(self)
  local parent = getScrollChild(self)
  local rowHeight = self:GetRowHeight()
  local button = CreateFrame("Button", nil, parent)
  self:CreateRowButtonStructure(button, rowHeight)
  
  button:SetScript("OnClick", function(btn, mouseButton)
    if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    handleRowClick(self, btn, mouseButton)
  end)

  return button
end

-- Extract the row structure creation into a reusable method
function ListUI:CreateRowButtonStructure(button, rowHeight)
  if not button then return end
  
  rowHeight = rowHeight or self:GetRowHeight()
  button:SetSize(340, rowHeight)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  button.bg = button:CreateTexture(nil, "BACKGROUND")
  button.bg:SetAllPoints(true)
  button.bg:SetColorTexture(0, 0, 0, 0)

  button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
  button.highlight:ClearAllPoints()
  button.highlight:SetPoint("TOPLEFT", button, "TOPLEFT", ROW_HILITE_INSET, -ROW_HILITE_INSET)
  button.highlight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -ROW_HILITE_INSET, ROW_HILITE_INSET)
  button.highlight:SetColorTexture(1, 1, 1, 0.08)
  button.highlight:SetAlpha(1)

  button.selected = button:CreateTexture(nil, "BACKGROUND", nil, 1)
  button.selected:ClearAllPoints()
  button.selected:SetPoint("TOPLEFT", button, "TOPLEFT", ROW_HILITE_INSET, -ROW_HILITE_INSET)
  button.selected:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -ROW_HILITE_INSET, ROW_HILITE_INSET)
  button.selected:SetColorTexture(1, 0.82, 0, 0.3)
  button.selected:SetAlpha(1)
  button.selected:Hide()

  button.selectedEdge = button:CreateTexture(nil, "OVERLAY")
  button.selectedEdge:ClearAllPoints()
  button.selectedEdge:SetPoint("TOPLEFT", button, "TOPLEFT", ROW_HILITE_INSET, -ROW_HILITE_INSET)
  button.selectedEdge:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", ROW_HILITE_INSET, ROW_HILITE_INSET)
  button.selectedEdge:SetWidth(ROW_EDGE_W)
  button.selectedEdge:SetColorTexture(1, 0.82, 0, 1)
  button.selectedEdge:Hide()

  local badgeContainer = CreateFrame("Frame", nil, button)
  badgeContainer:SetPoint("LEFT", button, "LEFT", ROW_PAD_L, 0)
  badgeContainer:SetSize(BADGE_COL_W, rowHeight)
  button.badgeContainer = badgeContainer

  local rowContent = CreateFrame("Frame", nil, button)
  button.content = rowContent
  setRowContentAnchors(button, false)

  local favoriteStar = rowContent:CreateTexture(nil, "OVERLAY")
  local baseSize = self:GetRowHeight() or 36
  local starSize = Metrics.ROW_FAVORITE_SIZE or math.floor(baseSize / 3)
  favoriteStar:SetSize(starSize, starSize)
  favoriteStar:SetPoint("TOPRIGHT", rowContent, "TOPRIGHT", 0, 0)
  if favoriteStar.SetAtlas then
    favoriteStar:SetAtlas("auctionhouse-icon-favorite")
  end
  favoriteStar:SetDesaturated(false)
  favoriteStar:SetAlpha(1)
  favoriteStar:Hide()
  button.favoriteStar = favoriteStar

  button.titleText = rowContent:CreateFontString(nil, "OVERLAY")
  button.titleText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
  button.titleText:SetPoint("TOPLEFT", rowContent, "TOPLEFT", 0, 0)
  button.titleText:SetPoint("TOPRIGHT", favoriteStar, "LEFT", -(Metrics.GAP_XS or 4), 0)
  button.titleText:SetJustifyH("LEFT")
  button.titleText:SetJustifyV("TOP")
  button.titleText:SetWordWrap(false)
  button.titleText:SetTextColor(1, 1, 1)
  button.titleText:SetShadowOffset(0, 0)

  button.metaText = rowContent:CreateFontString(nil, "OVERLAY")
  button.metaText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
  button.metaText:SetPoint("TOPLEFT", button.titleText, "BOTTOMLEFT", 0, -(Metrics.GAP_XS or 4))
  button.metaText:SetPoint("RIGHT", rowContent, "RIGHT", 0, 0)
  button.metaText:SetPoint("BOTTOMLEFT", rowContent, "BOTTOMLEFT", 0, 0)
  button.metaText:SetJustifyH("LEFT")
  button.metaText:SetTextColor(0.75, 0.75, 0.75)
  button.metaText:SetWordWrap(false)
  button.metaText:SetMaxLines(1)
  button.metaText:SetShadowOffset(0, 0)

  local badgeTitle = CreateFrame("Frame", nil, badgeContainer)
  badgeTitle:SetSize(BADGE_COL_W, BADGE_H)
  badgeTitle:Hide()
  local btBg = badgeTitle:CreateTexture(nil, "BACKGROUND")
  btBg:SetAllPoints(true)
  btBg:SetColorTexture(0.4, 0.3, 0, 0.8)
  local btBorder = badgeTitle:CreateTexture(nil, "BORDER")
  btBorder:SetPoint("TOPLEFT", -1, 1)
  btBorder:SetPoint("BOTTOMRIGHT", 1, -1)
  btBorder:SetColorTexture(0, 0, 0, 1)
  local btText = badgeTitle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btText:SetPoint("CENTER")
  btText:SetTextColor(1, 0.9, 0.3)
  badgeTitle.text = btText
  button.badgeTitle = badgeTitle

  local badgeText = CreateFrame("Frame", nil, badgeContainer)
  badgeText:SetSize(BADGE_COL_W, BADGE_H)
  badgeText:Hide()
  local bxBg = badgeText:CreateTexture(nil, "BACKGROUND")
  bxBg:SetAllPoints(true)
  bxBg:SetColorTexture(0, 0.2, 0.4, 0.8)
  local bxBorder = badgeText:CreateTexture(nil, "BORDER")
  bxBorder:SetPoint("TOPLEFT", -1, 1)
  bxBorder:SetPoint("BOTTOMRIGHT", 1, -1)
  bxBorder:SetColorTexture(0, 0, 0, 1)
  local bxText = badgeText:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bxText:SetPoint("CENTER")
  bxText:SetTextColor(0.8, 0.9, 1)
  badgeText.text = bxText
  button.badgeText = badgeText
end

function ListUI:HandleRowClick(button, mouseButton)
  handleRowClick(self, button, mouseButton)
end

local function acquireButton(self)
  local FramePool = BookArchivist.UI and BookArchivist.UI.FramePool
  if FramePool and FramePool:PoolExists("listRows") then
    -- Use proper FramePool
    local button = FramePool:Acquire("listRows")
    if button then
      return button
    end
  end
  
  -- Fallback to manual pool
  local pool = self:GetButtonPool()
  local button = table.remove(pool.free)
  if not button then
    button = createRowButton(self)
    self:DebugPrint("[BookArchivist] ButtonPool: created new row button (fallback)")
  end
  button:Show()
  table.insert(pool.active, button)
  return button
end

local function releaseAllButtons(self)
  local FramePool = BookArchivist.UI and BookArchivist.UI.FramePool
  if FramePool and FramePool:PoolExists("listRows") then
    -- Use proper FramePool
    FramePool:ReleaseAll("listRows")
    return
  end
  
  -- Fallback to manual pool
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

function ListUI:GetListScrollChild()
  return getScrollChild(self)
end

function ListUI:AcquireRowButton()
  return acquireButton(self)
end

function ListUI:ReleaseAllRowButtons()
  return releaseAllButtons(self)
end

function ListUI:SetRowContentAnchors(button, useBadgeColumn)
  return setRowContentAnchors(button, useBadgeColumn)
end

function ListUI:SyncRowFavorite(button, entry)
  return syncRowFavorite(button, entry)
end

function ListUI:SyncMatchBadges(button, key)
  return syncMatchBadges(self, button, key)
end

function ListUI:EnsureEntryInfo()
  return ensureEntryInfo(self)
end
