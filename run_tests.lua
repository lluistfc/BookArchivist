-- Test runner for BookArchivist tests
-- Usage: lua run_tests.lua [test_file]

-- Load test framework from Mechanic
dofile("G:/development/_dev_/Mechanic/sandbox/generated/test_framework.lua")

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
