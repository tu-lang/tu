
use fmt
use std

extern _ string_stringfmt()
func panic(size,args...){
    ret<i8*> = __.string_stringfmt(args)
    if ret != null {
		fmt.vfprintf(std.STDOUT,ret)
    }
   os.exit(-1)
}
func die(str){
    fmt.println(str)
    code<i8> = -1
    std.die(code)
}
func exit(code){
    std.die(*code)
}