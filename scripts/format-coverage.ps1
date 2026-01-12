#!/usr/bin/env pwsh
# Format coverage report with colors and better readability

$reportFile = "coverage/luacov.report.out"

if (-not (Test-Path $reportFile)) {
    Write-Host "❌ Coverage report not found. Run: make test-coverage" -ForegroundColor Red
    exit 1
}

# Parse the report
$lines = Get-Content $reportFile
$files = @()
$totalLine = $null

foreach ($line in $lines) {
    # Match file coverage lines (path, hits, missed, percentage)
    if ($line -match '^(.+?)\s+(\d+)\s+(\d+)\s+(\d+\.\d+)%$') {
        $fileName = $matches[1].Trim()
        # Skip the Total line in file list
        if ($fileName -ne "Total") {
            $files += [PSCustomObject]@{
                File = $fileName
                Hits = [int]$matches[2]
                Missed = [int]$matches[3]
                Coverage = [double]$matches[4]
            }
        }
        # Capture Total line
        else {
            $totalLine = [PSCustomObject]@{
                Hits = [int]$matches[3]
                Missed = [int]$matches[2] - [int]$matches[3]
                Coverage = [double]$matches[4]
            }
        }
    }
}

# Filter to only BookArchivist files
$addonFiles = $files | Where-Object { $_.File -match '^(core|ui|locales)\\' } | Sort-Object Coverage -Descending

# Display header
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Code Coverage Report" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Display summary
if ($totalLine) {
    $totalLines = $totalLine.Hits + $totalLine.Missed
    Write-Host "  Total Lines: " -NoNewline -ForegroundColor White
    Write-Host $totalLines -ForegroundColor Gray
    
    Write-Host "  Covered:     " -NoNewline -ForegroundColor White
    Write-Host "$($totalLine.Hits) lines" -ForegroundColor Green
    
    Write-Host "  Missed:      " -NoNewline -ForegroundColor White
    Write-Host "$($totalLine.Missed) lines" -ForegroundColor Red
    
    Write-Host "  Coverage:    " -NoNewline -ForegroundColor White
    $coverageColor = if ($totalLine.Coverage -ge 80) { "Green" } 
                     elseif ($totalLine.Coverage -ge 50) { "Yellow" } 
                     else { "Red" }
    Write-Host "$($totalLine.Coverage)%" -ForegroundColor $coverageColor
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  File Coverage Details" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Display table header
Write-Host ("{0,-55} {1,8} {2,8} {3,10}" -f "File", "Hits", "Missed", "Coverage") -ForegroundColor White
Write-Host ("{0,-55} {1,8} {2,8} {3,10}" -f ("─" * 55), ("─" * 8), ("─" * 8), ("─" * 10)) -ForegroundColor DarkGray

# Display files
foreach ($file in $addonFiles) {
    # Shorten file path for display
    $displayPath = $file.File -replace '^(core|ui|locales)\\', '$1\'
    if ($displayPath.Length -gt 55) {
        $displayPath = "..." + $displayPath.Substring($displayPath.Length - 52)
    }
    
    # Color code based on coverage
    $color = if ($file.Coverage -ge 80) { "Green" } 
             elseif ($file.Coverage -ge 50) { "Yellow" } 
             else { "Red" }
    
    # Coverage bar
    $barLength = [Math]::Floor($file.Coverage / 10)
    $bar = "█" * $barLength + "░" * (10 - $barLength)
    
    Write-Host ("{0,-55}" -f $displayPath) -NoNewline -ForegroundColor Gray
    Write-Host (" {0,8}" -f $file.Hits) -NoNewline -ForegroundColor Green
    Write-Host (" {0,8}" -f $file.Missed) -NoNewline -ForegroundColor Red
    Write-Host (" {0,7}%" -f $file.Coverage) -NoNewline -ForegroundColor $color
    Write-Host (" $bar" -f $file.Coverage) -ForegroundColor $color
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Coverage level message
if ($totalLine) {
    Write-Host "`n  " -NoNewline
    if ($totalLine.Coverage -ge 80) {
        Write-Host "✓ Excellent coverage!" -ForegroundColor Green
    } elseif ($totalLine.Coverage -ge 60) {
        Write-Host "✓ Good coverage" -ForegroundColor Yellow
    } elseif ($totalLine.Coverage -ge 40) {
        Write-Host "⚠ Fair coverage - consider adding more tests" -ForegroundColor Yellow
    } else {
        Write-Host "⚠ Low coverage - more tests needed" -ForegroundColor Red
    }
    Write-Host ""
}
