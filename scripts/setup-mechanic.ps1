#!/usr/bin/env pwsh
# Setup script for Mechanic - Windows/PowerShell
# Usage: .\scripts\setup-mechanic.ps1 [MECHANIC_DIR] [MECHANIC_REPO]

param(
    [string]$MechanicDir = "../../_dev_/Mechanic",
    [string]$MechanicRepo = "https://github.com/Falkicon/Mechanic.git"
)

Write-Host "Setting up Mechanic..." -ForegroundColor Cyan
Write-Host ""

# Determine dev folder and addon folder
$DevFolder = (Resolve-Path $MechanicDir).Path | Split-Path -Parent
$AddonFolder = (Get-Location).Path

Write-Host "Dev folder: $DevFolder" -ForegroundColor Gray
Write-Host "Addon folder: $AddonFolder" -ForegroundColor Gray
Write-Host ""

# Create junction link from _dev_/BookArchivist to actual addon folder
$JunctionPath = Join-Path $DevFolder "BookArchivist"
if (Test-Path $JunctionPath) {
    $item = Get-Item $JunctionPath
    if ($item.LinkType -eq "Junction") {
        Write-Host "✓ BookArchivist junction already exists in dev folder" -ForegroundColor Green
    } else {
        Write-Host "⚠ BookArchivist exists but is not a junction" -ForegroundColor Yellow
    }
} else {
    Write-Host "Creating junction: $JunctionPath -> $AddonFolder" -ForegroundColor Yellow
    New-Item -ItemType Junction -Path $JunctionPath -Target $AddonFolder | Out-Null
    if ($LASTEXITCODE -eq 0 -or (Test-Path $JunctionPath)) {
        Write-Host "✓ Created BookArchivist junction in dev folder" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to create junction. Run as Administrator?" -ForegroundColor Red
        exit 1
    }
}

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

# Sync Mechanic addons to WoW clients
Write-Host "Syncing Mechanic addons to WoW clients..." -ForegroundColor Yellow
$syncSuccess = $true

foreach ($addon in @("!Mechanic", "Mechanic")) {
    Write-Host "  Syncing $addon..." -ForegroundColor Gray
    $result = mech call addon.sync "{`"addon`": `"$addon`"}" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ Failed to sync $addon" -ForegroundColor Red
        $syncSuccess = $false
    } else {
        Write-Host "  ✓ Synced $addon" -ForegroundColor Green
    }
}

if ($syncSuccess) {
    Write-Host ""
    Write-Host "✓ All Mechanic addons synced to WoW clients!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  • Start dashboard: mech" -ForegroundColor White
Write-Host "  • Check installation: mech --version" -ForegroundColor White
Write-Host "  • View help: mech --help" -ForegroundColor White
Write-Host "  • Reload WoW to load Mechanic addons" -ForegroundColor White
