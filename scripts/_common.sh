# Shared helpers for TestRudolf stage scripts — source only, do not execute.
#
# shellcheck shell=bash

_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TESTRUDOLF_ROOT="$(cd "$_SCRIPTS_DIR/.." && pwd)"

testrudolf_load_env() {
  if [[ ! -f "$TESTRUDOLF_ROOT/.env" ]]; then
    echo "testrudolf: missing $TESTRUDOLF_ROOT/.env — cp dotenv.sample .env" >&2
    exit 1
  fi
  set -a
  # shellcheck disable=1091
  source "$TESTRUDOLF_ROOT/.env"
  set +a
}
