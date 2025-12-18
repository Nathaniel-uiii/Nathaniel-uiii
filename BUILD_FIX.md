# Fixing Build File Lock Issues on Windows/OneDrive

## Problem
Gradle build fails with "Unable to delete directory" errors because files are locked.

## Solutions (Try in order):

### Solution 1: Pause OneDrive Sync (RECOMMENDED)
1. Right-click OneDrive icon in system tray
2. Click "Pause syncing" → "2 hours" or "24 hours"
3. Try building again
4. Resume syncing after build completes

### Solution 2: Exclude Build Folder from OneDrive
1. Right-click OneDrive icon → Settings
2. Go to "Sync and backup" → "Advanced settings"
3. Click "Choose folders"
4. Uncheck the `build` folder if it's being synced
5. Or add `build/` to OneDrive exclusions

### Solution 3: Close All IDEs and File Explorers
1. Close Cursor/VS Code completely
2. Close any File Explorer windows showing the project
3. Stop all Java/Gradle processes:
   ```powershell
   taskkill /F /IM java.exe /T
   taskkill /F /IM gradle.exe /T
   ```
4. Try building again

### Solution 4: Build Without Daemon
The gradle.properties has been updated to disable daemon. If issues persist:
```powershell
cd android
.\gradlew --no-daemon clean
cd ..
flutter build apk --debug
```

### Solution 5: Move Project Outside OneDrive
If all else fails, move the project to a local folder (not synced):
- `C:\Projects\bread` instead of `C:\Users\admin\OneDrive\Desktop\bread`

## Quick Fix Commands
```powershell
# Stop all processes
taskkill /F /IM java.exe /T
taskkill /F /IM gradle.exe /T
cd android; .\gradlew --stop; cd ..

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

