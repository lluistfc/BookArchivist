---@diagnostic disable: undefined-global
-- BookArchivist_ChatLinks.lua
-- WeakAuras-style sharing: clickable chat links with automatic data transmission

BookArchivist = BookArchivist or {}

local ChatLinks = {}
BookArchivist.ChatLinks = ChatLinks

-- Get AceComm library
local AceComm = LibStub and LibStub("AceComm-3.0", true)
local AceSerializer = LibStub and LibStub("AceSerializer-3.0", true)

-- Color for BookArchivist links (blue)
local LINK_COLOR = "4A7EBB"

-- Recently shared books (for auto-responding to requests)
-- Format: { [bookId] = { bookData, timestamp } }
local linkedBooks = {}
local LINK_VALIDITY_DURATION = 60 * 5 -- 5 minutes

-- Safe senders (people who clicked our links)
local safeSenders = {}

-- Pending imports
local pendingImport = nil
local tooltipLoading = false
local receivedData = false

-- Chat filter function to convert plain text to hyperlinks
local function BookArchivistChatFilter(self, event, msg, sender, ...)
  local newMsg = msg
  local modified = false
  
  -- Find all [BookArchivist: Title] patterns and convert to hyperlinks
  -- Extract sender name for the link
  -- Note: Use greedy match (.+) to handle titles that contain brackets
  newMsg = msg:gsub("%[BookArchivist: (.+)%]", function(title)
    modified = true
    -- Encode title and sender for link data
    local encodedTitle = title:gsub(" ", "_"):gsub("|", "||")
    local encodedSender = (sender or "Unknown"):gsub("-.*", "") -- Remove realm
    -- Create clickable hyperlink with sender info
    return string.format("|Hbookarc:%s:%s|h|cFF%s[BookArchivist: %s]|h|r",
      encodedSender,
      encodedTitle,
      LINK_COLOR,
      title)
  end)
  
  if modified then
    return false, newMsg, sender, ...
  end
end

-- Install chat filters on all channels
local function InstallChatFilters()
  local chatEvents = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_BN_WHISPER",
    "CHAT_MSG_BN_WHISPER_INFORM",
    "CHAT_MSG_CHANNEL",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER"
  }
  
  for _, event in ipairs(chatEvents) do
    ChatFrame_AddMessageEventFilter(event, BookArchivistChatFilter)
  end
end

-- Hook SetItemRef to handle link clicks
local originalSetItemRef = SetItemRef
function SetItemRef(link, text, button, chatFrame)
  -- Check if this is a BookArchivist link
  if link and link:match("^bookarc:") then
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Link clicked:", link)
    local senderName, encodedTitle = link:match("^bookarc:([^:]+):(.+)$")
    if not senderName then
      BookArchivist:DebugPrint("|cFFFFAA00[ChatLinks DEBUG]|r Old format detected, using fallback")
      -- Old format fallback
      encodedTitle = link:sub(9)
      senderName = "Unknown"
    end
    
    local title = encodedTitle:gsub("_", " "):gsub("||", "|")
    senderName = senderName:gsub("_", " ")
    
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Parsed link:")
    BookArchivist:DebugPrint("  sender:", senderName)
    BookArchivist:DebugPrint("  title:", title)
    
    if IsShiftKeyDown() then
      -- Shift-click: insert plain text into active editbox
      local editbox = ChatEdit_GetActiveWindow()
      if editbox then
        editbox:Insert("[BookArchivist: " .. title .. "]")
      end
    else
      -- Normal click: request data from sender
      ChatLinks:RequestBookFromSender(senderName, title)
    end
    return
  end
  
  -- Not our link, call original handler
  return originalSetItemRef(link, text, button, chatFrame)
end

-- Request book data from sender
function ChatLinks:RequestBookFromSender(senderName, bookTitle)
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r RequestBookFromSender called:")
  BookArchivist:DebugPrint("  sender:", senderName)
  BookArchivist:DebugPrint("  title:", bookTitle)
  
  if not AceComm then
    BookArchivist:DebugPrint("|cFFFF0000[ChatLinks DEBUG]|r AceComm not available, falling back to manual import")
    -- Fallback to manual import if AceComm not available
    self:ShowImportPrompt(bookTitle)
    return
  end
  
  local L = BookArchivist.L or {}
  
  -- Mark sender as safe
  local senderNameClean = Ambiguate(senderName, "none")
  safeSenders[senderName] = true
  safeSenders[senderNameClean] = true
  
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Marked sender as safe:", senderNameClean)
  
  -- Show tooltip with loading state
  tooltipLoading = true
  receivedData = false
  self:ShowTooltip({
    {2, "BookArchivist", bookTitle, 0.29, 0.49, 0.73, 1, 1, 1},
    {1, (L["REQUESTING_BOOK"] or "Requesting book from %s..."):format(senderNameClean), 1, 0.82, 0}
  })
  
  -- Send request
  local request = {
    m = "request",
    title = bookTitle
  }
  
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Sending request via AceComm:")
  BookArchivist:DebugPrint("  to:", senderName)
  BookArchivist:DebugPrint("  request:", request.m, request.title)
  
  if AceSerializer then
    local serialized = AceSerializer:Serialize(request)
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Serialized length:", #serialized)
    AceComm:SendCommMessage("BookArchivist", serialized, "WHISPER", senderName)
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r SendCommMessage completed")
  end
  
  -- Timeout after 10 seconds (addon communication can be slow)
  C_Timer.After(10, function()
    if tooltipLoading and not receivedData and ItemRefTooltip:IsVisible() then
      self:ShowTooltip({
        {2, "BookArchivist", bookTitle, 0.29, 0.49, 0.73, 1, 1, 1},
        {1, (L["REQUEST_TIMEOUT"] or "No response from %s"):format(senderNameClean), 1, 0, 0}
      })
    end
  end)
end

-- Show tooltip (similar to WeakAuras)
function ChatLinks:ShowTooltip(lines)
  ItemRefTooltip:Show()
  if not ItemRefTooltip:IsVisible() then
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
  end
  ItemRefTooltip:ClearLines()
  
  for i, line in ipairs(lines) do
    local sides = line[1]
    if sides == 1 then
      ItemRefTooltip:AddLine(line[2], line[3], line[4], line[5], line[6])
    elseif sides == 2 then
      ItemRefTooltip:AddDoubleLine(line[2], line[3], line[4], line[5], line[6], line[7], line[8], line[9])
    end
  end
  
  ItemRefTooltip:Show()
end

-- Register a book as shareable (called when user clicks share button)
function ChatLinks:RegisterLinkedBook(bookId, bookData)
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Registering book as linked:")
  BookArchivist:DebugPrint("  bookId:", bookId)
  BookArchivist:DebugPrint("  title:", bookData and bookData.title or "nil")
  BookArchivist:DebugPrint("  timestamp:", GetTime())
  
  linkedBooks[bookId] = {
    data = bookData,
    timestamp = GetTime()
  }
  
  -- Clean up old entries
  local expiredTime = GetTime() - LINK_VALIDITY_DURATION
  for id, entry in pairs(linkedBooks) do
    if entry.timestamp < expiredTime then
      linkedBooks[id] = nil
    end
  end
  
  local count = 0
  for _ in pairs(linkedBooks) do count = count + 1 end
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Total linked books:", count)
end

-- Handle incoming comm messages
local function HandleComm(prefix, message, distribution, sender)
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r HandleComm called:")
  BookArchivist:DebugPrint("  prefix:", prefix)
  BookArchivist:DebugPrint("  distribution:", distribution)
  BookArchivist:DebugPrint("  sender:", sender)
  BookArchivist:DebugPrint("  message length:", #message)
  
  if not AceSerializer then 
    BookArchivist:DebugPrint("|cFFFF0000[ChatLinks DEBUG]|r AceSerializer not available")
    return 
  end
  
  local success, data = AceSerializer:Deserialize(message)
  if not success or type(data) ~= "table" then 
    BookArchivist:DebugPrint("|cFFFF0000[ChatLinks DEBUG]|r Deserialize failed or not a table:", success, type(data))
    return 
  end
  
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Deserialized message type:", data.m)
  
  local L = BookArchivist.L or {}
  
  if data.m == "request" then
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Received request for:", data.title)
    -- Someone is requesting a book from us
    ChatLinks:HandleBookRequest(sender, data.title)
    
  elseif data.m == "response" then
    BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Received response")
    -- We received book data - clear loading state immediately
    tooltipLoading = false
    receivedData = true
    
    -- Hide any tooltip that might be showing (including timeout message)
    if ItemRefTooltip:IsVisible() then
      ItemRefTooltip:Hide()
    end
    
    if data.bookData then
      BookArchivist:DebugPrint("|cFF00FF00[ChatLinks DEBUG]|r Response contains book data, showing import dialog")
      ItemRefTooltip:Hide()
      ChatLinks:ShowImportWithData(data.bookData)
    elseif data.error then
      BookArchivist:DebugPrint("|cFFFF0000[ChatLinks DEBUG]|r Response contains error:", data.error)
      ChatLinks:ShowTooltip({
        {1, "BookArchivist", 0.29, 0.49, 0.73},
        {1, data.error, 1, 0, 0}
      })
    end
  end
end

-- Handle book request from another player
function ChatLinks:HandleBookRequest(sender, bookTitle)
  local count = 0
  for _ in pairs(linkedBooks) do count = count + 1 end
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r HandleBookRequest called:")
  BookArchivist:DebugPrint("  sender:", sender)
  BookArchivist:DebugPrint("  bookTitle:", bookTitle)
  BookArchivist:DebugPrint("  linkedBooks count:", count)
  
  -- Find the book by title in our linked books
  local foundBook = nil
  local expiredTime = GetTime() - LINK_VALIDITY_DURATION
  
  BookArchivist:DebugPrint("|cFF4A7EBB[ChatLinks DEBUG]|r Searching linkedBooks:")
  for bookId, entry in pairs(linkedBooks) do
    BookArchivist:DebugPrint("  checking bookId:", bookId)
    BookArchivist:DebugPrint("    timestamp:", entry.timestamp, "expired at:", expiredTime)
    if entry.timestamp > expiredTime then
      local data = entry.data
      BookArchivist:DebugPrint("    title:", data and data.title or "nil")
      if data and data.title == bookTitle then
        BookArchivist:DebugPrint("|cFF00FF00[ChatLinks DEBUG]|r Found matching book!")
        foundBook = data
        break
      end
    else
      BookArchivist:DebugPrint("    expired")
    end
  end
  
  local response = { m = "response" }
  
  if foundBook then
    BookArchivist:DebugPrint("|cFF00FF00[ChatLinks DEBUG]|r Sending book data to", sender)
    response.bookData = foundBook
  else
    BookArchivist:DebugPrint("|cFFFF0000[ChatLinks DEBUG]|r Book not found, sending error")
    local L = BookArchivist.L or {}
    response.error = L["BOOK_NOT_AVAILABLE"] or "Book no longer available for sharing"
  end
  
  if AceSerializer and AceComm then
    local serialized = AceSerializer:Serialize(response)
    AceComm:SendCommMessage("BookArchivist", serialized, "WHISPER", sender)
  end
end

-- Show import prompt with data already loaded
function ChatLinks:ShowImportWithData(bookData)
  -- Hide share dialog if it's open (prevents overlap when clicking your own link)
  local shareFrame = _G["BookArchivistShareFrame"]
  if shareFrame and shareFrame:IsShown() then
    shareFrame:Hide()
  end
  
  if not self.importPrompt then
    self:CreateImportPrompt()
  end
  
  local L = BookArchivist.L or {}
  
  -- Update title
  self.promptTitle:SetText(string.format(
    L["IMPORT_PROMPT_TITLE_WITH_DATA"] or "Import: %s",
    bookData.title or "Book"
  ))
  
  -- Store book data
  self.importPrompt.pendingBook = bookData
  self.importPrompt.bookTitle = bookData.title
  
  -- Hide instructions text (for manual paste)
  if self.promptInstructions then
    self.promptInstructions:Hide()
  end
  
  -- Hide editbox and show confirmation message
  if self.promptEditBox and self.promptEditBox.frame then
    self.promptEditBox.frame:Hide()
  end
  
  if not self.importPrompt.confirmText then
    local confirmText = self.importPrompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    confirmText:SetPoint("TOP", self.promptTitle, "BOTTOM", 0, -20)
    confirmText:SetWidth(450)
    confirmText:SetJustifyH("LEFT")
    self.importPrompt.confirmText = confirmText
  end
  
  local confirmMsg = (L["IMPORT_CONFIRM_MESSAGE"] or "Book received! Click Import to add '%s' to your library."):format(bookData.title or "this book")
  self.importPrompt.confirmText:SetText(confirmMsg)
  self.importPrompt.confirmText:Show()
  
  -- Show prompt
  self.importPrompt:Show()
end

-- Create the import prompt dialog
function ChatLinks:CreateImportPrompt()
  local L = BookArchivist.L or {}
  
  local prompt = CreateFrame("Frame", "BookArchivistImportPrompt", UIParent, "BackdropTemplate")
  prompt:SetSize(500, 300)
  prompt:SetPoint("CENTER")
  prompt:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  prompt:SetBackdropColor(0, 0, 0, 1)
  prompt:EnableMouse(true)
  prompt:SetMovable(true)
  prompt:RegisterForDrag("LeftButton")
  prompt:SetScript("OnDragStart", prompt.StartMoving)
  prompt:SetScript("OnDragStop", prompt.StopMovingOrSizing)
  prompt:SetFrameStrata("DIALOG")
  prompt:Hide()
  
  -- Close on ESC
  prompt:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      self:Hide()
    end
  end)
  
  -- Title
  local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -20)
  title:SetText(L["IMPORT_PROMPT_TITLE"] or "Import Book")
  self.promptTitle = title
  
  -- Instructions
  local instructions = prompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  instructions:SetPoint("TOP", title, "BOTTOM", 0, -10)
  instructions:SetWidth(450)
  instructions:SetJustifyH("LEFT")
  local instructionText = (L["IMPORT_PROMPT_TEXT"] or "Paste the book export string below:") .. "\n\n" ..
    (L["IMPORT_PROMPT_HINT"] or "The sender must share the full export string with you separately (outside WoW chat).")
  instructions:SetText(instructionText)
  self.promptInstructions = instructions
  
  -- Edit box for paste
  local editBox
  local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
  
  if AceGUI then
    -- Use AceGUI MultiLineEditBox
    local aceEditBox = AceGUI:Create("MultiLineEditBox")
    aceEditBox:SetLabel("")
    aceEditBox:SetWidth(460)
    aceEditBox:SetHeight(150)
    aceEditBox.frame:SetParent(prompt)
    aceEditBox.frame:SetPoint("TOP", instructions, "BOTTOM", 0, -10)
    aceEditBox:DisableButton(true)
    editBox = aceEditBox
  else
    -- Native fallback
    local scroll = CreateFrame("ScrollFrame", nil, prompt, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOP", instructions, "BOTTOM", 0, -10)
    scroll:SetSize(440, 150)
    
    editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlight)
    editBox:SetWidth(420)
    editBox:SetScript("OnEscapePressed", function()
      editBox:ClearFocus()
      prompt:Hide()
    end)
    scroll:SetScrollChild(editBox)
  end
  
  self.promptEditBox = editBox
  
  -- Import button
  local importBtn = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
  importBtn:SetSize(100, 22)
  importBtn:SetPoint("BOTTOM", 50, 20)
  importBtn:SetText(L["IMPORT_PROMPT_BUTTON"] or "Import")
  importBtn:SetScript("OnClick", function()
    self:DoImport()
  end)
  
  -- Cancel button
  local cancelBtn = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
  cancelBtn:SetSize(100, 22)
  cancelBtn:SetPoint("BOTTOM", -50, 20)
  cancelBtn:SetText(CANCEL or "Cancel")
  cancelBtn:SetScript("OnClick", function()
    prompt:Hide()
  end)
  
  self.importPrompt = prompt
end

-- Perform the import
function ChatLinks:DoImport()
  local L = BookArchivist.L or {}
  local text = nil
  local pendingBook = self.importPrompt.pendingBook
  
  -- Check if we have pre-loaded data (from auto-transmission)
  if pendingBook then
    -- We have the book data already, just process it via the import worker
    -- The import worker expects a BDB1 string, so we need to serialize the book data
    -- For now, we'll pass the raw book data and handle it specially
    -- TODO: Update import worker to accept raw book data
    
    -- For now, show success message
    local bookTitle = self.importPrompt.bookTitle or "book"
    local successMsg = L["IMPORT_SUCCESS"] or "Imported: %s"
    BookArchivist:DebugPrint("|cFF4A7EBBBookArchivist:|r " .. successMsg:format(bookTitle))
    
    -- TODO: Actually import the book data
    -- This will require adding the book to the database
    
    -- Refresh UI if open
    if BookArchivist.UI and BookArchivist.UI.RefreshBookList then
      BookArchivist.UI:RefreshBookList()
    end
    
    self.importPrompt:Hide()
    self.importPrompt.pendingBook = nil
    return
  end
  
  -- Manual import: get text from editbox
  if self.promptEditBox and self.promptEditBox.GetText then
    text = self.promptEditBox:GetText()
  else
    BookArchivist:DebugPrint("|cFFFF0000BookArchivist:|r " .. (L["IMPORT_FAILED"]:format("No text provided") or "Import failed: No text provided"))
    return
  end
  
  if not text or text == "" then
    BookArchivist:DebugPrint("|cFFFF0000BookArchivist:|r " .. (L["IMPORT_FAILED"]:format("No text provided") or "Import failed: No text provided"))
    return
  end
  
  -- Normalize editbox paste (pipes are escaped as ||)
  text = text:gsub("||", "|")
  
  -- Use existing import worker
  local ImportWorker = BookArchivist.ImportWorker
  if not ImportWorker then
    BookArchivist:DebugPrint("|cFFFF0000BookArchivist:|r " .. (L["IMPORT_FAILED"]:format("Import system unavailable") or "Import failed: Import system unavailable"))
    return
  end
  
  local worker = ImportWorker:New(UIParent)
  
  worker.onDone = function(stats)
    local bookTitle = self.importPrompt.bookTitle or "book"
    if stats and (stats.newCount or 0) > 0 then
      local successMsg = L["IMPORT_SUCCESS"] or "Imported: %s"
      BookArchivist:DebugPrint("|cFF4A7EBBBookArchivist:|r " .. successMsg:format(bookTitle))
    else
      local warningMsg = L["IMPORT_COMPLETED_WITH_WARNINGS"] or "Import completed with warnings"
      BookArchivist:DebugPrint("|cFFFFAA00BookArchivist:|r " .. warningMsg)
    end
    
    -- Refresh UI if open
    if BookArchivist.UI and BookArchivist.UI.RefreshBookList then
      BookArchivist.UI:RefreshBookList()
    end
    
    self.importPrompt:Hide()
    self.importPrompt.pendingBook = nil
  end
  
  worker.onError = function(err)
    local errorMsg = L["IMPORT_FAILED"] or "Import failed: %s"
    BookArchivist:DebugPrint("|cFFFF0000BookArchivist:|r " .. errorMsg:format(err or "unknown error"))
    self.importPrompt:Hide()
    self.importPrompt.pendingBook = nil
  end
  
  worker:Start(text)
end

-- Initialize chat links system
function ChatLinks:Init()
  InstallChatFilters()
  
  -- Register AceComm handler
  if AceComm then
    AceComm:RegisterComm("BookArchivist", HandleComm)
  end
end

return ChatLinks
