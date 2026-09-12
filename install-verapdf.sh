#!/bin/bash
set -e

if [ -n "$GITHUB_ACTIONS" ]; then
    INSTALL_DIR="/home/runner/verapdf"
    BIN_DIR="/home/runner/.local/bin"
else
    INSTALL_DIR="$HOME/verapdf"
    BIN_DIR="$HOME/.local/bin"
fi

URL_DESCARGA="https://software.verapdf.org/dev/verapdf-installer.zip"
curl -fSL "$URL_DESCARGA" -o verapdf-installer.zip

rm -rf verapdf-snapshot
unzip -q verapdf-installer.zip -d verapdf-snapshot

cd verapdf-snapshot/verapdf-greenfield-*/
JAR_FILE=$(ls verapdf-izpack-installer-*.jar)

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

# === CREACIÓN DE ENLACES SIMBÓLICOS ===
mkdir -p "$BIN_DIR"
rm -f "$BIN_DIR/verapdf"
ln -s "$INSTALL_DIR/verapdf" "$BIN_DIR/verapdf"
# ======================================

cd ../../../
rm -f verapdf-installer.zip
rm -rf verapdf-snapshot
