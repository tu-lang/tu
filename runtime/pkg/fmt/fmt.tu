
use os
use runtime
use std
use fmt

func fatal(size,args...){
   println(args)
   os.exit(-1)
}
//format
func println(count<runtime.Value>,args...){
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
            vfprintf(std.STDOUT,*"null\n")
            continue
        }
		match var.type {
            runtime.Null:   vfprintf(std.STDOUT,*"null")
            runtime.Int:    vfprintf(std.STDOUT,*"%d",var.data)
            runtime.Bool:   {
                if var.data == 0 vfprintf(std.STDOUT,*"false")
                else             vfprintf(std.STDOUT,*"true")
            }
            runtime.String: vfprintf(std.STDOUT,*"%s",var.data)
            runtime.Char:   vfprintf(std.STDOUT,*"%d",var.data)
            runtime.Array:	vfprintf(std.STDOUT,*"%s",runtime.arr_tostring(var))
			runtime.Map:	vfprintf(std.STDOUT,*"map:%p",var)
			runtime.Object:	vfprintf(std.STDOUT,*"object:%p",var)
			_:				vfprintf(std.STDOUT,*"pointer:%p",var)
        }
        vfprintf(std.STDOUT,*"\t")
    }
    vfprintf(std.STDOUT,*"\n")
}
func print(count<runtime.Value> , args...){
	total<i32> = count.data
	var<runtime.Value> = null

	p<u64*> = &args
	stack<i32> = 5
    for(i<i32> = 0;i < total ; i += 1){
		var = *p
		if stack < 1  p += 8
		else 		  p -= 8
		if stack == 1 {
			p = &args
			p += 32
		}		
		stack -= 1

        if	!var {
            vfprintf(std.STDOUT,*"null")
            continue
        }
        match var.type {
            runtime.Int:	vfprintf(std.STDOUT,*"%d",var.data)
            runtime.Char:	vfprintf(std.STDOUT,*"%d",var.data)
            runtime.Bool:	vfprintf(std.STDOUT,*"%d",var.data)
            runtime.String:	vfprintf(std.STDOUT,*"%s",var.data)
            runtime.Array:	vfprintf(std.STDOUT,*"%s",runtime.arr_tostring(var))
            _ :				vfprintf(std.STDOUT,*"undefine")
        }
    }
    return total

}

// %s  origin char*
// %S  wrap  string*
// %i  signed int  
// %I  long signed int
// %u  unsigned int
// %U  long unsigned int
// %%  to '%'
extern _ string_stringfmt()
func sprintf(count<runtime.Value>,args...){
    ret<i8*> = __.string_stringfmt(args)
    return string.new(ret)
}
func printf(count<runtime.Value>,args...){
    ret<i8*> = __.string_stringfmt(args)
    if ret != null {
		vfprintf(std.STDOUT,ret)
    }
}