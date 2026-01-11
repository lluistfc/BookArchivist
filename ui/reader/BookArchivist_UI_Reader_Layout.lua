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
local getWidget = ReaderUI.__getWidget
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
	bookTitle:SetText(t("READER_EMPTY_PROMPT"))
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
				local addon = BookArchivist
				if not addon or not addon.GetLastBookId then
					return
				end
				local lastId = addon:GetLastBookId()
				if not lastId then
					return
				end
				local listUI = addon.UI and addon.UI.List
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
				local addon = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()

				-- Delegate to Share module
				local ReaderShare = BookArchivist
					and BookArchivist.UI
					and BookArchivist.UI.Reader
					and BookArchivist.UI.Reader.Share
				if ReaderShare and ReaderShare.ShareCurrentBook then
					ReaderShare:ShareCurrentBook(addon, key)
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
				local addon = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				local isFav = false
				if addon and addon.Favorites and key and addon.Favorites.IsFavorite then
					isFav = addon.Favorites:IsFavorite(key)
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
				local addon = getAddon and getAddon()
				local key = ReaderUI.__getSelectedKey and ReaderUI.__getSelectedKey()
				if not (addon and addon.Favorites and addon.Favorites.Toggle and key) then
					syncFavoriteVisual(self, false)
					return
				end
				addon.Favorites:Toggle(key)
				local isFav = addon.Favorites:IsFavorite(key)
				syncFavoriteVisual(self, isFav)
				if type(addon.RefreshUI) == "function" then
					addon:RefreshUI()
				end
			end)
		end
		if favoriteBtn then
			favoriteBtn:ClearAllPoints()
			if deleteButton then
				favoriteBtn:SetPoint("RIGHT", deleteButton, "LEFT", -(Metrics.GAP_S or 4), 0)
			else
				favoriteBtn:SetPoint("RIGHT", actionsRail, "RIGHT", 0, 0)
			end
		end

		-- Position share button to the left of favorite button
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
