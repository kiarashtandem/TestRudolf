# TestRudolf — local Git LFS → Rudolfs → MinIO (E2E)

This repo exists to **push Git LFS objects through Rudolfs** into a **MinIO** bucket while keeping Git refs in a **local bare remote** — no GitHub required.

Namespaces must match Rudolfs: `demo/local-lfs-test` (see [.lfsconfig](.lfsconfig)).

---

## Prerequisites

- Rust `rudolfs` binary from your fork/build (runs on **TCP 8080** here).
- **MinIO** on **9010 API** / **9101 Console** so this stack does not fight other MinIO installs on `:9000` (optional override — see `.env`).
- **Git + Git LFS** installed locally (`brew install git-lfs`).

---

## 1) MinIO (Terminal A)

Pick ports (defaults below):

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
cp -n dotenv.sample .env
source .env
mkdir -p "$MINIO_ROOT"
"$MINIO_BIN" server "$MINIO_ROOT" --address ":${MINIO_API_PORT}" --console-address ":${MINIO_CONSOLE_PORT}"
```

Console: `http://127.0.0.1:9101` — create bucket **`rudolfs-lfs`** once (name must match `RUDOLFS_S3_BUCKET`).

---

## 2) Rudolfs (Terminal B)

```bash
cd /Users/kiarash/Desktop/Projects/TestRudolf
source .env
export AWS_S3_ENDPOINT="http://${MINIO_API_HOST}:${MINIO_API_PORT}"
export AWS_ACCESS_KEY_ID="$MINIO_ROOT_USER"
export AWS_SECRET_ACCESS_KEY="$MINIO_ROOT_PASSWORD"
export AWS_DEFAULT_REGION=us-east-1
export RUDOLFS_METADATA_PATH="./dev-meta/rudolfs_metadata.sqlite"
mkdir -p ./dev-meta
export RUDOLFS_ADMIN_TOKEN="${RUDOLFS_ADMIN_TOKEN:-dev-admin-change-me}"

rudolfs \
  --host "${RUDOLFS_HOST}:${RUDOLFS_PORT}" \
  --metadata-path "$RUDOLFS_METADATA_PATH" \
  --admin-token "$RUDOLFS_ADMIN_TOKEN" \
  s3 \
  --bucket "$RUDOLFS_S3_BUCKET"
```

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
curl -s "http://${RUDOLFS_HOST}:${RUDOLFS_PORT:-8080}/" | head
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

**MinIO Console** (`9101`): bucket `rudolfs-lfs` → objects under paths like  
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
  blobs/           # tracked as LFS (see .gitattributes)
  scripts/bootstrap.sh
  scripts/git-push-e2e.sh
  dotenv.sample    → copy to .env
  .lfsconfig
  .gitattributes
../TestRudolf-bare.git   # bare remote (created by bootstrap)
```
