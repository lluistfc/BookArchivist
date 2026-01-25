---@diagnostic disable: undefined-global
-- FocusManager_spec.lua
-- Tests for the Focus Navigation system (accessibility keyboard navigation)

local helper = dofile("Tests/test_helper.lua")

describe("BookArchivist.UI.FocusManager", function()
    local FocusManager
    local originalDB

    -- Mock frame for testing
    local function createMockFrame(name, isShown)
        return {
            name = name,
            shown = isShown ~= false, -- default to shown
            visible = isShown ~= false,
            IsShown = function(self) return self.shown end,
            IsVisible = function(self) return self.visible end,
            Click = function(self) self.clicked = true end,
            SetFocus = function(self) self.focused = true end,
            GetScript = function(self, scriptType)
                if scriptType == "OnClick" and self.onClickHandler then
                    return self.onClickHandler
                end
                return nil
            end,
            GetObjectType = function(self) return self.objectType or "Button" end,
            GetParent = function(self) return self.parent end,
            bookArchivistFocusId = nil,
            clicked = false,
            focused = false,
        }
    end

    before_each(function()
        -- Backup original global DB
        originalDB = BookArchivistDB

        -- Setup namespace
        helper.setupNamespace()

        -- Mock UI parent namespace
        BookArchivist.UI = BookArchivist.UI or {}
        BookArchivist.UI.Internal = BookArchivist.UI.Internal or {}

        -- Mock IsUIVisible (default to true for tests)
        BookArchivist.IsUIVisible = function() return true end

        -- Mock L (localization)
        BookArchivist.L = {
            ["FOCUS_INSTRUCTIONS"] = "Tab: Next | Enter: Activate",
            ["FOCUS_NO_ELEMENTS"] = "No focusable elements",
            ["FOCUS_CATEGORY_HEADER"] = "Header",
            ["FOCUS_CATEGORY_TABS"] = "Tabs",
        }

        -- Mock GetTime
        _G.GetTime = function() return 100 end

        -- Mock CreateFrame for highlight/indicator panels
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
                    SetText = function(self, text) self.text = text end,
                    GetText = function(self) return self.text end,
                    GetStringWidth = function() return 100 end,
                }
            end
            frame.SetWidth = function() end
            return frame
        end

        _G.UIParent = createMockFrame("UIParent", true)
        _G.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end

        -- Load the FocusManager module
        helper.loadFile("ui/BookArchivist_UI_FocusManager.lua")

        FocusManager = BookArchivist.UI.FocusManager
    end)

    after_each(function()
        -- Restore original global DB
        BookArchivistDB = originalDB

        -- Disable focus manager if enabled
        if FocusManager and FocusManager.Disable then
            FocusManager:Disable()
        end
    end)

    describe("RegisterElement", function()
        it("should register a focusable element", function()
            local frame = createMockFrame("testButton", true)

            FocusManager:RegisterElement("test-btn", frame, "header", "Test Button", nil, 10)

            assert.is_not_nil(frame.bookArchivistFocusId)
            assert.are.equal("test-btn", frame.bookArchivistFocusId)
        end)

        it("should not register without an id", function()
            local frame = createMockFrame("testButton", true)

            FocusManager:RegisterElement(nil, frame, "header", "Test Button")

            assert.is_nil(frame.bookArchivistFocusId)
        end)

        it("should not register without a frame", function()
            -- Should not throw an error
            FocusManager:RegisterElement("test-btn", nil, "header", "Test Button")
        end)
    end)

    describe("UnregisterElement", function()
        it("should unregister a previously registered element", function()
            local frame = createMockFrame("testButton", true)
            FocusManager:RegisterElement("test-btn", frame, "header", "Test Button")

            assert.are.equal("test-btn", frame.bookArchivistFocusId)

            FocusManager:UnregisterElement("test-btn")

            assert.is_nil(frame.bookArchivistFocusId)
        end)

        it("should handle unregistering non-existent element gracefully", function()
            -- Should not throw an error
            FocusManager:UnregisterElement("non-existent")
        end)
    end)

    describe("ScanFocusableElements", function()
        it("should find visible registered elements", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)
            local frame3 = createMockFrame("btn3", false) -- hidden

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)
            FocusManager:RegisterElement("btn-3", frame3, "header", "Button 3", nil, 30)

            local elements = FocusManager:ScanFocusableElements()

            -- Should only find 2 visible elements
            assert.are.equal(2, #elements)
        end)

        it("should sort elements by category then priority", function()
            local headerBtn = createMockFrame("headerBtn", true)
            local tabBtn = createMockFrame("tabBtn", true)
            local filterBtn = createMockFrame("filterBtn", true)

            FocusManager:RegisterElement("filter-btn", filterBtn, "filters", "Filter", nil, 10)
            FocusManager:RegisterElement("header-btn", headerBtn, "header", "Header", nil, 10)
            FocusManager:RegisterElement("tab-btn", tabBtn, "tabs", "Tab", nil, 10)

            local elements = FocusManager:ScanFocusableElements()

            assert.are.equal(3, #elements)
            assert.are.equal("header-btn", elements[1].id)
            assert.are.equal("tab-btn", elements[2].id)
            assert.are.equal("filter-btn", elements[3].id)
        end)

        it("should sort by priority within same category", function()
            local btn1 = createMockFrame("btn1", true)
            local btn2 = createMockFrame("btn2", true)
            local btn3 = createMockFrame("btn3", true)

            FocusManager:RegisterElement("btn-high", btn1, "header", "High", nil, 30)
            FocusManager:RegisterElement("btn-low", btn2, "header", "Low", nil, 10)
            FocusManager:RegisterElement("btn-mid", btn3, "header", "Mid", nil, 20)

            local elements = FocusManager:ScanFocusableElements()

            assert.are.equal("btn-low", elements[1].id)
            assert.are.equal("btn-mid", elements[2].id)
            assert.are.equal("btn-high", elements[3].id)
        end)
    end)

    describe("Enable/Disable", function()
        it("should enable focus navigation mode", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            FocusManager:Enable()

            assert.is_true(FocusManager:IsEnabled())
        end)

        it("should disable focus navigation mode", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            FocusManager:Enable()
            FocusManager:Disable()

            assert.is_false(FocusManager:IsEnabled())
        end)

        it("should toggle between enabled and disabled", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            assert.is_false(FocusManager:IsEnabled())

            FocusManager:Toggle()
            assert.is_true(FocusManager:IsEnabled())

            FocusManager:Toggle()
            assert.is_false(FocusManager:IsEnabled())
        end)
    end)

    describe("FocusElement", function()
        it("should focus element by index", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)

            FocusManager:Enable()

            local state = FocusManager:GetState()
            assert.are.equal(1, state.currentIndex)

            FocusManager:FocusElement(2)
            state = FocusManager:GetState()
            assert.are.equal(2, state.currentIndex)
        end)

        it("should wrap around when going past the end", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)

            FocusManager:Enable()
            FocusManager:FocusElement(3) -- Only 2 elements, should wrap to 1

            local state = FocusManager:GetState()
            assert.are.equal(1, state.currentIndex)
        end)

        it("should wrap around when going before the start", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)

            FocusManager:Enable()
            FocusManager:FocusElement(0) -- Should wrap to last element (2)

            local state = FocusManager:GetState()
            assert.are.equal(2, state.currentIndex)
        end)
    end)

    describe("FocusNext/FocusPrev", function()
        it("should advance to next element", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)
            local frame3 = createMockFrame("btn3", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)
            FocusManager:RegisterElement("btn-3", frame3, "header", "Button 3", nil, 30)

            FocusManager:Enable()

            local state = FocusManager:GetState()
            assert.are.equal(1, state.currentIndex)

            FocusManager:FocusNext()
            state = FocusManager:GetState()
            assert.are.equal(2, state.currentIndex)

            FocusManager:FocusNext()
            state = FocusManager:GetState()
            assert.are.equal(3, state.currentIndex)
        end)

        it("should go back to previous element", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)
            local frame3 = createMockFrame("btn3", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)
            FocusManager:RegisterElement("btn-3", frame3, "header", "Button 3", nil, 30)

            FocusManager:Enable()
            FocusManager:FocusElement(3) -- Start at end

            FocusManager:FocusPrev()
            local state = FocusManager:GetState()
            assert.are.equal(2, state.currentIndex)

            FocusManager:FocusPrev()
            state = FocusManager:GetState()
            assert.are.equal(1, state.currentIndex)
        end)

        it("should enable focus mode if not already enabled", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            assert.is_false(FocusManager:IsEnabled())

            FocusManager:FocusNext()

            assert.is_true(FocusManager:IsEnabled())
        end)
    end)

    describe("ActivateCurrent", function()
        it("should call Click on button frames", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            FocusManager:Enable()

            assert.is_false(frame.clicked)
            FocusManager:ActivateCurrent()
            assert.is_true(frame.clicked)
        end)

        it("should call custom onActivate handler if provided", function()
            local frame = createMockFrame("btn", true)
            local activated = false

            FocusManager:RegisterElement("btn", frame, "header", "Button", function()
                activated = true
            end)

            FocusManager:Enable()

            assert.is_false(activated)
            FocusManager:ActivateCurrent()
            assert.is_true(activated)
        end)

        it("should call SetFocus on EditBox frames", function()
            local frame = createMockFrame("editbox", true)
            frame.objectType = "EditBox"
            frame.Click = nil -- EditBox doesn't have Click

            FocusManager:RegisterElement("editbox", frame, "filters", "Search Box")

            FocusManager:Enable()

            assert.is_false(frame.focused)
            FocusManager:ActivateCurrent()
            assert.is_true(frame.focused)
        end)

        it("should return false when not enabled", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            local result = FocusManager:ActivateCurrent()

            assert.is_false(result)
        end)
    end)

    describe("GetState", function()
        it("should return current focus state", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)

            FocusManager:Enable()
            FocusManager:FocusElement(2)

            local state = FocusManager:GetState()

            assert.is_true(state.enabled)
            assert.are.equal(2, state.currentIndex)
            assert.are.equal(2, state.totalElements)
            assert.is_not_nil(state.currentElement)
            assert.are.equal("btn-2", state.currentElement.id)
        end)
    end)

    describe("Dynamic display names", function()
        it("should support function-based display names", function()
            local frame = createMockFrame("btn", true)
            local dynamicName = "Initial Name"

            FocusManager:RegisterElement("btn", frame, "header", function()
                return dynamicName
            end)

            FocusManager:Enable()

            local state = FocusManager:GetState()
            -- The display name is evaluated when needed
            assert.are.equal("btn", state.currentElement.id)
            -- displayName should be the function
            assert.are.equal("function", type(state.currentElement.displayName))
        end)
    end)

    describe("Exported functions for bindings", function()
        it("should export FocusNext function", function()
            assert.is_function(BookArchivist.FocusNext)
        end)

        it("should export FocusPrev function", function()
            assert.is_function(BookArchivist.FocusPrev)
        end)

        it("should export FocusActivate function", function()
            assert.is_function(BookArchivist.FocusActivate)
        end)

        it("should export FocusToggle function", function()
            assert.is_function(BookArchivist.FocusToggle)
        end)

        it("should call FocusManager methods from exported functions", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            assert.is_false(FocusManager:IsEnabled())

            BookArchivist.FocusToggle()

            assert.is_true(FocusManager:IsEnabled())
        end)
    end)

    describe("Refresh", function()
        it("should maintain focus on same element after refresh", function()
            local frame1 = createMockFrame("btn1", true)
            local frame2 = createMockFrame("btn2", true)

            FocusManager:RegisterElement("btn-1", frame1, "header", "Button 1", nil, 10)
            FocusManager:RegisterElement("btn-2", frame2, "header", "Button 2", nil, 20)

            FocusManager:Enable()
            FocusManager:FocusElement(2)

            -- Simulate time passing for debounce
            local timeValue = 100
            _G.GetTime = function() return timeValue end
            timeValue = timeValue + 1 -- Advance time past debounce

            FocusManager:Refresh()

            local state = FocusManager:GetState()
            assert.are.equal("btn-2", state.currentElement.id)
        end)

        it("should not refresh when disabled", function()
            local frame = createMockFrame("btn", true)
            FocusManager:RegisterElement("btn", frame, "header", "Button")

            -- Refresh should do nothing when disabled
            FocusManager:Refresh()

            assert.is_false(FocusManager:IsEnabled())
        end)
    end)
end)
