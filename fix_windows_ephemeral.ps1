# Fix Windows Flutter Ephemeral Directory Lock Issue
# This script resolves the "Flutter failed to delete a directory" error

Write-Host ""
Write-Host "=== Fixing Windows Flutter Ephemeral Directory Lock ===" -ForegroundColor Cyan
Write-Host ""

$ephemeralPath = "windows\flutter\ephemeral\.plugin_symlinks"
$scriptRoot = Get-Location | Select-Object -ExpandProperty Path
$fullPath = Join-Path $scriptRoot $ephemeralPath

# Step 1: Stop processes that might be locking files
Write-Host "Step 1: Stopping processes that might lock files..." -ForegroundColor Yellow
$processes = @("dart", "flutter", "java", "gradle")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc..." -ForegroundColor Cyan
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 2

# Step 2: Check if directory exists
Write-Host ""
Write-Host "Step 2: Checking directory..." -ForegroundColor Yellow
if (Test-Path $fullPath) {
    Write-Host "  Found: $fullPath" -ForegroundColor Green
    
    # Step 3: Try to remove read-only attributes
    Write-Host ""
    Write-Host "Step 3: Removing read-only attributes..." -ForegroundColor Yellow
    try {
        Get-ChildItem -Path $fullPath -Recurse -Force | ForEach-Object {
            $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
        }
        Write-Host "  Attributes removed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Could not remove all attributes: $_" -ForegroundColor Yellow
    }
    
    # Step 4: Attempt to delete the directory
    Write-Host ""
    Write-Host "Step 4: Attempting to delete directory..." -ForegroundColor Yellow
    $maxRetries = 5
    $retryCount = 0
    $deleted = $false
    
    while ($retryCount -lt $maxRetries -and -not $deleted) {
        try {
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [SUCCESS] Directory deleted successfully!" -ForegroundColor Green
            $deleted = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "  Attempt $retryCount failed. Retrying in 2 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
                
                # Try to unlock files using handle.exe if available
                Write-Host "  Attempting to unlock files..." -ForegroundColor Cyan
                
                # Force close any handles (if handle.exe is available)
                $handlePath = "$env:ProgramFiles\Sysinternals\handle.exe"
                if (Test-Path $handlePath) {
                    Write-Host "  Using Sysinternals Handle to unlock files..." -ForegroundColor Cyan
                    & $handlePath -p $fullPath -accepteula 2>$null | ForEach-Object {
                        if ($_ -match "pid:\s+(\d+)\s+type:\s+File") {
                            $pid = $matches[1]
                            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
            } else {
                Write-Host "  [FAILED] Could not delete after $maxRetries attempts" -ForegroundColor Red
                Write-Host ""
                Write-Host "  Error: $_" -ForegroundColor Red
            }
        }
    }
    
    if (-not $deleted) {
        Write-Host ""
        Write-Host "[WARNING] OneDrive is likely locking these files!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please do ONE of the following:" -ForegroundColor Yellow
        Write-Host "  1. Right-click OneDrive icon -> Pause syncing -> 2 hours" -ForegroundColor White
        Write-Host "  2. Then run this script again" -ForegroundColor White
        Write-Host "  3. Or exclude 'windows\flutter\ephemeral' from OneDrive sync" -ForegroundColor White
        Write-Host ""
        Write-Host "  To exclude from OneDrive:" -ForegroundColor Cyan
        Write-Host "  - Right-click OneDrive icon -> Settings -> Sync and backup" -ForegroundColor White
        Write-Host "  - Advanced settings -> Choose folders" -ForegroundColor White
        Write-Host "  - Uncheck 'windows\flutter\ephemeral' folder" -ForegroundColor White
        exit 1
    }
} else {
    Write-Host "  Directory doesn't exist: $fullPath" -ForegroundColor Green
    Write-Host "  Nothing to clean up!" -ForegroundColor Green
}

# Step 5: Clean the entire ephemeral directory if it exists
Write-Host ""
Write-Host "Step 5: Cleaning entire ephemeral directory..." -ForegroundColor Yellow
$ephemeralDir = Join-Path $scriptRoot "windows\flutter\ephemeral"
if (Test-Path $ephemeralDir) {
    try {
        Remove-Item -Path $ephemeralDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [SUCCESS] Ephemeral directory cleaned" -ForegroundColor Green
    } catch {
        Write-Host "  [WARNING] Some files in ephemeral directory may still be locked" -ForegroundColor Yellow
        Write-Host "     This is usually fine - Flutter will regenerate them" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Fix Complete ===" -ForegroundColor Green
Write-Host "You can now run: flutter build windows" -ForegroundColor Cyan
Write-Host "Or: flutter clean" -ForegroundColor Cyan
Write-Host ""
