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
ReaderUI.__debugPrint = debugPrint

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

local function resetScrollToTop(scroll)
  scroll = scroll or state.textScroll or getWidget("textScroll")
  if not scroll then return end
  if scroll.ScrollBar and scroll.ScrollBar.SetValue then
    scroll.ScrollBar:SetValue(0)
  elseif scroll.SetVerticalScroll then
    scroll:SetVerticalScroll(0)
  end
end

function updateReaderHeight(height)
  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local child = state.textChild
  if not child then return end
  local host = state.contentHost or getWidget("contentHost")
  if host and child.SetWidth and host.GetWidth then
    local w = host:GetWidth() or 1
    child:SetWidth(math.max(1, w))
  end

  child:SetHeight(math.max(1, (height or 0) + 20))
end

ReaderUI.UpdateReaderHeight = updateReaderHeight

local function setReaderMode(useHtml)
  if not state.textPlain then
    state.textPlain = getWidget("textPlain")
  end
  if not state.htmlText then
    state.htmlText = getWidget("htmlText")
  end

  local plain = state.textPlain
  local htmlWidget = state.htmlText

  if useHtml and htmlWidget then
    if plain and plain.Hide then
      plain:Hide()
    end
    if htmlWidget.Show then
      htmlWidget:Show()
    end
  else
    if htmlWidget and htmlWidget.Hide then
      htmlWidget:Hide()
    end
    if plain and plain.Show then
      plain:Show()
    end
  end

	-- Clear any stale scroll-child height between mode switches so layout
	-- recalculates cleanly on the next render.
	if state.textChild and state.textChild.SetHeight then
		state.textChild:SetHeight(1)
	end

  return plain, htmlWidget
end

local function registerHTMLImages(htmlFrame, htmlText)
  if not htmlFrame or not htmlFrame.SetImageTexture or not htmlText or htmlText == "" then
    return htmlText
  end

  local i = 0
  htmlText = htmlText:gsub("<%s*[Ii][Mm][Gg]([^>]-)src%s*=%s*\"([^\"]+)\"([^>]*)>", function(pre, src, post)
    -- Normalise doubled backslashes from stored strings so spacer
    -- detection works regardless of how the path was serialized.
    src = src:gsub("\\\\", "\\")
    local lower = src:lower()
    if lower:find("interface\\common\\spacer", 1, true) then
      -- Spacer behaviour is already normalised separately; keep as-is.
      return "<IMG" .. pre .. "src=\"" .. src .. "\"" .. post .. ">"
    end

    i = i + 1
    local pageKey = tostring(state.currentEntryKey or "entry") .. "_" .. tostring(state.currentPageIndex or 1)
    local key = "ba_img_" .. pageKey .. "_" .. i

    local dimChunk = (pre or "") .. (post or "")
    local w = tonumber(dimChunk:match("width%s*=%s*\"(%d+)\"") or dimChunk:match("width%s*=%s*(%d+)"))
    local h = tonumber(dimChunk:match("height%s*=%s*\"(%d+)\"") or dimChunk:match("height%s*=%s*(%d+)"))

    htmlFrame:SetImageTexture(key, src)
    -- Ensure we always provide some size; some SimpleHTML builds
    -- will not draw images without explicit dimensions.
    w = w or 230
    h = h or 145
    if htmlFrame.SetImageSize then
      htmlFrame:SetImageSize(key, w, h)
    end

    return "<IMG" .. pre .. "src=\"" .. key .. "\"" .. post .. ">"
  end)

  return htmlText
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
  text = text or ""
  local richIsHTML = ReaderUI.IsHTMLContent
  local richRender = ReaderUI.RenderRichHTMLPage
  local richReset = ReaderUI.ResetRichPools
  local stripHTML = ReaderUI.StripHTMLTags
  local normalizeHTML = ReaderUI.NormalizeHTMLForReader

  local hasHTMLMarkup = richIsHTML and richIsHTML(text) or false

  -- Prefer the rich layout renderer for HTML pages, which parses the
  -- limited HTML subset we care about into explicit FontStrings and
  -- Textures instead of relying on SimpleHTML. If it succeeds, skip the
  -- legacy SimpleHTML/plain-text paths below.
  if hasHTMLMarkup then
    state.useRichRenderer = (state.useRichRenderer ~= false)
    if state.useRichRenderer and richRender and richRender(text) then
      return
    else
      -- If the rich renderer is disabled or fails for some reason,
      -- ensure any previously-created rich widgets are hidden before
      -- falling back to the legacy paths.
      if richReset then
        richReset()
      end
    end
  else
    -- Non-HTML content should never leave rich-renderer widgets visible.
    if richReset then
      richReset()
    end
  end

  if not state.textPlain then
    state.textPlain = getWidget("textPlain")
  end
  if not state.htmlText then
    state.htmlText = getWidget("htmlText")
  end

  local plain = state.textPlain
  local htmlWidget = state.htmlText
  if not plain then
    return
  end

  local function renderPlain()
    local displayText
    if hasHTMLMarkup and stripHTML then
      displayText = stripHTML(text)
    else
      displayText = text
    end
    local plainTarget = select(1, setReaderMode(false)) or plain
    if plainTarget and plainTarget.SetText then
      plainTarget:SetText(displayText ~= "" and displayText or "|cFF888888No content available|r")
    end
    local h = plainTarget.GetStringHeight and plainTarget:GetStringHeight() or 0
    updateReaderHeight(h)
    if state.textScroll and state.textScroll.UpdateScrollChildRect then
      state.textScroll:UpdateScrollChildRect()
    end
  end

  -- If there's no HTML markup or no SimpleHTML widget, just use plain mode.
  local canRenderHTML = hasHTMLMarkup and htmlWidget and htmlWidget.SetText
  if not canRenderHTML then
    renderPlain()
    return
  end

  -- Compute a reasonable max width for images from the content host.
  local host = state.contentHost or getWidget("contentHost")
  local maxWidth = 230
  if host and host.GetWidth then
    local w = host:GetWidth() or 0
    -- Subtract approximate left/right HTML padding so images fit neatly.
    maxWidth = math.max(180, math.floor(w - 2 * 18))
  end
  local normalized, spacerCount, resizedCount
  if normalizeHTML then
    normalized, spacerCount, resizedCount = normalizeHTML(text, maxWidth)
  else
    normalized, spacerCount, resizedCount = text, 0, 0
  end
  if (spacerCount or 0) > 0 or (resizedCount or 0) > 0 then
    debugPrint(string.format("[BookArchivist] HTML normalize: maxWidth=%d spacers=%d resizedImgs=%d", maxWidth, spacerCount or 0, resizedCount or 0))
  end

  local _, html = setReaderMode(true)
  html = html or htmlWidget

  if not html or not html.SetText then
    renderPlain()
    return
  end

  -- Reset the HTML widget to avoid stale layout state.
  html:SetText("")

  normalized = registerHTMLImages(html, normalized or text)
  local ok, err = pcall(html.SetText, html, normalized or text)
  if not ok then
    if logError then
      logError(string.format("BookArchivist reader HTML render failed: %s", tostring(err)))
    end
    renderPlain()
    return
  end

  if state.textScroll and state.textScroll.UpdateScrollChildRect then
    state.textScroll:UpdateScrollChildRect()
  end
  local htmlHeight = (html.GetContentHeight and html:GetContentHeight()) or (html.GetHeight and html:GetHeight()) or 0
  if (not htmlHeight or htmlHeight < 4) and state.textChild and state.textChild.GetHeight then
    htmlHeight = state.textChild:GetHeight()
  end
  local minVisible = 200
  if not htmlHeight or htmlHeight < minVisible then
    htmlHeight = minVisible
  end

  updateReaderHeight(htmlHeight)
  if state.textScroll and state.textScroll.UpdateScrollChildRect then
    state.textScroll:UpdateScrollChildRect()
  end

  -- SimpleHTML often finishes its final reflow on the next frame; run a
  -- second rect update and ensure the scroll offset is reset once more
  -- so returning to a page never starts mid-content.
  if C_Timer and C_Timer.After then
    local initialScroll = state.textScroll or getWidget("textScroll")
    if initialScroll then
      C_Timer.After(0, function()
        if not state then return end
        local scroll = state.textScroll or initialScroll
        if scroll and scroll.UpdateScrollChildRect then
          scroll:UpdateScrollChildRect()
        end
        resetScrollToTop(scroll)
      end)
    end
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

	resetScrollToTop(state.textScroll)
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
