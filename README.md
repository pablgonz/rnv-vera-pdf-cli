# rnv and vera-pdf cli tools

This repository provides installation scripts and precompiled binaries for Tagged-PDF validation tools for TL2026.

## What we offer

We compile and distribute a statically linked version of `rnv` (Relax NG Validator, v1.7.11), built directly from the official maintained repository (`hartwork/rnv`) using GNU Autotools. We package this static binary alongside our custom Lua wrapper (`rnv-wrapp`), which simplifies the validation of XML structures against specific PDF schemas.

We also provide automated installers for `veraPDF` (command-line interface) to test PDF/UA compliance.

## Quick Installation

Run the command for your operating system. `--unattended` installs to a default location and adds it to PATH automatically, without asking anything — restart your terminal afterwards (or, on Linux/macOS, run `source ~/.bashrc` or `source ~/.zshrc`) to use the new command right away.

Run any installer with no arguments to see its full set of options, including how to pick a different install location or skip touching PATH.

### 1. Install rnv-wrapp

**Linux / macOS (Bash):** installs to `~/.local/bin/rnv-wrapp`.
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.sh | bash -s -- --unattended
```

**Windows (PowerShell):** installs to `%USERPROFILE%\rnv-wrapp`. The one-liner below can't pass `--unattended` through the pipe — download the script and run it with the flag instead.
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-rnv.ps1" -OutFile install-rnv.ps1
.\install-rnv.ps1 --unattended
```

### 2. Install veraPDF (CLI)

*Note: Java must be installed on your system to run veraPDF.*

**Linux / macOS (Bash):** installs to `~/verapdf`, with a symlink in `~/.local/bin`.
```bash
curl -sSL https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.sh | bash -s -- --unattended
```

**Windows (PowerShell):** installs to `%USERPROFILE%\verapdf`.
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/install-verapdf.ps1" -OutFile install-verapdf.ps1
.\install-verapdf.ps1 --unattended
```

## Custom Install Location

Without `--unattended`, an installer never touches PATH on its own — it prints the exact line (Linux/macOS) or command (Windows) to run yourself.

`--install-dir=<path>` picks a different install location. Combine it with `--unattended` for a fully automatic install elsewhere; on its own, it installs there but leaves PATH alone. `--install-dir` with no path prompts for one interactively — only works when run from a real terminal, not through a pipe.

```bash
# Custom location, still automatic
./install-rnv.sh --unattended --install-dir=/opt/rnv

# Custom location, PATH left for you to configure
./install-rnv.sh --install-dir=/opt/rnv

# Prompts for a location (terminal only)
./install-rnv.sh --install-dir
```

```powershell
.\install-rnv.ps1 --unattended --install-dir=C:\Tools\rnv
.\install-rnv.ps1 --install-dir=C:\Tools\rnv
.\install-rnv.ps1 --install-dir
```

The same three forms work for `install-verapdf.sh`/`.ps1`. On Linux/macOS, `install-verapdf.sh` also takes `--no-symlink`, to skip the `~/.local/bin` symlink even under `--unattended`.

## Security & Code Signing

Releases are cryptographically signed during our automated GitHub Actions CI/CD pipeline, and verified by the installer before extracting anything.

* **Linux:** `rnv-wrapp-linux.zip` is signed with **GPG** (detached, armored signature) using a project signing key. `install-rnv.sh` downloads the checksum, the signature, and our public key (`pubkey.asc`, published at the root of this repository), then verifies both the SHA-256 checksum and the GPG signature before extracting any files. If verification fails, installation is aborted.
* **Windows:** code signing for the Windows binaries is not yet in place — it's planned via Certum. Until then, integrity is not cryptographically verified on Windows.

To verify a release yourself:
```bash
curl -O https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/pubkey.asc
curl -O https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_linux/rnv-wrapp-linux.zip
curl -O https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_linux/rnv-wrapp-linux.zip.sig
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
