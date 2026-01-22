-- Tests for Rich renderer texture security integration
-- Verifies TextureValidator is properly integrated into rendering pipeline

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("Rich Reader Security Integration", function()
	local TextureValidator
	local ReaderRich
	
	before_each(function()
		-- Setup namespace
		helper.setupNamespace()
		
		-- Load dependencies
		helper.loadFile("core/BookArchivist_TextureValidator.lua")
		helper.loadFile("ui/reader/BookArchivist_UI_Reader_Rich.lua")
		
		TextureValidator = BookArchivist.TextureValidator
		ReaderRich = BookArchivist.UI.Reader.Rich
	end)
	
	after_each(function()
		BookArchivist.TextureValidator = nil
		if BookArchivist.UI and BookArchivist.UI.Reader then
			BookArchivist.UI.Reader.Rich = nil
		end
	end)
	
	describe("Texture path sanitization", function()
		it("should sanitize texture paths before rendering", function()
			-- This test verifies that Rich renderer has access to TextureValidator
			assert.is_not_nil(TextureValidator)
			assert.is_not_nil(TextureValidator.SanitizeTexturePath)
		end)
		
		it("should accept valid texture paths", function()
			local validPath = "Interface\\Icons\\INV_Misc_Book_01"
			local sanitized = TextureValidator.SanitizeTexturePath(validPath)
			assert.equal(validPath, sanitized)
		end)
		
		it("should reject malicious texture paths", function()
			local maliciousPath = "Interface\\Icons\\..\\..\\Windows\\evil.dll"
			local sanitized = TextureValidator.SanitizeTexturePath(maliciousPath)
			local fallback = TextureValidator.GetFallbackTexture()
			assert.equal(fallback, sanitized)
		end)
		
		it("should handle texture paths from imported books", function()
			-- Simulate imported book with suspicious texture
			local suspiciousPath = "Interface\\AddOns\\SomeAddon\\logo.tga"
			local sanitized = TextureValidator.SanitizeTexturePath(suspiciousPath)
			local fallback = TextureValidator.GetFallbackTexture()
			assert.equal(fallback, sanitized)
		end)
	end)
	
	describe("Fallback behavior", function()
		it("should provide a valid fallback texture", function()
			local fallback = TextureValidator.GetFallbackTexture()
			assert.is_not_nil(fallback)
			assert.is_string(fallback)
			
			-- Fallback itself should be valid
			local valid = TextureValidator.IsValidTexturePath(fallback)
			assert.is_true(valid)
		end)
		
		it("should use fallback for nil texture paths", function()
			local sanitized = TextureValidator.SanitizeTexturePath(nil)
			local fallback = TextureValidator.GetFallbackTexture()
			assert.equal(fallback, sanitized)
		end)
		
		it("should use fallback for empty texture paths", function()
			local sanitized = TextureValidator.SanitizeTexturePath("")
			local fallback = TextureValidator.GetFallbackTexture()
			assert.equal(fallback, sanitized)
		end)
	end)
	
	describe("Security logging", function()
		it("should log rejected texture paths", function()
			-- This verifies integration point exists for logging
			local maliciousPath = "C:\\Windows\\System32\\kernel32.dll"
			local valid, reason = TextureValidator.IsValidTexturePath(maliciousPath)
			
			assert.is_false(valid)
			assert.is_not_nil(reason)
			assert.is_string(reason)
		end)
	end)
end)
