#!/usr/bin/env bash
# Stage 2 — Rudolfs LFS server (run in its own terminal; blocks until Ctrl+C).
# Uses cargo run in RUDOLFS_REPO (default: sibling ../rudolfs).
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh"
testrudolf_load_env

export AWS_S3_ENDPOINT="http://${MINIO_API_HOST}:${MINIO_API_PORT}"
export AWS_ACCESS_KEY_ID="${MINIO_ROOT_USER}"
export AWS_SECRET_ACCESS_KEY="${MINIO_ROOT_PASSWORD}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

METADATA="${RUDOLFS_METADATA_PATH:-$TESTRUDOLF_ROOT/dev-meta/rudolfs_metadata.sqlite}"
export RUDOLFS_METADATA_PATH="$METADATA"
mkdir -p "$(dirname "$METADATA")"

RUDOLFS_REPO="${RUDOLFS_REPO:-$TESTRUDOLF_ROOT/../rudolfs}"
if [[ ! -f "$RUDOLFS_REPO/Cargo.toml" ]]; then
  echo "RUDOLFS_REPO does not look like a Rust crate: $RUDOLFS_REPO" >&2
  echo "Set RUDOLFS_REPO in .env to your rudolfs fork path." >&2
  exit 1
fi

echo "Rudolfs crate: $RUDOLFS_REPO"
echo "Metadata DB:  $RUDOLFS_METADATA_PATH"
echo "S3 endpoint:  $AWS_S3_ENDPOINT  bucket=${RUDOLFS_S3_BUCKET}"
cd "$RUDOLFS_REPO"

exec cargo run --release -- \
  --host "${RUDOLFS_HOST}:${RUDOLFS_PORT}" \
  --metadata-path "$RUDOLFS_METADATA_PATH" \
  --admin-token "${RUDOLFS_ADMIN_TOKEN}" \
  s3 \
  --bucket "${RUDOLFS_S3_BUCKET}"
