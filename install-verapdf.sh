#!/bin/bash
set -e

INSTALL_DIR="$HOME/verapdf"
BIN_DIR="$HOME/.local/bin"
ADD_SYMLINK=true

for arg in "$@"; do
    case "$arg" in
        --no-symlink)
            ADD_SYMLINK=false
            ;;
        --install-dir=*)
            INSTALL_DIR="${arg#--install-dir=}"
            ;;
        --help|-h)
            echo "Usage: install-verapdf.sh [--install-dir=<path>] [--no-symlink]"
            echo ""
            echo "  --install-dir=<path>  Install to <path> instead of ~/verapdf."
            echo "  --no-symlink          Do not create a symlink in ~/.local/bin."
            exit 0
            ;;
        *)
            echo "Error: unrecognized option '$arg'" >&2
            exit 1
            ;;
    esac
done

# === 0. DEPENDENCY CHECK ===
REQUIRED_TOOLS=("curl" "unzip" "java")
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

if [ -d "$INSTALL_DIR" ]; then
    echo "Updating existing installation at $INSTALL_DIR..."
else
    echo "Installing to $INSTALL_DIR..."
fi

DOWNLOAD_URL="https://software.verapdf.org/dev/verapdf-installer.zip"
curl -fSL "$DOWNLOAD_URL" -o verapdf-installer.zip

# verapdf-snapshot is our own scratch workspace, cleaned up at the end
# either way -- safe to always start fresh, unlike INSTALL_DIR itself.
rm -rf verapdf-snapshot
unzip -q verapdf-installer.zip -d verapdf-snapshot

cd verapdf-snapshot/verapdf-greenfield-*/

# Avoid parsing ls: if the glob matches nothing, nullglob leaves the
# array empty instead of a literal, unexpanded pattern -- the check
# below catches that case.
shopt -s nullglob
jar_candidates=(verapdf-izpack-installer-*.jar)
shopt -u nullglob

if [ "${#jar_candidates[@]}" -ne 1 ]; then
    echo "Error: expected exactly one installer .jar, found ${#jar_candidates[@]}" >&2
    exit 1
fi
JAR_FILE="${jar_candidates[0]}"

cat << EOF > auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
        <installpath>$INSTALL_DIR</installpath>
    </com.izforge.izpack.panels.target.TargetPanel>
    <com.izforge.izpack.panels.packs.PacksPanel id="packs">
        <pack index="0" name="veraPDF CLI" selected="true"/>
        <pack index="1" name="veraPDF GUI" selected="false"/>
    </com.izforge.izpack.panels.packs.PacksPanel>
    <com.izforge.izpack.panels.install.InstallPanel id="install"/>
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
</AutomatedInstallation>
EOF

java -jar "$JAR_FILE" auto-install.xml

# === VERIFY INSTALLATION ===
if [ ! -x "$INSTALL_DIR/verapdf" ]; then
    echo "Error: installation appears to have failed -- $INSTALL_DIR/verapdf not found" >&2
    exit 1
fi

# === SYMLINK ===
if [ "$ADD_SYMLINK" = true ]; then
    mkdir -p "$BIN_DIR"
    if [ -L "$BIN_DIR/verapdf" ]; then
        echo "Replacing existing symlink at $BIN_DIR/verapdf"
    elif [ -e "$BIN_DIR/verapdf" ]; then
        echo "Warning: $BIN_DIR/verapdf already exists and is not a symlink -- replacing it anyway"
    fi
    rm -f "$BIN_DIR/verapdf"
    ln -s "$INSTALL_DIR/verapdf" "$BIN_DIR/verapdf"
    echo "veraPDF installed to $INSTALL_DIR. Symlinked to $BIN_DIR/verapdf."
else
    echo "veraPDF installed to $INSTALL_DIR (no symlink created, --no-symlink)."
    echo "Call it directly, or add this to your PATH yourself:"
    echo "  $INSTALL_DIR"
fi
# =========================

cd ../..
rm -f verapdf-installer.zip
rm -rf verapdf-snapshot

echo "Installation completed successfully."
