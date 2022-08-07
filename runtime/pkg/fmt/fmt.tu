
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
			p += 24
		}		
		stack -= 1

        if var == null {
            vfprintf(std.STDOUT,*"null\n")
            continue
        }
		match var.type {
            runtime.Null:   vfprintf(std.STDOUT,*"null")
            runtime.Int:    vfprintf(std.STDOUT,*"%d",var.data)
            runtime.Bool:   vfprintf(std.STDOUT,*"%d",var.data)
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
			p += 24
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
func sprintf(fmtstr<runtime.Value>, args , _1 , _2 , _3 , _4) {
    s<i8*> = string.stringempty()
    initlen<u64> = string.stringlen(s)
    f<i8*> = fmtstr.data
    i<u64> = 0
    db<i32> = 2
    single<i32> = 1
    s = string.stringMakeRoomFor(s, initlen + std.strlen(fmtstr.data) * db)
    i = initlen 
    curr<runtime.Value> = 0

 	pp<u64*> = &args
	stack<i32> = 5   
    while *f != null {
        next<i8> = 0
        str<i8*> = 0
        l<u64>   = 0
        num<i64> = 0
        unum<u64> = 0
        if string.stringavail(s) == runtime.Zero {
            s = string.stringMakeRoomFor(s,single)
        }
        match *f 
        {
            '%': {
                f   += 1
                next = *f
                match next {
                    's' | 'S' :{
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        //push end ---
                        //push rip
                        //push rbp
                        //mov %rdi ,-8(%rbp)
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        str = curr.data
                        if next == 's' 
                            l = std.strlen(str)
                        else 
                            l = string.stringlen(str)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,str,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    'i' | 'I' : {
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        num = curr.data

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = string.stringll2str(buf,num)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    'u' | 'U' : {
                        //init stack
                        curr = *pp
                        if stack < 1  pp += 8	else pp -= 8
                        if stack == 1 {	pp = &fmtstr	pp += 24	}		
                        stack -= 1
                        //stack end
                        unum = curr.data

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = string.stringull2str(buf,unum)
                        if string.stringavail(s) < l {
                            s = string.stringMakeRoomFor(s,l)
                        }
                        std.memcpy(s + i,buf,l)
                        string.stringinclen(s,l)
                        i += l
                    }
                    _ : {
                        # s[i++] = next
                        tp<i8*> = s + i
                        i += 1
                        *tp = next
                        string.stringinclen(s,single)
                    } 
                }
            }
            _ : {
                # s[i++] = *f
                tp<i8*> = s + i
                i += 1
                *tp = *f
                string.stringinclen(s,1)
            }
        }
        f += 1
    }
    # s[i] = '\0'
    tp<i8*> = s + i
    *tp = 0
    return string.new(s)
}