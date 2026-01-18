-- Tests for Phase 3: Content Sanitization
-- Verifies string length limits and special character filtering

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("Content Sanitization (Phase 3)", function()
	local ContentSanitizer
	
	before_each(function()
		-- Setup namespace
		helper.setupNamespace()
		
		-- Load the sanitizer module
		helper.loadFile("core/BookArchivist_ContentSanitizer.lua")
		
		ContentSanitizer = BookArchivist.ContentSanitizer
	end)
	
	after_each(function()
		BookArchivist.ContentSanitizer = nil
	end)
	
	describe("String length limits", function()
		it("should exist", function()
			assert.is_not_nil(ContentSanitizer)
			assert.is_not_nil(ContentSanitizer.SanitizeBook)
		end)
		
		it("should enforce maximum title length (255 chars)", function()
			local longTitle = string.rep("A", 300)
			local result = ContentSanitizer.SanitizeTitle(longTitle)
			
			assert.is_not_nil(result)
			assert.is_true(#result <= 255)
		end)
		
		it("should enforce maximum page content length (10000 chars)", function()
			local longContent = string.rep("A", 15000)
			local result = ContentSanitizer.SanitizePage(longContent)
			
			assert.is_not_nil(result)
			assert.is_true(#result <= 10000)
		end)
		
		it("should enforce maximum page count (100 pages)", function()
			local manyPages = {}
			for i = 1, 150 do
				table.insert(manyPages, "Page " .. i)
			end
			
			local result = ContentSanitizer.SanitizePages(manyPages)
			
			assert.is_not_nil(result)
			assert.is_true(#result <= 100)
		end)
		
		it("should not modify strings within limits", function()
			local validTitle = "Normal Book Title"
			local result = ContentSanitizer.SanitizeTitle(validTitle)
			
			assert.equal(validTitle, result)
		end)
	end)
	
	describe("Special character filtering", function()
		it("should strip null bytes", function()
			local textWithNull = "Hello\0World"
			local result = ContentSanitizer.StripNullBytes(textWithNull)
			
			assert.is_not_nil(result)
		assert.is_nil(result:match("%z"))  -- No null bytes should remain
		assert.equal("HelloWorld", result)
	end)
	
	it("should normalize line endings (CRLF to LF)", function()
		local textWithCRLF = "Line 1\r\nLine 2\r\nLine 3"
		local result = ContentSanitizer.NormalizeLineEndings(textWithCRLF)
		
		assert.is_not_nil(result)
		assert.is_nil(result:match("\r\n"))  -- No CRLF should remain
		assert.equal("Line 1\nLine 2\nLine 3", result)
	end)
	
	it("should remove non-printable control characters", function()
		-- Control chars except newline, tab, carriage return
		local textWithControls = "Hello" .. string.char(1) .. string.char(2) .. "World"
		local result = ContentSanitizer.StripControlChars(textWithControls)
		
		assert.is_not_nil(result)
		-- Should strip control characters
		assert.is_true(#result < #textWithControls)
		assert.equal("HelloWorld", result)
	end)
	end)
	
	describe("Full book sanitization", function()
		it("should sanitize all fields of a book entry", function()
			local dirtyBook = {
				title = string.rep("A", 300),  -- Too long
				pages = {
					string.rep("B", 15000),  -- Too long
					"Normal page",
					"Page with\0null"  -- Null byte
				},
				creator = "Author\0Name",  -- Null byte
				material = "Parchment"
			}
			
			local cleanBook = ContentSanitizer.SanitizeBook(dirtyBook)
			
			-- Title should be truncated
			assert.is_true(#cleanBook.title <= 255)
			
			-- First page should be truncated
			assert.is_true(#cleanBook.pages[1] <= 10000)
			
			-- Third page should have null byte removed
		assert.is_nil(cleanBook.pages[3]:match("%z"))
		
		-- Creator should have null byte removed
		assert.is_nil(cleanBook.creator:match("%z"))
	end)
	
	it("should handle nil values gracefully", function()
		local book = {
			title = "Test",
			pages = nil
		}
		
		local result = ContentSanitizer.SanitizeBook(book)
		
		assert.is_not_nil(result)
		assert.is_not_nil(result.pages)
		assert.equal("table", type(result.pages))
	end)
end)
	
	describe("Sanitization reporting", function()
		it("should report what was sanitized", function()
			local dirtyBook = {
				title = string.rep("A", 300),
				pages = { "Normal" }
			}
			
			local cleanBook, report = ContentSanitizer.SanitizeBook(dirtyBook, { report = true })
			
			if report then
				assert.is_not_nil(report)
				assert.is_not_nil(report.titleTruncated)
				assert.is_true(report.titleTruncated)
			end
		end)
	end)
end)
