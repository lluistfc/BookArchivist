-- Export tests (BDB1 format encoding/decoding)
-- Tests the export envelope format used for sharing books

-- Load test helper for cross-platform path resolution
local helper = dofile("tests/test_helper.lua")

-- Load bit library for CRC32 operations
helper.loadFile("tests/stubs/bit_library.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load dependencies
helper.loadFile("core/BookArchivist_CRC32.lua")
helper.loadFile("core/BookArchivist_Base64.lua")
helper.loadFile("core/BookArchivist_Serialize.lua")

-- Mock Core for Export module dependency
BookArchivist.Core = BookArchivist.Core or {}

-- Load Export module
helper.loadFile("core/BookArchivist_Export.lua")

describe("Export (BDB1 Format)", function()
  
  describe("DecodeBDB1Envelope", function()
    it("should reject empty string", function()
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope("")
      
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("Payload missing") ~= nil)
    end)
    
    it("should reject nil input", function()
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(nil)
      
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("Payload missing") ~= nil)
    end)
    
    it("should decode simple BDB1 envelope", function()
      -- Create a simple payload
      local data = "t2:a:s5:hello;b:s5:world;"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s\nBDB1|E", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(1, schema)
      assert.are.equal(data, result)
    end)
    
    it("should decode multi-chunk envelope", function()
      -- Create data that will be split into chunks
      local data = string.rep("test data content ", 1000) -- ~18000 bytes
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Split into 16KB chunks
      local CHUNK_SIZE = 16384
      local totalChunks = math.ceil(#encoded / CHUNK_SIZE)
      
      local lines = { string.format("BDB1|S|%d|%u|%d|1", totalChunks, crc, #data) }
      
      for i = 1, totalChunks do
        local startIdx = (i - 1) * CHUNK_SIZE + 1
        local endIdx = math.min(i * CHUNK_SIZE, #encoded)
        local chunk = encoded:sub(startIdx, endIdx)
        lines[#lines + 1] = string.format("BDB1|C|%d|%s", i, chunk)
      end
      
      lines[#lines + 1] = "BDB1|E"
      local envelope = table.concat(lines, "\n")
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(1, schema)
      assert.are.equal(data, result)
    end)
    
    it("should handle different newline formats", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Test with \r\n (Windows)
      local envelope = string.format("BDB1|S|1|%u|%d|1\r\nBDB1|C|1|%s\r\nBDB1|E", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
    
    it("should handle mixed newline formats", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Mix \r\n and \n
      local envelope = string.format("BDB1|S|1|%u|%d|1\r\nBDB1|C|1|%s\nBDB1|E", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
    
    it("should detect CRC mismatch", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local wrongCRC = 12345 -- Wrong CRC
      
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s\nBDB1|E", wrongCRC, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("CRC mismatch") ~= nil)
    end)
    
    it("should detect size mismatch", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      local wrongSize = 999 -- Wrong size
      
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s\nBDB1|E", crc, wrongSize, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(result)
      assert.is_not_nil(err)
      assert.is_true(err:find("Size mismatch") ~= nil)
    end)
    
    it("should extract schema version", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Schema version 2
      local envelope = string.format("BDB1|S|1|%u|%d|2\nBDB1|C|1|%s\nBDB1|E", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(2, schema)
      assert.are.equal(data, result)
    end)
    
    it("should handle whitespace around payload", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      local envelope = string.format("  BDB1|S|1|%u|%d|1\n  BDB1|C|1|%s  \n  BDB1|E  ", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
    
    it("should strip invalid base64 characters", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Add some garbage characters
      local messyEncoded = encoded:sub(1, 5) .. "!!!" .. encoded:sub(6)
      
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s\nBDB1|E", crc, #data, messyEncoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
    
    it("should handle fallback decode without header", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      
      -- No header/footer, just base64
      local envelope = encoded
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
    
    it("should handle fallback decode without footer", function()
      local data = "test"
      local encoded = BookArchivist.Base64.Encode(data)
      local crc = BookArchivist.CRC32:Compute(data)
      
      -- Header but no footer
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s", crc, #data, encoded)
      
      local result, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      
      -- Should still work due to fallback logic
      assert.is_nil(err)
      assert.are.equal(data, result)
    end)
  end)
  
  describe("Round-trip (Serialize → Export → Import)", function()
    it("should preserve simple table", function()
      local original = { a = "hello", b = "world", schemaVersion = 1 }
      
      -- Serialize
      local serialized = BookArchivist.Serialize.SerializeTable(original)
      
      -- Encode to BDB1
      local encoded = BookArchivist.Base64.Encode(serialized)
      local crc = BookArchivist.CRC32:Compute(serialized)
      local envelope = string.format("BDB1|S|1|%u|%d|1\nBDB1|C|1|%s\nBDB1|E", crc, #serialized, encoded)
      
      -- Decode from BDB1
      local decoded, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      assert.is_nil(err)
      
      -- Deserialize
      local result = BookArchivist.Serialize.DeserializeTable(decoded)
      
      assert.are.equal(original.a, result.a)
      assert.are.equal(original.b, result.b)
      assert.are.equal(1, result.schemaVersion)
    end)
    
    it("should preserve nested book structure", function()
      local original = {
        schemaVersion = 2,
        books = {
          book1 = {
            title = "Test Book",
            pages = { [1] = "Page 1", [2] = "Page 2" },
            location = { zoneText = "Stormwind" }
          }
        }
      }
      
      local serialized = BookArchivist.Serialize.SerializeTable(original)
      local encoded = BookArchivist.Base64.Encode(serialized)
      local crc = BookArchivist.CRC32:Compute(serialized)
      local envelope = string.format("BDB1|S|1|%u|%d|2\nBDB1|C|1|%s\nBDB1|E", crc, #serialized, encoded)
      
      local decoded, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      assert.is_nil(err)
      assert.are.equal(2, schema)
      
      local result = BookArchivist.Serialize.DeserializeTable(decoded)
      
      assert.are.equal("Test Book", result.books.book1.title)
      assert.are.equal("Page 1", result.books.book1.pages[1])
      assert.are.equal("Stormwind", result.books.book1.location.zoneText)
    end)
    
    it("should preserve large dataset with multiple chunks", function()
      -- Create a large payload with many books
      local books = {}
      for i = 1, 100 do
        books["book" .. i] = {
          title = "Book " .. i .. " with some longer title text",
          pages = {
            [1] = string.rep("Content for page 1 of book " .. i .. ". ", 50),
            [2] = string.rep("Content for page 2 of book " .. i .. ". ", 50),
          }
        }
      end
      
      local original = { schemaVersion = 2, books = books }
      
      local serialized = BookArchivist.Serialize.SerializeTable(original)
      local encoded = BookArchivist.Base64.Encode(serialized)
      local crc = BookArchivist.CRC32:Compute(serialized)
      
      -- Split into chunks
      local CHUNK_SIZE = 16384
      local totalChunks = math.ceil(#encoded / CHUNK_SIZE)
      local lines = { string.format("BDB1|S|%d|%u|%d|2", totalChunks, crc, #serialized) }
      
      for i = 1, totalChunks do
        local startIdx = (i - 1) * CHUNK_SIZE + 1
        local endIdx = math.min(i * CHUNK_SIZE, #encoded)
        local chunk = encoded:sub(startIdx, endIdx)
        lines[#lines + 1] = string.format("BDB1|C|%d|%s", i, chunk)
      end
      
      lines[#lines + 1] = "BDB1|E"
      local envelope = table.concat(lines, "\n")
      
      local decoded, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
      assert.is_nil(err)
      assert.are.equal(2, schema)
      
      local result = BookArchivist.Serialize.DeserializeTable(decoded)
      
      assert.are.equal(2, result.schemaVersion)
      -- Count books in keyed table
      local count = 0
      for k, v in pairs(result.books) do
        count = count + 1
      end
      assert.are.equal(100, count)
      assert.are.equal("Book 1 with some longer title text", result.books.book1.title)
      assert.are.equal("Book 50 with some longer title text", result.books.book50.title)
    end)
  end)
  
end)
