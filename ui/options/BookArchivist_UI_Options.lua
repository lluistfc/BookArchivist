---@diagnostic disable: undefined-global
-- BookArchivist_UI_Options.lua
-- Handles configuration panel UI separate from core logic.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local OptionsUI = BookArchivist.UI.Options or {}
BookArchivist.UI.Options = OptionsUI

local createFrame = BookArchivist.__createFrame or CreateFrame or function()
  local dummy = {}
  function dummy:RegisterEvent() end
  function dummy:SetScript() end
  return dummy
end

local optionsPanel
local optionsCategory
local settingsPanelHooked = false
local interfaceOptionsHooked = false
local gameMenuHooked = false
local shouldHideGameMenuOnClose = false

local function resetGameMenuFlagSoon()
  if type(C_Timer) ~= "table" or type(C_Timer.After) ~= "function" then
    return
  end
  C_Timer.After(1.0, function()
    shouldHideGameMenuOnClose = false
  end)
end

local function ensureSettingsUILoaded()
  if type(C_AddOns) ~= "table" then
    return
  end
  local isLoaded = C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_Settings")
  if not isLoaded and C_AddOns.LoadAddOn then
    pcall(C_AddOns.LoadAddOn, "Blizzard_Settings")
  end
end

local function hideGameMenuFrame()
  if type(_G) ~= "table" then
    return
  end
  local gameMenu = rawget(_G, "GameMenuFrame")
  if not gameMenu then
    return
  end
  local hideUIPanel = rawget(_G, "HideUIPanel")
  if type(hideUIPanel) == "function" then
    hideUIPanel(gameMenu)
  elseif gameMenu.Hide then
    gameMenu:Hide()
  end
end

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
      optionsCategory = category
    end
  end

  if type(addCategoryFn) == "function" then
    addCategoryFn(panel)
  end
end

local function handleOptionsPanelClosed()
  if not shouldHideGameMenuOnClose then
    return
  end
  hideGameMenuFrame()
  resetGameMenuFlagSoon()
end

local function ensureOptionsCloseHooks()
  if type(_G) ~= "table" then
    return
  end

  local settingsFrame = rawget(_G, "SettingsPanel")
  if settingsFrame and settingsFrame.HookScript and not settingsPanelHooked then
    settingsFrame:HookScript("OnHide", handleOptionsPanelClosed)
    settingsPanelHooked = true
  end

  local interfaceFrame = rawget(_G, "InterfaceOptionsFrame")
  if interfaceFrame and interfaceFrame.HookScript and not interfaceOptionsHooked then
    interfaceFrame:HookScript("OnHide", handleOptionsPanelClosed)
    interfaceOptionsHooked = true
  end
end

local function ensureGameMenuHook()
  if type(_G) ~= "table" or gameMenuHooked then
    return
  end
  local gameMenu = rawget(_G, "GameMenuFrame")
  if not gameMenu or not gameMenu.HookScript then
    return
  end
  gameMenu:HookScript("OnShow", function()
    if not shouldHideGameMenuOnClose then
      return
    end
    shouldHideGameMenuOnClose = false
    hideGameMenuFrame()
    resetGameMenuFlagSoon()
  end)
  gameMenuHooked = true
end

function OptionsUI:Sync()
  if not optionsPanel or not optionsPanel.debugCheckbox or not optionsPanel.uiDebugCheckbox then
    return
  end
  local enabled = false
  if BookArchivist and type(BookArchivist.IsDebugEnabled) == "function" then
    enabled = BookArchivist:IsDebugEnabled() and true or false
  end
  optionsPanel.debugCheckbox:SetChecked(enabled)

  local uiDebugEnabled = false
  if BookArchivist and type(BookArchivist.IsUIDebugEnabled) == "function" then
    uiDebugEnabled = BookArchivist:IsUIDebugEnabled() and true or false
  elseif BookArchivistDB and BookArchivistDB.options then
    uiDebugEnabled = BookArchivistDB.options.uiDebug and true or false
  end
  optionsPanel.uiDebugCheckbox:SetChecked(uiDebugEnabled)
end

function OptionsUI:Ensure()
  if optionsPanel or not createFrame then
    self:Sync()
    ensureOptionsCloseHooks()
    ensureGameMenuHook()
    return optionsPanel
  end

  ensureSettingsUILoaded()
  local parent
  if type(_G) == "table" then
    parent = rawget(_G, "UIParent")
  end
  optionsPanel = createFrame("Frame", "BookArchivistOptionsPanel", parent)
  optionsPanel.name = "Book Archivist"

  local logo = optionsPanel:CreateTexture(nil, "ARTWORK")
  logo:SetTexture("Interface\\AddOns\\BookArchivist\\BookArchivist_logo.png")
  logo:SetSize(128, 128)
  logo:SetPoint("TOP", optionsPanel, "TOP", 0, -32)

  local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", logo, "BOTTOM", 0, -8)
  title:SetText("Book Archivist")

  local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -220)
  subtitle:SetText("Enable verbose diagnostics to troubleshoot refresh issues.")

  local checkbox = createFrame("CheckButton", "BookArchivistDebugCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
  checkbox.Text:SetText("Enable debug logging")
  checkbox.tooltipText = "Shows extra BookArchivist information in chat for troubleshooting."
  checkbox:SetScript("OnClick", function(self)
    if BookArchivist and type(BookArchivist.SetDebugEnabled) == "function" then
      BookArchivist:SetDebugEnabled(self:GetChecked())
    end
  end)

  optionsPanel.debugCheckbox = checkbox

  local uiDebugCheckbox = createFrame("CheckButton", "BookArchivistUIDebugCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  uiDebugCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -8)
  uiDebugCheckbox.Text:SetText("Show UI debug grid")
  uiDebugCheckbox.tooltipText = "Highlights layout bounds for troubleshooting. Same as /ba uidebug on/off."
  uiDebugCheckbox:SetScript("OnClick", function(self)
    local state = self:GetChecked()
    if BookArchivist and type(BookArchivist.SetUIDebugEnabled) == "function" then
      BookArchivist:SetUIDebugEnabled(state)
    else
      BookArchivistDB = BookArchivistDB or {}
      BookArchivistDB.options = BookArchivistDB.options or {}
      BookArchivistDB.options.uiDebug = state and true or false
    end
    if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.setGridOverlayVisible then
      BookArchivist.UI.Internal.setGridOverlayVisible(state and true or false)
    end
  end)

  optionsPanel.uiDebugCheckbox = uiDebugCheckbox
  optionsPanel.refresh = function()
    OptionsUI:Sync()
  end
  self:Sync()

  registerOptionsPanel(optionsPanel)
  ensureOptionsCloseHooks()
  ensureGameMenuHook()
  return optionsPanel
end

function OptionsUI:Open()
  ensureSettingsUILoaded()
  local panel = self:Ensure()
  if not panel then
    return
  end

  local gameMenu
  local wasGameMenuVisible = false
  if type(_G) == "table" then
    gameMenu = rawget(_G, "GameMenuFrame")
    wasGameMenuVisible = gameMenu and gameMenu:IsShown() and true or false
  end

  local openedPanel = false
  local settingsAPI = type(_G) == "table" and rawget(_G, "Settings") or nil
  if settingsAPI and type(settingsAPI.OpenToCategory) == "function" and optionsCategory then
    settingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
    settingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
    openedPanel = true
  end

  if not openedPanel then
    local openLegacy = type(_G) == "table" and rawget(_G, "InterfaceOptionsFrame_OpenToCategory") or nil
    if type(openLegacy) == "function" then
      openLegacy(panel)
      openLegacy(panel)
      openedPanel = true
    end
  end

  if openedPanel then
    shouldHideGameMenuOnClose = not wasGameMenuVisible
    if shouldHideGameMenuOnClose then
      hideGameMenuFrame()
    end
    ensureOptionsCloseHooks()
  end
end

function OptionsUI:OnAddonLoaded(name)
  if name ~= ADDON_NAME then
    return
  end
  self:Ensure()
end
