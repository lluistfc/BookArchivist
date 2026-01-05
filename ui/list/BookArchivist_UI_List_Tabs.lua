---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {
  BTN_H = 22,
  BTN_W = 100,
  GAP_S = 6,
  GAP_M = 10,
  GAP_XS = 4,
  LIST_TAB_RAIL_H = 30,
  LIST_TAB_RAIL_W = 220,
  TAB_OVERLAP_X = 16,
  TAB_Y_BIAS = 0,
  TAB_ON_LINE_Y = -2,
}

local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

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
local TAB_ON_LINE_Y = Metrics.TAB_ON_LINE_Y or -2
local TAB_RAIL_W = Metrics.LIST_TAB_RAIL_W or (((Metrics.BTN_W or 100) * 2) + (Metrics.GAP_S or Metrics.GAP_M or 10))

local function ClearAnchors(frame)
  if frame and frame.ClearAllPoints then
    frame:ClearAllPoints()
  end
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

function ListUI:EnsureListTabParent(listHeaderRow)
  if not listHeaderRow then
    return nil
  end

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

function ListUI:EnsureListTabsRail(tabParent)
  if not tabParent then
    return nil
  end

  local tabsRail = self:GetFrame("listTabsRail")
  if tabsRail then
    return tabsRail
  end

  tabsRail = self:SafeCreateFrame("Frame", nil, tabParent)
  if not tabsRail then
    self:LogError("Unable to create tabs rail.")
    return nil
  end

  ClearAnchors(tabsRail)
  tabsRail:SetPoint("BOTTOM", tabParent, "BOTTOM", 0, TAB_Y_BIAS)
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
	tab1:SetText(t("BOOKS_TAB"))
  if PanelTemplates_TabResize and tab1.Text then
    PanelTemplates_TabResize(tab1, 0)
  end
  tab2:SetID(2)
	tab2:SetText(t("LOCATIONS_TAB"))
  if PanelTemplates_TabResize and tab2.Text then
    PanelTemplates_TabResize(tab2, 0)
  end

  -- Center the tab pair within the tabsRail based on their widths, sitting on the separator line.
  local totalWidth = (tab1:GetWidth() or 0) + (tab2:GetWidth() or 0) - TAB_OVERLAP_X
  tab1:ClearAllPoints()
  tab1:SetPoint("BOTTOMLEFT", tabsRail, "BOTTOM", -totalWidth / 2, TAB_ON_LINE_Y)
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
