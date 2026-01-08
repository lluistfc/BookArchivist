---@diagnostic disable: undefined-global
-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
local Capture = BookArchivist.Capture
local Location = BookArchivist.Location
local MinimapModule = BookArchivist.Minimap
local TooltipModule = BookArchivist.Tooltip
local ChatLinks = BookArchivist.ChatLinks

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
  
  -- Initialize debug logging state from DB
  if type(BookArchivist.EnableDebugLogging) == "function" and Core and Core.IsDebugEnabled then
    local debugState = Core:IsDebugEnabled()
    BookArchivist.EnableDebugLogging(debugState, true)
  end
  
  local optionsUI = getOptionsUI()
  if optionsUI and optionsUI.OnAddonLoaded then
    optionsUI:OnAddonLoaded(name)
  end
  if MinimapModule and MinimapModule.Initialize then
    MinimapModule:Initialize()
  end
  if TooltipModule and TooltipModule.Initialize then
    TooltipModule:Initialize()
  end
  if ChatLinks and ChatLinks.Init then
    ChatLinks:Init()
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

function BookArchivist:ExportBook(bookId)
	if Core and Core.ExportBookToString then
		return Core:ExportBookToString(bookId)
	end
	return nil, "export unavailable"
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
  -- Note: EnableDebugLogging is called by the UI callback to apply runtime state
  syncOptionsUI()
end

function BookArchivist:IsUIDebugEnabled()
  if Core and Core.IsUIDebugEnabled then
    return Core:IsUIDebugEnabled()
  end
  local db = self:GetDB() or {}
  local opts = db.options or {}
  return opts.uiDebug and true or false
end

function BookArchivist:IsTooltipEnabled()
  if Core and Core.IsTooltipEnabled then
    return Core:IsTooltipEnabled()
  end
  local db = self:GetDB() or {}
  local opts = db.options or {}
  if opts.tooltip == nil then
    return true
  end
  return opts.tooltip and true or false
end

function BookArchivist:SetTooltipEnabled(state)
  if Core and Core.SetTooltipEnabled then
    Core:SetTooltipEnabled(state)
  else
    local db = self:GetDB() or {}
    db.options = db.options or {}
    db.options.tooltip = state and true or false
  end
end

function BookArchivist:SetUIDebugEnabled(state)
  if Core and Core.SetUIDebugEnabled then
    Core:SetUIDebugEnabled(state)
  else
    local db = self:GetDB() or {}
    db.options = db.options or {}
    db.options.uiDebug = state and true or false
  end

  local internal = self.UI and self.UI.Internal
  if internal and internal.setGridOverlayVisible then
    internal.setGridOverlayVisible(state and true or false)
  end

  syncOptionsUI()
end

function BookArchivist:IsResumeLastPageEnabled()
  if Core and Core.IsResumeLastPageEnabled then
    return Core:IsResumeLastPageEnabled()
  end
  return true
end

function BookArchivist:SetResumeLastPageEnabled(state)
  if Core and Core.SetResumeLastPageEnabled then
    Core:SetResumeLastPageEnabled(state)
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

function BookArchivist:GetListPageSize()
  if Core and Core.GetListPageSize then
    return Core:GetListPageSize()
  end
  return 25
end

function BookArchivist:SetListPageSize(size)
  if Core and Core.SetListPageSize then
    Core:SetListPageSize(size)
  end
end

function BookArchivist:GetListSortMode()
  if Core and Core.GetSortMode then
    return Core:GetSortMode()
  end
	return "lastSeen"
end

function BookArchivist:SetListSortMode(mode)
  if Core and Core.SetSortMode then
    Core:SetSortMode(mode)
  end
end

function BookArchivist:ExportLibrary()
  if Core and Core.ExportToString then
    return Core:ExportToString()
  end
  return nil, "export unavailable"
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

function BookArchivist:IsVirtualCategoriesEnabled()
  if Core and Core.IsVirtualCategoriesEnabled then
    return Core:IsVirtualCategoriesEnabled()
  end
  return true
end

function BookArchivist:GetLastCategoryId()
  if Core and Core.GetLastCategoryId then
    return Core:GetLastCategoryId()
  end
  return "__all__"
end

function BookArchivist:SetLastCategoryId(categoryId)
  if Core and Core.SetLastCategoryId then
    Core:SetLastCategoryId(categoryId)
  end
end

function BookArchivist:GetLastBookId()
  if Core and Core.GetLastBookId then
    return Core:GetLastBookId()
  end
  return nil
end

function BookArchivist:SetLastBookId(bookId)
  if Core and Core.SetLastBookId then
    Core:SetLastBookId(bookId)
  end
end

function BookArchivist:GetLanguage()
  if Core and Core.GetLanguage then
    return Core:GetLanguage()
  end
  return "enUS"
end

function BookArchivist:SetLanguage(lang)
  if Core and Core.SetLanguage then
    Core:SetLanguage(lang)
  end
  local internal = self.UI and self.UI.Internal
  if internal and internal.rebuildUIForLanguageChange then
    internal.rebuildUIForLanguageChange()
  elseif type(self.RefreshUI) == "function" then
    self:RefreshUI()
  end
  syncOptionsUI()
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
