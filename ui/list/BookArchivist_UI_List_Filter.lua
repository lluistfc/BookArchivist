---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local function matches(self, entry, tokens)
  local passesFilters = true
  if self.GetListMode then
    passesFilters = self:EntryMatchesFilters(entry)
  end

  if not tokens or #tokens == 0 then
    return passesFilters
  end

  if not passesFilters then
    return false
  end

	local haystack = entry.searchText or ""
	haystack = haystack:lower()
	for i = 1, #tokens do
		local token = tokens[i]
		if token ~= "" and not haystack:find(token, 1, true) then
			return false
		end
	end

  return true
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

  local categoryId = (self.GetCategoryId and self:GetCategoryId()) or "__all__"
  local isRecentView = (categoryId == "__recent__")
  local baseKeys
  if isRecentView and addon.Recent and addon.Recent.GetList then
    baseKeys = addon.Recent:GetList()
  else
    baseKeys = order
  end

  self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: start (order=%d, category=%s)", #baseKeys, tostring(categoryId)))
  local query = self:GetSearchQuery()
  local tokens = {}
  for token in query:lower():gmatch("%S+") do
		table.insert(tokens, token)
	end
  local previousQuery = self.__state.pagination.lastQuery
  self.__state.pagination.lastQuery = query
  if previousQuery ~= query then
    self.__state.pagination.page = 1
  end

  local selectedKey = self:GetSelectedKey()
  local selectionStillValid = false

  for _, key in ipairs(baseKeys) do
      local entry = books[key]
    if entry and matches(self, entry, tokens) then
      table.insert(filtered, key)
      if key == selectedKey then
        selectionStillValid = true
      end
    end
  end

	self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: %d matched of %d", #filtered, #baseKeys))

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
