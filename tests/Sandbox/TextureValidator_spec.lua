-- Tests for BookArchivist_TextureValidator
-- Security validation for texture paths in imported books

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

describe("TextureValidator", function()
	local TextureValidator
	
	before_each(function()
		-- Setup namespace
		helper.setupNamespace()
		
		-- Load the module
		helper.loadFile("core/BookArchivist_TextureValidator.lua")
		
		TextureValidator = BookArchivist.TextureValidator
	end)
	
	after_each(function()
		-- Cleanup
		BookArchivist.TextureValidator = nil
	end)
	
	describe("IsValidTexturePath", function()
		it("should exist", function()
			assert.is_not_nil(TextureValidator)
			assert.is_not_nil(TextureValidator.IsValidTexturePath)
			assert.equal("function", type(TextureValidator.IsValidTexturePath))
		end)
		
		describe("Valid paths", function()
			it("should accept Interface\\Icons paths", function()
				local valid, reason = TextureValidator.IsValidTexturePath("Interface\\Icons\\INV_Misc_Book_01")
				assert.is_true(valid)
				assert.is_nil(reason)
			end)
			
			it("should accept Interface\\ICONS with forward slashes", function()
				local valid = TextureValidator.IsValidTexturePath("Interface/Icons/INV_Misc_Book_01")
				assert.is_true(valid)
			end)
			
			it("should accept Interface\\Pictures paths", function()
				local valid = TextureValidator.IsValidTexturePath("Interface\\Pictures\\LoadingScreen_Generic")
				assert.is_true(valid)
			end)
			
			it("should accept Interface\\GLUES paths", function()
				local valid = TextureValidator.IsValidTexturePath("Interface\\GLUES\\MODELS\\UI_MainMenu\\UI_MainMenu")
				assert.is_true(valid)
			end)
			
			it("should accept WorldMap paths", function()
				local valid = TextureValidator.IsValidTexturePath("WorldMap\\Azeroth\\Azeroth")
				assert.is_true(valid)
			end)
		end)
		
		describe("Invalid paths - security threats", function()
			it("should reject nil path", function()
				local valid, reason = TextureValidator.IsValidTexturePath(nil)
				assert.is_false(valid)
				assert.is_not_nil(reason)
				assert.matches("empty", reason:lower())
			end)
			
			it("should reject empty string", function()
				local valid, reason = TextureValidator.IsValidTexturePath("")
				assert.is_false(valid)
				assert.is_not_nil(reason)
			end)
			
			it("should reject parent directory traversal (..)", function()
				local valid, reason = TextureValidator.IsValidTexturePath("Interface\\Icons\\..\\..\\System32\\calc.exe")
				assert.is_false(valid)
				assert.matches("traversal", reason:lower())
			end)
			
			it("should reject paths outside whitelist", function()
				local valid, reason = TextureValidator.IsValidTexturePath("Interface\\AddOns\\SomeAddon\\secret.tga")
				assert.is_false(valid)
				assert.matches("whitelist", reason:lower())
			end)
			
			it("should reject arbitrary addon paths", function()
				local valid, reason = TextureValidator.IsValidTexturePath("Interface\\AddOns\\OtherAddon\\Logo.blp")
				assert.is_false(valid)
			end)
		end)
		
		describe("Case sensitivity", function()
			it("should accept mixed case Interface\\Icons", function()
				local valid = TextureValidator.IsValidTexturePath("interface\\icons\\inv_misc_book_01")
				assert.is_true(valid)
			end)
			
			it("should accept INTERFACE\\ICONS uppercase", function()
				local valid = TextureValidator.IsValidTexturePath("INTERFACE\\ICONS\\INV_MISC_BOOK_01")
				assert.is_true(valid)
			end)
		end)
		
		describe("Edge cases", function()
			it("should reject very long paths (>500 chars)", function()
				local longPath = "Interface\\Icons\\" .. string.rep("A", 500)
				local valid, reason = TextureValidator.IsValidTexturePath(longPath)
				assert.is_false(valid)
				assert.matches("too long", reason:lower())
			end)
			
			it("should reject paths with null bytes", function()
				local valid, reason = TextureValidator.IsValidTexturePath("Interface\\Icons\\test\0hidden")
				assert.is_false(valid)
				assert.matches("null byte", reason:lower())
			end)
			
			it("should handle trailing slashes", function()
				local valid = TextureValidator.IsValidTexturePath("Interface\\Icons\\")
				assert.is_false(valid)
			end)
		end)
	end)
	
	describe("GetFallbackTexture", function()
		it("should exist", function()
			assert.is_not_nil(TextureValidator.GetFallbackTexture)
			assert.equal("function", type(TextureValidator.GetFallbackTexture))
		end)
		
		it("should return a valid fallback texture path", function()
			local fallback = TextureValidator.GetFallbackTexture()
			assert.is_not_nil(fallback)
			assert.is_string(fallback)
			assert.is_true(#fallback > 0)
		end)
		
		it("should return a whitelisted path", function()
			local fallback = TextureValidator.GetFallbackTexture()
			local valid = TextureValidator.IsValidTexturePath(fallback)
			assert.is_true(valid)
		end)
	end)
	
	describe("SanitizeTexturePath", function()
		it("should exist", function()
			assert.is_not_nil(TextureValidator.SanitizeTexturePath)
			assert.equal("function", type(TextureValidator.SanitizeTexturePath))
		end)
		
		it("should return valid path unchanged", function()
			local input = "Interface\\Icons\\INV_Misc_Book_01"
			local output = TextureValidator.SanitizeTexturePath(input)
			assert.equal(input, output)
		end)
		
		it("should return fallback for invalid path", function()
			local input = "C:\\Windows\\System32\\evil.dll"
			local output = TextureValidator.SanitizeTexturePath(input)
			local fallback = TextureValidator.GetFallbackTexture()
			assert.equal(fallback, output)
		end)
		
		it("should normalize forward/backslash", function()
			local input = "Interface/Icons/INV_Misc_Book_01"
			local output = TextureValidator.SanitizeTexturePath(input)
			assert.is_not_nil(output)
			-- Should be valid regardless of slash direction
			local valid = TextureValidator.IsValidTexturePath(output)
			assert.is_true(valid)
		end)
		
		it("should handle nil gracefully", function()
			local output = TextureValidator.SanitizeTexturePath(nil)
			assert.is_not_nil(output)
			assert.equal(TextureValidator.GetFallbackTexture(), output)
		end)
	end)
	
	describe("Integration with security settings", function()
		it("should support strict mode by default", function()
			-- Default behavior should be strict (reject non-whitelisted)
			local valid = TextureValidator.IsValidTexturePath("Interface\\AddOns\\TestAddon\\test.tga")
			assert.is_false(valid)
		end)
	end)
end)
