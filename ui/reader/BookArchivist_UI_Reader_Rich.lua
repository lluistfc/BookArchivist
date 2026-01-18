---@diagnostic disable: undefined-global, undefined-field
local BA = BookArchivist
BA.UI = BA.UI or {}

local ReaderUI = BA.UI.Reader or {}
BA.UI.Reader = ReaderUI

local state = ReaderUI.__state or {}
ReaderUI.__state = state

local getWidget = ReaderUI.__getWidget
local safeCreateFrame = ReaderUI.__safeCreateFrame
local debugPrint = ReaderUI.__debugPrint or function(...)
	BA:DebugPrint(...)
end

local function isUIDebugEnabled()
	if BA and BA.IsUIDebugEnabled then
		return BA:IsUIDebugEnabled() and true or false
	end
	return false
end
-- HTML utility functions now live in BookArchivist_UI_Reader_HTML and are
-- exported on ReaderUI. The rich renderer uses those shared helpers.
local normalizeHTMLForReader = ReaderUI.NormalizeHTMLForReader
local parsePageToBlocks = ReaderUI.ParsePageToBlocks
	or function(html)
		if not html or html == "" then
			return {}
		end
		return {
			{ kind = "paragraph", text = tostring(html), align = "LEFT" },
		}
	end

local function resetRichPools()
	if state.richTextPool then
		for _, entry in ipairs(state.richTextPool) do
			entry.inUse = false
			if entry.fs then
				entry.fs:Hide()
			end
		end
	end
	if state.richTexPool then
		for _, entry in ipairs(state.richTexPool) do
			entry.inUse = false
			if entry.tex then
				entry.tex:Hide()
			end
		end
	end
end

local function resetRichDebugFrames(parent)
	if not state.richDebugFrames then
		return
	end
	parent = parent or state.textChild or (getWidget and getWidget("textChild")) or UIParent
	for _, frame in ipairs(state.richDebugFrames) do
		if frame then
			frame:Hide()
			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
			frame:SetSize(0.01, 0.01)
		end
	end
end

local function ensureRichDebugFrame(index, parent)
	if not isUIDebugEnabled() then
		return nil
	end
	parent = parent or state.textChild or (getWidget and getWidget("textChild"))
	if not parent then
		return nil
	end

	state.richDebugFrames = state.richDebugFrames or {}
	local frame = state.richDebugFrames[index]
	if not frame then
		frame = (safeCreateFrame and safeCreateFrame("Frame", nil, parent))
			or (CreateFrame and CreateFrame("Frame", nil, parent))
		if not frame then
			return nil
		end
		frame:EnableMouse(false)
		local level = (parent.GetFrameLevel and parent:GetFrameLevel()) or 0
		frame:SetFrameLevel(math.min(level + 5, 128))

		state.richDebugFrames[index] = frame

		if
			BookArchivist
			and BookArchivist.UI
			and BookArchivist.UI.Internal
			and BookArchivist.UI.Internal.registerGridTarget
		then
			local name = "reader-html-" .. tostring(index)
			BookArchivist.UI.Internal.registerGridTarget(name, frame)
		end
	end
	frame:Show()
	return frame
end

local function acquireFontStringForKind(kind)
	state.richTextPool = state.richTextPool or {}
	local template
	if kind == "heading1" then
		template = "GameFontNormalHuge"
	elseif kind == "heading2" or kind == "heading3" then
		template = "GameFontNormalLarge"
	else
		template = "GameFontHighlight"
	end

	for _, entry in ipairs(state.richTextPool) do
		if not entry.inUse then
			entry.inUse = true
			local fs = entry.fs
			if fs and fs.SetFontObject and template then
				fs:SetFontObject(template)
			end
			if fs then
				fs:Show()
			end
			return fs
		end
	end

	if not state.textChild then
		state.textChild = getWidget and getWidget("textChild")
	end
	local parent = state.textChild
	if not parent or not parent.CreateFontString then
		return nil
	end
	local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("TOP")
	fs:SetWordWrap(true)
	fs:SetNonSpaceWrap(true)
	fs:SetSpacing(2)

	local entry = { fs = fs, inUse = true }
	table.insert(state.richTextPool, entry)
	return fs
end

local function acquireTextureForKind(kind)
	state.richTexPool = state.richTexPool or {}
	for _, entry in ipairs(state.richTexPool) do
		if not entry.inUse then
			entry.inUse = true
			if entry.tex then
				entry.tex:Show()
			end
			return entry.tex
		end
	end

	if not state.textChild then
		state.textChild = getWidget and getWidget("textChild")
	end
	local parent = state.textChild
	if not parent or not parent.CreateTexture then
		return nil
	end
	local tex = parent:CreateTexture(nil, "ARTWORK")
	if kind == "rule" then
		tex:SetColorTexture(1, 1, 1, 0.25)
	end

	local entry = { tex = tex, inUse = true }
	table.insert(state.richTexPool, entry)
	return tex
end

local function renderRichHTMLPage(text)
	if not state.textChild then
		state.textChild = getWidget and getWidget("textChild")
	end
	local child = state.textChild
	if not child then
		return false
	end

	if state.textPlain and state.textPlain.Hide then
		state.textPlain:Hide()
	end
	if state.htmlText and state.htmlText.Hide then
		state.htmlText:Hide()
	end

	resetRichPools()
	resetRichDebugFrames(child)

	local host = state.contentHost or (getWidget and getWidget("contentHost"))
	local availableWidth = host and host.GetWidth and host:GetWidth() or (child.GetWidth and child:GetWidth()) or 400
	local padX = 10
	local topPad = 10
	local bottomPad = 12
	local contentWidth = math.max(50, availableWidth - padX * 2)

	local normalized = text
	if normalizeHTMLForReader then
		local norm, _, _ = normalizeHTMLForReader(text, contentWidth)
		if norm and norm ~= "" then
			normalized = norm
		end
	end
	local blocks = parsePageToBlocks(normalized or text)
	if not blocks or #blocks == 0 then
		return false
	end

	local y = -topPad
	local previousKind = nil
	local previousVisualKind = nil
	local debugIndex = 1
	for _, block in ipairs(blocks) do
		if block.kind == "heading" then
			if previousVisualKind == "image" then
				y = y - 4
			end
			local kindKey = block.level == 1 and "heading1" or (block.level == 2 and "heading2" or "heading3")
			local fs = acquireFontStringForKind(kindKey)
			if fs then
				fs:ClearAllPoints()
				fs:SetWidth(contentWidth)
				fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
				fs:SetText(block.text or "")
				fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
				local h = fs:GetStringHeight() or 0

				local dbg = ensureRichDebugFrame(debugIndex, child)
				if dbg then
					dbg:ClearAllPoints()
					dbg:SetAllPoints(fs)
				end
				debugIndex = debugIndex + 1

				y = y - h - 10
			end
			previousVisualKind = "text"
		elseif block.kind == "paragraph" then
			if previousVisualKind == "image" then
				y = y - 4
			end
			local fs = acquireFontStringForKind("paragraph")
			if fs then
				fs:ClearAllPoints()
				fs:SetWidth(contentWidth)
				fs:SetJustifyH((block.align == "CENTER" or block.align == "RIGHT") and block.align or "LEFT")
				fs:SetText(block.text or "")
				fs:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
				local h = fs:GetStringHeight() or 0

				local dbg = ensureRichDebugFrame(debugIndex, child)
				if dbg then
					dbg:ClearAllPoints()
					dbg:SetAllPoints(fs)
				end
				debugIndex = debugIndex + 1

				y = y - h - 8
			end
			previousVisualKind = "text"
		elseif block.kind == "image" then
			local tex = acquireTextureForKind("image")
			if tex and block.src and block.src ~= "" then
				tex:ClearAllPoints()
			
			-- Security: Validate texture path before rendering
			local texturePath = block.src
			if BA.TextureValidator then
				local valid, reason = BA.TextureValidator.IsValidTexturePath(texturePath)
				if not valid then
					-- Log security rejection
					if BA and BA.DebugPrint then
						BA:DebugPrint("[Reader] Rejected texture path:", texturePath, "reason:", reason)
					end
					-- Use fallback texture for security
					texturePath = BA.TextureValidator.GetFallbackTexture()
				end
			end
			
			tex:SetTexture(texturePath)
				local w = block.width or contentWidth
				local h = block.height or math.floor(w * 0.62 + 0.5)
				w = math.min(w, contentWidth)
				h = math.min(h, 600)

				local usedAtlas = false
				local atlasInfo = ReaderUI.GetArtifactBookTexInfo and ReaderUI.GetArtifactBookTexInfo(block.src)
				if atlasInfo then
					local ratio, left, right, top, bottom = unpack(atlasInfo)
					local imageWidth = contentWidth
					local imageHeight = math.min(600, math.max(32, math.floor(imageWidth * ratio + 0.5)))
					w, h = imageWidth, imageHeight
					tex:SetTexCoord(left, right, top, bottom)
					usedAtlas = true
				end

				if not usedAtlas then
					tex:SetTexCoord(0, 1, 0, 1)
				end

				tex:SetSize(w, h)
				local align = block.align or "CENTER"
				if align == "LEFT" then
					tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
				elseif align == "RIGHT" then
					tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)
				else
					tex:SetPoint("TOP", child, "TOP", 0, y)
				end

				local dbg = ensureRichDebugFrame(debugIndex, child)
				if dbg then
					dbg:ClearAllPoints()
					dbg:SetAllPoints(tex)
				end
				debugIndex = debugIndex + 1

				y = y - h - 6
			end
			previousVisualKind = "image"
		elseif block.kind == "spacer" then
			local gap = tonumber(block.height) or 10
			if previousKind == "image" then
				gap = math.min(gap, 4)
			end
			y = y - gap
		elseif block.kind == "rule" then
			local tex = acquireTextureForKind("rule")
			if tex then
				tex:ClearAllPoints()
				tex:SetHeight(2)
				tex:SetPoint("TOPLEFT", child, "TOPLEFT", padX, y)
				tex:SetPoint("TOPRIGHT", child, "TOPRIGHT", -padX, y)

				local dbg = ensureRichDebugFrame(debugIndex, child)
				if dbg then
					dbg:ClearAllPoints()
					dbg:SetAllPoints(tex)
				end
				debugIndex = debugIndex + 1

				y = y - 8
			end
			previousVisualKind = "text"
		end

		previousKind = block.kind
	end

	local totalHeight = -y + bottomPad
	if ReaderUI.UpdateReaderHeight then
		ReaderUI.UpdateReaderHeight(totalHeight)
	end
	if state.textScroll and state.textScroll.UpdateScrollChildRect then
		state.textScroll:UpdateScrollChildRect()
	end
	if state.textScroll and state.textScroll.ScrollBar and state.textScroll.ScrollBar.SetValue then
		state.textScroll.ScrollBar:SetValue(0)
	elseif state.textScroll and state.textScroll.SetVerticalScroll then
		state.textScroll:SetVerticalScroll(0)
	end

	return true
end

ReaderUI.RenderRichHTMLPage = renderRichHTMLPage
ReaderUI.ResetRichPools = resetRichPools
