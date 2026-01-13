---@diagnostic disable: undefined-global
-- BookArchivist_RandomBook.lua
-- Random book selection with location-aware navigation

local RandomBook = {}
BookArchivist.RandomBook = RandomBook

--- Select a random book from the entire library
--- @param excludeBookId string|nil Optional book ID to exclude from selection
--- @return string|nil bookId The randomly selected book ID, or nil if library is empty
function RandomBook:SelectRandomBook(excludeBookId)
	local db = BookArchivist.Repository:GetDB()
	local order = db.order or {}
	
	if #order == 0 then
		return nil
	end
	
	-- Build candidate list
	local candidates = {}
	for _, bookId in ipairs(order) do
		-- Include all books if only one book exists (single book edge case)
		-- Otherwise, exclude the specified book
		if bookId ~= excludeBookId or #order == 1 then
			table.insert(candidates, bookId)
		end
	end
	
	if #candidates == 0 then
		return nil
	end
	
	-- Uniform random selection
	local index = math.random(1, #candidates)
	return candidates[index]
end

--- Navigate to a book's location and open it in the reader
--- If book has location: Switches to Locations mode and navigates to location
--- If book has no location: Stays in current mode
--- @param bookId string The book ID to navigate to
--- @return boolean success True if navigation succeeded, false otherwise
function RandomBook:NavigateToBookLocation(bookId)
	if BookArchivist.DebugPrint then
		BookArchivist:DebugPrint(string.format("[RandomBook] NavigateToBookLocation called with bookId=%s", tostring(bookId)))
	end
	
	if not bookId then
		return false
	end
	
	local db = BookArchivist.Repository:GetDB()
	local book = db.booksById and db.booksById[bookId]
	
	if not book then
		if BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[RandomBook] Book not found in DB")
		end
		return false
	end
	
	local zoneChain = book.location and book.location.zoneChain
	local hasLocation = zoneChain and type(zoneChain) == "table" and #zoneChain > 0
	
	if BookArchivist.DebugPrint then
		BookArchivist:DebugPrint(string.format("[RandomBook] Book has location: %s (zoneChain length: %d)", tostring(hasLocation), zoneChain and #zoneChain or 0))
	end
	
	-- Get UI components
	local ListUI = BookArchivist.UI and BookArchivist.UI.List
	local ReaderUI = BookArchivist.UI and BookArchivist.UI.Reader
	
	if not ListUI then
		if BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[RandomBook] ListUI not available")
		end
		return false
	end
	
	-- Always set the selection first (needed for both location and non-location cases)
	if ListUI.SetSelectedKey then
		ListUI:SetSelectedKey(bookId)
	end
	
	-- Only switch mode and navigate if book has location
	if hasLocation then
		if BookArchivist.DebugPrint then
			BookArchivist:DebugPrint(string.format("[RandomBook] Navigating to location: %s", table.concat(zoneChain, " > ")))
		end
		
		-- Navigate to the book's location in the tree
		local state = ListUI.GetLocationState and ListUI:GetLocationState()
		if state and state.path then
			-- Build new path from zoneChain
			local newPath = {}
			for i = 1, #zoneChain do
				newPath[i] = zoneChain[i]
			end
			
			-- Replace the entire path
			state.path = newPath
			
			-- Store the target book ID so we can paginate to it after tree is ready
			state.targetBookId = bookId
			
			-- Check if tree already exists
			local treeExists = state.root ~= nil
			
			if BookArchivist.DebugPrint then
				BookArchivist:DebugPrint(string.format("[RandomBook] Tree exists: %s", tostring(treeExists)))
			end
			
			-- If tree doesn't exist, rebuild it (async)
			if not treeExists and ListUI.RebuildLocationTree then
				if BookArchivist.DebugPrint then
					BookArchivist:DebugPrint("[RandomBook] Rebuilding location tree (async)")
				end
				-- Switch to Locations mode (will trigger tree rebuild via mode change)
				if ListUI.SetListMode then
					ListUI:SetListMode("locations")
				end
				-- Tree rebuild will handle pagination via targetBookId when complete
			else
				-- Tree already exists, navigate synchronously
				if BookArchivist.DebugPrint then
					BookArchivist:DebugPrint("[RandomBook] Using existing tree, navigating now")
				end
				
				-- Ensure path is valid (note: using dot notation, not colon)
				if ListUI.EnsureLocationPathValid then
					ListUI.EnsureLocationPathValid(state)
				end
				
				-- Find which page the book is on
				local targetPage = 1
				if ListUI.FindPageForBook then
					local foundPage = ListUI:FindPageForBook(bookId)
					if foundPage then
						targetPage = foundPage
						if BookArchivist.DebugPrint then
							BookArchivist:DebugPrint(string.format("[RandomBook] Found book on page %d", targetPage))
						end
					else
						if BookArchivist.DebugPrint then
							BookArchivist:DebugPrint("[RandomBook] Book not found in location, defaulting to page 1")
						end
					end
				end
				
				-- Set pagination state for Locations mode only
				state.currentPage = targetPage
				
				-- Do NOT update global pagination - that's for Books mode
				-- Each mode maintains its own page state independently
				
				-- Rebuild rows with the correct page
				if ListUI.RebuildLocationRows then
					local pageSize = ListUI.GetPageSize and ListUI:GetPageSize() or 25
					ListUI.RebuildLocationRows(state, ListUI, pageSize, targetPage)
				end
				if ListUI.UpdateLocationBreadcrumbUI then
					ListUI:UpdateLocationBreadcrumbUI()
				end
				
				-- Check current mode
				local currentMode = ListUI.GetListMode and ListUI:GetListMode()
				local needsModeSwitch = (currentMode ~= "locations")
				
				if BookArchivist.DebugPrint then
					BookArchivist:DebugPrint(string.format("[RandomBook] Current mode: %s, needs switch: %s", tostring(currentMode), tostring(needsModeSwitch)))
				end
				
				if needsModeSwitch then
					-- Temporarily prevent tree rebuild during mode switch
					local oldRebuild = ListUI.RebuildLocationTree
					ListUI.RebuildLocationTree = function() 
						if BookArchivist.DebugPrint then
							BookArchivist:DebugPrint("[RandomBook] Suppressing tree rebuild during mode switch")
						end
					end
					
					-- Switch to Locations mode
					if ListUI.SetListMode then
						ListUI:SetListMode("locations")
					end
					
					-- Restore the original function
					ListUI.RebuildLocationTree = oldRebuild
				end
				
				-- Update the list display
				if ListUI.UpdateList then
					ListUI:UpdateList()
				end
				
				-- Clear the target book ID
				state.targetBookId = nil
			end
		end
	end
	-- If no location, just stay in current mode and show the book
	
	-- Notify selection changed to trigger reader update
	if ListUI.NotifySelectionChanged then
		ListUI:NotifySelectionChanged()
	end
	
	-- Render the book in reader
	if ReaderUI and ReaderUI.RenderSelected then
		ReaderUI:RenderSelected()
	end
	
	return true
end

--- Open a random book from the library
--- Automatically excludes currently selected book if multiple books exist
--- Navigates to the book's location context in Locations mode
--- @return boolean success True if a book was opened, false if library is empty
function RandomBook:OpenRandomBook()
	local ListUI = BookArchivist.UI and BookArchivist.UI.List
	local currentBookId = nil
	
	-- Get currently selected book to exclude it
	if ListUI and ListUI.GetSelectedKey then
		currentBookId = ListUI:GetSelectedKey()
	end
	
	-- Select random book (excluding current)
	local randomBookId = self:SelectRandomBook(currentBookId)
	
	if not randomBookId then
		return false
	end
	
	-- Navigate to the random book
	return self:NavigateToBookLocation(randomBookId)
end

return RandomBook
