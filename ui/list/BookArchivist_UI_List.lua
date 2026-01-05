---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ListUI = {}
BookArchivist.UI.List = ListUI

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local Metrics = BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics or {}

local DEFAULT_LIST_MODES = {
  BOOKS = "books",
  LOCATIONS = "locations",
}

local DEFAULT_ROW_HEIGHT = Metrics.ROW_H or 36
local SEARCH_DEBOUNCE_SECONDS = 0.2
local PAGE_SIZES = { 10, 25, 50, 100 }
local PAGE_SIZE_DEFAULT = 25

local SORT_OPTIONS = {
  { value = "title", labelKey = "SORT_TITLE" },
  { value = "zone", labelKey = "SORT_ZONE" },
  { value = "firstSeen", labelKey = "SORT_FIRST_SEEN" },
  { value = "lastSeen", labelKey = "SORT_LAST_SEEN" },
}

local QUICK_FILTERS = {
  { key = "favoritesOnly" },
}

local state = ListUI.__state or {}
ListUI.__state = state

state.ctx = state.ctx or {}
state.frames = state.frames or {}
state.location = state.location or {}
state.location.path = state.location.path or {}
state.location.rows = state.location.rows or {}
state.location.root = state.location.root
state.location.activeNode = state.location.activeNode
state.buttonPool = state.buttonPool or { free = {}, active = {} }
state.constants = state.constants or {}
state.constants.rowHeight = state.constants.rowHeight or DEFAULT_ROW_HEIGHT
state.listModes = state.listModes or DEFAULT_LIST_MODES
state.filters = state.filters or {}
state.widgets = state.widgets or {}
state.search = state.search or { pendingToken = 0 }
state.pagination = state.pagination or { page = 1, pageSize = PAGE_SIZE_DEFAULT }
state.filterButtons = state.filterButtons or {}
state.locationMenuFrame = state.locationMenuFrame or nil
state.selectedListTab = state.selectedListTab or 1

local function fallbackDebugPrint(...)
  BookArchivist:DebugPrint(...)
end

local function normalizeTextValue(text)
  text = text or ""
  text = tostring(text)
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  return text:lower()
end

local function getZoneLabel(entry)
  if not entry or not entry.location then
    return nil
  end
  local location = entry.location
  if location.zoneText and location.zoneText ~= "" then
    return location.zoneText
  end
  if location.zoneChain and #location.zoneChain > 0 then
    return table.concat(location.zoneChain, " > ")
  end
  return nil
end

local function entryPageCount(entry)
  if not entry or not entry.pages then
    return 0
  end
  local count = 0
  for _ in pairs(entry.pages) do
    count = count + 1
  end
  return count
end

local function entryHasLocation(entry)
  return getZoneLabel(entry) ~= nil
end

local function entryIsUnread(entry)
  if not entry then
    return false
  end
  if entry.seenCount and entry.seenCount > 1 then
    return false
  end
  if entry.lastSeenAt and entry.firstSeenAt and entry.lastSeenAt ~= entry.firstSeenAt then
    return false
  end
  return true
end

local function applyContext(ctx, overrides)
  if not overrides then
    return ctx or {}
  end
  ctx = ctx or {}
  for key, value in pairs(overrides) do
    ctx[key] = value
  end
  return ctx
end

function ListUI:Init(context)
  local ctx = context or {}
  ctx.debugPrint = ctx.debugPrint or fallbackDebugPrint
  self.__state.ctx = ctx
  if context and context.listModes then
    self.__state.listModes = context.listModes
  elseif not self.__state.listModes then
    self.__state.listModes = DEFAULT_LIST_MODES
  end
end

function ListUI:SetCallbacks(callbacks)
  local ctx = self:GetContext()
  local merged = applyContext(ctx, callbacks)
  merged.debugPrint = merged.debugPrint or fallbackDebugPrint
  self.__state.ctx = merged
end

function ListUI:GetContext()
  return self.__state.ctx or {}
end

function ListUI:GetTimeFormatter()
  local ctx = self:GetContext()
  return (ctx and ctx.fmtTime) or function(ts)
    if not ts then return "" end
    return date("%Y-%m-%d %H:%M", ts)
  end
end

function ListUI:GetLocationFormatter()
  local ctx = self:GetContext()
  return (ctx and ctx.formatLocationLine) or function()
    return nil
  end
end

function ListUI:GetListModes()
  return self.__state.listModes or DEFAULT_LIST_MODES
end

function ListUI:TabIdToMode(tabId)
  local modes = self:GetListModes()
  if tabId == 2 then
    return modes.LOCATIONS
  end
  return modes.BOOKS
end

function ListUI:ModeToTabId(mode)
  local modes = self:GetListModes()
  if mode == modes.LOCATIONS then
    return 2
  end
  return 1
end

function ListUI:GetSortOptions()
  local opts = {}
  for i, opt in ipairs(SORT_OPTIONS) do
    opts[i] = { value = opt.value, label = t(opt.labelKey) }
  end
  return opts
end

function ListUI:GetSortMode()
  local ctx = self:GetContext()
  if ctx and ctx.getSortMode then
    local mode = ctx.getSortMode()
    if mode and mode ~= "" then
      return mode
    end
  end
  return SORT_OPTIONS[1].value
end

function ListUI:SetSortMode(mode)
  local ctx = self:GetContext()
  if ctx and ctx.setSortMode then
    ctx.setSortMode(mode)
  end
end

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

local function normalizePageSize(size)
  size = tonumber(size)
  for _, allowed in ipairs(PAGE_SIZES) do
    if size == allowed then
      return allowed
    end
  end
  return PAGE_SIZE_DEFAULT
end

function ListUI:GetPageSizes()
  return PAGE_SIZES
end

function ListUI:GetPageSize()
  local ctx = self:GetContext()
  local persisted = ctx and ctx.getPageSize and ctx.getPageSize()
  local size = normalizePageSize(persisted or self.__state.pagination.pageSize)
  self.__state.pagination.pageSize = size
  return size
end

function ListUI:SetPageSize(size)
  local normalized = normalizePageSize(size)
  self.__state.pagination.pageSize = normalized
  self.__state.pagination.page = 1
  local ctx = self:GetContext()
  if ctx and ctx.setPageSize then
    ctx.setPageSize(normalized)
  end
  self:RunSearchRefresh()
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
  if not skipRefresh then
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
  self:UpdateFilterButtons()
  self:RebuildFiltered()
  self:UpdateList()
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

function ListUI:InitializeSortDropdown(dropdown)
  if not dropdown or type(UIDropDownMenu_SetWidth) ~= "function" then
    return
  end

  UIDropDownMenu_SetWidth(dropdown, 160)
	  UIDropDownMenu_SetText(dropdown, t("SORT_DROPDOWN_PLACEHOLDER"))

  UIDropDownMenu_Initialize(dropdown, function(self)
    local currentSort = ListUI:GetSortMode()
    local currentCategory = (ListUI.GetCategoryId and ListUI:GetCategoryId()) or "__all__"

    -- Inject virtual category choices at the top of the sort menu so
    -- users can switch between All and Favorites from a single
    -- selector. Use title-style rows to visually separate the
    -- category group from the sort group.
    if ListUI.IsVirtualCategoriesEnabled and ListUI:IsVirtualCategoriesEnabled() then
      local headerCategories = UIDropDownMenu_CreateInfo()
      headerCategories.isTitle = true
      headerCategories.notCheckable = true
      headerCategories.text = t("SORT_GROUP_CATEGORY")
      UIDropDownMenu_AddButton(headerCategories)

      local infoAll = UIDropDownMenu_CreateInfo()
      infoAll.text = t("CATEGORY_ALL")
      infoAll.func = function()
        ListUI:SetCategoryId("__all__")
      end
      infoAll.checked = (currentCategory == "__all__")
      UIDropDownMenu_AddButton(infoAll)

      local infoFav = UIDropDownMenu_CreateInfo()
      infoFav.text = t("CATEGORY_FAVORITES")
      infoFav.func = function()
        ListUI:SetCategoryId("__favorites__")
      end
      infoFav.checked = (currentCategory == "__favorites__")
      UIDropDownMenu_AddButton(infoFav)

			local infoRecent = UIDropDownMenu_CreateInfo()
			infoRecent.text = t("CATEGORY_RECENT")
			infoRecent.func = function()
				ListUI:SetCategoryId("__recent__")
			end
			infoRecent.checked = (currentCategory == "__recent__")
			UIDropDownMenu_AddButton(infoRecent)

      local sep = UIDropDownMenu_CreateInfo()
      sep.disabled = true
      sep.notCheckable = true
      sep.text = " "
      UIDropDownMenu_AddButton(sep)
    end

    local current = currentSort

    local headerSort = UIDropDownMenu_CreateInfo()
    headerSort.isTitle = true
    headerSort.notCheckable = true
    headerSort.text = t("SORT_GROUP_ORDER")
    UIDropDownMenu_AddButton(headerSort)

    for _, option in ipairs(SORT_OPTIONS) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = t(option.labelKey)
      info.value = option.value
      info.func = function()
        ListUI:SetSortMode(option.value)
        ListUI:UpdateSortDropdown()
        ListUI:RebuildFiltered()
        ListUI:UpdateList()
      end
      info.checked = (current == option.value)
      UIDropDownMenu_AddButton(info)
    end
  end)

  self:SetFrame("sortDropdown", dropdown)
  self:UpdateSortDropdown()
end

function ListUI:UpdateSortDropdown()
  local dropdown = self:GetFrame("sortDropdown")
  if not dropdown or type(UIDropDownMenu_SetText) ~= "function" then
    return
  end
  local current = self:GetSortMode()
  local label = nil
  for _, option in ipairs(SORT_OPTIONS) do
    if option.value == current then
      label = t(option.labelKey)
      break
    end
  end
	UIDropDownMenu_SetText(dropdown, label or t("SORT_DROPDOWN_PLACEHOLDER"))
end

function ListUI:GetRowHeight()
  return self.__state.constants.rowHeight or DEFAULT_ROW_HEIGHT
end

function ListUI:SetRowHeight(height)
  if type(height) == "number" and height > 0 then
    self.__state.constants.rowHeight = height
  end
end

function ListUI:FormatRowMetadata(entry)
  if not entry then
    return ""
  end
  local parts = {}
  if entry.creator and entry.creator ~= "" then
    table.insert(parts, entry.creator)
  end

  local zone = getZoneLabel(entry)
  if zone then
    table.insert(parts, zone)
  end

  if #parts == 0 then
	    return t("BOOK_META_FALLBACK") -- fallback
  end
  return table.concat(parts, "  |cFF666666•|r  ")
end

function ListUI:EntryMatchesFilters(entry)
  local filters = self:GetFiltersState()
  if not filters then
    return true
  end
  if filters.hasLocation and not entryHasLocation(entry) then
    return false
  end
  if filters.multiPage and entryPageCount(entry) <= 1 then
    return false
  end
  if filters.unread and not entryIsUnread(entry) then
    return false
  end
	if filters.favoritesOnly and not (entry and entry.isFavorite) then
		return false
	end
  return true
end

local function getBooksTable(db)
  if not db then return nil end
  if db.booksById and next(db.booksById) ~= nil then
    return db.booksById
  end
  return db.books
end

local function alphaComparator(db, selector)
  return function(aKey, bKey)
    local books = getBooksTable(db) or {}
    local aEntry = books[aKey] or {}
    local bEntry = books[bKey] or {}
    local aVal = normalizeTextValue(selector(aEntry) or "")
    local bVal = normalizeTextValue(selector(bEntry) or "")
    if aVal == bVal then
      return aKey < bKey
    end
    return aVal < bVal
  end
end

local function numericComparator(db, selector, desc)
  return function(aKey, bKey)
    local books = getBooksTable(db) or {}
    local aEntry = books[aKey] or {}
    local bEntry = books[bKey] or {}
    local aVal = selector(aEntry) or 0
    local bVal = selector(bEntry) or 0
    if aVal == bVal then
      return aKey < bKey
    end
    if desc then
      return aVal > bVal
    end
    return aVal < bVal
  end
end

function ListUI:GetSortComparator(mode, db)
  local books = getBooksTable(db)
  if not books then
    return nil
  end
  if mode == "title" then
    return alphaComparator(db, function(entry)
      return entry.title or ""
    end)
  elseif mode == "zone" then
    return alphaComparator(db, function(entry)
      return getZoneLabel(entry) or "zzzzz"
    end)
  elseif mode == "firstSeen" then
    return numericComparator(db, function(entry)
      return entry.firstSeenAt or entry.createdAt or 0
    end, false)
  elseif mode == "lastSeen" then
    return numericComparator(db, function(entry)
      return entry.lastSeenAt or entry.createdAt or 0
    end, true)
  end
  return nil
end

function ListUI:ApplySort(filteredKeys, db)
  local mode = self:GetSortMode()
  local categoryId = (self.GetCategoryId and self:GetCategoryId()) or "__all__"
  local isFavoritesView = (categoryId == "__favorites__")
  local isRecentView = (categoryId == "__recent__")

  -- In the Recently Read virtual category, ordering is driven by the
  -- MRU list managed by the Recent service; skip additional sorting.
  if isRecentView then
		self:UpdateSortDropdown()
    return
  end
  local effectiveMode = mode
  local comparator = self:GetSortComparator(effectiveMode, db)
  if comparator then
    table.sort(filteredKeys, comparator)
  end
  self:UpdateSortDropdown()
end

function ListUI:UpdateCountsDisplay()
  local headerCount = self:GetFrame("headerCountText")
  if not headerCount or not headerCount.SetText then
    return
  end
  local addon = self:GetAddon()
  local db = addon and addon:GetDB() or {}
  local total = db.order and #db.order or 0
  local modes = self:GetListModes()
  local mode = self:GetListMode()

  if mode == modes.BOOKS then
    local filtered = #self:GetFilteredKeys()
    if total == 0 then
        headerCount:SetText(t("BOOK_LIST_EMPTY_HEADER"))
    elseif filtered == total then
        local key = (total == 1) and "COUNT_BOOK_SINGULAR" or "COUNT_BOOK_PLURAL"
        headerCount:SetText(string.format("|cFFFFD100" .. t(key) .. "|r", total))
    else
        headerCount:SetText(string.format("|cFFFFD100" .. t("COUNT_BOOKS_FILTERED_FORMAT") .. "|r", filtered, total))
    end
    return
  end

  local state = self:GetLocationState()
  local node = state.activeNode or state.root
  if not node then
	    headerCount:SetText(t("LOCATIONS_BROWSE_HEADER"))
    return
  end
  local locationBooks = node.totalBooks or (node.books and #node.books) or 0
  local childCount = node.childNames and #node.childNames or 0
  if childCount > 0 then
      local key = (childCount == 1) and "COUNT_LOCATION_SINGULAR" or "COUNT_LOCATION_PLURAL"
      headerCount:SetText(string.format("|cFFFFD100" .. t(key) .. "|r", childCount))
  else
      local key = (locationBooks == 1) and "COUNT_BOOKS_HERE_SINGULAR" or "COUNT_BOOKS_HERE_PLURAL"
      headerCount:SetText(string.format("|cFFFFD100" .. t(key) .. "|r", locationBooks))
  end
end

function ListUI:UpdateResumeButton()
  local button = self:GetFrame("resumeButton")
  if not button then
    return
  end
  local addon = self:GetAddon()
  if not addon or not addon.GetLastBookId or not addon.GetDB then
    button:Hide()
    return
  end
  local lastId = addon:GetLastBookId()
  if not lastId then
    button:Hide()
    return
  end
  local db = addon:GetDB() or {}
  local books = (db.booksById and next(db.booksById) ~= nil) and db.booksById or db.books
  if not (books and books[lastId]) then
    button:Hide()
    return
  end
  button:Show()
end

function ListUI:GetLocationState()
  return self.__state.location
end

function ListUI:GetButtonPool()
  return self.__state.buttonPool
end

function ListUI:GetFrames()
  return self.__state.frames
end

function ListUI:SetUIFrame(frame)
  self.__state.uiFrame = frame
end

function ListUI:GetUIFrame()
  local ctx = self:GetContext()
  if ctx and ctx.getUIFrame then
    local ok, result = pcall(ctx.getUIFrame, ctx)
    if ok and result then
      return result
    end
  end
  return self.__state.uiFrame
end

function ListUI:SetFrame(name, frame)
  if not name then return end
  self.__state.frames[name] = frame
  if frame then
    self:RememberWidget(name, frame)
    local ui = self:GetUIFrame()
    if ui then
      ui[name] = frame
    end
  end
  return frame
end

function ListUI:GetFrame(name)
  return self.__state.frames[name]
end

function ListUI:RememberWidget(name, widget)
  local ctx = self:GetContext()
  if ctx and ctx.rememberWidget then
    return ctx.rememberWidget(name, widget)
  end
  return widget
end

function ListUI:SafeCreateFrame(frameType, name, parent, ...)
  local ctx = self:GetContext()
  if ctx and ctx.safeCreateFrame then
    return ctx.safeCreateFrame(frameType, name, parent, ...)
  end
  if CreateFrame then
    return CreateFrame(frameType, name, parent, ...)
  end
end

function ListUI:GetAddon()
  local ctx = self:GetContext()
  if ctx and ctx.getAddon then
    return ctx.getAddon()
  end
end

function ListUI:GetListMode()
  local ctx = self:GetContext()
  if ctx and ctx.getListMode then
    return ctx.getListMode()
  end
  return self:GetListModes().BOOKS
end

function ListUI:SetListMode(mode)
  if mode then
    self.__state.selectedListTab = self:ModeToTabId(mode)
  end
  local ctx = self:GetContext()
  if ctx and ctx.setListMode then
    ctx.setListMode(mode)
  end
end

function ListUI:GetSelectedListTab()
  local tab = tonumber(self.__state.selectedListTab) or 1
  if tab == 2 then
    return 2
  end
  return 1
end

function ListUI:SetSelectedListTab(tabId)
  self.__state.selectedListTab = (tabId == 2) and 2 or 1
end

function ListUI:SyncSelectedTabFromMode()
  local mode = self:GetListMode()
  local tabId = self:ModeToTabId(mode)
  self:SetSelectedListTab(tabId)
  return tabId
end

function ListUI:GetFilteredKeys()
  local ctx = self:GetContext()
  if ctx and ctx.getFilteredKeys then
    return ctx.getFilteredKeys()
  end
  return {}
end

function ListUI:GetSelectedKey()
  local ctx = self:GetContext()
  if ctx and ctx.getSelectedKey then
    return ctx.getSelectedKey()
  end
end

function ListUI:SetSelectedKey(key)
  local ctx = self:GetContext()
  if ctx and ctx.setSelectedKey then
    ctx.setSelectedKey(key)
  end
end

function ListUI:DisableDeleteButton()
  local ctx = self:GetContext()
  if ctx and ctx.disableDeleteButton then
    ctx.disableDeleteButton()
  end
end

function ListUI:NotifySelectionChanged()
  local ctx = self:GetContext()
  if ctx and ctx.onSelectionChanged then
    ctx.onSelectionChanged()
  end
  if self.UpdateResumeButton then
    self:UpdateResumeButton()
  end
end

function ListUI:ShowBookContextMenu(anchorButton, bookKey)
  if not anchorButton or not bookKey then
    return
  end
  local addon = self:GetAddon()
  if not addon or not addon.Favorites or not addon.Favorites.IsFavorite then
    return
  end
  local isFav = addon.Favorites:IsFavorite(bookKey)
  local menuFrame = self.GetLocationMenuFrame and self:GetLocationMenuFrame() or nil
  if not menuFrame then
    return
  end
  local label = isFav and t("READER_FAVORITE_REMOVE") or t("READER_FAVORITE_ADD")
  local menu = {
    { text = label, notCheckable = true, func = function()
      if isFav and addon.Favorites.Set then
        addon.Favorites:Set(bookKey, false)
      else
        addon.Favorites:Set(bookKey, true)
      end
      if type(addon.RefreshUI) == "function" then
        addon:RefreshUI()
      end
    end },
  }
  if type(EasyMenu) == "function" then
	EasyMenu(menu, menuFrame, anchorButton, 0, 0, "MENU")
	return
  end

  -- Manual dropdown construction if EasyMenu helper is unavailable but
  -- the underlying UIDropDownMenu API exists.
  if type(UIDropDownMenu_Initialize) == "function" and type(ToggleDropDownMenu) == "function" and type(UIDropDownMenu_CreateInfo) == "function" and type(UIDropDownMenu_AddButton) == "function" then
	UIDropDownMenu_Initialize(menuFrame, function(_, level)
		level = level or 1
		for _, item in ipairs(menu) do
			local info = UIDropDownMenu_CreateInfo()
			for k, v in pairs(item) do
				info[k] = v
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end, "MENU")
	ToggleDropDownMenu(1, nil, menuFrame, anchorButton, 0, 0)
	return
  end

  -- Final fallback: perform the action immediately.
  local first = menu[1]
  if first and type(first.func) == "function" then
	first.func()
  end
end

function ListUI:GetWidget(name)
  local ctx = self:GetContext()
  if ctx and ctx.getWidget then
    return ctx.getWidget(name)
  end
end

function ListUI:GetSearchText()
  local box = self:GetFrame("searchBox") or self:GetWidget("searchBox")
  if not box or not box.GetText then
    return ""
  end
  return box:GetText() or ""
end

function ListUI:ClearSearchMatchKinds()
  local search = self.__state.search or {}
  self.__state.search = search
  search.matchFlags = {}
end

function ListUI:SetSearchMatchKind(key, kind)
  if not key or not kind then
    return
  end
  local search = self.__state.search or {}
  self.__state.search = search
  search.matchFlags = search.matchFlags or {}
  local flags = search.matchFlags[key] or {}
  if kind == "title" then
    flags.title = true
  elseif kind == "content" then
    flags.text = true
  end
  search.matchFlags[key] = flags
end

function ListUI:GetSearchMatchKind(key)
  local search = self.__state.search
  if not search or not search.matchFlags then
    return nil
  end
  return search.matchFlags[key]
end

function ListUI:ClearSearch()
  local box = self:GetFrame("searchBox") or self:GetWidget("searchBox")
  if box and box.SetText then
    box:SetText("")
    if box.ClearFocus then
      box:ClearFocus()
    end
  end
  self:RunSearchRefresh()
end

function ListUI:UpdateSearchClearButton()
  local button = self:GetFrame("searchClearButton")
  if not button then
    return
  end
  if self:GetSearchQuery() ~= "" then
    button:Show()
  else
    button:Hide()
  end
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

function ListUI:RunSearchRefresh()
  self:RebuildFiltered()
  self:UpdateList()
end

function ListUI:ScheduleSearchRefresh()
  local tracker = self.__state.search
  tracker.pendingToken = (tracker.pendingToken or 0) + 1
  local token = tracker.pendingToken
  if not C_Timer or not C_Timer.After then
    tracker.pendingToken = nil
    self:RunSearchRefresh()
    return
  end
  C_Timer.After(SEARCH_DEBOUNCE_SECONDS, function()
    if tracker.pendingToken ~= token then
      return
    end
    tracker.pendingToken = nil
    self:RunSearchRefresh()
  end)
end

function ListUI:GetInfoText()
  return self:GetFrame("infoText")
end

function ListUI:DebugPrint(...)
  local ctx = self:GetContext()
  local logger = (ctx and ctx.debugPrint) or fallbackDebugPrint
  logger(...)
end

function ListUI:LogError(message)
  local ctx = self:GetContext()
  if ctx and ctx.logError then
    ctx.logError(message)
  elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(tostring(message))
  end
end

return ListUI
