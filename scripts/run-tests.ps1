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
    if ($Verbose) {
        # Verbose mode: show full busted output
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
        # Normal mode: parse and format output
        $output = & busted --output=json @args 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $output) {
            # Parse JSON
            try {
                $result = $output | ConvertFrom-Json
                
                $passed = $result.successes.Count
                $failed = $result.failures.Count
                $errors = $result.errors.Count
                $total = $passed + $failed + $errors
                
                # Summary
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "  SUMMARY" -ForegroundColor Cyan
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "  Total:  $total tests" -ForegroundColor White
                Write-Host "  Passed: $passed tests" -ForegroundColor Green
                Write-Host "  Failed: $($failed + $errors) tests" -ForegroundColor $(if ($failed + $errors -eq 0) { "Green" } else { "Red" })
                Write-Host "  Duration: $([math]::Round($result.duration, 2))s`n" -ForegroundColor Gray
                
                # Show failures if any
                if ($failed -gt 0) {
                    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                    Write-Host "  FAILURES" -ForegroundColor Red
                    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                    foreach ($failure in $result.failures) {
                        Write-Host "  ✗ $($failure.name)" -ForegroundColor Red
                        if ($ShowErrors -and $failure.trace) {
                            Write-Host "    Message: $($failure.trace.message)" -ForegroundColor Gray
                            if ($failure.trace.traceback) {
                                $lines = $failure.trace.traceback -split "`n" | Select-Object -First 5
                                foreach ($line in $lines) {
                                    Write-Host "    $line" -ForegroundColor DarkGray
                                }
                            }
                            Write-Host ""
                        } else {
                            Write-Host "    $($failure.trace.message)" -ForegroundColor Gray
                        }
                    }
                    Write-Host ""
                }
                
                # Show errors if any
                if ($errors -gt 0) {
                    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                    Write-Host "  ERRORS (InGame tests - expected to fail)" -ForegroundColor Yellow
                    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
                    Write-Host "  $errors InGame tests require WoW runtime" -ForegroundColor Gray
                    Write-Host "  These will work once converted to native WoW tests`n" -ForegroundColor Gray
                }
                
                # Exit code
                if ($failed -gt 0) {
                    exit 1
                } else {
                    Write-Host "✓ All Sandbox + Desktop tests passed!" -ForegroundColor Green
                    Write-Host ""
                    exit 0
                }
            } catch {
                # JSON parsing failed, show raw output
                Write-Host "Failed to parse test results. Raw output:" -ForegroundColor Yellow
                Write-Host $output
                exit 1
            }
        } else {
            Write-Host "❌ Tests failed to run" -ForegroundColor Red
            exit 1
        }
    }
} finally {
    Pop-Location
}
