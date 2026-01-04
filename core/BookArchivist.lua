---@diagnostic disable: undefined-global
-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
local Capture = BookArchivist.Capture
local Location = BookArchivist.Location
local MinimapModule = BookArchivist.Minimap

local function callInternalDebug(method, ...)
  local ui = BookArchivist.UI
  local internal = ui and ui.Internal
  if not internal then
    return nil
  end
  local fn = internal[method]
  if type(fn) == "function" then
    return fn(...)
  end
  return nil
end

function BookArchivist:DebugPrint(...)
  return callInternalDebug("debugPrint", ...)
end

function BookArchivist:DebugMessage(...)
  return callInternalDebug("debugMessage", ...)
end

function BookArchivist:LogError(...)
  return callInternalDebug("logError", ...)
end

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

BookArchivist.__createFrame = createFrameShim

local function getOptionsUI()
  if not BookArchivist.UI then
    return nil
  end
  return BookArchivist.UI.Options
end

local function syncOptionsUI()
  local optionsUI = getOptionsUI()
  if optionsUI and optionsUI.Sync then
    optionsUI:Sync()
  end
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
  local optionsUI = getOptionsUI()
  if optionsUI and optionsUI.OnAddonLoaded then
    optionsUI:OnAddonLoaded(name)
  end
  if MinimapModule and MinimapModule.Initialize then
    MinimapModule:Initialize()
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
  if type(self.RefreshUI) == "function" then
    self:RefreshUI()
  end
end

function BookArchivist:IsDebugEnabled()
  if Core and Core.IsDebugEnabled then
    return Core:IsDebugEnabled()
  end
  return false
end

function BookArchivist:SetDebugEnabled(state)
  if Core and Core.SetDebugEnabled then
    Core:SetDebugEnabled(state)
  end
  if type(self.EnableDebugLogging) == "function" then
    self.EnableDebugLogging(state, true)
  end
  syncOptionsUI()
end

function BookArchivist:GetListWidth()
  if Core and Core.GetListWidth then
    return Core:GetListWidth()
  end
  return 360
end

function BookArchivist:SetListWidth(width)
  if Core and Core.SetListWidth then
    Core:SetListWidth(width)
  end
end

function BookArchivist:GetListSortMode()
  if Core and Core.GetSortMode then
    return Core:GetSortMode()
  end
  return "recent"
end

function BookArchivist:SetListSortMode(mode)
  if Core and Core.SetSortMode then
    Core:SetSortMode(mode)
  end
end

function BookArchivist:GetListFilters()
  if Core and Core.GetListFilters then
    return Core:GetListFilters()
  end
  return {}
end

function BookArchivist:SetListFilter(filterKey, state)
  if Core and Core.SetListFilter then
    Core:SetListFilter(filterKey, state)
  end
end

function BookArchivist:OpenOptionsPanel()
  local optionsUI = getOptionsUI()
  if optionsUI and optionsUI.Open then
    optionsUI:Open()
  end
end

function BookArchivist_ToggleFromCompartment()
  if BookArchivist and type(BookArchivist.ToggleUI) == "function" then
    BookArchivist:ToggleUI()
  end
end
