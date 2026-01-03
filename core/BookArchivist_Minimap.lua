---@diagnostic disable: undefined-global
-- BookArchivist_Minimap.lua
-- Stores minimap button settings independent from UI concerns.

BookArchivist = BookArchivist or {}

local MinimapModule = BookArchivist.Minimap or {}
BookArchivist.Minimap = MinimapModule

local function getUI()
  if not BookArchivist.UI then
    return nil
  end
  return BookArchivist.UI.Minimap
end

local function getOptions()
  local core = BookArchivist.Core
  if core and core.GetMinimapButtonOptions then
    return core:GetMinimapButtonOptions()
  end
  MinimapModule._fallback = MinimapModule._fallback or { angle = 200 }
  return MinimapModule._fallback
end

function MinimapModule:GetButtonOptions()
  return getOptions()
end

function MinimapModule:GetAngle()
  local opts = getOptions()
  return opts.angle or 200
end

function MinimapModule:SetAngle(angle)
  local opts = getOptions()
  local normalized = tonumber(angle) or opts.angle or 200
  opts.angle = normalized % 360
end

function MinimapModule:RegisterButton(button)
  self.button = button
end

function MinimapModule:GetButton()
  return self.button
end

function MinimapModule:ClearButton()
  self.button = nil
end

function MinimapModule:RefreshPosition()
  local ui = getUI()
  if ui and ui.RefreshPosition then
    ui:RefreshPosition()
  end
end

function MinimapModule:Initialize()
  if self.initialized then
    return true
  end
  local ui = getUI()
  if ui and ui.Initialize then
    local ok = ui:Initialize()
    if ok then
      self.initialized = true
      return true
    end
  end
  return false
end
