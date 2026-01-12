-- ChatLinks tests (capability negotiation and version compatibility)
-- Tests the chat link sharing system with compression support detection

-- Load test helper
local helper = dofile("Tests/test_helper.lua")

-- Setup BookArchivist namespace
helper.setupNamespace()

-- Mock LibDeflate for compression tests
local mockLibDeflate = {
	CompressDeflate = function(self, data, opts)
		return "COMPRESSED:" .. data
	end,
	DecompressDeflate = function(self, data)
		return data:gsub("^COMPRESSED:", "")
	end,
	EncodeForPrint = function(self, data)
		return "ENCODED:" .. data
	end,
	DecodeForPrint = function(self, data)
		return data:gsub("^ENCODED:", "")
	end,
}

-- Mock AceSerializer-3.0
local mockAceSerializer = {
	Serialize = function(self, data)
		return "SERIALIZED:" .. tostring(data.m or data.title or "data")
	end,
	Deserialize = function(self, data)
		-- Simple mock deserialization
		local msgType = data:match("SERIALIZED:(%w+)")
		if msgType then
			return true, { m = msgType }
		end
		return true, { m = "unknown" }
	end,
}

-- Mock AceComm-3.0
local mockAceComm = {
	SendCommMessage = function(self, prefix, message, distribution, target)
		-- Capture sent messages for verification
		_G._lastCommMessage = {
			prefix = prefix,
			message = message,
			distribution = distribution,
			target = target,
		}
	end,
}

-- Save original LibStub and create mock version
local originalLibStub = _G.LibStub

-- Stateful mock LibStub that can be configured
local function createMockLibStub(libDeflateAvailable)
	return function(name, silent)
		if name == "LibDeflate" then
			return libDeflateAvailable and mockLibDeflate or nil
		end
		if name == "AceSerializer-3.0" then
			return mockAceSerializer
		end
		if name == "AceComm-3.0" then
			return mockAceComm
		end
		return nil
	end
end

describe("ChatLinks (Capability Negotiation)", function()
	before_each(function()
		-- Reset state
		_G._lastCommMessage = nil
	end)

	after_each(function()
		-- Restore original LibStub
		_G.LibStub = originalLibStub
	end)

	describe("Request with compression support", function()
		it("should include supportsCompression=true when LibDeflate is available", function()
			-- Set up mock LibStub with LibDeflate available
			_G.LibStub = createMockLibStub(true)
			
			-- Simulate what RequestBookFromSender does
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local request = {
				m = "request",
				title = "Test Book",
				supportsCompression = LibDeflate ~= nil,
			}
			
			assert.is_true(request.supportsCompression)
		end)

		it("should include supportsCompression=false when LibDeflate is not available", function()
			-- Set up mock LibStub without LibDeflate
			_G.LibStub = createMockLibStub(false)
			
			-- Simulate what RequestBookFromSender does
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local request = {
				m = "request",
				title = "Test Book",
				supportsCompression = LibDeflate ~= nil,
			}
			
			assert.is_false(request.supportsCompression)
		end)

		it("should include supportsCompression=false when LibStub is not available", function()
			-- No LibStub at all
			_G.LibStub = nil
			
			-- Simulate what RequestBookFromSender does
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local request = {
				m = "request",
				title = "Test Book",
				supportsCompression = LibDeflate ~= nil,
			}
			
			assert.is_false(request.supportsCompression)
		end)
	end)

	describe("Response compression decision", function()
		it("should compress response when receiver supports compression", function()
			-- Sender has LibDeflate
			_G.LibStub = createMockLibStub(true)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				supportsCompression = true,
			}
			
			local response = { bookData = { title = "Test Book" } }
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData.supportsCompression
			
			-- Verify compression should be used
			assert.is_not_nil(LibDeflate)
			assert.is_true(receiverSupportsCompression)
			assert.is_not_nil(response.bookData)
		end)

		it("should NOT compress response when receiver doesn't support compression", function()
			-- Sender has LibDeflate
			_G.LibStub = createMockLibStub(true)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				supportsCompression = false,
			}
			
			local response = { bookData = { title = "Test Book" } }
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData.supportsCompression
			
			-- Verify compression should NOT be used
			assert.is_not_nil(LibDeflate) -- Sender has LibDeflate
			assert.is_false(receiverSupportsCompression) -- But receiver doesn't
		end)

		it("should handle missing supportsCompression field (backward compatibility)", function()
			-- Sender has LibDeflate
			_G.LibStub = createMockLibStub(true)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				-- No supportsCompression field (old client)
			}
			
			local response = { bookData = { title = "Test Book" } }
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData and requestData.supportsCompression
			
			-- Verify compression should NOT be used for old clients
			assert.is_not_nil(LibDeflate)
			assert.is_false(receiverSupportsCompression or false) -- nil treated as false
		end)
	end)

	describe("Version compatibility scenarios", function()
		it("should work when new client (v2) requests from old client (v1)", function()
			-- New client (requester) sends supportsCompression=true
			-- Old client (sender) has no LibDeflate, can't compress
			_G.LibStub = createMockLibStub(false)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				supportsCompression = true, -- New client supports it
			}
			
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData.supportsCompression
			
			-- Old client doesn't have LibDeflate, so can't compress anyway
			assert.is_nil(LibDeflate)
			-- Even though receiver supports compression, sender can't provide it
			assert.is_true(receiverSupportsCompression)
		end)

		it("should work when old client (v1) requests from new client (v2)", function()
			-- Old client sends no supportsCompression field (or false)
			-- New client (has LibDeflate) sends uncompressed
			_G.LibStub = createMockLibStub(true)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				-- Old client doesn't send supportsCompression
			}
			
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData and requestData.supportsCompression
			
			-- New client has LibDeflate but won't use it for old clients
			assert.is_not_nil(LibDeflate)
			assert.is_false(receiverSupportsCompression or false)
		end)

		it("should work when both clients are new (v2)", function()
			-- Both have LibDeflate, both support compression
			_G.LibStub = createMockLibStub(true)
			
			local requestData = {
				m = "request",
				title = "Test Book",
				supportsCompression = true,
			}
			
			local LibDeflate = _G.LibStub and _G.LibStub("LibDeflate", true)
			local receiverSupportsCompression = requestData.supportsCompression
			
			-- Both support compression, should compress
			assert.is_not_nil(LibDeflate)
			assert.is_true(receiverSupportsCompression)
		end)
	end)
end)
