$ErrorActionPreference = "Stop"

# Definir directorios según el entorno (igual que en tu script de Linux)
if ($env:GITHUB_ACTIONS) {
    $InstallDir = "$env:USERPROFILE\verapdf"
} else {
    $InstallDir = "$env:USERPROFILE\verapdf"
}

# Descargar el instalador
$UrlDescarga = "https://software.verapdf.org/dev/verapdf-installer.zip"
Invoke-WebRequest -Uri $UrlDescarga -OutFile "verapdf-installer.zip"

# Extraer el instalador
if (Test-Path "verapdf-snapshot") { Remove-Item -Recurse -Force "verapdf-snapshot" }
Expand-Archive -Path "verapdf-installer.zip" -DestinationPath "verapdf-snapshot" -Force

# Obtener el instalador JAR
$JarFile = Get-ChildItem -Path "verapdf-snapshot\verapdf-greenfield-*\verapdf-izpack-installer-*.jar" | Select-Object -First 1

# Crear el XML de instalación silenciosa
$XmlContent = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
    <com.izforge.izpack.panels.htmlhello.HTMLHelloPanel id="welcome"/>
    <com.izforge.izpack.panels.target.TargetPanel id="install_dir">
        <installpath>$InstallDir</installpath>
    </com.izforge.izpack.panels.target.TargetPanel>
    <com.izforge.izpack.panels.packs.PacksPanel id="packs">
        <pack index="0" name="veraPDF CLI" selected="true"/>
        <pack index="1" name="veraPDF GUI" selected="false"/>
    </com.izforge.izpack.panels.packs.PacksPanel>
    <com.izforge.izpack.panels.install.InstallPanel id="install"/>
    <com.izforge.izpack.panels.finish.FinishPanel id="finish"/>
</AutomatedInstallation>
"@

Set-Content -Path "auto-install.xml" -Value $XmlContent -Encoding UTF8

# Ejecutar la instalación
java -jar $JarFile.FullName auto-install.xml

# === CONFIGURACIÓN LOCAL (WINDOWS) ===
# Si lo ejecutas localmente, registra veraPDF en tu PATH de Usuario
if (-not $env:GITHUB_ACTIONS) {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "veraPDF instalado localmente. Se agregó $InstallDir al PATH de usuario."
    }
}
# =====================================

# Limpieza de temporales
Remove-Item "verapdf-installer.zip" -Force
Remove-Item "verapdf-snapshot" -Recurse -Force
Remove-Item "auto-install.xml" -Force
