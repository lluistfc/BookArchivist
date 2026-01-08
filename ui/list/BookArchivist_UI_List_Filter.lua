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
	if self.ClearSearchMatchKinds then
		self:ClearSearchMatchKinds()
	end
  local previousQuery = self.__state.pagination.lastQuery
  self.__state.pagination.lastQuery = query
  if previousQuery ~= query then
    self.__state.pagination.page = 1
  end

  local selectedKey = self:GetSelectedKey()
  
  -- Use Iterator for throttled filtering to prevent UI freeze
  local Iterator = BookArchivist and BookArchivist.Iterator
  if Iterator and #baseKeys > 100 then
    -- Prevent concurrent async filtering
    if self.__state.isAsyncFiltering then
      self:DebugPrint("[BookArchivist] rebuildFiltered: async filtering already in progress, skipping")
      return
    end
    
    -- Throttled path for large datasets
    self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: using throttled iteration for %d books", #baseKeys))
    
    -- Set async filtering flag to prevent premature UpdateList
    self.__state.isAsyncFiltering = true
    
    -- Show loading indicator
    local noResults = self:GetFrame("noResultsText")
    if noResults then
      noResults:SetText("|cFFFFFF00Filtering books...|r")
      noResults:Show()
    end
    
    -- Convert array to table for Iterator
    local keysTable = {}
    for i, key in ipairs(baseKeys) do
      keysTable[i] = key
    end
    
    Iterator:Start(
      "rebuild_filtered",
      keysTable,
      function(idx, key, context)
        -- Initialize context tables on first call
        context.filtered = context.filtered or {}
        
        local entry = books[key]
        if entry and matches(self, entry, tokens) then
          table.insert(context.filtered, key)
          if key == selectedKey then
            context.selectionStillValid = true
          end
          if self.SetSearchMatchKind and #tokens > 0 then
            local titleHaystack = tostring(entry.title or ""):lower()
            local anyTitle = false
            local anyText = false
            for i = 1, #tokens do
              local token = tokens[i]
              if token ~= "" then
                if titleHaystack:find(token, 1, true) then
                  anyTitle = true
                end
                if (entry.searchText or ""):lower():find(token, 1, true) and not titleHaystack:find(token, 1, true) then
                  anyText = true
                end
              end
            end
            if anyTitle then
              self:SetSearchMatchKind(key, "title")
            end
            if anyText or (not anyTitle) then
              self:SetSearchMatchKind(key, "content")
            end
          end
        end
        return true -- continue
      end,
      {
        chunkSize = 100,
        budgetMs = 8,
        onProgress = function(progress, current, total)
          -- Update loading indicator with progress
          if noResults then
            noResults:SetText(string.format("|cFFFFFF00Filtering: %d/%d (%.0f%%)|r", current, total, progress * 100))
          end
        end,
        onComplete = function(context)
          self:DebugPrint("[BookArchivist] === ASYNC FILTER COMPLETION CALLBACK FIRED ===")
          self:DebugPrint(string.format("[BookArchivist] Flag before clear: %s", tostring(self.__state.isAsyncFiltering)))
          
          -- Wrap entire completion in error handler to catch issues
          local success, err = pcall(function()
            -- Get fresh reference to filtered keys and update it
            local filteredKeys = self:GetFilteredKeys()
            wipe(filteredKeys)
            for _, key in ipairs(context.filtered or {}) do
              table.insert(filteredKeys, key)
            end
            
            self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: %d matched of %d (throttled)", #filteredKeys, #baseKeys))
            
            -- Hide loading indicator
            local noResults = self:GetFrame("noResultsText")
            if noResults and #filteredKeys == 0 then
              noResults:SetText("|cFF999999" .. (self.L and self.L["LIST_EMPTY_SEARCH"] or "No results") .. "|r")
            elseif noResults then
              noResults:Hide()
            end
            
            -- Update pagination (protect against errors)
            local pageCount = (self.GetPageCount and self:GetPageCount(#filteredKeys)) or 1
            if self.__state.pagination then
              self.__state.pagination.total = #filteredKeys
              self.__state.pagination.pageCount = pageCount
              local currentPage = (self.GetPage and self:GetPage()) or 1
              if currentPage > pageCount and self.SetPage then
                self:SetPage(pageCount)
              end
            end
            
            -- Handle selection (protect against errors)
            if not context.selectionStillValid and self.ClearSelection then
              self:ClearSelection()
            end
          end)
          
          if not success then
            self:DebugPrint("[BookArchivist] ERROR in completion callback: " .. tostring(err))
          end
          
          -- Clear async filtering flag BEFORE calling UpdateList
          self.__state.isAsyncFiltering = false
          self:DebugPrint(string.format("[BookArchivist] Flag after clear: %s", tostring(self.__state.isAsyncFiltering)))
          self:DebugPrint("[BookArchivist] About to call UpdateList...")
          
          -- Trigger UI update
          if self.UpdateList then
            self:UpdateList()
            self:DebugPrint("[BookArchivist] UpdateList called from completion callback")
          else
            self:DebugPrint("[BookArchivist] ERROR: UpdateList method not found!")
          end
          if self.UpdatePaginationUI then
            self:UpdatePaginationUI()
          end
          
          self:DebugPrint("[BookArchivist] === COMPLETION CALLBACK FINISHED ===")
        end
      }
    )
    
    -- Early return - completion callback will update UI
    return
  end
  
  -- Fast synchronous path for small datasets (<100 books)
  local selectionStillValid = false
  for _, key in ipairs(baseKeys) do
      local entry = books[key]
    if entry and matches(self, entry, tokens) then
      table.insert(filtered, key)
      if key == selectedKey then
        selectionStillValid = true
      end
      if self.SetSearchMatchKind and #tokens > 0 then
        local titleHaystack = tostring(entry.title or ""):lower()
        local anyTitle = false
        local anyText = false
        for i = 1, #tokens do
          local token = tokens[i]
          if token ~= "" then
            if titleHaystack:find(token, 1, true) then
              anyTitle = true
            end
            if (entry.searchText or ""):lower():find(token, 1, true) and not titleHaystack:find(token, 1, true) then
              anyText = true
            end
          end
        end
        if anyTitle then
          self:SetSearchMatchKind(key, "title")
        end
        if anyText or (not anyTitle) then
          self:SetSearchMatchKind(key, "content")
        end
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
