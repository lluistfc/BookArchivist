---@diagnostic disable: undefined-global
-- BookArchivist_UI_Options.lua
-- Handles configuration panel UI separate from core logic.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local OptionsUI = BookArchivist.UI.Options or {}
BookArchivist.UI.Options = OptionsUI

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local createFrame = BookArchivist.__createFrame or CreateFrame or function()
  local dummy = {}
  function dummy:RegisterEvent() end
  function dummy:SetScript() end
  return dummy
end

local optionsPanel
local optionsCategory

local function ensureSettingsUILoaded()
  -- Do not programmatically load Blizzard_Settings; letting Blizzard
  -- manage loading avoids tainting its secure logout/quit flow.
  return
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

-- No hooks into Blizzard Settings or Game Menu to avoid taint.

function OptionsUI:Sync()
  if not optionsPanel or not optionsPanel.debugCheckbox or not optionsPanel.uiDebugCheckbox then
    return
  end

  -- Refresh static labels with the active locale so language
  -- changes are reflected without requiring a reload.
  optionsPanel.name = t("ADDON_TITLE")
  if optionsPanel.titleText and optionsPanel.titleText.SetText then
	optionsPanel.titleText:SetText(t("OPTIONS_TITLE"))
	end
  if optionsPanel.subtitleText and optionsPanel.subtitleText.SetText then
	optionsPanel.subtitleText:SetText(t("OPTIONS_SUBTITLE_DEBUG"))
	end

  local enabled = false
  if BookArchivist and type(BookArchivist.IsDebugEnabled) == "function" then
    enabled = BookArchivist:IsDebugEnabled() and true or false
  end
  optionsPanel.debugCheckbox:SetChecked(enabled)
  if optionsPanel.debugCheckbox.Text and optionsPanel.debugCheckbox.Text.SetText then
	optionsPanel.debugCheckbox.Text:SetText(t("OPTIONS_DEBUG_LOGGING_LABEL"))
	end
  optionsPanel.debugCheckbox.tooltipText = t("OPTIONS_DEBUG_LOGGING_TOOLTIP")

  local uiDebugEnabled = false
  if BookArchivist and type(BookArchivist.IsUIDebugEnabled) == "function" then
    uiDebugEnabled = BookArchivist:IsUIDebugEnabled() and true or false
  elseif BookArchivistDB and BookArchivistDB.options then
    uiDebugEnabled = BookArchivistDB.options.uiDebug and true or false
  end
  optionsPanel.uiDebugCheckbox:SetChecked(uiDebugEnabled)
  if optionsPanel.uiDebugCheckbox.Text and optionsPanel.uiDebugCheckbox.Text.SetText then
	optionsPanel.uiDebugCheckbox.Text:SetText(t("OPTIONS_UI_DEBUG_LABEL"))
	end
  optionsPanel.uiDebugCheckbox.tooltipText = t("OPTIONS_UI_DEBUG_TOOLTIP")

  local tooltipEnabled = true
  if BookArchivist and type(BookArchivist.IsTooltipEnabled) == "function" then
    tooltipEnabled = BookArchivist:IsTooltipEnabled() and true or false
  end
  if optionsPanel.tooltipCheckbox then
    optionsPanel.tooltipCheckbox:SetChecked(tooltipEnabled)
    if optionsPanel.tooltipCheckbox.Text and optionsPanel.tooltipCheckbox.Text.SetText then
      optionsPanel.tooltipCheckbox.Text:SetText(t("OPTIONS_TOOLTIP_LABEL"))
    end
    optionsPanel.tooltipCheckbox.tooltipText = t("OPTIONS_TOOLTIP_TOOLTIP")
  end

  local resumeEnabled = true
  if BookArchivist and type(BookArchivist.IsResumeLastPageEnabled) == "function" then
	  resumeEnabled = BookArchivist:IsResumeLastPageEnabled() and true or false
  end
  if optionsPanel.resumePageCheckbox then
	  optionsPanel.resumePageCheckbox:SetChecked(resumeEnabled)
	  if optionsPanel.resumePageCheckbox.Text and optionsPanel.resumePageCheckbox.Text.SetText then
		  optionsPanel.resumePageCheckbox.Text:SetText(t("OPTIONS_RESUME_LAST_PAGE_LABEL"))
	  end
	  optionsPanel.resumePageCheckbox.tooltipText = t("OPTIONS_RESUME_LAST_PAGE_TOOLTIP")
  end

  if optionsPanel.langLabel and optionsPanel.langLabel.SetText then
	optionsPanel.langLabel:SetText(t("LANGUAGE_LABEL"))
	end

  if optionsPanel.languageDropdown and UIDropDownMenu_SetSelectedValue and BookArchivist and BookArchivist.GetLanguage then
    local current = BookArchivist:GetLanguage()
    UIDropDownMenu_SetSelectedValue(optionsPanel.languageDropdown, current)
    local L2 = BookArchivist and BookArchivist.L or L
    local labelKey
    if current == "esES" or current == "esMX" then
        labelKey = "LANGUAGE_NAME_SPANISH"
      elseif current == "caES" then
        labelKey = "LANGUAGE_NAME_CATALAN"
      elseif current == "deDE" then
        labelKey = "LANGUAGE_NAME_GERMAN"
      elseif current == "frFR" then
        labelKey = "LANGUAGE_NAME_FRENCH"
      elseif current == "itIT" then
        labelKey = "LANGUAGE_NAME_ITALIAN"
      elseif current == "ptBR" or current == "ptPT" then
        labelKey = "LANGUAGE_NAME_PORTUGUESE"
      else
        labelKey = "LANGUAGE_NAME_ENGLISH"
      end
    local label = (L2 and L2[labelKey]) or labelKey or "English"
    UIDropDownMenu_SetText(optionsPanel.languageDropdown, label)
  end
end

function OptionsUI:Ensure()
  if optionsPanel or not createFrame then
    self:Sync()
    return optionsPanel
  end

  ensureSettingsUILoaded()
  local parent
  if type(_G) == "table" then
    parent = rawget(_G, "UIParent")
  end
  optionsPanel = createFrame("Frame", "BookArchivistOptionsPanel", parent)
	optionsPanel.name = t("ADDON_TITLE")

  local logo = optionsPanel:CreateTexture(nil, "ARTWORK")
  logo:SetTexture("Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png")
  logo:SetSize(64, 64)
  logo:SetPoint("TOP", optionsPanel, "TOP", 0, -32)

  local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", logo, "BOTTOM", 0, -8)
	title:SetText(t("OPTIONS_TITLE"))
  optionsPanel.titleText = title

  local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -220)
	subtitle:SetText(t("OPTIONS_SUBTITLE_DEBUG"))
  optionsPanel.subtitleText = subtitle

  local checkbox = createFrame("CheckButton", "BookArchivistDebugCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
  checkbox.Text:SetText(t("OPTIONS_DEBUG_LOGGING_LABEL"))
  checkbox.tooltipText = t("OPTIONS_DEBUG_LOGGING_TOOLTIP")
  checkbox:SetScript("OnClick", function(self)
    if BookArchivist and type(BookArchivist.SetDebugEnabled) == "function" then
      BookArchivist:SetDebugEnabled(self:GetChecked())
    end
  end)

  optionsPanel.debugCheckbox = checkbox

  local uiDebugCheckbox = createFrame("CheckButton", "BookArchivistUIDebugCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  uiDebugCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -8)
  uiDebugCheckbox.Text:SetText(t("OPTIONS_UI_DEBUG_LABEL"))
  uiDebugCheckbox.tooltipText = t("OPTIONS_UI_DEBUG_TOOLTIP")
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

  local tooltipCheckbox = createFrame("CheckButton", "BookArchivistTooltipCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  tooltipCheckbox:SetPoint("TOPLEFT", uiDebugCheckbox, "BOTTOMLEFT", 0, -8)
  tooltipCheckbox.Text:SetText(t("OPTIONS_TOOLTIP_LABEL"))
  tooltipCheckbox.tooltipText = t("OPTIONS_TOOLTIP_TOOLTIP")
  tooltipCheckbox:SetScript("OnClick", function(self)
    local state = self:GetChecked()
    if BookArchivist and type(BookArchivist.SetTooltipEnabled) == "function" then
      BookArchivist:SetTooltipEnabled(state)
    end
  end)

  optionsPanel.tooltipCheckbox = tooltipCheckbox

  local resumePageCheckbox = createFrame("CheckButton", "BookArchivistResumePageCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
  resumePageCheckbox:SetPoint("TOPLEFT", tooltipCheckbox, "BOTTOMLEFT", 0, -8)
  resumePageCheckbox.Text:SetText(t("OPTIONS_RESUME_LAST_PAGE_LABEL"))
  resumePageCheckbox.tooltipText = t("OPTIONS_RESUME_LAST_PAGE_TOOLTIP")
  resumePageCheckbox:SetScript("OnClick", function(self)
	  local state = self:GetChecked()
	  if BookArchivist and type(BookArchivist.SetResumeLastPageEnabled) == "function" then
		  BookArchivist:SetResumeLastPageEnabled(state)
	  end
  end)

  optionsPanel.resumePageCheckbox = resumePageCheckbox

  local langLabel = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  langLabel:SetPoint("TOPLEFT", resumePageCheckbox, "BOTTOMLEFT", 0, -16)
	langLabel:SetText(t("LANGUAGE_LABEL"))
  optionsPanel.langLabel = langLabel

  local dropdown = CreateFrame and CreateFrame("Frame", "BookArchivistLanguageDropdown", optionsPanel, "UIDropDownMenuTemplate")
  if dropdown then
    dropdown:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropdown, 160)

    UIDropDownMenu_Initialize(dropdown, function(frame, level)
      local current = "enUS"
      if BookArchivist and BookArchivist.GetLanguage then
        current = BookArchivist:GetLanguage()
      end

      local items = {
      { value = "enUS", labelKey = "LANGUAGE_NAME_ENGLISH" },
      { value = "esES", labelKey = "LANGUAGE_NAME_SPANISH" },
      { value = "caES", labelKey = "LANGUAGE_NAME_CATALAN" },
      { value = "deDE", labelKey = "LANGUAGE_NAME_GERMAN" },
      { value = "frFR", labelKey = "LANGUAGE_NAME_FRENCH" },
      { value = "itIT", labelKey = "LANGUAGE_NAME_ITALIAN" },
      { value = "ptBR", labelKey = "LANGUAGE_NAME_PORTUGUESE" },
  }

      for _, opt in ipairs(items) do
        local info = UIDropDownMenu_CreateInfo()
	        info.text = t(opt.labelKey)
        info.value = opt.value
        info.func = function()
          if BookArchivist and BookArchivist.SetLanguage then
            BookArchivist:SetLanguage(opt.value)
          end
        end
        info.checked = (opt.value == current)
        UIDropDownMenu_AddButton(info, level)
      end
    end)

    optionsPanel.languageDropdown = dropdown
  end
  optionsPanel.refresh = function()
    OptionsUI:Sync()
  end
  self:Sync()

  registerOptionsPanel(optionsPanel)
  return optionsPanel
end

function OptionsUI:Open()
  ensureSettingsUILoaded()
  local panel = self:Ensure()
  if not panel then
    return
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
end

function OptionsUI:OnAddonLoaded(name)
  if name ~= ADDON_NAME then
    return
  end
  self:Ensure()
end
