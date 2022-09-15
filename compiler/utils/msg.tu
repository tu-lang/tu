use fmt
use os
debug_mode<i32> = 0

func debug(size,args...){
    if debug_mode == 1 {
        println_green(args)
    }
}
func debugf(size,args...){
    if debug_mode != 1 {
        return debug_mode
    }
    msg1 = fmt.sprintf(args)
    green = fmt.sprintf("\033[32m%s\033[0m\n",msg1)
    fmt.println(green)
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
    m = fmt.sprintf(args)
    fmt.println(print_red(m))
    os.exit(-1)
}
func panic(args...){
    os.die(fmt.sprintf(args))
}