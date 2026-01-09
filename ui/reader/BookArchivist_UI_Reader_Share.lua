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
function ReaderShare:Show(exportStr, bookTitle, bookKey, addon, bookData)
  if not exportStr or exportStr == "" then
    BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r Failed to generate export string.")
    return
  end
  
BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Show() called with:")
BookArchivist:DebugPrint("  bookTitle:", bookTitle)
BookArchivist:DebugPrint("  bookKey:", bookKey)
BookArchivist:DebugPrint("  bookData:", bookData and "present" or "nil")
  
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
    
    -- Chat link hint
    local chatHint = shareFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatHint:SetPoint("TOPLEFT", helpText, "BOTTOMLEFT", 0, -4)
    chatHint:SetPoint("TOPRIGHT", helpText, "BOTTOMRIGHT", 0, -4)
    chatHint:SetJustifyH("LEFT")
    chatHint:SetTextColor(0.29, 0.49, 0.73) -- Blue color
    chatHint:SetText(t("SHARE_CHAT_HINT"))
    shareFrame.chatHint = chatHint
    
    -- ScrollFrame for EditBox
    local scrollFrame = createFrame("ScrollFrame", nil, shareFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", chatHint, "BOTTOMLEFT", 0, -8)
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
    
    -- Share to Chat button (at bottom)
    local shareToChatBtn = createFrame("Button", nil, shareFrame, "UIPanelButtonTemplate")
    shareToChatBtn:SetSize(140, 22)
    shareToChatBtn:SetPoint("BOTTOMLEFT", shareFrame, "BOTTOMLEFT", 8, 12)
    shareToChatBtn:SetText(t("SHARE_TO_CHAT_BUTTON"))
    shareToChatBtn:SetScript("OnClick", function()
      local bookTitle = shareFrame.bookTitle or "Book"
      local chatLink = string.format("[BookArchivist: %s]", bookTitle)
      
BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Share to Chat clicked:")
BookArchivist:DebugPrint("  bookTitle:", bookTitle)
BookArchivist:DebugPrint("  bookKey:", shareFrame.bookKey)
BookArchivist:DebugPrint("  bookData:", shareFrame.bookData and "present" or "nil")
      
      -- Register book as linked RIGHT NOW when sending to chat
      if BookArchivist.ChatLinks and shareFrame.bookKey and shareFrame.bookData then
BookArchivist:DebugPrint("|cFF00FF00[Share DEBUG]|r Registering book as linked")
        BookArchivist.ChatLinks:RegisterLinkedBook(shareFrame.bookKey, shareFrame.bookData)
      else
BookArchivist:DebugPrint("|cFFFF0000[Share DEBUG]|r Cannot register: missing ChatLinks, bookKey, or bookData")
      end
      
      -- Insert into active chat editbox
      local editbox = ChatEdit_GetActiveWindow()
      if editbox then
        editbox:Insert(chatLink)
        editbox:SetFocus()
      else
        -- No active chat, just put it in the default chat frame
        ChatFrame1EditBox:Show()
        ChatFrame1EditBox:SetFocus()
        ChatFrame1EditBox:Insert(chatLink)
      end
      
      -- Optional: show confirmation
    BookArchivist:DebugPrint("|cFF4A7EBBBookArchivist:|r " .. (t("SHARE_LINK_INSERTED") or "Chat link inserted! Press Enter to send."))
    end)
    shareFrame.shareToChatBtn = shareToChatBtn
    
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
  
  -- Store book context for Share to Chat button (update EVERY time Show() is called)
  shareFrame.bookTitle = bookTitle
  shareFrame.bookKey = bookKey
  shareFrame.addon = addon
  shareFrame.bookData = bookData
  
BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Stored in shareFrame:")
BookArchivist:DebugPrint("  bookTitle:", shareFrame.bookTitle)
BookArchivist:DebugPrint("  bookKey:", shareFrame.bookKey)
BookArchivist:DebugPrint("  bookData:", shareFrame.bookData and "present" or "nil")
  
  -- Update chat hint with book title if provided
  if shareFrame.chatHint and bookTitle then
    local hintText = string.format(
      t("SHARE_CHAT_HINT") or "Click the button below to insert a chat link, or copy the export string to share directly.",
      bookTitle
    )
    shareFrame.chatHint:SetText(hintText)
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
    BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r No book selected.")
    return
  end
  
BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r ShareCurrentBook called:")
BookArchivist:DebugPrint("  addon:", addon)
BookArchivist:DebugPrint("  bookKey:", bookKey)
  
  -- Get book data directly from DB
  local bookData = BookArchivistDB and BookArchivistDB.booksById and BookArchivistDB.booksById[bookKey]
  local bookTitle = bookData and bookData.title
  
BookArchivist:DebugPrint("|cFF4A7EBB[Share DEBUG]|r Retrieved from DB:")
BookArchivist:DebugPrint("  bookData:", bookData and "found" or "nil")
BookArchivist:DebugPrint("  bookTitle:", bookTitle or "nil")
  
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
    
    -- Register book as "linked" for auto-response to requests
    if BookArchivist.ChatLinks and bookData then
      BookArchivist.ChatLinks:RegisterLinkedBook(bookKey, bookData)
    end
    
    -- Show share popup with book title and context
    self:Show(exportStr, bookTitle, bookKey, addon, bookData)
  else
    local errMsg = err or "unknown error"
    BookArchivist:DebugPrint("|cFFFF0000[BookArchivist]|r Failed to generate export string: " .. tostring(errMsg))
  end
end

return ReaderShare
