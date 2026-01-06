---@diagnostic disable: undefined-global
-- BookArchivist_CRC32.lua
-- Simple CRC32 helper used by the export/import pipeline.

BookArchivist = BookArchivist or {}

local bitLib = _G and (_G.bit32 or _G.bit) or bit32 or bit
if not bitLib then
  error("BookArchivist: bit library unavailable for CRC32")
end
local band = bitLib.band
local bxor = bitLib.bxor
local rshift = bitLib.rshift

local CRC32 = {}
BookArchivist.CRC32 = CRC32

local crc32Table

local function buildTable()
  local poly = 0xEDB88320
  local tbl = {}
  for i = 0, 255 do
    local crc = i
    for _ = 1, 8 do
      if band(crc, 1) ~= 0 then
        crc = bxor(rshift(crc, 1), poly)
      else
        crc = rshift(crc, 1)
      end
    end
    tbl[i] = crc
  end
  crc32Table = tbl
end

local function computeCRC32(data)
  if type(data) ~= "string" or data == "" then
    return 0
  end
  if not crc32Table then
    buildTable()
  end

  local crc = 0xFFFFFFFF
  for i = 1, #data do
    local byte = string.byte(data, i)
    local idx = band(bxor(crc, byte), 0xFF)
    crc = bxor(rshift(crc, 8), crc32Table[idx])
  end

  -- Normalize to unsigned 32-bit
  return band(bxor(crc, 0xFFFFFFFF), 0xFFFFFFFF)
end

function CRC32:Compute(data)
  return computeCRC32(data)
end
