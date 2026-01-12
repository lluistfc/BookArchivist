-- Busted Bootstrap
-- Loaded before all tests to initialize common test infrastructure
-- Configure this in .busted as: helper = "Tests/busted_bootstrap.lua"

-- Load Mechanic's WoW API stubs first (provides C_Timer, C_Map, etc.)
local mechanicPath = "G:/development/_dev_/Mechanic/sandbox/generated/wow_stubs.lua"
local f = io.open(mechanicPath, "r")
if f then
	f:close()
	dofile(mechanicPath)
	print("✓ Loaded Mechanic wow_stubs.lua (22,945 lines of WoW API stubs)")
else
	print("⚠ Mechanic wow_stubs.lua not found - using inline mocks")
end

-- Now load our addon-specific stubs/overrides
dofile("Tests/stubs/bit_library.lua")

-- Add global WoW functions not in Mechanic's stubs
-- wipe() - Clears a table and returns it
if not _G.wipe then
	_G.wipe = function(tbl)
		if type(tbl) ~= "table" then return end
		for k in pairs(tbl) do
			tbl[k] = nil
		end
		return tbl
	end
end

-- time() - Returns current Unix timestamp (use mock value for tests)
if not _G.time then
	_G.time = function()
		return 1000 -- Fixed timestamp for deterministic tests
	end
end

-- Global test utilities (if needed)
-- These can override or extend Mechanic's stubs
_G.TEST_MODE = true
