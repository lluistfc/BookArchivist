---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = {}
BookArchivist.UI.Reader = ReaderUI

local ctx
local state = ReaderUI.__state or {}
ReaderUI.__state = state

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

local function debugPrint(...)
  if ctx and ctx.debugPrint then
    ctx.debugPrint(...)
  end
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

local function updateReaderHeight(height)
  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local child = state.textChild
  if not child then return end
  child:SetHeight(math.max(1, (height or 0) + 20))
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
  if canRenderHTML and htmlWidget then
    plain:Hide()
    htmlWidget:Show()
    htmlWidget:SetWidth(460)
    htmlWidget:SetText(text)
    local htmlHeight = htmlWidget.GetContentHeight and htmlWidget:GetContentHeight() or htmlWidget:GetHeight()
    updateReaderHeight(htmlHeight)
  else
    if htmlWidget then
      htmlWidget:Hide()
    end
    plain:Show()
    plain:SetWidth(460)
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
  if state.deleteButton then
    state.deleteButton:Disable()
  end
end

function ReaderUI:Init(context)
  ctx = context or {}
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
    if state.deleteButton then state.deleteButton:Disable() end
    if state.countText then
      state.countText:SetText("|cFF888888Books saved as you read them in-game|r")
    end
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
  metaDisplay:SetText(table.concat(meta, "  |cFF666666•|r  "))

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

  if state.deleteButton then state.deleteButton:Enable() end

  local pageCount = 0
  if entry.pages then
    for _ in pairs(entry.pages) do
      pageCount = pageCount + 1
    end
  end
  if state.countText then
    state.countText:SetText(string.format("|cFFFFD100%d|r page%s", pageCount, pageCount ~= 1 and "s" or ""))
  end
end
