---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then return end

local BACK_ICON_TAG = "|TInterface\\Buttons\\UI-SpellbookIcon-PrevPage-Up:14:14:0:0|t"

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local function hasMethod(obj, methodName)
  return obj and type(obj[methodName]) == "function"
end

function ListUI:UpdateList()
  -- Skip if async filtering is in progress
  if self.__state.isAsyncFiltering then
    self:DebugPrint("[BookArchivist] updateList skipped (async filtering in progress)")
    return
  end
  
  local dataProvider = self:GetDataProvider()
  if not dataProvider then
    self:DebugPrint("[BookArchivist] updateList skipped (data provider missing) - UI not fully initialized")
    -- Clear loading state if it was set
    if self.__state.isLoading then
      self.__state.isLoading = false
      if self.SetTabsEnabled then
        self:SetTabsEnabled(true)
      end
    end
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

  local info = self:EnsureEntryInfo()
  local paginationFrame = self:GetFrame("paginationFrame")

  if paginationFrame then
    paginationFrame:Show()
  end

  if info then
    info:SetText("")
    info:Hide()
  end

  -- Clear existing data
  dataProvider:Flush()

  if mode == modes.BOOKS then
    local filtered = self:GetFilteredKeys()
    local total = #filtered
    local dbCount = db.order and #db.order or 0
    
    -- Safety check: if filtered is empty but DB has books, rebuild
    -- BUT: Only do this for "All Books" - filtered categories like Favorites can legitimately be empty
    local categoryId = (self.GetCategoryId and self:GetCategoryId()) or "__all__"
    local isFilteredCategory = (categoryId ~= "__all__")
    
    if total == 0 and dbCount > 0 and not isFilteredCategory then
      self:DebugPrint(string.format("[BookArchivist] updateList: filtered empty but DB has %d books, forcing rebuild", dbCount))
      -- Clear any stuck async filtering state before forcing rebuild
      if self.__state then
        self.__state.isAsyncFiltering = false
        self.__state.asyncFilterStartTime = nil
      end
      if self.RebuildFiltered then
        self:RebuildFiltered()
        -- RebuildFiltered will call UpdateList when done, so return now
        return
      end
    end
    
    self:DebugPrint(string.format("[BookArchivist] updateList filtered=%d totalDB=%d", total, dbCount))

    local pageSize = self:GetPageSize()
    local page = self:GetPage()
    
    -- Use shared pagination helper
    local paginatedKeys, _, currentPage, pageCount = self:PaginateArray(filtered, pageSize, page)
    
    -- Update page state if it changed (e.g., clamped to valid range)
    if currentPage ~= page then
      self.__state.pagination.page = currentPage
    end

    local hasSearch = self.GetSearchQuery and (self:GetSearchQuery() ~= "") or false
    local selectedKey = self:GetSelectedKey()
    
    for _, key in ipairs(paginatedKeys) do
      if key then
        local books
        if db and db.booksById and next(db.booksById) ~= nil then
          books = db.booksById
        else
          books = db and db.books or {}
        end
        local entry = books[key]
        if entry then
          local title = entry.title or "(Untitled)"
          local meta = self:FormatRowMetadata(entry)
          local matchFlags = self:GetSearchMatchKind(key)
          
          -- Build element data for data provider
          local elementData = {
            bookKey = key,
            itemKind = "book",
            title = title,
            meta = meta,
            isSelected = (key == selectedKey),
            isFavorite = entry.isFavorite,
            showTitleBadge = matchFlags and matchFlags.title or false,
            showTextBadge = matchFlags and matchFlags.text or false,
          }
          dataProvider:Insert(elementData)
        end
      end
    end
    self:DebugPrint(string.format("[BookArchivist] UpdateList: Added %d books to data provider", dataProvider:GetSize()))

    local noResults = self:GetFrame("noResultsText")
    if noResults then
      if total == 0 then
        local hasSearch = (self.GetSearchQuery and self:GetSearchQuery() ~= "") or false
        local hasFilters = (self.HasActiveFilters and self:HasActiveFilters()) or false
        if hasSearch or hasFilters then
          noResults:SetText("|cFF999999" .. t("LIST_EMPTY_SEARCH") .. "|r")
        else
          noResults:SetText("|cFF999999" .. t("LIST_EMPTY_NO_BOOKS") .. "|r")
        end
        noResults:Show()
      else
        noResults:Hide()
      end
    end

    self:UpdatePaginationUI(total, pageCount)

    self:UpdateCountsDisplay()
    
    -- Force scroll box to update after data provider changes
    local scrollBox = self:GetFrame("scrollBox") or self:GetFrame("scrollFrame")
    if scrollBox and scrollBox.InvalidateDataProvider then
      scrollBox:InvalidateDataProvider()
    end
    
    -- Use C_Timer to defer loading overlay hide and welcome panel render
    -- This ensures the UI has time to fully update before triggering reader
    C_Timer.After(0.05, function()
      local uiFrame = self:GetUIFrame()
      if uiFrame and uiFrame.__loadingContainer then
        uiFrame.__loadingContainer:SetAlpha(0)
        uiFrame.__loadingContainer:Hide()
      end
      
      -- Trigger reader to show welcome panel if no selection
      local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
      if ReaderUI and ReaderUI.RenderSelected then
        ReaderUI:RenderSelected()
      end
    end)
    return
  end

  if paginationFrame then
    paginationFrame:Hide()
  end
  
  -- Get location pagination info
  local locPagination = self.GetLocationPagination and self:GetLocationPagination() or { totalRows = 0, currentPage = 1, totalPages = 1 }
  
  -- Update pagination for locations mode
  if paginationFrame and locPagination.totalRows > (self:GetPageSize() or 100) then
    paginationFrame:Show()
    self:UpdatePaginationUI(locPagination.totalRows, locPagination.totalPages)
  end
  
  local rows = self:GetLocationRows()
  local total = #rows
  local state = self:GetLocationState()
  local activeNode = state.activeNode or state.root
  local selectedKey = self:GetSelectedKey()
  local hasSearch = self.GetSearchQuery and (self:GetSearchQuery() ~= "") or false

  for i = 1, total do
    local row = rows[i]
    local elementData = {}

    if row.kind == "back" then
      elementData = {
        itemKind = "back",
        title = BACK_ICON_TAG .. " " .. t("LOCATION_BACK_TITLE"),
        meta = "|cFF999999" .. t("LOCATION_BACK_SUBTITLE") .. "|r",
        isSelected = false,
        isFavorite = false,
      }
    elseif row.kind == "location" then
      local childNode = row.node
      local childCount = childNode and childNode.childNames and #childNode.childNames or 0
      local bookCount = childNode and childNode.books and #childNode.books or 0
      local totalBooks = childNode and childNode.totalBooks or bookCount
      local detail
      if childCount > 0 then
        local key = (childCount == 1) and "COUNT_SUBLOCATION_SINGULAR" or "COUNT_SUBLOCATION_PLURAL"
        detail = string.format(t(key), childCount)
      elseif bookCount > 0 or totalBooks > 0 then
        local key = (totalBooks == 1) and "COUNT_BOOK_SINGULAR" or "COUNT_BOOK_PLURAL"
        detail = string.format(t(key), totalBooks)
      else
        detail = t("LOCATION_EMPTY")
      end
      elementData = {
        itemKind = "location",
        locationName = row.name,
        nodeRef = childNode,
        title = string.format("|cFFFFD100%s|r", row.name),
        meta = "|cFF999999" .. detail .. "|r",
        isSelected = false,
        isFavorite = false,
      }
    elseif row.kind == "book" then
      local key = row.key
      local books
      if db and db.booksById and next(db.booksById) ~= nil then
        books = db.booksById
      else
        books = db and db.books or nil
      end
      local entry = key and books and books[key]
      if entry then
        local title = entry.title or t("BOOK_UNTITLED")
        local meta = self:FormatRowMetadata(entry)
        local matchFlags = self:GetSearchMatchKind(key)
        elementData = {
          bookKey = key,
          itemKind = "book",
          title = title,
          meta = meta,
          isSelected = (key == selectedKey),
          isFavorite = entry.isFavorite,
          showTitleBadge = matchFlags and matchFlags.title or false,
          showTextBadge = matchFlags and matchFlags.text or false,
        }
      else
        elementData = {
          bookKey = key,
          itemKind = "book",
          title = string.format("|cFFFFD100%s|r", t("BOOK_UNKNOWN")),
          meta = "|cFF999999" .. t("BOOK_MISSING_DATA") .. "|r",
          isSelected = (key == selectedKey),
          isFavorite = false,
        }
      end
    else
      elementData = {
        itemKind = "unknown",
        title = "?",
        meta = "",
        isSelected = false,
        isFavorite = false,
      }
    end
    
    dataProvider:Insert(elementData)
  end
  
  self:DebugPrint(string.format("[BookArchivist] UpdateList: Added %d locations to data provider", dataProvider:GetSize()))

  -- Footer info is now minimal since breadcrumb moved to header
  if info then
    info:SetText("") -- Location info now shown in header
  end

  local noResults = self:GetFrame("noResultsText")
  if noResults then
    if total == 0 then
	      noResults:SetText("|cFF999999" .. t("LOCATIONS_NO_RESULTS") .. "|r")
      noResults:Show()
    else
      noResults:Hide()
    end
  end

  self:UpdateCountsDisplay()
  
  -- Force scroll box to update after data provider changes
  local scrollBox = self:GetFrame("scrollBox") or self:GetFrame("scrollFrame")
  if scrollBox and scrollBox.InvalidateDataProvider then
    scrollBox:InvalidateDataProvider()
  end
  
  -- Use C_Timer to defer loading overlay hide and welcome panel render
  -- This ensures the UI has time to fully update before triggering reader
  C_Timer.After(0.05, function()
    local uiFrame = self:GetUIFrame()
    if uiFrame and uiFrame.__loadingContainer then
      uiFrame.__loadingContainer:SetAlpha(0)
      uiFrame.__loadingContainer:Hide()
    end
    
    -- Trigger reader to show welcome panel if no selection
    local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
    if ReaderUI and ReaderUI.RenderSelected then
      ReaderUI:RenderSelected()
    end
  end)
end
