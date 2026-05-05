#!/usr/bin/env bash
# Stage 3 — git push (LFS objects → Rudolfs, Git refs → origin).
# Requires Rudolfs running (02). Pass branch name as first arg, default main.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/git-push-e2e.sh" "${1:-main}"
