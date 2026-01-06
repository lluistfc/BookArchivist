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

local IMPORT_PASTE_RENDER_LIMIT = 16000        -- chars kept visible in EditBox
local IMPORT_MAX_PAYLOAD_CHARS  = 5*1024*1024  -- hard cap: 5 MB

local function trim(msg)
  if type(msg) ~= "string" then
    return ""
  end
  local cleaned = msg:match("^%s*(.-)%s*$")
  return cleaned or ""
end

-- Ensure payload edit boxes (export/import) are readable in this panel
local function StylePayloadEditBox(editBox, isReadOnly)
  if not editBox then return end

  if editBox.SetFontObject then
    editBox:SetFontObject("ChatFontNormal")
  end
  if editBox.SetTextInsets then
    editBox:SetTextInsets(6, 6, 6, 6)
  end
  if editBox.SetTextColor then
    editBox:SetTextColor(1, 1, 1, 1)
  end
  if editBox.SetHighlightColor then
    editBox:SetHighlightColor(0.25, 0.5, 1, 0.5)
  end
  if editBox.SetCursorColor then
    editBox:SetCursorColor(1, 1, 1, 1)
  end
  if editBox.SetAlpha then
    editBox:SetAlpha(1)
  end

  if isReadOnly then
    editBox:SetScript("OnTextChanged", function(self, userInput)
      if userInput then
        self:HighlightText()
      end
    end)
    editBox:SetScript("OnKeyDown", function(self)
      self:HighlightText()
    end)
    editBox:SetScript("OnChar", function(self)
      self:HighlightText()
    end)
  end
end

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

  if optionsPanel.exportLabel and optionsPanel.exportLabel.SetText then
    optionsPanel.exportLabel:SetText(t("OPTIONS_EXPORT_IMPORT_LABEL"))
  end
  if optionsPanel.exportButton and optionsPanel.exportButton.SetText then
    optionsPanel.exportButton:SetText(t("OPTIONS_EXPORT_BUTTON"))
  end
  if optionsPanel.importLabel and optionsPanel.importLabel.SetText then
    optionsPanel.importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  end
  if optionsPanel.importButton and optionsPanel.importButton.SetText then
    optionsPanel.importButton:SetText(t("OPTIONS_IMPORT_BUTTON"))
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

  optionsPanel.pendingImportPayload = optionsPanel.pendingImportPayload or nil
  optionsPanel.pendingImportVisibleIsPlaceholder = false
  optionsPanel.lastExportPayload = optionsPanel.lastExportPayload or nil

  local logo = optionsPanel:CreateTexture(nil, "ARTWORK")
  logo:SetTexture("Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png")
  logo:SetSize(64, 64)
  logo:SetPoint("TOP", optionsPanel, "TOP", 0, -32)

  local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", logo, "BOTTOM", 0, -8)
	title:SetText(t("OPTIONS_TITLE"))
  optionsPanel.titleText = title

  local subtitle = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetText(t("OPTIONS_SUBTITLE_DEBUG"))
  optionsPanel.subtitleText = subtitle

  -- Left content column anchor (matches Blizzard option panel left margin)
  local contentLeft = createFrame("Frame", nil, optionsPanel)
  contentLeft:SetSize(1, 1)
  contentLeft:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -120)
  optionsPanel.contentLeft = contentLeft

  -- Right content boundary (matches Settings panel padding)
  local contentRight = createFrame("Frame", nil, optionsPanel)
  contentRight:SetSize(1, 1)
  contentRight:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -16, -120)
  optionsPanel.contentRight = contentRight

  subtitle:ClearAllPoints()
  subtitle:SetPoint("TOPLEFT", contentLeft, "TOPLEFT", 0, 0)

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
    -- Align language dropdown with the main content column
    dropdown:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -4)
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

  -- Prefer anchoring export/import to the visible dropdown button when available
  local dropdownButton
  if dropdown and dropdown.GetName then
    local name = dropdown:GetName()
    if name and _G then
      dropdownButton = _G[name .. "Button"]
    end
  end

  -- Export / Import section container (two columns)
  local exportImportContainer = createFrame("Frame", "BookArchivistExportImportContainer", optionsPanel)
  exportImportContainer:ClearAllPoints()
  -- Align with the left content column under the language row, with extra spacing as a new section
  exportImportContainer:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -36)
  -- Clamp to the panel's content width so it never drifts or overflows
  exportImportContainer:SetPoint("TOPRIGHT", optionsPanel.contentRight, "TOPLEFT", 0, -36)
  exportImportContainer:SetHeight(120)
  optionsPanel.exportImportContainer = exportImportContainer

  local COLUMN_GAP = 24

  local exportColumn = createFrame("Frame", "BookArchivistExportColumn", exportImportContainer)
  exportColumn:ClearAllPoints()
  exportColumn:SetPoint("TOPLEFT", exportImportContainer, "TOPLEFT", 0, 0)
  exportColumn:SetPoint("BOTTOMLEFT", exportImportContainer, "BOTTOMLEFT", 0, 0)
  optionsPanel.exportColumn = exportColumn

  local importColumn = createFrame("Frame", "BookArchivistImportColumn", exportImportContainer)
  importColumn:ClearAllPoints()
  importColumn:SetPoint("TOPRIGHT", exportImportContainer, "TOPRIGHT", 0, 0)
  importColumn:SetPoint("BOTTOMRIGHT", exportImportContainer, "BOTTOMRIGHT", 0, 0)
  optionsPanel.importColumn = importColumn

  local function LayoutExportImport()
    local w = exportImportContainer:GetWidth()
    if not w or w <= 0 then return end

    local colW = math.floor((w - COLUMN_GAP) / 2)
    if colW < 140 then
      colW = 140
    end

    exportColumn:SetWidth(colW)
    importColumn:SetWidth(colW)

    -- Ensure columns sit inside the container with a fixed gap
    exportColumn:ClearAllPoints()
    exportColumn:SetPoint("TOPLEFT", exportImportContainer, "TOPLEFT", 0, 0)
    exportColumn:SetPoint("BOTTOMLEFT", exportImportContainer, "BOTTOMLEFT", 0, 0)

    importColumn:ClearAllPoints()
    importColumn:SetPoint("TOPLEFT", exportColumn, "TOPRIGHT", COLUMN_GAP, 0)
    importColumn:SetPoint("BOTTOMLEFT", exportColumn, "BOTTOMRIGHT", COLUMN_GAP, 0)
  end

  exportImportContainer:HookScript("OnShow", LayoutExportImport)
  exportImportContainer:HookScript("OnSizeChanged", LayoutExportImport)
  LayoutExportImport()

  -- Export column
  local exportLabel = exportColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  exportLabel:SetPoint("TOPLEFT", exportColumn, "TOPLEFT", 0, 0)
  -- Use a short column label; fall back to plain text if not localized
  if L and L.OPTIONS_EXPORT_LABEL then
    exportLabel:SetText(L.OPTIONS_EXPORT_LABEL)
  else
    exportLabel:SetText("Export")
  end
  optionsPanel.exportLabel = exportLabel

  local exportScroll
  local exportBox

  local exportButton = createFrame("Button", "BookArchivistExportButton", exportColumn, "UIPanelButtonTemplate")
  exportButton:SetSize(160, 22)
  exportButton:SetPoint("TOPLEFT", exportLabel, "BOTTOMLEFT", 0, -4)
  exportButton:SetText(t("OPTIONS_EXPORT_BUTTON"))
  exportButton:SetScript("OnClick", function()
    if not BookArchivist or type(BookArchivist.ExportLibrary) ~= "function" then
      if print then
        print("[BookArchivist] Export unavailable")
      end
      return
    end
    local payload, err = BookArchivist:ExportLibrary()
    if not payload then
      if print then
        print("[BookArchivist] Export failed: " .. tostring(err))
      end
      return
    end
    if exportScroll then
      exportScroll:Show()
    else
      exportBox:Show()
    end
    if #payload > IMPORT_PASTE_RENDER_LIMIT then
      optionsPanel.lastExportPayload = payload
      exportBox:SetText(("Payload generated (%d chars). Use Copy."):format(#payload))
    else
      optionsPanel.lastExportPayload = nil
      exportBox:SetText(payload)
    end
    if exportBox.SetCursorPosition then
      exportBox:SetCursorPosition(0)
    end
    exportBox:SetFocus()
    exportBox:HighlightText()
  end)
  optionsPanel.exportButton = exportButton

  local exportCopyButton = createFrame("Button", "BookArchivistExportCopyButton", exportColumn, "UIPanelButtonTemplate")
  exportCopyButton:SetSize(80, 22)
  exportCopyButton:SetPoint("LEFT", exportButton, "RIGHT", 4, 0)
  exportCopyButton:SetText(t("OPTIONS_EXPORT_BUTTON_COPY") or "Copy")
  exportCopyButton:SetScript("OnClick", function()
    if not optionsPanel.lastExportPayload or optionsPanel.lastExportPayload == "" then
      if print then
        print("[BookArchivist] Nothing to copy yet")
      end
      return
    end
    if exportScroll then
      exportScroll:Show()
    else
      exportBox:Show()
    end
    exportBox:SetText(optionsPanel.lastExportPayload)
    if exportBox.SetCursorPosition then
      exportBox:SetCursorPosition(0)
    end
    exportBox:SetFocus()
    exportBox:HighlightText()
  end)
  optionsPanel.exportCopyButton = exportCopyButton

  exportScroll = CreateFrame and CreateFrame("ScrollFrame", "BookArchivistExportScrollFrame", exportColumn, "InputScrollFrameTemplate")
  if exportScroll and exportScroll.EditBox then
    exportScroll:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -6)
    exportScroll:SetPoint("TOPRIGHT", exportColumn, "TOPRIGHT", -6, 0)
    exportScroll:SetHeight(80)
    if exportScroll.SetAlpha then
      exportScroll:SetAlpha(1)
    end
    exportBox = exportScroll.EditBox
    exportBox:SetAutoFocus(false)
    exportBox:SetMultiLine(true)
    exportBox:SetFontObject("GameFontHighlightSmall")
    exportBox:SetMaxLetters(0)
    exportBox.cursorOffset = 0
    exportBox:SetText("")
    StylePayloadEditBox(exportBox, true)
    exportScroll:Show()
  else
    -- Fallback: simple multi-line edit box without a scrollbar.
    exportBox = createFrame("EditBox", "BookArchivistExportEditBox", exportColumn, "InputBoxTemplate")
    exportBox:ClearAllPoints()
    exportBox:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -6)
    exportBox:SetPoint("TOPRIGHT", exportColumn, "TOPRIGHT", -6, 0)
    exportBox:SetHeight(80)
    exportBox:SetAutoFocus(false)
    exportBox:SetMultiLine(true)
    exportBox:SetFontObject("GameFontHighlightSmall")
    exportBox:SetMaxLetters(0)
    StylePayloadEditBox(exportBox, true)
    exportBox:Hide()
  end
  optionsPanel.exportScroll = exportScroll
  optionsPanel.exportBox = exportBox

  -- Import column
  local importLabel = importColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  importLabel:SetPoint("TOPLEFT", importColumn, "TOPLEFT", 0, 0)
  importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  optionsPanel.importLabel = importLabel

  local importScroll
  local importBox

  local importButton = createFrame("Button", "BookArchivistImportButton", importColumn, "UIPanelButtonTemplate")
  importButton:SetSize(160, 22)
  importButton:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -4)
  importButton:SetText(t("OPTIONS_IMPORT_BUTTON"))
  local function GetImportPayload()
    if optionsPanel.pendingImportVisibleIsPlaceholder then
      return optionsPanel.pendingImportPayload or ""
    end
    if optionsPanel.pendingImportPayload then
      return optionsPanel.pendingImportPayload
    end
    return importBox and (importBox:GetText() or "") or ""
  end

  local importStatus = importColumn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  importStatus:SetPoint("LEFT", importButton, "RIGHT", 8, 0)
  importStatus:SetText("")
  optionsPanel.importStatus = importStatus

  importButton:SetScript("OnClick", function()
    local worker = optionsPanel.importWorker
    if not (BookArchivist and BookArchivist.ImportWorker and worker) then
      if print then
        print("[BookArchivist] Import unavailable")
      end
      return
    end

    local raw = trim(GetImportPayload())
    if raw == "" then
      if print then
        print("[BookArchivist] Import payload missing")
      end
      return
    end

    importButton:Disable()
    if optionsPanel.exportButton then optionsPanel.exportButton:Disable() end
    if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Disable() end
    importStatus:SetText("")

    local ok = worker:Start(raw, {
      onProgress = function(label, pct)
        if not importStatus or not importStatus.SetText then return end
        local pctNum = math.floor((pct or 0) * 100)
        importStatus:SetText(string.format("%s: %d%%", tostring(label or ""), pctNum))
      end,
      onDone = function(summary)
        importButton:Enable()
        if optionsPanel.exportButton then optionsPanel.exportButton:Enable() end
        if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Enable() end
        importStatus:SetText("")
        if print then
          print("[BookArchivist] " .. (summary or "Import complete"))
        end
        if BookArchivist.UI and BookArchivist.UI.Refresh then
          BookArchivist.UI:Refresh()
        elseif BookArchivist.RefreshUI then
          BookArchivist:RefreshUI()
        end
      end,
      onError = function(err)
        importButton:Enable()
        if optionsPanel.exportButton then optionsPanel.exportButton:Enable() end
        if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Enable() end
        importStatus:SetText("")
        if print then
          print("[BookArchivist] Import failed: " .. tostring(err))
        end
      end,
    })

    if not ok then
      importButton:Enable()
      if optionsPanel.exportButton then optionsPanel.exportButton:Enable() end
      if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Enable() end
      if print then
        print("[BookArchivist] Import already in progress")
      end
    end
  end)
  optionsPanel.importButton = importButton

  importScroll = CreateFrame and CreateFrame("ScrollFrame", "BookArchivistImportScrollFrame", importColumn, "InputScrollFrameTemplate")
  if importScroll and importScroll.EditBox then
    importScroll:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -6)
    importScroll:SetPoint("TOPRIGHT", importColumn, "TOPRIGHT", -6, 0)
    importScroll:SetHeight(80)
    if importScroll.SetAlpha then
      importScroll:SetAlpha(1)
    end
    importBox = importScroll.EditBox
    importBox:SetAutoFocus(false)
    importBox:SetMultiLine(true)
    importBox:SetFontObject("GameFontHighlightSmall")
    importBox:SetMaxLetters(0)
    importBox.cursorOffset = 0
    StylePayloadEditBox(importBox, false)
    local function SetImportPlaceholder(box, msg)
      optionsPanel.pendingImportVisibleIsPlaceholder = true
      box:SetText(msg)
      box:HighlightText(0, 0)
      if box.SetCursorPosition then
        box:SetCursorPosition(0)
      end
    end

    importBox:SetScript("OnTextChanged", function(self, userInput)
      if not userInput then return end
      local text = self:GetText() or ""

      if #text == 0 then
        optionsPanel.pendingImportPayload = nil
        optionsPanel.pendingImportVisibleIsPlaceholder = false
        return
      end

      if #text > IMPORT_MAX_PAYLOAD_CHARS then
        optionsPanel.pendingImportPayload = nil
        SetImportPlaceholder(self, "Payload too large. Aborting.")
        return
      end

      optionsPanel.pendingImportPayload = text
      optionsPanel.pendingImportVisibleIsPlaceholder = false

      if #text > IMPORT_PASTE_RENDER_LIMIT then
        SetImportPlaceholder(self, ("Payload received (%d chars). Click Import."):format(#text))
      end
    end)
  else
    importBox = createFrame("EditBox", "BookArchivistImportEditBox", importColumn, "InputBoxTemplate")
    importBox:ClearAllPoints()
    importBox:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -6)
    importBox:SetPoint("TOPRIGHT", importColumn, "TOPRIGHT", -6, 0)
    importBox:SetHeight(80)
    importBox:SetAutoFocus(false)
    importBox:SetMultiLine(true)
    importBox:SetFontObject("GameFontHighlightSmall")
    importBox:SetMaxLetters(0)
    StylePayloadEditBox(importBox, false)
  end
  optionsPanel.importScroll = importScroll
  optionsPanel.importBox = importBox
  optionsPanel.importWorker = optionsPanel.importWorker or (BookArchivist.ImportWorker and BookArchivist.ImportWorker:New(optionsPanel))
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
