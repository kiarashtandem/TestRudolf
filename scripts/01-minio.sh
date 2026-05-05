#!/usr/bin/env bash
# Stage 1 — MinIO object store (run in its own terminal; blocks until Ctrl+C).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"
testrudolf_load_env

mkdir -p "${MINIO_ROOT:?}"

echo "Starting MinIO: data=$MINIO_ROOT  API=:$MINIO_API_PORT  console=:$MINIO_CONSOLE_PORT"
echo "Create bucket ${RUDOLFS_S3_BUCKET:-rudolfs-lfs} at http://${MINIO_API_HOST}:${MINIO_CONSOLE_PORT} once."
exec "${MINIO_BIN:?}" server "$MINIO_ROOT" \
  --address ":${MINIO_API_PORT}" \
  --console-address ":${MINIO_CONSOLE_PORT}"
