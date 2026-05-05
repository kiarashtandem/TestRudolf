# TestRudolf — local Git LFS → Rudolfs → MinIO (E2E)

This repo exists to **push Git LFS objects through Rudolfs** into a **MinIO** bucket while keeping Git refs in a **local bare remote** — no GitHub required.

Namespaces must match Rudolfs: `demo/local-lfs-test` (see [.lfsconfig](.lfsconfig)).

### Stage scripts (fastest path)

Use **Bash** scripts from the repo root (works from **Fish** too: `bash scripts/…`).

| Step | Command | Notes |
|------|---------|--------|
| (optional) | `bash scripts/00-preflight.sh` | Probes MinIO + Rudolfs HTTP; prints Git LFS endpoint |
| 1 | `bash scripts/01-minio.sh` | Starts MinIO (blocking). Create bucket `rudolfs-lfs` in console once. |
| 2 | `bash scripts/02-rudolfs.sh` | Runs `cargo run --release` in `RUDOLFS_REPO` (default `../rudolfs`) |
| 3 | `bash scripts/03-git-lfs-push.sh main` | Pushes current branch to `origin`; LFS → Rudolfs |

Override **`RUDOLFS_REPO`** in `.env` if your rudolfs checkout is not next to TestRudolf.

---

## Prerequisites

- Rust `rudolfs` binary from your fork/build (runs on **TCP 8080** here).
- **MinIO** on **9020 API** / **9201 Console** by default (avoids **:9010**, often used by Logitech G Hub on macOS). Override in `.env`.
- **Git + Git LFS** installed locally (`brew install git-lfs`).

### Environment file (Bash vs Fish)

This repo’s **`.env`** is plain `KEY=value` (no `export`, no `${VAR:-default}`) so it is safe to load from Bash or Fish.

- **Bash / zsh:** use `set -a; source .env; set +a` so variables are **exported** to child processes.
- **Fish:** do **not** run `source .env` (Fish will parse `${` and fail). From the repo root run:
  ```fish
  source scripts/load-env.fish
  ```

---

## 1) MinIO (Terminal A)

Fish does **not** support `${VAR}` in hand-typed commands — use **`$MINIO_API_PORT`** (e.g. `":$MINIO_API_PORT"`).

Pick ports (defaults below).

**bash / zsh:**

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
cp -n dotenv.sample .env
set -a
source .env
set +a
mkdir -p "$MINIO_ROOT"
"$MINIO_BIN" server "$MINIO_ROOT" --address ":$MINIO_API_PORT" --console-address ":$MINIO_CONSOLE_PORT"
```

**Fish** (after `cp -n dotenv.sample .env` once):

```fish
cd /Users/kiarash/Desktop/Projects/TestRudolf
source scripts/load-env.fish
mkdir -p $MINIO_ROOT
command minio server $MINIO_ROOT --address ":$MINIO_API_PORT" --console-address ":$MINIO_CONSOLE_PORT"
```

**Fish (alternative — no load-env.fish):** wrap Bash so it sources `.env` with `set -a`:

```fish
bash -lc 'cd /Users/kiarash/Desktop/Projects/TestRudolf && test -f .env || cp -n dotenv.sample .env && set -a && source .env && set +a && mkdir -p "$MINIO_ROOT" && exec "$MINIO_BIN" server "$MINIO_ROOT" --address ":$MINIO_API_PORT" --console-address ":$MINIO_CONSOLE_PORT"'
```

Console: `http://127.0.0.1:9201` — create bucket **`rudolfs-lfs`** once (name must match `RUDOLFS_S3_BUCKET`).

---

## 2) Rudolfs (Terminal B)

**bash / zsh:**

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
set -a
source .env
set +a
export AWS_S3_ENDPOINT="http://$MINIO_API_HOST:$MINIO_API_PORT"
export AWS_ACCESS_KEY_ID="$MINIO_ROOT_USER"
export AWS_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD"
export AWS_DEFAULT_REGION=us-east-1
export RUDOLFS_METADATA_PATH="./dev-meta/rudolfs_metadata.sqlite"
mkdir -p ./dev-meta
export RUDOLFS_ADMIN_TOKEN="$RUDOLFS_ADMIN_TOKEN"  # optional; fallback in POSIX is below

rudolfs \
  --host "$RUDOLFS_HOST:$RUDOLFS_PORT" \
  --metadata-path "$RUDOLFS_METADATA_PATH" \
  --admin-token "${RUDOLFS_ADMIN_TOKEN:-dev-admin-change-me}" \
  s3 \
  --bucket "$RUDOLFS_S3_BUCKET"
```

**Fish:** load `.env`, then prefer **Bash** for one Rudolfs process (POSIX `${VAR:-x}` defaults only appear here):

```fish
bash -lc 'cd /Users/kiarash/Desktop/Projects/TestRudolf && set -a && source .env && set +a \
  && export AWS_S3_ENDPOINT="http://$MINIO_API_HOST:$MINIO_API_PORT" \
  && export AWS_ACCESS_KEY_ID="$MINIO_ROOT_USER" AWS_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD" AWS_DEFAULT_REGION=us-east-1 \
  && export RUDOLFS_METADATA_PATH=./dev-meta/rudolfs_metadata.sqlite \
  && mkdir -p dev-meta \
  && rudolfs --host "$RUDOLFS_HOST:$RUDOLFS_PORT" \
    --metadata-path "$RUDOLFS_METADATA_PATH" \
    --admin-token "${RUDOLFS_ADMIN_TOKEN:-dev-admin-change-me}" \
    s3 --bucket "$RUDOLFS_S3_BUCKET"'
```

Or **`source scripts/load-env.fish`** then `set -gx AWS_S3_ENDPOINT "http://$MINIO_API_HOST:$MINIO_API_PORT"` … and run **`rudolfs`** in Fish (`$RUDOLFS_ADMIN_TOKEN` only — no `${…}` defaults).

Adapt `rudolfs` → `cargo run --release --` while developing.

---

## 3) Git workflow (Terminal C)

Bootstrap **once**:

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
./scripts/bootstrap.sh
```

Verify Rudolfs is up:

```bash
curl -s "http://$RUDOLFS_HOST:${RUDOLFS_PORT:-8080}/" | head
```

Fish:

```fish
curl -s "http://$RUDOLFS_HOST:8080/" | head   # or $RUDOLFS_PORT once set -gx
```

Push (**LFS uploads** go to Rudolfs; Git objects go to the bare repo):

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
./scripts/git-push-e2e.sh
```

Increase concurrency (optional):

```bash
git config lfs.concurrenttransfers 8
```

---

## 4) What to check after push

**MinIO Console** (`9201`): bucket `rudolfs-lfs` → objects under paths like  
`lfs/demo/local-lfs-test/...` (default Rudolfs prefix).

**SQLite** (Terminal B cwd): `./dev-meta/rudolfs_metadata.sqlite` populated by uploads.

---

## Troubleshooting

| Symptom | Fix |
|--------|-----|
| ` Unsupported scheme http` | Use rudolfs build with `https_or_http` hyper-rustls connector (recent fork fixes). |
| `bucket not found` | Create `$RUDOLFS_S3_BUCKET` in MinIO. |
| LFS probe fails | `git lfs env` → `Endpoint` must be `http://127.0.0.1:8080/api/demo/local-lfs-test`. |
| 401 admin | Bearer only on `/admin/*`; LFS endpoints are unauthenticated. |

---

## Layout

```
TestRudolf/
  blobs/           # LFS: *.bin + sample text (see .gitattributes)
  scripts/bootstrap.sh
  scripts/git-push-e2e.sh
  dotenv.sample    → copy to .env
  .lfsconfig
  .gitattributes
../TestRudolf-bare.git   # bare remote (created by bootstrap)
```
