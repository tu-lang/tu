#!/bin/bash
# runtime_pclntab present when linking std. Skip on non-Darwin.
set -euo pipefail
if [ "$(uname -s)" != "Darwin" ]; then
    echo "skip: check_pclntab.sh is Darwin-only"
    exit 0
fi
export PATH="/usr/local/bin:$PATH"
if ! command -v tu >/dev/null 2>&1; then
    echo "skip: tu not installed"
    exit 0
fi
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
cat > "$WORKDIR/hello.tu" <<'EOF'
use fmt
fn main() {
    fmt.println("ok")
}
EOF
(cd "$WORKDIR" && tu build hello.tu --workdir-cwd)
nm "$WORKDIR/a.out" > "$WORKDIR/nm.txt"
grep -q 'runtime_pclntab' "$WORKDIR/nm.txt"
"$WORKDIR/a.out" > "$WORKDIR/out.txt" 2>"$WORKDIR/err.txt"
grep -q 'ok' "$WORKDIR/out.txt"
echo "ok: pclntab symbol + hello run"
