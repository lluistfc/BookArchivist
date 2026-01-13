#!/usr/bin/env pwsh
# Detailed coverage breakdown - shows which files to prioritize for testing

$reportDir = "coverage/reports"

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Detailed Coverage Breakdown - Priority for Testing" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$files = Get-ChildItem $reportDir -Filter "*.coverage.txt" | Sort-Object Name
$fileStats = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Extract filename
    if ($content -match '===.*\n(.+?)\n===') {
        $fileName = $matches[1].Trim()
    } else {
        continue
    }
    
    # Count total lines in file
    $lines = $content -split "`n"
    $inFileBlock = $false
    $totalLines = 0
    $untested = 0
    
    foreach ($line in $lines) {
        if ($line -match '^={70,}') {
            continue
        }
        if ($line -match '^[^\s].*\.lua$') {
            $inFileBlock = $true
            continue
        }
        
        if ($inFileBlock) {
            # Count all code lines
            if ($line -match '^\s+\d+\s+' -or $line -match '^\s*\*{7}0\s+') {
                $totalLines++
                if ($line -match '^\s*\*{7}0\s+') {
                    $untested++
                }
            }
        }
    }
    
    if ($totalLines -gt 0) {
        $coverage = [Math]::Round((($totalLines - $untested) / $totalLines) * 100, 1)
        $fileStats += @{
            name = $fileName
            total = $totalLines
            untested = $untested
            coverage = $coverage
        }
    }
}

# Sort by untested lines descending
$sorted = $fileStats | Sort-Object -Property untested -Descending

# Display
Write-Host "File" -NoNewline -ForegroundColor White
Write-Host (" " * 45) -NoNewline
Write-Host "Coverage  Untested    Total" -ForegroundColor Gray
Write-Host ("─" * 77) -ForegroundColor DarkGray

foreach ($stat in $sorted) {
    $name = $stat.name
    if ($name.Length -gt 45) {
        $name = "..." + $name.Substring($name.Length - 42)
    }
    
    $coverageColor = if ($stat.coverage -ge 80) { "Green" }
                     elseif ($stat.coverage -ge 50) { "Yellow" }
                     else { "Red" }
    
    $barLength = [Math]::Floor($stat.coverage / 10)
    $bar = "█" * $barLength + "░" * (10 - $barLength)
    
    Write-Host ("{0,-48}" -f $name) -NoNewline -ForegroundColor Gray
    Write-Host ("{0,6}%" -f $stat.coverage) -NoNewline -ForegroundColor $coverageColor
    Write-Host (" $bar" -f $stat.coverage) -NoNewline -ForegroundColor $coverageColor
    Write-Host (" {0,5}" -f $stat.untested) -NoNewline -ForegroundColor Red
    Write-Host (" {0,5}" -f $stat.total) -ForegroundColor DarkGray
}

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Calculate totals
$totalLines = 0
$totalUntested = 0

foreach ($stat in $fileStats) {
    $totalLines += $stat.total
    $totalUntested += $stat.untested
}

$totalCoverage = [Math]::Round((($totalLines - $totalUntested) / $totalLines) * 100, 1)
$totalBar = "█" * ([Math]::Floor($totalCoverage / 10)) + "░" * (10 - [Math]::Floor($totalCoverage / 10))

Write-Host "`nTOTAL" -NoNewline -ForegroundColor White
Write-Host (" " * 43) -NoNewline
Write-Host ("{0,6}%" -f $totalCoverage) -NoNewline -ForegroundColor "Yellow"
Write-Host (" $totalBar {0,5} {1,5}" -f $totalUntested, $totalLines) -ForegroundColor Yellow

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Recommendations
Write-Host "📊 Coverage Recommendations:`n" -ForegroundColor Cyan

Write-Host "🔴 CRITICAL (0-50% coverage):" -ForegroundColor Red
$critical = $sorted | Where-Object { $_.coverage -le 50 }
if ($critical.Count -gt 0) {
    foreach ($stat in $critical | Select-Object -First 5) {
        Write-Host "   • $($stat.name) - $($stat.untested) untested lines" -ForegroundColor Red
    }
} else {
    Write-Host "   ✓ None!" -ForegroundColor Green
}

Write-Host "`n🟡 WARNING (50-80% coverage):" -ForegroundColor Yellow
$warning = $sorted | Where-Object { $_.coverage -gt 50 -and $_.coverage -lt 80 }
if ($warning.Count -gt 0) {
    foreach ($stat in $warning | Select-Object -First 5) {
        Write-Host "   • $($stat.name) - $($stat.untested) untested lines" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ✓ None!" -ForegroundColor Green
}

Write-Host "`n🟢 GOOD (80%+ coverage):" -ForegroundColor Green
$good = $sorted | Where-Object { $_.coverage -ge 80 }
if ($good.Count -gt 0) {
    Write-Host "   ✓ $($good.Count) files fully tested" -ForegroundColor Green
} else {
    Write-Host "   ✓ None!" -ForegroundColor Green
}
