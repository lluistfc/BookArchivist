#!/usr/bin/env pwsh
# Analyze individual coverage files and show untested code per file

$reportDir = "coverage/reports"

if (-not (Test-Path $reportDir)) {
    Write-Host "❌ Coverage reports directory not found: $reportDir" -ForegroundColor Red
    Write-Host "First run: pwsh scripts\split-coverage.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n📊 Coverage Analysis - Untested Code by File`n" -ForegroundColor Cyan

$files = Get-ChildItem $reportDir -Filter "*.coverage.txt" | Sort-Object Name

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # Extract filename
    if ($content -match '===.*\n(.+?)\n===') {
        $fileName = $matches[1].Trim()
    } else {
        $fileName = $file.Name
    }
    
    # Find all untested lines (marked with *******0)
    $lines = $content -split "`n"
    $untestedLines = @()
    $lineNum = 0
    $inFileBlock = $false
    
    foreach ($line in $lines) {
        # Skip header lines
        if ($line -match '^={70,}') {
            continue
        }
        if ($line -match '^[^\s].*\.lua$') {
            $inFileBlock = $true
            continue
        }
        
        if ($inFileBlock) {
            $lineNum++
            if ($line -match '^\s*\*{7}0\s+') {
                $code = $line -replace '^\s*\*{7}0\s+', ''
                $untestedLines += @{
                    line = $lineNum
                    code = $code
                }
            }
        }
    }
    
    # Report
    if ($untestedLines.Count -gt 0) {
        Write-Host "❌ $fileName" -ForegroundColor Red
        Write-Host "   Untested lines: $($untestedLines.Count)" -ForegroundColor Yellow
        
        # Show first 3 untested lines
        for ($i = 0; $i -lt [Math]::Min(3, $untestedLines.Count); $i++) {
            $unt = $untestedLines[$i]
            $codeSnippet = $unt.code.Trim()
            if ($codeSnippet.Length -gt 80) {
                $codeSnippet = $codeSnippet.Substring(0, 77) + "..."
            }
            Write-Host "      Line $($unt.line): $codeSnippet" -ForegroundColor DarkGray
        }
        
        if ($untestedLines.Count -gt 3) {
            Write-Host "      ... and $($untestedLines.Count - 3) more" -ForegroundColor DarkGray
        }
        Write-Host ""
    } else {
        Write-Host "✅ $fileName" -ForegroundColor Green
    }
}

Write-Host "`n📈 Summary Statistics`n" -ForegroundColor Cyan

$totalUntested = 0
$filesToTest = 0
$totalFiles = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $lines = $content -split "`n"
    $inFileBlock = $false
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
            if ($line -match '^\s*\*{7}0\s+') {
                $untested++
            }
        }
    }
    
    $totalFiles++
    if ($untested -gt 0) {
        $totalUntested += $untested
        $filesToTest++
    }
}

Write-Host "   Total files analyzed: $totalFiles" -ForegroundColor Gray
Write-Host "   Files with untested code: $filesToTest" -ForegroundColor Yellow
Write-Host "   Total untested lines: $totalUntested" -ForegroundColor Yellow
Write-Host "   Files fully tested: $($totalFiles - $filesToTest)" -ForegroundColor Green
