#!/bin/bash
# Negative .await tests: each case_*/main.tu must FAIL (compile or run) and
# print the substring stored in case_*/expect.
# TU_RUN selects the driver (tu by default; the mother suite passes tuc).
set -u
cd "$(dirname "$0")"
runner="${TU_RUN:-tu}"
fail=0
for d in case_*/; do
    want=$(cat "$d/expect")
    out=$(cd "$d" && "$runner" run main.tu 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "NEG-FAIL(should fail): $d"
        fail=1
        continue
    fi
    if ! echo "$out" | grep -qF "$want"; then
        echo "NEG-FAIL(wrong diagnostic, want '$want'): $d"
        echo "$out" | tail -5
        fail=1
        continue
    fi
    echo "neg ok: $d"
done
exit $fail
