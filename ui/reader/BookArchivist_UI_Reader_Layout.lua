---@diagnostic disable: undefined-global, undefined-field
local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
if not ReaderUI then
	return
end

local Metrics = BookArchivist.UI.Metrics or {
	PAD = 12,
	GUTTER = 10,
	HEADER_H = 70,
	SUBHEADER_H = 34,
	READER_HEADER_H = 54,
	ROW_H = 36,
	BTN_H = 22,
	BTN_W = 90,
}
local Internal = BookArchivist.UI.Internal

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

StaticPopupDialogs = StaticPopupDialogs or {}
if not StaticPopupDialogs.BOOKARCHIVIST_CONFIRM_DELETE then
	StaticPopupDialogs.BOOKARCHIVIST_CONFIRM_DELETE = {
		text = "Delete '%s'? This cannot be undone.",
		button1 = YES,
		button2 = NO,
		OnAccept = function(_, data)
			if data and data.onAccept then
				data.onAccept()
			end
		end,
		hideOnEscape = true,
		whileDead = true,
		timeout = 0,
		preferredIndex = 3,
	}
end

local tableUnpack = table and table.unpack or nil
---@diagnostic disable-next-line: deprecated
local fallbackUnpack = type(_G) == "table" and (_G.unpack or _G.table and _G.table.unpack) or nil

local unsupportedHTMLFontTags = {}
local unsupportedHTMLSpacingTags = {}

local function resolveFontObject(font)
	if type(font) == "string" then
		local globalFonts = _G or {}
		return globalFonts[font] or font
	end
	return font
end

local function safeHTMLCall(frame, methodName, ...)
	if not frame or type(frame[methodName]) ~= "function" then
		return false
	end
	local ok, err = pcall(frame[methodName], frame, ...)
	if not ok and debugPrint then
		debugPrint(string.format("[BookArchivist] ReaderUI %s failed: %s", tostring(methodName), tostring(err)))
	end
	return ok
end

local function applyHTMLFont(frame, tag, font)
	if not font or unsupportedHTMLFontTags[tag] then
		return
	end
	local resolved = resolveFontObject(font)
	if not safeHTMLCall(frame, "SetFontObject", tag, resolved) then
		unsupportedHTMLFontTags[tag] = true
	end
end

local function applyHTMLSpacing(frame, tag, amount)
	if not amount or unsupportedHTMLSpacingTags[tag] then
		return
	end
	if not safeHTMLCall(frame, "SetSpacing", tag, amount) then
		unsupportedHTMLSpacingTags[tag] = true
	end
end

local function deleteDebug(...)
	local args = { ... }
	if #args == 0 then
		return
	end
	table.insert(args, 1, "[BookArchivist][DeleteBtn]")
	if tableUnpack then
		BookArchivist:DebugPrint(tableUnpack(args))
	elseif fallbackUnpack then
		BookArchivist:DebugPrint(fallbackUnpack(args))
	else
		BookArchivist:DebugPrint(table.concat(args, " "))
	end
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
	button:SetSize(Metrics.BTN_W + 20, Metrics.BTN_H)
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
			local db = addon.GetDB and addon:GetDB()
			local entry = db and db.books and db.books[key]
			local title = entry and entry.title or key
			if StaticPopup_Show then
				StaticPopup_Show("BOOKARCHIVIST_CONFIRM_DELETE", title, nil, {
					onAccept = function()
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
					end,
				})
			else
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
	button:SetHeight(Metrics.BTN_H)
	button:ClearAllPoints()
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	button:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
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
	local readerBlock = uiFrame.ReaderInset or uiFrame.readerBlock
	if not readerBlock and safeCreateFrame then
		readerBlock = safeCreateFrame("Frame", nil, uiFrame, "InsetFrameTemplate")
		local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
		readerBlock:SetPoint("TOPRIGHT", (uiFrame.BodyFrame or uiFrame), "TOPRIGHT", -padInset, -padInset)
		readerBlock:SetPoint("BOTTOMRIGHT", (uiFrame.BodyFrame or uiFrame), "BOTTOMRIGHT", -padInset, padInset)
		local gap = Metrics.SEPARATOR_GAP or Metrics.GAP_S or 6
		readerBlock:SetPoint("TOPLEFT", parent, "TOPRIGHT", gap, 0)
		readerBlock:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", gap, 0)
		uiFrame.readerBlock = readerBlock
	end
	if not readerBlock then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader panel.")
		end
		return
	end
	state.readerBlock = readerBlock
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("reader-inset", readerBlock)
	end

	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local gap = Metrics.GAP_S or Metrics.GAP_XS or 6

	local readerHeaderRow = safeCreateFrame and safeCreateFrame("Frame", nil, readerBlock)
	if not readerHeaderRow then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader header row.")
		end
		return
	end
	readerHeaderRow:ClearAllPoints()
	readerHeaderRow:SetPoint("TOPLEFT", readerBlock, "TOPLEFT", padInset, -padInset)
	readerHeaderRow:SetPoint("TOPRIGHT", readerBlock, "TOPRIGHT", -padInset, -padInset)
	readerHeaderRow:SetHeight(Metrics.READER_HEADER_H or Metrics.SUBHEADER_H or 54)
	state.readerHeader = readerHeaderRow
	if rememberWidget then
		rememberWidget("readerHeader", readerHeaderRow)
	end
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("reader-header-row", readerHeaderRow)
	end

	local actionsRail = safeCreateFrame and safeCreateFrame("Frame", nil, readerHeaderRow)
	if actionsRail then
		actionsRail:ClearAllPoints()
		actionsRail:SetPoint("TOPRIGHT", readerHeaderRow, "TOPRIGHT", 0, 0)
		actionsRail:SetPoint("BOTTOMRIGHT", readerHeaderRow, "BOTTOMRIGHT", 0, 0)
		actionsRail:SetWidth(Metrics.READER_ACTIONS_W or Metrics.HEADER_RIGHT_STACK_W or 130)
		state.readerActionsRail = actionsRail
		if rememberWidget then
			rememberWidget("readerActionsRail", actionsRail)
		end
		if Internal and Internal.registerGridTarget then
			Internal.registerGridTarget("reader-actions-rail", actionsRail)
		end
	end

	local bookTitle = readerHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	state.bookTitle = bookTitle
	if rememberWidget then
		rememberWidget("bookTitle", bookTitle)
	end
	bookTitle:SetJustifyH("LEFT")
	bookTitle:SetJustifyV("MIDDLE")
	bookTitle:SetText("Select a book from the list")
	bookTitle:SetTextColor(1, 0.82, 0)
	uiFrame.bookTitle = bookTitle
	bookTitle:ClearAllPoints()
	bookTitle:SetPoint("TOPLEFT", readerHeaderRow, "TOPLEFT", 0, 0)
	if actionsRail then
		bookTitle:SetPoint("TOPRIGHT", actionsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
	else
		bookTitle:SetPoint("TOPRIGHT", readerHeaderRow, "TOPRIGHT", 0, 0)
	end
	bookTitle:SetPoint("BOTTOM", readerHeaderRow, "CENTER", 0, 0)

	local metaDisplay = readerHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	state.metaDisplay = metaDisplay
	if rememberWidget then
		rememberWidget("meta", metaDisplay)
	end
	metaDisplay:ClearAllPoints()
	metaDisplay:SetPoint("TOPLEFT", bookTitle, "BOTTOMLEFT", 0, -(Metrics.GAP_XS or 2))
	if actionsRail then
		metaDisplay:SetPoint("TOPRIGHT", actionsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
	else
		metaDisplay:SetPoint("TOPRIGHT", readerHeaderRow, "TOPRIGHT", 0, 0)
	end
	metaDisplay:SetPoint("BOTTOM", readerHeaderRow, "BOTTOM", 0, 0)
	metaDisplay:SetJustifyH("LEFT")
	metaDisplay:SetJustifyV("TOP")
	metaDisplay:SetSpacing(1.5)
	metaDisplay:SetWordWrap(true)
	metaDisplay:SetText("")
	uiFrame.meta = metaDisplay

	local readerNavRow = safeCreateFrame and safeCreateFrame("Frame", nil, readerBlock)
	if readerNavRow then
		readerNavRow:ClearAllPoints()
		readerNavRow:SetPoint("TOPLEFT", readerHeaderRow, "BOTTOMLEFT", 0, -gap)
		readerNavRow:SetPoint("TOPRIGHT", readerHeaderRow, "BOTTOMRIGHT", 0, -gap)
		readerNavRow:SetHeight(Metrics.NAV_ROW_H or Metrics.BTN_H + 6)
		state.readerNavRow = readerNavRow
		if rememberWidget then
			rememberWidget("readerNavRow", readerNavRow)
		end
		if Internal and Internal.registerGridTarget then
			Internal.registerGridTarget("reader-nav-row", readerNavRow)
		end
	end

	local prevButton = safeCreateFrame and safeCreateFrame("Button", nil, readerNavRow or readerHeaderRow, "UIPanelButtonTemplate")
	if prevButton then
		prevButton:SetSize(Metrics.BTN_W - 10, Metrics.BTN_H)
		prevButton:SetPoint("LEFT", readerNavRow or readerHeaderRow, "LEFT", 0, 0)
		prevButton:SetText("< Prev")
		prevButton:SetScript("OnClick", function()
			if ReaderUI.ChangePage then
				ReaderUI:ChangePage(-1)
			end
		end)
		if rememberWidget then
			rememberWidget("prevButton", prevButton)
		end
	end
	state.prevButton = prevButton

	local nextButton = safeCreateFrame and safeCreateFrame("Button", nil, readerNavRow or readerHeaderRow, "UIPanelButtonTemplate")
	if nextButton then
		nextButton:SetSize(Metrics.BTN_W - 10, Metrics.BTN_H)
		nextButton:SetPoint("RIGHT", readerNavRow or readerHeaderRow, "RIGHT", 0, 0)
		nextButton:SetText("Next >")
		nextButton:SetScript("OnClick", function()
			if ReaderUI.ChangePage then
				ReaderUI:ChangePage(1)
			end
		end)
		if rememberWidget then
			rememberWidget("nextButton", nextButton)
		end
	end
	state.nextButton = nextButton

	local pageIndicatorParent = readerNavRow or readerHeaderRow
	local pageIndicator = pageIndicatorParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	pageIndicator:SetPoint("CENTER", pageIndicatorParent, "CENTER", 0, 0)
	pageIndicator:SetJustifyH("CENTER")
	pageIndicator:SetJustifyV("MIDDLE")
	pageIndicator:SetText("Page 1 / 1")
	state.pageIndicator = pageIndicator
	if rememberWidget then
		rememberWidget("pageIndicator", pageIndicator)
	end

	local readerScrollRow = safeCreateFrame and safeCreateFrame("Frame", nil, readerBlock)
	if readerScrollRow then
		readerScrollRow:ClearAllPoints()
		readerScrollRow:SetPoint("TOPLEFT", readerNavRow or readerHeaderRow, "BOTTOMLEFT", 0, -gap)
		readerScrollRow:SetPoint("TOPRIGHT", readerNavRow or readerHeaderRow, "BOTTOMRIGHT", 0, -gap)
		readerScrollRow:SetPoint("BOTTOMLEFT", readerBlock, "BOTTOMLEFT", padInset, padInset)
		readerScrollRow:SetPoint("BOTTOMRIGHT", readerBlock, "BOTTOMRIGHT", -padInset, padInset)
		state.readerScrollRow = readerScrollRow
		if rememberWidget then
			rememberWidget("readerScrollRow", readerScrollRow)
		end
		if Internal and Internal.registerGridTarget then
			Internal.registerGridTarget("reader-scroll-row", readerScrollRow)
		end
	end

	local textScroll = safeCreateFrame and safeCreateFrame("ScrollFrame", "BookArchivistTextScroll", readerScrollRow or readerBlock, "UIPanelScrollFrameTemplate")
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
	local innerPad = Metrics.PAD_INSET or Metrics.PAD or 10
	textScroll:ClearAllPoints()
	local scrollBar = textScroll.ScrollBar or _G[(textScroll:GetName() or "") .. "ScrollBar"]
	local sbW = (scrollBar and scrollBar.GetWidth and scrollBar:GetWidth()) or 16
	local gutter = Metrics.SCROLLBAR_GUTTER or math.ceil(sbW + 10)
	textScroll:SetPoint("TOPLEFT", readerScrollRow or readerBlock, "TOPLEFT", innerPad, -innerPad)
	textScroll:SetPoint("BOTTOMRIGHT", readerScrollRow or readerBlock, "BOTTOMRIGHT", -innerPad, innerPad)
	uiFrame.textScroll = textScroll
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("reader-scroll", textScroll)
	end

	local contentHost = (safeCreateFrame and safeCreateFrame("Frame", nil, textScroll)) or CreateFrame("Frame", nil, textScroll)
	contentHost:ClearAllPoints()
	contentHost:SetPoint("TOPLEFT", textScroll, "TOPLEFT", innerPad, -innerPad)
	contentHost:SetPoint("BOTTOMLEFT", textScroll, "BOTTOMLEFT", innerPad, innerPad)
	contentHost:SetPoint("RIGHT", textScroll, "RIGHT", -(innerPad + gutter), 0)
	state.contentHost = contentHost
	if rememberWidget then
		rememberWidget("contentHost", contentHost)
	end

	local textChild = CreateFrame("Frame", nil, textScroll)
	textChild:ClearAllPoints()
	textChild:SetPoint("TOPLEFT", contentHost, "TOPLEFT", 0, 0)
	textChild:SetPoint("TOPRIGHT", contentHost, "TOPRIGHT", 0, 0)
	textChild:SetHeight(1)
	textScroll:SetScrollChild(textChild)
	if rememberWidget then
		rememberWidget("textChild", textChild)
	end
	state.textChild = textChild
	uiFrame.textChild = textChild

	local textPad = math.floor((Metrics.PAD or 12) * 0.5)
	local textPlain = textChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	if rememberWidget then
		rememberWidget("textPlain", textPlain)
	end
	state.textPlain = textPlain
	textPlain:ClearAllPoints()
	textPlain:SetPoint("TOPLEFT", textChild, "TOPLEFT", textPad, -textPad)
	textPlain:SetPoint("TOPRIGHT", textChild, "TOPRIGHT", -textPad, -textPad)
	textPlain:SetJustifyH("LEFT")
	textPlain:SetJustifyV("TOP")
	textPlain:SetSpacing(3.5)
	if textPlain.SetWordWrap then
		textPlain:SetWordWrap(true)
	end
	if textPlain.SetNonSpaceWrap then
		textPlain:SetNonSpaceWrap(true)
	end

	local htmlFrame
	local htmlCreated = pcall(function()
		htmlFrame = CreateFrame("SimpleHTML", nil, textChild)
	end)
	if htmlCreated and htmlFrame then
		state.htmlText = htmlFrame
		if rememberWidget then
			rememberWidget("htmlText", htmlFrame)
		end
		htmlFrame:ClearAllPoints()
		htmlFrame:SetPoint("TOPLEFT", textChild, "TOPLEFT", textPad, -textPad)
		htmlFrame:SetPoint("TOPRIGHT", textChild, "TOPRIGHT", -textPad, -textPad)
		local bodyFont = GameFontNormal or "GameFontNormal"
		local headingFont = GameFontNormalLarge or bodyFont
		local subHeadingFont = GameFontHighlight or bodyFont
		applyHTMLFont(htmlFrame, "p", bodyFont)
		applyHTMLFont(htmlFrame, "li", bodyFont)
		applyHTMLFont(htmlFrame, "h1", headingFont)
		applyHTMLFont(htmlFrame, "h2", subHeadingFont)
		applyHTMLFont(htmlFrame, "h3", subHeadingFont)
		applyHTMLSpacing(htmlFrame, "p", 2)
		applyHTMLSpacing(htmlFrame, "li", 2)
		htmlFrame:Hide()
		uiFrame.htmlText = htmlFrame
	else
		state.htmlText = nil
		if rememberWidget then
			rememberWidget("htmlText", nil)
		end
	end

	-- Width is governed by anchors to contentHost; no explicit SetWidth needed.

	local deleteParent = actionsRail or readerHeaderRow
	local deleteButton = ensureDeleteButton(deleteParent)
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
	countText:SetPoint("BOTTOMRIGHT", readerBlock, "BOTTOMRIGHT", -Metrics.PAD, Metrics.PAD)
	countText:SetJustifyH("RIGHT")
	countText:SetJustifyV("MIDDLE")
	countText:SetText("|cFF888888Books saved as you read them in-game|r")
	uiFrame.countText = countText

	debugPrint("[BookArchivist] ReaderUI created")
end
