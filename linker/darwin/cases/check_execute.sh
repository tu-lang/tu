#!/bin/bash
# MH_EXECUTE structure smoke. Skip on non-Darwin.
set -euo pipefail
if [ "$(uname -s)" != "Darwin" ]; then
    echo "skip: check_execute.sh is Darwin-only"
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
file "$WORKDIR/a.out" > "$WORKDIR/file.txt"
grep -q 'Mach-O 64-bit executable' "$WORKDIR/file.txt"
"$WORKDIR/a.out"
echo "ok: empty main MH_EXECUTE exit 0"
