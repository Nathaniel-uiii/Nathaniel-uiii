# Fix Android Build Directory Lock Issue
# This script resolves Gradle "Unable to delete directory" errors caused by OneDrive

Write-Host ""
Write-Host "=== Fixing Android Build Directory Lock ===" -ForegroundColor Cyan
Write-Host ""

$scriptRoot = Get-Location | Select-Object -ExpandProperty Path
$buildPath = Join-Path $scriptRoot "build"

# Step 1: Stop all processes that might be locking files
Write-Host "Step 1: Stopping all processes..." -ForegroundColor Yellow
$processes = @("dart", "flutter", "java", "gradle", "adb")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc processes..." -ForegroundColor Cyan
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 3

# Step 2: Stop Gradle daemon
Write-Host ""
Write-Host "Step 2: Stopping Gradle daemon..." -ForegroundColor Yellow
if (Test-Path "android\gradlew.bat") {
    Push-Location android
    & .\gradlew.bat --stop 2>$null
    Pop-Location
    Start-Sleep -Seconds 2
}

# Step 3: Remove read-only attributes from build directory
Write-Host ""
Write-Host "Step 3: Removing read-only attributes..." -ForegroundColor Yellow
if (Test-Path $buildPath) {
    try {
        Get-ChildItem -Path $buildPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
            } catch {
                # Ignore individual file errors
            }
        }
        Write-Host "  Attributes removed" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Some attributes could not be removed" -ForegroundColor Yellow
    }
}

# Step 4: Delete problematic .transforms directories first
Write-Host ""
Write-Host "Step 4: Cleaning .transforms directories..." -ForegroundColor Yellow
if (Test-Path $buildPath) {
    $transformsDirs = Get-ChildItem -Path $buildPath -Recurse -Directory -Filter ".transforms" -ErrorAction SilentlyContinue
    foreach ($transformsDir in $transformsDirs) {
        $transformsPath = $transformsDir.FullName
        Write-Host "  Attempting to remove: $transformsPath" -ForegroundColor Cyan
        
        $maxRetries = 3
        $retryCount = 0
        $deleted = $false
        
        while ($retryCount -lt $maxRetries -and -not $deleted) {
            try {
                # Remove read-only from this specific directory first
                Get-ChildItem -Path $transformsPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                    } catch { }
                }
                
                Remove-Item -Path $transformsPath -Recurse -Force -ErrorAction Stop
                Write-Host "    [SUCCESS] Removed" -ForegroundColor Green
                $deleted = $true
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "    Retry $retryCount/$maxRetries..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                } else {
                    Write-Host "    [FAILED] Could not remove after $maxRetries attempts" -ForegroundColor Red
                }
            }
        }
    }
}

# Step 5: Delete the entire build directory
Write-Host ""
Write-Host "Step 5: Removing build directory..." -ForegroundColor Yellow
if (Test-Path $buildPath) {
    $maxRetries = 5
    $retryCount = 0
    $deleted = $false
    
    while ($retryCount -lt $maxRetries -and -not $deleted) {
        try {
            Remove-Item -Path $buildPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [SUCCESS] Build directory removed!" -ForegroundColor Green
            $deleted = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "  Attempt $retryCount/$maxRetries failed. Retrying in 3 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
                
                # Try to remove attributes again
                Write-Host "  Removing attributes again..." -ForegroundColor Cyan
                Get-ChildItem -Path $buildPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                    try {
                        $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                    } catch { }
                }
            } else {
                Write-Host "  [FAILED] Could not remove build directory after $maxRetries attempts" -ForegroundColor Red
                Write-Host ""
                Write-Host "  Error: $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $deleted) {
        Write-Host ""
        Write-Host "[WARNING] OneDrive is likely locking these files!" -ForegroundColor Red
        Write-Host ""
        Write-Host "CRITICAL: You MUST pause OneDrive sync before building!" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Please do the following:" -ForegroundColor Yellow
        Write-Host "  1. Right-click OneDrive icon in system tray" -ForegroundColor White
        Write-Host "  2. Click 'Pause syncing' -> '2 hours' or '24 hours'" -ForegroundColor White
        Write-Host "  3. Run this script again: .\fix_android_build.ps1" -ForegroundColor White
        Write-Host "  4. Then run: flutter clean" -ForegroundColor White
        Write-Host "  5. Then run: flutter build apk --debug" -ForegroundColor White
        Write-Host ""
        Write-Host "  PERMANENT FIX: Exclude 'build' folder from OneDrive sync" -ForegroundColor Cyan
        Write-Host "  - Right-click OneDrive icon -> Settings -> Sync and backup" -ForegroundColor White
        Write-Host "  - Advanced settings -> Choose folders" -ForegroundColor White
        Write-Host "  - Uncheck 'build' folder" -ForegroundColor White
        exit 1
    }
} else {
    Write-Host "  Build directory doesn't exist - nothing to clean!" -ForegroundColor Green
}

# Step 6: Clean .dart_tool as well
Write-Host ""
Write-Host "Step 6: Cleaning .dart_tool..." -ForegroundColor Yellow
$dartToolPath = Join-Path $scriptRoot ".dart_tool"
if (Test-Path $dartToolPath) {
    try {
        Remove-Item -Path $dartToolPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [SUCCESS] .dart_tool removed" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Could not fully remove .dart_tool (may be locked)" -ForegroundColor Yellow
    }
}

# Step 7: Clean Android build directories
Write-Host ""
Write-Host "Step 7: Cleaning Android build directories..." -ForegroundColor Yellow
$androidBuildDirs = @(
    "android\app\build",
    "android\build",
    "android\.gradle"
)
foreach ($dir in $androidBuildDirs) {
    $fullDirPath = Join-Path $scriptRoot $dir
    if (Test-Path $fullDirPath) {
        try {
            Remove-Item -Path $fullDirPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Removed: $dir" -ForegroundColor Green
        } catch {
            Write-Host "  Could not remove: $dir (may be locked)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Make sure OneDrive is paused (if it wasn't already)" -ForegroundColor White
Write-Host "  2. Run: flutter clean" -ForegroundColor White
Write-Host "  3. Run: flutter pub get" -ForegroundColor White
Write-Host "  4. Run: flutter build apk --debug" -ForegroundColor White
Write-Host ""

