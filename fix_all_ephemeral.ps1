# Fix All Flutter Ephemeral Directory Lock Issues
# This script fixes ephemeral directory locks for iOS, macOS, Windows, and Linux

Write-Host ""
Write-Host "=== Fixing All Flutter Ephemeral Directories ===" -ForegroundColor Cyan
Write-Host ""

$scriptRoot = Get-Location | Select-Object -ExpandProperty Path

# Define all ephemeral directories to fix
$ephemeralDirs = @(
    @{Path = "ios\Flutter\ephemeral"; Name = "iOS"},
    @{Path = "macos\Flutter\ephemeral"; Name = "macOS"},
    @{Path = "windows\flutter\ephemeral"; Name = "Windows"},
    @{Path = "linux\flutter\ephemeral"; Name = "Linux"}
)

# Step 1: Stop processes that might be locking files
Write-Host "Step 1: Stopping processes that might lock files..." -ForegroundColor Yellow
$processes = @("dart", "flutter", "java", "gradle", "xcodebuild", "swift")
foreach ($proc in $processes) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "  Stopping $proc processes..." -ForegroundColor Cyan
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 2

# Step 2: Fix each ephemeral directory
$totalFixed = 0
$totalFailed = 0

foreach ($dirInfo in $ephemeralDirs) {
    $relativePath = $dirInfo.Path
    $platformName = $dirInfo.Name
    $fullPath = Join-Path $scriptRoot $relativePath
    
    Write-Host ""
    Write-Host "Fixing $platformName ephemeral directory..." -ForegroundColor Yellow
    Write-Host "  Path: $fullPath" -ForegroundColor Cyan
    
    if (Test-Path $fullPath) {
        # Remove read-only attributes
        try {
            Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                } catch {
                    # Ignore individual file errors
                }
            }
        } catch {
            Write-Host "  Warning: Could not remove all attributes" -ForegroundColor Yellow
        }
        
        # Attempt to delete
        $maxRetries = 5
        $retryCount = 0
        $deleted = $false
        
        while ($retryCount -lt $maxRetries -and -not $deleted) {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Host "  [SUCCESS] $platformName ephemeral directory removed!" -ForegroundColor Green
                $deleted = $true
                $totalFixed++
            } catch {
                $retryCount++
                if ($retryCount -lt $maxRetries) {
                    Write-Host "  Attempt $retryCount/$maxRetries failed. Retrying in 2 seconds..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 2
                    
                    # Try to remove attributes again
                    Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            $_.Attributes = $_.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
                        } catch { }
                    }
                } else {
                    Write-Host "  [FAILED] Could not remove after $maxRetries attempts" -ForegroundColor Red
                    Write-Host "  Error: $_" -ForegroundColor Red
                    $totalFailed++
                }
            }
        }
    } else {
        Write-Host "  Directory doesn't exist - nothing to clean" -ForegroundColor Green
    }
}

# Step 3: Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "  Fixed: $totalFixed directories" -ForegroundColor Green
if ($totalFailed -gt 0) {
    Write-Host "  Failed: $totalFailed directories" -ForegroundColor Red
    Write-Host ""
    Write-Host "[WARNING] OneDrive is likely locking these files!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please do ONE of the following:" -ForegroundColor Yellow
    Write-Host "  1. Run: .\pause_onedrive_auto.ps1" -ForegroundColor White
    Write-Host "  2. Or manually pause OneDrive from system tray" -ForegroundColor White
    Write-Host "  3. Then run this script again: .\fix_all_ephemeral.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  PERMANENT FIX: Exclude ephemeral folders from OneDrive sync" -ForegroundColor Cyan
    Write-Host "  - Right-click OneDrive icon -> Settings -> Sync and backup" -ForegroundColor White
    Write-Host "  - Advanced settings -> Choose folders" -ForegroundColor White
    Write-Host "  - Exclude: ios\Flutter\ephemeral, macos\Flutter\ephemeral, etc." -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "[SUCCESS] All ephemeral directories cleaned!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run:" -ForegroundColor Cyan
    Write-Host "  flutter clean" -ForegroundColor White
    Write-Host "  flutter pub get" -ForegroundColor White
    Write-Host "  flutter build apk --debug" -ForegroundColor White
}

Write-Host ""

