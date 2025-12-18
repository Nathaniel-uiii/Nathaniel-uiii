# Clean Build Script - Fixes OneDrive file locking issues
Write-Host "Stopping all Java/Gradle processes..." -ForegroundColor Yellow
taskkill /F /IM java.exe /T 2>$null
taskkill /F /IM gradle.exe /T 2>$null
taskkill /F /IM dart.exe /T 2>$null
Start-Sleep -Seconds 2

Write-Host "Stopping Gradle daemon..." -ForegroundColor Yellow
cd android
.\gradlew --stop 2>$null
cd ..

Write-Host "Removing build directories..." -ForegroundColor Yellow
$buildDirs = @("build", ".dart_tool")
foreach ($dir in $buildDirs) {
    if (Test-Path $dir) {
        Write-Host "Removing $dir..." -ForegroundColor Cyan
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }
}

Write-Host "`nIMPORTANT: OneDrive is likely locking files!" -ForegroundColor Red
Write-Host "Please do ONE of the following:" -ForegroundColor Yellow
Write-Host "1. Right-click OneDrive icon -> Pause syncing -> 2 hours" -ForegroundColor White
Write-Host "2. Or exclude the 'build' folder from OneDrive sync" -ForegroundColor White
Write-Host "`nAfter pausing OneDrive, run: flutter build apk --debug" -ForegroundColor Green

