$ErrorActionPreference = "Stop"

function Show-Help {
    Write-Host "Usage: install-rnv.ps1 --unattended | --install-dir[=<path>]"
    Write-Host ""
    Write-Host "  --unattended          Install to $env:USERPROFILE\rnv-wrapp"
    Write-Host "                        (or --install-dir's value, if also given)"
    Write-Host "                        and add it to the user PATH automatically,"
    Write-Host "                        without asking anything."
    Write-Host "  --install-dir=<path>  Install to <path> instead of the default."
    Write-Host "                        Never touches PATH on its own -- prints"
    Write-Host "                        the command to run yourself, unless"
    Write-Host "                        combined with --unattended."
    Write-Host "  --install-dir         Same, but without a path: prompts for one"
    Write-Host "                        interactively (only works when run from a"
    Write-Host "                        real terminal, not through a pipe)."
}

$InstallDir = "$env:USERPROFILE\rnv-wrapp"
$Unattended = $false
$PromptForInstallDir = $false

if ($args.Count -eq 0) {
    Show-Help
    exit 0
}

# Only direct invocation (not irm | iex) can pass arguments.
foreach ($a in $args) {
    switch -Regex ($a) {
        '^--unattended$' { $Unattended = $true }
        '^--install-dir=(.*)$' { $InstallDir = $Matches[1] }
        '^--install-dir$' { $PromptForInstallDir = $true }
        '^--help$' {
            Show-Help
            exit 0
        }
        default {
            Write-Error "Error: unrecognized option '$a'"
            exit 1
        }
    }
}

if ($PromptForInstallDir) {
    if (-not [Console]::IsInputRedirected) {
        $userDir = Read-Host "Install directory [$InstallDir]"
        if ($userDir) { $InstallDir = $userDir }
    } else {
        Write-Error "'--install-dir' with no value needs a real terminal to ask for one. Pass '--install-dir=<path>' instead when running non-interactively."
        exit 1
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
# Only --unattended ever touches PATH on its own; otherwise, a ready
# to paste command is printed and left for the user to run.
if ($env:GITHUB_ACTIONS) {
    Add-Content -Path $env:GITHUB_PATH -Value $InstallDir
} else {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -like "*$InstallDir*") {
        Write-Host "rnv-wrapp installed to $InstallDir (already in PATH)."
    } elseif ($Unattended) {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "rnv-wrapp installed. Added $InstallDir to user PATH."
    } else {
        Write-Host "rnv-wrapp installed to $InstallDir."
        Write-Host "Run this to add it to your user PATH:"
        Write-Host "  [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$InstallDir', 'User')"
    }
}
# ==========================

Remove-Item "rnv-wrapp-windows.zip" -Force
Write-Host "Installation completed successfully. (Restart your terminal if running locally.)"
