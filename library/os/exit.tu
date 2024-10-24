
use fmt
use std
use runtime
use string
use runtime.debug

debug_stack<i64> = 5

func set_stack(size<i32>){
    debug_stack = size
}
NewLine<i8> = '\n'

func panic(args...){
    ret<i8*> = string.dynstringfmt(args)
    if ret != null {
		fmt.vfprintf(std.STDOUT,ret)
    }
    //REMOVE: todo
    if debug.enabled != 1 {
        p<i8*> = null
        *p = 1
    }    
    infos = debug.stack(debug_stack)
    fmt.println("\ndebug backtrace:")
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
    if debug.enabled != 1 {
        p<i8*> = null
        *p = 1
    }
    infos = debug.stack(debug_stack)
    fmt.println("\ndebug backtrace:")
    i = 1
    for v : infos {
        fmt.printf("%d: %s\n",i,v)
        i += 1
    }
    std.die(code)
}
func dief(args...){
    ret<string.Str> = string.dynstringfmt(args)
    if ret != null {
		  fmt.vfprintf(std.STDOUT,ret.putc(NewLine))
    }
    if debug.enabled != 1 {
        p<i8*> = null
        *p = 1
    }
    code<i8> = -1
    infos = debug.stack(debug_stack)
    fmt.println("\ndebug backtrace:")
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