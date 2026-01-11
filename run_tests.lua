-- Test runner for BookArchivist tests
-- Usage: lua run_tests.lua [test_file]

-- Load test framework from Mechanic (relative path)
local mechanicPath = os.getenv("MECHANIC_PATH") or "../Mechanic"
local frameworkPath = mechanicPath .. "/sandbox/generated/test_framework.lua"
dofile(frameworkPath)

-- Get test file from command line
local testFile = arg[1]

if not testFile then
  print("Usage: lua run_tests.lua <test_file>")
  os.exit(1)
end

-- Load and run the test
dofile(testFile)

-- Execute tests
_SANDBOX_AUTO_RUN()
