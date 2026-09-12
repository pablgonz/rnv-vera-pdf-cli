$ErrorActionPreference = "Stop"

# Define directories based on the environment
if ($env:GITHUB_ACTIONS) {
    $InstallDir = "$env:USERPROFILE\verapdf"
} else {
    $InstallDir = "$env:USERPROFILE\verapdf"
}

# Download the installer
$DownloadUrl = "https://software.verapdf.org/dev/verapdf-installer.zip"
Invoke-WebRequest -Uri $DownloadUrl -OutFile "verapdf-installer.zip"

# Extract the installer
if (Test-Path "verapdf-snapshot") { Remove-Item -Recurse -Force "verapdf-snapshot" }
Expand-Archive -Path "verapdf-installer.zip" -DestinationPath "verapdf-snapshot" -Force

# Get the installer JAR
$JarFile = Get-ChildItem -Path "verapdf-snapshot\verapdf-greenfield-*\verapdf-izpack-installer-*.jar" | Select-Object -First 1

# Create the silent installation XML
$XmlContent = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
        <installpath>$InstallDir</installpath>
    </com.izforge.izpack.panels.target.TargetPanel>
    <com.izforge.izpack.panels.packs.PacksPanel id="packs">
        <pack index="0" name="veraPDF CLI" selected="true"/>
        <pack index="1" name="veraPDF GUI" selected="false"/>
    </com.izforge.izpack.panels.packs.PacksPanel>
    <com.izforge.izpack.panels.install.InstallPanel id="install"/>
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
</AutomatedInstallation>
"@

Set-Content -Path "auto-install.xml" -Value $XmlContent -Encoding UTF8

# Run the installation
java -jar $JarFile.FullName auto-install.xml

# === LOCAL CONFIGURATION (WINDOWS) ===
# If running locally, register veraPDF in the User PATH
if (-not $env:GITHUB_ACTIONS) {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "veraPDF installed locally. Added $InstallDir to user PATH."
    }
}
# =====================================

# Cleanup temporary files
Remove-Item "verapdf-installer.zip" -Force
Remove-Item "verapdf-snapshot" -Recurse -Force
Remove-Item "auto-install.xml" -Force
