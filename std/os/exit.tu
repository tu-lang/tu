
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
    infos = debug.stack(3)
    fmt.println("debug backtrace:")
    i = 1
    for v : infos {
        fmt.printf("%d: %s\n",i,v)
        i += 1
    }
    os.exit(-1)
}
func die(str){
    fmt.println(str)
    code<i8> = -1
    infos = debug.stack(3)
    fmt.println("debug backtrace:")
    i = 1
    for v : infos {
        fmt.printf("%d: %s\n",i,v)
        i += 1
    }
    std.die(code)
}
func dief(size,args...){
    ret<string.Str> = __.string_stringfmt(args)
    if ret != null {
		  fmt.vfprintf(std.STDOUT,ret.putc(NewLine))
    }
    code<i8> = -1
    infos = debug.stack(3)
    fmt.println("debug backtrace:")
    i = 1
    for v : infos {
        fmt.printf("%d: %s\n",i,v)
        i += 1
    }
    std.die(code)
}
func exit(code){
    std.die(*code)
}