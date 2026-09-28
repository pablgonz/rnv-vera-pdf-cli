#!/bin/bash
set -e

show_help() {
    echo "Usage: install-rnv.sh --unattended | --install-dir[=<path>]"
    echo ""
    echo "  --unattended          Install to $HOME/.local/bin/rnv-wrapp"
    echo "                        (or --install-dir's value, if also given)"
    echo "                        and add it to PATH automatically, without"
    echo "                        asking anything."
    echo "  --install-dir=<path>  Install to <path> instead of the default."
    echo "                        Never touches PATH on its own -- prints"
    echo "                        the line to add yourself, unless combined"
    echo "                        with --unattended."
    echo "  --install-dir         Same, but without a path: prompts for one"
    echo "                        interactively (only works when run from a"
    echo "                        real terminal, not through a pipe)."
}

# Default install location follows the systemd File Hierarchy
# Specification for per-user executables:
# "~/.local/bin/ -- Executables that shall appear in the user's $PATH
# search path." (freedesktop.org, file-hierarchy.html, Home Directory)
INSTALL_DIR="$HOME/.local/bin/rnv-wrapp"
UNATTENDED=false
PROMPT_FOR_INSTALL_DIR=false

if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

for arg in "$@"; do
    case "$arg" in
        --unattended)
            UNATTENDED=true
            ;;
        --install-dir=*)
            INSTALL_DIR="${arg#--install-dir=}"
            ;;
        --install-dir)
            PROMPT_FOR_INSTALL_DIR=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Error: unrecognized option '$arg'" >&2
            exit 1
            ;;
    esac
done

if [ "$PROMPT_FOR_INSTALL_DIR" = true ]; then
    if [ -t 0 ]; then
        read -r -p "Install directory [$INSTALL_DIR]: " user_dir
        INSTALL_DIR="${user_dir:-$INSTALL_DIR}"
    else
        echo "Error: '--install-dir' with no value needs a real terminal to ask for one." >&2
        echo "Pass '--install-dir=<path>' instead when running non-interactively." >&2
        exit 1
    fi
fi

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
# Only --unattended ever touches PATH on its own; otherwise, the
# exact line to add is printed and left for the user to decide.
NEEDS_SOURCE_HINT=false
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "$INSTALL_DIR" >> "$GITHUB_PATH"
elif [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo "rnv-wrapp installed to $INSTALL_DIR (already in PATH)."
elif [ "$UNATTENDED" = true ]; then
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
    echo "rnv-wrapp installed to $INSTALL_DIR."
    echo "Add this to your shell's rc file to use it by name:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi
# =================================

rm -f "rnv-wrapp-linux.zip"
if [ "$NEEDS_SOURCE_HINT" = true ]; then
    echo "Installation completed successfully. (Run 'source $SHELL_RC' or restart your terminal to use it now.)"
else
    echo "Installation completed successfully."
fi
