use runtime
// cfg(mod_static,true)

func isspace(c<i32>){
    match c {
        ' ': return runtime.True
        '\t': return runtime.True
        '\v': return runtime.True
        '\n': return runtime.True
        '\f': return runtime.True
        '\r': return runtime.True
        _   : return runtime.False
    }
}
func isxdigit(c<i32>){
    if '0' <= c && c <= '9'
        return 1.(i8)
    if 'a' <= c && c <= 'f'
        return 1.(i8)
    if 'A' <= c && c <= 'F'
        return 1.(i8)
    return 0.(i8)
}
func isdigit(c<i32>)
{
    b<u32> = c
    if (b - '0') < 10 {
        return runtime.True
    }
    return runtime.False
}
func isalpha(c<i32>){
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') {
        return runtime.True
    }
    return runtime.False
}
func isupper(c<i32>){
    if c >= 'A' && c <= 'Z' {
        return runtime.True
    }
    return runtime.False
}
func tolower(c<i32>) {
    return c | 0x20
}
// mystring = newstringlen("abc",3)
// mystring = newstringlen(NULL,0)
func newlen(init<u64*>, initlen<u64>) {
    sh<u64*> = null
    s<u8*> = null

    type<i8> = stringReqType(initlen) 
    if type == LSTRING_TYPE_5 && initlen == null 
        type = LSTRING_TYPE_8

    hdrlen<i32> = stringHdrSize(type)

    // flags pointer. 
    fp<u8*> = null

    #init
    sh = runtime.gc_malloc(hdrlen + initlen + 1)
    if sh == runtime.Null return runtime.Null
    else if !init         std.memset(sh, runtime.Null, hdrlen + initlen + 1)

    s  = sh + hdrlen
    fp = s - 1
    match type {
        LSTRING_TYPE_5: *fp = type | initlen << LSTRING_TYPE_BITS
        LSTRING_TYPE_8: {
            sh8<Stringhdr8> = LSTRING_HDR(LSTRING_TYPE_8,s)
            sh8.len = initlen
            sh8.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_16: {
            sh16<Stringhdr16> = LSTRING_HDR(LSTRING_TYPE_16,s)
            sh16.len = initlen
            sh16.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_32: {
            sh32<Stringhdr32> = LSTRING_HDR(LSTRING_TYPE_32,s)
            sh32.len = initlen
            sh32.alloc = initlen
            *fp = type
        }
        LSTRING_TYPE_64: {
            sh64<Stringhdr64> = LSTRING_HDR(LSTRING_TYPE_64,s)
            sh64.len = initlen
            sh64.alloc = initlen
            *fp = type
        }
    }
    if initlen != runtime.Null && init != runtime.Null
        std.memcpy(s, init, initlen)
    s[initlen] = 0
    
    
    return s
}
func empty() {
    return newlen(*"",runtime.Zero)
}
func newstring(init<i8*>) {
    initlen<u64>  = null
    if  init == null  initlen = 0  
    else              initlen = std.strlen(init)

    return newlen(init, initlen)
}
func fromlonglong(value<i64>) {

    buf<i8*> = new LSTRING_LLSTR_SIZE 
    len<i32> = stringll2str(buf,value)

    return newlen(buf,len)
}
func fromulonglong(value<u64>) {

    buf<i8*> = new LSTRING_LLSTR_SIZE 
    len<i32> = stringull2str(buf,value)

    return newlen(buf,len)
}
func malloc(size<u64>) { 
    return runtime.gc_malloc(size) 
}
func free(ptr<u64*>) {
    runtime.gc_free(ptr) 
}

// func stringfmt(fmt<i8*>, args , _1 , _2 , _3 , _4) {
func stringfmt(_args...){
    curr<u64> = 0
    args<u64*> = _args
	count<i32> = args[0]
	args = args + 8
	fmts<i8*>  = args[0] // get first args 'fmt'

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
                        curr = args[argsidx]
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
                        curr = args[argsidx]
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
                        curr = args[argsidx]
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
                        curr = args[argsidx]
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
//stringll2str
func stringll2str(s<i8*>,value<i64>) {
    p<i8*> = null
    aux<i8> = null
    v<i64> = null
    l<u64> = null

    if value < 0 
        v = 0 - value 
    else 
        v = value
    p = s
    //value == 0
    if(v==null) {
        *p = '0'
        return 1.(i8)
    }
    while v != null {
        *p = '0' + v % 10
        p += 1
        v /= 10
    }
    if value < 0{
        *p = '-'
        p += 1
    } 

    l = p - s
    *p = 0

    p -= 1
    while s < p  {
        aux = *s
        *s = *p
        *p = aux
        s += 1
        p -= 1
    }
    return l
}
func stringull2str(s<i8*> ,v<u64>) {
    p<i8*> = null
    aux<i8> = null
    l<u64> = null

    p = s
    while v != null {
        # *p++ = '0'+(v%10)
        *p = 48 + v % 10
        p += 1
        v /= 10
    } 

    l = p - s
    *p = 0

    p -= 1
    while s < p {
        aux = *s
        *s = *p
        *p = aux
        s += 1
        p -= 1
    }
    return l
}