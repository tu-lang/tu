#!/bin/bash
# Shared helpers for examples/*/test.sh (source from demo test scripts).
# Demo-specific load / assert logic stays in each test.sh.
# Logs go to stderr; ex_build prints only the a.out path on stdout.

EX_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Optional mother tuc path: EX_USE_TUC=1. Default is self-hosted tu on both OS.
ex_setup_toolchain(){
    if [ "$(uname -s)" != Darwin ]; then
        return
    fi
    if [ -z "${CO_DARWIN_COASM:-}" ]; then
        export CO_DARWIN_COASM="/usr/local/lib/coasm-darwin"
    fi
    if [ -z "${CO_DARWIN_LIB:-}" ]; then
        if [ -d "$EX_ROOT/linker/darwin" ]; then
            export CO_DARWIN_LIB="$EX_ROOT/linker/darwin"
        elif [ -d "$EX_ROOT/../co/linker/darwin" ]; then
            export CO_DARWIN_LIB="$EX_ROOT/../co/linker/darwin"
        elif [ -d "$EX_ROOT/co/linker/darwin" ]; then
            export CO_DARWIN_LIB="$EX_ROOT/co/linker/darwin"
        fi
    fi
}

ex_use_tuc(){
    if [ "${EX_USE_TUC:-}" = 1 ]; then
        return 0
    fi
    return 1
}

ex_setup_toolchain

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
    local demo_dir="$EX_DIR/$name"
    [ -f "$src" ] || ex_fail "missing $src"

    if ex_use_tuc; then
        local ERR OUT
        ERR=$(mktemp)
        if ! (cd "$demo_dir" && tuc build main.tu >"$ERR" 2>&1); then
            cat "$ERR" >&2
            rm -f "$ERR"
            ex_fail "tuc build failed: $src"
        fi
        cat "$ERR" >&2
        rm -f "$ERR"
        OUT="$demo_dir/main"
        [ -f "$OUT" ] || ex_fail "missing binary $OUT (tuc build)"
        chmod 755 "$OUT" || ex_fail "chmod failed: $OUT"
        echo "$OUT"
        return
    fi

    local ERR OUT
    ERR=$(mktemp)
    if [ "$(uname -s)" = Darwin ]; then
        if ! (cd "$demo_dir" && tu build main.tu --workdir-cwd >"$ERR" 2>&1); then
            cat "$ERR" >&2
            rm -f "$ERR"
            ex_fail "tu build failed: $src"
        fi
        cat "$ERR" >&2
        rm -f "$ERR"
        OUT="$demo_dir/a.out"
        [ -f "$OUT" ] || ex_fail "missing binary $OUT (tu build)"
        chmod 755 "$OUT" || ex_fail "chmod failed: $OUT"
        echo "$OUT"
        return
    fi
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
