#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin/rnv-wrapp"
ADD_TO_PATH=true

for arg in "$@"; do
    case "$arg" in
        --no-path)
            ADD_TO_PATH=false
            ;;
        --install-dir=*)
            INSTALL_DIR="${arg#--install-dir=}"
            ADD_TO_PATH=false
            ;;
        --help|-h)
            echo "Usage: install-rnv-wrapp.sh [--install-dir=<path>] [--no-path]"
            echo ""
            echo "  --install-dir=<path>  Install to <path> instead of"
            echo "                        ~/.local/bin/rnv-wrapp. Implies"
            echo "                        --no-path (see below)."
            echo "  --no-path             Do not modify ~/.bashrc or ~/.zshrc to"
            echo "                        add the install dir to PATH. Implied"
            echo "                        by --install-dir, but can also be used"
            echo "                        on its own with the default install"
            echo "                        dir. Has no effect under GitHub"
            echo "                        Actions, which always uses GITHUB_PATH."
            exit 0
            ;;
        *)
            echo "Error: unrecognized option '$arg'" >&2
            exit 1
            ;;
    esac
done

# === 0. DEPENDENCY CHECK ===
REQUIRED_TOOLS=("curl" "unzip" "gpg" "sha256sum")
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Error: The following required tools are missing:"
    echo "  ${MISSING_TOOLS[*]}"
    echo "Please install them using your distribution's package manager and try again."
    exit 1
fi
# ===========================

REPO_URL="https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main"
BASE_URL="$REPO_URL/x64_linux"

# 1. Download ZIP and signature artifacts (CI or Remote Mode)
if [ -n "$LOCAL_ZIP_PATH" ]; then
    echo "CI Mode: Using local files from $(dirname "$LOCAL_ZIP_PATH")"
    BASE_DIR="$(dirname "$LOCAL_ZIP_PATH")"
    cp "$BASE_DIR/rnv-wrapp-linux.zip" "rnv-wrapp-linux.zip"
    cp "$BASE_DIR/checksums.sha256" "checksums.sha256"
    cp "$BASE_DIR/rnv-wrapp-linux.zip.sig" "rnv-wrapp-linux.zip.sig"
    if [ ! -f "pubkey.asc" ]; then
        cp "$(dirname "$BASE_DIR")/pubkey.asc" "pubkey.asc"
    fi
else
    echo "Downloading rnv-wrapp and verification artifacts..."
    curl -fsSL "$BASE_URL/rnv-wrapp-linux.zip" -o "rnv-wrapp-linux.zip"
    curl -fsSL "$BASE_URL/checksums.sha256" -o "checksums.sha256"
    curl -fsSL "$BASE_URL/rnv-wrapp-linux.zip.sig" -o "rnv-wrapp-linux.zip.sig"
    curl -fsSL "$REPO_URL/pubkey.asc" -o "pubkey.asc"
fi

# === 2. INTEGRITY AND DIGITAL SIGNATURE VERIFICATION ===
echo "Verifying SHA-256 checksum..."
sha256sum -c checksums.sha256

echo "Verifying GPG signature..."
export GNUPGHOME="$(mktemp -d)"
gpg --batch --import pubkey.asc > /dev/null 2>&1

if gpg --batch --verify rnv-wrapp-linux.zip.sig rnv-wrapp-linux.zip > /dev/null 2>&1; then
    echo "Signature verification SUCCESSFUL (Verified OK)."
else
    echo "Error: Digital signature verification FAILED! Aborting installation."
    rm -rf "$GNUPGHOME"
    rm -f rnv-wrapp-linux.zip* checksums.sha256 pubkey.asc
    exit 1
fi
rm -rf "$GNUPGHOME"

# Cleanup temporary verification files
rm -f rnv-wrapp-linux.zip.sig checksums.sha256 pubkey.asc
# ====================================================

# 3. Extract and install -- never wipe the whole directory: mkdir -p
# is a no-op if it already exists, and "unzip -o" only overwrites the
# files that are part of this package, leaving anything else in
# INSTALL_DIR untouched.
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation at $INSTALL_DIR..."
else
    echo "Installing to $INSTALL_DIR..."
fi
mkdir -p "$INSTALL_DIR"
unzip -oq "rnv-wrapp-linux.zip" -d "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/rnv" "$INSTALL_DIR/rnv-wrapp" "$INSTALL_DIR/rnv-wrapp.lua"

# === 4. PATH CONFIGURATION ===
NEEDS_SOURCE_HINT=false
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "$INSTALL_DIR" >> "$GITHUB_PATH"
elif [ "$ADD_TO_PATH" = true ]; then
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        # $ZSH_VERSION is only set inside an actual zsh session, never
        # inside a script started with #!/bin/bash -- use $SHELL (the
        # user's own default shell) instead.
        SHELL_RC="$HOME/.bashrc"
        case "$SHELL" in
            */zsh) SHELL_RC="$HOME/.zshrc" ;;
        esac

        echo -e "\nexport PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
        echo "rnv-wrapp installed. Added $INSTALL_DIR to PATH in $SHELL_RC."
        NEEDS_SOURCE_HINT=true
    else
        echo "rnv-wrapp installed to $INSTALL_DIR (already in PATH)."
    fi
else
    echo "rnv-wrapp installed to $INSTALL_DIR (PATH not modified, --no-path)."
    echo "To use it, add this to your shell's rc file yourself:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi
# =================================

rm -f "rnv-wrapp-linux.zip"
if [ "$NEEDS_SOURCE_HINT" = true ]; then
    echo "Installation completed successfully. (Run 'source $SHELL_RC' or restart your terminal to use it now.)"
else
    echo "Installation completed successfully."
fi
