---@diagnostic disable: undefined-global, undefined-field
local ReaderUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader
if not ReaderUI then
	return
end

local Metrics = BookArchivist.UI.Metrics
	or {
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

local L = BookArchivist and BookArchivist.L or {}
local function t(key)
	return (L and L[key]) or key
end

local rememberWidget = ReaderUI.__rememberWidget
local getAddon = ReaderUI.__getAddon
local safeCreateFrame = ReaderUI.__safeCreateFrame
local state = ReaderUI.__state or {}
ReaderUI.__state = state
local debugPrint = function(...)
	BookArchivist:DebugPrint(...)
end

local unsupportedHTMLFontTags = {}
local unsupportedHTMLSpacingTags = {}

local function syncFavoriteVisual(button, isFavorite)
	if not button then
		return
	end
	local isFav = isFavorite and true or false
	if button.starOn and button.starOff then
		button.starOn:SetShown(isFav)
		button.starOff:SetShown(not isFav)
	end
	if button.SetChecked then
		button:SetChecked(isFav)
	end
end

-- Expose for ReaderUI:RenderSelected so the reader controller can
-- drive the same visual treatment when selection changes.
ReaderUI.__syncFavoriteVisual = syncFavoriteVisual

local function resolveFontObject(font)
	if type(font) == "string" then
		local globalFonts = _G or {}
		local resolved = globalFonts[font]
		-- If font string doesn't resolve to an actual font object, return nil
		-- to prevent SetFontObject errors
		if type(resolved) ~= "table" and type(resolved) ~= "userdata" then
			return nil
		end
		return resolved
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
	local resolved = resolveFontObject(font) -- Skip if font didn't resolve to valid object
	if not resolved then
		return
	end
	-- SimpleHTML uses SetFont(tag, fontPath, size, flags) NOT SetFontObject
	-- We need to extract font properties from the FontObject
	if resolved.GetFont then
		local fontPath, fontSize, fontFlags = resolved:GetFont()
		if fontPath and fontSize then
			if not safeHTMLCall(frame, "SetFont", tag, fontPath, fontSize, fontFlags or "") then
				unsupportedHTMLFontTags[tag] = true
			end
		end
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
	bookTitle:SetJustifyV("TOP")
	bookTitle:SetWordWrap(true)  -- Enable word wrap for long titles
	bookTitle:SetText(t("READER_EMPTY_PROMPT"))
	bookTitle:SetTextColor(1, 0.82, 0)
	uiFrame.bookTitle = bookTitle
	bookTitle:ClearAllPoints()
	bookTitle:SetPoint("TOPLEFT", readerHeaderRow, "TOPLEFT", 0, 0)
	if actionsRail then
		bookTitle:SetPoint("RIGHT", actionsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
	else
		bookTitle:SetPoint("RIGHT", readerHeaderRow, "RIGHT", 0, 0)
	end
	-- Height will be determined by content, not anchored to bottom

	-- Echo text (Book Echo memory reflection)
	local echoText = readerHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	state.echoText = echoText
	if rememberWidget then
		rememberWidget("echoText", echoText)
	end
	echoText:ClearAllPoints()
	echoText:SetPoint("TOPLEFT", bookTitle, "BOTTOMLEFT", 0, -2)
	if actionsRail then
		echoText:SetPoint("TOPRIGHT", actionsRail, "LEFT", -(Metrics.GAP_M or Metrics.GUTTER), 0)
	else
		echoText:SetPoint("TOPRIGHT", readerHeaderRow, "TOPRIGHT", 0, 0)
	end
	echoText:SetJustifyH("LEFT")
	echoText:SetWordWrap(true)
	echoText:SetTextColor(0.7, 0.7, 0.7, 0.8)
	-- Make italic if possible
	local font, size = echoText:GetFont()
	if font then
		echoText:SetFont(font, size, "ITALIC")
	end
	echoText:SetText("")
	echoText:Hide()
	uiFrame.echoText = echoText

	local metaDisplay = readerHeaderRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	state.metaDisplay = metaDisplay
	if rememberWidget then
		rememberWidget("meta", metaDisplay)
	end
	metaDisplay:ClearAllPoints()
	metaDisplay:SetPoint("TOPLEFT", echoText, "BOTTOMLEFT", 0, -(Metrics.GAP_XS or 2))
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

	local prevButton = safeCreateFrame
		and safeCreateFrame("Button", nil, readerNavRow or readerHeaderRow, "UIPanelButtonTemplate")
	if prevButton then
		prevButton:SetSize(Metrics.BTN_W - 10, 22)
		prevButton:SetPoint("LEFT", readerNavRow or readerHeaderRow, "LEFT", 0, 0)
		prevButton:SetText(t("PAGINATION_PREV"))
		prevButton:SetNormalFontObject(GameFontNormal)
		local fontString = prevButton:GetFontString()
		if fontString then
			fontString:SetTextColor(1.0, 0.82, 0.0)
		end
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

	local nextButton = safeCreateFrame
		and safeCreateFrame("Button", nil, readerNavRow or readerHeaderRow, "UIPanelButtonTemplate")
	if nextButton then
		nextButton:SetSize(Metrics.BTN_W - 10, 22)
		nextButton:SetPoint("RIGHT", readerNavRow or readerHeaderRow, "RIGHT", 0, 0)
		nextButton:SetText(t("PAGINATION_NEXT"))
		nextButton:SetNormalFontObject(GameFontNormal)
		local fontString = nextButton:GetFontString()
		if fontString then
			fontString:SetTextColor(1.0, 0.82, 0.0)
		end

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

	-- Edit button for custom books (centered in nav row)
	local editButton = safeCreateFrame
		and safeCreateFrame("Button", nil, readerNavRow or readerHeaderRow, "UIPanelButtonTemplate")
	if editButton then
		editButton:SetSize(Metrics.BTN_W or 60, 22)
		editButton:SetPoint("CENTER", readerNavRow or readerHeaderRow, "CENTER", 0, 0)
		editButton:SetText(t("EDIT") or "Edit")
		editButton:SetNormalFontObject(GameFontNormal)
		local fontString = editButton:GetFontString()
		if fontString then
			fontString:SetTextColor(0.6, 0.8, 1.0)
		end
		editButton:SetScript("OnClick", function()
			local EditMode = BookArchivist and BookArchivist.UI and BookArchivist.UI.Reader and BookArchivist.UI.Reader.EditMode
			if EditMode and EditMode.StartEditingBook then
				local selectedKey = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				if selectedKey then
					EditMode:StartEditingBook(selectedKey)
				end
			end
		end)
		editButton:Hide() -- Initially hidden, shown only for custom books
		if rememberWidget then
			rememberWidget("editButton", editButton)
		end
	end
	state.editButton = editButton

	local pageIndicatorParent = readerNavRow or readerHeaderRow
	local pageIndicator = pageIndicatorParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	pageIndicator:SetPoint("CENTER", pageIndicatorParent, "CENTER", 0, 0)
	pageIndicator:SetJustifyH("CENTER")
	pageIndicator:SetJustifyV("MIDDLE")
	pageIndicator:SetText(t("PAGINATION_PAGE_SINGLE"))
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

	local textScroll = safeCreateFrame
		and safeCreateFrame("Frame", "BookArchivistTextScroll", readerScrollRow or readerBlock, "WowScrollBox")
	if not textScroll then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader scroll box.")
		end
		return
	end
	if rememberWidget then
		rememberWidget("textScroll", textScroll)
	end
	state.textScroll = textScroll
	local innerPad = Metrics.PAD_INSET or Metrics.PAD or 10
	textScroll:ClearAllPoints()

	-- Create modern scrollbar
	local scrollBar = safeCreateFrame
		and safeCreateFrame(
			"EventFrame",
			"BookArchivistTextScrollBar",
			readerScrollRow or readerBlock,
			"MinimalScrollBar"
		)
	if not scrollBar then
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("Unable to create reader scroll bar.")
		end
		return
	end

	local sbW = (scrollBar and scrollBar.GetWidth and scrollBar:GetWidth()) or 12
	local gutter = Metrics.SCROLLBAR_GUTTER or math.ceil(sbW + 6)

	-- Position scroll box
	textScroll:SetPoint("TOPLEFT", readerScrollRow or readerBlock, "TOPLEFT", innerPad, -innerPad)
	textScroll:SetPoint("BOTTOMLEFT", readerScrollRow or readerBlock, "BOTTOMLEFT", innerPad, innerPad)
	textScroll:SetPoint("RIGHT", scrollBar, "LEFT", -4, 0)

	-- Position scrollbar
	scrollBar:SetPoint("TOPRIGHT", readerScrollRow or readerBlock, "TOPRIGHT", -innerPad, -innerPad)
	scrollBar:SetPoint("BOTTOMRIGHT", readerScrollRow or readerBlock, "BOTTOMRIGHT", -innerPad, innerPad)

	-- Store scrollbar reference
	state.textScrollBar = scrollBar
	if rememberWidget then
		rememberWidget("textScrollBar", scrollBar)
	end

	uiFrame.textScroll = textScroll
	uiFrame.textScrollBar = scrollBar
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("reader-scroll", textScroll)
	end

	local contentHost = (safeCreateFrame and safeCreateFrame("Frame", nil, textScroll))
		or CreateFrame("Frame", nil, textScroll)
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

	-- Initialize ScrollBox with view and link scrollbar
	local scrollView = CreateScrollBoxLinearView()
	scrollView:SetPanExtent(30) -- Allow scrolling with mousewheel
	ScrollUtil.InitScrollBoxWithScrollBar(textScroll, scrollBar, scrollView)

	-- Set the scroll child as the content
	if textScroll.SetScrollTarget then
		textScroll:SetScrollTarget(textChild)
	end

	if rememberWidget then
		rememberWidget("textChild", textChild)
		rememberWidget("textScrollView", scrollView)
	end
	state.textChild = textChild
	state.textScrollView = scrollView
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
		local htmlPad = textPad + 6
		htmlFrame:SetPoint("TOPLEFT", textChild, "TOPLEFT", htmlPad, -htmlPad)
		htmlFrame:SetPoint("TOPRIGHT", textChild, "TOPRIGHT", -htmlPad, -htmlPad)
		htmlFrame:SetPoint("BOTTOMLEFT", textChild, "BOTTOMLEFT", htmlPad, htmlPad)
		htmlFrame:SetPoint("BOTTOMRIGHT", textChild, "BOTTOMRIGHT", -htmlPad, htmlPad)
		-- Use actual font objects, not strings, to avoid resolution issues
		local bodyFont = GameFontHighlight
		local headingFont = GameFontNormalHuge or GameFontNormalLarge
		local subHeadingFont = GameFontNormalLarge

		-- Only apply fonts if they resolved to valid objects
		if bodyFont then
			applyHTMLFont(htmlFrame, "p", bodyFont)
			applyHTMLFont(htmlFrame, "li", bodyFont)
		end
		if headingFont then
			applyHTMLFont(htmlFrame, "h1", headingFont)
		end
		if subHeadingFont then
			applyHTMLFont(htmlFrame, "h2", subHeadingFont)
			applyHTMLFont(htmlFrame, "h3", subHeadingFont)
		end

		applyHTMLSpacing(htmlFrame, "h1", 2)
		applyHTMLSpacing(htmlFrame, "h2", 2)
		applyHTMLSpacing(htmlFrame, "h3", 2)
		applyHTMLSpacing(htmlFrame, "p", 2)
		applyHTMLSpacing(htmlFrame, "li", 1)
		htmlFrame:Hide()
		uiFrame.htmlText = htmlFrame
	else
		state.htmlText = nil
		if rememberWidget then
			rememberWidget("htmlText", nil)
		end
	end

	-- Width is governed by anchors to contentHost; no explicit SetWidth needed.

	-- Create empty state frame
	local emptyStateFrame = safeCreateFrame and safeCreateFrame("Frame", nil, readerScrollRow or readerBlock)
	if emptyStateFrame then
		emptyStateFrame:SetAllPoints(readerScrollRow or readerBlock)
		emptyStateFrame:Hide() -- Hidden by default, shown when no book selected
		state.emptyStateFrame = emptyStateFrame
		if rememberWidget then
			rememberWidget("emptyStateFrame", emptyStateFrame)
		end

		-- Center container
		local centerContainer = CreateFrame("Frame", nil, emptyStateFrame)
		centerContainer:SetSize(400, 300)
		centerContainer:SetPoint("CENTER", emptyStateFrame, "CENTER", 0, 20)

		-- Title: "Book Archivist"
		local emptyTitle = centerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
		emptyTitle:SetPoint("TOP", centerContainer, "TOP", 0, 0)
		emptyTitle:SetText(t("ADDON_TITLE"))
		emptyTitle:SetTextColor(0.7, 0.7, 0.7)
		state.emptyTitle = emptyTitle

		-- Subtitle: "Select a book from the list"
		local emptySubtitle = centerContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		emptySubtitle:SetPoint("TOP", emptyTitle, "BOTTOM", 0, -8)
		emptySubtitle:SetText(t("READER_EMPTY_PROMPT"))
		emptySubtitle:SetTextColor(0.6, 0.6, 0.6)
		state.emptySubtitle = emptySubtitle

		-- Buttons container
		local buttonsRow = CreateFrame("Frame", nil, centerContainer)
		buttonsRow:SetSize(280, 24)
		buttonsRow:SetPoint("TOP", emptySubtitle, "BOTTOM", 0, -20)

		-- Resume last book button
		local resumeBtn = safeCreateFrame("Button", nil, buttonsRow, "UIPanelButtonTemplate")
		if resumeBtn then
			resumeBtn:SetSize(135, 26)
			resumeBtn:SetPoint("LEFT", buttonsRow, "LEFT", 0, 0)
			resumeBtn:SetText(t("RESUME_LAST_BOOK"))
			resumeBtn:SetNormalFontObject(GameFontNormal)
			local fontString = resumeBtn:GetFontString()
			if fontString then
				fontString:SetTextColor(1.0, 0.82, 0.0)
			end
			resumeBtn:SetScript("OnClick", function()
				local BA = BookArchivist
				if not BA or not BA.GetLastBookId then
					return
				end
				local lastId = BA:GetLastBookId()
				if not lastId then
					return
				end
				local listUI = BA.UI and BA.UI.List
				if listUI then
					if listUI.SetSelectedKey then
						listUI:SetSelectedKey(lastId)
					end
					if listUI.NotifySelectionChanged then
						listUI:NotifySelectionChanged()
					end
				end
			end)
			state.emptyResumeBtn = resumeBtn
		end

		-- Options button
		local optionsBtn = safeCreateFrame("Button", nil, buttonsRow, "UIPanelButtonTemplate")
		if optionsBtn then
			optionsBtn:SetSize(135, 26)
			optionsBtn:SetPoint("RIGHT", buttonsRow, "RIGHT", 0, 0)
			optionsBtn:SetText(t("HEADER_BUTTON_OPTIONS"))
			optionsBtn:SetNormalFontObject(GameFontNormal)
			local fontString = optionsBtn:GetFontString()
			if fontString then
				fontString:SetTextColor(1.0, 0.82, 0.0)
			end
			optionsBtn:SetScript("OnClick", function()
				local optionsUI = BookArchivist and BookArchivist.UI and BookArchivist.UI.Options
				if optionsUI and optionsUI.Open then
					optionsUI:Open()
				end
			end)
			state.emptyOptionsBtn = optionsBtn
		end

		-- Tips container
		local tipsContainer = CreateFrame("Frame", nil, centerContainer)
		tipsContainer:SetPoint("TOP", buttonsRow, "BOTTOM", 0, -24)
		tipsContainer:SetSize(380, 60)

		local tip1 = tipsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		tip1:SetPoint("TOP", tipsContainer, "TOP", 0, 0)
		tip1:SetWidth(380)
		tip1:SetJustifyH("CENTER")
		tip1:SetText(t("READER_EMPTY_TIP_SEARCH"))
		tip1:SetTextColor(0.5, 0.5, 0.5)
		state.emptyTip1 = tip1

		local tip2 = tipsContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		tip2:SetPoint("TOP", tip1, "BOTTOM", 0, -6)
		tip2:SetWidth(380)
		tip2:SetJustifyH("CENTER")
		tip2:SetText(t("READER_EMPTY_TIP_LOCATIONS"))
		tip2:SetTextColor(0.5, 0.5, 0.5)
		state.emptyTip2 = tip2

		-- Stats footer
		local statsFooter = emptyStateFrame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		statsFooter:SetPoint("BOTTOM", emptyStateFrame, "BOTTOM", 0, 20)
		statsFooter:SetWidth(450)
		statsFooter:SetJustifyH("CENTER")
		statsFooter:SetTextColor(0.4, 0.4, 0.4)
		statsFooter:SetText("") -- Will be populated dynamically
		state.emptyStatsFooter = statsFooter
	end

	local deleteParent = actionsRail or readerHeaderRow
	local deleteButton
	if ReaderUI.__ensureDeleteButton then
		deleteButton = ReaderUI.__ensureDeleteButton(deleteParent)
	end
	if not deleteButton then
		deleteDebug("ReaderUI:Create deleteButton creation failed; logging error")
		if BookArchivist and BookArchivist.UI and BookArchivist.UI.Internal and BookArchivist.UI.Internal.logError then
			BookArchivist.UI.Internal.logError("BookArchivist delete button failed to initialize.")
		end
	end

	-- Favorites toggle lives in the reader header actions rail, to the
	-- left of the delete button when available.
	if actionsRail and safeCreateFrame then
		-- Share button (export single book) - icon only
		local shareButton = state.shareButton
		if not shareButton or not (shareButton.IsObjectType and shareButton:IsObjectType("Button")) then
			shareButton = safeCreateFrame("Button", "BookArchivistShareButton", actionsRail)
			state.shareButton = shareButton
			if rememberWidget then
				rememberWidget("shareButton", shareButton)
			end
			local size = Metrics.BTN_H or 22
			if shareButton.SetSize then
				shareButton:SetSize(size, size)
			end
			-- Enable mouse clicks
			shareButton:EnableMouse(true)
			shareButton:RegisterForClicks("LeftButtonUp")
			-- Create icon texture for share/export
			local icon = shareButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints()
			if icon.SetAtlas then
				-- Try mail icon first
				local success = pcall(function()
					icon:SetAtlas("mailbox", true)
				end)
				if not success then
					-- Fallback: community invite icon
					success = pcall(function()
						icon:SetAtlas("communities-icon-invitemail", true)
					end)
					if not success then
						-- Final fallback: scroll/document icon
						icon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
					end
				end
			end
			shareButton.icon = icon
			-- Tooltip
			shareButton:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(t("READER_SHARE_BUTTON"), 1, 1, 1)
				if GameTooltip.AddLine then
					GameTooltip:AddLine(t("READER_SHARE_TOOLTIP_BODY"), nil, nil, nil, true)
				end
				GameTooltip:Show()
			end)
			shareButton:SetScript("OnLeave", function(self)
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			shareButton:SetScript("OnClick", function()
				local BA = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()

				-- Delegate to Share module
				local ReaderShare = BookArchivist
					and BookArchivist.UI
					and BookArchivist.UI.Reader
					and BookArchivist.UI.Reader.Share
				if ReaderShare and ReaderShare.ShareCurrentBook and BA then
					-- Create minimal export context instead of passing entire addon
					local exportFns = {
						ExportBook = BA.ExportBook and function(bookKey)
							return BA:ExportBook(bookKey)
						end,
						Export = BA.Export and function()
							return BA:Export()
						end
					}
					ReaderShare:ShareCurrentBook(exportFns, key)
				end
			end)
		end

		-- Copy button (copy text to clipboard) - icon only
		local copyButton = state.copyButton
		if not copyButton or not (copyButton.IsObjectType and copyButton:IsObjectType("Button")) then
			copyButton = safeCreateFrame("Button", "BookArchivistCopyButton", actionsRail)
			state.copyButton = copyButton
			if rememberWidget then
				rememberWidget("copyButton", copyButton)
			end
			local size = Metrics.BTN_H or 22
			if copyButton.SetSize then
				copyButton:SetSize(size, size)
			end
			-- Enable mouse clicks
			copyButton:EnableMouse(true)
			copyButton:RegisterForClicks("LeftButtonUp")
			-- Create icon texture for copy
			local icon = copyButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints()
			-- Use a visible copy/document icon - inv_inscription_scroll is a scroll with text
			local success = false
			if icon.SetAtlas then
				success = pcall(function()
					icon:SetAtlas("Garr_Building-AddFollowerPlus", true)
				end)
			end
			if not success then
				-- Fallback to scroll with text icon (good for "copy text")
				icon:SetTexture("Interface\\Icons\\inv_inscription_scroll")
				icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- Slight crop to remove border
			end
			copyButton.icon = icon
			-- Tooltip
			copyButton:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText(t("READER_COPY_BUTTON"), 1, 1, 1)
				if GameTooltip.AddLine then
					GameTooltip:AddLine(t("READER_COPY_TOOLTIP_BODY"), nil, nil, nil, true)
				end
				GameTooltip:Show()
			end)
			copyButton:SetScript("OnLeave", function(self)
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			copyButton:SetScript("OnClick", function()
				-- Delegate to Copy module
				local ReaderCopy = BookArchivist
					and BookArchivist.UI
					and BookArchivist.UI.Reader
					and BookArchivist.UI.Reader.Copy
				if ReaderCopy and ReaderCopy.CopyCurrentBook then
					ReaderCopy:CopyCurrentBook(ReaderUI.__getSelectedKey)
				end
			end)
		end

		-- Waypoint button (set map waypoint for book location) - icon only
		local waypointButton = state.waypointButton
		if not waypointButton or not (waypointButton.IsObjectType and waypointButton:IsObjectType("Button")) then
			waypointButton = safeCreateFrame("Button", "BookArchivistWaypointButton", actionsRail)
			state.waypointButton = waypointButton
			if rememberWidget then
				rememberWidget("waypointButton", waypointButton)
			end
			local size = Metrics.BTN_H or 22
			if waypointButton.SetSize then
				waypointButton:SetSize(size, size)
			end
			-- Enable mouse clicks
			waypointButton:EnableMouse(true)
			waypointButton:RegisterForClicks("LeftButtonUp")
			-- Create icon texture for waypoint/map pin
			local icon = waypointButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints()
			if icon.SetAtlas then
				-- Try map pin icon first
				local success = pcall(function()
					icon:SetAtlas("Waypoint-MapPin-ChatIcon", true)
				end)
				if not success then
					-- Fallback: poi icon
					success = pcall(function()
						icon:SetAtlas("poi-traveldirections-arrow", true)
					end)
					if not success then
						-- Final fallback: location icon
						icon:SetTexture("Interface\\Minimap\\Tracking\\POIArrow")
					end
				end
			end
			waypointButton.icon = icon
			-- Disabled visual state
			local disabledOverlay = waypointButton:CreateTexture(nil, "OVERLAY")
			disabledOverlay:SetAllPoints()
			disabledOverlay:SetColorTexture(0, 0, 0, 0.5)
			disabledOverlay:Hide()
			waypointButton.disabledOverlay = disabledOverlay
			
			-- Helper to get itemID from entry (stored or extracted from GUID)
			local function getItemIDFromEntry(entry)
				if not entry or not entry.source then
					return nil
				end
				-- First try stored itemID
				if entry.source.itemID then
					return entry.source.itemID
				end
				-- Try to extract from GUID using C_Item API
				if entry.source.guid and entry.source.objectType == "Item" then
					if C_Item and C_Item.GetItemIDByGUID then
						local ok, itemID = pcall(C_Item.GetItemIDByGUID, entry.source.guid)
						if ok and itemID then
							return itemID
						end
					end
				end
				return nil
			end
			
			-- Helper to get Wowhead URL for an entry (object or item)
			local function getWowheadURL(entry)
				if not entry or not entry.source then
					return nil
				end
				-- World objects use objectID
				if entry.source.objectID then
					return "https://www.wowhead.com/object=" .. entry.source.objectID
				end
				-- Inventory items use itemID
				local itemID = getItemIDFromEntry(entry)
				if itemID then
					return "https://www.wowhead.com/item=" .. itemID
				end
				return nil
			end
			
			-- Helper to copy Wowhead URL to clipboard and show message
			local function copyWowheadURL(entry)
				local BA = getAddon and getAddon()
				local url = getWowheadURL(entry)
				if url then
					local L = BA and BA.L or {}
					local msg = (L["WAYPOINT_WOWHEAD_COPIED"] or "Wowhead link copied to clipboard:") .. " " .. url
					if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
						DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBookArchivist:|r " .. msg)
					end
					if C_ClipBoard and C_ClipBoard.SetClipboardText then
						C_ClipBoard:SetClipboardText(url)
					end
					return true
				else
					local L = BA and BA.L or {}
					local msg = L["WAYPOINT_WOWHEAD_NO_ITEMID"] or "Item ID not available. Cannot generate Wowhead link."
					if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
						DEFAULT_CHAT_FRAME:AddMessage("|cFF00CCFFBookArchivist:|r " .. msg)
					end
					return false
				end
			end
			
			-- Tooltip - shows different hints based on available options
			waypointButton:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local BA = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				local entry = nil
				if BA and BA.Repository and key then
					local db = BA.Repository:GetDB()
					if db and db.booksById then
						entry = db.booksById[key]
					end
				end
				
				local hasWaypoint = BA and BA.Waypoint and BA.Waypoint.HasValidLocation and entry
					and BA.Waypoint:HasValidLocation(entry)
				local wowheadURL = getWowheadURL(entry)
				local hasWowhead = wowheadURL ~= nil
				
				if hasWaypoint and hasWowhead then
					-- Case: Both waypoint AND Wowhead available
					GameTooltip:SetText(t("READER_WAYPOINT_BUTTON"), 1, 1, 1)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_WAYPOINT_TOOLTIP_BODY"), nil, nil, nil, true)
						-- Show location info
						if BA.Waypoint.GetLocationDisplayText then
							local locText = BA.Waypoint:GetLocationDisplayText(entry)
							if locText and locText ~= "" then
								GameTooltip:AddLine(" ")
								GameTooltip:AddLine(locText, 0.7, 0.7, 0.7, true)
							end
						end
						GameTooltip:AddLine(" ")
						-- Hint for both actions
						GameTooltip:AddLine(t("READER_WAYPOINT_BOTH_HINT") or "Left-click: Set waypoint | Right-click: Wowhead", 0.3, 0.8, 1, true)
					end
				elseif hasWaypoint then
					-- Case: Only waypoint available (no objectID/itemID for Wowhead)
					GameTooltip:SetText(t("READER_WAYPOINT_BUTTON"), 1, 1, 1)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_WAYPOINT_TOOLTIP_BODY"), nil, nil, nil, true)
						if BA.Waypoint.GetLocationDisplayText then
							local locText = BA.Waypoint:GetLocationDisplayText(entry)
							if locText and locText ~= "" then
								GameTooltip:AddLine(" ")
								GameTooltip:AddLine(locText, 0.7, 0.7, 0.7, true)
							end
						end
					end
				elseif hasWowhead then
					-- Case: No waypoint but Wowhead available
					GameTooltip:SetText(t("READER_WAYPOINT_MENU_WOWHEAD") or "View on Wowhead", 1, 1, 1)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_WAYPOINT_WOWHEAD_ONLY") or "Click to view this book's source on Wowhead.", nil, nil, nil, true)
						-- Explain why no waypoint
						GameTooltip:AddLine(" ")
						local isInventoryItem = entry and entry.source and entry.source.kind == "inventory"
						if isInventoryItem then
							GameTooltip:AddLine(t("READER_WAYPOINT_INVENTORY_ITEM"), 1, 0.8, 0.3, true)
						else
							GameTooltip:AddLine(t("READER_WAYPOINT_UNAVAILABLE"), 1, 0.8, 0.3, true)
						end
					end
				else
					-- Case: Nothing available
					GameTooltip:SetText(t("READER_WAYPOINT_BUTTON"), 0.5, 0.5, 0.5)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_WAYPOINT_UNAVAILABLE"), 1, 0.3, 0.3, true)
					end
				end
				GameTooltip:Show()
			end)
			waypointButton:SetScript("OnLeave", function(self)
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			-- Register for both left and right mouse buttons
			waypointButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			waypointButton:SetScript("OnClick", function(self, button)
				local BA = getAddon and getAddon()
				if not BA then
					return
				end
				-- Get the current entry
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				local entry = nil
				if BA.Repository and key then
					local db = BA.Repository:GetDB()
					if db and db.booksById then
						entry = db.booksById[key]
					end
				end
				
				local hasWaypoint = BA.Waypoint and BA.Waypoint.HasValidLocation and entry
					and BA.Waypoint:HasValidLocation(entry)
				local wowheadURL = getWowheadURL(entry)
				local hasWowhead = wowheadURL ~= nil
				
				if hasWaypoint and hasWowhead then
					-- Both options: left = waypoint, right = Wowhead
					if button == "RightButton" then
						copyWowheadURL(entry)
					else
						-- Left click: set waypoint
						if BA.Waypoint and BA.Waypoint.SetWaypointForCurrentBook then
							local success, err = BA.Waypoint:SetWaypointForCurrentBook()
							if not success and err and BA.DebugPrint then
								BA:DebugPrint("[Waypoint] " .. err)
							end
						end
					end
				elseif hasWaypoint then
					-- Only waypoint: any click sets waypoint
					if BA.Waypoint and BA.Waypoint.SetWaypointForCurrentBook then
						local success, err = BA.Waypoint:SetWaypointForCurrentBook()
						if not success and err and BA.DebugPrint then
							BA:DebugPrint("[Waypoint] " .. err)
						end
					end
				elseif hasWowhead then
					-- Only Wowhead: any click copies link
					copyWowheadURL(entry)
				end
				-- If neither available, do nothing
			end)
		end

		-- TTS button (text-to-speech) - icon only
		local ttsButton = state.ttsButton
		if not ttsButton or not (ttsButton.IsObjectType and ttsButton:IsObjectType("Button")) then
			ttsButton = safeCreateFrame("Button", "BookArchivistTTSButton", actionsRail)
			state.ttsButton = ttsButton
			if rememberWidget then
				rememberWidget("ttsButton", ttsButton)
			end
			local size = Metrics.BTN_H or 22
			if ttsButton.SetSize then
				ttsButton:SetSize(size, size)
			end
			-- Enable mouse clicks
			ttsButton:EnableMouse(true)
			ttsButton:RegisterForClicks("LeftButtonUp")
			-- Create icon texture for TTS
			local icon = ttsButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints()
			if icon.SetAtlas then
				-- Use the standard TTS icon
				local success = pcall(function()
					icon:SetAtlas("chatframe-button-icon-TTS", true)
				end)
				if not success then
					-- Fallback: speaker icon
					icon:SetTexture("Interface\\Common\\VoiceChat-Speaker")
				end
			end
			ttsButton.icon = icon
			-- Playing indicator overlay
			local playingOverlay = ttsButton:CreateTexture(nil, "OVERLAY")
			playingOverlay:SetAllPoints()
			playingOverlay:SetColorTexture(0.3, 0.8, 0.3, 0.3)
			playingOverlay:Hide()
			ttsButton.playingOverlay = playingOverlay
			-- Disabled visual state
			local disabledOverlay = ttsButton:CreateTexture(nil, "OVERLAY")
			disabledOverlay:SetAllPoints()
			disabledOverlay:SetColorTexture(0, 0, 0, 0.5)
			disabledOverlay:Hide()
			ttsButton.disabledOverlay = disabledOverlay
			-- Tooltip
			ttsButton:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local BA = getAddon and getAddon()
				local isSpeaking = BA and BA.TTS and BA.TTS.IsSpeaking and BA.TTS:IsSpeaking()
				local isSupported = BA and BA.TTS and BA.TTS.IsSupported and BA.TTS:IsSupported()
				if not isSupported then
					GameTooltip:SetText(t("READER_TTS_BUTTON"), 0.5, 0.5, 0.5)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_TTS_UNAVAILABLE"), 1, 0.3, 0.3, true)
					end
				elseif isSpeaking then
					GameTooltip:SetText(t("READER_TTS_STOP"), 1, 1, 1)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_TTS_STOP_TOOLTIP"), nil, nil, nil, true)
					end
				else
					GameTooltip:SetText(t("READER_TTS_BUTTON"), 1, 1, 1)
					if GameTooltip.AddLine then
						GameTooltip:AddLine(t("READER_TTS_TOOLTIP_BODY"), nil, nil, nil, true)
					end
				end
				GameTooltip:Show()
			end)
			ttsButton:SetScript("OnLeave", function(self)
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			ttsButton:SetScript("OnClick", function(self)
				local BA = getAddon and getAddon()
				if not BA or not BA.TTS or not BA.TTS.ToggleCurrentBook then
					if BA and BA.DebugPrint then
						BA:DebugPrint("[TTS] Module not available")
					end
					return
				end
				local started, err = BA.TTS:ToggleCurrentBook()
				-- Show user-friendly message for common errors
				if not started and err then
					if err == "No TTS voices available" then
						-- Show a helpful message to the user
						if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
							DEFAULT_CHAT_FRAME:AddMessage("|cFFFFCC00BookArchivist:|r " .. t("TTS_ENABLE_HINT"), 1, 0.82, 0)
						end
					elseif BA and BA.DebugPrint then
						BA:DebugPrint("[TTS] " .. tostring(err))
					end
				end
				-- Update visual
				if self.playingOverlay then
					if started then
						self.playingOverlay:Show()
					else
						self.playingOverlay:Hide()
					end
				end
			end)
			-- Register for TTS events to update button state
			ttsButton:RegisterEvent("VOICE_CHAT_TTS_PLAYBACK_FINISHED")
			ttsButton:SetScript("OnEvent", function(self, event)
				if event == "VOICE_CHAT_TTS_PLAYBACK_FINISHED" then
					if self.playingOverlay then
						self.playingOverlay:Hide()
					end
				end
			end)
		end

		local favoriteBtn = state.favoriteButton
		if not favoriteBtn or not (favoriteBtn.IsObjectType and favoriteBtn:IsObjectType("Button")) then
			favoriteBtn = safeCreateFrame("Button", "BookArchivistFavoriteButton", actionsRail)
			state.favoriteButton = favoriteBtn
			if rememberWidget then
				rememberWidget("favoriteBtn", favoriteBtn)
			end
			-- Replace the default checkbox textures with a star-style favorite
			-- icon, similar to the mounts/collections UIs.
			local size = Metrics.BTN_H or 22
			if favoriteBtn.SetSize then
				favoriteBtn:SetSize(size, size)
			end
			local starOff = favoriteBtn:CreateTexture(nil, "ARTWORK")
			starOff:SetAllPoints()
			if starOff.SetAtlas then
				-- Golden star atlas used broadly in the default UI; when
				-- unavailable this call simply leaves the texture empty.
				starOff:SetAtlas("auctionhouse-icon-favorite", true)
			end
			starOff:SetDesaturated(true)
			starOff:SetAlpha(0.35)
			local starOn = favoriteBtn:CreateTexture(nil, "OVERLAY")
			starOn:SetAllPoints()
			if starOn.SetAtlas then
				starOn:SetAtlas("auctionhouse-icon-favorite", true)
			end
			starOn:SetDesaturated(false)
			starOn:SetAlpha(1)
			favoriteBtn.starOff = starOff
			favoriteBtn.starOn = starOn
			syncFavoriteVisual(favoriteBtn, false)
			favoriteBtn:SetMotionScriptsWhileDisabled(true)
			favoriteBtn:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				local BA = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				local isFav = false
				if BA and BA.Favorites and key and BA.Favorites.IsFavorite then
					isFav = BA.Favorites:IsFavorite(key)
				end
				if isFav then
					GameTooltip:SetText(t("READER_FAVORITE_REMOVE"), 1, 1, 1)
				else
					GameTooltip:SetText(t("READER_FAVORITE_ADD"), 1, 1, 1)
				end
				GameTooltip:Show()
			end)
			favoriteBtn:SetScript("OnLeave", function()
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			favoriteBtn:SetScript("OnClick", function(self)
				local BA = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				if not (BA and BA.Favorites and BA.Favorites.Toggle and key) then
					syncFavoriteVisual(self, false)
					return
				end
				BA.Favorites:Toggle(key)
				local isFav = BA.Favorites:IsFavorite(key)
				syncFavoriteVisual(self, isFav)
				if BA.RefreshUI then
					BA:RefreshUI()
				end
			end)
		end
		-- Custom book icon (inscription profession icon) - create before positioning favorite
		local customIcon = state.customBookIcon
		if not customIcon then
			customIcon = actionsRail:CreateTexture(nil, "ARTWORK")
			state.customBookIcon = customIcon
			local size = Metrics.BTN_H or 22
			customIcon:SetSize(size, size)
			customIcon:SetTexture("Interface\\Icons\\INV_Inscription_Tradeskill01")
			customIcon:SetAlpha(0.9)
			customIcon:Hide()
			
			-- Create an invisible frame for tooltip support
			local customIconFrame = CreateFrame("Frame", nil, actionsRail)
			state.customBookIconFrame = customIconFrame
			customIconFrame:SetSize(size, size)
			customIconFrame:SetScript("OnEnter", function(self)
				if not GameTooltip then
					return
				end
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
				local text = BookArchivist.L["CUSTOM_BOOK_TOOLTIP"] or "Custom Book"
				GameTooltip:SetText(text, 1, 0.82, 0)
				GameTooltip:Show()
			end)
			customIconFrame:SetScript("OnLeave", function()
				if GameTooltip then
					GameTooltip:Hide()
				end
			end)
			customIconFrame:Hide()
		end
		if customIcon then
			customIcon:ClearAllPoints()
			if deleteButton then
				customIcon:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				customIcon:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
			
			-- Position tooltip frame to match icon
			local customIconFrame = state.customBookIconFrame
			if customIconFrame then
				customIconFrame:ClearAllPoints()
				customIconFrame:SetAllPoints(customIcon)
			end
		end

		-- Position favorite button to left of custom icon (will be repositioned in ShowBook for non-custom books)
		if favoriteBtn then
			favoriteBtn:ClearAllPoints()
			if customIcon then
				favoriteBtn:SetPoint("RIGHT", customIcon, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif deleteButton then
				favoriteBtn:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				favoriteBtn:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
		end

		-- Position share button (will be repositioned dynamically in ShowBook)
		if shareButton then
			shareButton:ClearAllPoints()
			if favoriteBtn then
				shareButton:SetPoint("RIGHT", favoriteBtn, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif deleteButton then
				shareButton:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				shareButton:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
		end

		-- Position copy button to left of share button
		if copyButton then
			copyButton:ClearAllPoints()
			if shareButton then
				copyButton:SetPoint("RIGHT", shareButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif favoriteBtn then
				copyButton:SetPoint("RIGHT", favoriteBtn, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif deleteButton then
				copyButton:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				copyButton:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
		end

		-- Position waypoint button to left of copy button
		local waypointButton = state.waypointButton
		if waypointButton then
			waypointButton:ClearAllPoints()
			if copyButton then
				waypointButton:SetPoint("RIGHT", copyButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif shareButton then
				waypointButton:SetPoint("RIGHT", shareButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif favoriteBtn then
				waypointButton:SetPoint("RIGHT", favoriteBtn, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif deleteButton then
				waypointButton:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				waypointButton:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
		end

		-- Position TTS button to left of waypoint button
		local ttsButton = state.ttsButton
		if ttsButton then
			ttsButton:ClearAllPoints()
			if waypointButton then
				ttsButton:SetPoint("RIGHT", waypointButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif copyButton then
				ttsButton:SetPoint("RIGHT", copyButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif shareButton then
				ttsButton:SetPoint("RIGHT", shareButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif favoriteBtn then
				ttsButton:SetPoint("RIGHT", favoriteBtn, "LEFT", -(Metrics.GAP_S or 4), 0)
			elseif deleteButton then
				ttsButton:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				ttsButton:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
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

	-- -----------------------------------------------------------------------
	-- Custom book creation/edit UI (simplified edit mode)
	-- -----------------------------------------------------------------------
	-- This UI appears within the existing reader panel, replacing the normal
	-- reader content. It shows title, location, and page editor controls.
	if safeCreateFrame and rememberWidget then
		-- Create edit mode container
		local editFrame = safeCreateFrame("Frame", "BookArchivistEditBookFrame", readerScrollRow or readerBlock)
		if editFrame then
			editFrame:SetAllPoints(readerScrollRow or readerBlock)
			editFrame:Hide() -- Hidden by default
			
			-- Content container with padding
			local editContent = safeCreateFrame("Frame", nil, editFrame)
			editContent:SetPoint("TOPLEFT", editFrame, "TOPLEFT", padInset, -padInset)
			editContent:SetPoint("BOTTOMRIGHT", editFrame, "BOTTOMRIGHT", -padInset, padInset)
			
			rememberWidget("editBookFrame", editFrame)
			rememberWidget("editBookContent", editContent)
			state.editBookFrame = editFrame
			state.editBookContent = editContent
			
			-- We'll populate the edit controls dynamically in a separate function
			-- to keep this initialization code clean
		end
	end
end

-- Update header height based on title content
-- Call this after setting the book title to ensure proper layout
function ReaderUI.UpdateHeaderHeight()
	local state = ReaderUI.__state or {}
	local bookTitle = state.bookTitle
	local readerHeader = state.readerHeader
	local echoText = state.echoText
	local metaDisplay = state.metaDisplay
	local actionsRail = state.readerActionsRail
	
	if not bookTitle or not readerHeader then
		return
	end
	
	local Metrics = (BookArchivist and BookArchivist.UI and BookArchivist.UI.Metrics) or {}
	local minHeaderHeight = Metrics.READER_HEADER_H or 54
	local gap = Metrics.GAP_XS or 2
	
	-- Calculate title height (it has word wrap enabled)
	local titleHeight = bookTitle:GetStringHeight() or 20
	
	-- Calculate echo text height if visible
	local echoHeight = 0
	if echoText and echoText:IsShown() then
		echoHeight = (echoText:GetStringHeight() or 0) + gap
	end
	
	-- Calculate meta display height
	local metaHeight = 0
	if metaDisplay then
		metaHeight = (metaDisplay:GetStringHeight() or 0) + gap
	end
	
	-- Total needed height: title + echo + meta + some padding
	local neededHeight = titleHeight + echoHeight + metaHeight + (gap * 2)
	
	-- Use the greater of minimum or needed height
	local newHeight = math.max(minHeaderHeight, neededHeight)
	
	-- Update header height
	readerHeader:SetHeight(newHeight)
	
	-- Update actions rail to match (it's anchored TOP/BOTTOM to header, but ensure it stays right)
	if actionsRail then
		-- Actions rail height follows header automatically via anchors
		-- But we need to make sure buttons stay vertically centered
	end
end
