#!/bin/bash
# LC_LOAD_DYLIB / LC_MAIN / LC_DYLD_INFO smoke. Skip on non-Darwin.
set -euo pipefail
if [ "$(uname -s)" != "Darwin" ]; then
    echo "skip: check_dyld_import.sh is Darwin-only"
    exit 0
fi
export PATH="/usr/local/bin:$PATH"
if ! command -v tu >/dev/null 2>&1; then
    echo "skip: tu not installed"
    exit 0
fi
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cat > "$WORKDIR/empty.tu" <<'EOF'
func main(){}
EOF
(cd "$WORKDIR" && tu build empty.tu --workdir-cwd -nostd)
otool -l "$WORKDIR/a.out" > "$WORKDIR/otool.txt"
grep -q 'LC_MAIN' "$WORKDIR/otool.txt"
grep -q 'libSystem.B.dylib' "$WORKDIR/otool.txt"
grep -q 'LC_LOAD_DYLINKER' "$WORKDIR/otool.txt"
echo "ok: MH_EXECUTE dylib/entry load commands"
