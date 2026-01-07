---@diagnostic disable: undefined-global, undefined-field
-- Shared layout helpers for the main Book Archivist frame.

BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local FrameUI = BookArchivist.UI.Frame or {}
BookArchivist.UI.Frame = FrameUI
local Internal = BookArchivist.UI.Internal

local Metrics = BookArchivist.UI.Metrics or {
	PAD = 12,
	PAD_OUTER = 12,
	PAD_INSET = 10,
	GUTTER = 10,
	GAP_S = 6,
	GAP_M = 10,
	SEPARATOR_W = 10,
	SEPARATOR_GAP = 6,
}

local DEFAULT_WIDTH = FrameUI.DEFAULT_WIDTH or 1080
local MIN_LIST_WIDTH = 260
local MIN_READER_WIDTH = 640

local function resolveSafeCreateFrame(override)
	if type(override) == "function" then
		return override
	end
	if Internal and type(Internal.safeCreateFrame) == "function" then
		return Internal.safeCreateFrame
	end
	if type(CreateFrame) == "function" then
		return CreateFrame
	end
	return nil
end

local function ClearAnchors(frame, resetSize)
	if not frame then
		return
	end
	if frame.ClearAllPoints then
		frame:ClearAllPoints()
	end
	if resetSize and frame.SetSize then
		frame:SetSize(1, 1)
	end
end

local function CreateContainer(name, parent, template, override)
	local safeCreateFrame = resolveSafeCreateFrame(override)
	if not safeCreateFrame or not parent then
		return nil
	end
	return safeCreateFrame("Frame", name, parent, template)
end

local function CreateRow(name, parent, height, template, override)
	local row = CreateContainer(name, parent, template, override)
	if row and height then
		row:SetHeight(height)
	end
	return row
end

FrameUI.CreateContainer = FrameUI.CreateContainer or CreateContainer
FrameUI.CreateRow = FrameUI.CreateRow or CreateRow
FrameUI.ClearAnchors = FrameUI.ClearAnchors or ClearAnchors
if Internal then
	Internal.CreateContainer = Internal.CreateContainer or CreateContainer
	Internal.CreateRow = Internal.CreateRow or CreateRow
	Internal.ClearAnchors = Internal.ClearAnchors or ClearAnchors
end

local function clampListWidth(container, width)
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local separatorWidth = Metrics.SEPARATOR_W or math.max(8, math.floor((Metrics.GAP_M or 10) * 0.6))
	local separatorGap = Metrics.SEPARATOR_GAP or Metrics.GAP_S or 6
	local available = (container and container:GetWidth()) or (DEFAULT_WIDTH - (padOuter * 2))
	local usable = available - (padInset * 2) - separatorWidth - separatorGap - MIN_READER_WIDTH
	local maxWidth = math.max(MIN_LIST_WIDTH, usable)
	return math.max(MIN_LIST_WIDTH, math.min(width, maxWidth))
end

local function configureSplitter(splitter)
	local handle = splitter:CreateTexture(nil, "ARTWORK")
	handle:SetAllPoints(true)
	handle:SetColorTexture(0.9, 0.75, 0.3, 0.25)
	local grip = splitter:CreateTexture(nil, "OVERLAY")
	grip:SetSize(4, 32)
	grip:SetPoint("CENTER")
	grip:SetColorTexture(1, 0.82, 0, 0.75)
	splitter:SetScript("OnEnter", function(self)
		self:SetAlpha(1)
	end)
	splitter:SetScript("OnLeave", function(self)
		if not self.__isDragging then
			self:SetAlpha(0.85)
		end
	end)
	splitter:SetAlpha(0.85)
end

local function createContentLayout(frame, safeCreateFrame, opts)
	local createHeaderBar = FrameUI.CreateHeaderBar
	local header = frame.HeaderFrame or (createHeaderBar and createHeaderBar(frame, safeCreateFrame))
	if not header then
		return nil
	end
	local body = safeCreateFrame("Frame", nil, frame)
	if not body then
		return nil
	end
	local padOuter = Metrics.PAD_OUTER or Metrics.PAD or 12
	local padInset = Metrics.PAD_INSET or Metrics.PAD or 10
	local bodyGap = Metrics.GAP_M or Metrics.GUTTER or 10
	ClearAnchors(body)
	body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -bodyGap)
	body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padOuter, padOuter)
	frame.ContentFrame = body
	frame.BodyFrame = body
	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("body", body)
	end

	local listInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	local readerInset = safeCreateFrame("Frame", nil, body, "InsetFrameTemplate3")
	if not listInset or not readerInset then
		return nil
	end

	ClearAnchors(listInset)
	listInset:SetPoint("TOPLEFT", body, "TOPLEFT", padInset, -padInset)
	listInset:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", padInset, padInset)

	ClearAnchors(readerInset)
	readerInset:SetPoint("TOPRIGHT", body, "TOPRIGHT", -padInset, -padInset)
	readerInset:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -padInset, padInset)

	local splitter = safeCreateFrame("Frame", nil, body)
	local separatorWidth = Metrics.SEPARATOR_W or math.max(8, math.floor((Metrics.GAP_M or 10) * 0.6))
	splitter:SetWidth(separatorWidth)
	splitter:EnableMouse(true)
	splitter:RegisterForDrag("LeftButton")
	configureSplitter(splitter)
	frame.SplitterFrame = splitter
	frame.SeparatorFrame = splitter

	if Internal and Internal.registerGridTarget then
		Internal.registerGridTarget("list-inset", listInset)
		Internal.registerGridTarget("reader-inset", readerInset)
		Internal.registerGridTarget("body-separator", splitter)
	end

	frame.listBlock = listInset
	frame.ListInset = listInset
	frame.readerBlock = readerInset
	frame.ReaderInset = readerInset

	local separatorGap = Metrics.SEPARATOR_GAP or Metrics.GAP_S or 6
	local initialWidth = opts.getPreferredListWidth and opts.getPreferredListWidth() or 360
	local layoutState = {
		currentWidth = 0,
		separatorWidth = separatorWidth,
	}

	local function applyWidth(width, skipPersist)
		layoutState.currentWidth = clampListWidth(body, width)
		listInset:SetWidth(layoutState.currentWidth)

		local sepOffset = padInset + layoutState.currentWidth
		ClearAnchors(splitter)
		splitter:SetPoint("TOPLEFT", body, "TOPLEFT", sepOffset, -padInset)
		splitter:SetPoint("BOTTOMLEFT", body, "BOTTOMLEFT", sepOffset, padInset)

		ClearAnchors(readerInset)
		readerInset:SetPoint("TOPLEFT", body, "TOPLEFT", sepOffset + layoutState.separatorWidth + separatorGap, -padInset)
		readerInset:SetPoint("BOTTOMRIGHT", body, "BOTTOMRIGHT", -padInset, padInset)

		frame.currentListWidth = layoutState.currentWidth
		if not skipPersist and opts.onListWidthChanged then
			opts.onListWidthChanged(layoutState.currentWidth)
		end
	end

	applyWidth(initialWidth, true)

	body:SetScript("OnSizeChanged", function()
		applyWidth(layoutState.currentWidth, true)
	end)

	local function finishDrag()
		splitter.__isDragging = false
		splitter:SetScript("OnUpdate", nil)
		splitter:SetAlpha(0.85)
		applyWidth(layoutState.currentWidth)
	end

	local function beginDrag()
		splitter.__isDragging = true
		splitter:SetAlpha(1)
		splitter:SetScript("OnUpdate", function()
			local cursorX = 0
			local scale = UIParent and UIParent:GetEffectiveScale() or 1
			if GetCursorPosition then
				cursorX = select(1, GetCursorPosition()) / scale
			end
			local bodyLeft = body:GetLeft()
			if bodyLeft then
				local desired = cursorX - bodyLeft - padInset
				applyWidth(desired, true)
			end
		end)
	end

	splitter:SetScript("OnMouseDown", beginDrag)
	splitter:SetScript("OnDragStart", beginDrag)
	splitter:SetScript("OnMouseUp", finishDrag)
	splitter:SetScript("OnDragStop", finishDrag)
	splitter:SetScript("OnHide", function()
		if splitter.__isDragging then
			finishDrag()
		end
	end)

	return true
end

local function attachListUI(listUI, frame, listWrapper)
	if not listUI or type(listUI.Create) ~= "function" then
		return
	end
	
	-- Use the wrapper frame (traditional frame inside AceGUI container)
	local listContainer = listWrapper or frame
	
	local ok, err = pcall(listUI.Create, listUI, listContainer)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist list UI failed: " .. tostring(err))
	end
end

local function attachReaderUI(readerUI, listUI, frame, readerWrapper)
	if not readerUI or type(readerUI.Create) ~= "function" then
		return
	end
	
	-- Use the wrapper frame (traditional frame inside AceGUI container)
	local readerContainer = readerWrapper or frame
	
	-- CRITICAL: Do NOT pass list block as anchor to prevent cross-anchoring.
	-- Reader should fill readerContainer and be 100% wrapper-relative.
	local ok, err = pcall(readerUI.Create, readerUI, readerContainer, readerContainer)
	if not ok and BookArchivist and BookArchivist.LogError then
		BookArchivist:LogError("BookArchivist reader UI failed: " .. tostring(err))
	end
end

FrameUI.CreateContentLayout = FrameUI.CreateContentLayout or createContentLayout
FrameUI.AttachListUI = FrameUI.AttachListUI or attachListUI
FrameUI.AttachReaderUI = FrameUI.AttachReaderUI or attachReaderUI
