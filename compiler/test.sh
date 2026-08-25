#!/bin/bash
# compiler self-tests; artifacts live under $TMPDIR/tu-build-* ([tu] workdir:)
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

assert(){
    log "[run] tu run $1"
    tu run "$1"
    check
    echo "exec done..."
    return
}
assert compiler/test_scanner.tu
assert compiler/main.tu
assert compiler/test_scaner2.tu
assert compiler/test_static_token.tu
log "all passing...."
