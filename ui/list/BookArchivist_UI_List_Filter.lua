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
  
  -- Set loading state to prevent tab switches BEFORE wiping data
  self.__state.isLoading = true
  
  -- Disable tabs during filtering operation
  if self.SetTabsEnabled then
    self:SetTabsEnabled(false)
  end
  
  -- NOW wipe after we've set loading state
  wipe(filtered)
  self:DisableDeleteButton()

  local addon = self:GetAddon()
  if not addon then
    self:DebugPrint("[BookArchivist] rebuildFiltered: addon missing")
    self:LogError("BookArchivist addon missing during rebuildFiltered")
    self.__state.isLoading = false
    if self.SetTabsEnabled then
      self:SetTabsEnabled(true)
    end
    return
  end

  local db = addon:GetDB()
  if not db then
    self:DebugPrint("[BookArchivist] rebuildFiltered: DB missing")
    self:LogError("BookArchivist DB missing during rebuildFiltered")
    self.__state.isLoading = false
    if self.SetTabsEnabled then
      self:SetTabsEnabled(true)
    end
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
  
  -- Use Iterator for ALL filtering to prevent game freeze
  -- Even small datasets benefit from yielding to game engine
  local Iterator = BookArchivist and BookArchivist.Iterator
  if Iterator and #baseKeys > 0 then
    -- Prevent concurrent async filtering with timeout watchdog
    if self.__state.isAsyncFiltering then
      local now = GetTime()
      local started = self.__state.asyncFilterStartTime or 0
      local elapsed = now - started
      
      -- If async filter has been running for more than 30 seconds, assume it's stuck
      if elapsed > 30 then
        self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: async filter stuck for %.1fs, forcing reset", elapsed))
        self.__state.isAsyncFiltering = false
        self.__state.asyncFilterStartTime = nil
      else
        self:DebugPrint("[BookArchivist] rebuildFiltered: async filtering already in progress, skipping")
        self.__state.isLoading = false
        if self.SetTabsEnabled then
          self:SetTabsEnabled(true)
        end
        return
      end
    end
    
    -- Throttled path for ALL datasets (not just >100)
    -- Small datasets complete quickly but still yield to prevent freeze
    self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: using throttled iteration for %d books", #baseKeys))
    
    -- Set async filtering flag to prevent premature UpdateList
    self.__state.isAsyncFiltering = true
    self.__state.asyncFilterStartTime = GetTime()
    
    -- Show loading indicator
    local noResults = self:GetFrame("noResultsText")
    if noResults then
      noResults:SetText("|cFFFFFF00Filtering books...|r")
      noResults:Show()
    end
    
    -- Update main frame loading indicator if available
    local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal
    if Internal and Internal.getUIFrame then
      local uiFrame = Internal.getUIFrame()
      if uiFrame and BookArchivist.UI.Frame and BookArchivist.UI.Frame.UpdateLoadingProgress then
        BookArchivist.UI.Frame:UpdateLoadingProgress(uiFrame, "filtering", 0)
      end
    end
    
    -- Phase 3: Use array fast-path - no need to convert to table
    Iterator:Start(
      "rebuild_filtered",
      baseKeys, -- Pass array directly
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
        chunkSize = 50,  -- Reduced from 100 for faster first paint
        budgetMs = 5,     -- Reduced from 8 for more responsive feel
        isArray = true,   -- Phase 3: baseKeys is an array, use fast path
        onProgress = function(progress, current, total)
          -- Update loading indicator with progress
          if noResults then
            noResults:SetText(string.format("|cFFFFFF00Filtering: %d/%d (%.0f%%)|r", current, total, progress * 100))
          end
          
          -- Update main frame progress
          local Internal = BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal
          if Internal and Internal.getUIFrame then
            local uiFrame = Internal.getUIFrame()
            if uiFrame and BookArchivist.UI.Frame and BookArchivist.UI.Frame.UpdateLoadingProgress then
              BookArchivist.UI.Frame:UpdateLoadingProgress(uiFrame, "filtering", progress)
            end
          end
        end,
        onComplete = function(context)
          -- Wrap entire completion in error handler to catch issues
          local success, err = pcall(function()
            -- Get fresh reference to filtered keys and update it
            local filteredKeys = self:GetFilteredKeys()
            wipe(filteredKeys)
            
            self:DebugPrint(string.format("[BookArchivist] Async filter complete: context.filtered has %d items", #(context.filtered or {})))
            
            for _, key in ipairs(context.filtered or {}) do
              table.insert(filteredKeys, key)
            end
            
            self:DebugPrint(string.format("[BookArchivist] rebuildFiltered: %d matched of %d (throttled)", #filteredKeys, #baseKeys))
            
            -- Clear loading state
            self.__state.isLoading = false
            
            -- Re-enable Books tab after filtering
            local booksTab = self:GetFrame("booksTabButton")
            if booksTab then
              booksTab:Enable()
              if booksTab.Text then
                booksTab.Text:SetTextColor(1.0, 0.82, 0.0)
              end
            end
            
            -- Only enable Locations tab if tree has been built
            local state = self.GetLocationState and self:GetLocationState() or nil
            if state and state.root and state.rows and #state.rows > 0 then
              if self.SetLocationsTabEnabled then
                self:SetLocationsTabEnabled(true)
              end
            end
            
            -- Filtering complete - don't hide overlay yet, UpdateList will handle it
            -- after list has been populated and rendered
            
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
            
            -- Apply sorting to the filtered results
            if db and self.ApplySort then
              self:ApplySort(filteredKeys, db)
            end
          end)
          
          if not success then
            self:DebugPrint("[BookArchivist] ERROR in async filter completion: " .. tostring(err))
          end
          
          -- Clear async filtering flag BEFORE calling UpdateList
          self.__state.isAsyncFiltering = false
          self.__state.asyncFilterStartTime = nil
          
          -- Trigger UI update (UpdateList will call UpdatePaginationUI internally)
          if self.UpdateList then
            self:UpdateList()
          end
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

  -- Clear loading state for synchronous path
  self.__state.isLoading = false
  
  -- Re-enable Books tab
  local booksTab = self:GetFrame("booksTabButton")
  if booksTab then
    booksTab:Enable()
    if booksTab.Text then
      booksTab.Text:SetTextColor(1.0, 0.82, 0.0)
    end
  end
  
  -- Only enable Locations tab if tree has been built
  local state = self.GetLocationState and self:GetLocationState() or nil
  if state and state.root and state.rows and #state.rows > 0 then
    if self.SetLocationsTabEnabled then
      self:SetLocationsTabEnabled(true)
    end
  end

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
