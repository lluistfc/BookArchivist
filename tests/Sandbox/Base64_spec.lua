-- Base64 encoder/decoder tests
-- Pure Lua module - no WoW dependencies needed

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load Base64 module
helper.loadFile("core/BookArchivist_Base64.lua")

describe("Base64 (Core Module)", function()
  
  describe("Encode", function()
    it("should encode empty string as empty", function()
      local result = BookArchivist.Base64.Encode("")
      assert.are.equal("", result)
    end)
    
    it("should handle nil input", function()
      local result = BookArchivist.Base64.Encode(nil)
      assert.are.equal("", result)
    end)
    
    it("should handle non-string input", function()
      local result = BookArchivist.Base64.Encode(123)
      assert.are.equal("", result)
    end)
    
    it("should encode single byte", function()
      local result = BookArchivist.Base64.Encode("A")
      assert.are.equal("QQ==", result)
    end)
    
    it("should encode two bytes", function()
      local result = BookArchivist.Base64.Encode("AB")
      assert.are.equal("QUI=", result)
    end)
    
    it("should encode three bytes (no padding)", function()
      local result = BookArchivist.Base64.Encode("ABC")
      assert.are.equal("QUJD", result)
    end)
    
    it("should encode simple text", function()
      local result = BookArchivist.Base64.Encode("Hello")
      assert.are.equal("SGVsbG8=", result)
    end)
    
    it("should encode longer text", function()
      local result = BookArchivist.Base64.Encode("Hello, World!")
      assert.are.equal("SGVsbG8sIFdvcmxkIQ==", result)
    end)
    
    it("should encode binary data with null bytes", function()
      local data = string.char(0, 1, 2, 3, 255)
      local result = BookArchivist.Base64.Encode(data)
      -- Should not be empty and should decode back correctly
      assert.is_true(#result > 0)
    end)
    
    it("should handle special characters", function()
      local result = BookArchivist.Base64.Encode("!@#$%^&*()")
      assert.is_true(#result > 0)
      assert.is_true(result:match("^[A-Za-z0-9+/=]+$") ~= nil, "Should only contain base64 chars")
    end)
    
    it("should be deterministic", function()
      local text = "Test data 123"
      local result1 = BookArchivist.Base64.Encode(text)
      local result2 = BookArchivist.Base64.Encode(text)
      assert.are.equal(result1, result2)
    end)
    
    it("should produce different output for different input", function()
      local result1 = BookArchivist.Base64.Encode("AAA")
      local result2 = BookArchivist.Base64.Encode("BBB")
      assert.is_true(result1 ~= result2)
    end)
  end)
  
  describe("Decode", function()
    it("should return error for empty string", function()
      local result, err = BookArchivist.Base64.Decode("")
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("base64") ~= nil)
    end)
    
    it("should return error for nil input", function()
      local result, err = BookArchivist.Base64.Decode(nil)
      assert.is_nil(result)
      assert.is_not_nil(err)
    end)
    
    it("should return error for invalid length", function()
      local result, err = BookArchivist.Base64.Decode("ABC")
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("invalid base64 length") ~= nil)
    end)
    
    it("should return error for invalid characters", function()
      local result, err = BookArchivist.Base64.Decode("QQ!!")
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("invalid base64 character") ~= nil)
    end)
    
    it("should decode single byte with padding", function()
      local result, err = BookArchivist.Base64.Decode("QQ==")
      assert.is_nil(err)
      assert.are.equal("A", result)
    end)
    
    it("should decode two bytes with padding", function()
      local result, err = BookArchivist.Base64.Decode("QUI=")
      assert.is_nil(err)
      assert.are.equal("AB", result)
    end)
    
    it("should decode three bytes without padding", function()
      local result, err = BookArchivist.Base64.Decode("QUJD")
      assert.is_nil(err)
      assert.are.equal("ABC", result)
    end)
    
    it("should decode simple text", function()
      local result, err = BookArchivist.Base64.Decode("SGVsbG8=")
      assert.is_nil(err)
      assert.are.equal("Hello", result)
    end)
    
    it("should decode longer text", function()
      local result, err = BookArchivist.Base64.Decode("SGVsbG8sIFdvcmxkIQ==")
      assert.is_nil(err)
      assert.are.equal("Hello, World!", result)
    end)
    
    it("should handle whitespace in input", function()
      local result, err = BookArchivist.Base64.Decode("SGVs bG8s IFdv cmxk IQ==")
      assert.is_nil(err)
      assert.are.equal("Hello, World!", result)
    end)
    
    it("should handle newlines in input", function()
      local result, err = BookArchivist.Base64.Decode("SGVs\nbG8s\nIFdv\ncmxk\nIQ==")
      assert.is_nil(err)
      assert.are.equal("Hello, World!", result)
    end)
  end)
  
  describe("Round-trip (Encode → Decode)", function()
    it("should preserve empty string", function()
      local original = ""
      local encoded = BookArchivist.Base64.Encode(original)
      assert.are.equal("", encoded)
    end)
    
    it("should preserve single character", function()
      local original = "X"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve short text", function()
      local original = "Test"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve longer text", function()
      local original = "The quick brown fox jumps over the lazy dog"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve binary data with null bytes", function()
      local original = string.char(0, 1, 2, 3, 255, 254, 128, 127)
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve special characters", function()
      local original = "!@#$%^&*()_+-={}[]|\\:;\"'<>,.?/"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve UTF-8 multibyte characters", function()
      local original = "Hello 世界 🎉"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve WoW color codes", function()
      local original = "|cFFFF0000Red|r |cFF00FF00Green|r |cFF0000FFBlue|r"
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should preserve book content", function()
      local original = [[
A long book entry with multiple lines
Some lore text here
And more content
With special characters: é, ñ, ü
]]
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
    end)
    
    it("should handle very long strings", function()
      local original = string.rep("Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", 100)
      local encoded = BookArchivist.Base64.Encode(original)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal(original, decoded)
      assert.are.equal(#original, #decoded)
    end)
  end)
  
  describe("Known test vectors", function()
    it("should match RFC 4648 test vector 1", function()
      local encoded = BookArchivist.Base64.Encode("f")
      assert.are.equal("Zg==", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("f", decoded)
    end)
    
    it("should match RFC 4648 test vector 2", function()
      local encoded = BookArchivist.Base64.Encode("fo")
      assert.are.equal("Zm8=", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("fo", decoded)
    end)
    
    it("should match RFC 4648 test vector 3", function()
      local encoded = BookArchivist.Base64.Encode("foo")
      assert.are.equal("Zm9v", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("foo", decoded)
    end)
    
    it("should match RFC 4648 test vector 4", function()
      local encoded = BookArchivist.Base64.Encode("foob")
      assert.are.equal("Zm9vYg==", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("foob", decoded)
    end)
    
    it("should match RFC 4648 test vector 5", function()
      local encoded = BookArchivist.Base64.Encode("fooba")
      assert.are.equal("Zm9vYmE=", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("fooba", decoded)
    end)
    
    it("should match RFC 4648 test vector 6", function()
      local encoded = BookArchivist.Base64.Encode("foobar")
      assert.are.equal("Zm9vYmFy", encoded)
      local decoded, err = BookArchivist.Base64.Decode(encoded)
      assert.is_nil(err)
      assert.are.equal("foobar", decoded)
    end)
  end)
  
end)
