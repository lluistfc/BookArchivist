---@diagnostic disable: undefined-global
-- BookArchivist_FontSize.lua
-- Handles font size customization for the reader panel.

local BA = BookArchivist

local FontSize = {}
BA.FontSize = FontSize

-- Default font size (base scale = 1.0)
local DEFAULT_FONT_SIZE = 1.0
local MIN_FONT_SIZE = 0.8  -- 80% of normal
local MAX_FONT_SIZE = 1.5  -- 150% of normal

-- Cache for scaled fonts to avoid recreating them
local scaledFontCache = {}

--- Gets the current font scale factor from settings.
-- @return number The font scale (1.0 = normal size)
function FontSize:GetScale()
	if not BA.Repository or not BA.Repository.GetDB then
		return DEFAULT_FONT_SIZE
	end
	
	local db = BA.Repository:GetDB()
	if not db or not db.options then
		return DEFAULT_FONT_SIZE
	end
	
	local scale = db.options.fontSize
	if not scale or type(scale) ~= "number" then
		return DEFAULT_FONT_SIZE
	end
	
	-- Clamp to valid range
	return math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, scale))
end

--- Sets the font scale factor.
-- @param scale number The font scale (1.0 = normal size)
function FontSize:SetScale(scale)
	if not BA.Repository or not BA.Repository.GetDB then
		return
	end
	
	local db = BA.Repository:GetDB()
	if not db then
		return
	end
	
	db.options = db.options or {}
	
	-- Clamp to valid range
	scale = math.max(MIN_FONT_SIZE, math.min(MAX_FONT_SIZE, scale))
	db.options.fontSize = scale
	
	-- Clear font cache when scale changes
	scaledFontCache = {}
	
	-- Notify that font size changed
	if BA and BA.DebugPrint then
		BA:DebugPrint("[FontSize] Scale set to:", scale)
	end
end

--- Gets the default font size.
-- @return number The default font scale
function FontSize:GetDefault()
	return DEFAULT_FONT_SIZE
end

--- Gets the minimum font size.
-- @return number The minimum font scale
function FontSize:GetMin()
	return MIN_FONT_SIZE
end

--- Gets the maximum font size.
-- @return number The maximum font scale
function FontSize:GetMax()
	return MAX_FONT_SIZE
end

--- Applies the current font scale to a FontString.
-- This scales the font relative to its current/base size.
-- @param fontString userdata The FontString widget to scale
-- @param baseTemplate string|nil Optional base font template name
function FontSize:ApplyToFontString(fontString, baseTemplate)
	if not fontString then
		return
	end
	
	local scale = self:GetScale()
	if scale == 1.0 then
		-- No scaling needed
		return
	end
	
	-- Get current font info
	local fontPath, baseFontSize, fontFlags
	if fontString.GetFont then
		fontPath, baseFontSize, fontFlags = fontString:GetFont()
	end
	
	if not fontPath or not baseFontSize then
		return
	end
	
	-- Calculate scaled size
	local scaledSize = math.floor(baseFontSize * scale + 0.5)
	
	-- Apply the scaled font
	if fontString.SetFont then
		fontString:SetFont(fontPath, scaledSize, fontFlags or "")
	end
end

--- Gets a scaled font size based on a base size.
-- @param baseSize number The base font size in pixels
-- @return number The scaled font size
function FontSize:GetScaledSize(baseSize)
	local scale = self:GetScale()
	return math.floor(baseSize * scale + 0.5)
end

--- Gets the display percentage for the current scale.
-- @return string The percentage string (e.g., "100%")
function FontSize:GetDisplayPercentage()
	local scale = self:GetScale()
	return string.format("%d%%", math.floor(scale * 100 + 0.5))
end

return FontSize
