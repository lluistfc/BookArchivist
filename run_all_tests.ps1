# Run all portable BookArchivist tests
# Requirements:
#   - Lua 5.1 installed
#   - MECHANIC_PATH environment variable or Mechanic at ../Mechanic

param(
    [string]$LuaPath = "C:\Program Files (x86)\Lua\5.1\lua.exe",
    [string]$MechanicPath = $env:MECHANIC_PATH
)

# Default Mechanic path if not set
if (-not $MechanicPath) {
    $MechanicPath = "G:/development/_dev_/Mechanic"
}

$env:MECHANIC_PATH = $MechanicPath

$tests = @(
    "Tests/Core/BookId_spec.lua",
    "Tests/Core/CRC32_spec.lua",
    "Tests/Core/Serialize_spec.lua",
    "Tests/Core/Favorites_spec.lua",
    "Tests/Core/Recent_spec.lua",
    "Tests/Core/Search_spec.lua",
    "Tests/Core/Base64_spec.lua",
    "Tests/Core/Order_spec.lua",
    "Tests/Core/Export_spec.lua",
    "Tests/Core/DBSafety_spec.lua",
    "Tests/Integration/Async_Filtering_Integration_spec.lua"
)

$totalTests = 0
$totalPassed = 0
$results = @()
$failed = @()

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BookArchivist Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Lua: $LuaPath"
Write-Host "Mechanic: $MechanicPath"
Write-Host ""

foreach ($test in $tests) {
    $testName = Split-Path $test -Leaf
    Write-Host "Running $testName... " -NoNewline
    
    $output = & $LuaPath run_tests.lua $test 2>&1 | Out-String
    
    if ($output -match "(\d+) total, (\d+) passed, (\d+) failed") {
        $total = [int]$matches[1]
        $passed = [int]$matches[2]
        $failedCount = [int]$matches[3]
        
        $totalPassed += $passed
        $totalTests += $total
        
        if ($failedCount -eq 0) {
            Write-Host "✓ $passed/$total" -ForegroundColor Green
            $results += "  ✓ $testName : $passed/$total"
        } else {
            Write-Host "✗ $passed/$total ($failedCount failed)" -ForegroundColor Red
            $results += "  ✗ $testName : $passed/$total ($failedCount failed)"
            $failed += $test
        }
    } else {
        Write-Host "ERROR" -ForegroundColor Red
        $results += "  ✗ $testName : ERROR"
        $failed += $test
    }
}

Write-Host "`n========================================" -ForegroundColor Green
if ($failed.Count -eq 0) {
    Write-Host "ALL TESTS PASSED: $totalPassed/$totalTests" -ForegroundColor Green
} else {
    Write-Host "TESTS FAILED: $totalPassed/$totalTests passed" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nBreakdown:"
$results | ForEach-Object { Write-Host $_ }

if ($failed.Count -gt 0) {
    Write-Host "`nFailed tests:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

exit 0
