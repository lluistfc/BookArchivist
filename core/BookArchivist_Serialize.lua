---@diagnostic disable: undefined-global
-- BookArchivist_Serialize.lua
-- Deterministic table serializer/deserializer for export/import.

local BA = BookArchivist

local Serialize = {}
BA.Serialize = Serialize

local MAX_DEPTH = 20

local function typeError(msg)
	return nil, msg or "unsupported type in serialization"
end

local function serializeValue(value, depth)
	depth = depth or 0
	if depth > MAX_DEPTH then
		return typeError("max depth exceeded")
	end
	local t = type(value)
	if t == "nil" then
		return "n;"
	elseif t == "boolean" then
		return value and "b1;" or "b0;"
	elseif t == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return typeError("non-finite number")
		end
		return "d" .. string.format("%.17g", value) .. ";"
	elseif t == "string" then
		local len = #value
		return "s" .. tostring(len) .. ":" .. value .. ";"
	elseif t == "table" then
		local keys = {}
		for k in pairs(value) do
			if type(k) ~= "string" and type(k) ~= "number" then
				return typeError("unsupported key type: " .. type(k))
			end
			table.insert(keys, k)
		end
		table.sort(keys, function(a, b)
			local ta, tb = type(a), type(b)
			if ta ~= tb then
				return ta < tb
			end
			return a < b
		end)
		local parts = {}
		parts[#parts + 1] = "t" .. tostring(#keys) .. ":"
		for _, k in ipairs(keys) do
			local kStr, errK = serializeValue(k, depth + 1)
			if not kStr then
				return nil, errK
			end
			local vStr, errV = serializeValue(value[k], depth + 1)
			if not vStr then
				return nil, errV
			end
			parts[#parts + 1] = kStr
			parts[#parts + 1] = vStr
		end
		parts[#parts + 1] = ";"
		return table.concat(parts)
	else
		return typeError("unsupported value type: " .. t)
	end
end

---Serialize a table to a deterministic string.
---@param tbl table
---@return string|nil, string|nil
function Serialize.SerializeTable(tbl)
	if type(tbl) ~= "table" then
		return typeError("expected table root")
	end
	return serializeValue(tbl, 0)
end

local function parseError(msg)
	return nil, msg or "parse error"
end

local function parseNumber(s, pos)
	local startPos = pos
	local len = #s
	while pos <= len do
		local ch = string.sub(s, pos, pos)
		if (ch >= "0" and ch <= "9") or ch == "." or ch == "-" or ch == "+" or ch == "e" or ch == "E" then
			pos = pos + 1
		else
			break
		end
	end
	local numStr = string.sub(s, startPos, pos - 1)
	local val = tonumber(numStr)
	if not val then
		return nil, startPos, "invalid number"
	end
	return val, pos
end

local function parseInteger(s, pos)
	local startPos = pos
	local len = #s
	while pos <= len do
		local ch = string.sub(s, pos, pos)
		if ch >= "0" and ch <= "9" then
			pos = pos + 1
		else
			break
		end
	end
	if pos == startPos then
		return nil, startPos, "expected integer"
	end
	local intStr = string.sub(s, startPos, pos - 1)
	local val = tonumber(intStr)
	if not val then
		return nil, startPos, "invalid integer"
	end
	return val, pos
end

local function deserializeValue(s, pos, depth)
	depth = depth or 0
	if depth > MAX_DEPTH then
		return parseError("max depth exceeded"), pos
	end
	local len = #s
	if pos > len then
		return parseError("unexpected end of input"), pos
	end
	local tag = string.sub(s, pos, pos)
	pos = pos + 1
	if tag == "n" then
		if string.sub(s, pos, pos) ~= ";" then
			return parseError("expected ';' after nil"), pos
		end
		return nil, pos + 1
	elseif tag == "b" then
		local ch = string.sub(s, pos, pos)
		pos = pos + 1
		if string.sub(s, pos, pos) ~= ";" then
			return parseError("expected ';' after boolean"), pos
		end
		local val = (ch == "1") and true or false
		return val, pos + 1
	elseif tag == "d" then
		local num, newPosOrErr, msg = parseNumber(s, pos)
		if not num then
			return parseError(msg or "invalid number"), newPosOrErr or pos
		end
		if string.sub(s, newPosOrErr, newPosOrErr) ~= ";" then
			return parseError("expected ';' after number"), newPosOrErr
		end
		return num, newPosOrErr + 1
	elseif tag == "s" then
		local strlen, newPosOrErr, msg = parseInteger(s, pos)
		if not strlen then
			return parseError(msg or "invalid string length"), newPosOrErr or pos
		end
		if string.sub(s, newPosOrErr, newPosOrErr) ~= ":" then
			return parseError("expected ':' after string length"), newPosOrErr
		end
		local startStr = newPosOrErr + 1
		local endStr = startStr + strlen - 1
		if endStr > len then
			return parseError("string length out of bounds"), startStr
		end
		local val = string.sub(s, startStr, endStr)
		local terminatorPos = endStr + 1
		if string.sub(s, terminatorPos, terminatorPos) ~= ";" then
			return parseError("expected ';' after string value"), terminatorPos
		end
		return val, terminatorPos + 1
	elseif tag == "t" then
		local count, newPosOrErr, msg = parseInteger(s, pos)
		if not count then
			return parseError(msg or "invalid table count"), newPosOrErr or pos
		end
		if string.sub(s, newPosOrErr, newPosOrErr) ~= ":" then
			return parseError("expected ':' after table count"), newPosOrErr
		end
		pos = newPosOrErr + 1
		local tbl = {}
		for i = 1, count do
			local key, nextPos = deserializeValue(s, pos, depth + 1)
			if key == nil and nextPos == nil then
				return nil, pos, "failed to parse table key"
			end
			pos = nextPos
			local val, nextPosVal = deserializeValue(s, pos, depth + 1)
			if nextPosVal == nil then
				return nil, pos, "failed to parse table value"
			end
			pos = nextPosVal
			tbl[key] = val
		end
		if string.sub(s, pos, pos) ~= ";" then
			return parseError("expected ';' after table"), pos
		end
		return tbl, pos + 1
	else
		return parseError("unknown tag '" .. tostring(tag) .. "'"), pos
	end
end

---Deserialize a string produced by SerializeTable.
---@param s string
---@return table|nil, string|nil
function Serialize.DeserializeTable(s)
	if type(s) ~= "string" or s == "" then
		return nil, "expected non-empty string"
	end
	local value, posOrErr, msg = deserializeValue(s, 1, 0)
	if msg then
		return nil, msg
	end
	return value, nil
end

return Serialize
