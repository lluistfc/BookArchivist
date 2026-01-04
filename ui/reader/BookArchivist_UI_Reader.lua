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

  -- Preserve image information as simple placeholders so image-only pages
  -- don't disappear entirely when falling back to plain text.
  text = text:gsub("<%s*[Ii][Mm][Gg][^>]-src%s*=%s*\"([^\"]+)\"[^>]->", "[Image: %1]")
  text = text:gsub("<%s*[Ii][Mm][Gg][^>]->", "[Image]")

  -- Strip remaining tags.
  local cleaned = text:gsub("<[^>]+>", "")

  -- Normalise newlines and collapse excessive blank lines while keeping
  -- paragraph separation.
  cleaned = cleaned:gsub("\r\n", "\n")
  cleaned = cleaned:gsub("\n%s*\n%s*\n+", "\n\n")

  -- Collapse runs of spaces/tabs into a single space.
  cleaned = cleaned:gsub("[ \t]+", " ")

  return cleaned
end

local function normalizeHTMLForReader(html, maxWidth)
  if not html or html == "" then
    return html or "", 0, 0
  end

  maxWidth = tonumber(maxWidth) or 0
  if maxWidth <= 0 then
    maxWidth = 230
  end

  local spacerCount = 0
  local resizedCount = 0

  local function processImg(tag)
    local src = tag:match("src%s*=%s*\"([^\"]+)\"") or tag:match("src%s*=%s*'([^']+)'")
    if not src then
      return tag
    end
    local lowerSrc = src:lower()
    local width = tonumber(tag:match("width%s*=%s*\"(%d+)\"") or tag:match("width%s*=%s*'(%d+)'") or tag:match("width%s*=%s*(%d+)"))
    local height = tonumber(tag:match("height%s*=%s*\"(%d+)\"") or tag:match("height%s*=%s*'(%d+)'") or tag:match("height%s*=%s*(%d+)"))

    if lowerSrc:find("interface\\common\\spacer", 1, true) then
      local h = height or 0
      if h >= 80 then
        spacerCount = spacerCount + 1
        return "<BR/><BR/>"
      elseif h >= 30 then
        spacerCount = spacerCount + 1
        return "<BR/>"
      else
        spacerCount = spacerCount + 1
        local newH = (h > 0) and math.min(h, 28) or 20
        return string.format("<IMG src=\"%s\" width=\"1\" height=\"%d\"/>", src, newH)
      end
    end

		-- For non-spacer images, SimpleHTML often requires width/height or
		-- it will refuse to render. Rebuild the tag with safe defaults if
		-- they are missing, then wrap it in a centered paragraph.
		local defaultAspect = 145 / 230
		local w = width or maxWidth
		local h = height or math.floor(w * defaultAspect + 0.5)

		w = math.max(64, math.min(w, maxWidth))
		h = math.max(64, math.min(h, 600))

		local rebuilt = string.format("<IMG src=\"%s\" width=\"%d\" height=\"%d\"/>", src, w, h)
		return string.format("<P align=\"center\">%s</P>", rebuilt)
  end

  html = html:gsub("<%s*[Ii][Mm][Gg][^>]->", processImg)

	-- Normalise newlines/whitespace and paragraph structure for more
	-- predictable SimpleHTML wrapping.
	html = html:gsub("\r\n", "\n")

	-- Turn empty paragraphs into simple breaks so we don't end up with
	-- large vertical gaps that SimpleHTML might mishandle.
	html = html:gsub("<%s*[Pp]%s*[^>]*>%s*</%s*[Pp]%s*>", "<BR/>")

	-- Collapse excessive whitespace inside paragraph bodies.
	html = html:gsub("(<%s*[Pp][^>]*>)(.-)(</%s*[Pp]%s*>)", function(open, body, close)
		body = body:gsub("\n+", "\n")
		body = body:gsub("%s+", " ")
		return open .. body .. close
	end)

	-- Replace horizontal rules with a simple line break.
	html = html:gsub("<%s*[Hh][Rr]%s*/?>", "<BR/>")

	-- Limit excessive consecutive <BR/> elements to at most two.
	local brPattern = "<%s*[Bb][Rr]%s*/?>"
	html = html:gsub("(" .. brPattern .. "%s*)%s*(" .. brPattern .. ")%s*(" .. brPattern .. ")+", "%1%2")

  return html, spacerCount, resizedCount
end

-- Forward declaration so helper functions can call this without
-- falling back to the global environment.
local updateReaderHeight

--
-- Rich layout pipeline: parse a limited HTML subset (headings, paragraphs,
-- images, spacers, horizontal rules, and <BR> line breaks) into a sequence
-- of blocks, then lay those blocks out as real FontStrings and Textures
-- inside the scroll child. This avoids SimpleHTML quirks entirely for
-- supported content.
--

local function parseHTMLAttributes(attrText)
  local attrs = {}
  if not attrText or attrText == "" then
    return attrs
  end
  for key, value in attrText:gmatch("([%w_-]+)%s*=%s*\"([^\"]*)\"") do
    attrs[key:lower()] = value
  end
  for key, value in attrText:gmatch("([%w_-]+)%s*=%s*'([^']*)'") do
    attrs[key:lower()] = value
  end
  for key, value in attrText:gmatch("([%w_-]+)%s*=%s*([^%s\"'>]+)") do
    if attrs[key:lower()] == nil then
      attrs[key:lower()] = value
    end
  end
  return attrs
end

local function parsePageToBlocks(html)
  local blocks = {}
  if not html or html == "" then
    return blocks
  end

  local inner = tostring(html):gsub("\r\n", "\n")
  local body = inner:match("<[Hh][Tt][Mm][Ll][^>]*>.*<[Bb][Oo][Dd][Yy][^>]*>(.*)</%s*[Bb][Oo][Dd][Yy]%s*>")
  if body then
    inner = body
  end

  local pos = 1
  local len = #inner
  local currentPara = nil

  local function flushPara()
    if currentPara and currentPara.text and currentPara.text:match("%S") then
      local text = currentPara.text
      text = text:gsub("%s+\n", "\n"):gsub("\n%s+", "\n")
      text = text:gsub("[ \t]+", " ")
      text = text:gsub("^%s+", ""):gsub("%s+$", "")
      if text ~= "" then
        currentPara.text = text
        table.insert(blocks, currentPara)
      end
    end
    currentPara = nil
  end

  while true do
    local s, e, tag = inner:find("<([^>]+)>", pos)
    if not s then
      local tail = inner:sub(pos)
      if tail ~= "" then
        currentPara = currentPara or { kind = "paragraph", text = "", align = "LEFT" }
        currentPara.text = currentPara.text .. tail
      end
      break
    end

    if s > pos then
      local textChunk = inner:sub(pos, s - 1)
      if textChunk ~= "" then
        currentPara = currentPara or { kind = "paragraph", text = "", align = "LEFT" }
        currentPara.text = currentPara.text .. textChunk
      end
    end
    pos = e + 1

    tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
    local isClosing = tag:sub(1, 1) == "/"
    local tagName
    local attrText = ""
    if isClosing then
      tagName = tag:match("^/%s*([%w]+)") or ""
      tagName = tagName:lower()
    else
      tagName = tag:match("^([%w]+)") or ""
      tagName = tagName:lower()
      attrText = tag:sub(#tagName + 1)
    end

    if tagName == "p" then
      if isClosing then
        flushPara()
      else
        flushPara()
        local attrs = parseHTMLAttributes(attrText)
        local align = (attrs.align and attrs.align:upper()) or "LEFT"
        currentPara = { kind = "paragraph", text = "", align = align }
      end
    elseif tagName == "br" then
      currentPara = currentPara or { kind = "paragraph", text = "", align = "LEFT" }
      currentPara.text = currentPara.text .. "\n"
    elseif tagName == "h1" or tagName == "h2" or tagName == "h3" then
      local level = tonumber(tagName:sub(2)) or 1
      if not isClosing then
      -- Find the matching closing tag in a case-insensitive way.
      local closePattern = "</%s*[Hh]" .. tagName:sub(2) .. "%s*>"
      local cs, ce = inner:find(closePattern, pos)
        local headingText
        if cs then
          headingText = inner:sub(pos, cs - 1)
          pos = ce + 1
        else
          headingText = ""
        end
        flushPara()
        local attrs = parseHTMLAttributes(attrText)
        local align = (attrs.align and attrs.align:upper()) or "CENTER"
        headingText = headingText:gsub("[ \t]\n", "\n"):gsub("\n[ \t]", "\n")
        headingText = headingText:gsub("%s+", " ")
        headingText = headingText:gsub("^%s+", ""):gsub("%s+$", "")
        if headingText ~= "" then
          table.insert(blocks, { kind = "heading", level = level, text = headingText, align = align })
        end
      end
    elseif tagName == "img" then
      local attrs = parseHTMLAttributes(attrText)
      local src = attrs.src or ""
      src = src:gsub("\\\\", "\\")
      local lowerSrc = src:lower()
      if lowerSrc:find("interface\\common\\spacer", 1, true) then
        local h = tonumber(attrs.height or "0") or 0
        if h <= 0 then h = 20 end
        table.insert(blocks, { kind = "spacer", height = h })
      else
        local w = tonumber(attrs.width or "") or nil
        local h = tonumber(attrs.height or "") or nil
        local align = (attrs.align and attrs.align:upper()) or "CENTER"
        table.insert(blocks, { kind = "image", src = src, width = w, height = h, align = align })
      end
    elseif tagName == "hr" then
      flushPara()
      table.insert(blocks, { kind = "rule" })
    else
      -- Unknown tags are ignored; their inner text is already captured
      -- by the plain text handling above.
    end
  end

  flushPara()
  return blocks
end

local function resetRichPools()
  if state.richTextPool then
    for _, entry in ipairs(state.richTextPool) do
      entry.inUse = false
      if entry.fs then entry.fs:Hide() end
    end
  end
  if state.richTexPool then
    for _, entry in ipairs(state.richTexPool) do
      entry.inUse = false
      if entry.tex then entry.tex:Hide() end
    end
  end
end

local function acquireFontStringForKind(kind)
  state.richTextPool = state.richTextPool or {}
  local template
  if kind == "heading1" then
    template = "GameFontNormalHuge"
  elseif kind == "heading2" or kind == "heading3" then
    template = "GameFontNormalLarge"
  else
    template = "GameFontHighlight"
  end

  for _, entry in ipairs(state.richTextPool) do
    if not entry.inUse then
      entry.inUse = true
      local fs = entry.fs
      if fs and fs.SetFontObject and template then
        fs:SetFontObject(template)
      end
      if fs then fs:Show() end
      return fs
    end
  end

  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local parent = state.textChild
  if not parent or not parent.CreateFontString then
    return nil
  end
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  fs:SetWordWrap(true)
  fs:SetNonSpaceWrap(true)
  fs:SetSpacing(2)
  local entry = { fs = fs, inUse = true }
  table.insert(state.richTextPool, entry)
  return fs
end

local function acquireTextureForKind(kind)
  state.richTexPool = state.richTexPool or {}
  for _, entry in ipairs(state.richTexPool) do
    if not entry.inUse then
      entry.inUse = true
      if entry.tex then entry.tex:Show() end
      return entry.tex
    end
  end

  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local parent = state.textChild
  if not parent or not parent.CreateTexture then
    return nil
  end
  local tex = parent:CreateTexture(nil, "ARTWORK")
  if kind == "rule" then
    tex:SetColorTexture(1, 1, 1, 0.25)
  end
  local entry = { tex = tex, inUse = true }
  table.insert(state.richTexPool, entry)
  return tex
end

local function renderRichHTMLPage(text)
  if not state.textChild then
    state.textChild = getWidget("textChild")
  end
  local child = state.textChild
  if not child then
    return false
  end

  -- Hide the legacy plain/HTML widgets while the rich renderer is in
  -- control.
  if state.textPlain and state.textPlain.Hide then
    state.textPlain:Hide()
  end
  if state.htmlText and state.htmlText.Hide then
    state.htmlText:Hide()
  end

  resetRichPools()

  local host = state.contentHost or getWidget("contentHost")
  local availableWidth = host and host.GetWidth and host:GetWidth() or (child.GetWidth and child:GetWidth()) or 400
  local padX = 10
  local topPad = 10
  local bottomPad = 12
  local contentWidth = math.max(50, availableWidth - padX * 2)

  -- Normalise HTML first so spacers and images get sensible defaults.
  local normalized = text
  if normalizeHTMLForReader then
    local norm, _, _ = normalizeHTMLForReader(text, contentWidth)
    if norm and norm ~= "" then
      normalized = norm
    end
  end
  local blocks = parsePageToBlocks(normalized or text)
  if not blocks or #blocks == 0 then
    return false
  end

  local y = -topPad
  for _, block in ipairs(blocks) do
    if block.kind == "heading" then
      local kindKey = block.level == 1 and "heading1" or (block.level == 2 and "heading2" or "heading3")
      local fs = acquireFontStringForKind(kindKey)
      if fs then
        fs:ClearAllPoints()
        fs:SetWidth(contentWidth)
        fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
        fs:SetText(block.text or "")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        local h = fs:GetStringHeight() or 0
        y = y - h - 8
      end
    elseif block.kind == "paragraph" then
      local fs = acquireFontStringForKind("paragraph")
      if fs then
        fs:ClearAllPoints()
        fs:SetWidth(contentWidth)
        fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
        fs:SetText(block.text or "")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        local h = fs:GetStringHeight() or 0
        y = y - h - 6
      end
    elseif block.kind == "image" then
      local tex = acquireTextureForKind("image")
      if tex and block.src and block.src ~= "" then
        tex:ClearAllPoints()
        tex:SetTexture(block.src)
        local w = block.width or contentWidth
        local h = block.height or math.floor(w * 0.62 + 0.5)
        w = math.min(w, contentWidth)
        h = math.min(h, 600)
        tex:SetSize(w, h)
        local align = block.align or "CENTER"
        if align == "LEFT" then
          tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        elseif align == "RIGHT" then
          tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)
        else
          tex:SetPoint("TOP", child, "TOP", 0, y)
        end
        y = y - h - 6
      end
    elseif block.kind == "spacer" then
      local gap = tonumber(block.height) or 10
      y = y - gap
    elseif block.kind == "rule" then
      local tex = acquireTextureForKind("rule")
      if tex then
        tex:ClearAllPoints()
        tex:SetHeight(2)
        tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)
        y = y - 8
      end
    end
  end

  local totalHeight = (-y) + bottomPad
  updateReaderHeight(totalHeight)
  if state.textScroll and state.textScroll.UpdateScrollChildRect then
    state.textScroll:UpdateScrollChildRect()
  end
  if state.textScroll and state.textScroll.ScrollBar and state.textScroll.ScrollBar.SetValue then
    state.textScroll.ScrollBar:SetValue(0)
  elseif state.textScroll and state.textScroll.SetVerticalScroll then
    state.textScroll:SetVerticalScroll(0)
  end

  return true
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
  local hasHTMLMarkup = isHTMLContent(text)

  -- Prefer the rich layout renderer for HTML pages, which parses the
  -- limited HTML subset we care about into explicit FontStrings and
  -- Textures instead of relying on SimpleHTML. If it succeeds, skip the
  -- legacy SimpleHTML/plain-text paths below.
  if hasHTMLMarkup then
    state.useRichRenderer = (state.useRichRenderer ~= false)
    if state.useRichRenderer and renderRichHTMLPage(text) then
      return
    else
      -- If the rich renderer is disabled or fails for some reason,
      -- ensure any previously-created rich widgets are hidden before
      -- falling back to the legacy paths.
      resetRichPools()
    end
  else
    -- Non-HTML content should never leave rich-renderer widgets visible.
    resetRichPools()
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
    if hasHTMLMarkup then
      displayText = stripHTMLTags(text)
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
  local normalized, spacerCount, resizedCount = normalizeHTMLForReader(text, maxWidth)
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
