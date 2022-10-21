
use fmt
use std
use runtime
use string
use runtime.debug

NewLine<i8> = '\n'

extern _ string_stringfmt()
func panic(size,args...){
    ret<i8*> = __.string_stringfmt(args)
    if ret != null {
		fmt.vfprintf(std.STDOUT,ret)
    }
    debug.stack(3)
   os.exit(-1)
}
func die(str){
    fmt.println(str)
    code<i8> = -1
    debug.stack(3)
    std.die(code)
}
func dief(size,args...){
    ret<string.Str> = __.string_stringfmt(args)
    if ret != null {
		  fmt.vfprintf(std.STDOUT,ret.putc(NewLine))
    }
    code<i8> = -1
    debug.stack(3)
    std.die(code)
}
func exit(code){
    std.die(*code)
}