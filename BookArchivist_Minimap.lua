---@diagnostic disable: undefined-global
-- BookArchivist_Minimap.lua
-- Creates a lightweight minimap button without external libraries.

BookArchivist = BookArchivist or {}
local MinimapModule = BookArchivist.Minimap or {}
BookArchivist.Minimap = MinimapModule

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local BUTTON_SIZE = 32
local OUTER_BUFFER = 4

local function getOptions()
  local core = BookArchivist.Core
  if core and core.GetMinimapButtonOptions then
    return core:GetMinimapButtonOptions()
  end
  MinimapModule._fallback = MinimapModule._fallback or { angle = 200 }
  return MinimapModule._fallback
end



local function computeRadius(button)
  if not Minimap then
    return 80
  end
  local minSize = math.min(Minimap:GetWidth() or 140, Minimap:GetHeight() or 140)
  local mapRadius = minSize / 2
  local buttonHalf = (button and button:GetWidth() or BUTTON_SIZE) / 2
  return mapRadius + buttonHalf - OUTER_BUFFER
end

local function updatePosition(button)
  if not button or not Minimap then return end
  local opts = getOptions()
  local angle = (opts.angle or 200) % 360
  local radius = computeRadius(button)
  local radians = math.rad(angle)
  local x = math.cos(radians) * radius
  local y = math.sin(radians) * radius
  button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function updateAngleFromCursor(button)
  if not button or not Minimap then return end
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = UIParent and UIParent:GetEffectiveScale() or 1
  cx = cx / scale
  cy = cy / scale
  local angle = math.deg(math.atan2(cy - my, cx - mx))
  local opts = getOptions()
  opts.angle = angle
  updatePosition(button)
end

local function handleDragStart(button)
  if not button then return end
  button:SetScript("OnUpdate", function(self)
    updateAngleFromCursor(self)
  end)
end

local function handleDragStop(button)
  if not button then return end
  button:SetScript("OnUpdate", nil)
end

local function handleEnter(self)
  if not GameTooltip then return end
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText("Book Archivist", 1, 0.82, 0)
  GameTooltip:AddLine("Left-click: Open library", 0.9, 0.9, 0.9)
  GameTooltip:AddLine("Right-click: Open options", 0.9, 0.9, 0.9)
  GameTooltip:AddLine("Drag: Move button", 0.9, 0.9, 0.9)
  GameTooltip:Show()
end

local function handleLeave()
  if GameTooltip then
    GameTooltip:Hide()
  end
end

local function handleClick(_, button)
  if button == "RightButton" then
    if BookArchivist and BookArchivist.OpenOptionsPanel then
      BookArchivist:OpenOptionsPanel()
    end
  else
    if BookArchivist and BookArchivist.ToggleUI then
      BookArchivist:ToggleUI()
    end
  end
end

function MinimapModule:RefreshPosition()
  if not self.button then return end
  updatePosition(self.button)
end

local function hookResizeUpdates()
  if MinimapModule._resizeHooked or not Minimap then
    return
  end
  local function refresh()
    MinimapModule:RefreshPosition()
  end
  Minimap:HookScript("OnSizeChanged", refresh)
  if MinimapCluster then
    MinimapCluster:HookScript("OnSizeChanged", refresh)
    if hooksecurefunc then
      hooksecurefunc(MinimapCluster, "SetScale", refresh)
    end
  end
  MinimapModule._resizeHooked = true
end

function MinimapModule:Ensure()
  if self.button and self.button:IsObjectType("Button") then
    return self.button
  end
  if not CreateFrame or not Minimap then
    return nil
  end

  local button = CreateFrame("Button", "BookArchivistMinimapButton", Minimap)
  button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
  button:SetFrameStrata("MEDIUM")
  button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  button:SetScript("OnClick", handleClick)
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  button:RegisterForDrag("LeftButton")
  button:SetScript("OnDragStart", handleDragStart)
  button:SetScript("OnDragStop", handleDragStop)
  button:SetScript("OnEnter", handleEnter)
  button:SetScript("OnLeave", handleLeave)

  local icon = button:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(DEFAULT_ICON)
  icon:SetSize(BUTTON_SIZE - 6, BUTTON_SIZE - 6)
  icon:SetPoint("CENTER")
  button.icon = icon

  self.button = button
  updatePosition(button)
  hookResizeUpdates()
  return button
end

function MinimapModule:Initialize()
  if self.initialized then
    return true
  end
  local button = self:Ensure()
  if not button then
    return false
  end
  self.initialized = true
  return true
end

local function onEvent(self, event)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    if MinimapModule:Initialize() then
      self:UnregisterAllEvents()
    end
  end
end

local loader
if CreateFrame then
  loader = CreateFrame("Frame")
  loader:RegisterEvent("PLAYER_LOGIN")
  loader:RegisterEvent("PLAYER_ENTERING_WORLD")
  loader:SetScript("OnEvent", onEvent)
end
