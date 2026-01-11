---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
if not Core then
	return
end

local Serialize = BookArchivist.Serialize
local Base64 = BookArchivist.Base64
local CRC32 = BookArchivist.CRC32

local function EncodeBDB1Envelope(payload)
	if not payload then
		return nil, "payload missing"
	end
	if not (Serialize and Serialize.SerializeTable) then
		return nil, "serializer unavailable"
	end
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

local function DecodeBDB1Envelope(raw)
	if type(raw) ~= "string" or raw == "" then
		return nil, nil, "Payload missing"
	end

	-- Normalise newlines so the same decoder works for
	-- multi-line exports, single-line chat copies and
	-- capture-paste buffers.
	raw = raw:gsub("\r\n", "\n"):gsub("\r", "\n")

	-- Extract the BDB1 header from anywhere in the string, if present.
	local marker, totalChunksStr, crcStr, rawSizeStr, schemaStr = raw:match("(BDB%d+)|S|(%d+)|(%d+)|(%d+)|(%d+)")

	local totalChunksFromHeader = tonumber(totalChunksStr or "0") or 0
	local expectedCRC = tonumber(crcStr or "0") or 0
	local expectedSize = tonumber(rawSizeStr or "0") or 0
	local headerSchema = tonumber(schemaStr or "0") or 0

	if marker ~= "BDB1" or totalChunksFromHeader <= 0 then
		-- Treat header as absent/invalid; fall back to chunk-only
		-- decode with no CRC/size guarantees.
		expectedCRC = 0
		expectedSize = 0
		headerSchema = 1
		totalChunksFromHeader = 0
	end

	if not (Base64 and Base64.Decode) then
		return nil, nil, "Decode unavailable"
	end

	-- Strategy: extract everything between header and footer,
	-- strip all control lines (BDB1|S|, BDB1|C|, BDB1|E), and
	-- treat the remainder as base64 payload. This handles both
	-- single-line and multi-line wrapped payloads correctly.

	local headerStart = raw:find("BDB1|S|", 1, true)
	local footerStart = raw:find("BDB1|E", 1, true)

	-- Diagnostic data for debugging import issues
	if BookArchivist and BookArchivist.DebugPrint then
		BookArchivist:DebugPrint("[BA Decode] Raw length: " .. #raw)
		BookArchivist:DebugPrint("[BA Decode] Has header: " .. tostring(headerStart ~= nil))
		BookArchivist:DebugPrint("[BA Decode] Has footer: " .. tostring(footerStart ~= nil))
	end

	local body
	if headerStart and footerStart then
		-- Extract everything between header and footer
		body = raw:sub(headerStart, footerStart - 1)
		-- Strip the header line itself
		body = body:gsub("BDB%d+|S|[^\n]*", "")
		-- Strip any chunk markers (BDB1|C|1| etc)
		body = body:gsub("BDB%d+|C|%d+|", "")
		-- Strip the footer if it got included
		body = body:gsub("BDB%d+|E", "")
	else
		-- Last-resort fallback: no header/footer found, treat
		-- entire string as potential base64 body
		if BookArchivist and BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[BA Decode] WARNING: Missing header or footer, attempting fallback decode")
		end
		body = raw
		body = body:gsub("BDB%d+|S|[^\n]*", "")
		body = body:gsub("BDB%d+|C|%d+|", "")
		body = body:gsub("BDB%d+|E", "")
	end

	-- Remove everything that isn't valid base64
	body = body:gsub("[^A-Za-z0-9+/=]+", "")

	if BookArchivist and BookArchivist.DebugPrint then
		BookArchivist:DebugPrint("[BA Decode] Base64 length: " .. #body)
		BookArchivist:DebugPrint("[BA Decode] Expected CRC: " .. tostring(expectedCRC))
		BookArchivist:DebugPrint("[BA Decode] Expected size: " .. tostring(expectedSize))
	end

	if body == "" then
		return nil, nil, "Invalid header (empty body)"
	end

	local encoded = body

	local compressed, err = Base64.Decode(encoded)
	if not compressed then
		return nil, nil, "Decode failed: " .. tostring(err)
	end

	if BookArchivist and BookArchivist.DebugPrint then
		BookArchivist:DebugPrint("[BA Decode] Decoded length: " .. #compressed)
	end

	if CRC32 and CRC32.Compute and expectedCRC ~= 0 then
		local actual = CRC32:Compute(compressed)
		if BookArchivist and BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[BA Decode] CRC actual: " .. tostring(actual))
		end
		if actual ~= expectedCRC then
			return nil, nil, "CRC mismatch; data may be corrupt"
		end
	end

	local serialized = compressed
	if expectedSize > 0 and #serialized ~= expectedSize then
		if BookArchivist and BookArchivist.DebugPrint then
			BookArchivist:DebugPrint("[BA Decode] Size mismatch: got " .. #serialized .. ", expected " .. expectedSize)
		end
		return nil, nil, "Size mismatch; data may be corrupt"
	end

	return serialized, headerSchema, nil
end

Core._DecodeBDB1Envelope = DecodeBDB1Envelope

function Core:ExportToString()
	if not (self and self.BuildExportPayload) then
		return nil, "export unavailable"
	end
	local payload = self:BuildExportPayload()
	return EncodeBDB1Envelope(payload)
end

function Core:ExportBookToString(bookId)
	if not (self and self.BuildExportPayloadForBook) then
		return nil, "export unavailable"
	end
	local payload, err = self:BuildExportPayloadForBook(bookId)
	if not payload then
		return nil, err or "unknown book"
	end
	return EncodeBDB1Envelope(payload)
end
