#!/usr/bin/env bash
# One-shot self-host publish for Linux + Darwin + Windows.
#
# Mother tuc builds the *host* tu (ELF or Mach-O). That tu then
# --target=windows through the self-hosted peff linker — no lld-link,
# no Win SDK, no mother tul.exe.
# Darwin still goes through tuc (mother Mach-O linker).
# Linux host also rebuilds tulang.a; Darwin/Windows compile std from copkg.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Same prefix as `make prefix=... dev_release` (Makefile exports it).
prefix="${prefix:-${TU_PREFIX:-/usr/local}}"
export TU_PREFIX="$prefix"
export CO_PREFIX="$prefix"

UNAME_S="$(uname -s 2>/dev/null || echo unknown)"
HOST_TARGET=linux
if [ "$UNAME_S" = "Darwin" ]; then
    HOST_TARGET=darwin
fi
case "$UNAME_S" in
MINGW*|MSYS*|CYGWIN*)
    echo "[dev_release] Windows host: use CMake target INSTALL / windows/dev_release.ps1"
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass \
        -File "$ROOT/../co/windows/dev_release.ps1"
    ;;
esac

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "[dev_release] missing $1 in PATH" >&2
        exit 1
    fi
}

need_cmd tuc
need_cmd tua
need_cmd tul
mkdir -p "$ROOT/release"

make_tu() {
    make -C "$ROOT" prefix="$prefix" "$@"
}

# Staging: only tulang.tu + compiler/asmer/linker. cwd runtime/linux.tu would
# hide copkg overlays (darwin.tu / windows.tu) and break cross targets.
stage="$(mktemp -d "${TMPDIR:-/tmp}/tu-devrel-stage-XXXXXX")"
cleanup() { rm -rf "$stage"; }
on_err() {
    echo "[dev_release] restoring host overlay TARGET=$HOST_TARGET after failure"
    make_tu install TARGET="$HOST_TARGET" || true
}
trap cleanup EXIT
trap on_err ERR

echo "[dev_release] stage=$stage prefix=$prefix host=$HOST_TARGET"
cp "$ROOT/tulang.tu" "$stage/"
cp -a "$ROOT/compiler" "$ROOT/asmer" "$ROOT/linker" "$stage/"

install_overlay() {
    case "$1" in
    linux) make_tu install TARGET=linux ;;
    darwin) make_tu install-darwin ;;
    windows) make_tu install-windows ;;
    *) echo "[dev_release] unknown overlay $1" >&2; return 1 ;;
    esac
}

# Return 0 if file starts with MZ (PE).
is_pe() {
    [ "$(dd if="$1" bs=1 count=2 2>/dev/null)" = "MZ" ]
}

bootstrap_one() {
    local target="$1"
    local dest="$2"
    local compiler="$3"
    local work
    work="$(mktemp -d "${TMPDIR:-/tmp}/tu-devrel-$target-XXXXXX")"

    echo "[dev_release] === $target → $dest  ($compiler) ==="
    install_overlay "$target"

    rm -f "$stage/tulang" "$stage/tulang.exe" "$stage/a.out" "$stage/a.exe"
    (
        cd "$stage"
        "$compiler" build tulang.tu --target="$target" --workdir "$work"
    )

    local produced=""
    if [ "$target" = "windows" ]; then
        if [ -f "$stage/tulang.exe" ]; then
            produced="$stage/tulang.exe"
        elif [ -f "$work/a.exe" ]; then
            produced="$work/a.exe"
        fi
    else
        if [ -f "$stage/tulang" ]; then
            produced="$stage/tulang"
        elif [ -f "$work/a.out" ]; then
            produced="$work/a.out"
        fi
    fi
    if [ -z "$produced" ] || [ ! -f "$produced" ]; then
        echo "[dev_release] ERROR: $target produced no binary" >&2
        ls -la "$stage" "$work" >&2 || true
        rm -rf "$work"
        return 1
    fi
    if [ "$target" = "windows" ] && ! is_pe "$produced"; then
        echo "[dev_release] ERROR: $produced is not a PE (missing MZ)" >&2
        rm -rf "$work"
        return 1
    fi
    cp -f "$produced" "$ROOT/release/$dest"
    chmod +x "$ROOT/release/$dest" 2>/dev/null || true
    rm -rf "$work"
    echo "[dev_release] wrote release/$dest ($(wc -c < "$ROOT/release/$dest") bytes)"
}

# Shared syscall/stub trees for every --target= (cross from this host).
make_tu install-coasm-all

# Host gen1 via mother tuc (ELF / Mach-O). Needed before Windows: peff lives in tu.
if [ "$HOST_TARGET" = "linux" ]; then
    bootstrap_one linux tu tuc
    HOST_TU="$ROOT/release/tu"
    bootstrap_one darwin tu-darwin tuc
else
    bootstrap_one darwin tu-darwin tuc
    HOST_TU="$ROOT/release/tu-darwin"
    bootstrap_one linux tu tuc
fi

if [ ! -x "$HOST_TU" ]; then
    echo "[dev_release] ERROR: missing host tu $HOST_TU" >&2
    exit 1
fi

# Windows PE: self-hosted peff in the just-built host tu. No lld-link / SDK / tul.
if [ "${DEV_RELEASE_SKIP_WINDOWS:-0}" = "1" ]; then
    echo "[dev_release] skip windows (DEV_RELEASE_SKIP_WINDOWS=1)"
else
    bootstrap_one windows tu-windows "$HOST_TU"
fi

# Restore this host's copkg overlay and install the matching tu binary.
echo "[dev_release] restore host overlay TARGET=$HOST_TARGET"
make_tu install TARGET="$HOST_TARGET"

# Linux colib archive (Darwin/Windows compile std from source; no .a).
if [ "$HOST_TARGET" = "linux" ]; then
    echo "[dev_release] rebuild linux tulang.a"
    make_tu build-liba
    make_tu install TARGET=linux
else
    echo "[dev_release] skip tulang.a on $HOST_TARGET (no colib; std compiled from copkg)"
fi

echo
echo "[dev_release] published:"
ls -l "$ROOT/release"/tu "$ROOT/release"/tu-darwin "$ROOT/release"/tu-windows "$ROOT/release"/tulang.a 2>/dev/null || true
if [ ! -f "$ROOT/release/tu-windows" ]; then
    echo "[dev_release] note: release/tu-windows missing"
fi
echo "[dev_release] each platform: make install  (Windows: install-windows.cmd / CMake INSTALL)"
