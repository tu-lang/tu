use runtime
use fmt

// func stringfmt(fmt<i8*>, args , _1 , _2 , _3 , _4) {
func dynstringfmt(_args<u64*>...){
    curr<u64> = 0
	dyncurr<runtime.Value> = null

	count<i32> = *_args
	args<u64*> = _args + 8
	dyncurr    = args[0] // get first args 'fmt'
    fmts<i8*>  = dyncurr.data

    s<i8*> = empty()
	this<Str> = s

    initlen<u64> = this.len()
    f<i8*> = fmts
    i<u64> = 0
    db<i32> = 2
    single<i32> = 1
    s = this.MakeRoomFor(initlen + std.strlen(fmts) * db)
    f = fmts    
    i = initlen 
	//start at args[1]
	argsidx<i64> = 1
    while *f != null {
        next<i8> = 0
        str<i8*> = 0
        l<u64>   = 0
        num<i64> = 0
        unum<u64> = 0
        if stringavail(s) == runtime.Zero {
            this = s
            s = this.MakeRoomFor(single)
        }
        match *f 
        {
            '%': {
                f   += 1
                next = *f
                match next {
                    's' | 'S' :{
						//TODO: check arry index overflow
                        dyncurr = args[argsidx]
                        curr = dyncurr.data
						argsidx += 1

                        str = curr
						sstr<Str> = str
                        if next == 's' 
                            l = std.strlen(str)
                        else 
                            l = sstr.len()
                        if stringavail(s) < l {
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,str,l)
                        stringinclen(s,l)
                        i += l
                    }
                    'd' | 'D' | 'i' | 'I' : {
                        dyncurr = args[argsidx]
						curr    = dyncurr.data
						argsidx += 1
                        num = curr

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o

                        l = stringll2str(buf,num)
                        if stringavail(s) < l {
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    'u' | 'U' : {
                        dyncurr = args[argsidx]
						curr    = dyncurr.data
						argsidx += 1
                        unum = curr

                        buf_o<i8:21> = 0
                        buf<i8*> = &buf_o
                        l = stringull2str(buf,unum)
                        if stringavail(s) < l {
                            this = s
                            s = this.MakeRoomFor(l)
                        }
                        std.memcpy(s + i,buf,l)
                        stringinclen(s,l)
                        i += l
                    }
                    'c' : {
                        dyncurr = args[argsidx]
						curr    = dyncurr.data
						argsidx += 1
                        s[i] = curr
                        i += 1
                        stringinclen(s,single)
                    }
                    _ : {
                        s[i] = next
                        i += 1
                        stringinclen(s,single)
                    } 
                }
            }
            _ : {
                s[i] = *f
                i += 1
                stringinclen(s,single)
            }
        }
        f += 1
    }
    s[i] = 0
    return s
}