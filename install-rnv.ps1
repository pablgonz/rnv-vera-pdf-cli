$ErrorActionPreference = "Stop"

$InstallDir = "$env:USERPROFILE\rnv-wrapp"

# Only direct invocation (not irm | iex) can pass --install-dir.
foreach ($a in $args) {
    switch -Regex ($a) {
        '^--install-dir=(.*)$' { $InstallDir = $Matches[1] }
        '^--help$' {
            Write-Host "Usage: install-rnv.ps1 [--install-dir=<path>]"
            Write-Host ""
            Write-Host "  --install-dir=<path>  Install to <path> instead of"
            Write-Host "                        $env:USERPROFILE\rnv-wrapp. Still added"
            Write-Host "                        to the user PATH."
            exit 0
        }
        default {
            Write-Error "Error: unrecognized option '$a'"
            exit 1
        }
    }
}

# Download precompiled ZIP (or use local file if in GitHub Actions CI)
if ($env:LOCAL_ZIP_PATH) {
    Write-Host "CI Mode: Using local file $env:LOCAL_ZIP_PATH"
    Copy-Item -Path $env:LOCAL_ZIP_PATH -Destination "rnv-wrapp-windows.zip" -Force
} else {
    $DownloadUrl = "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_windows/rnv-wrapp-windows.zip"
    Write-Host "Downloading rnv-wrapp..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "rnv-wrapp-windows.zip"
}

# -Force on Expand-Archive only overwrites files in the package, leaving anything else in InstallDir untouched.
if (Test-Path $InstallDir) {
    Write-Host "Updating existing installation at $InstallDir..."
} else {
    Write-Host "Installing to $InstallDir..."
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Expand-Archive -Path "rnv-wrapp-windows.zip" -DestinationPath $InstallDir -Force

# === VERIFY EXTRACTION ===
$RnvBin = Join-Path $InstallDir "rnv.exe"
if (-not (Test-Path $RnvBin)) {
    Write-Error "Error: extraction appears to have failed -- $RnvBin not found (check for a nested folder inside the zip)"
    exit 1
}
# ==========================

# === PATH CONFIGURATION ===
if ($env:GITHUB_ACTIONS) {
    Add-Content -Path $env:GITHUB_PATH -Value $InstallDir
} else {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "rnv-wrapp installed. Added $InstallDir to user PATH."
    } else {
        Write-Host "rnv-wrapp installed to $InstallDir (already in PATH)."
    }
}
# ==========================

Remove-Item "rnv-wrapp-windows.zip" -Force
Write-Host "Installation completed successfully. (Restart your terminal if running locally.)"
