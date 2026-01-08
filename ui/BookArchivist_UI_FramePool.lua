-- BookArchivist_UI_FramePool.lua
-- Frame pooling system to prevent memory leaks from creating thousands of UI elements
-- Reuses frames instead of creating new ones for list rows, buttons, etc.

local ADDON_NAME = "BookArchivist"
local BookArchivist = _G[ADDON_NAME]
if not BookArchivist then return end

BookArchivist.UI = BookArchivist.UI or {}
local FramePool = {}
BookArchivist.UI.FramePool = FramePool

-- All frame pools indexed by pool name
local pools = {}

--- Create or get a frame pool
--- @param poolName string Unique pool identifier (e.g., "listRows", "buttons")
--- @param frameType string Frame type ("Button", "Frame", "EditBox", etc.)
--- @param parent Frame Parent frame for all pooled frames
--- @param template string|nil Optional template name (e.g., "BackdropTemplate")
--- @return table pool The pool object
function FramePool:CreatePool(poolName, frameType, parent, template)
  if pools[poolName] then
    return pools[poolName]
  end
  
  if not poolName or type(poolName) ~= "string" then
    error("FramePool:CreatePool - poolName must be a string")
  end
  
  if not frameType or type(frameType) ~= "string" then
    error("FramePool:CreatePool - frameType must be a string")
  end
  
  if not parent then
    error("FramePool:CreatePool - parent frame is required")
  end
  
  local pool = {
    name = poolName,
    frameType = frameType,
    parent = parent,
    template = template,
    available = {}, -- Frames ready for reuse
    active = {}, -- Frames currently in use (set for O(1) lookup)
    totalCreated = 0, -- Lifetime frame creation count
    resetFunc = nil, -- Custom reset function
  }
  
  pools[poolName] = pool
  
  if BookArchivist.LogInfo then
    BookArchivist:LogInfo(string.format(
      "FramePool created: %s (type=%s, template=%s)",
      poolName, frameType, template or "none"
    ))
  end
  
  return pool
end

--- Set a custom reset function to clean up frame state
--- Called automatically when a frame is released back to the pool
--- @param poolName string Pool identifier
--- @param resetFunc function(frame) Custom reset function
function FramePool:SetResetFunction(poolName, resetFunc)
  local pool = pools[poolName]
  if not pool then
    if BookArchivist.LogWarning then
      BookArchivist:LogWarning("FramePool:SetResetFunction - pool not found: " .. tostring(poolName))
    end
    return false
  end
  
  if type(resetFunc) ~= "function" then
    if BookArchivist.LogWarning then
      BookArchivist:LogWarning("FramePool:SetResetFunction - resetFunc must be a function")
    end
    return false
  end
  
  pool.resetFunc = resetFunc
  return true
end

--- Acquire a frame from the pool
--- Reuses an existing frame if available, otherwise creates a new one
--- @param poolName string Pool identifier
--- @return Frame|nil frame The acquired frame, or nil on error
function FramePool:Acquire(poolName)
  local pool = pools[poolName]
  if not pool then
    if BookArchivist.LogError then
      BookArchivist:LogError("FramePool:Acquire - pool not found: " .. tostring(poolName))
    end
    return nil
  end
  
  local frame
  
  if #pool.available > 0 then
    -- Reuse existing frame
    frame = table.remove(pool.available)
  else
    -- Create new frame
    frame = CreateFrame(pool.frameType, nil, pool.parent, pool.template)
    if not frame then
      if BookArchivist.LogError then
        BookArchivist:LogError(string.format(
          "FramePool:Acquire - CreateFrame failed for pool %s",
          poolName
        ))
      end
      return nil
    end
    
    pool.totalCreated = pool.totalCreated + 1
    frame.__poolName = poolName
    frame.__poolIndex = pool.totalCreated
  end
  
  -- Mark as active
  frame:Show()
  pool.active[frame] = true
  
  return frame
end

--- Release a frame back to the pool for reuse
--- Automatically resets frame state and hides it
--- @param frame Frame The frame to release
--- @return boolean success
function FramePool:Release(frame)
  if not frame then
    return false
  end
  
  if not frame.__poolName then
    if BookArchivist.LogWarning then
      BookArchivist:LogWarning("FramePool:Release - frame does not belong to any pool")
    end
    return false
  end
  
  local poolName = frame.__poolName
  local pool = pools[poolName]
  if not pool then
    if BookArchivist.LogError then
      BookArchivist:LogError("FramePool:Release - pool not found: " .. tostring(poolName))
    end
    return false
  end
  
  -- Remove from active set
  if not pool.active[frame] then
    -- Already released
    return true
  end
  pool.active[frame] = nil
  
  -- Reset frame state
  if pool.resetFunc then
    local success, err = pcall(pool.resetFunc, frame)
    if not success and BookArchivist.LogError then
      BookArchivist:LogError(string.format(
        "FramePool:Release - reset function error for %s: %s",
        poolName, tostring(err)
      ))
    end
  else
    self:DefaultReset(frame)
  end
  
  -- Hide and clear positioning
  frame:Hide()
  frame:ClearAllPoints()
  
  -- Return to available pool
  table.insert(pool.available, frame)
  
  return true
end

--- Default reset function for common frame properties
--- Called automatically if no custom reset function is set
--- @param frame Frame The frame to reset
function FramePool:DefaultReset(frame)
  -- Clear text
  if frame.SetText then 
    pcall(frame.SetText, frame, "")
  end
  
  -- Clear textures
  if frame.SetNormalTexture then 
    pcall(frame.SetNormalTexture, frame, nil)
  end
  if frame.SetHighlightTexture then 
    pcall(frame.SetHighlightTexture, frame, nil)
  end
  if frame.SetPushedTexture then 
    pcall(frame.SetPushedTexture, frame, nil)
  end
  
  -- Clear scripts
  frame:SetScript("OnClick", nil)
  frame:SetScript("OnEnter", nil)
  frame:SetScript("OnLeave", nil)
  frame:SetScript("OnMouseDown", nil)
  frame:SetScript("OnMouseUp", nil)
  
  -- Clear custom properties
  frame.bookKey = nil
  frame.itemKind = nil
  frame.data = nil
end

--- Release all active frames in a pool
--- Useful for clearing a list before rebuilding
--- @param poolName string Pool identifier
--- @return number count Number of frames released
function FramePool:ReleaseAll(poolName)
  local pool = pools[poolName]
  if not pool then
    if BookArchivist.LogWarning then
      BookArchivist:LogWarning("FramePool:ReleaseAll - pool not found: " .. tostring(poolName))
    end
    return 0
  end
  
  -- Collect frames to release (can't modify active table while iterating)
  local toRelease = {}
  for frame in pairs(pool.active) do
    table.insert(toRelease, frame)
  end
  
  -- Release each frame
  for _, frame in ipairs(toRelease) do
    self:Release(frame)
  end
  
  return #toRelease
end

--- Get pool statistics
--- @param poolName string Pool identifier
--- @return table|nil stats { available, active, total, totalCreated, reuseRatio }
function FramePool:GetStats(poolName)
  local pool = pools[poolName]
  if not pool then
    return nil
  end
  
  local activeCount = 0
  for _ in pairs(pool.active) do
    activeCount = activeCount + 1
  end
  
  local availableCount = #pool.available
  local totalFrames = availableCount + activeCount
  local reuseRatio = 0
  
  if pool.totalCreated > 0 then
    -- Ratio of reused frames vs total frames created
    -- Higher is better (means we're reusing more)
    reuseRatio = (pool.totalCreated - totalFrames) / pool.totalCreated
  end
  
  return {
    name = pool.name,
    available = availableCount,
    active = activeCount,
    total = totalFrames,
    totalCreated = pool.totalCreated,
    reuseRatio = reuseRatio,
  }
end

--- Get statistics for all pools
--- @return table stats Array of pool statistics
function FramePool:GetAllStats()
  local stats = {}
  for poolName in pairs(pools) do
    local poolStats = self:GetStats(poolName)
    if poolStats then
      table.insert(stats, poolStats)
    end
  end
  
  -- Sort by name
  table.sort(stats, function(a, b)
    return a.name < b.name
  end)
  
  return stats
end

--- Destroy a pool and all its frames
--- WARNING: This cannot be undone - all frames are destroyed
--- @param poolName string Pool identifier
--- @return boolean success
function FramePool:DestroyPool(poolName)
  local pool = pools[poolName]
  if not pool then
    return false
  end
  
  -- Hide and nil all active frames
  for frame in pairs(pool.active) do
    frame:Hide()
    frame:SetParent(nil)
  end
  
  -- Hide and nil all available frames
  for _, frame in ipairs(pool.available) do
    frame:Hide()
    frame:SetParent(nil)
  end
  
  pools[poolName] = nil
  
  if BookArchivist.LogInfo then
    BookArchivist:LogInfo("FramePool destroyed: " .. poolName)
  end
  
  return true
end

--- Check if a pool exists
--- @param poolName string Pool identifier
--- @return boolean exists
function FramePool:PoolExists(poolName)
  return pools[poolName] ~= nil
end

--- Get list of all pool names
--- @return table poolNames Array of pool name strings
function FramePool:GetPoolNames()
  local names = {}
  for poolName in pairs(pools) do
    table.insert(names, poolName)
  end
  table.sort(names)
  return names
end

if BookArchivist.LogInfo then
  BookArchivist:LogInfo("FramePool module loaded")
end
