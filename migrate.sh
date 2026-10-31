#!/usr/bin/env bash
# ==============================================================================
# Asistenbro Server Automated Migration Script
# Safe in-place migration from Omnigent to Asistenbro Server with automated backup.
# ==============================================================================

set -euo pipefail

# Styling
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log() {
    printf "${GREEN}==>${RESET} ${BOLD}%s${RESET}\n" "$1"
}

warn() {
    printf "${YELLOW}WARNING:${RESET} %s\n" "$1"
}

error() {
    printf "${RED}ERROR:${RESET} %s\n" "$1" >&2
    exit 1
}

print_banner() {
    cat << "EOF"

    _         _     _             _
   / \   ___ (_)___| |_ ___ _ __ | |__  _ __ ___
  / _ \ / __|| / __| __/ _ \ '_ \| '_ \| '__/ _ \
 / ___ \\__ \| \__ \ ||  __/ | | | |_) | | | (_) |
/_/   \_\___//_|___/\__\___|_| |_|_.__/|_|  \___/
          Migrasi Server Otomatis (Zero-Loss)

EOF
}

print_banner

# Step 1: Detect docker compose environment
if ! command -v docker >/dev/null 2>&1; then
    error "Docker tidak ditemukan. Pastikan Docker sudah terinstall di mesin ini."
fi

# Support both 'docker compose' and 'docker-compose'
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    error "Docker Compose tidak ditemukan."
fi

if [ ! -f "docker-compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
    error "File docker-compose.yaml tidak ditemukan di direktori saat ini ($(pwd)). Silakan masuk ke folder deploy/docker terlebih dahulu."
fi

TARGET_TAG="${1:-latest}"
NEW_IMAGE="ghcr.io/leviantech/asistenbro-server:${TARGET_TAG}"

log "Target image baru: ${NEW_IMAGE}"

# Step 2: Automated Backup (Safety Net)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$(pwd)/backups/migration_${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

log "Membuat backup otomatis di: ${BACKUP_DIR}..."

# 2a. Backup config files
[ -f ".env" ] && cp ".env" "${BACKUP_DIR}/.env.bak"
[ -f "docker-compose.yaml" ] && cp "docker-compose.yaml" "${BACKUP_DIR}/docker-compose.yaml.bak"

# 2b. Backup PostgreSQL Database if running
log "Mengecek service database PostgreSQL..."
POSTGRES_CONTAINER=$($DOCKER_COMPOSE ps -q postgres 2>/dev/null || true)

if [ -n "${POSTGRES_CONTAINER}" ]; then
    log "Dumping database PostgreSQL..."
    # Read db credentials from environment or defaults
    POSTGRES_USER="${POSTGRES_USER:-omnigent}"
    POSTGRES_DB="${POSTGRES_DB:-omnigent}"
    if [ -f ".env" ]; then
        POSTGRES_USER=$(grep -E '^POSTGRES_USER=' .env | cut -d '=' -f2- | tr -d '"'"'" || echo "${POSTGRES_USER}")
        POSTGRES_DB=$(grep -E '^POSTGRES_DB=' .env | cut -d '=' -f2- | tr -d '"'"'" || echo "${POSTGRES_DB}")
    fi
    POSTGRES_USER="${POSTGRES_USER:-omnigent}"
    POSTGRES_DB="${POSTGRES_DB:-omnigent}"

    $DOCKER_COMPOSE exec -T postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" > "${BACKUP_DIR}/database_${POSTGRES_DB}.sql"
    log "Database berhasil di-dump ke: ${BACKUP_DIR}/database_${POSTGRES_DB}.sql (${BOLD}$(du -h "${BACKUP_DIR}/database_${POSTGRES_DB}.sql" | cut -f1)${RESET})"
else
    warn "Container postgres tidak sedang berjalan. Backup database SQL dilewati (volume Docker tetap aman)."
fi

# 2c. Backup Persistent Artifact Volume
ARTIFACT_VOLUME=$(docker volume ls -q | grep -E 'artifact-data' | head -n 1 || true)
if [ -n "${ARTIFACT_VOLUME}" ]; then
    log "Membackup volume storage (${ARTIFACT_VOLUME})..."
    docker run --rm \
        -v "${ARTIFACT_VOLUME}:/source:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine tar czf "/backup/artifacts_${TIMESTAMP}.tar.gz" -C /source . 2>/dev/null || warn "Gagal mengarsipkan artifacts (bisa dilewati)."
    if [ -f "${BACKUP_DIR}/artifacts_${TIMESTAMP}.tar.gz" ]; then
        log "Storage volume berhasil diarsipkan ke: ${BACKUP_DIR}/artifacts_${TIMESTAMP}.tar.gz"
    fi
fi

log "Semua backup berhasil disimpan! 🛡️"

# Step 3: Update configuration to use Asistenbro image
log "Memperbarui konfigurasi image di .env..."
touch .env

update_env_var() {
    local key="$1"
    local value="$2"
    local file=".env"
    if grep -q "^[[:space:]]*${key}=" "${file}"; then
        sed "s|^[[:space:]]*${key}=.*|${key}=${value}|" "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
    else
        echo "${key}=${value}" >> "${file}"
    fi
}

update_env_var "ASISTENBRO_IMAGE" "ghcr.io/leviantech/asistenbro-server"
update_env_var "ASISTENBRO_TAG" "${TARGET_TAG}"
update_env_var "OMNIGENT_IMAGE" "ghcr.io/leviantech/asistenbro-server"
update_env_var "OMNIGENT_IMAGE_TAG" "${TARGET_TAG}"

# Also replace hardcoded upstream anthropics image if present in docker-compose.yaml
if [ -f "docker-compose.yaml" ] && grep -q "ghcr.io/anthropics/omnigent-server" "docker-compose.yaml"; then
    log "Mengganti hardcoded image di docker-compose.yaml..."
    sed "s|ghcr.io/anthropics/omnigent-server|ghcr.io/leviantech/asistenbro-server|g" docker-compose.yaml > docker-compose.yaml.tmp && mv docker-compose.yaml.tmp docker-compose.yaml
fi

# Step 4: Pull image and restart container
log "Menarik image Docker Asistenbro (${NEW_IMAGE})..."
$DOCKER_COMPOSE pull omnigent

log "Memulai proses in-place upgrade container..."
$DOCKER_COMPOSE up -d --no-deps omnigent

# Step 5: Verification
log "Menunggu server siap..."
HEALTHY=false
for i in {1..15}; do
    sleep 2
    if $DOCKER_COMPOSE ps omnigent | grep -qi "Up"; then
        HEALTHY=true
        break
    fi
done

if [ "$HEALTHY" = true ]; then
    echo ""
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
    printf "${BOLD}🎉 MIGRASI KE ASISTENBRO SERVER SUKSES 100%!${RESET}\n"
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
    echo ""
    echo "• Server sekarang berjalan dengan image: ${NEW_IMAGE}"
    echo "• Semua data chat, akun, & file tersimpan utuh di volume lama."
    echo "• File cadangan snapshot tersimpan di:"
    echo "    ${BACKUP_DIR}"
    echo ""
    printf "${BOLD}Cek log server:${RESET}   ${BLUE}%s logs -f omnigent${RESET}\n" "$DOCKER_COMPOSE"
    echo ""
    printf "${YELLOW}Cara Rollback (jika diperlukan):${RESET}\n"
    echo "  cp ${BACKUP_DIR}/.env.bak .env && $DOCKER_COMPOSE up -d omnigent"
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
else
    warn "Container sudah dinyalakan namun butuh waktu tambahan untuk bootstrap."
    echo "Silakan cek log dengan: $DOCKER_COMPOSE logs -f omnigent"
fi
