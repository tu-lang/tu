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

# Per-run scratch dir for build workdirs and binaries; nothing is left in the
# source tree. test.sh cleanup must call ex_cleanup_tmp.
EX_TMP="$(mktemp -d "${TMPDIR:-/tmp}/tu-examples.XXXXXX")"

ex_cleanup_tmp(){
    [ -n "${EX_TMP:-}" ] && rm -rf "$EX_TMP"
}

ex_log(){
    echo -e "\033[32m$1\033[0m" >&2
}
ex_fail(){
    echo -e "\033[31m$1\033[0m" >&2
    exit 1
}

# Build main.tu in $1 (example dir name under examples/) → binary path on stdout only.
# The binary lives in $EX_TMP/<name>; the copy `build` drops next to main.tu
# is removed so the source tree stays clean.
ex_build(){
    local name="$1"
    local src="$EX_DIR/$name/main.tu"
    local demo_dir="$EX_DIR/$name"
    [ -f "$src" ] || ex_fail "missing $src"

    local driver=tu
    if ex_use_tuc; then
        driver=tuc
    fi
    local work="$EX_TMP/$name"
    mkdir -p "$work" || ex_fail "mkdir failed: $work"

    local ERR OUT
    ERR="$work/build.log"
    # Default embed: build pulls std+coasm (no prefix colib).
    if ! (cd "$demo_dir" && "$driver" build main.tu --workdir "$work" >"$ERR" 2>&1); then
        cat "$ERR" >&2
        rm -f "$demo_dir/main" "$demo_dir/main.exe"
        ex_fail "$driver build failed: $src"
    fi
    cat "$ERR" >&2
    rm -f "$demo_dir/main" "$demo_dir/main.exe"
    OUT="$work/a.out"
    [ -f "$OUT" ] || OUT="$work/a.exe"
    [ -f "$OUT" ] || ex_fail "missing binary in $work ($driver build)"
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
