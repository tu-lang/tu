use runtime
use fmt
use std

func println_green(count<runtime.Value>,args...){
	total<i32> = count.data
	var<runtime.Value> = null

	p<u64*> = &args
	stack<i32> = 5
    for (i<i32> = 0 ; i < total ; i += 1){
		var = *p
		if stack < 1  p += 8
		else 		  p -= 8
		if stack == 1 {
			p = &args
			p += 32
		}		
		stack -= 1

        if var == null {
            fmt.vfprintf(std.STDOUT,*"\033[32mnull\033[0m\n")
            continue
        }
		match var.type {
            runtime.Null:   fmt.vfprintf(std.STDOUT,*"\033[32mnull\033[0m")
            runtime.Int:    fmt.vfprintf(std.STDOUT,*"\033[32m%d\033[0m",var.data)
            runtime.Bool:   {
                if var.data == 0 fmt.vfprintf(std.STDOUT,*"\033[32mfalse\033[0m")
                else             fmt.vfprintf(std.STDOUT,*"\033[32mtrue\033[0m")
            }
            runtime.String: fmt.vfprintf(std.STDOUT,*"\033[32m%s\033[0m",var.data)
            runtime.Char:   fmt.vfprintf(std.STDOUT,*"\033[32m%d\033[0m",var.data)
            runtime.Array:	fmt.vfprintf(std.STDOUT,*"\033[32m%s\033[0m",runtime.arr_tostring(var))
			runtime.Map:	fmt.vfprintf(std.STDOUT,*"\033[32mmap:%p\033[0m",var)
			runtime.Object:	fmt.vfprintf(std.STDOUT,*"\033[32mobject:%p\033[0m",var)
			_:				fmt.vfprintf(std.STDOUT,*"\033[32mpointer:%p\033[0m",var)
        }
        fmt.vfprintf(std.STDOUT,*"\t")
    }
    fmt.vfprintf(std.STDOUT,*"\n")
}