use fmt
use os
use std
use string
debug_mode<i32> = 0

func debug(args...){
    if debug_mode == 1 {
        s<string.Str> = string.stringfmt(args)
        s = s.putc('\n'.(i8))
        fmt.fputs(s,std.STDOUT)
    }
}
func printf(args...){
    // if debug_mode == 1 {
        s<string.Str> = string.stringfmt(args)
        fmt.fputs(s,std.STDOUT)
    // }
}
func print_green(red){
   return " \033[32m" + red + "\033[0m"
}
func print_red(red){
   return " \033[31m" + red + "\033[0m"
}
func msg(progress,str) {
    if progress == 0 {
        fmt.println(print_green(str))
    }else {
        prefix = "[ " + progress + "%]"
        fmt.println(prefix + print_green(str))
    }
}
func smsg(pre,str) {
    fmt.println(pre + print_green(str))
}
func error(str) {
    fmt.println(print_red(str))
    os.exit(-1)
}
func errorf(args...) {
    f = fmt.sprintf(args)
    fmt.println(print_red(f))
    os.exit(-1)
}