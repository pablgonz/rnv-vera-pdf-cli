$ErrorActionPreference = "Stop"
$InstallDir = "$env:USERPROFILE\rnv-wrapp"

# Descargar el ZIP precompilado (o usar uno local si estamos probando en Actions)
if ($env:LOCAL_ZIP_PATH) {
    Write-Host "Modo CI: Usando archivo local $env:LOCAL_ZIP_PATH"
    Copy-Item -Path $env:LOCAL_ZIP_PATH -Destination "rnv-wrapp-windows.zip" -Force
} else {
    $UrlDescarga = "https://raw.githubusercontent.com/pablgonz/rnv-vera-pdf-cli/main/x64_windows/rnv-wrapp-windows.zip"
    Write-Host "Descargando rnv-wrapp..."
    Invoke-WebRequest -Uri $UrlDescarga -OutFile "rnv-wrapp-windows.zip"
}

# Extraer el instalador
if (Test-Path $InstallDir) { Remove-Item -Recurse -Force $InstallDir }
Expand-Archive -Path "rnv-wrapp-windows.zip" -DestinationPath $InstallDir -Force

# === CONFIGURACIÓN DE PATH ===
if ($env:GITHUB_ACTIONS) {
    Add-Content -Path $env:GITHUB_PATH -Value $InstallDir
} else {
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$UserPath;$InstallDir", "User")
        Write-Host "rnv-wrapp instalado localmente. Se agregó $InstallDir al PATH de usuario."
    }
}
# =============================

Remove-Item "rnv-wrapp-windows.zip" -Force
Write-Host "Instalación completada con éxito."
