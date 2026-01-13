#!/usr/bin/env pwsh
# BookArchivist Test Runner
# Quick and easy test execution with readable output

param(
    [switch]$Verbose,      # Show full busted output (raw)
    [switch]$Detailed,     # Show each test result (JUnit-style)
    [switch]$ShowErrors,   # Display full error stack traces
    [switch]$Coverage,     # Enable code coverage with luacov
    [string]$Pattern = ""  # Filter tests by pattern
)
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$ErrorActionPreference = "Stop"
# Script is in scripts/ folder, addon root is parent
$addonPath = Split-Path -Parent $PSScriptRoot

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  BookArchivist Test Suite" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Detect environment: GitHub Actions vs Local Dev
$isCI = $env:GITHUB_ACTIONS -eq "true"
$useMechanic = $false

# Coverage requires busted directly (Mechanic doesn't collect coverage)
if ($Coverage) {
    Write-Host "✓ Coverage mode enabled - using Busted directly" -ForegroundColor Yellow
    $useMechanic = $false
}
# Try to use Mechanic in local dev (not CI, not coverage)
elseif (-not $isCI) {
    # Check if we can use Mechanic CLI
    $mechanicPath = $null
    
    # Try to find Mechanic via environment or relative path
    if (Test-Path "../_dev_/Mechanic/desktop") {
        $mechanicPath = "../_dev_/Mechanic"
    } elseif ($env:MECHANIC_PATH -and (Test-Path "$env:MECHANIC_PATH/desktop")) {
        $mechanicPath = $env:MECHANIC_PATH
    } elseif (Test-Path ".env") {
        # Try loading from .env file
        Get-Content .env | ForEach-Object {
            if ($_ -match '^\s*MECHANIC_PATH\s*=\s*(.+)\s*$') {
                $path = $matches[1] -replace '[''"]', ''
                if (Test-Path "$path/desktop") {
                    $mechanicPath = $path
                }
            }
        }
    }
    
    if ($mechanicPath) {
        # Check if mech CLI is available
        Push-Location $mechanicPath
        try {
            $mechTest = py -m mechanic.cli --help 2>&1
            if ($LASTEXITCODE -eq 0) {
                $useMechanic = $true
                Write-Host "✓ Using Mechanic CLI for test execution" -ForegroundColor Green
            }
        } catch {
            # Mechanic not available, fall back to busted
        } finally {
            Pop-Location
        }
    }
}

if (-not $useMechanic) {
    Write-Host "✓ Using Busted directly" -ForegroundColor $(if ($isCI) { "Green" } else { "Yellow" })
    if ($isCI) {
        Write-Host "  (GitHub Actions environment detected)" -ForegroundColor Gray
    }
}

# If using Mechanic, delegate to it
if ($useMechanic) {
    Push-Location $mechanicPath
    try {
        # When -ShowErrors is specified, bypass Mechanic and use Busted directly for full output
        if ($ShowErrors -or $Detailed) {
            Write-Host "Error detail mode requested - falling back to Busted for full output" -ForegroundColor Yellow
            Pop-Location
            $useMechanic = $false
        } else {
            Write-Host "Running tests via Mechanic..." -ForegroundColor Yellow
            Write-Host "Command: py -m mechanic.cli call addon.test`n" -ForegroundColor Gray
            
            $result = py -m mechanic.cli call addon.test '{"addon":"BookArchivist"}' 2>&1 | Out-String
            Write-Host $result
            
            # Parse result for exit code
            if ($result -match "(\d+) passed, (\d+) failed") {
                $passed = [int]$matches[1]
                $failed = [int]$matches[2]
                
                if ($failed -gt 0) {
                    Write-Host "`nℹ For detailed error output, run: make test-errors" -ForegroundColor Yellow
                    exit 1
                } else {
                    Write-Host "`n✓ All tests passed via Mechanic!" -ForegroundColor Green
                    exit 0
                }
            } else {
                Write-Host "✓ Tests completed via Mechanic" -ForegroundColor Green
                exit 0
            }
        }
    } finally {
        if ($useMechanic) {
            Pop-Location
            exit 0
        }
    }
}

# Fall back to busted for CI or when Mechanic not available
# Check if busted is available
$bustedPath = Get-Command busted -ErrorAction SilentlyContinue
if (-not $bustedPath) {
    Write-Host "❌ Busted not found in PATH" -ForegroundColor Red
    Write-Host "`nPlease ensure luarocks bin directory is in PATH:" -ForegroundColor Yellow
    Write-Host "  C:\Users\$env:USERNAME\AppData\Roaming\luarocks\bin`n" -ForegroundColor Gray
    exit 1
}

# Build command
$cmd = "busted"
$args = @()

if ($Coverage) {
    $args += "--coverage"
}

if ($Verbose) {
    $args += "--verbose"
}

if ($Pattern) {
    $args += "--pattern=$Pattern"
}

# Run tests
Write-Host "Running tests..." -ForegroundColor Yellow
if ($Coverage) {
    Write-Host "Coverage: Enabled (luacov)" -ForegroundColor Cyan
}
if ($Pattern) {
    Write-Host "Pattern: $Pattern" -ForegroundColor Gray
}
Write-Host "Command: busted $($args -join ' ')`n" -ForegroundColor Gray

Push-Location $addonPath
try {
    if ($Verbose -or $ShowErrors) {
        # Verbose/ShowErrors mode: show full busted output (native format with errors)
        & busted @args
    } elseif ($Detailed) {
        # Detailed mode: show each test with pass/fail (JUnit-style)
        $output = & busted --output=json @args 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $output) {
            try {
                $result = $output | ConvertFrom-Json
                
                $passed = $result.successes.Count
                $failed = $result.failures.Count
                $errors = $result.errors.Count
                $total = $passed + $failed + $errors
                
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "  TEST RESULTS" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
                
                # Show all successful tests
                foreach ($test in $result.successes) {
                    $duration = if ($test.duration) { " ($([math]::Round($test.duration * 1000, 1))ms)" } else { "" }
                    Write-Host "  ✓ $($test.name)$duration" -ForegroundColor Green
                }
                
                # Show all failures
                foreach ($test in $result.failures) {
                    $duration = if ($test.duration) { " ($([math]::Round($test.duration * 1000, 1))ms)" } else { "" }
                    Write-Host "  ✗ $($test.name)$duration" -ForegroundColor Red
                    if ($ShowErrors -and $test.trace) {
                        Write-Host "    Message: $($test.trace.message)" -ForegroundColor Gray
                        if ($test.trace.traceback) {
                            $lines = $test.trace.traceback -split "`n" | Select-Object -First 5
                            foreach ($line in $lines) {
                                Write-Host "    $line" -ForegroundColor DarkGray
                            }
                        }
                        Write-Host ""
                    }
                }
                
                # Show all errors
                foreach ($test in $result.errors) {
                    $duration = if ($test.duration) { " ($([math]::Round($test.duration * 1000, 1))ms)" } else { "" }
                    Write-Host "  ⚠ $($test.name)$duration" -ForegroundColor Yellow
                    if ($ShowErrors -and $test.trace) {
                        Write-Host "    Error: $($test.trace.message)" -ForegroundColor Gray
                        if ($test.trace.traceback) {
                            $lines = $test.trace.traceback -split "`n" | Select-Object -First 5
                            foreach ($line in $lines) {
                                Write-Host "    $line" -ForegroundColor DarkGray
                            }
                        }
                        Write-Host ""
                    }
                }
                
                # Summary
                Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "  SUMMARY" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "  Total:  $total tests" -ForegroundColor White
                Write-Host "  Passed: $passed tests" -ForegroundColor Green
                Write-Host "  Failed: $($failed + $errors) tests" -ForegroundColor $(if ($failed + $errors -eq 0) { "Green" } else { "Red" })
                Write-Host "  Duration: $([math]::Round($result.duration, 2))s`n" -ForegroundColor Gray
                
                # Exit code
                if ($failed + $errors -gt 0) {
                    exit 1
                } else {
                    Write-Host "✓ All tests passed!" -ForegroundColor Green
                    Write-Host ""
                    exit 0
                }
            } catch {
                Write-Host "Failed to parse test results. Raw output:" -ForegroundColor Yellow
                Write-Host $output
                exit 1
            }
        } else {
            Write-Host "❌ Tests failed to run" -ForegroundColor Red
            exit 1
        }
    } else {
        # Normal mode: use busted's default output (clean, shows only failures/errors)
        & busted @args
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
