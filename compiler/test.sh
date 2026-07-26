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
    log "[compile] tu -s compiler/$1 "
    ERR=$(mktemp)
    tu -s "$1" >"$ERR" 2>&1
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
    tu -c "$WD"
    check
    tu -o "$WD" -o /usr/local/lib/colib/
    check
    OUT="$WD/a.out"
    chmod 777 "$OUT"
    "$OUT"
    check
    if [ "$WD" != "." ]; then
        rm -rf "$WD"
    else
        clean "a.out"
        clean "*.s"
        clean "*.o"
    fi
    echo "exec done..."
    return
}
assert compiler/test_scanner.tu
assert compiler/main.tu
assert compiler/test_scaner2.tu
assert compiler/test_static_token.tu
log "all passing...."
