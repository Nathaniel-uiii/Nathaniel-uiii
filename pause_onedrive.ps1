# Script to pause OneDrive sync
Write-Host "Attempting to pause OneDrive sync..." -ForegroundColor Yellow

# Method 1: Try using OneDrive registry settings
try {
    $onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    if (Test-Path $onedrivePath) {
        Write-Host "OneDrive found at: $onedrivePath" -ForegroundColor Green
        
        # Try to pause sync using OneDrive command line
        # Note: OneDrive doesn't have a direct CLI for pausing, but we can try
        Write-Host "`nOneDrive doesn't have a direct command-line pause option." -ForegroundColor Yellow
        Write-Host "Please pause OneDrive manually:" -ForegroundColor Yellow
        Write-Host "1. Right-click OneDrive icon in system tray (bottom-right)" -ForegroundColor Cyan
        Write-Host "2. Click 'Pause syncing'" -ForegroundColor Cyan
        Write-Host "3. Select '2 hours'" -ForegroundColor Cyan
        Write-Host "`nWaiting 15 seconds for you to pause OneDrive..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
        
        Write-Host "`nOneDrive should now be paused. Proceeding with build cleanup..." -ForegroundColor Green
    } else {
        Write-Host "OneDrive executable not found in standard location." -ForegroundColor Red
        Write-Host "Please pause OneDrive manually from the system tray." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Please pause OneDrive manually from the system tray." -ForegroundColor Yellow
}

Write-Host "`nNow cleaning build..." -ForegroundColor Green
flutter clean

Write-Host "`nBuild cleaned! You can now run: flutter build apk --debug" -ForegroundColor Green

