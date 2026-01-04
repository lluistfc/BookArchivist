---@diagnostic disable: undefined-global, undefined-field
BookArchivist = BookArchivist or {}
BookArchivist.UI = BookArchivist.UI or {}

local ReaderUI = BookArchivist.UI.Reader or {}
BookArchivist.UI.Reader = ReaderUI

--
-- Shared HTML helpers for the reader. These are intentionally kept
-- stateless so they can be reused by both the core reader controller
-- and the rich renderer.
--

local function isHTMLContent(text)
	if not text or text == "" then return false end
	local lowered = text:lower()
	return lowered:find("<%s*html", 1, false)
		or lowered:find("<%s*body", 1, false)
		or lowered:find("<img", 1, false)
		or lowered:find("<table", 1, false)
		or lowered:find("<h%d", 1, false)
end

local function stripHTMLTags(text)
	if not text or text == "" then
		return text or ""
	end

	text = text:gsub("<%s*[Ii][Mm][Gg][^>]-src%s*=%s*\"([^\"]+)\"[^>]->", "[Image: %1]")
	text = text:gsub("<%s*[Ii][Mm][Gg][^>]->", "[Image]")

	local cleaned = text:gsub("<[^>]+>", "")

	cleaned = cleaned:gsub("\r\n", "\n")
	cleaned = cleaned:gsub("\n%s*\n%s*\n+", "\n\n")

	cleaned = cleaned:gsub("[ \t]+", " ")

	return cleaned
end

local function normalizeHTMLForReader(html, maxWidth)
	if not html or html == "" then
		return html or "", 0, 0
	end

	maxWidth = tonumber(maxWidth) or 0
	if maxWidth <= 0 then
		maxWidth = 230
	end

	local spacerCount = 0
	local resizedCount = 0

	local function processImg(tag)
		local src = tag:match("src%s*=%s*\"([^\"]+)\"") or tag:match("src%s*=%s*'([^']+)'")
		if not src then
			return tag
		end
		local lowerSrc = src:lower()

		if lowerSrc:find("interface\\common\\spacer", 1, true) then
			return ""
		end

		local width = tonumber(tag:match("width%s*=%s*\"(%d+)\"") or tag:match("width%s*=%s*'(%d+)'") or tag:match("width%s*=%s*(%d+)"))
		local height = tonumber(tag:match("height%s*=%s*\"(%d+)\"") or tag:match("height%s*=%s*'(%d+)'") or tag:match("height%s*=%s*(%d+)"))

		local defaultAspect = 145 / 230
		local w = width or maxWidth
		local h = height or math.floor(w * defaultAspect + 0.5)

		w = math.max(64, math.min(w, maxWidth))
		h = math.max(64, math.min(h, 600))

		local rebuilt = string.format("<IMG src=\"%s\" width=\"%d\" height=\"%d\"/>", src, w, h)
		return string.format("<P align=\"center\">%s</P>", rebuilt)
	end

	html = html:gsub("<%s*[Ii][Mm][Gg][^>]->", processImg)

	html = html:gsub("\r\n", "\n")
	html = html:gsub("<%s*[Pp]%s*[^>]*>%s*</%s*[Pp]%s*>", "<BR/>")
	html = html:gsub("(<%s*[Pp][^>]*>)(.-)(</%s*[Pp]%s*>)", function(open, body, close)
		body = body:gsub("\n+", "\n")
		body = body:gsub("%s+", " ")
		return open .. body .. close
	end)
	html = html:gsub("<%s*[Hh][Rr]%s*/?>", "<BR/>")
	local brPattern = "<%s*[Bb][Rr]%s*/?>"
	html = html:gsub("(" .. brPattern .. "%s*)%s*(" .. brPattern .. ")%s*(" .. brPattern .. ")+", "%1%2")

	return html, spacerCount, resizedCount
end

ReaderUI.IsHTMLContent = ReaderUI.IsHTMLContent or isHTMLContent
ReaderUI.StripHTMLTags = ReaderUI.StripHTMLTags or stripHTMLTags
ReaderUI.NormalizeHTMLForReader = ReaderUI.NormalizeHTMLForReader or normalizeHTMLForReader
