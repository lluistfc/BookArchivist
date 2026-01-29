---@diagnostic disable: undefined-global, undefined-field
--[[
    BookArchivist Keybindings Panel
    
    Shows a reference panel of all bound BookArchivist keybindings.
    Positioned to the right of the main UI window.
    Only shown if at least one keybinding is set.
]]

local BA = BookArchivist
BA.UI = BA.UI or {}

local KeybindingsPanel = {}
BA.UI.KeybindingsPanel = KeybindingsPanel

local L = BA.L or {}
local function t(key)
    return (L and L[key]) or key
end

-- Panel state
local state = {
    frame = nil,
    rows = {},
    isVisible = false,
}

-- All BookArchivist binding names (must match Bindings.xml)
local BINDING_NAMES = {
    { id = "BOOKARCHIVIST_TOGGLE", label = "BINDING_NAME_BOOKARCHIVIST_TOGGLE" },
    { id = "BOOKARCHIVIST_TTS_READ", label = "BINDING_NAME_BOOKARCHIVIST_TTS_READ" },
    { id = "BOOKARCHIVIST_PAGE_NEXT", label = "BINDING_NAME_BOOKARCHIVIST_PAGE_NEXT" },
    { id = "BOOKARCHIVIST_PAGE_PREV", label = "BINDING_NAME_BOOKARCHIVIST_PAGE_PREV" },
    { id = "BOOKARCHIVIST_NEW_BOOK", label = "BINDING_NAME_BOOKARCHIVIST_NEW_BOOK" },
    { id = "BOOKARCHIVIST_FOCUS_NEXT", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_NEXT" },
    { id = "BOOKARCHIVIST_FOCUS_PREV", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_PREV" },
    { id = "BOOKARCHIVIST_FOCUS_ACTIVATE", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_ACTIVATE" },
    { id = "BOOKARCHIVIST_FOCUS_TOGGLE", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_TOGGLE" },
    { id = "BOOKARCHIVIST_FOCUS_NEXT_BLOCK", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_NEXT_BLOCK" },
    { id = "BOOKARCHIVIST_FOCUS_PREV_BLOCK", label = "BINDING_NAME_BOOKARCHIVIST_FOCUS_PREV_BLOCK" },
}

-- Get the display name for a binding
local function GetBindingDisplayName(labelGlobal)
    return _G[labelGlobal] or labelGlobal
end

-- Get all bound keybindings
local function GetBoundKeybindings()
    local bound = {}
    for _, binding in ipairs(BINDING_NAMES) do
        local key1, key2 = GetBindingKey(binding.id)
        if key1 or key2 then
            local keys = {}
            if key1 then table.insert(keys, key1) end
            if key2 then table.insert(keys, key2) end
            table.insert(bound, {
                id = binding.id,
                name = GetBindingDisplayName(binding.label),
                keys = table.concat(keys, ", "),
            })
        end
    end
    return bound
end

-- Create the panel frame
local function CreatePanel()
    if state.frame then
        return state.frame
    end
    
    local mainFrame = _G["BookArchivistFrame"]
    if not mainFrame then
        return nil
    end
    
    -- Create panel frame
    local panel = CreateFrame("Frame", "BookArchivistKeybindingsPanel", mainFrame, "BackdropTemplate")
    panel:SetSize(340, 200)  -- Wider to fit long key names
    panel:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 8, 0)
    
    -- Backdrop styling
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    panel:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    
    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -12)
    title:SetText(t("KEYBINDINGS_PANEL_TITLE"))
    title:SetTextColor(1, 0.82, 0)
    panel.title = title
    
    -- Content container
    local content = CreateFrame("Frame", nil, panel)
    content:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, -40)
    content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 12)
    panel.content = content
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        KeybindingsPanel:Hide()
    end)
    
    -- Make it movable with main frame
    panel:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
    
    state.frame = panel
    return panel
end

-- Create a row for a keybinding
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(22)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 24))
    row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -((index - 1) * 24))
    
    -- Key label (left side, gold color)
    local keyLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    keyLabel:SetPoint("LEFT", row, "LEFT", 0, 0)
    keyLabel:SetWidth(120)  -- Wider to fit NUMPADMINUS, NUMPADPLUS, etc.
    keyLabel:SetJustifyH("LEFT")
    keyLabel:SetTextColor(1, 0.82, 0)
    row.keyLabel = keyLabel
    
    -- Action label (right side, white)
    local actionLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    actionLabel:SetPoint("LEFT", keyLabel, "RIGHT", 8, 0)
    actionLabel:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    actionLabel:SetJustifyH("LEFT")
    actionLabel:SetTextColor(1, 1, 1)
    row.actionLabel = actionLabel
    
    return row
end

-- Update panel content with current keybindings
local function UpdateContent()
    local panel = state.frame
    if not panel then return end
    
    local bound = GetBoundKeybindings()
    
    -- Hide all existing rows
    for _, row in ipairs(state.rows) do
        row:Hide()
    end
    
    -- No bindings? Hide panel
    if #bound == 0 then
        panel:Hide()
        state.isVisible = false
        return
    end
    
    -- Create/update rows
    for i, binding in ipairs(bound) do
        local row = state.rows[i]
        if not row then
            row = CreateRow(panel.content, i)
            state.rows[i] = row
        end
        
        row.keyLabel:SetText(binding.keys)
        row.actionLabel:SetText(binding.name)
        row:Show()
    end
    
    -- Resize panel to fit content
    local contentHeight = (#bound * 24) + 60
    panel:SetHeight(math.max(contentHeight, 100))
end

--[[
    Public API
]]

--- Show the keybindings panel (if any bindings are set)
function KeybindingsPanel:Show()
    local panel = CreatePanel()
    if not panel then return end
    
    UpdateContent()
    
    local bound = GetBoundKeybindings()
    if #bound > 0 then
        panel:Show()
        state.isVisible = true
    end
end

--- Hide the keybindings panel
function KeybindingsPanel:Hide()
    if state.frame then
        state.frame:Hide()
        state.isVisible = false
    end
end

--- Toggle the keybindings panel visibility
function KeybindingsPanel:Toggle()
    if state.isVisible then
        self:Hide()
    else
        self:Show()
    end
end

--- Check if the panel is visible
function KeybindingsPanel:IsVisible()
    return state.isVisible
end

--- Refresh the panel content (call when keybindings might have changed)
function KeybindingsPanel:Refresh()
    if state.isVisible then
        UpdateContent()
    end
end

--- Check if any BookArchivist keybindings are set
function KeybindingsPanel:HasAnyBindings()
    local bound = GetBoundKeybindings()
    return #bound > 0
end

return KeybindingsPanel
