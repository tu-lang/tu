
use fmt
use std
use runtime
use string
use runtime.debug

debug_stack<i64> = 5

// Dyn facade: backtrace depth from Int Value.data.
export func set_stack(size){
    sv<runtime.Value> = size
    if sv != null {
        debug_stack = sv.data
    }
}
NewLine<i8> = '\n'

export func panic(args...){
    ret<i8*> = string.dynstringfmt(args)
    if ret != null {
		fmt.vfprintf(std.STDOUT,ret)
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
export func die(str){
    fmt.println(str)
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
export func dief(args...){
    ret<string.Str> = string.dynstringfmt(args)
    if ret != null {
		  fmt.vfprintf(std.STDOUT,ret.putc(NewLine))
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
export func exit(code){
    cv<runtime.Value> = code
    if cv == null {
        std.die(-1.(i8))
    }
    std.die(cv.data.(i8))
}