#!/bin/bash
# RFC110/114 negative compile tests: each case must FAIL with a pkgmode: diagnostic.
# Every case dir is a self-contained mini project (its own fixture tu.mod, if any).
# Cases are copied into a fresh TMPDIR before compiling — the repo root manifest
# must never participate (a nested manifest above the fixture anchor is itself
# a rule-1 error, which would make the test pass for the wrong reason).
# TU_RUN selects the driver (tu by default; the mother suite passes tuc).
set -u
cd "$(dirname "$0")"
runner="${TU_RUN:-tu}"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tu-pkgmode-negative.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0
for d in case_*/; do
    d="${d%/}"
    rm -rf "$tmp/$d"
    cp -R "$d" "$tmp/$d"
    out=$(cd "$tmp/$d" && "$runner" run main.tu 2>&1)
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
