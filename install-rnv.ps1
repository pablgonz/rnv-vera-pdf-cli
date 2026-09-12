$ErrorActionPreference = "Stop"
$InstallDir = "$env:USERPROFILE\rnv-wrapp"

# Download precompiled ZIP (or use local file if in GitHub Actions CI)
if ($env:LOCAL_ZIP_PATH) {
    Write-Host "CI Mode: Using local file $env:LOCAL_ZIP_PATH"
    Copy-Item -Path $env:LOCAL_ZIP_PATH -Destination "rnv-wrapp-windows.zip" -Force
} else {
    $DownloadUrl = "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_windows/rnv-wrapp-windows.zip"
    Write-Host "Downloading rnv-wrapp..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "rnv-wrapp-windows.zip"
}

# Extract the installer
if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
Expand-Archive -Path "rnv-wrapp-windows.zip" -DestinationPath $InstallDir -Force

# === PATH CONFIGURATION ===
if ($env:GITHUB_ACTIONS) {
    Add-Content -Path $env:GITHUB_PATH -Value $InstallDir
} else {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "rnv-wrapp installed locally. Added $InstallDir to user PATH."
    }
}
# ==========================

Remove-Item "rnv-wrapp-windows.zip" -Force
Write-Host "Installation completed successfully. (Restart your terminal if running locally)."
