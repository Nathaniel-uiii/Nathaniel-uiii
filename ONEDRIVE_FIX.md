# Fix OneDrive File Locking Issues - PERMANENT SOLUTION

## The Problem
OneDrive is syncing your `build` folder and locking files during Gradle builds, causing build failures.

## ✅ PERMANENT FIX (Choose One):

### Option 1: Exclude Build Folder from OneDrive (RECOMMENDED)

1. **Right-click the OneDrive icon** in system tray
2. Click **Settings** → **Sync and backup** → **Advanced settings**
3. Click **"Choose folders"** or **"Files On-Demand"**
4. Find your project folder: `C:\Users\admin\OneDrive\Desktop\bread`
5. **Uncheck the `build` folder** (or exclude it)
6. Click **OK**

### Option 2: Pause OneDrive During Builds

1. **Right-click OneDrive icon** → **Pause syncing** → **2 hours**
2. Run your build
3. Resume syncing after build completes

### Option 3: Move Project Outside OneDrive (BEST LONG-TERM)

Move your project to a local folder that's NOT synced:

```powershell
# Create local projects folder
New-Item -ItemType Directory -Path "C:\Projects" -Force

# Move project (close Cursor first!)
# Then manually move: C:\Users\admin\OneDrive\Desktop\bread 
# To: C:\Projects\bread
```

**Benefits:**
- No sync conflicts
- Faster builds
- No file locking issues

### Option 4: Use .onedriveignore File

Create a file named `.onedriveignore` in your project root:

```
build/
.dart_tool/
*.iml
.gradle/
```

## 🚀 Quick Fix for Now:

1. **Pause OneDrive sync** (right-click icon → Pause → 2 hours)
2. Run: `.\clean_build.ps1`
3. Run: `flutter build apk --debug`
4. Resume OneDrive after build completes

## 📝 Why This Happens:

OneDrive syncs files in real-time. When Gradle tries to delete/overwrite files in the `build` folder, OneDrive has them locked for syncing, causing the build to fail.

## ✅ Recommended Solution:

**Exclude the `build` folder from OneDrive sync** - This is the best permanent fix. The build folder is generated code and doesn't need to be synced anyway.

