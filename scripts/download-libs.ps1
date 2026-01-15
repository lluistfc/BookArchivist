# Download external libraries for local development
# This script reads .pkgmeta and downloads all external libraries

Write-Host "BookArchivist - Library Downloader" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# Check for required tools
$hasSvn = Get-Command svn -ErrorAction SilentlyContinue
$hasGit = Get-Command git -ErrorAction SilentlyContinue

if (-not $hasSvn) {
    Write-Host "ERROR: svn (Subversion) is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install TortoiseSVN or Subversion CLI tools." -ForegroundColor Yellow
    exit 1
}

if (-not $hasGit) {
    Write-Host "ERROR: git is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# Ensure we're in the addon directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$addonDir = Split-Path -Parent $scriptDir
Set-Location $addonDir

# Create libs directory if it doesn't exist
if (-not (Test-Path "libs")) {
    New-Item -ItemType Directory -Path "libs" | Out-Null
}

Write-Host "Downloading libraries...`n" -ForegroundColor Green

# CurseForge SVN repositories
$svnLibs = @{
    "libs/AceComm-3.0" = "https://repos.curseforge.com/wow/ace3/trunk/AceComm-3.0"
    "libs/AceGUI-3.0" = "https://repos.curseforge.com/wow/ace3/trunk/AceGUI-3.0"
    "libs/AceSerializer-3.0" = "https://repos.curseforge.com/wow/ace3/trunk/AceSerializer-3.0"
    "libs/CallbackHandler-1.0" = "https://repos.curseforge.com/wow/callbackhandler/trunk/CallbackHandler-1.0"
    "libs/LibDBIcon-1.0" = "https://repos.curseforge.com/wow/libdbicon-1-0/trunk"
    "libs/LibStub" = "https://repos.curseforge.com/wow/libstub/trunk"
}

# Git repositories (CurseForge + GitHub)
$gitLibs = @{
    "libs/LibDataBroker-1.1" = @{
        url = "https://repos.curseforge.com/wow/libdatabroker-1-1"
        tag = $null
    }
    "libs/LibDeflate" = @{
        url = "https://github.com/SafeteeWoW/LibDeflate"
        tag = "1.0.2-release"
    }
}

foreach ($lib in $svnLibs.GetEnumerator()) {
    $path = $lib.Key
    $url = $lib.Value
    $libName = Split-Path -Leaf $path
    
    Write-Host "  Downloading $libName..." -ForegroundColor Yellow
    
    if (Test-Path $path) {
        # Update existing checkout
        & svn update $path --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✓ Updated" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Update failed" -ForegroundColor Red
        }
    } else {
        # Fresh checkout
        & svn checkout $url $path --quiet
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✓ Downloaded" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Download failed" -ForegroundColor Red
        }
    }
}

# Git repositories (CurseForge + GitHub)
foreach ($lib in $gitLibs.GetEnumerator()) {
    $path = $lib.Key
    $config = $lib.Value
    $url = $config.url
    $tag = $config.tag
    $libName = Split-Path -Leaf $path
    
    Write-Host "  Downloading $libName..." -ForegroundColor Yellow
    
    if (Test-Path $path) {
        # Update existing repo
        Push-Location $path
        & git fetch --tags --quiet 2>&1 | Out-Null
        if ($tag) {
            & git checkout $tag --quiet 2>&1 | Out-Null
        } else {
            & git pull --quiet 2>&1 | Out-Null
        }
        Pop-Location
        if ($LASTEXITCODE -eq 0) {
            if ($tag) {
                Write-Host "    ✓ Updated to $tag" -ForegroundColor Green
            } else {
                Write-Host "    ✓ Updated" -ForegroundColor Green
            }
        } else {
            Write-Host "    ✗ Update failed" -ForegroundColor Red
        }
    } else {
        # Clone repository
        & git clone $url $path --quiet 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            if ($tag) {
                Push-Location $path
                & git checkout $tag --quiet 2>&1 | Out-Null
                Pop-Location
                Write-Host "    ✓ Downloaded $tag" -ForegroundColor Green
            } else {
                Write-Host "    ✓ Downloaded" -ForegroundColor Green
            }
        } else {
            Write-Host "    ✗ Download failed" -ForegroundColor Red
        }
    }
}

Write-Host "`n====================================`n" -ForegroundColor Cyan
Write-Host "Library download complete!" -ForegroundColor Green
Write-Host "All external libraries are now available for local development.`n" -ForegroundColor Gray
