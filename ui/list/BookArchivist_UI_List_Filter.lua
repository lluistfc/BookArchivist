---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local function matches(self, entry, query)
  local passesFilters = true
  if self.GetListMode then
    passesFilters = self:EntryMatchesFilters(entry)
  end

  if query == "" then
    return passesFilters
  end

  if not passesFilters then
    return false
  end

  query = query:lower()

  local function has(text)
    text = (text or ""):lower()
    return text:find(query, 1, true) ~= nil
  end

  if has(entry.title) or has(entry.creator) then
    return true
  end

  if entry.pages then
    for _, page in pairs(entry.pages) do
      if has(page) then
        return true
      end
    end
  end

  return false
end

local function trim(text)
  text = text or ""
  return text:gsub("^%s+", ""):gsub("%s+$", "")
end

function ListUI:GetSearchQuery()
  return trim(self:GetSearchText())
end

function ListUI:RebuildFiltered()
  local filtered = self:GetFilteredKeys()
  wipe(filtered)
  self:DisableDeleteButton()

  local addon = self:GetAddon()
  if not addon then
    self:DebugPrint("[BookArchivist] rebuildFiltered: addon missing")
    self:LogError("BookArchivist addon missing during rebuildFiltered")
    return
  end

  local db = addon:GetDB()
  if not db then
    self:DebugPrint("[BookArchivist] rebuildFiltered: DB missing")
    self:LogError("BookArchivist DB missing during rebuildFiltered")
    return
  end
  local books
  if db.booksById and next(db.booksById) ~= nil then
    books = db.booksById
  else
    books = db.books or {}
  end
  local order = db.order or {}
  self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: start (order=%d)", #order))
  local query = self:GetSearchQuery()
  local previousQuery = self.__state.pagination.lastQuery
  self.__state.pagination.lastQuery = query
  if previousQuery ~= query then
    self.__state.pagination.page = 1
  end

  local selectedKey = self:GetSelectedKey()
  local selectionStillValid = false

  for _, key in ipairs(order) do
      local entry = books[key]
    if entry and matches(self, entry, query) then
      table.insert(filtered, key)
      if key == selectedKey then
        selectionStillValid = true
      end
    end
  end

  self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: %d matched of %d", #filtered, #order))

  local pageCount = self:GetPageCount(#filtered)
  self.__state.pagination.total = #filtered
  self.__state.pagination.pageCount = pageCount
  if self:GetPage() > pageCount then
    self:SetPage(pageCount > 0 and pageCount or 1, true)
  end

  if db then
    self:ApplySort(filtered, db)
  end

  if selectedKey and not selectionStillValid then
    self:SetSelectedKey(nil)
    self:NotifySelectionChanged()
  end
end
