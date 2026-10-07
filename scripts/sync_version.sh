#!/usr/bin/env bash
# Sync tu/VERSION and per-component VERSION files into generated sources (RFC-109).
# Usage: scripts/sync_version.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER_FILE="$ROOT/VERSION"
MANIFEST="$ROOT/scripts/version_manifest.txt"

read_ver() {
    local f="$1"
    if [ ! -f "$f" ]; then
        echo "sync_version: missing $f" >&2
        exit 1
    fi
    local v
    v="$(tr -d ' \t\r\n' < "$f")"
    if ! echo "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "sync_version: invalid VERSION in $f ('$v')" >&2
        exit 1
    fi
    echo "$v"
}

TOOL_VER="$(read_ver "$VER_FILE")"

OUT_TU="$ROOT/compiler/utils/version_gen.tu"
{
    echo "// Auto-generated from tu/VERSION + scripts/version_manifest.txt — do not edit."
    echo "// RFC-109 toolchain + component versions (string constants only; no package imports)."
    echo ""
    echo "use fmt"
    echo ""
    echo "TU_TOOL_VERSION = \"$TOOL_VER\""
    echo ""
    # compiler/ is RFC-110 dyn: emit func (not fn) so ModeCheck accepts version_gen.tu.
    echo "func tool_version() {"
    echo "	return TU_TOOL_VERSION"
    echo "}"
    echo ""
    echo "// Full aligned report; target_os is short name: linux | darwin | windows."
    echo "func print_version_report(target_os) {"
    echo "	fmt.printf(\"tu-lang version: %s\\n\", TU_TOOL_VERSION)"
    echo "	fmt.printf(\"Target         : x86_64 %s\\n\", target_os)"
    prev_section=""
    while IFS='|' read -r section name relpath _comment; do
        [[ -z "${section:-}" || "$section" == \#* ]] && continue
        [[ "$section" =~ ^[[:space:]]*# ]] && continue
        section="$(echo "$section" | tr -d ' \t\r\n')"
        name="$(echo "$name" | tr -d ' \t\r\n')"
        relpath="$(echo "$relpath" | tr -d ' \t\r\n')"
        comp_ver="$(read_ver "$ROOT/$relpath")"
        if [ "$section" != "$prev_section" ]; then
            if [ -n "$prev_section" ] && [ "$section" = "Packages" ]; then
                echo "	fmt.printf(\"\\n\")"
            fi
            if [ -z "$name" ]; then
                label="$section"
                label_padded="$(printf '%-14s' "$label")"
                echo "	fmt.printf(\"${label_padded}: %s\\n\", \"$comp_ver\")"
            else
                if [ "$prev_section" = "" ]; then
                    echo "	fmt.printf(\"\\n\")"
                fi
                echo "	fmt.printf(\"$section\\n\")"
            fi
            prev_section="$section"
        fi
        if [ -n "$name" ]; then
            sub="$(printf '  %-12s' "$name")"
            echo "	fmt.printf(\"${sub}: %s\\n\", \"$comp_ver\")"
        fi
    done < "$MANIFEST"
    echo "}"
} > "$OUT_TU"

CO_ROOT="$ROOT/../co"
if [ -d "$CO_ROOT" ]; then
    OUT_H="$CO_ROOT/lib/version_gen.h"
    {
        echo "/* Auto-generated from tu/VERSION + version_manifest.txt — do not edit. */"
        echo "#ifndef CO_LANG_VERSION_GEN_H"
        echo "#define CO_LANG_VERSION_GEN_H"
        echo "#include <stdio.h>"
        echo ""
        echo "#define TU_VERSION \"$TOOL_VER\""
        echo ""
        echo "static inline void tu_print_version_report(const char* target_os) {"
        echo "    printf(\"tuc-lang version: %s\\n\", TU_VERSION);"
        echo "    printf(\"Target         : x86_64 %s\\n\", target_os);"
        prev_section=""
    while IFS='|' read -r section name relpath _comment; do
        [[ -z "${section:-}" || "$section" == \#* ]] && continue
        [[ "$section" =~ ^[[:space:]]*# ]] && continue
        section="$(echo "$section" | tr -d ' \t\r\n')"
        name="$(echo "$name" | tr -d ' \t\r\n')"
        relpath="$(echo "$relpath" | tr -d ' \t\r\n')"
        comp_ver="$(read_ver "$ROOT/$relpath")"
        if [ "$section" != "$prev_section" ]; then
            if [ -n "$prev_section" ] && [ "$section" = "Packages" ]; then
                echo "    printf(\"\\n\");"
            fi
            if [ -z "$name" ]; then
                label_padded="$(printf '%-14s' "$section")"
                echo "    printf(\"${label_padded}: %s\\n\", \"$comp_ver\");"
            else
                if [ "$prev_section" = "" ]; then
                    echo "    printf(\"\\n\");"
                fi
                echo "    printf(\"$section\\n\");"
            fi
            prev_section="$section"
        fi
            if [ -n "$name" ]; then
                sub="$(printf '  %-12s' "$name")"
                echo "    printf(\"${sub}: %s\\n\", \"$comp_ver\");"
            fi
        done < "$MANIFEST"
        echo "}"
        echo ""
        echo "#endif"
    } > "$OUT_H"
    echo "sync_version: tool $TOOL_VER -> $OUT_TU + $OUT_H"
else
    echo "sync_version: tool $TOOL_VER -> $OUT_TU (no sibling co/)"
fi
