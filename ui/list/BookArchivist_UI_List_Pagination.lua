---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {}
local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local function getListConfig()
  return BookArchivist and BookArchivist.ListConfig or nil
end

function ListUI:GetPageSizes()
  local cfg = getListConfig()
  if cfg and cfg.GetPageSizes then
    return cfg:GetPageSizes()
  end
  return { 10, 25, 50, 100 }
end

function ListUI:GetPageSize()
  local ctx = self:GetContext()
  local persisted = ctx and ctx.getPageSize and ctx.getPageSize()
  local cfg = getListConfig()
  local size
  if cfg and cfg.NormalizePageSize then
    size = cfg:NormalizePageSize(persisted or self.__state.pagination.pageSize)
  else
    local candidate = tonumber(persisted or self.__state.pagination.pageSize) or 25
    local allowed = false
    for _, v in ipairs(self:GetPageSizes()) do
      if v == candidate then
        allowed = true
        break
      end
    end
    size = allowed and candidate or 25
  end
  self.__state.pagination.pageSize = size
  return size
end

function ListUI:SetPageSize(size)
  local cfg = getListConfig()
  local normalized
  if cfg and cfg.NormalizePageSize then
    normalized = cfg:NormalizePageSize(size)
  else
    local candidate = tonumber(size) or 25
    local allowed = false
    for _, v in ipairs(self:GetPageSizes()) do
      if v == candidate then
        allowed = true
        break
      end
    end
    normalized = allowed and candidate or 25
  end

  self.__state.pagination.pageSize = normalized
  self.__state.pagination.page = 1
  local ctx = self:GetContext()
  if ctx and ctx.setPageSize then
    ctx.setPageSize(normalized)
  end
  if self.RunSearchRefresh then
    self:RunSearchRefresh()
  end
end

function ListUI:GetPage()
  local page = tonumber(self.__state.pagination.page) or 1
  if page < 1 then
    page = 1
    self.__state.pagination.page = page
  end
  return page
end

function ListUI:SetPage(page, skipRefresh)
  local total = self.__state.pagination.total or #self:GetFilteredKeys()
  local pageCount = self:GetPageCount(total)
  local target = tonumber(page) or 1
  if pageCount < 1 then
    pageCount = 1
  end
  target = math.min(math.max(1, target), pageCount)
  self.__state.pagination.page = target
  if not skipRefresh and self.UpdateList then
    self:UpdateList()
  end
end

function ListUI:NextPage()
  self:SetPage(self:GetPage() + 1)
end

function ListUI:PrevPage()
  self:SetPage(self:GetPage() - 1)
end

function ListUI:GetPageCount(total)
  total = tonumber(total) or 0
  local pageSize = self:GetPageSize()
  if pageSize <= 0 then
    return 1
  end
  return math.max(1, math.ceil(total / pageSize))
end

function ListUI:UpdatePaginationUI(total, pageCount)
  local frame = self:GetFrame("paginationFrame")
  if not frame then
    return
  end

  total = tonumber(total) or 0
  pageCount = tonumber(pageCount) or self:GetPageCount(total)
  if pageCount < 1 then
    pageCount = 1
  end

  local page = self:GetPage()
  if page > pageCount then
    page = pageCount
    self.__state.pagination.page = page
  end
  if page < 1 then
    page = 1
    self.__state.pagination.page = page
  end

  local prevButton = self:GetFrame("pagePrevButton")
  local nextButton = self:GetFrame("pageNextButton")
  local pageLabel = self:GetFrame("pageLabel")
  local dropdown = self:GetFrame("pageSizeDropdown")

  if prevButton and prevButton.SetEnabled then
    prevButton:SetEnabled(page > 1)
  end
  if nextButton and nextButton.SetEnabled then
    nextButton:SetEnabled(page < pageCount and total > 0)
  end
  if pageLabel and pageLabel.SetText then
    if total == 0 then
      pageLabel:SetText(t("PAGINATION_EMPTY_RESULTS"))
    else
      pageLabel:SetText(string.format(t("PAGINATION_PAGE_FORMAT"), page, pageCount))
    end
  end
  if dropdown and UIDropDownMenu_SetText then
    UIDropDownMenu_SetText(dropdown, string.format(t("PAGINATION_PAGE_SIZE_FORMAT"), self:GetPageSize()))
  end
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
    prev:SetSize(80, 22)
    prev:SetText(t("PAGINATION_PREV"))
    prev:SetNormalFontObject(GameFontNormal)
    local fontString = prev:GetFontString()
    if fontString then
      fontString:SetTextColor(1.0, 0.82, 0.0)
    end
    prev:SetScript("OnClick", function()
      self:PrevPage()
    end)
    self:SetFrame("pagePrevButton", prev)
  end

  local nextBtn = self:SafeCreateFrame("Button", "BookArchivistListNextPage", bottomRow or pagination, "UIPanelButtonTemplate")
  if nextBtn then
    nextBtn:SetSize(80, 22)
    nextBtn:SetText(t("PAGINATION_NEXT"))
    nextBtn:SetNormalFontObject(GameFontNormal)
    local fontString = nextBtn:GetFontString()
    if fontString then
      fontString:SetTextColor(1.0, 0.82, 0.0)
    end
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
    UIDropDownMenu_Initialize(dropdown, function(_, level)
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
    
    -- Style the dropdown text with gold color
    local dropdownText = _G[dropdown:GetName() .. "Text"]
    if dropdownText and dropdownText.SetTextColor then
      dropdownText:SetTextColor(1.0, 0.82, 0.0)
    end
  end

  return pagination
end
