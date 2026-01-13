-- Export tests (BDB1 format encoding/decoding)
-- Tests the export envelope format used for sharing books

-- Load test helper for cross-platform path resolution
local helper = dofile("Tests/test_helper.lua")

-- Load bit library for CRC32 operations
helper.loadFile("tests/stubs/bit_library.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Load dependencies
helper.loadFile("core/BookArchivist_CRC32.lua")
helper.loadFile("core/BookArchivist_Base64.lua")
helper.loadFile("core/BookArchivist_Serialize.lua")
helper.loadFile("core/BookArchivist_Repository.lua")

-- Mock Core for Export module dependency
BookArchivist.Core = BookArchivist.Core or {}

-- Load Core module (contains BuildExportPayloadForBook)
helper.loadFile("core/BookArchivist_Core.lua")

-- Load Export module
helper.loadFile("core/BookArchivist_Export.lua")

describe("Export (BDB1 Format)", function()
	describe("BuildExportPayloadForBook", function()
		local testDB
		
		before_each(function()
			-- Mock global functions
			_G.time = function() return 1000000 end
			_G.UnitName = function() return "TestPlayer" end
			_G.GetRealmName = function() return "TestRealm" end
			_G.C_Timer = _G.C_Timer or {}
			_G.C_Timer.After = function(delay, callback) 
				if callback then callback() end 
			end
			
			-- Create test database with v3 schema
			testDB = {
				dbVersion = 3,
				booksById = {},
				order = {},
				indexes = {
					objectToBookId = {},
					itemToBookIds = {},
					titleToBookIds = {},
				},
				options = {},
			}
			
			-- Mock BookArchivistDB global
			_G.BookArchivistDB = testDB
			
			-- Initialize Repository with test DB
			BookArchivist.Repository:Init(testDB)
		end)
		
		after_each(function()
			-- Restore
			_G.BookArchivistDB = nil
			BookArchivist.Repository:Init(_G.BookArchivistDB or {})
		end)
		
		it("should strip echo metadata when exporting a book", function()
			-- Create a book with echo metadata
			testDB.booksById["test-book-1"] = {
				id = "test-book-1",
				title = "Test Book",
				material = "Parchment",
				creator = "Test Author",
				pages = {
					[1] = "Page 1 content",
					[2] = "Page 2 content",
				},
				location = { zoneText = "Stormwind" },
				createdAt = 900000,
				-- Echo metadata that should be stripped:
				readCount = 5,
				firstReadLocation = "Ironforge",
				lastPageRead = 2,
				lastReadAt = 999000,
			}
			testDB.order = { "test-book-1" }
			
			-- Export the book
			local payload, err = BookArchivist.Core:BuildExportPayloadForBook("test-book-1")
			
			assert.is_nil(err)
			assert.is_not_nil(payload)
			assert.is_not_nil(payload.booksById)
			assert.is_not_nil(payload.booksById["test-book-1"])
			
			local exportedBook = payload.booksById["test-book-1"]
			
			-- Verify content fields are present
			assert.are.equal("Test Book", exportedBook.title)
			assert.are.equal("Parchment", exportedBook.material)
			assert.are.equal("Test Author", exportedBook.creator)
			assert.are.equal(2, #exportedBook.pages)
			assert.are.equal("Stormwind", exportedBook.location.zoneText)
			assert.are.equal(900000, exportedBook.createdAt)
			
			-- Verify echo metadata is NOT present
			assert.is_nil(exportedBook.readCount, "readCount should be stripped")
			assert.is_nil(exportedBook.firstReadLocation, "firstReadLocation should be stripped")
			assert.is_nil(exportedBook.lastPageRead, "lastPageRead should be stripped")
			assert.is_nil(exportedBook.lastReadAt, "lastReadAt should be stripped")
		end)
		
		it("should export book without echo metadata if none exists", function()
			-- Create a book without echo metadata
			testDB.booksById["new-book"] = {
				id = "new-book",
				title = "New Book",
				pages = { [1] = "Content" },
			}
			testDB.order = { "new-book" }
			
			local payload, err = BookArchivist.Core:BuildExportPayloadForBook("new-book")
			
			assert.is_nil(err)
			assert.is_not_nil(payload)
			
			local exportedBook = payload.booksById["new-book"]
			assert.are.equal("New Book", exportedBook.title)
			assert.is_nil(exportedBook.readCount)
			assert.is_nil(exportedBook.firstReadLocation)
		end)
		
		it("should preserve all non-echo fields", function()
			-- Create a book with many fields
			testDB.booksById["full-book"] = {
				id = "full-book",
				title = "Complete Book",
				material = "Leather",
				creator = "Famous Author",
				pages = { [1] = "Page 1", [2] = "Page 2", [3] = "Page 3" },
				location = { 
					zoneText = "Dalaran",
					subZoneText = "Violet Citadel",
				},
				createdAt = 800000,
				lastSeenAt = 850000,
				-- Echo metadata (should be stripped)
				readCount = 10,
				firstReadLocation = "Stormwind",
				lastPageRead = 3,
				lastReadAt = 900000,
			}
			testDB.order = { "full-book" }
			
			local payload, err = BookArchivist.Core:BuildExportPayloadForBook("full-book")
			
			assert.is_nil(err)
			local exportedBook = payload.booksById["full-book"]
			
			-- All content preserved
			assert.are.equal("Complete Book", exportedBook.title)
			assert.are.equal("Leather", exportedBook.material)
			assert.are.equal("Famous Author", exportedBook.creator)
			assert.are.equal(3, #exportedBook.pages)
			assert.are.equal("Dalaran", exportedBook.location.zoneText)
			assert.are.equal("Violet Citadel", exportedBook.location.subZoneText)
			assert.are.equal(800000, exportedBook.createdAt)
			assert.are.equal(850000, exportedBook.lastSeenAt)
			
			-- Echo metadata stripped
			assert.is_nil(exportedBook.readCount)
			assert.is_nil(exportedBook.firstReadLocation)
			assert.is_nil(exportedBook.lastPageRead)
			assert.is_nil(exportedBook.lastReadAt)
		end)
		
		it("should return error for missing book", function()
			local payload, err = BookArchivist.Core:BuildExportPayloadForBook("nonexistent")
			
			assert.is_nil(payload)
			assert.is_not_nil(err)
			assert.is_truthy(err:find("not found"))
		end)
		
		it("should return error for invalid book ID", function()
			local payload, err = BookArchivist.Core:BuildExportPayloadForBook(nil)
			
			assert.is_nil(payload)
			assert.is_not_nil(err)
			assert.is_truthy(err:find("invalid"))
		end)
	end)
	
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
						location = { zoneText = "Stormwind" },
					},
				},
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
					},
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

	describe("Compression (v2 with LibDeflate)", function()
		-- Try to load LibDeflate if available
		local LibDeflate
		local hasLibDeflate = pcall(function()
			-- Load from local libs folder
			LibDeflate = dofile("libs/LibDeflate/LibDeflate.lua")
		end)

		if hasLibDeflate and LibDeflate then
			-- Make LibDeflate available via LibStub for decoder
			_G.LibStub = _G.LibStub or function(name, silent)
				if name == "LibDeflate" then
					return LibDeflate
				end
				return nil
			end

			it("should detect LibDeflate availability", function()
				assert.is_not_nil(LibDeflate)
				assert.is_function(LibDeflate.CompressDeflate)
				assert.is_function(LibDeflate.DecompressDeflate)
				assert.is_function(LibDeflate.EncodeForPrint)
				assert.is_function(LibDeflate.DecodeForPrint)
			end)

			it("should compress data with v2 schema", function()
				-- Create test data
				local testData = string.rep("This is repeated test data. ", 100)
				
				-- Compress
				local compressed = LibDeflate:CompressDeflate(testData, {level = 9})
				
				assert.is_not_nil(compressed)
				assert.is_true(#compressed < #testData, 
					string.format("Compressed size (%d) should be less than original (%d)", #compressed, #testData))
				
				-- Verify compression ratio
				local ratio = (1 - (#compressed / #testData)) * 100
				assert.is_true(ratio > 50, 
					string.format("Compression ratio should be > 50%%, got %.1f%%", ratio))
			end)

			it("should achieve 75%+ compression on book data", function()
				-- Create realistic book data
				local bookPages = {}
				for i = 1, 6 do
					bookPages[i] = string.format([[
						<HTML><BODY>
						<H1>Chapter %d</H1>
						<P>This is the content of chapter %d. It contains repeated phrases and common words that should compress well. The quick brown fox jumps over the lazy dog. Lorem ipsum dolor sit amet, consectetur adipiscing elit.</P>
						<P>More content here with similar patterns. The library contains many books with similar formatting and repeated vocabulary.</P>
						</BODY></HTML>
					]], i, i)
				end
				
				local book = {
					title = "Test Book with Long Title",
					material = "Parchment",
					pages = bookPages,
					createdAt = 1234567890,
				}
				
				local payload = {
					schemaVersion = 2,
					booksById = { ["test-book-id"] = book },
					exportedAt = 1234567890,
				}
				
				-- Serialize
				local serialized = BookArchivist.Serialize.SerializeTable(payload)
				local originalSize = #serialized
				
				-- Compress
				local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
				local compressedSize = #compressed
				
				-- Calculate reduction
				local reduction = (1 - (compressedSize / originalSize)) * 100
				
				assert.is_true(reduction >= 75, 
					string.format("Expected 75%% reduction, got %.1f%% (original: %d, compressed: %d)", 
						reduction, originalSize, compressedSize))
			end)

			it("should round-trip compress and decompress", function()
				local original = "Test data for compression"
				
				local compressed = LibDeflate:CompressDeflate(original, {level = 9})
				local decompressed = LibDeflate:DecompressDeflate(compressed)
				
				assert.are.equal(original, decompressed)
			end)

			it("should encode compressed data for safe transmission", function()
				local original = "Test data"
				
				local compressed = LibDeflate:CompressDeflate(original, {level = 9})
				local encoded = LibDeflate:EncodeForPrint(compressed)
				
				-- Encoded should be base64-like (printable characters)
				assert.is_string(encoded)
				assert.is_true(#encoded > 0)
				
				-- Should decode back
				local decoded = LibDeflate:DecodeForPrint(encoded)
				local decompressed = LibDeflate:DecompressDeflate(decoded)
				
				assert.are.equal(original, decompressed)
			end)

			it("should round-trip full v2 BDB1 envelope with compression", function()
				-- Create realistic book payload
				local originalPayload = {
					schemaVersion = 2,
					booksById = {
						["test-book-1"] = {
							title = "Test Book",
							material = "Parchment",
							pages = {
								[1] = "<HTML><BODY><H1>Chapter 1</H1><P>This is test content that should compress well.</P></BODY></HTML>",
								[2] = "<HTML><BODY><H1>Chapter 2</H1><P>More content with repeated patterns and words.</P></BODY></HTML>",
							},
							location = {
								zoneText = "Stormwind",
								subZoneText = "Trade District",
							},
							createdAt = 1234567890,
						},
					},
					exportedAt = 1234567890,
				}
				
				-- Serialize
				local serialized = BookArchivist.Serialize.SerializeTable(originalPayload)
				
				-- Compress with LibDeflate
				local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
				local encoded = LibDeflate:EncodeForPrint(compressed)
				
				-- Verify compression actually reduced size
				assert.is_true(#encoded < #BookArchivist.Base64.Encode(serialized),
					"Compressed+encoded size should be less than uncompressed base64")
				
				-- Build BDB1 envelope with v2 header
				-- NOTE: CRC is computed on compressed data, rawSize is uncompressed size
				local crc = BookArchivist.CRC32:Compute(compressed)
				local envelope = string.format("BDB1|S|2|%u|%d|2\nBDB1|C|1|%s\nBDB1|E", crc, #serialized, encoded)
				
				-- Decode the envelope (this should decompress)
				local decoded, schema, err = BookArchivist.Core._DecodeBDB1Envelope(envelope)
				assert.is_nil(err)
				assert.are.equal(2, schema)
				
				-- Deserialize and verify data integrity
				local result = BookArchivist.Serialize.DeserializeTable(decoded)
				
				assert.are.equal(2, result.schemaVersion)
				assert.is_not_nil(result.booksById["test-book-1"])
				assert.are.equal("Test Book", result.booksById["test-book-1"].title)
				assert.are.equal("Parchment", result.booksById["test-book-1"].material)
				assert.are.equal(2, #result.booksById["test-book-1"].pages)
				assert.are.equal("Stormwind", result.booksById["test-book-1"].location.zoneText)
				assert.are.equal(1234567890, result.booksById["test-book-1"].createdAt)
			end)
		else
			it("should skip compression tests when LibDeflate not available", function()
				-- This test always passes, just documents that LibDeflate is missing
				assert.is_true(true, "LibDeflate not available in test environment - compression tests skipped")
			end)
		end
	end)

	describe("Export envelope encoding", function()
		local originalBuildExport
		local originalBuildBookExport
		local originalSerialize
		local originalBase64Encode
		local originalCRCCompute
		local originalLibStub

		local function reloadExport(libDeflateStub)
			if libDeflateStub then
				_G.LibStub = function(name)
					if name == "LibDeflate" then
						return libDeflateStub
					end
					return nil
				end
			else
				_G.LibStub = nil
			end
			helper.loadFile("core/BookArchivist_Export.lua")
		end

		before_each(function()
			originalBuildExport = BookArchivist.Core.BuildExportPayload
			originalBuildBookExport = BookArchivist.Core.BuildExportPayloadForBook
			originalSerialize = BookArchivist.Serialize.SerializeTable
			originalBase64Encode = BookArchivist.Base64.Encode
			originalCRCCompute = BookArchivist.CRC32.Compute
			originalLibStub = _G.LibStub
			reloadExport(nil)
		end)

		after_each(function()
			BookArchivist.Core.BuildExportPayload = originalBuildExport
			BookArchivist.Core.BuildExportPayloadForBook = originalBuildBookExport
			BookArchivist.Serialize.SerializeTable = originalSerialize
			BookArchivist.Base64.Encode = originalBase64Encode
			BookArchivist.CRC32.Compute = originalCRCCompute
			_G.LibStub = originalLibStub
			helper.loadFile("core/BookArchivist_Export.lua")
		end)

		it("returns error when export helper missing", function()
			BookArchivist.Core.BuildExportPayload = nil

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.is_true(err:find("unavailable") ~= nil)
		end)

		it("returns error when payload is missing", function()
			BookArchivist.Core.BuildExportPayload = function()
				return nil
			end

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.is_true(err:find("payload") ~= nil)
		end)

		it("returns error when serializer is unavailable", function()
			BookArchivist.Serialize.SerializeTable = nil
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 1 }
			end

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.is_true(err:find("serializer") ~= nil)
		end)

		it("returns serializer failure messages", function()
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 1 }
			end
			BookArchivist.Serialize.SerializeTable = function()
				return nil, "serial fail"
			end

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.are.equal("serial fail", err)
		end)

		it("returns error when base64 encoder is unavailable", function()
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 1 }
			end
			BookArchivist.Serialize.SerializeTable = function()
				return "SER_DATA"
			end
			BookArchivist.Base64.Encode = nil

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.is_true(err:find("base64") ~= nil)
		end)

		it("builds a BDB1 envelope via base64 path", function()
			local lastEncoded
			local lastCRCInput
			local capturedPayload
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 1, booksById = { book = true } }
			end
			BookArchivist.Serialize.SerializeTable = function(payload)
				capturedPayload = payload
				return "SER_DATA"
			end
			BookArchivist.Base64.Encode = function(data)
				lastEncoded = data
				return originalBase64Encode(data)
			end
			BookArchivist.CRC32.Compute = function(_, data)
				lastCRCInput = data
				return 4242
			end

			local envelope, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.are.equal("SER_DATA", lastEncoded)
			assert.are.equal("SER_DATA", lastCRCInput)
			assert.are.same({ schemaVersion = 1, booksById = { book = true } }, capturedPayload)
			assert.is_true(envelope:find("BDB1|S|1|4242|8|1") ~= nil)
			assert.is_true(envelope:find("BDB1|C|1|") ~= nil)

			local serialized, schema = BookArchivist.Core._DecodeBDB1Envelope(envelope)
			assert.are.equal("SER_DATA", serialized)
			assert.are.equal(1, schema)
		end)

		it("falls back to zero CRC when CRC32.Compute is missing", function()
			BookArchivist.CRC32.Compute = nil
			BookArchivist.Serialize.SerializeTable = function()
				return "XYZ"
			end
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 1 }
			end

			local envelope, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.is_true(envelope:find("BDB1|S|1|0|3|1") ~= nil)
		end)

		it("uses LibDeflate when schema version is 2", function()
			local compressionLog = {}
			local libStub = {
				CompressDeflate = function(_, data)
					table.insert(compressionLog, { op = "compress", data = data })
					return "COMP:" .. data
				end,
				EncodeForPrint = function(_, data)
					table.insert(compressionLog, { op = "encode", data = data })
					return "PRINT:" .. data
				end,
			}
			reloadExport(libStub)
			BookArchivist.Base64.Encode = function()
				assert.is_true(false, "Base64 path should not be used when compression succeeds")
			end
			BookArchivist.Serialize.SerializeTable = function()
				return "SER_V2"
			end
			local crcInput
			BookArchivist.CRC32.Compute = function(_, data)
				crcInput = data
				return 9001
			end
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 2, booksById = {} }
			end

			local envelope, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.are.equal("COMP:SER_V2", crcInput)
			assert.is_true(envelope:find("BDB1|S|1|9001|6|2") ~= nil)
			assert.is_true(envelope:find("BDB1|C|1|PRINT:COMP:SER_V2") ~= nil)
			assert.are.equal(2, #compressionLog)
		end)

		it("propagates compression failures", function()
			local libStub = {
				CompressDeflate = function()
					return nil
				end,
				EncodeForPrint = function()
					return "unused"
				end,
			}
			reloadExport(libStub)
			BookArchivist.Serialize.SerializeTable = function()
				return "SER_FAIL"
			end
			BookArchivist.Core.BuildExportPayload = function()
				return { schemaVersion = 2 }
			end

			local text, err = BookArchivist.Core:ExportToString()

			assert.is_nil(text)
			assert.is_true(err:find("compression failed") ~= nil)
		end)

		it("returns error when book export helper is missing", function()
			BookArchivist.Core.BuildExportPayloadForBook = nil

			local text, err = BookArchivist.Core:ExportBookToString("book-id")

			assert.is_nil(text)
			assert.is_true(err:find("unavailable") ~= nil)
		end)

		it("propagates book export errors", function()
			BookArchivist.Core.BuildExportPayloadForBook = function(_, bookId)
				assert.are.equal("missing", bookId)
				return nil, "unknown book"
			end

			local text, err = BookArchivist.Core:ExportBookToString("missing")

			assert.is_nil(text)
			assert.are.equal("unknown book", err)
		end)

		it("exports a single book via helper", function()
			BookArchivist.Core.BuildExportPayloadForBook = function(_, bookId)
				assert.are.equal("book-1", bookId)
				return { schemaVersion = 1, booksById = { [bookId] = true } }, nil
			end
			BookArchivist.Serialize.SerializeTable = function()
				return "ONE"
			end

			local envelope, err = BookArchivist.Core:ExportBookToString("book-1")

			assert.is_nil(err)
			assert.is_true(envelope:find("BDB1|S|1|") ~= nil)
		end)
	end)

	describe("EncodeBDB1Envelope (full encoding)", function()
		it("encodes a minimal payload with schema v1", function()
			local payload = {
				schemaVersion = 1,
				booksById = {
					["test-book"] = {
						title = "Test",
						pages = { [1] = "Content" },
					},
				},
			}

			-- Use ExportToString which calls EncodeBDB1Envelope internally
			BookArchivist.Core.BuildExportPayload = function()
				return payload
			end

			local encoded, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.is_not_nil(encoded)
			assert.is_true(encoded:find("BDB1|S|") ~= nil, "Should have BDB1 header")
			assert.is_true(encoded:find("BDB1|E") ~= nil, "Should have BDB1 footer")
			assert.is_true(encoded:find("BDB1|C|1|") ~= nil, "Should have at least one chunk")
		end)

		it("encodes payload with compression (v2)", function()
			-- Mock LibDeflate for compression test
			local mockLibDeflate = {
				CompressDeflate = function(data, opts)
					assert.are.equal(9, opts.level)
					return "COMPRESSED:" .. data
				end,
				EncodeForPrint = function(data)
					return BookArchivist.Base64.Encode(data)
				end,
			}

			_G.LibStub = function(name, silent)
				if name == "LibDeflate" then
					return mockLibDeflate
				end
			end

			local payload = {
				schemaVersion = 2,
				booksById = {
					["test-book"] = {
						title = "Test",
						pages = { [1] = "Content" },
					},
				},
			}

			BookArchivist.Core.BuildExportPayload = function()
				return payload
			end

			local encoded, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.is_not_nil(encoded)
			assert.is_true(encoded:find("BDB1|S|") ~= nil)
			assert.is_true(encoded:find("BDB1|E") ~= nil)

			-- Cleanup
			_G.LibStub = nil
		end)

		it("handles missing payload gracefully", function()
			-- This tests the nil payload guard in EncodeBDB1Envelope
			BookArchivist.Core.BuildExportPayload = function()
				return nil  -- No payload
			end

			local encoded, err = BookArchivist.Core:ExportToString()

			-- EncodeBDB1Envelope should return error for nil payload
			assert.is_nil(encoded)
			assert.is_not_nil(err)
		end)

		it("handles serialization failure", function()
			-- Mock serializer to fail
			local origSerialize = BookArchivist.Serialize.SerializeTable
			BookArchivist.Serialize.SerializeTable = function()
				return nil, "serialization error"
			end

			local payload = {
				schemaVersion = 1,
				booksById = { ["test"] = {} },
			}

			BookArchivist.Core.BuildExportPayload = function()
				return payload
			end

			local encoded, err = BookArchivist.Core:ExportToString()

			assert.is_nil(encoded)
			assert.is_not_nil(err)
			assert.is_true(err:find("serialization") ~= nil)

			-- Restore
			BookArchivist.Serialize.SerializeTable = origSerialize
		end)

		it("handles missing CRC32 module gracefully", function()
			-- Temporarily remove CRC32
			local origCRC32 = BookArchivist.CRC32
			BookArchivist.CRC32 = nil

			local payload = {
				schemaVersion = 1,
				booksById = { ["test"] = { title = "Test" } },
			}

			BookArchivist.Core.BuildExportPayload = function()
				return payload
			end

			-- Should use CRC=0 fallback
			local encoded, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.is_not_nil(encoded)
			-- Should still create valid envelope (CRC may be computed differently, just verify it's valid)
			assert.is_true(encoded:find("BDB1|S|") ~= nil, "Should have valid BDB1 header")
			assert.is_true(encoded:find("BDB1|E") ~= nil, "Should have valid BDB1 footer")

			-- Restore
			BookArchivist.CRC32 = origCRC32
		end)

		it("chunks large payloads correctly", function()
			-- Create a large payload to force chunking
			local largePages = {}
			for i = 1, 100 do
				largePages[i] = string.rep("This is a long line of text. ", 50)
			end

			local payload = {
				schemaVersion = 1,
				booksById = {
					["large-book"] = {
						title = "Large Book",
						pages = largePages,
					},
				},
			}

			BookArchivist.Core.BuildExportPayload = function()
				return payload
			end

			local encoded, err = BookArchivist.Core:ExportToString()

			assert.is_nil(err)
			assert.is_not_nil(encoded)

			-- Count chunks (BDB1|C|X| markers)
			local chunkCount = 0
			for _ in encoded:gmatch("BDB1|C|%d+|") do
				chunkCount = chunkCount + 1
			end

			-- Large payload should create multiple chunks
			assert.is_true(chunkCount > 1, "Should have multiple chunks for large payload")

			-- Verify header indicates correct chunk count
			local headerChunks = encoded:match("BDB1|S|(%d+)|")
			assert.are.equal(tostring(chunkCount), headerChunks, "Header should match actual chunk count")
		end)
	end)
end)
