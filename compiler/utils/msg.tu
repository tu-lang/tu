use fmt
use os
use compiler.compile

func notice(args...){
    if compile.trace {
        fmt.print("[notice]\t")
        msg1 = fmt.sprintf(args)
        fmt.println(print_green(msg1))
    }
}
func debug(args...){
    if compile.trace {
        fmt.print("[debug]\t")
        fmt.println(args)
    }
}
func debugf(args...){
    if !compile.trace {
        return true
    }
    fmt.print("[debugf]\t")
    msg1 = fmt.sprintf(args)
    // green = fmt.sprintf("\033[32m%s\033[0m",msg1)
    // green = fmt.sprintf("\033[32m%s\033[0m",msg1)
    fmt.println(msg1)
}
func print_green(red){
   return " \033[32m" + red + "\033[0m"
}
func print_red(red){
   return " \033[31m" + red + "\033[0m"
}
func msg2(progress,str1,str2) {
    if progress == 0 {
        fmt.println(print_green(str1) + " " + str2)
    }else {
        prefix = "[ " + progress + "%]"
        fmt.println(prefix + print_green(str1) + " " + str2)
    }
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
    os.die(print_red(m))
}
func panic(args...){
    os.die(fmt.sprintf(args))
}