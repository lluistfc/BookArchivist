---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local QUICK_FILTERS = {
  { key = "favoritesOnly" },
}

function ListUI:GetQuickFilters()
  return QUICK_FILTERS
end

function ListUI:IsVirtualCategoriesEnabled()
  local ctx = self:GetContext()
  if ctx and ctx.isVirtualCategoriesEnabled then
    return ctx.isVirtualCategoriesEnabled() and true or false
  end
  return true
end

function ListUI:GetCategoryId()
  local ctx = self:GetContext()
  if ctx and ctx.getCategoryId then
    local id = ctx.getCategoryId()
    if type(id) == "string" and id ~= "" then
      return id
    end
  end
  return "__all__"
end

function ListUI:SetCategoryId(categoryId)
  local ctx = self:GetContext()
  if ctx and ctx.setCategoryId then
    ctx.setCategoryId(categoryId)
  end
  if self.UpdateFilterButtons then
    self:UpdateFilterButtons()
  end
  if self.RebuildFiltered then
    self:RebuildFiltered()
  end
  if self.RebuildLocationTree then
    self:RebuildLocationTree()
  end
  if self.UpdateList then
    self:UpdateList()
  end
  if self.UpdateCountsDisplay then
    self:UpdateCountsDisplay()
  end
end

function ListUI:GetFiltersState()
  local ctx = self:GetContext()
  local persisted = ctx and ctx.getFilters and ctx.getFilters()
  local filters = self.__state.filters
  for _, def in ipairs(QUICK_FILTERS) do
    local key = def.key
    local value
    if persisted and persisted[key] ~= nil then
      value = persisted[key]
    elseif filters[key] ~= nil then
      value = filters[key]
    else
      value = def.default or false
    end
    filters[key] = value and true or false
  end
  return filters
end

function ListUI:SetFilterState(key, enabled)
  if not key then return end
  local filters = self:GetFiltersState()
  filters[key] = enabled and true or false
  local ctx = self:GetContext()
  if ctx and ctx.setFilter then
    ctx.setFilter(key, enabled and true or false)
  end
end

function ListUI:ToggleFilter(key)
  if not key then return end
  local filters = self:GetFiltersState()
  local current = filters[key] and true or false
  self:SetFilterState(key, not current)
  if self.UpdateFilterButtons then
    self:UpdateFilterButtons()
  end
  if self.RebuildFiltered then
    self:RebuildFiltered()
  end
  if self.UpdateList then
    self:UpdateList()
  end
end

function ListUI:GetFilterButtons()
  return self.__state.filterButtons
end

function ListUI:SetFilterButton(key, button)
  if not key or not button then
    return
  end
  self.__state.filterButtons[key] = button
end

function ListUI:HasActiveFilters()
  local filters = self:GetFiltersState()
  for _, def in ipairs(QUICK_FILTERS) do
    if filters[def.key] then
      return true
    end
  end
  return false
end

function ListUI:UpdateFilterButtons()
  local filters = self:GetFiltersState()
  for _, def in ipairs(QUICK_FILTERS) do
    local button = self.__state.filterButtons[def.key]
    if button then
      local active = filters[def.key]
      button.active = active and true or false
      if button.icon then
        button.icon:SetDesaturated(not active)
        button.icon:SetAlpha(active and 1 or 0.55)
      end
      if button.bg then
        if active then
          button.bg:SetColorTexture(1, 0.82, 0, 0.25)
        else
          button.bg:SetColorTexture(0, 0, 0, 0.35)
        end
      end
      if button.border then
        button.border:SetVertexColor(active and 1 or 0.4, active and 0.9 or 0.4, active and 0 or 0.4, 0.9)
      end
    end
  end
end
