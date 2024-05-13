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

test_asmer_compile(){
    log "[compile] tu -s asmer/main.tu "
    tu -s asmer/main.tu
    check
    tu -c .
    tu -o . -o /usr/local/lib/colib/
    check
    chmod 777 a.out
    log "./a.out -p asmer/cases"
    ./a.out -p asmer/cases
    check
    clean "a.out"
    clean "*.s"
    clean "*.o"
    echo "test asmer_compile done..."
    return
}
test_all(){
    log "[compile] tu -s asmer/test.tu "
    tu -s asmer/test.tu
    check
    tu -c .
    tu -o . -o /usr/local/lib/colib
    check
    chmod 777 a.out
    ./a.out
    check
    clean "a.out"
    clean "*.s"
    clean "*.o"
    echo "test asmer_compile done..."
    return
}
clean "./*.s"
clean "./*.o"
test_asmer_compile
clean "./*.s"
clean "./*.o"
test_all
log "all passing...."
