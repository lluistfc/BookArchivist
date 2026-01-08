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
  if type(_G) == "table" then
    settingsAPI = rawget(_G, "Settings")
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
end

-- No hooks into Blizzard Settings or Game Menu to avoid taint.

function OptionsUI:Sync()
  if not optionsPanel or not optionsPanel.debugCheckbox then
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
	optionsPanel.debugCheckbox.Text:SetText(t("OPTIONS_DEBUG_LABEL"))
	end
  optionsPanel.debugCheckbox.tooltipText = t("OPTIONS_DEBUG_TOOLTIP")
  
  -- Sync UI debug grid state with debug mode (don't call SetDebugEnabled to avoid circular calls)
  if enabled then
    BookArchivistDB = BookArchivistDB or {}
    BookArchivistDB.options = BookArchivistDB.options or {}
    BookArchivistDB.options.uiDebug = true
    if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.setGridOverlayVisible then
      BookArchivist.UI.Internal.setGridOverlayVisible(true)
    end
  end

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
  if optionsPanel.importLabel and optionsPanel.importLabel.SetText then
    optionsPanel.importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  end
  if optionsPanel.importHelp and optionsPanel.importHelp.SetText then
    optionsPanel.importHelp:SetText(t("OPTIONS_IMPORT_HELP"))
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
  local scrollBar
  local scrollChild
  if type(_G) == "table" and rawget(_G, "CreateFrame") then
    -- Use standard ScrollFrame for continuous content, but with modern scrollbar
    scrollFrame = _G.CreateFrame("ScrollFrame", "BookArchivistOptionsScrollFrame", optionsPanel)
    scrollFrame:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMLEFT", optionsPanel, "BOTTOMLEFT", 4, 4)
    
    scrollBar = _G.CreateFrame("EventFrame", "BookArchivistOptionsScrollBar", optionsPanel, "MinimalScrollBar")
    scrollBar:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -4, -4)
    scrollBar:SetPoint("BOTTOMRIGHT", optionsPanel, "BOTTOMRIGHT", -4, 4)
    scrollFrame:SetPoint("RIGHT", scrollBar, "LEFT", -4, 0)

    scrollChild = createFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)  -- Start with minimal height, will be updated based on content
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Helper function to update scroll child dimensions based on content
    local function updateScrollChildDimensions()
      if not scrollChild or not scrollFrame then return end
      
      -- Update width to match scrollFrame
      local width = scrollFrame:GetWidth()
      if width and width > 0 then
        scrollChild:SetWidth(width)
      end
      
      -- Update height based on content
      local maxBottom = 0
      local children = {scrollChild:GetChildren()}
      for _, child in ipairs(children) do
        if child:IsShown() then
          local bottom = child:GetBottom()
          if bottom then
            local top = scrollChild:GetTop()
            if top then
              local relativeBottom = top - bottom
              if relativeBottom > maxBottom then
                maxBottom = relativeBottom
              end
            end
          end
        end
      end
      
      -- Add padding, with reasonable minimum
      local newHeight = math.max(400, maxBottom + 40)
      scrollChild:SetHeight(newHeight)
    end
    
    -- Store helper for external access
    optionsPanel.updateScrollChildHeight = updateScrollChildDimensions
    
    -- Initialize scroll controller with ScrollUtil
    if ScrollUtil and ScrollUtil.InitScrollFrameWithScrollBar then
      ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
      -- Configure scrollbar to auto-hide when not needed
      if scrollBar.SetHideIfUnscrollable then
        scrollBar:SetHideIfUnscrollable(true)
      end
    else
      -- Manual wiring for scroll functionality
      scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
      end)
      
      scrollBar:SetScript("OnMouseWheel", function(self, delta)
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        local newScroll = current - (delta * 20)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)
      end)
      
      -- Auto-hide scrollbar when content fits (manual mode)
      scrollFrame:HookScript("OnScrollRangeChanged", function(self, xRange, yRange)
        if scrollBar then
          local needsScroll = (yRange or 0) > 0
          scrollBar:SetShown(needsScroll)
        end
      end)
    end

    scrollFrame:HookScript("OnSizeChanged", function(frame, width)
      updateScrollChildDimensions()
    end)
    
    -- Ensure dimensions are set when scrollChild is shown
    scrollChild:SetScript("OnShow", function()
      C_Timer.After(0, updateScrollChildDimensions)
    end)
  else
    -- Fallback: no scroll frame available (e.g. in tests),
    -- render everything directly on the panel.
    scrollChild = optionsPanel
  end

  optionsPanel.scrollFrame = scrollFrame
  optionsPanel.scrollBar = scrollBar
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
  checkbox.Text:SetText(t("OPTIONS_DEBUG_LABEL"))
  checkbox.tooltipText = t("OPTIONS_DEBUG_TOOLTIP")
  checkbox:SetScript("OnClick", function(self)
    local state = self:GetChecked()
    if BookArchivist and type(BookArchivist.SetDebugEnabled) == "function" then
      BookArchivist:SetDebugEnabled(state)
    end
    
    -- Also control UI debug grid visibility
    BookArchivistDB = BookArchivistDB or {}
    BookArchivistDB.options = BookArchivistDB.options or {}
    BookArchivistDB.options.uiDebug = state and true or false
    
    if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.setGridOverlayVisible then
      BookArchivist.UI.Internal.setGridOverlayVisible(state and true or false)
    end
    
    -- Also control debug log widget visibility
    if state then
      -- Create and show debug log widget
      if optionsPanel.CreateDebugLogWidget then
        -- First ensure import widget exists
        if not optionsPanel.importWidget and optionsPanel.CreateImportWidget then
          optionsPanel.CreateImportWidget()
        end
        -- Now create debug widget
        optionsPanel.CreateDebugLogWidget()
        -- Force show if it was created
        if optionsPanel.debugWidget and optionsPanel.debugWidget.frame then
          optionsPanel.debugWidget.frame:Show()
        end
        -- Update scroll child height to accommodate new content
        if optionsPanel.updateScrollChildHeight then
          C_Timer.After(0, optionsPanel.updateScrollChildHeight)
        end
      end
    else
      -- Hide debug log widget
      if optionsPanel.debugWidget and optionsPanel.debugWidget.frame then
        optionsPanel.debugWidget.frame:Hide()
        optionsPanel.debugWidget.frame:SetParent(nil)
        optionsPanel.debugWidget = nil
      end
      -- Update scroll child height after hiding content
      if optionsPanel.updateScrollChildHeight then
        C_Timer.After(0, optionsPanel.updateScrollChildHeight)
      end
      -- Provide no-op when disabled
      optionsPanel.AppendDebugLog = function(message) end
    end
  end)

  optionsPanel.debugCheckbox = checkbox

  local tooltipCheckbox = createFrame("CheckButton", "BookArchivistTooltipCheckbox", scrollChild, "InterfaceOptionsCheckButtonTemplate")
  tooltipCheckbox:SetPoint("TOPLEFT", checkbox, "BOTTOMLEFT", 0, -8)
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

  -- Import section (aligned with other options)
  local importLabel = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  if dropdown then
    importLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", -16, -24)
  else
    importLabel:SetPoint("TOPLEFT", langLabel, "BOTTOMLEFT", 0, -24)
  end
  importLabel:SetText(t("OPTIONS_IMPORT_LABEL"))
  optionsPanel.importLabel = importLabel

  -- Info icon explaining import process
  local importInfoButton = createFrame("Button", nil, scrollChild)
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

  local importHelp = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  importHelp:SetPoint("TOPLEFT", importLabel, "BOTTOMLEFT", 0, -8)
  importHelp:SetPoint("RIGHT", contentRight, "TOPLEFT", 0, 0)
  importHelp:SetJustifyH("LEFT")
  importHelp:SetWordWrap(true)
  importHelp:SetText(t("OPTIONS_IMPORT_HELP"))
  optionsPanel.importHelp = importHelp

  -- Import status label for user feedback
  local importStatus = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  importStatus:SetPoint("TOPLEFT", importHelp, "BOTTOMLEFT", 0, -8)
  importStatus:SetPoint("RIGHT", contentRight, "TOPLEFT", 0, 0)
  importStatus:SetJustifyH("LEFT")
  importStatus:SetText("")
  importStatus:SetTextColor(0.8, 0.8, 0.8)
  optionsPanel.importStatus = importStatus

  local importScroll
  local importBox
  local function GetImportPayload()
    local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
    
    -- 1) Prefer an explicit pending payload captured from the
    --    import box (including placeholder-visible mode).
    if optionsPanel.pendingImportVisibleIsPlaceholder then
      if optionsPanel.pendingImportPayload and optionsPanel.pendingImportPayload ~= "" then
        if debugMode and optionsPanel.AppendDebugLog then 
          optionsPanel.AppendDebugLog("[Payload] Using pending payload: " .. #optionsPanel.pendingImportPayload .. " chars")
        end
        return optionsPanel.pendingImportPayload
      end
    elseif optionsPanel.pendingImportPayload and optionsPanel.pendingImportPayload ~= "" then
      if debugMode and optionsPanel.AppendDebugLog then
        optionsPanel.AppendDebugLog("[Payload] Using pending payload: " .. #optionsPanel.pendingImportPayload .. " chars")
      end
      return optionsPanel.pendingImportPayload
    end

    -- 2) If the visible import box has text (cross-client
    --    sharing case), prioritise that over any same-session
    --    export state. Use the committed text from OnTextChanged
    --    instead of GetText() to work around WoW multiline paste
    --    quirks.
    if optionsPanel.importBoxCommittedText and optionsPanel.importBoxCommittedText ~= "" then
      local vis = trim(optionsPanel.importBoxCommittedText)
      if vis ~= "" then
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("[Payload] Using committed box text: " .. #vis .. " chars")
        end
        return vis
      else
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("[Payload] Committed text is empty after trim")
        end
      end
    elseif optionsPanel.importBox and optionsPanel.importBox.GetText then
      local vis = trim(optionsPanel.importBox:GetText() or "")
      if vis ~= "" then
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("[Payload] Using visible box text: " .. #vis .. " chars")
        end
        return vis
      else
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("[Payload] Visible box is empty")
        end
      end
    end

    -- 3) If there is no explicit import text but we
    --    have a payload from this session's Export, allow Import
    --    to consume that directly so users don't need to paste at
    --    all for local transfers.
    if optionsPanel.lastExportPayload and optionsPanel.lastExportPayload ~= "" then
      if debugMode and optionsPanel.AppendDebugLog then
        optionsPanel.AppendDebugLog("[Payload] Using session export: " .. #optionsPanel.lastExportPayload .. " chars")
      end
      return optionsPanel.lastExportPayload
    end

    -- 4) As a final same-session fast path, fall back to the
    --    most recent export payload recorded globally (used by
    --    the reader Share popup as well as the options Export
    --    button) so imports don't depend on paste length.
    if BookArchivist and BookArchivist.__lastExportPayload and BookArchivist.__lastExportPayload ~= "" then
      if debugMode and optionsPanel.AppendDebugLog then
        optionsPanel.AppendDebugLog("[Payload] Using global export: " .. #BookArchivist.__lastExportPayload .. " chars")
      end
      return BookArchivist.__lastExportPayload
    end

    if debugMode and optionsPanel.AppendDebugLog then
      optionsPanel.AppendDebugLog("[Payload] No payload found")
    end
    return ""
  end
  
  -- Separate import processing logic (WeakAuras pattern)
  -- This can be called from OnTextChanged (auto-import) or from button click
  local function ProcessImport()
    local worker = optionsPanel.importWorker
    if not (BookArchivist and BookArchivist.ImportWorker and worker) then
      local msg = "[BookArchivist] " .. t("OPTIONS_IMPORT_STATUS_UNAVAILABLE")
      if print then print(msg) end
      if optionsPanel.AppendDebugLog then optionsPanel.AppendDebugLog(msg) end
      return false
    end

    local raw = trim(GetImportPayload())
    if raw == "" then
      local msg = "[BookArchivist] " .. t("OPTIONS_IMPORT_STATUS_PAYLOAD_MISSING")
      if print then print(msg) end
      if optionsPanel.AppendDebugLog then optionsPanel.AppendDebugLog(msg) end
      return false
    end

    local ok = worker:Start(raw, {
      onProgress = function(label, pct)
        local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
        local pctNum = math.floor((pct or 0) * 100)
        local phase = tostring(label or "")
        local userPhase = phase
        
        if phase == "Decoded" then
          userPhase = t("OPTIONS_IMPORT_STATUS_PHASE_DECODE")
        elseif phase == "Parsed" then
          userPhase = t("OPTIONS_IMPORT_STATUS_PHASE_PARSED")
        elseif phase == "Merging" then
          userPhase = t("OPTIONS_IMPORT_STATUS_PHASE_MERGE")
        elseif phase == "Building search" then
          userPhase = t("OPTIONS_IMPORT_STATUS_PHASE_SEARCH")
        elseif phase == "Indexing titles" then
          userPhase = t("OPTIONS_IMPORT_STATUS_PHASE_TITLES")
        end
        
        -- Show user-friendly progress for import/merge phases
        if phase == "Merging" or phase == "Building search" or phase == "Indexing titles" then
          if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
            optionsPanel.importStatus:SetText(string.format("%s: %d%%", userPhase, pctNum))
            optionsPanel.importStatus:SetTextColor(1, 0.9, 0.4)
          end
        end
        
        -- Log all phases to debug log if debug mode is enabled
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog(string.format("%s: %d%%", userPhase, pctNum))
        end
      end,
      onDone = function(summary)
        -- Show success message to user
        if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
          optionsPanel.importStatus:SetText(summary or t("OPTIONS_IMPORT_STATUS_COMPLETE"))
          optionsPanel.importStatus:SetTextColor(0.6, 1, 0.6)
        end
        
        if print then
          print("[BookArchivist] " .. (summary or t("OPTIONS_IMPORT_STATUS_COMPLETE")))
        end
        
        -- Log to debug if enabled
        local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog(summary or t("OPTIONS_IMPORT_STATUS_COMPLETE"))
        end
        
        -- Clear the import box after successful import
        if optionsPanel.importBox then
          optionsPanel.importBox:SetText("")
          optionsPanel.importBoxCommittedText = ""
        end
        
        if BookArchivist and type(BookArchivist.RefreshUI) == "function" then
          BookArchivist.RefreshUI()
        end
      end,
      onError = function(phase, err)
        local errMsg = string.format(t("OPTIONS_IMPORT_STATUS_ERROR"), tostring(phase or ""), tostring(err or ""))
        
        -- Show error to user
        if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
          optionsPanel.importStatus:SetText(errMsg)
          optionsPanel.importStatus:SetTextColor(1, 0.2, 0.2)
        end
        
        local fullMsg = "[BookArchivist] " .. errMsg
        if print then print(fullMsg) end
        
        -- Log detailed error info only if debug mode is enabled
        local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog(fullMsg)
          optionsPanel.AppendDebugLog("Phase: " .. tostring(phase))
          optionsPanel.AppendDebugLog("Error: " .. tostring(err))
        end
      end
    })
    
    if not ok then
      return false
    end
    
    return true
  end

  -- Defer AceGUI widget creation to avoid layout anchor conflicts
  -- Create it after the panel is shown and layout is stable
  local function CreateImportWidget()
    if optionsPanel.importWidget then return end -- Already created
    
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
    if not AceGUI then
      print("[BookArchivist] AceGUI-3.0 not found, using basic EditBox")
      return
    end
    
    -- Create AceGUI MultiLineEditBox widget (like WeakAuras)
    local importWidget = AceGUI:Create("MultiLineEditBox")
    importWidget:SetLabel("")
    importWidget:DisableButton(true)
    importWidget:SetNumLines(6)
    importWidget:SetFullWidth(true)
    importWidget.frame:SetParent(scrollChild)
    importWidget.frame:ClearAllPoints()
    importWidget.frame:SetPoint("TOPLEFT", optionsPanel.importStatus or importHelp, "BOTTOMLEFT", 0, -4)
    importWidget.frame:SetPoint("RIGHT", contentRight, "TOPLEFT", 0, 0)
    importWidget.frame:SetFrameLevel(optionsPanel:GetFrameLevel() + 10)
    importWidget.frame:Show()
    
    optionsPanel.importWidget = importWidget
    optionsPanel.importBox = importWidget.editBox
    
    -- Hide the fallback EditBox since we're using AceGUI
    if optionsPanel.importScroll then
      optionsPanel.importScroll:Hide()
    end
    
    -- WeakAuras-style auto-import on paste
    optionsPanel.importBoxCommittedText = ""
    importWidget.editBox:SetScript("OnTextChanged", function(self, userInput)
      if userInput then
        local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
        local pasted = self:GetText() or ""
        local numLetters = self:GetNumLetters()
        local rawLength = #pasted
        
        -- CRITICAL: WoW EditBox escapes | to || during paste, we need to unescape it
        pasted = pasted:gsub("||", "|")
        
        -- Show first and last 50 chars for diagnostics (only in debug mode)
        local first50 = pasted:sub(1, 50)
        local last50 = pasted:sub(-50)
        
        pasted = pasted:match("^%s*(.-)%s*$")
        
        optionsPanel.importBoxCommittedText = pasted
        
        if debugMode and #pasted > 0 and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("Text pasted: " .. #pasted .. " chars (trimmed)")
          optionsPanel.AppendDebugLog("GetNumLetters: " .. numLetters)
          optionsPanel.AppendDebugLog("First 50: " .. first50:gsub("|", "||"))
          optionsPanel.AppendDebugLog("Last 50: " .. last50:gsub("|", "||"))
        end
        
        if #pasted > 50 then
          local hasHeader = pasted:find("BDB1|S|", 1, true) ~= nil
          local hasFooter = pasted:find("BDB1|E", 1, true) ~= nil
          
          if debugMode and optionsPanel.AppendDebugLog then
            optionsPanel.AppendDebugLog("Has BDB1 header: " .. tostring(hasHeader))
            optionsPanel.AppendDebugLog("Has BDB1 footer: " .. tostring(hasFooter))
          end
          
          if hasHeader and hasFooter then
            -- Show user that import is starting
            if optionsPanel.importStatus and optionsPanel.importStatus.SetText then
              optionsPanel.importStatus:SetText("Processing import...")
              optionsPanel.importStatus:SetTextColor(1, 0.9, 0.4)
            end
            
            if debugMode and optionsPanel.AppendDebugLog then
              optionsPanel.AppendDebugLog("Valid BDB1 envelope detected, starting import...")
            end
            
            C_Timer.After(0.1, function()
              ProcessImport()
            end)
          elseif hasHeader and not hasFooter then
            local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
            local msg = "PASTE TRUNCATED! Footer missing (" .. #pasted .. " chars received)."
            
            if debugMode and optionsPanel.AppendDebugLog then
              optionsPanel.AppendDebugLog(msg)
              optionsPanel.AppendDebugLog("Paste may be incomplete - check export string.")
            end
          end
        end
      end
    end)
  end  -- End CreateImportWidget function
  
  -- Store reference so it's accessible from checkbox handlers
  optionsPanel.CreateImportWidget = CreateImportWidget
  
  -- Fallback: Create basic EditBox if AceGUI will not be available
  -- (kept for compatibility when AceGUI is missing)
  local importScroll = createFrame("ScrollFrame", "BookArchivistImportScrollFrame", scrollChild)
  importScroll:SetPoint("TOPLEFT", importStatus, "BOTTOMLEFT", 0, -4)
  importScroll:SetPoint("RIGHT", contentRight, "TOPLEFT", -20, 0)
  importScroll:SetHeight(120)
  optionsPanel.importScroll = importScroll  -- Store for debug widget anchor
  importScroll:EnableMouse(true)
  importScroll:EnableMouseWheel(true)
  if importScroll.SetBackdrop then
    importScroll:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
  end

  importBox = createFrame("EditBox", "BookArchivistImportEditBox", importScroll)
  importBox:SetMultiLine(true)
  importBox:SetAutoFocus(false)
  importBox:SetMaxLetters(0)
  importBox:SetMaxBytes(0)
  importBox:EnableMouse(true)
  importBox:EnableKeyboard(true)
  importBox:SetEnabled(true)
  importBox:SetCountInvisibleLetters(false)  -- KEY: This allows large paste like WeakAuras
  importBox:SetFontObject("GameFontHighlightSmall")
  importBox:SetWidth(importScroll:GetWidth() - 20)
  importBox:SetHeight(400)
  importBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  
  -- Make import box clearly visible with background and border
  local importBg = importScroll:CreateTexture(nil, "BACKGROUND")
  importBg:SetAllPoints(importScroll)
  importBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
  
  local importBorder = importScroll:CreateTexture(nil, "BORDER")
  importBorder:SetAllPoints(importScroll)
  importBorder:SetColorTexture(0.5, 0.5, 0.5, 1)
  importBorder:SetDrawLayer("BORDER", 0)
  
  local importInset = importScroll:CreateTexture(nil, "BACKGROUND")
  importInset:SetPoint("TOPLEFT", importScroll, "TOPLEFT", 1, -1)
  importInset:SetPoint("BOTTOMRIGHT", importScroll, "BOTTOMRIGHT", -1, 1)
  importInset:SetColorTexture(0.05, 0.05, 0.05, 0.9)

  -- WeakAuras-style import: OnTextChanged processes paste immediately
  -- and triggers import automatically when valid data detected.
  -- This bypasses GetText() unreliability entirely.
  optionsPanel.importBoxCommittedText = ""
  importBox:SetScript("OnTextChanged", function(self, userInput)
    if userInput then
      local debugMode = BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled()
      
      -- User-initiated change (paste, typing, etc)
      local pasted = self:GetText() or ""
      local numLetters = self:GetNumLetters()
      local rawLength = #pasted
      pasted = pasted:match("^%s*(.-)%s*$") -- trim whitespace
      
      optionsPanel.importBoxCommittedText = pasted
      
      if debugMode and #pasted > 0 then
        if optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("Text pasted: " .. #pasted .. " chars (trimmed)")
          optionsPanel.AppendDebugLog("GetNumLetters: " .. numLetters)
          optionsPanel.AppendDebugLog("Raw GetText length: " .. rawLength)
        end
      end
      
      -- Check for truncated paste (has header but no footer)
      if #pasted > 50 then
        local hasHeader = pasted:find("BDB1|S|", 1, true) ~= nil
        local hasFooter = pasted:find("BDB1|E", 1, true) ~= nil
        
        if debugMode and optionsPanel.AppendDebugLog then
          optionsPanel.AppendDebugLog("Has BDB1 header: " .. tostring(hasHeader))
          optionsPanel.AppendDebugLog("Has BDB1 footer: " .. tostring(hasFooter))
        end
        
        if hasHeader and not hasFooter then
          -- Paste was truncated - shouldn't happen with AceGUI but keep check
          local msg = "PASTE TRUNCATED! Footer missing (" .. #pasted .. " chars received)."
          if debugMode then
            print("[BA Import] " .. msg)
            if optionsPanel.AppendDebugLog then
              optionsPanel.AppendDebugLog(msg)
              optionsPanel.AppendDebugLog("Export may be too large or incomplete.")
            end
          end
          return
        end
        
        if hasHeader and hasFooter then
          if debugMode and optionsPanel.AppendDebugLog then
            optionsPanel.AppendDebugLog("Valid BDB1 envelope detected, starting import...")
          end
          -- Process immediately like WeakAuras does
          C_Timer.After(0.1, function()
            ProcessImport()
          end)
        end
      end
    end
  end)
  
  StylePayloadEditBox(importBox, false)
  
  importScroll:SetScrollChild(importBox)
  importScroll:SetScript("OnSizeChanged", function(self, w)
    if importBox and w and w > 20 then
      importBox:SetWidth(w - 20)
    end
  end)

  optionsPanel.importScroll = importScroll
  optionsPanel.importBox = importBox
  
  -- Define CreateDebugLogWidget after import widgets exist
  local function CreateDebugLogWidget()
    if optionsPanel.debugWidget then 
      -- Already created, just show it
      if optionsPanel.debugWidget.frame then
        optionsPanel.debugWidget.frame:Show()
      end
      -- Update scroll height
      if optionsPanel.updateScrollChildHeight then
        C_Timer.After(0, optionsPanel.updateScrollChildHeight)
      end
      return
    end
    
    local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
    if not AceGUI then return end
    
    local debugWidget = AceGUI:Create("MultiLineEditBox")
    debugWidget:SetLabel("Debug Log (copy errors from here):")
    debugWidget:DisableButton(true)
    debugWidget:SetNumLines(12)
    debugWidget:SetFullWidth(true)
    debugWidget:SetMaxLetters(50000)  -- Prevent overflow
    debugWidget.frame:SetParent(scrollChild)
    debugWidget.frame:ClearAllPoints()
    -- Anchor below import widget or fallback scroll frame
    local anchorFrame = (optionsPanel.importWidget and optionsPanel.importWidget.frame) or optionsPanel.importScroll
    if anchorFrame then
      debugWidget.frame:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -8)
    else
      -- Last resort: anchor below import status label
      debugWidget.frame:SetPoint("TOPLEFT", optionsPanel.importStatus or importHelp, "BOTTOMLEFT", 0, -150)
    end
    debugWidget.frame:SetPoint("RIGHT", contentRight, "TOPLEFT", 0, 0)
    debugWidget.frame:SetFrameLevel(optionsPanel:GetFrameLevel() + 10)
    debugWidget.frame:Show()
    debugWidget:SetText("Debug mode enabled. Diagnostics will appear here...")
    
    optionsPanel.debugWidget = debugWidget
    optionsPanel.debugLogBox = debugWidget.editBox
    
    -- Update scroll child height after adding debug widget
    if optionsPanel.updateScrollChildHeight then
      C_Timer.After(0.1, optionsPanel.updateScrollChildHeight)
    end
    
    -- Helper function to append to debug log
    local function AppendDebugLog(message)
      if not debugWidget then return end
      local current = debugWidget:GetText() or ""
      if current:match("^Debug mode enabled") or current:match("^Errors and diagnostic") then
        current = ""
      end
      local timestamp = date("%H:%M:%S")
      local newText = current .. "\n[" .. timestamp .. "] " .. message
      -- Truncate if too long
      if #newText > 45000 then
        newText = "[Log truncated]\n" .. newText:sub(-40000)
      end
      debugWidget:SetText(newText)
      if debugWidget.editBox then
        debugWidget.editBox:SetCursorPosition(#newText)
      end
    end
    
    optionsPanel.AppendDebugLog = AppendDebugLog
  end
  
  optionsPanel.CreateDebugLogWidget = CreateDebugLogWidget
  
  -- Call CreateImportWidget when panel is shown to ensure proper widget creation
  optionsPanel:HookScript("OnShow", function()
    if not optionsPanel.importWidget and optionsPanel.CreateImportWidget then
      optionsPanel.CreateImportWidget()
    end
    -- Create debug log if debug mode is enabled
    if BookArchivist and BookArchivist.IsDebugEnabled and BookArchivist:IsDebugEnabled() then
      if optionsPanel.CreateDebugLogWidget then
        optionsPanel.CreateDebugLogWidget()
      end
    end
  end)
  
  -- Provide no-op AppendDebugLog if debug widget not created
  if not optionsPanel.AppendDebugLog then
    optionsPanel.AppendDebugLog = function(message)
      -- No-op when debug mode is disabled
    end
  end

  -- Override print for the import section to also log to debug box
  local originalPrint = print
  local function debugPrint(...)
    local message = strjoin(" ", tostringall(...))
    if message:match("%[BA") or message:match("%[BookArchivist%]") then
      AppendDebugLog(message)
    end
    if originalPrint then
      originalPrint(...)
    end
  end
  
  -- Temporarily replace print during import operations
  optionsPanel.debugPrint = debugPrint
  optionsPanel.CreateImportWidget = CreateImportWidget
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
  
  -- Create AceGUI import widget after panel is ready
  C_Timer.After(0.1, function()
    if panel.CreateImportWidget then
      panel.CreateImportWidget()
    end
  end)

  local settingsAPI = type(_G) == "table" and rawget(_G, "Settings") or nil
  if settingsAPI and type(settingsAPI.OpenToCategory) == "function" and optionsCategory then
    settingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
    settingsAPI.OpenToCategory(optionsCategory.ID or optionsCategory)
  end
end

function OptionsUI:OnAddonLoaded(name)
  if name ~= ADDON_NAME then
    return
  end
  self:Ensure()
end
