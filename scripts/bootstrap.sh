#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -r .env ]] && [[ -r dotenv.sample ]]; then
  echo "hint: cp dotenv.sample .env and adjust MINIO_/RUDOLFS_ vars if needed" >&2
fi
if [[ -r .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

if [[ ! -f .lfsconfig ]]; then
  echo "missing .lfsconfig"
  exit 1
fi

if ! command -v git-lfs >/dev/null 2>&1; then
  echo "install Git LFS: brew install git-lfs && git lfs install"
  exit 1
fi

BARE_REMOTE="${BARE_REMOTE:-$(dirname "$ROOT")/TestRudolf-bare.git}"

if [[ ! -d "$BARE_REMOTE" ]]; then
  echo "creating bare remote at $BARE_REMOTE"
  git init --bare "$BARE_REMOTE"
fi

if [[ ! -d .git ]]; then
  git init
fi

git lfs install

if ! git config user.email >/dev/null 2>&1; then
  git config user.email "e2e@testrudolf.local"
  git config user.name "TestRudolf E2E"
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin "file://${BARE_REMOTE}"
fi

# Ensure sample blobs exist
mkdir -p blobs
if [[ ! -f blobs/sample-a.bin ]]; then
  dd if=/dev/urandom of=blobs/sample-a.bin bs=1024 count=256 status=none
fi
if [[ ! -f blobs/sample-b.bin ]]; then
  dd if=/dev/urandom of=blobs/sample-b.bin bs=1024 count=256 status=none
fi
if [[ ! -f blobs/sample.txt ]]; then
  cat > blobs/sample.txt <<'EOF'
TestRudolf LFS text blob (UTF-8).

This file is tracked as Git LFS and is uploaded to Rudolfs on push, alongside the
random *.bin fixtures from bootstrap.

Line three: predictable content for debugging and MinIO object inspection.

EOF
fi

git add .gitattributes .lfsconfig README.md dotenv.sample blobs/*.bin blobs/*.txt scripts/*.sh 2>/dev/null || true
git add .gitattributes .lfsconfig README.md dotenv.sample blobs scripts || true

if git diff --cached --quiet 2>/dev/null; then
  echo "nothing to commit (already bootstrapped)"
else
  git commit -m "bootstrap: LFS demo blobs + config" || true
fi

echo "Remote: file://${BARE_REMOTE}"
echo "LFS URL (from .lfsconfig):"
grep -E '^\s*url\s*=' .lfsconfig || true
echo "Next: start MinIO + Rudolfs (see README), then ./scripts/git-push-e2e.sh"
