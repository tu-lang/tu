#!/bin/bash
# Assert self-hosted tu encodes mov %reg, label(%rip) as a store (0x89).
set -euo pipefail
if [ "$(uname -s)" != "Darwin" ]; then
    echo "skip: check_rip_store.sh is Darwin-only"
    exit 0
fi
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
export PATH="${ROOT}/release:/usr/local/bin:$PATH"
if ! command -v tu >/dev/null 2>&1; then
    echo "skip: tu not in PATH"
    exit 0
fi
WD=$(mktemp -d "${TMPDIR:-/tmp}/rip-store-XXXXXX")
trap 'rm -rf "$WD"' EXIT
cp "$(dirname "$0")/rip_store.s" "$WD/"
tu -c "$WD/rip_store.s" --target=darwin
otool -tv "$WD/rip_store.o"
python3 - "$WD/rip_store.o" <<'PY'
import sys
d = open(sys.argv[1], "rb").read()
if d.find(b"\x48\x89\x05") < 0:
    print("FAIL: missing RIP-relative store 48 89 05", file=sys.stderr)
    sys.exit(1)
if d.find(b"\x48\x8b\x3d") < 0:
    print("FAIL: missing RIP-relative load 48 8b 3d (%rdi)", file=sys.stderr)
    sys.exit(1)
print("rip_store opcodes OK")
PY
# Host link + run: exit code must be 0x42 (66)
clang -arch x86_64 -o "$WD/a.out" "$WD/rip_store.o"
set +e
"$WD/a.out"
rc=$?
set -e
if [[ "$rc" -ne 66 ]]; then
    echo "expected exit 66 (0x42), got $rc" >&2
    exit 1
fi
echo "rip_store OK"
