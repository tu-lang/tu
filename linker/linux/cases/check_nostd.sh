#!/bin/bash
# Linux -nostd: links only platform/linux stub_*.s (no std package, no
# prebuilt archive). Positive programs must build an ELF and exit 0; a program
# that uses std must fail to link. Skip on non-Linux hosts.
# TU_RUN selects the driver (tu by default; the mother suite passes tuc).
set -u
if [ "$(uname -s)" != "Linux" ]; then
    echo "skip: check_nostd.sh is Linux-only"
    exit 0
fi
runner="${TU_RUN:-tu}"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/tu-nostd-linux.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fail=0

# Builds $1/main.tu with -nostd plus extra flags; sets rc and out.
build_case() {
    local dir="$1"; shift
    out=$(cd "$dir" && "$runner" -nostd "$@" build main.tu --workdir "$dir/wd" 2>&1)
    rc=$?
}

# Asserts $1/main is an ELF executable that exits 0.
expect_elf_exit0() {
    local dir="$1" name="$2"
    if [ "$rc" -ne 0 ]; then
        echo "NOSTD-FAIL(build): $name"; echo "$out" | tail -5; fail=1; return
    fi
    if [ ! -f "$dir/main" ] || [ "$(head -c 4 "$dir/main" | od -An -c | tr -d ' ')" != "177ELF" ]; then
        echo "NOSTD-FAIL(not ELF): $name"; fail=1; return
    fi
    "$dir/main"
    local erc=$?
    if [ "$erc" -ne 0 ]; then
        echo "NOSTD-FAIL(exit $erc): $name"; fail=1; return
    fi
    echo "ok: $name"
}

mkdir -p "$tmp/empty" "$tmp/static" "$tmp/target" "$tmp/usestd" "$tmp/run"

cat > "$tmp/empty/main.tu" <<'EOF'
func main(){}
EOF
build_case "$tmp/empty"
expect_elf_exit0 "$tmp/empty" "empty main"

printf 'package {\n    mode static\n}\n' > "$tmp/static/tu.mod"
cat > "$tmp/static/main.tu" <<'EOF'
fn add(a<i32>, b<i32>) i32 {
    return a + b
}
fn main(){
    s<i32> = 0
    for i<i32> = 0; i < 10; i += 1 {
        s = add(s, i)
    }
}
EOF
build_case "$tmp/static"
expect_elf_exit0 "$tmp/static" "static fn calls"

cp "$tmp/empty/main.tu" "$tmp/target/main.tu"
build_case "$tmp/target" --target=linux
expect_elf_exit0 "$tmp/target" "explicit --target=linux"

cp "$tmp/empty/main.tu" "$tmp/run/main.tu"
out=$(cd "$tmp/run" && "$runner" -nostd run main.tu 2>&1)
rc=$?
if [ "$rc" -ne 0 ]; then
    echo "NOSTD-FAIL(run): run subcommand"; echo "$out" | tail -5; fail=1
else
    echo "ok: run subcommand"
fi

# std is neither compiled nor linked, so std symbols stay undefined.
cat > "$tmp/usestd/main.tu" <<'EOF'
use fmt
func main(){
    fmt.println("nostd must not link std")
}
EOF
build_case "$tmp/usestd"
if [ "$rc" -eq 0 ] || [ -f "$tmp/usestd/main" ]; then
    echo "NOSTD-FAIL(should not link): use fmt"; fail=1
else
    echo "ok: use fmt rejected at link"
fi

if [ "$fail" -ne 0 ]; then
    exit 1
fi
echo "linux nostd tests passed"
