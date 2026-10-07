#!/usr/bin/env bash
# RFC-110 Stage F: after flattening library/packages into a copkg (or equivalent)
# root, copy the nearest source-tree ancestor tu.mod into each top-level package
# dir that does not already have one.
#
# Usage:
#   materialize_tu_mod.sh <repo_root> <copkg_root>
#
# Linux/Darwin: invoked from Makefile overlay-copkg.
# Windows: invoke from install-windows-full.cmd after robocopy (or mark待验).

set -euo pipefail

REPO="${1:?repo root}"
COPKG="${2:?copkg root}"

find_nearest_tumod() {
    # $1 = absolute or repo-relative source directory
    local dir="$1"
    local depth=0
    while [ "$depth" -lt 32 ]; do
        if [ -f "$dir/tu.mod" ]; then
            echo "$dir/tu.mod"
            return 0
        fi
        local parent
        parent="$(dirname "$dir")"
        if [ "$parent" = "$dir" ]; then
            break
        fi
        dir="$parent"
        depth=$((depth + 1))
    done
    return 1
}

materialize_from_src_parent() {
    # $1 = source parent (e.g. library or packages); children flatten into COPKG
    local src_parent="$1"
    local child
    [ -d "$src_parent" ] || return 0
    for child in "$src_parent"/*/; do
        [ -d "$child" ] || continue
        local name
        name="$(basename "$child")"
        local dest="$COPKG/$name"
        [ -d "$dest" ] || continue
        if [ -f "$dest/tu.mod" ]; then
            continue
        fi
        local mod
        if mod="$(find_nearest_tumod "$child")"; then
            cp -f "$mod" "$dest/tu.mod"
        fi
    done
}

# runtime is copied as a whole tree (cp -R runtime → COPKG/runtime);
# ensure tu.mod is present if source has it (already included by cp -R).
# Still materialize if missing and ancestor exists (defensive).
if [ -d "$COPKG/runtime" ] && [ ! -f "$COPKG/runtime/tu.mod" ]; then
    if mod="$(find_nearest_tumod "$REPO/runtime")"; then
        cp -f "$mod" "$COPKG/runtime/tu.mod"
    fi
fi

materialize_from_src_parent "$REPO/library"
materialize_from_src_parent "$REPO/packages"

echo "materialize_tu_mod: done → $COPKG"
