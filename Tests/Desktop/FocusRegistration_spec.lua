---@diagnostic disable: undefined-global
-- FocusRegistration_spec.lua
-- Tests for the Focus Registration system (registers UI elements with FocusManager)

local helper = dofile("Tests/test_helper.lua")

describe("BookArchivist.UI.FocusRegistration", function()
    local FocusRegistration
    local FocusManager
    local originalDB

    -- Mock frame for testing
    local function createMockFrame(name, isShown)
        return {
            name = name,
            shown = isShown ~= false,
            visible = isShown ~= false,
            IsShown = function(self) return self.shown end,
            IsVisible = function(self) return self.visible end,
            Click = function(self) self.clicked = true end,
            SetFocus = function(self) self.focused = true end,
            GetScript = function() return nil end,
            GetObjectType = function() return "Button" end,
            GetParent = function() return nil end,
            bookArchivistFocusId = nil,
        }
    end

    -- Mock ListUI module
    local mockListUI
    local mockListFrames

    before_each(function()
        -- Backup original global DB
        originalDB = BookArchivistDB

        -- Setup namespace
        helper.setupNamespace()

        -- Mock UI parent namespace
        BookArchivist.UI = BookArchivist.UI or {}
        BookArchivist.UI.Internal = BookArchivist.UI.Internal or {}

        -- Mock L (localization)
        BookArchivist.L = {
            ["HEADER_BUTTON_OPTIONS"] = "Options",
            ["HEADER_BUTTON_HELP"] = "Help",
            ["RANDOM_BOOK_TOOLTIP"] = "Random Book",
            ["NEW_BOOK"] = "New Book",
            ["TAB_BOOKS"] = "Books Tab",
            ["TAB_LOCATIONS"] = "Locations Tab",
            ["FOCUS_SEARCH_BOX"] = "Search Box",
            ["SORT_DROPDOWN_PLACEHOLDER"] = "Sort",
            ["ACTION_SHARE"] = "Share",
            ["ACTION_COPY"] = "Copy",
            ["ACTION_WAYPOINT"] = "Waypoint",
            ["ACTION_FAVORITE"] = "Favorite",
            ["ACTION_UNFAVORITE"] = "Unfavorite",
            ["ACTION_DELETE"] = "Delete",
            ["PAGINATION_FIRST"] = "First",
            ["PAGINATION_PREV"] = "Prev",
            ["PAGINATION_NEXT"] = "Next",
            ["PAGINATION_LAST"] = "Last",
            ["FOCUS_BOOK_ROW"] = "Book",
            ["FOCUS_INSTRUCTIONS"] = "Tab: Next",
            ["FOCUS_NO_ELEMENTS"] = "None",
        }

        -- Mock GetTime
        _G.GetTime = function() return 100 end

        -- Mock CreateFrame
        _G.CreateFrame = function(frameType, name, parent, template)
            local frame = createMockFrame(name, false)
            frame.SetFrameStrata = function() end
            frame.SetFrameLevel = function() end
            frame.SetBackdrop = function() end
            frame.SetBackdropColor = function() end
            frame.SetBackdropBorderColor = function() end
            frame.SetSize = function() end
            frame.SetPoint = function() end
            frame.ClearAllPoints = function() end
            frame.Show = function(self) self.shown = true end
            frame.Hide = function(self) self.shown = false end
            frame.CreateTexture = function()
                return {
                    SetTexture = function() end,
                    SetPoint = function() end,
                    SetVertexColor = function() end,
                    SetBlendMode = function() end,
                    SetAllPoints = function() end,
                }
            end
            frame.CreateFontString = function()
                return {
                    SetPoint = function() end,
                    SetTextColor = function() end,
                    SetText = function() end,
                    GetText = function() return "" end,
                    GetStringWidth = function() return 100 end,
                }
            end
            frame.SetWidth = function() end
            return frame
        end

        _G.UIParent = createMockFrame("UIParent", true)
        _G.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
        _G.UIDropDownMenu_Toggle = function() end

        -- Setup mock frames for ListUI
        mockListFrames = {
            helpButton = createMockFrame("helpButton", true),
            optionsButton = createMockFrame("optionsButton", true),
            randomButton = createMockFrame("randomButton", true),
            newBookButton = createMockFrame("newBookButton", true),
            booksTabButton = createMockFrame("booksTabButton", true),
            locationsTabButton = createMockFrame("locationsTabButton", true),
            searchBox = createMockFrame("searchBox", true),
            firstPageBtn = createMockFrame("firstPageBtn", true),
            prevPageBtn = createMockFrame("prevPageBtn", true),
            nextPageBtn = createMockFrame("nextPageBtn", true),
            lastPageBtn = createMockFrame("lastPageBtn", true),
        }
        mockListFrames.searchBox.objectType = "EditBox"

        -- Mock ListUI
        mockListUI = {
            GetFrame = function(self, frameName)
                return mockListFrames[frameName]
            end,
            __state = {
                buttonPool = {}
            }
        }
        BookArchivist.UI.List = mockListUI

        -- Mock global frames for reader buttons
        _G["BookArchivistShareButton"] = createMockFrame("BookArchivistShareButton", true)
        _G["BookArchivistCopyButton"] = createMockFrame("BookArchivistCopyButton", true)
        _G["BookArchivistWaypointButton"] = createMockFrame("BookArchivistWaypointButton", true)
        _G["BookArchivistFavoriteButton"] = createMockFrame("BookArchivistFavoriteButton", true)
        _G["BookArchivistDeleteButton"] = createMockFrame("BookArchivistDeleteButton", true)
        _G["BookArchivistSortDropdown"] = createMockFrame("BookArchivistSortDropdown", true)
        _G["BookArchivistSortDropdownButton"] = createMockFrame("BookArchivistSortDropdownButton", true)

        -- Load the FocusManager module first (FocusRegistration depends on it)
        helper.loadFile("ui/BookArchivist_UI_FocusManager.lua")
        FocusManager = BookArchivist.UI.FocusManager

        -- Load the FocusRegistration module
        helper.loadFile("ui/BookArchivist_UI_FocusRegistration.lua")
        FocusRegistration = BookArchivist.UI.FocusRegistration
    end)

    after_each(function()
        -- Restore original global DB
        BookArchivistDB = originalDB

        -- Disable focus manager if enabled
        if FocusManager and FocusManager.Disable then
            FocusManager:Disable()
        end

        -- Clean up global frames
        _G["BookArchivistShareButton"] = nil
        _G["BookArchivistCopyButton"] = nil
        _G["BookArchivistWaypointButton"] = nil
        _G["BookArchivistFavoriteButton"] = nil
        _G["BookArchivistDeleteButton"] = nil
        _G["BookArchivistSortDropdown"] = nil
        _G["BookArchivistSortDropdownButton"] = nil
    end)

    describe("RegisterHeaderElements", function()
        it("should register header buttons", function()
            FocusRegistration:RegisterHeaderElements()

            -- Check frames were marked with focus IDs
            assert.are.equal("header-help", mockListFrames.helpButton.bookArchivistFocusId)
            assert.are.equal("header-options", mockListFrames.optionsButton.bookArchivistFocusId)
            assert.are.equal("header-random", mockListFrames.randomButton.bookArchivistFocusId)
            assert.are.equal("header-newbook", mockListFrames.newBookButton.bookArchivistFocusId)
        end)

        it("should handle missing ListUI gracefully", function()
            BookArchivist.UI.List = nil

            -- Should not throw an error
            FocusRegistration:RegisterHeaderElements()
        end)

        it("should handle missing frames gracefully", function()
            mockListFrames.helpButton = nil
            mockListFrames.optionsButton = nil

            -- Should not throw an error
            FocusRegistration:RegisterHeaderElements()

            -- Other frames should still be registered
            assert.are.equal("header-random", mockListFrames.randomButton.bookArchivistFocusId)
        end)
    end)

    describe("RegisterTabElements", function()
        it("should register tab buttons", function()
            FocusRegistration:RegisterTabElements()

            assert.are.equal("tab-books", mockListFrames.booksTabButton.bookArchivistFocusId)
            assert.are.equal("tab-locations", mockListFrames.locationsTabButton.bookArchivistFocusId)
        end)
    end)

    describe("RegisterFilterElements", function()
        it("should register search box", function()
            FocusRegistration:RegisterFilterElements()

            assert.are.equal("filter-search", mockListFrames.searchBox.bookArchivistFocusId)
        end)

        it("should register sort dropdown", function()
            FocusRegistration:RegisterFilterElements()

            assert.are.equal("filter-sort", _G["BookArchivistSortDropdown"].bookArchivistFocusId)
        end)
    end)

    describe("RegisterReaderElements", function()
        it("should register reader action buttons", function()
            FocusRegistration:RegisterReaderElements()

            assert.are.equal("reader-share", _G["BookArchivistShareButton"].bookArchivistFocusId)
            assert.are.equal("reader-copy", _G["BookArchivistCopyButton"].bookArchivistFocusId)
            assert.are.equal("reader-waypoint", _G["BookArchivistWaypointButton"].bookArchivistFocusId)
            assert.are.equal("reader-favorite", _G["BookArchivistFavoriteButton"].bookArchivistFocusId)
            assert.are.equal("reader-delete", _G["BookArchivistDeleteButton"].bookArchivistFocusId)
        end)

        it("should handle missing global buttons gracefully", function()
            _G["BookArchivistShareButton"] = nil
            _G["BookArchivistCopyButton"] = nil

            -- Should not throw an error
            FocusRegistration:RegisterReaderElements()

            -- Other buttons should still be registered
            assert.are.equal("reader-waypoint", _G["BookArchivistWaypointButton"].bookArchivistFocusId)
        end)
    end)

    describe("RegisterPaginationElements", function()
        it("should register pagination buttons", function()
            FocusRegistration:RegisterPaginationElements()

            assert.are.equal("page-first", mockListFrames.firstPageBtn.bookArchivistFocusId)
            assert.are.equal("page-prev", mockListFrames.prevPageBtn.bookArchivistFocusId)
            assert.are.equal("page-next", mockListFrames.nextPageBtn.bookArchivistFocusId)
            assert.are.equal("page-last", mockListFrames.lastPageBtn.bookArchivistFocusId)
        end)
    end)

    describe("RegisterListRows", function()
        it("should register visible list rows", function()
            -- Setup mock button pool with visible buttons
            local row1 = createMockFrame("row1", true)
            row1.bookId = "book-123"
            row1.title = { GetText = function() return "Test Book 1" end }

            local row2 = createMockFrame("row2", true)
            row2.bookId = "book-456"
            row2.title = { GetText = function() return "Test Book 2" end }

            local row3 = createMockFrame("row3", false) -- hidden
            row3.bookId = "book-789"

            mockListUI.__state.buttonPool = { row1, row2, row3 }

            FocusRegistration:RegisterListRows()

            -- Only visible rows should be registered
            assert.are.equal("list-row-1", row1.bookArchivistFocusId)
            assert.are.equal("list-row-2", row2.bookArchivistFocusId)
            assert.is_nil(row3.bookArchivistFocusId)
        end)

        it("should unregister previous rows before re-registering", function()
            -- First registration
            local row1 = createMockFrame("row1", true)
            row1.bookId = "book-123"
            row1.title = { GetText = function() return "Book 1" end }
            mockListUI.__state.buttonPool = { row1 }

            FocusRegistration:RegisterListRows()
            assert.are.equal("list-row-1", row1.bookArchivistFocusId)

            -- Second registration with different rows
            local row2 = createMockFrame("row2", true)
            row2.bookId = "book-456"
            row2.title = { GetText = function() return "Book 2" end }
            mockListUI.__state.buttonPool = { row2 }

            FocusRegistration:RegisterListRows()

            -- row1 should be unregistered (via UnregisterElement which clears bookArchivistFocusId)
            -- row2 should be registered
            assert.are.equal("list-row-1", row2.bookArchivistFocusId)
        end)

        it("should handle empty button pool", function()
            mockListUI.__state.buttonPool = {}

            -- Should not throw an error
            FocusRegistration:RegisterListRows()
        end)

        it("should handle nil button pool", function()
            mockListUI.__state.buttonPool = nil

            -- Should not throw an error
            FocusRegistration:RegisterListRows()
        end)
    end)

    describe("RegisterAll", function()
        it("should register all element types", function()
            FocusRegistration:RegisterAll()

            -- Check header elements
            assert.are.equal("header-help", mockListFrames.helpButton.bookArchivistFocusId)
            assert.are.equal("header-options", mockListFrames.optionsButton.bookArchivistFocusId)

            -- Check tabs
            assert.are.equal("tab-books", mockListFrames.booksTabButton.bookArchivistFocusId)
            assert.are.equal("tab-locations", mockListFrames.locationsTabButton.bookArchivistFocusId)

            -- Check filters
            assert.are.equal("filter-search", mockListFrames.searchBox.bookArchivistFocusId)

            -- Check reader actions
            assert.are.equal("reader-share", _G["BookArchivistShareButton"].bookArchivistFocusId)

            -- Check pagination
            assert.are.equal("page-first", mockListFrames.firstPageBtn.bookArchivistFocusId)
        end)
    end)

    describe("Refresh", function()
        it("should re-register reader elements and list rows", function()
            -- Initial registration
            FocusRegistration:RegisterAll()

            -- Add a new button that wasn't there before
            local newRow = createMockFrame("newRow", true)
            newRow.bookId = "new-book"
            newRow.title = { GetText = function() return "New Book" end }
            mockListUI.__state.buttonPool = { newRow }

            -- Simulate time passing for debounce
            local timeValue = 100
            _G.GetTime = function() return timeValue end
            timeValue = timeValue + 1

            FocusRegistration:Refresh()

            -- New row should be registered
            assert.are.equal("list-row-1", newRow.bookArchivistFocusId)
        end)

        it("should call FocusManager.Refresh if available", function()
            local refreshCalled = false
            FocusManager.Refresh = function()
                refreshCalled = true
            end

            -- Simulate time passing for debounce
            local timeValue = 100
            _G.GetTime = function() return timeValue end
            timeValue = timeValue + 1

            FocusRegistration:Refresh()

            assert.is_true(refreshCalled)
        end)
    end)

    describe("Integration with FocusManager", function()
        it("should allow FocusManager to find registered elements", function()
            FocusRegistration:RegisterAll()

            local elements = FocusManager:ScanFocusableElements()

            -- Should find multiple elements across categories
            assert.is_true(#elements > 0)

            -- Check that elements are in expected order (header first)
            local firstCategory = elements[1].category
            assert.are.equal("header", firstCategory)
        end)

        it("should enable navigation through all registered elements", function()
            FocusRegistration:RegisterAll()

            FocusManager:Enable()

            local state = FocusManager:GetState()
            assert.is_true(state.enabled)
            assert.is_true(state.totalElements > 0)
            -- Block-based navigation: starts in List block (block 2), not at global index 1
            -- Verify we're in the List block
            assert.are.equal(2, state.currentBlockIndex)
            local initialIndex = state.currentIndex

            -- Navigate forward within the same block
            FocusManager:FocusNext()
            state = FocusManager:GetState()
            -- Should advance to next element (or wrap within block)
            assert.is_true(state.currentIndex >= 1)
            assert.are.equal(2, state.currentBlockIndex) -- Still in same block
        end)
    end)
end)
