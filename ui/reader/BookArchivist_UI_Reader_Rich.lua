---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = BookArchivist.UI.Reader or {}
BookArchivist.UI.Reader = ReaderUI

local state = ReaderUI.__state or {}
ReaderUI.__state = state

local getWidget = ReaderUI.__getWidget
local safeCreateFrame = ReaderUI.__safeCreateFrame
local debugPrint = ReaderUI.__debugPrint or function(...) BookArchivist:DebugPrint(...) end

local function isUIDebugEnabled()
  if BookArchivist and BookArchivist.IsUIDebugEnabled then
    return BookArchivist:IsUIDebugEnabled() and true or false
  end
  return false
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

  text = text:gsub("<%s*[Ii][Mm][Gg][^>]-src%s*=%s*\"([^\"]+)\"[^>]->", "[Image: %1]")
  text = text:gsub("<%s*[Ii][Mm][Gg][^>]->", "[Image]")

  local cleaned = text:gsub("<[^>]+>", "")

  cleaned = cleaned:gsub("\r\n", "\n")
  cleaned = cleaned:gsub("\n%s*\n%s*\n+", "\n\n")

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

    if lowerSrc:find("interface\\common\\spacer", 1, true) then
      return ""
    end

    local width = tonumber(tag:match("width%s*=%s*\"(%d+)\"") or tag:match("width%s*=%s*'(%d+)'") or tag:match("width%s*=%s*(%d+)"))
    local height = tonumber(tag:match("height%s*=%s*\"(%d+)\"") or tag:match("height%s*=%s*'(%d+)'") or tag:match("height%s*=%s*(%d+)"))

    local defaultAspect = 145 / 230
    local w = width or maxWidth
    local h = height or math.floor(w * defaultAspect + 0.5)

    w = math.max(64, math.min(w, maxWidth))
    h = math.max(64, math.min(h, 600))

    local rebuilt = string.format("<IMG src=\"%s\" width=\"%d\" height=\"%d\"/>", src, w, h)
    return string.format("<P align=\"center\">%s</P>", rebuilt)
  end

  html = html:gsub("<%s*[Ii][Mm][Gg][^>]->", processImg)

  html = html:gsub("\r\n", "\n")

  html = html:gsub("<%s*[Pp]%s*[^>]*>%s*</%s*[Pp]%s*>", "<BR/>")

  html = html:gsub("(<%s*[Pp][^>]*>)(.-)(</%s*[Pp]%s*>)", function(open, body, close)
    body = body:gsub("\n+", "\n")
    body = body:gsub("%s+", " ")
    return open .. body .. close
  end)

  html = html:gsub("<%s*[Hh][Rr]%s*/?>", "<BR/>")

  local brPattern = "<%s*[Bb][Rr]%s*/?>"
  html = html:gsub("(" .. brPattern .. "%s*)%s*(" .. brPattern .. ")%s*(" .. brPattern .. ")+", "%1%2")

  return html, spacerCount, resizedCount
end

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
      -- unknown tags ignored
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

local function resetRichDebugFrames(parent)
  if not state.richDebugFrames then
    return
  end
  parent = parent or state.textChild or (getWidget and getWidget("textChild")) or UIParent
  for _, frame in ipairs(state.richDebugFrames) do
    if frame then
      frame:Hide()
      frame:ClearAllPoints()
      frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
      frame:SetSize(0.01, 0.01)
    end
  end
end

local function ensureRichDebugFrame(index, parent)
  if not isUIDebugEnabled() then
    return nil
  end
  parent = parent or state.textChild or (getWidget and getWidget("textChild"))
  if not parent then
    return nil
  end

  state.richDebugFrames = state.richDebugFrames or {}
  local frame = state.richDebugFrames[index]
  if not frame then
    frame = (safeCreateFrame and safeCreateFrame("Frame", nil, parent))
      or (CreateFrame and CreateFrame("Frame", nil, parent))
    if not frame then
      return nil
    end
    frame:EnableMouse(false)
    local level = (parent.GetFrameLevel and parent:GetFrameLevel()) or 0
    frame:SetFrameLevel(math.min(level + 5, 128))

    state.richDebugFrames[index] = frame

    if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal
      and BookArchivist.UI.Internal.registerGridTarget then
      local name = "reader-html-" .. tostring(index)
      BookArchivist.UI.Internal.registerGridTarget(name, frame)
    end
  end
  frame:Show()
  return frame
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
    state.textChild = getWidget and getWidget("textChild")
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
    state.textChild = getWidget and getWidget("textChild")
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
    state.textChild = getWidget and getWidget("textChild")
  end
  local child = state.textChild
  if not child then
    return false
  end

  if state.textPlain and state.textPlain.Hide then
    state.textPlain:Hide()
  end
  if state.htmlText and state.htmlText.Hide then
    state.htmlText:Hide()
  end

  resetRichPools()
  resetRichDebugFrames(child)

  local host = state.contentHost or (getWidget and getWidget("contentHost"))
  local availableWidth = host and host.GetWidth and host:GetWidth() or (child.GetWidth and child:GetWidth()) or 400
  local padX = 10
  local topPad = 10
  local bottomPad = 12
  local contentWidth = math.max(50, availableWidth - padX * 2)

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
  local previousKind = nil
  local previousVisualKind = nil
  local debugIndex = 1
  for _, block in ipairs(blocks) do
    if block.kind == "heading" then
      if previousVisualKind == "image" then
        y = y - 4
      end
      local kindKey = block.level == 1 and "heading1" or (block.level == 2 and "heading2" or "heading3")
      local fs = acquireFontStringForKind(kindKey)
      if fs then
        fs:ClearAllPoints()
        fs:SetWidth(contentWidth)
        fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
        fs:SetText(block.text or "")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        local h = fs:GetStringHeight() or 0

        local dbg = ensureRichDebugFrame(debugIndex, child)
        if dbg then
          dbg:ClearAllPoints()
          dbg:SetAllPoints(fs)
        end
        debugIndex = debugIndex + 1

        y = y - h - 10
      end
      previousVisualKind = "text"
    elseif block.kind == "paragraph" then
      if previousVisualKind == "image" then
        y = y - 4
      end
      local fs = acquireFontStringForKind("paragraph")
      if fs then
        fs:ClearAllPoints()
        fs:SetWidth(contentWidth)
        fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
        fs:SetText(block.text or "")
        fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        local h = fs:GetStringHeight() or 0

        local dbg = ensureRichDebugFrame(debugIndex, child)
        if dbg then
          dbg:ClearAllPoints()
          dbg:SetAllPoints(fs)
        end
        debugIndex = debugIndex + 1

        y = y - h - 8
      end
      previousVisualKind = "text"
    elseif block.kind == "image" then
      local tex = acquireTextureForKind("image")
      if tex and block.src and block.src ~= "" then
        tex:ClearAllPoints()
        tex:SetTexture(block.src)
        local w = block.width or contentWidth
        local h = block.height or math.floor(w * 0.62 + 0.5)
        w = math.min(w, contentWidth)
        h = math.min(h, 600)

        local usedAtlas = false
        local atlasInfo = ReaderUI.GetArtifactBookTexInfo and ReaderUI.GetArtifactBookTexInfo(block.src)
        if atlasInfo then
          local ratio, left, right, top, bottom = unpack(atlasInfo)
          local imageWidth = contentWidth
          local imageHeight = math.min(600, math.max(32, math.floor(imageWidth * ratio + 0.5)))
          w, h = imageWidth, imageHeight
          tex:SetTexCoord(left, right, top, bottom)
          usedAtlas = true
        end

        if not usedAtlas then
          tex:SetTexCoord(0, 1, 0, 1)
        end

        tex:SetSize(w, h)
        local align = block.align or "CENTER"
        if align == "LEFT" then
          tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        elseif align == "RIGHT" then
          tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)
        else
          tex:SetPoint("TOP", child, "TOP", 0, y)
        end

        local dbg = ensureRichDebugFrame(debugIndex, child)
        if dbg then
          dbg:ClearAllPoints()
          dbg:SetAllPoints(tex)
        end
        debugIndex = debugIndex + 1

        y = y - h - 6
      end
      previousVisualKind = "image"
    elseif block.kind == "spacer" then
      local gap = tonumber(block.height) or 10
      if previousKind == "image" then
        gap = math.min(gap, 4)
      end
      y = y - gap
    elseif block.kind == "rule" then
      local tex = acquireTextureForKind("rule")
      if tex then
        tex:ClearAllPoints()
        tex:SetHeight(2)
        tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
        tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)

        local dbg = ensureRichDebugFrame(debugIndex, child)
        if dbg then
          dbg:ClearAllPoints()
          dbg:SetAllPoints(tex)
        end
        debugIndex = debugIndex + 1

        y = y - 8
      end
      previousVisualKind = "text"
    end

    previousKind = block.kind
  end

  local totalHeight = (-y) + bottomPad
  if ReaderUI.UpdateReaderHeight then
    ReaderUI.UpdateReaderHeight(totalHeight)
  elseif updateReaderHeight then
    updateReaderHeight(totalHeight)
  end
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

ReaderUI.IsHTMLContent = isHTMLContent
ReaderUI.StripHTMLTags = stripHTMLTags
ReaderUI.NormalizeHTMLForReader = normalizeHTMLForReader
ReaderUI.RenderRichHTMLPage = renderRichHTMLPage
ReaderUI.ResetRichPools = resetRichPools
