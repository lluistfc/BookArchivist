#!/usr/bin/env pwsh
# Split luacov.report.out into individual files per source file
# Extracts blocks with headers like:
# ==============================================================================
# core\BookArchivist_Order.lua
# ==============================================================================

$reportFile = "coverage/luacov.report.out"
$outputDir = "coverage/reports"

if (-not (Test-Path $reportFile)) {
    Write-Host "❌ Coverage report not found: $reportFile" -ForegroundColor Red
    Write-Host "Run: make test-coverage" -ForegroundColor Yellow
    exit 1
}

# Create output directory
if (Test-Path $outputDir) {
    Remove-Item -Path "$outputDir\*" -Force -ErrorAction SilentlyContinue
} else {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "📊 Splitting coverage report..." -ForegroundColor Cyan

$content = Get-Content $reportFile -Raw

# Split by the header pattern: lines of = followed by filename
# Pattern: ===...\n<filename>\n===...
$pattern = '={70,}\s*\n(.+?)\n={70,}'
$regex = [regex]$pattern

$fileCount = 0
$matches = $regex.Matches($content)

foreach ($match in $matches) {
    $fileName = $match.Groups[1].Value.Trim()
    
    # Only process BookArchivist files (core/, ui/, locales/)
    if ($fileName -notmatch '^(core|ui|locales)[\\\/]') {
        continue
    }
    
    # Extract the full block (from this header to next header)
    $blockStart = $match.Index + $match.Length
    $nextMatch = $null
    
    # Find next header
    $nextMatches = $regex.Matches($content, $blockStart)
    if ($nextMatches.Count -gt 0) {
        $blockEnd = $nextMatches[0].Index
    } else {
        $blockEnd = $content.Length
    }
    
    $blockContent = $content.Substring($blockStart, $blockEnd - $blockStart).Trim()
    
    # Create safe filename
    $safeFileName = $fileName -replace '[\\\/]', '.' -replace '\.lua$', ''
    $outputFile = Join-Path $outputDir "$safeFileName.coverage.txt"
    
    # Write the block to file with header
    $output = "==============================================================================`n"
    $output += "$fileName`n"
    $output += "==============================================================================`n`n"
    $output += $blockContent
    
    $output | Out-File -FilePath $outputFile -Encoding utf8
    
    $fileCount++
    Write-Host "  ✓ $fileName → $(Split-Path -Leaf $outputFile)" -ForegroundColor Green
}

Write-Host "`n✅ Extracted $fileCount BookArchivist files into $outputDir" -ForegroundColor Green
Write-Host "   Lines starting with *******0 are untested code" -ForegroundColor Yellow
Write-Host "   Use: Get-ChildItem $outputDir -Filter '*.coverage.txt' | % { Write-Host `$_.Name }" -ForegroundColor Gray
