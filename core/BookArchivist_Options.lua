---@diagnostic disable: undefined-global
BookArchivist = BookArchivist or {}

local Core = BookArchivist.Core
if not Core then return end

local function ensureUIOptions()
  local db = Core:EnsureDB()
  db.options = db.options or {}
  db.options.ui = db.options.ui or {}
  local uiOpts = db.options.ui
  if uiOpts.virtualCategoriesEnabled == nil then
    uiOpts.virtualCategoriesEnabled = true
  end
  if uiOpts.resumeLastPage == nil then
    uiOpts.resumeLastPage = true
  end
  return uiOpts
end

function Core:GetOptions()
  local db = self:EnsureDB()
  db.options = db.options or {}
  
  -- Migration: merge old debugMode into debugEnabled
  if db.options.debugEnabled == nil then
    -- If either old setting was enabled, enable the new merged setting
    local oldDebugEnabled = db.options.enableDebugLogging
    local oldDebugMode = db.options.debugMode
    db.options.debugEnabled = (oldDebugEnabled or oldDebugMode) and true or false
    -- Clean up old keys
    db.options.enableDebugLogging = nil
    db.options.debugMode = nil
  end
  
  return db.options
end

function Core:GetMinimapButtonOptions()
  local opts = self:GetOptions()
  opts.minimapButton = opts.minimapButton or {}
  if type(opts.minimapButton.angle) ~= "number" then
    opts.minimapButton.angle = 200
  end
  return opts.minimapButton
end

function Core:IsDebugEnabled()
  local opts = self:GetOptions()
  -- Read from the actual saved variable that the Settings UI uses
  if opts.debug ~= nil then
    return opts.debug and true or false
  end
  -- Fallback to old key for migration
  return opts.debugEnabled and true or false
end

function Core:SetDebugEnabled(state)
  local opts = self:GetOptions()
  -- Save to both keys for compatibility
  opts.debug = state and true or false
  opts.debugEnabled = state and true or false
end

function Core:IsTooltipEnabled()
  local opts = self:GetOptions()
  local tooltipOpts = opts.tooltip
  if tooltipOpts == nil then
    return true
  end
  if type(tooltipOpts) == "table" then
    if tooltipOpts.enabled == nil then
      tooltipOpts.enabled = true
    end
    return tooltipOpts.enabled and true or false
  end
  if type(tooltipOpts) == "boolean" then
    return tooltipOpts and true or false
  end
  return true
end

function Core:SetTooltipEnabled(state)
  local opts = self:GetOptions()
  opts.tooltip = opts.tooltip or {}
  if type(opts.tooltip) ~= "table" then
    opts.tooltip = { enabled = state and true or false }
  else
    opts.tooltip.enabled = state and true or false
  end
end

function Core:IsUIDebugEnabled()
  local opts = self:GetOptions()
  return opts.uiDebug and true or false
end

function Core:SetUIDebugEnabled(state)
  local opts = self:GetOptions()
  opts.uiDebug = state and true or false
end

function Core:GetUIFrameOptions()
  return ensureUIOptions()
end


function Core:IsVirtualCategoriesEnabled()
  local uiOpts = ensureUIOptions()
  if uiOpts.virtualCategoriesEnabled == nil then
    uiOpts.virtualCategoriesEnabled = true
  end
  return uiOpts.virtualCategoriesEnabled and true or false
end

function Core:SetVirtualCategoriesEnabled(state)
  local uiOpts = ensureUIOptions()
  uiOpts.virtualCategoriesEnabled = state and true or false
end

function Core:IsResumeLastPageEnabled()
  local uiOpts = ensureUIOptions()
  if uiOpts.resumeLastPage == nil then
    uiOpts.resumeLastPage = true
  end
  return uiOpts.resumeLastPage and true or false
end

function Core:SetResumeLastPageEnabled(state)
  local uiOpts = ensureUIOptions()
  uiOpts.resumeLastPage = state and true or false
end
