---@diagnostic disable: undefined-global, undefined-field
--[[
    BookArchivist Focus Registration
    
    Registers all focusable UI elements with the FocusManager.
    Called during UI initialization to set up keyboard navigation.
]]

local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI then
    return
end

local FocusRegistration = {}
addonRoot.UI.FocusRegistration = FocusRegistration

local L = addonRoot.L or {}
local function t(key)
    return (L and L[key]) or key
end

--[[
    Register all header elements (Options, Help, Random, New Book buttons).
]]
function FocusRegistration:RegisterHeaderElements()
    local FM = addonRoot.UI.FocusManager
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not FM or not ListUI then
        return
    end
    
    -- Help button
    local helpButton = ListUI.GetFrame and ListUI:GetFrame("helpButton")
    if helpButton then
        FM:RegisterElement("header-help", helpButton, "header", t("HEADER_BUTTON_HELP"), function(frame)
            if frame.Click then frame:Click() end
        end, 10)
    end
    
    -- Options button
    local optionsButton = ListUI.GetFrame and ListUI:GetFrame("optionsButton")
    if optionsButton then
        FM:RegisterElement("header-options", optionsButton, "header", t("HEADER_BUTTON_OPTIONS"), function(frame)
            if frame.Click then frame:Click() end
        end, 20)
    end
    
    -- Random book button
    local randomButton = ListUI.GetFrame and ListUI:GetFrame("randomButton")
    if randomButton then
        FM:RegisterElement("header-random", randomButton, "header", t("RANDOM_BOOK_TOOLTIP"), function(frame)
            if frame.Click then frame:Click() end
        end, 30)
    end
    
    -- New Book button
    local newBookButton = ListUI.GetFrame and ListUI:GetFrame("newBookButton")
    if newBookButton then
        FM:RegisterElement("header-newbook", newBookButton, "header", t("NEW_BOOK"), function(frame)
            if frame.Click then frame:Click() end
        end, 40)
    end
end

--[[
    Register tab elements (Books, Locations).
]]
function FocusRegistration:RegisterTabElements()
    local FM = addonRoot.UI.FocusManager
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not FM or not ListUI then
        return
    end
    
    -- Books tab (stored as "booksTabButton" in ListUI)
    local booksTab = ListUI.GetFrame and ListUI:GetFrame("booksTabButton")
    if booksTab then
        FM:RegisterElement("tab-books", booksTab, "tabs", t("TAB_BOOKS"), function(frame)
            if frame.Click then frame:Click() end
        end, 10)
    end
    
    -- Locations tab (stored as "locationsTabButton" in ListUI)
    local locationsTab = ListUI.GetFrame and ListUI:GetFrame("locationsTabButton")
    if locationsTab then
        FM:RegisterElement("tab-locations", locationsTab, "tabs", t("TAB_LOCATIONS"), function(frame)
            if frame.Click then frame:Click() end
        end, 20)
    end
end

--[[
    Register filter elements (Sort dropdown, Search box).
]]
function FocusRegistration:RegisterFilterElements()
    local FM = addonRoot.UI.FocusManager
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not FM or not ListUI then
        return
    end
    
    -- Search box
    local searchBox = ListUI.GetFrame and ListUI:GetFrame("searchBox")
    if searchBox then
        FM:RegisterElement("filter-search", searchBox, "filters", t("FOCUS_SEARCH_BOX"), function(frame)
            if frame.SetFocus then
                frame:SetFocus()
            end
        end, 10)
    end
    
    -- Sort dropdown
    local sortDropdown = _G["BookArchivistSortDropdown"]
    if sortDropdown then
        FM:RegisterElement("filter-sort", sortDropdown, "filters", t("SORT_DROPDOWN_PLACEHOLDER"), function(frame)
            -- Use ToggleDropDownMenu to open the dropdown programmatically
            if ToggleDropDownMenu then
                ToggleDropDownMenu(1, nil, frame, frame:GetName(), 0, 0)
            else
                -- Fallback: click the dropdown button
                local button = _G["BookArchivistSortDropdownButton"]
                if button and button.Click then
                    button:Click()
                end
            end
        end, 20, { isDropdown = true })
    end
    
    -- Category dropdowns (All Books, Favorites, Recent)
    -- These are inside the sort dropdown but we can register the virtual categories
end

--[[
    Register reader action elements (Waypoint, Copy, Share, Favorite, Delete).
    Priority order matches visual left-to-right layout in actionsRail:
      [TTS] [Waypoint] [Copy] [Share] [Favorite] [CustomIcon?] [Delete]
    TTS has its own keybinding so is excluded from focus navigation.
]]
function FocusRegistration:RegisterReaderElements()
    local FM = addonRoot.UI.FocusManager
    if not FM then
        return
    end
    
    -- Waypoint button (leftmost after TTS)
    local waypointButton = _G["BookArchivistWaypointButton"]
    if waypointButton then
        FM:RegisterElement("reader-waypoint", waypointButton, "reader", t("ACTION_WAYPOINT"), function(frame)
            if frame.Click then frame:Click() end
        end, 10)
    end
    
    -- Copy button
    local copyButton = _G["BookArchivistCopyButton"]
    if copyButton then
        FM:RegisterElement("reader-copy", copyButton, "reader", t("ACTION_COPY"), function(frame)
            if frame.Click then frame:Click() end
        end, 20)
    end
    
    -- Share button
    local shareButton = _G["BookArchivistShareButton"]
    if shareButton then
        FM:RegisterElement("reader-share", shareButton, "reader", t("ACTION_SHARE"), function(frame)
            if frame.Click then frame:Click() end
        end, 30)
    end
    
    -- Favorite button
    local favoriteButton = _G["BookArchivistFavoriteButton"]
    if favoriteButton then
        FM:RegisterElement("reader-favorite", favoriteButton, "reader", function()
            -- Dynamic name based on state
            local ReaderUI = addonRoot.UI and addonRoot.UI.Reader
            local state = ReaderUI and ReaderUI.__state
            if state and state.selectedBookId then
                local Favorites = addonRoot.Favorites
                if Favorites and Favorites.IsFavorite then
                    if Favorites:IsFavorite(state.selectedBookId) then
                        return t("ACTION_UNFAVORITE")
                    end
                end
            end
            return t("ACTION_FAVORITE")
        end, function(frame)
            if frame.Click then frame:Click() end
        end, 40)
    end
    
    -- Delete button (rightmost)
    local deleteButton = _G["BookArchivistDeleteButton"]
    if deleteButton then
        FM:RegisterElement("reader-delete", deleteButton, "reader", t("ACTION_DELETE"), function(frame)
            if frame.Click then frame:Click() end
        end, 50)
    end
    
    -- TTS button is excluded (has its own keybinding)
end

--[[
    Register edit mode elements (New Book / Edit Book UI).
    These use the "reader" category since they replace the reader panel content.
]]
function FocusRegistration:RegisterEditModeElements()
    local FM = addonRoot.UI.FocusManager
    local ReaderUI = addonRoot.UI and addonRoot.UI.Reader
    if not FM or not ReaderUI then
        return
    end
    
    local state = ReaderUI.__state
    if not state then
        return
    end
    
    -- Check if edit mode is active
    local EditMode = ReaderUI.EditMode
    if not EditMode or not EditMode:IsEditing() then
        -- Unregister edit elements when not in edit mode
        FM:UnregisterElement("edit-title")
        FM:UnregisterElement("edit-location")
        FM:UnregisterElement("edit-content")
        FM:UnregisterElement("edit-prev-page")
        FM:UnregisterElement("edit-add-page")
        FM:UnregisterElement("edit-next-page")
        FM:UnregisterElement("edit-tts-preview")
        FM:UnregisterElement("edit-save")
        FM:UnregisterElement("edit-cancel")
        return
    end
    
    -- Title input box
    local titleBox = state.editTitleBox
    if titleBox then
        FM:RegisterElement("edit-title", titleBox, "reader", t("BOOK_TITLE") or "Title", function(frame)
            if frame.SetFocus then frame:SetFocus() end
        end, 10)
    end
    
    -- Use Current Location button
    local useLocBtn = state.editUseCurrentLocBtn
    if useLocBtn then
        FM:RegisterElement("edit-location", useLocBtn, "reader", t("USE_CURRENT_LOC") or "Use Current Location", function(frame)
            if frame.Click then frame:Click() end
        end, 20)
    end
    
    -- Page content edit (AceGUI MultiLineEditBox)
    local pageEdit = state.editPageEdit
    if pageEdit and pageEdit.frame then
        -- For AceGUI widgets, we need to focus the internal editBox
        FM:RegisterElement("edit-content", pageEdit.frame, "reader", t("PAGE_CONTENT") or "Page Content", function(frame)
            if pageEdit.editBox and pageEdit.editBox.SetFocus then
                pageEdit.editBox:SetFocus()
            end
        end, 30)
    end
    
    -- Page navigation - Prev Page
    local prevPageBtn = state.editPrevPageBtn
    if prevPageBtn then
        FM:RegisterElement("edit-prev-page", prevPageBtn, "reader", t("PREV_PAGE") or "Previous Page", function(frame)
            if frame.Click then frame:Click() end
        end, 40)
    end
    
    -- Page navigation - Add Page
    local addPageBtn = state.editAddPageBtn
    if addPageBtn then
        FM:RegisterElement("edit-add-page", addPageBtn, "reader", t("ADD_PAGE") or "Add Page", function(frame)
            if frame.Click then frame:Click() end
        end, 50)
    end
    
    -- Page navigation - Next Page
    local nextPageBtn = state.editNextPageBtn
    if nextPageBtn then
        FM:RegisterElement("edit-next-page", nextPageBtn, "reader", t("NEXT_PAGE") or "Next Page", function(frame)
            if frame.Click then frame:Click() end
        end, 60)
    end
    
    -- TTS Preview button
    local ttsPreviewBtn = state.editTTSPreviewBtn
    if ttsPreviewBtn then
        FM:RegisterElement("edit-tts-preview", ttsPreviewBtn, "reader", t("TTS_PREVIEW") or "Preview", function(frame)
            if frame.Click then frame:Click() end
        end, 70)
    end
    
    -- Save button
    local saveBtn = state.editSaveBtn
    if saveBtn then
        FM:RegisterElement("edit-save", saveBtn, "reader", t("SAVE_BOOK") or "Save Book", function(frame)
            if frame.Click then frame:Click() end
        end, 80)
    end
    
    -- Cancel button
    local cancelBtn = state.editCancelBtn
    if cancelBtn then
        FM:RegisterElement("edit-cancel", cancelBtn, "reader", t("CANCEL") or "Cancel", function(frame)
            if frame.Click then frame:Click() end
        end, 90)
    end
    
    if addonRoot.DebugPrint then
        addonRoot:DebugPrint("[FocusRegistration] RegisterEditModeElements: registered edit mode elements")
    end
end

--[[
    Register pagination elements.
]]
function FocusRegistration:RegisterPaginationElements()
    local FM = addonRoot.UI.FocusManager
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not FM or not ListUI then
        return
    end
    
    -- First page button
    local firstPageBtn = ListUI.GetFrame and ListUI:GetFrame("firstPageBtn")
    if firstPageBtn then
        FM:RegisterElement("page-first", firstPageBtn, "pagination", t("PAGINATION_FIRST"), function(frame)
            if frame.Click then frame:Click() end
        end, 10)
    end
    
    -- Prev page button
    local prevPageBtn = ListUI.GetFrame and ListUI:GetFrame("prevPageBtn")
    if prevPageBtn then
        FM:RegisterElement("page-prev", prevPageBtn, "pagination", t("PAGINATION_PREV"), function(frame)
            if frame.Click then frame:Click() end
        end, 20)
    end
    
    -- Next page button
    local nextPageBtn = ListUI.GetFrame and ListUI:GetFrame("nextPageBtn")
    if nextPageBtn then
        FM:RegisterElement("page-next", nextPageBtn, "pagination", t("PAGINATION_NEXT"), function(frame)
            if frame.Click then frame:Click() end
        end, 30)
    end
    
    -- Last page button
    local lastPageBtn = ListUI.GetFrame and ListUI:GetFrame("lastPageBtn")
    if lastPageBtn then
        FM:RegisterElement("page-last", lastPageBtn, "pagination", t("PAGINATION_LAST"), function(frame)
            if frame.Click then frame:Click() end
        end, 40)
    end
end

--[[
    Register book list rows dynamically.
    Call this after the list is refreshed to register visible rows.
]]
function FocusRegistration:RegisterListRows()
    local FM = addonRoot.UI.FocusManager
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not FM or not ListUI then
        return
    end
    
    -- First, unregister all existing list row elements
    for i = 1, 50 do
        FM:UnregisterElement("list-row-" .. i)
    end
    
    local scrollBox = ListUI:GetFrame("scrollBox")
    
    -- Collect all valid row frames first (we'll sort them by position later)
    local rowFrames = {}
    
    -- Helper to check if a frame is a valid list row
    local function isValidRow(button)
        if not button or not button.IsShown or not button:IsShown() then
            return false
        end
        -- Check for any identifier that indicates this is a list row
        if not button.bookKey and not button.bookId and not button.itemKind and not button.locationName then
            return false
        end
        return true
    end
    
    -- Helper to collect valid rows from a list of children
    local function collectRows(children)
        for _, child in ipairs(children) do
            if isValidRow(child) then
                table.insert(rowFrames, child)
            end
        end
    end
    
    -- Method 1: Get scroll target from WowScrollBoxList
    if scrollBox then
        local scrollTarget = scrollBox.GetScrollTarget and scrollBox:GetScrollTarget()
        if scrollTarget and scrollTarget.GetChildren then
            collectRows({ scrollTarget:GetChildren() })
        end
    end
    
    -- Method 2: Try WowScrollBoxList's GetFrames() iterator
    if #rowFrames == 0 and scrollBox and scrollBox.GetFrames then
        local success, iterator = pcall(function() return scrollBox:GetFrames() end)
        if success and iterator then
            -- GetFrames returns an iterator function
            if type(iterator) == "function" then
                for button in iterator do
                    if isValidRow(button) then
                        table.insert(rowFrames, button)
                    end
                end
            elseif type(iterator) == "table" then
                for _, button in pairs(iterator) do
                    if isValidRow(button) then
                        table.insert(rowFrames, button)
                    end
                end
            end
        end
    end
    
    -- Method 3: Try EnumerateFrames
    if #rowFrames == 0 and scrollBox and scrollBox.EnumerateFrames then
        for button in scrollBox:EnumerateFrames() do
            if isValidRow(button) then
                table.insert(rowFrames, button)
            end
        end
    end
    
    -- Method 4: Try direct children + grandchildren
    if #rowFrames == 0 and scrollBox and scrollBox.GetChildren then
        local children = { scrollBox:GetChildren() }
        for _, child in ipairs(children) do
            if isValidRow(child) then
                table.insert(rowFrames, child)
            elseif child.GetChildren then
                collectRows({ child:GetChildren() })
            end
        end
    end
    
    -- Method 5: Try ListUI:GetListScrollChild()
    if #rowFrames == 0 and ListUI.GetListScrollChild then
        local scrollChild = ListUI:GetListScrollChild()
        if scrollChild and scrollChild.GetChildren then
            collectRows({ scrollChild:GetChildren() })
        end
    end
    
    -- Method 6: Fallback to buttonPool (for tests)
    if #rowFrames == 0 then
        local buttonPool = ListUI.__state and ListUI.__state.buttonPool
        if buttonPool then
            local activeRows = buttonPool.active or buttonPool
            if type(activeRows) == "table" then
                for _, button in ipairs(activeRows) do
                    if isValidRow(button) then
                        table.insert(rowFrames, button)
                    end
                end
            end
        end
    end
    
    -- CRITICAL: Sort frames by their visual Y position (top to bottom)
    -- GetTop() returns the top edge position; higher values = higher on screen
    table.sort(rowFrames, function(a, b)
        local topA = a.GetTop and a:GetTop() or 0
        local topB = b.GetTop and b:GetTop() or 0
        return topA > topB  -- Higher Y = earlier in list (top of screen)
    end)
    
    -- Now register in sorted order
    local count = 0
    for i, button in ipairs(rowFrames) do
        count = count + 1
        local rowIndex = count
        local capturedButton = button
        
        local displayName = function()
            if capturedButton.titleText and capturedButton.titleText.GetText then
                return capturedButton.titleText:GetText() or t("FOCUS_BOOK_ROW")
            elseif capturedButton.title and capturedButton.title.GetText then
                return capturedButton.title:GetText() or t("FOCUS_BOOK_ROW")
            end
            return t("FOCUS_BOOK_ROW") .. " " .. rowIndex
        end
        
        FM:RegisterElement("list-row-" .. count, button, "list", displayName, function(frame)
            if frame.Click then
                frame:Click()
            elseif frame.GetScript then
                local onClick = frame:GetScript("OnClick")
                if onClick then
                    onClick(frame, "LeftButton", false)
                end
            end
        end, rowIndex)
    end
    
    -- Debug: Print count if debug mode is on
    if addonRoot and addonRoot.DebugPrint then
        addonRoot:DebugPrint(string.format("[FocusRegistration] RegisterListRows: registered %d rows", count))
    end
end

--[[
    Debug function to inspect what's available in the scroll box.
    Call via /ba debugfocus
]]
function FocusRegistration:DebugScrollBox()
    local ListUI = addonRoot.UI and addonRoot.UI.List
    if not ListUI then
        print("|cFFFF0000[BookArchivist] ListUI not available|r")
        return
    end
    
    local scrollBox = ListUI:GetFrame("scrollBox")
    if not scrollBox then
        print("|cFFFF0000[BookArchivist] scrollBox not found|r")
        return
    end
    
    print("|cFF00FF00[BookArchivist] ScrollBox Debug:|r")
    print("  scrollBox type: " .. tostring(scrollBox:GetObjectType()))
    print("  GetScrollTarget: " .. tostring(scrollBox.GetScrollTarget ~= nil))
    print("  GetFrames: " .. tostring(scrollBox.GetFrames ~= nil))
    print("  EnumerateFrames: " .. tostring(scrollBox.EnumerateFrames ~= nil))
    print("  GetChildren: " .. tostring(scrollBox.GetChildren ~= nil))
    
    -- Try GetScrollTarget
    if scrollBox.GetScrollTarget then
        local target = scrollBox:GetScrollTarget()
        if target then
            print("  ScrollTarget type: " .. tostring(target:GetObjectType()))
            if target.GetChildren then
                local children = { target:GetChildren() }
                print("  ScrollTarget children: " .. #children)
                for i, child in ipairs(children) do
                    if i <= 5 then
                        local bookKey = child.bookKey or "nil"
                        local itemKind = child.itemKind or "nil"
                        local shown = child:IsShown() and "shown" or "hidden"
                        print(string.format("    [%d] %s bookKey=%s itemKind=%s (%s)", 
                            i, child:GetObjectType(), tostring(bookKey), tostring(itemKind), shown))
                    end
                end
                if #children > 5 then
                    print("    ... and " .. (#children - 5) .. " more")
                end
            end
        else
            print("  ScrollTarget: nil")
        end
    end
    
    -- Try direct children
    if scrollBox.GetChildren then
        local children = { scrollBox:GetChildren() }
        print("  Direct children: " .. #children)
        for i, child in ipairs(children) do
            if i <= 3 then
                print(string.format("    [%d] %s", i, child:GetObjectType()))
            end
        end
    end
    
    -- Check ListUI:GetListScrollChild
    if ListUI.GetListScrollChild then
        local scrollChild = ListUI:GetListScrollChild()
        if scrollChild then
            print("  GetListScrollChild type: " .. tostring(scrollChild:GetObjectType()))
            if scrollChild.GetChildren then
                local children = { scrollChild:GetChildren() }
                print("  GetListScrollChild children: " .. #children)
            end
        else
            print("  GetListScrollChild: nil")
        end
    end
end

--[[
    Register all UI elements.
    Call this during UI initialization.
]]
function FocusRegistration:RegisterAll()
    self:RegisterHeaderElements()
    self:RegisterTabElements()
    self:RegisterFilterElements()
    self:RegisterReaderElements()
    self:RegisterPaginationElements()
    -- List rows are registered dynamically via RegisterListRows()
end

--[[
    Refresh registrations (call after UI state changes).
]]
function FocusRegistration:Refresh()
    -- Re-register dynamic elements
    self:RegisterReaderElements()
    self:RegisterEditModeElements()
    self:RegisterListRows()
    
    -- Tell FocusManager to refresh
    local FM = addonRoot.UI.FocusManager
    if FM and FM.Refresh then
        FM:Refresh()
    end
end

return FocusRegistration
