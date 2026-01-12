---@diagnostic disable: undefined-global, undefined-field
local ListUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.List
if not ListUI then
	return
end

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

-- Location tree cache
-- Cache key: categoryId|favoritesOnly|searchText
local treeCache = {}
local lastCacheKey = nil

local function shouldIncludeEntry(self, entry)
	if not entry then
		return false
	end
	if self and self.EntryMatchesFilters then
		return self:EntryMatchesFilters(entry)
	end
	return true
end

local function normalizeLocationLabel(label)
	if not label or label == "" then
		return "Unknown Location"
	end
	return label
end

local function buildLocationTreeFromDB(self, db, onProgress)
	local root = {
		name = "__ROOT__",
		depth = 0,
		children = {},
		childNames = {},
		totalBooks = 0, -- Initialize for incremental updates
	}

	if not db or not (db.booksById or db.books) then
		if BookArchivist.LogInfo then
			BookArchivist:LogInfo("buildLocationTreeFromDB: No db or books")
		end
		return root
	end

	local order = db.order or {}
	local books
	if db.booksById and next(db.booksById) ~= nil then
		books = db.booksById
	else
		books = db.books or {}
	end

	-- Phase 2: Use async Iterator for tree building
	local Iterator = BookArchivist and BookArchivist.Iterator
	if not Iterator then
		if BookArchivist.LogError then
			BookArchivist:LogError("Iterator not available! Falling back to empty tree.")
		end
		return root
	end

	if #order == 0 then
		if BookArchivist.LogInfo then
			BookArchivist:LogInfo("buildLocationTreeFromDB: Empty order array")
		end
		return root
	end

	if BookArchivist.LogInfo then
		BookArchivist:LogInfo(string.format("buildLocationTreeFromDB: Starting async build for %d books", #order))
	end

	-- Build tree asynchronously
	return {
		root = root,
		isAsync = true,
		order = order,
		books = books,
		self = self,
		onProgress = onProgress,
	}
end

local function processBookIntoTree(idx, bookKey, context)
	local root = context.root
	local books = context.books
	local self = context.self

	-- In array mode: idx is the index, bookKey is the actual book ID
	local entry = books[bookKey]
	if not shouldIncludeEntry(self, entry) then
		return true -- Continue
	end

	local chain = entry.location and entry.location.zoneChain
	if not chain or #chain == 0 then
		local fallback = entry.location and entry.location.zoneText
		if fallback and fallback ~= "" then
			chain = { fallback }
		else
			chain = { "Unknown Location" }
		end
	end

	-- Track nodes we visit to update totals incrementally
	local visitedNodes = {}

	local node = root
	table.insert(visitedNodes, node)

	for _, segment in ipairs(chain) do
		local name = normalizeLocationLabel(segment)
		node.children = node.children or {}
		node.childNames = node.childNames or {}
		if not node.children[name] then
			node.children[name] = {
				name = name,
				depth = (node.depth or 0) + 1,
				parent = node,
				children = {},
				childNames = {},
				books = {},
				totalBooks = 0, -- Initialize total
			}
			table.insert(node.childNames, name)
		end
		node = node.children[name]
		table.insert(visitedNodes, node)
	end

	node.books = node.books or {}
	table.insert(node.books, bookKey)

	-- Incrementally update totals for all nodes in the path
	-- This eliminates the need for recursive markTotals at the end
	for _, visitedNode in ipairs(visitedNodes) do
		visitedNode.totalBooks = (visitedNode.totalBooks or 0) + 1
	end

	return true -- Continue iteration
end

-- Phase 2: Lazy sorting - only sort when needed, not during build
local function sortNodeLazy(node)
	if not node or not node.childNames or #node.childNames == 0 then
		return
	end

	-- Check if already sorted
	if node.__sorted then
		return
	end

	table.sort(node.childNames, function(a, b)
		return a:lower() < b:lower()
	end)

	node.__sorted = true
end

local function markTotals(node)
	if not node then
		return 0
	end
	local total = node.books and #node.books or 0
	if node.childNames then
		for _, childName in ipairs(node.childNames) do
			local child = node.children and node.children[childName]
			total = total + markTotals(child)
		end
	end
	node.totalBooks = total
	return total
end

local function getLocationState(self)
	local state = self:GetLocationState()
	state.path = state.path or {}
	state.rows = state.rows or {}
	return state
end

local function ensureLocationPathValid(state)
	local root = state.root
	local path = state.path
	if not path then
		path = {}
		state.path = path
	end
	if not root then
		wipe(path)
		state.activeNode = nil
		return
	end

	local node = root
	for i = 1, #path do
		local segment = path[i]
		if node.children and node.children[segment] then
			node = node.children[segment]
			-- Phase 2: Sort this node lazily before traversing
			sortNodeLazy(node)
		else
			for j = #path, i, -1 do
				table.remove(path, j)
			end
			break
		end
	end
	state.activeNode = node
end

local function rebuildLocationRows(state, listUI, pageSize, currentPage)
	local rows = {}
	local node = state.activeNode or state.root
	if not node then
		state.rows = rows
		state.totalRows = 0
		state.currentPage = 1
		state.totalPages = 1
		return
	end

	-- Phase 2: Sort current node lazily
	sortNodeLazy(node)

	local path = state.path or {}

	local childNames = node.childNames or {}
	local books = node.books or {}

	-- Filter books by current search query if applicable
	local hasSearch = listUI.GetSearchQuery and listUI:GetSearchQuery() ~= ""
	if hasSearch and not (childNames and #childNames > 0) then
		-- We're showing books and have a search query - use filtered keys
		local filtered = listUI.GetFilteredKeys and listUI:GetFilteredKeys() or {}
		if listUI.DebugPrint then
			listUI:DebugPrint(
				string.format(
					"[BookArchivist] rebuildLocationRows: hasSearch=true, filtered=%d, books=%d",
					#filtered,
					#books
				)
			)
		end
		local filteredBooksInLocation = {}
		for _, key in ipairs(filtered) do
			-- Check if this book is in the current location
			for _, locKey in ipairs(books) do
				if key == locKey then
					table.insert(filteredBooksInLocation, key)
					break
				end
			end
		end
		books = filteredBooksInLocation
		if listUI.DebugPrint then
			listUI:DebugPrint(string.format("[BookArchivist] rebuildLocationRows: after filter, books=%d", #books))
		end
	end

	-- Determine what we're showing
	local hasChildren = childNames and #childNames > 0
	local items = hasChildren and childNames or books

	-- Use shared pagination helper
	local paginated, totalItems, page, totalPages, startIdx, endIdx = listUI:PaginateArray(items, pageSize, currentPage)

	-- Add back button if not at root
	if #path > 0 then
		table.insert(rows, { kind = "back" })
	end

	-- Add paginated items
	if hasChildren then
		for _, childName in ipairs(paginated) do
			table.insert(
				rows,
				{ kind = "location", name = childName, node = node.children and node.children[childName] }
			)
		end
	else
		for i, key in ipairs(paginated) do
			table.insert(rows, { kind = "book", key = key })
		end
	end

	state.rows = rows
	state.totalRows = totalItems
	state.currentPage = page
	state.totalPages = totalPages
	
	if listUI.DebugPrint then
		listUI:DebugPrint(string.format(
			"[BookArchivist] rebuildLocationRows: page=%d/%d, items=%d, paginated=%d, rows=%d (startIdx=%d, endIdx=%d)",
			page, totalPages, totalItems, #paginated, #rows, startIdx or 0, endIdx or 0
		))
	end
end

function ListUI:GetLocationRows()
	local state = getLocationState(self)
	return state.rows or {}
end

function ListUI:GetLocationPagination()
	local state = getLocationState(self)
	return {
		totalRows = state.totalRows or 0,
		currentPage = state.currentPage or 1,
		totalPages = state.totalPages or 1,
	}
end

function ListUI:GetLocationBreadcrumbText()
	local state = getLocationState(self)
	local path = state.path or {}
	if #path == 0 then
		return t("LOCATIONS_BREADCRUMB_ROOT")
	end
	return table.concat(path, " > ")
end

function ListUI:GetLocationBreadcrumbSegments()
	local state = getLocationState(self)
	local path = state.path or {}
	if #path == 0 then
		return { t("LOCATIONS_BREADCRUMB_ROOT") }
	end
	return path
end

function ListUI:GetLocationBreadcrumbDisplayLines(maxLines)
	maxLines = maxLines or 4
	local segments = self:GetLocationBreadcrumbSegments()
	local numSegments = #segments

	if numSegments == 1 then
		return { segments[1], "", "", "" }
	elseif numSegments == 2 then
		return { segments[1], "› " .. segments[2], "", "" }
	elseif numSegments == 3 then
		return { segments[1], "› " .. segments[2], "› " .. segments[3], "" }
	elseif numSegments == 4 then
		return { segments[1], "› " .. segments[2], "› " .. segments[3], "› " .. segments[4] }
	else
		-- More than 4 segments: show root + ellipsis + parent + current
		return { segments[1], "…", "› " .. segments[numSegments - 1], "› " .. segments[numSegments] }
	end
end

function ListUI:UpdateLocationBreadcrumbUI()
	local breadcrumbRow = self:GetFrame("breadcrumbRow")
	local modes = self:GetListModes()
	local mode = self:GetListMode()

	-- Hide breadcrumbs in Books mode
	if mode ~= modes.LOCATIONS then
		if breadcrumbRow then
			breadcrumbRow:Hide()
		end
		return
	end

	-- Ensure breadcrumb row exists
	if not breadcrumbRow then
		breadcrumbRow = self:EnsureListBreadcrumbRow()
	end
	if not breadcrumbRow then
		return
	end

	breadcrumbRow:Show()

	-- Get button lines
	local line1 = self:GetFrame("breadcrumbLine1")
	local line2 = self:GetFrame("breadcrumbLine2")
	local line3 = self:GetFrame("breadcrumbLine3")
	local line4 = self:GetFrame("breadcrumbLine4")

	if not (line1 and line2 and line3 and line4) then
		return
	end

	-- Get current state to calculate navigation targets
	local state = self.GetLocationState and self:GetLocationState() or nil
	local segments = state and state.path or {}
	local lines = self:GetLocationBreadcrumbDisplayLines(4)

	-- Dynamically adjust breadcrumb row height based on actual content
	local numVisibleLines = 0
	for i = 1, 4 do
		if lines[i] and lines[i] ~= "" then
			numVisibleLines = i
		end
	end

	-- Calculate height: base padding + (lineHeight + gap) per visible line
	local lineHeight = 16
	local lineGap = 4
	local textPadding = 8
	local rowHeight = (textPadding * 2) + (lineHeight * numVisibleLines) + (lineGap * (numVisibleLines - 1))
	breadcrumbRow:SetHeight(math.max(rowHeight, 32)) -- Minimum 32px

	-- Update scroll row anchoring after height change
	if self.UpdateListScrollRowAnchors then
		self:UpdateListScrollRowAnchors()
	end

	-- Capture module reference for closures
	local listUI = self

	-- Map line index to actual path depth for navigation
	local function setupLine(btn, lineIndex, displayText)
		if not btn or not btn.text then
			return
		end

		if displayText == "" or displayText == "…" then
			-- Empty or ellipsis - not clickable
			btn.text:SetText(displayText)
			btn:SetScript("OnClick", nil)
			btn:Disable()
			btn.isClickable = false
			return
		end

		-- Determine navigation depth (number of path segments to keep)
		local targetDepth
		local numSegments = #segments

		if numSegments <= 4 then
			-- Direct mapping: line N = keep N segments
			targetDepth = lineIndex
		else
			-- Truncated view for >4 segments:
			-- Line 1 = root (keep 1 segment)
			-- Line 2 = ellipsis (not clickable)
			-- Line 3 = parent of current (numSegments - 1)
			-- Line 4 = current location (numSegments)
			if lineIndex == 1 then
				targetDepth = 1 -- Navigate to root
			elseif lineIndex == 2 then
				targetDepth = nil -- ellipsis, not clickable
			elseif lineIndex == 3 then
				targetDepth = numSegments - 1 -- Navigate to parent
			else -- lineIndex == 4
				targetDepth = numSegments -- current location
			end
		end

		-- Current location has depth = numSegments (length of path)
		-- Line showing current location should not be clickable
		local isCurrentLocation = (targetDepth == numSegments)

		if isCurrentLocation or targetDepth == nil then
			-- Current location or ellipsis - not clickable
			local color = isCurrentLocation and "|cFFFFD100" or "|cFFAAAAAA"
			btn.text:SetText(color .. displayText .. "|r")
			btn:SetScript("OnClick", nil)
			btn:Disable()
			btn.isClickable = false
		else
			-- Parent location - clickable
			btn.text:SetText("|cFFAAAAAA" .. displayText .. "|r")
			btn:Enable()
			btn.isClickable = true
			btn:SetScript("OnClick", function()
				-- Navigate to target depth by truncating path
				if state and state.path then
					local newPath = {}
					for i = 1, targetDepth do
						newPath[i] = state.path[i]
					end
					state.path = newPath
					state.currentPage = 1

					-- Ensure path is valid
					ensureLocationPathValid(state)

					-- Rebuild location rows
					local pageSize = listUI:GetPageSize()
					local page = state.currentPage or 1
					rebuildLocationRows(state, listUI, pageSize, page)

					-- Update breadcrumbs
					if listUI.UpdateLocationBreadcrumbUI then
						listUI:UpdateLocationBreadcrumbUI()
					end

					-- Update list display
					if listUI.UpdateList then
						listUI:UpdateList()
					end

					-- Update header counts
					if listUI.UpdateCountsDisplay then
						listUI:UpdateCountsDisplay()
					end
				end
			end)
		end
	end

	setupLine(line4, 4, lines[4])
	setupLine(line1, 1, lines[1])
	setupLine(line2, 2, lines[2])
	setupLine(line3, 3, lines[3])
end

-- Export helper functions for breadcrumb navigation
ListUI.RebuildLocationRows = rebuildLocationRows
ListUI.EnsureLocationPathValid = ensureLocationPathValid

function ListUI:NavigateInto(segment)
	local state = getLocationState(self)
	segment = normalizeLocationLabel(segment)
	self:DebugPrint(string.format("[BookArchivist] NavigateInto: segment='%s'", segment))
	if segment == "" then
		return
	end
	state.path[#state.path + 1] = segment
	self:DebugPrint(string.format("[BookArchivist] NavigateInto: path now has %d segments", #state.path))
	state.currentPage = 1 -- Reset to page 1 when navigating
	ensureLocationPathValid(state)
	local pageSize = self:GetPageSize()
	local page = state.currentPage or 1
	rebuildLocationRows(state, self, pageSize, page)
	self:UpdateLocationBreadcrumbUI()
end

function ListUI:NavigateUp()
	local state = getLocationState(self)
	local path = state.path
	if not path or #path == 0 then
		return
	end
	table.remove(path)
	state.currentPage = 1 -- Reset to page 1 when navigating
	ensureLocationPathValid(state)
	local pageSize = self:GetPageSize()
	local page = state.currentPage or 1
	rebuildLocationRows(state, self, pageSize, page)
	self:UpdateLocationBreadcrumbUI()
end

function ListUI:RebuildLocationTree()
	local addon = self:GetAddon()
	local state = getLocationState(self)
	if not addon then
		state.root = nil
		state.rows = {}
		state.activeNode = nil
		return
	end

	local db = addon:GetDB()

	-- Phase 2: Generate cache key from current filters
	local categoryId = "__all__"
	if self.GetCategoryId then
		categoryId = self:GetCategoryId() or "__all__"
	end

	local filters = {}
	if self.GetFiltersState then
		filters = self:GetFiltersState() or {}
	end

	local favoritesOnly = filters.favoritesOnly and "true" or "false"
	local searchText = (self.__state and self.__state.searchText) or ""
	local cacheKey = categoryId .. "|" .. favoritesOnly .. "|" .. searchText

	-- Check cache first
	if lastCacheKey == cacheKey then
		if BookArchivist.LogInfo then
			BookArchivist:LogInfo("Using cached location tree")
		end
		state.root = treeCache[cacheKey]
		state.currentPage = 1 -- Reset to page 1
		ensureLocationPathValid(state)
		local pageSize = self:GetPageSize()
		local page = state.currentPage or 1
		rebuildLocationRows(state, self, pageSize, page)
		return
	end

	-- Phase 2: Show loading progress
	local mainFrame = _G["BookArchivistFrame"]

	-- Start async tree build
	local buildResult = buildLocationTreeFromDB(self, db, nil)

	if not buildResult.isAsync then
		-- Fallback: synchronous (empty tree)
		if BookArchivist.LogInfo then
			BookArchivist:LogInfo("RebuildLocationTree: Using synchronous fallback")
		end
		treeCache[cacheKey] = buildResult
		lastCacheKey = cacheKey
		state.currentPage = 1
		ensureLocationPathValid(state)
		local pageSize = self:GetPageSize()
		local page = state.currentPage or 1
		rebuildLocationRows(state, self, pageSize, page)
		self:UpdateLocationBreadcrumbUI()

		-- Enable Locations tab now that tree is built
		if self.SetLocationsTabEnabled then
			self:SetLocationsTabEnabled(true)
		end

		return
	end

	-- Async path: use Iterator
	local Iterator = BookArchivist.Iterator
	local root = buildResult.root
	local order = buildResult.order
	local books = buildResult.books

	if BookArchivist.LogInfo then
		BookArchivist:LogInfo(string.format("RebuildLocationTree: Starting async build with %d books", #order))
	end

	-- Show loading indicator
	if mainFrame and mainFrame.UpdateLoadingProgress then
		mainFrame:UpdateLoadingProgress("building", nil)
	end

	-- Set loading state to prevent tab switches
	self.__state.isLoading = true

	-- Disable tabs during async tree build
	if self.SetTabsEnabled then
		self:SetTabsEnabled(false)
	end

	-- Cancel any existing tree build
	if Iterator:IsRunning("build_location_tree") then
		if BookArchivist.LogInfo then
			BookArchivist:LogInfo("RebuildLocationTree: Cancelling existing build")
		end
		Iterator:Cancel("build_location_tree")
	end

	Iterator:Start("build_location_tree", order, function(idx, bookKey, context)
		-- Initialize context on first call
		if not context.root then
			context.root = root
			context.books = books
			context.self = self
		end
		return processBookIntoTree(idx, bookKey, context)
	end, {
		chunkSize = 50, -- Process 50 books per chunk
		budgetMs = 5, -- Max 5ms per frame
		isArray = true, -- Phase 3: order is already an array, use fast path
		onProgress = function(progress, current, total)
			if mainFrame and mainFrame.UpdateLoadingProgress then
				mainFrame:UpdateLoadingProgress("filtering", progress)
			end
		end,
		onComplete = function(context)
			-- Totals already computed incrementally during tree build
			-- No need for recursive markTotals - eliminating the freeze!

			if BookArchivist.LogInfo then
				BookArchivist:LogInfo(
					string.format(
						"Location tree async build complete: %d books processed, root has %d total",
						#order,
						root.totalBooks or 0
					)
				)
			end

			-- Cache the result
			treeCache[cacheKey] = root
			lastCacheKey = cacheKey
			state.currentPage = 1 -- Start at page 1
			ensureLocationPathValid(state)

			if BookArchivist.LogInfo then
				BookArchivist:LogInfo("Rebuilding location rows...")
			end

			-- Use pagination parameters from ListUI
			local pageSize = self.GetPageSize and self:GetPageSize() or 100
			local page = state.currentPage or 1
			rebuildLocationRows(state, self, pageSize, page)

			-- Update breadcrumb UI
			if self.UpdateLocationBreadcrumbUI then
				self:UpdateLocationBreadcrumbUI()
			end

			-- Clear loading state
			self.__state.isLoading = false

			-- Enable Locations tab now that tree is built
			if self.SetLocationsTabEnabled then
				self:SetLocationsTabEnabled(true)
			end

			-- Re-enable tabs after tree build
			if self.SetTabsEnabled then
				self:SetTabsEnabled(true)
			end

			if BookArchivist.LogInfo then
				BookArchivist:LogInfo(string.format("Location rows built: %d rows", #(state.rows or {})))
			end

			-- Hide loading indicator
			if mainFrame and mainFrame.UpdateLoadingProgress then
				mainFrame:UpdateLoadingProgress("ready")
			end

			-- Defer UpdateList to next frame to avoid blocking
			-- This prevents freeze when adding 1000+ rows to ScrollBox
			local timerAfter = C_Timer and C_Timer.After
			if timerAfter and self.UpdateList then
				if BookArchivist.LogInfo then
					BookArchivist:LogInfo("Deferring UpdateList to next frame...")
				end
				timerAfter(0.05, function()
					if self.UpdateList then
						self:UpdateList()
					end
					if BookArchivist.LogInfo then
						BookArchivist:LogInfo("Location tree build complete!")
					end
				end)
			else
				-- Fallback: immediate update
				if self.UpdateList then
					if BookArchivist.LogInfo then
						BookArchivist:LogInfo("Calling UpdateList immediately (no C_Timer)...")
					end
					self:UpdateList()
				end
				if BookArchivist.LogInfo then
					BookArchivist:LogInfo("Location tree build complete!")
				end
			end
		end,
	})
end

-- Phase 2: Invalidate location tree cache
function ListUI:InvalidateLocationTreeCache()
	treeCache = {}
	lastCacheKey = nil
	if BookArchivist.LogInfo then
		BookArchivist:LogInfo("Location tree cache cleared")
	end
end

local function collectBooksRecursive(node, results)
	if not node then
		return
	end
	if node.books then
		for _, key in ipairs(node.books) do
			table.insert(results, key)
		end
	end
	if node.childNames then
		for _, childName in ipairs(node.childNames) do
			collectBooksRecursive(node.children and node.children[childName], results)
		end
	end
end

function ListUI:GetBooksForNode(node)
	local results = {}
	collectBooksRecursive(node, results)
	return results
end

function ListUI:HasBooksInNode(node)
	return #self:GetBooksForNode(node or {}) > 0
end

function ListUI:GetLocationMenuFrame()
	if not self.__state.locationMenuFrame and CreateFrame then
		self.__state.locationMenuFrame =
			CreateFrame("Frame", "BookArchivistLocationMenu", UIParent, "UIDropDownMenuTemplate")
	end
	return self.__state.locationMenuFrame
end

function ListUI:OpenRandomFromNode(node)
	local books = self:GetBooksForNode(node)
	if #books == 0 then
		return
	end
	local choice = books[math.random(#books)]
	if not choice then
		return
	end
	self:SetSelectedKey(choice)
	self:NotifySelectionChanged()
	self:UpdateList()
end

function ListUI:OpenMostRecentFromNode(node)
	local addon = self:GetAddon()
	local db = addon and addon:GetDB()
	if not db or not (db.booksById or db.books) then
		return
	end
	local books = (db.booksById or db.books) or {}
	local latestKey
	local latestTs = -1
	for _, key in ipairs(self:GetBooksForNode(node)) do
		local entry = books[key]
		local ts = entry and entry.lastSeenAt or 0
		if ts > latestTs then
			latestTs = ts
			latestKey = key
		end
	end
	if latestKey then
		self:SetSelectedKey(latestKey)
		self:NotifySelectionChanged()
		self:UpdateList()
	end
end

function ListUI:ShowLocationContextMenu(anchorButton, node)
	if not anchorButton or not node or not EasyMenu then
		return
	end
	local menuFrame = self:GetLocationMenuFrame()
	if not menuFrame then
		return
	end
	local hasBooks = self:HasBooksInNode(node)
	local menu = {
		{ text = node.name or "Location", isTitle = true, notCheckable = true },
		{
			text = "Open random book",
			notCheckable = true,
			disabled = not hasBooks,
			func = function()
				self:OpenRandomFromNode(node)
			end,
		},
		{
			text = "Open most recent",
			notCheckable = true,
			disabled = not hasBooks,
			func = function()
				self:OpenMostRecentFromNode(node)
			end,
		},
	}
	EasyMenu(menu, menuFrame, anchorButton, 0, 0, "MENU")
end
