#!/usr/bin/env bash
# Asistenbro Standalone Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash

set -euo pipefail

DEFAULT_SERVER_URL="https://agent.asistenbro.my.id"
DEFAULT_RELEASE_URL="https://github.com/leviantech/asistenbro-install/releases/latest/download/asistenbro-latest-py3-none-any.whl"

SERVER_URL="${ASISTENBRO_SERVER:-$DEFAULT_SERVER_URL}"
WHEEL_URL="${ASISTENBRO_WHEEL_URL:-$DEFAULT_RELEASE_URL}"

# Styling
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

log() {
    printf "${GREEN}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

warn() {
    printf "${YELLOW}WARNING:${RESET} %s\n" "$1"
}

print_banner() {
    cat << "EOF"

    _         _     _             _               
   / \   ___ (_)___| |_ ___ _ __ | |__  _ __ ___  
  / _ \ / __|| / __| __/ _ \ '_ \| '_ \| '__/ _ \ 
 / ___ \\__ \| \__ \ ||  __/ | | | |_) | | | (_) |
/_/   \_\___//_|___/\__\___|_| |_|_.__/|_|  \___/ 
      Ruang kerja cerdas untuk orkestrasi AI      

EOF
}

print_banner

# Step 1: Ensure uv is installed (fastest & cleanest Python environment manager)
if ! command -v uv >/dev/null 2>&1; then
    log "Menginstall uv (Python package manager cepat & mandiri)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${PATH}"
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: Gagal mendeteksi 'uv'. Silakan tambahkan ~/.local/bin ke PATH Anda."
    exit 1
fi

# Step 2: Install Asistenbro CLI using uv tool
log "Menginstall Asistenbro CLI..."
uv tool install --force "${WHEEL_URL}"

# Ensure ~/.local/bin is on PATH
BIN_DIR="${HOME}/.local/bin"
case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *)
        warn "${BIN_DIR} belum ada di PATH shell Anda."
        export PATH="${BIN_DIR}:${PATH}"
        echo "Tambahkan baris berikut ke ~/.bashrc atau ~/.zshrc Anda:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

log "Asistenbro berhasil terinstall!"
asistenbro --version || true

echo ""
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "${BOLD}Cara Menghubungkan Mesin Ini ke Server Asistenbro:${RESET}\n"
echo ""
echo "1. Untuk menjalankan host interaktif:"
printf "   ${GREEN}asistenbro host %s${RESET}\n" "${SERVER_URL}"
echo ""
echo "2. Atau jalankan di background sebagai service otomatis (systemd):"
printf "   ${GREEN}asistenbro host enable --server %s${RESET}\n" "${SERVER_URL}"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
echo ""
