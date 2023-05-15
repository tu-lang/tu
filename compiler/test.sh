#!/bin/bash
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
#        actual=`./a.out`
#        if [  "$?" != 0 ]; then
        failed "exec failed"
#        fi
#        rm ./a.out
    fi

}

assert(){
    log "[compile] tu -s compiler/$1 "
    tu -s "$1"
    check
    tu -c .
    tu -o . -o /usr/local/lib/colib/
    check
    chmod 777 a.out
    ./a.out
    check
    clean "a.out"
    clean "*.s"
    clean "*.o"
    echo "exec done..."

    return
#    failed "[compile] $input failed"
}
clean "./*.s"
clean "./*.o"
assert compiler/test_scanner.tu
clean "./*.s"
clean "./*.o"
assert compiler/main.tu
clean "./*.s"
clean "./*.o"
assert compiler/test_scaner2.tu
clean "./*.s"
clean "./*.o"
assert compiler/test_static_token.tu
clean "./*.s"
clean "./*.o"
log "all passing...."
