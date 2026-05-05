# Load `.env` (KEY=value) into Fish globals. Do NOT `source .env` in Fish — POSIX `${}` breaks.
#
# Supports:
#   KEY=value
#   export KEY=value   (optional `export` prefix, bash-style)
#
# Usage (from repo root):
#   source scripts/load-env.fish

set -l here (status filename)
set -l reporoot (path dirname $here)/..

set -l envfile $reporoot/.env
if not test -f "$envfile"
    echo "load-env.fish: missing .env — run: cp dotenv.sample .env" >&2
    return 1
end

while read -l raw
    set -l line (string trim "$raw")
    test -z "$line" && continue
    string match -q '#*' -- "$line" && continue

    # Strip bash-style `export` so the key is not `export MINIO_BIN`
    if string match -qr '^[Ee][Xx][Pp][Oo][Rr][Tt]\s+' -- "$line"
        set line (string replace -r '^[Ee][Xx][Pp][Oo][Rr][Tt]\s+' '' "$line")
        set line (string trim "$line")
    end

    if string match -q '*${*' -- "$line"
        echo "load-env.fish: .env must not use bash \`\${...}\` — use plain KEY=value; run: cp dotenv.sample .env" >&2
        return 1
    end

    string match -q '*=*' -- "$line" || continue

    set -l kv (string split -m 1 = "$line")
    set -l key (string trim "$kv[1]")
    set -l val (string trim "$kv[2]")
    test -z "$key" && continue

    # Expand $HOME / leading ~ in values (Fish: use `string replace -r` — no `-rs` flag)
    set val (string replace -a '$HOME' $HOME "$val")
    if string match -qr '^~' -- "$val"
        set val (string replace -r '^~' $HOME "$val")
    end

    # Fish variable names: letters, digits, underscore only
    if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- "$key"
        echo "load-env.fish: skip invalid key: $key" >&2
        continue
    end

    set -gx $key $val
end <"$envfile"
