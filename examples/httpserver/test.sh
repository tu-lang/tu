#!/bin/bash
# httpserver is a resident process. Harness: start → wait listen → client load ~10s → kill.
# Pass if at least one successful HTTP response during the window and server dies cleanly.

set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS="$DIR/../_harness.sh"
[ -f "$HARNESS" ] || { echo -e "\033[31mmissing $HARNESS\033[0m" >&2; exit 1; }
# shellcheck source=../_harness.sh
. "$HARNESS"

HOST=127.0.0.1
PORT=18080
URL="http://$HOST:$PORT/"
LOAD_SECS=10
SERVER_LOG=$(mktemp)
SPID=""

cleanup(){
    ex_kill "${SPID:-}"
    rm -f "$SERVER_LOG"
}
trap cleanup EXIT

ex_log "[httpserver] build"
SERVER_BIN=$(ex_build httpserver)
CLIENT_BIN=$(ex_build httpclient)
[ -n "$SERVER_BIN" ] && [ -f "$SERVER_BIN" ] || ex_fail "bad server binary"
[ -n "$CLIENT_BIN" ] && [ -f "$CLIENT_BIN" ] || ex_fail "bad client binary"

ex_log "[httpserver] start $SERVER_BIN"
"$SERVER_BIN" >"$SERVER_LOG" 2>&1 &
SPID=$!

if ! ex_wait_tcp "$HOST" "$PORT"; then
    echo "---- server log ----" >&2
    cat "$SERVER_LOG" >&2 || true
    ex_fail "httpserver did not listen on $HOST:$PORT"
fi
ex_log "[httpserver] listening; load ${LOAD_SECS}s"

ok=0
fail=0
deadline=$((SECONDS + LOAD_SECS))
while [ "$SECONDS" -lt "$deadline" ]; do
    if command -v curl >/dev/null 2>&1; then
        if out=$(curl -sf --max-time 2 "$URL" 2>/dev/null); then
            case "$out" in
                *Hello*) ok=$((ok + 1)) ;;
                *) fail=$((fail + 1)) ;;
            esac
        else
            fail=$((fail + 1))
        fi
    fi
    if "$CLIENT_BIN" >/dev/null 2>&1; then
        ok=$((ok + 1))
    else
        fail=$((fail + 1))
    fi
    sleep 0.2
done

ex_log "[httpserver] load done ok=$ok fail=$fail; killing pid=$SPID"
ex_kill "$SPID"
SPID=""

if [ "$ok" -lt 1 ]; then
    echo "---- server log ----" >&2
    cat "$SERVER_LOG" >&2 || true
    ex_fail "httpserver load: no successful responses in ${LOAD_SECS}s"
fi

ex_log "[httpserver] ok (responses=$ok)"
exit 0
