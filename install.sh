#!/usr/bin/env bash
# Asistenbro Standalone Installer
# One-liner: curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash
# Atau versi spesifik: curl -fsSL https://raw.githubusercontent.com/leviantech/asistenbro-install/main/install.sh | bash -s -- v0.21.0-rc.5

set -euo pipefail

RELEASE_TAG="${1:-${ASISTENBRO_VERSION:-v0.21.0-rc.5}}"
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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

# Determine wheel names based on tag
if [ "$RELEASE_TAG" = "v0.20.1" ]; then
    WHEEL_NAME="omnigent-0.20.0.dev0-py3-none-any.whl"
    CLIENT_WHEEL_NAME="omnigent_client-0.20.0.dev0-py3-none-any.whl"
    UI_WHEEL_NAME="omnigent_ui_sdk-0.20.0.dev0-py3-none-any.whl"
else
    CLEAN_VER="${RELEASE_TAG#v}"
    PY_VER="${CLEAN_VER/-rc./rc}"
    WHEEL_NAME="omnigent-${PY_VER}-py3-none-any.whl"
    CLIENT_WHEEL_NAME="omnigent_client-${PY_VER}-py3-none-any.whl"
    UI_WHEEL_NAME="omnigent_ui_sdk-${PY_VER}-py3-none-any.whl"
fi

# Step 2: Install CLI & Server packages
log "Mengunduh paket Asistenbro (${RELEASE_TAG})..."
curl -fsSL -o "${TMP_DIR}/${WHEEL_NAME}" "${BASE_URL}/${WHEEL_NAME}"
curl -fsSL -o "${TMP_DIR}/${CLIENT_WHEEL_NAME}" "${BASE_URL}/${CLIENT_WHEEL_NAME}" 2>/dev/null || true
curl -fsSL -o "${TMP_DIR}/${UI_WHEEL_NAME}" "${BASE_URL}/${UI_WHEEL_NAME}" 2>/dev/null || true

log "Menyiapkan environment di ${VENV_DIR}..."
mkdir -p "${VENV_DIR}"
uv venv --allow-existing "${VENV_DIR}"

log "Menginstall paket Asistenbro..."
uv pip install --python "${VENV_DIR}/bin/python" --find-links "${TMP_DIR}" "${TMP_DIR}/${WHEEL_NAME}"

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

log "CLI Asistenbro berhasil terinstall!"
"${BIN_DIR}/asistenbro" --version || true

# Step 3: Install macOS Desktop App if running on macOS
if [ "$(uname -s)" = "Darwin" ]; then
    case "$(uname -m)" in
        arm64) MAC_ARCH="arm64" ;;
        *)     MAC_ARCH="x64" ;;
    esac

    ZIP_NAME="Asistenbro-0.18.1-${MAC_ARCH}-mac.zip"
    log "Mengunduh Asistenbro Desktop App untuk macOS (${MAC_ARCH})..."
    curl -fsSL -o "${TMP_DIR}/desktop.zip" "${BASE_URL}/${ZIP_NAME}"

    APP_DIR="/Applications"
    if [ ! -w "${APP_DIR}" ]; then
        APP_DIR="${HOME}/Applications"
        mkdir -p "${APP_DIR}"
    fi

    log "Memasang ke ${APP_DIR}/Asistenbro.app..."
    rm -rf "${APP_DIR}/Asistenbro.app"
    ditto -xk "${TMP_DIR}/desktop.zip" "${APP_DIR}"
    xattr -cr "${APP_DIR}/Asistenbro.app" 2>/dev/null || true

    log "Desktop App berhasil dipasang di ${APP_DIR}/Asistenbro.app! ✨"
fi

echo ""
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "${BOLD}Cara Menggunakan Asistenbro (${RELEASE_TAG}):${RESET}\n"
echo ""
if [ "$(uname -s)" = "Darwin" ]; then
    echo "• Buka Desktop App: cari 'Asistenbro' di Spotlight (Cmd + Spasi) atau Launchpad."
fi
echo "• Untuk menjalankan host interaktif:"
printf "   ${GREEN}asistenbro host %s${RESET}\n" "${SERVER_URL}"
echo ""
echo "• Atau jalankan di background sebagai service otomatis (systemd):"
printf "   ${GREEN}asistenbro host enable --server %s${RESET}\n" "${SERVER_URL}"
printf "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
echo ""
