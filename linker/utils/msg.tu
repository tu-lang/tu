use fmt
use os
use linker.link

func debug(args...){
    if link.trace {
        fmt.println(args)
    }
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