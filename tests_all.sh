#!/bin/bash
# Run TuLang tests under tests/<dir>.
#
# Usage:
#   sh tests_all.sh <dir>              # every *.tu in tests/<dir>
#   sh tests_all.sh <dir> a.tu b.tu    # run only the named files
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
    # Default embed stdroot: tu run compiles std+coasm (no prefix colib).
    log "[run] tu run $input"
    tu run "$input"
    check
    echo "exec done..."
    return
}

# Collect basenames to run for $dir (cwd is tests/).
# Sets global FILES as space-separated list.
collect_files(){
    dir="$1"
    shift
    FILES=""

    if [ "$#" -gt 0 ]; then
        for f in "$@"; do
            base=$(basename "$f")
            if [ ! -f "$dir/$base" ]; then
                failed "test file not found: $dir/$base"
            fi
            FILES="$FILES $base"
        done
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
