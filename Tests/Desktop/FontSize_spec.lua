-- FontSize tests
-- Tests the Font Size customization functionality

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load Repository for database access
helper.loadFile("core/BookArchivist_Repository.lua")

-- Load FontSize module
helper.loadFile("core/BookArchivist_FontSize.lua")

describe("FontSize", function()
    local FontSize
    local testDB
    local originalDB
    
    before_each(function()
        -- Backup original
        originalDB = BookArchivistDB
        
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
        
        -- Get reference to FontSize module
        FontSize = BookArchivist.FontSize
    end)
    
    after_each(function()
        -- Restore
        _G.BookArchivistDB = originalDB
        BookArchivist.Repository:Init(originalDB or {})
    end)
    
    describe("GetScale", function()
        it("should return default value (1.0) when not set", function()
            local scale = FontSize:GetScale()
            assert.are.equal(1.0, scale)
        end)
        
        it("should return stored value when set", function()
            testDB.options.fontSize = 1.2
            local scale = FontSize:GetScale()
            assert.are.equal(1.2, scale)
        end)
        
        it("should clamp values below minimum", function()
            testDB.options.fontSize = 0.5  -- Below minimum of 0.8
            local scale = FontSize:GetScale()
            assert.are.equal(0.8, scale)
        end)
        
        it("should clamp values above maximum", function()
            testDB.options.fontSize = 2.0  -- Above maximum of 1.5
            local scale = FontSize:GetScale()
            assert.are.equal(1.5, scale)
        end)
    end)
    
    describe("SetScale", function()
        it("should store the scale value", function()
            FontSize:SetScale(1.3)
            assert.are.equal(1.3, testDB.options.fontSize)
        end)
        
        it("should clamp values below minimum", function()
            FontSize:SetScale(0.5)
            assert.are.equal(0.8, testDB.options.fontSize)
        end)
        
        it("should clamp values above maximum", function()
            FontSize:SetScale(2.0)
            assert.are.equal(1.5, testDB.options.fontSize)
        end)
        
        it("should initialize options table if not present", function()
            testDB.options = nil
            FontSize:SetScale(1.2)
            assert.is_not_nil(testDB.options)
            assert.are.equal(1.2, testDB.options.fontSize)
        end)
    end)
    
    describe("GetDefault", function()
        it("should return 1.0", function()
            assert.are.equal(1.0, FontSize:GetDefault())
        end)
    end)
    
    describe("GetMin", function()
        it("should return 0.8", function()
            assert.are.equal(0.8, FontSize:GetMin())
        end)
    end)
    
    describe("GetMax", function()
        it("should return 1.5", function()
            assert.are.equal(1.5, FontSize:GetMax())
        end)
    end)
    
    describe("GetScaledSize", function()
        it("should return base size when scale is 1.0", function()
            testDB.options.fontSize = 1.0
            local scaled = FontSize:GetScaledSize(14)
            assert.are.equal(14, scaled)
        end)
        
        it("should scale up when scale > 1.0", function()
            testDB.options.fontSize = 1.5
            local scaled = FontSize:GetScaledSize(14)
            assert.are.equal(21, scaled)  -- 14 * 1.5 = 21
        end)
        
        it("should scale down when scale < 1.0", function()
            testDB.options.fontSize = 0.8
            local scaled = FontSize:GetScaledSize(10)
            assert.are.equal(8, scaled)  -- 10 * 0.8 = 8
        end)
        
        it("should round to nearest integer", function()
            testDB.options.fontSize = 1.1
            local scaled = FontSize:GetScaledSize(14)
            assert.are.equal(15, scaled)  -- 14 * 1.1 = 15.4 -> 15
        end)
    end)
    
    describe("GetDisplayPercentage", function()
        it("should return '100%' for scale 1.0", function()
            testDB.options.fontSize = 1.0
            assert.are.equal("100%", FontSize:GetDisplayPercentage())
        end)
        
        it("should return '150%' for scale 1.5", function()
            testDB.options.fontSize = 1.5
            assert.are.equal("150%", FontSize:GetDisplayPercentage())
        end)
        
        it("should return '80%' for scale 0.8", function()
            testDB.options.fontSize = 0.8
            assert.are.equal("80%", FontSize:GetDisplayPercentage())
        end)
    end)
    
    describe("ApplyToFontString", function()
        it("should not crash when fontString is nil", function()
            -- Should not throw error
            FontSize:ApplyToFontString(nil)
        end)
        
        it("should not modify font when scale is 1.0", function()
            testDB.options.fontSize = 1.0
            
            local mockFontString = {
                GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end,
                SetFont = function(self, path, size, flags)
                    self._lastSetFont = { path = path, size = size, flags = flags }
                end,
            }
            
            FontSize:ApplyToFontString(mockFontString)
            
            -- SetFont should not have been called for scale 1.0
            assert.is_nil(mockFontString._lastSetFont)
        end)
        
        it("should scale font when scale is not 1.0", function()
            testDB.options.fontSize = 1.2
            
            local mockFontString = {
                GetFont = function() return "Fonts\\FRIZQT__.TTF", 14, "" end,
                SetFont = function(self, path, size, flags)
                    self._lastSetFont = { path = path, size = size, flags = flags }
                end,
            }
            
            FontSize:ApplyToFontString(mockFontString)
            
            assert.is_not_nil(mockFontString._lastSetFont)
            assert.are.equal("Fonts\\FRIZQT__.TTF", mockFontString._lastSetFont.path)
            assert.are.equal(17, mockFontString._lastSetFont.size)  -- 14 * 1.2 = 16.8 -> 17
        end)
    end)
end)
