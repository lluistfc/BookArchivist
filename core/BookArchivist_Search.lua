---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
if not Core then return end

local Search = {}
BookArchivist.Search = Search

local function normalizeSearchText(text)
  text = tostring(text or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  text = text:gsub("^%s+", ""):gsub("%s+$", "")
  text = text:gsub("%s+", " ")
  return text:lower()
end

local function buildSearchText(title, pages)
  local out = normalizeSearchText(title or "")
  if type(pages) == "table" then
    local indices = {}
    for pageNum in pairs(pages) do
      if type(pageNum) == "number" then
        table.insert(indices, pageNum)
      end
    end
    table.sort(indices)
    if #indices == 0 then
      for _, text in pairs(pages) do
        local norm = normalizeSearchText(text)
        if norm ~= "" then
          if out ~= "" then
            out = out .. "\n" .. norm
          else
            out = norm
          end
        end
      end
    else
      for _, pageNum in ipairs(indices) do
        local norm = normalizeSearchText(pages[pageNum])
        if norm ~= "" then
          if out ~= "" then
            out = out .. "\n" .. norm
          else
            out = norm
          end
        end
      end
    end
  end
  return out
end

function Search.NormalizeSearchText(text)
  return normalizeSearchText(text)
end

function Search.BuildSearchText(title, pages)
  return buildSearchText(title, pages)
end

function Core:BuildSearchText(title, pages)
  return Search.BuildSearchText(title, pages)
end
