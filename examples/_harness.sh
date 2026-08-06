#!/bin/bash
# Shared helpers for examples/*/test.sh (source from demo test scripts).
# Demo-specific load / assert logic stays in each test.sh.
# Logs go to stderr; ex_build prints only the a.out path on stdout.

EX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ex_log(){
    echo -e "\033[32m$1\033[0m" >&2
}
ex_fail(){
    echo -e "\033[31m$1\033[0m" >&2
    exit 1
}

# Build main.tu in $1 (example dir name under examples/) → a.out path on stdout only.
ex_build(){
    local name="$1"
    local src="$EX_DIR/$name/main.tu"
    [ -f "$src" ] || ex_fail "missing $src"
    local ERR WD OUT
    ERR=$(mktemp)
    if ! tu -s "$src" >"$ERR" 2>&1; then
        cat "$ERR" >&2
        rm -f "$ERR"
        ex_fail "tu -s failed: $src"
    fi
    cat "$ERR" >&2
    WD=$(sed -n 's/^\[tu\] workdir: //p' "$ERR" | tail -1 | tr -d '\t\r ')
    rm -f "$ERR"
    [ -n "$WD" ] || ex_fail "missing [tu] workdir for $src"
    [ "$WD" = "(cwd)" ] && WD="."
    tu -c "$WD" >&2 || ex_fail "tu -c failed: $name"
    tu -o "$WD" -o /usr/local/lib/colib >&2 || ex_fail "tu -o failed: $name"
    OUT="$WD/a.out"
    [ -f "$OUT" ] || ex_fail "missing binary $OUT"
    chmod 755 "$OUT" || ex_fail "chmod failed: $OUT"
    echo "$OUT"
}

# Wait until TCP host:port accepts (max ~10s).
ex_wait_tcp(){
    local host="$1"
    local port="$2"
    local i
    for i in $(seq 1 50); do
        if (echo >/dev/tcp/"$host"/"$port") >/dev/null 2>&1; then
            return 0
        fi
        if command -v curl >/dev/null 2>&1; then
            if curl -sf --connect-timeout 0.2 "http://$host:$port/" >/dev/null 2>&1; then
                return 0
            fi
        fi
        sleep 0.2
    done
    return 1
}

# SIGTERM then SIGKILL.
ex_kill(){
    local pid="${1:-}"
    [ -n "$pid" ] || return 0
    kill "$pid" >/dev/null 2>&1 || true
    sleep 0.3
    kill -9 "$pid" >/dev/null 2>&1 || true
    wait "$pid" >/dev/null 2>&1 || true
}
