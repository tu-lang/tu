#!/bin/bash
# asmer self-tests; artifacts live under $TMPDIR/tu-build-* ([tu] workdir:)
log(){
    str="$1"
    echo -e "\033[32m$str \033[0m "
}
failed(){
    str="$1"
    echo -e "\033[31m$str \033[0m"
    ps aux|grep test.sh|awk '{print $2}' |xargs kill -9
    exit 1
}
clean() {
    if ls $1 > /dev/null 2>&1; then
        rm -rf $1
    fi
}
check(){
    if [  "$?" != 0 ]; then
        failed "exec failed"
    fi
}

# Default embed: tu run compiles std+coasm (no prefix colib).
run_tu(){
    src="$1"
    shift
    log "[run] tu run $src $*"
    tu run "$src" "$@"
    check
}

test_asmer_compile(){
    run_tu asmer/main.tu -p asmer/cases
    echo "test asmer_compile done..."
}
test_all(){
    run_tu asmer/test.tu
    echo "test asmer_compile done..."
}
test_asmer_compile
test_all
log "all passing...."
