-- Waypoint tests
-- Tests the Map Waypoint functionality

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load Repository for database access
helper.loadFile("core/BookArchivist_Repository.lua")

-- Load Waypoint module
helper.loadFile("core/BookArchivist_Waypoint.lua")

describe("Waypoint", function()
    local Waypoint
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
        
        -- Get reference to Waypoint module
        Waypoint = BookArchivist.Waypoint
        
        -- Mock WoW APIs
        _G.C_Map = _G.C_Map or {}
        _G.C_SuperTrack = _G.C_SuperTrack or {}
    end)
    
    after_each(function()
        -- Restore
        _G.BookArchivistDB = originalDB
        BookArchivist.Repository:Init(originalDB or {})
    end)
    
    describe("IsSupported", function()
        it("should return false when C_Map.SetUserWaypoint is missing", function()
            _G.C_Map.SetUserWaypoint = nil
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = function() end
            
            local supported = Waypoint:IsSupported()
            assert.is_false(supported)
        end)
        
        it("should return false when C_SuperTrack.SetSuperTrackedUserWaypoint is missing", function()
            _G.C_Map.SetUserWaypoint = function() end
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = nil
            
            local supported = Waypoint:IsSupported()
            assert.is_false(supported)
        end)
        
        it("should return true when both APIs are available", function()
            _G.C_Map.SetUserWaypoint = function() end
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = function() end
            
            local supported = Waypoint:IsSupported()
            assert.is_true(supported)
        end)
    end)
    
    describe("HasValidLocation", function()
        it("should return false for nil entry", function()
            local hasLoc = Waypoint:HasValidLocation(nil)
            assert.is_false(hasLoc)
        end)
        
        it("should return false for entry without location", function()
            local entry = { title = "Test" }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_false(hasLoc)
        end)
        
        it("should return false for entry without mapID", function()
            local entry = {
                location = {
                    posX = 0.5,
                    posY = 0.5,
                },
            }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_false(hasLoc)
        end)
        
        it("should return false for entry without coordinates", function()
            local entry = {
                location = {
                    mapID = 85,
                },
            }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_false(hasLoc)
        end)
        
        it("should return false for entry with zero coordinates", function()
            local entry = {
                location = {
                    mapID = 85,
                    posX = 0,
                    posY = 0,
                },
            }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_false(hasLoc)
        end)
        
        it("should return true for entry with valid location data", function()
            -- Mock C_Map.GetMapInfo to return valid map info
            _G.C_Map.GetMapInfo = function(mapID)
                if mapID == 85 then
                    return { name = "Orgrimmar" }
                end
                return nil
            end
            
            local entry = {
                location = {
                    mapID = 85,
                    posX = 0.5,
                    posY = 0.5,
                },
            }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_true(hasLoc)
        end)
        
        it("should return false when map no longer exists", function()
            -- Mock C_Map.GetMapInfo to return nil (map removed)
            _G.C_Map.GetMapInfo = function(mapID)
                return nil
            end
            
            local entry = {
                location = {
                    mapID = 9999,
                    posX = 0.5,
                    posY = 0.5,
                },
            }
            local hasLoc = Waypoint:HasValidLocation(entry)
            assert.is_false(hasLoc)
        end)
    end)
    
    describe("GetLocationDisplayText", function()
        it("should return nil for entry without location", function()
            local text = Waypoint:GetLocationDisplayText({ title = "Test" })
            assert.is_nil(text)
        end)
        
        it("should return zone text without coordinates if not available", function()
            local entry = {
                location = {
                    zoneText = "Orgrimmar",
                },
            }
            local text = Waypoint:GetLocationDisplayText(entry)
            assert.are.equal("Orgrimmar", text)
        end)
        
        it("should include coordinates in display text", function()
            local entry = {
                location = {
                    zoneText = "Orgrimmar",
                    posX = 0.456,
                    posY = 0.789,
                },
            }
            local text = Waypoint:GetLocationDisplayText(entry)
            -- Coordinates are converted from 0-1 to percentage format (divided by 10)
            -- 0.456 * 100 = 45.6 -> floor(+0.5) = 46 -> 46/10 = 4.6
            -- 0.789 * 100 = 78.9 -> floor(+0.5) = 79 -> 79/10 = 7.9
            assert.is_not_nil(text:match("4%.6"))  -- posX formatted as 4.6
            assert.is_not_nil(text:match("7%.9"))  -- posY formatted as 7.9
        end)
        
        it("should not include zero coordinates", function()
            local entry = {
                location = {
                    zoneText = "Orgrimmar",
                    posX = 0,
                    posY = 0,
                },
            }
            local text = Waypoint:GetLocationDisplayText(entry)
            assert.are.equal("Orgrimmar", text)
        end)
    end)
    
    describe("SetWaypointForBook", function()
        it("should return error when API not supported", function()
            _G.C_Map.SetUserWaypoint = nil
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = nil
            
            local entry = {
                location = {
                    mapID = 85,
                    posX = 0.5,
                    posY = 0.5,
                },
            }
            
            local success, err = Waypoint:SetWaypointForBook(entry)
            assert.is_false(success)
            assert.are.equal("Waypoint API not available", err)
        end)
        
        it("should return error for entry without valid location", function()
            _G.C_Map.SetUserWaypoint = function() end
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = function() end
            _G.C_Map.GetMapInfo = function() return nil end
            
            local entry = { title = "Test" }
            
            local success, err = Waypoint:SetWaypointForBook(entry)
            assert.is_false(success)
            assert.are.equal("Book has no valid location data", err)
        end)
        
        it("should set waypoint successfully with valid data", function()
            local waypointSet = false
            local superTrackSet = false
            
            _G.C_Map.SetUserWaypoint = function() waypointSet = true end
            _G.C_SuperTrack.SetSuperTrackedUserWaypoint = function() superTrackSet = true end
            _G.C_Map.GetMapInfo = function(mapID)
                return { name = "Orgrimmar" }
            end
            
            -- Mock required globals
            _G.CreateVector2D = function(x, y)
                return { x = x, y = y }
            end
            _G.UiMapPoint = {
                CreateFromVector2D = function(mapID, vector)
                    return { mapID = mapID, vector = vector }
                end,
            }
            _G.WorldMapFrame = nil  -- Skip world map opening
            _G.PlaySound = function() end
            
            local entry = {
                location = {
                    mapID = 85,
                    posX = 0.5,
                    posY = 0.5,
                },
            }
            
            local success, err = Waypoint:SetWaypointForBook(entry)
            assert.is_true(success)
            assert.is_nil(err)
            assert.is_true(waypointSet)
            assert.is_true(superTrackSet)
        end)
    end)
    
    describe("SetWaypointForCurrentBook", function()
        it("should return error when no book is selected", function()
            -- Setup UI mock without selected book
            BookArchivist.UI = {
                Internal = {
                    getSelectedKey = function() return nil end,
                },
            }
            
            local success, err = Waypoint:SetWaypointForCurrentBook()
            assert.is_false(success)
            assert.are.equal("No book selected", err)
        end)
        
        it("should return error when book not found", function()
            -- Setup UI mock with selected book
            BookArchivist.UI = {
                Internal = {
                    getSelectedKey = function() return "b2:nonexistent" end,
                },
            }
            
            local success, err = Waypoint:SetWaypointForCurrentBook()
            assert.is_false(success)
            assert.are.equal("Book not found", err)
        end)
    end)
end)
