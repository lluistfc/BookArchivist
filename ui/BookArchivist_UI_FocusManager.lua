---@diagnostic disable: undefined-global, undefined-field
--[[
    BookArchivist Focus Manager
    
    Provides keyboard navigation for accessibility using block-based navigation:
    - Blocks: Header, List, Reader
    - Tab/Shift+Tab: Cycle within current block
    - Block switching: Jump to first element of next/prev block
    - Enter/Space: Activate the focused element
    - Escape: Exit focus mode
    
    Shows a floating indicator panel displaying the current focus target.
]]

local addonRoot = BookArchivist
if not addonRoot or not addonRoot.UI then
    return
end

local FocusManager = {}
addonRoot.UI.FocusManager = FocusManager

local Internal = addonRoot.UI.Internal
local L = addonRoot.L or {}

local function t(key)
    return (L and L[key]) or key
end

-- Block definitions (navigation groups)
-- Each block contains related categories
-- Block 1 (Header): Top bar - Help, Options, New Book, Search, Sort
-- Block 2 (List): Books/Locations tabs, book rows, pagination
-- Block 3 (Reader): Reader actions (TTS, Copy, Waypoint, Favorite, Delete)
local FOCUS_BLOCKS = {
    {
        id = "header",
        name = "FOCUS_BLOCK_HEADER",
        categories = { "header", "filters" },  -- filters = search box, sort dropdown
    },
    {
        id = "list",
        name = "FOCUS_BLOCK_LIST",
        categories = { "tabs", "list", "pagination" },
    },
    {
        id = "reader",
        name = "FOCUS_BLOCK_READER",
        categories = { "reader" },
    },
}

-- Build category-to-block lookup
local categoryToBlock = {}
for blockIndex, block in ipairs(FOCUS_BLOCKS) do
    for _, cat in ipairs(block.categories) do
        categoryToBlock[cat] = blockIndex
    end
end

-- State management
local state = {
    enabled = false,           -- Is focus navigation active
    currentIndex = 0,          -- Index of currently focused element
    currentBlockIndex = 1,     -- Index of current block (1=header, 2=list, 3=reader)
    focusableElements = {},    -- Ordered list of focusable elements
    blockElements = {},        -- Elements grouped by block: { [blockIndex] = { elements } }
    highlightFrame = nil,      -- Visual highlight around focused element
    indicatorPanel = nil,      -- Floating panel showing focus target name
    lastScanTime = 0,          -- Debounce rescanning
}

-- Keybindings that already exist (don't include these in focus navigation)
local EXCLUDED_BINDINGS = {
    ["BookArchivistTTSButton"] = true,      -- Has TTS bindings
}

-- Categories for organizing focus order within blocks
local FOCUS_CATEGORIES = {
    "header",      -- Header buttons (Options, Help, etc.)
    "tabs",        -- Books/Locations tabs
    "filters",     -- Sort dropdown, search box
    "list",        -- List rows (current page only)
    "pagination",  -- Page navigation
    "reader",      -- Reader panel actions
}

-- Element registration
local registeredElements = {}

--[[
    Register a focusable element with the focus manager.
    
    @param id string - Unique identifier for the element
    @param frame Frame - The WoW frame to focus
    @param category string - One of FOCUS_CATEGORIES
    @param displayName string|function - Name to show in indicator (or function returning name)
    @param onActivate function - Called when user activates this element
    @param priority number - Order within category (lower = earlier)
]]
function FocusManager:RegisterElement(id, frame, category, displayName, onActivate, priority)
    if not id or not frame then
        return
    end
    
    registeredElements[id] = {
        id = id,
        frame = frame,
        category = category or "other",
        displayName = displayName or id,
        onActivate = onActivate,
        priority = priority or 100,
        isRegistered = true,
    }
    
    -- Mark element as focusable for scanning
    frame.bookArchivistFocusId = id
end

--[[
    Unregister a focusable element.
]]
function FocusManager:UnregisterElement(id)
    if registeredElements[id] then
        local elem = registeredElements[id]
        if elem.frame then
            elem.frame.bookArchivistFocusId = nil
        end
        registeredElements[id] = nil
    end
end

--[[
    Get the display name for an element.
]]
local function getDisplayName(elem)
    if not elem then
        return "Unknown"
    end
    if type(elem.displayName) == "function" then
        return elem.displayName() or elem.id
    end
    return elem.displayName or elem.id
end

--[[
    Get the block index for an element's category.
]]
local function getBlockIndex(category)
    return categoryToBlock[category] or 2 -- Default to "list" block
end

--[[
    Scan the UI to build an ordered list of visible, focusable elements.
    Also groups elements by block for block-based navigation.
]]
function FocusManager:ScanFocusableElements()
    local elements = {}
    
    -- First, add all registered elements that are visible
    for id, elem in pairs(registeredElements) do
        local frame = elem.frame
        if frame and frame.IsShown and frame:IsShown() and frame.IsVisible and frame:IsVisible() then
            if not EXCLUDED_BINDINGS[id] then
                table.insert(elements, elem)
            end
        end
    end
    
    -- Sort by category order, then by priority within category
    local categoryOrder = {}
    for i, cat in ipairs(FOCUS_CATEGORIES) do
        categoryOrder[cat] = i
    end
    categoryOrder["other"] = #FOCUS_CATEGORIES + 1
    
    table.sort(elements, function(a, b)
        local catA = categoryOrder[a.category] or 999
        local catB = categoryOrder[b.category] or 999
        if catA ~= catB then
            return catA < catB
        end
        return (a.priority or 100) < (b.priority or 100)
    end)
    
    state.focusableElements = elements
    
    -- Build block groupings
    state.blockElements = {}
    for i = 1, #FOCUS_BLOCKS do
        state.blockElements[i] = {}
    end
    
    for i, elem in ipairs(elements) do
        local blockIdx = getBlockIndex(elem.category)
        table.insert(state.blockElements[blockIdx], {
            globalIndex = i,
            element = elem,
        })
    end
    
    return elements
end

--[[
    Create the visual highlight frame that surrounds the focused element.
]]
local function createHighlightFrame()
    if state.highlightFrame then
        return state.highlightFrame
    end
    
    local frame = CreateFrame("Frame", "BookArchivistFocusHighlight", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(100)
    frame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
    })
    frame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0) -- Gold border
    frame:Hide()
    
    -- Simple border only - no glow texture
    state.highlightFrame = frame
    return frame
end

--[[
    Create the floating indicator panel that shows the current focus target.
]]
local function createIndicatorPanel()
    if state.indicatorPanel then
        return state.indicatorPanel
    end
    
    local frame = CreateFrame("Frame", "BookArchivistFocusIndicator", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetFrameLevel(200)
    frame:SetSize(340, 110)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.1, 0.1, 0.15, 0.95)
    frame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
    frame:Hide()
    
    -- === TOP ROW: Block Navigation ===
    -- Previous block (left arrow)
    local prevBlockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevBlockLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -8)
    prevBlockLabel:SetTextColor(0.5, 0.5, 0.5)
    prevBlockLabel:SetText("")
    frame.prevBlockLabel = prevBlockLabel
    
    -- Current block (center, prominent)
    local blockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blockLabel:SetPoint("TOP", frame, "TOP", 0, -8)
    blockLabel:SetTextColor(0.5, 0.8, 1.0)
    blockLabel:SetText("")
    frame.blockLabel = blockLabel
    
    -- Next block (right arrow)
    local nextBlockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nextBlockLabel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -8)
    nextBlockLabel:SetTextColor(0.5, 0.5, 0.5)
    nextBlockLabel:SetText("")
    frame.nextBlockLabel = nextBlockLabel
    
    -- Separator line (visual)
    local sep1 = frame:CreateTexture(nil, "ARTWORK")
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -26)
    sep1:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -26)
    sep1:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- === MIDDLE ROW: Current Element ===
    -- Category header
    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOP", frame, "TOP", 0, -32)
    header:SetTextColor(0.7, 0.7, 0.7)
    header:SetText("")
    frame.header = header
    
    -- Main focus target name (prominent, gold)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOP", header, "BOTTOM", 0, -2)
    label:SetTextColor(1.0, 0.82, 0.0)
    label:SetText("")
    frame.label = label
    
    -- Counter (current/total in block)
    local counter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    counter:SetPoint("TOP", label, "BOTTOM", 0, -2)
    counter:SetTextColor(0.6, 0.6, 0.6)
    counter:SetText("")
    frame.counter = counter
    
    -- Separator line 2
    local sep2 = frame:CreateTexture(nil, "ARTWORK")
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -78)
    sep2:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -78)
    sep2:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- === BOTTOM ROW: Prev/Next Elements ===
    -- Previous element (left)
    local prevElemLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevElemLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
    prevElemLabel:SetWidth(140)
    prevElemLabel:SetJustifyH("LEFT")
    prevElemLabel:SetTextColor(0.5, 0.5, 0.5)
    prevElemLabel:SetText("")
    frame.prevElemLabel = prevElemLabel
    
    -- Next element (right)
    local nextElemLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nextElemLabel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
    nextElemLabel:SetWidth(140)
    nextElemLabel:SetJustifyH("RIGHT")
    nextElemLabel:SetTextColor(0.5, 0.5, 0.5)
    nextElemLabel:SetText("")
    frame.nextElemLabel = nextElemLabel
    
    state.indicatorPanel = frame
    return frame
end

--[[
    Position the highlight frame around the target element.
]]
local function positionHighlight(targetFrame)
    local highlight = state.highlightFrame
    if not highlight or not targetFrame then
        return
    end
    
    highlight:ClearAllPoints()
    highlight:SetPoint("TOPLEFT", targetFrame, "TOPLEFT", -4, 4)
    highlight:SetPoint("BOTTOMRIGHT", targetFrame, "BOTTOMRIGHT", 4, -4)
    highlight:Show()
end

--[[
    Update the indicator panel with current focus information.
]]
local function updateIndicator()
    local panel = state.indicatorPanel
    if not panel then
        return
    end
    
    local elements = state.focusableElements
    local index = state.currentIndex
    
    if index < 1 or index > #elements then
        panel:Hide()
        return
    end
    
    local elem = elements[index]
    if not elem then
        panel:Hide()
        return
    end
    
    -- Get current block info
    local blockIdx = state.currentBlockIndex
    local block = FOCUS_BLOCKS[blockIdx]
    local blockElements = state.blockElements[blockIdx] or {}
    
    -- Find position within block
    local posInBlock = 0
    for i, be in ipairs(blockElements) do
        if be.globalIndex == index then
            posInBlock = i
            break
        end
    end
    
    -- === Update Block Navigation (top row) ===
    -- Arrow icon tags for inline textures
    local LEFT_ARROW = "|TInterface\\BUTTONS\\UI-SpellbookIcon-PrevPage-Up:12:12:0:0|t "
    local RIGHT_ARROW = " |TInterface\\BUTTONS\\UI-SpellbookIcon-NextPage-Up:12:12:0:0|t"
    
    -- Previous block
    local prevBlockIdx = blockIdx - 1
    if prevBlockIdx < 1 then prevBlockIdx = #FOCUS_BLOCKS end
    local prevBlock = FOCUS_BLOCKS[prevBlockIdx]
    local prevBlockHasElements = state.blockElements[prevBlockIdx] and #state.blockElements[prevBlockIdx] > 0
    if prevBlock and prevBlockHasElements then
        panel.prevBlockLabel:SetText(LEFT_ARROW .. t(prevBlock.name))
        panel.prevBlockLabel:SetTextColor(0.5, 0.7, 0.9)
    else
        panel.prevBlockLabel:SetText("")
    end
    
    -- Current block
    panel.blockLabel:SetText("[ " .. t(block.name) .. " ]")
    
    -- Next block
    local nextBlockIdx = blockIdx + 1
    if nextBlockIdx > #FOCUS_BLOCKS then nextBlockIdx = 1 end
    local nextBlock = FOCUS_BLOCKS[nextBlockIdx]
    local nextBlockHasElements = state.blockElements[nextBlockIdx] and #state.blockElements[nextBlockIdx] > 0
    if nextBlock and nextBlockHasElements then
        panel.nextBlockLabel:SetText(t(nextBlock.name) .. RIGHT_ARROW)
        panel.nextBlockLabel:SetTextColor(0.5, 0.7, 0.9)
    else
        panel.nextBlockLabel:SetText("")
    end
    
    -- === Update Current Element (middle row) ===
    panel.label:SetText(getDisplayName(elem))
    panel.header:SetText(t("FOCUS_CATEGORY_" .. string.upper(elem.category)) or elem.category)
    panel.counter:SetText(string.format("(%d / %d)", posInBlock, #blockElements))
    
    -- === Update Prev/Next Elements (bottom row) ===
    -- Previous element in block
    local prevPosInBlock = posInBlock - 1
    if prevPosInBlock < 1 then prevPosInBlock = #blockElements end
    local prevElem = blockElements[prevPosInBlock]
    if prevElem and prevElem.element and prevPosInBlock ~= posInBlock then
        local prevName = getDisplayName(prevElem.element)
        -- Truncate if too long
        if #prevName > 20 then
            prevName = prevName:sub(1, 18) .. "…"
        end
        panel.prevElemLabel:SetText(LEFT_ARROW .. prevName)
    else
        panel.prevElemLabel:SetText("")
    end
    
    -- Next element in block
    local nextPosInBlock = posInBlock + 1
    if nextPosInBlock > #blockElements then nextPosInBlock = 1 end
    local nextElem = blockElements[nextPosInBlock]
    if nextElem and nextElem.element and nextPosInBlock ~= posInBlock then
        local nextName = getDisplayName(nextElem.element)
        -- Truncate if too long
        if #nextName > 20 then
            nextName = nextName:sub(1, 18) .. "…"
        end
        panel.nextElemLabel:SetText(nextName .. RIGHT_ARROW)
    else
        panel.nextElemLabel:SetText("")
    end
    
    -- Resize frame to fit content (based on main label)
    local labelWidth = panel.label:GetStringWidth()
    local newWidth = math.max(340, labelWidth + 60)
    panel:SetWidth(newWidth)
    
    panel:Show()
end

--[[
    Focus on a specific element by index.
]]
function FocusManager:FocusElement(index)
    local elements = state.focusableElements
    if not elements or #elements == 0 then
        return false
    end
    
    -- Wrap around
    if index < 1 then
        index = #elements
    elseif index > #elements then
        index = 1
    end
    
    state.currentIndex = index
    
    local elem = elements[index]
    if not elem or not elem.frame then
        return false
    end
    
    -- Update current block index based on element's category
    state.currentBlockIndex = getBlockIndex(elem.category)
    
    -- Position highlight
    positionHighlight(elem.frame)
    
    -- Update indicator
    updateIndicator()
    
    -- Try to scroll the element into view if it's in a ScrollFrame
    local frame = elem.frame
    if frame.GetParent then
        local parent = frame:GetParent()
        -- Check if parent or grandparent is a scroll child
        for i = 1, 3 do
            if parent and parent.scrollToElement then
                parent:scrollToElement(frame)
                break
            elseif parent and parent.GetParent then
                parent = parent:GetParent()
            else
                break
            end
        end
    end
    
    return true
end

--[[
    Move focus to the next element within the current block.
]]
function FocusManager:FocusNext()
    if not state.enabled then
        self:Enable()
        return
    end
    
    -- Rescan if needed
    self:ScanFocusableElements()
    
    local blockIdx = state.currentBlockIndex
    local blockElements = state.blockElements[blockIdx]
    
    if not blockElements or #blockElements == 0 then
        -- No elements in current block, try next block
        if addonRoot and addonRoot.DebugPrint then
            addonRoot:DebugPrint(string.format("[FocusManager] FocusNext: block %d empty, switching block", blockIdx))
        end
        return self:NextBlock()
    end
    
    -- Find current position within block
    local currentPosInBlock = 0
    for i, be in ipairs(blockElements) do
        if be.globalIndex == state.currentIndex then
            currentPosInBlock = i
            break
        end
    end
    
    -- Move to next in block (wrap within block)
    local nextPosInBlock = currentPosInBlock + 1
    if nextPosInBlock > #blockElements then
        nextPosInBlock = 1
    end
    
    local nextElem = blockElements[nextPosInBlock]
    if nextElem then
        if addonRoot and addonRoot.DebugPrint then
            local elemName = nextElem.element.id or "unknown"
            local elemCat = nextElem.element.category or "?"
            addonRoot:DebugPrint(string.format("[FocusManager] FocusNext: %d/%d -> %s (%s)", 
                nextPosInBlock, #blockElements, elemName, elemCat))
        end
        return self:FocusElement(nextElem.globalIndex)
    end
    
    return false
end

--[[
    Move focus to the previous element within the current block.
]]
function FocusManager:FocusPrev()
    if not state.enabled then
        self:Enable()
        return
    end
    
    -- Rescan if needed
    self:ScanFocusableElements()
    
    local blockIdx = state.currentBlockIndex
    local blockElements = state.blockElements[blockIdx]
    
    if not blockElements or #blockElements == 0 then
        -- No elements in current block, try previous block
        return self:PrevBlock()
    end
    
    -- Find current position within block
    local currentPosInBlock = 0
    for i, be in ipairs(blockElements) do
        if be.globalIndex == state.currentIndex then
            currentPosInBlock = i
            break
        end
    end
    
    -- Move to previous in block (wrap within block)
    local prevPosInBlock = currentPosInBlock - 1
    if prevPosInBlock < 1 then
        prevPosInBlock = #blockElements
    end
    
    local prevElem = blockElements[prevPosInBlock]
    if prevElem then
        return self:FocusElement(prevElem.globalIndex)
    end
    
    return false
end

--[[
    Move to the next block and focus its first element.
]]
function FocusManager:NextBlock()
    if not state.enabled then
        self:Enable()
        return
    end
    
    self:ScanFocusableElements()
    
    local startBlock = state.currentBlockIndex
    local blockIdx = startBlock
    
    -- Try each block starting from next
    for attempt = 1, #FOCUS_BLOCKS do
        blockIdx = blockIdx + 1
        if blockIdx > #FOCUS_BLOCKS then
            blockIdx = 1
        end
        
        local blockElements = state.blockElements[blockIdx]
        if blockElements and #blockElements > 0 then
            state.currentBlockIndex = blockIdx
            return self:FocusElement(blockElements[1].globalIndex)
        end
    end
    
    return false
end

--[[
    Move to the previous block and focus its first element.
]]
function FocusManager:PrevBlock()
    if not state.enabled then
        self:Enable()
        return
    end
    
    self:ScanFocusableElements()
    
    local startBlock = state.currentBlockIndex
    local blockIdx = startBlock
    
    -- Try each block starting from previous
    for attempt = 1, #FOCUS_BLOCKS do
        blockIdx = blockIdx - 1
        if blockIdx < 1 then
            blockIdx = #FOCUS_BLOCKS
        end
        
        local blockElements = state.blockElements[blockIdx]
        if blockElements and #blockElements > 0 then
            state.currentBlockIndex = blockIdx
            return self:FocusElement(blockElements[1].globalIndex)
        end
    end
    
    return false
end

--[[
    Get current block name for display.
]]
function FocusManager:GetCurrentBlockName()
    local block = FOCUS_BLOCKS[state.currentBlockIndex]
    return block and t(block.name) or "Unknown"
end

--[[
    Activate the currently focused element.
]]
function FocusManager:ActivateCurrent()
    if not state.enabled then
        return false
    end
    
    local elements = state.focusableElements
    local index = state.currentIndex
    
    if index < 1 or index > #elements then
        return false
    end
    
    local elem = elements[index]
    if not elem then
        return false
    end
    
    -- Call custom activation handler if provided
    if elem.onActivate then
        local ok, err = pcall(elem.onActivate, elem.frame)
        if not ok and addonRoot.DebugPrint then
            addonRoot:DebugPrint("[FocusManager] Activation failed: " .. tostring(err))
        end
        return ok
    end
    
    -- Default: simulate a click on the frame
    local frame = elem.frame
    if frame then
        -- Check for different frame types
        if frame.Click then
            frame:Click()
            return true
        elseif frame.GetScript then
            local onClick = frame:GetScript("OnClick")
            if onClick then
                onClick(frame, "LeftButton", false)
                return true
            end
        end
        
        -- For EditBoxes, set focus
        if frame.SetFocus and frame.GetObjectType and frame:GetObjectType() == "EditBox" then
            frame:SetFocus()
            return true
        end
        
        -- For dropdowns - click the button child
        if frame.GetObjectType and frame:GetObjectType() == "Frame" then
            local name = frame:GetName()
            if name then
                -- Try standard dropdown button pattern
                local button = _G[name .. "Button"]
                if button and button.Click then
                    button:Click()
                    return true
                end
            end
        end
    end
    
    return false
end

--[[
    Enable focus navigation mode.
]]
function FocusManager:Enable()
    if state.enabled then
        return
    end
    
    state.enabled = true
    
    -- Create UI elements if needed
    createHighlightFrame()
    createIndicatorPanel()
    
    -- Scan for focusable elements
    self:ScanFocusableElements()
    
    -- Focus first element (start in list block by default if available)
    local startBlockIdx = 2 -- List block
    if state.blockElements[startBlockIdx] and #state.blockElements[startBlockIdx] > 0 then
        state.currentBlockIndex = startBlockIdx
        self:FocusElement(state.blockElements[startBlockIdx][1].globalIndex)
    elseif #state.focusableElements > 0 then
        self:FocusElement(1)
    else
        -- Show indicator with "no elements" message
        if state.indicatorPanel then
            state.indicatorPanel.blockLabel:SetText("")
            state.indicatorPanel.label:SetText(t("FOCUS_NO_ELEMENTS"))
            state.indicatorPanel.header:SetText("")
            state.indicatorPanel.counter:SetText("")
            state.indicatorPanel:Show()
        end
    end
    
    if addonRoot.DebugPrint then
        addonRoot:DebugPrint("[FocusManager] Enabled, found " .. #state.focusableElements .. " elements in " .. #FOCUS_BLOCKS .. " blocks")
    end
end

--[[
    Disable focus navigation mode.
]]
function FocusManager:Disable()
    if not state.enabled then
        return
    end
    
    state.enabled = false
    state.currentIndex = 0
    
    -- Hide UI elements
    if state.highlightFrame then
        state.highlightFrame:Hide()
    end
    if state.indicatorPanel then
        state.indicatorPanel:Hide()
    end
    
    if addonRoot.DebugPrint then
        addonRoot:DebugPrint("[FocusManager] Disabled")
    end
end

--[[
    Toggle focus navigation mode.
]]
function FocusManager:Toggle()
    if state.enabled then
        self:Disable()
    else
        self:Enable()
    end
end

--[[
    Check if focus mode is enabled.
]]
function FocusManager:IsEnabled()
    return state.enabled
end

--[[
    Refresh the focus list (call after UI changes).
]]
function FocusManager:Refresh()
    if not state.enabled then
        return
    end
    
    -- Debounce
    local now = GetTime and GetTime() or 0
    if now - state.lastScanTime < 0.1 then
        return
    end
    state.lastScanTime = now
    
    local oldIndex = state.currentIndex
    local oldId = nil
    if state.focusableElements[oldIndex] then
        oldId = state.focusableElements[oldIndex].id
    end
    
    -- Rescan
    self:ScanFocusableElements()
    
    -- Try to maintain focus on same element
    if oldId then
        for i, elem in ipairs(state.focusableElements) do
            if elem.id == oldId then
                self:FocusElement(i)
                return
            end
        end
    end
    
    -- Fallback to first element in current block if old one not found
    local blockElements = state.blockElements[state.currentBlockIndex]
    if blockElements and #blockElements > 0 then
        self:FocusElement(blockElements[1].globalIndex)
    elseif #state.focusableElements > 0 then
        self:FocusElement(math.min(oldIndex, #state.focusableElements))
    end
end

--[[
    Get current focus state (for debugging).
]]
function FocusManager:GetState()
    return {
        enabled = state.enabled,
        currentIndex = state.currentIndex,
        currentBlockIndex = state.currentBlockIndex,
        currentBlockName = self:GetCurrentBlockName(),
        totalElements = #state.focusableElements,
        currentElement = state.focusableElements[state.currentIndex],
        blockCounts = {
            header = state.blockElements[1] and #state.blockElements[1] or 0,
            list = state.blockElements[2] and #state.blockElements[2] or 0,
            reader = state.blockElements[3] and #state.blockElements[3] or 0,
        },
    }
end

--[[
    Get current block ID for contextual actions.
    Returns "header", "list", "reader", or nil if not in focus mode.
]]
function FocusManager:GetCurrentBlockId()
    if not state.enabled then
        return nil
    end
    local block = FOCUS_BLOCKS[state.currentBlockIndex]
    return block and block.id or nil
end

-- Export for binding handlers
-- All focus functions require UI to be visible
addonRoot.FocusNext = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:FocusNext()
end

addonRoot.FocusPrev = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:FocusPrev()
end

addonRoot.FocusActivate = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:ActivateCurrent()
end

addonRoot.FocusToggle = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:Toggle()
end

addonRoot.FocusNextBlock = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:NextBlock()
end

addonRoot.FocusPrevBlock = function()
    if not addonRoot:IsUIVisible() then
        return
    end
    FocusManager:PrevBlock()
end

return FocusManager
