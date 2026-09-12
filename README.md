# rnv and vera-pdf cli tools

This repository provides installation scripts and precompiled binaries for Tagged-PDF validation tools for TL2026.

## What we offer

We compile and distribute a statically linked version of `rnv` (Relax NG Validator), built directly from its original source code without any modifications. We package this static binary alongside our custom Lua wrapper (`rnv-wrapp`). This wrapper simplifies the validation of XML structures against specific PDF schemas.

We also provide automated installers for `veraPDF` (command-line interface) to test PDF/UA compliance.

## Quick Installation

Open your terminal and run the command for your operating system. The scripts will download the required files, extract them, and configure your PATH automatically.

### 1. Install rnv-wrapp

**Linux / macOS (Bash):**
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.ps1" | Invoke-Expression
```

### 2. Install veraPDF (CLI)

*Note: Java must be installed on your system to run veraPDF.*

**Linux / macOS (Bash):**
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.ps1" | Invoke-Expression
```

## Important Note

After the installation finishes, you must close and reopen your terminal for the changes to take effect. On Linux, you can also run `source ~/.bashrc` or `source ~/.zshrc` to reload your PATH immediately.

## Repository Structure

* `install-*.sh` / `.ps1`: Standalone installation scripts.
* `rnv-wrapp.lua`: The main Lua wrapper logic.
* `x64_linux/`: Precompiled ZIP archives and SHA256 checksums for Linux.
* `x64_windows/`: Precompiled ZIP archives and SHA256 checksums for Windows.
