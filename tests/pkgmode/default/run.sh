#!/bin/bash
# RFC110 default mode: a tree with no tu.mod on any ancestor compiles as dyn.
# Each case is copied into a fresh TMPDIR dir (no ancestor manifest) and run there:
#   ok_*  : must build and run (exit 0) and print the `// expect:` substring
#   bad_* : must fail and print the `// expect:` diagnostic
# The expectation is the first line of each case's main.tu: `// expect: <substring>`.
# TU_RUN selects the driver (tu by default; the mother suite passes tuc).
set -u
cd "$(dirname "$0")"
runner="${TU_RUN:-tu}"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tu-pkgmode-default.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0
for d in ok_*/ bad_*/; do
    d="${d%/}"
    want=$(sed -n '1s|^// expect: ||p' "$d/main.tu")
    if [ -z "$want" ]; then
        echo "DEFAULT-FAIL(missing '// expect:' header): $d"
        fail=1
        continue
    fi
    cp -R "$d" "$tmp/$d"
    out=$(cd "$tmp/$d" && "$runner" run main.tu 2>&1)
    rc=$?
    case "$d" in
        ok_*)
            if [ "$rc" -ne 0 ]; then
                echo "DEFAULT-FAIL(should pass): $d"
                echo "$out" | tail -5
                fail=1
                continue
            fi
            ;;
        bad_*)
            if [ "$rc" -eq 0 ]; then
                echo "DEFAULT-FAIL(should fail): $d"
                fail=1
                continue
            fi
            ;;
    esac
    if ! echo "$out" | grep -qF "$want"; then
        echo "DEFAULT-FAIL(want '$want'): $d"
        echo "$out" | tail -5
        fail=1
        continue
    fi
    echo "default ok: $d"
done
exit $fail
