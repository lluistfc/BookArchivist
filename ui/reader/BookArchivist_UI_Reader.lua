---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = {}
BookArchivist.UI.Reader = ReaderUI

local ctx
local state = ReaderUI.__state or {}
ReaderUI.__state = state
state.pageOrder = state.pageOrder or {}
state.currentPageIndex = state.currentPageIndex or 1
state.currentEntryKey = state.currentEntryKey or nil

local function rememberWidget(name, widget)
  if ctx and ctx.rememberWidget then
    return ctx.rememberWidget(name, widget)
  end
  return widget
end
ReaderUI.__rememberWidget = rememberWidget

local function getWidget(name)
  if ctx and ctx.getWidget then
    return ctx.getWidget(name)
  end
end
ReaderUI.__getWidget = getWidget

local function getAddon()
  if ctx and ctx.getAddon then
    return ctx.getAddon()
  end
end
ReaderUI.__getAddon = getAddon

local function fmtTime(ts)
  if ctx and ctx.fmtTime then
    return ctx.fmtTime(ts)
  end
  return ""
end

local function formatLocationLine(loc)
  if ctx and ctx.formatLocationLine then
    return ctx.formatLocationLine(loc)
  end
  return nil
end

local function fallbackDebugPrint(...)
  BookArchivist:DebugPrint(...)
end

local function debugPrint(...)
  local logger = (ctx and ctx.debugPrint) or fallbackDebugPrint
  logger(...)
end

local function logError(message)
  if ctx and ctx.logError then
    ctx.logError(message)
  end
end

local function safeCreateFrame(frameType, name, parent, ...)
  if ctx and ctx.safeCreateFrame then
    return ctx.safeCreateFrame(frameType, name, parent, ...)
  end
  return nil
end
ReaderUI.__safeCreateFrame = safeCreateFrame

local function getSelectedKey()
  if ctx and ctx.getSelectedKey then
    return ctx.getSelectedKey()
  end
end
ReaderUI.__getSelectedKey = getSelectedKey

local function setSelectedKey(key)
  if ctx and ctx.setSelectedKey then
    ctx.setSelectedKey(key)
  end
end
ReaderUI.__setSelectedKey = setSelectedKey

local function chatMessage(msg)
  if ctx and ctx.chatMessage then
    ctx.chatMessage(msg)
  elseif DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(msg)
  end
end
ReaderUI.__chatMessage = chatMessage

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

local function getDeleteButton()
  if state.deleteButton and state.deleteButton.IsObjectType and state.deleteButton:IsObjectType("Button") then
    return state.deleteButton
  end
  local ensureFn = ReaderUI.__ensureDeleteButton
  if ensureFn then
    state.deleteButton = ensureFn()
  end
  return state.deleteButton
end

local function updateReaderHeight(height)
  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local child = state.textChild
  if not child then return end
  child:SetHeight(math.max(1, (height or 0) + 20))
end

local function getContentWidth()
  if state.readerBlock and state.readerBlock.GetWidth then
    return math.max(320, state.readerBlock:GetWidth() - 48)
  end
  return 460
end

local function buildPageOrder(entry)
  local order = {}
  if entry and entry.pages then
    for pageNum in pairs(entry.pages) do
      if type(pageNum) == "number" then
        table.insert(order, pageNum)
      end
    end
  end
  table.sort(order)
  return order
end

local function clampPageIndex(order, index)
  if not order or #order == 0 then
    return 1
  end
  index = index or 1
  if index < 1 then
    return 1
  end
  if index > #order then
    return #order
  end
  return index
end

local function renderBookContent(text)
  if not state.textPlain then
    state.textPlain = getWidget("textPlain")
  end
  local plain = state.textPlain
  if not plain then return end
  text = text or ""
  local hasHTMLMarkup = isHTMLContent(text)
  if not state.htmlText then
    state.htmlText = getWidget("htmlText")
  end
  local htmlWidget = state.htmlText
  local canRenderHTML = htmlWidget ~= nil and hasHTMLMarkup
  local contentWidth = getContentWidth()
  if canRenderHTML and htmlWidget then
    plain:Hide()
    htmlWidget:Show()
    htmlWidget:SetWidth(contentWidth)
    htmlWidget:SetText(text)
    local htmlHeight = htmlWidget.GetContentHeight and htmlWidget:GetContentHeight() or htmlWidget:GetHeight()
    updateReaderHeight(htmlHeight)
  else
    if htmlWidget then
      htmlWidget:Hide()
    end
    plain:Show()
    plain:SetWidth(contentWidth)
    local displayText
    if hasHTMLMarkup and not canRenderHTML then
      displayText = stripHTMLTags(text)
    else
      displayText = text
    end
    plain:SetText(displayText)
    local plainHeight = plain:GetStringHeight()
    updateReaderHeight(plainHeight)
  end
end

function ReaderUI:DisableDeleteButton()
  local button = getDeleteButton()
  if button then
    button:Disable()
  end
end

function ReaderUI:UpdatePageControlsDisplay(totalPages)
  local prevButton = state.prevButton or getWidget("prevButton")
  local nextButton = state.nextButton or getWidget("nextButton")
  local indicator = state.pageIndicator or getWidget("pageIndicator")
  totalPages = totalPages or #(state.pageOrder or {})
  local currentIndex = clampPageIndex(state.pageOrder or { 1 }, state.currentPageIndex or 1)

  if indicator then
    local displayIndex = totalPages == 0 and 0 or currentIndex
    indicator:SetText(string.format("Page %d / %d", displayIndex, totalPages))
  end

  if prevButton then
    if totalPages <= 1 or currentIndex <= 1 then
      prevButton:Disable()
    else
      prevButton:Enable()
    end
  end

  if nextButton then
    if totalPages <= 1 or currentIndex >= totalPages then
      nextButton:Disable()
    else
      nextButton:Enable()
    end
  end
end

function ReaderUI:ChangePage(delta)
  if not state.pageOrder or #state.pageOrder == 0 then
    return
  end
  local newIndex = clampPageIndex(state.pageOrder, (state.currentPageIndex or 1) + delta)
  if newIndex == state.currentPageIndex then
    return
  end
  state.currentPageIndex = newIndex
  self:RenderSelected()
end

function ReaderUI:Init(context)
  ctx = context or {}
  ctx.debugPrint = ctx.debugPrint or fallbackDebugPrint
end

function ReaderUI:RenderSelected()
  local ui = state.readerBlock or (ctx and ctx.getUIFrame and ctx.getUIFrame())
  if not ui then return end
  if not state.bookTitle then
    state.bookTitle = getWidget("bookTitle")
  end
  if not state.metaDisplay then
    state.metaDisplay = getWidget("meta")
  end
  if not state.countText then
    state.countText = getWidget("countText")
  end

  local bookTitle = state.bookTitle
  local metaDisplay = state.metaDisplay
  if not bookTitle or not metaDisplay then
    debugPrint("[BookArchivist] renderSelected skipped (title/meta widgets missing)")
    return
  end

  local addon = getAddon()
  if not addon then
    debugPrint("[BookArchivist] renderSelected: addon missing")
    return
  end
  local db = addon:GetDB()

  local key = getSelectedKey()
  local entry = key and db.books[key] or nil
  if not entry then
    debugPrint("[BookArchivist] renderSelected: no entry for key", tostring(key))
    bookTitle:SetText("Select a book from the list")
    bookTitle:SetTextColor(0.5, 0.5, 0.5)
    metaDisplay:SetText("")
    renderBookContent("")
    local deleteButton = getDeleteButton()
    if deleteButton then deleteButton:Disable() end
    if state.countText then
      state.countText:SetText("|cFF888888Books saved as you read them in-game|r")
    end
    state.currentEntryKey = nil
    state.pageOrder = {}
    state.currentPageIndex = 1
    self:UpdatePageControlsDisplay(0)
    return
  end

  bookTitle:SetText(entry.title or "(Untitled Book)")
  bookTitle:SetTextColor(1, 0.82, 0)

  local meta = {}
  if entry.creator and entry.creator ~= "" then
    table.insert(meta, "|cFFFFD100Creator:|r " .. entry.creator)
  end
  if entry.material and entry.material ~= "" then
    table.insert(meta, "|cFFFFD100Material:|r " .. entry.material)
  end
  if entry.lastSeenAt then
    table.insert(meta, "|cFFFFD100Last viewed:|r " .. fmtTime(entry.lastSeenAt))
  end
  local locationLine = formatLocationLine(entry.location)
  if locationLine then
    table.insert(meta, locationLine)
  end
  if #meta == 0 then
    metaDisplay:SetText("|cFF888888Captured automatically from ItemText.|r")
  else
    metaDisplay:SetText(table.concat(meta, "\n"))
  end

  local previousKey = state.currentEntryKey
  state.currentEntryKey = key
  state.pageOrder = buildPageOrder(entry)
  if previousKey ~= key then
    state.currentPageIndex = 1
  end
    local totalPages = #state.pageOrder
    if totalPages > 0 then
      state.currentPageIndex = clampPageIndex(state.pageOrder, state.currentPageIndex)
    else
      state.currentPageIndex = 1
    end

    local pageText
    if totalPages == 0 then
      pageText = "|cFF888888No content available|r"
    else
      local pageIndex = state.currentPageIndex
      local pageNum = state.pageOrder[pageIndex]
      pageText = (entry.pages and pageNum and entry.pages[pageNum]) or ""
      if pageText == "" then
        pageText = "|cFF888888No content available|r"
      end
    end
  renderBookContent(pageText)

  local deleteButton = getDeleteButton()
  if deleteButton then deleteButton:Enable() end

  local pageCount = 0
  if entry.pages then
    for _ in pairs(entry.pages) do
      pageCount = pageCount + 1
    end
  end
  if state.countText then
    local details = {}
    table.insert(details, string.format("|cFFFFD100%d|r page%s", pageCount, pageCount ~= 1 and "s" or ""))
    if entry.lastSeenAt then
      table.insert(details, "Last viewed " .. fmtTime(entry.lastSeenAt))
    end
    state.countText:SetText(table.concat(details, "  |cFF666666•|r  "))
  end

    self:UpdatePageControlsDisplay(totalPages)
end
