#!/usr/bin/env bash
# Quick checks before running other stages (MinIO + Rudolfs reachable).
set -euo pipefail
_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/_common.sh
source "$_SCRIPTS/_common.sh"
testrudolf_load_env

echo "== .env loaded ($TESTRUDOLF_ROOT) =="

MINIO_HEALTH="http://${MINIO_API_HOST}:${MINIO_API_PORT}/minio/health/live"
echo "Probing MinIO: $MINIO_HEALTH"
if curl -sf --connect-timeout 2 "$MINIO_HEALTH" >/dev/null; then
  echo "  MinIO: OK"
else
  echo "  MinIO: not reachable (start scripts/01-minio.sh)" >&2
fi

RUDOLFS_URL="http://${RUDOLFS_HOST}:${RUDOLFS_PORT}/"
echo "Probing Rudolfs: $RUDOLFS_URL"
if curl -sf --connect-timeout 2 "$RUDOLFS_URL" >/dev/null; then
  echo "  Rudolfs: OK"
else
  echo "  Rudolfs: not reachable (start scripts/02-rudolfs.sh)" >&2
fi

echo "git lfs endpoint:"
cd "$TESTRUDOLF_ROOT"
git lfs env 2>/dev/null | grep -E '^Endpoint' || true
