---@diagnostic disable: undefined-global, undefined-field
local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
if not ReaderUI then
	return
end

local rememberWidget = ReaderUI.__rememberWidget
local getWidget = ReaderUI.__getWidget
local getAddon = ReaderUI.__getAddon
local safeCreateFrame = ReaderUI.__safeCreateFrame
local getSelectedKey = ReaderUI.__getSelectedKey
local setSelectedKey = ReaderUI.__setSelectedKey
local chatMessage = ReaderUI.__chatMessage
local state = ReaderUI.__state or {}
ReaderUI.__state = state
local debugPrint = function(...)
	BookArchivist:DebugPrint(...)
end

local function deleteDebug(...)
	local args = { ... }
	if #args == 0 then
		return
	end
	table.insert(args, 1, "[BookArchivist][DeleteBtn]")
	BookArchivist:DebugPrint(table.unpack(args))
end

local function describeFrame(frame)
	if not frame then
		return "<nil>"
	end
	local ok, name
	if type(frame.GetName) == "function" then
		ok, name = pcall(frame.GetName, frame)
		if ok and name and name ~= "" then
			return name
		end
	end
	if type(frame.GetDebugName) == "function" then
		ok, name = pcall(frame.GetDebugName, frame)
		if ok and name and name ~= "" then
			return name
		end
	end
	return tostring(frame)
end

local function configureDeleteButton(button)
	if not button then
		return
	end
	button:SetSize(100, 22)
	button:SetText("Delete")
	button:SetNormalFontObject("GameFontNormal")
	button:Disable()
	button:SetMotionScriptsWhileDisabled(true)
	button:SetScript("OnEnter", function(self)
		if not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self:IsEnabled() then
			GameTooltip:SetText("Delete this book", 1, 1, 1)
			GameTooltip:AddLine("This will permanently remove the book from your archive.", 1, 0.82, 0, true)
		else
			GameTooltip:SetText("Select a saved book", 1, 0.9, 0)
			GameTooltip:AddLine("Choose a book from the list to enable deletion.", 0.9, 0.9, 0.9, true)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	button:SetScript("OnClick", function()
		local addon = getAddon and getAddon()
		if not addon then
			return
		end
		local key = getSelectedKey and getSelectedKey()
		if key then
			addon:Delete(key)
			if setSelectedKey then
				setSelectedKey(nil)
			end
			if ReaderUI.RenderSelected then
				ReaderUI:RenderSelected()
			end
			if chatMessage then
				chatMessage("|cFFFF0000Book deleted from archive.|r")
			end
		end
	end)
end

local function buildDeleteButton(parent)
	if not parent then
		deleteDebug("buildDeleteButton: parent missing; abort")
		return nil
	end

	deleteDebug("buildDeleteButton: starting", describeFrame(parent))

	local button
	if safeCreateFrame then
		deleteDebug("buildDeleteButton: attempting safeCreateFrame with named button")
		button = safeCreateFrame("Button", "BookArchivistDeleteButton", parent, "UIPanelButtonTemplate")
		if not button then
			deleteDebug("buildDeleteButton: named creation failed, retrying anonymous")
			button = safeCreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		end
	end

	if not button and CreateFrame then
		deleteDebug("buildDeleteButton: fallback to CreateFrame")
		local ok, created = pcall(CreateFrame, "Button", nil, parent, "UIPanelButtonTemplate")
		if ok then
			button = created
		else
			deleteDebug("buildDeleteButton: CreateFrame pcall failed", tostring(created))
		end
	end

	if button then
		deleteDebug("buildDeleteButton: success", describeFrame(button))
	else
		deleteDebug("buildDeleteButton: failed to create button (returning nil)")
	end

	return button
end

local function anchorDeleteButton(button, parent)
	if not button or not parent then
		return
	end
	button:SetSize(120, 24)
	button:ClearAllPoints()
	button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -8)
	local levelSource = (parent.GetFrameLevel and parent:GetFrameLevel()) or 0
	button:SetFrameLevel(math.min(levelSource + 25, 128))
	local strataSource
	if state.uiFrame and state.uiFrame.GetFrameStrata then
		strataSource = state.uiFrame:GetFrameStrata()
	end
	if not strataSource and parent.GetFrameStrata then
		strataSource = parent:GetFrameStrata()
	end
	button:SetFrameStrata(strataSource or "MEDIUM")
	button:SetToplevel(true)
end

local function ensureDeleteButton(parent)
	parent = parent or state.readerBlock or state.uiFrame
	if not parent then
		deleteDebug("ensureDeleteButton: parent missing")
		return nil
	end

	local button = state.deleteButton
	if not button or not button.IsObjectType or not button:IsObjectType("Button") then
		deleteDebug("ensureDeleteButton: creating new button on", describeFrame(parent))
		button = buildDeleteButton(parent)
		if not button then
			deleteDebug("ensureDeleteButton: creation failed")
			return nil
		end
		state.deleteButton = button
		if rememberWidget then
			rememberWidget("deleteBtn", button)
		end
		if state.uiFrame then
			state.uiFrame.deleteBtn = button
		end
		configureDeleteButton(button)
	else
		deleteDebug("ensureDeleteButton: reusing existing button", describeFrame(button))
	end

	if button:GetParent() ~= parent then
		button:SetParent(parent)
	end

	anchorDeleteButton(button, parent)
	button:Show()
	return button
end

ReaderUI.__ensureDeleteButton = ensureDeleteButton

function ReaderUI:Create(uiFrame, anchorFrame)
	if not uiFrame then
		return
	end

	state.uiFrame = uiFrame
	local parent = anchorFrame or uiFrame
	local readerBlock = safeCreateFrame and safeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate")
	if not readerBlock then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader panel.")
		end
		return
	end
	readerBlock:SetPoint("TOPLEFT", parent, "TOPRIGHT", 4, 0)
	readerBlock:SetPoint("BOTTOMRIGHT", uiFrame, "BOTTOMRIGHT", -6, 4)
	uiFrame.readerBlock = readerBlock
	state.readerBlock = readerBlock

	local readerHeader = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	readerHeader:SetPoint("TOPLEFT", readerBlock, "TOPLEFT", 8, -8)
	readerHeader:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -150, -8)
	readerHeader:SetText("Book Reader")

	local readerSeparator = readerBlock:CreateTexture(nil, "ARTWORK")
	readerSeparator:SetHeight(1)
	readerSeparator:SetPoint("TOPLEFT", readerHeader, "BOTTOMLEFT", -4, -4)
	readerSeparator:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -8, -28)
	readerSeparator:SetColorTexture(0.25, 0.25, 0.25, 1)

	local bookTitle = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	state.bookTitle = bookTitle
	if rememberWidget then
		rememberWidget("bookTitle", bookTitle)
	end
	bookTitle:SetPoint("TOPLEFT", readerSeparator, "BOTTOMLEFT", 4, -8)
	bookTitle:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -12, -36)
	bookTitle:SetJustifyH("LEFT")
	bookTitle:SetText("Select a book from the list")
	bookTitle:SetTextColor(1, 0.82, 0)
	uiFrame.bookTitle = bookTitle

	local metaDisplay = readerBlock:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	state.metaDisplay = metaDisplay
	if rememberWidget then
		rememberWidget("meta", metaDisplay)
	end
	metaDisplay:SetPoint("TOPLEFT", bookTitle, "BOTTOMLEFT", 0, -6)
	metaDisplay:SetPoint("TOPRIGHT", bookTitle, "BOTTOMRIGHT", 0, -6)
	metaDisplay:SetJustifyH("LEFT")
	metaDisplay:SetText("")
	uiFrame.meta = metaDisplay

	local divider = readerBlock:CreateTexture(nil, "ARTWORK")
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", metaDisplay, "BOTTOMLEFT", -4, -8)
	divider:SetPoint("TOPRIGHT", metaDisplay, "BOTTOMRIGHT", 4, -8)
	divider:SetColorTexture(0.25, 0.25, 0.25, 0.5)

	local textScroll = safeCreateFrame and safeCreateFrame("ScrollFrame", "BookArchivistTextScroll", readerBlock, "UIPanelScrollFrameTemplate")
	if not textScroll then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader scroll frame.")
		end
		return
	end
	if rememberWidget then
		rememberWidget("textScroll", textScroll)
	end
	state.textScroll = textScroll
	textScroll:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 4, -6)
	textScroll:SetPoint("BOTTOMRIGHT", readerBlock, "BOTTOMRIGHT", -28, 52)
	uiFrame.textScroll = textScroll

	local textChild = CreateFrame("Frame", nil, textScroll)
	textChild:SetSize(1, 1)
	textScroll:SetScrollChild(textChild)
	if rememberWidget then
		rememberWidget("textChild", textChild)
	end
	state.textChild = textChild
	uiFrame.textChild = textChild

	local textPlain = textChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if rememberWidget then
		rememberWidget("textPlain", textPlain)
	end
	state.textPlain = textPlain
	textPlain:SetPoint("TOPLEFT", 6, -6)
	textPlain:SetJustifyH("LEFT")
	textPlain:SetJustifyV("TOP")
	textPlain:SetSpacing(2)
	textPlain:SetWidth(460)

	local htmlFrame
	local htmlCreated = pcall(function()
		htmlFrame = CreateFrame("SimpleHTML", nil, textChild)
	end)
	if htmlCreated and htmlFrame then
		state.htmlText = htmlFrame
		if rememberWidget then
			rememberWidget("htmlText", htmlFrame)
		end
		htmlFrame:SetPoint("TOPLEFT", 6, -6)
		htmlFrame:SetPoint("TOPRIGHT", -12, -6)
		htmlFrame:SetFontObject("GameFontNormal")
		htmlFrame:SetSpacing(2)
		htmlFrame:SetWidth(460)
		htmlFrame:Hide()
		uiFrame.htmlText = htmlFrame
	else
		state.htmlText = nil
		if rememberWidget then
			rememberWidget("htmlText", nil)
		end
	end

	local deleteButton = ensureDeleteButton(readerBlock)
	if not deleteButton then
		deleteDebug("ReaderUI:Create deleteButton creation failed; logging error")
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("BookArchivist delete button failed to initialize.")
		end
	end

	local countTextParent = uiFrame or readerBlock
	local countText = countTextParent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	if rememberWidget then
		rememberWidget("countText", countText)
	end
	state.countText = countText
	countText:ClearAllPoints()
	countText:SetPoint("BOTTOMRIGHT", readerBlock, "BOTTOMRIGHT", -12, 14)
	countText:SetJustifyH("RIGHT")
	countText:SetText("|cFF888888Books saved as you read them in-game|r")
	uiFrame.countText = countText

	debugPrint("[BookArchivist] ReaderUI created")
end
