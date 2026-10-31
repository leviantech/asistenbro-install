# Asistenbro Windows Installer
# One-liner: irm https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$DefaultServer = "https://agent.asistenbro.my.id"
$DefaultWheel = "https://github.com/leviantech/asistenbro-install/releases/latest/download/asistenbro-latest-py3-none-any.whl"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "         Asistenbro Installer" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# Step 1: Ensure uv is installed
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "==> Menginstall uv package manager..." -ForegroundColor Yellow
    irm https://astral.sh/uv/install.ps1 | iex
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

# Step 2: Install Asistenbro CLI
Write-Host "==> Menginstall Asistenbro CLI..." -ForegroundColor Green
uv tool install --force $DefaultWheel

Write-Host ""
Write-Host "Asistenbro berhasil terinstall!" -ForegroundColor Green
Write-Host "Hubungkan ke server dengan perintah:" -ForegroundColor Cyan
Write-Host "  asistenbro host $DefaultServer" -ForegroundColor Yellow
Write-Host ""
