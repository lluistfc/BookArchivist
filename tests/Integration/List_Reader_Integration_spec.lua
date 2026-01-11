-- List_Reader_Integration_spec.lua
-- Integration tests for BookList and Reader interaction

-- Load test helper
local helper = dofile("tests/test_helper.lua")

-- Setup localization BEFORE loading modules
BookArchivist = BookArchivist or {}
BookArchivist.L = {
  BOOK_UNTITLED = "Untitled",
  READER_META_CREATOR = "Author:",
  READER_META_MATERIAL = "Material:",
  READER_META_LAST_VIEWED = "Last Viewed:",
  READER_META_CAPTURED_AUTOMATICALLY = "Captured automatically",
  READER_NO_CONTENT = "No content available",
  READER_PAGE_COUNT_SINGULAR = "%d page",
  READER_PAGE_COUNT_PLURAL = "%d pages",
  READER_LAST_VIEWED_AT_FORMAT = "Last viewed: %s",
  PAGINATION_PAGE_FORMAT = "Page %d of %d",
  LIST_EMPTY_NO_BOOKS = "No books in your library",
  LIST_EMPTY_SEARCH = "No books found",
  READER_FAVORITE_ADD = "Add to Favorites",
  READER_FAVORITE_REMOVE = "Remove from Favorites"
}

-- Mock WoW UI functions
local function setupMockWoW()
  _G.C_Timer = _G.C_Timer or {}
  _G.C_Timer.After = function(delay, callback) 
    if callback then callback() end
  end
  
  _G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
  }
  
  -- Mock CreateFrame
  _G.CreateFrame = function(type, name, parent, template)
    return {
      __type = type,
      __name = name,
      SetScript = function() end,
      SetPoint = function() end,
      SetSize = function() end,
      Hide = function(self) self.__shown = false end,
      Show = function(self) self.__shown = true end,
      SetShown = function(self, shown) self.__shown = shown end
    }
  end
end

-- Setup integrated environment
local function setupIntegration()
  setupMockWoW()
  
  local mockTime = 1000
  local selectedKey = nil
  local mockDB = {
    booksById = {
      ["book1"] = {
        bookId = "book1",
        title = "Test Book 1",
        creator = "Test Author",
        material = "Parchment",
        pages = {[1] = "First page", [2] = "Second page"},
        lastSeenAt = 12345,
        isFavorite = false,
        location = {zone = "Stormwind"}
      },
      ["book2"] = {
        bookId = "book2",
        title = "Test Book 2",
        creator = "Another Author",
        pages = {[1] = "Content here"},
        lastSeenAt = 12346,
        isFavorite = false
      },
      ["book3"] = {
        bookId = "book3",
        title = "Favorite Book",
        pages = {[1] = "Special content"},
        lastSeenAt = 12347,
        isFavorite = true
      }
    },
    order = {"book1", "book2", "book3"}
  }
  
  local mockAddon = {
    GetDB = function() return mockDB end,
    SetLastBookId = function(self, id) self.__lastBookId = id end,
    GetLastBookId = function(self) return self.__lastBookId end,
    IsResumeLastPageEnabled = function() return false end,
    RefreshUI = function(self)
      -- Trigger UI update callbacks
      if self.__onRefresh then
        self.__onRefresh()
      end
    end,
    Recent = {
      MarkOpened = function(self, id) self.__markedId = id end
    },
    Favorites = {
      IsFavorite = function(self, id) 
        return mockDB.booksById[id] and mockDB.booksById[id].isFavorite or false
      end,
      Set = function(self, id, value)
        if mockDB.booksById[id] then
          mockDB.booksById[id].isFavorite = value
        end
      end,
      Toggle = function(self, id)
        if mockDB.booksById[id] then
          mockDB.booksById[id].isFavorite = not mockDB.booksById[id].isFavorite
        end
      end
    },
    __lastBookId = nil,
    __onRefresh = nil
  }
  
  -- Mock widgets
  local function createMockWidget(widgetType)
    return {
      __type = widgetType,
      __text = "",
      __shown = true,
      __enabled = true,
      __height = 100,
      __width = 400,
      __checked = false,
      __children = {},
      SetText = function(self, text) self.__text = tostring(text or "") end,
      GetText = function(self) return self.__text end,
      SetTextColor = function(self, r, g, b) self.__color = {r=r, g=g, b=b} end,
      Show = function(self) self.__shown = true end,
      Hide = function(self) self.__shown = false end,
      SetShown = function(self, shown) self.__shown = shown end,
      IsShown = function(self) return self.__shown end,
      Enable = function(self) self.__enabled = true end,
      Disable = function(self) self.__enabled = false end,
      IsEnabled = function(self) return self.__enabled end,
      SetHeight = function(self, h) self.__height = h end,
      GetHeight = function(self) return self.__height end,
      SetWidth = function(self, w) self.__width = w end,
      GetWidth = function(self) return self.__width end,
      IsObjectType = function(self, type) return self.__type == type end,
      SetChecked = function(self, checked) self.__checked = checked end,
      GetChecked = function(self) return self.__checked end,
      GetContentHeight = function(self) return self.__height end,
      SetImageTexture = function(self, key, path) end,
      SetImageSize = function(self, key, w, h) end,
      ScrollToBegin = function(self) self.__scroll = 0 end,
      Update = function(self) end,
      UpdateScrollChildRect = function(self) end,
      CreateFontString = function(self, name, layer)
        local fs = createMockWidget("FontString")
        table.insert(self.__children, fs)
        return fs
      end,
      CreateTexture = function(self, name, layer)
        local tex = createMockWidget("Texture")
        table.insert(self.__children, tex)
        return tex
      end,
      SetPoint = function() end,
      SetSize = function() end,
      SetTexture = function() end,
      SetTexCoord = function() end,
      SetVertexColor = function() end
    }
  end
  
  local readerWidgets = {
    bookTitle = createMockWidget("FontString"),
    meta = createMockWidget("FontString"),
    countText = createMockWidget("FontString"),
    pageIndicator = createMockWidget("FontString"),
    textPlain = createMockWidget("FontString"),
    htmlText = createMockWidget("SimpleHTML"),
    textChild = createMockWidget("Frame"),
    textScroll = createMockWidget("ScrollFrame"),
    textScrollBar = createMockWidget("Slider"),
    contentHost = createMockWidget("Frame"),
    prevButton = createMockWidget("Button"),
    nextButton = createMockWidget("Button"),
    deleteButton = createMockWidget("Button"),
    shareButton = createMockWidget("Button"),
    favoriteBtn = createMockWidget("CheckButton"),
    readerNavRow = createMockWidget("Frame"),
    emptyStateFrame = createMockWidget("Frame")
  }
  
  -- Mock list data provider
  local listData = {}
  local dataProvider = {
    Flush = function(self) listData = {} end,
    Insert = function(self, data) table.insert(listData, data) end,
    GetSize = function(self) return #listData end,
    GetData = function(self) return listData end
  }
  
  -- Store favorite star widgets per row
  local rowStarWidgets = {}
  
  -- Shared context
  local sharedContext = {}
  sharedContext.selectedKey = nil
  
  -- Getters/setters
  sharedContext.getSelectedKey = function() return sharedContext.selectedKey end
  sharedContext.setSelectedKey = function(key) 
    sharedContext.selectedKey = key
    if sharedContext.onSelectionChanged then
      sharedContext.onSelectionChanged()
    end
  end
  
  -- Addon
  sharedContext.getAddon = function() return mockAddon end
  
  -- Widgets
  sharedContext.getWidget = function(name) return readerWidgets[name] end
  sharedContext.rememberWidget = function(name, widget) 
    readerWidgets[name] = widget
    return widget
  end
  
  -- UI Frame
  sharedContext.getUIFrame = function() return {__contentReady = true} end
  
  -- Utilities
  sharedContext.debugPrint = function(...) end
  sharedContext.logError = function(msg) end
  sharedContext.chatMessage = function(msg) end
  sharedContext.fmtTime = function(ts) return "2026-01-11 10:00" end
  sharedContext.formatLocationLine = function(loc) 
    if loc and loc.zone then
      return "|cFF88FF88" .. loc.zone .. "|r"
    end
    return nil
  end
  sharedContext.safeCreateFrame = function(type, name, parent, ...)
    return createMockWidget(type)
  end
  
  -- Reader-specific callbacks
  sharedContext.disableDeleteButton = function()
    if readerWidgets.deleteButton then
      readerWidgets.deleteButton:Disable()
    end
  end
  
  sharedContext.onSelectionChanged = nil -- Will be set by integration
  
  -- List-specific context
  local listContext = {
    -- Inherit shared context
    getAddon = sharedContext.getAddon,
    getSelectedKey = sharedContext.getSelectedKey,
    setSelectedKey = sharedContext.setSelectedKey,
    disableDeleteButton = sharedContext.disableDeleteButton,
    
    -- List-specific
    getDataProvider = function() return dataProvider end,
    
    -- Store star widget reference for each row
    getRowStarWidget = function(bookKey)
      return rowStarWidgets[bookKey]
    end,
    
    setRowStarWidget = function(bookKey, widget)
      rowStarWidgets[bookKey] = widget
    end
  }
  
  return {
    mockDB = mockDB,
    mockAddon = mockAddon,
    readerWidgets = readerWidgets,
    dataProvider = dataProvider,
    sharedContext = sharedContext,
    listContext = listContext,
    rowStarWidgets = rowStarWidgets
  }
end

describe("List + Reader Integration", function()
  describe("Initial load", function()
    it("shows welcome/empty state in reader when no book selected", function()
      local env = setupIntegration()
      
      -- Initialize Reader
      BookArchivist.UI = BookArchivist.UI or {}
      BookArchivist.UI.Reader = BookArchivist.UI.Reader or {}
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- No book selected initially
      env.sharedContext.setSelectedKey(nil)
      BookArchivist.UI.Reader:RenderSelected()
      
      local state = BookArchivist.UI.Reader.__state
      assert.is_nil(state.currentEntryKey)
      assert.are.equal(0, #state.pageOrder)
      assert.is_true(env.readerWidgets.emptyStateFrame.__shown)
    end)
  end)
  
  describe("Selecting a book from list", function()
    it("displays book content in reader when book is selected", function()
      local env = setupIntegration()
      
      -- Setup integration callback
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      -- Initialize Reader
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- Simulate selecting book1 from list
      env.sharedContext.setSelectedKey("book1")
      
      -- Verify reader updated
      local state = BookArchivist.UI.Reader.__state
      assert.are.equal("book1", state.currentEntryKey)
      assert.are.equal(2, #state.pageOrder) -- book1 has 2 pages
      assert.is_false(env.readerWidgets.emptyStateFrame.__shown)
      assert.is_true(env.readerWidgets.textScroll.__shown)
    end)
    
    it("marks book as recently opened", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      env.sharedContext.setSelectedKey("book2")
      
      assert.are.equal("book2", env.mockAddon.Recent.__markedId)
      assert.are.equal("book2", env.mockAddon.__lastBookId)
    end)
    
    it("switching books updates reader content", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- Select first book
      env.sharedContext.setSelectedKey("book1")
      local state = BookArchivist.UI.Reader.__state
      assert.are.equal("book1", state.currentEntryKey)
      assert.are.equal(2, #state.pageOrder)
      
      -- Switch to second book
      env.sharedContext.setSelectedKey("book2")
      assert.are.equal("book2", state.currentEntryKey)
      assert.are.equal(1, #state.pageOrder) -- book2 has 1 page
    end)
  end)
  
  describe("Favorite button integration", function()
    it("favoriting a book updates book data", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      env.sharedContext.setSelectedKey("book1")
      
      -- Initially not favorite
      assert.is_false(env.mockDB.booksById.book1.isFavorite)
      
      -- Favorite the book
      env.mockAddon.Favorites:Set("book1", true)
      
      -- Verify book is now favorite
      assert.is_true(env.mockDB.booksById.book1.isFavorite)
      assert.is_true(env.mockAddon.Favorites:IsFavorite("book1"))
    end)
    
    it("favorite button reflects current state", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      -- Setup favorite sync
      BookArchivist.UI.Reader.__syncFavoriteVisual = function(btn, isFav)
        btn:SetChecked(isFav)
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- Select book that is already favorite
      env.sharedContext.setSelectedKey("book3")
      assert.is_true(env.readerWidgets.favoriteBtn.__checked)
      
      -- Select book that is not favorite
      env.sharedContext.setSelectedKey("book1")
      assert.is_false(env.readerWidgets.favoriteBtn.__checked)
    end)
    
    it("favorite star appears in list after favoriting", function()
      local env = setupIntegration()
      
      -- Simulate list row creation with star widget
      local mockStarWidget = {
        __shown = false,
        Show = function(self) self.__shown = true end,
        Hide = function(self) self.__shown = false end,
        SetShown = function(self, shown) self.__shown = shown end
      }
      env.rowStarWidgets["book1"] = mockStarWidget
      
      -- Initially book1 not favorite, star hidden
      assert.is_false(env.mockDB.booksById.book1.isFavorite)
      mockStarWidget:SetShown(false)
      assert.is_false(mockStarWidget.__shown)
      
      -- Favorite the book
      env.mockAddon.Favorites:Set("book1", true)
      
      -- Simulate RefreshUI updating list rows
      env.mockAddon.__onRefresh = function()
        -- Update star visibility based on favorite status
        for bookKey, entry in pairs(env.mockDB.booksById) do
          local starWidget = env.rowStarWidgets[bookKey]
          if starWidget then
            starWidget:SetShown(entry.isFavorite == true)
          end
        end
      end
      
      env.mockAddon:RefreshUI()
      
      -- Star should now be visible
      assert.is_true(mockStarWidget.__shown)
    end)
    
    it("removing favorite hides star in list", function()
      local env = setupIntegration()
      
      -- Setup for book3 which is already favorite
      local mockStarWidget = {
        __shown = true,
        Show = function(self) self.__shown = true end,
        Hide = function(self) self.__shown = false end,
        SetShown = function(self, shown) self.__shown = shown end
      }
      env.rowStarWidgets["book3"] = mockStarWidget
      
      assert.is_true(env.mockDB.booksById.book3.isFavorite)
      assert.is_true(mockStarWidget.__shown)
      
      -- Remove favorite
      env.mockAddon.Favorites:Set("book3", false)
      
      env.mockAddon.__onRefresh = function()
        for bookKey, entry in pairs(env.mockDB.booksById) do
          local starWidget = env.rowStarWidgets[bookKey]
          if starWidget then
            starWidget:SetShown(entry.isFavorite == true)
          end
        end
      end
      
      env.mockAddon:RefreshUI()
      
      assert.is_false(mockStarWidget.__shown)
    end)
  end)
  
  describe("Delete button integration", function()
    it("deleting a book removes it from database", function()
      local env = setupIntegration()
      
      -- Verify book exists
      assert.is_true(env.mockDB.booksById["book2"] ~= nil)
      assert.are.equal(3, #env.mockDB.order)
      
      -- Delete book2
      env.mockDB.booksById["book2"] = nil
      
      -- Remove from order
      for i, key in ipairs(env.mockDB.order) do
        if key == "book2" then
          table.remove(env.mockDB.order, i)
          break
        end
      end
      
      -- Verify removed
      assert.is_nil(env.mockDB.booksById["book2"])
      assert.are.equal(2, #env.mockDB.order)
    end)
    
    it("deleting current book clears reader selection", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- Select book2
      env.sharedContext.setSelectedKey("book2")
      local state = BookArchivist.UI.Reader.__state
      assert.are.equal("book2", state.currentEntryKey)
      
      -- Delete book2
      env.mockDB.booksById["book2"] = nil
      
      -- Clear selection
      env.sharedContext.setSelectedKey(nil)
      
      -- Verify reader shows empty state
      assert.is_nil(state.currentEntryKey)
      assert.is_true(env.readerWidgets.emptyStateFrame.__shown)
    end)
    
    it("deleted book disappears from list", function()
      local env = setupIntegration()
      
      -- Populate data provider with all books
      env.dataProvider:Flush()
      for _, key in ipairs(env.mockDB.order) do
        local entry = env.mockDB.booksById[key]
        if entry then
          env.dataProvider:Insert({
            bookKey = key,
            title = entry.title,
            isFavorite = entry.isFavorite
          })
        end
      end
      
      assert.are.equal(3, env.dataProvider:GetSize())
      
      -- Delete book1
      env.mockDB.booksById["book1"] = nil
      for i, key in ipairs(env.mockDB.order) do
        if key == "book1" then
          table.remove(env.mockDB.order, i)
          break
        end
      end
      
      -- Rebuild list
      env.dataProvider:Flush()
      for _, key in ipairs(env.mockDB.order) do
        local entry = env.mockDB.booksById[key]
        if entry then
          env.dataProvider:Insert({
            bookKey = key,
            title = entry.title,
            isFavorite = entry.isFavorite
          })
        end
      end
      
      assert.are.equal(2, env.dataProvider:GetSize())
      
      -- Verify book1 not in list
      local listData = env.dataProvider:GetData()
      for _, data in ipairs(listData) do
        assert.is_true(data.bookKey ~= "book1")
      end
    end)
    
    it("deleting selected book switches to next available book", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- Select book2
      env.sharedContext.setSelectedKey("book2")
      assert.are.equal("book2", env.sharedContext.selectedKey)
      
      -- Delete book2
      env.mockDB.booksById["book2"] = nil
      for i, key in ipairs(env.mockDB.order) do
        if key == "book2" then
          table.remove(env.mockDB.order, i)
          break
        end
      end
      
      -- Simulate auto-selecting next book (book3)
      if #env.mockDB.order > 0 then
        env.sharedContext.setSelectedKey(env.mockDB.order[1])
      else
        env.sharedContext.setSelectedKey(nil)
      end
      
      -- Should now show book1 (first in remaining order)
      assert.are.equal("book1", env.sharedContext.selectedKey)
      local state = BookArchivist.UI.Reader.__state
      assert.are.equal("book1", state.currentEntryKey)
    end)
  end)
  
  describe("Full workflow", function()
    it("complete user journey: load, select, favorite, delete", function()
      local env = setupIntegration()
      
      env.sharedContext.onSelectionChanged = function()
        BookArchivist.UI.Reader:RenderSelected()
      end
      
      BookArchivist.UI.Reader.__syncFavoriteVisual = function(btn, isFav)
        btn:SetChecked(isFav)
      end
      
      env.mockAddon.__onRefresh = function()
        -- Rebuild list
        env.dataProvider:Flush()
        for _, key in ipairs(env.mockDB.order) do
          local entry = env.mockDB.booksById[key]
          if entry then
            env.dataProvider:Insert({
              bookKey = key,
              title = entry.title,
              isFavorite = entry.isFavorite
            })
            
            -- Update star widgets
            local starWidget = env.rowStarWidgets[key]
            if starWidget then
              starWidget:SetShown(entry.isFavorite == true)
            end
          end
        end
      end
      
      BookArchivist.UI.Reader:Init(env.sharedContext)
      
      -- STEP 1: Initial load - empty state
      env.sharedContext.setSelectedKey(nil)
      assert.is_true(env.readerWidgets.emptyStateFrame.__shown)
      
      -- STEP 2: Select book1 from list
      env.sharedContext.setSelectedKey("book1")
      local state = BookArchivist.UI.Reader.__state
      assert.are.equal("book1", state.currentEntryKey)
      assert.is_false(env.readerWidgets.emptyStateFrame.__shown)
      
      -- STEP 3: Favorite book1
      assert.is_false(env.readerWidgets.favoriteBtn.__checked)
      env.mockAddon.Favorites:Set("book1", true)
      
      -- Simulate list refresh
      local mockStar1 = {__shown = false, SetShown = function(self, s) self.__shown = s end}
      env.rowStarWidgets["book1"] = mockStar1
      env.mockAddon:RefreshUI()
      
      assert.is_true(env.mockDB.booksById.book1.isFavorite)
      assert.is_true(mockStar1.__shown) -- Star visible in list
      
      -- Re-render reader to update favorite button
      BookArchivist.UI.Reader:RenderSelected()
      assert.is_true(env.readerWidgets.favoriteBtn.__checked)
      
      -- STEP 4: Switch to book2
      env.sharedContext.setSelectedKey("book2")
      assert.are.equal("book2", state.currentEntryKey)
      
      -- STEP 5: Delete book2
      env.mockDB.booksById["book2"] = nil
      for i, key in ipairs(env.mockDB.order) do
        if key == "book2" then
          table.remove(env.mockDB.order, i)
          break
        end
      end
      
      env.mockAddon:RefreshUI()
      assert.are.equal(2, env.dataProvider:GetSize()) -- Only 2 books left
      
      -- Auto-select next book
      env.sharedContext.setSelectedKey("book1")
      assert.are.equal("book1", state.currentEntryKey)
    end)
  end)
end)
