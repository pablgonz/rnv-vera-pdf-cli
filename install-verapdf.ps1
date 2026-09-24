$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\verapdf"

# Only direct invocation (not irm | iex) can pass --install-dir.
foreach ($a in $args) {
    switch -Regex ($a) {
        '^--install-dir=(.*)$' { $InstallDir = $Matches[1] }
        '^--help$' {
            Write-Host "Usage: install-verapdf.ps1 [--install-dir=<path>]"
            Write-Host ""
            Write-Host "  --install-dir=<path>  Install to <path> instead of"
            Write-Host "                        $env:USERPROFILE\verapdf. Still added"
            Write-Host "                        to the user PATH."
            exit 0
        }
        default {
            Write-Error "Error: unrecognized option '$a'"
            exit 1
        }
    }
}

# === 0. DEPENDENCY CHECK ===
$RequiredTools = @("java")
$MissingTools = @()

foreach ($Tool in $RequiredTools) {
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) {
        $MissingTools += $Tool
    }
}

if ($MissingTools.Count -gt 0) {
    Write-Host "Error: The following required tools are missing: $($MissingTools -join ', ')" -ForegroundColor Red
    Write-Host "Please install Java (JRE or JDK), ensure it is added to your system PATH, and try again." -ForegroundColor Yellow
    exit 1
}
# ===========================

Write-Host "All dependencies met. Proceeding with installation..."

if (Test-Path $InstallDir) {
    Write-Host "Updating existing installation at $InstallDir..."
} else {
    Write-Host "Installing to $InstallDir..."
}

# Download the installer
$DownloadUrl = "https://software.verapdf.org/dev/verapdf-installer.zip"
Invoke-WebRequest -Uri $DownloadUrl -OutFile "verapdf-installer.zip"

# verapdf-snapshot is scratch space, always safe to start fresh.
if (Test-Path "verapdf-snapshot") { Remove-Item -Recurse -Force "verapdf-snapshot" }
Expand-Archive -Path "verapdf-installer.zip" -DestinationPath "verapdf-snapshot" -Force

# Get the installer JAR
$JarFile = Get-ChildItem -Path "verapdf-snapshot\verapdf-greenfield-*\verapdf-izpack-installer-*.jar" | Select-Object -First 1
if (-not $JarFile) {
    Write-Error "Error: no installer .jar found matching verapdf-izpack-installer-*.jar"
    exit 1
}

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

# === VERIFY INSTALLATION ===
$VeraPdfBin = Join-Path $InstallDir "verapdf.bat"
if (-not (Test-Path $VeraPdfBin)) {
    Write-Error "Error: installation appears to have failed -- $VeraPdfBin not found"
    exit 1
}
# ============================

# === PATH CONFIGURATION ===
if ($env:GITHUB_ACTIONS) {
    Add-Content -Path $env:GITHUB_PATH -Value $InstallDir
} else {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "veraPDF installed locally. Added $InstallDir to user PATH."
    } else {
        Write-Host "veraPDF installed to $InstallDir (already in PATH)."
    }
}
# =====================================

# Cleanup temporary files
Remove-Item "verapdf-installer.zip" -Force
Remove-Item "verapdf-snapshot" -Recurse -Force
Remove-Item "auto-install.xml" -Force

Write-Host "Installation completed successfully."
