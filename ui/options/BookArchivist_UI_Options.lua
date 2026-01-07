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
  if optionsPanel.exportCopyButton and optionsPanel.exportCopyButton.SetText then
    optionsPanel.exportCopyButton:SetText(t("OPTIONS_EXPORT_BUTTON_COPY"))
  end
  if optionsPanel.importLabel and optionsPanel.importLabel.SetText then
    optionsPanel.importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  end
  if optionsPanel.importButton and optionsPanel.importButton.SetText then
    optionsPanel.importButton:SetText(t("OPTIONS_IMPORT_BUTTON"))
  end
  if optionsPanel.importPasteButton and optionsPanel.importPasteButton.SetText then
    optionsPanel.importPasteButton:SetText(t("OPTIONS_IMPORT_BUTTON_CAPTURE"))
  end
  if optionsPanel.importHelp and optionsPanel.importHelp.SetText then
    optionsPanel.importHelp:SetText(t("OPTIONS_IMPORT_HELP"))
  end
  -- Keep the export status line in sync with the active
  -- language: show the default hint if no payload exists,
  -- otherwise show the localized "export ready" text.
  if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
    if optionsPanel.lastExportPayload and type(optionsPanel.lastExportPayload) == "string" and optionsPanel.lastExportPayload ~= "" then
      optionsPanel.exportStatus:SetText(string.format(t("OPTIONS_EXPORT_STATUS_READY"), #optionsPanel.lastExportPayload))
    else
      optionsPanel.exportStatus:SetText(t("OPTIONS_EXPORT_STATUS_DEFAULT"))
    end
  end
  -- If there is no pending import payload, keep the status line
  -- synced with the default hint in the active language.
  if optionsPanel.importStatus and optionsPanel.importStatus.SetText and not optionsPanel.pendingImportPayload then
    optionsPanel.importStatus:SetText(t("OPTIONS_IMPORT_STATUS_DEFAULT"))
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

  -- Wrap panel contents in a scroll frame so long localized
  -- help text (such as the export/import instructions) never
  -- overflows the visible options area.
  local scrollFrame
  local scrollChild
  if type(_G) == "table" and rawget(_G, "CreateFrame") then
    scrollFrame = _G.CreateFrame("ScrollFrame", "BookArchivistOptionsScrollFrame", optionsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -26, 4)

    scrollChild = createFrame("Frame", nil, scrollFrame)
    -- Give the scroll child a reasonable initial height so that
    -- content can extend and be scrolled without being clipped.
    scrollChild:SetSize(1, 800)
    scrollFrame:SetScrollChild(scrollChild)

    scrollFrame:HookScript("OnSizeChanged", function(frame, width)
      if not width or width <= 0 then return end
      if scrollChild and scrollChild.SetWidth then
        scrollChild:SetWidth(width)
      end
    end)
  else
    -- Fallback: no scroll frame available (e.g. in tests),
    -- render everything directly on the panel.
    scrollChild = optionsPanel
  end

  optionsPanel.scrollFrame = scrollFrame
  optionsPanel.scrollChild = scrollChild

  local logo = scrollChild:CreateTexture(nil, "ARTWORK")
  logo:SetTexture("Interface\\AddOns\\BookArchivist\\BookArchivist_logo_64x64.png")
  logo:SetSize(64, 64)
  logo:SetPoint("TOP", scrollChild, "TOP", 0, -32)

  local title = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", logo, "BOTTOM", 0, -8)
	title:SetText(t("OPTIONS_TITLE"))
  optionsPanel.titleText = title

  local subtitle = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetText(t("OPTIONS_SUBTITLE_DEBUG"))
  optionsPanel.subtitleText = subtitle

  -- Left content column anchor (matches Blizzard option panel left margin)
  local contentLeft = createFrame("Frame", nil, scrollChild)
  contentLeft:SetSize(1, 1)
  contentLeft:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 16, -120)
  optionsPanel.contentLeft = contentLeft

  -- Right content boundary (matches Settings panel padding)
  local contentRight = createFrame("Frame", nil, scrollChild)
  contentRight:SetSize(1, 1)
  contentRight:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", -16, -120)
  optionsPanel.contentRight = contentRight

  subtitle:ClearAllPoints()
  subtitle:SetPoint("TOPLEFT", contentLeft, "TOPLEFT", 0, 0)

  local checkbox = createFrame("CheckButton", "BookArchivistDebugCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
  checkbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
  checkbox.Text:SetText(t("OPTIONS_DEBUG_LOGGING_LABEL"))
  checkbox.tooltipText = t("OPTIONS_DEBUG_LOGGING_TOOLTIP")
  checkbox:SetScript("OnClick", function(self)
    if BookArchivist and type(BookArchivist.SetDebugEnabled) == "function" then
      BookArchivist:SetDebugEnabled(self:GetChecked())
    end
  end)

  optionsPanel.debugCheckbox = checkbox

  local uiDebugCheckbox = createFrame("CheckButton", "BookArchivistUIDebugCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
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

  local tooltipCheckbox = createFrame("CheckButton", "BookArchivistTooltipCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
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

  local resumePageCheckbox = createFrame("CheckButton", "BookArchivistResumePageCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
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

  local langLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  langLabel:SetPoint("TOPLEFT", resumePageCheckbox, "BOTTOMLEFT", 0, -16)
	langLabel:SetText(t("LANGUAGE_LABEL"))
  optionsPanel.langLabel = langLabel

  local dropdown = CreateFrame and CreateFrame("Frame", "BookArchivistLanguageDropdown", scrollChild, "UIDropDownMenuTemplate")
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
          if OptionsUI and OptionsUI.Sync then
            OptionsUI:Sync()
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
  local exportImportContainer = createFrame("Frame", "BookArchivistExportImportContainer", scrollChild)
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
  exportLabel:SetText(t("OPTIONS_EXPORT_LABEL"))
  optionsPanel.exportLabel = exportLabel

  local exportCopyScroll
  local exportCopyBox
  local exportStatus

  local exportButton = createFrame("Button", "BookArchivistExportButton", exportColumn, "UIPanelButtonTemplate")
  exportButton:SetSize(160, 22)
  exportButton:SetPoint("TOPLEFT", exportLabel, "BOTTOMLEFT", 0, -4)
  exportButton:SetText(t("OPTIONS_EXPORT_BUTTON"))
  exportButton:SetScript("OnClick", function()
    if not BookArchivist or type(BookArchivist.ExportLibrary) ~= "function" then
      if print then
        print("[BookArchivist] Export unavailable")
      end
      if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
        optionsPanel.exportStatus:SetText(t("OPTIONS_EXPORT_STATUS_UNAVAILABLE"))
        if optionsPanel.exportStatus.SetTextColor then
          optionsPanel.exportStatus:SetTextColor(1, 0.2, 0.2)
        end
      end
      return
    end
    local payload, err = BookArchivist:ExportLibrary()
    if not payload then
      if print then
        print("[BookArchivist] Export failed: " .. tostring(err))
      end
      if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
        optionsPanel.exportStatus:SetText(string.format(t("OPTIONS_EXPORT_STATUS_FAILED"), tostring(err)))
        if optionsPanel.exportStatus.SetTextColor then
          optionsPanel.exportStatus:SetTextColor(1, 0.2, 0.2)
        end
      end
      return
    end
    optionsPanel.lastExportPayload = payload
    if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
      optionsPanel.exportStatus:SetText(string.format(t("OPTIONS_EXPORT_STATUS_READY"), #payload))
      if optionsPanel.exportStatus.SetTextColor then
        optionsPanel.exportStatus:SetTextColor(0.6, 1, 0.6)
      end
    end
  end)
  optionsPanel.exportButton = exportButton

  local exportCopyButton = createFrame("Button", "BookArchivistExportCopyButton", exportColumn, "UIPanelButtonTemplate")
  exportCopyButton:SetSize(80, 22)
  exportCopyButton:SetPoint("LEFT", exportButton, "RIGHT", 4, 0)
  exportCopyButton:SetText(t("OPTIONS_EXPORT_BUTTON_COPY"))
  exportCopyButton:SetScript("OnClick", function()
    local text = optionsPanel.lastExportPayload or ""
    if text == "" then
      if print then
        print("[BookArchivist] Nothing to copy yet")
      end
      if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
        optionsPanel.exportStatus:SetText(t("OPTIONS_EXPORT_STATUS_NOTHING_TO_COPY"))
        if optionsPanel.exportStatus.SetTextColor then
          optionsPanel.exportStatus:SetTextColor(1, 0.9, 0.4)
        end
      end
      return
    end
    if optionsPanel.exportCopyBox then
      optionsPanel.exportCopyBox:Show()
      optionsPanel.exportCopyBox:SetText(text)
      if optionsPanel.exportCopyBox.SetCursorPosition then
        optionsPanel.exportCopyBox:SetCursorPosition(0)
      end
      optionsPanel.exportCopyBox:SetFocus()
      optionsPanel.exportCopyBox:HighlightText()
      if optionsPanel.exportStatus and optionsPanel.exportStatus.SetText then
        optionsPanel.exportStatus:SetText(t("OPTIONS_EXPORT_STATUS_COPY_HINT"))
        if optionsPanel.exportStatus.SetTextColor then
          optionsPanel.exportStatus:SetTextColor(0.9, 0.9, 0.9)
        end
      end
    end
  end)
  optionsPanel.exportCopyButton = exportCopyButton
  -- Export status line: communicates current export state.
  exportStatus = exportColumn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  exportStatus:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -4)
  exportStatus:SetPoint("RIGHT", exportColumn, "RIGHT", 0, 0)
  exportStatus:SetJustifyH("LEFT")
  exportStatus:SetText(t("OPTIONS_EXPORT_STATUS_DEFAULT"))
  if exportStatus.SetTextColor then
    exportStatus:SetTextColor(0.8, 0.8, 0.8)
  end
  optionsPanel.exportStatus = exportStatus
  -- Hidden multiline copy-catcher edit box: keeps the full
  -- BDB1 export (including newlines) so copy/paste works
  -- correctly, without rendering a giant visible textarea.
  exportCopyScroll = CreateFrame and CreateFrame("ScrollFrame", "BookArchivistExportCopyScrollFrame", optionsPanel, "InputScrollFrameTemplate")
  if exportCopyScroll and exportCopyScroll.EditBox then
    exportCopyScroll:ClearAllPoints()
    exportCopyScroll:SetPoint("TOPLEFT", optionsPanel, "BOTTOMLEFT", 0, -100)
    exportCopyScroll:SetSize(1, 1)
    if exportCopyScroll.SetAlpha then
      exportCopyScroll:SetAlpha(0)
    end
    exportCopyBox = exportCopyScroll.EditBox
    exportCopyBox:SetAutoFocus(false)
    if exportCopyBox.SetMultiLine then
      exportCopyBox:SetMultiLine(true)
    end
    if exportCopyBox.SetMaxBytes then
      exportCopyBox:SetMaxBytes(0)
    end
    exportCopyBox:SetFontObject("GameFontHighlightSmall")
    exportCopyBox:SetMaxLetters(0)
    -- Seed cursor metrics so ScrollingEdit_OnUpdate has safe values
    -- even before the first cursor change callback fires.
    exportCopyBox.cursorOffset = 0
    if exportCopyBox.GetLineHeight then
      exportCopyBox.cursorHeight = exportCopyBox:GetLineHeight() or 1
    else
      exportCopyBox.cursorHeight = 1
    end
    StylePayloadEditBox(exportCopyBox, false)
  else
    -- Fallback for environments without InputScrollFrameTemplate:
    -- still prefer multiline so newlines are preserved.
    exportCopyBox = createFrame("EditBox", "BookArchivistExportCopyBox", exportColumn, "InputBoxTemplate")
    exportCopyBox:ClearAllPoints()
    exportCopyBox:SetPoint("TOPLEFT", exportStatus, "BOTTOMLEFT", 0, -4)
    exportCopyBox:SetPoint("TOPRIGHT", exportColumn, "TOPRIGHT", -6, 0)
    exportCopyBox:SetHeight(40)
    exportCopyBox:SetAutoFocus(false)
    if exportCopyBox.SetMultiLine then
      exportCopyBox:SetMultiLine(true)
    end
    if exportCopyBox.SetMaxBytes then
      exportCopyBox:SetMaxBytes(0)
    end
    exportCopyBox:SetFontObject("GameFontHighlightSmall")
    exportCopyBox:SetMaxLetters(0)
    exportCopyBox.cursorOffset = 0
    if exportCopyBox.GetLineHeight then
      exportCopyBox.cursorHeight = exportCopyBox:GetLineHeight() or 1
    else
      exportCopyBox.cursorHeight = 1
    end
    StylePayloadEditBox(exportCopyBox, false)
    exportCopyBox:Hide()
  end
  optionsPanel.exportCopyBox = exportCopyBox

  -- Import column
  local importLabel = importColumn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  importLabel:SetPoint("TOPLEFT", importColumn, "TOPLEFT", 0, 0)
  importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  optionsPanel.importLabel = importLabel

  -- Info icon explaining Ctrl+V vs Capture Paste performance
  local importInfoButton = createFrame("Button", nil, importColumn)
  importInfoButton:SetSize(16, 16)
  importInfoButton:SetPoint("LEFT", importLabel, "RIGHT", 4, 0)
  local importInfoTex = importInfoButton:CreateTexture(nil, "ARTWORK")
  importInfoTex:SetAllPoints(true)
  importInfoTex:SetTexture("Interface\\FriendsFrame\\InformationIcon")
  importInfoButton:SetScript("OnEnter", function(self)
    if not GameTooltip or not GameTooltip.SetOwner then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(t("OPTIONS_IMPORT_LABEL"), 1, 1, 1)
    if GameTooltip.AddLine then
      GameTooltip:AddLine(t("OPTIONS_IMPORT_PERF_TIP"), nil, nil, nil, true)
    end
    GameTooltip:Show()
  end)
  importInfoButton:SetScript("OnLeave", function()
    if GameTooltip and GameTooltip.Hide then
      GameTooltip:Hide()
    end
  end)

  local importHelp = importColumn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  importHelp:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -4)
  importHelp:SetPoint("RIGHT", importColumn, "RIGHT", 0, 0)
  importHelp:SetJustifyH("LEFT")
  importHelp:SetText(t("OPTIONS_IMPORT_HELP"))
  optionsPanel.importHelp = importHelp

  local importScroll
  local importBox

  local importButton = createFrame("Button", "BookArchivistImportButton", importColumn, "UIPanelButtonTemplate")
  importButton:SetSize(160, 22)
  importButton:SetPoint("TOPLEFT", importHelp, "BOTTOMLEFT", 0, -4)
  importButton:SetText(t("OPTIONS_IMPORT_BUTTON"))
  local function GetImportPayload()
    -- 1) Prefer an explicit pending payload captured from the
    --    import box (including placeholder-visible mode).
    if optionsPanel.pendingImportVisibleIsPlaceholder then
      if optionsPanel.pendingImportPayload and optionsPanel.pendingImportPayload ~= "" then
        return optionsPanel.pendingImportPayload
      end
    elseif optionsPanel.pendingImportPayload and optionsPanel.pendingImportPayload ~= "" then
      return optionsPanel.pendingImportPayload
    end

    -- 2) If there is no explicit import text but we
    --    have a payload from this session's Export, allow Import
    --    to consume that directly so users don't need to paste at
    --    all for local transfers.
    if optionsPanel.lastExportPayload and optionsPanel.lastExportPayload ~= "" then
      return optionsPanel.lastExportPayload
    end

    return ""
  end

  local importStatus = importColumn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  importStatus:SetPoint("TOPLEFT", importButton, "BOTTOMLEFT", 0, -4)
  importStatus:SetPoint("RIGHT", importColumn, "RIGHT", 0, 0)
  importStatus:SetJustifyH("LEFT")
  importStatus:SetText(t("OPTIONS_IMPORT_STATUS_DEFAULT"))
  if importStatus.SetTextColor then
    importStatus:SetTextColor(0.8, 0.8, 0.8)
  end
  optionsPanel.importStatus = importStatus

  local importPasteButton = createFrame("Button", "BookArchivistImportPasteButton", importColumn, "UIPanelButtonTemplate")
  importPasteButton:SetSize(120, 22)
  importPasteButton:SetPoint("LEFT", importButton, "RIGHT", 4, 0)
  importPasteButton:SetText(t("OPTIONS_IMPORT_BUTTON_CAPTURE"))
  importPasteButton:SetScript("OnClick", function()
    optionsPanel.pendingImportPayload = nil
    optionsPanel.pendingImportVisibleIsPlaceholder = false
    optionsPanel.importPasteBuffer = {}
    optionsPanel.importBufferLen = 0
    optionsPanel.importIsPasting = false
    optionsPanel.importLastCharElapsed = 0

    -- Decide how aggressively to capture paste based on
    -- whether we still have a local export payload from this
    -- session. In the local-export case, we only need a tiny
    -- paste to act as a trigger and can avoid clipboard-sized
    -- freezes; in the cross-client/after-reload case we allow
    -- a full paste so we can reconstruct the payload text.
    local hasLocalExport = optionsPanel.lastExportPayload and optionsPanel.lastExportPayload ~= ""
    optionsPanel.importUseLocalExport = hasLocalExport and true or false
    if optionsPanel.importBox and optionsPanel.importBox.SetMaxBytes then
    if hasLocalExport then
      optionsPanel.importBox:SetMaxBytes(1)
    else
      optionsPanel.importBox:SetMaxBytes(0)
    end
    end
    if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
      optionsPanel.importStatus:SetText(t("OPTIONS_IMPORT_STATUS_PASTE_HINT"))
      if optionsPanel.importStatus.SetTextColor then
        optionsPanel.importStatus:SetTextColor(0.9, 0.9, 0.9)
      end
    end
    if optionsPanel.importBox and optionsPanel.importBox.SetFocus then
      optionsPanel.importBox:SetFocus()
    end
  end)
  optionsPanel.importPasteButton = importPasteButton

  importButton:SetScript("OnClick", function()
    local worker = optionsPanel.importWorker
    if not (BookArchivist and BookArchivist.ImportWorker and worker) then
      if print then
        print("[BookArchivist] " .. t("OPTIONS_IMPORT_STATUS_UNAVAILABLE"))
      end
      return
    end

    local raw = trim(GetImportPayload())
    if raw == "" then
      if print then
        print("[BookArchivist] " .. t("OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING"))
      end
      return
    end

    importButton:Disable()
    if optionsPanel.exportButton then optionsPanel.exportButton:Disable() end
    if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Disable() end
    if importStatus.SetText then
      importStatus:SetText(t("OPTIONS_IMPORT_STATUS_PREPARING"))
      if importStatus.SetTextColor then
        importStatus:SetTextColor(1, 0.9, 0.4)
      end
    end

    local ok = worker:Start(raw, {
      onProgress = function(label, pct)
        if not importStatus or not importStatus.SetText then return end
        local pctNum = math.floor((pct or 0) * 100)
        local phase = tostring(label or "")
        if phase == "Decoded" then
          phase = t("OPTIONS_IMPORT_STATUS_PHASE_DECODE")
        elseif phase == "Parsed" then
          phase = t("OPTIONS_IMPORT_STATUS_PHASE_PARSED")
        elseif phase == "Merging" then
          phase = t("OPTIONS_IMPORT_STATUS_PHASE_MERGE")
        elseif phase == "Building search" then
          phase = t("OPTIONS_IMPORT_STATUS_PHASE_SEARCH")
        elseif phase == "Indexing titles" then
          phase = t("OPTIONS_IMPORT_STATUS_PHASE_TITLES")
        end
        importStatus:SetText(string.format("%s: %d%%", phase, pctNum))
        if importStatus.SetTextColor then
          importStatus:SetTextColor(1, 0.9, 0.4)
        end
      end,
      onDone = function(summary)
        importButton:Enable()
        if optionsPanel.exportButton then optionsPanel.exportButton:Enable() end
        if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Enable() end
        if importStatus.SetText then
          importStatus:SetText(summary or t("OPTIONS_IMPORT_STATUS_COMPLETE"))
          if importStatus.SetTextColor then
            importStatus:SetTextColor(0.6, 1, 0.6)
          end
        end
        if print then
          print("[BookArchivist] " .. (summary or t("OPTIONS_IMPORT_STATUS_COMPLETE")))
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
        if importStatus.SetText then
          importStatus:SetText(string.format(t("OPTIONS_IMPORT_STATUS_FAILED"), tostring(err)))
          if importStatus.SetTextColor then
            importStatus:SetTextColor(1, 0.2, 0.2)
          end
        end
        if print then
          print("[BookArchivist] " .. string.format(t("OPTIONS_IMPORT_STATUS_FAILED"), tostring(err)))
        end
      end,
    })

    if not ok then
      importButton:Enable()
      if optionsPanel.exportButton then optionsPanel.exportButton:Enable() end
      if optionsPanel.exportCopyButton then optionsPanel.exportCopyButton:Enable() end
      if print then
        print("[BookArchivist] " .. t("OPTIONS_IMPORT_STATUS_IN_PROGRESS"))
      end
    end
  end)
  optionsPanel.importButton = importButton

  -- Hidden paste-catcher edit box: no visible textarea in the UI.
  importScroll = nil
  importBox = createFrame("EditBox", "BookArchivistImportPasteBox", optionsPanel, "InputBoxTemplate")
  importBox:ClearAllPoints()
  importBox:SetPoint("TOPLEFT", optionsPanel, "BOTTOMLEFT", 0, -100)
  importBox:SetWidth(1)
  importBox:SetHeight(1)
  importBox:SetAutoFocus(false)
  if importBox.SetMultiLine then
	  -- Use a multiline edit box so WoW will accept large
	  -- pasted payloads (full BDB export strings) instead of
	  -- truncating them to a short single-line limit, which
	  -- would trigger "Payload too short" during decode.
	  importBox:SetMultiLine(true)
  end
  if importBox.SetMaxBytes then
    -- Default to allowing full paste; Capture Paste will
    -- tighten this per-scenario (local export vs clipboard).
    importBox:SetMaxBytes(0)
  end
  importBox:SetFontObject("GameFontHighlightSmall")
  importBox:SetMaxLetters(0)
  importBox.cursorOffset = 0
  if importBox.SetAlpha then
    importBox:SetAlpha(0)
  end
  StylePayloadEditBox(importBox, false)

  -- Paste-catcher state: collect characters via OnChar into a
  -- Lua buffer and rebuild the full string off-screen after the
  -- paste finishes, as described in docs/import-export.md.
  optionsPanel.importPasteBuffer = optionsPanel.importPasteBuffer or {}
  optionsPanel.importIsPasting = false
  optionsPanel.importLastCharElapsed = 0
  optionsPanel.importBufferLen = optionsPanel.importBufferLen or 0

  local pasteWatcher = optionsPanel.importPasteWatcher
  if not pasteWatcher then
    pasteWatcher = createFrame("Frame", nil, optionsPanel)
    optionsPanel.importPasteWatcher = pasteWatcher
  end

  pasteWatcher:Hide()
  pasteWatcher:SetScript("OnUpdate", function(_, elapsed)
    if not optionsPanel.importIsPasting then
      return
    end

    optionsPanel.importLastCharElapsed = (optionsPanel.importLastCharElapsed or 0) + elapsed

    -- If no new chars for ~0.2s, assume the paste finished and
    -- rebuild the real string off-screen.
    if optionsPanel.importLastCharElapsed > 0.2 then
      optionsPanel.importIsPasting = false
      if pasteWatcher.Hide then
        pasteWatcher:Hide()
      end

      local function RebuildAndProcess()
        local buf = optionsPanel.importPasteBuffer or {}
        local text = table.concat(buf)

        optionsPanel.importPasteBuffer = {}
        optionsPanel.importBufferLen = 0

        if #text == 0 then
          optionsPanel.pendingImportPayload = nil
          optionsPanel.pendingImportVisibleIsPlaceholder = false
          if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
            optionsPanel.importStatus:SetText(t("OPTIONS_IMPORT_STATUS_DEFAULT"))
          end
          return
        end

        if #text > IMPORT_MAX_PAYLOAD_CHARS then
          optionsPanel.pendingImportPayload = nil
          optionsPanel.pendingImportVisibleIsPlaceholder = false
          if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
            optionsPanel.importStatus:SetText(t("OPTIONS_IMPORT_STATUS_TOO_LARGE"))
          end
          return
        end

        local payload

        if optionsPanel.lastExportPayload and optionsPanel.lastExportPayload ~= "" then
          -- Same-session fast path (Export -> Copy -> Capture
          -- Paste on this client): if we still have a canonical
          -- export string in memory, trust it and ignore any
          -- mutations introduced by the copy/paste path.
          payload = optionsPanel.lastExportPayload
        else
          -- Cross-client / after-reload path: accept the pasted
          -- text as a candidate payload and let the ImportWorker
          -- validate whether it is a real BookArchivist export.
          -- This avoids false "no export in clipboard" errors
          -- when the text is valid but formatted differently
          -- than expected.
          payload = text
          -- Remember this clipboard-based payload as the current
          -- canonical export so that subsequent Capture Paste
          -- uses on this client can take the fast, no-freeze
          -- path that relies on lastExportPayload instead of
          -- rebuilding from a large paste again.
          optionsPanel.lastExportPayload = payload
        end

        optionsPanel.pendingImportPayload = payload
        optionsPanel.pendingImportVisibleIsPlaceholder = true

        if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
          optionsPanel.importStatus:SetText(string.format(t("OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"), #payload))
        end

        if optionsPanel.importBox and optionsPanel.importBox.SetText then
          optionsPanel.importBox:SetText("")
          if optionsPanel.importBox.SetCursorPosition then
            optionsPanel.importBox:SetCursorPosition(0)
          end
        end
      end

      local hasTimer = type(C_Timer) == "table" and type(C_Timer.After) == "function"
      if hasTimer then
        C_Timer.After(0, RebuildAndProcess)
      else
        RebuildAndProcess()
      end
    end
  end)

  importBox:SetScript("OnChar", function(_, char)
    -- Fast path: when we still have a local export string from
    -- this session, treat Capture Paste as a lightweight
    -- trigger and avoid building a large Lua buffer.
    if optionsPanel.importUseLocalExport and optionsPanel.lastExportPayload and optionsPanel.lastExportPayload ~= "" then
    optionsPanel.importIsPasting = false
    optionsPanel.importPasteBuffer = {}
    optionsPanel.importBufferLen = 0
    if optionsPanel.importPasteWatcher and optionsPanel.importPasteWatcher.Hide then
      optionsPanel.importPasteWatcher:Hide()
    end

    local payload = optionsPanel.lastExportPayload
    optionsPanel.pendingImportPayload = payload
    optionsPanel.pendingImportVisibleIsPlaceholder = true
    if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
      optionsPanel.importStatus:SetText(string.format(t("OPTIONS_IMPORT_STATUS_PAYLOAD_RECEIVED"), #payload))
    end
    if optionsPanel.importBox and optionsPanel.importBox.SetText then
      optionsPanel.importBox:SetText("")
      if optionsPanel.importBox.SetCursorPosition then
      optionsPanel.importBox:SetCursorPosition(0)
      end
    end
    return
    end

    optionsPanel.importIsPasting = true
    optionsPanel.importLastCharElapsed = 0

    local buf = optionsPanel.importPasteBuffer
    buf[#buf + 1] = char
    optionsPanel.importBufferLen = (optionsPanel.importBufferLen or 0) + #char

    if optionsPanel.importBufferLen > IMPORT_MAX_PAYLOAD_CHARS then
      -- Enforce the cap during paste to avoid ever building an
      -- enormous string only to throw it away afterwards.
      optionsPanel.importIsPasting = false
      optionsPanel.importPasteBuffer = {}
      optionsPanel.importBufferLen = 0
      if optionsPanel.importPasteWatcher and optionsPanel.importPasteWatcher.Hide then
        optionsPanel.importPasteWatcher:Hide()
      end
      optionsPanel.pendingImportPayload = nil
      optionsPanel.pendingImportVisibleIsPlaceholder = false
      if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
        optionsPanel.importStatus:SetText(t("OPTIONS_IMPORT_STATUS_TOO_LARGE"))
      end
      return
    end

    if optionsPanel.importPasteWatcher and optionsPanel.importPasteWatcher.Show then
      optionsPanel.importPasteWatcher:Show()
    end
  end)

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
