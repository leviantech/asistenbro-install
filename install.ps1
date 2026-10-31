# Asistenbro Windows Installer
# One-liner: irm https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$ReleaseTag = "v0.20.1"
$BaseUrl = "https://github.com/leviantech/asistenbro-install/releases/download/$ReleaseTag"
$DefaultServer = "https://agent.asistenbro.my.id"

$InstallDir = "$env:USERPROFILE\.local\share\asistenbro\venv"
$BinDir = "$env:USERPROFILE\.local\bin"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         Asistenbro Installer" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Ensure uv is installed
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "==> Menginstall uv package manager..." -ForegroundColor Yellow
    irm https://astral.sh/uv/install.ps1 | iex
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

# Step 2: Download wheels to temporary folder
$TempDir = New-Item -ItemType Directory -Path "$env:TEMP\asistenbro-install-$([guid]::NewGuid())"

try {
    Write-Host "==> Mengunduh paket Asistenbro ($ReleaseTag)..." -ForegroundColor Green
    Invoke-WebRequest -Uri "$BaseUrl/omnigent-0.20.0.dev0-py3-none-any.whl" -OutFile "$TempDir\omnigent-0.20.0.dev0-py3-none-any.whl"
    Invoke-WebRequest -Uri "$BaseUrl/omnigent_client-0.20.0.dev0-py3-none-any.whl" -OutFile "$TempDir\omnigent_client-0.20.0.dev0-py3-none-any.whl"
    Invoke-WebRequest -Uri "$BaseUrl/omnigent_ui_sdk-0.20.0.dev0-py3-none-any.whl" -OutFile "$TempDir\omnigent_ui_sdk-0.20.0.dev0-py3-none-any.whl"

    Write-Host "==> Menyiapkan environment di $InstallDir..." -ForegroundColor Green
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    uv venv --allow-existing $InstallDir

    Write-Host "==> Menginstall paket Asistenbro..." -ForegroundColor Green
    uv pip install --python "$InstallDir\Scripts\python.exe" --find-links $TempDir "$TempDir\omnigent-0.20.0.dev0-py3-none-any.whl"

    if (-not (Test-Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }
    Copy-Item "$InstallDir\Scripts\asistenbro.exe" "$BinDir\asistenbro.exe" -Force -ErrorAction SilentlyContinue
    Copy-Item "$InstallDir\Scripts\bro.exe" "$BinDir\bro.exe" -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "Asistenbro berhasil terinstall!" -ForegroundColor Green
    Write-Host "Hubungkan ke server dengan perintah:" -ForegroundColor Cyan
    Write-Host "  asistenbro host $DefaultServer" -ForegroundColor Yellow
    Write-Host ""
}
finally {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
