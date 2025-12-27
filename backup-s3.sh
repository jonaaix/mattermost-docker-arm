#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="$(basename "${SCRIPT_DIR}")"
BACKUP_DIR="${SCRIPT_DIR}/backups"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"

if [ -f "${SCRIPT_DIR}/.env" ]; then
    set -a
    source "${SCRIPT_DIR}/.env"
    set +a
else
    echo "Error: .env file not found in ${SCRIPT_DIR}" >&2
    exit 1
fi

VOL_DATA="${PROJECT_NAME}_mm_data"
VOL_CONFIG="${PROJECT_NAME}_mm_config"
VOL_PLUGINS="${PROJECT_NAME}_mm_plugins"

FILE_SQL="db_${PROJECT_NAME}_${TIMESTAMP}.sql"
FILE_DATA="data_${PROJECT_NAME}_${TIMESTAMP}.tar.gz"

# Internal name for Rclone remote
REMOTE="s3store"

mkdir -p "${BACKUP_DIR}"

# Wrapper for Rclone via Docker
# ADDED: RCLONE_CONFIG_S3STORE_NO_CHECK_BUCKET=true
# This prevents Rclone from trying to create the bucket or list root buckets,
# which fixes the 403 error on restricted credentials.
rclone_cmd() {
    docker run --rm \
        -v "${BACKUP_DIR}:/data" \
        -e RCLONE_CONFIG_S3STORE_TYPE=s3 \
        -e RCLONE_CONFIG_S3STORE_PROVIDER=DigitalOcean \
        -e RCLONE_CONFIG_S3STORE_ENV_AUTH=false \
        -e RCLONE_CONFIG_S3STORE_ACCESS_KEY_ID="${S3_ACCESS_KEY}" \
        -e RCLONE_CONFIG_S3STORE_SECRET_ACCESS_KEY="${S3_SECRET_KEY}" \
        -e RCLONE_CONFIG_S3STORE_ENDPOINT="${S3_ENDPOINT}" \
        -e RCLONE_CONFIG_S3STORE_REGION="${S3_REGION}" \
        -e RCLONE_CONFIG_S3STORE_ACL=private \
        -e RCLONE_CONFIG_S3STORE_NO_CHECK_BUCKET=true \
        rclone/rclone:latest \
        "$@"
}

echo "[${TIMESTAMP}] Starting Backup: ${PROJECT_NAME}"

# 1. Database Dump
if ! DB_CONTAINER_ID=$(docker compose -f "${COMPOSE_FILE}" ps -q db); then
    echo "Error: Database container not found." >&2
    exit 1
fi

docker exec -t "${DB_CONTAINER_ID}" pg_dump -U "${MM_DB_USER:-mattermost}" "${MM_DB_NAME:-mattermost}" > "${BACKUP_DIR}/${FILE_SQL}"

# 2. Filesystem Archive
docker run --rm \
  -v "${VOL_DATA}:/mnt/data:ro" \
  -v "${VOL_CONFIG}:/mnt/config:ro" \
  -v "${VOL_PLUGINS}:/mnt/plugins:ro" \
  -v "${BACKUP_DIR}:/backup" \
  alpine \
  tar -czf "/backup/${FILE_DATA}" -C /mnt data config plugins

# 3. S3 Upload
echo "Uploading to S3..."
rclone_cmd copy "/data/${FILE_SQL}" "${REMOTE}:${S3_BUCKET}/${PROJECT_NAME}"
rclone_cmd copy "/data/${FILE_DATA}" "${REMOTE}:${S3_BUCKET}/${PROJECT_NAME}"

# 4. S3 Retention (Cold Storage Aware)
echo "Applying Retention Policy (Delete older than ${S3_RETENTION_DAYS} days)..."
rclone_cmd delete "${REMOTE}:${S3_BUCKET}/${PROJECT_NAME}" --min-age "${S3_RETENTION_DAYS}d"

# 5. Local Retention
find "${BACKUP_DIR}" -name "db_*.sql" -mtime "+${BACKUP_RETENTION_DAYS}" -delete
find "${BACKUP_DIR}" -name "data_*.tar.gz" -mtime "+${BACKUP_RETENTION_DAYS}" -delete

echo "[$(date +"%Y%m%d_%H%M%S")] Backup Completed"
