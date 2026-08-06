#!/bin/bash
# httpclient is one-shot. Harness: start httpserver → run client once → kill server.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS="$DIR/../_harness.sh"
[ -f "$HARNESS" ] || { echo -e "\033[31mmissing $HARNESS\033[0m" >&2; exit 1; }
# shellcheck source=../_harness.sh
. "$HARNESS"

HOST=127.0.0.1
PORT=18080
SERVER_LOG=$(mktemp)
CLIENT_LOG=$(mktemp)
SPID=""

cleanup(){
    ex_kill "${SPID:-}"
    rm -f "$SERVER_LOG" "$CLIENT_LOG"
}
trap cleanup EXIT

ex_log "[httpclient] build"
SERVER_BIN=$(ex_build httpserver)
CLIENT_BIN=$(ex_build httpclient)
[ -n "$SERVER_BIN" ] && [ -f "$SERVER_BIN" ] || ex_fail "bad server binary"
[ -n "$CLIENT_BIN" ] && [ -f "$CLIENT_BIN" ] || ex_fail "bad client binary"

ex_log "[httpclient] start httpserver"
"$SERVER_BIN" >"$SERVER_LOG" 2>&1 &
SPID=$!

if ! ex_wait_tcp "$HOST" "$PORT"; then
    echo "---- server log ----" >&2
    cat "$SERVER_LOG" >&2 || true
    ex_fail "httpserver did not listen (needed by httpclient test)"
fi

ex_log "[httpclient] run client"
if ! "$CLIENT_BIN" >"$CLIENT_LOG" 2>&1; then
    echo "---- client log ----" >&2
    cat "$CLIENT_LOG" >&2 || true
    echo "---- server log ----" >&2
    cat "$SERVER_LOG" >&2 || true
    ex_fail "httpclient binary failed"
fi

if ! grep -q "httpclient ok" "$CLIENT_LOG"; then
    echo "---- client log ----" >&2
    cat "$CLIENT_LOG" >&2 || true
    ex_fail "httpclient missing ok marker"
fi

ex_log "[httpclient] ok"
exit 0
