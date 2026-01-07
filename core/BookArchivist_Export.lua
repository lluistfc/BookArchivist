---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
if not Core then return end

local Serialize = BookArchivist.Serialize
local Base64 = BookArchivist.Base64
local CRC32 = BookArchivist.CRC32

local function DecodeBDB1Envelope(raw)
  if type(raw) ~= "string" or raw == "" then
    return nil, nil, "Payload missing"
  end

  raw = raw:gsub("\r\n", "\n"):gsub("\r", "\n")
  local lines = {}

  if raw:find("\n", 1, true) then
    for line in string.gmatch(raw, "([^\n]+)") do
      local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
      if trimmed ~= "" then
        lines[#lines + 1] = trimmed
      end
    end
  else
    local searchPos = 1

    local headerStart = raw:find("BDB1|S|", searchPos, true)
    if headerStart then
      local nextControl = math.huge
      local c1 = raw:find("BDB1|C|", headerStart + 1, true)
      local f1 = raw:find("BDB1|E", headerStart + 1, true)
      if c1 and c1 < nextControl then nextControl = c1 end
      if f1 and f1 < nextControl then nextControl = f1 end
      if nextControl == math.huge then
        nextControl = #raw + 1
      end

      local headerLine = raw:sub(headerStart, nextControl - 1)
      headerLine = headerLine:gsub("^%s+", ""):gsub("%s+$", "")
      if headerLine ~= "" then
        lines[#lines + 1] = headerLine
      end
      searchPos = nextControl
    end

    while true do
      local ci = raw:find("BDB1|C|", searchPos, true)
      if not ci then
        break
      end

      local nextPos = math.huge
      local cNext = raw:find("BDB1|C|", ci + 1, true)
      local fNext = raw:find("BDB1|E", ci + 1, true)
      if cNext and cNext < nextPos then nextPos = cNext end
      if fNext and fNext < nextPos then nextPos = fNext end
      if nextPos == math.huge then
        nextPos = #raw + 1
      end

      local line = raw:sub(ci, nextPos - 1)
      line = line:gsub("^%s+", ""):gsub("%s+$", "")
      if line ~= "" then
        lines[#lines + 1] = line
      end

      searchPos = nextPos
    end

    local footerStart = raw:find("BDB1|E", searchPos, true)
    if footerStart then
      local footerLine = raw:sub(footerStart, footerStart + #"BDB1|E" - 1)
      footerLine = footerLine:gsub("^%s+", ""):gsub("%s+$", "")
      if footerLine ~= "" then
        lines[#lines + 1] = footerLine
      end
    end
  end

  if #lines < 3 then
    return nil, nil, "Payload too short"
  end

  local headerIdx, footerIdx
  local hasChunks = false
  local maxChunkIdx = 0

  for i = 1, #lines do
    local line = lines[i]
    if not headerIdx and line:find("BDB%d+|S|") then
      headerIdx = i
    end
    if line:find("BDB%d+|E") then
      footerIdx = i
    end

    local _, idxStr = line:match("(BDB%d+)|C|(%d+)")
    if idxStr then
      hasChunks = true
      local idxNum = tonumber(idxStr or "0") or 0
      if idxNum > maxChunkIdx then
        maxChunkIdx = idxNum
      end
    end
  end

  if not hasChunks then
    return nil, nil, "Invalid header"
  end

  if not headerIdx then
    headerIdx = 1
  end
  if not footerIdx or footerIdx <= headerIdx then
    footerIdx = #lines
  end

  local header = lines[headerIdx] or ""

  local marker, totalChunksStr, crcStr, rawSizeStr, schemaStr = header:match("(BDB%d+)|S|(%d+)|(%d+)|(%d+)|(%d+)")
  if not marker then
    local m2, chunksOnly = header:match("(BDB%d+)|S|(%d+)|")
    if m2 then
      marker = m2
      totalChunksStr = chunksOnly
      crcStr, rawSizeStr, schemaStr = "0", "0", "1"
    end
  end

  local totalChunks
  local expectedCRC, expectedSize, headerSchema = 0, 0, 1

  if marker and marker == "BDB1" then
    totalChunks = tonumber(totalChunksStr or "0") or 0
    expectedCRC = tonumber(crcStr or "0") or 0
    expectedSize = tonumber(rawSizeStr or "0") or 0
    headerSchema = tonumber(schemaStr or "0") or 0
  else
    totalChunks = maxChunkIdx
    expectedCRC = 0
    expectedSize = 0
    headerSchema = 1
  end

  if not totalChunks or totalChunks <= 0 then
    return nil, nil, "Invalid chunk count"
  end

  if not (Base64 and Base64.Decode) then
    return nil, nil, "Decode unavailable"
  end

  local chunks = {}
  for i = 1, #lines do
    local line = lines[i]

    local prefix, idxStr, payload = line:match("^(BDB%d+)|C|(%d+)|(.+)$")

    if not prefix then
      prefix, idxStr, payload = line:match("^(BDB%d+)|C|(%d+)(.+)$")
    end

    if prefix and idxStr and payload ~= nil then
      if prefix ~= "BDB1" then
        return nil, nil, "Invalid chunk line"
      end

      local idx = tonumber(idxStr)
      if not idx or idx < 1 or idx > totalChunks then
        return nil, nil, "Invalid chunk index"
      end
      if chunks[idx] then
        return nil, nil, "Duplicate chunk index"
      end
      chunks[idx] = payload
    end
  end

  local missing = {}
  for i = 1, totalChunks do
    if not chunks[i] then
      missing[#missing + 1] = i
    end
  end
  if #missing > 0 then
    return nil, nil, "Missing chunks: " .. table.concat(missing, ", ")
  end

  local encoded = table.concat(chunks, "", 1, totalChunks)
  local compressed, err = Base64.Decode(encoded)
  if not compressed then
    return nil, nil, "Decode failed: " .. tostring(err)
  end

  if CRC32 and CRC32.Compute and expectedCRC ~= 0 then
    local actual = CRC32:Compute(compressed)
    if actual ~= expectedCRC then
      return nil, nil, "CRC mismatch; data may be corrupt"
    end
  end

  local serialized = compressed
  if expectedSize > 0 and #serialized ~= expectedSize then
    return nil, nil, "Size mismatch; data may be corrupt"
  end

  return serialized, headerSchema, nil
end

Core._DecodeBDB1Envelope = DecodeBDB1Envelope

function Core:ExportToString()
  if not (Serialize and Serialize.SerializeTable) then
    return nil, "serializer unavailable"
  end
  local payload = self:BuildExportPayload()
  local serialized, err = Serialize.SerializeTable(payload)
  if not serialized then
    return nil, err or "serialization failed"
  end
  local compressed = serialized

  local crc
  if CRC32 and CRC32.Compute then
    crc = CRC32:Compute(compressed)
  else
    crc = 0
  end

  local rawSize = #serialized

  if not (Base64 and Base64.Encode) then
    return nil, "base64 encoder unavailable"
  end

  local encoded = Base64.Encode(compressed)

  local CHUNK_SIZE = 16384
  local totalChunks = math.max(1, math.ceil(#encoded / CHUNK_SIZE))

  local header = string.format("BDB1|S|%d|%u|%d|%d", totalChunks, crc or 0, rawSize, payload.schemaVersion or 1)
  local lines = { header }

  for i = 1, totalChunks do
    local startIdx = (i - 1) * CHUNK_SIZE + 1
    local endIdx = math.min(i * CHUNK_SIZE, #encoded)
    local chunk = encoded:sub(startIdx, endIdx)
    lines[#lines + 1] = string.format("BDB1|C|%d|%s", i, chunk)
  end

  lines[#lines + 1] = "BDB1|E"
  return table.concat(lines, "\n"), nil
end
