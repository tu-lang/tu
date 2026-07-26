#!/bin/bash
# Run TuLang tests under tests/<dir>.
#
# Usage:
#   sh tests_all.sh <dir>              # all *.tu, or only allowlisted if .make_tests exists
#   sh tests_all.sh <dir> --all        # ignore .make_tests, run every *.tu
#   sh tests_all.sh <dir> a.tu b.tu    # run only the named files
#
# Optional allowlist: tests/<dir>/.make_tests
#   One basename per line (# comments and blank lines ignored).
#   Present → make tests / bare dir invoke only listed files.
#   Absent  → run all *.tu (legacy dirs).
#
# Intermediate artifacts live under $TMPDIR/tu-build-* (printed as [tu] workdir:).

log(){
    str="$1"
    echo -e "\033[32m$str \033[0m "
}
clean() {
    if ls $1 > /dev/null 2>&1; then
        rm -rf $1
    fi
}
failed(){
    str="$1"
    echo -e "\033[31m$str \033[0m"
    ps aux|grep tests_asmer.sh|awk '{print $2}' |xargs kill -9
    exit 1
}
check(){
    if [  "$?" != 0 ]; then
        failed "exec failed"
    fi
}

assert(){
    expected="$1"
    input="$2"
    log "[compile] tu -s $input"
    ERR=$(mktemp)
    tu -s $input >"$ERR" 2>&1
    check
    cat "$ERR"
    WD=$(sed -n 's/^\[tu\] workdir: //p' "$ERR" | tail -1 | tr -d '\t\r ')
    rm -f "$ERR"
    if [ -z "$WD" ]; then
        failed "missing [tu] workdir line"
    fi
    if [ "$WD" = "(cwd)" ]; then
        WD="."
    fi
    echo "[test] workdir=$WD"
    log "[asmer] tu -c $WD"
    tu -c "$WD"
    check
    echo "start linking..."
    echo "tu -o $WD -o /usr/local/lib/colib"
    tu -o "$WD" -o /usr/local/lib/colib
    check
    OUT="$WD/a.out"
    chmod 777 "$OUT"
    echo "exec $OUT..."
    "$OUT"
    check
    if [ "$WD" != "." ]; then
        rm -rf "$WD"
    else
        rm -f ./a.out
        clean "*.s"
        clean "*.o"
    fi
    echo "exec done..."

    return
}

# Collect basenames to run for $dir (cwd is tests/).
# Sets global FILES as space-separated list.
collect_files(){
    dir="$1"
    shift
    FILES=""
    force_all=0
    explicit=""

    for arg in "$@"; do
        if [ "$arg" = "--all" ]; then
            force_all=1
        else
            explicit="$explicit $arg"
        fi
    done

    if [ -n "$explicit" ]; then
        for f in $explicit; do
            base=$(basename "$f")
            if [ ! -f "$dir/$base" ]; then
                failed "test file not found: $dir/$base"
            fi
            FILES="$FILES $base"
        done
        return
    fi

    if [ "$force_all" = "0" ] && [ -f "$dir/.make_tests" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # strip comments and whitespace
            line="${line%%#*}"
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            [ -z "$line" ] && continue
            base=$(basename "$line")
            if [ ! -f "$dir/$base" ]; then
                failed "allowlist entry missing: $dir/$base (from .make_tests)"
            fi
            FILES="$FILES $base"
        done < "$dir/.make_tests"
        if [ -z "$FILES" ]; then
            log "[skip] $dir: .make_tests is empty (no files gated in)"
        fi
        return
    fi

    for f in $(ls "$dir"/*.tu 2>/dev/null); do
        FILES="$FILES $(basename "$f")"
    done
}

run_dir(){
    dir="$1"
    shift
    collect_files "$dir" "$@"
    if [ -z "$FILES" ]; then
        return
    fi
    cd "$dir"
    for file in $FILES; do
        echo "$file"
        assert "OK" "$file"
        log "[compile] $file passed!\n"
    done
    cd ..
}

install_env(){
    cd tests
    if [  "$?" != 0 ]; then
        failed "make failed"
    fi
}
install_env
if [ "$1" != "" ]; then
    dir="$1"
    shift
    run_dir "$dir" "$@"
    exit 0
fi
for dir in `ls`
do
    if [ -d $dir ] ; then
        run_dir "$dir"
    fi
done 
log "all passing...."
