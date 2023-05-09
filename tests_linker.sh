#!/bin/bash
log(){
    str="$1"
    echo -e "\033[32m$str \033[0m "
}
failed(){
    str="$1"
    echo -e "\033[31m$str \033[0m"
    ps aux|grep tests_linker.sh|awk '{print $2}' |xargs kill -9
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
    expected="$1"
    input="$2"
    log "[compile] tu -s $input ..."
    tuc -s $input
    check
    #log "[asmer] toa -p ."
    #toa -p .
    echo "tu -c . -c /usr/local/lib/coasm"
    tu -c . -c /usr/local/lib/coasm
    echo "start linking..."
    log "[linker] tu -c ."
    tu -o .
    check
    chmod 777 a.out
    echo "exec a.out..."
    ./a.out
    check
    rm ./a.out
    clean "*.s"
    clean "*.o"
    echo "exec done..."

    return
#    failed "[compile] $input failed"
}
read_dir(){
    dir="$1"
    cd $dir
    for file in `ls *.tu`
    do
     if [ -d $file ] ; then
        read_dir $file
     else
        clean "*.s"
        clean "*.o"
        assert "OK" $file
        log "[compile] $file passed!\n"
     fi
    done
    clean *.s
    clean *.o
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
    read_dir $1
    exit 0
fi
for dir in `ls`
do
    if [ -d $dir ] ; then
        read_dir $dir
        clean "$dir/*.o"
        clean "$dir/*.s"
    fi
done 
log "all passing...."
