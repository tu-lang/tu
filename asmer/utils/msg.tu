use fmt
use os
use std
use string
use asmer.asm

unsafe fn debug(args...){
    if asm.trace == 1 {
        s<string.Str> = string.stringfmt(args)
        s = s.putc('\n'.(i8))
        fmt.fputs(s,std.STDOUT)
    }
}
unsafe fn printf(args...){
    // if debug_mode == 1 {
        s<string.Str> = string.stringfmt(args)
        fmt.fputs(s,std.STDOUT)
    // }
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
    f = fmt.sprintf(args)
    fmt.println(print_red(f))
    os.exit(-1)
}