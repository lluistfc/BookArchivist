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
  local scrollChild = self:GetListScrollChild()
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
  self:ReleaseAllRowButtons()

  local info = self:EnsureEntryInfo()
  local rowHeight = self:GetRowHeight()
  local paginationFrame = self:GetFrame("paginationFrame")

  if paginationFrame then
    paginationFrame:Show()
  end

  if info then
    info:SetText("")
    info:Hide()
  end

  if mode == modes.BOOKS then
    local filtered = self:GetFilteredKeys()
    local total = #filtered
    local dbCount = db.order and #db.order or 0
    self:DebugPrint(string.format("[BookArchivist] updateList filtered=%d totalDB=%d", total, dbCount))

    local pageSize = self:GetPageSize()
    local pageCount = self:GetPageCount(total)
    local page = self:GetPage()
    if page > pageCount then
      page = pageCount
      self.__state.pagination.page = page
    end
    if page < 1 then
      page = 1
      self.__state.pagination.page = page
    end

    local startIndex = (page - 1) * pageSize + 1
    local endIndex = math.min(total, startIndex + pageSize - 1)
    local visibleCount = (total > 0 and endIndex >= startIndex) and (endIndex - startIndex + 1) or 0

    local totalHeight = math.max(1, math.max(visibleCount, 0) * rowHeight)
    if hasMethod(scrollChild, "SetSize") then
      local width = (scrollFrame and scrollFrame:GetWidth()) or 336
      scrollChild:SetSize(width, totalHeight)
    else
      self:DebugPrint("[BookArchivist] scrollChild missing SetSize; skipping resize")
    end

    local layoutIndex = 0
    local hasSearch = self.GetSearchQuery and (self:GetSearchQuery() ~= "") or false
    for i = startIndex, endIndex do
      layoutIndex = layoutIndex + 1
      local button = self:AcquireRowButton()
      button:SetPoint("TOPLEFT", 0, -(layoutIndex-1) * rowHeight)
      self:SetRowContentAnchors(button, hasSearch)

      local key = filtered[i]
      if key then
    local books
    if db and db.booksById and next(db.booksById) ~= nil then
      books = db.booksById
    else
      books = db and db.books or {}
    end
    local entry = books[key]
        if entry then
          button.bookKey = key
          button.itemKind = "book"
      local title = entry.title or "(Untitled)"
      local meta = self:FormatRowMetadata(entry)
      button.titleText:SetText(title)
      button.metaText:SetText(meta)
      self:SyncMatchBadges(button, key)
        self:SyncRowFavorite(button, entry)

          if key == self:GetSelectedKey() then
            button.selected:Show()
            button.selectedEdge:Show()
          else
            button.selected:Hide()
            button.selectedEdge:Hide()
          end
        else
	      self:SyncRowFavorite(button, nil)
        end
      end
    end

    local noResults = self:GetFrame("noResultsText")
    if noResults then
      if total == 0 then
        if self:GetSearchQuery() ~= "" or self:HasActiveFilters() then
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
    return
  end

  if paginationFrame then
    paginationFrame:Hide()
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
    local button = self:AcquireRowButton()
    button:SetPoint("TOPLEFT", 0, -(i-1) * rowHeight)
    local hasSearch = self.GetSearchQuery and (self:GetSearchQuery() ~= "") or false
    self:SetRowContentAnchors(button, hasSearch)
    button.itemKind = row.kind

    if row.kind == "back" then
      button.locationName = nil
      button.bookKey = nil
      button.nodeRef = nil
	      button.titleText:SetText(BACK_ICON_TAG .. " " .. t("LOCATION_BACK_TITLE"))
	      button.metaText:SetText("|cFF999999" .. t("LOCATION_BACK_SUBTITLE") .. "|r")
      button.selected:Hide()
      button.selectedEdge:Hide()
      self:SyncRowFavorite(button, nil)
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
          local key = (childCount == 1) and "COUNT_SUBLOCATION_SINGULAR" or "COUNT_SUBLOCATION_PLURAL"
          detail = string.format(t(key), childCount)
      elseif bookCount > 0 or totalBooks > 0 then
          local key = (totalBooks == 1) and "COUNT_BOOK_SINGULAR" or "COUNT_BOOK_PLURAL"
          detail = string.format(t(key), totalBooks)
      else
          detail = t("LOCATION_EMPTY")
      end
      button.titleText:SetText(string.format("|cFFFFD100%s|r", row.name))
      button.metaText:SetText("|cFF999999" .. detail .. "|r")
      button.selected:Hide()
      button.selectedEdge:Hide()
      self:SyncRowFavorite(button, nil)
    elseif row.kind == "book" then
      local key = row.key
      button.bookKey = key
      button.locationName = nil
      button.nodeRef = nil
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
      button.titleText:SetText(title)
      button.metaText:SetText(meta)
      self:SyncMatchBadges(button, key)
      else
          button.titleText:SetText(string.format("|cFFFFD100%s|r", t("BOOK_UNKNOWN")))
          button.metaText:SetText("|cFF999999" .. t("BOOK_MISSING_DATA") .. "|r")
      end
        self:SyncRowFavorite(button, entry)
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
      self:SyncRowFavorite(button, nil)
    end
  end

  local infoMessage
  if not activeNode or (total == 0 and (#(state.path or {}) == 0)) then
	    infoMessage = "|cFF888888" .. t("LOCATIONS_EMPTY") .. "|r"
  else
    local hasChildren = activeNode.childNames and #activeNode.childNames > 0
    if hasChildren then
      local count = #activeNode.childNames
        local key = (count == 1) and "COUNT_LOCATION_SINGULAR" or "COUNT_LOCATION_PLURAL"
        infoMessage = string.format("|cFFFFD100" .. t(key) .. "|r", count)
    else
      local count = activeNode.books and #activeNode.books or 0
        local key = (count == 1) and "COUNT_BOOKS_IN_LOCATION_SINGULAR" or "COUNT_BOOKS_IN_LOCATION_PLURAL"
        infoMessage = string.format("|cFFFFD100" .. t(key) .. "|r", count)
    end
  end

  if info then
    local crumb = self:GetLocationBreadcrumbText()
    local crumbText = crumb and ("|cFFCCCCCC" .. crumb .. "|r") or nil
    local detailText = infoMessage
    if crumbText and detailText then
      info:SetText(string.format("%s  |cFF666666•|r  %s", crumbText, detailText))
    else
	      info:SetText(detailText or crumbText or ("|cFF888888" .. t("LOCATIONS_BROWSE_SAVED") .. "|r"))
    end
    local tipRow = self:GetFrame("listTipRow") or self:EnsureListTipRow()
    if tipRow then
      info:ClearAllPoints()
      info:SetPoint("TOPLEFT", tipRow, "TOPLEFT", 0, 0)
      info:SetPoint("BOTTOMRIGHT", tipRow, "BOTTOMRIGHT", 0, 0)
    end
    info:Show()
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
end
