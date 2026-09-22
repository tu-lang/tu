use fmt
use os
use linker.link

unsafe fn debug(args...){
    if link.trace {
        fmt.println(args)
    }
}
unsafe fn print_green(red){
   return " \033[32m" + red + "\033[0m"
}
unsafe fn print_red(red){
   return " \033[31m" + red + "\033[0m"
}
unsafe fn msg(progress,str) {
    if progress == 0 {
        fmt.println(print_green(str))
    }else {
        prefix = "[ " + progress + "%]"
        fmt.println(prefix + print_green(str))
    }
}
unsafe fn smsg(pre,str) {
    fmt.println(pre + print_green(str))
}
unsafe fn error(str) {
    fmt.println(print_red(str))
    os.exit(-1)
}
unsafe fn errorf(args...) {
    fmt.println(
        print_red(
            fmt.sprintf(
                args
            )
        )
    )
    os.exit(-1)
}