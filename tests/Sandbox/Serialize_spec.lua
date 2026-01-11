-- Serialize_spec.lua
-- Sandbox tests for table serialization/deserialization

-- Load test helper
local helper = dofile("Tests/test_helper.lua")
helper.setupNamespace()

-- Load Serialize module
helper.loadFile("core/BookArchivist_Serialize.lua")

describe("Serialize.SerializeTable", function()
  it("serializes empty table", function()
    local result = BookArchivist.Serialize.SerializeTable({})
    assert.are.equal("t0:;", result)
  end)

  it("rejects non-table input", function()
    local result, err = BookArchivist.Serialize.SerializeTable("not a table")
    assert.is_nil(result)
    assert.is_true(err ~= nil)
  end)

  it("serializes simple key-value pairs", function()
    local result = BookArchivist.Serialize.SerializeTable({a = "test", b = 123})
    assert.is_true(result ~= nil)
    assert.is_true(type(result) == "string")
  end)

  it("serializes nested tables", function()
    local tbl = {outer = {inner = "value"}}
    local result = BookArchivist.Serialize.SerializeTable(tbl)
    assert.is_true(result ~= nil)
  end)

  it("produces deterministic output", function()
    local tbl = {c = 3, a = 1, b = 2}
    local s1 = BookArchivist.Serialize.SerializeTable(tbl)
    local s2 = BookArchivist.Serialize.SerializeTable(tbl)
    assert.are.equal(s1, s2)
  end)

  it("handles boolean values", function()
    local result = BookArchivist.Serialize.SerializeTable({t = true, f = false})
    assert.is_true(result ~= nil)
  end)

  it("handles numeric keys", function()
    local result = BookArchivist.Serialize.SerializeTable({[1] = "first", [2] = "second"})
    assert.is_true(result ~= nil)
  end)

  it("handles floating point numbers", function()
    local result = BookArchivist.Serialize.SerializeTable({pi = 3.14159})
    assert.is_true(result ~= nil)
  end)

  it("handles empty strings", function()
    local result = BookArchivist.Serialize.SerializeTable({empty = ""})
    assert.is_true(result ~= nil)
  end)

  it("rejects function values", function()
    local result, err = BookArchivist.Serialize.SerializeTable({func = function() end})
    assert.is_nil(result)
    assert.is_true(err ~= nil)
  end)
end)

describe("Serialize.DeserializeTable", function()
  it("deserializes empty table", function()
    local result = BookArchivist.Serialize.DeserializeTable("t0:;")
    assert.is_true(type(result) == "table")
    local count = 0
    for _ in pairs(result) do count = count + 1 end
    assert.are.equal(0, count)
  end)

  it("rejects non-string input", function()
    local result, err = BookArchivist.Serialize.DeserializeTable(123)
    assert.is_nil(result)
    assert.is_true(err ~= nil)
  end)

  it("rejects empty string input", function()
    local result, err = BookArchivist.Serialize.DeserializeTable("")
    assert.is_nil(result)
    assert.is_true(err ~= nil)
  end)

  it("rejects invalid data", function()
    local result, err = BookArchivist.Serialize.DeserializeTable("garbage")
    assert.is_nil(result)
    -- err may be nil in some cases, just ensure result is nil
  end)
end)

describe("Serialize round-trip", function()
  it("preserves empty table", function()
    local original = {}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    local count = 0
    for _ in pairs(deserialized) do count = count + 1 end
    assert.are.equal(0, count)
  end)

  it("preserves simple key-value pairs", function()
    local original = {name = "Test", value = 42}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.are.equal(original.name, deserialized.name)
    assert.are.equal(original.value, deserialized.value)
  end)

  it("preserves nested tables", function()
    local original = {outer = {inner = "nested"}}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.is_true(type(deserialized.outer) == "table")
    assert.are.equal(original.outer.inner, deserialized.outer.inner)
  end)

  it("preserves boolean values", function()
    local original = {t = true, f = false}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.is_true(deserialized.t == true)
    assert.is_true(deserialized.f == false)
  end)

  it("preserves numeric keys", function()
    local original = {[1] = "first", [2] = "second"}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.are.equal(original[1], deserialized[1])
    assert.are.equal(original[2], deserialized[2])
  end)

  it("preserves floating point numbers", function()
    local original = {pi = 3.14159}
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.is_true(math.abs(original.pi - deserialized.pi) < 0.00001)
  end)

  it("preserves complex structures", function()
    local original = {
      books = {
        {title = "Book 1", pages = {[1] = "P1"}},
        {title = "Book 2", pages = {[1] = "P1"}}
      },
      count = 2
    }
    local serialized = BookArchivist.Serialize.SerializeTable(original)
    local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
    assert.are.equal(original.count, deserialized.count)
    assert.are.equal(original.books[1].title, deserialized.books[1].title)
  end)
end)
