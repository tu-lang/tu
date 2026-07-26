#!/bin/bash
# linker self-tests; artifacts live under $TMPDIR/tu-build-* ([tu] workdir:)
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
    log "[compile] tu -s linker/main.tu "
    ERR=$(mktemp)
    tu -s linker/main.tu -std >"$ERR" 2>&1
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
    # Copy coasm sources into WD so their .o land there too (asmer writes .o
    # next to .s), keeping /usr/local/lib/coasm clean and the link one-dir.
    cp /usr/local/lib/coasm/*.s "$WD"/
    echo "tu -c $WD"
    tu -c "$WD"
    check
    echo "start linking..."
    log "[linker] tu -o $WD"
    tu -o "$WD"
    check
    chmod 777 "$WD/a.out"
    mv "$WD/a.out" tl_test
    if [ "$WD" != "." ]; then
        rm -rf "$WD"
    fi
    cd linker/demo;tua -p .
    cd ../../
    ./tl_test -p linker/demo
    check
    chmod 777 a.out
    echo "exec a.out..."
    ./a.out
    check
    rm ./a.out ./tl_test
    clean "*.s"
    clean "*.o"
    echo "exec done..."

    return
}
assert
log "all passing...."
