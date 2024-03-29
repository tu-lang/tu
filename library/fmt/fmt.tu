
use os
use runtime
use std
use fmt

func fatal(args...){
    println(args)
    os.exit(-1)
}
//format
func println(_args<u64*>...){
	total<i32> = *_args
    args<u64*> = _args + 8

	var<runtime.Value> = null

    for (i<i32> = 0 ; i < total ; i += 1){
		var = args[i]
        if var == null {
            vfprintf(std.STDOUT,*"NULL\n")
            continue
        }
		match var.type {
            runtime.Null:   vfprintf(std.STDOUT,*"null")
            runtime.Int:    vfprintf(std.STDOUT,string.fromlonglong(var.data))
            runtime.Bool:   {
                if var.data == 0 vfprintf(std.STDOUT,*"false")
                else             vfprintf(std.STDOUT,*"true")
            }
            runtime.String: vfprintf(std.STDOUT,*"%s",var.data)
            runtime.Char:   vfprintf(std.STDOUT,*"%c",var.data)
            runtime.Array:	vfprintf(std.STDOUT,*"%s",runtime.arr_tostring(var))
			runtime.Map:	vfprintf(std.STDOUT,*"map:%p",var)
			runtime.Object:	{
                vfprintf(std.STDOUT,*"obj:%s ",string.fromulonglong(var))
                vfprintf(std.STDOUT,*"iner:%s",string.fromulonglong(var.data))
            }
			_:	vfprintf(std.STDOUT,*"pointer:%s",string.fromlonglong(var))
        }
        vfprintf(std.STDOUT,*"\t")
    }
    vfprintf(std.STDOUT,*"\n")
}
func print(_args<u64*>...){
	total<i32> = *_args
	var<runtime.Value> = null

    args<u64*> = _args + 8
    for(i<i32> = 0;i < total ; i += 1){
		var = args[i]
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
func sprintf(args...){
    ret<i8*> = string.dynstringfmt(args)
    return string.new(ret)
}
func printf(args...){
    ret<i8*> = string.dynstringfmt(args)
    if ret != null {
		vfprintf(std.STDOUT,ret)
    }
}