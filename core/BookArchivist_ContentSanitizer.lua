---@diagnostic disable: undefined-global
-- BookArchivist_ContentSanitizer.lua
-- Phase 3: Content sanitization for imported books
-- Enforces string length limits and removes dangerous characters

local BA = BookArchivist

local ContentSanitizer = {}
BA.ContentSanitizer = ContentSanitizer

-- Security limits
local MAX_TITLE_LENGTH = 255
local MAX_PAGE_LENGTH = 10000
local MAX_PAGE_COUNT = 100

---Strip null bytes from string
---@param str string
---@return string
function ContentSanitizer.StripNullBytes(str)
	if not str then return "" end
	-- Remove all null bytes (00)
	return str:gsub("%z", "")
end

---Normalize line endings (CRLF -> LF)
---@param str string
---@return string
function ContentSanitizer.NormalizeLineEndings(str)
	if not str then return "" end
	-- Convert Windows line endings to Unix
	return str:gsub("\r\n", "\n"):gsub("\r", "\n")
end

---Remove non-printable control characters (except newline, tab, carriage return)
---@param str string
---@return string
function ContentSanitizer.StripControlChars(str)
	if not str then return "" end
	
	-- Allow: newline (10), tab (9), carriage return (13)
	-- Remove: other control chars (0-8, 11-12, 14-31, 127)
	local result = {}
	for i = 1, #str do
		local byte = str:byte(i)
		-- Keep printable chars (32-126) and allowed whitespace (9, 10, 13)
		if (byte >= 32 and byte <= 126) or byte == 9 or byte == 10 or byte == 13 then
			table.insert(result, str:sub(i, i))
		end
	end
	
	return table.concat(result)
end

---Sanitize title (enforce length limit)
---@param title string
---@return string
function ContentSanitizer.SanitizeTitle(title)
	if not title or type(title) ~= "string" then
		return ""
	end
	
	-- Strip null bytes and control chars first
	local clean = ContentSanitizer.StripNullBytes(title)
	clean = ContentSanitizer.StripControlChars(clean)
	
	-- Enforce length limit
	if #clean > MAX_TITLE_LENGTH then
		clean = clean:sub(1, MAX_TITLE_LENGTH)
	end
	
	return clean
end

---Sanitize single page content (enforce length limit)
---@param page string
---@return string
function ContentSanitizer.SanitizePage(page)
	if not page or type(page) ~= "string" then
		return ""
	end
	
	-- Strip null bytes and normalize line endings
	local clean = ContentSanitizer.StripNullBytes(page)
	clean = ContentSanitizer.NormalizeLineEndings(clean)
	clean = ContentSanitizer.StripControlChars(clean)
	
	-- Enforce length limit
	if #clean > MAX_PAGE_LENGTH then
		clean = clean:sub(1, MAX_PAGE_LENGTH)
	end
	
	return clean
end

---Sanitize pages array (enforce count and content limits)
---@param pages table|nil
---@return table
function ContentSanitizer.SanitizePages(pages)
	if not pages or type(pages) ~= "table" then
		return {}
	end
	
	local cleanPages = {}
	local count = 0
	
	for i, page in ipairs(pages) do
		if count >= MAX_PAGE_COUNT then
			break
		end
		
		table.insert(cleanPages, ContentSanitizer.SanitizePage(page))
		count = count + 1
	end
	
	return cleanPages
end

---Sanitize a full book entry
---@param book table The book entry to sanitize
---@param options table|nil Options (report: boolean)
---@return table cleanBook The sanitized book
---@return table|nil report Sanitization report if options.report = true
function ContentSanitizer.SanitizeBook(book, options)
	options = options or {}
	
	if not book or type(book) ~= "table" then
		return {
			title = "",
			pages = {},
			creator = "",
			material = ""
		}
	end
	
	local report = {}
	
	-- Sanitize title
	local originalTitle = book.title or ""
	local cleanTitle = ContentSanitizer.SanitizeTitle(originalTitle)
	if #originalTitle > MAX_TITLE_LENGTH then
		report.titleTruncated = true
	end
	
	-- Sanitize pages
	local originalPages = book.pages or {}
	local cleanPages = ContentSanitizer.SanitizePages(originalPages)
	if #originalPages > MAX_PAGE_COUNT then
		report.pagesTooMany = true
		report.pagesRemoved = #originalPages - MAX_PAGE_COUNT
	end
	
	-- Check for page truncation
	for i, page in ipairs(originalPages) do
		if i > MAX_PAGE_COUNT then break end
		if type(page) == "string" and #page > MAX_PAGE_LENGTH then
			report.pagesTruncated = report.pagesTruncated or {}
			table.insert(report.pagesTruncated, i)
		end
	end
	
	-- Sanitize string fields
	local cleanBook = {
		title = cleanTitle,
		pages = cleanPages,
		creator = ContentSanitizer.StripNullBytes(book.creator or ""),
		material = ContentSanitizer.StripNullBytes(book.material or ""),
	}
	
	-- Preserve non-string fields as-is
	for key, value in pairs(book) do
		if key ~= "title" and key ~= "pages" and key ~= "creator" and key ~= "material" then
			cleanBook[key] = value
		end
	end
	
	if options.report then
		return cleanBook, report
	end
	
	return cleanBook
end

---Get security limits (for documentation/UI display)
---@return table limits
function ContentSanitizer.GetLimits()
	return {
		maxTitleLength = MAX_TITLE_LENGTH,
		maxPageLength = MAX_PAGE_LENGTH,
		maxPageCount = MAX_PAGE_COUNT
	}
end

return ContentSanitizer
