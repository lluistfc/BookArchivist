---@diagnostic disable: undefined-global
-- BookArchivist_Locale.lua
-- Lightweight localization helper for UI strings.

BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core

local SUPPORTED_LOCALES = {
  enUS = "enUS",
  esES = "esES",
  caES = "caES",
  deDE = "deDE",
  frFR = "frFR",
  itIT = "itIT",
  ptBR = "ptBR",
}

local function normalizeLocale(tag)
  tag = tostring(tag or "")
  if SUPPORTED_LOCALES[tag] then
    return SUPPORTED_LOCALES[tag]
  end
  if tag == "esMX" then
    return "esES"
  elseif tag == "ptPT" then
    return "ptBR"
  end
  return "enUS"
end

local function getActiveLocale()
  if Core and Core.GetLanguage then
    local ok, lang = pcall(Core.GetLanguage, Core)
    if ok and type(lang) == "string" and lang ~= "" then
      return normalizeLocale(lang)
    end
  end

  local gameLocale = (type(GetLocale) == "function" and GetLocale()) or "enUS"
  return normalizeLocale(gameLocale)
end

local Locales = BookArchivist.__Locales or {}
BookArchivist.__Locales = Locales

local function resolve(key)
  local active = getActiveLocale()
  local bundle = Locales[active] or Locales.enUS or {}
  local value = bundle[key]
  if value ~= nil then
    return value
  end
  local fallback = Locales.enUS[key]
  return fallback or key
end

BookArchivist.L = BookArchivist.L or {}
setmetatable(BookArchivist.L, {
  __index = function(_, key)
    return resolve(key)
  end,
})
