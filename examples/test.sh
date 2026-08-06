#!/bin/bash
# Orchestrate per-example tests under examples/*/test.sh.
# Invoked by `make tests` (target: examples). Each demo owns its harness —
# resident servers, one-shot CLIs, and load shapes differ by product.
#
# Convention:
#   examples/<name>/main.tu   — demo entry
#   examples/<name>/test.sh   — required; exit 0 = pass
# New examples MUST add test.sh (see .cursor/rules/examples-dynamic-facade.mdc).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXAMPLES_DIR="$ROOT/examples"

log(){
    echo -e "\033[32m$1\033[0m"
}
failed(){
    echo -e "\033[31m$1\033[0m"
    exit 1
}

cd "$EXAMPLES_DIR" || failed "missing examples/"

[ -f "$EXAMPLES_DIR/_harness.sh" ] || failed "missing examples/_harness.sh"

ran=0
for dir in */; do
    name="${dir%/}"
    case "$name" in
        .) continue ;;
    esac
    if [ ! -f "$name/main.tu" ]; then
        continue
    fi
    if [ ! -f "$name/test.sh" ]; then
        failed "examples/$name: has main.tu but missing test.sh (required)"
    fi
    log "[examples] $name/test.sh"
    # Child must exit non-zero on any failure (set -e in each test.sh).
    if ! bash "$name/test.sh"; then
        failed "examples/$name failed"
    fi
    log "[examples] $name passed"
    ran=$((ran + 1))
done

if [ "$ran" -eq 0 ]; then
    failed "examples: no demos with main.tu + test.sh"
fi

log "examples: all $ran demos passed"
exit 0
