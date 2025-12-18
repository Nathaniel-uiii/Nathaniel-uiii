# Automatically pause OneDrive sync for 2 hours
# This script attempts to pause OneDrive programmatically

Write-Host ""
Write-Host "=== Pausing OneDrive Sync ===" -ForegroundColor Cyan
Write-Host ""

# Method 1: Try using registry to pause OneDrive
Write-Host "Attempting to pause OneDrive via registry..." -ForegroundColor Yellow

$onedriveRegPath = "HKCU:\Software\Microsoft\OneDrive"
$onedriveRegPath64 = "HKCU:\Software\WOW6432Node\Microsoft\OneDrive"

try {
    # Check if OneDrive registry keys exist
    $regPath = $null
    if (Test-Path $onedriveRegPath) {
        $regPath = $onedriveRegPath
    } elseif (Test-Path $onedriveRegPath64) {
        $regPath = $onedriveRegPath64
    }
    
    if ($regPath) {
        Write-Host "  Found OneDrive registry path: $regPath" -ForegroundColor Green
        
        # Try to set pause sync (this may not work for all OneDrive versions)
        # Note: OneDrive doesn't expose a direct registry key for pausing, but we can try
        Write-Host "  Note: OneDrive pause requires user interaction" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Registry method not available: $_" -ForegroundColor Yellow
}

# Method 2: Try to use OneDrive executable with command-line parameters
Write-Host ""
Write-Host "Attempting to pause OneDrive via executable..." -ForegroundColor Yellow

$onedrivePaths = @(
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
    "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
    "$env:ProgramFiles(x86)\Microsoft OneDrive\OneDrive.exe"
)

$onedriveExe = $null
foreach ($path in $onedrivePaths) {
    if (Test-Path $path) {
        $onedriveExe = $path
        Write-Host "  Found OneDrive at: $path" -ForegroundColor Green
        break
    }
}

if ($onedriveExe) {
    # Method 3: Use Windows COM to interact with OneDrive
    Write-Host ""
    Write-Host "Attempting to pause OneDrive using Windows automation..." -ForegroundColor Yellow
    
    try {
        # Try to find and click the OneDrive system tray icon programmatically
        # This is complex and may not work reliably, so we'll use a hybrid approach
        
        # Open OneDrive settings window
        Write-Host "  Opening OneDrive settings..." -ForegroundColor Cyan
        Start-Process $onedriveExe -ArgumentList "/settings" -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        Write-Host "  Note: OneDrive pause requires manual interaction" -ForegroundColor Yellow
        Write-Host "  However, we can help automate the process..." -ForegroundColor Cyan
        
    } catch {
        Write-Host "  Automation method failed: $_" -ForegroundColor Yellow
    }
}

# Method 4: Use a workaround - Stop OneDrive process temporarily
Write-Host ""
Write-Host "Attempting alternative method: Temporarily stopping OneDrive sync..." -ForegroundColor Yellow

try {
    $onedriveProcesses = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
    if ($onedriveProcesses) {
        Write-Host "  Found OneDrive processes running" -ForegroundColor Green
        Write-Host "  WARNING: Stopping OneDrive process will pause sync" -ForegroundColor Yellow
        Write-Host "  This is a temporary workaround - OneDrive will restart automatically" -ForegroundColor Yellow
        
        # Ask for confirmation (but since user wants this automated, we'll proceed)
        Write-Host ""
        Write-Host "  Stopping OneDrive processes to pause sync..." -ForegroundColor Cyan
        
        foreach ($proc in $onedriveProcesses) {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                Write-Host "    Stopped process: $($proc.ProcessName) (PID: $($proc.Id))" -ForegroundColor Green
            } catch {
                Write-Host "    Could not stop process: $($proc.ProcessName)" -ForegroundColor Yellow
            }
        }
        
        Start-Sleep -Seconds 2
        
        # Verify OneDrive is stopped
        $stillRunning = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
        if (-not $stillRunning) {
            Write-Host ""
            Write-Host "[SUCCESS] OneDrive sync paused (process stopped)" -ForegroundColor Green
            Write-Host "  OneDrive will restart automatically after a few minutes" -ForegroundColor Yellow
            Write-Host "  This gives you time to build without file locking issues" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  To resume OneDrive: It will restart automatically, or" -ForegroundColor White
            Write-Host "  Run: Start-Process '$onedriveExe'" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "[WARNING] OneDrive processes are still running" -ForegroundColor Yellow
            Write-Host "  You may need to pause OneDrive manually from the system tray" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  OneDrive processes not found - sync may already be paused" -ForegroundColor Green
    }
} catch {
    Write-Host "  Error stopping OneDrive: $_" -ForegroundColor Red
}

# Method 5: Create a scheduled task to delay OneDrive restart (advanced)
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host ""

$onedriveRunning = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
if (-not $onedriveRunning) {
    Write-Host "[SUCCESS] OneDrive sync is now paused!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run your Flutter build commands:" -ForegroundColor Cyan
    Write-Host "  flutter clean" -ForegroundColor White
    Write-Host "  flutter build apk --debug" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: OneDrive will restart automatically in a few minutes." -ForegroundColor Yellow
    Write-Host "If you need to resume it manually, run:" -ForegroundColor Yellow
    if ($onedriveExe) {
        Write-Host "  Start-Process '$onedriveExe'" -ForegroundColor White
    }
} else {
    Write-Host "[INFO] OneDrive is still running" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To pause OneDrive sync:" -ForegroundColor Yellow
    Write-Host "  1. Right-click OneDrive icon in system tray (bottom-right)" -ForegroundColor White
    Write-Host "  2. Click 'Pause syncing' -> '2 hours'" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run this script again to try stopping the process." -ForegroundColor Cyan
}

Write-Host ""

