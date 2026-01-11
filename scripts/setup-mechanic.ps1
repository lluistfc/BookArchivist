#!/usr/bin/env pwsh
# Setup script for Mechanic - Windows/PowerShell
# Usage: .\scripts\setup-mechanic.ps1 [MECHANIC_DIR] [MECHANIC_REPO]

param(
    [string]$MechanicDir = "../../_dev_/Mechanic",
    [string]$MechanicRepo = "https://github.com/Falkicon/Mechanic.git"
)

Write-Host "Setting up Mechanic..." -ForegroundColor Cyan
Write-Host ""

# Clone Mechanic if not present
if (-not (Test-Path $MechanicDir)) {
    Write-Host "Cloning Mechanic from $MechanicRepo..." -ForegroundColor Yellow
    git clone $MechanicRepo $MechanicDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to clone Mechanic repository" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Mechanic directory already exists at: $MechanicDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installing Mechanic Desktop (editable mode)..." -ForegroundColor Yellow

# Find Python executable (prefer py launcher on Windows)
$PythonCmd = $null
foreach ($cmd in @("py", "python3", "python")) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        # Test if it's actually executable (not a Windows Store stub)
        $testResult = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $PythonCmd = $cmd
            break
        }
    }
}

if (-not $PythonCmd) {
    Write-Host "✗ Python not found. Please install Python 3.10 or higher." -ForegroundColor Red
    Write-Host "  Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Using Python: $PythonCmd" -ForegroundColor Gray

# Install Mechanic in editable mode
Push-Location "$MechanicDir/desktop"
try {
    & $PythonCmd -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to upgrade pip" -ForegroundColor Red
        exit 1
    }

    & $PythonCmd -m pip install -e .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to install Mechanic" -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "✓ Mechanic setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  • Start dashboard: mech" -ForegroundColor White
Write-Host "  • Check installation: mech --version" -ForegroundColor White
Write-Host "  • View help: mech --help" -ForegroundColor White
