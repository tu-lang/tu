#!/bin/bash
# RFC-114 manifest suite: single project tu.mod with mod entries.
# Every case is a self-contained mini project (fixture tu.mod at its root) and
# is copied into a fresh TMPDIR before compiling — the repo root manifest must
# never participate (its `mod tests { mode mixed }` would disable all checks).
#   ok_*  : must build, run, and print the `// expect:` substring
#   bad_* : must fail and print the `// expect:` diagnostic
# TU_RUN selects the driver (tu by default; the mother suite passes tuc).
set -u
cd "$(dirname "$0")"
runner="${TU_RUN:-tu}"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tu-pkgmode-manifest.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0
for d in ok_*/ bad_*/; do
    d="${d%/}"
    want=$(sed -n '1s|^// expect: ||p' "$d/main.tu")
    if [ -z "$want" ]; then
        echo "MANIFEST-FAIL(missing '// expect:' header): $d"
        fail=1
        continue
    fi
    rm -rf "$tmp/$d"
    cp -R "$d" "$tmp/$d"
    out=$(cd "$tmp/$d" && "$runner" run main.tu 2>&1)
    rc=$?
    case "$d" in
        ok_*)
            if [ "$rc" -ne 0 ]; then
                echo "MANIFEST-FAIL(should pass): $d"
                echo "$out" | tail -5
                fail=1
                continue
            fi
            if ! echo "$out" | grep -q "$want"; then
                echo "MANIFEST-FAIL(missing output '$want'): $d"
                echo "$out" | tail -5
                fail=1
                continue
            fi
            ;;
        bad_*)
            if [ "$rc" -eq 0 ]; then
                echo "MANIFEST-FAIL(should fail): $d"
                fail=1
                continue
            fi
            # Manifest diagnostics embed the manifest path between the pkgmode:
            # prefix and the detail, so assert both parts separately.
            if ! echo "$out" | grep -q "pkgmode:" || ! echo "$out" | grep -q "$want"; then
                echo "MANIFEST-FAIL(wrong diagnostic, want '$want'): $d"
                echo "$out" | head -5
                fail=1
                continue
            fi
            ;;
    esac
    echo "manifest ok: $d"
done
exit $fail
