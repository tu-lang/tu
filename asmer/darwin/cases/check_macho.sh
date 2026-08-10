#!/bin/bash
# Structure checks for self-hosted MH_OBJECT. Skip on non-Darwin.
set -euo pipefail
if [ "$(uname -s)" != "Darwin" ]; then
    echo "skip: check_macho.sh is Darwin-only"
    exit 0
fi
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
export PATH="${ROOT}/release:/usr/local/bin:$PATH"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/demo_add.s" <<'EOF'
.text
.globl demo_add
demo_add:
    mov %edi, %eax
    add %esi, %eax
    ret
EOF

if command -v tu >/dev/null 2>&1; then
    tu -c "$WORKDIR/demo_add.s" --target=darwin
else
    echo "skip: tu binary not installed"
    exit 0
fi
file "$WORKDIR/demo_add.o" > "$WORKDIR/file.txt"
grep -q 'Mach-O 64-bit object' "$WORKDIR/file.txt"
otool -hv "$WORKDIR/demo_add.o" > "$WORKDIR/otool_hv.txt"
grep -q 'OBJECT' "$WORKDIR/otool_hv.txt"
otool -l "$WORKDIR/demo_add.o" > "$WORKDIR/otool_l.txt"
grep -q '__text' "$WORKDIR/otool_l.txt"
grep -q 'LC_SYMTAB' "$WORKDIR/otool_l.txt"
echo "ok: demo_add MH_OBJECT structure"
echo "all check_macho checks passed"
