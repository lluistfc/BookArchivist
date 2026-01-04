---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = BookArchivist.UI.Reader or {}
BookArchivist.UI.Reader = ReaderUI

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

ReaderUI.ParsePageToBlocks = ReaderUI.ParsePageToBlocks or parsePageToBlocks
