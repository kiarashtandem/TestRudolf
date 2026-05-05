#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -r .env ]]; then
  # shellcheck source=/dev/null
  source .env
fi

RUDOLFS_URL="http://${RUDOLFS_HOST:-127.0.0.1}:${RUDOLFS_PORT:-8080}"
echo "Probing Rudolfs at $RUDOLFS_URL ..."
if ! curl -sf --connect-timeout 2 "$RUDOLFS_URL/" >/dev/null; then
  echo "Rudolfs not reachable at $RUDOLFS_URL — start it first (README §2)"
  exit 1
fi

echo "git lfs env (endpoint must match .lfsconfig):"
git lfs env 2>/dev/null | grep -E 'Endpoint|git config' || true

BRANCH="${1:-main}"
git branch -M "$BRANCH" 2>/dev/null || true

echo "Pushing to origin ($BRANCH) — LFS objects go to Rudolfs, Git data to bare remote ..."
GIT_LFS_PROGRESS=1 git push -u origin "$BRANCH"

echo "Done. Check MinIO bucket for prefix lfs/demo/local-lfs-test/ (default Rudolfs layout)."
