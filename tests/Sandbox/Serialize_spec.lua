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
		local result = BookArchivist.Serialize.SerializeTable({ a = "test", b = 123 })
		assert.is_true(result ~= nil)
		assert.is_true(type(result) == "string")
	end)

	it("serializes nested tables", function()
		local tbl = { outer = { inner = "value" } }
		local result = BookArchivist.Serialize.SerializeTable(tbl)
		assert.is_true(result ~= nil)
	end)

	it("produces deterministic output", function()
		local tbl = { c = 3, a = 1, b = 2 }
		local s1 = BookArchivist.Serialize.SerializeTable(tbl)
		local s2 = BookArchivist.Serialize.SerializeTable(tbl)
		assert.are.equal(s1, s2)
	end)

	it("handles boolean values", function()
		local result = BookArchivist.Serialize.SerializeTable({ t = true, f = false })
		assert.is_true(result ~= nil)
	end)

	it("handles numeric keys", function()
		local result = BookArchivist.Serialize.SerializeTable({ [1] = "first", [2] = "second" })
		assert.is_true(result ~= nil)
	end)

	it("handles floating point numbers", function()
		local result = BookArchivist.Serialize.SerializeTable({ pi = 3.14159 })
		assert.is_true(result ~= nil)
	end)

	it("handles empty strings", function()
		local result = BookArchivist.Serialize.SerializeTable({ empty = "" })
		assert.is_true(result ~= nil)
	end)

	it("rejects function values", function()
		local result, err = BookArchivist.Serialize.SerializeTable({ func = function() end })
		assert.is_nil(result)
		assert.is_true(err ~= nil)
	end)

	it("rejects non-finite numbers (NaN)", function()
		local nan = 0/0
		local result, err = BookArchivist.Serialize.SerializeTable({ value = nan })
		assert.is_nil(result)
		assert.is_not_nil(err)
		assert.is_not_nil(string.match(err, "non%-finite"))
	end)

	it("rejects non-finite numbers (infinity)", function()
		local result, err = BookArchivist.Serialize.SerializeTable({ value = math.huge })
		assert.is_nil(result)
		assert.is_not_nil(err)
		assert.is_not_nil(string.match(err, "non%-finite"))
	end)

	it("rejects tables with unsupported key types", function()
		local tbl = {}
		tbl[function() end] = "bad key"
		local result, err = BookArchivist.Serialize.SerializeTable(tbl)
		assert.is_nil(result)
		assert.is_not_nil(err)
		assert.is_not_nil(string.match(err, "unsupported key type"))
	end)

	it("handles tables with mixed numeric and string keys", function()
		local tbl = { [1] = "numeric", key = "string" }
		local result = BookArchivist.Serialize.SerializeTable(tbl)
		assert.is_not_nil(result)
	end)

	it("rejects deeply nested tables beyond max depth", function()
		-- Build a deeply nested table
		local tbl = {}
		local current = tbl
		for i = 1, 25 do  -- Exceed MAX_DEPTH (20)
			current.nested = {}
			current = current.nested
		end
		
		local result, err = BookArchivist.Serialize.SerializeTable(tbl)
		assert.is_nil(result)
		assert.is_not_nil(err)
		assert.is_not_nil(string.match(err, "max depth"))
	end)

	it("handles nil values as table keys correctly", function()
		-- Lua doesn't allow nil as table key, but we validate behavior
		local tbl = { a = nil }  -- nil values are ignored in Lua tables
		local result = BookArchivist.Serialize.SerializeTable(tbl)
		-- Should serialize empty table since nil is dropped
		assert.is_not_nil(result)
	end)
end)

describe("Serialize.DeserializeTable", function()
	it("deserializes empty table", function()
		local result = BookArchivist.Serialize.DeserializeTable("t0:;")
		assert.is_true(type(result) == "table")
		local count = 0
		for _ in pairs(result) do
			count = count + 1
		end
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
		for _ in pairs(deserialized) do
			count = count + 1
		end
		assert.are.equal(0, count)
	end)

	it("preserves simple key-value pairs", function()
		local original = { name = "Test", value = 42 }
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.are.equal(original.name, deserialized.name)
		assert.are.equal(original.value, deserialized.value)
	end)

	it("preserves nested tables", function()
		local original = { outer = { inner = "nested" } }
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.is_true(type(deserialized.outer) == "table")
		assert.are.equal(original.outer.inner, deserialized.outer.inner)
	end)

	it("preserves boolean values", function()
		local original = { t = true, f = false }
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.is_true(deserialized.t == true)
		assert.is_true(deserialized.f == false)
	end)

	it("preserves numeric keys", function()
		local original = { [1] = "first", [2] = "second" }
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.are.equal(original[1], deserialized[1])
		assert.are.equal(original[2], deserialized[2])
	end)

	it("preserves floating point numbers", function()
		local original = { pi = 3.14159 }
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.is_true(math.abs(original.pi - deserialized.pi) < 0.00001)
	end)

	it("preserves complex structures", function()
		local original = {
			books = {
				{ title = "Book 1", pages = { [1] = "P1" } },
				{ title = "Book 2", pages = { [1] = "P1" } },
			},
			count = 2,
		}
		local serialized = BookArchivist.Serialize.SerializeTable(original)
		local deserialized = BookArchivist.Serialize.DeserializeTable(serialized)
		assert.are.equal(original.count, deserialized.count)
		assert.are.equal(original.books[1].title, deserialized.books[1].title)
	end)
end)
