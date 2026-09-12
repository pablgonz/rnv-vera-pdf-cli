#!/bin/bash
set -e
INSTALL_DIR="$HOME/.local/bin/rnv-wrapp"

# Descargar el ZIP precompilado (o usar uno local si estamos probando en Actions)
if [ -n "$LOCAL_ZIP_PATH" ]; then
    echo "Modo CI: Usando archivo local $LOCAL_ZIP_PATH"
    cp "$LOCAL_ZIP_PATH" "rnv-wrapp-linux.zip"
else
    ZIP_URL="https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_linux/rnv-wrapp-linux.zip"
    echo "Descargando rnv-wrapp..."
    curl -sSL "$ZIP_URL" -o "rnv-wrapp-linux.zip"
fi

# Extraer el instalador
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
unzip -q "rnv-wrapp-linux.zip" -d "$INSTALL_DIR"

chmod +x "$INSTALL_DIR/rnv" "$INSTALL_DIR/rnv-wrapp" "$INSTALL_DIR/rnv-wrapp.lua"

# === CONFIGURACIÓN DE PATH ===
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "$INSTALL_DIR" >> "$GITHUB_PATH"
else
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        SHELL_RC="$HOME/.bashrc"
        [ -n "$ZSH_VERSION" ] && SHELL_RC="$HOME/.zshrc"

        echo -e "\nexport PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_RC"
        echo "rnv-wrapp instalado. Se agregó $INSTALL_DIR al PATH en $SHELL_RC."
    fi
fi
# =============================

rm "rnv-wrapp-linux.zip"
echo "Instalación completada con éxito."
