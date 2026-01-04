---@diagnostic disable: undefined-global
-- BookArchivist_UI_Minimap.lua
-- Handles the physical minimap button and user interactions separate from logic/state.

local ADDON_NAME = ...

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local UIMinimap = BookArchivist.UI.Minimap or {}
BookArchivist.UI.Minimap = UIMinimap

local MinimapModule = BookArchivist.Minimap or {}

local DEFAULT_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local BUTTON_SIZE = 32
local OUTER_BUFFER = 4

local function getAngle()
  if MinimapModule and MinimapModule.GetAngle then
    return MinimapModule:GetAngle()
  end
  return 200
end

local function setAngle(angle)
  if MinimapModule and MinimapModule.SetAngle then
    MinimapModule:SetAngle(angle)
  end
end

local function registerButton(button)
  if MinimapModule and MinimapModule.RegisterButton then
    MinimapModule:RegisterButton(button)
  end
end

local function getRegisteredButton()
  if MinimapModule and MinimapModule.GetButton then
    return MinimapModule:GetButton()
  end
  return nil
end

local function updateRegisteredButton(button)
  if MinimapModule and MinimapModule.ClearButton then
    if not button then
      MinimapModule:ClearButton()
    else
      registerButton(button)
    end
  elseif button then
    registerButton(button)
  end
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
  local angle = getAngle() % 360
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
  local angle = math.deg(math.atan(cy - my, cx - mx))
  setAngle(angle)
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

local function hookResizeUpdates()
  if UIMinimap._resizeHooked or not Minimap then
    return
  end
  local function refresh()
    UIMinimap:RefreshPosition()
  end
  Minimap:HookScript("OnSizeChanged", refresh)
  if MinimapCluster then
    MinimapCluster:HookScript("OnSizeChanged", refresh)
    if hooksecurefunc then
      hooksecurefunc(MinimapCluster, "SetScale", refresh)
    end
  end
  UIMinimap._resizeHooked = true
end

function UIMinimap:RefreshPosition()
  local button = self.button or getRegisteredButton()
  if not button then
    return
  end
  updatePosition(button)
end

function UIMinimap:EnsureButton()
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
  updateRegisteredButton(button)
  updatePosition(button)
  hookResizeUpdates()
  return button
end

local function onEvent(self, _)
  if UIMinimap:EnsureButton() then
    UIMinimap.initialized = true
    if self and self.UnregisterAllEvents then
      self:UnregisterAllEvents()
    end
  end
end

function UIMinimap:Initialize()
  if self.initialized and self.button then
    return true
  end

  if self:EnsureButton() then
    self.initialized = true
    return true
  end

  if CreateFrame and not self.loader then
    local loader = CreateFrame("Frame")
    loader:RegisterEvent("PLAYER_LOGIN")
    loader:RegisterEvent("PLAYER_ENTERING_WORLD")
    loader:SetScript("OnEvent", onEvent)
    self.loader = loader
  end
  return false
end

function UIMinimap:OnAddonLoaded(name)
  if name ~= ADDON_NAME then
    return
  end
  self:Initialize()
end
