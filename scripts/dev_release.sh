#!/usr/bin/env bash
# One-shot self-host publish for Linux + Darwin + Windows.
#
# Self-hosted only: an existing host `tu` (release/tu or PATH) rebuilds
# tulang for linux / darwin / windows. Never call mother tuc/tua/tul here.
# Every target compiles std from the embedded stdroot; no prebuilt archive.
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

# Require a self-hosted host tu before any rebuild (no mother tuc).
require_host_tu() {
    local cand=""
    if [ "$HOST_TARGET" = "darwin" ] && [ -x "$ROOT/release/tu-darwin" ]; then
        cand="$ROOT/release/tu-darwin"
    elif [ -x "$ROOT/release/tu" ]; then
        cand="$ROOT/release/tu"
    elif command -v tu >/dev/null 2>&1; then
        cand="$(command -v tu)"
    fi
    if [ -z "$cand" ] || [ ! -x "$cand" ]; then
        echo "[dev_release] ERROR: need a self-hosted host tu (release/tu or PATH tu)" >&2
        echo "[dev_release]       mother tuc is not used for self-host publish" >&2
        exit 1
    fi
    # Reject shell wrappers; self-host must be a real binary.
    if head -c 2 "$cand" 2>/dev/null | grep -q '^#!'; then
        echo "[dev_release] ERROR: $cand looks like a script wrapper; install ELF/Mach-O tu" >&2
        exit 1
    fi
    echo "$cand"
}

HOST_TU="$(require_host_tu)"
echo "[dev_release] host tu: $HOST_TU"
mkdir -p "$ROOT/release"

# RFC-109: keep generated version strings in sync with VERSION
bash "$ROOT/scripts/sync_version.sh"

make_tu() {
    make -C "$ROOT" prefix="$prefix" "$@"
}

# Staging layout (RFC-107 embed + overlay isolation):
#
#   stage/
#     compiler/ asmer/ linker/     ← cwd package lookup (use compiler)
#     bin/
#       tulang.tu
#       library → repo, packages →, runtime →, syscall →, platform →
#                                  ↑ embed() roots next to tulang.tu
#
# Package parse uses getcwd(); embed() uses dirname(tulang.tu). Keeping
# stdroot under bin/ means cwd/runtime is absent → copkg overlays win
# (overlay-copkg), while embed still sees the full unfiltered tree.
# Cross-compile never runs `make install TARGET=…` (that would copy a
# host-mismatched tu binary).
stage="$(mktemp -d "${TMPDIR:-/tmp}/tu-devrel-stage-XXXXXX")"
cleanup() { rm -rf "$stage"; }
on_err() {
    echo "[dev_release] restoring host overlay TARGET=$HOST_TARGET after failure"
    make_tu overlay-copkg TARGET="$HOST_TARGET" || true
    make_tu install TARGET="$HOST_TARGET" || true
}
trap cleanup EXIT
trap on_err ERR

echo "[dev_release] stage=$stage prefix=$prefix host=$HOST_TARGET"
mkdir -p "$stage/bin"
cp "$ROOT/tulang.tu" "$stage/bin/"
if [ -f "$ROOT/tu.mod" ]; then
    cp "$ROOT/tu.mod" "$stage/bin/tu.mod"
fi
cp -a "$ROOT/compiler" "$ROOT/asmer" "$ROOT/linker" "$stage/"
for d in library packages runtime syscall platform; do
    if [ ! -d "$ROOT/$d" ]; then
        echo "[dev_release] ERROR: missing $ROOT/$d (needed for embed stdroot)" >&2
        exit 1
    fi
    ln -sfn "$ROOT/$d" "$stage/bin/$d"
done
echo "[dev_release] embed stdroot → stage/bin/{library,packages,runtime,syscall,platform}"

# Copkg sources for the compile --target. Does not touch coasm/stubs or the tu binary.
install_overlay() {
    case "$1" in
    linux|darwin|windows)
        make_tu overlay-copkg TARGET="$1"
        ;;
    *)
        echo "[dev_release] unknown overlay $1" >&2
        return 1
        ;;
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

    rm -f "$stage/bin/tulang" "$stage/bin/tulang.exe" "$stage/a.out" "$stage/a.exe" \
        "$stage/tulang" "$stage/tulang.exe"
    # Self-hosted tu embeds stdroot from stage/bin; overlay-copkg is for disk
    # consumers and mother tooling only.
    (
        cd "$stage"
        "$compiler" build bin/tulang.tu --target="$target" --workdir "$work"
    )

    local produced=""
    if [ "$target" = "windows" ]; then
        if [ -f "$stage/bin/tulang.exe" ]; then
            produced="$stage/bin/tulang.exe"
        elif [ -f "$stage/tulang.exe" ]; then
            produced="$stage/tulang.exe"
        elif [ -f "$work/a.exe" ]; then
            produced="$work/a.exe"
        fi
    else
        if [ -f "$stage/bin/tulang" ]; then
            produced="$stage/bin/tulang"
        elif [ -f "$stage/tulang" ]; then
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

# Shared syscall/stub trees for --stdlib=disk consumers (not used by embed tu).
make_tu install-coasm-all

# Rebuild all three targets with the self-hosted host tu only.
if [ "$HOST_TARGET" = "linux" ]; then
    bootstrap_one linux tu "$HOST_TU"
    HOST_TU="$ROOT/release/tu"
    bootstrap_one darwin tu-darwin "$HOST_TU"
else
    bootstrap_one darwin tu-darwin "$HOST_TU"
    HOST_TU="$ROOT/release/tu-darwin"
    bootstrap_one linux tu "$HOST_TU"
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

# Restore this host's disk tree (copkg overlay + coasm/stubs for --stdlib=disk)
# and install the host binary.
echo "[dev_release] restore host overlay TARGET=$HOST_TARGET + coasm/stubs + install bin"
make_tu overlay-copkg TARGET="$HOST_TARGET"
make_tu install-coasm-all
make_tu install TARGET="$HOST_TARGET"

echo
echo "[dev_release] published:"
ls -l "$ROOT/release"/tu "$ROOT/release"/tu-darwin "$ROOT/release"/tu-windows 2>/dev/null || true
if [ ! -f "$ROOT/release/tu-windows" ]; then
    echo "[dev_release] note: release/tu-windows missing"
fi
echo "[dev_release] install bin: make install   | disk tree: make install-full"
echo "[dev_release] Windows: install-windows.cmd (bin) / install-windows-full.cmd (disk)"
