#!/bin/bash
set -e
INSTALL_DIR="$HOME/.local/bin/rnv-wrapp"

# Download precompiled ZIP (or use local file if in GitHub Actions CI)
if [ -n "$LOCAL_ZIP_PATH" ]; then
    echo "CI Mode: Using local file $LOCAL_ZIP_PATH"
    cp "$LOCAL_ZIP_PATH" "rnv-wrapp-linux.zip"
else
    ZIP_URL="https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_linux/rnv-wrapp-linux.zip"
    echo "Downloading rnv-wrapp..."
    curl -sSL "$ZIP_URL" -o "rnv-wrapp-linux.zip"
fi

# Extract the installer
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "rnv-wrapp-linux.zip" -d "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/rnv" "$INSTALL_DIR/rnv-wrapp" "$INSTALL_DIR/rnv-wrapp.lua"

# === PATH CONFIGURATION ===
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "$INSTALL_DIR" >> "$GITHUB_PATH"
else
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        SHELL_RC="$HOME/.bashrc"
        [ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

        echo -e "\nexport PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
        echo "rnv-wrapp installed. Added $INSTALL_DIR to PATH in $SHELL_RC."
    fi
fi
# ==========================

rm "rnv-wrapp-linux.zip"
echo "Installation completed successfully. (Run 'source ~/.bashrc' or restart your terminal if running locally)."
