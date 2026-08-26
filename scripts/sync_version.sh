#!/usr/bin/env bash
# Sync tu/VERSION into generated sources (RFC-109).
# Usage: scripts/sync_version.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER_FILE="$ROOT/VERSION"
if [ ! -f "$VER_FILE" ]; then
    echo "sync_version: missing $VER_FILE" >&2
    exit 1
fi
VER="$(tr -d ' \t\r\n' < "$VER_FILE")"
if ! echo "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "sync_version: invalid VERSION '$VER' (want MAJOR.MINOR.PATCH)" >&2
    exit 1
fi

OUT_TU="$ROOT/compiler/utils/version_gen.tu"
cat > "$OUT_TU" <<EOF
// Auto-generated from tu/VERSION by scripts/sync_version.sh — do not edit.
// RFC-109 toolchain version.

TU_TOOL_VERSION = "$VER"

fn tool_version() {
	return TU_TOOL_VERSION
}
EOF

CO_ROOT="$ROOT/../co"
if [ -d "$CO_ROOT" ]; then
    OUT_H="$CO_ROOT/lib/version_gen.h"
    cat > "$OUT_H" <<EOF
/* Auto-generated from tu/VERSION by scripts/sync_version.sh — do not edit. */
#ifndef CO_LANG_VERSION_GEN_H
#define CO_LANG_VERSION_GEN_H
#define TU_VERSION "$VER"
#endif
EOF
    echo "sync_version: $VER -> $OUT_TU + $OUT_H"
else
    echo "sync_version: $VER -> $OUT_TU (no sibling co/)"
fi
