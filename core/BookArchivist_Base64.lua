---@diagnostic disable: undefined-global
-- BookArchivist_Base64.lua
-- Minimal Base64 encoder/decoder for export/import.

BookArchivist = BookArchivist or {}

local Base64 = {}
BookArchivist.Base64 = Base64

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64bytes = {}
for i = 1, #b64chars do
	b64bytes[string.sub(b64chars, i, i)] = i - 1
end

---Encode a binary string into Base64.
---@param data string
---@return string
function Base64.Encode(data)
	if type(data) ~= "string" or data == "" then
		return ""
	end
	local out = {}
	local len = #data
	local i = 1
	while i <= len do
		local b1, b2, b3 = string.byte(data, i, i + 2)
		local pad
		if not b2 then
			pad = 2
			b2, b3 = 0, 0
		elseif not b3 then
			pad = 1
			b3 = 0
		else
			pad = 0
		end
		local triple = b1 * 65536 + b2 * 256 + b3
		local c1 = math.floor(triple / 262144) % 64
		local c2 = math.floor(triple / 4096) % 64
		local c3 = math.floor(triple / 64) % 64
		local c4 = triple % 64
		out[#out + 1] = string.sub(b64chars, c1 + 1, c1 + 1)
		out[#out + 1] = string.sub(b64chars, c2 + 1, c2 + 1)
		if pad == 2 then
			out[#out + 1] = "="
			out[#out + 1] = "="
		elseif pad == 1 then
			out[#out + 1] = string.sub(b64chars, c3 + 1, c3 + 1)
			out[#out + 1] = "="
		else
			out[#out + 1] = string.sub(b64chars, c3 + 1, c3 + 1)
			out[#out + 1] = string.sub(b64chars, c4 + 1, c4 + 1)
		end
		i = i + 3
	end
	return table.concat(out)
end

---Decode a Base64 string back into a binary string.
---@param text string
---@return string|nil, string|nil
function Base64.Decode(text)
	if type(text) ~= "string" or text == "" then
		return nil, "expected non-empty base64 string"
	end
	local clean = text:gsub("%s+", "")
	if #clean % 4 ~= 0 then
		return nil, "invalid base64 length"
	end
	local out = {}
	local i = 1
	while i <= #clean do
		local c1 = string.sub(clean, i, i)
		i = i + 1
		local c2 = string.sub(clean, i, i)
		i = i + 1
		local c3 = string.sub(clean, i, i)
		i = i + 1
		local c4 = string.sub(clean, i, i)
		i = i + 1

		local v1 = b64bytes[c1]
		local v2 = b64bytes[c2]
		local v3 = (c3 ~= "=") and b64bytes[c3] or nil
		local v4 = (c4 ~= "=") and b64bytes[c4] or nil

		if not v1 or not v2 or (c3 ~= "=" and not v3) or (c4 ~= "=" and not v4) then
			return nil, "invalid base64 character"
		end

		local triple = v1 * 262144 + v2 * 4096 + (v3 or 0) * 64 + (v4 or 0)
		local b1 = math.floor(triple / 65536) % 256
		local b2 = math.floor(triple / 256) % 256
		local b3 = triple % 256

		out[#out + 1] = string.char(b1)
		if c3 ~= "=" then
			out[#out + 1] = string.char(b2)
		end
		if c4 ~= "=" then
			out[#out + 1] = string.char(b3)
		end
	end

	return table.concat(out), nil
end

return Base64
