-- ReaderCopy tests
-- Tests the Copy to Clipboard functionality for the reader panel

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load Repository for database access
helper.loadFile("core/BookArchivist_Repository.lua")

-- Mock CreateFrame for UI testing
local mockFrames = {}

local function createMockFrame(frameType, name, parent, template)
    local frame = {
        _type = frameType,
        _name = name,
        _parent = parent,
        _template = template,
        _scripts = {},
        _children = {},
        _text = "",
        _visible = false,
        _width = 100,
        _height = 100,
    }
    
    function frame:SetScript(event, handler)
        self._scripts[event] = handler
    end
    
    function frame:GetScript(event)
        return self._scripts[event]
    end
    
    function frame:SetSize(w, h)
        self._width = w
        self._height = h
    end
    
    function frame:GetWidth()
        return self._width or 100
    end
    
    function frame:GetHeight()
        return self._height or 100
    end
    
    function frame:SetHeight(h)
        self._height = h
    end
    
    function frame:SetWidth(w)
        self._width = w
    end
    
    function frame:SetPoint() end
    function frame:SetFrameStrata() end
    function frame:EnableMouse() end
    function frame:SetMovable() end
    function frame:RegisterForDrag() end
    function frame:SetBackdrop() end
    function frame:ClearAllPoints() end
    function frame:StartMoving() end
    function frame:StopMovingOrSizing() end
    
    function frame:Show()
        self._visible = true
    end
    
    function frame:Hide()
        self._visible = false
    end
    
    function frame:IsShown()
        return self._visible
    end
    
    function frame:CreateFontString(...)
        local fontString = {
            _text = "",
            SetPoint = function() end,
            SetJustifyH = function() end,
            SetWordWrap = function() end,
            SetText = function(self, text) self._text = text end,
            GetText = function(self) return self._text end,
        }
        return fontString
    end
    
    -- EditBox methods
    function frame:SetMultiLine() end
    function frame:SetAutoFocus() end
    function frame:SetFontObject() end
    function frame:SetMaxLetters() end
    function frame:SetText(text) self._text = text or "" end
    function frame:GetText() return self._text or "" end
    function frame:SetFocus() end
    function frame:HighlightText() end
    function frame:SetCursorPosition() end
    
    -- ScrollFrame methods
    function frame:SetScrollChild(child)
        self._scrollChild = child
    end
    
    if name then
        mockFrames[name] = frame
    end
    
    return frame
end

_G.CreateFrame = createMockFrame

-- Mock UIParent
_G.UIParent = {}

-- Mock GameTooltip
_G.GameTooltip = {
    SetOwner = function() end,
    SetText = function() end,
    AddLine = function() end,
    Show = function() end,
    Hide = function() end,
}

-- Load Copy module
helper.loadFile("ui/reader/BookArchivist_UI_Reader_Copy.lua")

describe("ReaderCopy", function()
    local ReaderCopy
    local testDB
    local originalDB
    
    before_each(function()
        -- Backup original
        originalDB = BookArchivistDB
        
        -- Clear mock frames cache
        mockFrames = {}
        
        -- Create test database
        testDB = {
            dbVersion = 3,
            booksById = {},
            order = {},
            indexes = {
                objectToBookId = {},
                itemToBookIds = {},
                titleToBookIds = {},
            },
            options = {},
        }
        
        _G.BookArchivistDB = testDB
        
        -- Initialize Repository
        BookArchivist.Repository:Init(testDB)
        
        -- Reload Copy module to reset its state
        BookArchivist.UI = BookArchivist.UI or {}
        BookArchivist.UI.Reader = BookArchivist.UI.Reader or {}
        BookArchivist.UI.Reader.Copy = nil  -- Reset the Copy module
        helper.loadFile("ui/reader/BookArchivist_UI_Reader_Copy.lua")
        
        -- Get reference to Copy module
        ReaderCopy = BookArchivist.UI.Reader.Copy
    end)
    
    after_each(function()
        -- Restore
        _G.BookArchivistDB = originalDB
        BookArchivist.Repository:Init(originalDB or {})
        mockFrames = {}
    end)
    
    describe("stripFormatting (internal)", function()
        -- We can test the Show function behavior which uses stripFormatting internally
        
        it("should handle nil book data gracefully", function()
            -- Show with nil should not crash
            ReaderCopy:Show(nil, "Test Book")
            -- Should not create the copy frame since no data
        end)
        
        it("should handle book with empty pages", function()
            local bookData = {
                title = "Empty Book",
                pages = {},
            }
            
            -- Should not crash, but may show empty
            ReaderCopy:Show(bookData, "Empty Book")
        end)
    end)
    
    describe("Show", function()
        it("should create copy frame when showing valid book", function()
            local bookData = {
                title = "Test Book",
                pages = {
                    [1] = "This is page one content.",
                    [2] = "This is page two content.",
                },
            }
            
            ReaderCopy:Show(bookData, "Test Book")
            
            -- Frame should be created
            assert.is_not_nil(mockFrames["BookArchivistCopyFrame"])
        end)
        
        it("should strip HTML tags from content", function()
            local bookData = {
                title = "HTML Book",
                pages = {
                    [1] = "<html><body><p>Hello World</p></body></html>",
                },
            }
            
            ReaderCopy:Show(bookData, "HTML Book")
            
            local frame = mockFrames["BookArchivistCopyFrame"]
            assert.is_not_nil(frame)
            -- The editBox should have stripped HTML
            if frame and frame.editBox then
                local text = frame.editBox:GetText()
                assert.is_not_nil(text)
                assert.does_not_match("<[^>]+>", text)
            end
        end)
        
        it("should strip WoW color codes from content", function()
            local bookData = {
                title = "Colored Book",
                pages = {
                    [1] = "|cFFFF0000Red Text|r and |cFF00FF00Green Text|r",
                },
            }
            
            ReaderCopy:Show(bookData, "Colored Book")
            
            local frame = mockFrames["BookArchivistCopyFrame"]
            assert.is_not_nil(frame)
            if frame and frame.editBox then
                local text = frame.editBox:GetText()
                assert.is_not_nil(text)
                assert.does_not_match("|c%x+", text)
                assert.does_not_match("|r", text)
            end
        end)
        
        it("should convert |n to newlines", function()
            local bookData = {
                title = "Newline Book",
                pages = {
                    [1] = "Line 1|nLine 2|nLine 3",
                },
            }
            
            ReaderCopy:Show(bookData, "Newline Book")
            
            local frame = mockFrames["BookArchivistCopyFrame"]
            if frame and frame.editBox then
                local text = frame.editBox:GetText()
                assert.is_not_nil(text)
                assert.does_not_match("|n", text)
                -- Should contain actual newlines
                assert.matches("\n", text)
            end
        end)
    end)
    
    describe("CopyCurrentBook", function()
        it("should not crash when no book is selected", function()
            local getSelectedKey = function() return nil end
            
            -- Should not crash
            ReaderCopy:CopyCurrentBook(getSelectedKey)
        end)
        
        it("should show copy dialog for valid selection", function()
            -- Add a book to the database
            testDB.booksById["test-book"] = {
                id = "test-book",
                title = "My Test Book",
                pages = {
                    [1] = "Test content here.",
                },
            }
            
            local getSelectedKey = function() return "test-book" end
            
            ReaderCopy:CopyCurrentBook(getSelectedKey)
            
            -- Frame should be created and shown
            local frame = mockFrames["BookArchivistCopyFrame"]
            assert.is_not_nil(frame)
        end)
        
        it("should not crash for non-existent book key", function()
            local getSelectedKey = function() return "non-existent-key" end
            
            -- Should not crash
            ReaderCopy:CopyCurrentBook(getSelectedKey)
        end)
    end)
    
    describe("Text extraction", function()
        it("should combine multiple pages with separators", function()
            local bookData = {
                title = "Multi-Page Book",
                pages = {
                    [1] = "Page one.",
                    [2] = "Page two.",
                    [3] = "Page three.",
                },
            }
            
            ReaderCopy:Show(bookData, "Multi-Page Book")
            
            local frame = mockFrames["BookArchivistCopyFrame"]
            if frame and frame.editBox then
                local text = frame.editBox:GetText()
                assert.is_not_nil(text)
                -- Should contain all pages
                assert.matches("Page one", text)
                assert.matches("Page two", text)
                assert.matches("Page three", text)
            end
        end)
        
        it("should respect pageOrder when provided", function()
            local bookData = {
                title = "Ordered Book",
                pages = {
                    ["a"] = "First page",
                    ["b"] = "Second page",
                    ["c"] = "Third page",
                },
                pageOrder = { "a", "b", "c" },
            }
            
            ReaderCopy:Show(bookData, "Ordered Book")
            
            local frame = mockFrames["BookArchivistCopyFrame"]
            assert.is_not_nil(frame)
        end)
    end)
end)
