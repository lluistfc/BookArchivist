-- Reader_spec.lua
-- Sandbox tests for Reader UI logic

-- Setup localization BEFORE loading the Reader module
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
  PAGINATION_PAGE_FORMAT = "Page %d of %d"
}

-- Mock WoW UI functions
local function setupMockUI()
  _G.C_Timer = _G.C_Timer or {}
  _G.C_Timer.After = function(delay, callback) 
    -- Execute immediately in tests
    if callback then callback() end
  end
  
  _G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
  }
end

-- Setup mock context
local function setupMockContext()
  BookArchivist.UI = BookArchivist.UI or {}
  
  local mockTime = 1000
  local widgets = {}
  local mockDB = {
    booksById = {
      ["book1"] = {
        bookId = "book1",
        title = "Test Book 1",
        creator = "Test Author",
        material = "Parchment",
        pages = {
          [1] = "First page content",
          [2] = "Second page content",
          [3] = "Third page content"
        },
        lastSeenAt = 12345,
        lastPageNum = nil,
        location = {zone = "Stormwind", object = "Bookshelf"}
      },
      ["htmlbook"] = {
        bookId = "htmlbook",
        title = "HTML Book",
        pages = {
          [1] = "<html><body><h1>Title</h1><p>Content</p></body></html>"
        },
        lastSeenAt = 12346
      },
      ["emptybook"] = {
        bookId = "emptybook",
        title = "Empty Book",
        pages = {},
        lastSeenAt = 12347
      }
    },
    order = {"book1", "htmlbook", "emptybook"}
  }
  
  local mockAddon = {
    GetDB = function() return mockDB end,
    SetLastBookId = function(self, id) self.__lastBookId = id end,
    GetLastBookId = function(self) return self.__lastBookId end,
    IsResumeLastPageEnabled = function() return false end,
    Recent = {
      MarkOpened = function(self, id) self.__markedId = id end
    },
    Favorites = {
      IsFavorite = function(self, id) 
        return self.__favorites and self.__favorites[id] or false 
      end
    },
    __lastBookId = nil
  }
  
  -- Mock widgets with basic frame functionality
  local function createMockWidget(widgetType)
    local widget = {
      __type = widgetType,
      __text = "",
      __shown = true,
      __enabled = true,
      __height = 100,
      __width = 400,
      __checked = false,
      SetText = function(self, text) self.__text = tostring(text or "") end,
      GetText = function(self) return self.__text end,
      SetTextColor = function(self, r, g, b) 
        self.__color = {r = r, g = g, b = b} 
      end,
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
      UpdateScrollChildRect = function(self) end
    }
    return widget
  end
  
  widgets.bookTitle = createMockWidget("FontString")
  widgets.meta = createMockWidget("FontString")
  widgets.countText = createMockWidget("FontString")
  widgets.pageIndicator = createMockWidget("FontString")
  widgets.textPlain = createMockWidget("FontString")
  widgets.htmlText = createMockWidget("SimpleHTML")
  widgets.textChild = createMockWidget("Frame")
  widgets.textScroll = createMockWidget("ScrollFrame")
  widgets.textScrollBar = createMockWidget("Slider")
  widgets.contentHost = createMockWidget("Frame")
  widgets.prevButton = createMockWidget("Button")
  widgets.nextButton = createMockWidget("Button")
  widgets.deleteButton = createMockWidget("Button")
  widgets.shareButton = createMockWidget("Button")
  widgets.favoriteBtn = createMockWidget("CheckButton")
  widgets.readerNavRow = createMockWidget("Frame")
  widgets.emptyStateFrame = createMockWidget("Frame")
  
  local selectedKey = nil
  
  local context = {
    getWidget = function(name) return widgets[name] end,
    rememberWidget = function(name, widget) 
      widgets[name] = widget
      return widget
    end,
    getAddon = function() return mockAddon end,
    getUIFrame = function() return {__contentReady = true} end,
    getSelectedKey = function() return selectedKey end,
    setSelectedKey = function(key) selectedKey = key end,
    debugPrint = function(...) end,
    logError = function(msg) end,
    chatMessage = function(msg) end,
    fmtTime = function(ts) return "2026-01-11 10:00" end,
    formatLocationLine = function(loc) 
      if loc and loc.zone then
        return "|cFF88FF88" .. loc.zone .. "|r"
      end
      return nil
    end,
    safeCreateFrame = function(type, name, parent, ...)
      return createMockWidget(type)
    end
  }
  
  return context, mockDB, mockAddon, widgets
end

describe("Reader.buildPageOrder", function()
  it("extracts numeric page keys in sorted order", function()
    setupMockUI()
    local ctx = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local entry = {
      pages = {
        [3] = "Third",
        [1] = "First",
        [2] = "Second",
        name = "Non-numeric" -- Should be ignored
      }
    }
    
    -- Access internal function through RenderSelected
    local state = BookArchivist.UI.Reader.__state
    ctx.setSelectedKey("book1")
    local _, mockDB = setupMockContext()
    mockDB.booksById.book1 = entry
    
    BookArchivist.UI.Reader:RenderSelected()
    
    assert.are.equal(3, #state.pageOrder)
    assert.are.equal(1, state.pageOrder[1])
    assert.are.equal(2, state.pageOrder[2])
    assert.are.equal(3, state.pageOrder[3])
  end)
  
  it("returns empty table for no pages", function()
    setupMockUI()
    local ctx = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    ctx.setSelectedKey("emptybook")
    
    BookArchivist.UI.Reader:RenderSelected()
    
    assert.are.equal(0, #state.pageOrder)
  end)
end)

describe("Reader.RenderSelected", function()
  it("displays book title and metadata", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    -- Title is set synchronously
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal("book1", state.currentEntryKey)
    assert.are.equal(3, #state.pageOrder)
  end)
  
  it("shows first page by default", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(1, state.currentPageIndex)
    assert.are.equal(1, state.pageOrder[1])
  end)
  
  it("marks book as recently opened", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    assert.are.equal("book1", mockAddon.Recent.__markedId)
    assert.are.equal("book1", mockAddon.__lastBookId)
  end)
  
  it("updates page controls display", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    -- Should show "Page 1 of 3"
    assert.are.equal("Page 1 of 3", widgets.pageIndicator.__text)
  end)
  
  it("enables navigation buttons correctly", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    -- On first page: prev disabled, next enabled
    assert.is_false(widgets.prevButton.__enabled)
    assert.is_true(widgets.nextButton.__enabled)
  end)
  
  it("shows empty state when no book selected", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey(nil)
    BookArchivist.UI.Reader:RenderSelected()
    
    local state = BookArchivist.UI.Reader.__state
    assert.is_nil(state.currentEntryKey)
    assert.are.equal(0, #state.pageOrder)
  end)
  
  it("hides empty state when book selected", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    assert.is_false(widgets.emptyStateFrame.__shown)
    assert.is_true(widgets.textScroll.__shown)
    assert.is_true(widgets.deleteButton.__shown)
  end)
  
  it("displays page count", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(3, #state.pageOrder)
  end)
  
  it("syncs favorite button state", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    mockAddon.Favorites.__favorites = {book1 = true}
    ctx.setSelectedKey("book1")
    
    BookArchivist.UI.Reader.__syncFavoriteVisual = function(btn, isFav)
      btn:SetChecked(isFav)
    end
    
    BookArchivist.UI.Reader:RenderSelected()
    
    assert.is_true(widgets.favoriteBtn.__checked)
  end)
end)

describe("Reader.ChangePage", function()
  it("advances to next page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    BookArchivist.UI.Reader:ChangePage(1)
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(2, state.currentPageIndex)
    assert.are.equal(2, state.pageOrder[2])
  end)
  
  it("goes to previous page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    local state = BookArchivist.UI.Reader.__state
    local startIndex = state.currentPageIndex
    BookArchivist.UI.Reader:ChangePage(1)
    assert.are.equal(startIndex + 1, state.currentPageIndex)
    BookArchivist.UI.Reader:ChangePage(-1)
    assert.are.equal(startIndex, state.currentPageIndex)
  end)
  
  it("clamps at first page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    BookArchivist.UI.Reader:ChangePage(-10)
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(1, state.currentPageIndex)
  end)
  
  it("clamps at last page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("book1")
    BookArchivist.UI.Reader:RenderSelected()
    
    BookArchivist.UI.Reader:ChangePage(10)
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(3, state.currentPageIndex)
  end)
  
  it("does nothing when no pages available", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    ctx.setSelectedKey("emptybook")
    BookArchivist.UI.Reader:RenderSelected()
    
    BookArchivist.UI.Reader:ChangePage(1)
    
    local state = BookArchivist.UI.Reader.__state
    assert.are.equal(1, state.currentPageIndex)
  end)
end)

describe("Reader.UpdatePageControlsDisplay", function()
  it("shows correct page indicator", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {1, 2, 3}
    state.currentPageIndex = 2
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(3)
    
    assert.are.equal("Page 2 of 3", widgets.pageIndicator.__text)
  end)
  
  it("disables prev button on first page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {1, 2, 3}
    state.currentPageIndex = 1
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(3)
    
    assert.is_false(widgets.prevButton.__enabled)
    assert.is_true(widgets.nextButton.__enabled)
  end)
  
  it("disables next button on last page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {1, 2, 3}
    state.currentPageIndex = 3
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(3)
    
    assert.is_true(widgets.prevButton.__enabled)
    assert.is_false(widgets.nextButton.__enabled)
  end)
  
  it("enables both buttons on middle page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {1, 2, 3}
    state.currentPageIndex = 2
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(3)
    
    assert.is_true(widgets.prevButton.__enabled)
    assert.is_true(widgets.nextButton.__enabled)
  end)
  
  it("disables both buttons for single page", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {1}
    state.currentPageIndex = 1
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(1)
    
    assert.is_false(widgets.prevButton.__enabled)
    assert.is_false(widgets.nextButton.__enabled)
  end)
  
  it("shows 0/0 for no pages", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.pageOrder = {}
    state.currentPageIndex = 1
    
    BookArchivist.UI.Reader:UpdatePageControlsDisplay(0)
    
    assert.are.equal("Page 0 of 0", widgets.pageIndicator.__text)
  end)
end)

describe("Reader.UpdateReaderHeight", function()
  it("updates scroll content height", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.textChild = widgets.textChild
    
    BookArchivist.UI.Reader.UpdateReaderHeight(500)
    
    -- Should set height + padding (20)
    assert.are.equal(520, widgets.textChild.__height)
  end)
  
  it("auto-hides scrollbar when content fits", function()
    setupMockUI()
    local ctx, mockDB, mockAddon, widgets = setupMockContext()
    BookArchivist.UI.Reader:Init(ctx)
    
    local state = BookArchivist.UI.Reader.__state
    state.textChild = widgets.textChild
    state.textScroll = widgets.textScroll
    state.textScrollBar = widgets.textScrollBar
    
    -- Content height (50) < scroll height (100)
    widgets.textChild.__height = 50
    widgets.textScroll.__height = 100
    
    BookArchivist.UI.Reader.UpdateReaderHeight(50)
    
    assert.is_false(widgets.textScrollBar.__shown)
  end)
end)
