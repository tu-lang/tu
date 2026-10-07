#!/usr/bin/env bash
# RFC-110 Stage F2: prefix package-level dynamic facades with `export` in static trees.
# Skips: already-exported, `func init`, member forms (`Type::method`), indented bodies.
#
# Usage: scripts/rfc110_export_facades.sh [--dry-run]

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY=1
fi

TREES=(library)
# When packages/runtime/platform declare mode static, add them back and re-run.
# Do NOT include compiler / asmer / linker / tests — dyn/mixed packages must not get export.


python3 - "$ROOT" "$DRY" "${TREES[@]}" <<'PY'
import re, sys
from pathlib import Path

root = Path(sys.argv[1])
dry = sys.argv[2] == "1"
trees = sys.argv[3:]

# Column-0: optional unsafe, then func|async|class, then name (no ::).
# Do not touch `fn` (static). Skip `func init`.
pat = re.compile(
    r"^(unsafe\s+)?(func|async|class)\s+([A-Za-z_][A-Za-z0-9_]*)\b"
)

changed_files = 0
changed_lines = 0
skipped_init = 0
samples = []

for tree in trees:
    base = root / tree
    if not base.is_dir():
        continue
    for path in sorted(base.rglob("*.tu")):
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines(keepends=True)
        out = []
        file_hits = 0
        for line in lines:
            # Only true package-level (no leading whitespace)
            m = pat.match(line)
            if not m:
                out.append(line)
                continue
            unsafe, kind, name = m.group(1), m.group(2), m.group(3)
            # Member defs use Type::name on the same line for async/func outside class
            if "::" in line.split("{", 1)[0]:
                out.append(line)
                continue
            if kind == "func" and name == "init":
                skipped_init += 1
                out.append(line)
                continue
            # Already exported
            if line.startswith("export "):
                out.append(line)
                continue
            prefix = "export "
            # If line was `unsafe func`, drop the leading unsafe — export body is already cross-mode
            rest = line
            if unsafe:
                rest = line[len(unsafe):]
            new = prefix + rest
            out.append(new)
            file_hits += 1
            changed_lines += 1
            if len(samples) < 12:
                samples.append(f"{path.relative_to(root)}: {line.rstrip()}  →  {new.rstrip()}")
        if file_hits:
            changed_files += 1
            if not dry:
                path.write_text("".join(out), encoding="utf-8")

print(f"files={changed_files} lines={changed_lines} skipped_init={skipped_init} dry={dry}")
for s in samples:
    print("  ", s)
PY
