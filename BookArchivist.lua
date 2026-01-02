-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

local Core = BookArchivist.Core
local Capture = BookArchivist.Capture
local Examples = BookArchivist.Examples
local Location = BookArchivist.Location

local globalCreateFrame = type(_G) == "table" and rawget(_G, "CreateFrame") or nil
local function createFrameShim(...)
  if globalCreateFrame then
    return globalCreateFrame(...)
  end

  local dummy = {}
  function dummy:RegisterEvent(...) end
  function dummy:SetScript(...) end
  return dummy
end

local eventFrame = createFrameShim("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("ITEM_TEXT_BEGIN")
eventFrame:RegisterEvent("ITEM_TEXT_READY")
eventFrame:RegisterEvent("ITEM_TEXT_CLOSED")
-- Simplified: treat all captures as item text books only

local function handleAddonLoaded(name)
  if name ~= ADDON_NAME then
    return
  end

  if Core and Core.EnsureDB then
    Core:EnsureDB()
  end

  if Examples and Examples.Seed then
    Examples:Seed()
  end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    handleAddonLoaded(...)
    return
  end

  if event == "ITEM_TEXT_BEGIN" then
    if Capture and Capture.OnBegin then
      Capture:OnBegin()
    end
  elseif event == "ITEM_TEXT_READY" then
    if Capture and Capture.OnReady then
      Capture:OnReady()
    end
  elseif event == "ITEM_TEXT_CLOSED" then
    if Capture and Capture.OnClosed then
      Capture:OnClosed()
    end
  end
end)

BookArchivist = BookArchivist or {}

function BookArchivist:GetDB()
  if Core and Core.GetDB then
    return Core:GetDB()
  end
  return {}
end

function BookArchivist:Delete(key)
  if Core and Core.Delete then
    Core:Delete(key)
  end
end
