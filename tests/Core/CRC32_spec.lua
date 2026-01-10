-- CRC32_spec.lua
-- Sandbox tests for CRC32 checksum computation

describe("CRC32.Compute", function()
  it("computes CRC32 for empty string", function()
    local result = BookArchivist.CRC32:Compute("")
    assert.are.equal(0, result)
  end)

  it("returns 0 for nil input", function()
    local result = BookArchivist.CRC32:Compute(nil)
    assert.are.equal(0, result)
  end)

  it("returns 0 for non-string input", function()
    assert.are.equal(0, BookArchivist.CRC32:Compute(123))
    assert.are.equal(0, BookArchivist.CRC32:Compute({}))
    assert.are.equal(0, BookArchivist.CRC32:Compute(true))
  end)

  it("produces consistent checksums for same input", function()
    local data = "The quick brown fox jumps over the lazy dog"
    local crc1 = BookArchivist.CRC32:Compute(data)
    local crc2 = BookArchivist.CRC32:Compute(data)
    assert.are.equal(crc1, crc2)
  end)

  it("produces different checksums for different inputs", function()
    local crc1 = BookArchivist.CRC32:Compute("Hello World")
    local crc2 = BookArchivist.CRC32:Compute("Hello world")
    assert.is_true(crc1 ~= crc2)
  end)

  it("computes correct CRC32 for known test vector", function()
    -- "123456789" should produce CRC32 = 0xCBF43926
    local result = BookArchivist.CRC32:Compute("123456789")
    assert.are.equal(0xCBF43926, result)
  end)

  it("handles binary data with null bytes", function()
    local data = "test\0data"
    local crc1 = BookArchivist.CRC32:Compute(data)
    local crc2 = BookArchivist.CRC32:Compute(data)
    assert.are.equal(crc1, crc2)
  end)

  it("handles long strings", function()
    local longString = string.rep("A", 10000)
    local crc = BookArchivist.CRC32:Compute(longString)
    assert.is_true(crc > 0)
    assert.is_true(crc <= 0xFFFFFFFF) -- Must fit in unsigned 32-bit
  end)

  it("handles UTF-8 multibyte characters", function()
    local utf8 = "Thïs ïs ütf-8 tëxt 你好"
    local crc1 = BookArchivist.CRC32:Compute(utf8)
    local crc2 = BookArchivist.CRC32:Compute(utf8)
    assert.are.equal(crc1, crc2)
  end)

  it("produces different checksums for single byte changes", function()
    local crc1 = BookArchivist.CRC32:Compute("test data")
    local crc2 = BookArchivist.CRC32:Compute("test dasa") -- 't' -> 's'
    assert.is_true(crc1 ~= crc2)
  end)
end)
