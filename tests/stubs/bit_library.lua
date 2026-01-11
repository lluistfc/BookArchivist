-- BookArchivist-specific test stubs
-- Load this AFTER Mechanic's wow_stubs.lua to add/override stubs

-- Pure-Lua bit library for testing environments without LuaJIT
-- Required for CRC32 and other bitwise operations

if not bit then
	bit = {}

	-- Bitwise AND
	function bit.band(a, b)
		local result = 0
		local bitval = 1
		while a > 0 and b > 0 do
			if a % 2 == 1 and b % 2 == 1 then
				result = result + bitval
			end
			bitval = bitval * 2
			a = math.floor(a / 2)
			b = math.floor(b / 2)
		end
		return result
	end

	-- Bitwise OR
	function bit.bor(a, b)
		local result = 0
		local bitval = 1
		while a > 0 or b > 0 do
			if a % 2 == 1 or b % 2 == 1 then
				result = result + bitval
			end
			bitval = bitval * 2
			a = math.floor(a / 2)
			b = math.floor(b / 2)
		end
		return result
	end

	-- Bitwise XOR
	function bit.bxor(a, b)
		local result = 0
		local bitval = 1
		while a > 0 or b > 0 do
			if (a % 2 == 1) ~= (b % 2 == 1) then
				result = result + bitval
			end
			bitval = bitval * 2
			a = math.floor(a / 2)
			b = math.floor(b / 2)
		end
		return result
	end

	-- Left shift
	function bit.lshift(a, n)
		return a * (2 ^ n)
	end

	-- Right shift
	function bit.rshift(a, n)
		return math.floor(a / (2 ^ n))
	end
end
