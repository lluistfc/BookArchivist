---@diagnostic disable: undefined-global
-- BookArchivist_UI_Reader_Share.lua
-- Handles share functionality for the reader (export single book and show share popup)

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}
BookArchivist.UI.Reader = BookArchivist.UI.Reader or {}

local ReaderShare = {}
BookArchivist.UI.Reader.Share = ReaderShare

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
  return (L and L[key]) or key
end

local shareFrame

-- Helper to get CreateFrame (safe version)
local function getCreateFrame()
  return BookArchivist.__createFrame or CreateFrame or function()
    local dummy = {}
    function dummy:SetScript() end
    function dummy:RegisterEvent() end
    return dummy
  end
end

-- Show the share popup with the export string
function ReaderShare:Show(exportStr)
  if not exportStr or exportStr == "" then
    print("|cFFFF0000[BookArchivist]|r Failed to generate export string.")
    return
  end
  
  -- Get or create the share modal frame
  if not shareFrame then
    local createFrame = getCreateFrame()
    shareFrame = createFrame("Frame", "BookArchivistShareFrame", UIParent, "BackdropTemplate")
    shareFrame:SetFrameStrata("DIALOG")
    shareFrame:SetSize(500, 300)
    shareFrame:SetPoint("CENTER")
    shareFrame:EnableMouse(true)
    shareFrame:SetMovable(true)
    shareFrame:RegisterForDrag("LeftButton")
    shareFrame:SetScript("OnDragStart", shareFrame.StartMoving)
    shareFrame:SetScript("OnDragStop", shareFrame.StopMovingOrSizing)
    
    if shareFrame.SetBackdrop then
      shareFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
      })
    end
    
    -- Title bar
    local titleBar = createFrame("Frame", nil, shareFrame)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", shareFrame, "TOPLEFT", 8, -8)
    titleBar:SetPoint("TOPRIGHT", shareFrame, "TOPRIGHT", -8, -8)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleText:SetText(t("READER_SHARE_POPUP_TITLE"))
    
    -- Close button
    local closeBtn = createFrame("Button", nil, shareFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", shareFrame, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
      shareFrame:Hide()
    end)
    
    -- Help text
    local helpText = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    helpText:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -8)
    helpText:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -8)
    helpText:SetJustifyH("LEFT")
    helpText:SetText(t("READER_SHARE_POPUP_LABEL"))
    
    -- ScrollFrame for EditBox
    local scrollFrame = createFrame("ScrollFrame", nil, shareFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", shareFrame, "BOTTOMRIGHT", -28, 48)
    
    if scrollFrame.SetBackdrop then
      scrollFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
      })
    end
    
    -- EditBox
    local editBox = createFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlight")
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetMaxLetters(0)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function()
      shareFrame:Hide()
    end)
    
    scrollFrame:SetScrollChild(editBox)
    shareFrame.editBox = editBox
    
    -- Select All button
    local selectAllBtn = createFrame("Button", nil, shareFrame, "UIPanelButtonTemplate")
    selectAllBtn:SetSize(100, 22)
    selectAllBtn:SetPoint("BOTTOM", shareFrame, "BOTTOM", 0, 12)
    selectAllBtn:SetText(t("READER_SHARE_SELECT_ALL"))
    selectAllBtn:SetScript("OnClick", function()
      editBox:SetFocus()
      editBox:HighlightText()
      if editBox.SetCursorPosition then
        editBox:SetCursorPosition(0)
      end
    end)
  end
  
  -- Set the export string and show
  shareFrame.editBox:SetText(exportStr)
  shareFrame.editBox:HighlightText()
  shareFrame:Show()
  C_Timer.After(0.1, function()
    if shareFrame and shareFrame.editBox then
      shareFrame.editBox:SetFocus()
    end
  end)
end

-- Generate export for the currently selected book and show share popup
function ReaderShare:ShareCurrentBook(addon, bookKey)
  if not (addon and bookKey) then 
    print("|cFFFF0000[BookArchivist]|r No book selected.")
    return
  end
  
  -- Generate export for single book
  local exportStr, err
  if addon.ExportBook and type(addon.ExportBook) == "function" then
    exportStr, err = addon:ExportBook(bookKey)
  elseif addon.Export and type(addon.Export) == "function" then
    -- Fallback to full export if ExportBook doesn't exist
    exportStr, err = addon:Export()
  end
  
  if exportStr and exportStr ~= "" then
    -- Store for quick access
    if addon then
      addon.__lastExportPayload = exportStr
    end
    
    -- Show share popup
    self:Show(exportStr)
  else
    local errMsg = err or "unknown error"
    print("|cFFFF0000[BookArchivist]|r Failed to generate export string: " .. tostring(errMsg))
  end
end

return ReaderShare
