-- BookArchivist.lua
-- Bootstraps the addon by wiring core, capture, and example modules.

local ADDON_NAME = ...

local Core = BookArchivist.Core
local Capture = BookArchivist.Capture
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

local optionsPanel

local function registerOptionsPanel(panel)
  if not panel then return end
  local settingsAPI
  local addCategoryFn
  if type(_G) == "table" then
    settingsAPI = rawget(_G, "Settings")
    addCategoryFn = rawget(_G, "InterfaceOptions_AddCategory")
  end

  if type(settingsAPI) == "table" then
    local registerAddOnCategory = settingsAPI.RegisterAddOnCategory
    local registerCanvas = settingsAPI.RegisterCanvasLayoutCategory
    local registerVertical = settingsAPI.RegisterVerticalLayoutCategory
    local category
    if type(registerCanvas) == "function" then
      category = registerCanvas(panel, panel.name)
    elseif type(registerVertical) == "function" then
      category = registerVertical(panel, panel.name)
    end
    if category and type(registerAddOnCategory) == "function" then
      category.ID = category.ID or "BOOKARCHIVIST_OPTIONS"
      registerAddOnCategory(category)
    end
  end

  if type(addCategoryFn) == "function" then
    addCategoryFn(panel)
  end
end

local function syncOptionsPanel()
  if not optionsPanel or not optionsPanel.debugCheckbox then
    return
  end
  local enabled = false
  if BookArchivist and type(BookArchivist.IsDebugEnabled) == "function" then
    enabled = BookArchivist:IsDebugEnabled() and true or false
  end
  optionsPanel.debugCheckbox:SetChecked(enabled)
end

local function ensureOptionsPanel()
  if optionsPanel or not globalCreateFrame then
    syncOptionsPanel()
    return
  end

  local parent
  if type(_G) == "table" then
    parent = rawget(_G, "UIParent")
  end
  optionsPanel = createFrameShim("Frame", "BookArchivistOptionsPanel", parent)
  optionsPanel.name = "Book Archivist"

  local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Book Archivist")

  local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  subtitle:SetText("Enable verbose diagnostics to troubleshoot refresh issues.")

  local checkbox = createFrameShim("CheckButton", "BookArchivistDebugCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
  checkbox.Text:SetText("Enable debug logging")
  checkbox.tooltipText = "Shows extra BookArchivist information in chat for troubleshooting."
  checkbox:SetScript("OnClick", function(self)
    if BookArchivist and type(BookArchivist.SetDebugEnabled) == "function" then
      BookArchivist:SetDebugEnabled(self:GetChecked())
    end
  end)

  optionsPanel.debugCheckbox = checkbox
  optionsPanel.refresh = syncOptionsPanel
  syncOptionsPanel()

  registerOptionsPanel(optionsPanel)
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

  ensureOptionsPanel()
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
  syncOptionsPanel()
end
