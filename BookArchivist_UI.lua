---@diagnostic disable: undefined-global
-- BookArchivist_UI.lua
-- Simple in-game UI to browse stored books and re-read them.

local function ensureAddon()
  if not BookArchivist or not BookArchivist.GetDB then
    return nil
  end
  return BookArchivist
end

local cachedAddon = ensureAddon()

local function getAddon()
  if cachedAddon and cachedAddon.GetDB then
    return cachedAddon
  end
  cachedAddon = ensureAddon()
  return cachedAddon
end

local ViewModel = {
  filteredKeys = {},
  selectedKey = nil,
}

local function setSelectedKey(key)
  ViewModel.selectedKey = key
end

local function getSelectedKey()
  return ViewModel.selectedKey
end

local function getFilteredKeys()
  return ViewModel.filteredKeys
end

local function fmtTime(ts)
  if not ts then return "" end
  return date("%Y-%m-%d %H:%M", ts)
end

local UI -- forward declaration so helper functions can reference the frame
local refreshAll -- forward declaration for lazy init callbacks

local function formatZoneText(chain)
  if not chain or #chain == 0 then
    return "Unknown Zone"
  end
  return table.concat(chain, " > ")
end

local function formatLocationLine(loc)
  if not loc then return nil end
  local zoneText = loc.zoneText and loc.zoneText ~= "" and loc.zoneText or formatZoneText(loc.zoneChain)
  if loc.context == "loot" then
    local mob = loc.mobName or "Unknown Mob"
    return string.format("|cFFFFD100Looted:|r %s > %s", zoneText, mob)
  else
    return string.format("|cFFFFD100Location:|r %s", zoneText)
  end
end

local function isHTMLContent(text)
  if not text or text == "" then return false end
  local lowered = text:lower()
  return lowered:find("<%s*html", 1, false)
    or lowered:find("<%s*body", 1, false)
    or lowered:find("<img", 1, false)
    or lowered:find("<table", 1, false)
    or lowered:find("<h%d", 1, false)
end

local function stripHTMLTags(text)
  if not text or text == "" then
    return text or ""
  end
  local cleaned = text:gsub("<[^>]+>", "")
  cleaned = cleaned:gsub("%s+", function(match)
    if #match > 2 then
      return "\n"
    end
    return " "
  end)
  return cleaned
end

local function logError(message)
  local formatted = "|cFFFF0000BookArchivist:|r " .. (message or "Unknown error")
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(formatted)
  elseif print then
    print(formatted)
  end
end

local function safeCreateFrame(frameType, name, parent, ...)
  if not CreateFrame then
    logError(string.format("CreateFrame missing; unable to build '%s'", name or frameType))
    return nil
  end

  local templates = { ... }
  local lastErr
  for i = 1, #templates do
    local template = templates[i]
    if template then
      local ok, frameOrErr = pcall(CreateFrame, frameType, name, parent, template)
      if ok and frameOrErr then
        return frameOrErr
      elseif not ok then
        lastErr = frameOrErr
      end
    end
  end

  local ok, frameOrErr = pcall(CreateFrame, frameType, name, parent)
  if ok and frameOrErr then
    return frameOrErr
  end

  lastErr = lastErr or frameOrErr or "unknown failure"
  logError(string.format("Unable to create frame '%s' (%s). %s", name or "unnamed", frameType, tostring(lastErr)))
  return nil
end

local function updateReaderHeight(height)
  if not UI or not UI.textChild then return end
  UI.textChild:SetHeight(math.max(1, (height or 0) + 20))
end

local function renderBookContent(text)
  if not UI or not UI.textPlain then
    return
  end
  text = text or ""
  local hasHTMLMarkup = isHTMLContent(text)
  local htmlWidget = UI.htmlText
  local canRenderHTML = htmlWidget ~= nil and hasHTMLMarkup
  if canRenderHTML and htmlWidget then
    UI.textPlain:Hide()
    htmlWidget:Show()
    htmlWidget:SetWidth(460)
    htmlWidget:SetText(text)
    local htmlHeight = htmlWidget.GetContentHeight and htmlWidget:GetContentHeight() or htmlWidget:GetHeight()
    updateReaderHeight(htmlHeight)
  else
    if htmlWidget then
      htmlWidget:Hide()
    end
    UI.textPlain:Show()
    UI.textPlain:SetWidth(460)
    local displayText
    if hasHTMLMarkup and not canRenderHTML then
      displayText = stripHTMLTags(text)
    else
      displayText = text
    end
    UI.textPlain:SetText(displayText)
    local plainHeight = UI.textPlain:GetStringHeight()
    updateReaderHeight(plainHeight)
  end
end

local initializationError

local ROW_H = 44

local function setupUI()
  if UI then
    return true
  end

  if not CreateFrame or not UIParent then
    return false, "Blizzard UI not ready yet. Please try again after entering the world."
  end

  local frame = safeCreateFrame("Frame", "BookArchivistFrame", UIParent, "PortraitFrameTemplate", "ButtonFrameTemplate")
  if not frame then
    return false, "Unable to create BookArchivist frame."
  end

  UI = frame
  UI:SetSize(900, 600)
  UI:SetPoint("CENTER")
  UI:Hide()
  UI:SetMovable(true)
  UI:EnableMouse(true)
  UI:RegisterForDrag("LeftButton")
  UI:SetScript("OnDragStart", UI.StartMoving)
  UI:SetScript("OnDragStop", UI.StopMovingOrSizing)
  UI:SetClampedToScreen(true)

  -- Set portrait (handle different template versions)
  if UI.PortraitContainer and UI.PortraitContainer.portrait then
    UI.portrait = UI.PortraitContainer.portrait
    UI.portrait:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  elseif UI.portrait then
    UI.portrait:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  end

  -- Title using built-in TitleText
  if UI.TitleText then
    UI.TitleText:SetText("Book Archivist")
  end

  -- Search box container (like mount filter area)
  local searchContainer = CreateFrame("Frame", nil, UI)
  searchContainer:SetPoint("TOPLEFT", UI, "TOPLEFT", 58, -28)
  searchContainer:SetPoint("TOPRIGHT", UI, "TOPRIGHT", -30, -28)
  searchContainer:SetHeight(32)

  UI.searchBox = safeCreateFrame("EditBox", nil, searchContainer, "SearchBoxTemplate", "InputBoxTemplate")
  if not UI.searchBox then
    return false, "Unable to create search box widget."
  end
  UI.searchBox:SetSize(200, 20)
  UI.searchBox:SetPoint("LEFT", 0, 0)
  UI.searchBox:SetAutoFocus(false)

  if UI.searchBox.Instructions then
    UI.searchBox.Instructions:SetText("Search books...")
  end

  local searchLabel = searchContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  searchLabel:SetPoint("LEFT", UI.searchBox, "RIGHT", 10, 0)
  searchLabel:SetText("|cFFFFD100Title, Creator, or Text|r")

  -- Left list block (like mount list)
  local listBlock = safeCreateFrame("Frame", nil, UI, "InsetFrameTemplate")
  if not listBlock then
    return false, "Unable to create book list panel."
  end
  listBlock:SetPoint("TOPLEFT", UI, "TOPLEFT", 4, -65)
  listBlock:SetSize(365, 485)

  -- Header inside the list block
  local listHeader = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  listHeader:SetPoint("TOPLEFT", listBlock, "TOPLEFT", 8, -8)
  listHeader:SetText("Saved Books")

  -- Separator line below header
  local listSeparator = listBlock:CreateTexture(nil, "ARTWORK")
  listSeparator:SetHeight(1)
  listSeparator:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", -4, -4)
  listSeparator:SetPoint("TOPRIGHT", listBlock, "TOPRIGHT", -8, -28)
  listSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)

  -- Modern ScrollFrame list with dynamic buttons
  UI.scrollFrame = safeCreateFrame("ScrollFrame", "BookArchivistListScroll", listBlock, "UIPanelScrollFrameTemplate")
  if not UI.scrollFrame then
    return false, "Unable to create list scroll frame."
  end
  UI.scrollFrame:SetPoint("TOPLEFT", listSeparator, "BOTTOMLEFT", 4, -4)
  UI.scrollFrame:SetPoint("BOTTOMRIGHT", listBlock, "BOTTOMRIGHT", -28, 28)

  UI.scrollChild = CreateFrame("Frame", nil, UI.scrollFrame)
  UI.scrollFrame:SetScrollChild(UI.scrollChild)
  UI.scrollChild:SetSize(336, 1)

  -- Right reader block (like mount details panel)
  local readerBlock = safeCreateFrame("Frame", nil, UI, "InsetFrameTemplate")
  if not readerBlock then
    return false, "Unable to create reader panel."
  end
  readerBlock:SetPoint("TOPLEFT", listBlock, "TOPRIGHT", 4, 0)
  readerBlock:SetPoint("BOTTOMRIGHT", UI, "BOTTOMRIGHT", -6, 4)

  -- Header inside the reader block
  local readerHeader = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  readerHeader:SetPoint("TOPLEFT", readerBlock, "TOPLEFT", 8, -8)
  readerHeader:SetText("Book Reader")

  -- Separator line below header
  local readerSeparator = readerBlock:CreateTexture(nil, "ARTWORK")
  readerSeparator:SetHeight(1)
  readerSeparator:SetPoint("TOPLEFT", readerHeader, "BOTTOMLEFT", -4, -4)
  readerSeparator:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -8, -28)
  readerSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)

  UI.bookTitle = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  UI.bookTitle:SetPoint("TOPLEFT", readerSeparator, "BOTTOMLEFT", 4, -8)
  UI.bookTitle:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -12, -36)
  UI.bookTitle:SetJustifyH("LEFT")
  UI.bookTitle:SetText("Select a book from the list")
  UI.bookTitle:SetTextColor(1, 0.82, 0)

  UI.meta = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  UI.meta:SetPoint("TOPLEFT", UI.bookTitle, "BOTTOMLEFT", 0, -6)
  UI.meta:SetPoint("TOPRIGHT", UI.bookTitle, "BOTTOMRIGHT", 0, -6)
  UI.meta:SetJustifyH("LEFT")
  UI.meta:SetText("")

  -- Divider line
  local divider = readerBlock:CreateTexture(nil, "ARTWORK")
  divider:SetHeight(1)
  divider:SetPoint("TOPLEFT", UI.meta, "BOTTOMLEFT", -4, -8)
  divider:SetPoint("TOPRIGHT", UI.meta, "BOTTOMRIGHT", 4, -8)
  divider:SetColorTexture(0.25, 0.25, 0.25, 0.5)

  -- Text scroll with parchment style
  UI.textScroll = safeCreateFrame("ScrollFrame", "BookArchivistTextScroll", readerBlock, "UIPanelScrollFrameTemplate")
  if not UI.textScroll then
    return false, "Unable to create reader scroll frame."
  end
  UI.textScroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 4, -6)
  UI.textScroll:SetPoint("BOTTOMRIGHT", readerBlock, "BOTTOMRIGHT", -28, 40)

  UI.textChild = CreateFrame("Frame", nil, UI.textScroll)
  UI.textChild:SetSize(1, 1)
  UI.textScroll:SetScrollChild(UI.textChild)

  UI.textPlain = UI.textChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  UI.textPlain:SetPoint("TOPLEFT", 6, -6)
  UI.textPlain:SetJustifyH("LEFT")
  UI.textPlain:SetJustifyV("TOP")
  UI.textPlain:SetSpacing(2)
  UI.textPlain:SetWidth(460)

  local htmlFrame
  local htmlCreated = pcall(function()
    htmlFrame = CreateFrame("SimpleHTML", nil, UI.textChild)
  end)

  if htmlCreated and htmlFrame then
    UI.htmlText = htmlFrame
    UI.htmlText:SetPoint("TOPLEFT", 6, -6)
    UI.htmlText:SetPoint("TOPRIGHT", -12, -6)
    UI.htmlText:SetFontObject("GameFontNormal")
    UI.htmlText:SetSpacing(2)
    UI.htmlText:SetWidth(460)
    UI.htmlText:Hide()
  else
    UI.htmlText = nil
  end

  -- Delete button with red theme
  UI.deleteBtn = safeCreateFrame("Button", nil, readerBlock, "UIPanelButtonTemplate", "OptionsButtonTemplate")
  if not UI.deleteBtn then
    return false, "Unable to create delete button."
  end
  UI.deleteBtn:SetSize(100, 22)
  UI.deleteBtn:SetPoint("BOTTOMLEFT", readerBlock, "BOTTOMLEFT", 12, 10)
  UI.deleteBtn:SetText("Delete")
  UI.deleteBtn:SetNormalFontObject("GameFontNormal")
  UI.deleteBtn:Disable()

  UI.deleteBtn:SetScript("OnEnter", function(self)
    if self:IsEnabled() then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Delete this book", 1, 1, 1)
      GameTooltip:AddLine("This will permanently remove the book from your archive.", 1, 0.82, 0, true)
      GameTooltip:Show()
    end
  end)

  UI.deleteBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Book count display
  UI.countText = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  UI.countText:SetPoint("BOTTOM", readerBlock, "BOTTOM", 0, 10)
  UI.countText:SetText("|cFF888888Books saved as you read them in-game|r")

  -- Info text in list block (below the list)
  UI.infoText = listBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  UI.infoText:SetPoint("BOTTOM", listBlock, "BOTTOM", 0, 6)
  UI.infoText:SetText("|cFF00FF00Tip:|r Open books normally - pages save automatically")

  -- Wire scroll and input handlers
  UI.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = math.max(0, math.min(maxScroll, current - (delta * ROW_H * 3)))
    self:SetVerticalScroll(newScroll)
  end)

  UI.searchBox:SetScript("OnTextChanged", function(self)
    if self.Instructions then
      if self:GetText() ~= "" then
        self.Instructions:Hide()
      else
        self.Instructions:Show()
      end
    end
    rebuildFiltered()
    updateList()
  end)

  UI.deleteBtn:SetScript("OnClick", function()
    local addon = getAddon()
    if not addon then return end
    local key = getSelectedKey()
    if key then
      addon:Delete(key)
      setSelectedKey(nil)
      rebuildFiltered()
      updateList()
      renderSelected()
    end
  end)

  UI:SetScript("OnShow", function()
    local success, err = pcall(refreshAll)
    if not success then
      logError("Error refreshing UI: " .. tostring(err))
    end
  end)

  refreshAll()
  return true
end

local function ensureUI()
  if UI then
    return true
  end

  local ok, err = setupUI()
  if not ok then
    initializationError = err or "BookArchivist UI failed to initialize."
    return false, initializationError
  end

  initializationError = nil
  return true
end

local ButtonPool = {
  free = {},
  active = {},
}

-- Forward declare functions that will be used in button callbacks
local renderSelected, updateList

local function entryToDisplay(entry)
  local title = entry.title or "(Untitled)"
  local creator = entry.creator or ""
  local seen = entry.seenCount or 1
  
  -- Color the title based on material or default gold
  local titleColor = "|cFFFFD100"
  if entry.material and entry.material:lower():find("parchment") then
    titleColor = "|cFFE6CC80"
  end
  
  local result = titleColor .. title .. "|r"
  
  if creator ~= "" then
    result = result .. "\n|cFF999999   " .. creator .. "|r"
  end
  
  if seen > 1 then
    result = result .. " |cFF666666(" .. seen .. "x)|r"
  end
  
  return result
end

local function makeRow()
  local b = CreateFrame("Button", nil, UI.scrollChild)
  b:SetSize(340, ROW_H)

  -- Background with alternating color support
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints(true)
  b.bg:SetColorTexture(0, 0, 0, 0)

  -- Highlight texture
  b.highlight = b:CreateTexture(nil, "HIGHLIGHT")
  b.highlight:SetAllPoints(true)
  -- Try to use atlas, fallback to color if it fails
  local hasAtlas = pcall(function() b.highlight:SetAtlas("search-highlight") end)
  if not hasAtlas then
    b.highlight:SetColorTexture(1, 1, 1, 0.1)
  end
  b.highlight:SetAlpha(0.5)

  -- Selection glow
  b.selected = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  b.selected:SetAllPoints(true)
  -- Try to use atlas, fallback to color if it fails
  local hasSelAtlas = pcall(function() b.selected:SetAtlas("groupfinder-button-cover") end)
  if not hasSelAtlas then
    b.selected:SetColorTexture(0.2, 0.4, 0.8, 0.3)
  end
  b.selected:SetAlpha(0.7)
  b.selected:Hide()

  -- Selection edge
  b.selectedEdge = b:CreateTexture(nil, "OVERLAY")
  b.selectedEdge:SetSize(2, ROW_H - 2)
  b.selectedEdge:SetPoint("LEFT", 2, 0)
  b.selectedEdge:SetColorTexture(1, 0.82, 0, 1)
  b.selectedEdge:Hide()

  b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  b.text:SetPoint("TOPLEFT", 10, -6)
  b.text:SetPoint("BOTTOMRIGHT", -10, 6)
  b.text:SetJustifyH("LEFT")
  b.text:SetJustifyV("TOP")
  b.text:SetWordWrap(true)
  b.text:SetMaxLines(2)

  b:SetScript("OnClick", function(self)
    if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
    setSelectedKey(self.bookKey)
    renderSelected()
    updateList()
  end)

  return b
end

local function resetButton(button)
  button:Hide()
  button:ClearAllPoints()
  button.bookKey = nil
  if button.selected then button.selected:Hide() end
  if button.selectedEdge then button.selectedEdge:Hide() end
end

function ButtonPool:Acquire()
  local button = table.remove(self.free)
  if not button then
    button = makeRow()
  end
  button:Show()
  table.insert(self.active, button)
  return button
end

function ButtonPool:ReleaseAll()
  for _, button in ipairs(self.active) do
    resetButton(button)
    table.insert(self.free, button)
  end
  wipe(self.active)
end


local function matches(entry, q)
  if q == "" then return true end
  q = q:lower()

  local function has(s)
    s = (s or ""):lower()
    return s:find(q, 1, true) ~= nil
  end

  if has(entry.title) or has(entry.creator) or has(entry.author) then
    return true
  end

  if entry.pages then
    for _, t in pairs(entry.pages) do
      if has(t) then return true end
    end
  end
  return false
end

local function rebuildFiltered()
  if not UI or not UI.deleteBtn then return end
  local filtered = getFilteredKeys()
  wipe(filtered)
  UI.deleteBtn:Disable()

  local addon = getAddon()
  if not addon then return end
  local db = addon:GetDB()
  local q = (UI.searchBox and UI.searchBox:GetText()) or ""
  q = q:gsub("^%s+", ""):gsub("%s+$", "")

  local selectedKey = getSelectedKey()
  local selectionStillValid = false

  for _, key in ipairs(db.order or {}) do
    local e = db.books[key]
    if e and matches(e, q) then
      table.insert(filtered, key)
      if key == selectedKey then
        selectionStillValid = true
      end
    end
  end

  if selectedKey and not selectionStillValid then
    setSelectedKey(nil)
  end
end

-- Define renderSelected function
function renderSelected()
  if not UI or not UI.deleteBtn then return end
  local addon = getAddon()
  if not addon then return end
  local db = addon:GetDB()

  local key = getSelectedKey()
  local entry = key and db.books[key] or nil
  if not entry then
    UI.bookTitle:SetText("Select a book from the list")
    UI.bookTitle:SetTextColor(0.5, 0.5, 0.5)
    UI.meta:SetText("")
    renderBookContent("")
    UI.deleteBtn:Disable()
    UI.countText:SetText("|cFF888888Books saved as you read them in-game|r")
    return
  end

  UI.bookTitle:SetText(entry.title or "(Untitled Book)")
  UI.bookTitle:SetTextColor(1, 0.82, 0)

  local meta = {}
  if entry.creator and entry.creator ~= "" then 
    table.insert(meta, "|cFFFFD100Creator:|r " .. entry.creator) 
  end
  if entry.material and entry.material ~= "" then 
    table.insert(meta, "|cFFFFD100Material:|r " .. entry.material) 
  end
  if entry.seenCount and entry.seenCount > 1 then
    table.insert(meta, "|cFFFFD100Read:|r " .. entry.seenCount .. "x")
  end
  if entry.lastSeenAt then 
    table.insert(meta, "|cFFFFD100Last viewed:|r " .. fmtTime(entry.lastSeenAt)) 
  end
  local locationLine = formatLocationLine(entry.location)
  if locationLine then
    table.insert(meta, locationLine)
  end
  UI.meta:SetText(table.concat(meta, "  |cFF666666•|r  "))

  -- Assemble pages in order
  local textParts = {}
  if entry.pages then
    local nums = {}
    for n, _ in pairs(entry.pages) do
      if type(n) == "number" then table.insert(nums, n) end
    end
    table.sort(nums)
    for _, n in ipairs(nums) do
      local t = entry.pages[n]
      if t and t ~= "" then
        if #nums > 1 then
          table.insert(textParts, string.format("|cFFD4A017— Page %d —|r\n\n%s", n, t))
        else
          table.insert(textParts, t)
        end
      end
    end
  end

  local fullText = table.concat(textParts, "\n\n\n")
  if fullText == "" then
    fullText = "|cFF888888No content available|r"
  end
  renderBookContent(fullText)

  UI.deleteBtn:Enable()
  
  -- Update count text
  local pageCount = entry.pages and 0 or 0
  if entry.pages then
    for _ in pairs(entry.pages) do
      pageCount = pageCount + 1
    end
  end
  UI.countText:SetText(string.format("|cFFFFD100%d|r page%s", pageCount, pageCount ~= 1 and "s" or ""))
end

-- Define updateList function
function updateList()
  if not UI or not UI.scrollChild or not UI.infoText then
    return
  end
  local addon = getAddon()
  if not addon then return end
  local db = addon:GetDB()
  local filtered = getFilteredKeys()
  local total = #filtered

  ButtonPool:ReleaseAll()

  -- Set scroll child height
  local totalHeight = math.max(1, total * ROW_H)
  UI.scrollChild:SetSize(336, totalHeight)

  -- Create buttons for all items
  for i = 1, total do
    local button = ButtonPool:Acquire()
    button:SetPoint("TOPLEFT", 0, -(i-1) * ROW_H)
    
    local key = filtered[i]
    if key then
      local entry = db.books[key]
      if entry then
        button.bookKey = key
        button.text:SetText(entryToDisplay(entry))
        
        -- Show selection
        if key == getSelectedKey() then
          button.selected:Show()
          button.selectedEdge:Show()
        else
          button.selected:Hide()
          button.selectedEdge:Hide()
        end
      end
    end
  end
  
  -- Update count display
  local countText = string.format("|cFFFFD100%d|r book%s", total, total ~= 1 and "s" or "")
  if total ~= #(db.order or {}) then
    countText = countText .. string.format(" (filtered from |cFFFFD100%d|r)", #(db.order or {}))
  end
  UI.infoText:SetText(countText)
end

local function refreshAll()
  if not UI then
    return
  end
  rebuildFiltered()
  updateList()
  renderSelected()
end

local function toggleUI()
  local ok, err = ensureUI()
  if not ok then
    logError(err or "BookArchivist UI unavailable.")
    return
  end

  if UI:IsShown() then
    UI:Hide()
  else
    refreshAll()
    UI:Show()
  end
end

SLASH_BOOKARCHIVIST1 = "/ba"
SLASH_BOOKARCHIVIST2 = "/bookarchivist"
SlashCmdList = SlashCmdList or {}
SlashCmdList["BOOKARCHIVIST"] = function()
  local ok, err = pcall(toggleUI)
  if not ok then
    logError(tostring(err))
  end
end

local loadMessageShown = false

local function tryInitializeAndAnnounce()
  local ok, err = ensureUI()
  if not ok then
    if not err or not err:find("not ready") then
      logError(err or "BookArchivist UI unavailable.")
    end
    return
  end

  if not loadMessageShown then
    loadMessageShown = true
    if print then
      print("|cFF00FF00BookArchivist UI loaded.|r Type /ba to open.")
    end
  end
end

if CreateFrame then
  local loadFrame = CreateFrame("Frame")
  loadFrame:RegisterEvent("PLAYER_LOGIN")
  loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  loadFrame:SetScript("OnEvent", function(self, event)
    tryInitializeAndAnnounce()
    if event == "PLAYER_LOGIN" then
      self:UnregisterEvent("PLAYER_LOGIN")
    end
    if loadMessageShown then
      self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
  end)
end

if type(IsLoggedIn) == "function" and IsLoggedIn() then
  tryInitializeAndAnnounce()
end
