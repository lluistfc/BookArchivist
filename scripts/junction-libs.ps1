# Junction external libraries from existing locations
# Reads paths from .env file and creates directory junctions

Write-Host "BookArchivist - Library Junction Tool" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Ensure we're in the addon directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$addonDir = Split-Path -Parent $scriptDir
Set-Location $addonDir

# Check if .env file exists
if (-not (Test-Path ".env")) {
    Write-Host "ERROR: .env file not found." -ForegroundColor Red
    Write-Host "Copy .env.dist to .env and configure library paths." -ForegroundColor Yellow
    exit 1
}

# Function to read .env file
function Read-EnvFile {
    param([string]$Path)
    
    $env = @{}
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        # Skip comments and empty lines
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim()
                $env[$key] = $value
            }
        }
    }
    return $env
}

# Library mapping: env variable -> target directory
$libMapping = @{
    "LIB_ACECOMM_PATH" = "libs/AceComm-3.0"
    "LIB_ACEGUI_PATH" = "libs/AceGUI-3.0"
    "LIB_ACESERIALIZER_PATH" = "libs/AceSerializer-3.0"
    "LIB_CALLBACKHANDLER_PATH" = "libs/CallbackHandler-1.0"
    "LIB_LIBDATABROKER_PATH" = "libs/LibDataBroker-1.1"
    "LIB_LIBDBICON_PATH" = "libs/LibDBIcon-1.0"
    "LIB_LIBSTUB_PATH" = "libs/LibStub"
    "LIB_LIBDEFLATE_PATH" = "libs_test/LibDeflate"
}

# Read .env file
Write-Host "Reading .env configuration...`n" -ForegroundColor Green
$envVars = Read-EnvFile ".env"

# Create libs directories if they don't exist
if (-not (Test-Path "libs")) {
    New-Item -ItemType Directory -Path "libs" | Out-Null
}
if (-not (Test-Path "libs_test")) {
    New-Item -ItemType Directory -Path "libs_test" | Out-Null
}

$junctionsCreated = 0
$junctionsSkipped = 0
$junctionsFailed = 0

Write-Host "Creating junctions...`n" -ForegroundColor Green

foreach ($mapping in $libMapping.GetEnumerator()) {
    $envKey = $mapping.Key
    $targetDir = $mapping.Value
    $libName = Split-Path -Leaf $targetDir
    
    if ($envVars.ContainsKey($envKey) -and $envVars[$envKey]) {
        $sourcePath = $envVars[$envKey]
        
        Write-Host "  Processing $libName..." -ForegroundColor Yellow
        
        # Validate source path exists
        if (-not (Test-Path $sourcePath)) {
            Write-Host "    ✗ Source path not found: $sourcePath" -ForegroundColor Red
            $junctionsFailed++
            continue
        }
        
        # Check if target already exists
        if (Test-Path $targetDir) {
            # Check if it's already a junction
            $item = Get-Item $targetDir -Force
            if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                Write-Host "    ⊜ Junction already exists" -ForegroundColor Gray
                $junctionsSkipped++
                continue
            } else {
                Write-Host "    ! Target directory exists but is not a junction" -ForegroundColor Yellow
                Write-Host "      Remove it manually if you want to replace it with a junction" -ForegroundColor Yellow
                $junctionsSkipped++
                continue
            }
        }
        
        # Create junction
        try {
            # Convert to absolute paths
            $sourcePathAbs = (Resolve-Path $sourcePath).Path
            $targetDirAbs = Join-Path $addonDir $targetDir
            
            # Create parent directory if needed
            $parentDir = Split-Path -Parent $targetDirAbs
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
            
            # Create junction using cmd /c mklink /J
            $result = cmd /c mklink /J "`"$targetDirAbs`"" "`"$sourcePathAbs`"" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ Junction created: $targetDir -> $sourcePath" -ForegroundColor Green
                $junctionsCreated++
            } else {
                Write-Host "    ✗ Failed to create junction: $result" -ForegroundColor Red
                $junctionsFailed++
            }
        } catch {
            Write-Host "    ✗ Error: $_" -ForegroundColor Red
            $junctionsFailed++
        }
    }
}

Write-Host "`n======================================`n" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Created:  $junctionsCreated" -ForegroundColor Green
Write-Host "  Skipped:  $junctionsSkipped" -ForegroundColor Gray
Write-Host "  Failed:   $junctionsFailed" -ForegroundColor $(if ($junctionsFailed -gt 0) { "Red" } else { "Gray" })

if ($junctionsCreated -eq 0 -and $junctionsSkipped -eq 0) {
    Write-Host "`nNo library paths configured in .env file." -ForegroundColor Yellow
    Write-Host "Edit .env and uncomment/set LIB_* variables to use junctions." -ForegroundColor Yellow
}

Write-Host ""
