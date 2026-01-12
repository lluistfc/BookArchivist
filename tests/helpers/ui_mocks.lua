---@diagnostic disable: undefined-global, undefined-field
-- ui_mocks.lua
-- Shared mocking utilities for UI tests
-- Provides consistent mock implementations across test files
--
-- NOTE: WoW API stubs (wipe, C_Timer, time, etc.) are now provided by
-- Mechanic's wow_stubs.lua loaded in busted_bootstrap.lua
-- This file focuses on BookArchivist-specific mocks only

local UIMocks = {}

-- ============================================================================
-- Database Mocks
-- ============================================================================

--- Create a mock database with v2 schema
---@param options table? Optional overrides (booksById, order, indexes, recent, etc.)
---@return table mockDB Mock database table
function UIMocks.createMockDB(options)
	options = options or {}
	local db = {
		dbVersion = options.dbVersion or 2,
		booksById = options.booksById or {},
		order = options.order or {},
		indexes = options.indexes or {
			objectToBookId = {},
			itemToBookIds = {},
			titleToBookIds = {},
		},
		recent = options.recent or {
			cap = 50,
			list = {},
		},
		uiState = options.uiState or {
			lastCategoryId = "__all__",
			lastBookId = nil,
		},
		options = options.dbOptions or {},
	}
	return db
end

--- Create a mock addon with GetDB method
---@param db table? Database to return (creates default if nil)
---@return table mockAddon Mock addon object
function UIMocks.createMockAddon(db)
	return {
		GetDB = function()
			return db or UIMocks.createMockDB()
		end,
	}
end

--- Create a mock book entry
---@param overrides table? Fields to override (title, pages, location, etc.)
---@return table bookEntry Mock book entry
function UIMocks.createMockBook(overrides)
	overrides = overrides or {}
	return {
		title = overrides.title or "Test Book",
		pages = overrides.pages or { [1] = "Page 1 content" },
		location = overrides.location or {
			zoneText = "Test Zone",
			zoneChain = { "Continent", "Test Zone" },
		},
		firstSeenAt = overrides.firstSeenAt or 1000,
		lastSeenAt = overrides.lastSeenAt or 1000,
		createdAt = overrides.createdAt or 1000,
		updatedAt = overrides.updatedAt or 1000,
		isFavorite = overrides.isFavorite or false,
		lastReadAt = overrides.lastReadAt,
	}
end

-- ============================================================================
-- UI Component Mocks
-- ============================================================================

--- Create a mock context (for pagination, sorting, etc.)
---@param options table? Initial values (pageSize, sortMode, etc.)
---@return table mockContext Mock context object
function UIMocks.createMockContext(options)
	options = options or {}
	local ctx = {
		pageSize = options.pageSize or 25,
		sortMode = options.sortMode or "title",
	}

	-- Add getter/setter methods
	ctx.getPageSize = function()
		return ctx.pageSize
	end
	ctx.setPageSize = function(size)
		ctx.pageSize = size
	end
	ctx.getSortMode = function()
		return ctx.sortMode
	end
	ctx.setSortMode = function(mode)
		ctx.sortMode = mode
	end

	return ctx
end

--- Create a mock ListUI state
---@param options table? Initial state values
---@return table state Mock UI state
function UIMocks.createMockListState(options)
	options = options or {}
	return {
		pagination = options.pagination or {
			page = 1,
			pageSize = 25,
			total = 0,
		},
		location = options.location or {
			root = nil,
			path = {},
			rows = {},
			activeNode = nil,
			totalRows = 0,
			currentPage = 1,
			totalPages = 1,
		},
		search = options.search or {
			matchFlags = {},
			pendingToken = 0,
		},
	}
end

--- Mock a search box widget
---@param initialText string? Initial search text (default: "")
---@return table searchBox Mock search box frame
function UIMocks.createMockSearchBox(initialText)
	local box = {
		text = initialText or "",
		focused = false,
	}

	function box:GetText()
		return self.text
	end

	function box:SetText(text)
		self.text = text or ""
	end

	function box:ClearFocus()
		self.focused = false
	end

	function box:SetFocus()
		self.focused = true
	end

	return box
end

--- Mock a button widget (for clear buttons, nav buttons, etc.)
---@param visible boolean? Initial visibility (default: true)
---@return table button Mock button frame
function UIMocks.createMockButton(visible)
	local button = {
		visible = visible ~= false,
		enabled = true,
		clickCount = 0,
	}

	function button:Show()
		self.visible = true
	end

	function button:Hide()
		self.visible = false
	end

	function button:IsVisible()
		return self.visible
	end

	function button:Enable()
		self.enabled = true
	end

	function button:Disable()
		self.enabled = false
	end

	function button:IsEnabled()
		return self.enabled
	end

	function button:Click()
		self.clickCount = self.clickCount + 1
	end

	return button
end

--- Mock a frame manager (for ListUI.GetFrame/SetFrame)
---@return table frameMgr Frame manager with Get/Set methods
function UIMocks.createFrameManager()
	local frames = {}

	return {
		frames = frames,
		GetFrame = function(_, name)
			return frames[name]
		end,
		SetFrame = function(_, name, frame)
			frames[name] = frame
		end,
		GetWidget = function(_, name)
			return frames[name]
		end,
	}
end

-- ============================================================================
-- Function Mocks (for spying)
-- ============================================================================

--- Create a spy function that tracks calls
---@param returnValue any? Value to return when called
---@return function spy Spy function
---@return table callTracker Table with .called, .callCount, .args
function UIMocks.createSpy(returnValue)
	local tracker = {
		called = false,
		callCount = 0,
		args = {},
	}

	local spy = function(...)
		tracker.called = true
		tracker.callCount = tracker.callCount + 1
		table.insert(tracker.args, { ... })
		return returnValue
	end

	return spy, tracker
end

--- Create a no-op function (useful for mocking optional callbacks)
---@return function noop Function that does nothing
function UIMocks.createNoop()
	return function() end
end

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Reset BookArchivist global namespace (call in teardown)
--- Note: WoW API globals (wipe, C_Timer, time) are provided by Mechanic
--- and don't need manual cleanup
function UIMocks.resetGlobals()
	_G.BookArchivist = nil
end

--- Create a simple pagination mock
---@return function PaginateArray Mock pagination function
function UIMocks.createMockPaginateArray()
	return function(_, items, pageSize, currentPage)
		pageSize = pageSize or 25
		currentPage = currentPage or 1
		local totalItems = #items
		local totalPages = math.max(1, math.ceil(totalItems / pageSize))
		currentPage = math.max(1, math.min(currentPage, totalPages))
		local startIdx = (currentPage - 1) * pageSize + 1
		local endIdx = math.min(startIdx + pageSize - 1, totalItems)
		local paginated = {}
		for i = startIdx, endIdx do
			if items[i] then
				table.insert(paginated, items[i])
			end
		end
		return paginated, totalItems, currentPage, totalPages, startIdx, endIdx
	end
end

--- Setup BookArchivist namespace (common setup code)
function UIMocks.setupNamespace()
	_G.BookArchivist = _G.BookArchivist or {}
	_G.BookArchivist.UI = _G.BookArchivist.UI or {}
	_G.BookArchivist.UI.List = _G.BookArchivist.UI.List or {}
	_G.BookArchivist.L = _G.BookArchivist.L or {}
	_G.BookArchivist.Core = _G.BookArchivist.Core or {}
end

--- Create mock localization table
---@param overrides table? Localization key overrides
---@return table L Mock localization table
function UIMocks.createMockLocalization(overrides)
	overrides = overrides or {}
	return setmetatable(overrides, {
		__index = function(t, key)
			return key -- Return key as fallback
		end,
	})
end

-- ============================================================================
-- Exports
-- ============================================================================

return UIMocks
