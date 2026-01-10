---@diagnostic disable: undefined-global
-- BookArchivist_UI_Options.lua
-- Retail (11.x) Settings UI integration.
--
-- IMPORTANT DESIGN CHOICE
-- The Blizzard Settings panel is not a general-purpose scroll container.
-- Mixing custom scroll frames + third-party widget libraries (AceGUI) inside
-- a Settings category can break hit-testing after a scroll (symptoms: cannot
-- click controls, empty panel when returning).
--
-- This file registers only native Settings controls (checkboxes + dropdown).
-- Import/Export + Debug log live in a separate movable frame opened by a button.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local OptionsUI = BookArchivist.UI.Options or {}
BookArchivist.UI.Options = OptionsUI

local function L(key)
  local t = BookArchivist and BookArchivist.L
  return (t and t[key]) or key
end

-- ----------------------------
-- Saved vars helpers
-- ----------------------------

local function EnsureDB()
  BookArchivistDB = BookArchivistDB or {}
  BookArchivistDB.options = BookArchivistDB.options or {}
  return BookArchivistDB
end

local function GetDBOption(key, defaultValue)
  local db = EnsureDB()
  local v = db.options[key]
  if v == nil then
    db.options[key] = defaultValue
    return defaultValue
  end
  return v
end

local function SetDBOption(key, value)
  local db = EnsureDB()
  db.options[key] = value
end

-- ----------------------------
-- Settings compatibility helpers
-- ----------------------------

local function ensureSettingsUILoaded()
  -- The global Settings table exists very early, but most of the API lives in
  -- Blizzard_Settings(_Shared) which is load-on-demand.
  if type(Settings) ~= "table" then
    return false
  end

  if type(Settings.RegisterVerticalLayoutCategory) == "function" and (type(Settings.CreateCheckBox) == "function" or type(Settings.CreateCheckbox) == "function") then
    return true
  end

  -- Load Blizzard_Settings to populate the API.
  local ok = pcall(function()
    if type(C_AddOns) == "table" and type(C_AddOns.LoadAddOn) == "function" then
      C_AddOns.LoadAddOn("Blizzard_Settings")
      C_AddOns.LoadAddOn("Blizzard_Settings_Shared")
    elseif type(LoadAddOn) == "function" then
      LoadAddOn("Blizzard_Settings")
      LoadAddOn("Blizzard_Settings_Shared")
    end
  end)

  if not ok then
    return false
  end

  return type(Settings.RegisterVerticalLayoutCategory) == "function" and (type(Settings.CreateCheckBox) == "function" or type(Settings.CreateCheckbox) == "function")
end

-- ----------------------------
-- Native Settings registration
-- ----------------------------

local optionsCategory
local registered = false

-- Store setting references for language updates
local settingObjects = {}

local function RegisterNativeSettings()
  if registered then return end

  local Settings = _G.Settings
  if not Settings or not Settings.RegisterVerticalLayoutCategory then
    return
  end

  EnsureDB()

  local categoryName = L("ADDON_TITLE")
  local category, layout = Settings.RegisterVerticalLayoutCategory(categoryName)
  optionsCategory = category
  
  -- Debug checkbox removed - now in dev/BookArchivist_DevOptions.lua
  -- Only loaded when BookArchivist_Dev.toc is present

  -- ----------------------
  -- Tooltip checkbox
  -- ----------------------
  do
    local variable = "tooltip"
    local variableKey = variable
    local variableTbl = BookArchivistDB.options
    local defaultValue = true
    local name = L("OPTIONS_TOOLTIP_LABEL")

    local setting = Settings.RegisterAddOnSetting(
      category,
      variable,
      variableKey,
      variableTbl,
      "boolean",
      name,
      defaultValue
    )
    
    -- Override SetValue to ensure it persists to the database
    if setting then
      local originalSetValue = setting.SetValue
      setting.SetValue = function(self, value)
        -- Ensure database exists
        BookArchivistDB = BookArchivistDB or {}
        BookArchivistDB.options = BookArchivistDB.options or {}
        
        -- Convert to boolean and persist
        local boolValue = value and true or false
        BookArchivistDB.options.tooltip = boolValue
        
        -- Call original if it exists
        if originalSetValue then
          originalSetValue(self, boolValue)
        end
        
        -- Apply runtime state
        if BookArchivist and type(BookArchivist.SetTooltipEnabled) == "function" then
          BookArchivist:SetTooltipEnabled(boolValue)
        end
      end
    end

    Settings.CreateCheckbox(
      category,
      setting,
      L("OPTIONS_TOOLTIP_TOOLTIP")
    )

    Settings.SetOnValueChangedCallback(variableKey, function(_, value)
      -- Blizzard already saved to BookArchivistDB.options.tooltip
      -- Just apply runtime state
      if BookArchivist and type(BookArchivist.SetTooltipEnabled) == "function" then
        BookArchivist:SetTooltipEnabled(value and true or false)
      end
    end)
  end

  -- ----------------------
  -- Resume last page
  -- ----------------------
  do
    local variable = "resumeLastPage"
    local variableKey = variable
    -- Store in options.ui.resumeLastPage to match Core implementation
    BookArchivistDB.options = BookArchivistDB.options or {}
    BookArchivistDB.options.ui = BookArchivistDB.options.ui or {}
    local variableTbl = BookArchivistDB.options.ui
    local defaultValue = true
    local name = L("OPTIONS_RESUME_LAST_PAGE_LABEL")

    local setting = Settings.RegisterAddOnSetting(
      category,
      variable,
      variableKey,
      variableTbl,
      "boolean",
      name,
      defaultValue
    )
    
    -- Store reference for language updates
    settingObjects.resumeLastPage = setting
    
    -- Override SetValue to ensure it persists to the database
    if setting then
      local originalSetValue = setting.SetValue
      setting.SetValue = function(self, value)
        -- Ensure database exists
        BookArchivistDB = BookArchivistDB or {}
        BookArchivistDB.options = BookArchivistDB.options or {}
        BookArchivistDB.options.ui = BookArchivistDB.options.ui or {}
        
        -- Convert to boolean and persist
        local boolValue = value and true or false
        BookArchivistDB.options.ui.resumeLastPage = boolValue
        
        -- Call original if it exists
        if originalSetValue then
          originalSetValue(self, boolValue)
        end
        
        -- Apply runtime state
        if BookArchivist and type(BookArchivist.SetResumeLastPageEnabled) == "function" then
          BookArchivist:SetResumeLastPageEnabled(boolValue)
        end
      end
    end

    Settings.CreateCheckbox(
      category,
      setting,
      L("OPTIONS_RESUME_LAST_PAGE_TOOLTIP")
    )

    Settings.SetOnValueChangedCallback(variableKey, function(_, value)
      -- Blizzard already saved to BookArchivistDB.options.resumeLastPage
      -- Just apply runtime state
      if BookArchivist and type(BookArchivist.SetResumeLastPageEnabled) == "function" then
        BookArchivist:SetResumeLastPageEnabled(value and true or false)
      end
    end)
  end

  -- ----------------------
  -- Language dropdown
  -- ----------------------
  do
    local variable = "language"
    local variableKey = variable
    local variableTbl = BookArchivistDB.options
    local defaultValue = (type(GetLocale) == "function" and GetLocale()) or "enUS"
    local name = L("LANGUAGE_LABEL")

    local setting = Settings.RegisterAddOnSetting(
      category,
      variable,
      variableKey,
      variableTbl,
      "string",
      name,
      defaultValue
    )

    -- Store reference for language updates
    settingObjects.language = setting

    -- Override SetValue to ensure it persists and triggers language change
    if setting then
      local originalSetValue = setting.SetValue
      setting.SetValue = function(self, value)
        -- Ensure database exists
        BookArchivistDB = BookArchivistDB or {}
        BookArchivistDB.options = BookArchivistDB.options or {}
        
        -- Persist to database
        BookArchivistDB.options.language = value
        
        -- Call original if it exists
        if originalSetValue then
          originalSetValue(self, value)
        end
        
        -- Apply runtime state (locale switching)
        if BookArchivist and type(BookArchivist.SetLanguage) == "function" then
          BookArchivist:SetLanguage(value)
        end
      end
    end

    local function GetLanguageOptions()
      local container = Settings.CreateControlTextContainer()
      container:Add("enUS", L("LANGUAGE_NAME_ENGLISH"))
      container:Add("esES", L("LANGUAGE_NAME_SPANISH"))
      container:Add("caES", L("LANGUAGE_NAME_CATALAN"))
      container:Add("deDE", L("LANGUAGE_NAME_GERMAN"))
      container:Add("frFR", L("LANGUAGE_NAME_FRENCH"))
      container:Add("itIT", L("LANGUAGE_NAME_ITALIAN"))
      container:Add("ptBR", L("LANGUAGE_NAME_PORTUGUESE"))
      return container:GetData()
    end

    Settings.CreateDropdown(
      category,
      setting,
      GetLanguageOptions,
      L("LANGUAGE_LABEL")
    )
  end

  -- Add custom button to open tools window
  if layout and layout.AddInitializer then
    local initializer = Settings.CreateElementInitializer("BookArchivistToolsButtonTemplate", {})
    layout:AddInitializer(initializer)
  end

  Settings.RegisterAddOnCategory(category)
  registered = true
  
  if SettingsPanel and SettingsPanel.Container.SettingsList.Header.DefaultsButton then
    SettingsPanel.Container.SettingsList.Header.DefaultsButton:Hide()
end
end


-- ----------------------------
-- Separate popup window for multiline text (import/debug)
-- ----------------------------

local toolsFrame

local function CreateToolsFrame()
  if toolsFrame then 
    return toolsFrame 
  end

  local f = CreateFrame("Frame", "BookArchivistToolsFrame", UIParent, "BasicFrameTemplateWithInset")
  f:SetSize(700, 520)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(100)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:Hide()

  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.title:SetPoint("LEFT", f.TitleBg, "LEFT", 8, 0)
  f.title:SetText(L("ADDON_TITLE") .. " - " .. (L("OPTIONS_EXPORT_IMPORT_LABEL") ~= "OPTIONS_EXPORT_IMPORT_LABEL" and L("OPTIONS_EXPORT_IMPORT_LABEL") or "Tools"))

  -- Import label
  local importLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  importLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -36)
  importLabel:SetText(L("OPTIONS_IMPORT_LABEL"))

  -- Import help text
  local importHelp = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  importHelp:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -6)
  importHelp:SetPoint("RIGHT", f, "RIGHT", -16, 0)
  importHelp:SetJustifyH("LEFT")
  importHelp:SetText(L("OPTIONS_IMPORT_HELP"))
  importHelp:SetTextColor(0.8, 0.8, 0.8, 1)

  -- Import performance tip
  local importPerfTip = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  importPerfTip:SetPoint("TOPLEFT", importHelp, "BOTTOMLEFT", 0, -8)
  importPerfTip:SetPoint("RIGHT", f, "RIGHT", -16, 0)
  importPerfTip:SetJustifyH("LEFT")
  importPerfTip:SetText(L("OPTIONS_IMPORT_PERF_TIP"))
  importPerfTip:SetTextColor(0.6, 0.9, 0.6, 1)
  importPerfTip:SetHeight(0)  -- Auto-height based on text wrapping

  -- Import status
  local importStatus = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  importStatus:SetPoint("TOPLEFT", importPerfTip, "BOTTOMLEFT", 0, -8)
  importStatus:SetText("")

  -- Import editbox with visible backdrop
  local importScroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate, BackdropTemplate")
  importScroll:SetPoint("TOPLEFT", importStatus, "BOTTOMLEFT", 0, -8)
  importScroll:SetPoint("RIGHT", f, "RIGHT", -30, 0)
  importScroll:SetHeight(200)
  
  -- Add backdrop to make the scroll area visible
  importScroll:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  importScroll:SetBackdropColor(0, 0, 0, 0.8)
  importScroll:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

  local importChild = CreateFrame("Frame", nil, importScroll)
  importChild:SetSize(importScroll:GetWidth() - 30, 400)

  local importBox = CreateFrame("EditBox", nil, importChild)
  importBox:SetMultiLine(true)
  importBox:SetAutoFocus(false)
  importBox:EnableMouse(true)
  importBox:SetMaxLetters(0)
  importBox:SetFontObject("ChatFontNormal")
  importBox:SetPoint("TOPLEFT", 6, -6)
  importBox:SetPoint("BOTTOMRIGHT", -6, 6)
  importBox:SetTextColor(1, 1, 1, 1)
  importBox:Show()
  
  importBox:SetScript("OnEscapePressed", function(self) 
    self:ClearFocus() 
  end)
  importBox:SetScript("OnEditFocusGained", function(self)
    self:EnableKeyboard(true)
    self:HighlightText(0, 0)
  end)
  importBox:SetScript("OnEditFocusLost", function(self)
    self:EnableKeyboard(false)
  end)
  importBox:SetScript("OnTextChanged", function(self)
    local text = self:GetText()
    if text and text:find("||") then
      local newText = text:gsub("||", "|")
      self:SetText(newText)
    end
  end)
  
  -- Click the scroll frame to focus the editbox
  importScroll:EnableMouse(true)
  importScroll:SetScript("OnMouseDown", function()
    importBox:SetFocus()
  end)
  
  importScroll:SetScrollChild(importChild)

  local function Trim(s)
    if type(s) ~= "string" then return "" end
    return (s:match("^%s*(.-)%s*$")) or ""
  end

  local function ProcessImportNow()
    local payload = Trim(importBox:GetText() or "")
    if payload == "" then
      importStatus:SetText(L("OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"))
      importStatus:SetTextColor(1, 0.2, 0.2)
      return
    end
    if #payload > 5 * 1024 * 1024 then
      importStatus:SetText("Payload too large.")
      importStatus:SetTextColor(1, 0.2, 0.2)
      return
    end

    if not (BookArchivist and BookArchivist.ImportWorker) then
      importStatus:SetText(L("OPTIONS_IMPORT_STATUS_UNAVAILABLE"))
      importStatus:SetTextColor(1, 0.2, 0.2)
      return
    end

    local worker = OptionsUI.importWorker
    if not worker and BookArchivist.ImportWorker and BookArchivist.ImportWorker.New then
      worker = BookArchivist.ImportWorker:New(f)
      OptionsUI.importWorker = worker
    end
    if not worker or not worker.Start then
      importStatus:SetText(L("OPTIONS_IMPORT_STATUS_UNAVAILABLE"))
      importStatus:SetTextColor(1, 0.2, 0.2)
      return
    end

    importStatus:SetText("Processing...")
    importStatus:SetTextColor(1, 0.9, 0.4)
    
    if BookArchivist and BookArchivist.DebugPrint then
      BookArchivist:DebugPrint("[Import] Starting import...")
      BookArchivist:DebugPrint("[Import] Payload size: " .. #payload .. " characters")
    end

    worker:Start(payload, {
      onProgress = function(label, pct)
        local pctNum = math.floor((pct or 0) * 100)
        importStatus:SetText(string.format("%s: %d%%", tostring(label or ""), pctNum))
        importStatus:SetTextColor(1, 0.9, 0.4)
        if BookArchivist and BookArchivist.DebugPrint then
          BookArchivist:DebugPrint(string.format("[Import] [%d%%] %s", pctNum, tostring(label or "")))
        end
      end,
      onDone = function(summary)
        importStatus:SetText(summary or L("OPTIONS_IMPORT_STATUS_COMPLETE"))
        importStatus:SetTextColor(0.6, 1, 0.6)
        importBox:SetText("")
        if BookArchivist and BookArchivist.DebugPrint then
          BookArchivist:DebugPrint("[Import] Import completed: " .. tostring(summary or ""))
        end
        if BookArchivist and type(BookArchivist.RefreshUI) == "function" then
          BookArchivist.RefreshUI()
        end
      end,
      onError = function(phase, err)
        importStatus:SetText(string.format(L("OPTIONS_IMPORT_STATUS_ERROR"), tostring(phase or ""), tostring(err or "")))
        importStatus:SetTextColor(1, 0.2, 0.2)
        if BookArchivist and BookArchivist.DebugPrint then
          BookArchivist:DebugPrint("[Import] ERROR in " .. tostring(phase) .. ": " .. tostring(err))
        end
      end,
    })
  end

  local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  importBtn:SetSize(140, 24)
  importBtn:SetPoint("TOPLEFT", importScroll, "BOTTOMLEFT", 0, -10)
  importBtn:SetText(L("OPTIONS_IMPORT_LABEL"))
  importBtn:SetScript("OnClick", ProcessImportNow)

  f.importBox = importBox
  toolsFrame = f
  return f
end

-- ----------------------------
-- Public API
-- ----------------------------

function OptionsUI:Ensure()
  RegisterNativeSettings()
end

function OptionsUI:Open()
  RegisterNativeSettings()
  if not ensureSettingsUILoaded() then
    return
  end
  local SettingsAPI = type(_G) == "table" and rawget(_G, "Settings") or nil
  if SettingsAPI and optionsCategory and type(SettingsAPI.OpenToCategory) == "function" then
    SettingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
    SettingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
  end
end

function OptionsUI:GetCategory()
  RegisterNativeSettings()
  return optionsCategory
end

function OptionsUI:Sync()
  -- Called when settings change (e.g., language)
  -- Update setting labels with new locale strings
  if settingObjects.tooltip then
    settingObjects.tooltip.name = L("OPTIONS_TOOLTIP_LABEL")
  end
  if settingObjects.resumeLastPage then
    settingObjects.resumeLastPage.name = L("OPTIONS_RESUME_LAST_PAGE_LABEL")
  end
  if settingObjects.language then
    settingObjects.language.name = L("LANGUAGE_LABEL")
  end
  
  -- Update category name
  if optionsCategory then
    optionsCategory.name = L("ADDON_TITLE")
  end
  
  -- Notify user that options panel labels won't update until UI reload
  -- (Blizzard Settings UI caches label text and doesn't support dynamic updates)
  if SettingsPanel and SettingsPanel:IsShown() then
    -- Show a message that reload is needed for options panel
    if BookArchivist and BookArchivist.DebugMessage then
      BookArchivist:DebugMessage(L("OPTIONS_RELOAD_REQUIRED") or "Language changed. Type /reload to update this settings panel.")
    end
  end
end

function OptionsUI:OpenTools()
  local f = CreateToolsFrame()
  f:Show()
  f:Raise()
end

function OptionsUI:OnAddonLoaded(name)
  if name ~= ADDON_NAME then return end
  self:Ensure()

  -- Slash command registration moved to BookArchivist_UI_Runtime.lua
  -- to consolidate all command handling in one place
end
