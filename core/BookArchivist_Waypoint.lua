---@diagnostic disable: undefined-global
-- BookArchivist_Waypoint.lua
-- Map waypoint functionality for BookArchivist

local BA = BookArchivist

local Waypoint = {}
BA.Waypoint = Waypoint

-- Check if waypoint APIs are available
function Waypoint:IsSupported()
    local hasAPIs = C_Map and C_Map.SetUserWaypoint and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint
    return hasAPIs and true or false
end

-- Check if a book entry has valid location data for setting a waypoint
function Waypoint:HasValidLocation(entry)
    if not entry or not entry.location then
        return false
    end
    local loc = entry.location
    -- Need mapID and valid coordinates (posX, posY are normalized 0-1 values)
    if not loc.mapID then
        return false
    end
    if not loc.posX or not loc.posY then
        return false
    end
    -- Coordinates 0,0 means position couldn't be determined (instance, etc.)
    if loc.posX == 0 and loc.posY == 0 then
        return false
    end
    -- Validate map still exists
    if C_Map and C_Map.GetMapInfo then
        local mapInfo = C_Map.GetMapInfo(loc.mapID)
        if not mapInfo then
            return false
        end
    end
    return true
end

-- Set a waypoint for the book's capture location
-- Returns true on success, false with error message on failure
function Waypoint:SetWaypointForBook(entry)
    if not self:IsSupported() then
        return false, "Waypoint API not available"
    end
    if not self:HasValidLocation(entry) then
        return false, "Book has no valid location data"
    end
    
    local loc = entry.location
    local mapID = loc.mapID
    local posX = loc.posX
    local posY = loc.posY
    
    -- Create the waypoint using UiMapPoint
    -- UiMapPoint.CreateFromVector2D(mapID, Vector2D)
    -- Vector2D is created via CreateVector2D(x, y)
    local success, err = pcall(function()
        local vector = CreateVector2D(posX, posY)
        local mapPoint = UiMapPoint.CreateFromVector2D(mapID, vector)
        C_Map.SetUserWaypoint(mapPoint)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end)
    
    if not success then
        if BA and BA.DebugPrint then
            BA:DebugPrint("[Waypoint] Error setting waypoint: " .. tostring(err))
        end
        return false, "Failed to set waypoint"
    end
    
    -- Open the world map to show the waypoint
    if WorldMapFrame and WorldMapFrame.Show then
        WorldMapFrame:Show()
        if WorldMapFrame.SetMapID then
            WorldMapFrame:SetMapID(mapID)
        end
    end
    
    -- Play feedback sound
    if PlaySound then
        PlaySound(170270) -- Map pin sound
    end
    
    return true
end

-- Get the current book from the UI selection and set a waypoint
function Waypoint:SetWaypointForCurrentBook()
    local Repository = BA and BA.Repository
    if not Repository then
        return false, "Repository not available"
    end
    
    local UI = BA and BA.UI
    if not UI or not UI.Internal or not UI.Internal.getSelectedKey then
        return false, "UI not available"
    end
    
    local selectedBookId = UI.Internal.getSelectedKey()
    if not selectedBookId then
        return false, "No book selected"
    end
    
    local db = Repository:GetDB()
    if not db or not db.booksById then
        return false, "Database not available"
    end
    
    local entry = db.booksById[selectedBookId]
    if not entry then
        return false, "Book not found"
    end
    
    return self:SetWaypointForBook(entry)
end

-- Format location for display (used in tooltips)
function Waypoint:GetLocationDisplayText(entry)
    if not entry or not entry.location then
        return nil
    end
    
    local loc = entry.location
    local text = loc.zoneText or ""
    
    -- Add coordinates if available
    if loc.posX and loc.posY and (loc.posX > 0 or loc.posY > 0) then
        -- Convert normalized (0-1) to percentage (0-100)
        local x = math.floor(loc.posX * 100 + 0.5)
        local y = math.floor(loc.posY * 100 + 0.5)
        text = text .. string.format(" (%.1f, %.1f)", x / 10, y / 10)
    end
    
    return text
end
