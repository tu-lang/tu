#!/bin/bash
# Compile-time negatives for RFC-107 embed (expect failure).
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/tests/statement/embed_neg"
fail=0
for f in *.tu; do
  set +e
  tuc -s "$f" >/tmp/embed_neg_$f.out 2>&1
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    echo "FAIL expected compile error: $f"
    fail=1
  else
    echo "ok (rejected): $f"
  fi
done
if [ "$fail" != 0 ]; then
  exit 1
fi
echo "all embed negatives rejected"
