# rnv and vera-pdf cli tools

This repository provides installation scripts and precompiled binaries for Tagged-PDF validation tools for TL2026.

## What we offer

We compile and distribute a statically linked version of `rnv` (Relax NG Validator, v1.7.11), built directly from the official maintained repository (`hartwork/rnv`) using GNU Autotools. We package this static binary alongside our custom Lua wrapper (`rnv-wrapp`), which simplifies the validation of XML structures against specific PDF schemas.

We also provide automated installers for `veraPDF` (command-line interface) to test PDF/UA compliance.

## Quick Installation

Run the command for your operating system. Each installer downloads the required files, extracts them to a default location, and adds that location to your PATH — restart your terminal afterwards (or, on Linux/macOS, run `source ~/.bashrc` or `source ~/.zshrc`) to use the new command right away.

### 1. Install rnv-wrapp

**Linux / macOS (Bash):** installs to `~/.local/bin/rnv-wrapp`.
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.sh | bash
```

**Windows (PowerShell):** installs to `%USERPROFILE%\rnv-wrapp`.
```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.ps1" | Invoke-Expression
```

### 2. Install veraPDF (CLI)

*Note: Java must be installed on your system to run veraPDF.*

**Linux / macOS (Bash):** installs to `~/verapdf`, with a symlink in `~/.local/bin`.
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.sh | bash
```

**Windows (PowerShell):** installs to `%USERPROFILE%\verapdf`.
```powershell
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.ps1" | Invoke-Expression
```

## Custom Install Location

Download the installer first, then run it with options — a one-liner pipe doesn't make sense once you're making a deliberate choice like a custom path.

### 1. rnv-wrapp

**Linux / macOS:** `--install-dir=<path>` installs elsewhere instead of `~/.local/bin/rnv-wrapp`; PATH is left for you to configure.
```bash
curl -o install-rnv.sh https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.sh
chmod +x install-rnv.sh
./install-rnv.sh --install-dir=/opt/rnv
```

**Windows:** `--install-dir=<path>` installs elsewhere instead of `%USERPROFILE%\rnv-wrapp`. Still added to PATH.
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.ps1" -OutFile install-rnv.ps1
.\install-rnv.ps1 --install-dir=C:\Tools\rnv
```

### 2. veraPDF

**Linux / macOS:** `--install-dir=<path>` installs elsewhere instead of `~/verapdf`; the symlink in `~/.local/bin` is still created. Use `--no-symlink` to skip it.
```bash
curl -o install-verapdf.sh https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.sh
chmod +x install-verapdf.sh
./install-verapdf.sh --install-dir=/opt/verapdf
```

**Windows:** `--install-dir=<path>` installs elsewhere instead of `%USERPROFILE%\verapdf`. Still added to PATH.
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.ps1" -OutFile install-verapdf.ps1
.\install-verapdf.ps1 --install-dir=C:\Tools\verapdf
```

Pass `--help` to any of the four installers for the full list of options.

## Security & Code Signing

Releases are cryptographically signed during our automated GitHub Actions CI/CD pipeline, and verified by the installer before extracting anything.

* **Linux:** `rnv-wrapp-linux.zip` is signed with **GPG** (detached, armored signature) using a project signing key. `install-rnv.sh` downloads the checksum, the signature, and our public key (`pubkey.asc`, published at the root of this repository), then verifies both the SHA-256 checksum and the GPG signature before extracting any files. If verification fails, installation is aborted.
* **Windows:** code signing for the Windows binaries is not yet in place — it's planned via Certum. Until then, integrity is not cryptographically verified on Windows.

To verify a release yourself:
```bash
gpg --import pubkey.asc
gpg --verify rnv-wrapp-linux.zip.sig rnv-wrapp-linux.zip
```

`veraPDF` is downloaded directly from the official upstream project and is not re-signed by us; we don't compile it ourselves.

## Repository Structure

* `install-*.sh` / `.ps1`: Standalone installation scripts.
* `rnv-wrapp.lua`: The main Lua wrapper logic. `rnv-wrapp` (Linux/macOS) and `rnv-wrapp.cmd` (Windows) are thin launchers generated at build time.
* `pubkey.asc`: Public GPG key used to verify Linux releases.
* `x64_linux/`: Precompiled ZIP archive, SHA-256 checksum, and GPG signature for Linux.
* `x64_windows/`: Precompiled ZIP archive and SHA-256 checksum for Windows.
