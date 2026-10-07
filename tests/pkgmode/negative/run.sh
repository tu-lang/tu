#!/bin/bash
# RFC110 negative compile tests: each case must FAIL with a pkgmode: diagnostic.
set -u
cd "$(dirname "$0")"
fail=0
for d in case_*/; do
    out=$(cd "$d" && tu run main.tu 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "NEG-FAIL(should not compile): $d"
        fail=1
        continue
    fi
    if ! echo "$out" | grep -q "pkgmode:"; then
        echo "NEG-FAIL(wrong diagnostic): $d"
        echo "$out" | head -5
        fail=1
        continue
    fi
    echo "neg ok: $d"
done
exit $fail
