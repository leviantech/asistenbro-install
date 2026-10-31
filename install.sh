#!/usr/bin/env bash
# Asistenbro Standalone Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash

set -euo pipefail

RELEASE_TAG="v0.20.1"
BASE_URL="https://github.com/leviantech/asistenbro-install/releases/download/${RELEASE_TAG}"
DEFAULT_SERVER_URL="https://agent.asistenbro.my.id"
SERVER_URL="${ASISTENBRO_SERVER:-$DEFAULT_SERVER_URL}"

VENV_DIR="${HOME}/.local/share/asistenbro/venv"
BIN_DIR="${HOME}/.local/bin"

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

# Step 1: Ensure uv is installed
if ! command -v uv >/dev/null 2>&1; then
    log "Menginstall uv (Python package manager cepat & mandiri)..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="${HOME}/.local/bin:${PATH}"
fi

if ! command -v uv >/dev/null 2>&1; then
    echo "Error: Gagal mendeteksi 'uv'. Silakan tambahkan ~/.local/bin ke PATH Anda."
    exit 1
fi

# Step 2: Download packages to temporary directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

log "Mengunduh paket Asistenbro (${RELEASE_TAG})..."
curl -fsSL -o "${TMP_DIR}/omnigent-0.20.0.dev0-py3-none-any.whl" "${BASE_URL}/omnigent-0.20.0.dev0-py3-none-any.whl"
curl -fsSL -o "${TMP_DIR}/omnigent_client-0.20.0.dev0-py3-none-any.whl" "${BASE_URL}/omnigent_client-0.20.0.dev0-py3-none-any.whl"
curl -fsSL -o "${TMP_DIR}/omnigent_ui_sdk-0.20.0.dev0-py3-none-any.whl" "${BASE_URL}/omnigent_ui_sdk-0.20.0.dev0-py3-none-any.whl"

# Step 3: Create dedicated virtualenv and install
log "Menyiapkan environment di ${VENV_DIR}..."
mkdir -p "${VENV_DIR}"
uv venv --allow-existing "${VENV_DIR}"

log "Menginstall paket Asistenbro..."
uv pip install --python "${VENV_DIR}/bin/python" --find-links "${TMP_DIR}" "${TMP_DIR}/omnigent-0.20.0.dev0-py3-none-any.whl"

# Step 4: Symlink binaries to ~/.local/bin
mkdir -p "${BIN_DIR}"
ln -sf "${VENV_DIR}/bin/asistenbro" "${BIN_DIR}/asistenbro"
ln -sf "${VENV_DIR}/bin/bro" "${BIN_DIR}/bro"

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
"${BIN_DIR}/asistenbro" --version || true

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
