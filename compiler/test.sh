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
    echo "gcc -g *.s /usr/local/lib/coasm/*.s -rdynamic -static -nostdlib -e main"
    gcc -g  *.s /usr/local/lib/coasm/*.s -rdynamic -static -nostdlib -e main 
    check
    ./a.out
    check
    clean "a.out"
    clean "*.s"
    clean "*.o"
    echo "exec done..."

    return
#    failed "[compile] $input failed"
}
cp compiler/test_scanner.tu tmp_test_scanner.tu  
clean "./*.s"
clean "./*.o"
assert tmp_test_scanner.tu
clean "./*.s"
clean "./*.o"
cp compiler/main.tu tmp_compiler.tu  
assert tmp_compiler.tu
clean "./*.s"
clean "./*.o"
clean "tmp_compiler.tu tmp_test_scanner.tu"
log "all passing...."
